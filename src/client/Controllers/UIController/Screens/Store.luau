--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local PlayerSettings = require(ReplicatedStorage.Utils.PlayerSettings)
local Remotes = require(ReplicatedStorage.Remotes)
local Store = require(ReplicatedStorage.Config.Store)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local MenuParts = require(script.Parent.Parent.MenuParts)
local Panel = require(script.Parent.Parent.Panel)
local Prices = require(script.Parent.Parent.Prices)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The Robux store (the user, 2026-10-05; mock-up E): Shear a Sheep's one page that scrolls, in its purple, with every
-- card's picture filling it and growing with the pack. Sections: Sheep (Golden Fleece and Kronos Sheep, Robux only),
-- Passes (2x Money, 2x Growth), Speed (2x Speed, whose price triples with each buy until sold out, and the stair
-- walker's next level for Robux or cash), Climbing (six packs) and Cash (five). The section tabs stand outside the
-- window on its right, close to it; the lit one is the section in view and a tap scrolls there. The server picks the
-- product and opens Roblox's dialog (StoreService); this screen only asks. Gamepad: B closes.
local StoreScreen = {}

local Color = Theme.Color
local GAP = 10
local SECTION_GAP = 16
local HEAD_HEIGHT = 30
local CARD_RADIUS = 13
local SHEEP_HEIGHT = 236
local PASS_HEIGHT = 150
local HERO_HEIGHT = 150
local WALKER_HEIGHT = 112
local TILE_HEIGHT = 222
local TILE_ART = 160
local TAB_GAP = 6 -- points between the window's edge and its tabs
local TAB_WIDTH = 74
local TAB_FACE = 60
local TAB_TOP = 74
local GOLD = Color3.fromRGB(255, 216, 74)
local SHEEP_PERKS = { "Arrives grown" }
local SCROLL_TIME = 0.35
local SCROLL_MARGIN = 6
local BACK_ACTION = "StoreBack"
local PRICE_SIZE = 24
local PRICE_HERO = 32

local CLIMB_ART = {
	Theme.Icons.StoreClimb1,
	Theme.Icons.StoreClimb2,
	Theme.Icons.StoreClimb3,
	Theme.Icons.StoreClimb4,
	Theme.Icons.StoreClimb5,
	Theme.Icons.StoreClimb6,
}
local CASH_ART = {
	Theme.Icons.StoreCash1,
	Theme.Icons.StoreCash2,
	Theme.Icons.StoreCash3,
	Theme.Icons.StoreCash4,
	Theme.Icons.StoreCash5,
}

local TINTS = {
	GoldenFleece = Color3.fromRGB(250, 180, 20),
	Kronos = Color3.fromRGB(146, 64, 232),
	DoubleMoney = Color3.fromRGB(46, 178, 80),
	DoubleGrowth = Color3.fromRGB(240, 100, 40),
	Speed = Color3.fromRGB(30, 120, 245),
	Walker = Color3.fromRGB(23, 173, 158),
	Climb = Color3.fromRGB(34, 150, 224),
	Cash = Color3.fromRGB(46, 178, 80),
}

type SectionSpec = { Name: string, Title: string, Tab: string, Icon: string }
local SECTIONS: { SectionSpec } = {
	{ Name = "Sheep", Title = "SHEEP", Tab = "Sheep", Icon = Theme.Icons.Wool },
	{ Name = "Passes", Title = "PASSES", Tab = "Passes", Icon = Theme.Icons.HudCrown },
	{ Name = "Speed", Title = "SPEED", Tab = "Speed", Icon = Theme.Icons.HudBoost },
	{ Name = "Climb", Title = "CLIMBING", Tab = "Climb", Icon = Theme.Icons.HudShoe },
	{ Name = "Cash", Title = "CASH", Tab = "Cash", Icon = Theme.Icons.HudCash },
}

-- A card's instance name: its key without the dot.
local function cardName(key: string): string
	return (string.gsub(key, "%.", ""))
end

local function hex(color: Color3): string
	return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
end

-- "+150K" in gold, then "CLIMB" smaller in white: a pack's amount over its picture.
local function goldWords(gold: string, word: string, wordSize: number): string
	return `<font color="{hex(GOLD)}">{gold}</font> <font size="{wordSize}">{word}</font>`
end

-- A card: its colour, lighter at the top, with the header's studs and the thick ink edge.
local function card(parent: Instance, name: string, size: UDim2, tint: Color3): Frame
	local frame = UIKit.Frame(parent, cardName(name), size, tint)
	frame.BackgroundTransparency = 0
	UIKit.Corner(frame, CARD_RADIUS)
	UIKit.Studs(frame, CARD_RADIUS)
	UIKit.Edge(frame, 3)
	local shade = Instance.new("UIGradient")
	shade.Name = "Shade"
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(165, 165, 165))
	shade.Parent = frame
	return frame
end

-- A picture on white rays, as big as fits in `size` (Art: Rays, Picture).
local function art(parent: Instance, size: UDim2, image: string): Frame
	local holder = UIKit.Frame(parent, "Art", size)
	holder.ZIndex = 2
	for _, name in { "Rays", "Picture" } do
		local picture = UIKit.Icon(holder, name, if name == "Rays" then Theme.Icons.Burst else image, 100)
		picture.AnchorPoint = Vector2.new(0.5, 0.5)
		picture.Position = UDim2.fromScale(0.5, 0.5)
		picture.Size = UDim2.fromScale(1, 1)
		picture.ScaleType = Enum.ScaleType.Fit
		if name == "Rays" then
			picture.ImageTransparency = 0.7
			Instance.new("UIAspectRatioConstraint").Parent = picture
		else
			picture.ZIndex = 3
		end
	end
	return holder
end

-- A sheep's own model on rays (Art: Rays, View), shown when the store opens (MenuParts.ShowSheep).
local function sheepArt(parent: Instance, size: UDim2): Frame
	local holder = art(parent, size, "")
	local picture = holder:FindFirstChild("Picture")
	if picture then
		picture:Destroy()
	end
	local view = Instance.new("ViewportFrame")
	view.Name = "View"
	view.BackgroundTransparency = 1
	view.Size = UDim2.fromScale(1, 1)
	view.ZIndex = 3
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.fromRGB(255, 255, 255)
	view.Parent = holder
	return holder
end

local function label(
	parent: Instance,
	name: string,
	text: string,
	size: number,
	frame: UDim2,
	rich: boolean?
): TextLabel
	local words = UIKit.Text(parent, name, text, size, Color.Snow, frame, {
		Stroke = Color.Line,
		Rich = rich,
		AlignX = Enum.TextXAlignment.Left,
	})
	words.ZIndex = 4
	return words
end

local function small(parent: Instance, name: string, text: string, frame: UDim2): TextLabel
	local words = UIKit.Text(parent, name, text, Theme.TextSize.Body, Color.Snow, frame, {
		Font = Theme.Font.TextHeavy,
		AlignX = Enum.TextXAlignment.Left,
	})
	UIKit.TextStroke(words, Color.Line).Thickness = 1.5
	words.ZIndex = 4
	return words
end

local function chip(parent: Instance, text: string, gold: boolean): GuiObject
	if gold then
		local frame = UIKit.GoldChip(parent, "Chip", text)
		frame.ZIndex = 6
		return frame
	end
	local frame = UIKit.DarkChip(parent, "Chip", nil, "ChipLabel", true)
	local words = frame:FindFirstChild("ChipLabel", true)
	if words and words:IsA("TextLabel") then
		words.Text = text
	end
	frame.ZIndex = 6
	return frame
end

local function buyButton(parent: Instance, width: number, height: number?): TextButton
	local faceHeight = height or Theme.ButtonHeight.Standard
	local button = UIKit.Button(parent, "BuyButton", "Robux", width, faceHeight, "...")
	button.ZIndex = 5
	-- The price as big as the mock-ups': a size up from a button's usual label.
	local size = if faceHeight >= Theme.ButtonHeight.Hero then PRICE_HERO else PRICE_SIZE
	local line = button:FindFirstChild("Line", true)
	local words = line and line:FindFirstChild("Label")
	local icon = line and line:FindFirstChild("Icon")
	if line and line:IsA("Frame") and words and words:IsA("TextLabel") and icon and icon:IsA("ImageLabel") then
		line.Size = UDim2.fromOffset(0, size + 4)
		words.TextSize = size
		words.Size = UDim2.fromOffset(0, size + 4)
		icon.Size = UDim2.fromOffset(math.floor(size * 1.05), math.floor(size * 1.05))
	end
	return button
end

-- A button across a card's foot (between `left` and `right` points in from its sides).
local function foot(parent: Instance, left: number, right: number, height: number?): TextButton
	local button = buyButton(parent, 100, height)
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, left, 1, -4)
	button.Size = UDim2.new(1, -(left + right), 0, button.Size.Y.Offset)
	return button
end

local function perks(parent: Instance, lines: { string }, align: Enum.HorizontalAlignment): Frame
	local holder = UIKit.Frame(parent, "Perks", UDim2.new())
	holder.AutomaticSize = Enum.AutomaticSize.XY
	holder.ZIndex = 4
	UIKit.List(holder, false, 2, align)
	for index, text in lines do
		local row = UIKit.Frame(holder, `Perk{index}`, UDim2.fromOffset(0, 19))
		row.AutomaticSize = Enum.AutomaticSize.X
		row.LayoutOrder = index
		UIKit.List(row, true, 4).VerticalAlignment = Enum.VerticalAlignment.Center
		UIKit.Icon(row, "Icon", Theme.Icons.CheckWhite, 15, Color.Green300).ZIndex = 4
		local words = UIKit.Text(row, "PerkLabel", text, Theme.TextSize.Body, Color.Snow, UDim2.fromOffset(0, 19), {
			Auto = Enum.AutomaticSize.X,
			Order = 1,
		})
		UIKit.TextStroke(words, Color.Line).Thickness = 2
		words.ZIndex = 4
	end
	return holder
end

-- A section: its head (picture, name in capitals, a rule) and its cards' rows.
local function section(list: Instance, order: number, spec: SectionSpec): Frame
	local holder = UIKit.Frame(list, `{spec.Name}Section`, UDim2.fromScale(1, 0))
	holder.AutomaticSize = Enum.AutomaticSize.Y
	holder.LayoutOrder = order
	UIKit.List(holder, false, 8)
	local head = UIKit.Frame(holder, "Head", UDim2.new(1, 0, 0, HEAD_HEIGHT))
	head.LayoutOrder = 0
	UIKit.List(head, true, 8).VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Icon(head, "Icon", spec.Icon, 28)
	UIKit.Text(head, "NameLabel", spec.Title, 18, Color.Snow, UDim2.fromOffset(0, HEAD_HEIGHT), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local rule = UIKit.Frame(head, "Rule", UDim2.fromOffset(0, 3), Color.Snow)
	rule.BackgroundTransparency = 0.92
	rule.LayoutOrder = 2
	UIKit.Corner(rule, 2)
	UIKit.Grow(rule)
	return holder
end

-- A row of cards side by side; each card's width is its share of the row (`units` of the total).
local function row(holder: Instance, order: number, height: number): Frame
	local frame = UIKit.Frame(holder, `Row{order}`, UDim2.new(1, 0, 0, height))
	frame.LayoutOrder = order
	UIKit.List(frame, true, GAP)
	return frame
end

local function share(units: number, total: number, count: number): UDim2
	return UDim2.new(units / total, -GAP * (count - 1) * units / total, 1, 0)
end

-- A pack: its picture filling the top, the amount over the picture's foot, the price at the bottom.
local function tile(
	parent: Instance,
	key: string,
	image: string,
	amount: string,
	word: string,
	tint: Color3,
	size: UDim2
): Frame
	local frame = card(parent, key, size, tint)
	art(frame, UDim2.new(1, -12, 0, TILE_ART), image).Position = UDim2.fromOffset(6, 4)
	local words =
		UIKit.Text(frame, "AmountLabel", goldWords(amount, word, 19), 25, Color.Snow, UDim2.new(1, -8, 0, 30), {
			Stroke = Color.Line,
			Rich = true,
			Fit = true,
		})
	words.AnchorPoint = Vector2.new(0.5, 0)
	words.Position = UDim2.new(0.5, 0, 0, TILE_ART - 30)
	words.ZIndex = 4
	foot(frame, 8, 8)
	return frame
end

function StoreScreen.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Store", "Day", "Store", nil, false, nil, {
		Accent = "Store",
		Badge = Theme.Icons.MenuStore,
		Width = 780,
	})
	window:SetAttribute("SideRoom", TAB_GAP + TAB_WIDTH + 8)
	local header = window:FindFirstChild("Header")
	local cashChip = header and header:FindFirstChild("CashChip", true)
	if cashChip then
		cashChip:Destroy()
	end
	local pages = window:FindFirstChild("Pages") :: Frame
	local well = UIKit.Well(pages, "Well", UDim2.fromScale(1, 1))
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	-- No bar: the tabs outside the window show where you are (the user, 2026-10-05).
	list.ScrollBarThickness = 0
	list.ScrollBarImageTransparency = 1
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	list.Selectable = false
	UIKit.List(list, false, SECTION_GAP)
	UIKit.Padding(list, 10, 14, 10, 16)
	list.Parent = well

	-- Sheep: the first offer's big card, the second's tall one.
	local sheepSection = section(list, 1, SECTIONS[1])
	local sheepRow = row(sheepSection, 1, SHEEP_HEIGHT)
	for index, offer in Store.Sheep do
		local robux = Economy.RobuxSheep[offer.Family]
		local lines = { `{robux.Times}x your best sheep` }
		for _, text in SHEEP_PERKS do
			table.insert(lines, text)
		end
		local breed = GameConfig.Breeds[offer.Family]
		if index == 1 then
			if breed and breed.SpecialFX == "GoldSparkles" then
				table.insert(lines, "Gold sparkles")
			end
			local frame = card(sheepRow, offer.Key, share(2, 3, 2), TINTS[offer.Family] or TINTS.Kronos)
			frame.LayoutOrder = index
			chip(frame, "ROBUX ONLY", false).Position = UDim2.fromOffset(8, 8)
			sheepArt(frame, UDim2.new(0.56, 0, 1, -20)).Position = UDim2.fromOffset(-4, 12)
			local words = UIKit.Frame(frame, "Words", UDim2.new(0.5, -10, 1, -70))
			words.Position = UDim2.new(0.5, 0, 0, 22)
			words.ZIndex = 4
			UIKit.List(words, false, 8)
			label(words, "NameLabel", robux.Name, 34, UDim2.new(1, 0, 0, 72)).TextWrapped = true
			perks(words, lines, Enum.HorizontalAlignment.Left).LayoutOrder = 1
			foot(frame, 0, 10).Position = UDim2.new(0.5, 0, 1, -4)
			local button = frame:FindFirstChild("BuyButton") :: TextButton
			button.Size = UDim2.new(0.5, -10, 0, button.Size.Y.Offset)
		else
			local frame = card(sheepRow, offer.Key, share(1, 3, 2), TINTS[offer.Family] or TINTS.Kronos)
			frame.LayoutOrder = index
			chip(frame, "ROBUX ONLY", false).Position = UDim2.fromOffset(8, 8)
			sheepArt(frame, UDim2.new(1, 0, 0, 86)).Position = UDim2.fromOffset(0, 24)
			local name = UIKit.Text(frame, "NameLabel", robux.Name, 22, Color.Snow, UDim2.new(1, -12, 0, 26), {
				Stroke = Color.Line,
				Fit = true,
			})
			name.Position = UDim2.fromOffset(6, 108)
			name.ZIndex = 4
			local list2 = perks(frame, lines, Enum.HorizontalAlignment.Center)
			list2.AnchorPoint = Vector2.new(0.5, 0)
			list2.Position = UDim2.new(0.5, 0, 0, 136)
			foot(frame, 8, 8)
		end
	end

	-- Passes: two side by side.
	local passSection = section(list, 2, SECTIONS[2])
	local passRow = row(passSection, 1, PASS_HEIGHT)
	for index, pass in Store.Passes do
		local frame = card(passRow, pass.Key, share(1, 2, 2), TINTS[pass.Key] or TINTS.Cash)
		frame.LayoutOrder = index
		local picture = if pass.Key == "DoubleMoney" then Theme.Icons.StoreMoney else Theme.Icons.StoreGrowth
		art(frame, UDim2.fromOffset(132, 132), picture).Position = UDim2.fromOffset(2, 6)
		local words = UIKit.Frame(frame, "Words", UDim2.new(1, -144, 0, 70))
		words.Position = UDim2.fromOffset(136, 18)
		words.ZIndex = 4
		UIKit.List(words, false, 4)
		local gold, word = string.match(pass.Name, "^(%S+)%s+(.+)$")
		label(
			words,
			"NameLabel",
			goldWords(gold or "", string.upper(word or pass.Name), 24),
			36,
			UDim2.new(1, 0, 0, 38),
			true
		)
		small(words, "LineLabel", pass.Line, UDim2.new(1, 0, 0, 18)).LayoutOrder = 1
		foot(frame, 140, 10)
	end

	-- Speed: the 2x Speed banner, then the stair walker's next level.
	local speedSection = section(list, 3, SECTIONS[3])
	local heroRow = row(speedSection, 1, HERO_HEIGHT)
	local hero = card(heroRow, "Speed", UDim2.fromScale(1, 1), TINTS.Speed)
	chip(hero, "CHEAP!", true).Position = UDim2.new(1, -96, 0, 8)
	art(hero, UDim2.fromOffset(236, 142), Theme.Icons.StoreSpeed).Position = UDim2.fromOffset(0, 4)
	local heroWords = UIKit.Frame(hero, "Words", UDim2.new(1, -420, 0, 90))
	heroWords.Position = UDim2.fromOffset(236, 22)
	heroWords.ZIndex = 4
	UIKit.List(heroWords, false, 4)
	label(heroWords, "NameLabel", goldWords("2x", "SPEED", 40), 52, UDim2.new(1, 0, 0, 54), true)
	small(heroWords, "LineLabel", "Double your Climbing", UDim2.new(1, 0, 0, 20)).LayoutOrder = 1
	local column = UIKit.Frame(hero, "BuyColumn", UDim2.new(0, 160, 1, 0))
	column.AnchorPoint = Vector2.new(1, 0)
	column.Position = UDim2.new(1, -12, 0, 0)
	column.ZIndex = 5
	local columnList = UIKit.List(column, false, 2, Enum.HorizontalAlignment.Center)
	columnList.VerticalAlignment = Enum.VerticalAlignment.Center
	buyButton(column, 160, Theme.ButtonHeight.Hero).LayoutOrder = 1
	local nextLabel = UIKit.Text(column, "NextLabel", "", Theme.TextSize.Body, Color.Snow, UDim2.new(1, 0, 0, 18), {
		Font = Theme.Font.TextHeavy,
		Order = 2,
	})
	UIKit.TextStroke(nextLabel, Color.Line).Thickness = 1.5

	local walkerRow = row(speedSection, 2, WALKER_HEIGHT)
	local walker = card(walkerRow, "Walker", UDim2.fromScale(1, 1), TINTS.Walker)
	art(walker, UDim2.fromOffset(104, 104), Theme.Icons.StoreWalker).Position = UDim2.fromOffset(4, 4)
	local walkerWords = UIKit.Frame(walker, "Words", UDim2.new(1, -440, 0, 64))
	walkerWords.Position = UDim2.fromOffset(116, 22)
	walkerWords.ZIndex = 4
	UIKit.List(walkerWords, false, 4)
	label(walkerWords, "NameLabel", "Stair Walker", 28, UDim2.new(1, 0, 0, 30))
	local level = UIKit.Frame(walkerWords, "LevelRow", UDim2.fromOffset(0, 24))
	level.AutomaticSize = Enum.AutomaticSize.X
	level.LayoutOrder = 1
	UIKit.List(level, true, 6).VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Text(level, "NowLabel", "", 21, Color.Snow, UDim2.fromOffset(0, 24), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	UIKit.Icon(level, "Arrow", Theme.Icons.ChevronWhite, 13).LayoutOrder = 2
	UIKit.Text(level, "NextLabel", "", 21, Color.Lime, UDim2.fromOffset(0, 24), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 3,
	})
	local buttons = UIKit.Frame(walker, "Buttons", UDim2.new(0, 300, 1, 0))
	buttons.AnchorPoint = Vector2.new(1, 0)
	buttons.Position = UDim2.new(1, -12, 0, 0)
	buttons.ZIndex = 5
	local buttonList = UIKit.List(buttons, true, 8, Enum.HorizontalAlignment.Right)
	buttonList.VerticalAlignment = Enum.VerticalAlignment.Center
	buyButton(buttons, 128).LayoutOrder = 1
	local orLabel = UIKit.Text(buttons, "OrLabel", "or", Theme.TextSize.Body, Color.Snow, UDim2.fromOffset(18, 20), {
		Font = Theme.Font.TextHeavy,
		Order = 2,
	})
	UIKit.TextStroke(orLabel, Color.Line).Thickness = 1.5
	local cashButton = UIKit.Button(buttons, "CashButton", "Buy", 128, Theme.ButtonHeight.Standard, "...")
	cashButton.LayoutOrder = 3

	-- Climbing: six packs, three to a row; the last says it's the best value.
	local climbSection = section(list, 4, SECTIONS[4])
	for index, pack in Store.Climb do
		local holder = climbSection:FindFirstChild(`Row{(index - 1) // 3 + 1}`)
			or row(climbSection, (index - 1) // 3 + 1, TILE_HEIGHT)
		local frame = tile(
			holder,
			pack.Key,
			CLIMB_ART[index] or Theme.Icons.HudShoe,
			`+{Format.Short(pack.Amount)}`,
			"CLIMB",
			TINTS.Climb,
			share(1, 3, 3)
		)
		frame.LayoutOrder = index
		if index == #Store.Climb then
			local best = chip(frame, "BEST VALUE", true)
			best.AnchorPoint = Vector2.new(0.5, 0)
			best.Position = UDim2.new(0.5, 0, 0, 6)
		end
	end

	-- Cash: three, then the fourth beside the biggest, two cards wide.
	local cashSection = section(list, 5, SECTIONS[5])
	local cashRows = { row(cashSection, 1, TILE_HEIGHT), row(cashSection, 2, TILE_HEIGHT) }
	for index, pack in Store.Cash do
		if index < #Store.Cash then
			local frame = tile(
				cashRows[if index <= 3 then 1 else 2],
				pack.Key,
				CASH_ART[index] or Theme.Icons.HudCash,
				`+{Format.Short(pack.Amount)}`,
				"CASH",
				TINTS.Cash,
				if index <= 3 then share(1, 3, 3) else share(1, 3, 2)
			)
			frame.LayoutOrder = index
		else
			local frame = card(cashRows[2], pack.Key, share(2, 3, 2), TINTS.Cash)
			frame.LayoutOrder = index
			art(frame, UDim2.fromOffset(220, 214), CASH_ART[index] or Theme.Icons.HudCash).Position =
				UDim2.fromOffset(4, 4)
			local words = UIKit.Text(
				frame,
				"AmountLabel",
				`<font color="{hex(GOLD)}">+{Format.Short(pack.Amount)}</font><br/><font size="30">CASH</font>`,
				50,
				Color.Snow,
				UDim2.new(1, -236, 0, 100),
				{ Stroke = Color.Line, Rich = true }
			)
			words.Position = UDim2.fromOffset(226, 28)
			words.ZIndex = 4
			foot(frame, 230, 12, Theme.ButtonHeight.Hero)
			local best = chip(frame, "BEST VALUE", true)
			best.AnchorPoint = Vector2.new(1, 0)
			best.Position = UDim2.new(1, -10, 0, 8)
		end
	end

	-- The tabs, outside the window on its right.
	local tabs = UIKit.Frame(window, "SectionTabs", UDim2.fromOffset(TAB_WIDTH, 0))
	tabs.AutomaticSize = Enum.AutomaticSize.Y
	tabs.Position = UDim2.new(1, TAB_GAP, 0, TAB_TOP)
	tabs.ZIndex = 5
	-- Smaller on a short window, so all five fit beside it (StoreScreen.new sets it).
	local tabScale = Instance.new("UIScale")
	tabScale.Name = "Fit"
	tabScale.Parent = tabs
	UIKit.List(tabs, false, 2, Enum.HorizontalAlignment.Center)
	for index, spec in SECTIONS do
		local button = Instance.new("TextButton")
		button.Name = `{spec.Name}Tab`
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(TAB_WIDTH, TAB_FACE + 16)
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Text = ""
		button.Selectable = true
		local on = UIKit.Frame(button, "On", UDim2.fromOffset(TAB_FACE, TAB_FACE - 4))
		on.AnchorPoint = Vector2.new(0.5, 0)
		on.Position = UDim2.fromScale(0.5, 0)
		UIKit.Lit(on, Theme.Fleece.Accent.Store.Hi, Theme.Fleece.Accent.Store.Base, 0.7)
		on.BackgroundTransparency = 0
		UIKit.Corner(on, 14)
		UIKit.Surface(on, Theme.Fleece.Accent.Store.Lo, 4, Color.Line, Theme.Line.Normal)
		UIKit.Studs(on, 14)
		on.Visible = false
		local icon = UIKit.Icon(button, "Icon", spec.Icon, 46)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 5)
		icon.ZIndex = 2
		local words = UIKit.Text(button, "TabLabel", spec.Tab, 17, Color.Snow, UDim2.new(1, 0, 0, 20), {
			Stroke = Color.Line,
		})
		words.AnchorPoint = Vector2.new(0.5, 1)
		words.Position = UDim2.new(0.5, 0, 1, 0)
		words.ZIndex = 3
		button.Parent = tabs
	end

	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

function StoreScreen.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local player = Players.LocalPlayer
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local tabs = window:FindFirstChild("SectionTabs") :: Frame
	local isOpen = false
	local busy = false
	local scrollTween: Tween? = nil
	local pinned: string? = nil
	local lit: string? = nil

	local function find(name: string): Instance
		local found = window:FindFirstChild(cardName(name), true)
		assert(found, `Store has no {cardName(name)}`)
		return found
	end
	local function buttonIn(holder: Instance, name: string?): TextButton
		return holder:FindFirstChild(name or "BuyButton", true) :: TextButton
	end

	local function cash(): number
		local value = player:GetAttribute("Coins")
		return if type(value) == "number" then value else 0
	end

	local function setRobux(button: TextButton, key: string)
		local price = Prices.Of(key)
		Buttons.Set(button, "Robux", if price then Format.Short(price) else "...")
		Buttons.SetIcon(button, Theme.Icons.Robux, true)
	end

	local function setDone(button: TextButton, text: string)
		Buttons.Set(button, "Disabled", text)
		Buttons.SetIcon(button, Theme.Icons.CheckWhite, true)
	end

	local function refresh()
		local data = stateController:Get()
		for _, offer in Store.Sheep do
			setRobux(buttonIn(find(offer.Key)), offer.Key)
		end
		for _, pass in Store.Passes do
			local frame = find(pass.Key) :: Frame
			local owned = player:GetAttribute(Store.PassAttribute(pass.Key)) == true
			if owned then
				setDone(buttonIn(frame), "Owned")
			else
				setRobux(buttonIn(frame), pass.Key)
			end
		end

		local hero = find("Speed")
		local heroButton = buttonIn(hero)
		local nextLabel = hero:FindFirstChild("NextLabel", true) :: TextLabel
		local buys = if type(data.SpeedBuys) == "number" then data.SpeedBuys else 0
		if buys >= #Store.SpeedPrices then
			setDone(heroButton, "Sold out")
			nextLabel.Text = ""
		else
			setRobux(heroButton, Store.SpeedKey(buys + 1))
			local after = Store.SpeedPrices[buys + 2]
			nextLabel.Text = if after then `Next: {Format.Short(after)}` else "Last one"
		end

		local walker = find("Walker")
		local walkerLevel = if type(data.WalkerLevel) == "number" then data.WalkerLevel else 0
		local nowLabel = walker:FindFirstChild("NowLabel", true) :: TextLabel
		local nextLevel = walker:FindFirstChild("NextLabel", true) :: TextLabel
		local robuxButton = buttonIn(walker)
		local cashButton = buttonIn(walker, "CashButton")
		local cost = Economy.WalkerCost(walkerLevel)
		nowLabel.Text = `Lv {walkerLevel + 1}`
		if cost then
			nextLevel.Text = tostring(walkerLevel + 2)
			setRobux(robuxButton, Store.WalkerKey(walkerLevel))
			Buttons.Set(cashButton, if cash() >= cost then "Buy" else "CantAfford", Format.Short(cost))
			Buttons.SetIcon(cashButton, Theme.Icons.HudCash)
		else
			nextLevel.Text = "MAX"
			setDone(robuxButton, "MAX")
			setDone(cashButton, "MAX")
		end

		for _, listOfPacks in { Store.Climb, Store.Cash } do
			for _, pack in listOfPacks do
				setRobux(buttonIn(find(pack.Key)), pack.Key)
			end
		end
	end

	local function showSheep()
		for _, offer in Store.Sheep do
			local view = find(offer.Key):FindFirstChild("View", true)
			if view and view:IsA("ViewportFrame") and not view:FindFirstChildOfClass("WorldModel") then
				MenuParts.ShowSheep(view, offer.Family)
			end
		end
	end

	local function say(text: string, kind: Style.NoticeKind)
		panel.Status(text, kind)
		if Style.IsProblem(kind) then
			sound:Play("Denied")
		end
	end

	-- Asks the server for `key`; it opens Roblox's dialog (or, in Studio, grants one that isn't on Roblox yet).
	local function buy(key: string, button: TextButton)
		if busy or Buttons.IsStill(button) then
			return
		end
		busy = true
		Buttons.Loading(button, true)
		task.spawn(function()
			local ok, done, message = Remotes.RequestPurchase:Invoke(key)
			Buttons.Loading(button, false)
			busy = false
			if not ok then
				say("Couldn't reach the server, try again", "Bad")
			elseif not done then
				say(message or "Can't buy that right now", "Bad")
			elseif message then
				say(message, "Good")
				sound:Play("Purchase")
			end
			refresh()
		end)
	end

	for _, offer in Store.Sheep do
		local button = buttonIn(find(offer.Key))
		trove:Connect(button.Activated, function()
			buy(offer.Key, button)
		end)
	end
	for _, pass in Store.Passes do
		local button = buttonIn(find(pass.Key))
		trove:Connect(button.Activated, function()
			buy(pass.Key, button)
		end)
	end
	local heroButton = buttonIn(find("Speed"))
	trove:Connect(heroButton.Activated, function()
		buy("Speed", heroButton)
	end)
	local walker = find("Walker")
	local walkerRobux = buttonIn(walker)
	trove:Connect(walkerRobux.Activated, function()
		buy("Walker", walkerRobux)
	end)
	-- The cash price is the shop's own purchase.
	local walkerCash = buttonIn(walker, "CashButton")
	trove:Connect(walkerCash.Activated, function()
		if busy or Buttons.IsStill(walkerCash) then
			return
		end
		if Buttons.Kind(walkerCash) == "CantAfford" then
			Buttons.Shake(walkerCash)
			say("Not enough cash", "Bad")
			return
		end
		busy = true
		Buttons.Loading(walkerCash, true)
		task.spawn(function()
			local ok, success, message = Remotes.Buy:Invoke("Walker", nil)
			Buttons.Loading(walkerCash, false)
			busy = false
			if not ok then
				say("Couldn't reach the server, try again", "Bad")
			elseif message then
				say(message, if success then "Good" else "Bad")
				if success then
					sound:Play("Upgrade")
				end
			end
			refresh()
		end)
	end)
	for _, listOfPacks in { Store.Climb, Store.Cash } do
		for _, pack in listOfPacks do
			local button = buttonIn(find(pack.Key))
			trove:Connect(button.Activated, function()
				buy(pack.Key, button)
			end)
		end
	end

	-- The section in view: the last one whose head has reached the top quarter of the list, or the last one once the
	-- list is scrolled to its end. A tab's own scroll keeps its section lit until the player scrolls on.
	local function sectionInView(): string
		if pinned then
			return pinned
		end
		local top = list.AbsolutePosition.Y + list.AbsoluteSize.Y / 4
		local current = SECTIONS[1].Name
		for _, spec in SECTIONS do
			local frame = list:FindFirstChild(`{spec.Name}Section`)
			if frame and frame:IsA("GuiObject") and frame.AbsolutePosition.Y <= top then
				current = spec.Name
			end
		end
		local bottom = list.CanvasPosition.Y + list.AbsoluteWindowSize.Y
		if list.CanvasPosition.Y > 0 and bottom >= list.AbsoluteCanvasSize.Y - 2 then
			return SECTIONS[#SECTIONS].Name
		end
		return current
	end

	local function lightTabs()
		local current = sectionInView()
		if current == lit then
			return
		end
		lit = current
		for _, spec in SECTIONS do
			local tab = tabs:FindFirstChild(`{spec.Name}Tab`)
			local on = tab and tab:FindFirstChild("On")
			if on and on:IsA("GuiObject") then
				on.Visible = spec.Name == current
			end
		end
	end

	local function scrollTo(name: string)
		local frame = list:FindFirstChild(`{name}Section`)
		if not frame or not frame:IsA("GuiObject") then
			return
		end
		-- CanvasPosition counts drawn pixels.
		local offset = frame.AbsolutePosition.Y - list.AbsolutePosition.Y
		local most = math.max(0, list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y)
		local target = Vector2.new(0, math.clamp(list.CanvasPosition.Y + offset - SCROLL_MARGIN, 0, most))
		if scrollTween then
			scrollTween:Cancel()
		end
		pinned = name
		lightTabs()
		if PlayerSettings.ReduceMotion() then
			list.CanvasPosition = target
			return
		end
		local tween = TweenService:Create(
			list,
			TweenInfo.new(SCROLL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CanvasPosition = target }
		)
		scrollTween = tween
		tween.Completed:Once(function()
			if scrollTween == tween then
				scrollTween = nil
			end
		end)
		tween:Play()
	end

	for _, spec in SECTIONS do
		local tab = tabs:FindFirstChild(`{spec.Name}Tab`) :: TextButton
		trove:Connect(tab.Activated, function()
			scrollTo(spec.Name)
		end)
	end
	-- The tabs start under the header where the window is tall enough, and higher up beside it on a short one (a
	-- phone held sideways), shrinking only as much as they still must.
	local tabScale = tabs:FindFirstChild("Fit") :: UIScale
	local function fitTabs()
		local natural = #SECTIONS * (TAB_FACE + 16) + (#SECTIONS - 1) * 2
		local height = window.Size.Y.Offset
		local top = math.clamp(height - natural - 8, 8, TAB_TOP)
		tabs.Position = UDim2.new(1, TAB_GAP, 0, top)
		tabScale.Scale = math.clamp((height - top - 8) / natural, 0.5, 1)
	end
	trove:Connect(window:GetPropertyChangedSignal("Size"), fitTabs)
	fitTabs()
	trove:Connect(list:GetPropertyChangedSignal("CanvasPosition"), function()
		if not scrollTween then
			pinned = nil
		end
		lightTabs()
	end)

	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close(gui.Name)
		end)
	end
	local function refreshIfOpen()
		if isOpen then
			refresh()
		end
	end
	trove:Add(stateController.Changed:Connect(refreshIfOpen))
	trove:Add(Prices.Changed:Connect(refreshIfOpen))
	trove:Connect(player.AttributeChanged, function(name: string)
		if name == "Coins" or string.sub(name, 1, 4) == "Pass" then
			refreshIfOpen()
		end
	end)

	gui.Enabled = false

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			list.CanvasPosition = Vector2.zero
			pinned = nil
			lit = nil
			refresh()
			showSheep()
			panel.Show()
			lightTabs()
			ContextActionService:BindActionAtPriority(
				BACK_ACTION,
				function(_action: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
					if state == Enum.UserInputState.Begin then
						context.Close(gui.Name)
					end
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value,
				Enum.KeyCode.ButtonB
			)
		end,
		Close = function(_self: Types.Screen)
			isOpen = false
			if scrollTween then
				scrollTween:Cancel()
				scrollTween = nil
			end
			ContextActionService:UnbindAction(BACK_ACTION)
			panel.Hide(function() end)
		end,
		Destroy = function(_self: Types.Screen)
			ContextActionService:UnbindAction(BACK_ACTION)
			trove:Clean()
			gui:Destroy()
		end,
		Notify = function(_self: Types.Screen, message: string, kind: string)
			panel.Status(message, Style.NoticeKindOf(kind))
		end,
	}
end

return StoreScreen
