--!strict
-- Builds the game's place file from what's on disk: the commissioned map with High Olympus built on top
-- (tools/UpperMountain.luau), the borrowed Shear a Sheep assets (assets/ShearASheepAssets.rbxm, from
-- tools/extract-assets.luau) in ServerStorage.Assets, the sheep's stud materials (studio/SheepStuds.luau) and the code
-- from a `rojo build` of default.project.json. Open the result in Studio and press Play, or `rojo serve` into it.
--
-- From the repo root:
--   rojo build default.project.json --output build/game.rbxl
--   lune run tools/assemble.luau "vvs_map(commission) (1).rbxl" assets/ShearASheepAssets.rbxm build/game.rbxl StealASheep.rbxl
-- (scripts/build-place.ps1 does both.)

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local UpperMountain = require("./UpperMountain")

local mapPath, assetsPath, codePath, output = process.args[1], process.args[2], process.args[3], process.args[4]
assert(
	mapPath and assetsPath and codePath and output,
	"usage: lune run tools/assemble.luau <map.rbxl> <assets.rbxm> <code.rbxl> <out.rbxl>"
)

local place = roblox.deserializePlace(fs.readFile(mapPath))
local code = roblox.deserializePlace(fs.readFile(codePath))

-- The map: High Olympus, the stretches above the commissioned map's old summit (tiers 13 to 30), from its own pieces.
UpperMountain.Build({
	Instance = roblox.Instance,
	CFrame = roblox.CFrame,
	Vector3 = roblox.Vector3,
	Color3 = roblox.Color3,
	Enum = roblox.Enum,
}, place:GetService("Workspace"))

-- Code: every child of the containers Rojo owns, over whatever the map had there.
local function moveChildren(from: any, to: any)
	for _, child in from:GetChildren() do
		local old = to:FindFirstChild(child.Name)
		if old then
			old:Destroy()
		end
		child.Parent = to
	end
end
moveChildren(code:GetService("ReplicatedStorage"), place:GetService("ReplicatedStorage"))
moveChildren(code:GetService("ServerScriptService"), place:GetService("ServerScriptService"))
local codeScripts = code:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local placeScripts = place:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
assert(codeScripts and placeScripts, "StarterPlayerScripts is missing")
moveChildren(codeScripts, placeScripts)
local tests = code:GetService("ServerStorage"):FindFirstChild("Tests")
local serverStorage = place:GetService("ServerStorage")
if tests then
	local old = serverStorage:FindFirstChild("Tests")
	if old then
		old:Destroy()
	end
	tests.Parent = serverStorage
end

-- Assets: ServerStorage.Assets (SheepService and ShopService read them there).
local folder = serverStorage:FindFirstChild("Assets")
if folder then
	folder:Destroy()
end
folder = roblox.Instance.new("Folder")
folder.Name = "Assets"
for _, instance in roblox.deserializeModel(fs.readFile(assetsPath)) do
	instance.Parent = folder
end
folder.Parent = serverStorage

-- The sheep's stud materials: the Studio script the cloud place gets, run here on this place.
local studs = luau.load(fs.readFile("studio/SheepStuds.luau"), {
	debugName = "studio/SheepStuds.luau",
	environment = { game = place, Enum = roblox.Enum, Color3 = roblox.Color3 },
})
print(studs())

fs.writeFile(output, roblox.serializePlace(place))
print(`Wrote {output}`)
