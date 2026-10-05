--!strict

-- Whether a spot is inside a plot's pen: PlotService/Build's invisible Pen box, which fills the plot's fence. Its x and
-- z must be inside the box less `margin` (a negative margin reaches past it), and its height near the box. The server
-- and every client use the same test, so "you're home" means the same everywhere.
local PenArea = {}

local HEIGHT_SLACK = 6 -- studs above or below the box that still count (a jump)

function PenArea.Contains(pen: BasePart, position: Vector3, margin: number): boolean
	local offset = pen.CFrame:PointToObjectSpace(position)
	local half = pen.Size / 2
	return math.abs(offset.X) <= half.X - margin
		and math.abs(offset.Z) <= half.Z - margin
		and math.abs(offset.Y) <= half.Y + HEIGHT_SLACK
end

-- The nearest spot to `position` that's inside the pen by at least `margin`, at the same height.
function PenArea.Clamp(pen: BasePart, position: Vector3, margin: number): Vector3
	local offset = pen.CFrame:PointToObjectSpace(position)
	local half = pen.Size / 2
	local x = math.clamp(offset.X, -math.max(half.X - margin, 0), math.max(half.X - margin, 0))
	local z = math.clamp(offset.Z, -math.max(half.Z - margin, 0), math.max(half.Z - margin, 0))
	return pen.CFrame:PointToWorldSpace(Vector3.new(x, offset.Y, z))
end

return table.freeze(PenArea)
