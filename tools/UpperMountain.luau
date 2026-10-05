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
-- Each stretch's length along its floor, in studs.
local SURFACE_LENGTH = 210
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
	{ 13, "Iris", "Rainbow Bridge", 32 },
	{ 14, "Pan", "Wild Grove", 33 },
	{ 15, "Hebe", "Ambrosia Orchard", 34 },
	{ 16, "Eros", "Heart Garden", 36 },
	{ 17, "Tyche", "Fortune Terraces", 37 },
	{ 18, "Asclepius", "Healing Springs", 38 },
	{ 19, "Eris", "Discord Rift", 39 },
	{ 20, "Hecate", "Torchlit Crossroads", 40 },
	{ 21, "Hypnos", "Poppy Fields", 41 },
	{ 22, "Morpheus", "Dream Steps", 43 },
	{ 23, "Phobos", "Fear Moon", 44 },
	{ 24, "Deimos", "Dread Moon", 45 },
	{ 25, "Thanatos", "Asphodel Meadow", 46 },
	{ 26, "Nemesis", "Reckoning Ridge", 47 },
	{ 27, "Themis", "Court of Justice", 48 },
	{ 28, "Nike", "Victory Stair", 49 },
	{ 29, "Hestia", "Eternal Hearth", 51 },
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
	Trophy = {
		"GGGGGGGGG",
		"G.GGGGG.G",
		"G.GGGGG.G",
		".GGGGGGG.",
		"..GGGGG..",
		"...GGG...",
		"....G....",
		"....G....",
		"..GGGGG..",
		".BBBBBBB.",
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
	Scales = {
		".....G.....",
		"GGGGGGGGGGG",
		"G....G....G",
		"G....G....G",
		"G....G....G",
		"GGG..G..GGG",
		".....G.....",
		".....G.....",
		"...GGGGG...",
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
	Clover = {
		".GG...GG.",
		"GGGG.GGGG",
		"GGGGGGGGG",
		".GGGGGGG.",
		"...GGG...",
		".GGGGGGG.",
		"GGGGGGGGG",
		"GGGG.GGGG",
		".GG.T.GG.",
	},
	Eye = {
		"...WWW...",
		".WWRRRWW.",
		"WWRRKRRWW",
		".WWRRRWW.",
		"...WWW...",
	},
	Wing = {
		"WWWWW...",
		".WWWWWW.",
		"..WWWWWW",
		"...WWWWW",
		"....WWWW",
		".....WWW",
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

		-- Floor.
		local floor = slab:Clone()
		floor.Name = "Floor"
		floor.Size = Vector3.new(SLAB_WIDTH, slab.Size.Y, SURFACE_LENGTH + 8)
		floor.CFrame = frame * CFrame.new(0, -slab.Size.Y / 2, 0)
		floor.Color = theme.Floor
		floor.Parent = model

		-- Terraces: stage 3's, trimmed to this stretch's length; their tops are the ground decor stands on.
		local terraces = Instance.new("Model")
		terraces.Name = "Terraces"
		terraces.Parent = model
		local tops: { { number } } = {}
		for _, piece in cliffPieces do
			local localCf = CFrame.new(0, -slab.Size.Y / 2, 0) * piece.Local
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
		}

		-- Plants on the terraces and the floor's edges.
		for _, entry in theme.Plants or {} do
			for _ = 1, entry[2] do
				local x, z = sideSpot(entry[3] or LANE_HALF + 9, entry[4])
				place(entry[1], x, z, { Scale = random.Number(0.85, 1.15), Leaves = entry.Leaves })
			end
		end
		-- Rocks.
		for _ = 1, theme.Stones or 6 do
			local x, z = sideSpot(LANE_HALF + 2, 100)
			place(
				random.Pick({ "Stone1", "Stone2", "Stone3" }),
				x,
				z,
				{ Solid = theme.Stone, Scale = random.Number(1.2, 2.2), Tilted = true }
			)
		end
		-- Floating islands and clouds off to the sides.
		for i = 1, theme.Islands or 3 do
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
		for i = 1, theme.Clouds or 2 do
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
	local plazaCenter = Vector3.new(last.XEnd + plazaLength / 2 - 4, last.YEnd, MIDDLE_Z)
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

-- Blocks round an arc standing across the path at (y, z): a rainbow's band.
function Props.Arc(c: any, y: number, z: number, radius: number, count: number, size: any, color: any)
	for i = 0, count - 1 do
		local a = math.pi * (i + 0.5) / count
		c.Block(math.cos(a) * radius, y + math.sin(a) * radius, z, size, color, {
			Turn = c.CFrame.Angles(0, 0, a),
			CanCollide = false,
		})
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

-- `count` things on the terraces or the floor's edges, made by `make(x, z)`.
function Props.Scatter(c: any, count: number, make: (number, number) -> (), minX: number?, maxX: number?)
	for _ = 1, count do
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
	local rainbow = {
		rgb(206, 104, 104),
		rgb(214, 152, 96),
		rgb(214, 202, 104),
		rgb(116, 192, 116),
		rgb(104, 160, 214),
		rgb(128, 116, 204),
		rgb(184, 116, 204),
	}
	local themes: { [string]: any } = {}

	themes.Iris = {
		Floor = rgb(226, 226, 234),
		CapAt = function(p: any): any
			return rainbow[math.floor((p.Z + 120) / 34) % 7 + 1]
		end,
		Cap = rainbow[1],
		SideA = rgb(204, 204, 220),
		SideB = rgb(218, 218, 232),
		Leaves = rgb(200, 200, 230),
		Trunk = rgb(200, 190, 214),
		Stone = rgb(214, 214, 228),
		Cloud = rgb(226, 226, 236),
		Islands = 4,
		Clouds = 3,
		Plants = { { "BlossomTree", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			-- A rainbow over the path, and rainbow-leaved trees.
			for band = 1, 7 do
				local radius = 92 - (band - 1) * 5.4
				Props.Arc(c, -14, 0, radius, 26, V.new(5.6, math.pi * radius / 26 + 1.2, 5), rainbow[band])
			end
			for _ = 1, 7 do
				local x, z = c.SideSpot(c.Lane + 6, 98)
				c.Place("RoundTree", x, z, { Leaves = c.Random.Pick(rainbow), Scale = c.Random.Number(0.9, 1.2) })
			end
		end,
	}

	themes.Pan = {
		Floor = rgb(72, 142, 72),
		Cap = rgb(86, 156, 76),
		SideA = rgb(122, 92, 62),
		SideB = rgb(142, 106, 72),
		Leaves = rgb(62, 142, 70),
		Trunk = rgb(122, 86, 62),
		Stone = rgb(126, 126, 116),
		Stones = 8,
		Plants = { { "Pine", 5 }, { "Pine2", 4 }, { "Pine3", 3 }, { "RoundTree", 4 }, { "Bamboo", 8 } },
		Props = function(c: any)
			local V = c.Vector3
			-- Pan's pipes: seven reeds, tallest first, tied with a band.
			for _, side in { -1, 1 } do
				local x, z = side * 84, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				for i = 0, 6 do
					local h = 16 - i * 1.6
					c.Block(x, y + h / 2, z - 8 + i * 2.6, V.new(2.4, h, 2.4), rgb(206, 176, 112))
				end
				c.Block(x, y + 9, z, V.new(2.8, 2, 19), rgb(142, 92, 62))
			end
			-- Toadstools.
			Props.Scatter(c, 10, function(x: number, z: number)
				local y = c.Ground(x, z)
				local k = c.Random.Number(0.8, 1.6)
				c.Block(x, y + 1.5 * k, z, V.new(1.6 * k, 3 * k, 1.6 * k), rgb(236, 226, 206))
				c.Block(x, y + 3.5 * k, z, V.new(5 * k, 1.6 * k, 5 * k), rgb(204, 62, 52))
				c.Block(x + 1.2 * k, y + 4.4 * k, z, V.new(1 * k, 0.4 * k, 1 * k), rgb(246, 240, 230))
			end)
		end,
	}

	themes.Hebe = {
		Floor = rgb(238, 226, 186),
		Cap = rgb(236, 196, 110),
		SideA = rgb(222, 200, 150),
		SideB = rgb(234, 214, 170),
		Leaves = rgb(140, 196, 110),
		Trunk = rgb(150, 112, 80),
		Stone = rgb(230, 220, 196),
		Plants = { { "RoundTree", 5 }, { "BlossomTree", 3, Leaves = rgb(250, 240, 236) }, { "Bush", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local gold = rgb(226, 186, 82)
			-- Golden goblets of ambrosia.
			Props.Scatter(c, 5, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 0.5, z, V.new(5, 1, 5), gold)
				c.Block(x, y + 3, z, V.new(1.6, 4, 1.6), gold)
				c.Block(x, y + 7, z, V.new(6, 4.4, 6), gold)
				c.Block(x, y + 9.3, z, V.new(4.6, 0.3, 4.6), rgb(244, 168, 196), { Material = c.Enum.Material.Neon })
			end, c.Lane + 8, 96)
			-- A fountain on one terrace.
			local x, z = 86 * c.Random.Side(), c.Random.Number(-50, 50)
			local y = c.Ground(x, z)
			local white = rgb(244, 240, 236)
			for i = 0, 3 do
				local a = math.rad(i * 90)
				c.Block(x + math.cos(a) * 7, y + 1.5, z + math.sin(a) * 7, V.new(2, 3, 16), white, { Yaw = -i * 90 })
			end
			c.Block(x, y + 2.2, z, V.new(13, 0.4, 13), rgb(120, 200, 236), { Material = c.Enum.Material.Neon })
			c.Block(x, y + 5, z, V.new(2.4, 8, 2.4), white)
			c.Block(x, y + 9.4, z, V.new(7, 1.2, 7), gold)
		end,
	}

	themes.Eros = {
		Floor = rgb(232, 174, 190),
		Cap = rgb(216, 112, 138),
		SideA = rgb(236, 198, 208),
		SideB = rgb(246, 216, 224),
		Leaves = rgb(226, 96, 126),
		Trunk = rgb(202, 142, 152),
		Stone = rgb(240, 202, 212),
		Plants = { { "BlossomTree", 4 }, { "RoundTree", 3 } },
		Props = function(c: any)
			local legend = { R = rgb(222, 62, 92), W = rgb(255, 224, 232) }
			Props.Scatter(c, 6, function(x: number, z: number)
				c.Sprite("Heart", x, z, c.Random.Number(1.8, 2.8), legend, { Lift = c.Random.Pick({ 0, 0, 8, 16 }) })
			end, c.Lane + 10, 96)
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Place("SmallArch", x, z, { Solid = rgb(232, 120, 150), Yaw = 0 })
			end, c.Lane + 14, 90)
		end,
	}

	themes.Tyche = {
		Floor = rgb(72, 152, 102),
		Cap = rgb(214, 184, 84),
		SideA = rgb(62, 120, 82),
		SideB = rgb(80, 138, 96),
		Leaves = rgb(92, 172, 92),
		Trunk = rgb(152, 122, 72),
		Stone = rgb(202, 182, 102),
		Plants = { { "Bush", 4 }, { "RoundTree", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local gold = rgb(232, 192, 72)
			-- Stacks of coins.
			Props.Scatter(c, 7, function(x: number, z: number)
				local y = c.Ground(x, z)
				for i = 1, c.Random.Int(3, 8) do
					c.Block(
						x + c.Random.Number(-0.4, 0.4),
						y + (i - 0.5) * 1.1,
						z + c.Random.Number(-0.4, 0.4),
						V.new(1, 6, 6),
						gold,
						{
							Shape = c.Enum.PartType.Cylinder,
							Turn = c.CFrame.Angles(0, 0, math.pi / 2),
						}
					)
				end
			end, c.Lane + 6, 98)
			-- The wheel of fortune.
			Props.Wheel(
				c,
				78 * c.Random.Side(),
				c.Random.Number(-40, 40),
				{ gold, rgb(204, 72, 62), rgb(82, 162, 92) },
				rgb(150, 112, 62)
			)
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Sprite("Clover", x, z, 1.6, { G = rgb(84, 172, 84), T = rgb(62, 122, 62) })
			end, c.Lane + 10, 96)
		end,
	}

	themes.Asclepius = {
		Floor = rgb(206, 236, 222),
		Cap = rgb(152, 212, 184),
		SideA = rgb(226, 236, 230),
		SideB = rgb(208, 222, 216),
		Leaves = rgb(112, 190, 142),
		Trunk = rgb(170, 150, 122),
		Stone = rgb(230, 236, 232),
		Plants = { { "Bush", 6 }, { "SmallPine", 3 }, { "Pine", 2 } },
		Props = function(c: any)
			local V = c.Vector3
			local white = rgb(246, 248, 246)
			Props.Edges(c, 70, function(x: number, z: number)
				Props.Column(c, x, z, white, rgb(150, 210, 182))
			end)
			-- The rod of Asclepius: a staff with a serpent round it.
			for _, side in { -1, 1 } do
				local x, z = side * 88, c.Random.Number(-70, 70)
				local y = c.Ground(x, z)
				c.Block(x, y + 14, z, V.new(2, 28, 2), rgb(150, 110, 72))
				for i = 0, 15 do
					local a = i * 0.9
					c.Block(
						x + math.cos(a) * 1.8,
						y + 4 + i * 1.4,
						z + math.sin(a) * 1.8,
						V.new(1.4, 1.4, 1.4),
						rgb(84, 172, 92)
					)
				end
				c.Block(x + math.cos(14) * 2.2, y + 26, z + math.sin(14) * 2.2, V.new(2.2, 1.8, 2.6), rgb(84, 172, 92))
			end
			-- Healing pools.
			Props.Scatter(c, 3, function(x: number, z: number)
				local y = c.Ground(x, z)
				for i = 0, 3 do
					local a = math.rad(i * 90)
					c.Block(x + math.cos(a) * 6, y + 1, z + math.sin(a) * 6, V.new(2, 2, 14), white, { Yaw = -i * 90 })
				end
				c.Block(x, y + 1.4, z, V.new(11, 0.4, 11), rgb(110, 212, 222), { Material = c.Enum.Material.Neon })
			end, 72, 96)
		end,
	}

	local clash = { rgb(212, 82, 172), rgb(162, 212, 72), rgb(232, 142, 62), rgb(92, 192, 212) }
	themes.Eris = {
		Floor = rgb(70, 64, 80),
		CapAt = function(_p: any, random: any): any
			return random.Pick(clash)
		end,
		Cap = clash[1],
		SideA = rgb(52, 48, 60),
		SideB = rgb(62, 56, 72),
		Leaves = rgb(162, 212, 72),
		Trunk = rgb(60, 52, 70),
		Stone = rgb(110, 100, 120),
		Islands = 5,
		Plants = { { "TwinTree", 3 } },
		Props = function(c: any)
			local legend = { G = rgb(238, 198, 72), L = rgb(98, 172, 72), W = rgb(255, 244, 200) }
			-- The golden apple of discord, hanging over the path, and more on the terraces.
			c.Sprite("Apple", 0, 0, 3.2, legend, { Y = 46, Yaw = 0, Ghost = true })
			Props.Scatter(c, 3, function(x: number, z: number)
				c.Sprite("Apple", x, z, 1.8, legend)
			end, c.Lane + 10, 96)
			-- Crystals at odd angles.
			Props.Scatter(c, 10, function(x: number, z: number)
				c.Place(c.Random.Pick({ "Spire", "SmallSpire" }), x, z, {
					Solid = c.Random.Pick(clash),
					Roll = { c.Random.Number(-28, 28), c.Random.Number(-28, 28) },
					Sink = 2,
				})
			end, c.Lane + 6, 100)
		end,
	}

	themes.Hecate = {
		Floor = rgb(60, 66, 112),
		Cap = rgb(100, 92, 160),
		SideA = rgb(46, 50, 82),
		SideB = rgb(54, 58, 94),
		Leaves = rgb(70, 70, 120),
		Trunk = rgb(50, 48, 64),
		Stone = rgb(90, 90, 124),
		Plants = { { "Pine", 4 }, { "SnowPine", 3 }, { "SmallPine", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local wood = rgb(92, 70, 60)
			Props.Edges(c, 52, function(x: number, z: number)
				Props.Fire(c, x, z, rgb(72, 66, 86), rgb(70, 60, 74))
			end)
			-- Crossroads signposts.
			for _, side in { -1, 1 } do
				local x, z = side * 80, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				c.Block(x, y + 8, z, V.new(2, 16, 2), wood)
				for i = 0, 2 do
					c.Block(x, y + 10 + i * 2.6, z, V.new(10, 2, 0.8), rgb(150, 120, 92), { Yaw = i * 60 + 20 })
				end
			end
			c.Sprite("Moon", -150, 30, 7, { M = rgb(232, 232, 255) }, { Y = 70, Yaw = -90, Neon = true, Ghost = true })
		end,
	}

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
			for _ = 1, 18 do
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
			for _ = 1, 3 do
				local x = c.Random.Number(130, 190) * c.Random.Side()
				c.Place("Island", x, c.Random.Number(-c.Half, c.Half), {
					Y = c.Random.Number(30, 70),
					Roll = { 180, 0 },
					Solid = rgb(240, 172, 212),
				})
			end
		end,
	}

	local function moon(name: string, colors: { any }, planetX: number, planetSize: number): any
		local floor, cap, sideA, sideB, stone, planet, spire = table.unpack(colors)
		return {
			Floor = floor,
			Cap = cap,
			SideA = sideA,
			SideB = sideB,
			Leaves = cap,
			Trunk = sideA,
			Stone = stone,
			Stones = 14,
			Islands = 2,
			Plants = {},
			Props = function(c: any)
				Props.Scatter(c, 7, function(x: number, z: number)
					Props.Crater(c, x, z, cap, sideA, c.Random.Number(4, 7))
				end, c.Lane + 8, 96)
				Props.Scatter(c, 6, function(x: number, z: number)
					c.Place(c.Random.Pick({ "Spire", "SmallSpire" }), x, z, { Solid = spire, Sink = 1 })
				end, c.Lane + 8, 100)
				-- Mars, which both moons go round.
				if planetSize > 0 then
					c.Block(planetX, 150, 0, c.Vector3.new(planetSize, planetSize, planetSize), planet, {
						Shape = c.Enum.PartType.Ball,
						CanCollide = false,
						CastShadow = false,
					})
				end
				if name == "Phobos" then
					Props.Scatter(c, 3, function(x: number, z: number)
						c.Sprite(
							"Eye",
							x,
							z,
							1.4,
							{ W = rgb(240, 240, 240), R = rgb(204, 42, 42), K = rgb(20, 20, 24) },
							{ Lift = 8 }
						)
					end, 72, 100)
				else
					for _, side in { -1, 1 } do
						c.Place(
							"Pyramid",
							side * 160,
							c.Random.Number(-40, 40),
							{ Solid = sideB, Y = -30, Scale = 0.6 }
						)
					end
				end
			end,
		}
	end
	themes.Phobos = moon("Phobos", {
		rgb(140, 140, 140),
		rgb(166, 166, 166),
		rgb(104, 104, 106),
		rgb(120, 120, 122),
		rgb(118, 118, 120),
		rgb(0, 0, 0),
		rgb(66, 66, 70),
	}, 0, 0)
	themes.Deimos = moon("Deimos", {
		rgb(154, 104, 88),
		rgb(174, 118, 98),
		rgb(114, 78, 68),
		rgb(128, 88, 76),
		rgb(142, 96, 82),
		rgb(170, 100, 82),
		rgb(122, 62, 52),
	}, 520, 200)

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
			for _ = 1, 10 do
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

	themes.Themis = {
		Floor = rgb(238, 235, 228),
		Cap = rgb(224, 194, 104),
		SideA = rgb(218, 213, 203),
		SideB = rgb(231, 227, 218),
		Leaves = rgb(112, 162, 92),
		Trunk = rgb(152, 122, 92),
		Stone = rgb(232, 228, 220),
		Plants = { { "Bush", 4 } },
		Props = function(c: any)
			local marble, gold = rgb(240, 238, 232), rgb(224, 190, 92)
			Props.Edges(c, 46, function(x: number, z: number)
				Props.Column(c, x, z, marble, gold, 30)
			end)
			for _, side in { -1, 1 } do
				c.Sprite("Scales", side * 86, c.Random.Number(-50, 50), 2.4, { G = gold })
			end
			c.Place("Pavilion", 84 * c.Random.Side(), c.Random.Number(-80, 80), { Solid = marble, Yaw = 0 })
		end,
	}

	themes.Nike = {
		Floor = rgb(234, 216, 158),
		Cap = rgb(218, 178, 74),
		SideA = rgb(242, 237, 223),
		SideB = rgb(228, 218, 194),
		Leaves = rgb(92, 152, 82),
		Trunk = rgb(152, 122, 82),
		Stone = rgb(236, 226, 202),
		Plants = { { "Bush", 3 } },
		Props = function(c: any)
			local V = c.Vector3
			local gold = rgb(228, 186, 70)
			-- A laurel arch over the path.
			c.Place("BigArch", 0, 0, { Y = -6, Yaw = 0, Scale = 1.25, Solid = rgb(96, 158, 84), Ghost = true })
			Props.Scatter(c, 4, function(x: number, z: number)
				c.Sprite("Trophy", x, z, 1.5, { G = gold, B = rgb(110, 80, 60) })
			end, c.Lane + 10, 96)
			-- Winged victory: a pair of wings on a plinth, each side.
			for _, side in { -1, 1 } do
				local x, z = side * 88, c.Random.Number(-60, 60)
				local y = c.Ground(x, z)
				local face = if side > 0 then 90 else -90
				c.Block(x, y + 3, z, V.new(8, 6, 8), rgb(242, 237, 223))
				c.Sprite("Wing", x, z - 4.5, 1.4, { W = rgb(250, 250, 255) }, { Y = y + 6, Yaw = face })
				c.Sprite("Wing", x, z + 4.5, 1.4, { W = rgb(250, 250, 255) }, { Y = y + 6, Yaw = face + 180 })
			end
			Props.Edges(c, 60, function(x: number, z: number)
				local y = c.Ground(x, z)
				c.Block(x, y + 9, z, V.new(1, 18, 1), gold)
				c.Block(x, y + 14, z + 3.4, V.new(0.4, 8, 6), rgb(206, 62, 62))
			end)
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
