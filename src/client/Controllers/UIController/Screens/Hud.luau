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
local GuidePath = require(script.Parent.Parent.GuidePath)
local Motion = require(script.Parent.Parent.Motion)
local Scale = require(script.Parent.Parent.Scale)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The HUD in Shear a Sheep's Ranch Studs look: coins (with the flock's income) and Climbing at the top right, the menu
-- pictures down the left (shown after the first delivery), notices, the friend boost's tile under them (tap to invite),
-- the chase banner, and the onboarding's trail of chevrons on the ground. No hints in words and no card for the lamb
-- being carried: players work the rest out (the user, 2026-10-06).
local Hud = {}

local PICTURE_SIZE = 66
local TILES_BOTTOM = 70 -- the menu pictures stop this far above the bottom, clear of a phone's thumbstick
local MIDDLE_HALF_WIDTH = 160 -- half the widest notice, in points: what must clear the menu pictures
-- Pixels Roblox's player list (the leaderstats: Income, Climbing) takes at the top right, with a margin. It opens there
-- by default over the counters on a computer or a tablet; on a phone (a touch screen whose short side is under
-- SMALL_TOUCH pixels) it starts closed.
local PLAYER_LIST_WIDTH = 330
local SMALL_TOUCH = 500
local Color = Theme.Color

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

	gui.Parent = playerGui
	return gui
end

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
	local tiles = root:FindFirstChild("Tiles") :: Frame
	local storeButton = root:FindFirstChild("StoreButton") :: TextButton
	local banner = root:FindFirstChild("Banner") :: TextLabel
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController

	-- Notices and the chase banner stand in the middle of the screen, or, where the menu pictures wrap into a wide block
	-- (a phone held sideways), in the middle of the room right of them, so nothing covers a picture.
	local below = 60
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
		local middle = width / 2
		if left > middle - MIDDLE_HALF_WIDTH then
			middle = (left + width) / 2
		end
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

	-- One of the player's own plot pieces (the pen, the walker's entry), and the ground under its middle.
	local function plotPiece(name: string): BasePart?
		local index = player:GetAttribute("Plot")
		local plots = workspace:FindFirstChild("Plots")
		local plot = if plots and type(index) == "number" then plots:FindFirstChild(`Plot{index}`) else nil
		local found = plot and plot:FindFirstChild(name, true)
		return if found and found:IsA("BasePart") then found else nil
	end
	local function floorUnder(piece: BasePart?): Vector3?
		return if piece then piece.Position - Vector3.yAxis * piece.Size.Y / 2 else nil
	end
	-- The front of the first god's meadow, mid-lane: the place the first trail leads to, not a lamb (the user,
	-- 2026-10-06). The tutorial lamb waits just short of it; the meadow's wild lambs are past it.
	local firstTier = Olympus.Tiers[1]
	local meadowX = firstTier.XStart + (firstTier.XEnd - firstTier.XStart) * Olympus.PastureFrom
	local meadow = Vector3.new(meadowX, Mountain.RampY(meadowX), Olympus.LaneMiddleZ)

	-- Where the trail leads, only until the first lamb is home and the stair walker tried once (the user, 2026-10-06:
	-- simple, no hand-holding): from the pen to the first meadow; with the lamb, from the mountain's foot into the pen
	-- (none on the slope, where the slide takes the player down; the Put down prompt takes over in the pen); then out to
	-- the stair walker.
	local function goal(): Vector3?
		local data = stateController:Get()
		local stage = data.Tutorial
		if data.Sheep == nil or type(stage) ~= "number" or stage >= 2 then
			return nil
		end
		local character = player.Character
		local here = character and character:GetPivot().Position
		if not here then
			return nil
		end
		local carrying = player:GetAttribute("Carrying") == true
		if stage == 0 and not carrying then
			-- In the meadow or past it, the lambs are in view: the trail would only point back.
			return if here.X < meadowX - 4 then meadow else nil
		end
		if stage == 0 then
			local pen = plotPiece("Pen")
			if not pen or Mountain.IsOnRamp(here) or PenArea.Contains(pen, here, 0) then
				return nil
			end
			return floorUnder(pen)
		end
		return if carrying then nil else floorUnder(plotPiece("Zone"))
	end

	local current: Vector3? = nil
	local function refreshGoal()
		current = goal()
		-- The STORE button on the right edge sits where an open menu's tabs (the store's own) stand.
		storeButton.Visible = tiles.Visible and not context.Controllers.UIController:IsModalOpen()
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

	trove:Add(stateController.Changed:Connect(function()
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

	-- The chase banner (its sounds and red screen are ChaseController's).
	local bannerToken = 0
	trove:Add(Remotes.Chase:Connect(function(god: string?)
		bannerToken += 1
		if god then
			banner.Text = `{god} wants their sheep back!`
			banner.Visible = true
			Motion.NoticeIn(banner, banner.Position)
			local token = bannerToken
			task.delay(GameConfig.Ui.BannerSeconds, function()
				if bannerToken == token then
					banner.Visible = false
				end
			end)
		else
			banner.Visible = false
		end
	end))
	trove:Add(Remotes.Notify:Connect(function(message: string, kind: string, cue: string?)
		context.Notify(message, kind, cue)
	end))

	-- The trail, laid each frame from where the player stands; a menu covers the world, so it waits behind one.
	local path = GuidePath.new(workspace, function(): Model?
		return player.Character
	end)
	trove:Add(function()
		path:Destroy()
	end)
	trove:Connect(RunService.PreRender, function()
		local covered = not gui.Enabled or context.Controllers.UIController:IsModalOpen()
		local target = if covered then nil else current
		local character = player.Character
		path:Show(if target and character then character:GetPivot().Position else nil, target)
	end)

	-- Where the trail leads changes with where the player is (on the slope, home), so it's checked a few times a second.
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
