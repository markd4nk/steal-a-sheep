--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)

-- The primitive pieces each plot gets at runtime, in the plot's own frame (its middle, +X towards its gate): the pen
-- (an invisible box filling the fence, where the owner's sheep live and where a stolen lamb is put down), the stair
-- walker by the back fence with a keep-out box round it for the sheep, and the owner's sign over the gate. Map decor
-- (hay, trees) standing where the walker goes is moved out of the way; the rest stays, and the sheep walk round it.
local Build = {}

export type Pieces = {
	Folder: Folder,
	Pen: BasePart,
	Keepouts: { BasePart },
	Walker: Model,
	WalkerZone: BasePart,
	WalkerScreen: TextLabel,
	Steps: { BasePart },
	Sign: TextLabel,
	SignIncome: TextLabel,
	Spawn: CFrame,
}

local FLOOR_Y = 59.5
local PEN_HEIGHT = 14
local FENCE_INSET = 1 -- studs from the fence posts' outer faces to the pen's edge

-- Offsets from the plot's middle (x along its length, towards the gate; z across).
local WALKER_AT = Vector2.new(20, 25)
local SPAWN_AT = Vector2.new(34, 0)

local function block(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function label(face: BasePart, side: Enum.NormalId, text: string, color: Color3): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = side
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = face
	local words = Instance.new("TextLabel")
	words.Name = "Label"
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromScale(1, 1)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = color
	words.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(20, 22, 30)
	stroke.Parent = words
	words.Parent = gui
	return words
end

-- Hides map decor (a model or part under Decors or Base.Foliages) whose footprint overlaps a box, by moving it to
-- ServerStorage.ClearedDecor; nothing is destroyed.
local function clearDecor(center: Vector3, half: Vector3)
	local store = ServerStorage:FindFirstChild("ClearedDecor")
	if not store then
		local created = Instance.new("Folder")
		created.Name = "ClearedDecor"
		created.Parent = ServerStorage
		store = created
	end
	-- The map keeps its props in categories (Decors.HayStacks, Base.Foliages.Trees ...): a prop is a category's child.
	local categories: { Instance } = {}
	local base = workspace:FindFirstChild("Base")
	for _, holder in { workspace:FindFirstChild("Decors"), base and base:FindFirstChild("Foliages") } do
		if holder then
			for _, category in holder:GetChildren() do
				table.insert(categories, category)
			end
		end
	end
	local hay = base and base:FindFirstChild("HayStacks")
	if hay then
		table.insert(categories, hay)
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = categories
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(center), half * 2, params) do
		local prop: Instance? = part
		while prop and prop.Parent and not table.find(categories, prop.Parent) do
			prop = prop.Parent
		end
		if prop and prop.Parent then
			prop.Parent = store
		end
	end
end

-- The plot's fence lines along the world's axes: the smallest and largest x and z its parts reach.
local function fenceBox(model: Model): (Vector3, Vector3)
	local low = Vector3.one * math.huge
	local high = -low
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local cframe, half = part.CFrame, part.Size / 2
			local reach = Vector3.new(
				math.abs(cframe.XVector.X) * half.X
					+ math.abs(cframe.YVector.X) * half.Y
					+ math.abs(cframe.ZVector.X) * half.Z,
				0,
				math.abs(cframe.XVector.Z) * half.X
					+ math.abs(cframe.YVector.Z) * half.Y
					+ math.abs(cframe.ZVector.Z) * half.Z
			)
			low = low:Min(part.Position - reach)
			high = high:Max(part.Position + reach)
		end
	end
	return low, high
end

local function invisible(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
end

local function makeWalker(parent: Instance, origin: CFrame): (Model, BasePart, TextLabel, { BasePart })
	local walker = Instance.new("Model")
	walker.Name = "StairWalker"
	local base =
		block(walker, "Base", Vector3.new(10, 1, 9), origin * CFrame.new(0, 0.5, 0), Color3.fromRGB(70, 76, 92))
	base.Material = Enum.Material.Metal
	walker.PrimaryPart = base
	-- The steps run up towards the back fence (+Z of its frame); they only show, the player stands on the base.
	local steps: { BasePart } = {}
	for index = 1, 5 do
		local step = block(
			walker,
			`Step{index}`,
			Vector3.new(6, 0.6, 1.4),
			origin * CFrame.new(0, 1 + index * 0.6, 0.8 + index * 0.9),
			Color3.fromRGB(230, 214, 170)
		)
		step.CanCollide = false
		step.Material = Enum.Material.WoodPlanks
		table.insert(steps, step)
	end
	for _, side in { -1, 1 } do
		local rail = block(
			walker,
			"Rail",
			Vector3.new(0.4, 0.4, 7.5),
			origin * CFrame.new(side * 3.6, 4.6, 1.2) * CFrame.Angles(math.rad(-15), 0, 0),
			Color3.fromRGB(255, 196, 64)
		)
		rail.Material = Enum.Material.Metal
		local post = block(
			walker,
			"Post",
			Vector3.new(0.5, 4, 0.5),
			origin * CFrame.new(side * 3.6, 2.8, -2.4),
			Color3.fromRGB(255, 196, 64)
		)
		post.Material = Enum.Material.Metal
	end
	local screen =
		block(walker, "Screen", Vector3.new(5, 2.4, 0.4), origin * CFrame.new(0, 6.6, 5.4), Color3.fromRGB(30, 34, 46))
	local words = label(screen, Enum.NormalId.Front, "STAIR WALKER", Color3.fromRGB(255, 226, 120))
	local zone = block(walker, "Zone", Vector3.new(6, 7, 5), origin * CFrame.new(0, 4.5, -1.5), Color3.new(1, 1, 1))
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	walker.Parent = parent
	return walker, zone, words, steps
end

function Build.Plot(index: number, model: Model, parent: Instance): (Pieces, CFrame)
	local center, size = model:GetBoundingBox()
	local origin = CFrame.new(center.Position.X, FLOOR_Y, center.Position.Z)
	local folder = Instance.new("Folder")
	folder.Name = `Plot{index}`

	-- The pen fills the fence; clients read it too (am I home with a lamb, where's home).
	local low, high = fenceBox(model)
	local pen = block(
		folder,
		"Pen",
		Vector3.new(high.X - low.X - 2 * FENCE_INSET, PEN_HEIGHT, high.Z - low.Z - 2 * FENCE_INSET),
		CFrame.new((low.X + high.X) / 2, FLOOR_Y + PEN_HEIGHT / 2, (low.Z + high.Z) / 2),
		Color3.new(1, 1, 1)
	)
	invisible(pen)

	local walkerOrigin = origin * CFrame.new(WALKER_AT.X, 0, WALKER_AT.Y)
	clearDecor(walkerOrigin.Position + Vector3.new(0, 6, 2), Vector3.new(6, 6, 7))
	local walker, zone, screen, steps = makeWalker(folder, walkerOrigin)
	-- Sheep keep off the machine, its steps and its screen.
	local keepout =
		block(folder, "Keepout", Vector3.new(12, 8, 13), walkerOrigin * CFrame.new(0, 4, 1.5), Color3.new(1, 1, 1))
	invisible(keepout)

	-- The owner's name over the gate.
	local gateTop = origin * CFrame.new(size.X / 2 - 1, 38, 0)
	local signAnchor = block(folder, "SignAnchor", Vector3.new(1, 1, 1), gateTop, Color3.new(1, 1, 1))
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false
	signAnchor.CanQuery = false
	local sign = Instance.new("BillboardGui")
	sign.Size = UDim2.fromOffset(320, 90)
	sign.MaxDistance = 300
	sign.LightInfluence = 0
	sign.Parent = signAnchor
	local signList = Instance.new("UIListLayout")
	signList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	signList.Parent = sign
	local function signLine(text: string, height: number, color: Color3): TextLabel
		local line = Instance.new("TextLabel")
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1, 0, 0, height)
		line.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		line.TextScaled = true
		line.TextColor3 = color
		line.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Parent = line
		line.Parent = sign
		return line
	end
	local signName = signLine("Empty plot", 50, Color3.new(1, 1, 1))
	local signIncome = signLine("", 36, Color3.fromRGB(190, 255, 90))

	folder.Parent = parent
	local spawn = origin * CFrame.new(SPAWN_AT.X, 4, SPAWN_AT.Y) * CFrame.Angles(0, math.rad(-90), 0)
	return {
		Folder = folder,
		Pen = pen,
		Keepouts = { keepout },
		Walker = walker,
		WalkerZone = zone,
		WalkerScreen = screen,
		Steps = steps,
		Sign = signName,
		SignIncome = signIncome,
		Spawn = spawn,
	},
		origin
end

-- The machine's accent shows its level: a colour along a ramp from wood to gold.
function Build.PaintWalker(walker: Model, level: number)
	local share = level / Economy.MaxWalker
	local accent = Color3.fromRGB(230, 214, 170):Lerp(Color3.fromRGB(255, 180, 30), share)
	for _, child in walker:GetChildren() do
		if child:IsA("BasePart") and string.match(child.Name, "^Step") then
			child.Color = accent
			child.Material = if level >= 6 then Enum.Material.Neon else Enum.Material.WoodPlanks
		end
	end
end

return table.freeze(Build)
