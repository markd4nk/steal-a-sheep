--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local MenuParts = require(script.Parent.Parent.MenuParts)
local Panel = require(script.Parent.Parent.Panel)
local SheepIcon = require(script.Parent.Parent.SheepIcon)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The Sell Stall (Mark's pick A of DESIGN/ui/mockups/sell-stall.html, after Steal an Egg's Sell Pets): the stored
-- sheep as cards, cheapest first, tap the ones to sell (or Select all), and one Sell for all of them in the tile on the
-- right, after a confirm. Sheep in the pen never show here, so the best ones can't be sold by mistake; locked ones show
-- dark with their padlock. It opens with nothing picked.
local SellStall = {}

type View = {
	Id: string,
	Family: string,
	Rarity: number,
	Size: number,
	Rank: number,
	Locked: boolean,
	Slot: number,
	Adult: boolean,
	Sell: number,
}

local Color = Theme.Color
local Fleece = Theme.Fleece

local SORTS = { "Cheapest", "Best" }
local FAN = 4 -- tokens shown in the tile's fan of what's picked
local FAN_TOKEN = 42
local FAN_STEP = 27 -- each token overlaps the last

function SellStall.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("SellStall", "Day", "Sell Stall", nil, true, nil, {
		Accent = "Sell",
		Badge = Theme.Icons.HudCash,
		Size = "Large",
	})
	local header = window:FindFirstChild("Header") :: Frame
	UIKit.Button(header, "SortButton", "Soft", 120, Theme.ButtonHeight.Row, SORTS[1]).LayoutOrder = 4
	local page = MenuParts.Pages(window)
	local well = MenuParts.CardGrid(page)

	-- The cards: a red ring and tick once picked, the size (or LAMB, or the merge) over the picture's foot.
	local template = well:FindFirstChild("CardTemplate", true) :: TextButton
	local face = template:FindFirstChild("Face") :: Frame
	local selected = face:FindFirstChild("Selected")
	if selected and selected:IsA("UIStroke") then
		selected.Color = Color.Red400
	end
	local sizeChip = UIKit.DarkChip(face, "SizeChip", nil, "SizeLabel", true)
	sizeChip.AnchorPoint = Vector2.new(0.5, 0)
	sizeChip.Position = UDim2.new(0.5, 0, 0, 54)
	sizeChip.ZIndex = 5
	sizeChip.Visible = false
	local tick = UIKit.Frame(face, "Tick", UDim2.fromOffset(28, 28), Color.Red500)
	tick.AnchorPoint = Vector2.new(1, 0)
	tick.Position = UDim2.new(1, 8, 0, -9)
	tick.ZIndex = 7
	tick.Visible = false
	UIKit.Corner(tick)
	local ring = Instance.new("UIStroke")
	ring.Color = Color.Line
	ring.Thickness = Theme.Line.Normal
	ring.Parent = tick
	local mark = UIKit.Icon(tick, "Mark", Theme.Icons.CheckWhite, 16)
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.ZIndex = 8

	-- The sell tile: a fan of what's picked (or the hint), the total, Select all / Clear and Sell.
	local tile = UIKit.Tile(page, "SellTile", UDim2.new(1, -(MenuParts.GridWidth + Fleece.Inset - 2), 1, -4))
	tile.AnchorPoint = Vector2.new(1, 0)
	tile.Position = UDim2.fromScale(1, 0)
	UIKit.Padding(tile, 9, 9, 9, 10)
	UIKit.List(tile, false, 6, Enum.HorizontalAlignment.Center)
	local pile = UIKit.Well(tile, "Pile", UDim2.new(1, 0, 0, 56))
	pile.LayoutOrder = 1
	local fan = UIKit.Frame(pile, "Fan", UDim2.fromOffset(FAN_TOKEN, FAN_TOKEN))
	fan.AnchorPoint = Vector2.new(0.5, 0.5)
	fan.Position = UDim2.fromScale(0.5, 0.5)
	for index = 1, FAN do
		local token = UIKit.Token(fan, FAN_TOKEN, `Token{index}`)
		token.Position = UDim2.fromOffset((index - 1) * FAN_STEP, 0)
		token.ZIndex = index + 1
	end
	local more = UIKit.DarkChip(pile, "MoreChip", nil, "MoreLabel")
	more.AnchorPoint = Vector2.new(1, 0.5)
	more.Position = UDim2.new(1, -8, 0.5, 0)
	more.ZIndex = 8
	UIKit.Text(pile, "HintLabel", "Tap the sheep to sell", 15, Fleece.Muted, UDim2.fromScale(1, 1), {
		Font = Theme.Font.TextHeavy,
		Wrap = true,
	})
	local total = UIKit.Frame(tile, "Total", UDim2.new(1, 0, 0, 40))
	total.LayoutOrder = 2
	UIKit.List(total, true, 5, Enum.HorizontalAlignment.Center)
	UIKit.Icon(total, "Bill", Theme.Icons.HudCash, 36)
	UIKit.Text(total, "TotalLabel", "0", 30, Color.Lime, UDim2.fromOffset(0, 40), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local spacer = UIKit.Frame(tile, "Spacer", UDim2.fromOffset(1, 0))
	spacer.LayoutOrder = 3
	UIKit.Grow(spacer)
	local select = UIKit.Button(tile, "SelectButton", "Soft", 100, Theme.ButtonHeight.Row, "Select all")
	select.Size = UDim2.new(1, 0, 0, select.Size.Y.Offset)
	select.LayoutOrder = 4
	local sell = UIKit.Button(tile, "SellButton", "Disabled", 100, Theme.ButtonHeight.Standard, "Sell")
	sell.Size = UDim2.new(1, 0, 0, sell.Size.Y.Offset)
	sell.LayoutOrder = 5

	UIKit.Text(
		page,
		"EmptyLabel",
		"No stored sheep to sell",
		20,
		Fleece.Muted,
		UDim2.new(0, MenuParts.GridWidth, 0, 40),
		{
			Font = Theme.Font.TextHeavy,
			Wrap = true,
		}
	).Position =
		UDim2.fromScale(0, 0.4)
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

-- A family's name without "Sheep" ("Meadow"), for a card.
local function shortName(family: string): string
	local tier = Olympus.ByFamily[family]
	return if tier then (string.gsub(tier.FamilyName, " Sheep$", "")) else family
end

function SellStall.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local cardTrove = trove:Extend()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local emptyLabel = window:FindFirstChild("EmptyLabel", true) :: TextLabel
	local sortButton = window:FindFirstChild("SortButton", true) :: TextButton
	local tile = window:FindFirstChild("SellTile", true) :: Frame
	local fan = tile:FindFirstChild("Fan", true) :: Frame
	local more = tile:FindFirstChild("MoreChip", true) :: Frame
	local moreLabel = more:FindFirstChild("MoreLabel") :: TextLabel
	local hint = tile:FindFirstChild("HintLabel", true) :: TextLabel
	local totalLabel = tile:FindFirstChild("TotalLabel", true) :: TextLabel
	local selectButton = tile:FindFirstChild("SelectButton", true) :: TextButton
	local sellButton = tile:FindFirstChild("SellButton", true) :: TextButton
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController

	local sortIndex = 1
	local picked: { [string]: boolean } = {}
	local shown: { View } = {}
	local cards: { [string]: TextButton } = {}
	local busy = false

	-- The stored sheep (the pen's are never offered), cheapest or dearest first, oldest first on a tie.
	local function stored(): { View }
		local views: { View } = {}
		for _, sheep in stateController:Flock() do
			if sheep.Slot == 0 then
				table.insert(views, sheep :: any)
			end
		end
		local cheapest = SORTS[sortIndex] == "Cheapest"
		table.sort(views, function(a: View, b: View)
			if a.Sell ~= b.Sell then
				return if cheapest then a.Sell < b.Sell else a.Sell > b.Sell
			end
			return (tonumber(a.Id) or 0) < (tonumber(b.Id) or 0)
		end)
		return views
	end

	local function pickedList(): ({ View }, number)
		local views: { View } = {}
		local sum = 0
		for _, sheep in shown do
			if picked[sheep.Id] then
				table.insert(views, sheep)
				sum += sheep.Sell
			end
		end
		return views, sum
	end

	local function paintPick(card: TextButton, on: boolean)
		local face = card:FindFirstChild("Face")
		if not face then
			return
		end
		for _, name in { "Selected", "SelectedRing" } do
			local stroke = face:FindFirstChild(name)
			if stroke and stroke:IsA("UIStroke") then
				stroke.Enabled = on
			end
		end
		local tick = face:FindFirstChild("Tick")
		if tick and tick:IsA("GuiObject") then
			tick.Visible = on
		end
	end

	local function showTile()
		local views, sum = pickedList()
		-- The fan: the dearest few, the dearest in front.
		local front = table.clone(views)
		table.sort(front, function(a: View, b: View)
			return a.Sell < b.Sell
		end)
		local from = math.max(#front - FAN + 1, 1)
		local count = #front - from + 1
		for index = 1, FAN do
			local token = fan:FindFirstChild(`Token{index}`) :: Frame
			local sheep = front[from + index - 1]
			token.Visible = index <= count and sheep ~= nil
			if token.Visible then
				SheepIcon.Paint(token, sheep.Family, sheep.Rarity)
			end
		end
		fan.Size = UDim2.fromOffset(FAN_TOKEN + FAN_STEP * math.max(count - 1, 0), FAN_TOKEN)
		fan.Position = UDim2.new(0.5, if #views > FAN then -18 else 0, 0.5, 0)
		fan.Visible = #views > 0
		more.Visible = #views > FAN
		moreLabel.Text = `+{#views - FAN}`
		hint.Visible = #views == 0
		totalLabel.Text = Format.Short(sum)
		totalLabel.TextColor3 = if #views > 0 then Color.Lime else Fleece.Faint

		local pickable, allPicked = 0, true
		for _, sheep in shown do
			if not sheep.Locked then
				pickable += 1
				allPicked = allPicked and picked[sheep.Id] == true
			end
		end
		if pickable == 0 then
			Buttons.Set(selectButton, "Disabled", "Select all")
		else
			Buttons.Set(selectButton, "Soft", if allPicked then "Clear" else "Select all")
		end
		if #views == 0 then
			Buttons.Set(sellButton, "Disabled", "Sell")
		else
			Buttons.Set(sellButton, "Danger", `Sell {#views}`)
		end
	end

	local function refresh()
		local data = stateController:Get()
		if type(data.Sheep) ~= "table" then
			return
		end
		shown = stored()
		local present: { [string]: boolean } = {}
		for _, sheep in shown do
			if not sheep.Locked then
				present[sheep.Id] = true
			end
		end
		for id in picked do
			if not present[id] then
				picked[id] = nil
			end
		end
		cardTrove:Clean()
		cards = {}
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") and child.Name ~= "CardTemplate" then
				child:Destroy()
			end
		end
		for order, sheep in shown do
			local card = MenuParts.NewCard(list, `Sheep{sheep.Id}`, order)
			local face = card:FindFirstChild("Face") :: Frame
			Style.PaintCard(card, SheepIcon.RarityLook(sheep.Rarity), sheep.Locked)
			SheepIcon.Paint(face:FindFirstChild("Token") :: Frame, sheep.Family, sheep.Rarity)
			local lock = face:FindFirstChild("Lock")
			if lock and lock:IsA("GuiObject") then
				lock.Visible = sheep.Locked
			end
			local name = face:FindFirstChild("NameLabel") :: TextLabel
			name.Text = shortName(sheep.Family)
			local price = face:FindFirstChild("PriceLabel", true) :: TextLabel
			price.Text = Format.Short(sheep.Sell)
			local chip = face:FindFirstChild("SizeChip") :: Frame
			local chipLabel = chip:FindFirstChild("SizeLabel") :: TextLabel
			local chipText = if not sheep.Adult
				then "LAMB"
				elseif sheep.Rank > 0 then string.upper(Economy.RankNames[sheep.Rank])
				elseif sheep.Size > 1 then string.upper(Economy.Sizes[sheep.Size].Name)
				else nil
			chip.Visible = chipText ~= nil
			chipLabel.Text = chipText or ""
			chip.BackgroundTransparency = if not sheep.Adult or sheep.Rank > 0 then 0 else 0.45
			chip.BackgroundColor3 = if not sheep.Adult
				then Color.Green500
				elseif sheep.Rank > 0 then Fleece.Rarity.Epic.Base
				else Fleece.Well
			paintPick(card, picked[sheep.Id] == true)
			cards[sheep.Id] = card
			cardTrove:Connect(card.Activated, function()
				if busy then
					return
				end
				if sheep.Locked then
					panel.Status("Locked: unlock it in Your Flock", "Bad")
					sound:Play("Denied")
					return
				end
				local on = not picked[sheep.Id]
				if on then
					picked[sheep.Id] = true
				else
					picked[sheep.Id] = nil
				end
				paintPick(card, on)
				sound:Play("Click")
				showTile()
			end)
		end
		emptyLabel.Visible = #shown == 0
		showTile()
	end

	local function sellPicked()
		local views, sum = pickedList()
		if #views == 0 or busy then
			return
		end
		local dearest = views[1]
		for _, sheep in views do
			if sheep.Sell > dearest.Sell then
				dearest = sheep
			end
		end
		local ids: { string } = {}
		for _, sheep in views do
			table.insert(ids, sheep.Id)
		end
		local title = if #views == 1 then "Sell this sheep?" else `Sell {#views} sheep?`
		MenuParts.Confirm(
			gui,
			title,
			`{Format.Short(sum)} cash`,
			"This can't be undone",
			`Sell {#views}`,
			function(token)
				SheepIcon.Paint(token, dearest.Family, dearest.Rarity)
			end,
			function()
				busy = true
				Buttons.Loading(sellButton, true)
				local callOk, success, message = Remotes.Sell:Invoke(ids)
				Buttons.Loading(sellButton, false)
				busy = false
				if not callOk then
					panel.Status("Try again", "Bad")
					sound:Play("Denied")
					return
				end
				if success then
					table.clear(picked)
					sound:Play("Purchase")
				else
					sound:Play("Denied")
				end
				panel.Status(message or "Try again", if success then "Good" else "Bad")
				refresh()
			end
		)
		-- How many go, on the confirm's stage.
		local countChip = gui:FindFirstChild("CountChip", true)
		if countChip and countChip:IsA("GuiObject") then
			countChip.Visible = #views > 1
			local countLabel = countChip:FindFirstChild("CountLabel")
			if countLabel and countLabel:IsA("TextLabel") then
				countLabel.Text = `x{#views}`
			end
		end
	end

	trove:Connect(sortButton.Activated, function()
		sortIndex = sortIndex % #SORTS + 1
		Buttons.Set(sortButton, "Soft", SORTS[sortIndex])
		sound:Play("Click")
		refresh()
	end)
	trove:Connect(selectButton.Activated, function()
		if busy or Buttons.Kind(selectButton) == "Disabled" then
			return
		end
		local allPicked = true
		for _, sheep in shown do
			if not sheep.Locked and not picked[sheep.Id] then
				allPicked = false
			end
		end
		for _, sheep in shown do
			if not sheep.Locked then
				if allPicked then
					picked[sheep.Id] = nil
				else
					picked[sheep.Id] = true
				end
				local card = cards[sheep.Id]
				if card then
					paintPick(card, not allPicked)
				end
			end
		end
		sound:Play("Click")
		showTile()
	end)
	trove:Connect(sellButton.Activated, sellPicked)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("SellStall")
		end)
	end
	trove:Add(stateController.Changed:Connect(function()
		if gui.Enabled and not busy then
			refresh()
		end
	end))

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			table.clear(picked)
			MenuParts.HideConfirm(gui)
			list.CanvasPosition = Vector2.zero
			refresh()
			panel.Show()
		end,
		Close = function(_self: Types.Screen)
			panel.Hide(function() end)
		end,
		Destroy = function(_self: Types.Screen)
			trove:Clean()
			gui:Destroy()
		end,
		Notify = function(_self: Types.Screen, message: string, kind: string)
			panel.Status(message, Style.NoticeKindOf(kind))
		end,
	}
end

return SellStall
