--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local MenuParts = require(script.Parent.Parent.MenuParts)
local Panel = require(script.Parent.Parent.Panel)
local SheepIcon = require(script.Parent.Parent.SheepIcon)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The standard collection book (Shear a Sheep's Sheepdex look): the twelve families as cards, dark with a "?" until
-- the first delivery of one, and the picked one beside them: its god, its area, what it earns and its reward.
local Sheepdex = {}

function Sheepdex.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Sheepdex", "Day", "Sheepdex", nil, false, nil, {
		Accent = "Dex",
		Badge = Theme.Icons.MenuSheepdex,
		Size = "Large",
		Width = 780,
	})
	local header = window:FindFirstChild("Header") :: Frame
	local cash = header:FindFirstChild("CashChip", true)
	if cash then
		cash:Destroy()
	end
	UIKit.HeaderChip(header, "FoundChip", Theme.Icons.Book, "FoundLabel", "0/12").LayoutOrder = 3
	local page = MenuParts.Pages(window)
	MenuParts.CardGrid(page)
	MenuParts.Detail(page, MenuParts.GridWidth)
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

function Sheepdex.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local detail = window:FindFirstChild("Detail", true) :: Frame
	local foundLabel = window:FindFirstChild("FoundLabel", true) :: TextLabel
	local view = detail:FindFirstChild("View", true) :: ViewportFrame
	local nameLabel = detail:FindFirstChild("NameLabel", true) :: TextLabel
	local rarityChip = detail:FindFirstChild("RarityChip", true) :: Frame
	local rateLabel = detail:FindFirstChild("RateLabel", true) :: TextLabel
	local stage = detail:FindFirstChild("Stage", true) :: Frame
	local lines = {
		detail:FindFirstChild("Line1", true) :: TextLabel,
		detail:FindFirstChild("Line2", true) :: TextLabel,
		detail:FindFirstChild("Line3", true) :: TextLabel,
	}
	local stateController = context.Controllers.StateController
	local picked = 1

	local function showDetail()
		local data = stateController:Get()
		local tier = Olympus.Tiers[picked]
		local found = type(data.Dex) == "table" and data.Dex[tier.Family] == true
		nameLabel.Text = if found then tier.FamilyName else "???"
		Style.PaintStage(stage, if found then "Rare" else nil)
		Style.PaintRarity(rarityChip, if found then "Uncommon" else "Locked")
		local chipLabel = rarityChip:FindFirstChild("Label")
		if chipLabel and chipLabel:IsA("TextLabel") then
			chipLabel.Text = `TIER {tier.Tier}`
		end
		local base = Economy.BaseIncome(tier.Tier)
		rateLabel.Text = `+{Format.Rate(base)}/s`
		if found then
			MenuParts.ShowSheep(view, tier.Family, 1)
		else
			view:ClearAllChildren()
		end
		lines[1].Text = `{tier.God}'s {tier.Area}`
		lines[2].Text = `Climbing {Format.Short(tier.Reach)} to reach`
		lines[3].Text = if found
			then `Found! Rewarded {Format.Short(Economy.DexReward(tier.Tier))} coins`
			else `First one pays {Format.Short(Economy.DexReward(tier.Tier))} coins`
	end

	local function refresh()
		local data = stateController:Get()
		local dex = if type(data.Dex) == "table" then data.Dex else {}
		local count = 0
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") and child.Name ~= "CardTemplate" then
				child:Destroy()
			end
		end
		for _, tier in Olympus.Tiers do
			local found = dex[tier.Family] == true
			if found then
				count += 1
			end
			local card = MenuParts.NewCard(list, `Family{tier.Tier}`, tier.Tier)
			local face = card:FindFirstChild("Face") :: Frame
			Style.PaintCard(card, "Rare", not found)
			SheepIcon.Paint(face:FindFirstChild("Token") :: Frame, tier.Family, 1, not found)
			local cardName = face:FindFirstChild("NameLabel") :: TextLabel
			cardName.Text = if found then (string.gsub(tier.FamilyName, " Sheep$", "")) else "???"
			local price = face:FindFirstChild("PriceLabel", true) :: TextLabel
			price.Text = tier.God
			local icon = face:FindFirstChild("Icon", true)
			if icon and icon:IsA("GuiObject") then
				icon.Visible = false
			end
			trove:Connect(card.Activated, function()
				picked = tier.Tier
				MenuParts.Select(list, card)
				showDetail()
			end)
			if tier.Tier == picked then
				MenuParts.Select(list, card)
			end
		end
		foundLabel.Text = `{count}/{Olympus.Count}`
		showDetail()
	end

	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Sheepdex")
		end)
	end
	trove:Add(stateController.Changed:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end))

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

return Sheepdex
