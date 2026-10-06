--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Theme = require(ReplicatedStorage.Config.Theme)

-- Builders for the standard pieces of the "Blue Ribbon" UI (DESIGN/ui/UI_SPEC.md), all from Theme, with the names
-- the screens look up. The studio/ build scripts make every screen from these in Edit; at run time only pieces made
-- on the fly use them. Requiring it makes nothing.
--
-- Most pieces are a coloured frame with its lip and ink outline drawn by three UIShadows under it: `Ring` (the
-- outline round the face), `LipRing` (the outline round the lip) and `Lip` (the darker band below). Buttons.Set and
-- the screens recolour those by name.

export type Kind = Theme.ButtonKind

local Color = Theme.Color
local Radius = Theme.Radius
local Line = Theme.Line
local TextSize = Theme.TextSize
-- A gold chip's words (UIKit.GoldChip): the rarity chips' 14 pt with a thinner edge than a label's, since at 12 pt
-- a label's edge filled the gaps between the letters (Mark, 2026-10-03: BADGE!'s G and E ran together).
local GOLD_CHIP_TEXT = 14
local GOLD_CHIP_HEIGHT = 20
local GOLD_CHIP_EDGE = 1.75

local UIKit = {}

-- Shared -----------------------------------------------------------------------------------------------------------

function UIKit.Corner(parent: Instance, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	-- No radius: a pill (half the height).
	corner.CornerRadius = if radius then UDim.new(0, radius) else UDim.new(0.5, 0)
	corner.Parent = parent
	return corner
end

function UIKit.Padding(parent: Instance, left: number, right: number?, top: number?, bottom: number?): UIPadding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right or left)
	padding.PaddingTop = UDim.new(0, top or left)
	padding.PaddingBottom = UDim.new(0, bottom or top or left)
	padding.Parent = parent
	return padding
end

-- A list layout; `horizontal` lays children left to right, centred on the cross axis.
function UIKit.List(parent: Instance, horizontal: boolean, gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	if horizontal then
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	else
		layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	end
	layout.Parent = parent
	return layout
end

-- A frame; `color` nil leaves it see-through.
function UIKit.Frame(parent: Instance?, name: string, size: UDim2, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BorderSizePixel = 0
	if color then
		frame.BackgroundColor3 = color
	else
		frame.BackgroundTransparency = 1
	end
	frame.Parent = parent
	return frame
end

-- Makes a child grow to fill what its list layout leaves over.
function UIKit.Grow(child: GuiObject)
	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = child
end

-- The lip under a piece and one ink outline round both, as UIShadows (see the header). `lip` 0 draws the outline
-- alone; `soft` adds the panels' soft drop shadow.
function UIKit.Surface(
	frame: GuiObject,
	lipColor: Color3?,
	lip: number,
	outline: Color3?,
	thickness: number?,
	soft: boolean?
)
	local width = (thickness or Line.Normal) * 2
	local function shadow(name: string, color: Color3, offset: number, spread: number, z: number): UIShadow
		local instance = Instance.new("UIShadow")
		instance.Name = name
		instance.Color = color
		instance.Offset = UDim2.fromOffset(0, offset)
		-- A shadow with no blur has a hard, stair-stepped edge; one pixel of blur smooths it like anti-aliasing.
		instance.BlurRadius = UDim.new(0, 1)
		instance.Spread = UDim2.fromOffset(spread, spread)
		instance.Transparency = 0
		instance.ZIndex = z
		instance.Parent = frame
		return instance
	end
	if soft then
		local drop = shadow("Soft", Color.Shadow, 20, 0, 1)
		drop.BlurRadius = UDim.new(0, 34)
		drop.Transparency = 0.6
	end
	if outline then
		shadow("Ring", outline, 0, width, 2)
		shadow("LipRing", outline, lip, width, 3)
	end
	if lipColor and lip > 0 then
		shadow("Lip", lipColor, lip, 0, 4)
	end
end

-- The studs over a coloured face (Theme.Studs): the stud image tiled over the face's own colour, under its words, with
-- the face's corners (`radius` nil: a pill). Hidden while there's no stud image; Buttons.Set hides it on flat kinds.
function UIKit.Studs(face: GuiObject, radius: number?): ImageLabel
	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.BorderSizePixel = 0
	studs.Size = UDim2.fromScale(1, 1)
	studs.Image = Theme.Studs.Image
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(Theme.Studs.Tile, Theme.Studs.Tile)
	studs.Visible = Theme.Studs.Image ~= ""
	studs.ZIndex = 0
	UIKit.Corner(studs, radius)
	studs.Parent = face
	return studs
end

-- Outline width for snow text on a colour: 2.5 up to 18, 3 at 22, 3.5 at 24 and up (Ranch Studs' thick edge; it
-- was 2, 2.5 and 3 in Blue Ribbon).
-- The ink edge a chip's small words get (13 pt): StrokeWidth's 2.5, all of it outside the glyph, fills the gaps
-- inside the letters at that size and the word smears (Mark, 2026-10-03: "SILVER" on Your pen's cards read blurry).
-- About 12% of the size, as Prize Fleece's type rule says.
local SMALL_TEXT_STROKE = 1.5

function UIKit.StrokeWidth(size: number): number
	return if size >= 24 then 3.5 elseif size >= 22 then 3 else 2.5
end

-- Ranch Studs' edge round a panel or a row: a thick black line outside it and a pale one just inside, as two UIStrokes
-- (`Edge`, `Inner`).
function UIKit.Edge(frame: GuiObject, thickness: number?)
	local glass = Theme.Glass
	local edge = Instance.new("UIStroke")
	edge.Name = "Edge"
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	edge.Color = Color.Line
	edge.Thickness = thickness or glass.Edge
	edge.Parent = frame
	local inner = Instance.new("UIStroke")
	inner.Name = "Inner"
	inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inner.BorderStrokePosition = Enum.BorderStrokePosition.Inner
	inner.Color = Color.Snow
	inner.Transparency = glass.InnerTransparency
	inner.Thickness = glass.Inner
	inner.Parent = frame
end

-- An outline round a label's letters, in the dark shade of the colour it sits on.
function UIKit.TextStroke(label: TextLabel, color: Color3): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Name = "TextStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = color
	stroke.Thickness = UIKit.StrokeWidth(label.TextSize)
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = label
	return stroke
end

export type TextOptions = {
	Font: Font?, -- Theme.Font.Display unless given
	Stroke: Color3?, -- an outline round the letters
	AlignX: Enum.TextXAlignment?,
	AlignY: Enum.TextYAlignment?,
	Wrap: boolean?,
	Rich: boolean?,
	Auto: Enum.AutomaticSize?, -- grows with its text
	Fit: boolean?, -- shrinks (TextScaled, down to TextSize.Min) instead of cutting off
	Order: number?,
}

-- A label at a fixed text size (UIScale does the scaling), or shrinking to fit when its length varies.
function UIKit.Text(
	parent: Instance?,
	name: string,
	text: string,
	size: number,
	color: Color3,
	box: UDim2?,
	options: TextOptions?
): TextLabel
	local opts: TextOptions = options or {}
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.FontFace = opts.Font or Theme.Font.Display
	label.TextSize = size
	label.TextColor3 = color
	label.Text = text
	label.Size = box or UDim2.new(1, 0, 0, size + 4)
	label.TextXAlignment = opts.AlignX or Enum.TextXAlignment.Center
	label.TextYAlignment = opts.AlignY or Enum.TextYAlignment.Center
	label.TextWrapped = opts.Wrap == true
	label.RichText = opts.Rich == true
	label.LayoutOrder = opts.Order or 0
	if opts.Auto then
		label.AutomaticSize = opts.Auto
	end
	if opts.Fit then
		label.TextScaled = true
		-- A size constraint counts screen pixels, not points, so UIController/Scale multiplies these by the UI scale.
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize = size
		limit.MinTextSize = TextSize.Min
		limit:SetAttribute("MaxPoints", size)
		limit:SetAttribute("MinPoints", TextSize.Min)
		limit.Parent = label
	end
	if opts.Stroke then
		UIKit.TextStroke(label, opts.Stroke)
	end
	label.Parent = parent
	return label
end

-- An icon from Theme.Icons, `size` points square.
function UIKit.Icon(parent: Instance?, name: string, image: string, size: number, tint: Color3?): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = name
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Size = UDim2.fromOffset(size, size)
	icon.Image = image
	icon.ImageColor3 = tint or Color3.new(1, 1, 1)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = parent
	return icon
end

-- An icon whose face takes a colour (a tier's gem, a mutation's sparkle, the red wolf pointer): `Fill` is tinted,
-- `Ink` stays as drawn. `key` is the icon's name in Theme.Icons ("Gem" uses GemFill and GemInk).
function UIKit.TintedIcon(parent: Instance?, name: string, key: string, size: number, tint: Color3): Frame
	local icons = Theme.Icons :: { [string]: string }
	local holder = UIKit.Frame(parent, name, UDim2.fromOffset(size, size))
	local fill = UIKit.Icon(holder, "Fill", icons[`{key}Fill`], size, tint)
	fill.Size = UDim2.fromScale(1, 1)
	local ink = UIKit.Icon(holder, "Ink", icons[`{key}Ink`], size)
	ink.Size = UDim2.fromScale(1, 1)
	-- The wool icon's outline is a fat shape under its face; the others' outlines are drawn over it.
	if key == "Wool" then
		ink.ZIndex = 0
	end
	local rainbow = Instance.new("UIGradient")
	rainbow.Name = "Rainbow"
	rainbow.Color = Theme.Rainbow
	rainbow.Rotation = Theme.RainbowRotation
	rainbow.Enabled = false
	rainbow.Parent = fill
	return holder
end

-- A see-through frame covering a screen: each ScreenGui's content goes in it, and its UIScale named Scale turns
-- points into pixels (UIController/Scale sizes it).
-- Never a CanvasGroup: one draws everything in it to a texture whose resolution the graphics quality caps, so a
-- screen-sized one blurs every icon and word on it.
function UIKit.Root(parent: Instance): GuiObject
	local root = UIKit.Frame(parent, "Root", UDim2.fromScale(1, 1))
	local scale = Instance.new("UIScale")
	scale.Name = "Scale"
	scale.Parent = root
	return root
end

-- A pulsing ring that draws the eye (the tutorial and hints): a UIStroke named Glow, and a second ring named
-- GlowRing outside it, both off until Motion.SetGlow. `inner` is the ring next to the piece.
function UIKit.Glow(parent: Instance, inner: Color3, outer: Color3, gap: number?)
	local offset = gap or 3
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	glow.BorderOffset = UDim.new(0, offset)
	glow.Color = inner
	glow.Thickness = 3.5
	glow.Enabled = false
	glow.Parent = parent
	local ring = Instance.new("UIStroke")
	ring.Name = "GlowRing"
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ring.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	ring.BorderOffset = UDim.new(0, offset + 3.5)
	ring.Color = outer
	ring.Thickness = Line.Normal
	ring.Enabled = false
	ring.Parent = parent
end

-- Prize Fleece -----------------------------------------------------------------------------------------------------
-- The menus' and pop-ups' pieces (DESIGN/ui/fleece/SPEC.md): one panel with a header in its family's colour, an opaque
-- slate body, sunk wells and raised tiles, cards in their sheep's rarity, a stage for a thing shown big.

local Fleece = Theme.Fleece

export type Accent = { Hi: Color3, Base: Color3, Lo: Color3 }

-- Lights a face from the top: a UIGradient named Lit multiplies its colour, `hi` at the top easing to `base` at `at`
-- (0.6 of the way down unless given) and below. Painting it again (a card's rarity) reuses the gradient.
function UIKit.Lit(frame: GuiObject, hi: Color3, base: Color3, at: number?): UIGradient
	frame.BackgroundColor3 = hi
	local found = frame:FindFirstChild("Lit")
	local gradient = if found and found:IsA("UIGradient") then found else Instance.new("UIGradient")
	gradient.Name = "Lit"
	gradient.Rotation = 90
	local function share(low: number, high: number): number
		return math.clamp(low / math.max(high, 1 / 255), 0, 1)
	end
	local ratio = Color3.new(share(base.R, hi.R), share(base.G, hi.G), share(base.B, hi.B))
	local stop = math.clamp(at or 0.6, 0.01, 1)
	local keys = { ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), ColorSequenceKeypoint.new(stop, ratio) }
	if stop < 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, ratio))
	end
	gradient.Color = ColorSequence.new(keys)
	gradient.Parent = frame
	return gradient
end

-- The Theme.Fleece accent for a family's name, the sky blue of the Sheep Shop when it has none.
function UIKit.Accent(name: string?): Accent
	return Fleece.Accent[name or "Shop"] or Fleece.Accent.Shop
end

-- A header across the top of `holder` (a panel or a pop-up card), Prize Fleece's: the family's colour, lit from the
-- top, with studs and a darker lip, and an ink line under it, as layers in HeaderSkin; the family's picture (Badge)
-- hanging over the top-left corner, turned a little; and Header, laid out left to right, holding the TitleLabel, what
-- the screen puts beside it (LayoutOrder 2 to 8), and the CloseButton (9). `badge` "" leaves the picture out, `title`
-- nil the TitleLabel (the screen puts something in its place, LayoutOrder 1).
local function header(
	holder: GuiObject,
	accent: Accent,
	badge: string,
	title: string?,
	titleSize: number,
	close: boolean
)
	local height = Fleece.Header
	local skin = UIKit.Frame(holder, "HeaderSkin", UDim2.new(1, 0, 0, height))
	skin.ZIndex = 2
	-- The face in two pieces, a rounded cap and a square bottom half, so only its top corners are round.
	local cap = UIKit.Frame(skin, "Cap", UDim2.fromScale(1, 1), accent.Base)
	UIKit.Corner(cap, Fleece.Radius)
	local square = UIKit.Frame(skin, "Square", UDim2.fromScale(1, 0.5), accent.Base)
	square.Position = UDim2.fromScale(0, 0.5)
	-- The light from the top: the lit colour fading into the face.
	local shine = UIKit.Frame(skin, "Shine", UDim2.fromScale(1, 0.62), accent.Hi)
	shine.ZIndex = 2
	UIKit.Corner(shine, Fleece.Radius)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new(0, 1)
	fade.Parent = shine
	-- The studs stay clear of the rounded corners, so they never poke out past them.
	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.Position = UDim2.fromOffset(8, 5)
	studs.Size = UDim2.new(1, -16, 1, -(Fleece.HeaderLip + 6))
	studs.Image = Theme.Studs.Image
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(Theme.Studs.Tile, Theme.Studs.Tile)
	studs.Visible = Theme.Studs.Image ~= ""
	studs.ZIndex = 3
	studs.Parent = skin
	local lip = UIKit.Frame(skin, "Lip", UDim2.new(1, 0, 0, Fleece.HeaderLip), accent.Lo)
	lip.Position = UDim2.new(0, 0, 1, -Fleece.HeaderLip)
	lip.ZIndex = 4
	local line = UIKit.Frame(skin, "Line", UDim2.new(1, 0, 0, Fleece.Outline), Color.Line)
	line.Position = UDim2.fromScale(0, 1)
	line.ZIndex = 4

	local picture = UIKit.Icon(holder, "Badge", badge, Fleece.Badge)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromOffset(Fleece.Badge / 2 - 16, Fleece.Badge / 2 - 22)
	picture.Rotation = Fleece.BadgeTilt
	picture.ZIndex = 6
	picture.Visible = badge ~= ""

	local head = UIKit.Frame(holder, "Header", UDim2.new(1, 0, 0, height - Fleece.HeaderLip))
	head.ZIndex = 4
	UIKit.Padding(head, if badge ~= "" then 80 else 18, 8, 0, 0)
	UIKit.List(head, true, 10)
	if title then
		local label = UIKit.Text(head, "TitleLabel", title, titleSize, Color.Snow, UDim2.fromOffset(0, height), {
			Stroke = Color.Line,
			Auto = Enum.AutomaticSize.X,
			Order = 1,
		})
		label.ZIndex = 4
		local stroke = label:FindFirstChild("TextStroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Thickness = 4
		end
	end
	local spacer = UIKit.Frame(head, "Spacer", UDim2.fromOffset(0, 1))
	spacer.LayoutOrder = 3
	UIKit.Grow(spacer)
	if close then
		UIKit.Close(head).LayoutOrder = 9
	end
	return head
end

-- A chip in a header (the cash, pen space, a level): a dark pane on the header's colour with an ink edge, its icon
-- (Bill) and its words (`labelName`).
function UIKit.HeaderChip(parent: Instance?, name: string, icon: string, labelName: string, text: string): Frame
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, 36), Fleece.Well)
	chip.BackgroundTransparency = 0.5
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip, 12)
	UIKit.Padding(chip, 5, 12, 0, 0)
	UIKit.List(chip, true, 6)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Normal
	edge.Parent = chip
	UIKit.Icon(chip, "Bill", icon, 30)
	UIKit.Text(chip, labelName, text, 21, Color.Snow, UDim2.fromOffset(0, 36), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	return chip
end

-- A dark chip on the body or a stage: an optional icon and its words ("x3", "+$102/s", "18/20"). `small` makes it
-- 20 pt tall with 13 pt words, for a stage that has to leave room for its picture (Your pen's).
function UIKit.DarkChip(parent: Instance?, name: string, icon: string?, labelName: string?, small: boolean?): Frame
	local height = if small then 20 else 28
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, height), Fleece.Well)
	chip.BackgroundTransparency = 0.45
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip, if small then 7 else 10)
	UIKit.Padding(
		chip,
		if icon then (if small then 3 else 4) else (if small then 6 else 10),
		if small then 7 else 10,
		0,
		0
	)
	UIKit.List(chip, true, if small then 3 else 4)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Thin
	edge.Parent = chip
	if icon then
		UIKit.Icon(chip, "Icon", icon, if small then 17 else 24)
	end
	local label =
		UIKit.Text(chip, labelName or "Label", "", if small then 13 else 17, Color.Snow, UDim2.fromOffset(0, height), {
			Stroke = Color.Line,
			Auto = Enum.AutomaticSize.X,
			Order = 1,
		})
	local ink = label:FindFirstChild("TextStroke")
	if small and ink and ink:IsA("UIStroke") then
		ink.Thickness = SMALL_TEXT_STROKE
	end
	return chip
end

-- The sheep count's chip: a studded blue pill with a thick black edge, the Farm Sheep's Token, the count (SheepLabel)
-- and, where it opens Your pen (the HUD's), a Chevron; the token, count and chevron sit in a Line of their own so the
-- studs stay out of their row. The HUD's top bar has one (studio/BuildUI.luau) and the mutation lab makes its own.
function UIKit.SheepChip(parent: Instance?, name: string, height: number, chevron: boolean): Frame
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, height), Color.Blue500)
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.Position = UDim2.fromScale(0, 0.5)
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip, Radius.Button - 2)
	UIKit.Surface(chip, Color.Blue700, Theme.Lip.Small, Color.Line, Line.Thick)
	UIKit.Studs(chip, Radius.Button - 2)
	local line = UIKit.Frame(chip, "Line", UDim2.fromOffset(0, height))
	line.AutomaticSize = Enum.AutomaticSize.X
	line.ZIndex = 2
	UIKit.Padding(line, 4, 10, 0, 0)
	UIKit.List(line, true, 6)
	UIKit.Token(line, height - 2)
	UIKit.Text(line, "SheepLabel", "...", TextSize.Big, Color.Snow, UDim2.fromOffset(0, height), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	if chevron then
		UIKit.Icon(line, "Chevron", Theme.Icons.ChevronWhite, 18).LayoutOrder = 2
	end
	return chip
end

-- A small gold chip with white words on a toast ("NEW!" on a Sheepdex find, "BADGE!" on a badge), growing with its
-- words; returns the chip and its Label.
function UIKit.GoldChip(parent: Instance?, name: string, text: string): (Frame, TextLabel)
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, GOLD_CHIP_HEIGHT), Color.Gold500)
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip, Radius.Tag)
	UIKit.Padding(chip, 6, 6, 0, 0)
	local label = UIKit.Text(chip, "Label", text, GOLD_CHIP_TEXT, Color.Snow, UDim2.fromOffset(0, GOLD_CHIP_HEIGHT), {
		Auto = Enum.AutomaticSize.X,
	})
	UIKit.TextStroke(label, Color.Gold800).Thickness = GOLD_CHIP_EDGE
	return chip, label
end

-- The points a gold chip with these words takes, for a spot that keeps its place while the chip pops (its own scale
-- would shove what's beside it in a list).
function UIKit.GoldChipSize(text: string): Vector2
	local words = TextService:GetTextSize(text, GOLD_CHIP_TEXT, Enum.Font.FredokaOne, Vector2.new(1000, 1000))
	return Vector2.new(math.ceil(words.X) + 12, GOLD_CHIP_HEIGHT)
end

-- A rarity's label ("UNCOMMON"): a small plate in the rarity's colour, lit from the top, with an ink edge; Style.PaintRarity
-- colours it and writes it. `small` makes it 20 pt tall with 13 pt words and a thin edge (Your pen's cards: at 11 pt
-- the words read blurry on a phone, Mark 2026-10-03).
function UIKit.RarityChip(parent: Instance?, name: string, small: boolean?): Frame
	local height = if small then 20 else 24
	local lip = if small then 2 else 3
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, height), Fleece.Rarity.Common.Base)
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip, if small then 6 else 8)
	UIKit.Padding(chip, if small then 6 else 10, if small then 6 else 10, 0, lip)
	UIKit.Surface(chip, Fleece.Rarity.Common.Lo, lip, Color.Line, Line.Thin)
	UIKit.Lit(chip, Fleece.Rarity.Common.Hi, Fleece.Rarity.Common.Base, 1)
	local label =
		UIKit.Text(chip, "Label", "COMMON", if small then 13 else 14, Color.Snow, UDim2.fromOffset(0, height - lip), {
			Stroke = Color.Line,
			Auto = Enum.AutomaticSize.X,
		})
	local edge = label:FindFirstChild("TextStroke")
	if small and edge and edge:IsA("UIStroke") then
		edge.Thickness = SMALL_TEXT_STROKE
	end
	return chip
end

-- A sunk pane on the body (a list, the tab bar): dark, see-through, with a soft ink edge.
function UIKit.Well(parent: Instance?, name: string, size: UDim2): Frame
	local well = UIKit.Frame(parent, name, size, Fleece.Well)
	well.BackgroundTransparency = Fleece.WellTransparency
	UIKit.Corner(well, Fleece.TileRadius)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Thin
	edge.Transparency = 0.45
	edge.Parent = well
	return well
end

-- A raised pane on the body (a fact, a row, a requirement): lighter slate lit from the top, with an ink edge and lip.
function UIKit.Tile(parent: Instance?, name: string, size: UDim2): Frame
	local tile = UIKit.Frame(parent, name, size, Fleece.Tile.Hi)
	UIKit.Lit(tile, Fleece.Tile.Hi, Fleece.Tile.Lo, 1)
	UIKit.Corner(tile, Fleece.TileRadius)
	UIKit.Surface(tile, Color.Line, 4, Color.Line, Line.Normal)
	tile:SetAttribute("Glass", true)
	return tile
end

-- A stage for a thing shown big (the shop's picked sheep, a pop-up's prize): its rarity's colour lit from the top
-- (Style.PaintStage), slow white rays (Rays, which Motion can turn), and its Picture in the middle.
function UIKit.Stage(parent: Instance?, name: string, size: UDim2, pictureSize: number): Frame
	local look = Fleece.Rarity.Common
	local stage = UIKit.Frame(parent, name, size, look.Hi)
	UIKit.Lit(stage, look.Hi, look.Lo, 1)
	UIKit.Corner(stage, 16)
	stage.ClipsDescendants = true
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Normal
	edge.Parent = stage
	local rays = UIKit.Icon(stage, "Rays", Theme.Icons.Burst, 100, Color.Snow)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromScale(1.5, 1.5)
	rays.ImageTransparency = 0.72
	Instance.new("UIAspectRatioConstraint").Parent = rays
	local picture = UIKit.Icon(stage, "Picture", "", pictureSize)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.46)
	picture.ZIndex = 2
	return stage
end

-- A progress bar, Prize Fleece's: a dark track with an ink edge, a Fill lit gold (green once full, Style.SetBar reads
-- the bar's FillColor and DoneColor), and its words on top (Label).
function UIKit.Meter(parent: Instance?, name: string, size: UDim2): Frame
	local track = UIKit.Frame(parent, name, size, Color3.fromRGB(20, 23, 32))
	UIKit.Corner(track)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Normal
	edge.Parent = track
	track:SetAttribute("FillColor", Color.Gold500)
	track:SetAttribute("DoneColor", Color.Green500)
	local fill = UIKit.Frame(track, "Fill", UDim2.fromScale(0, 1), Color.Gold500)
	UIKit.Corner(fill)
	local shine = Instance.new("UIGradient")
	shine.Rotation = 90
	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(225, 225, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 190)),
	})
	shine.Parent = fill
	local label = UIKit.Text(track, "Label", "", 15, Color.Snow, UDim2.fromScale(1, 1), { Stroke = Color.Line })
	label.ZIndex = 3
	return track
end

-- A pip per level (an upgrade's 20): Pips holds Pip1..PipN; Style.SetPips lights them.
function UIKit.Pips(parent: Instance?, name: string, count: number, size: UDim2): Frame
	local track = UIKit.Frame(parent, name, size, Color3.fromRGB(20, 23, 32))
	UIKit.Corner(track, 8)
	UIKit.Padding(track, 3, 3, 3, 3)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Normal
	edge.Parent = track
	local layout = UIKit.List(track, true, 3)
	layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
	for index = 1, count do
		local pip = UIKit.Frame(track, `Pip{index}`, UDim2.fromScale(0, 1), Color.Snow)
		pip.LayoutOrder = index
		pip.BackgroundTransparency = 0.93
		UIKit.Corner(pip, 3)
	end
	return track
end

-- "16 ▸ 17": what a thing is now, an ink disc with a white arrow, and what it'll be (lime), with its unit after them
-- (Now, Arrow, Next, Unit labels and the Step bubble, "+1").
function UIKit.Gain(parent: Instance?, name: string, size: number): Frame
	local row = UIKit.Frame(parent, name, UDim2.fromOffset(0, size + 8))
	row.AutomaticSize = Enum.AutomaticSize.X
	UIKit.List(row, true, 7)
	local now = UIKit.Text(row, "NowLabel", "", size, Color.Snow, UDim2.fromOffset(0, size + 8), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local disc = UIKit.Frame(row, "Arrow", UDim2.fromOffset(30, 30), Color3.fromRGB(20, 23, 32))
	disc.LayoutOrder = 2
	UIKit.Corner(disc)
	local ring = Instance.new("UIStroke")
	ring.Color = Color.Line
	ring.Thickness = Line.Normal
	ring.Parent = disc
	-- The chevron is drawn pointing right.
	local arrow = UIKit.Icon(disc, "Icon", Theme.Icons.ChevronWhite, 16)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Position = UDim2.new(0.5, 1, 0.5, 0)
	local nextLabel = UIKit.Text(row, "NextLabel", "", size, Color.Lime, UDim2.fromOffset(0, size + 8), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 3,
	})
	for _, label in { now, nextLabel } do
		local stroke = label:FindFirstChild("TextStroke")
		if stroke and stroke:IsA("UIStroke") then
			stroke.Thickness = math.max(3, size * 0.12)
		end
	end
	UIKit.Text(row, "UnitLabel", "", 16, Color.Snow, UDim2.fromOffset(0, size + 8), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 4,
	})
	local step = UIKit.Frame(row, "Step", UDim2.fromOffset(0, 24), Color.Green500)
	step.LayoutOrder = 5
	step.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(step)
	UIKit.Padding(step, 8, 8, 0, 2)
	UIKit.Surface(step, Color.Green600, 3, Color.Line, Line.Thin)
	UIKit.Text(step, "Label", "+1", 15, Color.Snow, UDim2.fromOffset(0, 22), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
	})
	return row
end

-- A card for a sheep in a grid (the Sheep Shop, the Sheepdex): a TextButton holding Face, the card in its sheep's
-- rarity (Style.PaintCard) with an ink edge and lip, its Picture, its NameLabel and, in a dark strip at its foot, its
-- Price (an Icon and the PriceLabel) or its rarity; a CountLabel badge (top left), a NewTag (top right), a Lock, a
-- Selected ring (Selected, SelectedRing) and the hints' Glow. Its Lift UIScale grows it while it's picked.
function UIKit.SheepCard(parent: Instance?, name: string): TextButton
	local size = Fleece.Card
	local card = Instance.new("TextButton")
	card.Name = name
	card.Size = UDim2.fromOffset(size.X, size.Y)
	card.BackgroundTransparency = 1
	card.AutoButtonColor = false
	card.Text = ""
	card.Selectable = true
	card:SetAttribute("Card", true)
	local lift = Instance.new("UIScale")
	lift.Name = "Lift"
	lift.Parent = card

	local look = Fleece.Rarity.Common
	local face = UIKit.Frame(card, "Face", UDim2.fromScale(1, 1), look.Hi)
	UIKit.Lit(face, look.Hi, look.Lo, 1)
	UIKit.Corner(face, Fleece.CardRadius)
	UIKit.Surface(face, Color.Line, 5, Color.Line, Line.Normal)
	local selected = Instance.new("UIStroke")
	selected.Name = "Selected"
	selected.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	selected.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	selected.BorderOffset = UDim.new(0, 2)
	selected.Color = Color.Snow
	selected.Thickness = 3.5
	selected.Enabled = false
	selected.Parent = face
	local selectedRing = Instance.new("UIStroke")
	selectedRing.Name = "SelectedRing"
	selectedRing.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	selectedRing.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	selectedRing.BorderOffset = UDim.new(0, 5.5)
	selectedRing.Color = Color.Line
	selectedRing.Thickness = Line.Normal
	selectedRing.Enabled = false
	selectedRing.Parent = face
	UIKit.Glow(face, Color.Snow, Color.Blue500, 6)
	-- Rays behind the picture, faint: the card's glow.
	local rays = UIKit.Icon(face, "Rays", Theme.Icons.Burst, 120, Color.Snow)
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.new(0.5, 0, 0, 42)
	rays.ImageTransparency = 0.8
	rays.ZIndex = 1

	local picture = UIKit.Icon(face, "Picture", "", 84)
	picture.AnchorPoint = Vector2.new(0.5, 0)
	picture.Position = UDim2.new(0.5, 0, 0, 3)
	picture.ZIndex = 2
	local lock = UIKit.Icon(face, "Lock", Theme.Icons.HudLock, 42)
	lock.AnchorPoint = Vector2.new(0.5, 0.5)
	lock.Position = UDim2.new(0.5, 0, 0, 44)
	lock.ZIndex = 3
	lock.Visible = false

	local nameLabel = UIKit.Text(face, "NameLabel", "Breed", 15, Color.Snow, UDim2.new(1, -10, 0, 18), {
		Stroke = Color.Line,
		Fit = true,
	})
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 1, -33)
	nameLabel.ZIndex = 4

	local strip = UIKit.Frame(face, "Strip", UDim2.new(1, -12, 0, 24), Fleece.Well)
	strip.AnchorPoint = Vector2.new(0.5, 1)
	strip.Position = UDim2.new(0.5, 0, 1, -6)
	strip.BackgroundTransparency = 0.45
	strip.ZIndex = 4
	UIKit.Corner(strip, 8)
	local stripList = UIKit.List(strip, true, 2, Enum.HorizontalAlignment.Center)
	stripList.VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Icon(strip, "Icon", Theme.Icons.HudCash, 22).ZIndex = 4
	local price = UIKit.Text(strip, "PriceLabel", "$0", 16, Color.Lime, UDim2.fromOffset(0, 22), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	price.ZIndex = 4
	local rarity = UIKit.RarityChip(face, "RarityChip")
	rarity.AnchorPoint = Vector2.new(0.5, 1)
	rarity.Position = UDim2.new(0.5, 0, 1, -7)
	rarity.ZIndex = 4
	rarity.Visible = false

	local count = UIKit.Text(face, "CountLabel", "x1", 14, Color.Snow, UDim2.fromOffset(0, 22), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
	})
	count.Position = UDim2.fromOffset(-6, -7)
	count.BackgroundTransparency = 0
	count.BackgroundColor3 = Fleece.Tile.Base
	count.ZIndex = 6
	count.Visible = false
	UIKit.Corner(count, 8)
	UIKit.Padding(count, 7, 7, 0, 0)
	local countEdge = Instance.new("UIStroke")
	countEdge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	countEdge.Color = Color.Line
	countEdge.Thickness = Line.Thin
	countEdge.Parent = count

	local newTag = UIKit.Text(face, "NewTag", "NEW!", 13, Color.Snow, UDim2.fromOffset(0, 22), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
	})
	newTag.AnchorPoint = Vector2.new(1, 0)
	newTag.Position = UDim2.new(1, 8, 0, -9)
	newTag.Rotation = 8
	newTag.BackgroundTransparency = 0
	newTag.BackgroundColor3 = Color.Red500
	newTag.ZIndex = 6
	newTag.Visible = false
	UIKit.Corner(newTag, 8)
	UIKit.Padding(newTag, 7, 7, 0, 2)
	UIKit.Surface(newTag, Color.Red800, 3, Color.Line, Line.Thin)
	card.Parent = parent
	return card
end

-- Buttons ----------------------------------------------------------------------------------------------------------

-- Three dots that show while a button waits on the server.
local function dots(parent: Instance, color: Color3)
	local holder = UIKit.Frame(parent, "Dots", UDim2.fromScale(1, 1))
	holder.Visible = false
	holder.ZIndex = 3
	UIKit.List(holder, true, 6, Enum.HorizontalAlignment.Center)
	for index = 1, 3 do
		local dot = UIKit.Frame(holder, `Dot{index}`, UDim2.fromOffset(9, 9), color)
		dot.LayoutOrder = index
		UIKit.Corner(dot)
		local ring = Instance.new("UIStroke")
		ring.Thickness = Line.Thin
		ring.Color = Color.Ink
		ring.Parent = dot
	end
end

-- A button: a coloured face with its lip and outline (UIKit.Surface), a snow shine bar, and in its Content a Line
-- (an Icon and the Label) over a SubLabel; a Value on the right (a price with its icon) for the Buy button; Dots
-- while loading. `height` is the face's; the TextButton (the hit area, never under 44 x 44) adds the lip. Colours
-- come from Theme.Button[kind] and change only through Buttons.Set.
function UIKit.Button(
	parent: Instance?,
	name: string,
	kind: Kind,
	width: number,
	height: number,
	text: string
): TextButton
	local look = Theme.Button[kind]
	local lip = if height >= Theme.ButtonHeight.Standard then Theme.Lip.Button else Theme.Lip.Small
	local hitHeight = math.max(height + lip, Theme.MinTouch)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(width, hitHeight)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Selectable = true
	button:SetAttribute("Kind", kind)
	button:SetAttribute("FaceHeight", height)
	local squish = Instance.new("UIScale")
	squish.Name = "Squish"
	squish.Parent = button

	local face = UIKit.Frame(button, "Face", UDim2.new(1, 0, 0, height), look.Face)
	face.AnchorPoint = Vector2.new(0.5, 0)
	face.Position = UDim2.new(0.5, 0, 0.5, -(height + lip) / 2)
	local radius = if height >= Theme.ButtonHeight.Row then Radius.Button else nil
	UIKit.Corner(face, radius)
	UIKit.Surface(face, look.Lip or look.Face, lip, look.Outline)
	face:SetAttribute("Lip", lip)
	UIKit.Studs(face, radius).Visible = look.Lip ~= nil and kind ~= "Soft" and Theme.Studs.Image ~= ""

	local shine = UIKit.Frame(face, "Shine", UDim2.new(0.36, 0, 0, if height > 40 then 5 else 4), Color.Snow)
	shine.Position = UDim2.fromOffset(10, if height > 40 then 5 else 4)
	shine.BackgroundTransparency = 0.62
	shine.Visible = look.Lip ~= nil
	UIKit.Corner(shine)
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(64, math.huge)
	cap.Parent = shine

	local labelSize = if height >= Theme.ButtonHeight.Hero
		then TextSize.Title
		elseif height <= Theme.ButtonHeight.Row then TextSize.Tab
		else TextSize.Label
	local content = UIKit.Frame(face, "Content", UDim2.fromScale(1, 1))
	content.ZIndex = 2
	local column = UIKit.List(content, false, 3, Enum.HorizontalAlignment.Center)
	column.VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Padding(content, 12, 12, 0, 0)
	local lineFrame = UIKit.Frame(content, "Line", UDim2.fromOffset(0, labelSize + 4))
	lineFrame.AutomaticSize = Enum.AutomaticSize.X
	lineFrame.LayoutOrder = 1
	UIKit.List(lineFrame, true, 6, Enum.HorizontalAlignment.Center)
	local icon = UIKit.Icon(lineFrame, "Icon", "", math.floor(labelSize * 1.15))
	icon.Visible = false
	local label = UIKit.Text(lineFrame, "Label", text, labelSize, look.Label, UDim2.fromOffset(0, labelSize + 4), {
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local stroke = UIKit.TextStroke(label, look.LabelStroke or look.Label)
	stroke.Enabled = look.LabelStroke ~= nil
	local sub = UIKit.Text(content, "SubLabel", "", TextSize.Caption, look.Label, UDim2.fromOffset(0, 14), {
		Font = Theme.Font.TextHeavy,
		Auto = Enum.AutomaticSize.X,
		Order = 2,
	})
	sub.Visible = false

	-- A price on the right ("Buy ... $6K"): the button's Label moves to the left while it shows.
	local value = UIKit.Frame(face, "Value", UDim2.new(0, 0, 1, 0))
	value.AutomaticSize = Enum.AutomaticSize.X
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, -16, 0, 0)
	value.Visible = false
	value.ZIndex = 2
	UIKit.List(value, true, 6, Enum.HorizontalAlignment.Right)
	local valueIcon = UIKit.Icon(value, "ValueIcon", Theme.Icons.Cash, labelSize + 6)
	valueIcon.Rotation = -8
	local valueLabel = UIKit.Text(value, "ValueLabel", "", labelSize, look.Label, UDim2.fromOffset(0, labelSize + 4), {
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local valueStroke = UIKit.TextStroke(valueLabel, look.LabelStroke or look.Label)
	valueStroke.Enabled = look.LabelStroke ~= nil

	dots(face, look.Label)
	button.Parent = parent
	return button
end

-- The close button: a red studded square with a snow X (or "B" while a gamepad plays), Ranch Studs' close.
function UIKit.Close(parent: Instance?, name: string?): TextButton
	local size = Theme.ButtonHeight.Close
	local lip = Theme.Lip.Small
	local look = Theme.Button["Danger" :: Kind]
	local radius = Radius.Tag + 2
	local button = Instance.new("TextButton")
	button.Name = name or "CloseButton"
	button.Size = UDim2.fromOffset(Theme.MinTouch, Theme.MinTouch)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Text = ""
	button:SetAttribute("Kind", "Danger")
	button:SetAttribute("FaceHeight", size)
	local squish = Instance.new("UIScale")
	squish.Name = "Squish"
	squish.Parent = button
	local face = UIKit.Frame(button, "Face", UDim2.fromOffset(size, size), look.Face)
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.new(0.5, 0, 0.5, -lip / 2)
	face:SetAttribute("Lip", lip)
	UIKit.Corner(face, radius)
	UIKit.Surface(face, look.Lip, lip, look.Outline)
	UIKit.Studs(face, radius)
	local icon = UIKit.Icon(face, "Icon", Theme.Icons.CloseWhite, 22)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	local key = UIKit.Text(face, "KeyLabel", "B", 20, Color.Snow, UDim2.fromScale(1, 1), { Stroke = look.LabelStroke })
	key.Visible = false
	button.Parent = parent
	return button
end

-- A small ink key cap ("LB", "RB") shown beside tabs while a gamepad plays.
function UIKit.KeyChip(parent: Instance?, name: string, text: string): TextLabel
	local chip = UIKit.Text(parent, name, text, TextSize.Caption, Color.Snow, UDim2.fromOffset(0, 18), {
		Font = Theme.Font.TextHeavy,
		Auto = Enum.AutomaticSize.X,
	})
	chip.BackgroundTransparency = 0
	chip.BackgroundColor3 = Color.Ink
	UIKit.Corner(chip)
	UIKit.Padding(chip, 6, 6, 0, 0)
	chip.Visible = false
	return chip
end

export type TabSpec = { Name: string, Text: string, Icon: string? }

-- The tabs (Prize Fleece): a segmented bar in a well. Each tab is `<Name>Tab`, a TextButton (Fleece attribute) with a
-- Face in the menu's colour that shows only on the page showing (Buttons.SetTab), and a Line holding an Icon and a
-- Label: white with an ink edge on the page showing, muted on the others. LB and RB key caps sit on the first and last
-- tab.
function UIKit.Tabs(parent: Instance?, specs: { TabSpec }, accent: Accent?): Frame
	local look = accent or UIKit.Accent(nil)
	local height = Fleece.TabBar - 8
	local bar = UIKit.Frame(parent, "Tabs", UDim2.fromOffset(0, Fleece.TabBar), Fleece.Well)
	bar.BackgroundTransparency = Fleece.WellTransparency
	bar.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(bar, Fleece.TileRadius)
	UIKit.Padding(bar, 4, 4, 4, 4)
	UIKit.List(bar, true, 4)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Line.Thin
	edge.Transparency = 0.45
	edge.Parent = bar
	for order, spec in specs do
		local tab = Instance.new("TextButton")
		tab.Name = `{spec.Name}Tab`
		tab.LayoutOrder = order
		tab.Size = UDim2.fromOffset(0, height)
		tab.AutomaticSize = Enum.AutomaticSize.X
		tab.BackgroundTransparency = 1
		tab.AutoButtonColor = false
		tab.Text = ""
		tab:SetAttribute("Fleece", true)
		local face = UIKit.Frame(tab, "Face", UDim2.fromScale(1, 1), look.Base)
		UIKit.Lit(face, look.Hi, look.Base, 0.7)
		UIKit.Corner(face, 10)
		UIKit.Surface(face, look.Lo, 3, Color.Line, Line.Normal)
		face.Visible = false
		local holder = UIKit.Frame(tab, "Line", UDim2.fromScale(0, 1))
		holder.AutomaticSize = Enum.AutomaticSize.X
		holder.ZIndex = 3
		UIKit.Padding(holder, 14, 16, 0, 3)
		UIKit.List(holder, true, 6)
		if order == 1 and #specs > 1 then
			UIKit.KeyChip(holder, "KeyChip", "LB").LayoutOrder = 0
		end
		if spec.Icon then
			local icon = UIKit.Icon(holder, "Icon", spec.Icon, 24)
			icon.LayoutOrder = 1
		end
		UIKit.Text(holder, "Label", string.upper(spec.Text), 18, Fleece.Muted, UDim2.fromOffset(0, height), {
			Stroke = Color.Line,
			Auto = Enum.AutomaticSize.X,
			Order = 2,
		})
		if order == #specs and #specs > 1 then
			UIKit.KeyChip(holder, "KeyChip", "RB").LayoutOrder = 3
		end
		tab.Parent = bar
	end
	return bar
end

-- Chips, strips, bars ----------------------------------------------------------------------------------------------

-- A pale pill with an optional icon: a tier ("UNCOMMON" with its gem), a mutation, "YOU HAVE 2". `iconKey` is a
-- TintedIcon key (Gem, Sparkle) or nil for text only. Code recolours it (Style.PaintChip).
function UIKit.Chip(parent: Instance?, name: string, text: string, iconKey: string?): Frame
	local chip = UIKit.Frame(parent, name, UDim2.fromOffset(0, 20), Color.Blue100)
	chip.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(chip)
	UIKit.Padding(chip, if iconKey then 4 else 8, 8, 0, 0)
	UIKit.List(chip, true, 4)
	if iconKey then
		UIKit.TintedIcon(chip, "Icon", iconKey, 14, Color.Snow)
	end
	UIKit.Text(chip, "Label", text, TextSize.Caption, Color.Blue800, UDim2.fromOffset(0, 20), {
		Font = Theme.Font.TextHeavy,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local rainbow = Instance.new("UIGradient")
	rainbow.Name = "Rainbow"
	rainbow.Color = Theme.Rainbow
	rainbow.Rotation = Theme.RainbowRotation
	rainbow.Enabled = false
	rainbow.Parent = chip
	return chip
end

-- A strip of small print in a panel: an icon and a line of Builder Sans. Kind "Warn" is red.
function UIKit.Strip(parent: Instance?, name: string, labelName: string, icon: string, text: string): Frame
	local strip = UIKit.Frame(parent, name, UDim2.new(1, 0, 0, 0), Color.Blue100)
	strip.AutomaticSize = Enum.AutomaticSize.Y
	UIKit.Corner(strip, Radius.Button)
	UIKit.Padding(strip, 8, 12, 8, 8)
	UIKit.List(strip, true, 8)
	UIKit.Icon(strip, "Icon", icon, 22)
	local label = UIKit.Text(strip, labelName, text, TextSize.Body, Color.Blue800, UDim2.new(1, -30, 0, 0), {
		Font = Theme.Font.Text,
		AlignX = Enum.TextXAlignment.Left,
		Wrap = true,
		Auto = Enum.AutomaticSize.Y,
		Order = 1,
	})
	label.LineHeight = 1.1
	return strip
end

-- A progress bar: an outlined track with a Fill whose X scale code sets.
function UIKit.Bar(parent: Instance?, name: string, size: UDim2): Frame
	local track = UIKit.Frame(parent, name, size, Color.Blue100)
	UIKit.Corner(track)
	local ring = Instance.new("UIStroke")
	ring.Thickness = Line.Thin
	ring.Color = Color.Ink
	ring.Parent = track
	local fill = UIKit.Frame(track, "Fill", UDim2.fromScale(0, 1), Color.Blue500)
	UIKit.Corner(fill)
	return track
end

-- Sheep tokens -----------------------------------------------------------------------------------------------------

-- Layers of the token, bottom to top, and whether code tints them.
local TOKEN_LAYERS: { { string } } = {
	{ "Legs", "TokenLegs" },
	{ "Wool", "TokenWool" },
	{ "Shine", "TokenShine" },
	{ "Spots", "TokenSpots" },
	{ "Horns", "TokenHorns" },
	{ "Antennae", "TokenAntennae" },
	{ "Face", "TokenFace" },
	{ "Tuft", "TokenTuft" },
	{ "Features", "TokenFeatures" },
}

-- The sheep token: one drawing for every breed and mutation, stacked ImageLabels that Style.PaintToken tints. With a
-- "?" (Mystery) for the unknown silhouette, a Lock, two Sparkles and a Count badge ("x3"), all hidden.
function UIKit.Token(parent: Instance?, size: number, name: string?): Frame
	local icons = Theme.Icons :: { [string]: string }
	local token = UIKit.Frame(parent, name or "Token", UDim2.fromOffset(size, size))
	for order, layer in TOKEN_LAYERS do
		local image = UIKit.Icon(token, layer[1], icons[layer[2]], size)
		image.Size = UDim2.fromScale(1, 1)
		image.ZIndex = order
		if layer[1] == "Wool" or layer[1] == "Tuft" then
			local rainbow = Instance.new("UIGradient")
			rainbow.Name = "Rainbow"
			rainbow.Color = Theme.Rainbow
			rainbow.Rotation = Theme.RainbowRotation
			rainbow.Enabled = false
			rainbow.Parent = image
		end
	end
	local mystery = UIKit.Text(token, "Mystery", "?", math.floor(size * 0.34), Color.Snow, UDim2.fromScale(1, 0.4), {
		Stroke = Color.Ink,
	})
	mystery.Position = UDim2.fromScale(0, 0.47)
	mystery.ZIndex = 20
	mystery.Visible = false
	local lock = UIKit.Icon(token, "Lock", Theme.Icons.Lock, math.floor(size * 0.5), Color.Blue100)
	lock.AnchorPoint = Vector2.new(0.5, 0.4)
	lock.Position = UDim2.fromScale(0.5, 0.5)
	lock.ZIndex = 21
	lock.Visible = false
	local first = UIKit.TintedIcon(token, "Sparkle1", "Sparkle", math.floor(size * 0.34), Color.Gold300)
	first.Position = UDim2.fromScale(-0.06, -0.04)
	first.ZIndex = 22
	first.Visible = false
	local second = UIKit.TintedIcon(token, "Sparkle2", "Sparkle", math.floor(size * 0.26), Color.Gold300)
	second.Position = UDim2.fromScale(0.74, 0.08)
	second.ZIndex = 22
	second.Visible = false
	local count = UIKit.Text(token, "Count", "x1", TextSize.Caption, Color.Snow, UDim2.fromOffset(0, 18), {
		Auto = Enum.AutomaticSize.X,
	})
	count.AnchorPoint = Vector2.new(1, 1)
	count.Position = UDim2.new(1, 6, 1, 4)
	count.BackgroundTransparency = 0
	count.BackgroundColor3 = Color.Ink
	count.ZIndex = 23
	count.Visible = false
	UIKit.Corner(count)
	UIKit.Padding(count, 5, 5, 0, 0)
	local minimum = Instance.new("UISizeConstraint")
	minimum.MinSize = Vector2.new(22, 18)
	minimum.Parent = count
	return token
end

-- A token on a rounded plate in its tier's pale colour (Style.PaintToken colours the plate too).
function UIKit.Plate(parent: Instance?, plateSize: number, tokenSize: number, name: string?): Frame
	local plate = UIKit.Frame(parent, name or "Plate", UDim2.fromOffset(plateSize, plateSize), Color.Blue100)
	UIKit.Corner(plate, if plateSize >= 60 then Radius.Card else Radius.Button)
	local rainbow = Instance.new("UIGradient")
	rainbow.Name = "Rainbow"
	rainbow.Color = Theme.Rainbow
	rainbow.Rotation = Theme.RainbowRotation
	rainbow.Enabled = false
	rainbow.Parent = plate
	local token = UIKit.Token(plate, tokenSize)
	token.AnchorPoint = Vector2.new(0.5, 0.5)
	token.Position = UDim2.fromScale(0.5, 0.5)
	return plate
end

-- Panels -----------------------------------------------------------------------------------------------------------

export type PanelKind = "Day" | "Night"

-- The dimmed world behind a menu: blue 950, never black. Covers the whole screen, notches included.
function UIKit.Backdrop(parent: Instance?, transparency: number?): Frame
	local backdrop = UIKit.Frame(parent, "Backdrop", UDim2.fromScale(3, 3), Color.Blue950)
	backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
	backdrop.Position = UDim2.fromScale(0.5, 0.5)
	backdrop.BackgroundTransparency = transparency or Theme.Motion.Backdrop
	backdrop.Active = true
	return backdrop
end

-- The cash in a panel's header, like the HUD's: the icon pack's bill stack and the amount in lime with a thick black
-- edge, straight on the world (no pill).
function UIKit.CashChip(parent: Instance?, name: string?): TextLabel
	local chip = UIKit.Text(parent, name or "CashLabel", "$...", 26, Color.Lime, UDim2.fromOffset(0, 36), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
	})
	UIKit.Padding(chip, 44, 4, 0, 0)
	-- The padding moves the bill too: -48 puts it 4 points left of the chip's edge, clear of the amount.
	local bill = UIKit.Icon(chip, "Bill", Theme.Icons.HudCash, 46)
	bill.AnchorPoint = Vector2.new(0, 0.5)
	bill.Position = UDim2.new(0, -48, 0.5, -1)
	return chip
end

-- A notice pill: a snow dot with an icon, and the words; Style.PaintNotice colours it good, bad or rare.
function UIKit.Notice(parent: Instance?, name: string): TextLabel
	local notice = UIKit.Text(parent, name, "", TextSize.Label, Color.Snow, UDim2.fromOffset(0, 38), {
		Stroke = Color.Green800,
		Auto = Enum.AutomaticSize.X,
	})
	notice.BackgroundTransparency = 0
	notice.BackgroundColor3 = Color.Green500
	UIKit.Corner(notice)
	UIKit.Padding(notice, 41, 16, 0, 0)
	UIKit.Surface(notice, Color.Green600, Theme.Lip.Small, Color.Ink)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 38)
	limit.Parent = notice
	local dot = UIKit.Frame(notice, "Dot", UDim2.fromOffset(28, 28), Color.Snow)
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, -36, 0.5, 0)
	UIKit.Corner(dot)
	local ring = Instance.new("UIStroke")
	ring.Thickness = Line.Thin
	ring.Color = Color.Ink
	ring.Parent = dot
	-- The dot's mark: a face to tint (Icon) under an ink layer (Ink) that Style.PaintNotice swaps per kind.
	for _, layer in { "Icon", "Ink" } do
		local image = UIKit.Icon(dot, layer, "", 20)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
	end
	local slide = Instance.new("UIScale")
	slide.Name = "Pop"
	slide.Parent = notice
	notice.Visible = false
	return notice
end

export type PanelLook = {
	Accent: string?, -- the family's colour (Theme.Fleece.Accent): Shop, Rebirth, Dex...
	Badge: string?, -- its picture over the header's corner
	Size: ("Large" | "Medium")?, -- L for shops and collections, M for one thing's page
	Width: number?, -- points, instead of its size's width
	TabsInHeader: boolean?, -- the tabs in the header, in the title's place (the Sheep Shop's, Mark 2026-10-03)
}

-- A menu's window (Prize Fleece): the opaque slate body, lit from the top, with an ink edge, a thick lip and a soft
-- shadow, under a header in the family's colour (`look`) holding its picture, the TitleLabel, a CashChip (CashLabel)
-- and the red CloseButton. Under the header, the TabBar (Tabs, in a well) when the menu has pages, then Pages, where
-- the screen's own pieces go; StatusLabel, a notice that slides up over the bottom edge; and a UIScale named Pop for
-- opening. With TabsInHeader the Tabs take the TitleLabel's place and the Pages start under the header. Scale sizes
-- the window from the safe area and its PanelWidth and PanelHeight; `maxWidth` narrows it.
function UIKit.Panel(
	parent: Instance?,
	kind: PanelKind,
	title: string,
	tabs: { TabSpec }?,
	maxWidth: number?,
	look: PanelLook?
): Frame
	local opts: PanelLook = look or {}
	local accent = UIKit.Accent(opts.Accent or (if kind == "Night" then "Den" else "Shop"))
	local size = if opts.Size == "Medium" then Fleece.Medium else Fleece.Large
	local width = opts.Width or size.X
	local tabsInHeader = tabs ~= nil and #tabs > 0 and opts.TabsInHeader == true
	local inset = Fleece.Inset
	local body = Fleece.Body
	local window = UIKit.Frame(parent, "Window", UDim2.fromOffset(width, size.Y), body.Hi)
	window:SetAttribute("Kind", kind)
	window:SetAttribute("PanelWidth", width)
	window:SetAttribute("PanelHeight", size.Y)
	window:SetAttribute("Glass", true)
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Active = true
	window.SelectionGroup = true
	window.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	window.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	window.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	window.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	if maxWidth then
		window:SetAttribute("MaxWidth", maxWidth)
	end
	UIKit.Lit(window, body.Hi, body.Lo, 1)
	UIKit.Corner(window, Fleece.Radius)
	UIKit.Surface(window, Color.Line, Fleece.Lip, Color.Line, Fleece.Outline, true)
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = window

	local head = header(window, accent, opts.Badge or "", if tabsInHeader then nil else title, Fleece.Title, true)
	UIKit.HeaderChip(head, "CashChip", Theme.Icons.HudCash, "CashLabel", "$...").LayoutOrder = 5

	local top = Fleece.Header + Fleece.Outline + inset
	if tabs and tabsInHeader then
		-- Its well is dark glass with an ink edge, as the header's chips are.
		local bar = UIKit.Tabs(head, tabs, accent)
		bar.LayoutOrder = 1
		bar.BackgroundTransparency = 0.5
		local edge = bar:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Thickness = Line.Normal
			edge.Transparency = 0
		end
	elseif tabs and #tabs > 0 then
		local bar = UIKit.Frame(window, "TabBar", UDim2.new(1, -2 * inset, 0, Fleece.TabBar))
		bar.Position = UDim2.fromOffset(inset, top)
		bar.ZIndex = 3
		local barList = UIKit.List(bar, true, 10)
		barList.VerticalAlignment = Enum.VerticalAlignment.Center
		UIKit.Tabs(bar, tabs, accent).LayoutOrder = 1
		local spacer = UIKit.Frame(bar, "Spacer", UDim2.fromOffset(0, 1))
		spacer.LayoutOrder = 2
		UIKit.Grow(spacer)
		top += Fleece.TabBar + inset - 2
	end
	window:SetAttribute("PagesTop", top)
	local pages = UIKit.Frame(window, "Pages", UDim2.new(1, -2 * inset, 1, -(top + inset)))
	pages.Position = UDim2.fromOffset(inset, top)
	pages.ZIndex = 2

	local status = UIKit.Notice(window, "StatusLabel")
	status.AnchorPoint = Vector2.new(0.5, 0.5)
	status.Position = UDim2.new(0.5, 0, 1, Fleece.Lip)
	status.ZIndex = 10
	return window
end

local GIVE_TEXT = 18 -- the confirm's prize words, big enough to read through their ink edge

-- The "are you sure?" card over a 45% backdrop: a small Prize Fleece pop-up (Dialog) in the Confirm family's blue,
-- its question as the header's TitleLabel; a Stage with the sheep's Token (and CountChip > CountLabel, "x8", when
-- several go at once), the NameLabel and the DetailLabel (one line); a gold GiveStrip (the rebirth's prize, hidden);
-- then CancelButton (Soft) on the left and ConfirmButton (Danger) on the right, where a quick thumb doesn't land first.
function UIKit.Confirm(parent: Instance?): Frame
	local cover = UIKit.Frame(parent, "Confirm", UDim2.fromScale(1, 1))
	cover.Active = true
	cover.Visible = false
	cover.ZIndex = 20
	local backdrop = UIKit.Backdrop(cover, Theme.Motion.ConfirmBackdrop)
	backdrop.ZIndex = 20
	local dialog, body = UIKit.PopCard(cover, "Dialog", {
		Width = Fleece.Small,
		Title = "Are you sure?",
		Accent = "Confirm",
		Badge = Theme.Icons.HudAlert,
		Gap = 9,
	})
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.SelectionGroup = true
	dialog.ZIndex = 21

	local stage = UIKit.Stage(body, "Stage", UDim2.new(1, 0, 0, 118), 10)
	stage.LayoutOrder = 1
	stage.Visible = false
	local token = UIKit.Token(stage, 104)
	token.AnchorPoint = Vector2.new(0.5, 0.5)
	token.Position = UDim2.fromScale(0.5, 0.5)
	token.ZIndex = 2
	local count = UIKit.DarkChip(stage, "CountChip", nil, "CountLabel")
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, -8, 0, 8)
	count.ZIndex = 3
	count.Visible = false
	UIKit.Text(body, "NameLabel", "", 26, Color.Snow, UDim2.new(1, 0, 0, 30), {
		Stroke = Color.Line,
		Fit = true,
		Order = 2,
	})
	UIKit.Text(body, "DetailLabel", "", 16, Fleece.Muted, UDim2.new(1, 0, 0, 0), {
		Font = Theme.Font.TextHeavy,
		Wrap = true,
		Rich = true,
		Auto = Enum.AutomaticSize.Y,
		Order = 3,
	})
	-- The prize in the rebirth menu's gold, its words white with an ink edge (Mark, 2026-10-03: the pale green was plain).
	local give = UIKit.Strip(body, "GiveStrip", "GiveLabel", Theme.Icons.Rosette, "")
	give.LayoutOrder = 4
	give.Visible = false
	UIKit.Lit(give, Fleece.Accent.Gold.Hi, Fleece.Accent.Gold.Lo, 1)
	UIKit.Surface(give, Color.Line, 3, Color.Line, Line.Normal)
	local giveLabel = give:FindFirstChild("GiveLabel") :: TextLabel
	giveLabel.FontFace = Theme.Font.Display
	giveLabel.TextSize = GIVE_TEXT
	giveLabel.TextColor3 = Color.Snow
	UIKit.TextStroke(giveLabel, Color.Line)

	local row = UIKit.Frame(body, "Buttons", UDim2.new(1, 0, 0, Theme.MinTouch + 4))
	row.LayoutOrder = 5
	UIKit.List(row, true, 10)
	local cancel = UIKit.Button(row, "CancelButton", "Soft", 100, Theme.ButtonHeight.Standard, "Cancel")
	cancel.LayoutOrder = 1
	UIKit.Grow(cancel)
	local ok = UIKit.Button(row, "ConfirmButton", "Danger", 150, Theme.ButtonHeight.Standard, "Release")
	ok.LayoutOrder = 2
	UIKit.Grow(ok)
	return cover
end

-- A menu's ScreenGui: the Backdrop, and in Root (scaled) the Window and the Confirm card. `confirm` false leaves the
-- card out (the Sheepdex and the store); `look` is the panel's family, picture and size.
function UIKit.MenuGui(
	name: string,
	kind: PanelKind,
	title: string,
	tabs: { TabSpec }?,
	confirm: boolean?,
	maxWidth: number?,
	look: PanelLook?
): (ScreenGui, Frame)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 10
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ClipToDeviceSafeArea = false
	UIKit.Backdrop(gui)
	local root = UIKit.Root(gui)
	local window = UIKit.Panel(root, kind, title, tabs, maxWidth, look)
	if confirm ~= false then
		UIKit.Confirm(root)
	end
	return gui, window
end

-- A card in a panel (a store product, the rebirth's parts, a setting): a raised slate tile (UIKit.Tile; Glass
-- attribute, so UIKit.LightText turns the words on it white), or a plain card in `color`.
function UIKit.Card(parent: Instance?, name: string, size: UDim2, color: Color3?): Frame
	if color then
		local card = UIKit.Frame(parent, name, size, color)
		UIKit.Corner(card, Radius.Card)
		return card
	end
	return UIKit.Tile(parent, name, size)
end

export type PopCardOptions = {
	Width: number?, -- points; nil: it grows with its content both ways (the Sheepdex find's toast)
	Title: string?, -- the header's TitleLabel; nil for no header (a toast)
	Close: boolean?, -- the red CloseButton at the header's right
	Horizontal: boolean?, -- the Body lays its content out left to right (a column by default)
	Gap: number?, -- points between the Body's pieces
	Edge: number?, -- unused since Prize Fleece (it was the glass's edge)
	Inset: number?, -- the margin inside the card (Theme.Fleece.Inset by default)
	Accent: string?, -- the header's family colour (Theme.Fleece.Accent): Daily, Confirm, Warning, Gold...
	Badge: string?, -- the picture over the header's corner
}

-- A pop-up card (Prize Fleece, the menus' panel at its small size): the slate body with its ink edge, lip and soft
-- shadow, under a header in its family's colour with its picture, the TitleLabel and the red CloseButton; Body holds
-- what the caller puts in it, laid out in a column (or a row), and the card grows with it. Without a title it's a
-- small slate toast. A UIScale named Pop for opening. Returns the card and its Body. The Starter Pack's card is built
-- with it in Edit (studio/BuildUI), the daily gift's and the Sheepdex finds' at run time.
function UIKit.PopCard(parent: Instance?, name: string, options: PopCardOptions?): (Frame, Frame)
	local opts: PopCardOptions = options or {}
	local width = opts.Width
	local title = opts.Title
	local inset = opts.Inset or Fleece.Inset
	local grow = if width then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY
	local body = Fleece.Body
	local card = UIKit.Frame(parent, name, UDim2.fromOffset(width or 0, 0), body.Hi)
	card.AutomaticSize = grow
	card.Active = true
	card:SetAttribute("Glass", true)
	UIKit.Lit(card, body.Hi, body.Lo, 1)
	UIKit.Corner(card, if title then Fleece.Radius else Fleece.TileRadius)
	UIKit.Surface(card, Color.Line, if title then Fleece.Lip else 4, Color.Line, Fleece.Outline, title ~= nil)
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = card

	local top = 0
	if title then
		-- Shrinks to fit a short screen as it opens (Motion.PopIn).
		card:SetAttribute("AutoFit", true)
		header(card, UIKit.Accent(opts.Accent or "Shop"), opts.Badge or "", title, Fleece.PopTitle, opts.Close == true)
		top = Fleece.Header + Fleece.Outline
	end
	local content = UIKit.Frame(card, "Body", if width then UDim2.fromScale(1, 0) else UDim2.new())
	content.AutomaticSize = grow
	content.Position = UDim2.fromOffset(0, top)
	content.ZIndex = 2
	UIKit.Padding(content, inset, inset, inset, inset + 2)
	local layout = UIKit.List(
		content,
		opts.Horizontal == true,
		opts.Gap or 8,
		if opts.Horizontal then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center
	)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return card, content
end

-- Dark words that ended up on the glass (a card, a row, or a page straight on the panel) in light ones, as a build's
-- last step: Ranch Studs' menus were Blue Ribbon's pale ones. Words on anything with a colour of its own (a chip, a
-- strip, a button, a plate) keep theirs.
local LIGHTER: { [string]: Color3 } = {
	[Color.Ink:ToHex()] = Color.Snow,
	[Color.Blue800:ToHex()] = Color.Snow,
	[Color.Line:ToHex()] = Color.Snow,
	[Color.Blue700:ToHex()] = Color.Blue100,
	[Color.Blue600:ToHex()] = Color.Blue200,
	[Color.Green600:ToHex()] = Color.Green300,
	[Color.Green800:ToHex()] = Color.Green300,
	[Color.Red600:ToHex()] = Color.Red300,
	[Color.Gold800:ToHex()] = Color.Gold300,
}

local function onGlass(label: GuiObject, stop: Instance): boolean
	local node = label.Parent
	while node and node ~= stop do
		if node:IsA("GuiObject") then
			if node:GetAttribute("Glass") == true then
				return true
			elseif node.BackgroundTransparency < 0.95 then
				return false
			end
		end
		node = node.Parent
	end
	return true
end

function UIKit.LightText(window: Instance)
	for _, label in window:GetDescendants() do
		-- Only labels: the UIKit buttons' own words are labels inside them.
		if label:IsA("TextLabel") and label.BackgroundTransparency >= 0.95 then
			local lighter = LIGHTER[label.TextColor3:ToHex()]
			if lighter and onGlass(label, window) then
				label.TextColor3 = lighter
				-- Big white words get the black edge; small print reads without one.
				if lighter == Color.Snow and label.TextSize >= 16 and not label:FindFirstChild("TextStroke") then
					UIKit.TextStroke(label, Color.Line)
				end
			end
		end
	end
end

-- A scrolling list in a panel's body, with rows 6 pt apart and a pale blue thumb. Gamepad selection goes to the rows'
-- buttons, never the list itself.
function UIKit.Scroller(parent: Instance?, name: string, size: UDim2, gap: number?): ScrollingFrame
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = name
	scroller.Size = size
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.ScrollBarThickness = 5
	scroller.ScrollBarImageColor3 = Color.Blue300
	scroller.ScrollBarImageTransparency = 0
	scroller.CanvasSize = UDim2.new()
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.Selectable = false
	scroller.SelectionGroup = false
	UIKit.List(scroller, false, gap or Theme.Menu.Inset)
	-- Room for the rows' glow rings at the edges.
	UIKit.Padding(scroller, 7, 9, 7, 7)
	scroller.Parent = parent
	return scroller
end

-- HUD --------------------------------------------------------------------------------------------------------------

local PICTURE_NAME = 18 -- a HUD picture's one-word name under it, in points
local PICTURE_NAME_DROP = 10 -- how far that name hangs below the picture
local OFFER_PILL = 22 -- an offer's price or time pill

-- A name in snow with a thick ink outline, for the HUD's pictures ("STORE", "WOLF GUARD").
local function pictureName(parent: Instance, text: string): TextLabel
	local label =
		UIKit.Text(parent, "NameLabel", text, PICTURE_NAME, Color.Snow, UDim2.new(1, 50, 0, PICTURE_NAME + 4), {
			Stroke = Color.Line,
		})
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.ZIndex = 3
	local stroke = label:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = 3.5
	end
	return label
end

-- A HUD button that is only its picture (Theme.Icons' Menu pictures: the Sheepdex book, the Store's basket, the
-- Settings gear), with no face colour, lip or box, and optionally a one-word `label` under it (NameLabel). A
-- TextButton with the Picture attribute, so Buttons squishes it and grows it under the mouse; its Face is clear and
-- round and holds the Icon and the hints' Glow rings, which pulse round it as a halo.
function UIKit.PictureButton(parent: Instance?, name: string, image: string, size: number, label: string?): TextButton
	local side = math.max(size, Theme.MinTouch)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(side, if label then side + PICTURE_NAME_DROP else side)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Text = ""
	button:SetAttribute("Picture", true)
	local squish = Instance.new("UIScale")
	squish.Name = "Squish"
	squish.Parent = button
	local face = UIKit.Frame(button, "Face", UDim2.fromOffset(size, size))
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = if label then UDim2.new(0.5, 0, 0, side / 2) else UDim2.fromScale(0.5, 0.5)
	face.ZIndex = 2
	UIKit.Corner(face)
	UIKit.Glow(face, Color.Snow, Color.Ink, Line.Thick)
	local picture = UIKit.Icon(face, "Icon", image, size)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, 0.5)
	if label then
		pictureName(button, label).Position = UDim2.fromScale(0.5, 1)
	end
	button.Parent = parent
	return button
end

-- A studded pill on the HUD in a button kind's colours (Theme.Button[kind]): an offer's Robux price (`icon` the Robux
-- glyph) or a boost's time left. Its words are `labelName`.
function UIKit.StudPill(parent: Instance?, name: string, kind: Kind, labelName: string, icon: string?): Frame
	local look = Theme.Button[kind]
	local pill = UIKit.Frame(parent, name, UDim2.fromOffset(0, OFFER_PILL), look.Face)
	pill.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(pill)
	UIKit.Surface(pill, look.Lip, Theme.Lip.Small, look.Outline)
	UIKit.Studs(pill)
	-- The icon and words in a row of their own: laid out in the pill itself, the studs would be one of the row's items.
	local line = UIKit.Frame(pill, "Line", UDim2.fromOffset(0, OFFER_PILL))
	line.AutomaticSize = Enum.AutomaticSize.X
	line.ZIndex = 2
	UIKit.Padding(line, if icon then 7 else 10, 10, 0, 0)
	UIKit.List(line, true, 3)
	if icon then
		UIKit.Icon(line, "Icon", icon, 14, look.Label).ZIndex = 2
	end
	local text = UIKit.Text(line, labelName, "", TextSize.Tab, look.Label, UDim2.fromOffset(0, OFFER_PILL), {
		Stroke = look.LabelStroke,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	text.ZIndex = 2
	return pill
end

-- One of the HUD's offers down the right (the Wolf Guard's shield, Fast Wool's lightning, the Starter Pack): its
-- picture on gold rays (Burst, which the HUD turns), its `label` under it, and under that the Robux price in a purple
-- pill (`<prefix>Price` > `<prefix>PriceLabel`) or, while it runs, the time left in a green one (`<prefix>Time` >
-- `<prefix>Label`), both hidden. A PictureButton, so it squishes and its Face glows like the menu pictures.
function UIKit.OfferButton(
	parent: Instance?,
	name: string,
	image: string,
	size: number,
	label: string,
	prefix: string
): TextButton
	local button = UIKit.PictureButton(nil, name, image, size)
	button.Size = UDim2.fromOffset(size + 44, size + PICTURE_NAME_DROP + OFFER_PILL)
	local face = button:FindFirstChild("Face") :: Frame
	face.Position = UDim2.new(0.5, 0, 0, size / 2)
	local burst = UIKit.Icon(button, "Burst", Theme.Icons.Burst, math.floor(size * 1.9), Color.Gold300)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = face.Position
	burst.ZIndex = 1
	pictureName(button, label).Position = UDim2.new(0.5, 0, 0, size + PICTURE_NAME_DROP)
	local price = UIKit.StudPill(button, `{prefix}Price`, "Robux", `{prefix}PriceLabel`, Theme.Icons.Robux)
	local time = UIKit.StudPill(button, `{prefix}Time`, "Buy", `{prefix}Label`)
	for _, pill in { price, time } do
		pill.AnchorPoint = Vector2.new(0.5, 1)
		pill.Position = UDim2.fromScale(0.5, 1)
		pill.ZIndex = 4
		pill.Visible = false
	end
	button.Parent = parent
	return button
end

-- A blue callout that points left at what's beside it (the hint's words next to a HUD button).
function UIKit.Callout(parent: Instance?, name: string, text: string): TextLabel
	local callout = UIKit.Text(parent, name, text, TextSize.Label, Color.Snow, UDim2.fromOffset(0, 36), {
		Stroke = Color.Ink,
		Auto = Enum.AutomaticSize.X,
	})
	callout.BackgroundTransparency = 0
	callout.BackgroundColor3 = Color.Blue500
	UIKit.Corner(callout, Radius.Button)
	UIKit.Padding(callout, 14, 14, 0, 0)
	UIKit.Surface(callout, Color.Blue700, Theme.Lip.Small, Color.Ink)
	local nib = UIKit.Frame(callout, "Nib", UDim2.fromOffset(12, 12), Color.Blue500)
	nib.AnchorPoint = Vector2.new(0.5, 0.5)
	nib.Position = UDim2.new(0, -14, 0.5, 0)
	nib.Rotation = 45
	nib.ZIndex = 0
	return callout
end

-- A snow HUD pill (the status chips, the carry hint, the goal line): lip in blue 200, ink outline.
function UIKit.Pill(parent: Instance?, name: string, height: number): Frame
	local pill = UIKit.Frame(parent, name, UDim2.fromOffset(0, height), Color.Snow)
	pill.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Corner(pill)
	UIKit.Surface(pill, Color.Blue200, Theme.Lip.Small, Color.Ink)
	UIKit.List(pill, true, 6)
	return pill
end

-- Arrows, banners, celebrations ----------------------------------------------------------------------------------

-- The pointer, drawn pointing down: a face to tint (the pointer's own colour) under its ink outline and shine, or with
-- `key` "WolfPointer" the wolf alert's plain triangle with a thin black edge. Code turns it (Rotation) towards what it
-- points at.
function UIKit.Pointer(parent: Instance?, name: string, size: number, tint: Color3, key: string?): ImageLabel
	local icons = Theme.Icons :: { [string]: string }
	local art = key or "Pointer"
	local pointer = UIKit.Icon(parent, name, icons[`{art}Fill`], size, tint)
	local ink = UIKit.Icon(pointer, "Ink", icons[`{art}Ink`], size)
	ink.Size = UDim2.fromScale(1, 1)
	return pointer
end

export type ArrowKind = "Guide" | "Wolf" | "Own"

-- The guide's arrow (UI_SPEC 1.7): a bubble with the words (Label), an optional snow line under it (SubLabel, with a
-- SubBar for progress), and the Pointer in its PointerSlot. A plain Frame: the guide moves its parts into a CanvasGroup
-- only while it waits (50% and grey), since a CanvasGroup softens everything in it. The slot is what the list lays
-- out: a UIListLayout draws its children unrotated, so a Pointer placed straight in the list never turned.
-- Wolves' arrows are just their words, dark red ("WOLF!") with a very thin black edge, or navy over the player's own
-- raid wolf, with no bubble or face, and a small plain triangle for a pointer in the same colour, which the wolf alert
-- shows only on the screen's edge (Mark, 2026-10-03: the filled bubble was too much; he picked the triangle and the
-- dark red from mock-ups).
function UIKit.Arrow(parent: Instance?, name: string, kind: ArrowKind): Frame
	local wolf = kind ~= "Guide"
	local wolfColor = if kind == "Wolf" then Color.Red700 else Color.Blue700
	local pointerColor = if wolf then wolfColor else Color.Blue400
	local pointerSize = if wolf then 30 else 46
	local arrow = Instance.new("Frame")
	arrow.Name = name
	arrow.BackgroundTransparency = 1
	arrow.BorderSizePixel = 0
	arrow.Size = UDim2.fromOffset(0, 0)
	arrow.AutomaticSize = Enum.AutomaticSize.XY
	arrow.AnchorPoint = Vector2.new(0.5, 1)
	arrow.Visible = false
	-- Room round the bubble for its outline and lip, which the waiting guide arrow's CanvasGroup would otherwise cut off.
	UIKit.Padding(arrow, 6, 6, 6, 6)
	UIKit.List(arrow, false, 6, Enum.HorizontalAlignment.Center)
	if wolf then
		local size = TextSize.Title + 4
		local label = UIKit.Text(arrow, "Label", "", size, wolfColor, UDim2.fromOffset(0, size + 6), {
			Stroke = Color.Line,
			Auto = Enum.AutomaticSize.X,
			Order = 1,
		})
		local edge = label:FindFirstChildOfClass("UIStroke")
		if edge then
			edge.Thickness = 1.2
		end
	else
		local size = TextSize.Title
		local label = UIKit.Text(arrow, "Label", "", size, Color.Snow, UDim2.fromOffset(0, size + 16), {
			Stroke = Color.Ink,
			Auto = Enum.AutomaticSize.X,
			Order = 1,
		})
		label.BackgroundTransparency = 0
		label.BackgroundColor3 = Color.Blue500
		UIKit.Corner(label, Radius.Button)
		UIKit.Padding(label, 16, 16, 0, 0)
		UIKit.Surface(label, Color.Blue700, Theme.Lip.Button, Color.Ink, Line.Thick)
	end
	local sub = UIKit.Text(arrow, "SubLabel", "", TextSize.Body, Color.Ink, UDim2.fromOffset(0, 24), {
		Font = Theme.Font.Text,
		Auto = Enum.AutomaticSize.X,
		Order = 2,
	})
	sub.BackgroundTransparency = 0
	sub.BackgroundColor3 = Color.Snow
	sub.Visible = false
	UIKit.Corner(sub)
	UIKit.Padding(sub, 10, 10, 0, 0)
	UIKit.Surface(sub, nil, 0, Color.Ink, Line.Thin)
	local bar = UIKit.Bar(sub, "SubBar", UDim2.fromOffset(60, 8))
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(1, 8, 0.5, 0)
	bar.Visible = false
	local slot = UIKit.Frame(arrow, "PointerSlot", UDim2.fromOffset(pointerSize, pointerSize))
	slot.LayoutOrder = 3
	local pointer = UIKit.Pointer(slot, "Pointer", pointerSize, pointerColor, if wolf then "WolfPointer" else nil)
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Position = UDim2.fromScale(0.5, 0.5)
	arrow.Parent = parent
	return arrow
end

-- The raid's line: plain red words with the red notices' black edge, straight over the game, with no box or wolf face
-- (Mark, 2026-10-03). The TextLabel itself.
function UIKit.Banner(parent: Instance?, name: string): TextLabel
	local banner = UIKit.Text(parent, name, "", TextSize.Big, Color.Red500, UDim2.fromOffset(0, TextSize.Big + 6), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
	})
	banner.Visible = false
	return banner
end

-- A celebration ("2 sheep!", "RAINBOW x10!"): snow rays behind big words. `name` is the words' TextLabel; the frame
-- around them holds the UIScale Pop that Motion.Celebrate springs.
function UIKit.Celebration(parent: Instance?, frameName: string, labelName: string): Frame
	local holder = UIKit.Frame(parent, frameName, UDim2.fromOffset(320, 120))
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false
	local pop = Instance.new("UIScale")
	pop.Name = "Pop"
	pop.Parent = holder
	local burst = UIKit.Icon(holder, "Burst", Theme.Icons.Burst, 230, Color.Snow)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, 0.5)
	burst.ImageTransparency = 0.45
	local label = UIKit.Text(holder, labelName, "2 sheep!", TextSize.Hero, Color.Snow, UDim2.fromScale(1, 1), {
		Stroke = Color.Ink,
	})
	label.ZIndex = 2
	UIKit.CelebrationLine(holder)
	return holder
end

-- A celebration's one short line under its big words ("White fence + 0.5x wool multiplier!"), hidden until it has one; made here
-- for a celebration built before it had one.
function UIKit.CelebrationLine(holder: Frame): TextLabel
	local found = holder:FindFirstChild("LineLabel")
	if found and found:IsA("TextLabel") then
		return found
	end
	local line =
		UIKit.Text(holder, "LineLabel", "", TextSize.Big, Color.Gold300, UDim2.new(1.6, 0, 0, TextSize.Big + 6), {
			Stroke = Color.Ink,
		})
	line.AnchorPoint = Vector2.new(0.5, 0)
	line.Position = UDim2.new(0.5, 0, 0.5, TextSize.Hero / 2 + 4)
	line.ZIndex = 2
	line.Visible = false
	return line
end

-- The gamepad's selection ring: a snow ring 3.5 pt outside the selected button, then an ink one
-- (PlayerGui.SelectionImageObject).
function UIKit.SelectionRing(parent: Instance?): Frame
	local ring = UIKit.Frame(parent, "SelectionRing", UDim2.fromScale(1, 1))
	UIKit.Corner(ring, Radius.Button)
	UIKit.Glow(ring, Color.Snow, Color.Ink, 2)
	for _, child in ring:GetChildren() do
		if child:IsA("UIStroke") then
			child.Enabled = true
		end
	end
	return ring
end

-- A speech bubble over someone in the world (the kennel keeper's, KeeperTalk): a snow box with an ink outline holding
-- the speaker's name (NameLabel) over their words (LineLabel, wrapped to `width` points), and a tail (Tail) under it
-- pointing down at them. A plain list of the box and the tail, so the code places it by the tail's tip (its anchor).
function UIKit.SpeechBubble(parent: Instance?, name: string, width: number): Frame
	local bubble = UIKit.Frame(nil, name, UDim2.fromOffset(width, 0))
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.AnchorPoint = Vector2.new(0.5, 1)
	bubble.Visible = false
	-- The tail tucks up over the box's outline and lip, so the two read as one shape.
	UIKit.List(bubble, false, -(Line.Thick * 2 + Theme.Lip.Small), Enum.HorizontalAlignment.Center)
	local box = UIKit.Frame(bubble, "Box", UDim2.fromScale(1, 0), Color.Snow)
	box.AutomaticSize = Enum.AutomaticSize.Y
	box.LayoutOrder = 1
	UIKit.Corner(box, Radius.Card)
	UIKit.Padding(box, 14, 14, 6, 9)
	UIKit.Surface(box, Color.Blue200, Theme.Lip.Small, Color.Ink, Line.Thick)
	UIKit.List(box, false, 0, Enum.HorizontalAlignment.Center)
	UIKit.Text(box, "NameLabel", "", TextSize.Caption, Color.Blue500, UDim2.new(1, 0, 0, TextSize.Caption + 4), {
		Order = 1,
	})
	local line = UIKit.Text(box, "LineLabel", "", TextSize.Label, Color.Ink, UDim2.fromScale(1, 0), {
		Wrap = true,
		Order = 2,
	})
	line.AutomaticSize = Enum.AutomaticSize.Y
	-- The tail: the lower half of a snow diamond with an ink edge, cut off at the box's edge by a clipping frame.
	local tail = UIKit.Frame(bubble, "Tail", UDim2.fromOffset(26, 14))
	tail.ClipsDescendants = true
	tail.LayoutOrder = 2
	local diamond = UIKit.Frame(tail, "Diamond", UDim2.fromOffset(18, 18), Color.Snow)
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.fromScale(0.5, 0)
	diamond.Rotation = 45
	local edge = Instance.new("UIStroke")
	edge.Color = Color.Ink
	edge.Thickness = Line.Thick
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Parent = diamond
	bubble.Parent = parent
	return bubble
end

return table.freeze(UIKit)
