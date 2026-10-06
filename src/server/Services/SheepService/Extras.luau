--!strict

-- The primitive accessories some families wear on top of a Shear a Sheep breed: the Grape Sheep's leaf, the War
-- Sheep's helmet and plume, the Laurel Sheep's wreath, the Wingfoot Sheep's ankle wings, the Cupid and Victory sheep's
-- back wings, the Justice Sheep's blindfold, the Hearth Sheep's flame and the Pegasus Sheep's feathered wings, halo and
-- gold hooves. Built on a sheep dressed at its rig's own size (Looks.Dress at scale 1), welded to the piece they sit
-- on, and scaled with the sheep afterwards.
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

function Extras.Add(model: Model, kind: string)
	local head = piece(model, "Head")
	if not head then
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
			part(model, head, `Leaf{index}`, Enum.PartType.Ball, Vector3.new(0.32, 0.12, 0.2), at, LEAF)
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
			Color3.fromRGB(255, 140, 50),
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
		local beads = 16
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
				Vector3.new(0.17, 0.17, 0.17),
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
