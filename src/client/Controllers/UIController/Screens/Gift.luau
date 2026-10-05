--!strict

local AvatarEditorService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local Panel = require(script.Parent.Parent.Panel)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The free gift, in the Shop's look (a Prize Fleece menu): the gift on a stage beside what it gives, the two steps
-- (like the game, favorite it) each with a picture of the button to press on the game's page, and Claim. Claim opens
-- Roblox's own favorite prompt and claims once that says yes. No game can see a like, so the like is asked, not
-- checked. Opens by itself once a session until it's claimed (GameConfig.Gift).
local Gift = {}

local Color = Theme.Color
local ACCENT = "Lab"
local TOP_HEIGHT = 110
local STEP_HEIGHT = 104
local REWARD_TEXT = 34

local function reward(parent: Instance, name: string, icon: string, labelName: string, color: Color3, order: number)
	local line = UIKit.Frame(parent, name, UDim2.fromOffset(0, 48))
	line.AutomaticSize = Enum.AutomaticSize.X
	line.LayoutOrder = order
	UIKit.List(line, true, 8)
	UIKit.Icon(line, "Icon", icon, 46)
	local label = UIKit.Text(line, labelName, "", REWARD_TEXT, color, UDim2.fromOffset(0, 44), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
	local stroke = label:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = 4
	end
end

-- A red pointer at the button to press (UIKit.Pointer is drawn pointing down; -90 points it right).
local function pointer(parent: Instance, position: UDim2)
	local arrow = UIKit.Pointer(parent, "Pointer", 34, Color.Red500)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Position = position
	arrow.Rotation = -90
	arrow.ZIndex = 4
end

-- A step: its title over a dark well holding the picture (Picture), with a check (Done) at its right once it's done.
local function step(parent: Instance, name: string, title: string, order: number): Frame
	local tile = UIKit.Tile(parent, name, UDim2.new(0.5, -6, 1, 0))
	tile.LayoutOrder = order
	UIKit.Padding(tile, 10, 10, 6, 10)
	UIKit.List(tile, false, 4, Enum.HorizontalAlignment.Center)
	UIKit.Text(tile, "TitleLabel", title, 20, Color.Snow, UDim2.new(1, 0, 0, 26), {
		Stroke = Color.Line,
		Fit = true,
		Order = 1,
	})
	local well = UIKit.Well(tile, "Picture", UDim2.new(1, 0, 1, -30))
	well.LayoutOrder = 2
	local done = UIKit.Icon(well, "Done", Theme.Icons.HudCheck, 34)
	done.AnchorPoint = Vector2.new(0.5, 0.5)
	done.Position = UDim2.new(1, -24, 0.5, 0)
	done.ZIndex = 5
	done.Visible = false
	return well
end

-- The game page's vote buttons: a thumb up, the bar, a thumb down; the pointer at the thumb up.
local function likePicture(well: Frame)
	local row = UIKit.Frame(well, "Row", UDim2.fromScale(1, 1))
	UIKit.List(row, true, 8, Enum.HorizontalAlignment.Center)
	UIKit.Text(row, "Up", "👍", 34, Color.Snow, UDim2.fromOffset(40, 44), { Order = 1 })
	local bar = UIKit.Frame(row, "Bar", UDim2.fromOffset(60, 7), Color.Snow)
	bar.LayoutOrder = 2
	bar.BackgroundTransparency = 0.55
	UIKit.Corner(bar)
	local filled = UIKit.Frame(bar, "Fill", UDim2.fromScale(0.85, 1), Color.Snow)
	UIKit.Corner(filled)
	UIKit.Text(row, "Down", "👎", 34, Color.Snow, UDim2.fromOffset(40, 44), { Order = 3 }).TextTransparency = 0.5
	pointer(well, UDim2.new(0.5, -100, 0.5, 0))
end

-- The game page's Favorite button: the star over its word; the pointer at it.
local function favoritePicture(well: Frame)
	local button = UIKit.Frame(well, "Button", UDim2.fromOffset(90, 58))
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	UIKit.List(button, false, 0, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.TintedIcon(button, "Star", "Star", 42, Color.Snow).LayoutOrder = 1
	UIKit.Text(button, "Word", "Favorite", 16, Color.Snow, UDim2.fromOffset(90, 18), {
		Font = Theme.Font.TextHeavy,
		Order = 2,
	})
	pointer(well, UDim2.new(0.5, -66, 0.5, 0))
end

function Gift.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Gift", "Day", "Free Gift!", nil, false, nil, {
		Accent = ACCENT,
		Badge = Theme.Icons.MenuGift,
		Size = "Medium",
	})
	-- The gift is about what it gives, not the balance: no cash chip in this header.
	local cash = window:FindFirstChild("CashChip", true)
	if cash and cash:IsA("GuiObject") then
		cash.Visible = false
	end
	local page = window:FindFirstChild("Pages") :: Frame
	local layout = UIKit.List(page, false, 10, Enum.HorizontalAlignment.Center)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local top = UIKit.Frame(page, "Top", UDim2.new(1, 0, 0, TOP_HEIGHT))
	top.LayoutOrder = 1
	UIKit.List(top, true, 12)
	local stage = UIKit.Stage(top, "Stage", UDim2.fromOffset(150, TOP_HEIGHT), 100)
	stage.LayoutOrder = 1
	Style.PaintStage(stage, nil, ACCENT)
	local picture = stage:FindFirstChild("Picture") :: ImageLabel
	picture.Image = Theme.Icons.MenuGift
	picture.Position = UDim2.fromScale(0.5, 0.5)
	local rewards = UIKit.Frame(top, "Rewards", UDim2.new(1, -162, 1, 0))
	rewards.LayoutOrder = 2
	UIKit.Grow(rewards)
	UIKit.List(rewards, false, 2, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Center
	reward(rewards, "ClimbLine", Theme.Icons.HudShoe, "ClimbLabel", Color.Gold300, 1)
	reward(rewards, "CoinLine", Theme.Icons.HudCash, "CoinLabel", Color.Lime, 2)

	local steps = UIKit.Frame(page, "Steps", UDim2.new(1, 0, 0, STEP_HEIGHT))
	steps.LayoutOrder = 2
	UIKit.List(steps, true, 12)
	likePicture(step(steps, "LikeStep", "1. Like the game!", 1))
	favoritePicture(step(steps, "FavoriteStep", "2. Favorite the game!", 2))

	local claim = UIKit.Button(page, "ClaimButton", "Buy", 260, Theme.ButtonHeight.Hero, "Claim!")
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
	local player = Players.LocalPlayer
	local climbLabel = window:FindFirstChild("ClimbLabel", true) :: TextLabel
	local coinLabel = window:FindFirstChild("CoinLabel", true) :: TextLabel
	local claimButton = window:FindFirstChild("ClaimButton", true) :: TextButton
	local favoriteStep = window:FindFirstChild("FavoriteStep", true) :: Frame
	local favoriteDone = favoriteStep:FindFirstChild("Done", true) :: ImageLabel
	local busy = false
	local favorited = false

	local function refresh()
		local data = stateController:Get()
		climbLabel.Text = `+{Format.Short(data.GiftClimb or Economy.GiftClimb)} Climbing`
		coinLabel.Text = `+{Format.Short(data.GiftCoins or Economy.GiftCoins)} Coins`
		favoriteDone.Visible = favorited
		if data.FreeGift == true then
			Buttons.Set(claimButton, "Owned", "Claimed")
		else
			Buttons.Set(claimButton, "Buy", "Claim!")
		end
	end

	-- Roblox's favorite prompt for this game: true once the player says yes. An unpublished place (PlaceId 0, a Studio
	-- playtest) has nothing to favorite, so there it counts as done.
	local function favorite(): boolean
		if game.PlaceId == 0 then
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
		return answer == Enum.AvatarPromptResult.Success
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
			`+{Format.Short(climb or 0)} Climbing  +{Format.Short(coins or 0)} Coins`
		)
	end

	trove:Connect(claimButton.Activated, claim)
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

	-- Once a session: AutoOpenSeconds after it could first be claimed, as soon as the player is off the mountain, not
	-- carrying a lamb, and no other menu is open.
	task.spawn(function()
		local readySince: number? = nil
		while gui.Parent do
			local data = stateController:Get()
			if data.FreeGift ~= false or (data.Tutorial or 0) < 1 then
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
				if calm and os.clock() - since >= GameConfig.Gift.AutoOpenSeconds then
					context.Open("Gift")
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
