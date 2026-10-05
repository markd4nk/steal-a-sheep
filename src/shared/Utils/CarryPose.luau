--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreedBuilds = require(ReplicatedStorage.Config.BreedBuilds)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local SheepRigLayout = require(ReplicatedStorage.Config.SheepRigLayout)

-- How a player holds the sheep they carry home: both arms up like lifting a trophy, the sheep resting on the palms.
-- The server welds the sheep where this says the palms end up (MerchantService) and every client poses the arms to
-- match (CarryController), so both work it out from the same measurements: the character's own joints at rest, and
-- the breed's size. Everything is in the space of the torso the arms hang from (UpperTorso, or Torso on R6): +X is
-- the character's right, +Y up, -Z forward.
--
-- Angles are turns from the arms hanging at rest, in the parent part's axes: around X swings an arm forward and up
-- (180 is straight up) or bends an elbow, around Z leans it sideways.
export type Link = {
	C0: CFrame,
	C1: CFrame,
}

-- One arm, as measured: its joints from the shoulder out, the size of the part each one moves, and the palm (where
-- tools are gripped) in the hand's space.
export type Arm = {
	Links: { Link },
	Sizes: { Vector3 },
	Palm: Vector3,
	Side: number, -- 1 for the right arm, -1 for the left
}

-- The head is taken as a box with rounded top corners.
export type Shape = {
	Arms: { Arm }, -- right, then left
	HeadTop: number, -- above the torso's centre, at rest
	HeadBottom: number,
	HeadHalfWidth: number,
	HeadHalfDepth: number,
}

-- A character joint: a Motor6D, or on R15 characters with the Avatar Joint Upgrade (on by default since May 2026)
-- the AnimationConstraint that replaces it. Both pose through Transform, between the same two frames.
export type Joint = Motor6D | AnimationConstraint

-- A character ready to hold a sheep: its measured shape and the joints a client poses.
export type Body = {
	Torso: BasePart,
	Shape: Shape,
	Joints: { { Joint } }, -- each arm's joints, in the order of Shape.Arms and their links
	Waist: Joint?, -- R15 only: the lean and the sway
}

-- The underside of a sheep seen from the front: its lowest row of puffs, and the skin body above them, at the breed's
-- size. Heights are above the sheep's feet.
export type Fleece = {
	PuffX: number, -- how far either side of the middle the lowest puffs' centres are
	PuffY: number,
	HalfWidth: number, -- each of those puffs' half width
	Hang: number, -- how far each hangs below its centre
	BodyHalfWidth: number,
	BodyBottom: number,
}

export type Hold = {
	Rotations: { { CFrame } }, -- each arm's joint turns, in the order of Shape.Arms
	Palms: { Vector3 },
	Sheep: CFrame, -- where the sheep's feet's centre goes: its model pivot
}

-- Where to find an arm: its parts from the shoulder out and its grip attachment.
type ArmSpec = {
	Side: number,
	Parts: { string },
	Grip: string,
}

local Settings = GameConfig.Carry

local DEFAULT_HEAD_TOP = 2.5 -- studs from the root part's centre to the top of the head, when there's no Head
local STEPS = 16 -- halvings of the lean range when fitting the arms
local HEAD_SAMPLES = 16 -- points across the head's half width that the fleece must clear
local ALONG = { -0.5, -0.25, 0, 0.25, 0.5 } -- points along a part's inner face, and across a palm, as shares of it
local DEEP = { -0.5, 0, 0.5 } -- and through the inner face, front to back

local R15_ARMS: { ArmSpec } = {
	{ Side = 1, Parts = { "RightUpperArm", "RightLowerArm", "RightHand" }, Grip = "RightGripAttachment" },
	{ Side = -1, Parts = { "LeftUpperArm", "LeftLowerArm", "LeftHand" }, Grip = "LeftGripAttachment" },
}
-- R6 arms are one part each.
local R6_ARMS: { ArmSpec } = {
	{ Side = 1, Parts = { "Right Arm" }, Grip = "RightGripAttachment" },
	{ Side = -1, Parts = { "Left Arm" }, Grip = "LeftGripAttachment" },
}

local CarryPose = {}

local function bodyPiece(): SheepRigLayout.Piece
	for _, piece in SheepRigLayout.Pieces do
		if piece.Name == "Body" then
			return piece
		end
	end
	error("SheepRigLayout has no Body")
end

-- The size a breed is carried at: its roster size (before GameConfig.SheepSize), or GameConfig.Carry.ShrunkScale for
-- a big one. It grows into its own size as it lands (SheepService.Place).
function CarryPose.Scale(breed: GameConfig.Breed): number
	local roster = breed.Scale / GameConfig.SheepSize
	return if roster > Settings.ShrinkFrom then Settings.ShrunkScale else roster
end

-- The breed's underside as SheepService dresses it: the style's measured underside (a build's own, its lift in it),
-- its wool grown by WoolSize and pushed out from the body's middle (Looks.sizeWool), then the whole sheep scaled.
function CarryPose.Fleece(breed: GameConfig.Breed): Fleece
	local build = if breed.Build then BreedBuilds.Builds[breed.Build] else nil
	local under = (if build then SheepRigLayout.Undersides[`{breed.Build}Wool`] else nil)
		or SheepRigLayout.Undersides[breed.WoolStyle]
		or SheepRigLayout.Undersides.Puffs
	local lift = if build then build.Lift else 0
	-- Carried lying down, its underside is all wool: the rig's body box stands upright.
	local lying = build ~= nil and build.Carry ~= nil
	local body = bodyPiece()
	local middle = body.Pivot.Y
	local spread = 1 + (breed.WoolSize - 1) * GameConfig.Sheep.WoolSpread
	local scale = CarryPose.Scale(breed)
	return {
		PuffX = under.PuffX * spread * scale,
		PuffY = (middle + (under.PuffY - middle) * spread) * scale,
		HalfWidth = under.HalfWidth * breed.WoolSize * scale,
		Hang = under.Hang * breed.WoolSize * scale,
		BodyHalfWidth = body.Size.X / 2 * scale,
		BodyBottom = if lying then math.huge else (body.CFrame.Y - body.Size.Y / 2 + lift) * scale,
	}
end

-- A breed carried lying down (Build.Carry: the Humanoid, on its back): the middle it turns about, in its own space at
-- its carried size, and the turn. Nil for the rest.
function CarryPose.LyingTurn(breed: GameConfig.Breed): (Vector3?, CFrame)
	local build = if breed.Build then BreedBuilds.Builds[breed.Build] else nil
	local carry = if build then build.Carry else nil
	if not carry then
		return nil, CFrame.identity
	end
	return carry.Pivot * CarryPose.Scale(breed), CFrame.Angles(math.rad(carry.Tilt), 0, 0)
end

-- How a breed carried lying down turns from standing, in its own space at its carried size: about its middle, then
-- raised so its lowest point is where its feet were. Identity for the rest.
function CarryPose.Lying(breed: GameConfig.Breed): CFrame
	local middle, turn = CarryPose.LyingTurn(breed)
	local build = if breed.Build then BreedBuilds.Builds[breed.Build] else nil
	local carry = if build then build.Carry else nil
	if not middle or not carry then
		return CFrame.identity
	end
	return CFrame.new(0, -carry.Drop * CarryPose.Scale(breed), 0) * CFrame.new(middle) * turn * CFrame.new(-middle)
end

-- How far the fleece reaches either side of the sheep's middle.
function CarryPose.HalfWidth(fleece: Fleece): number
	return fleece.PuffX + fleece.HalfWidth
end

-- The height of the sheep's underside above its feet at `dx` studs from its middle. Past the fleece's edge it's the
-- height of its widest point: a palm out there holds the sheep's side.
function CarryPose.Underside(fleece: Fleece, dx: number): number
	local across = math.abs(dx)
	local u = (across - fleece.PuffX) / fleece.HalfWidth
	local wool = if math.abs(u) < 1 then fleece.PuffY - fleece.Hang * math.sqrt(1 - u * u) else fleece.PuffY
	local body = if across <= fleece.BodyHalfWidth then fleece.BodyBottom else math.huge
	return math.min(wool, body)
end

-- The top of the head at `dx` from its middle, grown by `margin` all round. The fleece's lowest puffs sit over the
-- head's corners, which are lower than its crown.
function CarryPose.HeadHeight(shape: Shape, dx: number, margin: number?): number
	local grow = margin or 0
	local halfWidth = shape.HeadHalfWidth + grow
	local corner = halfWidth / 2
	local u = math.abs(dx) - (halfWidth - corner)
	if u <= 0 then
		return shape.HeadTop + grow
	end
	return shape.HeadTop + grow - corner + math.sqrt(math.max(corner * corner - u * u, 0))
end

-- Whether a point is inside the head grown by ArmClearance.
local function inHead(shape: Shape, point: Vector3): boolean
	local margin = Settings.ArmClearance
	return math.abs(point.X) < shape.HeadHalfWidth + margin
		and math.abs(point.Z) < shape.HeadHalfDepth + margin
		and point.Y > shape.HeadBottom
		and point.Y < CarryPose.HeadHeight(shape, point.X, margin)
end

-- Each joint's turn in the hold, for an arm of `count` joints (3 on R15: shoulder, elbow, wrist; 1 on R6), leaning
-- in by `roll` degrees. The left arm mirrors the right.
function CarryPose.Rotations(side: number, roll: number, count: number): { CFrame }
	local rad = math.rad
	local rotations = {
		CFrame.Angles(0, 0, rad(roll * side)) * CFrame.Angles(rad(Settings.ShoulderRaise), 0, 0),
		CFrame.Angles(rad(Settings.ElbowBend), 0, 0),
		-- Fingers turn outwards, which tips the palms up under the fleece.
		CFrame.Angles(0, 0, rad(Settings.WristBend * side)),
	}
	return table.move(rotations, 1, math.min(count, #rotations), 1, {})
end

-- The joint's Transform that turns its part by `rotation` in the parent part's axes, whatever angle its C0 has
-- (R6's shoulders are turned a quarter round).
function CarryPose.Transform(c0: CFrame, rotation: CFrame): CFrame
	local turn = c0.Rotation
	return turn:Inverse() * rotation * turn
end

-- Each of an arm's parts in torso space with its joints turned by `rotations`, from the shoulder out.
function CarryPose.PartFrames(arm: Arm, rotations: { CFrame }): { CFrame }
	local frames: { CFrame } = {}
	local frame = CFrame.identity
	for index, link in arm.Links do
		local rotation = rotations[index] or CFrame.identity
		frame = frame * link.C0 * CarryPose.Transform(link.C0, rotation) * link.C1:Inverse()
		table.insert(frames, frame)
	end
	return frames
end

-- The palm in torso space, turned with the hand.
function CarryPose.PalmFrame(arm: Arm, rotations: { CFrame }): CFrame
	local frames = CarryPose.PartFrames(arm, rotations)
	return frames[#frames] * CFrame.new(arm.Palm)
end

local function turnsFor(arm: Arm, roll: number): { CFrame }
	return CarryPose.Rotations(arm.Side, roll, #arm.Links)
end

-- Whether the arm, leaning in by `roll`, keeps clear of the head: blocky arms are a stud thick, and a small avatar's
-- head is big next to its shoulders.
local function clearsHead(shape: Shape, arm: Arm, roll: number): boolean
	for index, frame in CarryPose.PartFrames(arm, turnsFor(arm, roll)) do
		local size = arm.Sizes[index]
		local inner = -arm.Side * size.X / 2
		for _, along in ALONG do
			for _, deep in DEEP do
				if inHead(shape, frame * Vector3.new(inner, along * size.Y, deep * size.Z)) then
					return false
				end
			end
		end
	end
	return true
end

-- Halves [low, high] towards where `keepsLow` turns false; returns the last lean known to keep it. Both tests here
-- change once over the range, as leaning in only brings the arm closer to the middle.
local function search(low: number, high: number, keepsLow: (roll: number) -> boolean): number
	if keepsLow(high) then
		return high
	elseif not keepsLow(low) then
		return low
	end
	for _ = 1, STEPS do
		local middle = (low + high) / 2
		if keepsLow(middle) then
			low = middle
		else
			high = middle
		end
	end
	return low
end

-- The arm's lean: as far in as puts the palm `across` studs from the middle, but no further than clears the head.
local function fitRoll(shape: Shape, arm: Arm, across: number): number
	local low = Settings.ShoulderRollMin
	local limit = search(low, Settings.ShoulderRollMax, function(roll: number): boolean
		return clearsHead(shape, arm, roll)
	end)
	return search(low, limit, function(roll: number): boolean
		return math.abs(CarryPose.PalmFrame(arm, turnsFor(arm, roll)).X) > across
	end)
end

-- The hold for a character's shape and a breed. The arms lean in to put the palms PalmSpread of the way from the
-- sheep's middle to its fleece's edge, as far as the head lets them. The sheep comes down until the first part of
-- either palm presses PalmSink into its underside (a blocky hand is a stud wide, so that can be its inner edge), but
-- never so low that it comes within HeadClearance of the head.
function CarryPose.Solve(shape: Shape, breed: GameConfig.Breed): Hold
	local fleece = CarryPose.Fleece(breed)
	local across = Settings.PalmSpread * CarryPose.HalfWidth(fleece)
	local rotations: { { CFrame } } = {}
	local palms: { CFrame } = {}
	local centre = Vector3.zero
	for _, arm in shape.Arms do
		local turns = turnsFor(arm, fitRoll(shape, arm, across))
		local palm = CarryPose.PalmFrame(arm, turns)
		table.insert(rotations, turns)
		table.insert(palms, palm)
		centre += palm.Position / #shape.Arms
	end
	local feet = -math.huge
	for index, palm in palms do
		local arm = shape.Arms[index]
		local width = arm.Sizes[#arm.Sizes].X
		for _, along in ALONG do
			local point = palm * Vector3.new(along * width, 0, 0)
			feet = math.max(feet, point.Y - Settings.PalmSink - CarryPose.Underside(fleece, point.X - centre.X))
		end
	end
	for step = 0, HEAD_SAMPLES do
		local dx = shape.HeadHalfWidth * step / HEAD_SAMPLES
		local clear = CarryPose.HeadHeight(shape, dx) + Settings.HeadClearance - CarryPose.Underside(fleece, dx)
		feet = math.max(feet, clear)
	end
	local positions: { Vector3 } = {}
	for _, palm in palms do
		table.insert(positions, palm.Position)
	end
	return {
		Rotations = rotations,
		Palms = positions,
		Sheep = CFrame.new(centre.X, feet, centre.Z) * CarryPose.Lying(breed),
	}
end

-- A joint's two frames (a Motor6D's C0 and C1) and the parts it joins. An AnimationConstraint's are its attachments'.
function CarryPose.JointFrames(joint: Joint): (CFrame, CFrame, Instance?, Instance?)
	if joint:IsA("Motor6D") then
		return joint.C0, joint.C1, joint.Part0, joint.Part1
	end
	local constraint = joint :: AnimationConstraint
	local from, to = constraint.Attachment0, constraint.Attachment1
	if not from or not to then
		return CFrame.identity, CFrame.identity, nil, nil
	end
	return from.CFrame, to.CFrame, from.Parent, to.Parent
end

-- Poses a joint of either kind.
function CarryPose.SetTransform(joint: Joint, transform: CFrame)
	if joint:IsA("Motor6D") then
		joint.Transform = transform
	else
		local constraint = joint :: AnimationConstraint
		constraint.Transform = transform
	end
end

-- Every working joint in the character, AnimationConstraints first in case one sits beside the Motor6D it replaced.
-- Joints are found by the parts they join rather than by where they're kept or what they're called.
local function jointsOf(character: Model): { Joint }
	local constraints: { Joint } = {}
	local motors: { Joint } = {}
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("AnimationConstraint") and descendant.Enabled then
			table.insert(constraints, descendant)
		elseif descendant:IsA("Motor6D") and descendant.Enabled then
			table.insert(motors, descendant)
		end
	end
	return table.move(motors, 1, #motors, #constraints + 1, constraints)
end

local function jointBetween(joints: { Joint }, from: BasePart, to: BasePart): Joint?
	for _, joint in joints do
		local _, _, part0, part1 = CarryPose.JointFrames(joint)
		if part0 == from and part1 == to then
			return joint
		end
	end
	return nil
end

local function partNamed(character: Model, name: string): BasePart?
	local found = character:FindFirstChild(name)
	return if found and found:IsA("BasePart") then found else nil
end

-- One arm, from the torso out; nil if a part or a joint is missing.
local function measureArm(character: Model, joints: { Joint }, torso: BasePart, spec: ArmSpec): (Arm?, { Joint }?)
	local links: { Link } = {}
	local sizes: { Vector3 } = {}
	local armJoints: { Joint } = {}
	local previous: BasePart = torso
	for _, partName in spec.Parts do
		local part = partNamed(character, partName)
		local joint = if part then jointBetween(joints, previous, part) else nil
		if not part or not joint then
			return nil, nil
		end
		local c0, c1 = CarryPose.JointFrames(joint)
		table.insert(links, { C0 = c0, C1 = c1 })
		table.insert(sizes, part.Size)
		table.insert(armJoints, joint)
		previous = part
	end
	local grip = previous:FindFirstChild(spec.Grip)
	local palm = if grip and grip:IsA("Attachment") then grip.Position else Vector3.new(0, -previous.Size.Y / 2, 0)
	return { Links = links, Sizes = sizes, Palm = palm, Side = spec.Side }, armJoints
end

-- Reads a character's arms and head as they stand at rest, from its joints, so the walk, a jump or the server not
-- animating it don't matter. Nil for a character without a standard R15 or R6 upper body.
function CarryPose.Measure(character: Model): Body?
	local isR15 = character:FindFirstChild("UpperTorso") ~= nil
	local torso = partNamed(character, if isR15 then "UpperTorso" else "Torso")
	local head = partNamed(character, "Head")
	if not torso or not head then
		return nil
	end
	local joints = jointsOf(character)
	local neck = jointBetween(joints, torso, head)
	if not neck then
		return nil
	end
	local arms: { Arm } = {}
	local armJoints: { { Joint } } = {}
	local specs: { ArmSpec } = if isR15 then R15_ARMS else R6_ARMS
	for _, spec in specs do
		local arm, found = measureArm(character, joints, torso, spec)
		if not arm or not found then
			return nil
		end
		table.insert(arms, arm)
		table.insert(armJoints, found)
	end
	local lowerTorso = partNamed(character, "LowerTorso")
	local neckC0, neckC1 = CarryPose.JointFrames(neck)
	local headAt = (neckC0 * neckC1:Inverse()).Position
	local halfSize = head.Size / 2
	return {
		Torso = torso,
		Shape = {
			Arms = arms,
			HeadTop = headAt.Y + halfSize.Y,
			HeadBottom = headAt.Y - halfSize.Y,
			HeadHalfWidth = math.min(halfSize.X, halfSize.Z),
			HeadHalfDepth = math.min(halfSize.X, halfSize.Z),
		},
		Joints = armJoints,
		Waist = if isR15 and lowerTorso then jointBetween(joints, lowerTorso, torso) else nil,
	}
end

-- Where a carried sheep goes: the part it's welded to and its feet's centre in that part's space. In its carrier's
-- raised palms, on the torso the arms hang from so the hands and the sheep bob together; on the head of a character
-- without a standard upper body. The server welds the real sheep here, and a buyer's client its stand-in.
function CarryPose.HoldSpot(character: Model, root: BasePart, breed: GameConfig.Breed): (BasePart, CFrame)
	local body = CarryPose.Measure(character)
	if body then
		return body.Torso, CarryPose.Solve(body.Shape, breed).Sheep
	end
	local head = character:FindFirstChild("Head")
	local headTop = if head and head:IsA("BasePart")
		then head.Position.Y + head.Size.Y / 2 - root.Position.Y
		else DEFAULT_HEAD_TOP
	return root, CFrame.new(0, headTop, 0)
end

return table.freeze(CarryPose)
