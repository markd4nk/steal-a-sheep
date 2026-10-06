--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarryPose = require(ReplicatedStorage.Utils.CarryPose)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)

-- Whole-body motion for R15 characters as pure functions of time, played on every device over what the Animator
-- played, as SheepClips is for the sheep: a god's lunge, belly glide and getting up (GodController) and a player
-- surfing down the slope (SlideController). The user picked them from mock-ups on 2026-10-06 (studio/SlideMockup).
--
-- Joints go by name (Root, Waist, Neck, LeftShoulder ... RightAnkle). +X tips a part forward and up (a leg swings
-- forward, the head looks up, a knee folds the other way), Y turns, Z rolls the right side up. Root's transform is in
-- the HumanoidRootPart's frame at the hips: lying flat is Root tipped -90 degrees and lowered until the chest meets
-- the floor. Ground then turns the whole pose to the ramp's slope round the point under the hips, and leans it into
-- turns.
local BodyClips = {}

export type Pose = { [string]: CFrame } -- joint name -> transform; joints left out go back to their rest

export type ArmRest = {
	Turn: CFrame, -- the shoulder's C0 rotation, which a Transform is measured against
	Down: Vector3, -- the upper arm's direction at rest in the torso's space (straight down on blocky avatars)
}

export type Body = {
	Joint: number, -- the Root joint's height over the floor, standing
	Belly: number, -- from the Root joint's axis to the chest's front
	Arms: { Left: ArmRest, Right: ArmRest },
}

export type Rig = {
	Model: Model,
	Root: BasePart,
	Joints: { [string]: CarryPose.Joint },
	Body: Body,
	Tilt: CFrame, -- the slope turn, eased
	Lean: number, -- degrees into the turn, eased
	Yaw: number?, -- the root's heading last frame
}

export type ClipName = string -- "Lunge", "Belly", "GetUp" or "Surf"

local Lunge = GameConfig.Theft.Lunge

BodyClips.LungeSeconds = Lunge.Seconds
BodyClips.GetUpSeconds = 0.62

-- Each joint by the parts it joins.
local JOINTS: { [string]: { string } } = {
	Root = { "HumanoidRootPart", "LowerTorso" },
	Waist = { "LowerTorso", "UpperTorso" },
	Neck = { "UpperTorso", "Head" },
	LeftShoulder = { "UpperTorso", "LeftUpperArm" },
	RightShoulder = { "UpperTorso", "RightUpperArm" },
	LeftElbow = { "LeftUpperArm", "LeftLowerArm" },
	RightElbow = { "RightUpperArm", "RightLowerArm" },
	LeftWrist = { "LeftLowerArm", "LeftHand" },
	RightWrist = { "RightLowerArm", "RightHand" },
	LeftHip = { "LowerTorso", "LeftUpperLeg" },
	RightHip = { "LowerTorso", "RightUpperLeg" },
	LeftKnee = { "LeftUpperLeg", "LeftLowerLeg" },
	RightKnee = { "RightUpperLeg", "RightLowerLeg" },
	LeftAnkle = { "LeftLowerLeg", "LeftFoot" },
	RightAnkle = { "RightLowerLeg", "RightFoot" },
}

-- The joints CarryController holds a lamb up with: a carrier's pose leaves them to it.
BodyClips.HoldJoints = table.freeze({
	LeftShoulder = true,
	RightShoulder = true,
	LeftElbow = true,
	RightElbow = true,
	LeftWrist = true,
	RightWrist = true,
	Waist = true,
}) :: { [string]: boolean }

local rad = math.rad
local TAU = 2 * math.pi

local function tip(degrees: number): CFrame
	return CFrame.Angles(rad(degrees), 0, 0)
end

local function turn(degrees: number): CFrame
	return CFrame.Angles(0, rad(degrees), 0)
end

local function roll(degrees: number): CFrame
	return CFrame.Angles(0, 0, rad(degrees))
end

local function smooth(x: number): number
	local t = math.clamp(x, 0, 1)
	return t * t * (3 - 2 * t)
end

-- Both arms: forward swing, outward spread, elbow bend (blocky arms, hanging at rest: the gods').
local function arms(pose: Pose, swing: number, spread: number, elbow: number)
	pose.LeftShoulder = tip(swing) * roll(-spread)
	pose.RightShoulder = tip(swing) * roll(spread)
	pose.LeftElbow = tip(elbow)
	pose.RightElbow = tip(elbow)
end

-- Both legs: forward swing, outward spread, knee (negative folds the shin back), ankle.
local function legs(pose: Pose, swing: number, spread: number, knee: number, ankle: number)
	pose.LeftHip = tip(swing) * roll(-spread)
	pose.RightHip = tip(swing) * roll(spread)
	pose.LeftKnee = tip(knee)
	pose.RightKnee = tip(knee)
	pose.LeftAnkle = tip(ankle)
	pose.RightAnkle = tip(ankle)
end

-- An upper arm pointed along `direction` (torso space) whatever its rest pose: blocky arms hang down, some skinned
-- avatars rest in a T-pose (BRAIN characters.md).
local function aim(rest: ArmRest, direction: Vector3): CFrame
	return CarryPose.Transform(rest.Turn, CFrame.fromRotationBetweenVectors(rest.Down, direction.Unit))
end

local function lying(body: Body, lift: number, pitch: number): CFrame
	return CFrame.new(0, -(body.Joint - body.Belly) + lift, 0) * tip(-90 + pitch)
end

-- On the belly like a penguin: chest and head up, flippers back and flapping, feet up behind and kicking.
local function belly(t: number, body: Body, pose: Pose)
	local wave = math.sin(t * TAU / 0.9)
	local flap = math.sin(t * TAU * 2 / 0.9)
	pose.Root = lying(body, 0.04 * body.Joint * math.abs(wave), 0) * turn(3 * wave)
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

local function stand(_body: Body, _pose: Pose) end

local function crouch(body: Body, pose: Pose)
	pose.Root = CFrame.new(0, -0.14 * body.Joint, 0) * tip(-26)
	pose.Waist = tip(-10)
	pose.Neck = tip(32)
	arms(pose, -55, 18, 25)
	legs(pose, 62, 4, -88, 28)
end

-- Airborne, face first, arms swept back.
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

type Key = { At: number, Fill: (body: Body, pose: Pose) -> () }

local KEYED: { [string]: { Key } } = {
	-- A crouch, the dive (DiveFrom to DiveTo, when GodService carries the god faster), a belly flop and a bounce.
	Lunge = {
		{ At = 0, Fill = stand },
		{ At = Lunge.DiveFrom, Fill = crouch },
		{ At = Lunge.DiveFrom + (Lunge.DiveTo - Lunge.DiveFrom) * 0.65, Fill = dive },
		{ At = Lunge.DiveTo, Fill = contact },
		{ At = Lunge.DiveTo + (Lunge.Seconds - Lunge.DiveTo) * 0.43, Fill = bounce },
		{ At = Lunge.Seconds, Fill = settled },
	},
	GetUp = {
		{ At = 0, Fill = settled },
		{ At = 0.24, Fill = push },
		{ At = 0.46, Fill = rise },
		{ At = BodyClips.GetUpSeconds, Fill = stand },
	},
}

local function keyed(name: string, t: number, body: Body, pose: Pose)
	local keys = KEYED[name]
	if not keys then
		return
	end
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
				local x, y = from[joint], to[joint]
				if x or y then
					pose[joint] = (x or CFrame.identity):Lerp(y or CFrame.identity, share)
				end
			end
			return
		end
	end
end

-- Surfing down without a board: side on, left shoulder first, knees bent, looking downhill, carving. Empty-handed,
-- the arms are out for balance.
local function surf(t: number, body: Body, pose: Pose)
	local carve = math.sin(t * TAU / 1.8)
	local bob = math.sin(t * TAU / 0.6)
	pose.Root = CFrame.new(0, -0.27 * body.Joint + 0.025 * body.Joint * bob, 0)
		* turn(-78)
		* roll(-8 * carve)
		* tip(-10)
	pose.Waist = turn(18) * tip(-6)
	pose.Neck = turn(52) * tip(4)
	pose.LeftShoulder = aim(body.Arms.Left, Vector3.new(-1, -0.3 - 0.12 * carve, -0.15))
	pose.RightShoulder = aim(body.Arms.Right, Vector3.new(1, -0.45 + 0.12 * carve, 0.25))
	pose.LeftElbow = tip(10)
	pose.RightElbow = tip(16)
	pose.LeftHip = tip(44) * roll(-28)
	pose.RightHip = tip(38) * roll(26)
	pose.LeftKnee = tip(-74)
	pose.RightKnee = tip(-66)
	pose.LeftAnkle = tip(30) * roll(24)
	pose.RightAnkle = tip(28) * roll(-22)
end

-- How much of the ramp's slope a clip leans into: lying follows the floor, a stance stays near upright.
local TILT: { [string]: number } = { Lunge = 1, Belly = 1, GetUp = 1, Surf = 0.35 }

-- The clip's pose `t` seconds in (the belly glide and the surf loop).
function BodyClips.Sample(clip: ClipName, t: number, body: Body): Pose
	local pose: Pose = {}
	if clip == "Belly" then
		belly(t, body, pose)
	elseif clip == "Surf" then
		surf(t, body, pose)
	else
		keyed(clip, t, body, pose)
	end
	return pose
end

local function jointsOf(model: Model): { CarryPose.Joint }
	local found: { CarryPose.Joint } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("AnimationConstraint") and descendant.Enabled then
			table.insert(found, 1, descendant)
		elseif descendant:IsA("Motor6D") and descendant.Enabled then
			table.insert(found, descendant)
		end
	end
	return found
end

local function armRest(joints: { [string]: CarryPose.Joint }, shoulder: string, elbow: string): ArmRest?
	local upper, lower = joints[shoulder], joints[elbow]
	if not upper or not lower then
		return nil
	end
	local c0, c1 = CarryPose.JointFrames(upper)
	local elbowC0 = CarryPose.JointFrames(lower)
	local down = (c0 * c1:Inverse() * elbowC0).Position - c0.Position
	return {
		Turn = c0.Rotation,
		Down = if down.Magnitude > 1e-3 then down.Unit else Vector3.new(0, -1, 0),
	}
end

-- Reads an R15 character or avatar god as it stands at rest; nil without a full R15 body (R6, a block figure).
function BodyClips.Measure(model: Model): Rig?
	local root = model:FindFirstChild("HumanoidRootPart")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not root or not root:IsA("BasePart") or not humanoid then
		return nil
	end
	local all = jointsOf(model)
	local joints: { [string]: CarryPose.Joint } = {}
	for name, parts in JOINTS do
		local from, to = model:FindFirstChild(parts[1]), model:FindFirstChild(parts[2])
		for _, joint in all do
			local _, _, part0, part1 = CarryPose.JointFrames(joint)
			if from and part0 == from and part1 == to then
				joints[name] = joint
				break
			end
		end
		if not joints[name] then
			return nil
		end
	end
	local left = armRest(joints, "LeftShoulder", "LeftElbow")
	local right = armRest(joints, "RightShoulder", "RightElbow")
	local upper = model:FindFirstChild("UpperTorso")
	local lower = model:FindFirstChild("LowerTorso")
	if not left or not right or not upper or not upper:IsA("BasePart") or not lower or not lower:IsA("BasePart") then
		return nil
	end
	local rootC0 = CarryPose.JointFrames(joints.Root)
	return {
		Model = model,
		Root = root,
		Joints = joints,
		Body = {
			Joint = humanoid.HipHeight + root.Size.Y / 2 + rootC0.Position.Y,
			Belly = math.max(upper.Size.Z, lower.Size.Z) / 2 + 0.05,
			Arms = { Left = left, Right = right },
		},
		Tilt = CFrame.identity,
		Lean = 0,
		Yaw = nil,
	}
end

-- The turn that lays a clip's pose on the ramp's slope under the rig (round the point under its hips) and leans it
-- into the turn it's making, eased over frames.
function BodyClips.Ground(rig: Rig, clip: ClipName, dt: number): CFrame
	local frame = rig.Root.CFrame
	local normal = Vector3.yAxis
	if Mountain.IsOnRamp(frame.Position) then
		normal = Vector3.new(-Mountain.RampSlope(frame.Position.X), 1, 0).Unit
	end
	local share = TILT[clip] or 0
	local slope = frame:VectorToObjectSpace(normal)
	local target = CFrame.fromRotationBetweenVectors(Vector3.yAxis, Vector3.yAxis:Lerp(slope, share).Unit)
	rig.Tilt = rig.Tilt:Lerp(target, math.clamp(dt * 10, 0, 1))
	local look = frame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local rate = 0
	local last = rig.Yaw
	if last and dt > 0 then
		rate = ((yaw - last + math.pi) % TAU - math.pi) / dt
	end
	rig.Yaw = yaw
	rig.Lean += (math.clamp(math.deg(rate) * 0.25, -22, 22) - rig.Lean) * math.clamp(dt * 6, 0, 1)
	local under = CFrame.new(0, -rig.Body.Joint, 0)
	return under * rig.Tilt * roll(-rig.Lean) * under:Inverse()
end

-- Blends `pose` over the Animator's by `weight` on every joint not in `skip`, noting each joint and what it held so
-- `Restore` can put it back after the frame's physics (BRAIN characters.md, Posing arms from code).
function BodyClips.Apply(
	rig: Rig,
	pose: Pose,
	weight: number,
	skip: { [string]: boolean }?,
	touched: { CarryPose.Joint },
	befores: { CFrame }
)
	for name, joint in rig.Joints do
		if skip and skip[name] then
			continue
		end
		local before = if joint:IsA("Motor6D") then joint.Transform else (joint :: AnimationConstraint).Transform
		table.insert(touched, joint)
		table.insert(befores, before)
		CarryPose.SetTransform(joint, before:Lerp(pose[name] or CFrame.identity, weight))
	end
end

function BodyClips.Restore(touched: { CarryPose.Joint }, befores: { CFrame })
	for index, joint in touched do
		CarryPose.SetTransform(joint, befores[index])
	end
	table.clear(touched)
	table.clear(befores)
end

-- A rig's joints are still the ones measured (a respawn or a rebuilt avatar makes new ones).
function BodyClips.Intact(rig: Rig): boolean
	if not rig.Model.Parent or not rig.Root.Parent then
		return false
	end
	for _, joint in rig.Joints do
		if not joint.Parent then
			return false
		end
	end
	return true
end

return table.freeze(BodyClips)
