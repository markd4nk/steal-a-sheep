--!strict
-- Mock-ups of the map's studs laid over the sheep (the user, 2026-10-05). Run with execute_luau in Edit after setting
-- LOOK. It destroys and rebuilds workspace.TEMP_StudSheep: four sheep side by side on the grass by the first plot's
-- fence, turned a little toward the camera at CAMERA. The map's studs are MaterialService.Studs (Plastic, colour and
-- bump maps, one stud a tile). On the sheep's meshes the tiles follow each mesh's UVs at that size in studs, so a
-- bigger sheep carries more of them, as a bigger block on the map does.
--   "Today": FAMILIES as they are.
--   "A": the map's studs at the map's size (1 stud) on the fleece; face, ears, legs, horns and extras stay smooth.
--   "B": the same studs at half size on the fleece (a copy of the variant, TEMP_SheepStuds, at 0.5).
--   "C": B's half-size studs all over: fleece, face, ears, legs, horns and extras.
--   "Compare": COMPARE_FAMILY four times, in Today, A, B and C from left to right.
--   "None": removes everything this script made.
-- Only Plastic and SmoothPlastic parts take studs: a family's glowing, glass or metal wool keeps its material here.
-- A mock-up, not the shipped look.

local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LOOK = "A"
local FAMILIES = { "Laurel", "Grape", "Rose", "War" }
local COMPARE_FAMILY = "Laurel"
local SCALE = 1.6 -- a Standard adult (GameConfig.SheepSize)
local GROUND = 59.463
local FIRST_X = 231.5
local SPACING = 5.4
local ROW_Z = 240
local CAMERA = Vector3.new(239.6, 63.4, 249.5)
local TURN = math.rad(-18)
local HALF_NAME = "TEMP_SheepStuds"

local old = workspace:FindFirstChild("TEMP_StudSheep")
if old then
	old:Destroy()
end
local oldVariant = MaterialService:FindFirstChild(HALF_NAME)
if oldVariant then
	oldVariant:Destroy()
end
if LOOK == "None" then
	return "removed TEMP_StudSheep and TEMP_SheepStuds"
end

local studs = MaterialService:FindFirstChild("Studs")
assert(studs and studs:IsA("MaterialVariant"), "MaterialService.Studs is missing: is this the map's place?")
local half = studs:Clone()
half.Name = HALF_NAME
half.StudsPerTile = 0.5
half.Parent = MaterialService

local service = require(ServerScriptService.Services.SheepService) :: any
if not service.IsReady(service) then
	service.Start(service)
end
-- SheepService.Start made the menus' preview folder; it isn't part of the place.
local looks = ReplicatedStorage:FindFirstChild("SheepLooks")
if looks then
	looks:Destroy()
end

local function isFleece(sheep: Model, part: BasePart): boolean
	local wool = sheep:FindFirstChild("Wool")
	if wool and part:IsDescendantOf(wool) then
		return true
	end
	local tint = part:GetAttribute("Tint")
	return part.Name == "Tail" or tint == "Wool" or tint == "Spot"
end

local function addStuds(sheep: Model, variant: string, everywhere: boolean)
	for _, descendant in sheep:GetDescendants() do
		if not descendant:IsA("BasePart") or descendant == sheep.PrimaryPart or descendant.Transparency >= 1 then
			continue
		end
		local material = descendant.Material
		if material ~= Enum.Material.Plastic and material ~= Enum.Material.SmoothPlastic then
			continue
		end
		if everywhere or isFleece(sheep, descendant) then
			descendant.Material = Enum.Material.Plastic
			descendant.MaterialVariant = variant
		end
	end
end

local function dress(sheep: Model, look: string)
	if look == "A" then
		addStuds(sheep, "Studs", false)
	elseif look == "B" then
		addStuds(sheep, HALF_NAME, false)
	elseif look == "C" then
		addStuds(sheep, HALF_NAME, true)
	end
end

local row: { { Family: string, Look: string } } = {}
if LOOK == "Compare" then
	for _, look in { "Today", "A", "B", "C" } do
		table.insert(row, { Family = COMPARE_FAMILY, Look = look })
	end
else
	for _, family in FAMILIES do
		table.insert(row, { Family = family, Look = LOOK })
	end
end

local model = Instance.new("Model")
model.Name = "TEMP_StudSheep"
for index, entry in row do
	local sheep = service.Build(service, entry.Family, 1, SCALE)
	if not sheep then
		continue
	end
	dress(sheep, entry.Look)
	local at = Vector3.new(FIRST_X + (index - 1) * SPACING, GROUND, ROW_Z)
	sheep:PivotTo(CFrame.lookAt(at, Vector3.new(CAMERA.X, GROUND, CAMERA.Z)) * CFrame.Angles(0, TURN, 0))
	sheep.Parent = model
end
model.Parent = workspace
return `built TEMP_StudSheep, look {LOOK}`
