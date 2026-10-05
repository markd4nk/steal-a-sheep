--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(ReplicatedStorage.Config.Theme)

-- A board's screen: an upright part just in front of the map's panel, with a title, ten rows and a note, written by
-- the server and seen by everyone. The panels lie on their side (a SurfaceGui on one would read sideways), so the
-- screen is a part of its own.
local Face = {}

export type Line = {
	Name: string,
	Value: string,
	Picture: string,
}

type Row = {
	Frame: Frame,
	Picture: ImageLabel,
	Name: TextLabel,
	Value: TextLabel,
}

export type Face = {
	Part: Part,
	Rows: { Row },
	Empty: TextLabel,
	Note: TextLabel,
}

local PIXELS_PER_STUD = 50
local MARGIN = 0.4 -- studs of the panel left showing round the screen
local ROWS = 10
local PAD = 22
local GAP = 8
local HEADER = 110
local NOTE = 34

local Color = Theme.Color
local MEDALS = { Color.Gold500, Color3.fromRGB(196, 206, 220), Color3.fromRGB(214, 138, 74) }

local function stroke(parent: GuiObject, thickness: number)
	local line = Instance.new("UIStroke")
	line.Color = Color.Line
	line.Thickness = thickness
	line.Parent = parent
end

local function corner(parent: GuiObject, radius: UDim)
	local round = Instance.new("UICorner")
	round.CornerRadius = radius
	round.Parent = parent
end

local function text(parent: Instance, name: string, size: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = Theme.Font.Display
	label.TextSize = size
	label.TextColor3 = color
	label.Text = ""
	stroke(label, math.max(2, math.floor(size * 0.1)))
	label.Parent = parent
	return label
end

-- Where the screen goes: in front of the panel's front face (the side facing the plots), upright, as wide and tall as
-- the panel less the margin.
local function placement(panel: BasePart): (CFrame, Vector2)
	local look = panel.CFrame.LookVector
	local normal = Vector3.new(look.X, 0, look.Z).Unit
	local across = Vector3.yAxis:Cross(normal)
	local function extent(direction: Vector3): number
		local frame, size = panel.CFrame, panel.Size
		return math.abs(frame.RightVector:Dot(direction)) * size.X
			+ math.abs(frame.UpVector:Dot(direction)) * size.Y
			+ math.abs(frame.LookVector:Dot(direction)) * size.Z
	end
	local center = panel.Position + normal * (extent(normal) / 2 + 0.05)
	local size = Vector2.new(extent(across) - 2 * MARGIN, extent(Vector3.yAxis) - 2 * MARGIN)
	return CFrame.lookAt(center, center + normal), size
end

local function makeRow(parent: Instance, index: number, width: number, height: number, valueColor: Color3): Row
	local frame = Instance.new("Frame")
	frame.Name = `Row{index}`
	frame.LayoutOrder = index
	frame.Size = UDim2.fromOffset(width, height)
	frame.BackgroundColor3 = MEDALS[index] or Color.Snow
	frame.BackgroundTransparency = if MEDALS[index] then 0.6 else 0.9
	frame.Visible = false
	corner(frame, UDim.new(0, 14))

	local badgeSize = height - 12
	local badge = Instance.new("Frame")
	badge.Name = "Rank"
	badge.Position = UDim2.fromOffset(10, 6)
	badge.Size = UDim2.fromOffset(badgeSize, badgeSize)
	badge.BackgroundColor3 = MEDALS[index] or Color.Grey600
	corner(badge, UDim.new(0.5, 0))
	stroke(badge, 3)
	badge.Parent = frame
	local rank = text(badge, "Number", math.floor(badgeSize * 0.62), Color.Snow)
	rank.Size = UDim2.fromScale(1, 1)
	rank.Text = tostring(index)

	local picture = Instance.new("ImageLabel")
	picture.Name = "Picture"
	picture.Position = UDim2.fromOffset(20 + badgeSize, 6)
	picture.Size = UDim2.fromOffset(badgeSize, badgeSize)
	picture.BackgroundColor3 = Color.Grey800
	picture.Image = ""
	corner(picture, UDim.new(0.5, 0))
	stroke(picture, 3)
	picture.Parent = frame

	local valueWidth = math.floor(width * 0.34)
	local nameLeft = 34 + 2 * badgeSize
	local name = text(frame, "PlayerName", math.floor(height * 0.56), Color.Snow)
	name.Position = UDim2.fromOffset(nameLeft, 0)
	name.Size = UDim2.new(1, -(nameLeft + valueWidth + 14), 1, 0)
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd

	local value = text(frame, "Value", math.floor(height * 0.6), valueColor)
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, -14, 0, 0)
	value.Size = UDim2.new(0, valueWidth, 1, 0)
	value.TextXAlignment = Enum.TextXAlignment.Right

	frame.Parent = parent
	return { Frame = frame, Picture = picture, Name = name, Value = value }
end

function Face.Build(panel: BasePart, name: string, title: string, valueColor: Color3): Face
	local at, studs = placement(panel)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(studs.X, studs.Y, 0.1)
	part.CFrame = at

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Screen"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.MaxDistance = 300
	gui.Parent = part
	local width = math.floor(studs.X * PIXELS_PER_STUD)
	local height = math.floor(studs.Y * PIXELS_PER_STUD)

	local back = Instance.new("Frame")
	back.Name = "Back"
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color.Glass
	back.BackgroundTransparency = 0.08
	corner(back, UDim.new(0, 28))
	back.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, PAD)
	padding.PaddingBottom = UDim.new(0, PAD)
	padding.PaddingLeft = UDim.new(0, PAD)
	padding.PaddingRight = UDim.new(0, PAD)
	padding.Parent = back
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, GAP)
	list.Parent = back

	local inner = width - 2 * PAD
	-- Words only (the user, 2026-10-05: no icon).
	local titleLabel = text(back, "Title", 70, Color.Snow)
	titleLabel.LayoutOrder = 0
	titleLabel.Size = UDim2.fromOffset(inner, HEADER)
	titleLabel.Text = title

	local rowHeight = math.floor((height - 2 * PAD - HEADER - NOTE - (ROWS + 1) * GAP) / ROWS)
	local rows: { Row } = {}
	for index = 1, ROWS do
		table.insert(rows, makeRow(back, index, inner, rowHeight, valueColor))
	end

	-- Shown over the first row while the board is empty.
	local empty = text(back, "Empty", 40, Color.Snow)
	empty.LayoutOrder = ROWS + 1
	empty.Size = UDim2.fromOffset(inner, rowHeight)
	empty.Text = "No one yet"

	-- Pinned to the bottom, outside the list, so it stays put however many rows show.
	local note = text(gui, "Note", 26, Color.Snow)
	note.AnchorPoint = Vector2.new(0.5, 1)
	note.Position = UDim2.new(0.5, 0, 1, -PAD)
	note.Size = UDim2.fromOffset(inner, NOTE)
	note.TextTransparency = 0.35
	note.ZIndex = 2

	return { Part = part, Rows = rows, Empty = empty, Note = note }
end

function Face.Paint(face: Face, lines: { Line }, note: string)
	for index, row in face.Rows do
		local line = lines[index]
		row.Frame.Visible = line ~= nil
		if line then
			row.Name.Text = line.Name
			row.Value.Text = line.Value
			row.Picture.Image = line.Picture
		end
	end
	face.Empty.Visible = #lines == 0
	face.Note.Text = note
end

return table.freeze(Face)
