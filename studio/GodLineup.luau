--!strict
-- Lines the avatar gods up on Zeus's summit plaza for a review screenshot. Run with execute_luau on the Server during
-- a playtest (GodService builds the gods a few seconds after the server starts). FIRST and COUNT pick the tiers: it
-- destroys and rebuilds workspace.TEMP_GodLineup with copies of those gods in a row facing -X (downhill), their
-- nameplates on, standing still in their rest pose. Shoot from about 40 studs down the plaza (the return value says
-- where), with the HUD hidden on the client.

local FIRST = 1
local COUNT = 5
local SPACING = 9

local old = workspace:FindFirstChild("TEMP_GodLineup")
if old then
	old:Destroy()
end
local plaza = workspace.Stages.HighOlympus.Summit.Plaza :: BasePart
local floorY = plaza.Position.Y + plaza.Size.Y / 2
local folder = Instance.new("Folder")
folder.Name = "TEMP_GodLineup"
folder.Parent = workspace
local gods = workspace:WaitForChild("Gods")
local x = plaza.Position.X - 30
local placed = {}
for index = 0, COUNT - 1 do
	local tier = FIRST + index
	local source: Model? = nil
	for _, god in gods:GetChildren() do
		if god:IsA("Model") and god:GetAttribute("Tier") == tier then
			source = god
		end
	end
	if not source then
		continue
	end
	local copy = source:Clone()
	for _, item in copy:GetDescendants() do
		if item:IsA("AlignPosition") or item:IsA("AlignOrientation") then
			item:Destroy()
		end
	end
	local root = copy.PrimaryPart :: BasePart
	root.Anchored = true
	local humanoid = copy:FindFirstChildOfClass("Humanoid")
	local hip = if humanoid then humanoid.HipHeight + root.Size.Y / 2 else 4.8
	local z = plaza.Position.Z + (index - (COUNT - 1) / 2) * SPACING
	copy:PivotTo(CFrame.lookAlong(Vector3.new(x, floorY + hip, z), Vector3.new(-1, 0, 0)))
	copy.Parent = folder
	table.insert(placed, `{tier} {copy.Name}`)
end
return `{table.concat(placed, ", ")}; camera {x - 40}, {floorY + 7}, {plaza.Position.Z} looking at {x}, {floorY + 5}, {plaza.Position.Z}`
