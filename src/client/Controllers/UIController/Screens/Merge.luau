--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Panel = require(script.Parent.Parent.Panel)
local SheepIcon = require(script.Parent.Parent.SheepIcon)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The Merge Shrine's menu (the user's mix, 2026-10-05: Shear a Sheep's mutation lab and the shop): the camera on the
-- shrine with no backdrop (ShrineController), the odds on the left in the lab's glass panel, your grown sheep on the
-- right as the shop's rows, and one big Merge button with the price. Picking three of one kind stands them on the
-- pedestals; Merge pays and the shrine plays the merge (ShrineController), and the lamb lands on its altar to be
-- carried home. The odds are the shrine's own (Economy.LuckySizeOdds, Economy.ShrineFleeceOdds) for what's picked.
-- The menu closes when its player walks away from the shrine.
local Merge = {}

type View = {
	Id: string,
	Family: string,
	Rarity: number,
	Size: number,
	Adult: boolean,
	Locked: boolean,
	Income: number,
	AtShrine: boolean?,
}

type Row = {
	Tile: Frame,
	Token: Frame,
	Name: TextLabel,
	Detail: TextLabel,
	Number: TextLabel,
	Ring: Frame,
	Button: TextButton,
}

local PANEL_WIDTH = 420
local ROW_HEIGHT = 62
local TOKEN = 46
local ODDS_WIDTH = 236
local ODDS_ROW = 20
local EDGE = 16
local ODDS_TOP = 56 -- under Roblox's buttons
local CHECK_SECONDS = 0.25
local PICKS = 3
local GLASS = Color3.fromRGB(8, 14, 38)
local GOLD_TEXT = Color3.fromRGB(255, 216, 102)
local SIZE_DOTS = {
	Color3.fromRGB(196, 202, 214),
	Color3.fromRGB(94, 227, 106),
	Color3.fromRGB(90, 168, 255),
	Color3.fromRGB(255, 170, 40),
}

local function percent(value: number): string
	if value >= 9.95 then
		return `{math.floor(value + 0.5)}%`
	elseif value >= 0.995 then
		return `{string.format("%.1f", value)}%`
	elseif value >= 0.005 then
		return `{string.format("%.2f", value)}%`
	end
	return "<0.01%"
end

local function times(multiplier: number): string
	return if multiplier == 1 then "" else ` x{multiplier}`
end

-- "Sun" for the Sun Sheep: what the rows' buttons say when another family is picked.
local function shortName(family: string): string
	return (string.gsub(Economy.Tier(family).FamilyName, " Sheep$", ""))
end

local function oddsRow(parent: Instance, name: string, order: number, color: Color3)
	local row = UIKit.Frame(parent, name, UDim2.new(1, 0, 0, ODDS_ROW))
	row.LayoutOrder = order
	local dot = UIKit.Frame(row, "Dot", UDim2.fromOffset(12, 12), color)
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 3, 0.5, 0)
	UIKit.Corner(dot, 6)
	local edge = Instance.new("UIStroke")
	edge.Color = Theme.Color.Line
	edge.Thickness = 1.5
	edge.Parent = dot
	local label = UIKit.Text(row, "NameLabel", "", 15, Theme.Color.Snow, UDim2.new(1, -86, 1, 0), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Left,
	})
	label.Position = UDim2.fromOffset(22, 0)
	local chance = UIKit.Text(row, "ChanceLabel", "", 15, Theme.Color.Snow, UDim2.new(0, 64, 1, 0), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Right,
	})
	chance.AnchorPoint = Vector2.new(1, 0)
	chance.Position = UDim2.new(1, -2, 0, 0)
end

local function heading(parent: Instance, name: string, text: string, order: number): TextLabel
	return UIKit.Text(parent, name, text, 15, GOLD_TEXT, UDim2.new(1, 0, 0, 20), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Left,
		Order = order,
	})
end

-- The lab's odds panel: dark glass with a gold edge, each size and fleece with its chance.
local function buildOdds(root: Instance)
	local odds = UIKit.Frame(root, "Odds", UDim2.fromOffset(ODDS_WIDTH, 0), GLASS)
	odds.BackgroundTransparency = 0.18
	odds.AutomaticSize = Enum.AutomaticSize.Y
	odds.Position = UDim2.fromOffset(EDGE, ODDS_TOP)
	UIKit.Corner(odds, 16)
	local edge = Instance.new("UIStroke")
	edge.Color = GOLD_TEXT
	edge.Transparency = 0.45
	edge.Thickness = 2
	edge.Parent = odds
	UIKit.Padding(odds, 10, 10, 9, 9)
	UIKit.List(odds, false, 3)
	local head = UIKit.Frame(odds, "SizeHead", UDim2.new(1, 0, 0, 20))
	head.LayoutOrder = 1
	heading(head, "TitleLabel", "SIZE", 0)
	local luck = UIKit.Text(head, "LuckLabel", "", 13, Theme.Color.Snow, UDim2.new(0, 110, 1, 0), {
		Font = Theme.Font.TextHeavy,
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Right,
	})
	luck.AnchorPoint = Vector2.new(1, 0)
	luck.Position = UDim2.new(1, 0, 0, 0)
	for index in Economy.Sizes do
		oddsRow(odds, `Size{index}`, 1 + index, SIZE_DOTS[index] or SIZE_DOTS[1])
	end
	heading(odds, "FleeceHead", "FLEECE", 10)
	for index, rarity in Economy.Rarities do
		oddsRow(odds, `Fleece{index}`, 10 + index, rarity.Color)
	end
	UIKit.Text(odds, "HintLabel", "Bigger sheep in, more luck", 13, Theme.Fleece.Muted, UDim2.new(1, 0, 0, 18), {
		Font = Theme.Font.TextHeavy,
		Order = 20,
	})
end

function Merge.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Merge", "Day", "Merge Shrine", nil, false, nil, {
		Accent = "Gold",
		Badge = Theme.Icons.Sparkle,
		Size = "Large",
		Width = PANEL_WIDTH,
	})
	-- The shrine is the scene: no backdrop over it.
	local backdrop = gui:FindFirstChild("Backdrop")
	if backdrop and backdrop:IsA("GuiObject") then
		backdrop.Visible = false
	end
	window.AnchorPoint = Vector2.new(1, 0.5)
	window.Position = UDim2.new(1, -EDGE, 0.5, 0)
	local page = window:FindFirstChild("Pages") :: Frame
	local top = UIKit.Frame(page, "TopRow", UDim2.new(1, 0, 0, 26))
	UIKit.Text(top, "PickLabel", "Pick 3 of one kind", 15, Theme.Fleece.Muted, UDim2.new(1, -70, 1, 0), {
		Font = Theme.Font.TextHeavy,
		AlignX = Enum.TextXAlignment.Left,
	}).Position =
		UDim2.fromOffset(6, 0)
	local count = UIKit.Text(top, "CountLabel", "0/3", 18, Theme.Color.Snow, UDim2.new(0, 64, 1, 0), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Right,
	})
	count.AnchorPoint = Vector2.new(1, 0)
	count.Position = UDim2.new(1, -6, 0, 0)
	local list = UIKit.Scroller(page, "List", UDim2.new(1, 0, 1, -30), 8)
	list.Position = UDim2.fromOffset(0, 30)
	UIKit.Text(page, "EmptyLabel", "", 18, Theme.Fleece.Muted, UDim2.new(1, -20, 0, 80), {
		Font = Theme.Font.TextHeavy,
		Wrap = true,
	}).Position =
		UDim2.new(0, 10, 0.35, 0)

	local root = gui:FindFirstChild("Root") :: Frame
	buildOdds(root)
	local button = UIKit.Button(root, "MergeButton", "Buy", 280, Theme.ButtonHeight.Hero, "Merge")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, -(PANEL_WIDTH + EDGE) / 2, 1, -EDGE)
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

local function newRow(list: Instance): Row
	local tile = UIKit.Tile(list, "Row", UDim2.new(1, -8, 0, ROW_HEIGHT))
	-- The row's pieces in their own frame, so the ring over the tile isn't laid out with them.
	local content = UIKit.Frame(tile, "Content", UDim2.fromScale(1, 1))
	UIKit.Padding(content, 10, 10, 0, 0)
	local layout = UIKit.List(content, true, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	local token = UIKit.Token(content, TOKEN, "Token")
	token.LayoutOrder = 1
	local words = UIKit.Frame(content, "Words", UDim2.new(1, -(TOKEN + 140), 0, 44))
	words.LayoutOrder = 2
	UIKit.Grow(words)
	UIKit.List(words, false, 0)
	local name = UIKit.Text(words, "NameLabel", "", 18, Theme.Color.Snow, UDim2.new(1, 0, 0, 24), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Left,
		Fit = true,
		Order = 1,
	})
	local detail = UIKit.Text(words, "DetailLabel", "", 14, Theme.Fleece.Muted, UDim2.new(1, 0, 0, 20), {
		Font = Theme.Font.TextHeavy,
		AlignX = Enum.TextXAlignment.Left,
		Fit = true,
		Order = 2,
	})
	local pick = UIKit.Button(content, "PickButton", "Action", 100, Theme.ButtonHeight.Row, "Add")
	pick.LayoutOrder = 3
	-- Which pedestal it stands on: a gold number on the token's corner.
	local number = UIKit.Text(token, "NumberLabel", "", 14, Theme.Color.Snow, UDim2.fromOffset(22, 22), {
		Stroke = Theme.Color.Line,
	})
	number.BackgroundTransparency = 0
	number.BackgroundColor3 = Color3.fromRGB(255, 184, 28)
	number.Position = UDim2.fromOffset(-6, -6)
	number.ZIndex = 20
	UIKit.Corner(number, 11)
	local ring = UIKit.SelectionRing(tile)
	ring.Visible = false
	return {
		Tile = tile,
		Token = token,
		Name = name,
		Detail = detail,
		Number = number,
		Ring = ring,
		Button = pick,
	}
end

function Merge.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local root = gui:FindFirstChild("Root") :: Frame
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local emptyLabel = window:FindFirstChild("EmptyLabel", true) :: TextLabel
	local countLabel = window:FindFirstChild("CountLabel", true) :: TextLabel
	local odds = root:FindFirstChild("Odds") :: Frame
	local luckLabel = odds:FindFirstChild("LuckLabel", true) :: TextLabel
	local mergeButton = root:FindFirstChild("MergeButton") :: TextButton
	local stateController = context.Controllers.StateController
	local shrineController = context.Controllers.ShrineController
	local sound = context.Controllers.SoundController
	local player = Players.LocalPlayer
	local rows: { [string]: Row } = {}
	local picks: { string } = {}
	local byId: { [string]: View } = {}
	local busy = false
	local isOpen = false
	local merged = false

	local function coins(): number
		local value = player:GetAttribute("Coins")
		return if type(value) == "number" then value else 0
	end

	local function picked(): { View }
		local chosen: { View } = {}
		for _, id in picks do
			local sheep = byId[id]
			if sheep then
				table.insert(chosen, sheep)
			end
		end
		return chosen
	end

	local function pickedFamily(): string?
		local first = picks[1] and byId[picks[1]]
		return if first then first.Family else nil
	end

	local function setOdds(chosen: { View })
		local luck = if #chosen > 0 then Economy.ShrineLuck(chosen :: any) else Economy.ShrineBaseLuck
		local fleece = Economy.ShrineFleeceOdds(chosen :: any)
		local sizes = Economy.LuckySizeOdds(luck)
		luckLabel.Text = `LUCK {math.floor(luck * 100 + 0.5)}%`
		local function line(name: string, words: string, chance: number)
			local row = odds:FindFirstChild(name)
			local nameLabel = row and row:FindFirstChild("NameLabel")
			local chanceLabel = row and row:FindFirstChild("ChanceLabel")
			if nameLabel and nameLabel:IsA("TextLabel") and chanceLabel and chanceLabel:IsA("TextLabel") then
				nameLabel.Text = words
				chanceLabel.Text = percent(chance)
			end
		end
		for index, size in Economy.Sizes do
			line(`Size{index}`, `{size.Name}{times(size.Multiplier)}`, sizes[index] or 0)
		end
		for index, rarity in Economy.Rarities do
			line(`Fleece{index}`, `{rarity.Name}{times(rarity.Multiplier)}`, fleece[index] or 0)
		end
	end

	local function setButton(ready: boolean)
		local family = pickedFamily()
		local price = if family then Economy.ShrinePrice(family) else nil
		if not ready then
			Buttons.Set(mergeButton, "Disabled", "After 3 deliveries")
			Buttons.SetValue(mergeButton, nil)
		elseif #picks < PICKS then
			Buttons.Set(mergeButton, "Disabled", `Pick {PICKS - #picks} more`)
			Buttons.SetValue(mergeButton, nil)
		else
			local cost = price or 0
			Buttons.Set(mergeButton, if coins() >= cost then "Buy" else "CantAfford", "Merge")
			Buttons.SetValue(mergeButton, Format.Short(cost), Theme.Icons.HudCash)
		end
	end

	local function preview()
		local stand: { { Family: string, Scale: number } } = {}
		for _, sheep in picked() do
			local size = Economy.Sizes[sheep.Size] or Economy.Sizes[1]
			table.insert(stand, { Family = sheep.Family, Scale = GameConfig.SheepSize * size.Scale })
		end
		shrineController:Preview(stand)
	end

	local function paintRow(row: Row, sheep: View)
		SheepIcon.Paint(row.Token, sheep.Family, sheep.Rarity)
		local size = Economy.Sizes[sheep.Size] or Economy.Sizes[1]
		row.Name.Text = Economy.Tier(sheep.Family).FamilyName
		local fleece = if sheep.Rarity > 1 then ` {Economy.Rarities[sheep.Rarity].Name}` else ""
		row.Detail.Text = `{size.Name}{fleece} · +{Format.Rate(sheep.Income)}/s`
		local at = table.find(picks, sheep.Id)
		row.Number.Text = if at then tostring(at) else ""
		row.Number.Visible = at ~= nil
		row.Ring.Visible = at ~= nil
		local family = pickedFamily()
		if at then
			Buttons.Set(row.Button, "Soft", "Remove")
		elseif sheep.Locked then
			Buttons.Set(row.Button, "Locked", "Locked")
		elseif #picks >= PICKS then
			Buttons.Set(row.Button, "Disabled", "Full")
		elseif family and family ~= sheep.Family then
			Buttons.Set(row.Button, "Disabled", `Not {shortName(family)}`)
		else
			Buttons.Set(row.Button, "Action", "Add")
		end
	end

	local refresh: () -> ()

	local function toggle(id: string, button: TextButton)
		if busy then
			return
		end
		local at = table.find(picks, id)
		if at then
			table.remove(picks, at)
		else
			local kind = Buttons.Kind(button)
			if kind ~= "Action" then
				Buttons.Shake(button)
				sound:Play("Denied")
				return
			end
			table.insert(picks, id)
		end
		sound:Play("Click")
		refresh()
		preview()
	end

	refresh = function()
		local data = stateController:Get()
		local ready = data.MergeReady == true
		table.clear(byId)
		local eligible: { View } = {}
		for _, sheep in stateController:Flock() :: { any } do
			if sheep.Adult and not sheep.AtShrine and not sheep.Robux then
				byId[sheep.Id] = sheep
				table.insert(eligible, sheep)
			end
		end
		-- Picks that are gone (sold, merged, locked meanwhile) drop out.
		for index = #picks, 1, -1 do
			local sheep = byId[picks[index]]
			if not sheep or sheep.Locked then
				table.remove(picks, index)
			end
		end
		table.sort(eligible, function(a: View, b: View)
			local tierA, tierB = Economy.Tier(a.Family).Tier, Economy.Tier(b.Family).Tier
			if tierA ~= tierB then
				return tierA > tierB
			end
			if a.Size ~= b.Size then
				return a.Size > b.Size
			end
			return a.Income > b.Income
		end)
		local wanted: { [string]: boolean } = {}
		for order, sheep in eligible do
			wanted[sheep.Id] = true
			local row = rows[sheep.Id]
			if not row then
				local made = newRow(list)
				rows[sheep.Id] = made
				local id = sheep.Id
				trove:Connect(made.Button.Activated, function()
					toggle(id, made.Button)
				end)
				row = made
			end
			local shown = row :: Row
			shown.Tile.LayoutOrder = order
			paintRow(shown, sheep)
		end
		for id, row in rows do
			if not wanted[id] then
				row.Tile:Destroy()
				rows[id] = nil
			end
		end
		list.Visible = ready and #eligible > 0
		emptyLabel.Visible = not list.Visible
		emptyLabel.Text = if not ready
			then "The shrine opens after your third delivery"
			else "Grow three sheep of one kind to merge them"
		countLabel.Text = `{#picks}/{PICKS}`
		setOdds(picked())
		setButton(ready)
	end

	trove:Connect(mergeButton.Activated, function()
		if busy then
			return
		end
		local kind = Buttons.Kind(mergeButton)
		if kind ~= "Buy" then
			Buttons.Shake(mergeButton)
			sound:Play("Denied")
			return
		end
		busy = true
		Buttons.Loading(mergeButton, true)
		local ids = table.clone(picks)
		local callOk, ok, message = Remotes.Merge:Invoke(ids)
		Buttons.Loading(mergeButton, false)
		busy = false
		if not callOk then
			return
		end
		if ok then
			-- The shrine takes it from here: the picks on the pedestals turn into the merge.
			merged = true
			table.clear(picks)
			sound:Play("LabCharge")
			context.Close("Merge")
			task.delay(2, function()
				if not shrineController:IsShowing() then
					shrineController:Frame(false)
				end
			end)
		else
			sound:Play("Denied")
			panel.Status(message or "Can't merge those", "Bad")
			refresh()
		end
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Merge")
		end)
	end
	trove:Add(stateController.Changed:Connect(function()
		if isOpen and not busy then
			refresh()
		end
	end))
	trove:Connect(player:GetAttributeChangedSignal("Coins"), function()
		if isOpen then
			setButton(stateController:Get().MergeReady == true)
		end
	end)
	-- Walking away from the shrine closes it.
	local since = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		if not isOpen then
			return
		end
		since += dt
		if since < CHECK_SECONDS then
			return
		end
		since = 0
		local character = player.Character
		local here = character and character:GetPivot().Position
		if not here or (here - GameConfig.Shrine.At.Position).Magnitude > GameConfig.Shrine.MenuDistance then
			context.Close("Merge")
		end
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
			isOpen = true
			merged = false
			table.clear(picks)
			refresh()
			panel.Show()
			shrineController:Frame(true)
			preview()
		end,
		Close = function(_self: Types.Screen)
			local wasOpen = isOpen
			isOpen = false
			panel.Hide(function() end)
			if not wasOpen then
				return
			end
			if not merged then
				table.clear(picks)
				shrineController:Preview({})
				shrineController:Frame(false)
			end
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

return Merge
