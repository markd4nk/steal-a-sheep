--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Olympus = require(ReplicatedStorage.Config.Olympus)

-- Where things are on the ramp: its height along the middle, which tier a spot is in, how fast a climb goes
-- there, and the real floor under a point. Uphill is +X; downhill, towards the plots, is -X.
local Mountain = {}

Mountain.Downhill = Vector3.new(-1, 0, 0)

local ramp = Olympus.Ramp
local top = Olympus.Tiers[#Olympus.Tiers].XEnd

-- The floor's height along the ramp's middle, from the measured profile.
function Mountain.RampY(x: number): number
	if x <= ramp[1][1] then
		return ramp[1][2]
	end
	for index = 1, #ramp - 1 do
		local a, b = ramp[index], ramp[index + 1]
		if x <= b[1] then
			return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1])
		end
	end
	return ramp[#ramp][2]
end

-- How steep the ramp is at `x`: height gained per stud of x.
function Mountain.RampSlope(x: number): number
	for index = 1, #ramp - 1 do
		local a, b = ramp[index], ramp[index + 1]
		if x <= b[1] then
			return if x < a[1] then 0 else (b[2] - a[2]) / (b[1] - a[1])
		end
	end
	return 0
end

-- The tier whose stretch of ramp `x` is on; 0 below the safety line.
function Mountain.TierAt(x: number): number
	if x < Olympus.SafeLineX then
		return 0
	end
	for _, tier in Olympus.Tiers do
		if x < tier.XEnd then
			return tier.Tier
		end
	end
	return #Olympus.Tiers
end

-- How fast a player with `climb` Climbing may go up the slope at `x`, in studs a second: walking speed times the
-- tier's climb share, never under a crawl. Below the safety line it's walking speed.
function Mountain.ClimbSpeedAt(x: number, climb: number): number
	local movement = GameConfig.Movement
	local share = Economy.ClimbShare(climb, Mountain.TierAt(x))
	return math.max(movement.CrawlSpeed, movement.WalkSpeed * share)
end

-- On the ramp between the safety line and the summit, near its floor (not on a roof or cloud above it).
function Mountain.IsOnRamp(position: Vector3): boolean
	if position.X < Olympus.SafeLineX or position.X > top + 20 then
		return false
	end
	return math.abs(position.Y - Mountain.RampY(position.X)) < 18
end

function Mountain.Top(): number
	return top
end

-- The floor under (x, z) near the ramp's line, or the line itself where a raycast finds nothing close (a tree's
-- canopy, a gap). `params` should leave out characters, sheep and gods.
function Mountain.Floor(x: number, z: number, params: RaycastParams?): number
	local guess = Mountain.RampY(x)
	local snap = Olympus.RampSnap
	local query = params or RaycastParams.new()
	for _ = 1, 4 do
		local result = workspace:Raycast(Vector3.new(x, guess + snap, z), Vector3.new(0, -snap * 2, 0), query)
		if not result then
			break
		end
		-- The stages' trees and bamboo stand on the ramp: look through them to the floor.
		if Mountain.IsPlant(result.Instance) then
			query:AddToFilter(result.Instance)
			continue
		end
		if result.Normal.Y > 0.5 then
			return result.Position.Y
		end
		break
	end
	return guess
end

-- A tree, bamboo stalk or leaf of the map's stages (models named Tree..., tree, Bamboo; parts named Leaf/Leaves).
function Mountain.IsPlant(part: Instance): boolean
	local node: Instance? = part
	for _ = 1, 4 do
		if not node then
			break
		end
		local name = node.Name
		if string.match(name, "^[Tt]ree") or name == "Bamboo" or name == "Leaf" or name == "Leaves" then
			return true
		end
		node = node.Parent
	end
	return false
end

-- A tier's four wild-sheep spots (x, z), spread over its pasture: the top part of its stretch.
function Mountain.PastureSpots(tierNumber: number): { Vector2 }
	local tier = Olympus.Tiers[tierNumber]
	local from = tier.XStart + (tier.XEnd - tier.XStart) * Olympus.PastureFrom
	local to = tier.XEnd - 18
	local lanes = Olympus.LaneZ
	local spots: { Vector2 } = {}
	local count = Olympus.SpawnsPerTier
	for index = 1, count do
		local share = (index - 0.5) / count
		local x = from + (to - from) * (if index % 2 == 0 then 0.35 else 0.75)
		local z = lanes[1] + 14 + (lanes[2] - lanes[1] - 28) * share
		table.insert(spots, Vector2.new(x, z))
	end
	return spots
end

-- Where a tier's god waits: near the top of its stretch, to one side so the next gate's sign stays readable.
function Mountain.GodHome(tierNumber: number): Vector2
	local tier = Olympus.Tiers[tierNumber]
	return Vector2.new(tier.XEnd - 22, Olympus.LaneMiddleZ + 26)
end

-- Keeps a point's z inside the walkable lane.
function Mountain.ClampLane(z: number): number
	return math.clamp(z, Olympus.LaneZ[1], Olympus.LaneZ[2])
end

return table.freeze(Mountain)
