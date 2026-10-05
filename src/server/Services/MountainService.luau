--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The climb's rules on the ramp. Gates: a see-through wall at the foot of every tier from the second up, solid for a
-- player until that tier is open to them (clients drop the ones they've opened, MovementController); the server sends
-- anyone found past a closed one back to its approach, which also ends a theft. Slide hits: a player sliding downhill
-- fast enough who reaches a player walking uphill knocks them back down the slope (their client moves them), protects
-- them for a moment, and loses some speed. No hits below the safety line or on a protected tutorial run.
local MountainService = { Name = "MountainService" }

local ENFORCE_EVERY = 0.25
local SAFE_MARGIN = 6
local UPHILL_SPEED = 1.5 -- a target must be moving up the slope at least this fast

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local sliders: { [Player]: boolean } = {}
local protectedUntil: { [Player]: number } = {}
-- A slider who hit a target can't hit them again until they're SeparateStuds apart.
local touching: { [Player]: { [Player]: boolean } } = {}
local blockedNoticeAt: { [Player]: number } = {}
local sightParams = RaycastParams.new()
sightParams.FilterType = Enum.RaycastFilterType.Exclude

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function gateSign(parent: Instance, tier: Olympus.Tier): Part
	local x = tier.XStart - 1.5
	local y = Mountain.RampY(tier.XStart) + 16
	local board = Instance.new("Part")
	board.Name = "Sign"
	board.Anchored = true
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.Transparency = 1
	board.Size = Vector3.new(0.2, 8, 30)
	board.CFrame = CFrame.new(x, y, Olympus.LaneMiddleZ)
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
	words.Text = `{tier.God}'s {tier.Area}\nClimb Power {Format.Short(tier.Reach)}`
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Parent = words
	words.Parent = gui
	board.Parent = parent
	return board
end

local function buildGates(): Folder
	local folder = Instance.new("Folder")
	folder.Name = "ClimbGates"
	for _, tier in Olympus.Tiers do
		if tier.Tier < 2 then
			continue
		end
		local gate = Instance.new("Model")
		gate.Name = `Gate{tier.Tier}`
		gate:SetAttribute("Tier", tier.Tier)
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Anchored = true
		wall.CanQuery = false
		wall.CanTouch = false
		wall.Material = Enum.Material.ForceField
		wall.Color = tier.Accent
		wall.Transparency = 0.2
		local height = Olympus.GateHeight
		wall.Size = Vector3.new(2, height, Olympus.GateWidth)
		wall.CFrame = CFrame.new(tier.XStart, Mountain.RampY(tier.XStart) + height / 2 - 15, Olympus.LaneMiddleZ)
		wall.Parent = gate
		gateSign(gate, tier)
		gate.Parent = folder
	end
	return folder
end

local function block(player: Player, root: BasePart, unlocked: number)
	local next = Olympus.Tiers[unlocked + 1]
	if not next then
		return
	end
	local x = next.XStart - 10
	local z = Mountain.ClampLane(root.Position.Z)
	local character = player.Character
	if character then
		character:PivotTo(CFrame.lookAlong(Vector3.new(x, Mountain.Floor(x, z) + 4, z), Vector3.new(1, 0, 0)))
	end
	if registry.WildService:IsCarrying(player) then
		registry.WildService:Fail(player, "Blocked")
	end
	local now = os.clock()
	if now - (blockedNoticeAt[player] or 0) > 2 then
		blockedNoticeAt[player] = now
		local data = registry.DataService:GetData(player)
		local below = data and (data.Deliveries[tostring(next.Tier - 1)] or 0) or 0
		if below == 0 then
			local previous = Olympus.Tiers[next.Tier - 1]
			Remotes.Notify:Fire(player, `Deliver a lamb from {previous.God} first`, "Bad", "Denied")
		else
			Remotes.Notify:Fire(
				player,
				`Train to climb this slope: {Format.Short(next.Reach)} Climb Power`,
				"Bad",
				"Denied"
			)
		end
	end
end

local function enforce()
	for _, player in Players:GetPlayers() do
		local root = rootOf(player)
		local data = registry.DataService:GetData(player)
		if not root or not data then
			continue
		end
		local position = root.Position
		local tier = Mountain.TierAt(position.X)
		-- Only on the ramp's floor: the plots and the sky above aren't climbing.
		if tier <= 1 or math.abs(position.Y - Mountain.RampY(position.X)) > 60 then
			continue
		end
		local unlocked = Economy.Unlocked(data.ClimbPower, data.Deliveries)
		if tier > unlocked then
			block(player, root, unlocked)
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
	local gates = buildGates()
	gates.Parent = workspace
	trove:Add(gates)
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
		blockedNoticeAt[player] = nil
		for _, list in touching do
			list[player] = nil
		end
	end)
	local sinceEnforce = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceEnforce += dt
		if sinceEnforce >= ENFORCE_EVERY then
			sinceEnforce = 0
			enforce()
		end
		if next(sliders) ~= nil then
			checkHits()
		end
	end)
end

function MountainService.Destroy(_self: any)
	trove:Clean()
end

return MountainService
