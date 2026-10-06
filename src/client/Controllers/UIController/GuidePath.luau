--!strict

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mountain = require(ReplicatedStorage.Utils.Mountain)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Theme = require(ReplicatedStorage.Config.Theme)

-- One chevron of the trail: its parts in PIECES' order, whether they show, and how big they are now (1 = full size).
type Chevron = { Parts: { Part }, Shown: boolean, Scale: number }
-- One of a chevron's parts, laid out round its middle, which faces the way the trail goes (-Z).
type Piece = { Name: string, Offset: Vector3, Turn: CFrame, Size: Vector3, Color: Color3 }

export type GuidePath = {
	-- Lays the trail from the character's feet towards `goal` (a point on the ground) this frame, or hides it (nil).
	Show: (self: GuidePath, feet: Vector3?, goal: Vector3?) -> (),
	Destroy: (self: GuidePath) -> (),
}

-- Shear a Sheep's numbers (Mark, 2026-10-03: quick and close together, to urge the player on).
local COUNT = 17 -- chevrons at most: the nearest stretch of a long way
local SPACING = 3.4 -- studs between them along the way
local START = 3.5 -- studs ahead of the player the first one is
local STOP = 2 -- studs short of the goal the last one is; nearer than START + STOP, there's no trail
local SPEED = 13 -- studs a second they run towards the goal
local GROW = 2.5 -- studs over which they grow in at the player's end and shrink away at the goal's
local SMALLEST = 0.05 -- of full size; smaller than this, a chevron isn't shown
-- Each chevron is two white bars meeting at its tip over two black bars OUTLINE bigger all round: one white shape with a
-- black outline. Solid rather than a picture or a fade: Roblox draws see-through things in order of distance, so
-- see-through chevrons looked to go under the ground's see-through edges in Shear a Sheep.
local ARM_LENGTH = 3 -- studs along each bar's outer edge, from the tip
local ARM_WIDTH = 0.8
-- Degrees each arm turns off the way ahead. From 45 up, each bar's front end lies inside the other bar, so the tip is
-- one clean point.
local ARM_ANGLE = 45
local OUTLINE = 0.18
local THICKNESS = 0.05
local RAISE = 0.04 -- studs the white sits over the black, so they don't flicker from afar
local LIFT = 0.28 -- studs over the ground a ray finds, clear of the grass and anything flat
local PROBE = 8 -- studs above and below the ramp's height a ray looks for the ground
-- The way is worked out again this often, or once the player has moved this far from where it was worked out from.
local REPLAN_SECONDS = 1.5
local REPLAN_MOVE = 6
-- The walker the way is worked out for: about a character, kept a little wide of stalls and fences.
local AGENT = { AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 4 }
-- A way round things longer than this many times the straight line, plus DETOUR_SLACK studs, isn't taken: the trail
-- runs straight instead.
local DETOUR = 1.3
local DETOUR_SLACK = 16
local NEW_GOAL = 1 -- studs a goal moves before it counts as a new one: the old way is dropped at once
-- Folders whose models a ray for the ground looks through: the trail never climbs over a sheep or a god.
local SEE_THROUGH = { "WildSheep", "PenSheep", "CarriedSheep", "Gods" }

-- A chevron's parts: the black bars first, then the white ones over them. Each bar's outer edge runs back from the tip,
-- and the tip sits so the chevron's middle is half way along it.
local PIECES: { Piece } = {}
do
	local angle = math.rad(ARM_ANGLE)
	local depth = ARM_LENGTH * math.cos(angle) + ARM_WIDTH * math.sin(angle)
	local tip = Vector3.new(0, 0, -depth / 2)
	for _, layer in { { Name = "Edge", Grow = OUTLINE, Height = 0 }, { Name = "", Grow = 0, Height = RAISE } } do
		for _, side in { -1, 1 } do
			local back = Vector3.new(side * math.sin(angle), 0, math.cos(angle)) -- along the bar, away from the tip
			local out = Vector3.new(side * math.cos(angle), 0, -math.sin(angle)) -- across it, away from the V's inside
			table.insert(PIECES, {
				Name = (if side < 0 then "Left" else "Right") .. layer.Name,
				Offset = tip + back * (ARM_LENGTH / 2) - out * (ARM_WIDTH / 2) + Vector3.yAxis * layer.Height,
				Turn = CFrame.lookAt(Vector3.zero, back),
				Size = Vector3.new(ARM_WIDTH + 2 * layer.Grow, THICKNESS, ARM_LENGTH + 2 * layer.Grow),
				Color = if layer.Grow > 0 then Theme.Color.Line else Theme.Color.Snow,
			})
		end
	end
end

-- Shear a Sheep's guide trail: white chevrons with a black outline flat on the ground, running from the player towards
-- the place the onboarding sends them (the user, 2026-10-06: a place to go, not a sheep to point at). The way always
-- comes from PathfindingService: the plots' fences, the hay and the leaderboards can't be seen by rays (CanQuery off),
-- so a straight line that looks clear can run into a fence; it goes out through the gate instead. Straight until the
-- first way is worked out, or when none is short enough. A new goal drops the old way at once. On this device only;
-- Reduce motion keeps them still.
local GuidePath = {}

function GuidePath.new(parent: Instance, character: () -> Model?): GuidePath
	local folder = Instance.new("Folder")
	folder.Name = "GuidePath"
	folder.Parent = parent
	local rays = RaycastParams.new()
	rays.FilterType = Enum.RaycastFilterType.Exclude
	rays.RespectCanCollide = true

	local chevrons: { Chevron } = {}
	for index = 1, COUNT do
		local model = Instance.new("Model")
		model.Name = `Chevron{index}`
		local parts: { Part } = {}
		for _, piece in PIECES do
			local part = Instance.new("Part")
			part.Name = piece.Name
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Material = Enum.Material.SmoothPlastic
			part.Color = piece.Color
			part.Size = piece.Size
			part.Transparency = 1
			part.Parent = model
			table.insert(parts, part)
		end
		model.Parent = folder
		table.insert(chevrons, { Parts = parts, Shown = false, Scale = 1 })
	end
	-- This frame's moves, made together.
	local moving: { BasePart } = {}
	local places: { CFrame } = {}

	-- What rays for the ground see through: the trail itself, every character, and the sheep and gods.
	local function refreshRays()
		local skip: { Instance } = { folder }
		for _, name in SEE_THROUGH do
			local holder = workspace:FindFirstChild(name)
			if holder then
				table.insert(skip, holder)
			end
		end
		for _, other in Players:GetPlayers() do
			if other.Character then
				table.insert(skip, other.Character)
			end
		end
		local own = character()
		if own and not table.find(skip, own) then
			table.insert(skip, own)
		end
		rays.FilterDescendantsInstances = skip
	end
	local shown = true
	local alive = true

	-- The way, as last worked out: its corners from where the player was then to the goal.
	local route: { Vector3 }? = nil
	local routeFrom: Vector3? = nil
	local routeGoal: Vector3? = nil
	local plannedAt = -math.huge
	local planning = false

	local function hide()
		if shown then
			shown = false
			folder.Parent = nil
		end
	end

	-- The corners of the way round things from one point to the other, or nil when none is found or it's a long way
	-- round. Yields.
	local function aroundThings(from: Vector3, to: Vector3): { Vector3 }?
		local longest = (to - from).Magnitude * DETOUR + DETOUR_SLACK
		local way = PathfindingService:CreatePath(AGENT)
		local ok = pcall(function()
			way:ComputeAsync(from, to)
		end)
		if not ok or way.Status ~= Enum.PathStatus.Success then
			return nil
		end
		local points = way:GetWaypoints()
		local corners: { Vector3 } = {}
		local length = 0
		for index, waypoint in points do
			if index > 1 then
				length += (waypoint.Position - points[index - 1].Position).Magnitude
			end
			table.insert(corners, waypoint.Position)
		end
		return if #corners >= 2 and length <= longest then corners else nil
	end

	local function plan(from: Vector3, goal: Vector3)
		planning = true
		plannedAt = os.clock()
		routeFrom = from
		routeGoal = goal
		task.spawn(function()
			local corners = aroundThings(from, goal)
			planning = false
			local current = routeGoal
			if alive and current and (current - goal).Magnitude <= NEW_GOAL then
				route = corners
			end
		end)
	end

	-- The way from the player's feet now: on from the corner of the last worked-out way nearest them, or straight.
	local function way(feet: Vector3, goal: Vector3): { Vector3 }
		local corners = route
		if not corners or #corners < 2 then
			return { feet, goal }
		end
		local nearest, best = 1, math.huge
		for index, corner in corners do
			local away = Vector3.new(corner.X - feet.X, 0, corner.Z - feet.Z).Magnitude
			if away < best then
				nearest, best = index, away
			end
		end
		local points = { feet }
		for index = nearest + 1, #corners do
			table.insert(points, corners[index])
		end
		if #points < 2 then
			table.insert(points, goal)
		end
		return points
	end

	-- The ground's height under `at`, looking PROBE studs either side of the ramp's height there (flat by the plots):
	-- never from the character's height, which rises when they jump.
	local function ground(at: Vector3): number
		local floor = Mountain.RampY(at.X)
		local hit = workspace:Raycast(Vector3.new(at.X, floor + PROBE, at.Z), Vector3.new(0, -2 * PROBE, 0), rays)
		return if hit then hit.Position.Y else floor
	end

	local function reveal(chevron: Chevron, isShown: boolean)
		if chevron.Shown ~= isShown then
			chevron.Shown = isShown
			for _, part in chevron.Parts do
				part.Transparency = if isShown then 0 else 1
			end
		end
	end

	-- Lays `chevron` out round `middle` pointing `ahead`, at `scale` of its full size (its thickness stays).
	local function place(chevron: Chevron, middle: Vector3, ahead: Vector3, scale: number)
		local resized = chevron.Scale ~= scale
		chevron.Scale = scale
		local flat = Vector3.new(scale, 1, scale)
		local frame = CFrame.lookAt(middle, middle + ahead)
		for index, piece in PIECES do
			local part = chevron.Parts[index]
			if resized then
				part.Size = piece.Size * flat
			end
			table.insert(moving, part)
			table.insert(places, frame * CFrame.new(piece.Offset * flat) * piece.Turn)
		end
	end

	-- Whether `goal` is somewhere else than where the way was last worked out to.
	local function isNew(goal: Vector3): boolean
		local last = routeGoal
		return last == nil or (goal - last).Magnitude > NEW_GOAL
	end

	local self = {} :: GuidePath

	function self.Show(_self: GuidePath, standing: Vector3?, goal: Vector3?)
		if not standing or not goal then
			hide()
			return
		end
		-- Laid out on the ground: where the player's feet are, not how high they are.
		local feet = Vector3.new(standing.X, goal.Y, standing.Z)
		local from = routeFrom
		local moved = if from then Vector3.new(feet.X - from.X, 0, feet.Z - from.Z).Magnitude else math.huge
		local changed = isNew(goal)
		if changed then
			-- Somewhere else now: the old way goes at once (straight until the new one is worked out).
			route = nil
			routeGoal = goal
			plannedAt = -math.huge
		end
		if not planning and (changed or moved > REPLAN_MOVE or os.clock() - plannedAt > REPLAN_SECONDS) then
			plan(Vector3.new(standing.X, ground(standing) + 2, standing.Z), goal)
		end
		local points = way(feet, goal)
		local length = 0
		for index = 2, #points do
			local step = points[index] - points[index - 1]
			length += Vector3.new(step.X, 0, step.Z).Magnitude
		end
		length -= STOP
		if length <= START then
			hide()
			return
		end
		if not shown then
			shown = true
			folder.Parent = parent
		end
		refreshRays()
		local drift = if PlayerSettings.ReduceMotion() then 0 else (os.clock() * SPEED) % SPACING
		local segment, segmentStart = 2, 0
		table.clear(moving)
		table.clear(places)
		for index, chevron in chevrons do
			local along = START + (index - 1) * SPACING + drift
			local grown = math.clamp(math.min((along - START) / GROW, (length - along) / GROW), 0, 1)
			-- Quick at first, easing into full size.
			local scale = 1 - (1 - grown) ^ 2
			if scale < SMALLEST then
				reveal(chevron, false)
				continue
			end
			-- Along the way's segments to the one this chevron is on.
			local a, b = points[segment - 1], points[segment]
			local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			while along > segmentStart + flat.Magnitude and segment < #points do
				segmentStart += flat.Magnitude
				segment += 1
				a, b = points[segment - 1], points[segment]
				flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			end
			if flat.Magnitude < 1e-3 then
				reveal(chevron, false)
				continue
			end
			local ahead = flat.Unit
			local spot = a + ahead * (along - segmentStart)
			place(chevron, Vector3.new(spot.X, ground(spot) + LIFT + THICKNESS / 2, spot.Z), ahead, scale)
			reveal(chevron, true)
		end
		workspace:BulkMoveTo(moving, places, Enum.BulkMoveMode.FireCFrameChanged)
	end

	function self.Destroy(_self: GuidePath)
		alive = false
		folder:Destroy()
	end

	hide()
	return self
end

return table.freeze(GuidePath)
