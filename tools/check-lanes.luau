--!strict
-- High Olympus's lane check, without Studio, in each stretch's own frame (x across, y up from the floor, z uphill):
--   * decor (each stretch's Decor) stays out of the slide lane (|x| < 56) unless it's 16 or more studs up;
--   * in the lane (its Lane model) only the dunes (the Ramp attribute) are solid: everything else is passed through;
--   * the dunes never stand on the path (its Path tiles) and keep off the wild lambs' spots and the god's.
-- Only collidable parts lower than 16 studs count. Usage, after scripts/build-place.ps1:
--   lune run tools/check-lanes.luau [StealASheep.rbxl]

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local UpperMountain = require("./UpperMountain")

local CFrame, Vector3 = roblox.CFrame, roblox.Vector3
local LANE_HALF = 56
local CLEAR_ABOVE = 16
local MIDDLE_Z = 193.45 -- UpperMountain's corridor middle
local PATH_HALF = 6 -- half the path's width: nothing solid on it
local SPOT_CLEAR = 6
local CELL = 2
-- Config/Olympus and Utils/Mountain's spots: the pasture from 45% of a tier up to 18 studs short of its top, four
-- lambs between z 154 and 230; the god 22 studs short of the top at z 217.
local LANE_Z = { 140, 244 }

local game = roblox.deserializePlace(fs.readFile(process.args[1] or "StealASheep.rbxl"))
local folder = (game :: any).Workspace.Stages.HighOlympus

-- A part's box in the stretch's frame.
local function bounds(inverse: any, part: any): (number, number, number, number, number)
	local minX, maxX, minY, minZ, maxZ = math.huge, -math.huge, math.huge, math.huge, -math.huge
	local half = part.Size / 2
	for _, dx in { -1, 1 } do
		for _, dy in { -1, 1 } do
			for _, dz in { -1, 1 } do
				local p = inverse * (part.CFrame * Vector3.new(dx * half.X, dy * half.Y, dz * half.Z))
				minX, maxX, minY = math.min(minX, p.X), math.max(maxX, p.X), math.min(minY, p.Y)
				minZ, maxZ = math.min(minZ, p.Z), math.max(maxZ, p.Z)
			end
		end
	end
	return minX, maxX, minY, minZ, maxZ
end

local failures = 0
local function fail(message: string)
	failures += 1
	print(`  {message}`)
end

local total = 0
for _, section in UpperMountain.Layout() do
	local name = `Tier{section.Tier} {section.God}`
	local model = folder:FindFirstChild(name)
	assert(model, `missing {name}`)
	local grade = math.rad(section.Grade)
	local mid = Vector3.new((section.XStart + section.XEnd) / 2, (section.YStart + section.YEnd) / 2, MIDDLE_Z)
	local frame = CFrame.new(mid) * CFrame.fromEulerAnglesYXZ(-grade, math.pi / 2, 0)
	local inverse = frame:Inverse()
	print(name)

	local count = 0
	for _, part in model.Decor:GetDescendants() do
		if part:IsA("BasePart") then
			count += 1
			if part.CanCollide then
				local minX, maxX, minY = bounds(inverse, part)
				if minX < LANE_HALF and maxX > -LANE_HALF and minY < CLEAR_ABOVE then
					fail(
						`decor in the lane: {part.Parent.Name}.{part.Name}, x {minX // 0.1 / 10} to {maxX // 0.1 / 10}`
					)
				end
			end
		end
	end
	total += count

	local lane = model:FindFirstChild("Lane")
	if not lane then
		print(`  {count} decor parts, no lane yet`)
		continue
	end
	-- Solid cells across the lane (x) and along it (z), and the path's centre on each row.
	local length = (section.XEnd - section.XStart) / math.cos(grade)
	local rows = math.ceil(length / CELL)
	local columns = LANE_HALF * 2 / CELL
	local solid: { [number]: { [number]: string } } = {}
	local pathX: { [number]: number } = {}
	local function row(z: number): number
		return math.floor((z + length / 2) / CELL) + 1
	end
	local laneParts = 0
	for _, part in lane:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		laneParts += 1
		if part.Name == "Path" then
			local p = inverse * part.CFrame.Position
			pathX[row(p.Z)] = p.X
		elseif part.CanCollide and not part:GetAttribute("Ramp") then
			fail(`solid but not a ramp: {part.Parent and part.Parent.Name}.{part.Name}`)
		elseif part.CanCollide then
			-- A dune stands above the floor over about 0.3 of its size each way from its middle (UpperMountain's
			-- DUNE_REACH); its box is mostly under the floor.
			local local_ = inverse * part.CFrame
			local yaw = math.atan2(local_.LookVector.X, local_.LookVector.Z)
			local hx = 0.3 * (math.abs(math.cos(yaw)) * part.Size.X + math.abs(math.sin(yaw)) * part.Size.Z)
			local hz = 0.3 * (math.abs(math.sin(yaw)) * part.Size.X + math.abs(math.cos(yaw)) * part.Size.Z)
			local p = local_.Position
			local minX, maxX, minY, minZ, maxZ = p.X - hx, p.X + hx, 0, p.Z - hz, p.Z + hz
			if minY < CLEAR_ABOVE and maxX > -LANE_HALF and minX < LANE_HALF then
				local owner = part.Parent and part.Parent.Name or part.Name
				for r = math.max(1, row(minZ)), math.min(rows, row(maxZ)) do
					solid[r] = solid[r] or {}
					for col = math.max(1, math.floor((minX + LANE_HALF) / CELL) + 1), math.min(columns, math.ceil((maxX + LANE_HALF) / CELL)) do
						solid[r][col] = owner
					end
				end
			end
		end
	end
	total += laneParts

	-- The path's tiles clear.
	local onPath = {}
	for r = 1, rows do
		local cells = solid[r] or {}
		-- The path's tiles are 6 apart: check the rows between from the nearest tile.
		local px = pathX[r] or pathX[r - 1] or pathX[r + 1] or pathX[r - 2] or pathX[r + 2]
		if px then
			for col = math.floor((px - PATH_HALF + LANE_HALF) / CELL) + 1, math.ceil((px + PATH_HALF + LANE_HALF) / CELL) do
				local owner = cells[col]
				if owner and not onPath[owner] then
					onPath[owner] = true
					fail(`on the path: {owner} at z {(r * CELL - length / 2) // 1}`)
				end
			end
		end
	end

	-- Lamb and god spots.
	local spots = {}
	local from = section.XStart + (section.XEnd - section.XStart) * 0.45
	local to = section.XEnd - 18
	for index = 1, 4 do
		local share = (index - 0.5) / 4
		local x = from + (to - from) * (if index % 2 == 0 then 0.35 else 0.75)
		table.insert(spots, Vector3.new(x, 0, LANE_Z[1] + 14 + (LANE_Z[2] - LANE_Z[1] - 28) * share))
	end
	table.insert(spots, Vector3.new(section.XEnd - 22, 0, 217))
	for _, spot in spots do
		local local_ = inverse
			* Vector3.new(spot.X, section.YStart + (spot.X - section.XStart) * math.tan(grade), spot.Z)
		local r0 = row(local_.Z)
		local c0 = math.floor((local_.X + LANE_HALF) / CELL) + 1
		local reach = math.ceil(SPOT_CLEAR / CELL)
		for r = r0 - reach, r0 + reach do
			for col = c0 - reach, c0 + reach do
				local owner = solid[r] and solid[r][col]
				if owner then
					fail(`{owner} within {SPOT_CLEAR} studs of a lamb or god spot`)
					break
				end
			end
		end
	end
	local dunes = 0
	for _, part in lane:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Ramp") then
			dunes += 1
		end
	end
	print(`  {count} decor parts, {laneParts} lane parts, {dunes} dunes`)
end
print(`{total} parts checked, {failures} problems`)
process.exit(if failures > 0 then 1 else 0)
