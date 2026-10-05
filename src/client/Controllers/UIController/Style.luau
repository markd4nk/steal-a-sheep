--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Theme = require(ReplicatedStorage.Config.Theme)
local UIKit = require(ReplicatedStorage.Utils.UIKit)

local Color = Theme.Color
local Icons = Theme.Icons

-- Good and Rare news come in pills; problems as words straight over the game: a raid's or a wolf's in red after the
-- warning sign (Raid), everyday ones in yellow on their own (Bad).
export type NoticeKind = "Good" | "Bad" | "Rare" | "Raid"

-- A bar's fill as last set: where it's heading, and what's moving it.
type Fill = {
	Share: number?, -- nil until first set: the first length shows at once
	Done: boolean?,
	Grow: Tween?,
	Pulse: Tween?,
}

local fills: { [GuiObject]: Fill } = setmetatable({}, { __mode = "k" }) :: any

-- A notice's pill, as built (pillOf).
type Pill = {
	TextSize: number,
	PadLeft: UDim,
	PadRight: UDim,
	DotSize: UDim2,
	DotPosition: UDim2,
	IconSize: UDim2,
	Size: UDim2,
	MaxSize: Vector2,
	Wrapped: boolean,
	AutoSize: Enum.AutomaticSize,
}

local pills: { [TextLabel]: Pill } = setmetatable({}, { __mode = "k" }) :: any

-- A problem's notice: the guide's objective's size ("Buy a sheep"), a raid's after a warning sign this many points
-- across. Words too long for the notice's width go on two lines of about the same length (shrunk to fit one, the
-- longest went too small to read), in a box this much wider than half of them so a word that won't break evenly doesn't
-- make a third.
local PROBLEM_SIZE = Theme.TextSize.Title + 4
local PROBLEM_HEIGHT = 120 -- the most a problem's lines may stand
local PROBLEM_ICON = 40
local PROBLEM_GAP = 4
local PROBLEM_WRAP = 1.15
local WHITE = Color3.new(1, 1, 1) -- the warning sign's own colours, untinted

-- Painting helpers the screens share: sheep tokens, chips, notices, and small text helpers.
local Style = {
	Green = Color.Green600, -- good news in text
	Red = Color.Red600, -- problems in text
}

local function image(parent: Instance, name: string): ImageLabel?
	local found = parent:FindFirstChild(name)
	return if found and found:IsA("ImageLabel") then found else nil
end

local function setRainbow(target: Instance, on: boolean)
	local gradient = target:FindFirstChild("Rainbow")
	if gradient and gradient:IsA("UIGradient") then
		gradient.Enabled = on
	end
end

-- Tints a sheep token for a breed and its mutation (Utils/SheepToken).
local function paintChip(chip: Instance, background: Color3, text: Color3, gem: Color3?, rainbow: boolean?)
	if chip:IsA("GuiObject") then
		chip.BackgroundColor3 = background
	end
	setRainbow(chip, rainbow == true)
	local label = chip:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.TextColor3 = text
	end
	local icon = chip:FindFirstChild("Icon")
	local fill = icon and image(icon, "Fill")
	if fill then
		fill.ImageColor3 = if rainbow then Color3.new(1, 1, 1) else gem or Color.Snow
		setRainbow(fill, rainbow == true)
	end
end

-- A tier's chip: its gem and name on its pale colour ("UNCOMMON").
function Style.PaintTierChip(chip: Instance, tierName: string)
	if chip:GetAttribute("Fleece") == true then
		Style.PaintRarity(chip, tierName)
		return
	end
	local tier = Theme.Tier[tierName]
	local label = chip:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = string.upper(tierName)
	end
	if tier then
		paintChip(chip, tier.Chip, tier.ChipText, tier.Gem, tier.Rainbow)
	end
end

-- A row on the glass panel (Ranch Studs), tinted with its tier's colour over the glass; `dim` for one that can't be
-- had yet (a breed still locked) takes no tint.
function Style.PaintRow(row: GuiObject, tierName: string, dim: boolean?)
	-- A Prize Fleece row (a slate tile): its picture's box takes the tier's colour instead.
	if row:GetAttribute("Fleece") == true then
		local pic = row:FindFirstChild("Pic")
		if pic and pic:IsA("GuiObject") then
			local look = Theme.Fleece.Rarity[if dim then "Locked" else tierName] or Theme.Fleece.Rarity.Locked
			UIKit.Lit(pic, look.Hi, look.Lo, 1)
		end
		return
	end
	local tier = Theme.Tier[tierName]
	local glass = Theme.Glass
	local tint = if tier and not dim then tier.Gem else Color.Glass
	row.BackgroundColor3 = Color.Glass:Lerp(tint, glass.RowTint)
	row.BackgroundTransparency = glass.Row
end

-- Prize Fleece -------------------------------------------------------------------------------------------------------

-- A tier's look on a card, chip or stage (Theme.Fleece.Rarity), or the locked one.
local function rarityLook(tierName: string?): { Hi: Color3, Base: Color3, Lo: Color3 }
	local rarity = Theme.Fleece.Rarity
	return if tierName and rarity[tierName] then rarity[tierName] else rarity.Locked
end

-- A sheep card (UIKit.SheepCard) in its tier's colour, or dark while `locked`.
function Style.PaintCard(card: Instance, tierName: string, locked: boolean?)
	local face = card:FindFirstChild("Face")
	if face and face:IsA("GuiObject") then
		local look = rarityLook(if locked then nil else tierName)
		UIKit.Lit(face, look.Hi, look.Lo, 1)
	end
end

-- A rarity chip (UIKit.RarityChip): its colour and its name in capitals.
function Style.PaintRarity(chip: Instance, tierName: string)
	local look = rarityLook(tierName)
	if chip:IsA("GuiObject") then
		UIKit.Lit(chip, look.Hi, look.Base, 1)
	end
	local lip = chip:FindFirstChild("Lip")
	if lip and lip:IsA("UIShadow") then
		lip.Color = look.Lo
	end
	local label = chip:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = string.upper(tierName)
	end
end

-- A mutation's badge on a rarity chip (UIKit.RarityChip): "GOLD x3" in the mutation's colour, Rainbow in the rainbow;
-- `short` leaves the multiplier off ("GOLD"), for a small card that needs the room.
-- A stage (UIKit.Stage) in a tier's colour, or a family's (Theme.Fleece.Accent) for a pop-up's.
function Style.PaintStage(stage: Instance, tierName: string?, accent: string?)
	if not stage:IsA("GuiObject") then
		return
	end
	local look = if accent then UIKit.Accent(accent) else rarityLook(tierName)
	UIKit.Lit(stage, look.Hi, look.Lo, 1)
end

-- Lights an upgrade's pips (UIKit.Pips): one green a level, the next one dim green; all gold once maxed.
function Style.SetPips(pips: Instance, level: number, maxed: boolean)
	for _, pip in pips:GetChildren() do
		if pip:IsA("Frame") then
			local index = tonumber(string.match(pip.Name, "^Pip(%d+)$"))
			if index then
				local on = index <= level
				pip.BackgroundColor3 = if maxed then Color.Gold500 elseif on then Color.Green500 else Color.Green300
				pip.BackgroundTransparency = if on or maxed then 0 elseif index == level + 1 then 0.6 else 0.93
				if not on and not maxed and index ~= level + 1 then
					pip.BackgroundColor3 = Color.Snow
				end
			end
		end
	end
end

-- A mutation's chip: "GOLD x3" with its sparkle.
function Style.PaintPlainChip(chip: Instance, kind: ("Plain" | "Good" | "Bad")?)
	if kind == "Good" then
		paintChip(chip, Color.Green100, Color.Green800)
	elseif kind == "Bad" then
		paintChip(chip, Color.Red100, Color.Red600)
	else
		paintChip(chip, Color.Blue100, Color.Blue700)
	end
end

-- A notice's pill as UIKit.Notice built it, read before its first paint, so good news can go back to it after a
-- problem took the box away.
local function pillOf(notice: TextLabel): Pill
	local known = pills[notice]
	if known then
		return known
	end
	local padding = notice:FindFirstChildOfClass("UIPadding")
	local limit = notice:FindFirstChildOfClass("UISizeConstraint")
	local dot = notice:FindFirstChild("Dot")
	local icon = if dot then image(dot, "Icon") else nil
	local pill: Pill = {
		TextSize = notice.TextSize,
		PadLeft = if padding then padding.PaddingLeft else UDim.new(),
		PadRight = if padding then padding.PaddingRight else UDim.new(),
		DotSize = if dot and dot:IsA("GuiObject") then dot.Size else UDim2.new(),
		DotPosition = if dot and dot:IsA("GuiObject") then dot.Position else UDim2.new(),
		IconSize = if icon then icon.Size else UDim2.new(),
		Size = notice.Size,
		MaxSize = if limit then limit.MaxSize else Vector2.new(math.huge, math.huge),
		Wrapped = notice.TextWrapped,
		AutoSize = notice.AutomaticSize,
	}
	pills[notice] = pill
	return pill
end

-- A kind named in a string (menus hear the HUD's notices that way); anything else is an everyday problem.
function Style.NoticeKindOf(kind: string): NoticeKind
	return if kind == "Good" then "Good" elseif kind == "Rare" then "Rare" elseif kind == "Raid" then "Raid" else "Bad"
end

-- Whether a notice is a problem: it shows at once, shakes, and has no pill.
function Style.IsProblem(kind: NoticeKind): boolean
	return kind == "Bad" or kind == "Raid"
end

-- A notice (UIKit.Notice) in its kind: good news a green pill with a check, rare news a gold one with a sparkle, and a
-- problem no pill at all, just words in the guide's look ("Buy a sheep": its size and ink outline, straight over the
-- game): a raid's or a wolf's red after the pack's warning sign, an everyday one ("Not enough cash") yellow on its own
-- (Mark, 2026-10-03: the red box was too big, and red is for raids).
function Style.PaintNotice(notice: TextLabel, kind: NoticeKind)
	local pill = pillOf(notice)
	local bare = Style.IsProblem(kind)
	local marked = kind == "Raid" -- the warning sign before the words
	local face: Color3, lip: Color3, stroke: Color3, fill: string, fillTint: Color3, ink: string?
	if kind == "Good" then
		face, lip, stroke = Color.Green500, Color.Green600, Color.Green800
		fill, fillTint, ink = Icons.CheckWhite, Color.Green600, nil
	elseif kind == "Rare" then
		face, lip, stroke = Color.Gold500, Color.Gold600, Color.Gold800
		fill, fillTint, ink = Icons.SparkleFill, Color.Gold500, Icons.SparkleInk
	elseif kind == "Raid" then
		face, lip, stroke = Color.Red500, Color.Red600, Color.Line
		fill, fillTint, ink = Icons.HudWarning, WHITE, nil
	else
		face, lip, stroke = Color.Gold500, Color.Gold600, Color.Line
		fill, fillTint, ink = "", WHITE, nil
	end
	notice.BackgroundColor3 = face
	notice.BackgroundTransparency = if bare then 1 else 0
	for _, child in notice:GetChildren() do
		if child:IsA("UIShadow") then
			child.Enabled = not bare
		end
	end
	local lipShadow = notice:FindFirstChild("Lip")
	if lipShadow and lipShadow:IsA("UIShadow") then
		lipShadow.Color = lip
	end
	notice.TextColor3 = if marked then Color.Red500 elseif bare then Color.Gold300 else Color.Snow
	notice.TextSize = if bare then PROBLEM_SIZE else pill.TextSize
	-- Roblox's own sizing wraps at whatever width the label had, so a problem too long for one line gets its width.
	local beside = if marked then PROBLEM_ICON + PROBLEM_GAP else 0
	local room = pill.MaxSize.X - beside - 2 * UIKit.StrokeWidth(PROBLEM_SIZE)
	local width = if bare
		then TextService:GetTextSize(notice.Text, PROBLEM_SIZE, Enum.Font.FredokaOne, Vector2.new(math.huge, math.huge)).X
		else 0
	local wraps = width > room
	notice.TextWrapped = if bare then wraps else pill.Wrapped
	notice.AutomaticSize = if wraps then Enum.AutomaticSize.Y elseif bare then Enum.AutomaticSize.X else pill.AutoSize
	notice.Size = if wraps
		then UDim2.fromOffset(math.min(room, math.ceil(width / 2 * PROBLEM_WRAP)) + beside, pill.Size.Y.Offset)
		else pill.Size
	local limit = notice:FindFirstChildOfClass("UISizeConstraint")
	if limit then
		limit.MaxSize = if bare then Vector2.new(pill.MaxSize.X, PROBLEM_HEIGHT) else pill.MaxSize
	end
	local textStroke = notice:FindFirstChild("TextStroke")
	if textStroke and textStroke:IsA("UIStroke") then
		textStroke.Color = stroke
		textStroke.Thickness = UIKit.StrokeWidth(notice.TextSize)
	end
	local padding = notice:FindFirstChildOfClass("UIPadding")
	if padding then
		padding.PaddingLeft = if bare then UDim.new(0, beside) else pill.PadLeft
		padding.PaddingRight = if bare then UDim.new() else pill.PadRight
	end
	local dot = notice:FindFirstChild("Dot")
	if dot and dot:IsA("GuiObject") then
		dot.Visible = marked or not bare
		dot.BackgroundTransparency = if bare then 1 else 0
		local ring = dot:FindFirstChildOfClass("UIStroke")
		if ring then
			ring.Enabled = not bare
		end
		dot.Size = if bare then UDim2.fromOffset(PROBLEM_ICON, PROBLEM_ICON) else pill.DotSize
		dot.Position = if bare then UDim2.new(0, -(PROBLEM_ICON + PROBLEM_GAP), 0.5, 0) else pill.DotPosition
		local icon = image(dot, "Icon")
		if icon then
			icon.Image = fill
			icon.ImageColor3 = fillTint
			icon.Size = if bare then UDim2.fromScale(1, 1) else pill.IconSize
		end
		local inkLayer = image(dot, "Ink")
		if inkLayer then
			inkLayer.Image = ink or ""
			inkLayer.Visible = ink ~= nil
		end
	end
end

-- A strip's kind: blue 100 small print, or red for a problem ("Pen full").
function Style.PaintStrip(strip: Instance, isWarning: boolean, icon: string?)
	if strip:IsA("GuiObject") then
		strip.BackgroundColor3 = if isWarning then Color.Red100 else Color.Blue100
	end
	for _, child in strip:GetChildren() do
		if child:IsA("TextLabel") then
			child.TextColor3 = if isWarning then Color.Red800 else Color.Blue800
		elseif child:IsA("ImageLabel") and child.Name == "Icon" then
			child.Image = icon or (if isWarning then Icons.Alert else Icons.Info)
		end
	end
end

-- Sets a progress bar's fill (0 to 1), green once it's full or `done`. The fill slides to its new length, and a
-- full or done bar breathes between two greens so "ready" catches the eye. Reduce Motion: it jumps and stays still.
function Style.SetBar(bar: Instance, progress: number, done: boolean?)
	local fill = bar:FindFirstChild("Fill")
	if not fill or not fill:IsA("GuiObject") then
		return
	end
	local share = math.clamp(progress, 0, 1)
	local isDone = done == true or share >= 1
	local still = PlayerSettings.ReduceMotion()
	local state = fills[fill]
	if not state then
		state = { Share = nil, Done = nil, Grow = nil, Pulse = nil }
		fills[fill] = state
	end
	local current = state :: Fill
	if share ~= current.Share then
		local first = current.Share == nil
		current.Share = share
		local running = current.Grow
		if running then
			running:Cancel()
			current.Grow = nil
		end
		local target = UDim2.fromScale(share, 1)
		if still or first then
			fill.Size = target
			fill.Visible = share > 0
		else
			if not fill.Visible then
				-- An empty bar grows from nothing, not from the length it had before it emptied.
				fill.Size = UDim2.fromScale(0, 1)
				fill.Visible = true
			end
			local grow = TweenService:Create(fill, Theme.Motion.BarFill, { Size = target })
			current.Grow = grow
			grow.Completed:Once(function(playback: Enum.PlaybackState)
				if playback == Enum.PlaybackState.Completed and current.Grow == grow then
					current.Grow = nil
					fill.Visible = share > 0
				end
			end)
			grow:Play()
		end
	end
	-- Repainted when it fills or empties, or when Reduce Motion changes whether it should breathe.
	local breathes = isDone and not still
	if isDone ~= current.Done or (current.Pulse ~= nil) ~= breathes then
		current.Done = isDone
		local pulse = current.Pulse
		if pulse then
			pulse:Cancel()
			current.Pulse = nil
		end
		-- A Prize Fleece meter (UIKit.Meter) says its own colours.
		local filling = bar:GetAttribute("FillColor")
		local full = bar:GetAttribute("DoneColor")
		local doneColor = if typeof(full) == "Color3" then full else Color.Green500
		fill.BackgroundColor3 = if isDone
			then doneColor
			elseif typeof(filling) == "Color3" then filling
			else Color.Blue500
		if breathes then
			local breathe = TweenService:Create(fill, Theme.Motion.BarReady, { BackgroundColor3 = Color.Green300 })
			current.Pulse = breathe
			breathe:Play()
		end
	end
end

-- 1.6 -> "1.6", 45 -> "45", 16500 -> "16.5K"
-- A mutation's word among white words, where its own colour won't do: Silver's is nearly white.
return table.freeze(Style)
