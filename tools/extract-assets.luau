--!strict
-- Copies the Studio-side pieces this game borrows from Shear a Sheep's place into one model file, so building the
-- place never needs Shear a Sheep again:
--   SheepRig        workspace.SheepRig (the sheep rig every breed is dressed on)
--   SheepAddons     ServerStorage.Assets.SheepAddons (wool styles, horns, breed builds' wool and extras: MeshParts)
--   WorldKit        ServerStorage.Assets.WorldKit.MutationMachine (the Merge Shrine)
--
-- Run with Lune (rokit add --global lune-org/lune), from the repo root:
--   lune run tools/extract-assets.luau "<a Shear a Sheep place .rbxl>" assets/ShearASheepAssets.rbxm
-- A local copy of the place is %LOCALAPPDATA%\Roblox\server.rbxl after a Server & Clients test in its Studio.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local source, output = process.args[1], process.args[2]
assert(source and output, "usage: lune run tools/extract-assets.luau <shear place.rbxl> <out.rbxm>")

local place = roblox.deserializePlace(fs.readFile(source))
local workspace = place:GetService("Workspace")
local serverStorage = place:GetService("ServerStorage")
local assets = serverStorage:FindFirstChild("Assets")
assert(assets, "the place has no ServerStorage.Assets")

local rig = workspace:FindFirstChild("SheepRig") or assets:FindFirstChild("SheepRig")
assert(rig, "the place has no SheepRig")
local addons = assets:FindFirstChild("SheepAddons")
assert(addons, "the place has no ServerStorage.Assets.SheepAddons")
local kit = assets:FindFirstChild("WorldKit")
local machine = kit and kit:FindFirstChild("MutationMachine")

-- The originals are serialized as they are (Lune can't serialize clones of these), trimmed in memory first; the source
-- file is never written. The Animation Editor's link to its drafts stays in Shear a Sheep: it points outside the rig.
local saves = rig:FindFirstChild("AnimSaves")
if saves then
	saves:Destroy()
end
rig.Name = "SheepRig"
local roots: { any } = { rig, addons }
if kit and machine then
	for _, child in kit:GetChildren() do
		if child ~= machine then
			child:Destroy()
		end
	end
	table.insert(roots, kit)
end
fs.writeFile(output, roblox.serializeModel(roots))
print(`Wrote {output}: SheepRig ({#rig:GetDescendants()} parts and joints), SheepAddons ({#addons:GetChildren()}), WorldKit ({if machine then "MutationMachine" else "none"})`)
