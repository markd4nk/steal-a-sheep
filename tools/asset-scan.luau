--!strict
-- Every content id in a place file, with where it's used (the asset audit: DESIGN/TESTING.md, Asset audit).
-- Usage: lune run tools/asset-scan.luau <place.rbxl> <out.json>
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local game = roblox.deserializePlace(fs.readFile(process.args[1]))
local PROPS = {
	"MeshId", "TextureID", "TextureId", "Texture", "SoundId", "Image", "AnimationId", "ColorMap", "NormalMap",
	"MetalnessMap", "RoughnessMap", "ShirtTemplate", "PantsTemplate", "Graphic", "SkyboxBk", "SkyboxDn", "SkyboxFt",
	"SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId", "HoverImage", "PressedImage", "LinkedSource",
	"VideoContent", "Video", "ImageContent", "MeshContent", "TextureContent", "OverlayTextureId",
}
local found: { [string]: { string } } = {}
local function note(id: string, where: string)
	local list = found[id]
	if not list then
		list = {}
		found[id] = list
	end
	if #list < 4 then
		table.insert(list, where)
	end
end
local count = 0
for _, service in game:GetChildren() do
	for _, inst in service:GetDescendants() do
		count += 1
		for _, prop in PROPS do
			local ok, value = pcall(function()
				return (inst :: any)[prop]
			end)
			if ok and value ~= nil then
				local text = tostring(value)
				for id in string.gmatch(text, "(%d%d%d%d%d+)") do
					if string.find(text, "rbxassetid") or string.find(text, "asset") or string.find(text, "id=") then
						note(id, inst.ClassName .. "." .. prop .. " " .. inst:GetFullName())
					end
				end
			end
		end
	end
end
fs.writeFile(process.args[2], serde.encode("json", found, true))
local n = 0
for _ in found do
	n += 1
end
print(count, "instances,", n, "distinct ids")
