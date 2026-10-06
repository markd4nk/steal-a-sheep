--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Avatar = require(script.Avatar)
local Rig = require(script.Rig)

-- The thirty gods, one per tier, all on one state machine: Idle at home, Alert (the thief's head start), Chase along
-- the ramp, Catch or Disengage, then Return home. A god chases only thieves of its own tier, nearest first with a short
-- lock on its target, down the whole descent until they cross the foothill safety line. It moves along the floor itself
-- (no pathfinding to get stuck) at one set speed for the whole chase (Economy.GodSpeed), like Steal an Egg's guardians:
-- never scaled by the thief, nor by the stretch it's on. A catch needs the target within reach and nothing solid
-- between them. Each god is a Roblox avatar (Avatar, Looks), or its block figure (Rig) if the catalog won't load.
local GodService = {
	Name = "GodService",
	-- A god caught this thief: (player).
	Caught = Signal.new() :: Signal.Signal<Player>,
}

type Mood = "Idle" | "Alert" | "Run" | "Taunt" | "Return"

type God = {
	Tier: Olympus.Tier,
	Model: Model,
	Root: BasePart,
	Hip: number, -- studs from its feet to its root's centre
	Align: AlignPosition,
	Turn: AlignOrientation,
	Home: Vector3, -- feet
	At: Vector3, -- feet, where it is now
	Facing: Vector3,
	Mood: Mood,
	Until: number, -- os.clock() an Alert or a Taunt ends
	Target: Player?,
	TargetSince: number,
	Thieves: { [Player]: boolean }, -- carriers of this tier's lambs it may chase
	Gentle: { [Player]: boolean }, -- tutorial thieves: a slower chase
}

local TUTORIAL_SHARE = 0.7
local TARGET_LOCK = 2
local TAUNT_SECONDS = 1.6
local RETURN_SPEED = 16
local LANE_MARGIN = 30

local trove = Trove.new()
local gods: { God } = {}
local losParams = RaycastParams.new()
losParams.FilterType = Enum.RaycastFilterType.Exclude
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

local function setMood(god: God, mood: Mood)
	if god.Mood == mood then
		return
	end
	god.Mood = mood
	god.Model:SetAttribute("Mood", mood)
	local head = god.Model:FindFirstChild("Head")
	local plate = head and head:FindFirstChild("Nameplate")
	local words = plate and plate:FindFirstChild("Mood")
	if words and words:IsA("TextLabel") then
		words.Text = if mood == "Alert" or mood == "Run" then "!!" elseif mood == "Taunt" then "HMPH!" else ""
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function place(god: God, at: Vector3, facing: Vector3)
	god.At = at
	if facing.Magnitude > 1e-3 then
		god.Facing = facing.Unit
	end
	god.Align.Position = at + Vector3.new(0, god.Hip, 0)
	god.Turn.CFrame = CFrame.lookAlong(Vector3.zero, god.Facing)
end

-- A step of `distance` towards `goal` (feet height ignored), along the floor and inside the lane. Distances are
-- measured along the slope, as a player's Humanoid moves its WalkSpeed along it: on a steep stretch a step covers
-- less ground, so a god keeps the same share of a slider's speed on every grade.
local function stepTowards(god: God, goal: Vector3, distance: number): number
	local flat = Vector3.new(goal.X - god.At.X, 0, goal.Z - god.At.Z)
	local remaining = flat.Magnitude
	if remaining < 1e-3 then
		return 0
	end
	local slope = Mountain.RampSlope(god.At.X)
	local move = flat.Unit * math.min(distance / math.sqrt(1 + slope * slope), remaining)
	local x = math.max(god.At.X + move.X, Olympus.SafeLineX)
	local z = math.clamp(god.At.Z + move.Z, Olympus.LaneZ[1] - LANE_MARGIN, Olympus.LaneZ[2] + LANE_MARGIN)
	place(god, Vector3.new(x, Mountain.Floor(x, z, groundParams), z), flat)
	return remaining - move.Magnitude
end

local function eligible(god: God, player: Player): boolean
	local root = rootOf(player)
	return god.Thieves[player] == true and root ~= nil and root.Position.X >= Olympus.SafeLineX
end

local function pickTarget(god: God, now: number): Player?
	local current = god.Target
	if current and eligible(god, current) and now - god.TargetSince < TARGET_LOCK then
		return current
	end
	local best: Player? = nil
	local bestDistance = math.huge
	for player in god.Thieves do
		local root = rootOf(player)
		if root and eligible(god, player) then
			local distance = (root.Position - god.At).Magnitude
			if distance < bestDistance then
				best, bestDistance = player, distance
			end
		end
	end
	if best ~= current then
		god.Target = best
		god.TargetSince = now
	end
	return best
end

local function clearSight(god: God, root: BasePart): boolean
	local eye = god.At + Vector3.new(0, god.Hip + 2, 0)
	local toward = root.Position - eye
	return workspace:Raycast(eye, toward, losParams) == nil
end

-- Thieves who crossed the safety line got away: the chase ends for them (the banner and the danger music stop; nothing
-- more is said).
local function dropEscapees(god: God)
	for player in god.Thieves do
		local root = rootOf(player)
		if root and root.Position.X < Olympus.SafeLineX then
			god.Thieves[player] = nil
			god.Gentle[player] = nil
			Remotes.Chase:Fire(player, nil, nil)
		end
	end
end

local function update(god: God, dt: number, now: number)
	if god.Mood == "Taunt" then
		if now < god.Until then
			return
		end
		setMood(god, "Return")
	end
	dropEscapees(god)
	local target = pickTarget(god, now)
	if god.Mood == "Alert" then
		if not target then
			setMood(god, "Return")
		elseif now >= god.Until then
			setMood(god, "Run")
		else
			local root = rootOf(target)
			if root then
				place(god, god.At, Vector3.new(root.Position.X - god.At.X, 0, root.Position.Z - god.At.Z))
			end
			return
		end
	end
	if target and god.Mood ~= "Alert" then
		setMood(god, "Run")
		local root = rootOf(target) :: BasePart
		local speed = if god.Gentle[target]
			then god.Tier.SlideSpeed * TUTORIAL_SHARE
			else Economy.GodSpeed(god.Tier.Tier)
		god.Model:SetAttribute("Speed", speed)
		stepTowards(god, root.Position, speed * dt)
		local offset = root.Position - (god.At + Vector3.new(0, god.Hip, 0))
		local flat = Vector2.new(offset.X, offset.Z).Magnitude
		if flat <= GameConfig.Theft.CatchStuds + 1 and math.abs(offset.Y) < 8 and clearSight(god, root) then
			god.Thieves[target] = nil
			god.Gentle[target] = nil
			god.Target = nil
			setMood(god, "Taunt")
			god.Until = now + TAUNT_SECONDS
			GodService.Caught:Fire(target)
		end
		return
	end
	if (god.Mood :: Mood) ~= "Idle" then
		setMood(god, "Return")
		god.Model:SetAttribute("Speed", RETURN_SPEED)
		if stepTowards(god, god.Home, RETURN_SPEED * dt) <= 0.5 then
			place(god, god.Home, Mountain.Downhill)
			setMood(god, "Idle")
			god.Model:SetAttribute("Speed", 0)
		end
	end
end

-- Yields: an avatar's catalog items load first.
local function build(tier: Olympus.Tier, parent: Instance): God?
	local avatar, avatarHip = Avatar.Build(tier)
	local model: Model = avatar or Rig.Build(tier)
	local hip = if avatar then avatarHip else Rig.Hip
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local home2 = Mountain.GodHome(tier.Tier)
	local home = Vector3.new(home2.X, Mountain.Floor(home2.X, home2.Y, groundParams), home2.Y)
	model:PivotTo(CFrame.lookAlong(home + Vector3.new(0, hip, 0), Mountain.Downhill))
	local attachment = Instance.new("Attachment")
	attachment.Name = "Drive"
	attachment.Parent = root
	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.Parent = root
	local turn = Instance.new("AlignOrientation")
	turn.Mode = Enum.OrientationAlignmentMode.OneAttachment
	turn.Attachment0 = attachment
	turn.RigidityEnabled = true
	turn.Parent = root
	model:SetAttribute("Tier", tier.Tier)
	model:SetAttribute("Mood", "Idle")
	model:SetAttribute("Speed", 0)
	model.Parent = parent
	root:SetNetworkOwner(nil)
	local god: God = {
		Tier = tier,
		Model = model,
		Root = root,
		Hip = hip,
		Align = align,
		Turn = turn,
		Home = home,
		At = home,
		Facing = Mountain.Downhill,
		Mood = "Idle",
		Until = 0,
		Target = nil,
		TargetSince = 0,
		Thieves = {},
		Gentle = {},
	}
	place(god, home, Mountain.Downhill)
	return god
end

function GodService.Init(_self: any, _systems: Lifecycle.Registry) end

function GodService.Start(_self: any)
	local gods_ = Instance.new("Folder")
	gods_.Name = "Gods"
	gods_.Parent = workspace
	trove:Add(gods_)
	-- Sight lines see through every character, sheep, god, gate and plant; walls and rocks still block them. The
	-- sheep folders are made by services that start later, so the list is looked up again every second.
	local function refreshExclusions()
		local list: { Instance } = { gods_ }
		for _, name in { "WildSheep", "CarriedSheep", "PenSheep" } do
			local found = workspace:FindFirstChild(name)
			if found then
				table.insert(list, found)
			end
		end
		local base = workspace:FindFirstChild("Base")
		local foliage = base and base:FindFirstChild("Foliages")
		if foliage then
			table.insert(list, foliage)
		end
		for _, player in Players:GetPlayers() do
			if player.Character then
				table.insert(list, player.Character)
			end
		end
		losParams.FilterDescendantsInstances = list
		groundParams.FilterDescendantsInstances = list
	end
	refreshExclusions()
	-- Built side by side in the background (Start can't wait for the catalog); a god chases once it's there.
	for _, tier in Olympus.Tiers do
		task.spawn(function()
			local god = build(tier, gods_)
			if god and gods_.Parent then
				gods[tier.Tier] = god
			end
		end)
	end
	local sinceRefresh = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceRefresh += dt
		if sinceRefresh > 1 then
			sinceRefresh = 0
			refreshExclusions()
		end
		local now = os.clock()
		for _, god in gods do
			if god.Mood ~= "Idle" or next(god.Thieves) ~= nil then
				update(god, dt, now)
			end
		end
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		GodService:Release(player)
	end)
end

function GodService.Destroy(_self: any)
	trove:Clean()
	table.clear(gods)
end

-- A thief took one of `tier`'s lambs: after the head start its god comes after them.
function GodService.Chase(_self: any, tier: number, player: Player, tutorial: boolean)
	local god = gods[tier]
	if not god then
		return
	end
	god.Thieves[player] = true
	if tutorial then
		god.Gentle[player] = true
	else
		god.Gentle[player] = nil
	end
	if god.Mood == "Idle" or god.Mood == "Return" then
		setMood(god, "Alert")
		god.Until = os.clock() + GameConfig.Theft.HeadStart
	end
end

-- The thief delivered, gave up or lost the lamb: no god chases them any more.
function GodService.Release(_self: any, player: Player)
	for _, god in gods do
		god.Thieves[player] = nil
		god.Gentle[player] = nil
		if god.Target == player then
			god.Target = nil
		end
	end
end

function GodService.Gods(_self: any): { Model }
	local list: { Model } = {}
	for _, god in gods do
		table.insert(list, god.Model)
	end
	return list
end

return GodService
