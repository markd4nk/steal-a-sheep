--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Panel = require(script.Parent.Parent.Panel)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The hub shop, in Shear a Sheep's upgrades look (an orange Prize Fleece menu of raised tiles): the next stair walker
-- level, room for one more sheep in the pen, and the four trails in order. Each tile is its name, one short line and its buy button.
local Shop = {}

local ROW_HEIGHT = 74

local function row(list: Instance, name: string, icon: string, order: number, tint: Color3?): Frame
	local tile = UIKit.Tile(list, name, UDim2.new(1, -8, 0, ROW_HEIGHT))
	tile.LayoutOrder = order
	UIKit.Padding(tile, 12, 12, 0, 0)
	local layout = UIKit.List(tile, true, 12)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Icon(tile, "Icon", icon, 52, tint).LayoutOrder = 1
	local words = UIKit.Frame(tile, "Words", UDim2.new(1, -260, 0, 52))
	words.LayoutOrder = 2
	UIKit.Grow(words)
	UIKit.List(words, false, 0)
	UIKit.Text(words, "NameLabel", "", 22, Theme.Color.Snow, UDim2.new(1, 0, 0, 28), {
		Stroke = Theme.Color.Line,
		AlignX = Enum.TextXAlignment.Left,
		Fit = true,
		Order = 1,
	})
	UIKit.Text(words, "DetailLabel", "", 16, Theme.Fleece.Muted, UDim2.new(1, 0, 0, 22), {
		Font = Theme.Font.TextHeavy,
		AlignX = Enum.TextXAlignment.Left,
		Fit = true,
		Order = 2,
	})
	local button = UIKit.Button(tile, "BuyButton", "Buy", 170, Theme.ButtonHeight.Standard, "Buy")
	button.LayoutOrder = 3
	return tile
end

function Shop.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Shop", "Day", "Shop", nil, false, nil, {
		Accent = "Upgrade",
		Badge = Theme.Icons.HudUpgrade,
		Size = "Large",
	})
	local page = window:FindFirstChild("Pages") :: Frame
	local list = UIKit.Scroller(page, "List", UDim2.fromScale(1, 1), 8)
	row(list, "Walker", Theme.Icons.HudShoe, 1)
	row(list, "PenSlot", Theme.Icons.Wool, 2)
	for index, trail in Economy.Trails do
		row(list, `Trail{trail.Id}`, Theme.Icons.Star, 2 + index, trail.Color)
	end
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

function Shop.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local player = Players.LocalPlayer
	local busy = false

	local function tile(name: string): (TextLabel, TextLabel, TextButton)
		local found = window:FindFirstChild(name, true) :: Frame
		return found:FindFirstChild("NameLabel", true) :: TextLabel,
			found:FindFirstChild("DetailLabel", true) :: TextLabel,
			found:FindFirstChild("BuyButton") :: TextButton
	end

	local function coins(): number
		local value = player:GetAttribute("Coins")
		return if type(value) == "number" then value else 0
	end

	local function price(button: TextButton, cost: number, text: string)
		Buttons.Set(button, if coins() >= cost then "Buy" else "CantAfford", text)
		Buttons.SetValue(button, Format.Short(cost), Theme.Icons.HudCash)
	end

	local function refresh()
		local data = stateController:Get()
		if data.WalkerLevel == nil then
			return
		end
		if panel.CashLabel then
			panel.CashLabel.Text = Format.Short(coins())
		end
		do
			local nameLabel, detailLabel, button = tile("Walker")
			local level = data.WalkerLevel
			nameLabel.Text = `Stair Walker Lv {level + 1}`
			local cost = Economy.WalkerCost(level)
			if cost then
				detailLabel.Text = `{Format.Short(Economy.WalkerRate(level))} → {Format.Short(
					Economy.WalkerRate(level + 1)
				)} Climbing/s`
				price(button, cost, "Upgrade")
			else
				detailLabel.Text = `{Format.Short(Economy.WalkerRate(level))} Climbing/s`
				Buttons.Set(button, "Owned", "MAX")
				Buttons.SetValue(button, nil)
			end
		end
		do
			local nameLabel, detailLabel, button = tile("PenSlot")
			nameLabel.Text = `Pen Space {data.PenSlots}/{Economy.MaxPens}`
			local cost = Economy.PenCost(data.PenSlots + 1)
			if cost then
				detailLabel.Text = "One more sheep can earn"
				price(button, cost, "Buy")
			else
				detailLabel.Text = "Your pen is as big as it gets"
				Buttons.Set(button, "Owned", "MAX")
				Buttons.SetValue(button, nil)
			end
		end
		local trails = data.Trails or {}
		for index, trail in Economy.Trails do
			local nameLabel, detailLabel, button = tile(`Trail{trail.Id}`)
			nameLabel.Text = trail.Name
			detailLabel.Text = `{trail.Multiplier}x training`
			if trails[trail.Id] then
				local worn = data.Trail == trail.Id
				Buttons.Set(button, if worn then "Owned" else "Action", if worn then "Equipped" else "Equip")
				Buttons.SetValue(button, nil)
			else
				local previous = Economy.Trails[index - 1]
				if previous and not trails[previous.Id] then
					Buttons.Set(button, "Locked", `After {previous.Name}`)
					Buttons.SetValue(button, nil)
				else
					price(button, trail.Cost, "Buy")
				end
			end
		end
	end

	local function buy(item: string, which: string?, button: TextButton)
		if busy then
			return
		end
		local kind = Buttons.Kind(button)
		if kind == "CantAfford" or kind == "Locked" then
			Buttons.Shake(button)
			sound:Play("Denied")
		end
		busy = true
		Buttons.Loading(button, true)
		local callOk, success, message = Remotes.Buy:Invoke(item, which)
		Buttons.Loading(button, false)
		busy = false
		if callOk then
			if message then
				panel.Status(message, if success then "Good" else "Bad")
			end
			sound:Play(if success then "Upgrade" else "Denied")
		end
		refresh()
	end

	local _, _, walkerButton = tile("Walker")
	trove:Connect(walkerButton.Activated, function()
		buy("Walker", nil, walkerButton)
	end)
	local _, _, penButton = tile("PenSlot")
	trove:Connect(penButton.Activated, function()
		buy("PenSlot", nil, penButton)
	end)
	for _, trail in Economy.Trails do
		local _, _, trailButton = tile(`Trail{trail.Id}`)
		trove:Connect(trailButton.Activated, function()
			buy("Trail", trail.Id, trailButton)
		end)
	end
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Shop")
		end)
	end
	trove:Add(stateController.Changed:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end))
	trove:Connect(player:GetAttributeChangedSignal("Coins"), function()
		if gui.Enabled then
			refresh()
		end
	end)

	return {
		Modal = true,
		StartsOpen = false,
		Open = function(_self: Types.Screen)
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

return Shop
