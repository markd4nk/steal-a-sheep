--!strict
-- The Merge Shrine mock-up the user picked (2026-10-05): "Laurel Ring", mock-up C. Run with execute_luau in Edit.
-- It destroys and rebuilds workspace.TEMP_ShrineC at the shrine's spot in the hub (ShopService's SHRINE_AT), with
-- three Sun Sheep on the pedestals. A round marble dais in three steps, three pedestals at 120 degrees round a centre
-- altar, a column with a fire bowl behind each, a glowing orb over the altar (where the merged lamb pops out) and a
-- floating gold laurel crown. The map's own look: Plastic with its studs texture, marble, gold, blue neon inlays.
-- A mock-up, not the shipped model: the real build gets its own name and place once the user approves the look.

local ORIGIN = CFrame.new(287, 59.46, 245) * CFrame.Angles(0, math.rad(90), 0)
local STUDS = "rbxassetid://6905003203"
local MARBLE = Color3.fromRGB(240, 238, 232)
local SHADE = Color3.fromRGB(222, 216, 236)
local GOLD = Color3.fromRGB(228, 186, 70)
local BLUE = Color3.fromRGB(70, 130, 225)
local LEAF = Color3.fromRGB(110, 190, 90)
local FLOOR = 3
local WITH_SHEEP = true

local old = workspace:FindFirstChild("TEMP_ShrineC")
if old then
	old:Destroy()
end
local model = Instance.new("Model")
model.Name = "TEMP_ShrineC"

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

local function block(size: Vector3, at: CFrame, color: Color3, neon: boolean?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.CFrame = ORIGIN * at
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
	local part = block(Vector3.new(height, diameter, diameter), CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), color)
	part.Shape = Enum.PartType.Cylinder
end

local function flame(at: CFrame)
	local part = block(Vector3.new(1.8, 1.3, 1.8), at, Color3.fromRGB(255, 140, 40), true)
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
for i = 0, 15 do
	local angle = math.rad(i * 22.5)
	local at = CFrame.new(math.sin(angle) * 4.6, FLOOR + 0.05, math.cos(angle) * 4.6)
		* CFrame.Angles(0, angle + math.rad(90), 0)
	block(Vector3.new(2.4, 0.1, 0.6), at, BLUE, true)
end

-- The centre altar, where the merged lamb lands. The pole of light and the orb it pops out of exist only during a
-- merge (the user, 2026-10-05): hidden here, shown by the merge.
block(Vector3.new(3.4, 1.4, 3.4), CFrame.new(0, FLOOR + 0.7, 0), SHADE)
block(Vector3.new(4, 0.5, 4), CFrame.new(0, FLOOR + 1.65, 0), GOLD)
local orb = Instance.new("Part")
orb.Name = "Orb"
orb.Shape = Enum.PartType.Ball
orb.Anchored = true
orb.CanCollide = false
orb.Size = Vector3.new(3.2, 3.2, 3.2)
orb.Material = Enum.Material.Neon
orb.Color = Color3.fromRGB(150, 210, 255)
orb.Transparency = 1
orb.CFrame = ORIGIN * CFrame.new(0, FLOOR + 13, 0)
orb.Parent = model
local glow = Instance.new("PointLight")
glow.Color = orb.Color
glow.Range = 18
glow.Brightness = 2
glow.Enabled = false
glow.Parent = orb
local beam = block(Vector3.new(0.6, 10.6, 0.6), CFrame.new(0, FLOOR + 7.2, 0), Color3.fromRGB(150, 210, 255), true)
beam.Name = "Beam"
beam.CanCollide = false
beam.Transparency = 1

local sheepService = nil
if WITH_SHEEP then
	local ServerScriptService = game:GetService("ServerScriptService")
	local service = require(ServerScriptService.Services.SheepService) :: any
	service.Start(service)
	sheepService = service
end

local RADIUS = 7.6
for index, degrees in { 180, 60, 300 } do
	local angle = math.rad(degrees)
	local x, z = math.sin(angle) * RADIUS, -math.cos(angle) * RADIUS
	local at = CFrame.new(x, FLOOR, z)
	block(Vector3.new(4.6, 0.8, 4.6), at * CFrame.new(0, 0.4, 0), MARBLE)
	block(Vector3.new(3.6, 2.8, 3.6), at * CFrame.new(0, 2.2, 0), SHADE)
	block(Vector3.new(4.8, 0.6, 4.8), at * CFrame.new(0, 3.9, 0), GOLD)
	block(Vector3.new(4, 0.12, 4), at * CFrame.new(0, 4.22, 0), BLUE, true)
	if sheepService then
		local sheep = sheepService.Build(sheepService, "Sun", 1, if index == 1 then 1.6 * 1.35 else 1.6)
		if sheep then
			sheep:PivotTo(ORIGIN * at * CFrame.new(0, 4.28, 0) * CFrame.Angles(0, math.rad(180), 0))
			sheep.Parent = model
		end
	end
	local columnAt = CFrame.new(math.sin(angle) * (RADIUS + 3.8), FLOOR, -math.cos(angle) * (RADIUS + 3.8))
	block(Vector3.new(3, 0.8, 3), columnAt * CFrame.new(0, 0.4, 0), MARBLE)
	block(Vector3.new(2, 12.4, 2), columnAt * CFrame.new(0, 7, 0), MARBLE)
	block(Vector3.new(3, 0.8, 3), columnAt * CFrame.new(0, 13.6, 0), MARBLE)
	block(Vector3.new(3.4, 0.9, 3.4), columnAt * CFrame.new(0, 14.45, 0), GOLD)
	flame(columnAt * CFrame.new(0, 15.5, 0))
end

-- The floating laurel crown.
for i = 0, 23 do
	local angle = math.rad(i * 15)
	local at = CFrame.new(math.sin(angle) * 8.4, FLOOR + 19, math.cos(angle) * 8.4) * CFrame.Angles(0, angle + math.rad(90), 0)
	block(Vector3.new(2.3, 0.7, 0.9), at, GOLD)
	block(Vector3.new(1.4, 0.6, 1.3), at * CFrame.new(0.3, 0.5, 0) * CFrame.Angles(0, 0, math.rad(25)), LEAF)
end

block(Vector3.new(7, 0.5, 2.4), CFrame.new(0, 0.25, -15.2), SHADE)

model.Parent = workspace
-- SheepService.Start made the menus' preview folder; it isn't part of the place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local looks = ReplicatedStorage:FindFirstChild("SheepLooks")
if looks then
	looks:Destroy()
end
return "built TEMP_ShrineC"
