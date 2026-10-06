--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Panel = require(script.Parent.Parent.Panel)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The free gift, in the Shop's look (a Prize Fleece menu): what it gives, big on a stage of rays; the two steps (like
-- the game, favorite it), each a picture of Roblox's own game page with the button to tap lit up; and Claim. Claim (or
-- tapping the favorite step) opens Roblox's favorite prompt and claims once that says yes. No game can see a like, so
-- the like is asked, not checked. It never opens by itself: the HUD's GIFT glows until it's claimed.
local Gift = {}

local Color = Theme.Color
local ACCENT = "Lab"
local PANEL_HEIGHT = 470
local PRIZE_HEIGHT = 96
local AMOUNT_TEXT = 44
-- Roblox's game page with the button to tap lit up (art/gift/step-pictures.js makes them).
local LIKE_PICTURE = "rbxassetid://79093897520396"
local FAVORITE_PICTURE = "rbxassetid://94266843104437"
local PICTURE_ASPECT = 912 / 376

-- One reward: its picture, then the amount (`labelName`) over what it is.
local function reward(parent: Instance, name: string, icon: string, labelName: string, color: Color3, word: string)
	local holder = UIKit.Frame(parent, name, UDim2.fromOffset(0, PRIZE_HEIGHT))
	holder.AutomaticSize = Enum.AutomaticSize.X
	UIKit.List(holder, true, 6)
	UIKit.Icon(holder, "Icon", icon, 74)
	local column = UIKit.Frame(holder, "Column", UDim2.fromOffset(0, 74))
	column.AutomaticSize = Enum.AutomaticSize.X
	column.LayoutOrder = 1
	UIKit.List(column, false, -8).VerticalAlignment = Enum.VerticalAlignment.Center
	local amount = UIKit.Text(column, labelName, "", AMOUNT_TEXT, color, UDim2.fromOffset(0, AMOUNT_TEXT + 6), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		AlignX = Enum.TextXAlignment.Left,
		Order = 1,
	})
	local stroke = amount:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = 4.5
	end
	UIKit.Text(column, "WordLabel", word, 20, Color.Snow, UDim2.fromOffset(0, 24), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		AlignX = Enum.TextXAlignment.Left,
		Order = 2,
	})
	return holder
end

-- A stage of rays in the menu's colour (UIKit.Stage, its own picture unused) with the rewards in a row (Line).
local function prize(parent: Instance): Frame
	local stage = UIKit.Stage(parent, "Prize", UDim2.fromScale(1, 1), 10)
	Style.PaintStage(stage, nil, ACCENT)
	local picture = stage:FindFirstChild("Picture")
	if picture and picture:IsA("GuiObject") then
		picture.Visible = false
	end
	local line = UIKit.Frame(stage, "Line", UDim2.fromScale(1, 1))
	line.ZIndex = 2
	UIKit.List(line, true, 14, Enum.HorizontalAlignment.Center)
	return line
end

-- A step: its number and title, the game page's picture (Picture, a check on its corner once done), and one line.
local function step(parent: Instance, name: string, number: string, title: string, picture: string, line: string)
	local tile = UIKit.Tile(parent, name, UDim2.new(0.5, -6, 1, 0))
	tile.LayoutOrder = tonumber(number) or 0
	UIKit.Padding(tile, 10, 10, 8, 8)
	UIKit.List(tile, false, 6, Enum.HorizontalAlignment.Center)
	local head = UIKit.Frame(tile, "Head", UDim2.fromOffset(0, 30))
	head.AutomaticSize = Enum.AutomaticSize.X
	head.LayoutOrder = 1
	UIKit.List(head, true, 8)
	local accent = UIKit.Accent(ACCENT)
	local disc = UIKit.Frame(head, "Number", UDim2.fromOffset(28, 28), accent.Base)
	UIKit.Corner(disc)
	UIKit.Surface(disc, accent.Lo, 2, Color.Line, Theme.Line.Normal)
	UIKit.Text(disc, "Label", number, 18, Color.Snow, UDim2.fromScale(1, 1), { Stroke = Color.Line })
	UIKit.Text(head, "TitleLabel", title, 22, Color.Snow, UDim2.fromOffset(0, 30), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local shot = UIKit.Icon(tile, "Picture", picture, 100)
	shot.LayoutOrder = 2
	shot.Size = UDim2.fromScale(1, 1)
	shot.ScaleType = Enum.ScaleType.Stretch
	UIKit.Grow(shot)
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = PICTURE_ASPECT
	aspect.Parent = shot
	UIKit.Corner(shot, 10)
	local edge = Instance.new("UIStroke")
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edge.Color = Color.Line
	edge.Thickness = Theme.Line.Normal
	edge.Parent = shot
	local done = UIKit.Icon(shot, "Done", Theme.Icons.HudCheck, 40)
	done.AnchorPoint = Vector2.new(0.5, 0.5)
	done.Position = UDim2.new(1, -6, 0, 6)
	done.ZIndex = 5
	done.Visible = false
	UIKit.Text(tile, "LineLabel", line, 16, Theme.Fleece.Muted, UDim2.new(1, 0, 0, 20), {
		Font = Theme.Font.TextHeavy,
		Fit = true,
		Order = 3,
	})
	return shot
end

function Gift.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Gift", "Day", "Free Gift!", nil, false, nil, {
		Accent = ACCENT,
		Badge = Theme.Icons.MenuGift,
		Size = "Large",
	})
	window:SetAttribute("PanelHeight", PANEL_HEIGHT)
	-- The gift is about what it gives, not the balance: no cash chip in this header.
	local cash = window:FindFirstChild("CashChip", true)
	if cash and cash:IsA("GuiObject") then
		cash.Visible = false
	end
	local page = window:FindFirstChild("Pages") :: Frame
	UIKit.List(page, false, 10, Enum.HorizontalAlignment.Center)

	local prizes = UIKit.Frame(page, "Prizes", UDim2.new(1, 0, 0, PRIZE_HEIGHT))
	prizes.LayoutOrder = 1
	local line = prize(prizes)
	reward(line, "ClimbReward", Theme.Icons.HudShoe, "ClimbLabel", Color.Gold300, "CLIMBING").LayoutOrder = 1
	UIKit.Text(line, "Plus", "+", 40, Color.Snow, UDim2.fromOffset(30, PRIZE_HEIGHT), {
		Stroke = Color.Line,
		Order = 2,
	})
	reward(line, "CoinReward", Theme.Icons.HudCash, "CoinLabel", Color.Lime, "CASH").LayoutOrder = 3

	local steps = UIKit.Frame(page, "Steps", UDim2.fromScale(1, 0))
	steps.LayoutOrder = 2
	UIKit.Grow(steps)
	UIKit.List(steps, true, 12)
	step(steps, "LikeStep", "1", "Like the game", LIKE_PICTURE, "Thumbs up on its page")
	local favorite = step(steps, "FavoriteStep", "2", "Favorite the game", FAVORITE_PICTURE, "Tap here, or the star")
	local tap = Instance.new("TextButton")
	tap.Name = "FavoriteButton"
	tap.Text = ""
	tap.BackgroundTransparency = 1
	tap.Size = UDim2.fromScale(1, 1)
	tap.ZIndex = 6
	tap.Parent = favorite

	local claim = UIKit.Button(page, "ClaimButton", "Buy", 280, Theme.ButtonHeight.Hero, "Claim!")
	claim.LayoutOrder = 3
	UIKit.LightText(window)
	gui.Parent = playerGui
	return gui
end

function Gift.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local panel = Panel.Bind(gui, trove)
	local window = panel.Window
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local climbLabel = window:FindFirstChild("ClimbLabel", true) :: TextLabel
	local coinLabel = window:FindFirstChild("CoinLabel", true) :: TextLabel
	local claimButton = window:FindFirstChild("ClaimButton", true) :: TextButton
	local favoriteStep = window:FindFirstChild("FavoriteStep", true) :: Frame
	local favoriteDone = favoriteStep:FindFirstChild("Done", true) :: ImageLabel
	local favoriteButton = favoriteStep:FindFirstChild("FavoriteButton", true) :: TextButton
	local busy = false
	local favorited = false

	local function refresh()
		local data = stateController:Get()
		climbLabel.Text = `+{Format.Short(data.GiftClimb or Economy.GiftClimb)}`
		coinLabel.Text = `+{Format.Short(data.GiftCoins or Economy.GiftCoins)}`
		favoriteDone.Visible = favorited
		if data.FreeGift == true then
			Buttons.Set(claimButton, "Owned", "Claimed")
		else
			Buttons.Set(claimButton, "Buy", "Claim!")
		end
	end

	local function isFavorite(): boolean
		local ok, result = pcall(function()
			return AvatarEditorService:GetFavoriteAsync(game.PlaceId, Enum.AvatarItemType.Asset)
		end)
		return ok and result == true
	end

	-- Roblox's favorite prompt for this game: true once the player says yes, or if they favorited it before (they'd
	-- have nothing to say yes to). An unpublished place (PlaceId 0, a Studio playtest) has nothing to favorite, so there
	-- it counts as done.
	local function favorite(): boolean
		if game.PlaceId == 0 then
			return true
		end
		if isFavorite() then
			return true
		end
		local answer: Enum.AvatarPromptResult? = nil
		local connection = AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result)
			answer = result
		end)
		local prompted = pcall(function()
			AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
		end)
		local waited = 0
		while prompted and answer == nil and waited < GameConfig.Gift.FavoriteTimeout do
			waited += task.wait(0.1)
		end
		connection:Disconnect()
		return answer == Enum.AvatarPromptResult.Success or isFavorite()
	end

	local function claim()
		if busy then
			return
		end
		if stateController:Get().FreeGift ~= false then
			Buttons.Shake(claimButton)
			return
		end
		busy = true
		Buttons.Loading(claimButton, true)
		if not favorited then
			favorited = favorite()
			refresh()
		end
		if not favorited then
			Buttons.Loading(claimButton, false)
			busy = false
			panel.Status("Favorite the game to claim", "Bad")
			sound:Play("Denied")
			return
		end
		local callOk, success, message, coins, climb = Remotes.ClaimGift:Invoke()
		Buttons.Loading(claimButton, false)
		busy = false
		if not callOk or not success then
			panel.Status(if callOk and message then message else "Try again", "Bad")
			sound:Play("Denied")
			refresh()
			return
		end
		sound:Play("RevealCoins")
		context.Close("Gift")
		context.Controllers.UIController:Celebrate(
			"FREE GIFT!",
			`+{Format.Short(climb or 0)} Climbing  +{Format.Short(coins or 0)} Cash`
		)
	end

	trove:Connect(claimButton.Activated, claim)
	trove:Connect(favoriteButton.Activated, function()
		if busy or favorited then
			return
		end
		busy = true
		favorited = favorite()
		busy = false
		refresh()
		if favorited then
			panel.Status("Favorited! Now claim your gift", "Good")
			sound:Play("StepDone")
		end
	end)
	if panel.CloseButton then
		trove:Connect(panel.CloseButton.Activated, function()
			context.Close("Gift")
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

return Gift
