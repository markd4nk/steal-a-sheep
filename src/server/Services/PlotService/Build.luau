--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Walker = require(script.Parent.Walker)

-- The primitive pieces each plot gets at runtime, in the plot's own frame (its middle, +X towards its gate): twelve
-- pen pads in a 4 x 3 grid, the delivery pad just inside the gate, the stair walker just outside the pen beside the
-- gate with its upgrade sign, and the owner's sign over the gate. Map decor (hay, trees) standing where they go is
-- moved out of the way.
local Build = {}

export type Pieces = {
	Folder: Folder,
	Pads: { BasePart },
	Delivery: BasePart,
	Walker: Walker.Pieces,
	Sign: TextLabel,
	SignIncome: TextLabel,
	Spawn: CFrame,
}

local PAD_SIZE = 8.5
local PAD_GAP = 10.5
local PAD_COLUMNS = 4
local FLOOR_Y = 59.5

-- Offsets from the plot's middle (x along its length, towards the gate; z across).
local PADS_FROM = Vector2.new(-27, -10.5)
local DELIVERY_AT = Vector2.new(44, 0)
-- Outside the front fence (x 53.6), beside the gate (z -15 to 14), climbing towards the pen's corner; the sign stands
-- by its entry, turned to the gate.
local WALKER_AT = Vector2.new(61, 25)
local SIGN_AT = Vector2.new(65.5, 18.5)
local GATE_AT = Vector2.new(54, 0)
local SPAWN_AT = Vector2.new(34, 0)

local PAD_OPEN = Color3.fromRGB(196, 160, 112)
local PAD_LOCKED = Color3.fromRGB(82, 88, 104)

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

function Build.Plot(index: number, model: Model, parent: Instance): (Pieces, CFrame)
	local center, size = model:GetBoundingBox()
	local origin = CFrame.new(center.Position.X, FLOOR_Y, center.Position.Z)
	local folder = Instance.new("Folder")
	folder.Name = `Plot{index}`

	local pads: { BasePart } = {}
	for slot = 1, Economy.MaxPens do
		local column = (slot - 1) % PAD_COLUMNS
		local row = (slot - 1) // PAD_COLUMNS
		local at = origin * CFrame.new(PADS_FROM.X + column * PAD_GAP, 0.15, PADS_FROM.Y + row * PAD_GAP)
		clearDecor(at.Position + Vector3.new(0, 6, 0), Vector3.new(PAD_SIZE / 2, 6, PAD_SIZE / 2))
		local pad = block(folder, `Pad{slot}`, Vector3.new(PAD_SIZE, 0.3, PAD_SIZE), at, PAD_OPEN)
		pad.Material = Enum.Material.Grass
		pad.CanCollide = false
		pad:SetAttribute("Slot", slot)
		local tag = label(pad, Enum.NormalId.Top, tostring(slot), Color3.new(1, 1, 1))
		tag.TextTransparency = 0.5
		table.insert(pads, pad)
	end

	local deliveryAt = origin * CFrame.new(DELIVERY_AT.X, 0.2, DELIVERY_AT.Y)
	clearDecor(deliveryAt.Position + Vector3.new(0, 6, 0), Vector3.new(7, 6, 7))
	local delivery = block(folder, "Delivery", Vector3.new(12, 0.4, 12), deliveryAt, Color3.fromRGB(90, 200, 120))
	delivery.Material = Enum.Material.Neon
	delivery.Transparency = 0.35
	delivery.CanCollide = false
	local deliveryShape = Instance.new("CylinderMesh")
	deliveryShape.Parent = delivery
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	billboard.MaxDistance = 120
	billboard.LightInfluence = 0
	billboard.Parent = delivery
	local deliverWords = Instance.new("TextLabel")
	deliverWords.BackgroundTransparency = 1
	deliverWords.Size = UDim2.fromScale(1, 1)
	deliverWords.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	deliverWords.TextScaled = true
	deliverWords.TextColor3 = Color3.fromRGB(180, 255, 190)
	deliverWords.Text = "DELIVER HERE"
	local deliverStroke = Instance.new("UIStroke")
	deliverStroke.Thickness = 2.5
	deliverStroke.Parent = deliverWords
	deliverWords.Parent = billboard

	-- The machine's frame faces up its stairs (-Z), here towards +Z of the plot.
	local walkerFrame = origin * CFrame.new(WALKER_AT.X, 0, WALKER_AT.Y) * CFrame.Angles(0, math.pi, 0)
	clearDecor(walkerFrame:PointToWorldSpace(Vector3.new(0, 6, 0.6)), Vector3.new(4, 6, 6.5))
	local signSpot = origin:PointToWorldSpace(Vector3.new(SIGN_AT.X, 0, SIGN_AT.Y))
	local gate = origin:PointToWorldSpace(Vector3.new(GATE_AT.X, 0, GATE_AT.Y))
	clearDecor(signSpot + Vector3.new(0, 4, 0), Vector3.new(2.5, 4, 2.5))
	local walker = Walker.Build(folder, walkerFrame, CFrame.lookAt(signSpot, Vector3.new(gate.X, signSpot.Y, gate.Z)))

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
		Pads = pads,
		Delivery = delivery,
		Walker = walker,
		Sign = signName,
		SignIncome = signIncome,
		Spawn = spawn,
	},
		origin
end

-- Pads past the owner's slot count show a padlock and the next one's price.
function Build.PaintPads(pads: { BasePart }, unlocked: number)
	for slot, pad in pads do
		local open = slot <= unlocked
		pad.Color = if open then PAD_OPEN else PAD_LOCKED
		pad.Material = if open then Enum.Material.Grass else Enum.Material.Slate
		local gui = pad:FindFirstChildOfClass("SurfaceGui")
		local words = gui and gui:FindFirstChild("Label")
		if words and words:IsA("TextLabel") then
			if open then
				words.Text = tostring(slot)
			elseif slot == unlocked + 1 then
				local cost = Economy.PenCost(slot)
				words.Text = if cost then `🔒 {Format.Short(cost)}` else "🔒"
			else
				words.Text = "🔒"
			end
		end
	end
end

return table.freeze(Build)
