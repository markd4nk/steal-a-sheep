--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The climb's rules on the ramp. Climbing: nothing walls a tier off; each player climbs at the speed their Climbing
-- allows on that tier's slope (Mountain.SpeedAt, MovementController moves them), down to a crawl. The server
-- keeps a ceiling per player that rises at that speed (with some slack for lag) and puts anyone found above it back on
-- it. It also gives each player a budget of ground they may cover, refilled at the fastest they could legally go (their
-- walking or escape speed there, or a knockback), and puts anyone who outruns it back where they were. Punches: a god
-- that catches a thief punches them PunchTiers tiers down the mountain; their device flies them there, both checks wait
-- for the flight, and the server puts them on the landing spot if they aren't there by then. A sign at the foot of each
-- tier from the second up names it and its Reach. Slide hits: a player sliding downhill
-- fast enough who reaches a player walking uphill knocks them back down the slope (their client moves them), protects
-- them for a moment, and loses some speed. No hits below the safety line or on a protected tutorial run.
local MountainService = { Name = "MountainService" }

local ENFORCE_EVERY = 0.25
local CLIMB_SLACK = 1.3 -- times the allowed climb speed the ceiling rises
local LEAD_STUDS = 10 -- how far ahead of a player the ceiling may run, so a lag burst isn't pulled back
local LEAD_SECONDS = 1 -- or this many seconds of their climb, whichever is more
local BUDGET_SECONDS = 2 -- the ground budget holds this many seconds of the fastest legal speed (a lag spike's catch-up)
local SAFE_MARGIN = 6
local UPHILL_SPEED = 1.5 -- a target must be moving up the slope at least this fast
local LANDING_GRACE = 0.4 -- seconds after a punch's flight before the server checks the landing
local LANDING_SLACK = 25 -- studs from the landing spot that still count as landed

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local sliders: { [Player]: boolean } = {}
local protectedUntil: { [Player]: number } = {}
-- A slider who hit a target can't hit them again until they're SeparateStuds apart.
local touching: { [Player]: { [Player]: boolean } } = {}
-- The furthest up the ramp (x) each player may be right now.
local ceilings: { [Player]: number } = {}
-- Each player's last checked spot, its character's root, and the studs they may still cover before the next refill.
type Track = { Root: BasePart, At: Vector3, Budget: number }
local tracks: { [Player]: Track } = {}
-- Punched players in flight: when they should have landed, and where.
type Launch = { Until: number, Landing: Vector3 }
local launches: { [Player]: Launch } = {}
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude
local pathParams = RaycastParams.new()
pathParams.FilterType = Enum.RaycastFilterType.Exclude

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function tierSign(parent: Instance, tier: Olympus.Tier): Part
	local x = tier.XStart - 1.5
	local y = Mountain.RampY(tier.XStart) + 16
	local board = Instance.new("Part")
	board.Name = `Sign{tier.Tier}`
	board.Anchored = true
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.Transparency = 1
	board.Size = Vector3.new(0.2, 8, 30)
	board.CFrame = CFrame.new(x, y, Olympus.LaneMiddleZ)
	board:SetAttribute("Tier", tier.Tier)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Left -- facing downhill (-X), towards climbers
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = board
	local words = Instance.new("TextLabel")
	words.Name = "Label"
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromScale(1, 1)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = Color3.new(1, 1, 1)
	words.Text = `{tier.God}'s {tier.Area}\nClimbing {Format.Short(tier.Reach)}`
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Parent = words
	words.Parent = gui
	board.Parent = parent
	return board
end

local function buildSigns(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "TierSigns"
	for _, tier in Olympus.Tiers do
		if tier.Tier >= 2 then
			tierSign(folder, tier)
		end
	end
	return folder
end

-- Studio playtests only: the DebugSpeed attribute (DebugService) multiplies the character's speed.
local function speedBoost(player: Player): number
	if not RunService:IsStudio() then
		return 1
	end
	local boost = player:GetAttribute("DebugSpeed")
	return if type(boost) == "number" and boost > 0 then boost else 1
end

-- The fastest a player at `x` could legally move across the ground: walking, sliding (carrying or not) or knocked back.
-- A slide's momentum counts from the carried lamb's tier, or empty-handed from wherever it began: at most the top.
local function fastest(player: Player, x: number, climb: number): number
	local tier = player:GetAttribute("CarryTier")
	local weight = player:GetAttribute("CarryWeight")
	local base, from = Mountain.SlideBase(climb, math.max(Mountain.TierAt(x), 1), 1), Olympus.Count
	if type(tier) == "number" and type(weight) == "number" then
		base, from = Mountain.SlideBase(climb, tier, weight), tier
	end
	local slide = base * Mountain.Momentum(base, from, x)
	local knock = GameConfig.SlideHit.KnockStuds / GameConfig.SlideHit.KnockSeconds
	return math.max(Mountain.SpeedAt(x, climb, 1), slide, knock)
end

-- Ground covered (x and z) against the budget, which refills at the fastest legal speed and holds up to
-- BUDGET_SECONDS of it. Anyone past it is put at the furthest point they could have reached along the way they moved,
-- not back where they were: a lag spike's catch-up must not drag a slider back towards their god.
local function checkSpeed(player: Player, root: BasePart, climb: number, dt: number)
	local track = tracks[player]
	local position = root.Position
	if not track or track.Root ~= root then
		tracks[player] = { Root = root, At = position, Budget = 0 }
		return
	end
	local speed = fastest(player, track.At.X, climb) * speedBoost(player)
	local cap = math.max(LEAD_STUDS, speed * BUDGET_SECONDS)
	track.Budget = math.min(track.Budget + speed * CLIMB_SLACK * dt, cap)
	local moved = Vector2.new(position.X - track.At.X, position.Z - track.At.Z).Magnitude
	if moved > track.Budget + 0.5 then
		local character = player.Character :: Model
		local reached = track.At:Lerp(position, math.clamp(track.Budget / moved, 0, 1))
		-- The straight line between two samples can cut through a ledge or a trunk: back where they were if anything
		-- solid is in the way, else on the floor under that spot.
		pathParams.FilterDescendantsInstances = { character }
		if workspace:Raycast(track.At, reached - track.At, pathParams) then
			reached = track.At
		else
			reached = Vector3.new(reached.X, math.max(reached.Y, Mountain.Floor(reached.X, reached.Z) + 3), reached.Z)
		end
		character:PivotTo(CFrame.new(reached) * root.CFrame.Rotation)
		track.At = reached
		track.Budget = 0
		return
	end
	track.Budget -= moved
	track.At = position
end

-- A new character starts on its plot, below the safety line, so a ceiling never starts higher than that.
local function enforce(dt: number)
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local data = registry.DataService:GetData(player)
		if not root or not data then
			ceilings[player] = nil
			tracks[player] = nil
			-- Dead or reset mid-punch: the flight is over, so the next character isn't put on its landing spot.
			launches[player] = nil
			continue
		end
		local launch = launches[player]
		if launch then
			if os.clock() < launch.Until + LANDING_GRACE then
				continue
			end
			launches[player] = nil
			if (root.Position - launch.Landing).Magnitude > LANDING_SLACK then
				(player.Character :: Model):PivotTo(CFrame.new(launch.Landing) * root.CFrame.Rotation)
			end
			MountainService:Teleported(player, launch.Landing.X)
			continue
		end
		checkSpeed(player, root, data.ClimbPower, dt)
		local position = root.Position
		local ceiling = ceilings[player] or math.min(position.X, Olympus.SafeLineX)
		local speed = Mountain.SpeedAt(ceiling, data.ClimbPower, 1) * speedBoost(player)
		local lead = math.max(LEAD_STUDS, speed * LEAD_SECONDS)
		ceiling = math.min(ceiling + speed * CLIMB_SLACK * dt, position.X + lead)
		ceilings[player] = ceiling
		if position.X > ceiling + 0.5 then
			local character = player.Character :: Model
			local z = Mountain.ClampLane(position.Z)
			local turn = root.CFrame.Rotation
			character:PivotTo(CFrame.new(ceiling, Mountain.Floor(ceiling, z) + 4, z) * turn)
			tracks[player] = nil
		end
	end
end

local function canHitFrom(root: BasePart): boolean
	return root.Position.X > Olympus.SafeLineX + SAFE_MARGIN and Mountain.IsOnRamp(root.Position)
end

local function checkHits()
	local settings = GameConfig.SlideHit
	local now = os.clock()
	for slider in sliders do
		local sliderRoot = rootOf(slider)
		if not sliderRoot then
			continue
		end
		local velocity = sliderRoot.AssemblyLinearVelocity
		local speed = Vector2.new(velocity.X, velocity.Z).Magnitude
		local hitList = touching[slider]
		if not hitList then
			hitList = {}
			touching[slider] = hitList
		end
		for _, target in Players:GetPlayers() do
			if target == slider then
				continue
			end
			local targetRoot = rootOf(target)
			if not targetRoot then
				hitList[target] = nil
				continue
			end
			local distance = (targetRoot.Position - sliderRoot.Position).Magnitude
			if hitList[target] then
				if distance > settings.SeparateStuds then
					hitList[target] = nil
				end
				continue
			end
			if distance > settings.Reach then
				continue
			end
			local targetVelocity = targetRoot.AssemblyLinearVelocity
			local eligible = speed >= settings.MinSpeed
				and velocity.X < 0
				and canHitFrom(sliderRoot)
				and canHitFrom(targetRoot)
				and not sliders[target]
				and not launches[target]
				and targetVelocity.X > UPHILL_SPEED
				and now >= (protectedUntil[target] or 0)
				and target:GetAttribute("CarryTutorial") ~= true
			if not eligible then
				continue
			end
			local exclude: { Instance } = {}
			for _, player in Players:GetPlayers() do
				if player.Character then
					table.insert(exclude, player.Character)
				end
			end
			sightParams.FilterDescendantsInstances = exclude
			if workspace:Raycast(sliderRoot.Position, targetRoot.Position - sliderRoot.Position, sightParams) then
				continue
			end
			hitList[target] = true
			protectedUntil[target] = now + settings.ProtectSeconds
			target:SetAttribute("ProtectedUntil", workspace:GetServerTimeNow() + settings.ProtectSeconds)
			-- Down the slope, pushed a little to the side the slider came from.
			local side = math.sign(targetRoot.Position.Z - sliderRoot.Position.Z)
			local direction = Vector3.new(-1, 0, side * 0.25).Unit
			Remotes.Knockback:Fire(target, direction)
			Remotes.SlideHit:Fire(slider, settings.SpeedLoss)
			Remotes.Notify:Fire(target, `Bonk! {slider.DisplayName} slid into you`, "Bad", "Denied")
		end
	end
end

function MountainService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function MountainService.Start(_self: any)
	local signs = buildSigns()
	signs.Parent = workspace
	trove:Add(signs)
	trove:Add(Remotes.Slide:Connect(function(player: Player, sliding: boolean)
		if sliding then
			sliders[player] = true
		else
			sliders[player] = nil
		end
		player:SetAttribute("Sliding", sliding)
	end))
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		sliders[player] = nil
		protectedUntil[player] = nil
		touching[player] = nil
		ceilings[player] = nil
		tracks[player] = nil
		launches[player] = nil
		for _, list in touching do
			list[player] = nil
		end
	end)
	local sinceEnforce = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceEnforce += dt
		if sinceEnforce >= ENFORCE_EVERY then
			local elapsed = sinceEnforce
			sinceEnforce = 0
			enforce(elapsed)
		end
		if next(sliders) ~= nil then
			checkHits()
		end
	end)
end

-- A god caught `player`: they're punched PunchTiers tiers down the mountain, to the same share along that tier, or to
-- the mountain's foot from the lowest tiers. The flight takes 1 to 2.5 seconds, longer the further it goes.
function MountainService.Punch(_self: any, player: Player)
	local root = rootOf(player)
	if not root then
		return
	end
	local from = root.Position
	local tier = Mountain.TierAt(from.X)
	local below = tier - GameConfig.Theft.PunchTiers
	local x = Olympus.SafeLineX + 12
	if tier >= 1 and below >= 1 then
		local here, there = Olympus.Tiers[tier], Olympus.Tiers[below]
		local share = math.clamp((from.X - here.XStart) / (here.XEnd - here.XStart), 0, 1)
		x = there.XStart + (there.XEnd - there.XStart) * share
	end
	local z = Mountain.ClampLane(from.Z)
	local landing = Vector3.new(x, Mountain.Floor(x, z) + 3, z)
	local seconds = math.clamp(0.8 + (from - landing).Magnitude / 500, 1, 2.5)
	launches[player] = { Until = os.clock() + seconds, Landing = landing }
	sliders[player] = nil
	Remotes.Punch:Fire(player, landing, seconds)
end

-- Whether `player` is flying from a god's punch: nothing they do counts until they've landed (a steal or a delivery
-- made mid-flight, while the checks wait, would skip the climb).
function MountainService.IsLaunched(_self: any, player: Player): boolean
	return launches[player] ~= nil
end

-- The server moved `player` to `x` itself (home after a catch, onto their plot, a debug steal): both checks start
-- again from there.
function MountainService.Teleported(_self: any, player: Player, x: number)
	ceilings[player] = x
	tracks[player] = nil
end

function MountainService.Destroy(_self: any)
	trove:Clean()
end

return MountainService
