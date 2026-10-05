--!strict

-- The maths behind TrailerController's camera moves: easing, and smooth paths through a shot's keys that the camera
-- travels at an even speed (a Catmull-Rom spline, resampled by length so unevenly spaced keys don't lurch).
local Path = {}

export type Ease = "Linear" | "In" | "Out" | "InOut"

export type Built = {
	Points: { Vector3 }, -- samples along the spline
	Lengths: { number }, -- distance along the path at each sample
}

local SAMPLES_PER_SEGMENT = 24

function Path.Ease(t: number, ease: string?): number
	local x = math.clamp(t, 0, 1)
	if ease == "Linear" then
		return x
	elseif ease == "In" then
		return x * x * x
	elseif ease == "Out" then
		local u = 1 - x
		return 1 - u * u * u
	end
	-- Smootherstep: starts and stops without a jolt, like a dolly pushed by hand.
	return x * x * x * (x * (x * 6 - 15) + 10)
end

local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: number): Vector3
	local u2 = u * u
	local u3 = u2 * u
	return 0.5 * ((2 * p1) + (p2 - p0) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (3 * p1 - p0 - 3 * p2 + p3) * u3)
end

function Path.Build(keys: { Vector3 }): Built
	local count = #keys
	if count <= 1 then
		local only = keys[1] or Vector3.zero
		return { Points = { only, only }, Lengths = { 0, 0 } }
	end
	local points: { Vector3 } = {}
	for index = 1, count - 1 do
		local p0 = keys[math.max(index - 1, 1)]
		local p1 = keys[index]
		local p2 = keys[index + 1]
		local p3 = keys[math.min(index + 2, count)]
		for step = 0, SAMPLES_PER_SEGMENT - 1 do
			table.insert(points, catmullRom(p0, p1, p2, p3, step / SAMPLES_PER_SEGMENT))
		end
	end
	table.insert(points, keys[count])
	local lengths = { 0 }
	for index = 2, #points do
		lengths[index] = lengths[index - 1] + (points[index] - points[index - 1]).Magnitude
	end
	return { Points = points, Lengths = lengths }
end

-- The point a share t (0..1) of the way along the path by distance.
function Path.At(built: Built, t: number): Vector3
	local points, lengths = built.Points, built.Lengths
	local total = lengths[#lengths]
	if total <= 0 then
		return points[1]
	end
	local wanted = math.clamp(t, 0, 1) * total
	local low, high = 1, #lengths
	while high - low > 1 do
		local middle = (low + high) // 2
		if lengths[middle] < wanted then
			low = middle
		else
			high = middle
		end
	end
	local span = lengths[high] - lengths[low]
	local u = if span > 0 then (wanted - lengths[low]) / span else 0
	return points[low]:Lerp(points[high], u)
end

return Path
