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

-- The Merge Shrine: three unlocked adults of one family, fleece and rank become one of the next rank, guaranteed. The
-- cards are the groups that can merge; the preview beside them names the three it uses (the biggest, then the two
-- that earn least), the result, the three's income against the result's, and the flock's income after.
local Merge = {}

type View = {
	Id: string,
	Family: string,
	Rarity: number,
	Weight: number,
	Size: number,
	Rank: number,
	Locked: boolean,
	Slot: number,
	Adult: boolean,
	Income: number,
	Name: string,
}

type Group = { Key: string, Members: { View }, Picked: { View } }

local MERGE_SECONDS = 1.6 -- the shrine's moment before the result shows

function Merge.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Merge", "Day", "Merge Shrine", nil, false, nil, {
		Accent = "Lab",
		Badge = Theme.Icons.Helix,
		Size = "Large",
		Width = 780,
	})
	local page = MenuParts.Pages(window)
	MenuParts.CardGrid(page)
	local detail = MenuParts.Detail(page, MenuParts.GridWidth)
	local buttons = detail:FindFirstChild("Buttons") :: Frame
	local button = UIKit.Button(buttons, "MergeButton", "Buy", 160, Theme.ButtonHeight.Standard, "Merge")
	UIKit.Grow(button)
	UIKit.Text(page, "EmptyLabel", "", 18, Theme.Fleece.Muted, UDim2.new(0, MenuParts.GridWidth - 20, 0, 80), {
		Font = Theme.Font.TextHeavy,
		Wrap = true,
	}).Position =
		UDim2.new(0, 10, 0.35, 0)
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

-- Groups of three or more unlocked adults that can merge, with the three each would use.
local function groupsOf(flock: { View }): { Group }
	local byKey: { [string]: { View } } = {}
	for _, sheep in flock do
		if sheep.Adult and not sheep.Locked and sheep.Rank < Economy.MaxRank then
			local key = `{sheep.Family}|{sheep.Rarity}|{sheep.Rank}`
			byKey[key] = byKey[key] or {}
			table.insert(byKey[key], sheep)
		end
	end
	local groups: { Group } = {}
	for key, members in byKey do
		if #members >= 3 then
			local sorted = table.clone(members)
			-- The biggest goes in (the result takes its size); then whichever two earn least, stored ones first.
			table.sort(sorted, function(a: View, b: View)
				if a.Size ~= b.Size then
					return a.Size > b.Size
				end
				return (a.Slot > 0 and 1 or 0) < (b.Slot > 0 and 1 or 0)
			end)
			local picked = { sorted[1] }
			local rest = { table.unpack(sorted, 2) }
			table.sort(rest, function(a: View, b: View)
				local aOn, bOn = a.Slot > 0, b.Slot > 0
				if aOn ~= bOn then
					return not aOn
				end
				return a.Income < b.Income
			end)
			table.insert(picked, rest[1])
			table.insert(picked, rest[2])
			table.insert(groups, { Key = key, Members = members, Picked = picked })
		end
	end
	table.sort(groups, function(a: Group, b: Group)
		return a.Picked[1].Income > b.Picked[1].Income
	end)
	return groups
end

function Merge.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local list = window:FindFirstChild("List", true) :: ScrollingFrame
	local detail = window:FindFirstChild("Detail", true) :: Frame
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
	local mergeButton = detail:FindFirstChild("MergeButton", true) :: TextButton
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local pickedKey: string? = nil
	local groups: { Group } = {}
	local busy = false

	local function current(): Group?
		for _, group in groups do
			if group.Key == pickedKey then
				return group
			end
		end
		return nil
	end

	local function showDetail()
		local group = current()
		detail.Visible = group ~= nil
		if not group then
			return
		end
		local inputs = group.Picked
		local first = inputs[1]
		local result = Economy.MergeResult(inputs :: any)
		local resultIncome = Economy.AdultIncome(result)
		nameLabel.Text = Economy.Name(result)
		Style.PaintRarity(rarityChip, SheepIcon.RarityLook(first.Rarity))
		local rarityLabel = rarityChip:FindFirstChild("Label")
		if rarityLabel and rarityLabel:IsA("TextLabel") then
			rarityLabel.Text = string.upper(Economy.Rarities[first.Rarity].Name)
		end
		rankChip.Visible = true
		Style.PaintRarity(rankChip, if result.Rank >= 2 then "Mythic" else "Epic")
		local rankLabel = rankChip:FindFirstChild("Label")
		if rankLabel and rankLabel:IsA("TextLabel") then
			rankLabel.Text = `{string.upper(Economy.RankNames[result.Rank])} x{3 ^ result.Rank}`
		end
		Style.PaintStage(stage, SheepIcon.RarityLook(first.Rarity))
		rateLabel.Text = `+{Format.Rate(resultIncome)}/s`
		MenuParts.ShowSheep(view, first.Family, Economy.Sizes[result.Size].Scale)
		local sizes: { string } = {}
		local together = 0
		local equippedIncome = 0
		local anyEquipped = false
		for _, sheep in inputs do
			table.insert(sizes, Economy.Sizes[sheep.Size].Name)
			together += sheep.Income
			if sheep.Slot > 0 then
				anyEquipped = true
				equippedIncome += sheep.Income
			end
		end
		local data = stateController:Get()
		local flockNow = if type(data.Income) == "number" then data.Income else 0
		local flockAfter = flockNow - equippedIncome + (if anyEquipped then resultIncome else 0)
		lines[1].Text = `Uses 3: {table.concat(sizes, ", ")}`
		lines[2].Text = `+{Format.Rate(together)}/s together -> +{Format.Rate(resultIncome)}/s`
		lines[3].Text = `Flock: +{Format.Rate(flockNow)}/s -> +{Format.Rate(flockAfter)}/s`
		Buttons.Set(mergeButton, "Buy", "Merge")
	end

	local function refresh()
		local data = stateController:Get()
		for _, child in list:GetChildren() do
			if child:IsA("TextButton") and child.Name ~= "CardTemplate" then
				child:Destroy()
			end
		end
		if data.MergeReady ~= true then
			groups = {}
			emptyLabel.Text = "The shrine opens after your third delivery"
			emptyLabel.Visible = true
			detail.Visible = false
			return
		end
		groups = groupsOf(stateController:Flock() :: any)
		emptyLabel.Text = "Bring three grown sheep of the same family, fleece and rank"
		emptyLabel.Visible = #groups == 0
		if not current() then
			pickedKey = if groups[1] then groups[1].Key else nil
		end
		for order, group in groups do
			local first = group.Picked[1]
			local card = MenuParts.NewCard(list, `Group{order}`, order)
			local face = card:FindFirstChild("Face") :: Frame
			Style.PaintCard(card, SheepIcon.RarityLook(first.Rarity))
			SheepIcon.Paint(face:FindFirstChild("Token") :: Frame, first.Family, first.Rarity)
			local cardName = face:FindFirstChild("NameLabel") :: TextLabel
			cardName.Text = (string.gsub(first.Name, " Sheep$", ""))
			local price = face:FindFirstChild("PriceLabel", true) :: TextLabel
			price.Text = `+{Format.Rate(first.Income)}/s`
			local count = face:FindFirstChild("CountLabel") :: TextLabel
			count.Text = `x{#group.Members}`
			count.Visible = true
			trove:Connect(card.Activated, function()
				pickedKey = group.Key
				MenuParts.Select(list, card)
				showDetail()
			end)
			if group.Key == pickedKey then
				MenuParts.Select(list, card)
			end
		end
		showDetail()
	end

	trove:Connect(mergeButton.Activated, function()
		local group = current()
		if not group or busy then
			return
		end
		busy = true
		Buttons.Loading(mergeButton, true)
		sound:Play("LabCharge")
		task.wait(MERGE_SECONDS)
		local ids = { group.Picked[1].Id, group.Picked[2].Id, group.Picked[3].Id }
		local callOk, success, message = Remotes.Merge:Invoke(ids)
		Buttons.Loading(mergeButton, false)
		busy = false
		if not callOk then
			return
		end
		if success then
			sound:Play("SpinWin")
			context.Controllers.UIController:Celebrate("MERGED!", message or "")
		else
			sound:Play("Denied")
			panel.Status(message or "Can't merge those", "Bad")
		end
		refresh()
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Merge")
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

return Merge
