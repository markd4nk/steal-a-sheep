--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

local Motion = GameConfig.SheepMotion

-- One stroll: turn to face the way (Turn seconds), then walk there (Duration seconds), easing in and out over Ease
-- seconds at each end. A turn on the spot has no Duration.
export type Walk = {
	From: CFrame,
	To: CFrame,
	Start: number, -- on whatever clock the caller keeps: the server's time on the server, os.clock() on a client
	Turn: number,
	Duration: number,
	Ease: number,
}

-- Sheep strolling round their owner's plot like farm animals (Shear a Sheep's): long spells standing about, then a
-- short walk. The server picks each stroll and keeps the sheep's position along it; every client walks the sheep the
-- same way. Pure functions, so they can be unit-tested.
local Wander = {}

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

local function flatDistance(from: Vector3, to: Vector3): number
	return Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
end

-- The way a sheep faces while walking from `from` to `to`, or `to`'s way for a turn on the spot.
function Wander.Heading(from: CFrame, to: CFrame): CFrame
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 0.05 then
		return to.Rotation
	end
	return CFrame.lookAt(Vector3.zero, flat).Rotation
end

-- A stroll's end (rolls are 0 <= roll < 1, e.g. Random:NextNumber()): StrollMinDistance to StrollMaxDistance away
-- in any direction, at `from`'s height, facing the way the sheep walks. Whether it may stand there is the caller's
-- to check.
function Wander.Stroll(from: CFrame, rollAngle: number, rollDistance: number): CFrame
	local angle = rollAngle * 2 * math.pi
	local distance = Motion.StrollMinDistance + (Motion.StrollMaxDistance - Motion.StrollMinDistance) * rollDistance
	local target = from.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
	return CFrame.lookAt(target, target + (target - from.Position))
end

-- A turn on the spot to face a new way.
function Wander.TurnAround(from: CFrame, rollAngle: number): CFrame
	return CFrame.new(from.Position) * CFrame.Angles(0, rollAngle * 2 * math.pi, 0)
end

-- The stroll from `from` to `to`, starting at `start`. Walking at WanderSpeed, it takes the distance over that
-- speed, plus the ease (half the ease at each end is at a slower pace).
function Wander.Plan(from: CFrame, to: CFrame, start: number): Walk
	local distance = flatDistance(from.Position, to.Position)
	if distance < 0.05 then
		return { From = from, To = to, Start = start, Turn = Motion.TurnAroundSeconds, Duration = 0, Ease = 0 }
	end
	local cruise = distance / Motion.WanderSpeed
	local ease = math.min(Motion.EaseSeconds, cruise)
	return {
		From = from,
		To = to,
		Start = start,
		Turn = Motion.WanderTurnSeconds,
		Duration = cruise + ease,
		Ease = ease,
	}
end

-- When the stroll is over, on its own clock.
function Wander.Ends(walk: Walk): number
	return walk.Start + walk.Turn + walk.Duration
end

-- How far along the way (0 to 1) the sheep is `t` seconds after setting off: speeding up over Ease, walking at
-- WanderSpeed, then slowing down over Ease.
local function travelled(walk: Walk, t: number): number
	local total = walk.Duration
	local ease = walk.Ease
	local cruise = total - ease
	if t >= total then
		return 1
	elseif cruise <= 0 then
		return 1
	elseif ease <= 0 then
		return t / cruise
	elseif t < ease then
		return t * t / (2 * ease * cruise)
	elseif t <= total - ease then
		return (t - ease / 2) / cruise
	end
	local left = total - t
	return 1 - left * left / (2 * ease * cruise)
end

-- Where the sheep stands `now` (on the walk's clock), and whether the stroll is over.
function Wander.PoseAt(walk: Walk, now: number): (CFrame, boolean)
	local elapsed = math.max(0, now - walk.Start)
	local facing = Wander.Heading(walk.From, walk.To)
	if elapsed < walk.Turn then
		local rotation = walk.From.Rotation:Lerp(facing, smooth(elapsed / walk.Turn))
		return CFrame.new(walk.From.Position) * rotation, false
	end
	local t = elapsed - walk.Turn
	if t >= walk.Duration then
		return CFrame.new(walk.To.Position) * facing, true
	end
	return CFrame.new(walk.From.Position:Lerp(walk.To.Position, travelled(walk, t))) * facing, false
end

return table.freeze(Wander)
