--!strict
-- The stud materials every sheep's wool wears (the user, 2026-10-05: the map's studs on every sheep, mock-up B). Each
-- is a copy of the map's MaterialService.Studs (Plastic, colour and bump maps, one stud a tile) at half a stud a tile:
-- one for each base material wool comes in, and a glowing Plastic one for Neon wool, whose own colour map is also its
-- glow mask (Neon and Glass draw no variant). GameConfig.Sheep.Studs names them; SheepService/Looks puts them on.
--
-- Run with execute_luau in Edit: on the cloud place before publishing code that uses them, or on any place copy.
-- tools/assemble.luau runs this same file on the place it builds. It destroys and remakes what it made.

local MaterialService = game:GetService("MaterialService")

local STUDS_PER_TILE = 0.5
local GLOW_STRENGTH = 1.6
local VARIANTS: { { Name: string, Base: string, Glow: boolean? } } = {
	{ Name = "SheepStuds", Base = "Plastic" },
	{ Name = "SheepStudsMetal", Base = "Metal" },
	{ Name = "SheepStudsFabric", Base = "Fabric" },
	{ Name = "SheepStudsFoil", Base = "Foil" },
	{ Name = "SheepStudsGlow", Base = "Plastic", Glow = true },
}

local studs = MaterialService:FindFirstChild("Studs")
assert(studs and studs:IsA("MaterialVariant"), "MaterialService.Studs (the map's studs) is missing")

for _, spec in VARIANTS do
	local old = MaterialService:FindFirstChild(spec.Name)
	if old then
		old:Destroy()
	end
	local variant = studs:Clone()
	variant.Name = spec.Name
	variant.BaseMaterial = (Enum.Material :: any)[spec.Base]
	variant.StudsPerTile = STUDS_PER_TILE
	if spec.Glow then
		variant.EmissiveMaskContent = variant.ColorMapContent
		variant.EmissiveStrength = GLOW_STRENGTH
		variant.EmissiveTint = Color3.new(1, 1, 1)
	end
	variant.Parent = MaterialService
end

return `made {#VARIANTS} sheep stud materials in MaterialService`
