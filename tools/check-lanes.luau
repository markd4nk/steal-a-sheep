--!strict
-- High Olympus's lane check, without Studio: every collidable decor part in each stretch, in the stretch's own frame
-- (x across, y up from the floor), must stay out of the slide lane (|x| < 56) unless it's 16 or more studs up.
-- Usage, after scripts/build-place.ps1: lune run tools/check-lanes.luau [StealASheep.rbxl]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local UpperMountain = require("./UpperMountain")

local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local LANE_HALF = 56
local CLEAR_ABOVE = 16
local MIDDLE_Z = 193.45 -- UpperMountain's corridor middle

local game = roblox.deserializePlace(fs.readFile(process.args[1] or "StealASheep.rbxl"))
local folder = (game :: any).Workspace.Stages.HighOlympus

local blocked, total = 0, 0
for _, section in UpperMountain.Layout() do
	local model = folder:FindFirstChild(`Tier{section.Tier} {section.God}`)
	assert(model, `missing Tier{section.Tier} {section.God}`)
	local grade = math.rad(section.Grade)
	local mid = Vector3.new((section.XStart + section.XEnd) / 2, (section.YStart + section.YEnd) / 2, MIDDLE_Z)
	local inverse = (CFrame.new(mid) * CFrame.fromEulerAnglesYXZ(-grade, math.pi / 2, 0)):Inverse()
	local count = 0
	for _, part in model.Decor:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		count += 1
		if not part.CanCollide then
			continue
		end
		local minX, maxX, minY = math.huge, -math.huge, math.huge
		local half = part.Size / 2
		for _, dx in { -1, 1 } do
			for _, dy in { -1, 1 } do
				for _, dz in { -1, 1 } do
					local p = inverse * (part.CFrame * Vector3.new(dx * half.X, dy * half.Y, dz * half.Z))
					minX, maxX, minY = math.min(minX, p.X), math.max(maxX, p.X), math.min(minY, p.Y)
				end
			end
		end
		if minX < LANE_HALF and maxX > -LANE_HALF and minY < CLEAR_ABOVE then
			blocked += 1
			print(
				`  in the lane: {part.Parent.Name}.{part.Name}, x {minX // 0.1 / 10} to {maxX // 0.1 / 10}, y {minY // 0.1 / 10}`
			)
		end
	end
	total += count
	print(`Tier{section.Tier} {section.God}: {count} decor parts`)
end
print(`{total} decor parts, {blocked} in the lane`)
process.exit(if blocked > 0 then 1 else 0)
