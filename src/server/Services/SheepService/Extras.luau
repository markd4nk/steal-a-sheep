--!strict

-- The primitive accessories some families wear on top of a Shear a Sheep breed (the design's "primitive visual"):
-- the Grape Sheep's leaf, the War Sheep's helmet and plume, the Laurel Sheep's wreath, the Wingfoot Sheep's ankle
-- wings, the Cupid and Victory sheep's back wings, the Justice Sheep's blindfold and the Hearth Sheep's flame. Built on
-- a sheep dressed at its rig's own size (Looks.Dress at scale 1), welded to the piece they sit on, and scaled with the
-- sheep afterwards.
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
