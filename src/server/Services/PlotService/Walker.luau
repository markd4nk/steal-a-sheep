--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local StairClimb = require(ReplicatedStorage.Utils.StairClimb)

-- The stair walker machine outside a pen and the upgrade sign beside it. Built in machine space (Utils/StairClimb):
-- the model's pivot is the machine's frame, -Z up the stairs. Each level has a look (the last one carries on above
-- it); the steps are left where they were built, and each client runs them (WalkerController).
local Walker = {}

type Paint = { Color: Color3, Material: Enum.Material }
type Look = {
	Body: Paint,
	Base: Paint,
	Top: Paint, -- the strip along each side's top edge
	Hood: Paint, -- the strip round the hood
	Panel: Paint?, -- a band down each side
	Glow: Color3?, -- a neon line under the top strip, and the screen's frame
	Under: Color3?, -- neon under the base
	Tread: Paint,
	Nose: Paint,
	Riser: Paint,
	Rail: Paint,
	Grip: Paint,
	Post: Paint,
	Head: Paint,
	Screen: Color3,
	Text: Color3,
	HeadSize: Vector2,
	Trim: Paint?, -- the entry step's edge
	Fan: boolean?,
	Vents: boolean?,
	Torches: boolean?,
	Laurel: boolean?,
}

export type Pieces = {
	Model: Model,
	Zone: BasePart,
	Steps: { { BasePart } },
	Body: Folder,
	Tag: TextLabel,
	Screen: TextLabel,
	Sign: Model,
	SignLines: { { TextLabel } }, -- the board's front, then its back
	CoinPrompt: ProximityPrompt,
	RobuxPrompt: ProximityPrompt,
	Look: number,
}

local SP, METAL, NEON, PLATE =
	Enum.Material.SmoothPlastic, Enum.Material.Metal, Enum.Material.Neon, Enum.Material.DiamondPlate

local function paint(r: number, g: number, b: number, material: Enum.Material?): Paint
	return { Color = Color3.fromRGB(r, g, b), Material = material or SP }
end

local WHITE = paint(246, 243, 236)
local GOLD = paint(240, 186, 60, METAL)

-- Starter, Sport, Pro, Turbo, Champion (the user's pick, 2026-10-05).
local LOOKS: { Look } = {
	{
		Body = paint(206, 210, 216),
		Base = paint(78, 82, 92),
		Top = paint(150, 156, 166),
		Hood = paint(150, 156, 166),
		Tread = paint(56, 60, 68),
		Nose = paint(140, 146, 156),
		Riser = paint(78, 82, 92),
		Rail = paint(96, 100, 110, METAL),
		Grip = paint(36, 38, 44),
		Post = paint(78, 82, 92),
		Head = paint(64, 68, 78),
		Screen = Color3.fromRGB(30, 34, 42),
		Text = Color3.fromRGB(230, 232, 236),
		HeadSize = Vector2.new(2.4, 1.1),
	},
	{
		Body = paint(244, 246, 250),
		Base = paint(60, 66, 80),
		Top = paint(40, 120, 255),
		Hood = paint(40, 120, 255),
		Panel = paint(40, 120, 255),
		Tread = paint(48, 52, 62),
		Nose = paint(255, 204, 40),
		Riser = paint(60, 66, 80),
		Rail = paint(200, 206, 214, METAL),
		Grip = paint(40, 120, 255),
		Post = paint(60, 66, 80),
		Head = paint(50, 56, 70),
		Screen = Color3.fromRGB(18, 28, 50),
		Text = Color3.fromRGB(120, 190, 255),
		HeadSize = Vector2.new(3, 1.35),
	},
	{
		Body = paint(58, 60, 68),
		Base = paint(34, 36, 42),
		Top = paint(225, 40, 52),
		Hood = paint(225, 40, 52),
		Panel = paint(225, 40, 52),
		Glow = Color3.fromRGB(255, 70, 80),
		Tread = paint(40, 42, 48),
		Nose = paint(255, 70, 80),
		Riser = paint(34, 36, 42),
		Rail = paint(225, 230, 236, METAL),
		Grip = paint(225, 40, 52),
		Post = paint(44, 46, 54),
		Head = paint(34, 36, 42),
		Screen = Color3.fromRGB(16, 18, 24),
		Text = Color3.fromRGB(255, 130, 130),
		HeadSize = Vector2.new(3.4, 1.6),
		Fan = true,
	},
	{
		Body = paint(26, 28, 34),
		Base = paint(18, 20, 24),
		Top = paint(40, 230, 255, NEON),
		Hood = paint(40, 230, 255, NEON),
		Panel = paint(70, 60, 140),
		Glow = Color3.fromRGB(40, 230, 255),
		Under = Color3.fromRGB(40, 230, 255),
		Tread = paint(60, 64, 72, PLATE),
		Nose = paint(40, 230, 255, NEON),
		Riser = paint(20, 22, 28),
		Rail = paint(30, 32, 38, METAL),
		Grip = paint(40, 230, 255),
		Post = paint(22, 24, 30),
		Head = paint(18, 20, 24),
		Screen = Color3.fromRGB(8, 12, 20),
		Text = Color3.fromRGB(90, 240, 255),
		HeadSize = Vector2.new(3.6, 1.7),
		Fan = true,
		Vents = true,
	},
	{
		-- Bronze and dark gold read as plain orange and yellow under the map's colour correction: white and gold.
		Body = WHITE,
		Base = paint(60, 52, 50),
		Top = WHITE,
		Hood = GOLD,
		Panel = paint(30, 28, 34),
		Glow = Color3.fromRGB(255, 190, 80),
		Tread = paint(64, 62, 66, PLATE),
		Nose = paint(255, 236, 160, NEON),
		Riser = paint(60, 52, 50),
		Rail = GOLD,
		Grip = paint(28, 26, 30),
		Post = paint(28, 24, 24),
		Head = paint(60, 52, 50),
		Screen = Color3.fromRGB(20, 14, 10),
		Text = Color3.fromRGB(255, 200, 110),
		HeadSize = Vector2.new(3.6, 1.7),
		Trim = GOLD,
		Vents = true,
		Torches = true,
		Laurel = true,
	},
}

local W, H, D = StairClimb.Width, StairClimb.Rise, StairClimb.Run
local P = StairClimb.Tread
local SLOPE = math.atan2(H, D)
local Z_BACK = P(StairClimb.Lowest - 0.6).Z
local Z_FRONT = P(StairClimb.Highest + 0.4).Z
local LENGTH = Z_BACK - Z_FRONT
local Z_MID = (Z_BACK + Z_FRONT) / 2
local POST_Z = Z_FRONT - 0.9
local HEAD_Y = 7
-- A torch's cartoon flame: three glowing balls, smaller and paler going up.
local FLAMES: { { Size: number, Up: number, Color: Color3 } } = {
	{ Size = 1.25, Up = 0.35, Color = Color3.fromRGB(255, 110, 30) },
	{ Size = 0.95, Up = 0.85, Color = Color3.fromRGB(255, 160, 40) },
	{ Size = 0.6, Up = 1.3, Color = Color3.fromRGB(255, 230, 110) },
}

local function part(parent: Instance, size: Vector3, cframe: CFrame, look: Paint, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cframe
	p.Color = look.Color
	p.Material = look.Material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function solid(p: BasePart): BasePart
	p.CanCollide = true
	p.CanQuery = true
	return p
end

local function neon(color: Color3): Paint
	return { Color = color, Material = NEON }
end

-- A round bar between two machine-space points.
local function bar(parent: Instance, frame: CFrame, a: Vector3, b: Vector3, thick: number, look: Paint)
	local wa, wb = frame:PointToWorldSpace(a), frame:PointToWorldSpace(b)
	local cframe = CFrame.lookAt((wa + wb) / 2, wb) * CFrame.Angles(0, math.rad(90), 0)
	part(parent, Vector3.new((wb - wa).Magnitude, thick, thick), cframe, look, Enum.PartType.Cylinder)
end

-- A strip lying along the stairs' slope, centred on the machine-space point `at`.
local function sloped(parent: Instance, frame: CFrame, size: Vector3, at: Vector3, look: Paint): Part
	return part(parent, size, frame * CFrame.new(at) * CFrame.Angles(SLOPE, 0, 0), look)
end

local function words(parent: Instance, lines: { { Text: string, Height: number, Color: Color3 } }): { TextLabel }
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = parent
	local labels: { TextLabel } = {}
	for index, line in lines do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = index
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(0.92, line.Height)
		label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		label.TextScaled = true
		label.TextColor3 = line.Color
		label.Text = line.Text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(20, 22, 30)
		stroke.Parent = label
		label.Parent = parent
		table.insert(labels, label)
	end
	return labels
end

local function surface(face: BasePart, side: Enum.NormalId, pixels: number): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Face = side
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixels
	gui.LightInfluence = 0
	gui.Parent = face
	return gui
end

-- The machine's body in a look: everything but the steps. Returns the screen's text.
local function body(folder: Folder, frame: CFrame, look: Look): TextLabel
	local function at(x: number, y: number, z: number): CFrame
		return frame * CFrame.new(x, y, z)
	end
	local lift = if look.Under then 0.1 else 0
	if look.Under then
		part(folder, Vector3.new(W + 2.5, 0.1, LENGTH + 2.9), at(0, 0.05, Z_MID - 0.6), neon(look.Under))
	end
	solid(part(folder, Vector3.new(W + 2.2, 0.35, LENGTH + 2.6), at(0, lift + 0.175, Z_MID - 0.6), look.Base))
	local yLow = P(StairClimb.Lowest - 0.6).Y + 0.45
	local yHigh = P(StairClimb.Highest + 0.4).Y + 0.45
	for _, side in { -1, 1 } do
		local x = side * (W / 2 + 0.35)
		solid(part(folder, Vector3.new(0.7, yLow - 0.35, LENGTH), at(x, 0.35 + (yLow - 0.35) / 2, Z_MID), look.Body))
		local wedge = Instance.new("WedgePart")
		wedge.Anchored = true
		wedge.CanTouch = false
		wedge.Size = Vector3.new(0.7, yHigh - yLow, LENGTH)
		-- A wedge rises towards its +Z; turned round, it rises with the stairs.
		wedge.CFrame = at(x, yLow + (yHigh - yLow) / 2, Z_MID) * CFrame.Angles(0, math.pi, 0)
		wedge.Color = look.Body.Color
		wedge.Material = look.Body.Material
		wedge.Parent = folder
		local a = P(StairClimb.Lowest - 0.6) + Vector3.new(x, 0.45, 0)
		local b = P(StairClimb.Highest + 0.4) + Vector3.new(x, 0.45, 0)
		sloped(folder, frame, Vector3.new(0.78, 0.22, (b - a).Magnitude), (a + b) / 2, look.Top)
		local outside = side * (W / 2 + 0.73)
		if look.Glow then
			local middle = (a + b) / 2
			local glow = Vector3.new(0.06, 0.12, (b - a).Magnitude * 0.96)
			sloped(folder, frame, glow, Vector3.new(outside, middle.Y - 0.3, middle.Z), neon(look.Glow))
		end
		if look.Panel then
			local pa = P(-0.8) + Vector3.new(outside, -0.3, 0)
			local pb = P(3.3) + Vector3.new(outside, -0.3, 0)
			sloped(folder, frame, Vector3.new(0.06, 0.8, (pb - pa).Magnitude), (pa + pb) / 2, look.Panel)
		end
		if look.Vents then
			for k = 0, 2 do
				part(folder, Vector3.new(0.07, 0.14, 1.5), at(outside, 1 + k * 0.32, Z_FRONT + 1.3), paint(10, 10, 12))
			end
		end
	end
	-- The entry step (walk-through: the owner snaps on as they reach it) and the hood the steps run into.
	local entryTop = P(StairClimb.Lowest).Y - 0.05
	part(
		folder,
		Vector3.new(W + 1.4, entryTop - 0.35, 1.3),
		at(0, 0.35 + (entryTop - 0.35) / 2, Z_BACK + 0.65),
		look.Base
	)
	if look.Trim then
		part(folder, Vector3.new(W + 1.46, 0.12, 1.36), at(0, entryTop - 0.04, Z_BACK + 0.65), look.Trim)
	end
	local hoodZ = P(StairClimb.Highest + 0.2).Z - 0.35
	solid(part(folder, Vector3.new(W + 1.4, 1.5, 1.6), at(0, P(StairClimb.Highest).Y + 0.55, hoodZ), look.Body))
	part(folder, Vector3.new(W + 1.45, 0.24, 1.65), at(0, P(StairClimb.Highest).Y + 1.25, hoodZ), look.Hood)
	-- The console: a post, a tilted head with the screen, and the level's extras.
	local post = Vector3.new(1.5, HEAD_Y - 1, 1)
	solid(part(folder, post, at(0, 0.35 + (HEAD_Y - 1.35) / 2, POST_Z) * CFrame.Angles(math.rad(-8), 0, 0), look.Post))
	local size = look.HeadSize
	local head = at(0, HEAD_Y - 0.4, POST_Z + 0.75) * CFrame.Angles(math.rad(-28), 0, 0)
	solid(part(folder, Vector3.new(size.X, size.Y, 0.5), head, look.Head))
	local rim = if look.Glow then neon(look.Glow) else look.Top
	part(folder, Vector3.new(size.X + 0.16, size.Y + 0.16, 0.4), head * CFrame.new(0, 0, -0.05), rim)
	local face = part(folder, Vector3.new(size.X - 0.45, size.Y - 0.35, 0.1), head * CFrame.new(0, 0, 0.26), {
		Color = look.Screen,
		Material = SP,
	})
	-- The screen faces the climber, behind the head (+Z).
	local screen = words(surface(face, Enum.NormalId.Back, 60), {
		{ Text = "STAIR WALKER", Height = 0.4, Color = look.Text },
		{ Text = "LV 1", Height = 0.5, Color = look.Text },
	})[2]
	if look.Fan then
		local fan = at(0, 5.95, POST_Z + 0.3) * CFrame.Angles(0, math.rad(90), 0)
		local glow = if look.Glow then neon(look.Glow) else look.Top
		part(folder, Vector3.new(0.14, 1, 1), fan, look.Head, Enum.PartType.Cylinder)
		part(folder, Vector3.new(0.16, 0.8, 0.8), fan * CFrame.new(-0.02, 0, 0), glow, Enum.PartType.Cylinder)
		part(folder, Vector3.new(0.18, 0.62, 0.62), fan * CFrame.new(-0.04, 0, 0), look.Head, Enum.PartType.Cylinder)
		for k = 0, 2 do
			local blade = fan * CFrame.new(-0.07, 0, 0) * CFrame.Angles(math.rad(k * 120 + 15), 0, 0)
			part(folder, Vector3.new(0.05, 0.56, 0.16), blade, paint(150, 154, 162, METAL))
		end
	end
	if look.Torches then
		for _, side in { -1, 1 } do
			local x = side * 2.35
			local pole = at(x, 3.45, POST_Z + 0.2) * CFrame.Angles(0, 0, math.rad(90))
			part(folder, Vector3.new(6.2, 0.35, 0.35), pole, GOLD, Enum.PartType.Cylinder)
			part(
				folder,
				Vector3.new(0.3, 0.9, 0.9),
				at(x, 0.5, POST_Z + 0.2) * CFrame.Angles(0, 0, math.rad(90)),
				GOLD,
				Enum.PartType.Cylinder
			)
			local bowl = part(
				folder,
				Vector3.new(0.45, 1, 1),
				at(x, 6.65, POST_Z + 0.2) * CFrame.Angles(0, 0, math.rad(90)),
				GOLD,
				Enum.PartType.Cylinder
			)
			local top = bowl.Position + Vector3.new(0, 0.25, 0)
			for _, flame in FLAMES do
				local ball = part(
					folder,
					Vector3.one * flame.Size,
					CFrame.new(top + Vector3.new(0, flame.Up, 0)),
					neon(flame.Color),
					Enum.PartType.Ball
				)
				ball.CastShadow = false
			end
			local fire = Instance.new("Fire")
			fire.Size = 2.6
			fire.Heat = 7
			fire.Color = Color3.fromRGB(255, 140, 40)
			fire.SecondaryColor = Color3.fromRGB(255, 220, 90)
			fire.Parent = bowl
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 200, 120)
			light.Range = 10
			light.Brightness = 1.5
			light.Parent = bowl
		end
	end
	if look.Laurel then
		-- An open wreath of green leaves round a gold disc, above the screen.
		local centre = head * CFrame.new(0, size.Y / 2 + 0.85, 0)
		for branch = -1, 1, 2 do
			for k = 0, 7 do
				local theta = math.rad(270 + branch * (18 + k * 17))
				local leaf = centre
					* CFrame.new(0.8 * math.cos(theta), 0.8 * math.sin(theta), 0)
					* CFrame.Angles(0, 0, theta + math.rad(90) + branch * math.rad(35))
				part(folder, Vector3.new(0.55, 0.22, 0.1), leaf, paint(96, 168, 70))
			end
		end
		part(
			folder,
			Vector3.new(0.14, 0.75, 0.75),
			centre * CFrame.Angles(0, math.rad(90), 0),
			GOLD,
			Enum.PartType.Cylinder
		)
	end
	-- Rails at hand height down both sides, a post into the body at the back, joined to the console at the front.
	for _, side in { -1, 1 } do
		local x = side * (W / 2 + 0.55)
		local back = P(-1.1) + Vector3.new(x, 2.35, 0)
		local front = P(StairClimb.Highest + 0.3) + Vector3.new(x, 2.35, 0)
		bar(folder, frame, back, front, 0.32, look.Rail)
		bar(folder, frame, back, Vector3.new(x, P(-1.1).Y + 0.4, back.Z), 0.32, look.Rail)
		bar(folder, frame, front, Vector3.new(x * 0.55, front.Y + 0.2, POST_Z + 0.2), 0.32, look.Rail)
		bar(folder, frame, P(-0.2) + Vector3.new(x, 2.35, 0), P(1.6) + Vector3.new(x, 2.35, 0), 0.42, look.Grip)
	end
	return screen
end

local function paintSteps(steps: { { BasePart } }, look: Look)
	for _, step in steps do
		for index, paintOf in { look.Tread, look.Nose, look.Riser } do
			step[index].Color = paintOf.Color
			step[index].Material = paintOf.Material
		end
	end
end

local function prompt(anchor: BasePart, name: string, key: Enum.KeyCode, pad: Enum.KeyCode): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ActionText = "Upgrade"
	p.KeyboardKeyCode = key
	p.GamepadKeyCode = pad
	p.MaxActivationDistance = 10
	p.RequiresLineOfSight = false
	p.Enabled = false
	p.Parent = anchor
	return p
end

-- Builds the machine (pivot `frame`) and its upgrade sign (pivot `signAt`, facing the way players come) in `parent`.
function Walker.Build(parent: Instance, frame: CFrame, signAt: CFrame): Pieces
	local model = Instance.new("Model")
	model.Name = "StairWalker"
	local root = part(model, Vector3.one, frame, paint(255, 255, 255))
	root.Name = "Root"
	root.Transparency = 1
	model.PrimaryPart = root

	local folder = Instance.new("Folder")
	folder.Name = "Body"
	folder.Parent = model
	local look = LOOKS[1]
	local screen = body(folder, frame, look)

	local stepsFolder = Instance.new("Folder")
	stepsFolder.Name = "Steps"
	stepsFolder.Parent = model
	local steps: { { BasePart } } = {}
	for index = 1, StairClimb.Steps do
		local u = StairClimb.StepAt(index, 0)
		local tread, nose, riser = StairClimb.StepParts(u)
		local step = Instance.new("Model")
		step.Name = `Step{index}`
		local function piece(name: string, size: Vector3, at: CFrame): BasePart
			local p = part(step, size, frame * at, look.Tread)
			p.Name = name
			p.Transparency = if StairClimb.Shown(u) then 0 else 1
			return p
		end
		local sizes = StairClimb.StepSizes
		table.insert(steps, {
			piece("Tread", sizes.Tread, tread),
			piece("Nose", sizes.Nose, nose),
			piece("Riser", sizes.Riser, riser),
		})
		step.Parent = stepsFolder
	end
	paintSteps(steps, look)

	-- Where the owner steps on: the entry step and just behind it. The tutorial's arrow points here too.
	local zone = part(model, Vector3.new(W + 1, 6, 3.2), frame * CFrame.new(0, 3, Z_BACK + 0.8), paint(255, 255, 255))
	zone.Name = "Zone"
	zone.Transparency = 1

	-- The level, floating over the machine.
	local tagAnchor = part(model, Vector3.one * 0.2, frame * CFrame.new(0, 10, Z_MID), paint(255, 255, 255))
	tagAnchor.Name = "TagAnchor"
	tagAnchor.Transparency = 1
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(150, 56)
	billboard.MaxDistance = 160
	billboard.LightInfluence = 0
	billboard.Parent = tagAnchor
	local tag = words(billboard, { { Text = "LV 1", Height = 1, Color = Color3.new(1, 1, 1) } })[1]

	-- The upgrade sign: a post and a board, its prompts on the board.
	local sign = Instance.new("Model")
	sign.Name = "UpgradeSign"
	-- The post stops inside the board's edge, so it hides no words on either side.
	local wood = paint(120, 84, 56, Enum.Material.Wood)
	solid(part(sign, Vector3.new(0.5, 3.2, 0.28), signAt * CFrame.new(0, 1.6, 0.04), wood))
	local board = part(sign, Vector3.new(3.6, 2.6, 0.3), signAt * CFrame.new(0, 4.4, 0), paint(36, 40, 52))
	board.Name = "Board"
	solid(board)
	local back = part(sign, Vector3.new(3.8, 2.8, 0.25), signAt * CFrame.new(0, 4.4, 0.06), paint(255, 196, 64, METAL))
	solid(back)
	local function signWords(holder: Instance): { TextLabel }
		return words(holder, {
			{ Text = "UPGRADE", Height = 0.3, Color = Color3.fromRGB(255, 214, 90) },
			{ Text = "", Height = 0.24, Color = Color3.new(1, 1, 1) },
			{ Text = "", Height = 0.2, Color = Color3.fromRGB(255, 214, 90) },
			{ Text = "", Height = 0.2, Color = Color3.fromRGB(140, 235, 120) },
		})
	end
	-- Written on both sides: the board's front, and a dark plate on the gold backing behind it.
	local plate = Instance.new("Frame")
	plate.Size = UDim2.new(1, -12, 1, -12)
	plate.Position = UDim2.fromOffset(6, 6)
	plate.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
	plate.BorderSizePixel = 0
	plate.Parent = surface(back, Enum.NormalId.Back, 50)
	local lines = { signWords(surface(board, Enum.NormalId.Front, 50)), signWords(plate) }
	sign.PrimaryPart = board
	local coin = prompt(board, "CoinPrompt", Enum.KeyCode.E, Enum.KeyCode.ButtonX)
	local robux = prompt(board, "RobuxPrompt", Enum.KeyCode.R, Enum.KeyCode.ButtonY)

	model.Parent = parent
	sign.Parent = parent
	return {
		Model = model,
		Zone = zone,
		Steps = steps,
		Body = folder,
		Tag = tag,
		Screen = screen,
		Sign = sign,
		SignLines = lines,
		CoinPrompt = coin,
		RobuxPrompt = robux,
		Look = 1,
	}
end

-- Shows the owner's level (saved WalkerLevel, 0-based), or an empty plot's machine when `level` is nil.
function Walker.Paint(pieces: Pieces, level: number?, ownerId: number?)
	local shown = (level or 0) + 1
	local lookIndex = math.min(shown, #LOOKS)
	if lookIndex ~= pieces.Look then
		local look = LOOKS[lookIndex]
		pieces.Body:ClearAllChildren()
		pieces.Screen = body(pieces.Body, pieces.Model:GetPivot(), look)
		paintSteps(pieces.Steps, look)
		pieces.Look = lookIndex
	end
	pieces.Model:SetAttribute("Level", shown)
	pieces.Tag.Text = `LV {shown}`
	-- An empty plot's machine has no level to show off.
	local billboard = pieces.Tag.Parent
	if billboard and billboard:IsA("BillboardGui") then
		billboard.Enabled = level ~= nil
	end
	pieces.Screen.Text = `LV {shown}`
	local cost = if level then Economy.WalkerCost(level) else nil
	for _, p in { pieces.CoinPrompt, pieces.RobuxPrompt } do
		p:SetAttribute("OwnerId", ownerId)
		p.Enabled = cost ~= nil
	end
	local next, coins, robux = "", "", ""
	if level and not cost then
		next = "MAX LEVEL"
	elseif level and cost then
		local offer = StairClimb.RobuxOffer(level)
		next, coins, robux = `LV {shown + 1}`, `{Format.Short(cost)} coins`, `R$ {offer.Price}`
		pieces.CoinPrompt.ObjectText = coins
		pieces.RobuxPrompt.ObjectText = robux
	end
	for _, lines in pieces.SignLines do
		lines[2].Text, lines[3].Text, lines[4].Text = next, coins, robux
	end
end

return table.freeze(Walker)
