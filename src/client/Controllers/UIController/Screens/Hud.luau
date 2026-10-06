--!strict

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local PenArea = require(ReplicatedStorage.Utils.PenArea)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Motion = require(script.Parent.Parent.Motion)
local Scale = require(script.Parent.Parent.Scale)
local SheepIcon = require(script.Parent.Parent.SheepIcon)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The HUD in Shear a Sheep's Ranch Studs look: coins (with the flock's income) and Climbing at the top right, a hint
-- under the top bar only when one is needed (with a guide arrow for the first lamb and the first training), the menu
-- pictures down the left (shown after the first delivery), notices, the friend boost's tile under them (tap to invite),
-- the chase banner, the card of the lamb being carried (with Return), and the stair walker's meter while training.
local Hud = {}

local PICTURE_SIZE = 66
local TILES_BOTTOM = 70 -- the menu pictures stop this far above the bottom, clear of a phone's thumbstick
local WORK_HINT_SECONDS = 12 -- "Put your sheep to work" shows this long after room opens up in the pen
local CRAWL_SHARE = 0.5 -- climbing slower than this share of normal speed: "Train to climb"
local MIDDLE_HALF_WIDTH = 160 -- half the widest hint or notice, in points: what must clear the menu pictures
-- Pixels Roblox's player list (the leaderstats: Income, Climbing) takes at the top right, with a margin. It opens there
-- by default over the counters on a computer or a tablet; on a phone (a touch screen whose short side is under
-- SMALL_TOUCH pixels) it starts closed.
local PLAYER_LIST_WIDTH = 330
local SMALL_TOUCH = 500
local Color = Theme.Color
local TextSize = Theme.TextSize

local function pill(
	parent: Instance,
	name: string,
	icon: string,
	labelName: string,
	color: Color3,
	order: number
): Frame
	local holder = UIKit.Frame(parent, name, UDim2.fromOffset(0, 44))
	holder.LayoutOrder = order
	holder.AutomaticSize = Enum.AutomaticSize.X
	UIKit.Padding(holder, 50, 2, 0, 0)
	local punch = Instance.new("UIScale")
	punch.Name = "Punch"
	punch.Parent = holder
	local picture = UIKit.Icon(holder, "Icon", icon, 52)
	picture.AnchorPoint = Vector2.new(0, 0.5)
	picture.Position = UDim2.new(0, -56, 0.5, -2)
	local column = UIKit.Frame(holder, "Column", UDim2.fromOffset(0, 44))
	column.AutomaticSize = Enum.AutomaticSize.X
	UIKit.List(column, false, -6)
	local label = UIKit.Text(column, labelName, "...", 32, color, UDim2.fromOffset(0, 34), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		AlignX = Enum.TextXAlignment.Left,
		Order = 1,
	})
	local stroke = label:FindFirstChild("TextStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Thickness = 3.5
	end
	UIKit.Text(column, "RateLabel", "", 16, Color.Snow, UDim2.fromOffset(0, 16), {
		Font = Theme.Font.TextHeavy,
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		AlignX = Enum.TextXAlignment.Left,
		Order = 2,
	})
	return holder
end

function Hud.Build(playerGui: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	local root = UIKit.Root(gui)

	local topBar = UIKit.Frame(root, "TopBar", UDim2.new(1, 0, 0, 50))
	topBar.ZIndex = 2
	local right = UIKit.Frame(topBar, "Right", UDim2.fromOffset(0, 50))
	right.AnchorPoint = Vector2.new(1, 0.5)
	right.Position = UDim2.new(1, -10, 0.5, 0)
	right.AutomaticSize = Enum.AutomaticSize.X
	UIKit.List(right, true, 24)
	pill(right, "ClimbPill", Theme.Icons.HudShoe, "ClimbLabel", Color.Gold300, 1)
	pill(right, "CoinPill", Theme.Icons.HudCash, "CoinLabel", Color.Lime, 2)

	local notice = UIKit.Notice(root, "NoticeLabel")
	notice.AnchorPoint = Vector2.new(0.5, 0)
	notice.Position = UDim2.new(0.5, 0, 0, 120)

	-- The hint (Shear a Sheep's guide line): one short line, only while something needs doing.
	local objective = UIKit.Frame(root, "Objective", UDim2.fromOffset(0, 0))
	objective.AnchorPoint = Vector2.new(0.5, 0)
	objective.Position = UDim2.new(0.5, 0, 0, 60)
	objective.AutomaticSize = Enum.AutomaticSize.XY
	objective.Visible = false
	UIKit.List(objective, false, 2, Enum.HorizontalAlignment.Center)
	local size = TextSize.Title + 4
	UIKit.Text(objective, "TitleLabel", "", size, Color.Snow, UDim2.fromOffset(0, size + 6), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})

	-- The menu pictures down the left edge, as far as the bottom margin: on a short screen (a phone held sideways) the
	-- rest wrap into a second column beside the first.
	local tiles = UIKit.Frame(root, "Tiles", UDim2.new(0, PICTURE_SIZE + 12, 1, -(70 + TILES_BOTTOM)))
	tiles.Position = UDim2.fromOffset(8, 70)
	local tilesList = UIKit.List(tiles, false, 12, Enum.HorizontalAlignment.Left)
	tilesList.Wraps = true
	UIKit.Padding(tiles, (PICTURE_SIZE + 12 - math.max(PICTURE_SIZE, Theme.MinTouch)) / 2, 0, 0, 0)
	-- A red "!" on a button's corner: something waiting there.
	-- A red badge on a picture's corner: "!" unless `text` says otherwise (the Sheepdex's count of rewards waiting).
	local function alertOn(button: TextButton, text: string?): TextLabel
		local alert = UIKit.Text(button, "Alert", text or "!", 20, Color.Snow, UDim2.fromOffset(26, 26), {
			Stroke = Color.Line,
		})
		alert.BackgroundTransparency = 0
		alert.BackgroundColor3 = Color.Red500
		alert.AnchorPoint = Vector2.new(0.5, 0.5)
		alert.Position = UDim2.new(1, -8, 0, 6)
		alert.ZIndex = 5
		UIKit.Corner(alert)
		local ring = Instance.new("UIStroke")
		ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ring.Color = Color.Line
		ring.Thickness = Theme.Line.Normal
		ring.Parent = alert
		return alert
	end
	-- The rewards at the top: the free gift until it's claimed, then the daily gifts' golden calendar.
	local gift = UIKit.PictureButton(tiles, "GiftButton", Theme.Icons.MenuGift, PICTURE_SIZE, "GIFT")
	gift.LayoutOrder = 0
	alertOn(gift)
	local daily = UIKit.PictureButton(tiles, "DailyButton", Theme.Icons.HudDaily, PICTURE_SIZE, "DAILY")
	daily.LayoutOrder = 1
	alertOn(daily)
	local flock = UIKit.PictureButton(tiles, "FlockButton", Theme.Icons.Wool, PICTURE_SIZE, "FLOCK")
	flock.LayoutOrder = 2
	local shop = UIKit.PictureButton(tiles, "ShopButton", Theme.Icons.MenuStore, PICTURE_SIZE, "SHOP")
	shop.LayoutOrder = 3
	local dex = UIKit.PictureButton(tiles, "SheepdexButton", Theme.Icons.MenuSheepdex, PICTURE_SIZE, "SHEEPDEX")
	dex.LayoutOrder = 4
	alertOn(dex, "").Visible = false
	local friends = UIKit.PictureButton(tiles, "FriendButton", Theme.Icons.HudInvite, PICTURE_SIZE, "INVITE")
	friends.LayoutOrder = 5
	-- The Robux store on the right edge, where the left column has no room left (as the reference game's store buttons).
	local storeButton = UIKit.PictureButton(root, "StoreButton", Theme.Icons.HudRobux, PICTURE_SIZE, "STORE")
	storeButton.AnchorPoint = Vector2.new(1, 0.5)
	storeButton.Position = UDim2.new(1, -8, 0.5, 0)

	local banner = UIKit.Banner(root, "Banner")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 150)
	banner.ZIndex = 5

	local arrow = UIKit.Arrow(root, "GuideArrow", "Guide")
	arrow.ZIndex = 4

	-- The lamb being carried, at the bottom: its token, name and burden, and Return.
	local carry = UIKit.Frame(root, "CarryCard", UDim2.fromOffset(0, 64), Theme.Fleece.Tile.Base)
	carry.AnchorPoint = Vector2.new(0.5, 1)
	carry.Position = UDim2.new(0.5, 0, 1, -18)
	carry.AutomaticSize = Enum.AutomaticSize.X
	carry.Visible = false
	UIKit.Corner(carry, Theme.Fleece.CardRadius)
	UIKit.Surface(carry, Color.Line, 4, Color.Line, Theme.Line.Normal)
	UIKit.Padding(carry, 8, 10, 0, 0)
	local carryList = UIKit.List(carry, true, 10)
	carryList.VerticalAlignment = Enum.VerticalAlignment.Center
	UIKit.Token(carry, 52, "Token").LayoutOrder = 1
	local words = UIKit.Frame(carry, "Words", UDim2.fromOffset(0, 52))
	words.LayoutOrder = 2
	words.AutomaticSize = Enum.AutomaticSize.X
	UIKit.List(words, false, 0)
	UIKit.Text(words, "NameLabel", "", 22, Color.Snow, UDim2.fromOffset(0, 28), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		AlignX = Enum.TextXAlignment.Left,
		Order = 1,
	})
	local giveUp = UIKit.Button(carry, "ReturnButton", "Soft", 110, Theme.ButtonHeight.Standard, "Return")
	giveUp.LayoutOrder = 3

	-- The stair walker's meter, while training: a bar to the next god's sign (the rate is on the Climbing counter).
	local meter = UIKit.Frame(root, "TrainMeter", UDim2.fromOffset(300, 0))
	meter.AnchorPoint = Vector2.new(0.5, 1)
	meter.Position = UDim2.new(0.5, 0, 1, -24)
	meter.AutomaticSize = Enum.AutomaticSize.Y
	meter.Visible = false
	UIKit.List(meter, false, 4, Enum.HorizontalAlignment.Center)
	UIKit.Bar(meter, "Bar", UDim2.fromOffset(260, 12)).LayoutOrder = 2
	UIKit.Text(meter, "GoalLabel", "", 16, Color.Snow, UDim2.fromOffset(0, 20), {
		Font = Theme.Font.TextHeavy,
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 3,
	})

	gui.Parent = playerGui
	return gui
end

type Goal = { Title: string?, Target: Vector3? }

function Hud.new(context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()
	local player = Players.LocalPlayer
	local root = gui:FindFirstChild("Root") :: Frame
	local topBar = root:FindFirstChild("TopBar") :: Frame
	local coinLabel = root:FindFirstChild("CoinLabel", true) :: TextLabel
	local coinPill = root:FindFirstChild("CoinPill", true) :: Frame
	local incomeLabel = coinPill:FindFirstChild("RateLabel", true) :: TextLabel
	local climbLabel = root:FindFirstChild("ClimbLabel", true) :: TextLabel
	local climbPill = root:FindFirstChild("ClimbPill", true) :: Frame
	local trainLabel = climbPill:FindFirstChild("RateLabel", true) :: TextLabel
	local noticeLabel = root:FindFirstChild("NoticeLabel") :: TextLabel
	local objective = root:FindFirstChild("Objective") :: Frame
	local objectiveTitle = objective:FindFirstChild("TitleLabel") :: TextLabel
	local tiles = root:FindFirstChild("Tiles") :: Frame
	local storeButton = root:FindFirstChild("StoreButton") :: TextButton
	local banner = root:FindFirstChild("Banner") :: TextLabel
	local arrow = root:FindFirstChild("GuideArrow") :: Frame
	local arrowLabel = arrow:FindFirstChild("Label") :: TextLabel
	local pointer = arrow:FindFirstChild("Pointer", true) :: GuiObject
	local carryCard = root:FindFirstChild("CarryCard") :: Frame
	local carryToken = carryCard:FindFirstChild("Token") :: Frame
	local carryName = carryCard:FindFirstChild("NameLabel", true) :: TextLabel
	local returnButton = carryCard:FindFirstChild("ReturnButton") :: TextButton
	local meter = root:FindFirstChild("TrainMeter") :: Frame
	local meterBar = meter:FindFirstChild("Bar") :: Frame
	local goalLabel = meter:FindFirstChild("GoalLabel") :: TextLabel
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController

	-- The hint, notices and chase banner stand in the middle of the screen, or, where the menu pictures wrap into a wide
	-- block (a phone held sideways), in the middle of the room right of them, so nothing covers a picture.
	local below = 60
	local tilesRight = 0 -- points from the left: where the menu pictures end
	local noticeHome = noticeLabel.Position -- where a notice rests, from placeMiddle
	local function placeMiddle()
		local scale = Scale.Of(root)
		local width = root.AbsoluteSize.X / scale
		local left = 0
		if tiles.Visible then
			for _, child in tiles:GetChildren() do
				if child:IsA("GuiObject") and child.Visible then
					local right = child.AbsolutePosition.X + child.AbsoluteSize.X - root.AbsolutePosition.X
					left = math.max(left, right / scale)
				end
			end
		end
		tilesRight = left
		local middle = width / 2
		if left > middle - MIDDLE_HALF_WIDTH then
			middle = (left + width) / 2
		end
		objective.Position = UDim2.new(0, middle, 0, below)
		noticeHome = UDim2.new(0, middle, 0, below + 64)
		if not noticeLabel.Visible then
			noticeLabel.Position = noticeHome
		end
		banner.Position = UDim2.new(0, middle, 0, below + 110)
	end
	-- On a computer or a tablet the counters stand left of Roblox's player list, which opens by default over the top
	-- right there.
	local counters = topBar:FindFirstChild("Right") :: Frame
	local function clearPlayerList()
		local camera = workspace.CurrentCamera
		local short = if camera then math.min(camera.ViewportSize.X, camera.ViewportSize.Y) else 0
		local phone = UserInputService.TouchEnabled and short < SMALL_TOUCH
		local opensListed = not phone and not GuiService:IsTenFootInterface()
		local listed = opensListed and StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
		local shift = if listed then PLAYER_LIST_WIDTH / Scale.Of(root) else 0
		counters.Position = UDim2.new(1, -10 - shift, 0.5, 0)
	end
	Scale.TopBar(gui, root, topBar, trove, function(top: number)
		clearPlayerList()
		below = top
		tiles.Position = UDim2.fromOffset(8, below + 8)
		tiles.Size = UDim2.new(0, PICTURE_SIZE + 12, 1, -(below + 8 + TILES_BOTTOM))
		placeMiddle()
	end)
	trove:Connect(tiles:GetPropertyChangedSignal("Visible"), placeMiddle)
	local wrapping = tiles:FindFirstChildOfClass("UIListLayout")
	if wrapping then
		-- After the pictures wrap again (a resized window, the gift's picture gone), not before.
		trove:Connect(wrapping:GetPropertyChangedSignal("AbsoluteContentSize"), placeMiddle)
	end

	-- Notices: one at a time, the rest queued (Shear a Sheep's HUD notices). A notice's sound plays when its words show.
	local noticeRest = noticeHome
	local queue: { { Text: string, Kind: string, Cue: string? } } = {}
	local showing = false
	noticeLabel.Visible = false
	local function showNext()
		local nextNotice = table.remove(queue, 1)
		if not nextNotice then
			showing = false
			return
		end
		showing = true
		noticeLabel.Text = nextNotice.Text
		if nextNotice.Cue then
			sound:Play(nextNotice.Cue)
		end
		local kind: Style.NoticeKind = Style.NoticeKindOf(nextNotice.Kind)
		Style.PaintNotice(noticeLabel, kind)
		noticeRest = noticeHome
		Motion.NoticeIn(noticeLabel, noticeRest)
		if Style.IsProblem(kind) then
			task.delay(Theme.Motion.NoticeIn.Time, function()
				Motion.Shake(noticeLabel)
			end)
		end
		task.delay(GameConfig.Ui.NoticeSeconds, function()
			if #queue > 0 then
				showNext()
				return
			end
			Motion.NoticeOut(noticeLabel, noticeRest, function()
				noticeLabel.Visible = false
				showNext()
			end)
		end)
	end
	local function notice(text: string, kind: string, cue: string?)
		table.insert(queue, { Text = text, Kind = kind, Cue = cue })
		while #queue > GameConfig.Ui.NoticeQueue do
			table.remove(queue, 1)
		end
		if not showing then
			showNext()
		end
	end

	-- Coins, income and Climbing.
	local shownCoins = -1
	local function refreshCoins()
		local coins = player:GetAttribute("Coins")
		if type(coins) ~= "number" then
			return
		end
		local whole = math.floor(coins)
		if whole ~= shownCoins then
			if whole > shownCoins and shownCoins > 0 then
				Motion.Count(coinLabel, shownCoins, whole, Format.Short)
			else
				Motion.Set(coinLabel, Format.Short(whole))
			end
			shownCoins = whole
		end
		local income = player:GetAttribute("Income")
		local friends = player:GetAttribute("Friends")
		local boost = Economy.FriendBoost(if type(friends) == "number" then friends else 0)
		incomeLabel.Text = if type(income) == "number" and income > 0 then `+{Format.Rate(income * boost)}/s` else ""
	end
	local function refreshClimb()
		local climb = player:GetAttribute("ClimbPower")
		climbLabel.Text = if type(climb) == "number" then Format.Short(climb) else "..."
		local data = stateController:Get()
		local training = player:GetAttribute("Training") == true
		if training and data.WalkerLevel then
			local rate = Economy.TrainingRate(data.WalkerLevel, data.Trail)
			trainLabel.Text = `+{Format.Rate(rate)}/s`
			trainLabel.TextColor3 = Color.Lime
		else
			trainLabel.Text = "CLIMBING"
			trainLabel.TextColor3 = Color.Snow
		end
	end
	for _, name in { "Coins", "Income", "Friends" } do
		trove:Connect(player:GetAttributeChangedSignal(name), refreshCoins)
	end
	for _, name in { "ClimbPower", "Training" } do
		trove:Connect(player:GetAttributeChangedSignal(name), refreshClimb)
	end
	refreshCoins()
	refreshClimb()

	-- Where the guide arrow points: the player's own pad, walker, or a pasture.
	local function plotPiece(name: string): BasePart?
		local index = player:GetAttribute("Plot")
		local plots = workspace:FindFirstChild("Plots")
		local plot = if plots and type(index) == "number" then plots:FindFirstChild(`Plot{index}`) else nil
		local found = plot and plot:FindFirstChild(name, true)
		return if found and found:IsA("BasePart") then found else nil
	end
	local function tutorialLamb(): Vector3?
		local wild = workspace:FindFirstChild("WildSheep")
		if not wild then
			return nil
		end
		for _, model in wild:GetChildren() do
			local prompt = model:FindFirstChild("StealPrompt", true)
			if prompt and prompt:GetAttribute("OwnerId") == player.UserId and model:IsA("Model") then
				return model:GetPivot().Position
			end
		end
		return nil
	end
	local function pasture(tier: number): Vector3
		local spots = Mountain.PastureSpots(tier)
		local spot = spots[1]
		return Vector3.new(spot.X, Mountain.RampY(spot.X) + 3, Olympus.LaneMiddleZ)
	end

	-- "Put your sheep to work" waits for room to open up in the pen (more pen space, sheep merged away) while sheep are
	-- stored, not for a sheep the player stored on purpose.
	local workUntil = 0
	local lastFree, lastStored = -1, -1
	local function watchPen(data: { [string]: any })
		local stored, equipped = 0, 0
		for _, sheep in data.Sheep do
			if sheep.Slot > 0 then
				equipped += 1
			elseif not sheep.AtShrine then
				stored += 1
			end
		end
		local free = math.max(0, (data.PenSlots or 0) - equipped)
		if lastFree >= 0 and free > lastFree and stored > 0 and stored <= lastStored then
			workUntil = os.clock() + WORK_HINT_SECONDS
		end
		if free == 0 or stored == 0 then
			workUntil = 0
		end
		lastFree, lastStored = free, stored
	end

	-- Slowed to a crawl on a slope above the player's Climbing.
	local function crawling(here: Vector3): boolean
		local climb = player:GetAttribute("ClimbPower")
		local power = if type(climb) == "number" then climb else 0
		return Mountain.IsOnRamp(here)
			and Mountain.TierAt(here.X) >= 2
			and Mountain.SpeedAt(here.X, power, 1) < GameConfig.Movement.WalkSpeed * CRAWL_SHARE
	end

	-- The hint, only when one is needed: the first lamb (where it is, then home with it; the Put down prompt takes over
	-- in the pen), the stair walker after it, the pen when room opens up, and a slope that's too steep.
	local function goal(): Goal?
		local data = stateController:Get()
		if data.Sheep == nil then
			return nil
		end
		local character = player.Character
		local here = character and character:GetPivot().Position
		local carrying = player:GetAttribute("Carrying") == true
		if data.Tutorial == 0 then
			if not carrying then
				return { Title = `Steal {Olympus.Tiers[1].God}'s lamb`, Target = tutorialLamb() or pasture(1) }
			end
			local pen = plotPiece("Pen")
			if not pen or (here and PenArea.Contains(pen, here, 0)) then
				return nil
			end
			return {
				Title = if here and Mountain.IsOnRamp(here) then "Slide home!" else nil,
				Target = pen.Position,
			}
		end
		if carrying then
			return nil
		end
		if data.Tutorial == 1 then
			local walker = plotPiece("Zone")
			return { Title = "Train on your Stair Walker", Target = if walker then walker.Position else nil }
		end
		if os.clock() < workUntil then
			return { Title = "Put your sheep to work" }
		end
		if here and player:GetAttribute("Training") ~= true and crawling(here) then
			return { Title = "Train to climb" }
		end
		return nil
	end

	local current: Goal? = nil
	local function refreshGoal()
		current = goal()
		local title = current and current.Title
		local modal = context.Controllers.UIController:IsModalOpen()
		objective.Visible = title ~= nil and not modal
		-- The STORE button on the right edge sits where an open menu's tabs (the store's own) stand.
		storeButton.Visible = tiles.Visible and not modal
		objectiveTitle.Text = title or ""
		Motion.SetGlow(Motion.FindGlow(tiles:FindFirstChild("FlockButton") :: GuiObject), os.clock() < workUntil)
	end

	-- Menu pictures: hidden until the first delivery, like Shear a Sheep's onboarding. The gift's glows until claimed.
	local giftButton = tiles:FindFirstChild("GiftButton") :: TextButton
	local dexAlert = (tiles:FindFirstChild("SheepdexButton") :: TextButton):FindFirstChild("Alert") :: TextLabel
	local dailyButton = tiles:FindFirstChild("DailyButton") :: TextButton
	local dailyAlert = dailyButton:FindFirstChild("Alert") :: GuiObject
	local dailyLabel = dailyButton:FindFirstChild("NameLabel") :: TextLabel
	-- DAILY glows with its "!" while a gift waits; once claimed its name is the countdown to the next.
	local function refreshDaily()
		local daily = stateController:Get().Daily
		local readyAt = if type(daily) == "table" and type(daily.ReadyAt) == "number" then daily.ReadyAt else 0
		local left = math.max(0, math.ceil(readyAt - workspace:GetServerTimeNow()))
		dailyAlert.Visible = left <= 0
		dailyLabel.Text = if left <= 0
			then "DAILY"
			else string.format("%d:%02d:%02d", left // 3600, left % 3600 // 60, left % 60)
		Motion.SetGlow(Motion.FindGlow(dailyButton), left <= 0 and tiles.Visible)
	end
	local function refreshTiles()
		local data = stateController:Get()
		tiles.Visible = (data.Tutorial or 0) >= 1
		storeButton.Visible = tiles.Visible
		local unclaimed = data.FreeGift == false
		giftButton.Visible = unclaimed
		Motion.SetGlow(Motion.FindGlow(giftButton), unclaimed and tiles.Visible)
		-- Sheepdex rewards found but not claimed yet.
		local waiting = 0
		local found = if type(data.Dex) == "table" then data.Dex else {}
		local claimed = if type(data.DexClaimed) == "table" then data.DexClaimed else {}
		for family, isFound in found do
			if isFound == true and claimed[family] ~= true and Olympus.ByFamily[family] then
				waiting += 1
			end
		end
		dexAlert.Visible = waiting > 0
		dexAlert.Text = if waiting > 9 then "9+" else tostring(waiting)
		refreshDaily()
		task.defer(placeMiddle)
	end

	-- The carry card: a lamb, unnamed like every lamb, with its marks (WildService sets their colour and count).
	local function refreshCarry()
		local carrying = player:GetAttribute("Carrying") == true
		carryCard.Visible = carrying
		if not carrying then
			return
		end
		local color = player:GetAttribute("CarriedColor")
		local spots = player:GetAttribute("CarriedSpots")
		local look = if typeof(color) == "Color3" and type(spots) == "number"
			then { Color = color, Spots = spots, Horns = nil }
			else nil
		SheepIcon.PaintLamb(carryToken, look, 1)
		carryName.Text = "Lamb"
	end
	trove:Connect(returnButton.Activated, function()
		Remotes.ReturnSheep:Fire()
	end)
	for _, name in { "Carrying", "CarriedColor" } do
		trove:Connect(player:GetAttributeChangedSignal(name), refreshCarry)
	end
	refreshCarry()

	-- The training meter: from the god the player has reached to the next one's sign. Lamb weight stays hidden, so it
	-- names no sheep; past Zeus's sign there's no next god and the meter stays away.
	local function refreshMeter()
		local climb = player:GetAttribute("ClimbPower")
		local power = if type(climb) == "number" then climb else 0
		local reached = Economy.ClimbTier(power)
		local nextTier = Olympus.Tiers[reached + 1]
		meter.Visible = player:GetAttribute("Training") == true and nextTier ~= nil
		if not meter.Visible or not nextTier then
			return
		end
		local reach = Economy.Targets(reached)
		Style.SetBar(meterBar, math.clamp((power - reach) / math.max(nextTier.Reach - reach, 1), 0, 1))
		goalLabel.Text = `Next: {nextTier.God} at {Format.Short(nextTier.Reach)}`
	end
	trove:Connect(player:GetAttributeChangedSignal("Training"), refreshMeter)
	trove:Connect(player:GetAttributeChangedSignal("ClimbPower"), refreshMeter)

	trove:Add(stateController.Changed:Connect(function(data: { [string]: any })
		watchPen(data)
		refreshTiles()
		refreshGoal()
		refreshClimb()
	end))
	refreshTiles()

	trove:Connect(giftButton.Activated, function()
		context.Open("Gift")
	end)
	trove:Connect(dailyButton.Activated, function()
		context.Open("Daily")
	end)
	-- The countdown under DAILY, once a second.
	local sinceDaily = 0
	trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		sinceDaily += deltaTime
		if sinceDaily >= 1 then
			sinceDaily = 0
			refreshDaily()
		end
	end)
	trove:Connect((tiles:FindFirstChild("FlockButton") :: TextButton).Activated, function()
		context.Open("Flock")
	end)
	trove:Connect((tiles:FindFirstChild("ShopButton") :: TextButton).Activated, function()
		context.Open("Shop")
	end)
	trove:Connect(storeButton.Activated, function()
		context.Open("Store")
	end)
	trove:Connect((tiles:FindFirstChild("SheepdexButton") :: TextButton).Activated, function()
		context.Open("Sheepdex")
	end)

	-- The friend boost's tile: the boost while friends are here, the invite (and what a friend is worth) while none
	-- are. Either way a tap opens Roblox's invite.
	local friendButton = tiles:FindFirstChild("FriendButton") :: TextButton
	local friendIcon = friendButton:FindFirstChild("Icon", true) :: ImageLabel
	local friendLabel = friendButton:FindFirstChild("NameLabel") :: TextLabel
	local function refreshFriends()
		local friends = player:GetAttribute("Friends")
		local count = if type(friends) == "number" then friends else 0
		local percent = math.round((Economy.FriendBoost(count) - 1) * 100)
		friendIcon.Image = if count > 0 then Theme.Icons.HudFriend else Theme.Icons.HudInvite
		friendLabel.Text = if count > 0 then `+{percent}%` else "INVITE"
		friendLabel.TextColor3 = if count > 0 then Color.Lime else Color.Snow
	end
	trove:Connect(player:GetAttributeChangedSignal("Friends"), refreshFriends)
	refreshFriends()
	trove:Connect(friendButton.Activated, function()
		task.spawn(function()
			local ok, canInvite = pcall(function()
				return SocialService:CanSendGameInviteAsync(player)
			end)
			if not (ok and canInvite and pcall(SocialService.PromptGameInvite, SocialService, player)) then
				notice("Invites aren't available here", "Bad")
			end
		end)
	end)

	-- The chase banner and its music.
	local bannerToken = 0
	trove:Add(Remotes.Chase:Connect(function(god: string?)
		bannerToken += 1
		if god then
			banner.Text = `{god} wants their sheep back!`
			banner.Visible = true
			Motion.NoticeIn(banner, banner.Position)
			sound:SetDanger(true)
			sound:Play("WolfScare")
			local token = bannerToken
			task.delay(GameConfig.Ui.BannerSeconds, function()
				if bannerToken == token then
					banner.Visible = false
				end
			end)
		else
			banner.Visible = false
			sound:SetDanger(false)
		end
	end))
	trove:Add(Remotes.Notify:Connect(function(message: string, kind: string, cue: string?)
		context.Notify(message, kind, cue)
	end))

	-- The guide arrow: over its target when it's on screen, on the screen's edge pointing at it when it isn't.
	local SCREEN_MARGIN = 70
	local HINT_GAP = 8 -- points kept between the arrow and the hint
	-- Where the arrow (hanging from its point, in points) would cover the hint, it hangs just under the hint instead,
	-- pointing up: a lamb far up the mountain sits right behind the hint's words. True when it moved.
	local function underHint(x: number, y: number, scale: number): (number, boolean)
		if not objective.Visible then
			return y, false
		end
		local topLeft = (objective.AbsolutePosition - gui.AbsolutePosition) / scale
		local size = objective.AbsoluteSize / scale
		local box = arrow.AbsoluteSize / scale
		local acrossHint = x + box.X / 2 > topLeft.X - HINT_GAP and x - box.X / 2 < topLeft.X + size.X + HINT_GAP
		local downHint = y > topLeft.Y - HINT_GAP and y - box.Y < topLeft.Y + size.Y + HINT_GAP
		if acrossHint and downHint then
			return topLeft.Y + size.Y + HINT_GAP + box.Y, true
		end
		return y, false
	end
	trove:Connect(RunService.RenderStepped, function()
		local target = current and current.Target
		local camera = workspace.CurrentCamera
		if not target or not camera or context.Controllers.UIController:IsModalOpen() then
			arrow.Visible = false
			return
		end
		local character = player.Character
		local here = character and character:GetPivot().Position
		if here and (here - target).Magnitude < 14 then
			arrow.Visible = false
			return
		end
		arrow.Visible = true
		arrowLabel.Text = if here then `{math.floor((here - target).Magnitude)}m` else ""
		local scale = Scale.Of(root)
		local point, onScreen = camera:WorldToViewportPoint(target + Vector3.new(0, 6, 0))
		local viewport = camera.ViewportSize
		local inset = gui.AbsolutePosition
		if onScreen then
			local x = (point.X - inset.X) / scale
			local y, moved = underHint(x, (point.Y - inset.Y) / scale, scale)
			arrow.Position = UDim2.fromOffset(x, y)
			pointer.Rotation = if moved then 180 else 0
			return
		end
		-- Behind or off to the side: along the screen's edge, in the target's direction from the middle.
		local middle = viewport / 2
		local direction = Vector2.new(point.X, point.Y) - middle
		if point.Z < 0 then
			direction = -direction
		end
		if direction.Magnitude < 1 then
			direction = Vector2.new(0, 1)
		end
		local unit = direction.Unit
		local reach = math.min(
			(middle.X - SCREEN_MARGIN) / math.max(math.abs(unit.X), 1e-3),
			(middle.Y - SCREEN_MARGIN) / math.max(math.abs(unit.Y), 1e-3)
		)
		local at = middle + unit * reach
		-- Clear of the menu pictures, and on a touch screen of the thumbstick and jump button along the bottom; the
		-- pointer still turns to the target.
		local right = viewport.X - SCREEN_MARGIN
		local left = math.min(inset.X + (tilesRight + 40) * scale, right)
		local bottom = math.max(
			if UserInputService.TouchEnabled then viewport.Y * 0.6 else viewport.Y - SCREEN_MARGIN,
			SCREEN_MARGIN
		)
		at = Vector2.new(math.clamp(at.X, left, right), math.clamp(at.Y, SCREEN_MARGIN, bottom))
		local edgeX = (at.X - inset.X) / scale
		arrow.Position = UDim2.fromOffset(edgeX, (underHint(edgeX, (at.Y - inset.Y) / scale, scale)))
		pointer.Rotation = math.deg(math.atan2(unit.Y, unit.X)) - 90
	end)

	-- The objective changes with where the player is (sliding, home), so it's checked a few times a second.
	task.spawn(function()
		while gui.Parent do
			refreshGoal()
			task.wait(0.3)
		end
	end)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Clean()
			gui:Destroy()
		end,
		Notify = function(_self: Types.Screen, message: string, kind: string, cue: string?)
			notice(message, kind, cue)
		end,
	}
end

return Hud
