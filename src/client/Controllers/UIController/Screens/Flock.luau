--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
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

-- The player's flock in the Prize Fleece menu (Shear a Sheep's Your pen): every sheep as a card, the picked one big
-- beside them with Equip / Store and Lock, Equip Best in the header. Opened from the Sell Stall it adds Sell, with a
-- confirm showing the proceeds and the income lost.
local Flock = {}

local WIDTH = 780

function Flock.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Flock", "Day", "Your Flock", nil, true, nil, {
		Accent = "Shop",
		Badge = Theme.Icons.Wool,
		Size = "Large",
		Width = WIDTH,
	})
	local header = window:FindFirstChild("Header") :: Frame
	local penChip = UIKit.HeaderChip(header, "PenChip", Theme.Icons.Wool, "InfoLabel", "0/3")
	penChip.LayoutOrder = 3
	local best = UIKit.Button(header, "EquipBestButton", "Buy", 130, Theme.ButtonHeight.Row, "Equip Best")
	best.LayoutOrder = 4
	local sort = UIKit.Button(header, "SortButton", "Soft", 110, Theme.ButtonHeight.Row, "Income")
	sort.LayoutOrder = 2
	local page = MenuParts.Pages(window)
	MenuParts.CardGrid(page)
	local detail = MenuParts.Detail(page, MenuParts.GridWidth)
	local buttons = detail:FindFirstChild("Buttons") :: Frame
	local equip = UIKit.Button(buttons, "EquipButton", "Action", 100, Theme.ButtonHeight.Standard, "Equip")
	equip.LayoutOrder = 1
	UIKit.Grow(equip)
	local lock = UIKit.Button(buttons, "LockButton", "Soft", 80, Theme.ButtonHeight.Standard, "Lock")
	lock.LayoutOrder = 2
	local sell = UIKit.Button(buttons, "SellButton", "Danger", 100, Theme.ButtonHeight.Standard, "Sell")
	sell.LayoutOrder = 3
	UIKit.Grow(sell)
	UIKit.Text(
		page,
		"EmptyLabel",
		"Steal a lamb from a god to start your flock",
		20,
		Theme.Fleece.Muted,
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

function Flock.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local detail = window:FindFirstChild("Detail", true) :: Frame
	local title = window:FindFirstChild("TitleLabel", true) :: TextLabel?
	local penLabel = window:FindFirstChild("InfoLabel", true) :: TextLabel
	local bestButton = window:FindFirstChild("EquipBestButton", true) :: TextButton
	local emptyLabel = window:FindFirstChild("EmptyLabel", true) :: TextLabel
	local view = detail:FindFirstChild("View", true) :: ViewportFrame
	local nameLabel = detail:FindFirstChild("NameLabel", true) :: TextLabel
	local rarityChip = detail:FindFirstChild("RarityChip", true) :: Frame
	local rankChip = detail:FindFirstChild("RankChip", true) :: Frame
	local rateLabel = detail:FindFirstChild("RateLabel", true) :: TextLabel
	local stage = detail:FindFirstChild("Stage", true) :: Frame
	local lines = {
		detail:FindFirstChild("Line1", true) :: TextLabel,
		detail:FindFirstChild("Line2", true) :: TextLabel,
		detail:FindFirstChild("Line3", true) :: TextLabel,
	}
	local growthBar = detail:FindFirstChild("Bar", true) :: Frame
	local equipButton = detail:FindFirstChild("EquipButton", true) :: TextButton
	local lockButton = detail:FindFirstChild("LockButton", true) :: TextButton
	local sellButton = detail:FindFirstChild("SellButton", true) :: TextButton
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController

	local sortButton = window:FindFirstChild("SortButton", true) :: TextButton
	local sorts = { "Income", "Family", "Size", "Rank" }
	local sortIndex = 1
	local sellMode = false
	local picked: string? = nil
	local busy = false

	local function sheepById(id: string?): any
		local data = stateController:Get()
		return if id and type(data.Sheep) == "table" then data.Sheep[id] else nil
	end

	local function showDetail()
		local sheep = sheepById(picked)
		detail.Visible = sheep ~= nil
		if not sheep then
			return
		end
		nameLabel.Text = sheep.Name
		Style.PaintRarity(rarityChip, SheepIcon.RarityLook(sheep.Rarity))
		local rarityLabel = rarityChip:FindFirstChild("Label")
		if rarityLabel and rarityLabel:IsA("TextLabel") then
			rarityLabel.Text = string.upper(Economy.Rarities[sheep.Rarity].Name)
		end
		Style.PaintStage(stage, SheepIcon.RarityLook(sheep.Rarity))
		rankChip.Visible = sheep.Rank > 0
		if sheep.Rank > 0 then
			Style.PaintRarity(rankChip, if sheep.Rank >= 2 then "Mythic" else "Epic")
			local rankLabel = rankChip:FindFirstChild("Label")
			if rankLabel and rankLabel:IsA("TextLabel") then
				rankLabel.Text = `{string.upper(Economy.RankNames[sheep.Rank])} x{3 ^ sheep.Rank}`
			end
		end
		rateLabel.Text = `+{Format.Rate(sheep.Income)}/s`
		local scale = if sheep.Adult
			then Economy.Sizes[math.max(sheep.Size, 1)].Scale
			else Economy.Burdens[sheep.Burden].Scale + 0.3 * sheep.Growth
		MenuParts.ShowSheep(view, sheep.Family, scale)
		local burden = Economy.Burdens[sheep.Burden].Name
		if sheep.Adult then
			lines[1].Text = `{Economy.Sizes[sheep.Size].Name} adult - {burden} to carry`
			growthBar.Visible = false
		else
			lines[1].Text = `Grows to +{Format.Rate(sheep.Low)}-{Format.Rate(sheep.High)}/s`
			growthBar.Visible = true
			Style.SetBar(growthBar, sheep.Growth)
		end
		lines[2].Text = if sheep.Slot > 0
			then (if sheep.Pinned then `In pen slot {sheep.Slot} (pinned)` else `In pen slot {sheep.Slot}`)
			else "Stored - not earning"
		lines[3].Text = if sellMode
			then `Sells for {Format.Short(sheep.Sell)} coins`
			elseif sheep.Locked then "Locked: can't be sold or merged"
			else ""
		Buttons.Set(
			equipButton,
			if sheep.Slot > 0 then "Soft" else "Action",
			if sheep.Slot > 0 then "Store" else "Equip"
		)
		Buttons.Set(lockButton, "Soft", if sheep.Locked then "Unlock" else "Lock")
		sellButton.Visible = sellMode
		if sellMode then
			Buttons.Set(sellButton, if sheep.Locked then "Disabled" else "Danger", `Sell {Format.Short(sheep.Sell)}`)
		end
	end

	local function refresh()
		local data = stateController:Get()
		if type(data.Sheep) ~= "table" then
			return
		end
		local flock = stateController:Flock(sorts[sortIndex])
		local equipped = 0
		for _, sheep in flock do
			if sheep.Slot > 0 then
				equipped += 1
			end
		end
		penLabel.Text = `{equipped}/{data.PenSlots}`
		if title then
			title.Text = if sellMode then "Sell Stall" else `Your Flock ({#flock}/{data.Limit})`
		end
		emptyLabel.Visible = #flock == 0
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") and child.Name ~= "CardTemplate" then
				child:Destroy()
			end
		end
		if picked and not sheepById(picked) then
			picked = nil
		end
		for order, sheep in flock do
			local card = MenuParts.NewCard(list, `Sheep{sheep.Id}`, order)
			local face = card:FindFirstChild("Face") :: Frame
			Style.PaintCard(card, SheepIcon.RarityLook(sheep.Rarity))
			SheepIcon.Paint(face:FindFirstChild("Token") :: Frame, sheep.Family, sheep.Rarity)
			local cardName = face:FindFirstChild("NameLabel") :: TextLabel
			cardName.Text = (string.gsub(string.gsub(sheep.Name, " Sheep$", ""), " Lamb$", " Lamb"))
			local price = face:FindFirstChild("PriceLabel", true) :: TextLabel
			price.Text = `+{Format.Rate(sheep.Income)}/s`
			local tag = face:FindFirstChild("CountLabel") :: TextLabel
			local marks: { string } = {}
			if sheep.Slot > 0 then
				table.insert(marks, "PEN")
			end
			if sheep.Locked then
				table.insert(marks, "LOCK")
			end
			tag.Text = table.concat(marks, " ")
			tag.Visible = #marks > 0
			local newTag = face:FindFirstChild("NewTag") :: TextLabel
			newTag.Text = "LAMB"
			newTag.Visible = not sheep.Adult
			trove:Connect(card.Activated, function()
				picked = sheep.Id
				MenuParts.Select(list, card)
				showDetail()
			end)
			if sheep.Id == picked then
				MenuParts.Select(list, card)
			end
		end
		if not picked and flock[1] then
			picked = flock[1].Id
			MenuParts.Select(list, list:FindFirstChild(`Sheep{picked}`))
		end
		showDetail()
	end

	local function act(action: string, id: string?)
		if busy then
			return
		end
		busy = true
		local callOk, success, message = Remotes.FlockAction:Invoke(action, id)
		busy = false
		if not callOk then
			return
		end
		local accepted = success == true
		if message then
			panel.Status(message, if accepted then "Good" else "Bad")
		end
		sound:Play(if accepted then "Click" else "Denied")
	end

	trove:Connect(sortButton.Activated, function()
		sortIndex = sortIndex % #sorts + 1
		Buttons.Set(sortButton, "Soft", sorts[sortIndex])
		sound:Play("Click")
		refresh()
	end)
	trove:Connect(bestButton.Activated, function()
		act("EquipBest", nil)
	end)
	trove:Connect(equipButton.Activated, function()
		local sheep = sheepById(picked)
		if sheep then
			act(if sheep.Slot > 0 then "Unequip" else "Equip", sheep.Id)
		end
	end)
	trove:Connect(lockButton.Activated, function()
		local sheep = sheepById(picked)
		if sheep then
			act(if sheep.Locked then "Unlock" else "Lock", sheep.Id)
		end
	end)
	trove:Connect(sellButton.Activated, function()
		local sheep = sheepById(picked)
		if not sheep then
			return
		end
		if sheep.Locked then
			panel.Status("Unlock it first", "Bad")
			sound:Play("Denied")
			return
		end
		local lost = if sheep.Slot > 0 then `You lose +{Format.Rate(sheep.Income)}/s` else "It isn't earning now"
		MenuParts.Confirm(gui, "Sell this sheep?", sheep.Name, lost, `Sell {Format.Short(sheep.Sell)}`, function(token)
			SheepIcon.Paint(token, sheep.Family, sheep.Rarity)
		end, function()
			act("Sell", sheep.Id)
			sound:Play("Purchase")
		end)
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Flock")
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
		Open = function(_self: Types.Screen, options: { [string]: any }?)
			sellMode = options ~= nil and options.Sell == true
			MenuParts.HideConfirm(gui)
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

return Flock
