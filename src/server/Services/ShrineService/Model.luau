--!strict

-- The Merge Shrine's model, the Laurel Ring the user picked (studio/MergeShrineMockup.luau, 2026-10-05), in the map's
-- own look: Plastic with its studs texture, marble, gold and blue neon inlays. A round marble dais in three steps,
-- three pedestals round a centre altar, a column with a fire bowl behind each, and a floating gold laurel crown. The
-- pole of light and the orb the lamb pops out of are there but hidden: they show only during a merge.
--
-- What the clients find by name (ShrineController): Pedestal1 (left, seen from the front), Pedestal2 (the back) and
-- Pedestal3 (right), the inlays the three sheep stand on; Altar, the gold cap the lamb lands on; Orb and Beam.
local Model = {}

local STUDS = "rbxassetid://6905003203"
local MARBLE = Color3.fromRGB(240, 238, 232)
local SHADE = Color3.fromRGB(222, 216, 236)
local GOLD = Color3.fromRGB(228, 186, 70)
local BLUE = Color3.fromRGB(70, 130, 225)
local LEAF = Color3.fromRGB(110, 190, 90)
local ORB = Color3.fromRGB(150, 210, 255)
local FLOOR = 3 -- the dais's top, above the ground
local RADIUS = 7.6 -- the pedestals' distance from the centre
-- The pedestals' angles round the centre, from the front, in the order the clients number them.
local PEDESTALS = { 60, 180, 300 }

function Model.Build(at: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "MergeShrine"

	local function studs(part: BasePart)
		for _, face in Enum.NormalId:GetEnumItems() do
			local texture = Instance.new("Texture")
			texture.Texture = STUDS
			texture.Face = face
			texture.StudsPerTileU = 9
			texture.StudsPerTileV = 9
			texture.Transparency = 0.9
			texture.Parent = part
		end
	end

	local function block(size: Vector3, offset: CFrame, color: Color3, neon: boolean?): Part
		local part = Instance.new("Part")
		part.Anchored = true
		part.Size = size
		part.CFrame = at * offset
		part.Color = color
		part.Material = if neon then Enum.Material.Neon else Enum.Material.Plastic
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if not neon then
			studs(part)
		end
		part.Parent = model
		return part
	end

	local function disc(diameter: number, height: number, y: number, color: Color3)
		local part = block(
			Vector3.new(height, diameter, diameter),
			CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)),
			color
		)
		part.Shape = Enum.PartType.Cylinder
	end

	local function flame(offset: CFrame)
		local part = block(Vector3.new(1.8, 1.3, 1.8), offset, Color3.fromRGB(255, 140, 40), true)
		part.CanCollide = false
		local fire = Instance.new("Fire")
		fire.Size = 5
		fire.Heat = 7
		fire.Parent = part
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 170, 80)
		light.Range = 16
		light.Brightness = 1.6
		light.Parent = part
	end

	disc(29, 1, 0.5, MARBLE)
	disc(26, 1, 1.5, SHADE)
	disc(23, 1, 2.5, MARBLE)
	for index = 0, 15 do
		local angle = math.rad(index * 22.5)
		local offset = CFrame.new(math.sin(angle) * 4.6, FLOOR + 0.05, math.cos(angle) * 4.6)
			* CFrame.Angles(0, angle + math.rad(90), 0)
		block(Vector3.new(2.4, 0.1, 0.6), offset, BLUE, true).CanCollide = false
	end
	block(Vector3.new(7, 0.5, 2.4), CFrame.new(0, 0.25, -15.2), SHADE)

	block(Vector3.new(3.4, 1.4, 3.4), CFrame.new(0, FLOOR + 0.7, 0), SHADE)
	block(Vector3.new(4, 0.5, 4), CFrame.new(0, FLOOR + 1.65, 0), GOLD).Name = "Altar"

	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CastShadow = false
	orb.Size = Vector3.new(3.2, 3.2, 3.2)
	orb.Material = Enum.Material.Neon
	orb.Color = ORB
	orb.Transparency = 1
	orb.CFrame = at * CFrame.new(0, FLOOR + 13, 0)
	orb.Parent = model
	local glow = Instance.new("PointLight")
	glow.Color = ORB
	glow.Range = 18
	glow.Brightness = 2
	glow.Enabled = false
	glow.Parent = orb
	local beam = block(Vector3.new(0.6, 10.6, 0.6), CFrame.new(0, FLOOR + 7.2, 0), ORB, true)
	beam.Name = "Beam"
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CastShadow = false
	beam.Transparency = 1

	for index, degrees in PEDESTALS do
		local angle = math.rad(degrees)
		local spot = CFrame.new(math.sin(angle) * RADIUS, FLOOR, -math.cos(angle) * RADIUS)
		block(Vector3.new(4.6, 0.8, 4.6), spot * CFrame.new(0, 0.4, 0), MARBLE)
		block(Vector3.new(3.6, 2.8, 3.6), spot * CFrame.new(0, 2.2, 0), SHADE)
		block(Vector3.new(4.8, 0.6, 4.8), spot * CFrame.new(0, 3.9, 0), GOLD)
		block(Vector3.new(4, 0.12, 4), spot * CFrame.new(0, 4.22, 0), BLUE, true).Name = `Pedestal{index}`

		local column = CFrame.new(math.sin(angle) * (RADIUS + 3.8), FLOOR, -math.cos(angle) * (RADIUS + 3.8))
		block(Vector3.new(3, 0.8, 3), column * CFrame.new(0, 0.4, 0), MARBLE)
		block(Vector3.new(2, 12.4, 2), column * CFrame.new(0, 7, 0), MARBLE)
		block(Vector3.new(3, 0.8, 3), column * CFrame.new(0, 13.6, 0), MARBLE)
		block(Vector3.new(3.4, 0.9, 3.4), column * CFrame.new(0, 14.45, 0), GOLD)
		flame(column * CFrame.new(0, 15.5, 0))
	end

	for index = 0, 23 do
		local angle = math.rad(index * 15)
		local offset = CFrame.new(math.sin(angle) * 8.4, FLOOR + 19, math.cos(angle) * 8.4)
			* CFrame.Angles(0, angle + math.rad(90), 0)
		block(Vector3.new(2.3, 0.7, 0.9), offset, GOLD).CanCollide = false
		local leaf = block(
			Vector3.new(1.4, 0.6, 1.3),
			offset * CFrame.new(0.3, 0.5, 0) * CFrame.Angles(0, 0, math.rad(25)),
			LEAF
		)
		leaf.CanCollide = false
	end

	model.PrimaryPart = model:FindFirstChild("Altar") :: BasePart
	return model
end

return Model
