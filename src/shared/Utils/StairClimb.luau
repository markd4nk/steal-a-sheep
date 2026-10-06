--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

-- The stair walker's moving stairs and the climb on them, shared by the server (which builds the machine and places
-- the climber) and every client (which runs the steps and poses the climber). Machine space: origin on the floor under
-- the climber, -Z forward up the stairs, +X to the climber's right, in studs.
--
-- The climber's root is anchored. Each frame after the Animator, a two-bone IK in each leg's plane bends hip and knee
-- so the foot on a step rides it down and back while the other lifts onto the next step; the ankle keeps the foot
-- level. Lengths come from the avatar's own joints, so feet land on the steps for any R15 avatar. R6 legs just swing.
local StairClimb = {}

StairClimb.Width = 3 -- of a tread
StairClimb.Rise = 0.6
StairClimb.Run = 1
StairClimb.Steps = 8
-- The steps on show, in steps from the climber's lower foot; the rest are inside the machine.
StairClimb.Lowest = -1.9
StairClimb.Highest = 3.5

StairClimb.StepSizes = table.freeze({
	Tread = Vector3.new(StairClimb.Width, 0.18, StairClimb.Run),
	Nose = Vector3.new(StairClimb.Width + 0.02, 0.2, 0.16),
	Riser = Vector3.new(StairClimb.Width - 0.04, StairClimb.Rise, 0.12),
})

local TREAD_TOP = 2 -- the lower foot's tread: its top above the floor
local TREAD_BACK = 1.2 -- and its middle behind the origin
local LEAN = math.rad(-8)
local REACH = 0.96 -- of the leg's length, at the bottom of a stride
local LIFT = 0.32 -- how much higher than its path the swinging foot goes
local TOE = math.rad(-30)
local BOB = 0.05
local R6_SWING = math.rad(32)

type Joint = { Instance: any, C0: CFrame, C1: CFrame }
type Leg = { Hip: Joint, Knee: Joint, Ankle: Joint, Thigh: Vector3, Shin: Vector3, Sole: Vector3 }
type Arm = { Shoulder: Joint, Elbow: Joint, Wrist: Joint, Upper: Vector3, Fore: Vector3, Side: number }
export type Rig = {
	Kind: "R15" | "R6",
	Root: Joint?,
	Legs: { Leg },
	Arms: { Arm },
	Swing: { Joint }, -- R6 hips
	Shift: number, -- the sole's middle behind its tread's middle
	Offset: Vector3, -- the root, in machine space
}

local function joint(model: Model, partName: string, jointName: string): Joint?
	local part = model:FindFirstChild(partName)
	local found = part and part:FindFirstChild(jointName)
	if found and found:IsA("Motor6D") then
		return { Instance = found, C0 = found.C0, C1 = found.C1 }
	elseif found and found:IsA("AnimationConstraint") then
		-- The Avatar Joint Upgrade's joint: its attachments stand where a Motor6D's C0 and C1 would.
		local a0, a1 = found.Attachment0, found.Attachment1
		if a0 and a1 then
			return { Instance = found, C0 = a0.CFrame, C1 = a1.CFrame }
		end
	end
	return nil
end

-- The top middle of the tread `u` steps above the climber's lower foot.
function StairClimb.Tread(u: number): Vector3
	return Vector3.new(0, TREAD_TOP + u * StairClimb.Rise, TREAD_BACK - u * StairClimb.Run)
end

-- Seconds a step takes to come down one step, on a machine of this level (1 is the free one).
function StairClimb.StepSeconds(level: number): number
	local config = GameConfig.StairWalker
	return config.StepSeconds + config.StepRange * config.StepDecay ^ (math.max(level, 1) - 1)
end

-- Where step `index` (1 to Steps) is, in steps above the lower foot, `cycle` steps into the run.
function StairClimb.StepAt(index: number, cycle: number): number
	return (index - 1 - cycle % 1 - StairClimb.Lowest) % StairClimb.Steps + StairClimb.Lowest
end

function StairClimb.Shown(u: number): boolean
	return u <= StairClimb.Highest
end

-- A step's three parts at `u`, in machine space: the tread, its coloured nose and the riser under its back edge.
function StairClimb.StepParts(u: number): (CFrame, CFrame, CFrame)
	local top = CFrame.new(StairClimb.Tread(u))
	return top * CFrame.new(0, -0.09, 0),
		top * CFrame.new(0, -0.09, -StairClimb.Run / 2 + 0.08),
		top * CFrame.new(0, -StairClimb.Rise / 2, StairClimb.Run / 2 - 0.06)
end

-- Where a climber is put down when they step off, in world space: behind the entry, facing away from the machine.
function StairClimb.ExitAt(frame: CFrame): CFrame
	local at = frame:PointToWorldSpace(Vector3.new(0, 3.2, StairClimb.Tread(StairClimb.Lowest - 0.6).Z + 4.6))
	return CFrame.lookAt(at, at - frame.LookVector)
end

-- The character's joints and where its root goes. Nil if it has neither an R15 nor an R6 body.
function StairClimb.Rig(character: Model): Rig?
	local root = joint(character, "LowerTorso", "Root")
	if root then
		local legs: { Leg } = {}
		local arms: { Arm } = {}
		for _, side in { "Left", "Right" } do
			local hip = joint(character, side .. "UpperLeg", side .. "Hip")
			local knee = joint(character, side .. "LowerLeg", side .. "Knee")
			local ankle = joint(character, side .. "Foot", side .. "Ankle")
			local foot = character:FindFirstChild(side .. "Foot")
			if not hip or not knee or not ankle or not foot or not foot:IsA("BasePart") then
				return nil
			end
			table.insert(legs, {
				Hip = hip,
				Knee = knee,
				Ankle = ankle,
				Thigh = (hip.C1:Inverse() * knee.C0).Position,
				Shin = (knee.C1:Inverse() * ankle.C0).Position,
				-- The middle of the sole, from the ankle, with the foot level.
				Sole = ankle.C1:Inverse().Position - Vector3.new(0, foot.Size.Y / 2, 0),
			})
			local shoulder = joint(character, side .. "UpperArm", side .. "Shoulder")
			local elbow = joint(character, side .. "LowerArm", side .. "Elbow")
			local wrist = joint(character, side .. "Hand", side .. "Wrist")
			if shoulder and elbow and wrist then
				table.insert(arms, {
					Shoulder = shoulder,
					Elbow = elbow,
					Wrist = wrist,
					Upper = (shoulder.C1:Inverse() * elbow.C0).Position,
					Fore = (elbow.C1:Inverse() * wrist.C0).Position,
					Side = if side == "Left" then -1 else 1,
				})
			end
		end
		local leg = legs[1]
		local foot = character:FindFirstChild("LeftFoot") :: BasePart
		local shift = -StairClimb.Run / 2 + foot.Size.Z / 2 + 0.05 -- toes at the tread's front edge
		local hip = (root.C0 * root.C1:Inverse() * leg.Hip.C0).Position
		local reach = REACH * (leg.Thigh.Magnitude + leg.Shin.Magnitude)
		local behind = 0.1
		local ankle = Vector3.new(0, hip.Y - math.sqrt(reach * reach - behind * behind), hip.Z + behind)
		local sole = StairClimb.Tread(0) + Vector3.new(0, 0, shift)
		local bottom = ankle + leg.Sole
		return {
			Kind = "R15",
			Root = root,
			Legs = legs,
			Arms = arms,
			Swing = {},
			Shift = shift,
			Offset = Vector3.new(0, sole.Y - bottom.Y, sole.Z - bottom.Z),
		}
	end
	local left = joint(character, "Torso", "Left Hip")
	local right = joint(character, "Torso", "Right Hip")
	if left and right then
		return {
			Kind = "R6",
			Root = nil,
			Legs = {},
			Arms = {},
			Swing = { left, right },
			Shift = 0,
			-- Hips 2 studs above the soles, the root's middle 1 above them.
			Offset = StairClimb.Tread(0.5) + Vector3.new(0, 3, 0.2),
		}
	end
	return nil
end

local function angle(y: number, z: number): number
	return math.atan2(z, y)
end

local function smooth(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

-- The smallest turn taking direction `from` onto `to`.
local function aim(from: Vector3, to: Vector3): CFrame
	local a, b = from.Unit, to.Unit
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-5 then
		return CFrame.identity
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(a:Dot(b), -1, 1)))
end

-- Bends hip and knee so the ankle reaches `target` (in the hip joint's frame), knee forward; the ankle keeps the foot
-- level, tipped by `toe`.
local function reach(leg: Leg, target: Vector3, lean: number, toe: number)
	local a, b = leg.Thigh.Magnitude, leg.Shin.Magnitude
	local ty, tz = target.Y, target.Z
	local distance = math.clamp(math.sqrt(ty * ty + tz * tz), math.abs(a - b) + 0.01, a + b - 0.005)
	local toward = angle(ty, tz)
	local spread = math.acos(math.clamp((a * a + distance * distance - b * b) / (2 * a * distance), -1, 1))
	-- Of the two ways to bend, the one with the knee in front (-Z).
	local thigh = if math.sin(toward + spread) < math.sin(toward - spread) then toward + spread else toward - spread
	local hip = thigh - angle(leg.Thigh.Y, leg.Thigh.Z)
	local knee = angle(ty - a * math.cos(thigh), tz - a * math.sin(thigh)) - angle(leg.Shin.Y, leg.Shin.Z) - hip
	leg.Hip.Instance.Transform = CFrame.Angles(hip, 0, 0)
	leg.Knee.Instance.Transform = CFrame.Angles(knee, 0, 0)
	leg.Ankle.Instance.Transform = CFrame.Angles(-(lean + hip + knee) + toe, 0, 0)
end

-- Poses the climber `cycle` steps into the climb. Call after the Animator has run (PreSimulation).
function StairClimb.Pose(rig: Rig, cycle: number)
	local s = cycle % 1
	local planted = math.floor(cycle) % 2 + 1 -- the leg on a step this half of the stride
	if rig.Kind == "R6" then
		local swing = R6_SWING * math.cos(math.pi * cycle)
		for _, hip in rig.Swing do
			hip.Instance.Transform = CFrame.Angles(0, 0, swing)
		end
		return
	end
	local root = rig.Root :: Joint
	local body = CFrame.new(0, BOB * math.cos(2 * math.pi * s), 0) * CFrame.Angles(LEAN, 0, 0)
	root.Instance.Transform = body
	local torso = root.C0 * body * root.C1:Inverse()
	local function sole(u: number): Vector3
		return StairClimb.Tread(u) + Vector3.new(0, 0, rig.Shift) - rig.Offset
	end
	for index, leg in rig.Legs do
		local hipFrame = torso * leg.Hip.C0
		local at: Vector3
		local toe = 0
		if index == planted then
			at = sole(1 - s)
		else
			local from, to = sole(0), sole(1)
			at = Vector3.new(
				0,
				from.Y + (to.Y - from.Y) * smooth(s / 0.75) + LIFT * math.sin(math.pi * s),
				from.Z + (to.Z - from.Z) * smooth((s - 0.1) / 0.8)
			)
			toe = TOE * math.sin(math.pi * math.clamp(s / 0.6, 0, 1)) * (1 - s)
		end
		local ankle = Vector3.new(hipFrame.Position.X, at.Y - leg.Sole.Y, at.Z - leg.Sole.Z)
		reach(leg, hipFrame:PointToObjectSpace(ankle), LEAN, toe)
	end
	-- Arms forward over the rails, pumping a little with the steps.
	for index, arm in rig.Arms do
		local pump = math.sin(math.pi * (cycle + index - 1)) * 0.25
		local upper = aim(arm.Upper, Vector3.new(arm.Side * 0.22, -0.85, -0.35 - pump))
		arm.Shoulder.Instance.Transform = upper
		arm.Elbow.Instance.Transform = aim(arm.Fore, upper:VectorToObjectSpace(Vector3.new(arm.Side * 0.05, -0.15, -1)))
		arm.Wrist.Instance.Transform = CFrame.identity
	end
end

-- Hands the joints back to the Animator: a joint no animation keys would keep the last pose.
function StairClimb.Release(rig: Rig)
	local joints: { Joint } = table.clone(rig.Swing)
	if rig.Root then
		table.insert(joints, rig.Root)
	end
	for _, leg in rig.Legs do
		table.insert(joints, leg.Hip)
		table.insert(joints, leg.Knee)
		table.insert(joints, leg.Ankle)
	end
	for _, arm in rig.Arms do
		table.insert(joints, arm.Shoulder)
		table.insert(joints, arm.Elbow)
		table.insert(joints, arm.Wrist)
	end
	for _, each in joints do
		if each.Instance.Parent then
			each.Instance.Transform = CFrame.identity
		end
	end
end

return table.freeze(StairClimb)
