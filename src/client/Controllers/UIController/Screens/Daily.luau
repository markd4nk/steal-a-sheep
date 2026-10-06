--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Motion = require(script.Parent.Parent.Motion)
local Panel = require(script.Parent.Parent.Panel)
local SheepIcon = require(script.Parent.Parent.SheepIcon)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The daily gifts (DailyService), as the user picked from DESIGN/ui/mockups/daily-gifts.html (layout B): Days 1-6 as
-- cards in a grid, Day 7's Pegasus Sheep big on the right over Claim. Days claimed go dark with a tick, today's is
-- gold and glowing, the days ahead blue, each showing what it gives this player now. Once claimed, Claim counts down
-- to the next. Opens by itself once a session while a gift waits (GameConfig.Daily), but never in a player's first
-- session; the HUD's DAILY opens it any time. Claiming Day 7 brings the Pegasus up on its own card.
local Daily = {}

type DayState = "Done" | "Today" | "Ahead"

local Color = Theme.Color
local Fleece = Theme.Fleece
local ACCENT = "Daily"
local PANEL_WIDTH = 600
-- The height a panel is laid out at on a short screen (Theme.Fleece.CompactHeight): the same layout everywhere, scaled.
local PANEL_HEIGHT = Fleece.CompactHeight
local CARD = Vector2.new(110, 111)
local CARD_GAP = 10
local PICTURE = 58
local TODAY_LIFT = 1.04
-- Day 7's stage: a sky over the Epic purple.
local SKY = Color3.fromRGB(143, 216, 255)
local DUSK = Color3.fromRGB(139, 85, 232)
local POP_WIDTH = 320

-- Each day's picture, the prize growing with the week; Day 4's lamb is a token of its family instead.
local PICTURES: { [number]: string } = {
	[1] = Theme.Icons.DailyCash1,
	[2] = Theme.Icons.DailyClimb1,
	[3] = Theme.Icons.DailyCash3,
	[5] = Theme.Icons.DailyClimb3,
	[6] = Theme.Icons.DailyCash5,
}

-- A day's card (UIKit.SheepCard): "Day N" on top, its picture, what it gives in the strip at its foot, a tick once
-- claimed.
local function dayCard(parent: Instance, day: number): TextButton
	local card = UIKit.SheepCard(parent, `Day{day}`)
	card.LayoutOrder = day
	local face = card:FindFirstChild("Face") :: Frame
	local name = face:FindFirstChild("NameLabel") :: TextLabel
	name.Text = `Day {day}`
	name.TextSize = 17
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 5)
	name.Size = UDim2.new(1, -10, 0, 20)
	local rays = face:FindFirstChild("Rays") :: ImageLabel
	rays.Position = UDim2.new(0.5, 0, 0, 53)
	local picture = face:FindFirstChild("Picture") :: ImageLabel
	picture.Size = UDim2.fromOffset(PICTURE, PICTURE)
	picture.Position = UDim2.new(0.5, 0, 0, 24)
	local kind = Economy.DailyWeek[day].Kind
	if kind == "Lamb" then
		picture.Visible = false
		local token = UIKit.Token(face, PICTURE, "Token")
		token.AnchorPoint = Vector2.new(0.5, 0)
		token.Position = UDim2.new(0.5, 0, 0, 24)
		token.ZIndex = 2
	else
		picture.Image = PICTURES[day] or ""
	end
	local strip = face:FindFirstChild("Strip") :: Frame
	local icon = strip:FindFirstChild("Icon")
	if icon and icon:IsA("GuiObject") then
		icon.Visible = false
	end
	local amount = strip:FindFirstChild("PriceLabel") :: TextLabel
	amount.TextSize = 17
	amount.TextColor3 = if kind == "Cash" then Color.Lime elseif kind == "Climb" then Color.Gold300 else Color.Blue200
	local done = UIKit.Icon(face, "Done", Theme.Icons.HudCheck, 50)
	done.AnchorPoint = Vector2.new(0.5, 0.5)
	done.Position = UDim2.new(0.5, 0, 0, 53)
	done.ZIndex = 6
	done.Visible = false
	return card
end

-- Day 7's stage: the Pegasus on rays in a sky, "Day 7" over it, its name and SUPER RARE (a rainbow chip) under it, a
-- tick once claimed.
local function pegasusStage(parent: Instance, name: string, size: UDim2): Frame
	local stage = UIKit.Stage(parent, name, size, 10)
	UIKit.Lit(stage, SKY, DUSK, 1)
	UIKit.Glow(stage, Color.Snow, Color.Gold300, 6)
	local picture = stage:FindFirstChild("Picture") :: ImageLabel
	picture.Image = Theme.Icons.Pegasus
	picture.ScaleType = Enum.ScaleType.Fit
	picture.AnchorPoint = Vector2.new(0.5, 0)
	picture.Position = UDim2.new(0.5, 0, 0, 24)
	picture.Size = UDim2.new(0.86, 0, 1, -82)
	UIKit.Text(stage, "DayLabel", "Day 7", 19, Color.Snow, UDim2.new(1, 0, 0, 24), { Stroke = Color.Line }).ZIndex = 3
	local title = UIKit.Text(stage, "NameLabel", "Pegasus Sheep", 22, Color.Snow, UDim2.new(1, -12, 0, 26), {
		Stroke = Color.Line,
		Fit = true,
	})
	title.AnchorPoint = Vector2.new(0.5, 1)
	title.Position = UDim2.new(0.5, 0, 1, -34)
	title.ZIndex = 3
	local chip = UIKit.RarityChip(stage, "RareChip")
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.new(0.5, 0, 1, -8)
	chip.ZIndex = 3
	local gradient = chip:FindFirstChildOfClass("UIGradient")
	if gradient then
		gradient.Color = Theme.Rainbow
		gradient.Rotation = Theme.RainbowRotation
	end
	local chipLabel = chip:FindFirstChild("Label") :: TextLabel
	chipLabel.Text = "SUPER RARE"
	local shade = UIKit.Frame(stage, "Shade", UDim2.fromScale(1, 1), Color.Ink)
	shade.BackgroundTransparency = 0.45
	shade.ZIndex = 4
	shade.Visible = false
	local done = UIKit.Icon(stage, "Done", Theme.Icons.HudCheck, 60)
	done.AnchorPoint = Vector2.new(0.5, 0.5)
	done.Position = UDim2.fromScale(0.5, 0.45)
	done.ZIndex = 5
	done.Visible = false
	return stage
end

function Daily.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Daily", "Day", "Daily Gifts", nil, false, nil, {
		Accent = ACCENT,
		Badge = Theme.Icons.HudDaily,
		Size = "Medium",
		Width = PANEL_WIDTH,
	})
	window:SetAttribute("PanelHeight", PANEL_HEIGHT)
	-- About what it gives, not the balance: no cash chip.
	local cash = window:FindFirstChild("CashChip", true)
	if cash and cash:IsA("GuiObject") then
		cash.Visible = false
	end
	local page = window:FindFirstChild("Pages") :: Frame

	local gridWidth = 3 * CARD.X + 2 * CARD_GAP
	local grid = UIKit.Frame(page, "Grid", UDim2.new(0, gridWidth, 1, 0))
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(CARD.X, CARD.Y)
	layout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
	for day = 1, #Economy.DailyWeek - 1 do
		dayCard(grid, day)
	end

	local side = UIKit.Frame(page, "Side", UDim2.new(1, -(gridWidth + Fleece.Inset), 1, 0))
	side.AnchorPoint = Vector2.new(1, 0)
	side.Position = UDim2.fromScale(1, 0)
	UIKit.List(side, false, 10, Enum.HorizontalAlignment.Center)
	local claim = UIKit.Button(side, "ClaimButton", "Buy", 200, Theme.ButtonHeight.Hero, "Claim!")
	claim.Size = UDim2.new(1, 0, 0, claim.Size.Y.Offset)
	claim.LayoutOrder = 2
	pegasusStage(side, "Hero", UDim2.new(1, 0, 1, -(claim.Size.Y.Offset + 10))).LayoutOrder = 1
	UIKit.LightText(window)

	-- Day 7's own card over the menu once it's claimed.
	local root = gui:FindFirstChild("Root") :: Frame
	local cover = UIKit.Frame(root, "PegasusCover", UDim2.fromScale(1, 1))
	cover.Active = true
	cover.Visible = false
	cover.ZIndex = 20
	UIKit.Backdrop(cover, Theme.Motion.ConfirmBackdrop).ZIndex = 20
	local card, body = UIKit.PopCard(cover, "PegasusCard", {
		Width = POP_WIDTH,
		Title = "Day 7!",
		Accent = ACCENT,
		Badge = Theme.Icons.HudDaily,
		Gap = 8,
	})
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.ZIndex = 21
	local stage = pegasusStage(body, "Stage", UDim2.new(1, 0, 0, 150))
	stage.LayoutOrder = 1
	for _, hidden in { "DayLabel", "NameLabel" } do
		(stage:FindFirstChild(hidden) :: GuiObject).Visible = false
	end
	local picture = stage:FindFirstChild("Picture") :: ImageLabel
	picture.Position = UDim2.new(0.5, 0, 0, 6)
	picture.Size = UDim2.new(0.86, 0, 1, -40)
	UIKit.Text(body, "PopName", "Pegasus Sheep", 30, Color.Snow, UDim2.new(1, 0, 0, 34), {
		Stroke = Color.Line,
		Fit = true,
		Order = 2,
	})
	UIKit.Text(body, "PopLine", "In your pen now", 16, Fleece.Muted, UDim2.new(1, 0, 0, 20), {
		Font = Theme.Font.TextHeavy,
		Fit = true,
		Order = 3,
	})
	local ok = UIKit.Button(body, "OkButton", "Buy", 200, Theme.ButtonHeight.Standard, "Awesome!")
	ok.Size = UDim2.new(1, 0, 0, ok.Size.Y.Offset)
	ok.LayoutOrder = 4
	UIKit.LightText(card)
	gui.Parent = playerGui
	return gui
end

function Daily.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local root = gui:FindFirstChild("Root") :: Frame
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local player = Players.LocalPlayer
	local cards: { [number]: TextButton } = {}
	for day = 1, #Economy.DailyWeek - 1 do
		cards[day] = window:FindFirstChild(`Day{day}`, true) :: TextButton
	end
	local hero = window:FindFirstChild("Hero", true) :: Frame
	local claimButton = window:FindFirstChild("ClaimButton", true) :: TextButton
	local cover = root:FindFirstChild("PegasusCover") :: Frame
	local backdrop = cover:FindFirstChild("Backdrop") :: GuiObject
	local popCard = cover:FindFirstChild("PegasusCard") :: Frame
	local popLine = popCard:FindFirstChild("PopLine", true) :: TextLabel
	local okButton = popCard:FindFirstChild("OkButton", true) :: TextButton
	local busy = false
	local ticking = 0

	local function daily(): { [string]: any }?
		local data = stateController:Get().Daily
		return if type(data) == "table" then data else nil
	end

	local function isReady(data: { [string]: any }): boolean
		return (data.ReadyAt or 0) <= workspace:GetServerTimeNow()
	end

	-- "19:59:58" to the next gift.
	local function countdown(data: { [string]: any }): string
		local left = math.max(0, math.ceil((data.ReadyAt or 0) - workspace:GetServerTimeNow()))
		return string.format("%d:%02d:%02d", left // 3600, left % 3600 // 60, left % 60)
	end

	-- Which days are claimed: the ones before today's while a gift waits; once it's claimed, through the one just
	-- claimed (the whole week once Day 7 is, until the next Day 1).
	local function stateOf(data: { [string]: any }, day: number): DayState
		local ready = isReady(data)
		local through = if ready then data.Day - 1 elseif data.Day == 1 then #Economy.DailyWeek else data.Day - 1
		if day <= through then
			return "Done"
		end
		return if ready and day == data.Day then "Today" else "Ahead"
	end

	local function paintCard(card: TextButton, day: number, state: DayState, data: { [string]: any })
		local face = card:FindFirstChild("Face") :: Frame
		Style.PaintCard(card, if state == "Today" then "Legendary" else "Rare", state == "Done")
		local done = state == "Done"
		local today = state == "Today"
		local picture = face:FindFirstChild("Picture") :: ImageLabel
		local token = face:FindFirstChild("Token")
		local kind = Economy.DailyWeek[day].Kind
		picture.Visible = kind ~= "Lamb" and not done
		if token and token:IsA("GuiObject") then
			token.Visible = not done
			SheepIcon.Paint(token, data.LambFamily or "Meadow", 2)
		end
		local rays = face:FindFirstChild("Rays") :: ImageLabel
		rays.Visible = not done;
		(face:FindFirstChild("Done") :: GuiObject).Visible = done
		local amount = face:FindFirstChild("PriceLabel", true) :: TextLabel
		local amounts = data.Amounts or {}
		amount.Text = if kind == "Lamb" then "Shiny lamb" else `+{Format.Short(amounts[day] or 0)}`
		for _, ring in { "Selected", "SelectedRing" } do
			local stroke = face:FindFirstChild(ring)
			if stroke and stroke:IsA("UIStroke") then
				stroke.Enabled = today
			end
		end
		Motion.SetGlow(Motion.FindGlow(face), today)
		local lift = card:FindFirstChild("Lift")
		if lift and lift:IsA("UIScale") then
			lift.Scale = if today then TODAY_LIFT else 1
		end
	end

	local function refresh()
		local data = daily()
		if not data then
			return
		end
		for day, card in cards do
			paintCard(card, day, stateOf(data, day), data)
		end
		local seventh = stateOf(data, #Economy.DailyWeek);
		(hero:FindFirstChild("Shade") :: GuiObject).Visible = seventh == "Done"
		(hero:FindFirstChild("Done") :: GuiObject).Visible = seventh == "Done"
		Motion.SetGlow(Motion.FindGlow(hero), seventh == "Today")
		if isReady(data) then
			Buttons.Set(claimButton, "Buy", "Claim!")
		else
			Buttons.Set(claimButton, "Disabled", `Next in {countdown(data)}`)
		end
	end

	local function showPegasus(given: { [string]: any })
		popLine.Text = if given.Stored then "Stored: your pen is full" else "In your pen now"
		cover.Visible = true
		Motion.PopIn(popCard, backdrop)
		sound:Play("RevealFanfare")
	end

	local function claim()
		if busy then
			return
		end
		local data = daily()
		if not data or not isReady(data) then
			Buttons.Shake(claimButton)
			sound:Play("Denied")
			return
		end
		busy = true
		Buttons.Loading(claimButton, true)
		local callOk, success, message, given = Remotes.ClaimDaily:Invoke()
		Buttons.Loading(claimButton, false)
		busy = false
		if not callOk or not success or type(given) ~= "table" then
			panel.Status(if callOk and message then message else "Try again", "Bad")
			sound:Play("Denied")
			refresh()
			return
		end
		if given.Kind == "Cash" then
			sound:Play("RevealCoins")
			panel.Status(`+{Format.Short(given.Amount or 0)} cash`, "Good")
		elseif given.Kind == "Climb" then
			sound:Play("Upgrade")
			panel.Status(`+{Format.Short(given.Amount or 0)} Climbing`, "Good")
		elseif given.Kind == "Lamb" then
			sound:Play("Reveal")
			if given.Stored then
				panel.Status(`{given.Name} is stored: your pen is full`, "Bad")
			else
				panel.Status(`{given.Name} is in your pen!`, "Good")
			end
		else
			showPegasus(given)
		end
		refresh()
	end

	trove:Connect(claimButton.Activated, claim)
	for _, card in cards do
		-- Today's card claims too.
		trove:Connect(card.Activated, function()
			local data = daily()
			if data and isReady(data) and cards[data.Day] == card then
				claim()
			end
		end)
	end
	trove:Connect(okButton.Activated, function()
		Motion.PopOut(popCard, backdrop, function()
			cover.Visible = false
		end)
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Daily")
		end)
	end
	trove:Add(stateController.Changed:Connect(function()
		if gui.Enabled then
			refresh()
		end
	end))
	-- The countdown, once a second while the menu is open.
	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		ticking += deltaTime
		if ticking < 1 or not gui.Enabled then
			return
		end
		ticking = 0
		refresh()
	end)

	-- Once a session: AutoOpenSeconds after a gift is waiting, as soon as the player is off the mountain, not carrying
	-- a lamb, and no other menu is open.
	task.spawn(function()
		local readySince: number? = nil
		while gui.Parent do
			local data = daily()
			if
				not data
				or not isReady(data)
				or (stateController:Get().Tutorial or 0) < 1
				or stateController:IsFirstSession()
			then
				readySince = nil
			else
				local since = readySince or os.clock()
				readySince = since
				local character = player.Character
				local here = character and character:GetPivot().Position
				local calm = here ~= nil
					and not Mountain.IsOnRamp(here)
					and player:GetAttribute("Carrying") ~= true
					and not context.Controllers.UIController:IsModalOpen()
				if calm and os.clock() - since >= GameConfig.Daily.AutoOpenSeconds then
					context.Open("Daily")
					return
				end
			end
			task.wait(1)
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
			cover.Visible = false
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

return Daily
