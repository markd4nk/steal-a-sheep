--!strict

-- The primitive accessories families wear on top of a Shear a Sheep breed (the Grape Sheep's leaf, the War Sheep's
-- helmet, halos, crowns, antlers, a witch's hat, the Pegasus Sheep's feathered wings...), some in a colour of the
-- family's choosing. Built on a sheep dressed at its rig's own size (Looks.Dress at scale 1), welded to the piece they
-- sit on, and scaled with the sheep afterwards.
local Extras = {}

local function part(
	model: Model,
	host: BasePart,
	name: string,
	shape: Enum.PartType,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
): BasePart
	local block = Instance.new("Part")
	block.Name = name
	block.Shape = shape
	block.Size = size
	block.Color = color
	block.Material = material or Enum.Material.SmoothPlastic
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.CanCollide = false
	block.CanTouch = false
	block.CanQuery = false
	block.Massless = true
	block.Anchored = false
	block.CFrame = host.CFrame * offset
	local weld = Instance.new("Weld")
	weld.Part0 = host
	weld.Part1 = block
	weld.C0 = offset
	weld.Parent = block
	local folder = model:FindFirstChild("Extras")
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "Extras"
		created.Parent = model
		folder = created
	end
	block.Parent = folder
	return block
end

-- A smooth stretched sphere (a feather, a puff): a block shown as an ellipsoid its size, placed at `at` in the host's
-- space, its long side along at's X.
local function puff(model: Model, host: BasePart, name: string, size: Vector3, at: CFrame, color: Color3): BasePart
	local block = part(model, host, name, Enum.PartType.Block, size, at, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = block
	return block
end

local function piece(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name)
	return if found and found:IsA("BasePart") then found else nil
end

local LEAF = Color3.fromRGB(96, 170, 70)
local WING_LEGS: { { Name: string, Side: number } } = {
	{ Name = "LegFL", Side = -1 },
	{ Name = "LegFR", Side = 1 },
	{ Name = "LegBL", Side = -1 },
	{ Name = "LegBR", Side = 1 },
}
local rad = math.rad

local rgb = Color3.fromRGB
local BALL = Enum.PartType.Ball
local BLOCK = Enum.PartType.Block
local CYLINDER = Enum.PartType.Cylinder
local WEDGE = Enum.PartType.Wedge
local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal
local GLASS = Enum.Material.Glass
local FABRIC = Enum.Material.Fabric
local GOLD = rgb(255, 196, 60)
local WOOD = rgb(120, 84, 52)
-- A cylinder's length runs along its X axis: these stand it up, or turn it to face the camera (a disc).
local UPRIGHT = CFrame.Angles(0, 0, rad(90))
local FACING = CFrame.Angles(0, rad(90), 0)

type Builder = (model: Model, head: BasePart, body: BasePart?, color: Color3?) -> ()

-- `count` balls round a circle of `radius` in the XZ plane of `center` (its XY plane when `upright`).
local function ring(
	model: Model,
	host: BasePart,
	name: string,
	center: CFrame,
	radius: number,
	count: number,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	upright: boolean?
)
	for index = 1, count do
		local angle = index / count * 2 * math.pi
		local offset = if upright
			then Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0)
			else Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		part(model, host, `{name}{index}`, BALL, size, center * CFrame.new(offset), color, material)
	end
end

-- Stacked cylinders narrowing upwards from `base` (a pointed hat), each `step` along and leaning `lean` per tier.
local function cone(
	model: Model,
	host: BasePart,
	name: string,
	base: CFrame,
	widths: { number },
	step: number,
	lean: number,
	color: Color3,
	material: Enum.Material?
): CFrame
	local at = base
	for index, width in widths do
		part(model, host, `{name}{index}`, CYLINDER, Vector3.new(step, width, width), at * UPRIGHT, color, material)
		at = at * CFrame.Angles(0, 0, rad(-lean)) * CFrame.new(0, step * 0.9, 0)
	end
	return at
end

-- Drawn small, these read better bigger: scaled about the bottom middle of what was just added, so they still sit
-- where they were put.
local GROW: { [string]: number } = {
	Apple = 1.4,
	Bolt = 1.7,
	Bow = 1.4,
	Candle = 1.2,
	Clover = 1.5,
	Coin = 1.4,
	Crystal = 1.4,
	Dice = 1.3,
	Eyeball = 1.3,
	Flower = 1.5,
	Hammer = 1.7,
	Heart = 1.5,
	Potion = 1.3,
	Star = 1.6,
	Trident = 1.4,
	UnicornHorn = 1.4,
}

local function grow(blocks: { Instance }, factor: number)
	local low, sum, count = math.huge, Vector3.zero, 0
	for _, block in blocks do
		local weld = block:FindFirstChildOfClass("Weld")
		if weld then
			low = math.min(low, weld.C0.Position.Y)
			sum += weld.C0.Position
			count += 1
		end
	end
	if count == 0 then
		return
	end
	local anchor = Vector3.new(sum.X / count, low, sum.Z / count)
	for _, block in blocks do
		local weld = block:FindFirstChildOfClass("Weld")
		local host = weld and weld.Part0
		if weld and host and block:IsA("BasePart") then
			weld.C0 = CFrame.new(anchor + (weld.C0.Position - anchor) * factor) * weld.C0.Rotation
			block.Size *= factor
			block.CFrame = host.CFrame * weld.C0
		end
	end
end

-- The Pegasus Sheep's wings, in studs on the rig at scale 1, from the body's centre (+X its right, +Y up, +Z back), as
-- in the mock-up's render (DESIGN/ui/art/pegasus.py): each rises from the top of its back in an arch, out to the side
-- and swept back; three rows of feathers hang from the arch, longest at the tip, the long ones tipped in gold.
local PEGASUS_WHITE = Color3.fromRGB(250, 250, 246)
local PEGASUS_GOLD = Color3.fromRGB(255, 206, 72)
local WING = {
	Root = Vector3.new(0.3, 0.68, 0.13), -- the shoulder (X mirrored for the left wing)
	Span = 1.55, -- how far out the arch reaches
	Height = 1.45, -- how high it rises
	Sweep = 0.5, -- how far back it leans (0 straight out to the side)
	Puffs = 7,
	-- name, count, shortest and longest, half-width, how far in front of the wing's middle, first and last angle
	-- (degrees from straight out; -90 hangs straight down), gold or not.
	Rows = {
		{
			Name = "Primary",
			Count = 7,
			Short = 0.75,
			Long = 1.55,
			Width = 0.16,
			Lift = -0.07,
			First = -100,
			Last = -38,
			Gold = true,
		},
		{
			Name = "Secondary",
			Count = 6,
			Short = 0.55,
			Long = 1,
			Width = 0.17,
			Lift = 0,
			First = -98,
			Last = -42,
			Gold = false,
		},
		{
			Name = "Covert",
			Count = 5,
			Short = 0.36,
			Long = 0.55,
			Width = 0.18,
			Lift = 0.07,
			First = -95,
			Last = -50,
			Gold = false,
		},
	},
}

local function pegasusWing(model: Model, body: BasePart, side: number)
	local u = Vector3.new(side, 0, WING.Sweep).Unit -- out, and back
	local v = Vector3.new(0, 1, 0.22).Unit -- up, a little back
	local w = u:Cross(v).Unit -- the wing's face, turned to the front
	if w.Z > 0 then
		w = -w
	end
	local root = Vector3.new(side * WING.Root.X, WING.Root.Y, WING.Root.Z)
	local function edge(t: number): Vector3
		local x = WING.Span * t
		local y = WING.Height * math.sin(math.pi * (0.18 + 0.62 * t)) - 0.1 * t
		return root + u * x + v * y
	end
	for index = 0, WING.Puffs - 1 do
		local t = index / (WING.Puffs - 1)
		local radius = 0.19 - 0.06 * t
		local at = CFrame.fromMatrix(edge(t) + w * 0.03, u, w:Cross(u).Unit)
		puff(model, body, `Arm{side}{index}`, Vector3.new(radius * 2.5, radius * 2, radius * 1.5), at, PEGASUS_WHITE)
	end
	for _, row in WING.Rows do
		for index = 0, row.Count - 1 do
			local t = 0.04 + 0.92 * index / (row.Count - 1)
			local length = row.Short + (row.Long - row.Short) * t
			local angle = rad(row.First + (row.Last - row.First) * t)
			local along = (u * math.cos(angle) + v * math.sin(angle)).Unit
			local centre = edge(t) + w * (row.Lift - 0.004 * index) + along * (length / 2)
			puff(
				model,
				body,
				`{row.Name}{side}{index}`,
				Vector3.new(length, row.Width * 2, 0.14),
				CFrame.fromMatrix(centre, along, w:Cross(along).Unit),
				if row.Gold then PEGASUS_GOLD else PEGASUS_WHITE
			)
		end
	end
end

local builders: { [string]: Builder } = {
	Halo = function(model, head, _body, color)
		local tilt = CFrame.new(0, 1.55, 0.05) * CFrame.Angles(rad(-30), 0, 0)
		ring(model, head, "Halo", tilt, 0.42, 16, Vector3.one * 0.17, color or GOLD, NEON)
	end,
	Crown = function(model, head, _body, color)
		local metal = color or GOLD
		part(
			model,
			head,
			"Band",
			CYLINDER,
			Vector3.new(0.24, 0.95, 0.95),
			CFrame.new(0, 1.0, 0.05) * UPRIGHT,
			metal,
			METAL
		)
		for index = 1, 6 do
			local angle = index / 6 * 2 * math.pi
			local at = CFrame.new(math.cos(angle) * 0.4, 1.24, 0.05 + math.sin(angle) * 0.4)
				* CFrame.Angles(0, -angle, 0)
			part(model, head, `Spike{index}`, BLOCK, Vector3.new(0.12, 0.3, 0.16), at, metal, METAL)
			part(model, head, `Tip{index}`, BALL, Vector3.one * 0.12, at * CFrame.new(0, 0.17, 0), metal, METAL)
		end
		part(model, head, "Gem", BALL, Vector3.one * 0.18, CFrame.new(0, 1.0, -0.45), rgb(220, 40, 70), GLASS)
	end,
	Flower = function(model, head, _body, color)
		local base = CFrame.new(0.32, 1.12, -0.05) * CFrame.Angles(rad(-40), 0, rad(-15))
		ring(model, head, "Petal", base, 0.17, 6, Vector3.new(0.22, 0.08, 0.22), color or rgb(255, 255, 255))
		part(
			model,
			head,
			"Middle",
			BALL,
			Vector3.new(0.18, 0.12, 0.18),
			base * CFrame.new(0, 0.03, 0),
			rgb(255, 205, 50)
		)
	end,
	Bow = function(model, head, _body, color)
		local ribbon = color or rgb(255, 110, 170)
		local base = CFrame.new(0.4, 1.0, -0.1) * CFrame.Angles(0, rad(-30), rad(-20))
		part(model, head, "Knot", BALL, Vector3.one * 0.16, base, ribbon)
		for _, side in { -1, 1 } do
			local at = base * CFrame.new(side * 0.17, 0, 0) * CFrame.Angles(0, 0, rad(side * 20))
			part(model, head, `Loop{side}`, BALL, Vector3.new(0.3, 0.24, 0.1), at, ribbon)
		end
	end,
	Clover = function(model, head, _body, color)
		local leaf = color or rgb(60, 170, 70)
		local base = CFrame.new(0.3, 1.2, -0.05) * CFrame.Angles(rad(-45), rad(45), 0)
		for _, offset in
			{
				Vector3.new(0.11, 0, 0.11),
				Vector3.new(-0.11, 0, 0.11),
				Vector3.new(0.11, 0, -0.11),
				Vector3.new(-0.11, 0, -0.11),
			}
		do
			part(model, head, "Leaf", BALL, Vector3.new(0.24, 0.06, 0.24), base * CFrame.new(offset), leaf)
		end
		part(
			model,
			head,
			"Stem",
			CYLINDER,
			Vector3.new(0.3, 0.05, 0.05),
			base * CFrame.new(0, -0.15, 0.05) * UPRIGHT,
			leaf
		)
	end,
	Mushroom = function(model, head, _body, color)
		part(
			model,
			head,
			"Stalk",
			CYLINDER,
			Vector3.new(0.3, 0.24, 0.24),
			CFrame.new(0.15, 1.05, 0.05) * UPRIGHT,
			rgb(245, 238, 220)
		)
		local cap = CFrame.new(0.15, 1.28, 0.05)
		part(model, head, "Cap", BALL, Vector3.new(0.72, 0.42, 0.72), cap, color or rgb(215, 40, 40))
		for index, offset in
			{
				Vector3.new(-0.15, 0.15, -0.16),
				Vector3.new(0.17, 0.14, -0.1),
				Vector3.new(0.02, 0.2, 0.05),
				Vector3.new(-0.22, 0.08, 0.12),
			}
		do
			part(model, head, `Dot{index}`, BALL, Vector3.one * 0.12, cap * CFrame.new(offset), rgb(255, 255, 255))
		end
	end,
	Collar = function(model, head, _body, color)
		ring(
			model,
			head,
			"Collar",
			CFrame.new(0, -0.5, 0.2),
			0.48,
			12,
			Vector3.one * 0.24,
			color or rgb(210, 40, 50),
			FABRIC
		)
	end,
	Bell = function(model, head, _body, color)
		ring(
			model,
			head,
			"Collar",
			CFrame.new(0, -0.5, 0.2),
			0.48,
			12,
			Vector3.one * 0.22,
			color or rgb(210, 40, 50),
			FABRIC
		)
		part(model, head, "Bell", BALL, Vector3.one * 0.32, CFrame.new(0, -0.66, -0.32), GOLD, METAL)
	end,
	Candle = function(model, head, _body, color)
		part(
			model,
			head,
			"Wax",
			CYLINDER,
			Vector3.new(0.5, 0.22, 0.22),
			CFrame.new(0.28, 1.3, 0) * UPRIGHT,
			color or rgb(250, 240, 215)
		)
		part(
			model,
			head,
			"Wick",
			BLOCK,
			Vector3.new(0.12, 0.2, 0.12),
			CFrame.new(0.28, 1.65, 0) * CFrame.Angles(0, rad(45), 0),
			rgb(255, 170, 60),
			NEON
		)
	end,
	Moon = function(model, head, _body, color)
		-- A crescent: balls along an arc, fattest in the middle.
		for index = 0, 6 do
			local angle = rad(110 + index * 25)
			local size = 0.12 + 0.12 * math.sin(index / 6 * math.pi)
			local at = CFrame.new(0.3 + math.cos(angle) * 0.28, 1.4 + math.sin(angle) * 0.28, 0.1)
			part(model, head, `Moon{index}`, BALL, Vector3.one * size, at, color or rgb(255, 244, 190), NEON)
		end
	end,
	Star = function(model, head, _body, color)
		for index = 0, 2 do
			local at = CFrame.new(0.32, 1.42, -0.1) * CFrame.Angles(0, 0, rad(index * 60))
			part(model, head, `Ray{index}`, BLOCK, Vector3.new(0.08, 0.5, 0.08), at, color or rgb(255, 240, 150), NEON)
		end
	end,
	Heart = function(model, head, _body, color)
		local red = color or rgb(255, 70, 120)
		local base = CFrame.new(0.3, 1.38, -0.05)
		for _, side in { -1, 1 } do
			part(
				model,
				head,
				`Lobe{side}`,
				BALL,
				Vector3.new(0.26, 0.26, 0.12),
				base * CFrame.new(side * 0.09, 0.05, 0),
				red,
				NEON
			)
		end
		part(
			model,
			head,
			"Point",
			BLOCK,
			Vector3.new(0.25, 0.25, 0.11),
			base * CFrame.new(0, -0.07, 0) * CFrame.Angles(0, 0, rad(45)),
			red,
			NEON
		)
	end,
	Bolt = function(model, head, _body, color)
		local yellow = color or rgb(255, 226, 60)
		local base = CFrame.new(0.32, 1.42, -0.05)
		part(
			model,
			head,
			"Top",
			BLOCK,
			Vector3.new(0.1, 0.32, 0.08),
			base * CFrame.new(-0.04, 0.17, 0) * CFrame.Angles(0, 0, rad(-25)),
			yellow,
			NEON
		)
		part(model, head, "Middle", BLOCK, Vector3.new(0.24, 0.08, 0.08), base, yellow, NEON)
		part(
			model,
			head,
			"Bottom",
			BLOCK,
			Vector3.new(0.1, 0.32, 0.08),
			base * CFrame.new(0.04, -0.17, 0) * CFrame.Angles(0, 0, rad(-25)),
			yellow,
			NEON
		)
	end,
	Trident = function(model, head, body, color)
		local host = body or head
		local metal = color or GOLD
		local base = CFrame.new(0.55, 1.15, 0.35) * CFrame.Angles(0, 0, rad(-20))
		part(model, host, "Shaft", CYLINDER, Vector3.new(1.5, 0.08, 0.08), base * UPRIGHT, metal, METAL)
		part(model, host, "Bar", BLOCK, Vector3.new(0.42, 0.07, 0.07), base * CFrame.new(0, 0.72, 0), metal, METAL)
		for _, x in { -0.18, 0, 0.18 } do
			part(model, host, "Prong", BLOCK, Vector3.new(0.06, 0.3, 0.06), base * CFrame.new(x, 0.88, 0), metal, METAL)
		end
	end,
	Shield = function(model, head, body, color)
		local host = body or head
		part(
			model,
			host,
			"Shield",
			CYLINDER,
			Vector3.new(0.1, 0.95, 0.95),
			CFrame.new(-1.62, 0.25, -0.1),
			color or rgb(200, 130, 60),
			METAL
		)
		part(model, host, "Boss", BALL, Vector3.one * 0.26, CFrame.new(-1.69, 0.25, -0.1), GOLD, METAL)
	end,
	Nightcap = function(model, head, _body, color)
		local cloth = color or rgb(80, 110, 220)
		local tip =
			cone(model, head, "Cap", CFrame.new(0, 1.0, 0.05), { 0.86, 0.62, 0.42, 0.24 }, 0.22, 18, cloth, FABRIC)
		part(model, head, "Pom", BALL, Vector3.one * 0.22, tip, rgb(255, 255, 255), FABRIC)
	end,
	WitchHat = function(model, head, _body, color)
		local cloth = color or rgb(46, 34, 70)
		part(model, head, "Brim", CYLINDER, Vector3.new(0.06, 1.35, 1.35), CFrame.new(0, 0.95, 0.05) * UPRIGHT, cloth)
		part(
			model,
			head,
			"Band",
			CYLINDER,
			Vector3.new(0.1, 0.78, 0.78),
			CFrame.new(0, 1.03, 0.05) * UPRIGHT,
			rgb(150, 70, 210)
		)
		cone(model, head, "Crown", CFrame.new(0, 1.1, 0.05), { 0.74, 0.54, 0.36, 0.2 }, 0.26, 12, cloth)
	end,
	TopHat = function(model, head, _body, color)
		local cloth = color or rgb(30, 30, 34)
		part(model, head, "Brim", CYLINDER, Vector3.new(0.06, 1.1, 1.1), CFrame.new(0, 0.95, 0.05) * UPRIGHT, cloth)
		part(model, head, "Crown", CYLINDER, Vector3.new(0.6, 0.7, 0.7), CFrame.new(0, 1.28, 0.05) * UPRIGHT, cloth)
		part(
			model,
			head,
			"Band",
			CYLINDER,
			Vector3.new(0.12, 0.72, 0.72),
			CFrame.new(0, 1.05, 0.05) * UPRIGHT,
			rgb(200, 40, 50)
		)
	end,
	Antlers = function(model, head, _body, color)
		local bone = color or WOOD
		for _, side in { -1, 1 } do
			local base = CFrame.new(side * 0.3, 0.85, 0.1) * CFrame.Angles(0, 0, rad(side * -28))
			part(
				model,
				head,
				`Beam{side}`,
				CYLINDER,
				Vector3.new(0.8, 0.09, 0.09),
				base * CFrame.new(0, 0.4, 0) * UPRIGHT,
				bone
			)
			for index, spec in { { 0.3, 50, 0.32 }, { 0.6, -45, 0.26 } } do
				local at = base
					* CFrame.new(0, spec[1], 0)
					* CFrame.Angles(0, 0, rad(side * spec[2]))
					* CFrame.new(0, spec[3] / 2, 0)
				part(model, head, `Tine{side}{index}`, CYLINDER, Vector3.new(spec[3], 0.07, 0.07), at * UPRIGHT, bone)
			end
		end
	end,
	UnicornHorn = function(model, head, _body, color)
		local base = CFrame.new(0, 0.8, -0.42) * CFrame.Angles(rad(-35), 0, 0)
		cone(model, head, "Horn", base, { 0.2, 0.15, 0.1, 0.05 }, 0.18, 0, color or GOLD, METAL)
	end,
	BackSpikes = function(model, head, body, color)
		local host = body or head
		for index, z in { -0.7, -0.35, 0, 0.35, 0.7 } do
			part(
				model,
				host,
				`Spike{index}`,
				WEDGE,
				Vector3.new(0.18, 0.6, 0.45),
				CFrame.new(0, 1.45, z),
				color or rgb(70, 40, 90)
			)
		end
	end,
	Sword = function(model, head, body, color)
		local host = body or head
		local base = CFrame.new(-0.5, 1.3, 0.35) * CFrame.Angles(0, 0, rad(35))
		part(
			model,
			host,
			"Blade",
			BLOCK,
			Vector3.new(0.08, 1.0, 0.2),
			base * CFrame.new(0, 0.48, 0),
			color or rgb(214, 220, 232),
			METAL
		)
		part(model, host, "Guard", BLOCK, Vector3.new(0.1, 0.08, 0.5), base * CFrame.new(0, -0.05, 0), GOLD, METAL)
		part(
			model,
			host,
			"Grip",
			CYLINDER,
			Vector3.new(0.25, 0.1, 0.1),
			base * CFrame.new(0, -0.22, 0) * UPRIGHT,
			rgb(90, 50, 30)
		)
		part(model, host, "Pommel", BALL, Vector3.one * 0.14, base * CFrame.new(0, -0.38, 0), GOLD, METAL)
	end,
	Hammer = function(model, head, body, color)
		local host = body or head
		local base = CFrame.new(0.5, 1.25, 0.35) * CFrame.Angles(0, 0, rad(-30))
		part(model, host, "Handle", CYLINDER, Vector3.new(0.9, 0.1, 0.1), base * UPRIGHT, WOOD)
		part(
			model,
			host,
			"Head",
			BLOCK,
			Vector3.new(0.48, 0.24, 0.24),
			base * CFrame.new(0, 0.45, 0),
			color or rgb(96, 98, 108),
			METAL
		)
	end,
	Scythe = function(model, head, body, color)
		local host = body or head
		local base = CFrame.new(-0.5, 1.3, 0.35) * CFrame.Angles(0, 0, rad(25))
		part(model, host, "Handle", CYLINDER, Vector3.new(1.6, 0.08, 0.08), base * UPRIGHT, rgb(40, 34, 36))
		part(
			model,
			host,
			"Blade",
			BLOCK,
			Vector3.new(0.06, 0.16, 0.7),
			base * CFrame.new(0, 0.78, -0.3) * CFrame.Angles(rad(-15), 0, 0),
			color or rgb(200, 206, 218),
			METAL
		)
	end,
	Dice = function(model, head, _body, color)
		local cube = CFrame.new(0.32, 1.3, -0.05) * CFrame.Angles(rad(20), rad(35), 0)
		part(model, head, "Die", BLOCK, Vector3.one * 0.42, cube, color or rgb(250, 250, 250))
		local pips = {
			Vector3.new(0, 0, -0.215),
			Vector3.new(-0.1, 0.215, -0.1),
			Vector3.new(0.1, 0.215, 0.1),
			Vector3.new(-0.215, 0.1, -0.1),
			Vector3.new(-0.215, 0, 0),
			Vector3.new(-0.215, -0.1, 0.1),
		}
		for index, at in pips do
			part(model, head, `Pip{index}`, BALL, Vector3.new(0.09, 0.09, 0.09), cube * CFrame.new(at), rgb(30, 30, 34))
		end
	end,
	Coin = function(model, head, _body, color)
		part(
			model,
			head,
			"Coin",
			CYLINDER,
			Vector3.new(0.08, 0.55, 0.55),
			CFrame.new(0.3, 1.35, -0.05) * FACING,
			color or GOLD,
			METAL
		)
		part(
			model,
			head,
			"Mark",
			CYLINDER,
			Vector3.new(0.1, 0.32, 0.32),
			CFrame.new(0.3, 1.35, -0.05) * FACING,
			rgb(230, 160, 30),
			METAL
		)
	end,
	SunRays = function(model, head, _body, color)
		for index = 1, 12 do
			local at = CFrame.new(0, 0.25, 0.5) * CFrame.Angles(0, 0, index / 12 * 2 * math.pi) * CFrame.new(0, 0.85, 0)
			part(model, head, `Ray{index}`, BLOCK, Vector3.new(0.12, 0.34, 0.06), at, color or rgb(255, 210, 60), NEON)
		end
	end,
	Cloud = function(model, head, _body, color)
		local puff = color or rgb(255, 255, 255)
		for index, spec in { { -0.22, 1.48, 0.46 }, { 0.08, 1.56, 0.58 }, { 0.36, 1.46, 0.42 } } do
			part(model, head, `Puff{index}`, BALL, Vector3.one * spec[3], CFrame.new(spec[1], spec[2], 0.1), puff)
		end
	end,
	Wheat = function(model, head, _body, color)
		local grain = color or rgb(235, 190, 80)
		for index, x in { -0.12, 0, 0.12 } do
			local at = CFrame.new(0.3 + x, 1.2, 0) * CFrame.Angles(0, 0, rad(-x * 150))
			part(model, head, `Stalk{index}`, CYLINDER, Vector3.new(0.5, 0.04, 0.04), at * UPRIGHT, rgb(200, 170, 90))
			part(model, head, `Ear{index}`, BALL, Vector3.new(0.12, 0.32, 0.12), at * CFrame.new(0, 0.32, 0), grain)
		end
	end,
	Grapes = function(model, head, _body, color)
		local fruit = color or rgb(120, 60, 170)
		local base = CFrame.new(0.5, 0.8, -0.05)
		for index, at in
			{
				Vector3.new(0, 0, 0),
				Vector3.new(0.13, 0.02, 0),
				Vector3.new(-0.13, 0.02, 0),
				Vector3.new(0.06, -0.12, 0),
				Vector3.new(-0.06, -0.12, 0),
				Vector3.new(0, -0.24, 0),
			}
		do
			part(model, head, `Grape{index}`, BALL, Vector3.one * 0.16, base * CFrame.new(at), fruit)
		end
		part(
			model,
			head,
			"Leaf",
			BALL,
			Vector3.new(0.34, 0.07, 0.22),
			base * CFrame.new(0, 0.14, 0.05) * CFrame.Angles(0, 0, rad(-20)),
			LEAF
		)
	end,
	Apple = function(model, head, _body, color)
		local base = CFrame.new(0.3, 1.28, -0.05)
		part(model, head, "Apple", BALL, Vector3.one * 0.42, base, color or GOLD, METAL)
		part(
			model,
			head,
			"Stalk",
			CYLINDER,
			Vector3.new(0.14, 0.04, 0.04),
			base * CFrame.new(0, 0.24, 0) * UPRIGHT,
			WOOD
		)
		part(
			model,
			head,
			"Leaf",
			BALL,
			Vector3.new(0.2, 0.05, 0.12),
			base * CFrame.new(0.1, 0.28, 0) * CFrame.Angles(0, 0, rad(-25)),
			LEAF
		)
	end,
	HeadWings = function(model, head, _body, color)
		local feather = color or rgb(255, 255, 255)
		for _, side in { -1, 1 } do
			for index, spec in { { 0.45, 0.85, 0.5 }, { 0.3, 0.6, 0.78 } } do
				local at = CFrame.new(side * 0.68, spec[3], 0.25) * CFrame.Angles(rad(-30), 0, rad(side * -50))
				part(model, head, `Wing{side}{index}`, BLOCK, Vector3.new(0.06, spec[1], spec[2]), at, feather, NEON)
			end
		end
	end,
	Potion = function(model, head, _body, color)
		local base = CFrame.new(0.3, 1.28, -0.05)
		part(model, head, "Flask", BALL, Vector3.one * 0.44, base, rgb(200, 235, 255), GLASS).Transparency = 0.4
		part(
			model,
			head,
			"Brew",
			BALL,
			Vector3.one * 0.34,
			base * CFrame.new(0, -0.03, 0),
			color or rgb(90, 255, 140),
			NEON
		)
		part(
			model,
			head,
			"Neck",
			CYLINDER,
			Vector3.new(0.16, 0.14, 0.14),
			base * CFrame.new(0, 0.26, 0) * UPRIGHT,
			rgb(200, 235, 255),
			GLASS
		)
		part(model, head, "Cork", CYLINDER, Vector3.new(0.1, 0.16, 0.16), base * CFrame.new(0, 0.37, 0) * UPRIGHT, WOOD)
	end,
	Shades = function(model, head, _body, color)
		local lens = color or rgb(20, 20, 24)
		for _, side in { -1, 1 } do
			part(
				model,
				head,
				`Lens{side}`,
				BLOCK,
				Vector3.new(0.36, 0.22, 0.06),
				CFrame.new(side * 0.24, 0.12, -0.56),
				lens
			)
		end
		part(model, head, "Bridge", BLOCK, Vector3.new(0.9, 0.05, 0.05), CFrame.new(0, 0.2, -0.56), lens)
	end,
	Eyeball = function(model, head, _body, color)
		local base = CFrame.new(0.05, 1.3, -0.1)
		part(model, head, "White", BALL, Vector3.one * 0.46, base, rgb(250, 250, 250))
		part(
			model,
			head,
			"Iris",
			BALL,
			Vector3.new(0.24, 0.24, 0.1),
			base * CFrame.new(0, 0, -0.2),
			color or rgb(200, 30, 40)
		)
		part(model, head, "Pupil", BALL, Vector3.new(0.12, 0.12, 0.06), base * CFrame.new(0, 0, -0.25), rgb(10, 10, 12))
	end,
	Crystal = function(model, head, _body, color)
		local gem = color or rgb(140, 220, 255)
		for index, spec in { { 0, 0.55, 0 }, { -0.16, 0.38, -20 }, { 0.16, 0.4, 20 } } do
			local at = CFrame.new(spec[1], 1.05 + spec[2] / 2, 0.05) * CFrame.Angles(0, rad(45), rad(spec[3]))
			part(model, head, `Shard{index}`, BLOCK, Vector3.new(0.16, spec[2], 0.16), at, gem, NEON)
		end
	end,
}

function Extras.Add(model: Model, kind: string, color: Color3?)
	local head = piece(model, "Head")
	if not head then
		return
	end
	local build = builders[kind]
	if build then
		local folder = model:FindFirstChild("Extras")
		local before = if folder then #folder:GetChildren() else 0
		build(model, head, piece(model, "Body"), color)
		local factor = GROW[kind]
		local made = model:FindFirstChild("Extras")
		if factor and made then
			grow({ table.unpack(made:GetChildren(), before + 1) }, factor)
		end
		return
	end
	-- Offsets from the head's centre: the top of its wool is about a stud above it.
	if kind == "Leaf" then
		part(
			model,
			head,
			"Stem",
			Enum.PartType.Cylinder,
			Vector3.new(0.35, 0.08, 0.08),
			CFrame.new(0.1, 1.02, 0.05) * CFrame.Angles(0, 0, rad(80)),
			Color3.fromRGB(110, 80, 50)
		)
		part(
			model,
			head,
			"Leaf",
			Enum.PartType.Ball,
			Vector3.new(0.75, 0.12, 0.45),
			CFrame.new(0.38, 1.2, 0.05) * CFrame.Angles(0, rad(20), rad(-25)),
			LEAF
		)
	elseif kind == "Helmet" then
		part(
			model,
			head,
			"Helmet",
			Enum.PartType.Ball,
			Vector3.new(1.35, 0.85, 1.25),
			CFrame.new(0, 0.85, 0.08),
			Color3.fromRGB(150, 156, 166),
			Enum.Material.Metal
		)
		part(
			model,
			head,
			"Brim",
			Enum.PartType.Cylinder,
			Vector3.new(0.12, 1.4, 1.4),
			CFrame.new(0, 0.62, 0.08) * CFrame.Angles(0, 0, rad(90)),
			Color3.fromRGB(196, 150, 70),
			Enum.Material.Metal
		)
		part(
			model,
			head,
			"Plume",
			Enum.PartType.Block,
			Vector3.new(0.18, 0.55, 1.05),
			CFrame.new(0, 1.42, 0.18),
			Color3.fromRGB(220, 40, 40)
		)
	elseif kind == "Wreath" then
		for index = 1, 10 do
			local angle = (index / 10) * 2 * math.pi
			local at = CFrame.new(math.sin(angle) * 0.62, 0.78, 0.05 + math.cos(angle) * 0.56)
				* CFrame.Angles(0, angle, rad(25))
			part(model, head, `Leaf{index}`, Enum.PartType.Ball, Vector3.new(0.32, 0.12, 0.2), at, color or LEAF)
		end
	elseif kind == "BackWings" then
		-- A pair of wings up off its back, for the Cupid and Victory sheep.
		local body = piece(model, "Body")
		if body then
			for _, side in { -1, 1 } do
				for index, size in { Vector3.new(0.08, 0.7, 1.15), Vector3.new(0.08, 0.5, 0.8) } do
					part(
						model,
						body,
						`BackWing{side}{index}`,
						Enum.PartType.Block,
						size,
						CFrame.new(side * (0.75 + index * 0.18), 1.05 + index * 0.12, 0.15 + index * 0.1)
							* CFrame.Angles(rad(-15), 0, rad(side * -40)),
						Color3.fromRGB(255, 255, 255),
						Enum.Material.Neon
					)
				end
			end
		end
	elseif kind == "Blindfold" then
		-- Justice is blind: a band round its eyes.
		part(
			model,
			head,
			"Blindfold",
			Enum.PartType.Block,
			Vector3.new(1.18, 0.24, 1.03),
			CFrame.new(0, 0.12, 0),
			Color3.fromRGB(236, 238, 246)
		)
		part(
			model,
			head,
			"Knot",
			Enum.PartType.Ball,
			Vector3.new(0.3, 0.3, 0.3),
			CFrame.new(0, 0.12, 0.56),
			Color3.fromRGB(236, 238, 246)
		)
	elseif kind == "Flame" then
		-- The hearth's flame on its head.
		part(
			model,
			head,
			"Flame",
			Enum.PartType.Block,
			Vector3.new(0.42, 0.55, 0.42),
			CFrame.new(0, 1.3, 0.05) * CFrame.Angles(0, rad(45), 0),
			color or Color3.fromRGB(255, 140, 50),
			Enum.Material.Neon
		)
		part(
			model,
			head,
			"FlameCore",
			Enum.PartType.Block,
			Vector3.new(0.24, 0.42, 0.24),
			CFrame.new(0, 1.42, 0.05) * CFrame.Angles(0, rad(45), 0),
			Color3.fromRGB(255, 220, 110),
			Enum.Material.Neon
		)
	elseif kind == "Pegasus" then
		local body = piece(model, "Body")
		if body then
			pegasusWing(model, body, 1)
			pegasusWing(model, body, -1)
		end
		-- A glowing gold halo over its head, tipped back a little: a ring of beads.
		local beads = 26
		for index = 1, beads do
			local angle = (index / beads) * 2 * math.pi
			local at = CFrame.new(0, 1.2, 0.12)
				* CFrame.Angles(rad(-14), 0, 0)
				* CFrame.new(math.cos(angle) * 0.42, 0, math.sin(angle) * 0.42)
			part(
				model,
				head,
				`Halo{index}`,
				Enum.PartType.Ball,
				Vector3.new(0.13, 0.13, 0.13),
				at,
				PEGASUS_GOLD,
				Enum.Material.Neon
			)
		end
		-- Gold hooves: a band round the foot of each leg.
		for _, spec in WING_LEGS do
			local leg = piece(model, spec.Name)
			if leg then
				part(
					model,
					leg,
					`Hoof{spec.Name}`,
					Enum.PartType.Cylinder,
					Vector3.new(0.2, leg.Size.X * 1.12, leg.Size.Z * 1.12),
					CFrame.new(0, -leg.Size.Y / 2 + 0.1, 0) * CFrame.Angles(0, 0, rad(90)),
					PEGASUS_GOLD,
					Enum.Material.Metal
				)
			end
		end
	elseif kind == "Wings" then
		for _, spec in WING_LEGS do
			local leg = piece(model, spec.Name)
			local side = spec.Side
			if leg then
				local at = CFrame.new(side * 0.22, -0.28, 0.05) * CFrame.Angles(rad(-35), 0, rad(side * 20))
				part(
					model,
					leg,
					`Wing{spec.Name}`,
					Enum.PartType.Block,
					Vector3.new(0.06, 0.32, 0.5),
					at,
					Color3.fromRGB(255, 255, 255),
					Enum.Material.Neon
				)
			end
		end
	end
end

return table.freeze(Extras)
