--!strict
-- The trailer's and thumbnail's summit lineup (trailer/stealasheep.md, shot 9): all thirty avatar gods on marble risers
-- on Zeus's plaza, Zeus front and centre with his bolt raised, every god idling. Run with execute_luau on the Client
-- during a playtest (GodService builds the gods a few seconds after the server starts). This device only: it destroys
-- and rebuilds workspace.TEMP_TrailerSummit with copies of the gods, and hides the real ones on this screen.
-- Returns the camera points for a slow glide along the rows.

local RunService = game:GetService("RunService")

local FLOOR = 4439.08
local MIDDLE_Z = 193.45
local ROWS = {
	{ X = 6751, Rise = 0, Gods = { "Athena", "Apollo", "Demeter", "Poseidon", "Zeus", "Hera", "Hestia", "Artemis", "Ares" } },
	{
		X = 6758,
		Rise = 5,
		Gods = { "Thanatos", "Nemesis", "Dionysus", "Hermes", "Hephaestus", "Aphrodite", "Hypnos", "Morpheus", "Deimos", "Aeolus" },
	},
	{
		X = 6765,
		Rise = 10,
		Gods = { "Pan", "Tyche", "Hecate", "Phobos", "Eris", "Eros", "Hebe", "Themis", "Asclepius", "Iris", "Nike" },
	},
}
local SPACING = 7.6
local IDLE = "rbxassetid://507766388"
local MARBLE = Color3.fromRGB(242, 238, 236)
local GOLD = Color3.fromRGB(232, 192, 76)

local old = workspace:FindFirstChild("TEMP_TrailerSummit")
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = "TEMP_TrailerSummit"
folder.Parent = workspace

local function block(cframe: CFrame, size: Vector3, color: Color3, material: Enum.Material?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
end
block(CFrame.new(6759, FLOOR + 2.5, MIDDLE_Z), Vector3.new(7, 5, 86), MARBLE)
block(CFrame.new(6755.6, FLOOR + 4.9, MIDDLE_Z), Vector3.new(0.4, 0.4, 86), GOLD, Enum.Material.Neon)
block(CFrame.new(6766, FLOOR + 5, MIDDLE_Z), Vector3.new(7, 10, 92), MARBLE)
block(CFrame.new(6762.6, FLOOR + 9.9, MIDDLE_Z), Vector3.new(0.4, 0.4, 92), GOLD, Enum.Material.Neon)

-- The real gods stand elsewhere on the mountain; only Zeus is on the plaza, so hide him here.
local real = workspace:WaitForChild("Gods"):FindFirstChild("Zeus")
if real then
	for _, part in real:GetDescendants() do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 1
		elseif part:IsA("Decal") then
			part.Transparency = 1
		elseif part:IsA("BillboardGui") then
			part.Enabled = false
		end
	end
end

local raised: { Model } = {}
for rowIndex, row in ROWS do
	local count = #row.Gods
	for index, name in row.Gods do
		local source = workspace.Gods:FindFirstChild(name)
		if not source then
			continue
		end
		source.Archivable = true
		local copy = source:Clone()
		for _, item in copy:GetDescendants() do
			if
				item:IsA("BillboardGui")
				or item:IsA("AlignPosition")
				or item:IsA("AlignOrientation")
			then
				item:Destroy()
			elseif item:IsA("BasePart") then
				item.LocalTransparencyModifier = 0
			elseif item:IsA("Decal") then
				item.Transparency = 0
			end
		end
		local root = copy.PrimaryPart :: BasePart
		root.Anchored = true
		local humanoid = copy:FindFirstChildOfClass("Humanoid") :: Humanoid
		local hip = humanoid.HipHeight + root.Size.Y / 2
		local z = MIDDLE_Z + (index - (count + 1) / 2) * SPACING
		local facing = (Vector3.new(6700, 0, MIDDLE_Z) - Vector3.new(row.X, 0, z)).Unit
		copy:PivotTo(CFrame.lookAlong(Vector3.new(row.X, FLOOR + row.Rise + hip, z), facing))
		copy.Name = "Trailer" .. name
		copy.Parent = folder
		local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator
		local animation = Instance.new("Animation")
		animation.AnimationId = IDLE
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play(0)
		task.defer(function()
			while track.Length == 0 do
				task.wait()
			end
			track.TimePosition = ((index * 0.137 + rowIndex * 0.31) % 1) * track.Length
		end)
		if name == "Zeus" then
			table.insert(raised, copy)
		end
	end
end
local connection = RunService.PreSimulation:Connect(function()
	if not folder.Parent then
		return
	end
	for _, model in raised do
		local upper = model:FindFirstChild("RightUpperArm")
		local shoulder = upper and upper:FindFirstChild("RightShoulder")
		if shoulder and shoulder:IsA("AnimationConstraint") then
			shoulder.Transform = CFrame.Angles(math.rad(165), 0, 0)
		end
	end
end)
folder.Destroying:Connect(function()
	connection:Disconnect()
end)

return "glide from (6716, 4447, 222) to (6706, 4448.5, 193.45), looking at (6760, 4448, 193.45)"
