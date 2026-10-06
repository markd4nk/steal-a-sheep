--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Config.GameConfig)

-- The numbers behind a chase's feel (GameConfig.Chase): how scary the god's distance is, and what that level does to
-- the heartbeat, the music's drums and the red edges. ChaseController plays them; GodController times the god's
-- footfalls with StepSeconds.
local ChaseFeel = {}

local settings = GameConfig.Chase

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- 0 with the god FarStuds away or more, 1 at NearStuds or closer.
function ChaseFeel.Level(distance: number): number
	return math.clamp((settings.FarStuds - distance) / (settings.FarStuds - settings.NearStuds), 0, 1)
end

-- Seconds from one heartbeat to the next.
function ChaseFeel.BeatSeconds(level: number): number
	return 60 / lerp(settings.HeartbeatBpm[1], settings.HeartbeatBpm[2], math.clamp(level, 0, 1))
end

-- A heartbeat's playback speed and its volume as a share of the loudest.
function ChaseFeel.Beat(level: number): (number, number)
	local t = math.clamp(level, 0, 1)
	return 1 + settings.HeartbeatSpeedUp * t, lerp(settings.HeartbeatQuiet, 1, t)
end

-- How far in the chase music's drums are, 0 to 1.
function ChaseFeel.Drums(level: number): number
	return math.clamp((level - settings.DrumsFrom) / (settings.DrumsFull - settings.DrumsFrom), 0, 1)
end

-- The red edges' opacity `since` seconds after the last heartbeat.
function ChaseFeel.Edges(level: number, since: number): number
	local t = math.clamp(level, 0, 1)
	local throb = if since >= 0 then math.exp(-since / settings.ThrobSeconds) else 0
	return math.min(
		1,
		lerp(settings.Edges[1], settings.Edges[2], t) + throb * lerp(settings.Throb[1], settings.Throb[2], t)
	)
end

-- Seconds between a running god's footfalls at `speed` studs a second; `runStuds` is the speed at which its run
-- clip plays at 1x (GodController), and the clip's speed is kept within the same limits it is.
function ChaseFeel.StepSeconds(speed: number, runStuds: number): number
	return settings.StepSeconds / math.clamp(speed / runStuds, 0.6, 2.4)
end

return table.freeze(ChaseFeel)
