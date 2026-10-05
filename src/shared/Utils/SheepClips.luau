--!strict

-- The sheep's motion as pure functions of time, from Shear a Sheep (Shake, HappyHop, Scared, Struggle, LieDown, the
-- idle's readable layer, the carried sway) plus this game's walk and graze: each fills in a Motor6D transform per
-- joint, and AnimController plays them procedurally on every device.
--
-- Joint frames as in studio/BuildSheepAnimations.luau: +X rotation lifts a head or swings a leg forward, Y turns,
-- Z rolls sideways; Body moving up is the whole sheep rising, since Root never moves.

export type ClipName = "Shake" | "HappyHop" | "Scared" | "Struggle" | "LieDown"
export type Pose = { [string]: CFrame } -- joint name -> transform; joints not in it stay as the Animator left them

export type Clip = {
	Length: number, -- seconds; a looping clip repeats from 0
	Loop: boolean,
	Sample: (t: number, pose: Pose) -> (),
}

local SheepClips = {}

SheepClips.Names = table.freeze({ "Shake", "HappyHop", "Scared", "Struggle", "LieDown" }) :: { string }

local TAU = 2 * math.pi
local CARRY_FULL_PACE = 16 -- studs per second at which a carried sheep sways its most (a walk is 16)
local rad = math.rad

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

-- 0 at both ends of a clip, 1 in its middle: so a one-shot starts and ends on the Animator's own pose.
local function envelope(t: number, length: number, edge: number): number
	return math.min(smooth(t / edge), smooth((length - t) / edge))
end

local clips: { [string]: Clip } = {}

-- Wool full again: a whole-body shake like a wet dog's, ears and tail flapping.
clips.Shake = {
	Length = 1.0,
	Loop = false,
	Sample = function(t: number, pose: Pose)
		local env = envelope(t, 1.0, 0.2)
		local wave = math.sin(t * TAU * 7)
		pose.Body = CFrame.new(0, 0.05 * env, 0) * roll(14 * wave * env)
		pose.Head = roll(-10 * wave * env)
		pose.EarL = roll(28 * math.sin(t * TAU * 7 + 1) * env)
		pose.EarR = roll(-28 * math.sin(t * TAU * 7 + 1) * env)
		pose.Tail = turn(25 * math.sin(t * TAU * 9) * env)
	end,
}

-- A jump in place: up, legs tucked, head up, and a soft landing.
clips.HappyHop = {
	Length = 0.7,
	Loop = false,
	Sample = function(t: number, pose: Pose)
		local x = math.clamp(t / 0.7, 0, 1)
		local height = 4 * x * (1 - x)
		pose.Body = CFrame.new(0, 0.9 * height, 0)
		pose.LegFL = tip(30 * height)
		pose.LegFR = tip(30 * height)
		pose.LegBL = tip(-30 * height)
		pose.LegBR = tip(-30 * height)
		pose.Head = tip(15 * height)
		pose.EarL = turn(35 * height)
		pose.EarR = turn(-35 * height)
		pose.Tail = tip(25 * height)
	end,
}

-- A wolf is at the pen: head low, ears back, tail tucked, trembling.
clips.Scared = {
	Length = 0.6,
	Loop = true,
	Sample = function(t: number, pose: Pose)
		pose.Body = CFrame.new(0, 0.03 * math.sin(t * TAU * 18), 0) * roll(2.5 * math.sin(t * TAU * 14))
		pose.Head = tip(-14) * turn(4 * math.sin(t * TAU * 5))
		pose.EarL = turn(45)
		pose.EarR = turn(-45)
		pose.Tail = tip(-35)
	end,
}

-- In a wolf's jaws: legs kicking in pairs, head thrashing, tail going.
clips.Struggle = {
	Length = 0.6,
	Loop = true,
	Sample = function(t: number, pose: Pose)
		local kick = math.sin(t * TAU / 0.3)
		pose.LegFL = roll(-15) * tip(40 * kick)
		pose.LegBR = roll(15) * tip(40 * kick)
		pose.LegFR = roll(15) * tip(-40 * kick)
		pose.LegBL = roll(-15) * tip(-40 * kick)
		pose.Head = turn(25 * math.sin(t * TAU / 0.6)) * tip(10 * math.sin(t * TAU / 0.2))
		pose.Tail = turn(30 * math.sin(t * TAU / 0.15))
	end,
}

local DOWN = 1.2 -- seconds to settle
local UP = 0.8 -- seconds to get up again
local LIE_LENGTH = 7

-- A rare rest: it folds its legs and lies down, breathes slowly for a while, then gets up.
clips.LieDown = {
	Length = LIE_LENGTH,
	Loop = false,
	Sample = function(t: number, pose: Pose)
		local amount = if t < DOWN
			then smooth(t / DOWN)
			elseif t > LIE_LENGTH - UP then 1 - smooth((t - (LIE_LENGTH - UP)) / UP)
			else 1
		local breathe = 0.02 * math.sin(t * TAU / 3) * amount
		pose.Body = CFrame.new(0, -0.45 * amount + breathe, 0)
		pose.LegFL = tip(-80 * amount)
		pose.LegFR = tip(-80 * amount)
		pose.LegBL = tip(80 * amount)
		pose.LegBR = tip(80 * amount)
		pose.Head = tip(-8 * amount) * turn(12 * math.sin(t * TAU / 5) * amount)
	end,
}

SheepClips.Clips = table.freeze(clips)

function SheepClips.Get(name: string): Clip?
	return clips[name]
end

-- The readable idle, played over the Animator's Idle on every penned sheep: breathing you can see from across the
-- pen and a head that looks about now and then. `seed` staggers sheep; `weight` (0 to 1) fades it out while the
-- sheep grazes, walks or does anything else.
local LOOK_EVERY = 4.5 -- seconds between glances, give or take the seed
local LOOK_TURN = 0.6 -- seconds a glance takes

local function lookTarget(segment: number, seed: number): number
	return math.clamp(math.noise(segment * 0.731, seed * 3.17, 0.5) * 70, -32, 32)
end

-- On a head (or in a wolf's jaws): the body leans back against the carrier's pace and sways with their turns, bobbing
-- with their steps, legs dangling. Still while they stand still. `velocity` is the carrier's, in the sheep's own space
-- (-Z its front), in studs per second; it's layered on top of whatever else the pose holds.
function SheepClips.Carried(t: number, velocity: Vector3, pose: Pose)
	local pace = math.min(Vector2.new(velocity.X, velocity.Z).Magnitude / CARRY_FULL_PACE, 1)
	if pace < 0.05 then
		return
	end
	local forward = math.clamp(-velocity.Z / CARRY_FULL_PACE, -1, 1)
	local side = math.clamp(velocity.X / CARRY_FULL_PACE, -1, 1)
	local step = math.sin(t * TAU * 2.4)
	local sway = CFrame.new(0, 0.06 * math.abs(step) * pace, 0)
		* tip(6 * forward + 3 * step * pace)
		* roll(-7 * side + 4 * math.sin(t * TAU * 1.2) * pace)
	pose.Body = if pose.Body then pose.Body * sway else sway
	local dangle = 18 * step * pace
	for name, sign in { LegFL = 1, LegBR = 1, LegFR = -1, LegBL = -1 } :: { [string]: number } do
		local swing = tip(dangle * sign)
		local current = pose[name]
		pose[name] = if current then current * swing else swing
	end
end

local function add(pose: Pose, name: string, offset: CFrame)
	local current = pose[name]
	pose[name] = if current then current * offset else offset
end

-- Walking (Steal a Sheep's pens): legs swinging in diagonal pairs, the body bobbing and rolling a little with each
-- step, the head nodding, the tail swaying. `phase` counts walk cycles (two steps each), so the caller keeps the legs
-- in step with the ground; `pace` (0 to 1) blends it in and out; `scale` is the model's, for the bob's height.
-- Layered on top of whatever the pose holds.
function SheepClips.Walk(phase: number, pace: number, scale: number, pose: Pose)
	if pace <= 0 then
		return
	end
	local swing = math.sin(phase * TAU)
	local lift = math.abs(swing)
	add(pose, "Body", CFrame.new(0, 0.05 * lift * pace * scale, 0) * roll(2.5 * swing * pace))
	add(pose, "Head", tip(4 * math.sin(phase * TAU * 2) * pace))
	add(pose, "LegFL", tip(30 * swing * pace))
	add(pose, "LegBR", tip(30 * swing * pace))
	add(pose, "LegFR", tip(-30 * swing * pace))
	add(pose, "LegBL", tip(-30 * swing * pace))
	add(pose, "Tail", turn(12 * swing * pace))
end

-- A grazing bout: `count` times the head goes down to the grass (GRAZE_DOWN), nibbles and tugs at it for `bite`
-- seconds, comes up a little (GRAZE_UP) and chews for `chew` seconds, its head working from side to side; then it
-- stands up again (GRAZE_END). Body and front tip forward so the nose reaches the ground, the legs staying upright.
export type Bout = {
	Bite: number,
	Chew: number,
	Count: number,
}

local GRAZE_DOWN = 0.55
local GRAZE_UP = 0.45
local GRAZE_END = 0.5
local CHEW_LEVEL = 0.3 -- how far down the head stays while it chews (1 is nose in the grass)
local GRAZE_HEAD = 80 -- degrees the head tips down at the grass
local GRAZE_BODY = 14 -- degrees the body tips forward
local GRAZE_SINK = 0.08 -- studs the body sinks at the grass (at rig scale 1), the legs taking it
local GRAZE_STRETCH = Vector3.new(0, -0.18, -0.14) -- the neck reaching down and forward at the grass (rig scale 1)
local CHEW_RATE = 2.4 -- chews a second

function SheepClips.GrazeLength(bout: Bout): number
	return bout.Count * (GRAZE_DOWN + bout.Bite + GRAZE_UP + bout.Chew) + GRAZE_END
end

-- Where in a bout `t` is: how far down the head is (0 standing, 1 at the grass), and "Bite" or "Chew" while it's
-- doing that (nil moving between, and after the end).
function SheepClips.GrazeStage(bout: Bout, t: number): (number, string?)
	local cycle = GRAZE_DOWN + bout.Bite + GRAZE_UP + bout.Chew
	local body = bout.Count * cycle
	if t < 0 then
		return 0, nil
	elseif t >= body then
		return CHEW_LEVEL * (1 - smooth((t - body) / GRAZE_END)), nil
	end
	local index = math.floor(t / cycle)
	local into = t - index * cycle
	local before = if index == 0 then 0 else CHEW_LEVEL
	if into < GRAZE_DOWN then
		return before + (1 - before) * smooth(into / GRAZE_DOWN), nil
	end
	into -= GRAZE_DOWN
	if into < bout.Bite then
		return 1, "Bite"
	end
	into -= bout.Bite
	if into < GRAZE_UP then
		return 1 - (1 - CHEW_LEVEL) * smooth(into / GRAZE_UP), nil
	end
	return CHEW_LEVEL, "Chew"
end

-- The bout's pose at `t`, `weight` (0 to 1) of it (for fading out a bout cut short), on a model of `scale`, layered on
-- top of the pose. Returns how far down the head is, for the idle to make way.
function SheepClips.Graze(bout: Bout, t: number, weight: number, scale: number, pose: Pose): number
	local level, stage = SheepClips.GrazeStage(bout, t)
	level *= weight
	if level <= 0 then
		return 0
	end
	local nibble = 0
	local sweep = 0
	if stage == "Bite" then
		-- Quick tugs at the grass, the head sweeping slowly along it.
		nibble = 7 * math.abs(math.sin(t * TAU * 2.2)) * weight
		sweep = 12 * math.sin(t * TAU * 0.4) * weight
	end
	local chew = 0
	if stage == "Chew" then
		chew = math.sin(t * TAU * CHEW_RATE) * weight
	end
	add(pose, "Body", CFrame.new(0, -GRAZE_SINK * level * scale, 0) * tip(-GRAZE_BODY * level))
	for _, leg in { "LegFL", "LegFR", "LegBL", "LegBR" } do
		add(pose, leg, tip(GRAZE_BODY * level))
	end
	add(
		pose,
		"Head",
		CFrame.new(GRAZE_STRETCH * level * scale)
			* turn(sweep)
			* tip(-GRAZE_HEAD * level + nibble + 2.5 * math.abs(chew))
			* roll(5 * chew)
	)
	add(pose, "EarL", roll(-14 * level))
	add(pose, "EarR", roll(14 * level))
	return level
end

function SheepClips.Idle(t: number, seed: number, weight: number, pose: Pose)
	if weight <= 0 then
		return
	end
	local shifted = t + seed * 11
	local segment = math.floor(shifted / LOOK_EVERY)
	local into = shifted - segment * LOOK_EVERY
	local yaw = lookTarget(segment - 1, seed)
		+ (lookTarget(segment, seed) - lookTarget(segment - 1, seed)) * smooth(into / LOOK_TURN)
	local breath = math.sin(shifted * TAU / 2.8)
	pose.Body = CFrame.new(0, 0.035 * breath * weight, 0) * tip(1.5 * breath * weight)
	pose.Head = turn(yaw * weight) * tip(-2 * breath * weight)
	-- A few tail wags now and then.
	local wagPhase = shifted % 6
	if wagPhase < 1 then
		pose.Tail = turn(20 * math.sin(wagPhase * TAU * 3) * math.sin(wagPhase * math.pi) * weight)
	end
end

return table.freeze(SheepClips)
