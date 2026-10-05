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
-- The walkable lane in a stretch's own frame (x across: +x is world -z). Decor stays out of it so slides run clear.
local LANE_HALF = 56
local FOLDER_NAME = "HighOlympus"

type Env = { Instance: any, CFrame: any, Vector3: any, Color3: any, Enum: any }

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

		-- Places a template upright (or tilted with the slope), turned `yaw` degrees, recoloured part by part.
		local function place(name: string, x: number, z: number, options: { [string]: any }?): any
			local template = templates[name]
			if not template then
				return nil
			end
			local opts = options or {}
			local scale = opts.Scale or 1
			local y = if opts.Y then opts.Y else ground(x, z) - (opts.Sink or 0.3)
			local base
			if opts.Tilted then
				base = frame * CFrame.new(x, y, z) * CFrame.fromEulerAnglesYXZ(0, -math.pi / 2, 0)
			else
				base = CFrame.new(at(x, y, z))
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

		-- A block in the stretch's upright frame at (x, y, z), turned `yaw` degrees.
		local function block(x: number, y: number, z: number, size: any, color: any, props: { [string]: any }?): any
			local yaw = props and props.Yaw or 0
			local cf = CFrame.new(at(x, y, z)) * upright * CFrame.Angles(0, math.rad(yaw), 0)
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

		-- A pixel sprite standing upright at (x, z) on the ground, facing the lane, `cell` studs a pixel.
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
			local base = CFrame.new(at(x, y0, z)) * upright * CFrame.Angles(0, math.rad(yaw), 0)
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
				{ Solid = theme.Stone, Scale = random.Number(1.2, 2.2), Tilted = true }
			)
		end
		-- Floating islands and clouds off to the sides.
		for i = 1, count(theme.Islands or 3) do
			local side = if i % 2 == 0 then 1 else -1
			local x = side * random.Number(135, 210)
			local z = random.Number(-half, half)
			place("Island", x, z, {
				Y = random.Number(-10, 45),
				Scale = random.Number(0.8, 1.4),
				Color = function(_part: any, source: any, _i: number, value: number): any
					local h = select(1, source:ToHSV())
					if h > 0.1 and h < 0.2 then
						return theme.CapAt and theme.CapAt(Vector3.new(x, 0, z), random) or theme.Cap
					end
					return shade(theme.SideB, value, 1)
				end,
			})
		end
		for i = 1, count(theme.Clouds or 2) do
			local side = if i % 2 == 0 then -1 else 1
			place("Cloud", side * random.Number(170, 320), random.Number(-half, half), {
				Y = random.Number(40, 120),
				Solid = theme.Cloud or rgb(214, 214, 214),
				Ghost = true,
				Scale = random.Number(0.5, 0.8),
			})
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

-- A wheel on a post at a terrace's edge, its face towards the lane.
function Props.Wheel(c: any, x: number, z: number, colors: { any }, hub: any)
	local y = c.Ground(x, z)
	local V = c.Vector3
	local center = y + 20
	c.Block(x, y + 9, z, V.new(3, 18, 3), hub)
	for i = 0, 15 do
		local a = (i + 0.5) * math.pi * 2 / 16
		c.Block(x, center + math.sin(a) * 13, z + math.cos(a) * 13, V.new(2, 4, 5.4), colors[i % #colors + 1], {
			Turn = c.CFrame.Angles(-a, 0, 0),
		})
	end
	for i = 0, 3 do
		c.Block(x, center, z, V.new(1.4, 24, 1.4), hub, { Turn = c.CFrame.Angles(math.rad(i * 45), 0, 0) })
	end
	c.Block(x, center, z, V.new(2.6, 4, 4), hub)
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

-- Along both lane edges, alternating sides every `step / 2` studs: torches, columns, banners.
function Props.Edges(c: any, step: number, make: (number, number) -> ())
	local z = -c.Half + step / 2
	local side = 1
	while z < c.Half - 6 do
		make(side * (c.Lane + 5), z)
		side = -side
		z += step / 2
	end
end

-- Each god's stretch: colours before the map's colour grading (Lighting.ColorCorrection, saturation +0.7, which
-- brightens them a lot), plants as { template, count, nearest x, farthest x }, and props.
function UpperMountain.Themes(rgb: (number, number, number) -> any): { [string]: any }
	local themes: { [string]: any } = {}

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
		Props = function(c: any)
			local poppy, middle = rgb(232, 92, 62), rgb(52, 42, 62)
			Props.Scatter(c, 50, function(x: number, z: number)
				Props.Flower(c, x, z, poppy, middle)
			end, c.Lane + 1, 102)
			-- Sleepy clouds low over the terraces.
			for i = 1, 3 do
				local side = if i % 2 == 0 then 1 else -1
				c.Place("Cloud", side * c.Random.Number(110, 150), c.Random.Number(-80, 80), {
					Y = c.Random.Number(18, 34),
					Solid = rgb(214, 204, 240),
					Ghost = true,
					Scale = 0.35,
				})
			end
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Sprite("Zzz", x, z, 2.2, { Z = rgb(246, 244, 255) }, { Lift = 16, Neon = true, Ghost = true })
			end, 70, 100)
		end,
	}

	themes.Morpheus = {
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
				c.Block(x, c.Ground(x, z) + c.Random.Number(14, 55), z, V.new(s, s, s), c.Random.Pick(dream), {
					Material = c.Enum.Material.Neon,
					CanCollide = false,
					Shape = if ball then c.Enum.PartType.Ball else c.Enum.PartType.Block,
					Turn = c.CFrame.Angles(c.Random.Number(0, 6), c.Random.Number(0, 6), c.Random.Number(0, 6)),
				})
			end
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Sprite(
					"Star",
					x,
					z,
					1.6,
					{ S = rgb(255, 236, 130) },
					{ Lift = c.Random.Number(10, 30), Neon = true, Ghost = true }
				)
			end, c.Lane + 10, 110)
			for _ = 1, c.Count(3) do
				local x = c.Random.Number(130, 190) * c.Random.Side()
				c.Place("Island", x, c.Random.Number(-c.Half, c.Half), {
					Y = c.Random.Number(30, 70),
					Roll = { 180, 0 },
					Solid = rgb(240, 172, 212),
				})
			end
		end,
	}

	themes.Deimos = {
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
				Shape = c.Enum.PartType.Ball,
				CanCollide = false,
				CastShadow = false,
			})
			for _, side in { -1, 1 } do
				c.Place(
					"Pyramid",
					side * 160,
					c.Random.Number(-40, 40),
					{ Solid = rgb(128, 88, 76), Y = -30, Scale = 0.6 }
				)
			end
		end,
	}

	themes.Thanatos = {
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
					{ Lift = c.Random.Number(8, 20), Ghost = true }
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

	themes.Nemesis = {
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

	themes.Dionysus = {
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

	themes.Hermes = {
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

	themes.Hephaestus = {
		Floor = rgb(78, 70, 70),
		Cap = rgb(122, 74, 56),
		SideA = rgb(58, 52, 54),
		SideB = rgb(68, 60, 62),
		Leaves = rgb(96, 82, 76),
		Trunk = rgb(52, 44, 44),
		Stone = rgb(92, 84, 84),
		Cloud = rgb(80, 76, 80),
		Stones = 10,
		Islands = 2,
		Plants = {},
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
		end,
	}

	themes.Ares = {
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

	themes.Aphrodite = {
		Floor = rgb(236, 196, 204),
		Cap = rgb(222, 118, 142),
		SideA = rgb(240, 214, 220),
		SideB = rgb(248, 226, 230),
		Leaves = rgb(96, 158, 92),
		Trunk = rgb(190, 140, 140),
		Stone = rgb(242, 220, 224),
		Plants = { { "BlossomTree", 3 }, { "Bush", 4 } },
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

	themes.Artemis = {
		Floor = rgb(70, 92, 96),
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
			c.Sprite("Moon", -150, 30, 7, { M = rgb(236, 240, 255) }, { Y = 70, Yaw = -90, Neon = true, Ghost = true })
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

	themes.Apollo = {
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
				Shape = c.Enum.PartType.Ball,
				Material = light.Material,
				CanCollide = false,
				CastShadow = false,
			})
			for i = 0, 11 do
				local a = i * math.pi / 6
				c.Block(sx, sy + math.cos(a) * 27, sz + math.sin(a) * 27, V.new(2, 12, 4), rgb(255, 170, 60), {
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

	themes.Athena = {
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

	themes.Demeter = {
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

	themes.Hestia = {
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

	themes.Poseidon = {
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
				c.Place("Island", x, z, { Y = top - 10, Scale = 1.2, Solid = rgb(150, 170, 172) })
				c.Block(x, top - 70, z, V.new(6, 120, 14), water, {
					Material = neon,
					Transparency = 0.3,
					CanCollide = false,
					CastShadow = false,
				})
				c.Block(x, top - 3, z, V.new(10, 2, 18), foam, { Material = neon, CanCollide = false })
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

	themes.Hera = {
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
				c.Place("Cloud", side * c.Random.Number(120, 170), c.Random.Number(-80, 80), {
					Y = c.Random.Number(40, 70),
					Solid = rgb(84, 88, 104),
					Ghost = true,
					Scale = 0.45,
				})
			end
		end,
	}

	return themes
end

return UpperMountain
