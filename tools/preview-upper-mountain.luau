--!strict
-- Packs tools/UpperMountain.luau as a ModuleScript into Studio's content folder, so an Edit-mode command can load it
-- with game:GetObjects("rbxasset://sas/upper.rbxm") and build High Olympus into the open place for a look:
--
--   lune run tools/preview-upper-mountain.luau "%LOCALAPPDATA%/Roblox/Versions/<version>/content"
--
-- then, in Studio (Edit):
--   local m = game:GetObjects("rbxasset://sas/upper.rbxm")[1]; m.Parent = game.ServerStorage
--   require(m).Build({ Instance = Instance, CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum }, workspace)
--   m:Destroy()

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local content = process.args[1]
assert(content, "usage: lune run tools/preview-upper-mountain.luau <Studio content folder>")
local module = roblox.Instance.new("ModuleScript")
module.Name = "UpperMountain"
module.Source = fs.readFile("tools/UpperMountain.luau")
if not fs.isDir(`{content}/sas`) then
	fs.writeDir(`{content}/sas`)
end
fs.writeFile(`{content}/sas/upper.rbxm`, roblox.serializeModel({ module }))
print(`Wrote {content}/sas/upper.rbxm`)
