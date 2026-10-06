--!strict
-- Mock-up of the gods' lunge and belly glide and of three new slide poses for players (2026-10-06), for the user to
-- review before anything is built. Not part of the game. In a playtest of a place copy, a Client execute_luau loads
-- this as ReplicatedStorage.TEMP_SlideMockup (rojo build it into Studio's content folder, then GetObjects) and calls
-- Mock.Shot(name): a scripted take on tier 1 with a copy of Pan and the local character carrying a copy of a wild
-- lamb, its camera included, all on one clock (Mock.TimeScale slows it for a slow recorder). Shots: "Now" (Roblox's
-- sit and run, as the game is), "Chase" (the lunge, the belly glide, the catch, getting up, the laugh), and "Penguin",
-- "Surf", "Sled" (the player's slide poses, Pan gliding behind). Mock.Stop() puts everything back.
-- The clips pose over whatever the Animator played, as AnimController does the sheep; a carried lamb keeps
-- CarryController's raised arms.
-- Joints: +X tips forward parts up (a leg swings forward, the head looks up), Y turns, Z rolls the right side up.
-- Root's transform is in the HumanoidRootPart's frame at the hips; lying flat is Root tipped -90 degrees and dropped
-- until the belly meets the floor, then turned to the ramp's slope round the point under the hips.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)

local Mock = {}
Mock.TimeScale = 1

type Pose = { [string]: CFrame }

type Body = {
	Joint: number, -- the Root joint's height over the floor, standing
	Belly: number, -- from the Root joint's axis to the chest's front
	Seat: number, -- from the Root joint to the floor when sitting
}

type Rig = {
	Model: Model,
	Root: BasePart,
	Joints: { [string]: CarryPose.Joint },
	Body: Body,
	Clip: string?,
	ClipStart: number,
	Weight: number,
	Tilt: CFrame,
	Lean: number,
	LastYaw: number,
	Phase: number,
	KeepArms: boolean, -- CarryController holds the arms (a carrying player)
}

local JOINTS: { [string]: string } = {
	Root = "LowerTorso",
	Waist = "UpperTorso",
	Neck = "Head",
	LeftShoulder = "LeftUpperArm",
	RightShoulder = "RightUpperArm",
	LeftElbow = "LeftLowerArm",
	RightElbow = "RightLowerArm",
	LeftWrist = "LeftHand",
	RightWrist = "RightHand",
	LeftHip = "LeftUpperLeg",
	RightHip = "RightUpperLeg",
	LeftKnee = "LeftLowerLeg",
	RightKnee = "RightLowerLeg",
	LeftAnkle = "LeftFoot",
	RightAnkle = "RightFoot",
}
local ARMS = { "LeftShoulder", "RightShoulder", "LeftElbow", "RightElbow", "LeftWrist", "RightWrist", "Waist" }

local rad = math.rad
local TAU = 2 * math.pi

local function tip(d: number): CFrame
	return CFrame.Angles(rad(d), 0, 0)
end
local function turn(d: number): CFrame
	return CFrame.Angles(0, rad(d), 0)
end
local function roll(d: number): CFrame
	return CFrame.Angles(0, 0, rad(d))
end
local function smooth(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Both arms: forward swing, outward spread, elbow bend.
local function arms(pose: Pose, swing: number, spread: number, elbow: number)
	pose.LeftShoulder = tip(swing) * roll(-spread)
	pose.RightShoulder = tip(swing) * roll(spread)
	pose.LeftElbow = tip(elbow)
	pose.RightElbow = tip(elbow)
end

-- Both legs: forward swing, outward spread, knee bend (negative folds the shin back), ankle.
local function legs(pose: Pose, swing: number, spread: number, knee: number, ankle: number)
	pose.LeftHip = tip(swing) * roll(-spread)
	pose.RightHip = tip(swing) * roll(spread)
	pose.LeftKnee = tip(knee)
	pose.RightKnee = tip(knee)
	pose.LeftAnkle = tip(ankle)
	pose.RightAnkle = tip(ankle)
end

local function lying(body: Body, lift: number, pitch: number): CFrame
	return CFrame.new(0, -(body.Joint - body.Belly) + lift, 0) * tip(-90 + pitch)
end

-- Clips: functions of time and the body, filling in a transform per joint.

-- On the belly like a penguin: chest and head up, flippers back and flapping, feet up behind and kicking.
local function belly(t: number, body: Body, pose: Pose)
	local wave = math.sin(t * TAU / 0.9)
	local flap = math.sin(t * TAU * 2 / 0.9)
	pose.Root = lying(body, 0.04 * body.Joint * math.abs(wave), 0) * CFrame.Angles(0, rad(3 * wave), 0)
	pose.Waist = tip(22)
	pose.Neck = tip(70 + 4 * flap)
	arms(pose, -6, 26 + 14 * flap, 6)
	pose.LeftHip = tip(-6 + 9 * wave) * roll(-3)
	pose.RightHip = tip(-6 - 9 * wave) * roll(3)
	pose.LeftKnee = tip(-38 - 8 * wave)
	pose.RightKnee = tip(-38 + 8 * wave)
	pose.LeftAnkle = tip(-25)
	pose.RightAnkle = tip(-25)
end

type Key = { At: number, Fill: (body: Body, pose: Pose) -> () }

local function crouch(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, -0.14 * body.Joint, 0) * tip(-26)
	pose.Waist = tip(-10)
	pose.Neck = tip(32)
	arms(pose, -55, 18, 25)
	legs(pose, 62, 4, -88, 28)
end

local function dive(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, 0.12 * body.Joint, -0.25 * body.Joint) * tip(-72)
	pose.Waist = tip(6)
	pose.Neck = tip(58)
	arms(pose, -18, 38, 0)
	legs(pose, -12, 2, -12, -30)
end

local function contact(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, 0, -0.2 * body.Joint) * lying(body, 0, -4)
	pose.Waist = tip(10)
	pose.Neck = tip(60)
	arms(pose, -8, 34, 4)
	legs(pose, -4, 3, -22, -25)
end

local function bounce(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, 0, -0.1 * body.Joint) * lying(body, 0.2 * body.Joint, 3)
	pose.Waist = tip(24)
	pose.Neck = tip(74)
	arms(pose, -4, 40, 6)
	legs(pose, -2, 3, -45, -25)
end

local function settled(body: Body, pose: Pose)
	belly(0, body, pose)
end

local function stand(_body: Body, _pose: Pose) end

local function push(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, -0.5 * (body.Joint - body.Belly), 0) * tip(-58)
	pose.Waist = tip(14)
	pose.Neck = tip(40)
	arms(pose, 62, 12, 12)
	legs(pose, 72, 4, -115, 42)
end

local function rise(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, -0.12 * body.Joint, 0) * tip(-14)
	pose.Waist = tip(-4)
	pose.Neck = tip(10)
	arms(pose, 12, 10, 10)
	legs(pose, 36, 2, -52, 16)
end

local KEYED: { [string]: { Key } } = {
	-- The god's lunge: crouch, a dive face first with its arms swept back, a belly flop and a bounce.
	Lunge = {
		{ At = 0, Fill = stand },
		{ At = 0.22, Fill = crouch },
		{ At = 0.44, Fill = dive },
		{ At = 0.56, Fill = contact },
		{ At = 0.68, Fill = bounce },
		{ At = 0.84, Fill = settled },
	},
	-- A player throwing themselves onto their belly: the lunge, quicker and lower.
	Flop = {
		{ At = 0, Fill = stand },
		{ At = 0.1, Fill = crouch },
		{ At = 0.24, Fill = dive },
		{ At = 0.32, Fill = contact },
		{ At = 0.42, Fill = bounce },
		{ At = 0.54, Fill = settled },
	},
	GetUp = {
		{ At = 0, Fill = settled },
		{ At = 0.24, Fill = push },
		{ At = 0.46, Fill = rise },
		{ At = 0.62, Fill = stand },
	},
}

local LENGTHS: { [string]: number } = { Lunge = 0.84, Flop = 0.54, GetUp = 0.62 }

local function keyed(name: string, t: number, body: Body, pose: Pose)
	local keys = KEYED[name]
	local last = keys[#keys]
	if t >= last.At then
		last.Fill(body, pose)
		return
	end
	for index = 1, #keys - 1 do
		local a, b = keys[index], keys[index + 1]
		if t < b.At then
			local from: Pose, to: Pose = {}, {}
			a.Fill(body, from)
			b.Fill(body, to)
			local share = smooth((t - a.At) / (b.At - a.At))
			for joint in JOINTS do
				local x = from[joint] or CFrame.identity
				local y = to[joint] or CFrame.identity
				if x ~= CFrame.identity or y ~= CFrame.identity then
					pose[joint] = x:Lerp(y, share)
				end
			end
			return
		end
	end
end

-- Surfing down without a board: side on, left shoulder first, knees bent, looking downhill, carving.
local function surf(t: number, body: Body, pose: Pose)
	local carve = math.sin(t * TAU / 1.8)
	local bob = math.sin(t * TAU / 0.6)
	pose.Root = CFrame.new(0, -0.27 * body.Joint + 0.025 * body.Joint * bob, 0)
		* turn(-78)
		* roll(-8 * carve)
		* tip(-10)
	pose.Waist = turn(18) * tip(-6)
	pose.Neck = turn(52) * tip(4)
	pose.LeftShoulder = roll(-78 - 8 * carve) * tip(8)
	pose.RightShoulder = roll(64 + 8 * carve) * tip(-6)
	pose.LeftElbow = tip(10)
	pose.RightElbow = tip(16)
	pose.LeftHip = tip(44) * roll(-28)
	pose.RightHip = tip(38) * roll(26)
	pose.LeftKnee = tip(-74)
	pose.RightKnee = tip(-66)
	pose.LeftAnkle = tip(30) * roll(24)
	pose.RightAnkle = tip(28) * roll(-22)
end

-- Sat on the ground like a sledge: legs straight out, leaning back, bumping over the slope, arms up (wheee).
local function sled(t: number, body: Body, pose: Pose)
	local bump = math.sin(t * TAU / 0.23) * 0.6 + math.sin(t * TAU / 0.37) * 0.4
	pose.Root = CFrame.new(0, -(body.Joint - body.Seat) + 0.03 * body.Joint * math.abs(bump), 0)
		* tip(20)
		* roll(2 * bump)
	pose.Waist = tip(-4)
	pose.Neck = tip(-12)
	arms(pose, 160, 22, 12)
	pose.LeftHip = tip(76) * roll(-6)
	pose.RightHip = tip(76) * roll(6)
	pose.LeftKnee = tip(-4)
	pose.RightKnee = tip(-4)
	pose.LeftAnkle = tip(-20)
	pose.RightAnkle = tip(-20)
end

local LOOPS: { [string]: (t: number, body: Body, pose: Pose) -> () } = {
	Belly = belly,
	Surf = surf,
	Sled = sled,
}

-- How much of the ramp's slope a pose leans into: lying and sitting follow the floor, a stance stays near upright.
local TILT: { [string]: number } = { Lunge = 1, Flop = 1, GetUp = 1, Belly = 1, Surf = 0.35, Sled = 1 }

local rigs: { [Model]: Rig } = {}
local connections: { RBXScriptConnection } = {}
local touched: { CarryPose.Joint } = {}
local befores: { CFrame } = {}
local clock = 0 -- the scene's seconds: TimeScale times real ones

local function measure(model: Model): Rig?
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return nil
	end
	local joints: { [string]: CarryPose.Joint } = {}
	for joint, part in JOINTS do
		local holder = model:FindFirstChild(part)
		local found = holder and holder:FindFirstChild(joint)
		if found and found:IsA("Motor6D") then
			joints[joint] = found
		elseif found and found:IsA("AnimationConstraint") then
			joints[joint] = found
		end
	end
	local rootJoint = joints.Root
	if not rootJoint then
		return nil
	end
	local offset = if rootJoint:IsA("Motor6D")
		then rootJoint.C0.Y
		else ((rootJoint :: AnimationConstraint).Attachment0 :: Attachment).Position.Y
	local upper = model:FindFirstChild("UpperTorso") :: BasePart?
	local lower = model:FindFirstChild("LowerTorso") :: BasePart?
	local thigh = model:FindFirstChild("LeftUpperLeg") :: BasePart?
	local depth = math.max(upper and upper.Size.Z or 1, lower and lower.Size.Z or 1)
	return {
		Model = model,
		Root = root,
		Joints = joints,
		Body = {
			Joint = humanoid.HipHeight + root.Size.Y / 2 + offset,
			Belly = depth / 2 + 0.05,
			Seat = (thigh and thigh.Size.Z / 2 or 0.5) + 0.1,
		},
		Clip = nil,
		ClipStart = 0,
		Weight = 0,
		Tilt = CFrame.identity,
		Lean = 0,
		LastYaw = 0,
		Phase = 0,
		KeepArms = false,
	}
end

local function transformOf(joint: CarryPose.Joint): CFrame
	if joint:IsA("Motor6D") then
		return joint.Transform
	end
	return (joint :: AnimationConstraint).Transform
end

local function sample(rig: Rig, pose: Pose)
	local clip = rig.Clip
	if not clip then
		return
	end
	local t = clock - rig.ClipStart
	local loop = LOOPS[clip]
	if loop then
		loop(t + rig.Phase, rig.Body, pose)
	elseif KEYED[clip] then
		keyed(clip, t, rig.Body, pose)
	end
end

-- The floor's slope under the rig, as a turn of Root round the point under its hips; and a lean into turns.
local function grounding(rig: Rig, dt: number, share: number): CFrame
	local position = rig.Root.Position
	local normal = Vector3.yAxis
	if Mountain.IsOnRamp(position) then
		normal = Vector3.new(-Mountain.RampSlope(position.X), 1, 0).Unit
	end
	local localNormal = rig.Root.CFrame:VectorToObjectSpace(normal)
	local target = CFrame.fromRotationBetweenVectors(Vector3.yAxis, Vector3.yAxis:Lerp(localNormal, share).Unit)
	rig.Tilt = rig.Tilt:Lerp(target, math.clamp(dt * 10, 0, 1))
	local look = rig.Root.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local delta = (yaw - rig.LastYaw + math.pi) % TAU - math.pi
	rig.LastYaw = yaw
	local rate = if dt > 0 then delta / dt else 0
	rig.Lean += (math.clamp(math.deg(rate) * 0.25, -22, 22) - rig.Lean) * math.clamp(dt * 6, 0, 1)
	local under = CFrame.new(0, -rig.Body.Joint, 0)
	return under * rig.Tilt * roll(-rig.Lean) * under:Inverse()
end

local function apply(realDt: number)
	local dt = realDt * Mock.TimeScale
	table.clear(touched)
	table.clear(befores)
	for model, rig in rigs do
		if not model.Parent then
			rigs[model] = nil
			continue
		end
		local wanted = rig.Clip ~= nil
		rig.Weight += ((if wanted then 1 else 0) - rig.Weight) * math.clamp(dt * (if wanted then 14 else 8), 0, 1)
		if rig.Weight < 0.01 and not wanted then
			rig.Weight = 0
			continue
		end
		local pose: Pose = {}
		sample(rig, pose)
		local share = if rig.Clip then TILT[rig.Clip :: string] or 0 else 0
		pose.Root = grounding(rig, dt, share) * (pose.Root or CFrame.identity)
		for name, joint in rig.Joints do
			if rig.KeepArms and table.find(ARMS, name) then
				continue
			end
			local target = pose[name] or CFrame.identity
			local before = transformOf(joint)
			table.insert(touched, joint)
			table.insert(befores, before)
			CarryPose.SetTransform(joint, before:Lerp(target, rig.Weight))
		end
	end
end

local function restore()
	for index, joint in touched do
		CarryPose.SetTransform(joint, befores[index])
	end
	table.clear(touched)
end

-- Starts `clip` on the model (nil hands it back to the Animator, faded).
function Mock.Play(model: Model, clip: string?)
	local rig = rigs[model]
	if not rig then
		local measured = measure(model)
		if not measured then
			return
		end
		rig = measured
		rigs[model] = measured
	end
	if rig.Clip ~= clip then
		rig.Clip = clip
		rig.ClipStart = clock
	end
end

local function clipOf(model: Model): (string?, number)
	local rig = rigs[model]
	if not rig then
		return nil, 0
	end
	return rig.Clip, clock - rig.ClipStart
end

-- The scene -----------------------------------------------------------------------------------------------------------

local ROBLOX: { [string]: string } = {
	Idle = "rbxassetid://507766388",
	Run = "rbxassetid://507767714",
	Point = "rbxassetid://507770453",
	Laugh = "rbxassetid://507770818",
	Sit = "rbxassetid://2506281703",
}
local GOD_SPEED = 19.2 -- Pan's chase speed (Economy.GodSpeed(1))
local GOD_TURN = math.rad(110) -- how fast a gliding god turns, a second
local RUN_STUDS = 12.8 * 1.65 -- GodController: the speed Roblox's run matches at 1x on a god

type Scene = {
	Folder: Folder,
	God: Model,
	GodHip: number,
	Tracks: { [Model]: { [string]: AnimationTrack } },
	Playing: { [Model]: string? },
	Hidden: { { Instance: Instance, Parent: Instance } },
	Started: number,
	Update: (t: number, dt: number) -> boolean,
}

local scene: Scene? = nil
local player = Players.LocalPlayer

local function track(model: Model, name: string): AnimationTrack?
	local current = scene
	if not current then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local list = current.Tracks[model] or {}
	current.Tracks[model] = list
	if not list[name] then
		local animation = Instance.new("Animation")
		animation.AnimationId = ROBLOX[name]
		local loaded = animator:LoadAnimation(animation)
		loaded.Looped = name ~= "Point"
		loaded.Priority = if name == "Sit" then Enum.AnimationPriority.Action else Enum.AnimationPriority.Movement
		list[name] = loaded
	end
	return list[name]
end

-- One of Roblox's own clips on a model (nil stops it), at `speed` times the scene's clock.
local function roblox(model: Model, name: string?, speed: number?)
	local current = scene
	if not current then
		return
	end
	local playing = current.Playing[model]
	if playing ~= name then
		if playing then
			local old = track(model, playing)
			if old then
				old:Stop(0.2)
			end
		end
		if name then
			local new = track(model, name)
			if new then
				new:Play(0.2)
			end
		end
		current.Playing[model] = name
	end
	if name then
		local now = track(model, name)
		if now then
			now:AdjustSpeed((speed or 1) * Mock.TimeScale)
		end
	end
end

-- The ground under the actors, seen through every character, sheep, god and plant, as GodService's sight lines are.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
-- The camera's view is blocked by trees too, only the actors aren't in its way.
local viewParams = RaycastParams.new()
viewParams.FilterType = Enum.RaycastFilterType.Exclude
local function floorAt(x: number, z: number): number
	return Mountain.Floor(x, z, groundParams)
end

local function excludeActors(folder: Folder)
	local list: { Instance } = { folder }
	for _, name in { "Gods", "WildSheep", "CarriedSheep", "PenSheep" } do
		local found = workspace:FindFirstChild(name)
		if found then
			table.insert(list, found)
		end
	end
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(list, other.Character)
		end
	end
	viewParams.FilterDescendantsInstances = table.clone(list)
	local base = workspace:FindFirstChild("Base")
	local foliage = base and base:FindFirstChild("Foliages")
	if foliage then
		table.insert(list, foliage)
	end
	groundParams.FilterDescendantsInstances = list
end

local function place(model: Model, hip: number, at: Vector3, facing: Vector3)
	local flat = Vector3.new(facing.X, 0, facing.Z)
	if flat.Magnitude < 1e-3 then
		flat = Mountain.Downhill
	end
	model:PivotTo(CFrame.lookAlong(Vector3.new(at.X, floorAt(at.X, at.Z) + hip, at.Z), flat.Unit))
end

local camEye: Vector3? = nil
local camLook: Vector3? = nil
local function camera(eye: Vector3, look: Vector3, dt: number, lag: number, fov: number?)
	local cam = workspace.CurrentCamera
	local share = if lag <= 0 then 1 else 1 - math.exp(-dt / lag)
	local nextEye = if camEye then camEye:Lerp(eye, share) else eye
	local nextLook = if camLook then camLook:Lerp(look, share) else look
	camEye, camLook = nextEye, nextLook
	-- Scenery between the subject and the camera (a tree's crown) pulls the camera in front of it.
	local shown = nextEye
	local hit = workspace:Raycast(nextLook, nextEye - nextLook, viewParams)
	if hit then
		shown = hit.Position + (nextLook - nextEye).Unit * 1.5
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = fov or 50
	cam.CFrame = CFrame.lookAt(shown, nextLook)
end

local function characterParts(): (Model?, BasePart?, number)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid then
		return nil, nil, 0
	end
	return character, root, humanoid.HipHeight + root.Size.Y / 2
end

-- A copy of a wild lamb in the character's raised hands, welded as SheepService.Carry does.
local function carryLamb(folder: Folder, character: Model, root: BasePart)
	local source: Model? = nil
	local wild = workspace:FindFirstChild("WildSheep")
	if wild then
		for _, lamb in wild:GetChildren() do
			if lamb:IsA("Model") and lamb:GetAttribute("Family") and lamb.PrimaryPart then
				source = lamb
				break
			end
		end
	end
	if not source then
		return
	end
	local lamb = source:Clone()
	for _, tag in CollectionService:GetTags(lamb) do
		CollectionService:RemoveTag(lamb, tag)
	end
	for _, item in lamb:GetDescendants() do
		if item:IsA("ProximityPrompt") or item:IsA("BillboardGui") then
			item:Destroy()
		end
	end
	local family = lamb:GetAttribute("Family") :: string
	local base = GameConfig.Breeds[family]
	local lambRoot = lamb.PrimaryPart :: BasePart
	if not base then
		lamb:Destroy()
		return
	end
	player:SetAttribute("CarriedFamily", family)
	player:SetAttribute("CarriedScale", lamb:GetScale())
	player:SetAttribute("Carrying", true)
	local breed = table.clone(base)
	breed.Scale = lamb:GetScale() * GameConfig.SheepSize
	local holder, at = CarryPose.HoldSpot(character, root, breed)
	for _, part in lamb:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			part.CanCollide = false
		end
	end
	local joint = Instance.new("Weld")
	joint.Part0 = holder
	joint.Part1 = lambRoot
	joint.C0 = at * lambRoot.PivotOffset:Inverse()
	joint.Parent = lambRoot
	lamb:PivotTo(holder.CFrame * at)
	lamb.Parent = folder
end

local function newScene(godName: string): Scene?
	Mock.Clear()
	local character, root = characterParts()
	local gods = workspace:FindFirstChild("Gods")
	local source = gods and gods:FindFirstChild(godName)
	if not character or not root or not source or not source:IsA("Model") then
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = "TEMP_SlideMockup"
	folder.Parent = workspace
	excludeActors(folder)
	local god = source:Clone()
	god.Name = "TEMP_" .. godName
	for _, item in god:GetDescendants() do
		if item:IsA("AlignPosition") or item:IsA("AlignOrientation") then
			item:Destroy()
		elseif item:IsA("BillboardGui") then
			item.Enabled = false
		end
	end
	local godRoot = god.PrimaryPart :: BasePart
	godRoot.Anchored = true
	local humanoid = god:FindFirstChildOfClass("Humanoid") :: Humanoid
	god.Parent = folder
	local made: Scene = {
		Folder = folder,
		God = god,
		GodHip = humanoid.HipHeight + godRoot.Size.Y / 2,
		Tracks = {},
		Playing = {},
		Hidden = {},
		Started = clock,
		Update = function()
			return false
		end,
	}
	scene = made
	-- The real god stays at home on the server; on this device it's out of the picture while the copy acts.
	table.insert(made.Hidden, { Instance = source, Parent = source.Parent :: Instance })
	source.Parent = nil
	root.Anchored = true
	carryLamb(folder, character, root)
	-- Filmed slowed down, the grazing lambs would play at full speed: they're out of the picture too.
	local wildFolder = workspace:FindFirstChild("WildSheep")
	if wildFolder and Mock.TimeScale < 1 then
		table.insert(made.Hidden, { Instance = wildFolder, Parent = workspace })
		wildFolder.Parent = nil
	end
	for _, gui in player.PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Enabled then
			gui.Enabled = false
			gui:SetAttribute("TEMP_Hidden", true)
		end
	end
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	game:GetService("ProximityPromptService").Enabled = false
	-- The wild lambs' theft cards would crowd the picture.
	local wild = workspace:FindFirstChild("WildSheep")
	if wild then
		for _, card in wild:GetDescendants() do
			if card:IsA("BillboardGui") and card.Enabled then
				card.Enabled = false
				card:SetAttribute("TEMP_Hidden", true)
			end
		end
	end
	camEye, camLook = nil, nil
	return made
end

-- The thief's slide: from `from` downhill at a speed rising to `speed` over `rise` seconds, weaving across the lane.
local function slidePath(from: Vector3, speed: number, weave: number, rise: number): (number) -> (Vector3, Vector3)
	return function(t: number): (Vector3, Vector3)
		local travelled = if t < rise then 0.5 * speed / rise * t * t else speed * (t - rise / 2)
		local x = from.X - travelled
		local z = from.Z + weave * math.sin(t * 1.1)
		local dz = weave * 1.1 * math.cos(t * 1.1)
		local v = if t < rise then speed * t / rise else speed
		return Vector3.new(x, 0, z), Vector3.new(-math.max(v, 1), 0, dz * math.min(1, t / rise))
	end
end

local function steer(facing: Vector3, wanted: Vector3, dt: number): Vector3
	local a = math.atan2(-facing.X, -facing.Z)
	local b = math.atan2(-wanted.X, -wanted.Z)
	local delta = (b - a + math.pi) % TAU - math.pi
	local turned = a + math.clamp(delta, -GOD_TURN * dt, GOD_TURN * dt)
	return Vector3.new(-math.sin(turned), 0, -math.cos(turned))
end

local function follow(focus: Vector3, offset: Vector3, lookUp: number, dt: number, t: number, lag: number, fov: number?)
	local y = floorAt(focus.X, focus.Z)
	camera(
		Vector3.new(focus.X, y, focus.Z) + offset,
		Vector3.new(focus.X, y + lookUp, focus.Z),
		dt,
		if t < 0.05 then 0 else lag,
		fov
	)
end

local SHOTS: { [string]: (made: Scene) -> () } = {}

-- As the game is now: Roblox's sit for the slide, Roblox's run for the chase.
SHOTS.Now = function(made: Scene)
	local character, _, hip = characterParts()
	local path = slidePath(Vector3.new(500, 0, 196), 16, 4, 0.6)
	local godAt = Vector3.new(512, 0, 200)
	local facing = Mountain.Downhill
	made.Update = function(t: number, dt: number): boolean
		if not character then
			return false
		end
		local at, heading = path(t)
		place(character, hip, at, heading)
		roblox(character, "Sit")
		facing = steer(facing, at - godAt, dt)
		if t > 0.6 then
			godAt += facing * GOD_SPEED * dt
			roblox(made.God, "Run", GOD_SPEED / RUN_STUDS)
		else
			roblox(made.God, "Point")
		end
		place(made.God, made.GodHip, godAt, facing)
		follow(at:Lerp(godAt, 0.45), Vector3.new(-24, 15, -25), 2.5, dt, t, 0.45, 42)
		return t < 4.5
	end
end

-- The new chase: the god points, lunges face first, glides on its belly steering after the thief, catches them
-- (they fly off, as a god's punch throws them), gets up and laughs.
SHOTS.Chase = function(made: Scene)
	local character, _, hip = characterParts()
	local path = slidePath(Vector3.new(500, 0, 196), 14, 5, 0.8)
	local godAt = Vector3.new(512, 0, 200)
	local facing = (Vector3.new(500, 0, 196) - godAt).Unit
	local caughtAt: number? = nil
	local thiefAt = Vector3.zero
	local thiefHeading = Mountain.Downhill
	made.Update = function(t: number, dt: number): boolean
		if not character then
			return false
		end
		local god = made.God
		if not caughtAt then
			thiefAt, thiefHeading = path(t)
			place(character, hip, thiefAt, thiefHeading)
			roblox(character, "Sit")
		else
			-- Punched: a high arc down the mountain, tumbling, as MovementController flies a caught thief.
			local share = math.clamp((t - caughtAt) / 1.6, 0, 1)
			local at = thiefAt:Lerp(thiefAt + Vector3.new(-70, 0, 6), share)
			local height = floorAt(at.X, at.Z) + hip + 4 * share * (1 - share) * 22
			character:PivotTo(
				CFrame.lookAlong(Vector3.new(at.X, height, at.Z), Mountain.Downhill)
					* CFrame.Angles(-share * math.pi * 4, 0, 0)
			)
		end
		local reach = thiefAt - godAt
		if t < 1.5 then
			facing = steer(facing, reach, dt)
			roblox(god, "Point")
		elseif not caughtAt then
			local clip, age = clipOf(god)
			if clip ~= "Lunge" and clip ~= "Belly" then
				Mock.Play(god, "Lunge")
				clip, age = "Lunge", 0
			elseif clip == "Lunge" and age >= LENGTHS.Lunge then
				Mock.Play(god, "Belly")
			end
			roblox(god, "Idle")
			facing = steer(facing, reach, dt)
			-- The dive carries the god forward a little faster than its glide.
			local burst = if clip == "Lunge" and age > 0.2 and age < 0.56 then 1.6 else 1
			godAt += facing * GOD_SPEED * burst * dt
			if Vector2.new(reach.X, reach.Z).Magnitude < 4.5 then
				caughtAt = t
				Mock.Play(god, "GetUp")
			end
		elseif t - (caughtAt :: number) > LENGTHS.GetUp then
			Mock.Play(god, nil)
			roblox(god, "Laugh", 1.4)
		end
		place(god, made.GodHip, godAt, facing)
		local focus = if caughtAt then godAt else thiefAt:Lerp(godAt, 0.45)
		follow(focus, Vector3.new(-24, 15, -25), 2.5, dt, t, 0.45, 42)
		return t < (if caughtAt then caughtAt + 2.6 else 12)
	end
end

-- A player's slide pose, close up from the front, the god gliding on its belly behind.
local function poseShot(variant: string): (made: Scene) -> ()
	return function(made: Scene)
		local character, _, hip = characterParts()
		local path = slidePath(Vector3.new(502, 0, 194), 17, 4, 0.7)
		local godAt = Vector3.new(518, 0, 194)
		local facing = Mountain.Downhill
		made.Update = function(t: number, dt: number): boolean
			if not character then
				return false
			end
			local at, heading = path(t)
			place(character, hip, at, heading)
			if variant == "Penguin" then
				Mock.Play(character, if t < LENGTHS.Flop then "Flop" else "Belly")
			else
				Mock.Play(character, variant)
			end
			local god = made.God
			facing = steer(facing, at - godAt, dt)
			godAt = godAt:Lerp(at + Vector3.new(16, 0, 2 * math.sin(t * 0.9)), math.clamp(dt * 2, 0, 1))
			Mock.Play(god, "Belly")
			roblox(god, "Idle")
			place(god, made.GodHip, godAt, facing)
			follow(at + Vector3.new(2, 0, 0), Vector3.new(-14, 5, -12), 1.5, dt, t, 0.06, 50)
			return t < 4.5
		end
	end
end
SHOTS.Penguin = poseShot("Penguin")
SHOTS.Surf = poseShot("Surf")
SHOTS.Sled = poseShot("Sled")

Mock.Done = false

local function step(realDt: number)
	clock += realDt * Mock.TimeScale
	local current = scene
	if not current then
		return
	end
	local character = player.Character
	local rig = character and rigs[character]
	if rig then
		rig.KeepArms = player:GetAttribute("Carrying") == true
	end
	if not current.Update(clock - current.Started, realDt * Mock.TimeScale) then
		current.Update = function()
			return true
		end
		Mock.Done = true
	end
end

-- Plays a shot from its start; Mock.Done turns true when it ends, holding its last frame.
function Mock.Shot(name: string, godName: string?): boolean
	local made = newScene(godName or "Pan")
	if not made then
		return false
	end
	Mock.Done = false
	SHOTS[name](made)
	if #connections == 0 then
		table.insert(connections, RunService.RenderStepped:Connect(step))
		-- After CarryController (connected first) has posed the arms, and put back before its own restore runs.
		table.insert(connections, RunService.PreSimulation:Connect(apply))
		table.insert(connections, RunService.PostSimulation:Connect(restore))
	end
	return true
end

-- Ends the shot: the copies go, the real god comes back, the character moves again.
function Mock.Clear()
	local current = scene
	scene = nil
	table.clear(rigs)
	restore()
	if current then
		for _, list in current.Tracks do
			for _, loaded in list do
				loaded:Stop(0)
			end
		end
		for _, hidden in current.Hidden do
			hidden.Instance.Parent = hidden.Parent
		end
		current.Folder:Destroy()
	end
	local _, root = characterParts()
	if root then
		root.Anchored = false
	end
	player:SetAttribute("Carrying", nil)
	player:SetAttribute("CarriedFamily", nil)
	player:SetAttribute("CarriedScale", nil)
end

function Mock.Stop()
	Mock.Clear()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, gui in player.PlayerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui:GetAttribute("TEMP_Hidden") then
			gui.Enabled = true
			gui:SetAttribute("TEMP_Hidden", nil)
		end
	end
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	game:GetService("ProximityPromptService").Enabled = true
	for _, card in workspace:GetDescendants() do
		if card:IsA("BillboardGui") and card:GetAttribute("TEMP_Hidden") then
			card.Enabled = true
			card:SetAttribute("TEMP_Hidden", nil)
		end
	end
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

return Mock
