--!strict
-- High Olympus: the mountain above the commissioned map's old summit, one stretch of ramp for each god from tier 13 to
-- Zeus at tier 30, and a summit plaza with his throne. Every stretch is built from the map's own pieces (stage 3's
-- floor slab and cliff terraces, the stages' trees, rocks, arches, islands, clouds and the Studs material) recoloured
-- for its god, plus a few block props in the same style, so it reads as part of the same map. The slope gets steeper
-- one step at a time, from the old summit's 31 degrees to 52 at the top.
--
-- Runs in Lune when tools/assemble.luau builds StealASheep.rbxl, and in Studio for a preview
-- (tools/preview-upper-mountain.luau). Both pass in their own Instance and datatype constructors, and the code uses
-- only what both have: no raycasts, pivots or bounding boxes. Rebuilding destroys and replaces what it made.

local UpperMountain = {}

-- Where the old summit's ramp ends (Config/Olympus.Ramp's last point, on the floor along the corridor's middle).
local START_X = 3060
local START_Y = 1148.8
-- The corridor's middle (the map's floor slabs are centred here; Config/Olympus.LaneMiddleZ is 191).
local MIDDLE_Z = 193.45
-- Each stretch's length along its floor, in studs: a little longer than the map's first stages (about 250), so a god's
-- stretch takes as long to climb as theirs.
local SURFACE_LENGTH = 275
-- The decor counts in Themes were picked for 210-stud stretches; they scale with the length to keep that density.
local DECOR_SCALE = SURFACE_LENGTH / 210
-- In the map, stage 3's terrace unit repeats every 251.16 studs along the floor, each copy's ends overlapping the next's.
-- A stretch longer than one unit takes its ends from the neighbouring copies, laid along its floor like the first.
local TERRACE_REPEAT = 251.16
local SLAB_WIDTH = 190
-- The walkable lane in a stretch's own frame (x across: +x is world -z). Decor stays out of it so slides run clear;
-- the lane's own obstacles (Lane, below) go in it.
local LANE_HALF = 56
local FOLDER_NAME = "HighOlympus"
-- What the game keeps clear on each stretch, from Config/Olympus and Utils/Mountain (PastureSpots, GodHome): keep in
-- step. The lane's z range in the world, where on a tier its pasture starts and stops, and the god's spot.
local LANE_Z = { 140, 244 }
local PASTURE_FROM = 0.45
local PASTURE_TOP = 18
local SPAWNS_PER_TIER = 4
local GOD_BACK = 22
local GOD_Z = 217

type Env = {
	Instance: any,
	CFrame: any,
	Vector3: any,
	Color3: any,
	Enum: any,
	NumberRange: any,
	NumberSequence: any,
	NumberSequenceKeypoint: any,
	ColorSequence: any,
}

export type Section = {
	Tier: number,
	God: string,
	Area: string,
	Grade: number, -- degrees
	XStart: number,
	XEnd: number,
	YStart: number,
	YEnd: number,
}

-- The stretches in climbing order: tier, god, area, grade.
local STRETCHES: { { any } } = {
	{ 13, "Hypnos", "Poppy Fields", 32 },
	{ 14, "Morpheus", "Dream Steps", 33 },
	{ 15, "Deimos", "Dread Moon", 34 },
	{ 16, "Thanatos", "Asphodel Meadow", 36 },
	{ 17, "Nemesis", "Reckoning Ridge", 37 },
	{ 18, "Dionysus", "Vineyard Terraces", 38 },
	{ 19, "Hermes", "Messenger's Road", 39 },
	{ 20, "Hephaestus", "Great Forge", 40 },
	{ 21, "Ares", "War Camp", 41 },
	{ 22, "Aphrodite", "Rose Garden", 43 },
	{ 23, "Artemis", "Moonlit Forest", 44 },
	{ 24, "Apollo", "Sun Terrace", 45 },
	{ 25, "Athena", "Olive Grove", 46 },
	{ 26, "Demeter", "Harvest Fields", 47 },
	{ 27, "Hestia", "Eternal Hearth", 48 },
	{ 28, "Poseidon", "Cloudwater Falls", 49 },
	{ 29, "Hera", "Royal Courtyard", 51 },
	{ 30, "Zeus", "Throne of Olympus", 52 },
}

-- The stretches' positions: pure maths, so Config/Olympus can be checked against it.
function UpperMountain.Layout(): { Section }
	local sections: { Section } = {}
	local x, y = START_X, START_Y
	for _, row in STRETCHES do
		local grade = math.rad(row[4])
		local x2 = x + SURFACE_LENGTH * math.cos(grade)
		local y2 = y + SURFACE_LENGTH * math.sin(grade)
		table.insert(sections, {
			Tier = row[1],
			God = row[2],
			Area = row[3],
			Grade = row[4],
			XStart = x,
			XEnd = x2,
			YStart = y,
			YEnd = y2,
		})
		x, y = x2, y2
	end
	return sections
end

-- The lane's obstacles and terrain (defined below the shared props).
local Lane = {}

-- The commissioned stages' lane (z between these, with each piece's reach) and what in it stays solid.
local OLD_LANE_Z = { 140, 244 }
-- Models of more parts than this are a stage's floor, terraces or a big building: only their pillars in the lane go.
local DECOR_MOST_PARTS = 60
-- Stage 4's pyramids (two wedges each) lean into the lane's edges as banks: ramps, so they stay.
local PYRAMID_PARTS = 2

-- Scenery the client sets moving (src/client/Controllers/SceneryController): a tag and its numbers as attributes.
local Motion = {}

-- Bobs up and down `height` studs every `period` seconds.
function Motion.Bob(instance: any, height: number, period: number)
	if not instance then
		return
	end
	instance:AddTag("OlympusBob")
	instance:SetAttribute("BobHeight", height)
	instance:SetAttribute("BobPeriod", period)
end

-- Turns round `axis` through `center` at `speed` degrees a second.
function Motion.Spin(instance: any, center: any, axis: any, speed: number)
	instance:AddTag("OlympusSpin")
	instance:SetAttribute("SpinCenter", center)
	instance:SetAttribute("SpinAxis", axis)
	instance:SetAttribute("SpinSpeed", speed)
end

-- Its birds circle `center` (a level circle `radius` across) at `speed` degrees a second, flapping.
function Motion.Flock(instance: any, center: any, radius: number, speed: number)
	instance:AddTag("OlympusFlock")
	instance:SetAttribute("FlockCenter", center)
	instance:SetAttribute("FlockRadius", radius)
	instance:SetAttribute("FlockSpeed", speed)
end

-- A small seeded random (Park-Miller), the same in Lune and Studio.
local function newRandom(seed: number)
	local state = (seed * 7919) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	local random = {}
	function random.Number(lo: number, hi: number): number
		state = (state * 48271) % 2147483647
		return lo + (hi - lo) * (state / 2147483647)
	end
	function random.Int(lo: number, hi: number): number
		return math.floor(random.Number(lo, hi + 1 - 1e-9))
	end
	function random.Pick<T>(list: { T }): T
		return list[random.Int(1, #list)]
	end
	function random.Side(): number
		return if random.Number(0, 1) < 0.5 then -1 else 1
	end
	return random
end

-- Pixel sprites for the gods' props: one character a cell, "." empty. Built as blocks with depth.
local SPRITES: { [string]: { string } } = {
	Heart = {
		".RR...RR.",
		"RWRR.RRRR",
		"RRRRRRRRR",
		"RRRRRRRRR",
		".RRRRRRR.",
		"..RRRRR..",
		"...RRR...",
		"....R....",
	},
	Bolt = {
		"....YYY",
		"...YYY.",
		"..YYY..",
		".YYYYYY",
		"....YY.",
		"...YY..",
		"..YY...",
		".YY....",
		"YY.....",
	},
	Moon = {
		"..MMMM..",
		".MMM....",
		"MMM.....",
		"MMM.....",
		"MMM.....",
		"MMM.....",
		".MMM....",
		"..MMMM..",
	},
	Apple = {
		"....L...",
		"...LL...",
		".GGGGGG.",
		"GGGGGGGG",
		"GGWGGGGG",
		"GGGGGGGG",
		"GGGGGGGG",
		".GGGGGG.",
		"..GG.GG.",
	},
	Sword = {
		"..G..",
		"..H..",
		"..H..",
		"GGGGG",
		".SSS.",
		".SSS.",
		".SSS.",
		".SSS.",
		".SSS.",
		".SSS.",
		".SSS.",
		"..S..",
	},
	Star = {
		"...S...",
		"...S...",
		"SSSSSSS",
		".SSSSS.",
		"..SSS..",
		".SS.SS.",
		"SS...SS",
	},
	Ghost = {
		"..WWW..",
		".WWWWW.",
		"WWBWBWW",
		"WWWWWWW",
		"WWWWWWW",
		"WWWWWWW",
		"W.W.W.W",
	},
	Wing = {
		"WWWWW...",
		".WWWWWW.",
		"..WWWWWW",
		"...WWWWW",
		"....WWWW",
		".....WWW",
	},
	Grapes = {
		"....LL.",
		"...L...",
		".PPPPP.",
		"PPPPPPP",
		".PPPPP.",
		"..PPPP.",
		"..PPP..",
		"...P...",
	},
	Helmet = {
		"..RRRRRR.",
		".RRRRRRRR",
		"...BBBBB.",
		"..BBBBBBB",
		".BBBBBBBB",
		".B..BBBBB",
		".BB.BBBBB",
		".BB..BBB.",
		"..B...BB.",
	},
	Lyre = {
		"GG.......GG",
		".G.......G.",
		".GG.....GG.",
		"..GGGGGGG..",
		"..G.S.S.G..",
		"..G.S.S.G..",
		"..G.S.S.G..",
		"..G.S.S.G..",
		"..GGGGGGG..",
		"...GGGGG...",
	},
	Owl = {
		"B.....B",
		"BB...BB",
		"BBBBBBB",
		"WWBBBWW",
		"WKWBWKW",
		"WWBYBWW",
		".BBYBB.",
		".BLLLB.",
		".BLLLB.",
		"..BBB..",
		"..Y.Y..",
	},
	Trident = {
		"G...G...G",
		"G...G...G",
		"GG..G..GG",
		".GGGGGGG.",
		"....G....",
		"....G....",
		"....G....",
		"....G....",
		"....G....",
		"....G....",
		"....G....",
		"...GGG...",
	},
	Crown = {
		"G...G...G",
		"GG.GGG.GG",
		"GGGGGGGGG",
		"GRGGBGGRG",
		"GGGGGGGGG",
	},
	Zzz = {
		"ZZZZ",
		"..Z.",
		".Z..",
		"ZZZZ",
	},
	Eagle = {
		"BB.........BB",
		"BBB...W...BBB",
		".BBB.WWW.BBB.",
		".BBBBWKWBBBB.",
		"..BBBWYWBBB..",
		"...BBBYBBB...",
		"....BBBBB....",
		".....BBB.....",
		"....BB.BB....",
		"....T...T....",
	},
}

-- Map pieces the stretches are made of: { stage, model name or "" for any, part count, approximate height }.
local TEMPLATES: { [string]: { any } } = {
	Pine = { 1, "Tree1", 21, 32 },
	Pine2 = { 1, "Tree2", 19, 34 },
	Pine3 = { 1, "Tree3", 22, 34 },
	TwinTree = { 1, "Tree5", 33, 35 },
	RoundTree = { 1, "tree", 39, 31 },
	Bush = { 2, "Tree", 20, 33 },
	Bamboo = { 2, "Bamboo", 6, 41 },
	SnowPine = { 3, "Tree", 39, 38 },
	SmallPine = { 3, "Tree", 15, 27 },
	Stone1 = { 1, "Stone1", 4, 2 },
	Stone2 = { 1, "Stone2", 3, 2 },
	Stone3 = { 1, "Stone3", 4, 2 },
	Spire = { 4, "Model", 7, 38 },
	SmallSpire = { 4, "Model", 3, 19 },
	Pyramid = { 4, "Model", 2, 58 },
	BlossomTree = { 5, "Model", 19, 54 },
	Island = { 5, "Model", 4, 23 },
	BigArch = { 5, "Model", 19, 138 },
	Fence = { 5, "Model", 19, 23 },
	SmallArch = { 5, "Model", 11, 43 },
	Pavilion = { 6, "Model", 24, 35 },
	Lamp = { 7, "Model", 6, 43 },
	Cloud = { 7, "Model", 10, 75 },
}

-- Stage 3's floor and terrace colours, and what each becomes in a stretch.
local CLIFF_CAP = "178,214,211"
local CLIFF_SIDE_A = "165,155,104"
local CLIFF_SIDE_B = "185,173,116"

local function key(color: any): string
	return string.format(
		"%d,%d,%d",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function halfHeight(cf: any, size: any): number
	return math.abs(cf.RightVector.Y) * size.X / 2
		+ math.abs(cf.UpVector.Y) * size.Y / 2
		+ math.abs(cf.LookVector.Y) * size.Z / 2
end

local function parts(root: any): { any }
	local list = {}
	if root:IsA("BasePart") then
		table.insert(list, root)
	end
	for _, item in root:GetDescendants() do
		if item:IsA("BasePart") then
			table.insert(list, item)
		end
	end
	return list
end

-- Only ramps are solid in the commissioned stages' lane too (the user, 2026-10-06: at a slide's speed, dodging
-- things is too hard): its trees, bamboo, spires, arches, blossom trees, fences, the pavilion, lamps and the aqueduct's
-- and temple's columns are passed through, and left out of ground checks and the gods' line of sight. The floors,
-- terraces, dunes, pyramids and backdrop mountains stay. Returns how many parts it changed.
function UpperMountain.ClearOldLanes(stages: any): number
	local changed = 0
	local function pass(part: any)
		if part.CanCollide or part.CanQuery then
			changed += 1
		end
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
	local function inLane(part: any): boolean
		local reach = part.Size.Magnitude / 2
		local z = part.CFrame.Position.Z
		return z + reach > OLD_LANE_Z[1] and z - reach < OLD_LANE_Z[2]
	end
	for index = 1, 7 do
		local stage = stages:FindFirstChild(`Stage{index}`)
		if not stage then
			continue
		end
		for _, child in stage:GetChildren() do
			if not child:IsA("Model") then
				continue -- the dunes, backdrop mountains and stage 4's unions
			end
			local list = parts(child)
			if #list > DECOR_MOST_PARTS then
				-- Columns and their capitals standing in the lane; floors and roofs are far wider, terraces outside it.
				for _, part in list do
					local z = part.CFrame.Position.Z
					if math.max(part.Size.X, part.Size.Z) < 40 and z > OLD_LANE_Z[1] and z < OLD_LANE_Z[2] then
						pass(part)
					end
				end
			elseif #list ~= PYRAMID_PARTS then
				local reaches = false
				for _, part in list do
					if part.CanCollide and inLane(part) then
						reaches = true
						break
					end
				end
				if reaches then
					for _, part in list do
						pass(part)
					end
				end
			end
		end
	end
	return changed
end

function UpperMountain.Build(env: Env, workspace: any)
	local Instance, CFrame, Vector3, Color3, Enum = env.Instance, env.CFrame, env.Vector3, env.Color3, env.Enum
	local rgb = Color3.fromRGB

	local stages = workspace:FindFirstChild("Stages")
	assert(stages, "UpperMountain: the map's Stages folder is missing")
	local old = stages:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end

	-- The old summit's end wall (stage 7's 80-part terrace across the path's top) goes: the path carries on.
	local stage7 = stages:FindFirstChild("Stage7")
	-- Stage 7's dunes, the template for the lanes' ramps (the four 229-stud ones on its path).
	local duneTemplate
	if stage7 then
		for _, child in stage7:GetChildren() do
			if child:IsA("MeshPart") and math.abs(child.Size.X - 229) < 2 then
				duneTemplate = child
				break
			end
		end
	end
	assert(duneTemplate, "UpperMountain: stage 7's dunes are missing")
	UpperMountain.ClearOldLanes(stages)
	if stage7 then
		for _, child in stage7:GetChildren() do
			if child:IsA("Model") and #parts(child) == 80 then
				child:Destroy()
			end
		end
	end

	-- Stage 3's frame: its cliff terraces were built flat and tilted 10 degrees; its slab 12.
	local stage3 = stages:FindFirstChild("Stage3")
	assert(stage3, "UpperMountain: Stage3 is missing")
	local cliffBody, cliffCaps, slab
	for _, child in stage3:GetChildren() do
		if child:IsA("Model") then
			local count = #parts(child)
			if count == 198 then
				cliffBody = child
			elseif count == 67 then
				cliffCaps = child
			end
		end
	end
	assert(cliffBody and cliffCaps, "UpperMountain: stage 3's terraces are missing")
	for _, part in parts(cliffCaps) do
		if part.Size.Z > 200 then
			slab = part
		end
	end
	assert(slab, "UpperMountain: stage 3's floor slab is missing")
	local cliffFrame = CFrame.new(slab.CFrame.Position) * CFrame.fromEulerAnglesYXZ(math.rad(-10), math.pi / 2, 0)
	local cliffPieces: { { Part: any, Local: any } } = {}
	for _, model in { cliffBody, cliffCaps } do
		for _, part in parts(model) do
			if part ~= slab then
				table.insert(cliffPieces, { Part = part, Local = cliffFrame:Inverse() * part.CFrame })
			end
		end
	end
	local checker
	for _, child in slab:GetChildren() do
		if child:IsA("Texture") then
			checker = child
			break
		end
	end

	-- Decor templates: each un-tilted to stand upright, with its base point at its feet.
	type Template = { Pieces: { { Part: any, Local: any } }, Height: number }
	local templates: { [string]: Template } = {}
	local function untilt(model: any): Template
		local list = parts(model)
		-- The stage's tilt is a turn about world z; the most common one among its parts is the model's.
		local counts: { [number]: number } = {}
		local best, bestCount = 0, 0
		local sumX, sumY, sumZ = 0, 0, 0
		for _, part in list do
			local up = part.CFrame.UpVector
			local angle = math.floor(math.deg(math.atan2(-up.X, up.Y)) + 0.5)
			counts[angle] = (counts[angle] or 0) + 1
			if counts[angle] > bestCount then
				best, bestCount = angle, counts[angle]
			end
			sumX += part.CFrame.Position.X
			sumY += part.CFrame.Position.Y
			sumZ += part.CFrame.Position.Z
		end
		if math.abs(best) > 40 then
			best = 0
		end
		local center = Vector3.new(sumX / #list, sumY / #list, sumZ / #list)
		local flatten = CFrame.Angles(0, 0, math.rad(-best))
		local lowest, highest = math.huge, -math.huge
		local midX, midZ = 0, 0
		local flat = {}
		for _, part in list do
			local cf = flatten * (CFrame.new(-center) * part.CFrame)
			local half = halfHeight(cf, part.Size)
			lowest = math.min(lowest, cf.Position.Y - half)
			highest = math.max(highest, cf.Position.Y + half)
			midX += cf.Position.X / #list
			midZ += cf.Position.Z / #list
			table.insert(flat, { Part = part, Local = cf })
		end
		-- Its feet at the origin, centred.
		for _, piece in flat do
			piece.Local = CFrame.new(-midX, -lowest, -midZ) * piece.Local
		end
		return { Pieces = flat, Height = highest - lowest }
	end
	for name, spec in TEMPLATES do
		local stage = stages:FindFirstChild(`Stage{spec[1]}`)
		if not stage then
			continue
		end
		local found
		for _, child in stage:GetChildren() do
			if child:IsA("Model") and (spec[2] == "" or child.Name == spec[2]) and #parts(child) == spec[3] then
				local template = untilt(child)
				if math.abs(template.Height - spec[4]) < spec[4] * 0.35 + 3 then
					found = template
					break
				end
			end
		end
		if found then
			templates[name] = found
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	-- Colour helpers. Shade keeps a source colour's brightness relative to a reference, in the new hue.
	local function shade(target: any, sourceValue: number, reference: number): any
		local h, s, v = target:ToHSV()
		local scaled = math.clamp(v * sourceValue / math.max(reference, 0.05), 0, 1)
		return Color3.fromHSV(h, s, scaled)
	end
	local function isLeafy(color: any): boolean
		local h, s, v = color:ToHSV()
		if s < 0.22 and v > 0.6 then
			return true -- snow
		end
		return h > 0.13 and h < 0.55
	end

	local function newPart(parent: any, cf: any, size: any, color: any, props: { [string]: any }?): any
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = size
		part.CFrame = cf
		part.Color = color
		part.Material = Enum.Material.Plastic
		part.MaterialVariant = "Studs"
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if props then
			for name, value in props do
				part[name] = value
			end
		end
		part.Parent = parent
		return part
	end

	local sections = UpperMountain.Layout()
	local themes = UpperMountain.Themes(rgb)
	local function count(n: number): number
		return math.max(1, math.floor(n * DECOR_SCALE + 0.5))
	end

	for index, section in sections do
		local theme = themes[section.God]
		assert(theme, `UpperMountain: no theme for {section.God}`)
		local random = newRandom(section.Tier * 101)
		local grade = math.rad(section.Grade)
		local model = Instance.new("Model")
		model.Name = `Tier{section.Tier} {section.God}`
		model.Parent = folder
		local decor = Instance.new("Model")
		decor.Name = "Decor"
		decor.Parent = model

		-- The stretch's frame: at the middle of its floor, x across (+x is world -z), z uphill along the floor.
		local mid = Vector3.new((section.XStart + section.XEnd) / 2, (section.YStart + section.YEnd) / 2, MIDDLE_Z)
		local frame = CFrame.new(mid) * CFrame.fromEulerAnglesYXZ(-grade, math.pi / 2, 0)
		local upright = CFrame.fromEulerAnglesYXZ(0, math.pi / 2, 0)
		local half = SURFACE_LENGTH / 2

		-- Floor, overlapping its neighbours by 4 at each end. The last stops at the top, where the summit plaza starts
		-- flush with it: an overhang there is a ledge a walker can't get onto.
		local floor = slab:Clone()
		floor.Name = "Floor"
		local overlapUp = if index == #sections then 0 else 4
		floor.Size = Vector3.new(SLAB_WIDTH, slab.Size.Y, SURFACE_LENGTH + 4 + overlapUp)
		floor.CFrame = frame * CFrame.new(0, -slab.Size.Y / 2, (overlapUp - 4) / 2)
		floor.Color = theme.Floor
		floor.Parent = model

		-- Terraces: stage 3's, trimmed to this stretch's length; their tops are the ground decor stands on.
		local terraces = Instance.new("Model")
		terraces.Name = "Terraces"
		terraces.Parent = model
		local tops: { { number } } = {}
		for _, copy in { 0, -1, 1 } do
			local shift = CFrame.new(0, -slab.Size.Y / 2, copy * TERRACE_REPEAT)
			for _, piece in cliffPieces do
				local localCf = shift * piece.Local
				if math.abs(localCf.Position.Z) > half + 6 then
					continue
				end
				local part = piece.Part:Clone()
				part.CFrame = frame * localCf
				local source = key(piece.Part.Color)
				if source == CLIFF_CAP then
					part.Color = if theme.CapAt then theme.CapAt(localCf.Position, random) else theme.Cap
				elseif source == CLIFF_SIDE_A then
					part.Color = theme.SideA
				elseif source == CLIFF_SIDE_B then
					part.Color = theme.SideB
				else
					part.Color = theme.SideA
				end
				part.Parent = terraces
				local size = part.Size
				local p = localCf.Position
				local hx = math.abs(localCf.RightVector.X) * size.X / 2
					+ math.abs(localCf.UpVector.X) * size.Y / 2
					+ math.abs(localCf.LookVector.X) * size.Z / 2
				local hz = math.abs(localCf.RightVector.Z) * size.X / 2
					+ math.abs(localCf.UpVector.Z) * size.Y / 2
					+ math.abs(localCf.LookVector.Z) * size.Z / 2
				table.insert(tops, { p.X - hx, p.X + hx, p.Z - hz, p.Z + hz, p.Y + halfHeight(localCf, size) })
			end
		end

		local function ground(x: number, z: number): number
			local y = 0
			for _, top in tops do
				if x >= top[1] and x <= top[2] and z >= top[3] and z <= top[4] and top[5] > y then
					y = top[5]
				end
			end
			return y
		end

		-- A point on the stretch (x across, z along, y above the floor) in world space.
		local function at(x: number, y: number, z: number): any
			return frame * Vector3.new(x, y, z)
		end

		-- Places a template tilted with the slope like the old stages' pieces (upright ones look as if they're toppling
		-- downhill on the steep stretches), or `Upright` for things floating off the mountain, turned `yaw` degrees,
		-- recoloured part by part.
		local function place(name: string, x: number, z: number, options: { [string]: any }?): any
			local template = templates[name]
			if not template then
				return nil
			end
			local opts = options or {}
			local scale = opts.Scale or 1
			local y = if opts.Y then opts.Y else ground(x, z) - (opts.Sink or 0.3)
			local base
			if opts.Upright then
				base = CFrame.new(at(x, y, z))
			else
				base = frame * CFrame.new(x, y, z) * CFrame.fromEulerAnglesYXZ(0, -math.pi / 2, 0)
			end
			base = base * CFrame.Angles(0, math.rad(opts.Yaw or random.Number(0, 360)), 0)
			if opts.Roll then
				base = base * CFrame.Angles(math.rad(opts.Roll[1]), 0, math.rad(opts.Roll[2]))
			end
			local holder = Instance.new("Model")
			holder.Name = opts.Name or name
			-- Reference brightness per role, for shading.
			local leafRef, woodRef, allRef = 0, 0, 0
			local leafCount, woodCount = 0, 0
			for _, piece in template.Pieces do
				local _, _, v = piece.Part.Color:ToHSV()
				allRef = math.max(allRef, v)
				if isLeafy(piece.Part.Color) then
					leafRef += v
					leafCount += 1
				else
					woodRef += v
					woodCount += 1
				end
			end
			leafRef = if leafCount > 0 then leafRef / leafCount else 0.6
			woodRef = if woodCount > 0 then woodRef / woodCount else 0.6
			for i, piece in template.Pieces do
				local part = piece.Part:Clone()
				local cf = piece.Local
				if scale ~= 1 then
					cf = CFrame.new(cf.Position * scale) * (CFrame.new(-cf.Position) * cf)
					part.Size = part.Size * scale
				end
				part.CFrame = base * cf
				local source = piece.Part.Color
				local _, _, v = source:ToHSV()
				if opts.Color then
					part.Color = opts.Color(part, source, i, v / math.max(allRef, 0.05))
				elseif opts.Solid then
					part.Color = shade(opts.Solid, v, allRef)
				elseif isLeafy(source) then
					part.Color = shade(opts.Leaves or theme.Leaves, v, leafRef)
				else
					part.Color = shade(opts.Wood or theme.Trunk, v, woodRef)
				end
				if opts.Neon then
					part.Material = Enum.Material.Neon
				end
				if opts.Ghost then
					part.CanCollide = false
				end
				part.Parent = holder
			end
			holder.Parent = opts.Parent or decor
			return holder
		end

		-- A block at (x, y, z) in the stretch's frame, tilted with the slope (or `Upright`), turned `yaw` degrees.
		local function block(x: number, y: number, z: number, size: any, color: any, props: { [string]: any }?): any
			local yaw = props and props.Yaw or 0
			local cf = if props and props.Upright
				then CFrame.new(at(x, y, z)) * upright
				else frame * CFrame.new(x, y, z)
			cf = cf * CFrame.Angles(0, math.rad(yaw), 0)
			if props and props.Turn then
				cf = cf * props.Turn
			end
			local extra: { [string]: any } = {}
			if props then
				for name, value in props do
					if name ~= "Yaw" and name ~= "Turn" and name ~= "Parent" and name ~= "Upright" then
						extra[name] = value
					end
				end
			end
			return newPart(props and props.Parent or decor, cf, size, color, extra)
		end

		-- A pixel sprite standing at (x, z) on the ground, facing the lane, `cell` studs a pixel; tilted with the slope
		-- unless `Upright`.
		local function sprite(
			name: string,
			x: number,
			z: number,
			cell: number,
			legend: { [string]: any },
			options: { [string]: any }?
		): any
			local rows = SPRITES[name]
			local opts = options or {}
			local holder = Instance.new("Model")
			holder.Name = name
			local width = #rows[1]
			local lift = opts.Lift or 0
			local y0 = (if opts.Y then opts.Y else ground(x, z)) + lift
			local face = if x > 0 then 90 else -90
			local yaw = opts.Yaw or face
			-- `Frame`: stand it in this frame instead (the top of a post).
			local stood = if opts.Upright then CFrame.new(at(x, y0, z)) * upright else frame * CFrame.new(x, y0, z)
			local base = (opts.Frame or stood) * CFrame.Angles(0, math.rad(yaw), 0)
			if opts.Tip then
				base = base * CFrame.Angles(0, 0, math.rad(opts.Tip))
			end
			for r, row in rows do
				local c = 1
				while c <= width do
					local char = string.sub(row, c, c)
					if char == "." then
						c += 1
						continue
					end
					local run = c
					while run + 1 <= width and string.sub(row, run + 1, run + 1) == char do
						run += 1
					end
					local cells = run - c + 1
					local color = legend[char] or legend.Default
					local centerX = ((c + run) / 2 - (width + 1) / 2) * cell
					local centerY = (#rows - r + 0.5) * cell
					local part = newPart(
						holder,
						base * CFrame.new(centerX, centerY, 0),
						Vector3.new(cells * cell, cell, cell),
						color
					)
					if opts.Neon and (opts.Neon == true or opts.Neon[char]) then
						part.Material = Enum.Material.Neon
					end
					if opts.Ghost then
						part.CanCollide = false
					end
					c = run + 1
				end
			end
			holder.Parent = opts.Parent or decor
			return holder
		end

		-- Somewhere on the terraces or the floor's edge, either side, never in the lane.
		local function sideSpot(minX: number?, maxX: number?): (number, number)
			-- The slab is 190 wide: past 90 a prop would hang off its edge.
			local x = random.Number(minX or LANE_HALF + 4, math.min(maxX or 90, 90)) * random.Side()
			local z = random.Number(-half + 10, half - 10)
			return x, z
		end

		-- A block lying in the floor's frame (tilted with the slope like the terraces), `y` up from the floor, turned
		-- `Yaw` degrees about the floor's normal.
		local function tilted(x: number, y: number, z: number, size: any, color: any, props: { [string]: any }?): any
			local cf = frame * CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(props and props.Yaw or 0), 0)
			if props and props.Turn then
				cf = cf * props.Turn
			end
			local extra: { [string]: any } = {}
			if props then
				for name, value in props do
					if name ~= "Yaw" and name ~= "Turn" and name ~= "Parent" then
						extra[name] = value
					end
				end
			end
			return newPart(props and props.Parent or decor, cf, size, color, extra)
		end

		-- A frame standing on the floor at (x, z), or on a surface `lift` studs above it (a knoll's top), tilted with the
		-- slope like the old stages' pieces (upright ones look as if they're toppling downhill on the steep stretches):
		-- x across, y out of the floor, z uphill.
		local function stand(x: number, z: number, lift: number?): any
			return frame * CFrame.new(x, lift or 0, z)
		end

		-- One of the map's dunes lying in the lane at (x, z), `size` studs, gentle side uphill, turned `yaw` degrees: the
		-- only solid thing in a lane (its Ramp attribute).
		local function dune(x: number, z: number, size: any, yaw: number, color: any, parent: any): any
			local part = duneTemplate:Clone()
			part.Name = "Dune"
			part.Size = size
			part.CFrame = frame * CFrame.new(x, 0, z) * CFrame.Angles(0, math.pi + math.rad(yaw), 0)
			part.Color = color
			part:SetAttribute("Ramp", true)
			part.Parent = parent
			return part
		end

		-- A particle emitter on an invisible part. `spec`: Texture, Color (Color3 or two), Size and Transparency
		-- ({ { time, value } }), Lifetime, Speed (numbers or { min, max }), Rate and any other emitter property.
		local function emitter(parent: any, cf: any, size: any, spec: { [string]: any }): any
			local holder = newPart(parent, cf, size, rgb(255, 255, 255), {
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				CastShadow = false,
			})
			holder.Name = spec.Name or "Emitter"
			local function range(value: any): any
				return if type(value) == "table"
					then env.NumberRange.new(value[1], value[2])
					else env.NumberRange.new(value)
			end
			local function sequence(points: { { number } }): any
				local keypoints = {}
				for _, point in points do
					table.insert(keypoints, env.NumberSequenceKeypoint.new(point[1], point[2]))
				end
				return env.NumberSequence.new(keypoints)
			end
			local particles = Instance.new("ParticleEmitter")
			for name, value in spec do
				if name == "Name" then
					continue
				elseif name == "Color" then
					particles.Color = if type(value) == "table"
						then env.ColorSequence.new(value[1], value[2])
						else env.ColorSequence.new(value)
				elseif name == "Size" or name == "Transparency" then
					particles[name] = sequence(value)
				elseif name == "Lifetime" or name == "Speed" or name == "Rotation" or name == "RotSpeed" then
					particles[name] = range(value)
				else
					particles[name] = value
				end
			end
			particles.Parent = holder
			return holder
		end

		local ctx = {
			Random = random,
			Half = half,
			Lane = LANE_HALF,
			Grade = grade,
			Ground = ground,
			At = at,
			Place = place,
			Block = block,
			Sprite = sprite,
			SideSpot = sideSpot,
			Frame = frame,
			Upright = upright,
			Decor = decor,
			Model = model,
			CFrame = CFrame,
			Vector3 = Vector3,
			Color3 = Color3,
			Enum = Enum,
			Instance = Instance,
			NewPart = newPart,
			Rgb = rgb,
			Index = index,
			Count = count,
			Section = section,
			Tilted = tilted,
			Stand = stand,
			Emitter = emitter,
			Dune = dune,
			LaneRandom = newRandom(section.Tier * 101 + 57),
			-- Filled by Lane.Build: the outcrops and knoll as { X1, X2, Z1, Z2 }, for the edge props to keep off.
			Walls = {},
		}

		-- Plants on the terraces and the floor's edges.
		for _, entry in theme.Plants or {} do
			for _ = 1, count(entry[2]) do
				local x, z = sideSpot(entry[3] or LANE_HALF + 9, entry[4])
				place(entry[1], x, z, { Scale = random.Number(0.85, 1.15), Leaves = entry.Leaves })
			end
		end
		-- Rocks.
		for _ = 1, count(theme.Stones or 6) do
			local x, z = sideSpot(LANE_HALF + 2, 100)
			place(
				random.Pick({ "Stone1", "Stone2", "Stone3" }),
				x,
				z,
				{ Solid = theme.Stone, Scale = random.Number(1.2, 2.2) }
			)
		end
		-- Floating islands and clouds off to the sides.
		for i = 1, count(theme.Islands or 3) do
			local side = if i % 2 == 0 then 1 else -1
			local x = side * random.Number(135, 210)
			local z = random.Number(-half, half)
			local island = place("Island", x, z, {
				Y = random.Number(-10, 45),
				Upright = true,
				Scale = random.Number(0.8, 1.4),
				Color = function(_part: any, source: any, _i: number, value: number): any
					local h = select(1, source:ToHSV())
					if h > 0.1 and h < 0.2 then
						return theme.CapAt and theme.CapAt(Vector3.new(x, 0, z), random) or theme.Cap
					end
					return shade(theme.SideB, value, 1)
				end,
			})
			-- Motion's numbers come from the index, not `random`, so the decor after them keeps its places.
			Motion.Bob(island, 3 + (i % 3), 6 + (i % 4))
		end
		for i = 1, count(theme.Clouds or 2) do
			local side = if i % 2 == 0 then -1 else 1
			local cloud = place("Cloud", side * random.Number(170, 320), random.Number(-half, half), {
				Y = random.Number(40, 120),
				Upright = true,
				Solid = theme.Cloud or rgb(214, 214, 214),
				Ghost = true,
				Scale = random.Number(0.5, 0.8),
			})
			Motion.Bob(cloud, 3, 14 + (i % 3) * 3)
		end
		-- The lane's outcrops, knoll, obstacles, floor patches and particles, on their own random stream so the decor
		-- above keeps its places. Built before the props so edge props can keep off the outcrops.
		if theme.Obstacles then
			Lane.Build(ctx, theme)
		end
		if theme.Props then
			theme.Props(ctx, theme)
		end
	end

	-- The summit plaza above Zeus's stretch: a flat terrace with his throne.
	local last = sections[#sections]
	local summit = Instance.new("Model")
	summit.Name = "Summit"
	summit.Parent = folder
	local zeus = themes.Zeus
	local plazaLength = 90
	local plazaCenter = Vector3.new(last.XEnd + plazaLength / 2, last.YEnd, MIDDLE_Z)
	local plaza = slab:Clone()
	plaza.Name = "Plaza"
	plaza.Size = Vector3.new(SLAB_WIDTH, slab.Size.Y, plazaLength)
	plaza.CFrame = CFrame.new(plazaCenter - Vector3.new(0, slab.Size.Y / 2, 0))
		* CFrame.fromEulerAnglesYXZ(0, math.pi / 2, 0)
	plaza.Color = zeus.Floor
	plaza.Parent = summit
	local gold = zeus.Cap
	local marble = rgb(232, 228, 220)
	local function summitPart(offset: any, size: any, color: any, neon: boolean?): any
		return newPart(
			summit,
			CFrame.new(plazaCenter + offset),
			size,
			color,
			if neon then { Material = Enum.Material.Neon } else nil
		)
	end
	-- Steps up to the throne, then the throne itself (facing back down the mountain, -x).
	local throneX = plazaLength / 2 - 22
	summitPart(Vector3.new(throneX - 6, 1, 0), Vector3.new(26, 2, 56), marble)
	summitPart(Vector3.new(throneX - 2, 3, 0), Vector3.new(20, 2, 46), marble)
	summitPart(Vector3.new(throneX + 2, 5, 0), Vector3.new(14, 2, 36), gold)
	summitPart(Vector3.new(throneX + 2, 9, 0), Vector3.new(12, 6, 22), gold) -- seat
	summitPart(Vector3.new(throneX + 7, 22, 0), Vector3.new(3, 32, 22), gold) -- back
	summitPart(Vector3.new(throneX + 7, 40, 0), Vector3.new(3, 4, 14), gold)
	summitPart(Vector3.new(throneX + 7, 43, 0), Vector3.new(3, 3, 6), gold)
	summitPart(Vector3.new(throneX + 2, 15, 12.5), Vector3.new(12, 3, 3), gold) -- arms
	summitPart(Vector3.new(throneX + 2, 15, -12.5), Vector3.new(12, 3, 3), gold)
	summitPart(Vector3.new(throneX + 2, 9, 12.5), Vector3.new(3, 9, 3), gold)
	summitPart(Vector3.new(throneX + 2, 9, -12.5), Vector3.new(3, 9, 3), gold)
	summitPart(Vector3.new(throneX + 6, 28, 0), Vector3.new(1, 10, 10), zeus.Glow, true) -- a bolt's glow on the back
	-- Columns round the plaza.
	for i = -2, 2 do
		for _, side in { -1, 1 } do
			local offset = Vector3.new(i * 18, 0, side * 80)
			summitPart(offset + Vector3.new(0, 1, 0), Vector3.new(10, 2, 10), marble)
			summitPart(offset + Vector3.new(0, 18, 0), Vector3.new(6, 32, 6), marble)
			summitPart(offset + Vector3.new(0, 35, 0), Vector3.new(10, 2, 10), gold)
		end
	end
	summitPart(Vector3.new(0, 37, 80), Vector3.new(86, 2, 12), marble)
	summitPart(Vector3.new(0, 37, -80), Vector3.new(86, 2, 12), marble)

	folder.Parent = stages
	return folder
end

-- Block props shared by several gods. `c` is a stretch's context (Build); x across, z along, on the ground there.
local Props = {}

function Props.Column(c: any, x: number, z: number, stone: any, trim: any, height: number?)
	local h = height or 26
	local y = c.Ground(x, z)
	local V = c.Vector3
	c.Block(x, y + 1, z, V.new(8, 2, 8), trim)
	c.Block(x, y + 2 + h / 2, z, V.new(5, h, 5), stone)
	c.Block(x, y + 3 + h, z, V.new(8, 2, 8), trim)
end

-- A torch or brazier: stone foot, bowl and two neon flames.
function Props.Fire(c: any, x: number, z: number, stone: any, bowl: any, big: boolean?)
	local y = c.Ground(x, z)
	local V = c.Vector3
	local k = if big then 1.6 else 1
	local neon = { Material = c.Enum.Material.Neon, CanCollide = false }
	c.Block(x, y + 3 * k, z, V.new(2.5 * k, 6 * k, 2.5 * k), stone)
	c.Block(x, y + 6.8 * k, z, V.new(5 * k, 1.6 * k, 5 * k), bowl)
	c.Block(x, y + 9 * k, z, V.new(3 * k, 3.4 * k, 3 * k), c.Rgb(255, 140, 50), neon)
	c.Block(x, y + 10 * k, z, V.new(1.7 * k, 3 * k, 1.7 * k), c.Rgb(255, 214, 90), neon)
end

-- A flower: stem, four petals and a middle.
function Props.Flower(c: any, x: number, z: number, petal: any, middle: any)
	local y = c.Ground(x, z)
	local V = c.Vector3
	local yaw = c.Random.Number(0, 90)
	c.Block(x, y + 1.5, z, V.new(0.5, 3, 0.5), c.Rgb(96, 150, 84), { CanCollide = false })
	for i = 0, 3 do
		local a = math.rad(yaw + i * 90)
		c.Block(
			x + math.cos(a) * 0.9,
			y + 3.1,
			z + math.sin(a) * 0.9,
			V.new(1.4, 0.5, 1.4),
			petal,
			{ CanCollide = false }
		)
	end
	c.Block(x, y + 3.3, z, V.new(0.9, 0.6, 0.9), middle, { CanCollide = false })
end

-- A crater: a raised rim of blocks round a dark floor.
function Props.Crater(c: any, x: number, z: number, rim: any, inside: any, radius: number)
	local y = c.Ground(x, z)
	local V = c.Vector3
	c.Block(x, y + 0.15, z, V.new(radius * 1.7, 0.3, radius * 1.7), inside, { Yaw = 45 })
	local count = 10
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		c.Block(
			x + math.cos(a) * radius,
			y + 0.9,
			z + math.sin(a) * radius,
			V.new(3.5, 1.8, 4),
			rim,
			{ Yaw = -math.deg(a) }
		)
	end
end

-- A wheel on a post at a terrace's edge, its face towards the lane, turning.
function Props.Wheel(c: any, x: number, z: number, colors: { any }, hub: any)
	local y = c.Ground(x, z)
	local V = c.Vector3
	local center = y + 20
	c.Block(x, y + 9, z, V.new(3, 18, 3), hub)
	local wheel = c.Instance.new("Model")
	wheel.Name = "Wheel"
	for i = 0, 15 do
		local a = (i + 0.5) * math.pi * 2 / 16
		c.Block(x, center + math.sin(a) * 13, z + math.cos(a) * 13, V.new(2, 4, 5.4), colors[i % #colors + 1], {
			Turn = c.CFrame.Angles(-a, 0, 0),
			Parent = wheel,
		})
	end
	for i = 0, 3 do
		c.Block(
			x,
			center,
			z,
			V.new(1.4, 24, 1.4),
			hub,
			{ Turn = c.CFrame.Angles(math.rad(i * 45), 0, 0), Parent = wheel }
		)
	end
	c.Block(x, center, z, V.new(2.6, 4, 4), hub, { Parent = wheel })
	wheel.Parent = c.Decor
	Motion.Spin(wheel, c.At(x, center, z), c.Frame.RightVector, 12)
end

-- A fan of ribs standing at (x, z) from a hinge at height y, facing the path: a shell, a peacock's tail.
function Props.Fan(c: any, x: number, y: number, z: number, ribs: number, length: number, colors: { any }, tip: any?)
	local V = c.Vector3
	for i = 0, ribs - 1 do
		local a = math.rad(-75 + i * 150 / (ribs - 1))
		local dy, dz = math.cos(a), math.sin(a)
		c.Block(x, y + dy * length / 2, z + dz * length / 2, V.new(0.8, length, 2.6), colors[i % #colors + 1], {
			Turn = c.CFrame.Angles(a, 0, 0),
		})
		if tip then
			c.Block(x, y + dy * length, z + dz * length, V.new(2.4, 2.4, 2.4), tip, { Shape = c.Enum.PartType.Ball })
		end
	end
end

-- `count` things on the terraces or the floor's edges, made by `make(x, z)`.
function Props.Scatter(c: any, count: number, make: (number, number) -> (), minX: number?, maxX: number?)
	for _ = 1, c.Count(count) do
		local x, z = c.SideSpot(minX, maxX)
		make(x, z)
	end
end

-- Along both lane edges, alternating sides every `step / 2` studs: torches, columns, banners. Not where an outcrop
-- reaches into the lane.
function Props.Edges(c: any, step: number, make: (number, number) -> ())
	local z = -c.Half + step / 2
	local side = 1
	while z < c.Half - 6 do
		local x = side * (c.Lane + 5)
		local walled = false
		for _, wall in c.Walls do
			if x * wall[1] > 0 and z > wall[3] - 6 and z < wall[4] + 6 then
				walled = true
			end
		end
		if not walled then
			make(x, z)
		end
		side = -side
		z += step / 2
	end
end

-- The lane (2026-10-06). The old stages have trees, snowmen, arches and lamps in their lanes; these stretches get the
-- same: rock outcrops of the terraces' stacked blocks reaching in from the sides, a knoll splitting the path round
-- the god's landmark, the god's obstacles at about the old stages' density (more each tier), flat patches on the floor
-- and the god's particles. A slider always has a gap of MIN_GAP studs somewhere across, and the pasture's lamb spots,
-- the god's spot and the gate at the foot stay clear.

-- Room a slider needs between obstacles at every point down a stretch, in studs across.
local MIN_GAP = 30
-- Walking room between two obstacles.
local SPACING = 6
-- Kept clear: the foot of each stretch (its gate and sign) and its top.
local FOOT_CLEAR = 30
local TOP_CLEAR = 14
-- The map's dunes (stage 7's rolling mounds; one mesh): the share of their size each way that stands above the
-- floor, how high their crest is for their height, and how far downhill of their middle it sits. Laid with their
-- gentle side uphill, so a slide rides up and leaves the crest in a jump; their steep side faces down the mountain.
local DUNE_REACH = 0.3
local DUNE_TOP = 0.32
local DUNE_CREST = 0.08

-- The box a dune `w` by `l` turned `yaw` degrees at (x, z) stands on above the floor.
local function duneBox(x: number, z: number, w: number, l: number, yaw: number): { [string]: any }
	local a = math.rad(yaw)
	local hx = DUNE_REACH * (math.abs(math.cos(a)) * w + math.abs(math.sin(a)) * l)
	local hz = DUNE_REACH * (math.abs(math.sin(a)) * w + math.abs(math.cos(a)) * l)
	return { X1 = x - hx, X2 = x + hx, Z1 = z - hz, Z2 = z + hz, Ramp = true }
end
-- Studs kept clear round a lamb spot and the god's spot.
local SPOT_CLEAR = 10
-- The path up the lane, a line nothing solid stands on (the user, 2026-10-06): its centre swings PATH_SWING studs
-- either side, a full bend every 2 pi PATH_BEND studs along, gentle enough to follow at a slide's top speed (100);
-- obstacles keep PATH_CLEAR studs from its centre line, and it's drawn PATH_WIDTH wide.
local PATH_SWING = 18
local PATH_BEND = 52
local PATH_CLEAR = 11
local PATH_WIDTH = 12

-- The narrowest open run across the lane at `z`, given the shapes (circles { X, Z, R }, boxes { X1, X2, Z1, Z2 });
-- dunes (`Ramp`) don't close it.
local function gapAt(shapes: { any }, z: number): number
	local cells: { [number]: boolean } = {}
	local count = LANE_HALF -- two-stud cells across the lane
	for _, shape in shapes do
		if shape.Ramp then
			continue
		end
		local lo, hi
		if shape.R then
			local dz = math.abs(z - shape.Z)
			if dz < shape.R then
				local w = math.sqrt(shape.R * shape.R - dz * dz)
				lo, hi = shape.X - w, shape.X + w
			end
		elseif z >= shape.Z1 and z <= shape.Z2 then
			lo, hi = shape.X1, shape.X2
		end
		if lo then
			local from = math.max(1, math.floor((lo + LANE_HALF) / 2) + 1)
			for i = from, math.min(count, math.ceil((hi + LANE_HALF) / 2)) do
				cells[i] = true
			end
		end
	end
	local best, run = 0, 0
	for i = 1, count do
		if cells[i] then
			run = 0
		else
			run += 1
			best = math.max(best, run)
		end
	end
	return best * 2
end

-- The spots the game keeps clear on a stretch, in its frame: the four lamb spots and the god's.
local function keepClear(c: any): { { number } }
	local section = c.Section
	local midX = (section.XStart + section.XEnd) / 2
	local cosine = math.cos(c.Grade)
	local middleZ = MIDDLE_Z
	local spots = {}
	local from = section.XStart + (section.XEnd - section.XStart) * PASTURE_FROM
	local to = section.XEnd - PASTURE_TOP
	for index = 1, SPAWNS_PER_TIER do
		local share = (index - 0.5) / SPAWNS_PER_TIER
		local worldX = from + (to - from) * (if index % 2 == 0 then 0.35 else 0.75)
		local worldZ = LANE_Z[1] + 14 + (LANE_Z[2] - LANE_Z[1] - 28) * share
		table.insert(spots, { middleZ - worldZ, (worldX - midX) / cosine })
	end
	table.insert(spots, { middleZ - GOD_Z, (section.XEnd - GOD_BACK - midX) / cosine })
	return spots
end

-- Whether `shape` fits: clear of the kept spots and the other shapes, leaving the gap everywhere along it.
local function fits(c: any, shapes: { any }, shape: any, spots: { { number } }): boolean
	local z1 = if shape.R then shape.Z - shape.R else shape.Z1
	local z2 = if shape.R then shape.Z + shape.R else shape.Z2
	if z1 < -c.Half + FOOT_CLEAR or z2 > c.Half - TOP_CLEAR then
		return false
	end
	for _, spot in spots do
		local distance
		if shape.R then
			distance = math.sqrt((spot[1] - shape.X) ^ 2 + (spot[2] - shape.Z) ^ 2) - shape.R
		else
			local dx = math.max(shape.X1 - spot[1], spot[1] - shape.X2, 0)
			local dz = math.max(shape.Z1 - spot[2], spot[2] - shape.Z2, 0)
			distance = math.sqrt(dx * dx + dz * dz)
		end
		if distance < SPOT_CLEAR then
			return false
		end
	end
	-- Off the path: its centre line, sampled every 2 studs along, stays PATH_CLEAR from the shape.
	local pathX = c.PathX
	if pathX then
		local reach = if shape.R then shape.R else 0
		local z = z1 - PATH_CLEAR - reach
		while z <= z2 + PATH_CLEAR + reach do
			local px = pathX(z)
			local distance
			if shape.R then
				distance = math.sqrt((px - shape.X) ^ 2 + (z - shape.Z) ^ 2) - shape.R
			else
				local dx = math.max(shape.X1 - px, px - shape.X2, 0)
				local dz = math.max(shape.Z1 - z, z - shape.Z2, 0)
				distance = math.sqrt(dx * dx + dz * dz)
			end
			if distance < PATH_CLEAR then
				return false
			end
			z += 2
		end
	end
	if shape.R then
		for _, other in shapes do
			if other.R then
				local d = math.sqrt((other.X - shape.X) ^ 2 + (other.Z - shape.Z) ^ 2)
				if d < other.R + shape.R + SPACING then
					return false
				end
			else
				local dx = math.max(other.X1 - shape.X, shape.X - other.X2, 0)
				local dz = math.max(other.Z1 - shape.Z, shape.Z - other.Z2, 0)
				if math.sqrt(dx * dx + dz * dz) < shape.R + SPACING then
					return false
				end
			end
		end
	end
	table.insert(shapes, shape)
	local z = if shape.Ramp then z2 + 1 else z1
	while z <= z2 do
		if gapAt(shapes, z) < MIN_GAP then
			table.remove(shapes)
			return false
		end
		z += 2
	end
	return true
end

function Lane.Build(c: any, theme: any)
	local random = c.LaneRandom
	local Instance = c.Instance
	local lane = Instance.new("Model")
	lane.Name = "Lane"
	lane.Parent = c.Model
	local function folder(name: string): any
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = lane
		return model
	end
	local outcrops, obstacles, patches, life =
		folder("Outcrops"), folder("Obstacles"), folder("Patches"), folder("Life")
	local spots = keepClear(c)
	local shapes = {}
	local usable = c.Half * 2 - FOOT_CLEAR - TOP_CLEAR
	-- The path first: everything else keeps off it.
	local phase = random.Number(0, math.pi * 2)
	local function pathX(z: number): number
		return math.sin(z / PATH_BEND + phase) * PATH_SWING
	end
	c.PathX = pathX

	-- The knoll first, the stretch's landmark: a big dune beside the path with the god's landmark on its crest.
	for _ = 1, 200 do
		local w, l, h = random.Number(64, 76), random.Number(60, 72), random.Number(34, 40)
		local yaw = random.Number(-15, 15)
		local x = random.Number(-LANE_HALF + w * DUNE_REACH + 4, LANE_HALF - w * DUNE_REACH - 4)
		local z = random.Number(-c.Half + FOOT_CLEAR + l * DUNE_REACH, c.Half - TOP_CLEAR - l * DUNE_REACH)
		local box = duneBox(x, z, w, l, yaw)
		if fits(c, shapes, box, spots) then
			local model = Instance.new("Model")
			model.Name = "Knoll"
			model.Parent = outcrops
			c.Dune(x, z, c.Vector3.new(w, h, l), yaw, theme.Cap, model)
			table.insert(c.Walls, { 0, 0, box.Z1, box.Z2 })
			if theme.Knoll then
				theme.Knoll(c, x, h * DUNE_TOP, z - l * DUNE_CREST, model)
			end
			break
		end
	end

	-- Smaller dunes at the lane's sides, alternating, spread along the stretch.
	local duneCount = theme.Dunes or (if c.Index <= 6 then 2 else 3)
	local side = random.Side()
	for i = 1, duneCount do
		for _ = 1, 40 do
			local w, l, h = random.Number(46, 56), random.Number(42, 52), random.Number(24, 30)
			local x = side * random.Number(36, 46)
			local z = -c.Half + FOOT_CLEAR + usable * (i - 0.5) / duneCount + random.Number(-20, 20)
			local yaw = random.Number(-25, 25)
			local box = duneBox(x, z, w, l, yaw)
			box.X1, box.X2 = math.max(box.X1, -LANE_HALF), math.min(box.X2, LANE_HALF)
			if fits(c, shapes, box, spots) then
				local model = Instance.new("Model")
				model.Name = "Outcrop"
				model.Parent = outcrops
				c.Dune(x, z, c.Vector3.new(w, h, l), yaw, theme.Cap, model)
				table.insert(c.Walls, { side, 0, box.Z1, box.Z2 })
				break
			end
		end
		side = -side
	end

	-- Obstacles, one to each slice of the stretch so they spread like the old stages', more each tier.
	-- 20% fewer than the first mock-up's 12 rising to 18 (the user, 2026-10-06).
	local count = theme.ObstacleCount or math.floor((12 + (c.Index - 1) * 0.35) * 0.8 + 0.5)
	local total = 0
	for _, entry in theme.Obstacles do
		total += entry[1]
	end
	local slice = usable / count
	for i = 1, count do
		for _ = 1, 80 do
			local pick = random.Number(0, total)
			local entry = theme.Obstacles[#theme.Obstacles]
			for _, candidate in theme.Obstacles do
				pick -= candidate[1]
				if pick <= 0 then
					entry = candidate
					break
				end
			end
			local r = entry[2]
			local x = random.Number(-LANE_HALF + r + 2, LANE_HALF - r - 2)
			local z = -c.Half + FOOT_CLEAR + slice * (i - 1) + random.Number(r, math.max(r, slice - r))
			if fits(c, shapes, { X = x, Z = z, R = r }, spots) then
				local model = Instance.new("Model")
				model.Name = entry.Name or "Obstacle"
				model.Parent = obstacles
				entry[3](c, x, z, model)
				break
			end
		end
	end

	-- Flat patches on the floor: a winding path up the lane and the god's own ground, under everything.
	local flat = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Parent = patches }
	if theme.Path then
		local z = -c.Half + 3
		while z < c.Half - 3 do
			local x1, x2 = pathX(z), pathX(z + 6)
			local props = table.clone(flat)
			props.Yaw = math.deg(math.atan2(x2 - x1, 6))
			local tile = c.Tilted((x1 + x2) / 2, 0.08, z + 3, c.Vector3.new(PATH_WIDTH, 0.2, 7.5), theme.Path, props)
			tile.Name = "Path"
			z += 6
		end
	end
	if theme.Patch then
		for _ = 1, theme.Patches or 6 do
			local x, z = random.Number(-48, 48), random.Number(-c.Half + 10, c.Half - 10)
			for _ = 1, random.Int(2, 4) do
				local s = random.Number(6, 12)
				local props = table.clone(flat)
				props.Yaw = random.Number(0, 90)
				c.Tilted(
					x + random.Number(-5, 5),
					0.06,
					z + random.Number(-5, 5),
					c.Vector3.new(s, 0.15, s),
					theme.Patch,
					props
				)
			end
		end
	end
	if theme.Life then
		theme.Life(c, life)
	end
	if theme.Birds then
		Lane.Birds(c, life, theme.Birds)
	end
	-- Only the dunes are solid (the user, 2026-10-06: at a slide's speed, dodging things is too hard; only what works as
	-- a ramp should have collision). Everything else in the lane, the landmark too, is passed through, and left out of
	-- ground checks and the gods' line of sight.
	for _, part in lane:GetDescendants() do
		if part:IsA("BasePart") and not part:GetAttribute("Ramp") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
end

-- A few small flocks of block birds circling over the stretch (Motion.Flock flies them).
function Lane.Birds(c: any, parent: any, colors: { any })
	local random = c.LaneRandom
	local V, CF = c.Vector3, c.CFrame
	local soft = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
	for _ = 1, random.Int(2, 3) do
		local center = c.At(random.Number(-50, 50), random.Number(30, 55), random.Number(-c.Half + 40, c.Half - 40))
		local radius = random.Number(25, 45)
		local speed = random.Number(10, 18) * random.Side()
		local flock = c.Instance.new("Model")
		flock.Name = "Flock"
		-- Laid out where the flock's circle starts, facing the way it flies.
		local start = CF.new(center) * CF.new(radius, 0, 0) * CF.Angles(0, if speed > 0 then math.pi else 0, 0)
		for _ = 1, random.Int(3, 5) do
			local bird = c.Instance.new("Model")
			bird.Name = "Bird"
			local cf = start
				* CF.new(random.Number(-8, 8), random.Number(-3, 3), random.Number(-8, 8))
				* CF.Angles(0, math.rad(random.Number(-10, 10)), 0)
			local body, wing = colors[1], colors[2] or colors[1]
			local function piece(name: string, offset: any, size: any, color: any, turn: any?)
				local part = c.NewPart(bird, cf * CF.new(offset) * (turn or CF.new()), size, color, table.clone(soft))
				part.Name = name
			end
			piece("Body", V.new(0, 0, 0), V.new(1.2, 1, 3), body)
			piece("Head", V.new(0, 0.3, 1.9), V.new(1, 1, 1), body)
			piece("Beak", V.new(0, 0.2, 2.7), V.new(0.4, 0.4, 0.7), colors[3] or c.Rgb(240, 190, 70))
			piece("Tail", V.new(0, 0.1, -1.9), V.new(1.2, 0.3, 1.2), wing)
			local flap = math.rad(random.Number(-10, 25))
			for _, side in { -1, 1 } do
				-- Swept back, so a still bird doesn't read as a little plane.
				piece(
					if side < 0 then "WingL" else "WingR",
					V.new(side * 2.3, 0.2 + math.sin(flap) * 1.8, -0.3),
					V.new(4.2, 0.3, 1.4),
					wing,
					CF.Angles(0, side * math.rad(22), side * flap)
				)
			end
			bird.Parent = flock
		end
		Motion.Flock(flock, center, radius, speed)
		flock.Parent = parent
	end
end

-- A rock of two or three blocks lying on the floor, `size` studs across, with an optional glowing seam.
function Lane.Rock(c: any, x: number, z: number, model: any, color: any, size: number, seam: any?)
	local random = c.LaneRandom
	local V = c.Vector3
	local yaw = random.Number(0, 90)
	c.Tilted(x, size * 0.35, z, V.new(size * 1.5, size * 0.7, size * 1.2), color, { Yaw = yaw, Parent = model })
	c.Tilted(
		x + random.Number(-1, 1),
		size * 0.95,
		z + random.Number(-1, 1),
		V.new(size, size * 0.55, size * 0.85),
		color,
		{ Yaw = yaw + random.Number(15, 40), Parent = model }
	)
	if random.Number(0, 1) < 0.6 then
		local s = size * 0.5
		c.Tilted(x + size * 0.7, s / 2, z - size * 0.4, V.new(s, s, s), color, { Yaw = yaw + 30, Parent = model })
	end
	if seam then
		c.Tilted(x, size * 0.72, z, V.new(size * 1.3, 0.3, size * 1.0), seam, {
			Yaw = yaw,
			Material = c.Enum.Material.Neon,
			CanCollide = false,
			Parent = model,
		})
	end
end

-- A glowing crack zig-zagging over the floor, starting at (x, z).
function Lane.Crack(c: any, x: number, z: number, segments: number, color: any, parent: any)
	local random = c.LaneRandom
	local angle = random.Number(0, 360)
	for _ = 1, segments do
		local length = random.Number(4, 8)
		local a = math.rad(angle)
		local mx, mz = x + math.sin(a) * length / 2, z + math.cos(a) * length / 2
		c.Tilted(mx, 0.1, mz, c.Vector3.new(0.7, 0.2, length + 0.6), color, {
			Yaw = angle,
			Material = c.Enum.Material.Neon,
			CanCollide = false,
			CanQuery = false,
			CastShadow = false,
			Parent = parent,
		})
		x, z = x + math.sin(a) * length, z + math.cos(a) * length
		angle += random.Number(-60, 60)
	end
end

-- A marble column standing on the floor, broken off at `height`, its plinth and a ring of trim.
function Lane.Column(c: any, x: number, z: number, model: any, stone: any, trim: any, height: number, lift: number?)
	local V, CF = c.Vector3, c.CFrame
	-- The plinth lies on the slope (or the knoll's top, `lift` up); the shaft stands out of it.
	c.Tilted(x, (lift or 0) + 1.2, z, V.new(7, 2.4, 7), stone, { Parent = model })
	local base = c.Stand(x, z, lift)
	c.NewPart(model, base * CF.new(0, height / 2, 0), V.new(5, height, 5), stone)
	c.NewPart(model, base * CF.new(0, height * 0.55, 0), V.new(5.6, 0.8, 5.6), trim)
	-- The break: two stubs of the shaft, one taller.
	c.NewPart(model, base * CF.new(-1.2, height + 0.8, 0.6), V.new(2.4, 1.6, 3.4), stone)
	c.NewPart(model, base * CF.new(1.1, height + 0.4, -1), V.new(2.6, 0.8, 2.4), stone)
end

-- An invisible box of drifting particles over the lane at (x, y, z).
function Lane.Motes(c: any, parent: any, x: number, y: number, z: number, size: any, spec: { [string]: any })
	local full = table.clone(spec)
	full.Shape = c.Enum.ParticleEmitterShape.Box
	full.ShapeStyle = c.Enum.ParticleEmitterShapeStyle.Volume
	c.Emitter(parent, c.CFrame.new(c.At(x, y, z)) * c.Upright, size, full)
end

-- One of the map's trees in the lane, recoloured. It's named Tree... so ground checks look through it
-- (Mountain.IsPlant), as they do through the old stages' trees. `opts`: Leaves, Wood, Scale, Lift (a knoll's top).
function Lane.Tree(c: any, x: number, z: number, model: any, template: string, opts: { [string]: any })
	c.Place(template, x, z, {
		Name = "Tree" .. template,
		Y = (opts.Lift or 0) - 1,
		Yaw = c.LaneRandom.Number(0, 360),
		Scale = opts.Scale or c.LaneRandom.Number(0.85, 1.1),
		Leaves = opts.Leaves,
		Wood = opts.Wood,
		Parent = model,
	})
end

-- A barrel on the floor at (x, z), `y` up (a stack's second row), lying across the slope or standing.
function Lane.Barrel(c: any, x: number, y: number, z: number, model: any, wood: any, hoop: any, standing: boolean?)
	local V, CF = c.Vector3, c.CFrame
	local cylinder = { Shape = c.Enum.PartType.Cylinder }
	-- A cylinder's axis is its X: standing ones turn it up.
	local base = c.Stand(x, z) * CF.new(0, y + (if standing then 2.5 else 2.2), 0)
	if standing then
		base = base * CF.Angles(0, 0, math.pi / 2)
	end
	c.NewPart(model, base, V.new(5, 4.4, 4.4), wood, cylinder)
	for _, d in { -1.6, 1.6 } do
		c.NewPart(model, base * CF.new(d, 0, 0), V.new(0.5, 4.7, 4.7), hoop, cylinder)
	end
end

-- A big clay jar (an amphora), `k` times its usual 9 studs tall.
function Lane.Jar(c: any, x: number, z: number, model: any, clay: any, rim: any, k: number?)
	local V, CF = c.Vector3, c.CFrame
	local s = k or 1
	local base = c.Stand(x, z)
	c.NewPart(model, base * CF.new(0, 0.6 * s, 0), V.new(3, 1.2, 3) * s, clay)
	c.NewPart(model, base * CF.new(0, 3.4 * s, 0), V.new(5.4, 5.4, 5.4) * s, clay, { Shape = c.Enum.PartType.Ball })
	c.NewPart(model, base * CF.new(0, 6.9 * s, 0), V.new(2.2, 2.4, 2.2) * s, clay)
	c.NewPart(model, base * CF.new(0, 8.3 * s, 0), V.new(3, 0.6, 3) * s, rim)
	for _, side in { -1, 1 } do
		c.NewPart(model, base * CF.new(side * 1.9 * s, 6.6 * s, 0), V.new(0.6, 2.6, 0.6) * s, clay)
	end
end

-- A pedestal `height` tall and `width` across, trimmed on top; returns the frame on its top.
function Lane.Pedestal(
	c: any,
	x: number,
	z: number,
	model: any,
	stone: any,
	trim: any,
	height: number,
	width: number,
	lift: number?
): any
	local V, CF = c.Vector3, c.CFrame
	local base = c.Stand(x, z, lift)
	c.NewPart(model, base * CF.new(0, height / 2, 0), V.new(width, height, width), stone)
	c.NewPart(model, base * CF.new(0, height + 0.4, 0), V.new(width + 1, 0.8, width + 1), trim)
	return base * CF.new(0, height + 0.8, 0)
end

-- A log lying on the floor, `length` long, turned up to 60 degrees off straight across: low enough to jump.
function Lane.Log(c: any, x: number, z: number, model: any, bark: any, inner: any, length: number)
	local V, CF = c.Vector3, c.CFrame
	local cylinder = { Shape = c.Enum.PartType.Cylinder }
	local base = c.Stand(x, z) * CF.new(0, 1.6, 0) * CF.Angles(0, math.rad(c.LaneRandom.Number(-60, 60)), 0)
	c.NewPart(model, base, V.new(length, 3.2, 3.2), bark, cylinder)
	for _, side in { -1, 1 } do
		c.NewPart(model, base * CF.new(side * (length / 2 + 0.05), 0, 0), V.new(0.2, 2.6, 2.6), inner, cylinder)
	end
	c.NewPart(model, base * CF.new(length * 0.2, 1.8, 0) * CF.Angles(0, 0, math.rad(40)), V.new(0.6, 2.4, 0.6), bark)
end

-- A fan of `ribs` ribs from `frame`'s origin, in its x-y plane (facing down the mountain): a peacock's tail, a shell.
function Lane.Fan(c: any, frame: any, model: any, ribs: number, length: number, colors: { any }, tip: any?)
	local V, CF = c.Vector3, c.CFrame
	for i = 0, ribs - 1 do
		local turn = frame * CF.Angles(0, 0, math.rad(75 - i * 150 / (ribs - 1)))
		c.NewPart(model, turn * CF.new(0, length / 2, 0), V.new(2.6, length, 0.8), colors[i % #colors + 1])
		if tip then
			c.NewPart(model, turn * CF.new(0, length, 0), V.new(2.4, 2.4, 2.4), tip, { Shape = c.Enum.PartType.Ball })
		end
	end
end

-- Flames: two neon blocks and a fire emitter at `frame`, `k` times a torch's.
function Lane.Flame(c: any, frame: any, model: any, k: number)
	local V, CF = c.Vector3, c.CFrame
	local neon = { Material = c.Enum.Material.Neon, CanCollide = false }
	c.NewPart(model, frame * CF.new(0, 1.7 * k, 0), V.new(3, 3.4, 3) * k, c.Rgb(255, 140, 50), neon)
	c.NewPart(model, frame * CF.new(0, 2.7 * k, 0), V.new(1.7, 3, 1.7) * k, c.Rgb(255, 214, 90), neon)
	c.Emitter(model, frame * CF.new(0, 3 * k, 0), V.new(2, 1, 2) * k, {
		Name = "Fire",
		Texture = "rbxasset://textures/particles/fire_main.dds",
		Color = { c.Rgb(255, 214, 90), c.Rgb(255, 110, 40) },
		LightEmission = 1,
		Size = { { 0, 1.6 * k }, { 1, 0.2 } },
		Transparency = { { 0, 0.2 }, { 1, 1 } },
		Lifetime = { 0.5, 1 },
		Speed = { 3, 6 },
		Rate = 14,
	})
end

-- A ring of `count` blocks round (x, z) on the floor, `radius` out: a hearth, a rock pool, a crater's rim.
function Lane.Ring(c: any, x: number, z: number, model: any, color: any, radius: number, count: number, size: any)
	for i = 1, count do
		local a = i / count * math.pi * 2
		c.Tilted(x + math.cos(a) * radius, size.Y / 2, z + math.sin(a) * radius, size, color, {
			Yaw = -math.deg(a),
			Parent = model,
		})
	end
end

-- Each god's stretch: colours before the map's colour grading (Lighting.ColorCorrection, saturation +0.7, which
-- brightens them a lot), plants as { template, count, nearest x, farthest x }, and props.
function UpperMountain.Themes(rgb: (number, number, number) -> any): { [string]: any }
	local themes: { [string]: any } = {}
	local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
	local FIRE = "rbxasset://textures/particles/fire_main.dds"
	local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

	-- Hypnos's lane: giant poppies, stacks of pillows, dream trees and moon lamps; a big dream tree on the knoll.
	local poppyRed, poppyMiddle, stem = rgb(232, 92, 62), rgb(52, 42, 62), rgb(96, 150, 84)
	local function giantPoppy(c: any, x: number, z: number, model: any, height: number?, lift: number?)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local h = height or random.Number(11, 16)
		local base = c.Stand(x, z, lift)
		c.NewPart(model, base * CF.new(0, h / 2, 0), V.new(1.6, h, 1.6), stem)
		c.NewPart(model, base * CF.new(1.4, h * 0.35, 0) * CF.Angles(0, 0, math.rad(-35)), V.new(3.6, 0.6, 1.8), stem)
		c.NewPart(model, base * CF.new(-1.4, h * 0.55, 0) * CF.Angles(0, 0, math.rad(35)), V.new(3.6, 0.6, 1.8), stem)
		local head = base * CF.new(0, h, 0) * CF.Angles(0, math.rad(random.Number(0, 90)), 0)
		for i = 0, 3 do
			c.NewPart(
				model,
				head * CF.Angles(0, i * math.pi / 2, 0) * CF.new(0, 0.8, 2.4) * CF.Angles(math.rad(-28), 0, 0),
				V.new(5, 0.8, 4.6),
				poppyRed
			)
		end
		c.NewPart(model, head * CF.new(0, 1.1, 0), V.new(2.6, 1.6, 2.6), poppyMiddle)
	end
	local function poppies(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local count = random.Int(2, 3)
		for i = 1, count do
			local a = (i / count) * math.pi * 2 + random.Number(0, 1)
			local d = if i == 1 then 0 else random.Number(3, 4.5)
			giantPoppy(c, x + math.cos(a) * d, z + math.sin(a) * d, model, random.Number(12, 22))
		end
	end
	local function pillows(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local colors = { rgb(246, 242, 255), rgb(206, 186, 240), rgb(240, 196, 226) }
		local yaw = random.Number(0, 180)
		local y = 0
		for i = 1, random.Int(3, 4) do
			c.Tilted(
				x + random.Number(-0.8, 0.8),
				y + 1.6,
				z + random.Number(-0.8, 0.8),
				c.Vector3.new(14 - i * 1.5, 3.2, 10 - i),
				random.Pick(colors),
				{ Yaw = yaw + random.Number(-25, 25), Parent = model }
			)
			y += 3.2
		end
	end
	themes.Hypnos = {
		Floor = rgb(174, 154, 214),
		Cap = rgb(194, 174, 228),
		SideA = rgb(142, 122, 182),
		SideB = rgb(158, 138, 198),
		Leaves = rgb(152, 130, 202),
		Trunk = rgb(120, 102, 142),
		Stone = rgb(182, 172, 212),
		Cloud = rgb(206, 196, 236),
		Clouds = 4,
		Plants = { { "RoundTree", 4 } },
		Path = rgb(190, 172, 226),
		Birds = { rgb(250, 248, 255), rgb(226, 214, 250) },
		Obstacles = {
			{ 3, 6, poppies, Name = "GiantPoppies" },
			{ 2, 7, pillows, Name = "Pillows" },
			{
				1,
				9,
				function(c: any, x: number, z: number, model: any)
					c.Place("Cloud", x, z, {
						Y = -2,
						Yaw = c.LaneRandom.Number(0, 360),
						Scale = 0.2,
						Solid = rgb(232, 226, 250),
						Parent = model,
					})
				end,
				Name = "RestingCloud",
			},
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(c, x, z, model, "RoundTree", {
						Leaves = rgb(186, 150, 226),
						Scale = c.LaneRandom.Number(0.9, 1.15),
					})
				end,
				Name = "DreamTree",
			},
			{
				2,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(182, 172, 212), c.LaneRandom.Number(5, 7))
				end,
				Name = "Rock",
			},
			{
				1,
				3,
				function(c: any, x: number, z: number, model: any)
					local V, CF = c.Vector3, c.CFrame
					local base = c.Stand(x, z)
					c.Tilted(x, 0.6, z, V.new(4, 1.2, 4), rgb(142, 122, 182), { Parent = model })
					c.NewPart(model, base * CF.new(0, 9, 0), V.new(1.6, 18, 1.6), rgb(120, 102, 142))
					c.Sprite("Moon", x, z, 1.2, { M = rgb(255, 244, 200) }, {
						Frame = base * CF.new(0, 17.4, 0),
						Yaw = c.LaneRandom.Number(-30, 30),
						Neon = true,
						Parent = model,
					})
				end,
				Name = "MoonLamp",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			Lane.Tree(c, x, z, model, "RoundTree", { Leaves = rgb(196, 160, 236), Scale = 1.35, Lift = y })
			for i = 0, 3 do
				local a = i * math.pi / 2 + 0.6
				giantPoppy(c, x + math.cos(a) * 5, z + math.sin(a) * 8, model, c.LaneRandom.Number(7, 10), y)
			end
			c.Sprite(
				"Zzz",
				x + 4,
				z,
				2.4,
				{ Z = rgb(246, 244, 255) },
				{ Y = y + 34, Yaw = 0, Upright = true, Neon = true, Ghost = true, Parent = model }
			)
		end,
		Life = function(c: any, life: any)
			-- Sleepy sparkles drifting up over the poppies.
			for i = 1, 5 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 5
				Lane.Motes(c, life, c.LaneRandom.Number(-30, 30), 6, z, c.Vector3.new(80, 6, 40), {
					Texture = SPARKLE,
					Color = rgb(236, 220, 255),
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.8 }, { 1, 0 } },
					Transparency = { { 0, 0.1 }, { 1, 0.6 } },
					Lifetime = { 4, 7 },
					Speed = { 0.4, 1.2 },
					Acceleration = c.Vector3.new(0, 0.5, 0),
					Rate = 5,
				})
			end
		end,
		Props = function(c: any)
			local poppy, middle = rgb(232, 92, 62), rgb(52, 42, 62)
			Props.Scatter(c, 50, function(x: number, z: number)
				Props.Flower(c, x, z, poppy, middle)
			end, c.Lane + 1, 102)
			-- Sleepy clouds low over the terraces.
			for i = 1, 3 do
				local side = if i % 2 == 0 then 1 else -1
				local cloud = c.Place("Cloud", side * c.Random.Number(110, 150), c.Random.Number(-80, 80), {
					Y = c.Random.Number(18, 34),
					Upright = true,
					Solid = rgb(214, 204, 240),
					Ghost = true,
					Scale = 0.35,
				})
				Motion.Bob(cloud, 1.5, 12)
			end
			Props.Scatter(c, 3, function(x: number, z: number)
				local zzz = c.Sprite(
					"Zzz",
					x,
					z,
					2.2,
					{ Z = rgb(246, 244, 255) },
					{ Lift = 16, Upright = true, Neon = true, Ghost = true }
				)
				Motion.Bob(zzz, 1.5, 5)
			end, 70, 100)
		end,
	}

	-- Morpheus's lane: dream steps whose top steps float, pastel crystals, blossom trees and pastel rocks; a blossom
	-- tree on the knoll with dream shapes circling it.
	local dreamColors = { rgb(255, 150, 210), rgb(130, 230, 255), rgb(255, 236, 130), rgb(160, 255, 200) }
	local function dreamSteps(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local yaw = random.Number(0, 360)
		local a = math.rad(yaw)
		for i = 0, 3 do
			local d = (i - 1.5) * 3.2
			local s = 4.4 - i * 0.4
			local step = c.Tilted(
				x + math.sin(a) * d,
				s / 2 + i * 2.6,
				z + math.cos(a) * d,
				c.Vector3.new(s, s, s),
				dreamColors[i + 1],
				{ Yaw = yaw + i * 12, Parent = model }
			)
			-- The top two float, bobbing.
			if i >= 2 then
				step.CanCollide = false
				Motion.Bob(step, 0.8, 3 + i)
			end
		end
	end
	local function dreamCrystal(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local color = random.Pick(dreamColors)
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(random.Number(0, 90)), 0)
		local h = random.Number(10, 16)
		c.NewPart(model, base * CF.new(0, h / 2, 0), V.new(3.4, h, 3.4), color)
		c.NewPart(
			model,
			base * CF.new(2.4, h * 0.25, 0.8) * CF.Angles(0, 0, math.rad(-22)),
			V.new(2.2, h * 0.55, 2.2),
			color
		)
		c.NewPart(
			model,
			base * CF.new(-2.1, h * 0.2, -1.2) * CF.Angles(0, 0, math.rad(20)),
			V.new(2, h * 0.45, 2),
			color
		)
		c.NewPart(model, base * CF.new(0, h + 0.8, 0), V.new(1.6, 1.6, 1.6), color, {
			Material = c.Enum.Material.Neon,
			CanCollide = false,
		})
	end
	themes.Morpheus = {
		Path = rgb(232, 236, 252),
		Birds = { rgb(255, 250, 255), rgb(200, 220, 255) },
		Obstacles = {
			{ 3, 7, dreamSteps, Name = "DreamSteps" },
			{ 3, 5, dreamCrystal, Name = "DreamCrystal" },
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"BlossomTree",
						{ Leaves = rgb(250, 190, 226), Scale = c.LaneRandom.Number(0.5, 0.65) }
					)
				end,
				Name = "Blossom",
			},
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(220, 226, 246), c.LaneRandom.Number(5, 6.5))
				end,
				Name = "Rock",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			Lane.Tree(c, x, z, model, "BlossomTree", { Leaves = rgb(255, 176, 220), Scale = 0.8, Lift = y })
			-- A ring of dream shapes circling above the tree.
			local ring = c.Instance.new("Model")
			ring.Name = "DreamRing"
			ring.Parent = model
			local center = c.At(x, y + 30, z)
			for i = 1, 8 do
				local a = i / 8 * math.pi * 2
				local s = if i % 2 == 0 then 3 else 2.2
				c.NewPart(
					ring,
					c.CFrame.new(center + c.Vector3.new(math.cos(a) * 16, 0, math.sin(a) * 16))
						* c.CFrame.Angles(a, a * 2, 0),
					c.Vector3.new(s, s, s),
					dreamColors[i % #dreamColors + 1],
					{
						Material = c.Enum.Material.Neon,
						CanCollide = false,
						Shape = if i % 3 == 0 then c.Enum.PartType.Ball else c.Enum.PartType.Block,
					}
				)
			end
			Motion.Spin(ring, center, c.Vector3.new(0, 1, 0), 18)
		end,
		Life = function(c: any, life: any)
			for i = 1, 5 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 5
				Lane.Motes(c, life, c.LaneRandom.Number(-30, 30), 8, z, c.Vector3.new(80, 8, 40), {
					Texture = SPARKLE,
					Color = { rgb(255, 190, 230), rgb(170, 230, 255) },
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.9 }, { 1, 0 } },
					Lifetime = { 4, 7 },
					Speed = { 0.4, 1.2 },
					Acceleration = c.Vector3.new(0, 0.6, 0),
					Rate = 5,
				})
			end
		end,
		Floor = rgb(150, 192, 236),
		Cap = rgb(240, 172, 212),
		SideA = rgb(196, 216, 244),
		SideB = rgb(214, 228, 248),
		Leaves = rgb(250, 190, 226),
		Trunk = rgb(170, 160, 210),
		Stone = rgb(220, 226, 246),
		Plants = { { "BlossomTree", 3 }, { "RoundTree", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local dream = { rgb(255, 150, 210), rgb(130, 230, 255), rgb(255, 236, 130), rgb(160, 255, 200) }
			-- Shapes drifting over the dream.
			for _ = 1, c.Count(18) do
				local x = c.Random.Number(60, 150) * c.Random.Side()
				local z = c.Random.Number(-c.Half, c.Half)
				local s = c.Random.Number(3, 9)
				local ball = c.Random.Number(0, 1) < 0.35
				local shape =
					c.Block(x, c.Ground(x, z) + c.Random.Number(14, 55), z, V.new(s, s, s), c.Random.Pick(dream), {
						Upright = true,
						Material = c.Enum.Material.Neon,
						CanCollide = false,
						Shape = if ball then c.Enum.PartType.Ball else c.Enum.PartType.Block,
						Turn = c.CFrame.Angles(c.Random.Number(0, 6), c.Random.Number(0, 6), c.Random.Number(0, 6)),
					})
				Motion.Bob(shape, 1.5 + s * 0.3, 5 + s * 0.4)
			end
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Sprite(
					"Star",
					x,
					z,
					1.6,
					{ S = rgb(255, 236, 130) },
					{ Lift = c.Random.Number(10, 30), Upright = true, Neon = true, Ghost = true }
				)
			end, c.Lane + 10, 110)
			for _ = 1, c.Count(3) do
				local x = c.Random.Number(130, 190) * c.Random.Side()
				local island = c.Place("Island", x, c.Random.Number(-c.Half, c.Half), {
					Y = c.Random.Number(30, 70),
					Upright = true,
					Roll = { 180, 0 },
					Solid = rgb(240, 172, 212),
				})
				Motion.Bob(island, 4, 8)
			end
		end,
	}

	-- Deimos's lane: dread rocks with red seams, dark spires, totems with glowing eyes and craters; on the knoll a
	-- monolith with one red eye, rocks hanging in the air round it.
	local dreadDark, dreadRed = rgb(70, 44, 40), rgb(255, 60, 40)
	local function dreadTotem(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-20, 20)), 0)
		c.NewPart(model, base * CF.new(0, 2, 0), V.new(6, 4, 6), dreadDark)
		c.NewPart(model, base * CF.new(0, 6.5, 0), V.new(4.6, 5, 4.6), rgb(96, 58, 50))
		c.NewPart(model, base * CF.new(0, 10.5, 0), V.new(5.4, 3, 5.4), dreadDark)
		c.NewPart(model, base * CF.new(0, 12.6, 0), V.new(3, 1.2, 3), rgb(96, 58, 50))
		-- Eyes on the downhill face, glowing at the climbers.
		for _, side in { -1, 1 } do
			c.NewPart(model, base * CF.new(side * 1.1, 7.4, -2.35), V.new(1, 0.8, 0.2), dreadRed, {
				Material = c.Enum.Material.Neon,
				CanCollide = false,
			})
		end
	end
	local function dreadCrater(c: any, x: number, z: number, model: any)
		local radius = c.LaneRandom.Number(4.5, 6)
		c.Tilted(x, 0.1, z, c.Vector3.new(radius * 1.7, 0.2, radius * 1.7), rgb(60, 36, 32), {
			Yaw = 45,
			CanCollide = false,
			Parent = model,
		})
		Lane.Ring(c, x, z, model, rgb(174, 118, 98), radius, 10, c.Vector3.new(3.5, 2, 4))
	end
	themes.Deimos = {
		Path = rgb(122, 80, 68),
		Birds = { rgb(44, 32, 32), rgb(64, 44, 42), rgb(200, 60, 40) },
		Obstacles = {
			{
				3,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(112, 68, 58), c.LaneRandom.Number(5.5, 7), dreadRed)
				end,
				Name = "DreadRock",
			},
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					c.Place(c.LaneRandom.Pick({ "Spire", "SmallSpire" }), x, z, {
						Y = -1,
						Yaw = c.LaneRandom.Number(0, 360),
						Scale = c.LaneRandom.Number(0.55, 0.7),
						Solid = rgb(110, 56, 48),
						Parent = model,
					})
				end,
				Name = "DreadSpire",
			},
			{ 2, 4, dreadTotem, Name = "DreadTotem" },
			{ 1, 7, dreadCrater, Name = "Crater" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 9, 0), V.new(7, 18, 5), rgb(60, 38, 36))
			c.NewPart(model, base * CF.new(0, 18.6, 0), V.new(8, 1.2, 6), rgb(112, 68, 58))
			c.NewPart(model, base * CF.new(0, 12, -2.55), V.new(3.6, 2.2, 0.2), dreadRed, {
				Material = c.Enum.Material.Neon,
				CanCollide = false,
			})
			c.NewPart(model, base * CF.new(0, 12, -2.7), V.new(1.2, 1.4, 0.2), rgb(30, 10, 10), { CanCollide = false })
			-- Rocks hanging in the air round it, bobbing.
			for i = 1, 5 do
				local a = i / 5 * math.pi * 2
				local s = c.LaneRandom.Number(2.5, 4.5)
				local rock = c.Instance.new("Model")
				rock.Name = "FloatingRock"
				rock.Parent = model
				c.Tilted(
					x + math.cos(a) * 11,
					y + 16 + c.LaneRandom.Number(-3, 3),
					z + math.sin(a) * 15,
					V.new(s, s * 0.8, s),
					rgb(112, 68, 58),
					{ Yaw = c.LaneRandom.Number(0, 90), CanCollide = false, Parent = rock }
				)
				Motion.Bob(rock, 1.5, 4 + i * 0.7)
			end
		end,
		Life = function(c: any, life: any)
			for _ = 1, 6 do
				local x, z = c.LaneRandom.Number(-50, 50), c.LaneRandom.Number(-c.Half + 12, c.Half - 12)
				Lane.Crack(c, x, z, c.LaneRandom.Int(3, 5), dreadRed, life)
			end
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 4, z, c.Vector3.new(100, 6, 50), {
					Texture = SMOKE,
					Color = rgb(150, 80, 64),
					Size = { { 0, 1.5 }, { 1, 4 } },
					Transparency = { { 0, 0.75 }, { 1, 1 } },
					Lifetime = { 4, 6 },
					Speed = { 0.5, 1.5 },
					Rate = 3,
				})
			end
		end,
		Floor = rgb(154, 104, 88),
		Cap = rgb(174, 118, 98),
		SideA = rgb(114, 78, 68),
		SideB = rgb(128, 88, 76),
		Leaves = rgb(174, 118, 98),
		Trunk = rgb(114, 78, 68),
		Stone = rgb(142, 96, 82),
		Stones = 14,
		Islands = 2,
		Plants = {},
		Props = function(c: any)
			Props.Scatter(c, 7, function(x: number, z: number)
				Props.Crater(c, x, z, rgb(174, 118, 98), rgb(114, 78, 68), c.Random.Number(4, 7))
			end, c.Lane + 8, 96)
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Place(c.Random.Pick({ "Spire", "SmallSpire" }), x, z, { Solid = rgb(122, 62, 52), Sink = 1 })
			end, c.Lane + 8, 100)
			-- Mars, which Deimos goes round.
			c.Block(520, 150, 0, c.Vector3.new(200, 200, 200), rgb(170, 100, 82), {
				Upright = true,
				Shape = c.Enum.PartType.Ball,
				CanCollide = false,
				CastShadow = false,
			})
			for _, side in { -1, 1 } do
				c.Place(
					"Pyramid",
					side * 160,
					c.Random.Number(-40, 40),
					{ Solid = rgb(128, 88, 76), Y = -30, Scale = 0.6, Upright = true }
				)
			end
		end,
	}

	-- Thanatos's lane: gravestones, stone tombs, bare grey trees and funeral urns; a crypt on the knoll, its doorway
	-- glowing, ghosts floating over it.
	local graveStone, graveDark = rgb(150, 152, 160), rgb(104, 106, 116)
	local ghostLegend = { W = rgb(236, 244, 255), B = rgb(30, 30, 40) }
	local function gravestone(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-15, 15)), 0)
		c.NewPart(model, base * CF.new(0, 0.5, 0), V.new(7, 1, 4), graveDark)
		c.NewPart(model, base * CF.new(0, 4.5, 0), V.new(5.4, 7, 1.6), graveStone)
		c.NewPart(model, base * CF.new(0, 8, 0) * CF.Angles(0, math.pi / 2, 0), V.new(1.6, 5.4, 5.4), graveStone, {
			Shape = c.Enum.PartType.Cylinder,
		})
	end
	local function tomb(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-40, 40)), 0)
		c.NewPart(model, base * CF.new(0, 1.5, 0), V.new(10, 3, 5), graveDark)
		c.NewPart(model, base * CF.new(0, 3.3, 0), V.new(10.8, 0.6, 5.8), graveStone)
		c.NewPart(model, base * CF.new(0, 3.9, 0), V.new(8, 0.6, 3.4), graveStone)
	end
	themes.Thanatos = {
		Path = rgb(112, 114, 124),
		Birds = { rgb(30, 30, 36), rgb(44, 44, 52), rgb(90, 90, 96) },
		Obstacles = {
			{ 3, 4, gravestone, Name = "Gravestone" },
			{ 2, 6, tomb, Name = "Tomb" },
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"Bush",
						{ Leaves = rgb(100, 104, 114), Wood = rgb(40, 40, 44), Scale = 0.65 }
					)
				end,
				Name = "Dead",
			},
			{
				1,
				4,
				function(c: any, x: number, z: number, model: any)
					Lane.Jar(c, x, z, model, rgb(80, 82, 92), rgb(176, 232, 255), 0.9)
				end,
				Name = "Urn",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 5, 2), V.new(12, 10, 8), graveDark)
			c.NewPart(model, base * CF.new(0, 10.6, 2), V.new(14, 1.2, 10), graveStone)
			c.NewPart(model, base * CF.new(0, 12, 2), V.new(10, 1.6, 7), graveStone)
			for _, side in { -1, 1 } do
				c.NewPart(model, base * CF.new(side * 5, 5, -2.6), V.new(1.8, 10, 1.8), graveStone)
			end
			c.NewPart(model, base * CF.new(0, 4, -2.05), V.new(4, 7, 0.2), rgb(170, 230, 255), {
				Material = c.Enum.Material.Neon,
				CanCollide = false,
			})
			for _, side in { -1, 1 } do
				local ghost = c.Sprite("Ghost", x, z, 1.4, ghostLegend, {
					Frame = base * CF.new(side * 7, 16, 0),
					Yaw = 0,
					Ghost = true,
					Parent = model,
				})
				Motion.Bob(ghost, 1.5, 4 + side)
			end
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 5, z, c.Vector3.new(100, 8, 50), {
					Texture = SPARKLE,
					Color = rgb(190, 236, 255),
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.7 }, { 1, 0 } },
					Lifetime = { 4, 7 },
					Speed = { 0.3, 1 },
					Acceleration = c.Vector3.new(0, 0.5, 0),
					Rate = 4,
				})
			end
			-- Ghosts drifting over the lane, high enough to pass under.
			for _ = 1, 2 do
				local ghost = c.Sprite(
					"Ghost",
					c.LaneRandom.Number(-40, 40),
					c.LaneRandom.Number(-c.Half + 30, c.Half - 30),
					1.4,
					ghostLegend,
					{ Lift = 20, Yaw = 0, Ghost = true, Parent = life }
				)
				Motion.Bob(ghost, 2, 5)
			end
		end,
		Floor = rgb(54, 56, 64),
		Cap = rgb(74, 76, 86),
		SideA = rgb(40, 42, 48),
		SideB = rgb(48, 50, 58),
		Leaves = rgb(100, 104, 114),
		Trunk = rgb(36, 36, 40),
		Stone = rgb(92, 94, 102),
		Plants = { { "Bush", 4 }, { "SmallPine", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			Props.Scatter(c, 36, function(x: number, z: number)
				Props.Flower(c, x, z, rgb(242, 242, 232), rgb(236, 210, 90))
			end, c.Lane + 1, 102)
			-- Gravestones facing the path.
			Props.Scatter(c, 8, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 3, z, V.new(1.4, 6, 5), rgb(152, 154, 162))
				c.Block(x, y + 6.5, z, V.new(1.4, 1, 3), rgb(152, 154, 162))
			end, 70, 100)
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Place("Spire", x, z, { Solid = rgb(40, 40, 46), Sink = 1 })
			end, 72, 100)
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Sprite(
					"Ghost",
					x,
					z,
					1.4,
					{ W = rgb(236, 244, 255), B = rgb(30, 30, 40) },
					{ Lift = c.Random.Number(8, 20), Upright = true, Ghost = true }
				)
			end, c.Lane + 8, 100)
			for _ = 1, c.Count(10) do
				local x = c.Random.Number(c.Lane + 4, 110) * c.Random.Side()
				local z = c.Random.Number(-c.Half, c.Half)
				local s = c.Random.Number(1.4, 2.6)
				c.Block(x, c.Ground(x, z) + c.Random.Number(5, 20), z, V.new(s, s, s), rgb(176, 232, 255), {
					Shape = c.Enum.PartType.Ball,
					Material = c.Enum.Material.Neon,
					CanCollide = false,
				})
			end
		end,
	}

	-- Nemesis's lane: giant swords driven into the ground, scales of judgement, silver-seamed stones and pines; a great
	-- sword in the knoll.
	local swordLegend = { S = rgb(204, 210, 220), G = rgb(216, 182, 82), H = rgb(72, 52, 42) }
	local function scales(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local silver, gold = rgb(174, 184, 194), rgb(216, 182, 82)
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-30, 30)), 0)
		c.NewPart(model, base * CF.new(0, 0.5, 0), V.new(5, 1, 5), silver)
		c.NewPart(model, base * CF.new(0, 7, 0), V.new(1.2, 13, 1.2), gold)
		local tilt = math.rad(c.LaneRandom.Number(-12, 12))
		c.NewPart(model, base * CF.new(0, 13.4, 0) * CF.Angles(0, 0, tilt), V.new(13, 0.8, 0.8), gold)
		c.NewPart(model, base * CF.new(0, 14.4, 0), V.new(1.8, 1.8, 1.8), gold, { Shape = c.Enum.PartType.Ball })
		for _, side in { -1, 1 } do
			-- Each pan hangs straight under its end of the beam.
			local hang = base * CF.new(side * 6 * math.cos(tilt), 13.4 + side * 6 * math.sin(tilt), 0)
			c.NewPart(model, hang * CF.new(0, -2.5, 0), V.new(0.2, 5, 0.2), silver, { CanCollide = false })
			c.NewPart(model, hang * CF.new(0, -5.2, 0) * CF.Angles(0, 0, math.pi / 2), V.new(0.5, 4.4, 4.4), silver, {
				Shape = c.Enum.PartType.Cylinder,
			})
		end
	end
	themes.Nemesis = {
		Path = rgb(140, 162, 168),
		Birds = { rgb(222, 228, 234), rgb(170, 180, 190) },
		Obstacles = {
			{
				3,
				6,
				function(c: any, x: number, z: number, model: any)
					c.Sprite("Sword", x, z, 2.2, swordLegend, {
						Lift = -4,
						Yaw = c.LaneRandom.Number(-30, 30),
						Tip = c.LaneRandom.Number(-10, 10),
						Parent = model,
					})
				end,
				Name = "Sword",
			},
			{ 2, 7, scales, Name = "Scales" },
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(140, 150, 160), c.LaneRandom.Number(5, 6.5), rgb(220, 240, 255))
				end,
				Name = "JudgementStone",
			},
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"Pine3",
						{ Leaves = rgb(62, 122, 112), Scale = c.LaneRandom.Number(0.6, 0.75) }
					)
				end,
				Name = "Pine",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			c.Sprite("Sword", x, z, 3.2, swordLegend, { Frame = c.Stand(x, z, y - 6), Yaw = 0, Parent = model })
			c.Emitter(model, c.Stand(x, z, y + 26), c.Vector3.new(8, 4, 2), {
				Name = "Gleam",
				Texture = SPARKLE,
				Color = rgb(240, 248, 255),
				LightEmission = 1,
				Size = { { 0, 0 }, { 0.3, 1.4 }, { 1, 0 } },
				Lifetime = { 1, 2 },
				Speed = { 0.5, 1.5 },
				Rate = 6,
			})
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 6, z, c.Vector3.new(100, 8, 50), {
					Texture = SPARKLE,
					Color = rgb(226, 236, 246),
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.6 }, { 1, 0 } },
					Lifetime = { 3, 5 },
					Speed = { 0.3, 1 },
					Rate = 4,
				})
			end
		end,
		Floor = rgb(62, 112, 118),
		Cap = rgb(174, 184, 194),
		SideA = rgb(48, 88, 94),
		SideB = rgb(58, 100, 106),
		Leaves = rgb(62, 122, 112),
		Trunk = rgb(72, 72, 82),
		Stone = rgb(152, 162, 172),
		Plants = { { "Pine3", 3 }, { "SmallPine", 3 } },
		Props = function(c: any)
			local legend = { S = rgb(204, 210, 220), G = rgb(216, 182, 82), H = rgb(72, 52, 42) }
			Props.Scatter(c, 7, function(x: number, z: number)
				c.Sprite("Sword", x, z, 1.6, legend, { Lift = -3, Tip = c.Random.Number(-10, 10) })
			end, c.Lane + 8, 98)
			Props.Wheel(
				c,
				80 * c.Random.Side(),
				c.Random.Number(-50, 50),
				{ rgb(174, 184, 194), rgb(62, 112, 118) },
				rgb(80, 86, 96)
			)
		end,
	}

	-- Dionysus's lane: stacked wine barrels, short rows of vines heavy with grapes, wine jars and vine trees; a great
	-- vat on the knoll with grapes on top.
	local vineWood, vineLeaf, vineGrape = rgb(122, 88, 62), rgb(92, 156, 72), rgb(122, 62, 154)
	local function barrels(c: any, x: number, z: number, model: any)
		local wood, hoop = rgb(150, 104, 66), rgb(70, 60, 56)
		Lane.Barrel(c, x, 0, z - 2.3, model, wood, hoop)
		Lane.Barrel(c, x, 0, z + 2.3, model, wood, hoop)
		if c.LaneRandom.Number(0, 1) < 0.7 then
			Lane.Barrel(c, x, 3.8, z, model, wood, hoop)
		end
	end
	local function vineRow(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-20, 20)), 0)
		for _, dz in { -5.5, 5.5 } do
			c.NewPart(model, base * CF.new(0, 4, dz), V.new(1.2, 8, 1.2), vineWood)
		end
		c.NewPart(model, base * CF.new(0, 8.4, 0), V.new(1, 0.8, 12), vineWood)
		c.NewPart(model, base * CF.new(0, 6.4, 0), V.new(3, 3.4, 12), vineLeaf)
		for i = -2, 2 do
			c.NewPart(model, base * CF.new(c.LaneRandom.Pick({ -1.4, 1.4 }), 4.2, i * 2.4), V.new(2, 2, 2), vineGrape, {
				Shape = c.Enum.PartType.Ball,
			})
		end
	end
	themes.Dionysus = {
		Path = rgb(112, 86, 62),
		Birds = { rgb(120, 92, 62), rgb(96, 150, 72), rgb(230, 190, 80) },
		Obstacles = {
			{ 3, 5, barrels, Name = "Barrels" },
			{ 3, 7, vineRow, Name = "VineRow" },
			{
				1,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Jar(c, x - 1.8, z, model, rgb(170, 84, 62), rgb(60, 40, 36))
					Lane.Jar(c, x + 2.2, z + 1.2, model, rgb(150, 76, 58), rgb(60, 40, 36), 0.8)
				end,
				Name = "WineJars",
			},
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"RoundTree",
						{ Leaves = vineLeaf, Scale = c.LaneRandom.Number(0.6, 0.75) }
					)
				end,
				Name = "Vine",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local cylinder = { Shape = c.Enum.PartType.Cylinder }
			local base = c.Stand(x, z, y)
			local up = base * CF.Angles(0, 0, math.pi / 2)
			c.NewPart(model, up * CF.new(5, 0, 0), V.new(10, 13, 13), rgb(150, 104, 66), cylinder)
			for _, h in { 1.2, 5, 8.8 } do
				c.NewPart(model, up * CF.new(h, 0, 0), V.new(0.7, 13.5, 13.5), rgb(70, 60, 56), cylinder)
			end
			c.NewPart(model, up * CF.new(10.2, 0, 0), V.new(0.4, 12, 12), rgb(110, 40, 90), {
				Shape = c.Enum.PartType.Cylinder,
				Material = c.Enum.Material.Neon,
			})
			c.Sprite("Grapes", x, z, 1.8, { P = vineGrape, L = vineLeaf }, {
				Frame = base * CF.new(0, 10.4, 0),
				Yaw = 0,
				Parent = model,
			})
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 6, z, c.Vector3.new(100, 8, 50), {
					Texture = SPARKLE,
					Color = { rgb(200, 120, 255), rgb(255, 210, 110) },
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.7 }, { 1, 0 } },
					Lifetime = { 3, 6 },
					Speed = { 0.3, 1 },
					Rate = 4,
				})
			end
		end,
		Floor = rgb(150, 128, 96),
		Cap = rgb(112, 152, 72),
		SideA = rgb(122, 96, 72),
		SideB = rgb(138, 110, 82),
		Leaves = rgb(92, 152, 72),
		Trunk = rgb(112, 82, 62),
		Stone = rgb(150, 132, 112),
		Plants = { { "RoundTree", 3 }, { "Bush", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local wood, leaf, grape = rgb(122, 88, 62), rgb(92, 156, 72), rgb(122, 62, 154)
			-- Rows of vines on posts, running beside the path, heavy with grapes.
			Props.Scatter(c, 6, function(x: number, z: number)
				local y = c.Ground(x, z)
				for _, dz in { -7, 7 } do
					c.Block(x, y + 4, z + dz, V.new(1.2, 8, 1.2), wood)
				end
				c.Block(x, y + 8.4, z, V.new(1, 0.8, 16), wood)
				c.Block(x, y + 6.8, z, V.new(3, 3, 16), leaf)
				for i = -2, 2 do
					c.Block(
						x + c.Random.Number(-0.8, 0.8),
						y + 4.6,
						z + i * 3,
						V.new(2, 2, 2),
						grape,
						{ Shape = c.Enum.PartType.Ball }
					)
				end
			end, c.Lane + 6, 90)
			-- Barrels of wine.
			local barrel = { Shape = c.Enum.PartType.Cylinder, Turn = c.CFrame.Angles(0, 0, math.pi / 2) }
			Props.Scatter(c, 5, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 2.5, z, V.new(5, 4.4, 4.4), rgb(150, 104, 66), barrel)
				for _, h in { 1, 4 } do
					c.Block(x, y + h, z, V.new(0.5, 4.7, 4.7), rgb(70, 60, 56), barrel)
				end
			end, c.Lane + 6, 92)
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Sprite("Grapes", x, z, 1.6, { P = grape, L = leaf })
			end, c.Lane + 10, 96)
		end,
	}

	-- Hermes's lane: herms (the travellers' waymarkers), stacks of parcels, signposts and piles of coins with a coin
	-- spinning over each; a great caduceus turning on the knoll.
	local hermesStone, hermesGold, hermesWhite = rgb(214, 210, 200), rgb(228, 190, 82), rgb(250, 250, 255)
	local function herm(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		c.NewPart(model, base * CF.new(0, 0.6, 0), V.new(5, 1.2, 5), hermesStone)
		c.NewPart(model, base * CF.new(0, 7, 0), V.new(3.6, 12, 3.6), hermesStone)
		c.NewPart(model, base * CF.new(0, 14.6, 0), V.new(3.2, 3.2, 3.2), hermesStone)
		c.NewPart(model, base * CF.new(0, 16.6, 0), V.new(4.6, 0.8, 4.6), hermesGold)
		for _, side in { -1, 1 } do
			c.Sprite("Wing", x, z, 0.5, { W = hermesWhite }, {
				Frame = base * CF.new(side * 2.3, 16.2, 0) * CF.Angles(0, math.pi / 2, 0),
				Yaw = if side > 0 then 180 else 0,
				Ghost = true,
				Parent = model,
			})
		end
	end
	local function parcels(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local colors = { rgb(176, 132, 88), rgb(196, 152, 104), rgb(150, 110, 74) }
		local y = 0
		for i = 1, random.Int(2, 3) do
			local s = 5 - i * 0.6
			c.Tilted(
				x + random.Number(-1, 1),
				y + s / 2,
				z + random.Number(-1, 1),
				c.Vector3.new(s * 1.2, s, s),
				random.Pick(colors),
				{
					Yaw = random.Number(0, 90),
					Parent = model,
				}
			)
			y += s
		end
		-- A strap of twine round the bottom one.
		c.Tilted(x, 2.4, z, c.Vector3.new(6.2, 0.4, 0.6), rgb(230, 214, 170), { Parent = model, CanCollide = false })
	end
	local function signpost(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		local wood = rgb(140, 104, 70)
		c.NewPart(model, base * CF.new(0, 6, 0), V.new(1.2, 12, 1.2), wood)
		for i, yaw in { 20, 150, 260 } do
			local arm = base * CF.new(0, 7 + i * 1.4, 0) * CF.Angles(0, math.rad(yaw + c.LaneRandom.Number(-15, 15)), 0)
			c.NewPart(model, arm * CF.new(3, 0, 0), V.new(6, 1.1, 0.4), rgb(214, 196, 150))
			c.NewPart(
				model,
				arm * CF.new(6.3, 0, 0) * CF.Angles(0, 0, math.rad(45)),
				V.new(0.8, 0.8, 0.4),
				rgb(214, 196, 150)
			)
		end
	end
	local function coinPile(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local coin = { Shape = c.Enum.PartType.Cylinder, Turn = CF.Angles(0, 0, math.pi / 2) }
		for _ = 1, 3 do
			local cx, cz = x + random.Number(-2, 2), z + random.Number(-2, 2)
			for i = 1, random.Int(3, 6) do
				local props = table.clone(coin)
				props.Parent = model
				c.Tilted(cx + random.Number(-0.3, 0.3), (i - 0.5) * 1.1, cz, V.new(1, 6, 6), hermesGold, props)
			end
		end
		-- One big coin spinning over the pile.
		local spin = c.Instance.new("Model")
		spin.Name = "SpinningCoin"
		spin.Parent = model
		local at = c.Stand(x, z) * CF.new(0, 11, 0)
		c.NewPart(spin, at, V.new(0.8, 5, 5), hermesGold, { Shape = c.Enum.PartType.Cylinder, CanCollide = false })
		Motion.Spin(spin, at.Position, at.UpVector, 90)
		Motion.Bob(spin, 0.8, 3)
	end
	themes.Hermes = {
		Path = rgb(186, 176, 154),
		Birds = { rgb(250, 250, 255), rgb(230, 236, 250), rgb(240, 170, 90) },
		Obstacles = {
			{ 3, 3.5, herm, Name = "Herm" },
			{ 2, 5, parcels, Name = "Parcels" },
			{ 2, 7, signpost, Name = "Signpost" },
			{ 2, 5, coinPile, Name = "Coins" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local staff = c.Instance.new("Model")
			staff.Name = "Caduceus"
			staff.Parent = model
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 1, 0), V.new(7, 2, 7), hermesStone)
			c.NewPart(staff, base * CF.new(0, 18, 0), V.new(2.2, 32, 2.2), hermesGold)
			for i = 0, 18 do
				for _, phase in { 0, math.pi } do
					local a = i * 0.9 + phase
					c.NewPart(
						staff,
						base * CF.new(math.cos(a) * 2.6, 6 + i * 1.3, math.sin(a) * 2.6),
						V.new(1.6, 1.6, 1.6),
						rgb(84, 150, 92),
						{ CanCollide = false }
					)
				end
			end
			c.NewPart(
				staff,
				base * CF.new(0, 35, 0),
				V.new(3.6, 3.6, 3.6),
				hermesGold,
				{ Shape = c.Enum.PartType.Ball }
			)
			for _, side in { -1, 1 } do
				c.Sprite("Wing", x, z, 1.1, { W = hermesWhite }, {
					Frame = base * CF.new(side * 1.4, 29, 0) * CF.Angles(0, math.pi / 2, 0),
					Yaw = if side > 0 then 180 else 0,
					Ghost = true,
					Parent = staff,
				})
			end
			Motion.Spin(staff, base.Position, base.UpVector, 20)
		end,
		Life = function(c: any, life: any)
			-- Gusts blowing down the road.
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 6, z, c.Vector3.new(100, 8, 50), {
					Texture = SMOKE,
					Color = rgb(255, 255, 255),
					Size = { { 0, 0.6 }, { 1, 2.4 } },
					Transparency = { { 0, 0.7 }, { 1, 1 } },
					Lifetime = { 1.5, 2.5 },
					Speed = { 0.5, 1 },
					Acceleration = c.Frame.LookVector * 14,
					Rate = 5,
				})
			end
		end,
		Floor = rgb(214, 204, 178),
		Cap = rgb(132, 192, 226),
		SideA = rgb(170, 160, 140),
		SideB = rgb(186, 176, 154),
		Leaves = rgb(120, 182, 112),
		Trunk = rgb(140, 112, 82),
		Stone = rgb(200, 192, 172),
		Cloud = rgb(236, 240, 248),
		Clouds = 4,
		Plants = { { "Pine2", 3 }, { "RoundTree", 3, 70 } },
		Props = function(c: any)
			local V = c.Vector3
			local stone, gold, white = rgb(214, 210, 200), rgb(228, 190, 82), rgb(250, 250, 255)
			-- Herms, the travellers' waymarkers: a pillar with Hermes's head and hat.
			Props.Edges(c, 64, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 5, z, V.new(3, 10, 3), stone)
				c.Block(x, y + 11.5, z, V.new(2.6, 3, 2.6), stone)
				c.Block(x, y + 13.3, z, V.new(3.6, 0.6, 3.6), gold)
			end)
			-- His caduceus: a golden staff, two serpents and a pair of wings.
			for _, side in { -1, 1 } do
				local x, z = side * 86, c.Random.Number(-70, 70)
				local y = c.Ground(x, z)
				local face = if side > 0 then 90 else -90
				c.Block(x, y + 13, z, V.new(1.6, 26, 1.6), gold)
				for i = 0, 13 do
					for _, phase in { 0, math.pi } do
						local a = i * 0.9 + phase
						c.Block(
							x + math.cos(a) * 1.8,
							y + 4 + i * 1.3,
							z + math.sin(a) * 1.8,
							V.new(1.2, 1.2, 1.2),
							rgb(84, 150, 92)
						)
					end
				end
				c.Block(x, y + 26.6, z, V.new(2.6, 2.6, 2.6), gold, { Shape = c.Enum.PartType.Ball })
				c.Sprite("Wing", x, z - 3, 0.8, { W = white }, { Y = y + 21, Yaw = face })
				c.Sprite("Wing", x, z + 3, 0.8, { W = white }, { Y = y + 21, Yaw = face + 180 })
			end
			-- Winged sandals on plinths.
			Props.Scatter(c, 3, function(x: number, z: number)
				local y = c.Ground(x, z)
				local face = if x > 0 then 90 else -90
				c.Block(x, y + 2, z, V.new(6, 4, 8), stone)
				c.Block(x, y + 4.6, z, V.new(2.4, 1.2, 5), rgb(150, 104, 66))
				c.Sprite("Wing", x, z - 1.6, 0.6, { W = white }, { Y = y + 5, Yaw = face })
				c.Sprite("Wing", x, z + 1.6, 0.6, { W = white }, { Y = y + 5, Yaw = face + 180 })
			end, c.Lane + 10, 90)
			-- Coins, for the god of trade.
			Props.Scatter(c, 5, function(x: number, z: number)
				local y = c.Ground(x, z)
				for i = 1, c.Random.Int(3, 7) do
					c.Block(
						x + c.Random.Number(-0.4, 0.4),
						y + (i - 0.5) * 1.1,
						z + c.Random.Number(-0.4, 0.4),
						V.new(1, 6, 6),
						gold,
						{ Shape = c.Enum.PartType.Cylinder, Turn = c.CFrame.Angles(0, 0, math.pi / 2) }
					)
				end
			end, c.Lane + 6, 96)
		end,
	}

	-- Hephaestus's lane: anvils on stumps, slag with glowing seams, ore carts, half-buried cogs and girders; a forge on
	-- the knoll, lava cracks in the floor and embers rising.
	local iron, rust, molten, ember = rgb(62, 60, 66), rgb(132, 82, 58), rgb(255, 120, 40), rgb(255, 170, 70)
	local function embers(c: any, parent: any, x: number, y: number, z: number, size: any, rate: number)
		Lane.Motes(c, parent, x, y, z, size, {
			Texture = FIRE,
			Color = { ember, molten },
			LightEmission = 1,
			Size = { { 0, 0.35 }, { 1, 0 } },
			Lifetime = { 1.5, 3 },
			Speed = { 3, 6 },
			EmissionDirection = c.Enum.NormalId.Top,
			Acceleration = c.Vector3.new(0, 2, 0),
			Rate = rate,
		})
	end
	local function anvil(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local k = 1.3
		local base = c.Stand(x, z)
		local function piece(px: number, py: number, pz: number, size: any, color: any, turn: any?)
			c.NewPart(model, base * CF.new(px * k, py * k, pz * k) * (turn or CF.new()), size * k, color)
		end
		piece(0, 2.5, 0, V.new(5, 5, 5), rgb(110, 82, 60))
		piece(0, 5.6, 0, V.new(4.4, 1.6, 5), iron)
		piece(0, 7, 0, V.new(2.6, 1.6, 3.4), iron)
		piece(0, 8.6, 0.6, V.new(4.6, 1.8, 8.4), iron)
		piece(0, 8.9, 5.4, V.new(2.4, 1.2, 2.4), iron)
		-- The hammer left on it.
		piece(1, 10, -1, V.new(0.8, 0.8, 6), rgb(110, 82, 60), CF.Angles(0, math.rad(30), 0))
		piece(1.9, 10.2, -3.6, V.new(2.6, 1.6, 1.6), iron, CF.Angles(0, math.rad(30), 0))
	end
	local function pillar(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local h = random.Number(16, 26)
		local base = c.Stand(x, z)
		c.NewPart(model, base * CF.new(0, h / 2, 0), V.new(7, h, 7), rgb(110, 70, 58))
		c.NewPart(model, base * CF.new(0, h + 0.4, 0), V.new(8, 0.8, 8), iron)
		c.NewPart(model, base * CF.new(0, h * 0.45, -3.55), V.new(2, h * 0.3, 0.2), molten, {
			Material = c.Enum.Material.Neon,
			CanCollide = false,
		})
		c.Emitter(model, base * CF.new(0, h + 1, 0), V.new(5, 1, 5), {
			Name = "Smoke",
			Texture = SMOKE,
			Color = rgb(70, 66, 70),
			Size = { { 0, 2 }, { 1, 7 } },
			Transparency = { { 0, 0.5 }, { 1, 1 } },
			Lifetime = { 3, 5 },
			Speed = { 3, 5 },
			Rate = 3,
		})
	end
	local function cart(c: any, x: number, z: number, model: any)
		local V = c.Vector3
		local random = c.LaneRandom
		local yaw = random.Number(-25, 25)
		for _, dx in { -2.6, 2.6 } do
			c.Tilted(x + dx, 0.2, z, V.new(0.6, 0.4, 14), iron, { Yaw = yaw, CanCollide = false, Parent = model })
		end
		c.Tilted(x, 3.4, z, V.new(6.4, 4, 8), rust, { Yaw = yaw, Parent = model })
		c.Tilted(x, 5.8, z, V.new(5, 1.4, 6.4), molten, { Yaw = yaw, Material = c.Enum.Material.Neon, Parent = model })
		c.Tilted(
			x,
			6.8,
			z + 0.6,
			V.new(3, 1.2, 3.4),
			molten,
			{ Yaw = yaw + 20, Material = c.Enum.Material.Neon, Parent = model }
		)
		for _, dx in { -3.4, 3.4 } do
			for _, dz in { -2.6, 2.6 } do
				c.Tilted(x + dx, 1.6, z + dz, V.new(1, 2.6, 2.6), iron, {
					Yaw = yaw,
					Shape = c.Enum.PartType.Cylinder,
					Parent = model,
				})
			end
		end
	end
	-- A cog of radius `r` round `center`'s look axis, turning at `speed` degrees a second.
	local function gear(c: any, center: any, r: number, model: any, speed: number)
		local V, CF = c.Vector3, c.CFrame
		c.NewPart(model, center * CF.Angles(0, math.pi / 2, 0), V.new(2, r * 2, r * 2), rust, {
			Shape = c.Enum.PartType.Cylinder,
		})
		local teeth = math.max(10, math.floor(r * 1.5))
		for i = 0, teeth - 1 do
			c.NewPart(
				model,
				center * CF.Angles(0, 0, i * math.pi * 2 / teeth) * CF.new(0, r + 0.7, 0),
				V.new(2, 1.6, 2.2),
				rust
			)
		end
		c.NewPart(model, center * CF.Angles(0, math.pi / 2, 0), V.new(2.6, r * 0.3, r * 0.3), iron, {
			Shape = c.Enum.PartType.Cylinder,
		})
		Motion.Spin(model, center.Position, center.LookVector, speed)
	end
	local function cog(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local r = random.Number(7, 9)
		-- Half buried, standing on edge, its face across the slope.
		local center = c.Stand(x, z)
			* c.CFrame.new(0, r * 0.3, 0)
			* c.CFrame.Angles(0, math.rad(random.Number(-30, 30)), 0)
		gear(c, center, r, model, random.Number(15, 30) * random.Side())
	end
	themes.Hephaestus = {
		Floor = rgb(78, 70, 70),
		Cap = rgb(92, 80, 76),
		SideA = rgb(58, 52, 54),
		SideB = rgb(68, 60, 62),
		Leaves = rgb(96, 82, 76),
		Trunk = rgb(52, 44, 44),
		Stone = rgb(92, 84, 84),
		Cloud = rgb(80, 76, 80),
		Stones = 10,
		Islands = 2,
		Plants = {},
		Path = rgb(58, 54, 60),
		Birds = { rgb(44, 42, 48), rgb(60, 56, 64), rgb(200, 150, 60) },
		Obstacles = {
			{ 2, 8.5, anvil, Name = "Anvil" },
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(52, 46, 48), c.LaneRandom.Number(5.5, 7.5), molten)
				end,
				Name = "Slag",
			},
			{ 1, 6, cart, Name = "OreCart" },
			{ 3, 9, cog, Name = "Cog" },
			{ 2, 5, pillar, Name = "ChimneyPillar" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local brick = rgb(110, 70, 58)
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 7, 0), V.new(14, 14, 14), brick)
			c.NewPart(model, base * CF.new(0, 14.6, 0), V.new(15, 1.2, 15), iron)
			-- The furnace's mouth glows down the mountain, towards the climbers.
			c.NewPart(model, base * CF.new(0, 5, -7.1), V.new(7, 6, 0.4), molten, {
				Material = c.Enum.Material.Neon,
				CanCollide = false,
			})
			c.NewPart(model, base * CF.new(3, 25, 3), V.new(5, 20, 5), brick)
			c.NewPart(model, base * CF.new(3, 35.4, 3), V.new(6.4, 0.8, 6.4), iron)
			c.Emitter(model, base * CF.new(3, 36, 3), V.new(4, 1, 4), {
				Name = "Smoke",
				Texture = SMOKE,
				Color = rgb(70, 66, 70),
				Size = { { 0, 3 }, { 1, 9 } },
				Transparency = { { 0, 0.4 }, { 1, 1 } },
				Lifetime = { 4, 6 },
				Speed = { 4, 6 },
				Rate = 6,
				Acceleration = V.new(0, 1, 0),
			})
			c.Emitter(model, base * CF.new(0, 5, -8), V.new(6, 4, 1), {
				Name = "Sparks",
				Texture = FIRE,
				Color = { ember, molten },
				LightEmission = 1,
				Size = { { 0, 0.5 }, { 1, 0 } },
				Lifetime = { 0.6, 1.2 },
				Speed = { 6, 12 },
				Rate = 18,
				EmissionDirection = c.Enum.NormalId.Front,
				Acceleration = V.new(0, -20, 0),
			})
		end,
		Life = function(c: any, life: any)
			for _ = 1, 7 do
				local x, z = c.LaneRandom.Number(-50, 50), c.LaneRandom.Number(-c.Half + 12, c.Half - 12)
				Lane.Crack(c, x, z, c.LaneRandom.Int(3, 5), molten, life)
				embers(c, life, x, 1, z, c.Vector3.new(8, 1, 8), 3)
			end
			for _, obstacle in c.Model:FindFirstChild("Lane"):FindFirstChild("Obstacles"):GetChildren() do
				if obstacle.Name == "Slag" or obstacle.Name == "OreCart" then
					local pivot = obstacle:GetChildren()[1].CFrame
					c.Emitter(life, c.CFrame.new(pivot.Position), c.Vector3.new(4, 1, 4), {
						Name = "Embers",
						Texture = FIRE,
						Color = { ember, molten },
						LightEmission = 1,
						Size = { { 0, 0.35 }, { 1, 0 } },
						Lifetime = { 1.5, 3 },
						Speed = { 3, 6 },
						Acceleration = c.Vector3.new(0, 2, 0),
						Rate = 4,
					})
				end
			end
		end,
		Props = function(c: any)
			local V = c.Vector3
			local iron, brick, glow = rgb(62, 60, 66), rgb(110, 70, 58), rgb(255, 120, 40)
			local neon = { Material = c.Enum.Material.Neon, CanCollide = false }
			Props.Edges(c, 52, function(x: number, z: number)
				Props.Fire(c, x, z, iron, rgb(90, 70, 60))
			end)
			-- His forges: a furnace glowing towards the path, and its chimney.
			for _, side in { -1, 1 } do
				local x, z = side * 84, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				c.Block(x, y + 6, z, V.new(12, 12, 14), brick)
				c.Block(x - side * 6.1, y + 4, z, V.new(0.4, 5, 6), glow, neon)
				c.Block(x + side * 2, y + 20, z, V.new(5, 16, 5), brick)
				c.Block(x + side * 2, y + 28.4, z, V.new(6, 0.8, 6), iron)
			end
			-- Anvils.
			Props.Scatter(c, 4, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 1, z, V.new(4, 2, 6), iron)
				c.Block(x, y + 3, z, V.new(2, 2, 3), iron)
				c.Block(x, y + 5, z, V.new(4, 2, 8), iron)
				c.Block(x, y + 5.3, z + 5, V.new(2.4, 1.4, 2), iron)
			end, c.Lane + 8, 92)
			-- Pools of molten metal.
			Props.Scatter(c, 5, function(x: number, z: number)
				local radius = c.Random.Number(4, 6)
				Props.Crater(c, x, z, rgb(96, 70, 62), iron, radius)
				c.Block(x, c.Ground(x, z) + 0.4, z, V.new(radius * 1.5, 0.3, radius * 1.5), glow, {
					Material = c.Enum.Material.Neon,
					CanCollide = false,
					Yaw = 45,
				})
			end, c.Lane + 10, 90)
			-- Two great cogs set in the cliffs either side, turning slowly, faces to the lane.
			for _, side in { -1, 1 } do
				local x, z = side * 76, c.Random.Number(-60, 60)
				local wheel = c.Instance.new("Model")
				wheel.Name = "WallCog"
				wheel.Parent = c.Decor
				local r = 14
				local center = c.Frame
					* c.CFrame.new(x, c.Ground(x, z) + r * 0.55, z)
					* c.CFrame.Angles(0, math.pi / 2, 0)
				gear(c, center, r, wheel, 8 * side)
			end
		end,
	}

	-- Ares's lane: weapon racks, spiked barricades, shields on stands, campfires and war drums; a bronze helmet on the
	-- knoll between two banners.
	local aresBronze, aresRed, aresWood = rgb(196, 146, 72), rgb(184, 44, 40), rgb(110, 82, 60)
	local function weaponRack(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-30, 30)), 0)
		for _, dx in { -4, 4 } do
			c.NewPart(model, base * CF.new(dx, 4, 0), V.new(1, 8, 1), aresWood)
		end
		c.NewPart(model, base * CF.new(0, 7.6, 0), V.new(9.6, 0.8, 0.8), aresWood)
		for i = -3, 3, 2 do
			c.NewPart(model, base * CF.new(i, 6.5, 0.6) * CF.Angles(math.rad(-10), 0, 0), V.new(0.4, 13, 0.4), aresWood)
			c.NewPart(
				model,
				base * CF.new(i, 13.2, 1.7) * CF.Angles(math.rad(-10), 0, 0),
				V.new(0.8, 1.6, 0.4),
				rgb(200, 204, 210)
			)
		end
		c.NewPart(model, base * CF.new(0, 3.6, -0.9) * CF.Angles(0, math.pi / 2, 0), V.new(0.6, 5.4, 5.4), aresBronze, {
			Shape = c.Enum.PartType.Cylinder,
		})
	end
	local function barricade(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.new(0, 2.2, 0) * CF.Angles(0, math.rad(c.LaneRandom.Number(-50, 50)), 0)
		c.NewPart(model, base, V.new(12, 1.6, 1.6), aresWood, { Shape = c.Enum.PartType.Cylinder })
		for i = -2, 2 do
			for _, lean in { -40, 40 } do
				c.NewPart(
					model,
					base * CF.new(i * 2.5, 0, 0) * CF.Angles(math.rad(lean), 0, 0),
					V.new(0.6, 6, 0.6),
					rgb(150, 112, 74)
				)
			end
		end
	end
	local function shieldStand(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-25, 25)), 0)
		c.NewPart(model, base * CF.new(0, 3.5, 0), V.new(0.8, 7, 0.8), aresWood)
		local face = base * CF.new(0, 5, -0.7) * CF.Angles(0, math.pi / 2, 0)
		c.NewPart(model, face, V.new(0.8, 7, 7), aresBronze, { Shape = c.Enum.PartType.Cylinder })
		c.NewPart(model, face * CF.new(0.5, 0, 0), V.new(0.4, 2.4, 2.4), aresRed, { Shape = c.Enum.PartType.Cylinder })
		c.NewPart(model, base * CF.new(2, 7, 0.8) * CF.Angles(0, 0, math.rad(-12)), V.new(0.5, 14, 0.5), aresWood)
	end
	local function campfire(c: any, x: number, z: number, model: any)
		Lane.Ring(c, x, z, model, rgb(110, 100, 96), 3.2, 8, c.Vector3.new(1.8, 1.2, 1.8))
		for _, yaw in { 0, 60, 120 } do
			c.Tilted(x, 0.6, z, c.Vector3.new(5, 0.9, 0.9), aresWood, { Yaw = yaw, Parent = model })
		end
		Lane.Flame(c, c.Stand(x, z) * c.CFrame.new(0, 0.6, 0), model, 0.8)
		c.Emitter(model, c.Stand(x, z) * c.CFrame.new(0, 4, 0), c.Vector3.new(1, 1, 1), {
			Name = "Smoke",
			Texture = SMOKE,
			Color = rgb(90, 86, 84),
			Size = { { 0, 1.5 }, { 1, 6 } },
			Transparency = { { 0, 0.5 }, { 1, 1 } },
			Lifetime = { 3, 5 },
			Speed = { 3, 5 },
			Rate = 3,
		})
	end
	themes.Ares = {
		Path = rgb(124, 82, 66),
		Birds = { rgb(70, 52, 42), rgb(54, 40, 34), rgb(220, 190, 140) },
		Obstacles = {
			{ 2, 6, weaponRack, Name = "WeaponRack" },
			{ 3, 7, barricade, Name = "Barricade" },
			{ 2, 4.5, shieldStand, Name = "ShieldStand" },
			{ 2, 4.5, campfire, Name = "Campfire" },
			{
				1,
				3.5,
				function(c: any, x: number, z: number, model: any)
					local base = c.Stand(x, z) * c.CFrame.new(0, 2.5, 0) * c.CFrame.Angles(0, 0, math.pi / 2)
					local cylinder = { Shape = c.Enum.PartType.Cylinder }
					c.NewPart(model, base, c.Vector3.new(5, 6, 6), aresRed, cylinder)
					for _, d in { -2.4, 2.4 } do
						c.NewPart(
							model,
							base * c.CFrame.new(d, 0, 0),
							c.Vector3.new(0.4, 6.4, 6.4),
							aresBronze,
							cylinder
						)
					end
				end,
				Name = "WarDrum",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local top = Lane.Pedestal(c, x, z, model, rgb(126, 86, 72), aresBronze, 4, 12, y)
			c.Sprite("Helmet", x, z, 1.8, { R = aresRed, B = aresBronze }, { Frame = top, Yaw = 0, Parent = model })
			for _, side in { -1, 1 } do
				local pole = c.Stand(x + side * 9, z + 4, y)
				c.NewPart(model, pole * c.CFrame.new(0, 12, 0), c.Vector3.new(1, 24, 1), aresWood)
				c.NewPart(model, pole * c.CFrame.new(side * 3.2, 19, 0), c.Vector3.new(6, 9, 0.4), aresRed)
			end
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 3, z, c.Vector3.new(100, 4, 50), {
					Texture = SMOKE,
					Color = rgb(170, 130, 100),
					Size = { { 0, 1 }, { 1, 3.5 } },
					Transparency = { { 0, 0.8 }, { 1, 1 } },
					Lifetime = { 3, 5 },
					Speed = { 0.5, 1.5 },
					Rate = 3,
				})
			end
		end,
		Floor = rgb(150, 96, 78),
		Cap = rgb(160, 58, 50),
		SideA = rgb(112, 76, 64),
		SideB = rgb(126, 86, 72),
		Leaves = rgb(122, 112, 72),
		Trunk = rgb(92, 70, 56),
		Stone = rgb(132, 102, 92),
		Stones = 8,
		Plants = { { "Bush", 3 }, { "Pine3", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local bronze, red, wood, canvas = rgb(196, 146, 72), rgb(184, 44, 40), rgb(110, 82, 60), rgb(196, 176, 140)
			-- War banners along the path.
			Props.Edges(c, 56, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 9, z, V.new(1, 18, 1), wood)
				c.Block(x, y + 14, z + 3.4, V.new(0.4, 8, 6), red)
			end)
			-- The camp: a tent each side, a red pennant on its ridge.
			for _, side in { -1, 1 } do
				local x, z = side * 82, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				for _, s in { -1, 1 } do
					c.Block(x + s * 3.2, y + 4, z, V.new(0.6, 9.5, 14), canvas, {
						Turn = c.CFrame.Angles(0, 0, s * math.rad(40)),
					})
				end
				c.Block(x, y + 9, z + 6, V.new(0.4, 4, 0.4), wood)
				c.Block(x, y + 10.4, z + 7.2, V.new(0.3, 1.4, 2.4), red)
			end
			-- Round bronze shields propped facing the path, a spear beside each.
			Props.Scatter(c, 6, function(x: number, z: number)
				local y = c.Ground(x, z)
				local out = if x > 0 then 1 else -1
				local disc = { Shape = c.Enum.PartType.Cylinder }
				c.Block(x, y + 3.2, z, V.new(0.8, 6, 6), bronze, disc)
				c.Block(x - out * 0.5, y + 3.2, z, V.new(0.4, 2, 2), red, disc)
				c.Block(x + out * 1.5, y + 7, z + 3.5, V.new(0.6, 14, 0.6), wood, {
					Turn = c.CFrame.Angles(math.rad(12), 0, 0),
				})
			end, c.Lane + 8, 92)
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Sprite("Helmet", x, z, 1.4, { R = red, B = bronze })
			end, c.Lane + 10, 96)
		end,
	}

	-- Aphrodite's lane: rose hedges, heart topiaries, little fountains and blossom trees; a heart on the knoll, bobbing,
	-- and petals falling all along.
	local roseRed, rosePink, hedge = rgb(214, 44, 72), rgb(240, 120, 160), rgb(80, 146, 86)
	local function roseHedge(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		local yaw = random.Number(0, 90)
		c.Tilted(x, 2, z, c.Vector3.new(8, 4, 6), hedge, { Yaw = yaw, Parent = model })
		c.Tilted(x, 4.6, z, c.Vector3.new(6, 2, 4.4), hedge, { Yaw = yaw + 10, Parent = model })
		for _ = 1, 9 do
			c.Tilted(
				x + random.Number(-3.4, 3.4),
				random.Number(2, 5.6),
				z + random.Number(-2.6, 2.6),
				c.Vector3.new(1.3, 1.3, 1.3),
				random.Pick({ roseRed, rosePink }),
				{ Yaw = random.Number(0, 90), Parent = model, CanCollide = false }
			)
		end
	end
	local function heartTopiary(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		c.NewPart(model, base * CF.new(0, 1.5, 0), V.new(4, 3, 4), rgb(232, 196, 186))
		c.NewPart(model, base * CF.new(0, 5, 0), V.new(0.8, 4, 0.8), rgb(120, 90, 70))
		c.Sprite("Heart", x, z, 0.9, { R = roseRed, W = rgb(255, 224, 232) }, {
			Frame = base * CF.new(0, 6.8, 0),
			Yaw = c.LaneRandom.Number(-25, 25),
			Parent = model,
		})
	end
	local function fountain(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, 0, math.pi / 2)
		local marble = rgb(248, 236, 236)
		local cylinder = { Shape = c.Enum.PartType.Cylinder }
		c.NewPart(model, base * CF.new(1.2, 0, 0), V.new(2.4, 9, 9), marble, cylinder)
		c.NewPart(model, base * CF.new(2.45, 0, 0), V.new(0.2, 7.6, 7.6), rgb(150, 210, 240), {
			Shape = c.Enum.PartType.Cylinder,
			Material = c.Enum.Material.Neon,
			Transparency = 0.2,
			CanCollide = false,
		})
		c.NewPart(model, base * CF.new(4, 0, 0), V.new(5, 1.4, 1.4), marble, cylinder)
		c.NewPart(model, base * CF.new(6.6, 0, 0), V.new(0.8, 3.4, 3.4), marble, cylinder)
		c.Emitter(model, c.Stand(x, z) * CF.new(0, 7, 0), V.new(0.6, 0.6, 0.6), {
			Name = "Spray",
			Texture = SPARKLE,
			Color = rgb(210, 240, 255),
			LightEmission = 0.6,
			Size = { { 0, 0.5 }, { 1, 0.2 } },
			Lifetime = { 0.8, 1.1 },
			Speed = { 7, 9 },
			Acceleration = V.new(0, -18, 0),
			Rate = 30,
		})
	end
	themes.Aphrodite = {
		Path = rgb(248, 226, 230),
		Birds = { rgb(255, 250, 252), rgb(250, 210, 226), rgb(240, 150, 170) },
		Obstacles = {
			{ 3, 5.5, roseHedge, Name = "RoseHedge" },
			{ 2, 4.5, heartTopiary, Name = "HeartTopiary" },
			{ 1, 5, fountain, Name = "Fountain" },
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"BlossomTree",
						{ Leaves = rgb(240, 156, 186), Scale = c.LaneRandom.Number(0.5, 0.6) }
					)
				end,
				Name = "Blossom",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local top = Lane.Pedestal(c, x, z, model, rgb(248, 236, 236), rgb(222, 118, 142), 3, 10, y)
			local heart = c.Sprite("Heart", x, z, 2.2, { R = roseRed, W = rgb(255, 224, 232) }, {
				Frame = top * c.CFrame.new(0, 2, 0),
				Yaw = 0,
				Parent = model,
			})
			Motion.Bob(heart, 1.2, 3)
		end,
		Life = function(c: any, life: any)
			-- Petals falling over the whole stretch.
			for i = 1, 3 do
				local z = -c.Half + (i - 0.5) * c.Half * 2 / 3
				Lane.Motes(c, life, 0, 34, z, c.Vector3.new(120, 2, 90), {
					Texture = SPARKLE,
					Color = { rgb(255, 150, 180), rgb(255, 210, 225) },
					Size = { { 0, 0.6 }, { 1, 0.5 } },
					Lifetime = { 6, 9 },
					Speed = { 0.5, 1.5 },
					Acceleration = c.Vector3.new(0, -4, 0),
					Rotation = { 0, 360 },
					RotSpeed = { -90, 90 },
					Rate = 8,
				})
			end
		end,
		Floor = rgb(236, 196, 204),
		Cap = rgb(222, 118, 142),
		SideA = rgb(240, 214, 220),
		SideB = rgb(248, 226, 230),
		Leaves = rgb(96, 158, 92),
		Trunk = rgb(190, 140, 140),
		Stone = rgb(242, 220, 224),
		Plants = { { "BlossomTree", 3, Leaves = rgb(240, 156, 186) }, { "Bush", 4 } },
		Props = function(c: any)
			-- Roses.
			Props.Scatter(c, 40, function(x: number, z: number)
				Props.Flower(c, x, z, rgb(214, 44, 72), rgb(150, 20, 46))
			end, c.Lane + 1, 102)
			Props.Scatter(c, 5, function(x: number, z: number)
				c.Sprite("Heart", x, z, c.Random.Number(1.8, 2.6), { R = rgb(222, 62, 92), W = rgb(255, 224, 232) }, {
					Lift = c.Random.Pick({ 0, 8, 14 }),
				})
			end, c.Lane + 10, 96)
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Place("SmallArch", x, z, { Solid = rgb(232, 120, 150), Yaw = 0 })
			end, c.Lane + 22, 90)
			-- The scallop shell she rose from the sea on, and its pearl.
			local side = c.Random.Side()
			local x, z = side * 84, c.Random.Number(-50, 50)
			local y = c.Ground(x, z)
			Props.Fan(c, x, y + 1, z, 9, 12, { rgb(250, 226, 214), rgb(240, 196, 190) })
			c.Block(x - side * 1.5, y + 3, z, c.Vector3.new(3, 3, 3), rgb(250, 248, 240), {
				Shape = c.Enum.PartType.Ball,
			})
		end,
	}

	-- Artemis's lane: pines, archery targets, fallen logs and silver stags; her crescent moon on the knoll, and
	-- fireflies between the trees.
	local function target(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local wood = rgb(120, 92, 66)
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-25, 25)), 0)
		for _, dx in { -3, 3 } do
			c.NewPart(model, base * CF.new(dx, 4, 0.8), V.new(0.8, 8, 0.8), wood)
		end
		local rings = { rgb(240, 240, 236), rgb(40, 40, 44), rgb(70, 130, 210), rgb(214, 60, 52), rgb(240, 204, 70) }
		for i, color in rings do
			local d = 10 - (i - 1) * 1.9
			c.NewPart(
				model,
				base * CF.new(0, 7.5, -(i - 1) * 0.12) * CF.Angles(0, math.pi / 2, 0),
				V.new(0.6, d, d),
				color,
				{
					Shape = c.Enum.PartType.Cylinder,
				}
			)
		end
		c.NewPart(model, base * CF.new(0.6, 7.8, -1.4), V.new(0.3, 0.3, 3), wood)
	end
	local function stag(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local silver = rgb(214, 220, 232)
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(0, 360)), 0)
		c.NewPart(model, base * CF.new(0, 1, 0), V.new(4, 2, 8), rgb(150, 160, 176))
		c.NewPart(model, base * CF.new(0, 6.5, 0), V.new(2.6, 2.8, 6.4), silver)
		for _, dx in { -0.9, 0.9 } do
			for _, dz in { -2.4, 2.4 } do
				c.NewPart(model, base * CF.new(dx, 3.5, dz), V.new(0.8, 3.4, 0.8), silver)
			end
		end
		c.NewPart(model, base * CF.new(0, 8.8, 2.9) * CF.Angles(math.rad(-30), 0, 0), V.new(1.4, 3.6, 1.4), silver)
		c.NewPart(model, base * CF.new(0, 10.4, 4), V.new(1.4, 1.4, 2.6), silver)
		for _, side in { -1, 1 } do
			c.NewPart(
				model,
				base * CF.new(side * 0.8, 12.2, 3.6) * CF.Angles(0, 0, math.rad(side * -25)),
				V.new(0.4, 3, 0.4),
				silver
			)
			c.NewPart(
				model,
				base * CF.new(side * 1.6, 13.2, 3.6) * CF.Angles(0, 0, math.rad(side * -60)),
				V.new(0.4, 1.6, 0.4),
				silver
			)
		end
	end
	themes.Artemis = {
		Path = rgb(150, 160, 176),
		Birds = { rgb(150, 130, 110), rgb(120, 100, 84), rgb(240, 200, 80) },
		Obstacles = {
			{
				3,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(c, x, z, model, c.LaneRandom.Pick({ "SnowPine", "Pine", "Pine3" }), {
						Leaves = rgb(52, 104, 86),
						Scale = c.LaneRandom.Number(0.65, 0.8),
					})
				end,
				Name = "Pine",
			},
			{ 2, 5.5, target, Name = "Target" },
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Log(c, x, z, model, rgb(80, 66, 60), rgb(180, 150, 110), 12)
				end,
				Name = "FallenLog",
			},
			{ 1, 4.5, stag, Name = "SilverStag" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * c.CFrame.new(0, 7, 0), c.Vector3.new(1.4, 14, 1.4), rgb(200, 206, 218))
			local moon = c.Sprite("Moon", x, z, 2.2, { M = rgb(236, 240, 255) }, {
				Frame = base * c.CFrame.new(0, 14, 0),
				Yaw = 0,
				Neon = true,
				Ghost = true,
				Parent = model,
			})
			Motion.Bob(moon, 1.2, 4)
		end,
		Life = function(c: any, life: any)
			for i = 1, 5 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 5
				Lane.Motes(c, life, 0, 6, z, c.Vector3.new(100, 8, 40), {
					Texture = SPARKLE,
					Color = { rgb(220, 255, 200), rgb(200, 230, 255) },
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.5, 0.6 }, { 1, 0 } },
					Lifetime = { 2, 4 },
					Speed = { 0.5, 1.5 },
					Rate = 6,
				})
			end
		end,
		Floor = rgb(94, 102, 112),
		Cap = rgb(226, 232, 240),
		SideA = rgb(58, 70, 92),
		SideB = rgb(66, 80, 104),
		Leaves = rgb(52, 104, 86),
		Trunk = rgb(70, 60, 58),
		Stone = rgb(150, 160, 176),
		Cloud = rgb(120, 130, 160),
		Plants = { { "SnowPine", 4, 70 }, { "Pine", 4 }, { "Pine3", 3 }, { "SmallPine", 4 } },
		Props = function(c: any)
			local V = c.Vector3
			local wood = rgb(120, 92, 66)
			c.Sprite(
				"Moon",
				-150,
				30,
				7,
				{ M = rgb(236, 240, 255) },
				{ Y = 70, Yaw = -90, Upright = true, Neon = true, Ghost = true }
			)
			-- Archery targets facing the path, an arrow in each.
			local rings =
				{ rgb(240, 240, 236), rgb(40, 40, 44), rgb(70, 130, 210), rgb(214, 60, 52), rgb(240, 204, 70) }
			Props.Scatter(c, 5, function(x: number, z: number)
				local y = c.Ground(x, z)
				local out = if x > 0 then 1 else -1
				for _, dz in { -2.5, 2.5 } do
					c.Block(x + out * 0.8, y + 3, z + dz, V.new(0.8, 6, 0.8), wood)
				end
				for i, color in rings do
					local d = 8 - (i - 1) * 1.5
					c.Block(x - out * (i - 1) * 0.12, y + 6.5, z, V.new(0.6, d, d), color, {
						Shape = c.Enum.PartType.Cylinder,
					})
				end
				c.Block(x - out * 1.6, y + 6.8, z + 0.5, V.new(3, 0.3, 0.3), wood)
			end, c.Lane + 8, 92)
			-- Silver lights drifting between the trees.
			Props.Scatter(c, 8, function(x: number, z: number)
				c.Block(x, c.Ground(x, z) + c.Random.Number(5, 16), z, V.new(1.2, 1.2, 1.2), rgb(220, 236, 255), {
					Shape = c.Enum.PartType.Ball,
					Material = c.Enum.Material.Neon,
					CanCollide = false,
				})
			end, c.Lane + 4, 100)
		end,
	}

	-- Apollo's lane: golden tripods with fire, lyres on stands, laurel trees, sun discs turning and white columns; a
	-- golden sun turning on the knoll.
	local apolloGold, apolloMarble = rgb(236, 186, 62), rgb(244, 238, 226)
	local function tripod(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		for i = 0, 2 do
			local a = i * math.pi * 2 / 3
			c.NewPart(
				model,
				base * CF.new(math.cos(a) * 1.6, 3.5, math.sin(a) * 1.6) * CF.Angles(0, -a, math.rad(-12)),
				V.new(0.6, 7.4, 0.6),
				apolloGold
			)
		end
		c.NewPart(model, base * CF.new(0, 7.4, 0), V.new(5, 1.4, 5), apolloGold)
		Lane.Flame(c, base * CF.new(0, 7.6, 0), model, 0.9)
	end
	local function sunDisc(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local top = Lane.Pedestal(c, x, z, model, apolloMarble, apolloGold, 5, 4)
		local disc = c.Instance.new("Model")
		disc.Name = "Disc"
		disc.Parent = model
		local center = top * CF.new(0, 4.5, 0)
		c.NewPart(
			disc,
			center * CF.Angles(0, math.pi / 2, 0),
			V.new(0.8, 7, 7),
			apolloGold,
			{ Shape = c.Enum.PartType.Cylinder }
		)
		for i = 0, 7 do
			c.NewPart(
				disc,
				center * CF.Angles(0, 0, i * math.pi / 4) * CF.new(0, 4.6, 0),
				V.new(1, 2.2, 0.6),
				rgb(255, 170, 60),
				{
					Material = c.Enum.Material.Neon,
					CanCollide = false,
				}
			)
		end
		Motion.Spin(disc, center.Position, center.LookVector, 30)
	end
	themes.Apollo = {
		Path = rgb(232, 206, 140),
		Birds = { rgb(255, 255, 255), rgb(246, 240, 226), rgb(240, 160, 60) },
		Obstacles = {
			{ 2, 3.5, tripod, Name = "Tripod" },
			{
				2,
				4,
				function(c: any, x: number, z: number, model: any)
					local top = Lane.Pedestal(c, x, z, model, apolloMarble, apolloGold, 3, 4)
					c.Sprite("Lyre", x, z, 0.7, { G = apolloGold, S = rgb(250, 246, 236) }, {
						Frame = top,
						Yaw = c.LaneRandom.Number(-25, 25),
						Parent = model,
					})
				end,
				Name = "Lyre",
			},
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(
						c,
						x,
						z,
						model,
						"RoundTree",
						{ Leaves = rgb(96, 158, 82), Scale = c.LaneRandom.Number(0.6, 0.75) }
					)
				end,
				Name = "Laurel",
			},
			{ 1, 4, sunDisc, Name = "SunDisc" },
			{
				2,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Column(c, x, z, model, apolloMarble, apolloGold, c.LaneRandom.Number(12, 24))
				end,
				Name = "Column",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local top = Lane.Pedestal(c, x, z, model, apolloMarble, apolloGold, 6, 6, y)
			local sun = c.Instance.new("Model")
			sun.Name = "Sun"
			sun.Parent = model
			local center = top * CF.new(0, 9, 0)
			c.NewPart(sun, center, V.new(10, 10, 10), rgb(255, 214, 90), {
				Shape = c.Enum.PartType.Ball,
				Material = c.Enum.Material.Neon,
				CanCollide = false,
			})
			for i = 0, 11 do
				c.NewPart(
					sun,
					center * CF.Angles(0, 0, i * math.pi / 6) * CF.new(0, 8, 0),
					V.new(1.6, 4, 1.2),
					rgb(255, 170, 60),
					{
						Material = c.Enum.Material.Neon,
						CanCollide = false,
					}
				)
			end
			Motion.Spin(sun, center.Position, center.LookVector, 25)
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 8, z, c.Vector3.new(100, 10, 50), {
					Texture = SPARKLE,
					Color = { rgb(255, 236, 150), rgb(255, 200, 90) },
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.8 }, { 1, 0 } },
					Lifetime = { 3, 5 },
					Speed = { 0.3, 1 },
					Rate = 5,
				})
			end
		end,
		Floor = rgb(240, 222, 170),
		Cap = rgb(236, 176, 64),
		SideA = rgb(240, 232, 214),
		SideB = rgb(230, 220, 198),
		Leaves = rgb(96, 158, 82),
		Trunk = rgb(150, 116, 80),
		Stone = rgb(238, 226, 200),
		Plants = { { "RoundTree", 4 }, { "Bush", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local gold = rgb(236, 186, 62)
			local light = { Material = c.Enum.Material.Neon, CanCollide = false, CastShadow = false }
			-- The sun low over one side, its rays round it.
			local sx, sy, sz = 170 * c.Random.Side(), 80, c.Random.Number(-40, 40)
			c.Block(sx, sy, sz, V.new(36, 36, 36), rgb(255, 214, 90), {
				Upright = true,
				Shape = c.Enum.PartType.Ball,
				Material = light.Material,
				CanCollide = false,
				CastShadow = false,
			})
			for i = 0, 11 do
				local a = i * math.pi / 6
				c.Block(sx, sy + math.cos(a) * 27, sz + math.sin(a) * 27, V.new(2, 12, 4), rgb(255, 170, 60), {
					Upright = true,
					Turn = c.CFrame.Angles(a, 0, 0),
					Material = light.Material,
					CanCollide = false,
					CastShadow = false,
				})
			end
			-- A laurel arch over the path, golden tripods along it, and his lyres.
			c.Place("BigArch", 0, 0, { Y = -6, Yaw = 0, Scale = 1.25, Solid = rgb(96, 158, 84), Ghost = true })
			Props.Edges(c, 54, function(x: number, z: number)
				Props.Fire(c, x, z, gold, gold)
			end)
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Sprite("Lyre", x, z, 1.5, { G = gold, S = rgb(250, 246, 236) })
			end, c.Lane + 10, 96)
		end,
	}

	-- Athena's lane: olive trees, broken marble columns, oil jars, owls on plinths and shields propped on spears; her
	-- owl on the knoll.
	local athenaMarble, athenaBlue = rgb(240, 238, 232), rgb(70, 104, 170)
	local owlLegend = {
		B = rgb(150, 120, 92),
		L = rgb(206, 184, 150),
		W = rgb(244, 236, 214),
		K = rgb(30, 28, 30),
		Y = rgb(236, 186, 62),
	}
	local function athenaShield(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-25, 25)), 0)
		c.NewPart(
			model,
			base * CF.new(1.6, 7, 0.6) * CF.Angles(0, 0, math.rad(-8)),
			V.new(0.5, 14, 0.5),
			rgb(128, 108, 88)
		)
		local face = base * CF.new(0, 3.8, -0.4) * CF.Angles(math.rad(-12), math.pi / 2, 0)
		c.NewPart(model, face, V.new(0.8, 7.4, 7.4), athenaBlue, { Shape = c.Enum.PartType.Cylinder })
		c.NewPart(
			model,
			face * CF.new(-0.45, 0, 0),
			V.new(0.2, 3, 3),
			rgb(236, 186, 62),
			{ Shape = c.Enum.PartType.Cylinder }
		)
	end
	themes.Athena = {
		Path = rgb(206, 200, 188),
		Birds = { rgb(150, 120, 92), rgb(206, 184, 150), rgb(236, 186, 62) },
		Obstacles = {
			{
				3,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Tree(c, x, z, model, "RoundTree", {
						Leaves = rgb(132, 152, 104),
						Wood = rgb(128, 108, 88),
						Scale = c.LaneRandom.Number(0.6, 0.75),
					})
				end,
				Name = "Olive",
			},
			{
				2,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Column(c, x, z, model, athenaMarble, athenaBlue, c.LaneRandom.Number(10, 24))
				end,
				Name = "Column",
			},
			{
				2,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Jar(c, x - 1.8, z, model, rgb(200, 120, 72), rgb(40, 34, 32))
					Lane.Jar(c, x + 2.2, z - 1, model, rgb(184, 108, 64), rgb(40, 34, 32), 0.75)
				end,
				Name = "OilJars",
			},
			{
				1,
				4,
				function(c: any, x: number, z: number, model: any)
					local top = Lane.Pedestal(c, x, z, model, athenaMarble, athenaBlue, 4, 5)
					c.Sprite(
						"Owl",
						x,
						z,
						0.8,
						owlLegend,
						{ Frame = top, Yaw = c.LaneRandom.Number(-20, 20), Parent = model }
					)
				end,
				Name = "Owl",
			},
			{ 1, 4.5, athenaShield, Name = "Shield" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local top = Lane.Pedestal(c, x, z, model, athenaMarble, athenaBlue, 4, 10, y)
			c.Sprite("Owl", x, z, 1.8, owlLegend, { Frame = top, Yaw = 0, Parent = model })
		end,
		Life = function(c: any, life: any)
			for i = 1, 3 do
				local z = -c.Half + (i - 0.5) * c.Half * 2 / 3
				Lane.Motes(c, life, 0, 26, z, c.Vector3.new(110, 2, 90), {
					Texture = SPARKLE,
					Color = { rgb(150, 170, 110), rgb(120, 140, 90) },
					Size = { { 0, 0.5 }, { 1, 0.4 } },
					Lifetime = { 6, 9 },
					Speed = { 0.5, 1.5 },
					Acceleration = c.Vector3.new(0, -3, 0),
					Rotation = { 0, 360 },
					RotSpeed = { -60, 60 },
					Rate = 5,
				})
			end
		end,
		Floor = rgb(226, 222, 212),
		Cap = rgb(138, 156, 96),
		SideA = rgb(206, 200, 188),
		SideB = rgb(220, 214, 202),
		Leaves = rgb(132, 152, 104),
		Trunk = rgb(128, 108, 88),
		Stone = rgb(222, 218, 208),
		Plants = { { "RoundTree", 6 }, { "Bush", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local marble, blue = rgb(240, 238, 232), rgb(70, 104, 170)
			Props.Edges(c, 46, function(x: number, z: number)
				Props.Column(c, x, z, marble, blue, 30)
			end)
			c.Place("Pavilion", 84 * c.Random.Side(), c.Random.Number(-80, 80), { Solid = marble, Yaw = 0 })
			-- Her owl on a plinth, each side.
			local owl = {
				B = rgb(150, 120, 92),
				L = rgb(206, 184, 150),
				W = rgb(244, 236, 214),
				K = rgb(30, 28, 30),
				Y = rgb(236, 186, 62),
			}
			for _, side in { -1, 1 } do
				local x, z = side * 86, c.Random.Number(-50, 50)
				local y = c.Ground(x, z)
				c.Block(x, y + 2, z, V.new(6, 4, 6), marble)
				c.Sprite("Owl", x, z, 1.2, owl, { Y = y + 4 })
			end
			-- Jars of olive oil.
			Props.Scatter(c, 6, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 2.2, z, V.new(4.4, 4.4, 4.4), rgb(200, 120, 72), { Shape = c.Enum.PartType.Ball })
				c.Block(x, y + 4.8, z, V.new(1.8, 2, 1.8), rgb(200, 120, 72))
				c.Block(x, y + 5.9, z, V.new(2.4, 0.4, 2.4), rgb(40, 34, 32))
			end, c.Lane + 6, 94)
		end,
	}

	-- Demeter's lane: hay bales, wheat sheaves, a harvest cart, scarecrows and pumpkins; a windmill on the knoll, its
	-- sails turning.
	local harvestHay, harvestWood, harvestWheat = rgb(222, 190, 96), rgb(122, 92, 62), rgb(236, 196, 92)
	local function bales(c: any, x: number, z: number, model: any)
		local random = c.LaneRandom
		if random.Number(0, 1) < 0.5 then
			-- A round bale lying across the slope.
			local base = c.Stand(x, z) * c.CFrame.new(0, 3, 0) * c.CFrame.Angles(0, math.rad(random.Number(-40, 40)), 0)
			c.NewPart(model, base, c.Vector3.new(5, 6, 6), harvestHay, { Shape = c.Enum.PartType.Cylinder })
			c.NewPart(model, base * c.CFrame.new(2.55, 0, 0), c.Vector3.new(0.2, 4, 4), rgb(196, 160, 70), {
				Shape = c.Enum.PartType.Cylinder,
			})
		else
			local yaw = random.Number(0, 90)
			c.Tilted(x, 1.5, z - 2, c.Vector3.new(4, 3, 7), harvestHay, { Yaw = yaw, Parent = model })
			c.Tilted(x + 1, 1.5, z + 3, c.Vector3.new(4, 3, 5), harvestHay, { Yaw = yaw + 30, Parent = model })
			c.Tilted(x, 4.5, z, c.Vector3.new(4, 3, 6), harvestHay, { Yaw = yaw + 8, Parent = model })
		end
	end
	local function sheaves(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		for i = 1, 3 do
			local a = i / 3 * math.pi * 2
			local base = c.Stand(x + math.cos(a) * 2.2, z + math.sin(a) * 2.2)
				* CF.Angles(math.rad(random.Number(-8, 8)), 0, math.rad(random.Number(-8, 8)))
			c.NewPart(model, base * CF.new(0, 3, 0), V.new(2.2, 6, 2.2), rgb(196, 170, 84))
			c.NewPart(model, base * CF.new(0, 3.4, 0), V.new(2.5, 0.6, 2.5), harvestWood)
			c.NewPart(model, base * CF.new(0, 6.6, 0), V.new(2.8, 1.6, 2.8), harvestWheat)
		end
	end
	local function cart(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(random.Number(-40, 40)), 0)
		c.NewPart(model, base * CF.new(0, 3.4, 0), V.new(6, 0.6, 8), harvestWood)
		for _, side in { -1, 1 } do
			c.NewPart(model, base * CF.new(side * 2.8, 4.6, 0), V.new(0.4, 2, 8), harvestWood)
			c.NewPart(model, base * CF.new(side * 3.4, 2.4, -1), V.new(0.6, 4.8, 4.8), rgb(90, 70, 52), {
				Shape = c.Enum.PartType.Cylinder,
			})
		end
		c.NewPart(model, base * CF.new(0, 3, 5), V.new(0.5, 0.5, 3), harvestWood)
		for _ = 1, 5 do
			c.NewPart(
				model,
				base * CF.new(random.Number(-1.6, 1.6), 5, random.Number(-2.6, 2.6)),
				V.new(2.4, 2.2, 2.4),
				rgb(232, 128, 44),
				{ Shape = c.Enum.PartType.Ball }
			)
		end
	end
	local function scarecrow(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-30, 30)), 0)
		c.NewPart(model, base * CF.new(0, 6, 0), V.new(1, 12, 1), harvestWood)
		c.NewPart(model, base * CF.new(0, 9, 0), V.new(10, 1, 1), harvestWood)
		c.NewPart(model, base * CF.new(0, 8, 0), V.new(4, 4, 2.6), rgb(176, 70, 56))
		c.NewPart(model, base * CF.new(0, 11.6, 0), V.new(2.6, 2.6, 2.6), rgb(214, 190, 140))
		c.NewPart(model, base * CF.new(0, 13.1, 0), V.new(5, 0.4, 5), rgb(150, 116, 62))
		c.NewPart(model, base * CF.new(0, 14, 0), V.new(2.6, 1.6, 2.6), rgb(150, 116, 62))
	end
	themes.Demeter = {
		Path = rgb(150, 116, 72),
		Birds = { rgb(36, 34, 40), rgb(52, 50, 58), rgb(220, 180, 70) },
		Obstacles = {
			{ 3, 5, bales, Name = "HayBales" },
			{ 2, 4.5, sheaves, Name = "Sheaves" },
			{ 1, 7, cart, Name = "HarvestCart" },
			{ 2, 5.5, scarecrow, Name = "Scarecrow" },
			{
				1,
				4,
				function(c: any, x: number, z: number, model: any)
					for i = 1, 3 do
						local a = i / 3 * math.pi * 2 + c.LaneRandom.Number(0, 1)
						local s = c.LaneRandom.Number(2.6, 3.6)
						local px, pz = x + math.cos(a) * 2.2, z + math.sin(a) * 2.2
						c.Tilted(px, s / 2, pz, c.Vector3.new(s * 1.2, s, s * 1.2), rgb(232, 128, 44), {
							Shape = c.Enum.PartType.Ball,
							Parent = model,
						})
						c.Tilted(px, s + 0.4, pz, c.Vector3.new(0.4, 1, 0.4), rgb(96, 120, 60), { Parent = model })
					end
				end,
				Name = "Pumpkins",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 5, 0), V.new(9, 10, 9), rgb(236, 226, 200))
			c.NewPart(model, base * CF.new(0, 13, 0), V.new(7, 6, 7), rgb(236, 226, 200))
			c.NewPart(model, base * CF.new(0, 17, 0), V.new(8, 2, 8), rgb(176, 70, 56))
			c.NewPart(model, base * CF.new(0, 19, 0), V.new(5, 2, 5), rgb(176, 70, 56))
			c.NewPart(model, base * CF.new(0, 3, -4.55), V.new(3, 5, 0.2), harvestWood, { CanCollide = false })
			local sails = c.Instance.new("Model")
			sails.Name = "Sails"
			sails.Parent = model
			local hub = base * CF.new(0, 14, -4.2)
			c.NewPart(sails, hub, V.new(1.6, 1.6, 1.6), harvestWood, { CanCollide = false })
			for i = 0, 3 do
				local arm = hub * CF.Angles(0, 0, i * math.pi / 2)
				c.NewPart(sails, arm * CF.new(0, 6.5, 0), V.new(0.6, 13, 0.6), harvestWood, { CanCollide = false })
				c.NewPart(
					sails,
					arm * CF.new(1.4, 7.5, -0.1),
					V.new(2.4, 9, 0.2),
					rgb(244, 236, 220),
					{ CanCollide = false }
				)
			end
			Motion.Spin(sails, hub.Position, hub.LookVector, 30)
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 5, z, c.Vector3.new(100, 8, 50), {
					Texture = SPARKLE,
					Color = rgb(255, 226, 140),
					Size = { { 0, 0 }, { 0.3, 0.5 }, { 1, 0 } },
					Lifetime = { 3, 5 },
					Speed = { 0.5, 1.5 },
					Acceleration = c.Frame.LookVector * 2,
					Rate = 6,
				})
			end
		end,
		Floor = rgb(196, 176, 104),
		Cap = rgb(222, 186, 82),
		SideA = rgb(150, 122, 82),
		SideB = rgb(166, 136, 92),
		Leaves = rgb(110, 162, 72),
		Trunk = rgb(130, 98, 70),
		Stone = rgb(176, 156, 118),
		Plants = { { "RoundTree", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local wheat, stalk, hay, wood = rgb(236, 196, 92), rgb(196, 170, 84), rgb(222, 190, 96), rgb(122, 92, 62)
			local soft = { CanCollide = false }
			-- Fields of wheat.
			Props.Scatter(c, 26, function(x: number, z: number)
				local y = c.Ground(x, z)
				for _ = 1, 5 do
					local wx, wz = x + c.Random.Number(-1.5, 1.5), z + c.Random.Number(-1.5, 1.5)
					local h = c.Random.Number(4, 6)
					c.Block(wx, y + h / 2, wz, V.new(0.4, h, 0.4), stalk, soft)
					c.Block(wx, y + h + 0.6, wz, V.new(0.8, 1.6, 0.8), wheat, soft)
				end
			end, c.Lane + 3, 100)
			-- Hay bales.
			Props.Scatter(c, 5, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 1.5, z, V.new(4, 3, 7), hay)
				c.Block(x, y + 1.5, z + 6, V.new(4, 3, 4), hay, { Yaw = 30 })
				c.Block(x + 0.2, y + 4.5, z + 2, V.new(4, 3, 6), hay)
			end, c.Lane + 8, 92)
			-- A scarecrow each side, like her flock.
			for _, side in { -1, 1 } do
				local x, z = side * 84, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				c.Block(x, y + 6, z, V.new(1, 12, 1), wood)
				c.Block(x, y + 9, z, V.new(1, 1, 10), wood)
				c.Block(x, y + 8, z, V.new(2.6, 4, 4), rgb(176, 70, 56))
				c.Block(x, y + 11.6, z, V.new(2.6, 2.6, 2.6), rgb(214, 190, 140))
				c.Block(x, y + 13.1, z, V.new(5, 0.4, 5), rgb(150, 116, 62))
				c.Block(x, y + 14, z, V.new(2.6, 1.6, 2.6), rgb(150, 116, 62))
			end
		end,
	}

	-- Hestia's lane: braziers, hearth rings, stacks of firewood, bread ovens and clay pots; the eternal flame on the
	-- knoll, embers rising everywhere.
	local hearthStone, hearthClay = rgb(150, 100, 80), rgb(182, 112, 72)
	local function brazier(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		c.NewPart(model, base * CF.new(0, 3, 0), V.new(2.6, 6, 2.6), hearthStone)
		c.NewPart(model, base * CF.new(0, 6.6, 0), V.new(5, 1.6, 5), rgb(182, 122, 62))
		Lane.Flame(c, base * CF.new(0, 7, 0), model, 1)
	end
	local function hearthRing(c: any, x: number, z: number, model: any)
		Lane.Ring(c, x, z, model, hearthStone, 3.6, 9, c.Vector3.new(2.4, 1.8, 2.4))
		for _, yaw in { 20, 80, 140 } do
			c.Tilted(x, 0.7, z, c.Vector3.new(5.4, 1, 1), rgb(100, 70, 52), { Yaw = yaw, Parent = model })
		end
		Lane.Flame(c, c.Stand(x, z) * c.CFrame.new(0, 0.8, 0), model, 1.1)
	end
	local function firewood(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(c.LaneRandom.Number(-40, 40)), 0)
		local cylinder = { Shape = c.Enum.PartType.Cylinder }
		local rows = { { -2.4, 0, 2.4 }, { -1.2, 1.2 }, { 0 } }
		for level, row in rows do
			for _, dz in row do
				c.NewPart(
					model,
					base * CF.new(0, 1.1 + (level - 1) * 2, dz),
					V.new(8, 2.2, 2.2),
					rgb(120, 84, 60),
					cylinder
				)
			end
		end
	end
	local function oven(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z)
		c.NewPart(model, base * CF.new(0, 1, 0), V.new(9, 2, 9), hearthStone)
		c.NewPart(model, base * CF.new(0, 2, 0), V.new(8, 8, 8), hearthClay, { Shape = c.Enum.PartType.Ball })
		c.NewPart(model, base * CF.new(0, 3, -3.6), V.new(3, 2.6, 1), rgb(255, 140, 50), {
			Material = c.Enum.Material.Neon,
			CanCollide = false,
		})
		c.NewPart(model, base * CF.new(1.6, 6.6, 1.6), V.new(1.6, 3, 1.6), hearthStone)
	end
	themes.Hestia = {
		Path = rgb(172, 98, 76),
		Birds = { rgb(150, 90, 60), rgb(200, 120, 70), rgb(250, 200, 90) },
		Obstacles = {
			{ 3, 3, brazier, Name = "Brazier" },
			{ 2, 5, hearthRing, Name = "HearthRing" },
			{ 2, 5, firewood, Name = "Firewood" },
			{ 1, 5, oven, Name = "Oven" },
			{
				1,
				4.5,
				function(c: any, x: number, z: number, model: any)
					Lane.Jar(c, x - 1.6, z, model, hearthClay, rgb(90, 60, 48), 0.7)
					Lane.Jar(c, x + 1.8, z + 1.2, model, rgb(196, 124, 80), rgb(90, 60, 48), 0.6)
				end,
				Name = "Pots",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 2.5, 0), V.new(5, 5, 5), hearthStone)
			c.NewPart(model, base * CF.new(0, 5.6, 0), V.new(11, 1.4, 11), rgb(182, 122, 62))
			c.NewPart(model, base * CF.new(0, 6.8, 0), V.new(12, 1, 12), rgb(182, 122, 62))
			Lane.Flame(c, base * CF.new(0, 7, 0), model, 2.4)
		end,
		Life = function(c: any, life: any)
			for i = 1, 5 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 5
				Lane.Motes(c, life, 0, 2, z, c.Vector3.new(100, 2, 40), {
					Texture = FIRE,
					Color = { rgb(255, 200, 90), rgb(255, 110, 40) },
					LightEmission = 1,
					Size = { { 0, 0.3 }, { 1, 0 } },
					Lifetime = { 2, 4 },
					Speed = { 2, 4 },
					EmissionDirection = c.Enum.NormalId.Top,
					Rate = 5,
				})
			end
		end,
		Floor = rgb(194, 114, 84),
		Cap = rgb(214, 144, 94),
		SideA = rgb(152, 88, 68),
		SideB = rgb(172, 98, 76),
		Leaves = rgb(224, 144, 74),
		Trunk = rgb(112, 78, 62),
		Stone = rgb(172, 122, 102),
		Plants = { { "RoundTree", 4 }, { "TwinTree", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			Props.Edges(c, 48, function(x: number, z: number)
				Props.Fire(c, x, z, rgb(150, 100, 80), rgb(182, 122, 62))
			end)
			-- The hearth of Olympus: a ring of stones round a big fire.
			local x, z = 84 * c.Random.Side(), c.Random.Number(-40, 40)
			local y = c.Ground(x, z)
			for i = 1, 10 do
				local a = i / 10 * math.pi * 2
				c.Block(
					x + math.cos(a) * 8,
					y + 1.2,
					z + math.sin(a) * 8,
					V.new(4, 2.4, 4),
					rgb(150, 100, 80),
					{ Yaw = -math.deg(a) }
				)
			end
			Props.Fire(c, x, z, rgb(150, 100, 80), rgb(182, 122, 62), true)
		end,
	}

	-- Poseidon's lane: coral, rock pools, tridents driven into the sand, anchors and kelp; a fountain on the knoll with
	-- his trident in it, and bubbles rising. The path is a stream.
	local seaGold, seaWater, seaFoam = rgb(232, 192, 76), rgb(52, 150, 210), rgb(220, 244, 250)
	local function coral(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		local color = random.Pick({ rgb(236, 112, 102), rgb(244, 160, 120), rgb(214, 92, 150) })
		local base = c.Stand(x, z) * CF.Angles(0, math.rad(random.Number(0, 90)), 0)
		c.NewPart(model, base * CF.new(0, 3, 0), V.new(1.8, 6, 1.8), color)
		for i = 1, 5 do
			local a = i / 5 * math.pi * 2
			local h = random.Number(3, 6)
			c.NewPart(
				model,
				base
					* CF.new(math.cos(a) * 1.8, 4 + h / 2, math.sin(a) * 1.8)
					* CF.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5),
				V.new(1.2, h, 1.2),
				color
			)
			c.NewPart(
				model,
				base * CF.new(math.cos(a) * (2 + h * 0.45), 4 + h, math.sin(a) * (2 + h * 0.45)),
				V.new(1.6, 1.6, 1.6),
				color,
				{ Shape = c.Enum.PartType.Ball, CanCollide = false }
			)
		end
	end
	local function rockPool(c: any, x: number, z: number, model: any)
		Lane.Ring(c, x, z, model, rgb(150, 170, 172), 5, 12, c.Vector3.new(3, 2, 3.4))
		c.Tilted(x, 1.3, z, c.Vector3.new(8.6, 0.4, 8.6), seaWater, {
			Yaw = 45,
			Material = c.Enum.Material.Neon,
			Transparency = 0.2,
			CanCollide = false,
			Parent = model,
		})
	end
	local function anchor(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local iron = rgb(70, 80, 92)
		local base = c.Stand(x, z)
			* CF.Angles(0, math.rad(c.LaneRandom.Number(-30, 30)), math.rad(c.LaneRandom.Number(-15, 15)))
		c.NewPart(model, base * CF.new(0, 6, 0), V.new(1.4, 12, 1.4), iron)
		c.NewPart(model, base * CF.new(0, 10, 0), V.new(7, 1.2, 1.2), iron)
		c.NewPart(model, base * CF.new(0, 13, 0) * CF.Angles(0, math.pi / 2, 0), V.new(0.6, 3, 3), iron, {
			Shape = c.Enum.PartType.Cylinder,
		})
		for _, side in { -1, 1 } do
			c.NewPart(
				model,
				base * CF.new(side * 2.4, 1.6, 0) * CF.Angles(0, 0, math.rad(side * 50)),
				V.new(1.2, 5, 1.2),
				iron
			)
			c.NewPart(model, base * CF.new(side * 4.2, 3.4, 0), V.new(1.6, 1.6, 1.6), iron)
		end
	end
	local function kelp(c: any, x: number, z: number, model: any)
		local V, CF = c.Vector3, c.CFrame
		local random = c.LaneRandom
		for i = 1, 3 do
			local px, pz = x + random.Number(-2, 2), z + random.Number(-2, 2)
			local base = c.Stand(px, pz)
			local h = 0
			for j = 1, random.Int(4, 6) do
				local s = 2.2
				c.NewPart(
					model,
					base * CF.new(math.sin(j * 1.3 + i) * 0.8, h + s / 2, 0),
					V.new(1.2, s, 1.6),
					rgb(72, 150, 96)
				)
				h += s
			end
		end
	end
	themes.Poseidon = {
		Path = rgb(120, 196, 214),
		Birds = { rgb(250, 250, 250), rgb(190, 196, 204), rgb(240, 190, 70) },
		Obstacles = {
			{ 3, 5, coral, Name = "Coral" },
			{ 2, 7, rockPool, Name = "RockPool" },
			{
				2,
				6,
				function(c: any, x: number, z: number, model: any)
					c.Sprite("Trident", x, z, 1.2, { G = seaGold }, {
						Lift = -3,
						Yaw = c.LaneRandom.Number(-30, 30),
						Tip = c.LaneRandom.Number(-10, 10),
						Parent = model,
					})
				end,
				Name = "Trident",
			},
			{ 1, 6, anchor, Name = "Anchor" },
			{ 2, 4, kelp, Name = "Kelp" },
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			local base = c.Stand(x, z, y)
			local up = base * CF.Angles(0, 0, math.pi / 2)
			local cylinder = { Shape = c.Enum.PartType.Cylinder }
			c.NewPart(model, up * CF.new(1.2, 0, 0), V.new(2.4, 14, 14), rgb(236, 236, 228), cylinder)
			c.NewPart(model, up * CF.new(2.45, 0, 0), V.new(0.2, 12.4, 12.4), seaWater, {
				Shape = c.Enum.PartType.Cylinder,
				Material = c.Enum.Material.Neon,
				Transparency = 0.15,
				CanCollide = false,
			})
			c.Sprite("Trident", x, z, 2, { G = seaGold }, { Frame = base * CF.new(0, 1, 0), Yaw = 0, Parent = model })
			for _, side in { -1, 1 } do
				c.Emitter(model, base * CF.new(side * 4, 2.6, 0), V.new(0.6, 0.6, 0.6), {
					Name = "Spray",
					Texture = SPARKLE,
					Color = seaFoam,
					LightEmission = 0.6,
					Size = { { 0, 0.7 }, { 1, 0.3 } },
					Lifetime = { 1, 1.4 },
					Speed = { 10, 13 },
					Acceleration = V.new(0, -18, 0),
					Rate = 30,
				})
			end
		end,
		Life = function(c: any, life: any)
			for i = 1, 5 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 5
				Lane.Motes(c, life, 0, 2, z, c.Vector3.new(100, 2, 40), {
					Texture = SPARKLE,
					Color = rgb(200, 240, 255),
					LightEmission = 0.5,
					Size = { { 0, 0.4 }, { 1, 0.8 } },
					Transparency = { { 0, 0.3 }, { 1, 1 } },
					Lifetime = { 3, 5 },
					Speed = { 2, 3 },
					EmissionDirection = c.Enum.NormalId.Top,
					Rate = 5,
				})
			end
		end,
		Floor = rgb(206, 196, 160),
		Cap = rgb(72, 168, 182),
		SideA = rgb(150, 170, 172),
		SideB = rgb(166, 186, 188),
		Leaves = rgb(72, 162, 132),
		Trunk = rgb(150, 122, 92),
		Stone = rgb(180, 196, 196),
		Cloud = rgb(230, 244, 248),
		Islands = 4,
		Plants = { { "Bush", 3 }, { "RoundTree", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local water, foam, gold = rgb(52, 150, 210), rgb(220, 244, 250), rgb(232, 192, 76)
			local neon = c.Enum.Material.Neon
			-- Waterfalls from floating rocks either side.
			for _, side in { -1, 1 } do
				local x, z = side * c.Random.Number(140, 170), c.Random.Number(-60, 60)
				local top = c.Random.Number(40, 60)
				c.Place("Island", x, z, { Y = top - 10, Upright = true, Scale = 1.2, Solid = rgb(150, 170, 172) })
				c.Block(x, top - 70, z, V.new(6, 120, 14), water, {
					Upright = true,
					Material = neon,
					Transparency = 0.3,
					CanCollide = false,
					CastShadow = false,
				})
				c.Block(x, top - 3, z, V.new(10, 2, 18), foam, { Upright = true, Material = neon, CanCollide = false })
			end
			-- Rock pools, coral and his trident.
			Props.Scatter(c, 4, function(x: number, z: number)
				local y = c.Ground(x, z)
				for i = 0, 3 do
					local a = math.rad(i * 90)
					c.Block(x + math.cos(a) * 6, y + 1, z + math.sin(a) * 6, V.new(2, 2, 14), foam, { Yaw = -i * 90 })
				end
				c.Block(x, y + 1.4, z, V.new(11, 0.4, 11), water, { Material = neon })
			end, 72, 94)
			local coral = { rgb(236, 112, 102), rgb(244, 160, 120), rgb(214, 92, 150) }
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Place(c.Random.Pick({ "Spire", "SmallSpire" }), x, z, { Solid = c.Random.Pick(coral), Sink = 1 })
			end, c.Lane + 14, 100)
			for _, side in { -1, 1 } do
				c.Sprite("Trident", side * 86, c.Random.Number(-60, 60), 2, { G = gold })
			end
		end,
	}

	-- Hera's lane: golden urns of flowers, peacock statues, clipped hedges, marble benches and crowns on pedestals; a
	-- great peacock on the knoll, her crown turning over it. The path is a royal carpet.
	local heraGold, heraPurple, heraMarble = rgb(232, 192, 76), rgb(122, 72, 160), rgb(242, 238, 236)
	local peacockTail = { rgb(52, 150, 132), rgb(62, 120, 190) }
	local crownLegend = { G = heraGold, R = rgb(204, 52, 62), B = rgb(62, 92, 200) }
	local function peacock(c: any, x: number, z: number, model: any, k: number, lift: number?)
		local V, CF = c.Vector3, c.CFrame
		local base = c.Stand(x, z, lift)
		Lane.Fan(c, base * CF.new(0, 2 * k, 1 * k), model, 11, 9 * k, peacockTail, rgb(40, 60, 150))
		c.NewPart(model, base * CF.new(0, 2.4 * k, 0), V.new(2.4, 3, 3) * k, rgb(52, 92, 180))
		c.NewPart(model, base * CF.new(0, 4.8 * k, -0.8 * k), V.new(1, 3, 1) * k, rgb(52, 92, 180))
		c.NewPart(model, base * CF.new(0, 6.6 * k, -1 * k), V.new(1.4, 1.2, 1.6) * k, rgb(52, 92, 180))
		c.NewPart(model, base * CF.new(0, 0.4 * k, 0), V.new(1, 0.8, 1) * k, heraGold)
	end
	themes.Hera = {
		Path = rgb(122, 72, 160),
		Birds = { rgb(52, 92, 180), rgb(52, 150, 132), rgb(230, 190, 80) },
		Obstacles = {
			{
				3,
				4,
				function(c: any, x: number, z: number, model: any)
					Lane.Jar(c, x, z, model, heraGold, heraPurple, 1)
					for i = 1, 5 do
						local a = i / 5 * math.pi * 2
						c.NewPart(
							model,
							c.Stand(x, z) * c.CFrame.new(math.cos(a) * 1.2, 9.2, math.sin(a) * 1.2),
							c.Vector3.new(1.4, 1.4, 1.4),
							rgb(214, 120, 200),
							{ Shape = c.Enum.PartType.Ball, CanCollide = false }
						)
					end
				end,
				Name = "Urn",
			},
			{
				2,
				7.5,
				function(c: any, x: number, z: number, model: any)
					peacock(c, x, z, model, 0.8)
				end,
				Name = "Peacock",
			},
			{
				2,
				4,
				function(c: any, x: number, z: number, model: any)
					local hedge = rgb(80, 150, 110)
					c.Tilted(
						x,
						3,
						z,
						c.Vector3.new(6, 6, 6),
						hedge,
						{ Yaw = c.LaneRandom.Number(0, 90), Parent = model }
					)
					c.Tilted(x, 8, z, c.Vector3.new(4, 4, 4), hedge, { Shape = c.Enum.PartType.Ball, Parent = model })
				end,
				Name = "Topiary",
			},
			{
				1,
				5,
				function(c: any, x: number, z: number, model: any)
					local yaw = c.LaneRandom.Number(-30, 30)
					c.Tilted(x, 2.8, z, c.Vector3.new(9, 0.8, 3), heraMarble, { Yaw = yaw, Parent = model })
					for _, d in { -3.4, 3.4 } do
						local a = math.rad(yaw)
						c.Tilted(
							x + math.cos(a) * d,
							1.2,
							z - math.sin(a) * d,
							c.Vector3.new(1.4, 2.4, 2.6),
							heraMarble,
							{
								Yaw = yaw,
								Parent = model,
							}
						)
					end
				end,
				Name = "Bench",
			},
			{
				1,
				4,
				function(c: any, x: number, z: number, model: any)
					local top = Lane.Pedestal(c, x, z, model, heraMarble, heraGold, 5, 5)
					c.Sprite(
						"Crown",
						x,
						z,
						0.8,
						crownLegend,
						{ Frame = top, Yaw = c.LaneRandom.Number(-20, 20), Parent = model }
					)
				end,
				Name = "CrownPedestal",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			peacock(c, x, z, model, 2, y)
			local crown = c.Instance.new("Model")
			crown.Name = "Crown"
			crown.Parent = model
			local at = c.Stand(x, z, y + 22)
			c.Sprite("Crown", x, z, 1.2, crownLegend, { Frame = at, Yaw = 0, Ghost = true, Parent = crown })
			Motion.Spin(crown, (at * c.CFrame.new(0, 3, 0)).Position, c.Vector3.new(0, 1, 0), 30)
		end,
		Life = function(c: any, life: any)
			for i = 1, 4 do
				local z = -c.Half + 30 + (i - 0.5) * (c.Half * 2 - 44) / 4
				Lane.Motes(c, life, 0, 7, z, c.Vector3.new(100, 8, 50), {
					Texture = SPARKLE,
					Color = { rgb(255, 230, 140), rgb(220, 180, 255) },
					LightEmission = 1,
					Size = { { 0, 0 }, { 0.3, 0.8 }, { 1, 0 } },
					Lifetime = { 3, 5 },
					Speed = { 0.3, 1 },
					Rate = 5,
				})
			end
		end,
		Floor = rgb(200, 186, 214),
		Cap = rgb(226, 190, 86),
		SideA = rgb(158, 128, 182),
		SideB = rgb(172, 142, 194),
		Leaves = rgb(80, 150, 110),
		Trunk = rgb(120, 92, 82),
		Stone = rgb(214, 204, 224),
		Plants = { { "RoundTree", 3 }, { "BlossomTree", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local gold, purple, marble = rgb(232, 192, 76), rgb(122, 72, 160), rgb(242, 238, 236)
			-- Golden urns of flowers along the courtyard.
			Props.Edges(c, 50, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 1, z, V.new(4, 2, 4), marble)
				c.Block(x, y + 3.4, z, V.new(4.4, 2.8, 4.4), gold)
				c.Block(x, y + 5.4, z, V.new(3.6, 1.4, 3.6), purple, { CanCollide = false })
			end)
			-- Peacocks, her birds, their tails fanned open.
			local tail = { rgb(52, 150, 132), rgb(62, 120, 190) }
			Props.Scatter(c, 3, function(x: number, z: number)
				local y = c.Ground(x, z)
				local out = if x > 0 then 1 else -1
				Props.Fan(c, x + out * 1.5, y + 2, z, 11, 11, tail, rgb(40, 60, 150))
				c.Block(x, y + 2.4, z, V.new(2.4, 3, 3), rgb(52, 92, 180))
				c.Block(x - out * 0.6, y + 5, z, V.new(1, 3, 1), rgb(52, 92, 180))
			end, c.Lane + 12, 90)
			-- Her crown, and the golden apples she was given at her wedding.
			for _, side in { -1, 1 } do
				local x, z = side * 86, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				c.Block(x, y + 2, z, V.new(6, 4, 10), marble)
				c.Sprite("Crown", x, z, 1.4, { G = gold, R = rgb(204, 52, 62), B = rgb(62, 92, 200) }, { Y = y + 4 })
			end
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Sprite("Apple", x, z, 1.8, { G = gold, L = rgb(98, 172, 72), W = rgb(255, 244, 200) })
			end, c.Lane + 10, 96)
		end,
	}

	-- Zeus's lane: broken and fallen marble columns, scorched rocks, bolts struck into the ground and golden braziers;
	-- his eagle on the knoll, a marble path, glowing cracks where lightning hit and sparks crackling.
	local marble, gold, bolt = rgb(236, 232, 224), rgb(224, 194, 94), rgb(255, 232, 92)
	local function sparks(c: any, parent: any, cf: any, size: any, rate: number)
		c.Emitter(parent, cf, size, {
			Name = "Sparks",
			Texture = SPARKLE,
			Color = { rgb(255, 250, 200), bolt },
			LightEmission = 1,
			Size = { { 0, 0.9 }, { 1, 0 } },
			Lifetime = { 0.3, 0.7 },
			Speed = { 2, 5 },
			Rate = rate,
			Shape = c.Enum.ParticleEmitterShape.Box,
			ShapeStyle = c.Enum.ParticleEmitterShapeStyle.Volume,
		})
	end
	themes.Zeus = {
		Floor = rgb(124, 134, 164),
		Cap = rgb(224, 194, 94),
		SideA = rgb(94, 104, 134),
		SideB = rgb(108, 118, 148),
		Leaves = rgb(112, 152, 112),
		Trunk = rgb(122, 112, 102),
		Stone = rgb(152, 162, 182),
		Cloud = rgb(94, 98, 114),
		Glow = rgb(255, 232, 92),
		Clouds = 4,
		Plants = {},
		Path = rgb(150, 158, 186),
		Birds = { rgb(150, 112, 70), rgb(120, 88, 56), rgb(255, 214, 90) },
		Obstacles = {
			{
				3,
				5,
				function(c: any, x: number, z: number, model: any)
					Lane.Column(c, x, z, model, marble, gold, c.LaneRandom.Number(12, 28))
				end,
				Name = "BrokenColumn",
			},
			{
				2,
				10,
				function(c: any, x: number, z: number, model: any)
					-- Fallen across the path in drums, low enough to jump.
					local random = c.LaneRandom
					local yaw = random.Number(40, 75) * random.Side()
					local a = math.rad(yaw)
					for i = -1, 1 do
						local d = i * 6.4 + random.Number(-0.4, 0.4)
						c.Tilted(x + math.sin(a) * d, 2.8, z + math.cos(a) * d, c.Vector3.new(5.6, 5.6, 6), marble, {
							Yaw = yaw + random.Number(-6, 6),
							Parent = model,
						})
					end
					c.Tilted(
						x + math.sin(a) * 10.2,
						3.2,
						z + math.cos(a) * 10.2,
						c.Vector3.new(7.6, 6.4, 1.8),
						marble,
						{
							Yaw = yaw,
							Parent = model,
						}
					)
				end,
				Name = "FallenColumn",
			},
			{
				2,
				7,
				function(c: any, x: number, z: number, model: any)
					Lane.Rock(c, x, z, model, rgb(70, 74, 92), c.LaneRandom.Number(5.5, 7.5), bolt)
				end,
				Name = "ScorchedRock",
			},
			{
				2,
				4,
				function(c: any, x: number, z: number, model: any)
					local holder = c.Sprite("Bolt", x, z, 2.6, { Y = bolt }, {
						Frame = c.Stand(x, z, -3),
						Yaw = c.LaneRandom.Number(-25, 25),
						Neon = true,
						Tip = c.LaneRandom.Number(-18, 18),
						Parent = model,
					})
					Lane.Crack(c, x, z, 3, bolt, model)
					sparks(c, model, c.CFrame.new(c.At(x, 4, z)), c.Vector3.new(4, 8, 4), 8)
					return holder
				end,
				Name = "StruckBolt",
			},
			{
				1,
				3,
				function(c: any, x: number, z: number, model: any)
					local V, CF = c.Vector3, c.CFrame
					local base = c.Stand(x, z)
					c.Tilted(x, 0.6, z, V.new(5, 1.2, 5), marble, { Parent = model })
					c.NewPart(model, base * CF.new(0, 3.5, 0), V.new(3, 7, 3), marble)
					c.NewPart(model, base * CF.new(0, 7.6, 0), V.new(5.6, 1.4, 5.6), gold)
					c.NewPart(model, base * CF.new(0, 9.4, 0), V.new(3.4, 2.6, 3.4), rgb(255, 160, 60), {
						Material = c.Enum.Material.Neon,
						CanCollide = false,
					})
					c.NewPart(model, base * CF.new(0, 10.4, 0), V.new(2, 2.6, 2), bolt, {
						Material = c.Enum.Material.Neon,
						CanCollide = false,
					})
				end,
				Name = "Brazier",
			},
		},
		Knoll = function(c: any, x: number, y: number, z: number, model: any)
			local V, CF = c.Vector3, c.CFrame
			-- His eagle on a marble pedestal, wings spread, two columns behind.
			local base = c.Stand(x, z, y)
			c.NewPart(model, base * CF.new(0, 4, 0), V.new(8, 8, 8), marble)
			c.NewPart(model, base * CF.new(0, 8.4, 0), V.new(9, 1, 9), gold)
			local legend = { B = rgb(150, 112, 70), W = rgb(250, 250, 250), K = rgb(30, 28, 30), Y = bolt, T = gold }
			c.Sprite("Eagle", x, z, 1.5, legend, { Frame = base * CF.new(0, 8.9, 0), Yaw = 0, Parent = model })
			for _, dx in { -6, 6 } do
				Lane.Column(c, x + dx, z + 7, model, marble, gold, 20, y)
			end
			sparks(c, model, base * CF.new(0, 16, 0), V.new(16, 8, 4), 10)
		end,
		Life = function(c: any, life: any)
			for _ = 1, 6 do
				local x, z = c.LaneRandom.Number(-50, 50), c.LaneRandom.Number(-c.Half + 12, c.Half - 12)
				Lane.Crack(c, x, z, c.LaneRandom.Int(3, 6), bolt, life)
			end
		end,
		Props = function(c: any)
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Sprite(
					"Bolt",
					x,
					z,
					2.2,
					{ Y = rgb(255, 232, 92) },
					{ Lift = c.Random.Pick({ 0, 10, 24 }), Neon = true, Tip = c.Random.Number(-15, 15) }
				)
			end, c.Lane + 10, 100)
			Props.Edges(c, 50, function(x: number, z: number)
				Props.Column(c, x, z, rgb(236, 232, 224), rgb(224, 194, 94), 30)
			end)
			for i = 1, 3 do
				local side = if i % 2 == 0 then 1 else -1
				local cloud = c.Place("Cloud", side * c.Random.Number(120, 170), c.Random.Number(-80, 80), {
					Y = c.Random.Number(40, 70),
					Upright = true,
					Solid = rgb(84, 88, 104),
					Ghost = true,
					Scale = 0.45,
				})
				Motion.Bob(cloud, 2, 10)
			end
		end,
	}

	return themes
end

return UpperMountain
