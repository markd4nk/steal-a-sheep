--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

-- The HUD in Shear a Sheep's Ranch Studs look: coins (with the flock's income) and Climbing at the top right, the
-- one-line objective under the top bar, the menu pictures down the left (shown after the first delivery), notices,
-- the chase banner, a guide arrow to the next thing to do, the card of the lamb being carried (with Return), and the
-- stair walker's meter while training.
local Hud = {}

local PICTURE_SIZE = 66
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

	-- The objective (Shear a Sheep's guide line): what to do, how, and a bar for a Climbing goal.
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
	UIKit.Text(objective, "SubLabel", "", TextSize.Label, Color.Snow, UDim2.fromOffset(0, TextSize.Label + 6), {
		Font = Theme.Font.TextHeavy,
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 2,
	})
	local bar = UIKit.Bar(objective, "Bar", UDim2.fromOffset(180, 10))
	bar.LayoutOrder = 3
	bar.Visible = false

	local tiles = UIKit.Frame(root, "Tiles", UDim2.fromOffset(PICTURE_SIZE + 12, 0))
	tiles.Position = UDim2.fromOffset(8, 70)
	tiles.AutomaticSize = Enum.AutomaticSize.Y
	UIKit.List(tiles, false, 12, Enum.HorizontalAlignment.Center)
	local flock = UIKit.PictureButton(tiles, "FlockButton", Theme.Icons.Wool, PICTURE_SIZE, "FLOCK")
	flock.LayoutOrder = 1
	local shop = UIKit.PictureButton(tiles, "ShopButton", Theme.Icons.MenuStore, PICTURE_SIZE, "SHOP")
	shop.LayoutOrder = 2
	local dex = UIKit.PictureButton(tiles, "SheepdexButton", Theme.Icons.MenuSheepdex, PICTURE_SIZE, "SHEEPDEX")
	dex.LayoutOrder = 3

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

	-- The stair walker's meter, while training.
	local meter = UIKit.Frame(root, "TrainMeter", UDim2.fromOffset(300, 0))
	meter.AnchorPoint = Vector2.new(0.5, 1)
	meter.Position = UDim2.new(0.5, 0, 1, -24)
	meter.AutomaticSize = Enum.AutomaticSize.Y
	meter.Visible = false
	UIKit.List(meter, false, 4, Enum.HorizontalAlignment.Center)
	UIKit.Text(meter, "GainLabel", "", 26, Color.Gold300, UDim2.fromOffset(0, 30), {
		Stroke = Color.Line,
		Auto = Enum.AutomaticSize.X,
		Order = 1,
	})
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

type Goal = { Title: string, Sub: string?, Progress: number?, Target: Vector3? }

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
	local objectiveSub = objective:FindFirstChild("SubLabel") :: TextLabel
	local objectiveBar = objective:FindFirstChild("Bar") :: Frame
	local tiles = root:FindFirstChild("Tiles") :: Frame
	local banner = root:FindFirstChild("Banner") :: TextLabel
	local arrow = root:FindFirstChild("GuideArrow") :: Frame
	local arrowLabel = arrow:FindFirstChild("Label") :: TextLabel
	local pointer = arrow:FindFirstChild("Pointer", true) :: GuiObject
	local carryCard = root:FindFirstChild("CarryCard") :: Frame
	local carryToken = carryCard:FindFirstChild("Token") :: Frame
	local carryName = carryCard:FindFirstChild("NameLabel", true) :: TextLabel
	local returnButton = carryCard:FindFirstChild("ReturnButton") :: TextButton
	local meter = root:FindFirstChild("TrainMeter") :: Frame
	local gainLabel = meter:FindFirstChild("GainLabel") :: TextLabel
	local meterBar = meter:FindFirstChild("Bar") :: Frame
	local goalLabel = meter:FindFirstChild("GoalLabel") :: TextLabel
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController

	Scale.TopBar(gui, root, topBar, trove, function(below: number)
		objective.Position = UDim2.new(0.5, 0, 0, below)
		noticeLabel.Position = UDim2.new(0.5, 0, 0, below + 64)
		banner.Position = UDim2.new(0.5, 0, 0, below + 110)
		tiles.Position = UDim2.fromOffset(8, below + 8)
	end)

	-- Notices: one at a time, the rest queued (Shear a Sheep's HUD notices).
	local noticeRest = noticeLabel.Position
	local queue: { { Text: string, Kind: string } } = {}
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
		local kind: Style.NoticeKind = Style.NoticeKindOf(nextNotice.Kind)
		Style.PaintNotice(noticeLabel, kind)
		noticeRest = noticeLabel.Position
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
	local function notice(text: string, kind: string)
		table.insert(queue, { Text = text, Kind = kind })
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
		incomeLabel.Text = if type(income) == "number" and income > 0 then `+{Format.Rate(income)}/s` else ""
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
	for _, name in { "Coins", "Income" } do
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

	local function goal(): Goal?
		local data = stateController:Get()
		if data.Sheep == nil then
			return nil
		end
		local climb = player:GetAttribute("ClimbPower")
		local power = if type(climb) == "number" then climb else 0
		if player:GetAttribute("Carrying") == true then
			local character = player.Character
			local here = character and character:GetPivot().Position
			local onRamp = here ~= nil and Mountain.IsOnRamp(here)
			local pen = plotPiece("Pen")
			if pen and here and PenArea.Contains(pen, here, 0) then
				local equipped = 0
				for _, sheep in data.Sheep do
					if sheep.Slot > 0 then
						equipped += 1
					end
				end
				return {
					Title = "Put it down where you like",
					Sub = if equipped >= (data.PenSlots or 0) then "Your pen is full: it'll be stored" else nil,
				}
			end
			return {
				Title = if onRamp then "Slide home!" else "Bring it into your pen",
				Sub = if onRamp then "Run downhill to slide" else nil,
				Target = if pen then pen.Position else nil,
			}
		end
		if data.Tutorial == 0 then
			return {
				Title = `Steal {Olympus.Tiers[1].God}'s lamb`,
				Sub = "Hold E next to it",
				Target = tutorialLamb() or pasture(1),
			}
		end
		if data.Tutorial == 1 then
			local walker = plotPiece("Zone")
			return {
				Title = "Train on your Stair Walker",
				Sub = "Climbing gets you up steeper slopes",
				Target = if walker then walker.Position else nil,
			}
		end
		local stored, equipped = 0, 0
		for _, sheep in data.Sheep do
			if sheep.Slot > 0 then
				equipped += 1
			else
				stored += 1
			end
		end
		if stored > 0 and equipped < data.PenSlots then
			return { Title = "Put your sheep to work", Sub = "Flock > Equip Best" }
		end
		local reached = Economy.ClimbTier(power)
		local readiness = Economy.Readiness(power, reached)
		local _, _, heavy = Economy.Targets(reached)
		local here = Olympus.Tiers[reached]
		local nextTier = Olympus.Tiers[reached + 1]
		if not nextTier then
			if readiness == "Light" then
				return {
					Title = `Train for heavier sheep: {Format.Short(power)}/{Format.Short(heavy)}`,
					Progress = power / heavy,
				}
			end
			return { Title = "Ready for the heaviest sheep", Sub = "Complete your Sheepdex" }
		end
		local delivered = (data.Deliveries[tostring(reached)] or 0) > 0
		if not delivered then
			return { Title = `Steal a lamb from {here.God}`, Target = pasture(reached) }
		end
		-- ClimbTier is the highest tier whose Reach the player has, so the next one's is always still ahead.
		return {
			Title = `Train to climb: {Format.Short(power)}/{Format.Short(nextTier.Reach)}`,
			Sub = if readiness == "Light" and power < heavy
				then `Next: {nextTier.God}'s {nextTier.Area}`
				else `Ready for heavier sheep from {here.God}`,
			Progress = power / nextTier.Reach,
		}
	end

	local current: Goal? = nil
	local function refreshGoal()
		current = goal()
		objective.Visible = current ~= nil and not context.Controllers.UIController:IsModalOpen()
		if current then
			objectiveTitle.Text = current.Title
			objectiveSub.Text = current.Sub or ""
			objectiveSub.Visible = current.Sub ~= nil
			objectiveBar.Visible = current.Progress ~= nil
			if current.Progress then
				Style.SetBar(objectiveBar, math.clamp(current.Progress, 0, 1))
			end
		end
	end

	-- Menu pictures: hidden until the first delivery, like Shear a Sheep's onboarding.
	local function refreshTiles()
		local data = stateController:Get()
		tiles.Visible = (data.Tutorial or 0) >= 1
	end

	-- The carry card.
	local function refreshCarry()
		local carrying = player:GetAttribute("Carrying") == true
		carryCard.Visible = carrying
		if not carrying then
			return
		end
		local family = player:GetAttribute("CarriedFamily")
		local tier = player:GetAttribute("CarryTier")
		if type(family) == "string" and type(tier) == "number" then
			SheepIcon.Paint(carryToken, family, 1)
			carryName.Text = string.gsub(Olympus.Tiers[tier].FamilyName, "Sheep$", "Lamb")
		end
	end
	trove:Connect(returnButton.Activated, function()
		Remotes.ReturnSheep:Fire()
	end)
	for _, name in { "Carrying", "CarriedFamily" } do
		trove:Connect(player:GetAttributeChangedSignal(name), refreshCarry)
	end
	refreshCarry()

	-- The training meter.
	local function refreshMeter()
		local training = player:GetAttribute("Training") == true
		meter.Visible = training
		if not training then
			return
		end
		local data = stateController:Get()
		local climb = player:GetAttribute("ClimbPower")
		local power = if type(climb) == "number" then climb else 0
		local rate = Economy.TrainingRate(data.WalkerLevel or 0, data.Trail)
		gainLabel.Text = `+{Format.Rate(rate)} Climbing/s`
		local reached = Economy.ClimbTier(power)
		local target = 0
		local name = ""
		local reach, light, heavy = Economy.Targets(reached)
		local nextTier = Olympus.Tiers[reached + 1]
		local steps: { { At: number, Name: string } } = {
			{ At = light, Name = "Lightest sheep" },
			{ At = heavy, Name = "Heavier sheep" },
			{ At = if nextTier then nextTier.Reach else math.huge, Name = if nextTier then nextTier.God else "" },
		}
		for _, step in steps do
			if power < step.At then
				target = step.At
				name = step.Name
				break
			end
		end
		if target > 0 and target < math.huge then
			Style.SetBar(meterBar, math.clamp((power - reach) / math.max(target - reach, 1), 0, 1))
			goalLabel.Text = `Next: {name} at {Format.Short(target)}`
		else
			Style.SetBar(meterBar, 1, true)
			goalLabel.Text = "Fully trained"
		end
	end
	trove:Connect(player:GetAttributeChangedSignal("Training"), refreshMeter)
	trove:Connect(player:GetAttributeChangedSignal("ClimbPower"), refreshMeter)

	trove:Add(stateController.Changed:Connect(function()
		refreshTiles()
		refreshGoal()
		refreshClimb()
	end))
	refreshTiles()

	trove:Connect((tiles:FindFirstChild("FlockButton") :: TextButton).Activated, function()
		context.Open("Flock")
	end)
	trove:Connect((tiles:FindFirstChild("ShopButton") :: TextButton).Activated, function()
		context.Open("Shop")
	end)
	trove:Connect((tiles:FindFirstChild("SheepdexButton") :: TextButton).Activated, function()
		context.Open("Sheepdex")
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
		context.Notify(message, kind)
		if cue then
			sound:Play(cue)
		end
	end))

	-- The guide arrow: over its target when it's on screen, on the screen's edge pointing at it when it isn't.
	local SCREEN_MARGIN = 70
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
			arrow.Position = UDim2.fromOffset((point.X - inset.X) / scale, (point.Y - inset.Y) / scale)
			pointer.Rotation = 0
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
		arrow.Position = UDim2.fromOffset((at.X - inset.X) / scale, (at.Y - inset.Y) / scale)
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
		Notify = function(_self: Types.Screen, message: string, kind: string)
			notice(message, kind)
		end,
	}
end

return Hud
