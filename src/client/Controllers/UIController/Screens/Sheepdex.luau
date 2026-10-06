--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Herds = require(ReplicatedStorage.Config.Herds)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)
local UIKit = require(ReplicatedStorage.Utils.UIKit)
local Buttons = require(script.Parent.Parent.Buttons)
local MenuParts = require(script.Parent.Parent.MenuParts)
local Panel = require(script.Parent.Parent.Panel)
local Style = require(script.Parent.Parent.Style)
local Types = require(script.Parent.Parent.Types)

-- The collection book (Mark's mock-up, 2026-10-05, like Steal an Egg's Pet Index): one scrolling list with a section
-- per tier (its god, its six sheep Common to Mythic, a bar to the herd's gift), dark silhouettes in their rarity's
-- colour until the first of a family grows up, and the picked one beside it: what it earns, its rarity and its
-- reward, claimed here (SheepdexService). Cards draw their 3D sheep only once their tier scrolls near view.
local Sheepdex = {}

local Color = Theme.Color
local Fleece = Theme.Fleece

local PANEL_WIDTH = 820
local LIST_WIDTH = 520
local CARD = Vector2.new(116, 106)
local CARD_GAP = 8
local BANNER_WIDTH = 116
local BAR_HEIGHT = 22
local SECTION_HEIGHT = 2 * CARD.Y + CARD_GAP + 6 + BAR_HEIGHT
local SECTION_GAP = 14
local FOUND_BAR = 36
local BUILD_MARGIN = 300 -- a section's sheep are drawn once it's this many points from view
local SILHOUETTE_FADE = 0.35

local TOTAL = 0
for _, herd in Herds.ByGod do
	TOTAL += #herd
end

local function lit(frame: GuiObject, look: { Hi: Color3, Lo: Color3 })
	UIKit.Lit(frame, look.Hi, look.Lo, 1)
end

local function rays(parent: Instance, size: number, y: number)
	local burst = UIKit.Icon(parent, "Rays", Theme.Icons.Burst, size, Color.Snow)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, y)
	burst.ImageTransparency = 0.8
end

local function viewport(parent: Instance, name: string, size: UDim2): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = name
	view.BackgroundTransparency = 1
	view.Size = size
	view.Ambient = Color3.fromRGB(200, 200, 200)
	view.LightColor = Color3.fromRGB(255, 255, 255)
	view.LightDirection = Vector3.new(-0.4, -1, 0.6)
	view.ZIndex = 2
	view.Parent = parent
	return view
end

-- A dark silhouette while the family is unknown, so the card's colour still says how rare it is.
local function shade(view: ViewportFrame, known: boolean)
	view.Ambient = if known then Color3.fromRGB(200, 200, 200) else Color3.new(0, 0, 0)
	view.LightColor = if known then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
	view.ImageTransparency = if known then 0 else SILHOUETTE_FADE
end

-- A model in a viewport, turned a little from the camera; `lift` aims the camera higher (the model sits lower).
local function frameModel(view: ViewportFrame, model: Model, turn: number, distance: number, lift: number)
	view:ClearAllChildren()
	model:PivotTo(CFrame.Angles(0, math.rad(turn), 0))
	local world = Instance.new("WorldModel")
	model.Parent = world
	world.Parent = view
	local center, extents = model:GetBoundingBox()
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local aim = center.Position + Vector3.new(0, extents.Y * lift, 0)
	camera.CFrame = CFrame.lookAt(aim + Vector3.new(0, extents.Y * 0.25, -extents.Magnitude * distance), aim)
	camera.Parent = view
	view.CurrentCamera = camera
end

-- A god head to foot in the tall banner: its staffs and wings make the bounding box too big to frame by.
local function frameGod(view: ViewportFrame, god: Model)
	view:ClearAllChildren()
	god:PivotTo(CFrame.Angles(0, math.rad(-20), 0))
	local world = Instance.new("WorldModel")
	god.Parent = world
	world.Parent = view
	local head = god:FindFirstChild("Head")
	local root = god:FindFirstChild("HumanoidRootPart")
	if not head or not head:IsA("BasePart") or not root or not root:IsA("BasePart") then
		frameModel(view, god, -20, 0.95, 0)
		return
	end
	local top = head.Position.Y + head.Size.Y
	local bottom = root.Position.Y - root.Size.Y * 1.6
	local middle = Vector3.new(root.Position.X, (top + bottom) / 2, root.Position.Z)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local distance = (top - bottom) / (2 * math.tan(math.rad(15))) * 1.05
	camera.CFrame = CFrame.lookAt(middle + Vector3.new(0, 0, -distance), middle)
	camera.Parent = view
	view.CurrentCamera = camera
end

local function sheepModel(family: string): Model?
	local looks = ReplicatedStorage:FindFirstChild("SheepLooks")
	local look = looks and looks:FindFirstChild(family)
	return if look and look:IsA("Model") then look:Clone() else nil
end

-- The tier's god, copied from the mountain (GodService's models in workspace.Gods), still, without its nameplate.
-- Only the constraints that move it go: an avatar god's joints are constraints too, and without them its layered
-- clothing (dresses, goat legs) doesn't draw.
local function godModel(tier: number): Model?
	local gods = workspace:FindFirstChild("Gods")
	if not gods then
		return nil
	end
	for _, god in gods:GetChildren() do
		if god:IsA("Model") and god:GetAttribute("Tier") == tier then
			local copy = god:Clone()
			for _, part in copy:GetDescendants() do
				if
					part:IsA("BillboardGui")
					or part:IsA("AlignPosition")
					or part:IsA("AlignOrientation")
					or part:IsA("Script")
				then
					part:Destroy()
				elseif part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			return copy
		end
	end
	return nil
end

local function badge(parent: Instance): TextLabel
	local dot = UIKit.Text(parent, "ClaimBadge", "!", 15, Color.Snow, UDim2.fromOffset(24, 24), { Stroke = Color.Line })
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -2, 0, 0)
	dot.BackgroundTransparency = 0
	dot.BackgroundColor3 = Color.Red500
	dot.ZIndex = 8
	dot.Visible = false
	UIKit.Corner(dot)
	UIKit.Surface(dot, Color.Red800, 2, Color.Line, 1.5)
	return dot
end

local function card(parent: Instance, family: string, slot: number): TextButton
	local rarity = Herds.Rarities[slot]
	local button = Instance.new("TextButton")
	button.Name = family
	button.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = slot
	button.Parent = parent
	local face = UIKit.Frame(button, "Face", UDim2.fromScale(1, 1), Fleece.Rarity[rarity].Hi)
	lit(face, Fleece.Rarity[rarity])
	UIKit.Corner(face, Fleece.CardRadius)
	UIKit.Surface(face, Color.Line, 4, Color.Line, 2)
	rays(face, 120, 0.56)
	local view = viewport(face, "View", UDim2.new(1, -4, 1, -18))
	view.Position = UDim2.fromOffset(2, 16)
	local name = UIKit.Text(face, "NameLabel", "???", 14, Color.Snow, UDim2.new(1, -8, 0, 18), {
		Stroke = Color.Line,
		Fit = true,
	})
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 4)
	name.ZIndex = 4
	badge(face)
	for _, spec in { { "Selected", Color.Snow, 3.5, 2 }, { "SelectedRing", Color.Line, 2, 5.5 } } :: { { any } } do
		local stroke = Instance.new("UIStroke")
		stroke.Name = spec[1]
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
		stroke.BorderOffset = UDim.new(0, spec[4])
		stroke.Color = spec[2]
		stroke.Thickness = spec[3]
		stroke.Enabled = false
		stroke.Parent = face
	end
	return button
end

local function banner(parent: Instance, tier: Olympus.Tier)
	local frame = UIKit.Frame(parent, "Banner", UDim2.fromOffset(BANNER_WIDTH, SECTION_HEIGHT), tier.Robe)
	lit(frame, { Hi = tier.Robe:Lerp(Color.Snow, 0.35), Lo = tier.Robe:Lerp(Color3.new(0, 0, 0), 0.45) })
	UIKit.Corner(frame, Fleece.TileRadius)
	UIKit.Surface(frame, Color.Line, 4, Color.Line, 2)
	frame.ClipsDescendants = true
	rays(frame, 220, 0.5)
	local view = viewport(frame, "God", UDim2.new(1, 0, 1, -50))
	view.Position = UDim2.fromOffset(0, 24)
	local name = UIKit.Text(frame, "GodLabel", tier.God, 18, Color.Snow, UDim2.new(1, -8, 0, 22), {
		Stroke = Color.Line,
		Fit = true,
	})
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 4)
	name.ZIndex = 4
	local chip = UIKit.DarkChip(frame, "TierChip", nil, "TierLabel", true)
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.new(0.5, 0, 1, -8)
	chip.ZIndex = 4
	for _, child in chip:GetDescendants() do
		if child:IsA("GuiObject") then
			child.ZIndex = 4
		end
	end
	local tierLabel = chip:FindFirstChild("TierLabel") :: TextLabel
	tierLabel.Text = `TIER {tier.Tier}`
end

local function section(list: Instance, tier: Olympus.Tier, herd: { string }): Frame
	local frame = UIKit.Frame(list, `Tier{tier.Tier}`, UDim2.new(1, 0, 0, SECTION_HEIGHT))
	frame.LayoutOrder = tier.Tier
	banner(frame, tier)
	local cards = UIKit.Frame(frame, "Cards", UDim2.new(1, -(BANNER_WIDTH + CARD_GAP), 0, 2 * CARD.Y + CARD_GAP))
	cards.Position = UDim2.fromOffset(BANNER_WIDTH + CARD_GAP, 0)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(CARD.X, CARD.Y)
	grid.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = cards
	for slot, family in herd do
		card(cards, family, slot)
	end
	local meter = UIKit.Meter(frame, "Progress", UDim2.new(1, -(BANNER_WIDTH + CARD_GAP + 22), 0, BAR_HEIGHT))
	meter.Position = UDim2.new(0, BANNER_WIDTH + CARD_GAP, 1, -BAR_HEIGHT)
	local label = meter:FindFirstChild("Label") :: TextLabel
	label.TextSize = 16
	-- The herd's gift for claiming all six, at the end of its bar.
	local gift = UIKit.Icon(frame, "HerdGift", Theme.Icons.MenuGift, 40)
	gift.AnchorPoint = Vector2.new(1, 0.5)
	gift.Position = UDim2.new(1, 4, 1, -BAR_HEIGHT / 2 - 2)
	gift.Rotation = 10
	gift.ZIndex = 5
	return frame
end

local function rewardTile(parent: Instance, name: string, icon: string, order: number): TextLabel
	local tile = UIKit.Frame(parent, name, UDim2.fromOffset(54, 46), Fleece.Tile.Base)
	tile.LayoutOrder = order
	lit(tile, Fleece.Tile)
	UIKit.Corner(tile, 10)
	UIKit.Surface(tile, Color.Line, 3, Color.Line, 1.5)
	local picture = UIKit.Icon(tile, "Icon", icon, 26)
	picture.AnchorPoint = Vector2.new(0.5, 0)
	picture.Position = UDim2.new(0.5, 0, 0, 2)
	local amount = UIKit.Text(tile, "AmountLabel", "", 15, Color.Snow, UDim2.new(1, -4, 0, 18), {
		Stroke = Color.Line,
		Fit = true,
	})
	amount.AnchorPoint = Vector2.new(0.5, 1)
	amount.Position = UDim2.new(0.5, 0, 1, -2)
	return amount
end

function Sheepdex.Build(playerGui: Instance): ScreenGui
	local gui, window = UIKit.MenuGui("Sheepdex", "Day", "Sheepdex", nil, false, nil, {
		Accent = "Dex",
		Badge = Theme.Icons.MenuSheepdex,
		Size = "Large",
		Width = PANEL_WIDTH,
	})
	local header = window:FindFirstChild("Header") :: Frame
	local cash = header:FindFirstChild("CashChip", true)
	if cash then
		cash:Destroy()
	end
	local page = MenuParts.Pages(window)

	-- The list: every tier, one after another.
	local well = UIKit.Well(page, "ListWell", UDim2.new(0, LIST_WIDTH, 1, -(FOUND_BAR + 10)))
	well.ClipsDescendants = true
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.ScrollBarImageColor3 = Color.Snow
	list.ScrollBarImageTransparency = 0.5
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	list.Selectable = false
	list.ZIndex = 2
	list.Parent = well
	UIKit.List(list, false, SECTION_GAP)
	UIKit.Padding(list, 10, 12, 10, 10)
	for _, tier in Olympus.Tiers do
		section(list, tier, Herds.ByGod[tier.God] or { tier.Family })
	end

	-- How many of all the sheep you've found.
	local foundBar = UIKit.Frame(page, "FoundBar", UDim2.new(0, LIST_WIDTH, 0, FOUND_BAR))
	foundBar.AnchorPoint = Vector2.new(0, 1)
	foundBar.Position = UDim2.fromScale(0, 1)
	local foundMeter = UIKit.Meter(foundBar, "FoundMeter", UDim2.new(1, -24, 0, 30))
	foundMeter.AnchorPoint = Vector2.new(1, 0.5)
	foundMeter.Position = UDim2.fromScale(1, 0.5)
	local foundLabel = foundMeter:FindFirstChild("Label") :: TextLabel
	foundLabel.Name = "FoundLabel"
	foundLabel.TextSize = 19
	local book = UIKit.Icon(foundBar, "Book", Theme.Icons.MenuSheepdex, 54)
	book.AnchorPoint = Vector2.new(0, 0.5)
	book.Position = UDim2.new(0, -14, 0.5, -3)
	book.Rotation = -10
	book.ZIndex = 5

	-- The picked sheep, its reward and the claim.
	local detail = MenuParts.Detail(page, LIST_WIDTH)
	-- The picture takes what the line, rewards and button leave, so they fit on a short screen's compact panel too.
	local detailCard = detail:FindFirstChild("Card") :: Frame
	detailCard.Size = UDim2.new(1, 0, 0, 60)
	UIKit.Grow(detailCard)
	local info = detail:FindFirstChild("Info") :: Frame
	for _, name in { "Line2", "Line3" } do
		local line = info:FindFirstChild(name)
		if line and line:IsA("GuiObject") then
			line.Visible = false
		end
	end
	-- Its reward, cash and Climbing, beside the claim button: one row, so the picture keeps the room.
	local buttons = detail:FindFirstChild("Buttons") :: Frame
	local row = buttons:FindFirstChildOfClass("UIListLayout")
	if row then
		row.Padding = UDim.new(0, 6)
		row.VerticalAlignment = Enum.VerticalAlignment.Center
	end
	rewardTile(buttons, "CashReward", Theme.Icons.HudCash, 1)
	rewardTile(buttons, "ClimbReward", Theme.Icons.HudShoe, 2)
	local claim = UIKit.Button(buttons, "ClaimButton", "Buy", 110, Theme.ButtonHeight.Standard, "Claim!")
	claim.LayoutOrder = 3
	UIKit.Grow(claim)
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
	local foundMeter = window:FindFirstChild("FoundMeter", true) :: Frame
	local bigView = detail:FindFirstChild("View", true) :: ViewportFrame
	local nameLabel = detail:FindFirstChild("NameLabel", true) :: TextLabel
	local rarityChip = detail:FindFirstChild("RarityChip", true) :: Frame
	local rateLabel = detail:FindFirstChild("RateLabel", true) :: TextLabel
	local stage = detail:FindFirstChild("Stage", true) :: Frame
	local line1 = detail:FindFirstChild("Line1", true) :: TextLabel
	local cashLabel = (detail:FindFirstChild("CashReward", true) :: Frame):FindFirstChild("AmountLabel") :: TextLabel
	local climbLabel = (detail:FindFirstChild("ClimbReward", true) :: Frame):FindFirstChild("AmountLabel") :: TextLabel
	local claimButton = detail:FindFirstChild("ClaimButton", true) :: TextButton
	local stateController = context.Controllers.StateController
	local sound = context.Controllers.SoundController
	local picked: string? = nil
	local shownFamily: string? = nil
	local busy = false
	local drawn: { [Instance]: boolean } = {}

	local function dexOf(): ({ [string]: boolean }, { [string]: boolean }, { [string]: boolean })
		local data = stateController:Get()
		local found = if type(data.Dex) == "table" then data.Dex else {}
		local claimed = if type(data.DexClaimed) == "table" then data.DexClaimed else {}
		local gifts = if type(data.HerdGifts) == "table" then data.HerdGifts else {}
		return found, claimed, gifts
	end

	local function cardsOf(frame: Instance): { TextButton }
		local result = {}
		local cards = frame:FindFirstChild("Cards")
		if cards then
			for _, child in cards:GetChildren() do
				if child:IsA("TextButton") then
					table.insert(result, child)
				end
			end
		end
		return result
	end

	-- Draws a tier's god and sheep once it's near view (each viewport holds a whole model, so not all 180 at once).
	local function drawNear()
		local top = list.AbsolutePosition.Y - BUILD_MARGIN
		local bottom = list.AbsolutePosition.Y + list.AbsoluteSize.Y + BUILD_MARGIN
		local found = dexOf()
		for _, frame in list:GetChildren() do
			if frame:IsA("Frame") and not drawn[frame] then
				local y = frame.AbsolutePosition.Y
				if y + frame.AbsoluteSize.Y >= top and y <= bottom then
					drawn[frame] = true
					local tier = Olympus.Tiers[frame.LayoutOrder]
					local godView = (frame:FindFirstChild("Banner") :: Frame):FindFirstChild("God") :: ViewportFrame
					local god = if tier then godModel(tier.Tier) else nil
					if god then
						frameGod(godView, god)
					end
					for _, button in cardsOf(frame) do
						local view = (button:FindFirstChild("Face") :: Frame):FindFirstChild("View") :: ViewportFrame
						local model = sheepModel(button.Name)
						if model then
							frameModel(view, model, -35, 1.25, 0.12)
							shade(view, found[button.Name] == true)
						end
					end
				end
			end
		end
	end

	local function showDetail()
		local family = picked
		if not family then
			return
		end
		local found, claimed = dexOf()
		local known = found[family] == true
		local tier = Economy.Tier(family)
		local rarity = Herds.Rarities[Economy.FamilyRarity(family)]
		nameLabel.Text = if known then Economy.FamilyName(family) else "???"
		Style.PaintStage(stage, rarity)
		Style.PaintRarity(rarityChip, rarity)
		rateLabel.Text = `+{Format.Rate(Economy.FamilyBase(family))}/s`
		if shownFamily ~= family then
			shownFamily = family
			local model = sheepModel(family)
			if model then
				frameModel(bigView, model, -35, 1.35, 0.05)
			else
				bigView:ClearAllChildren()
			end
		end
		shade(bigView, known)
		line1.Text = if known then `{tier.God}'s {tier.Area}` else `Steal one from {tier.God}`
		cashLabel.Text = Format.Short(Economy.DexReward(family))
		climbLabel.Text = `+{Format.Short(Economy.DexClimb(family))}`
		if not known then
			Buttons.Set(claimButton, "Disabled", "Not found")
		elseif claimed[family] then
			Buttons.Set(claimButton, "Disabled", "Claimed!")
		else
			Buttons.Set(claimButton, "Buy", "Claim!")
		end
	end

	local function refresh()
		local found, claimed, gifts = dexOf()
		local total = 0
		for _, frame in list:GetChildren() do
			if not frame:IsA("Frame") then
				continue
			end
			local count = 0
			local cards = cardsOf(frame)
			for _, button in cards do
				local family = button.Name
				local known = found[family] == true
				if known then
					count += 1
				end
				local face = button:FindFirstChild("Face") :: Frame
				local name = face:FindFirstChild("NameLabel") :: TextLabel
				name.Text = if known then (string.gsub(Economy.FamilyName(family), " Sheep$", "")) else "???"
				local dot = face:FindFirstChild("ClaimBadge")
				if dot and dot:IsA("GuiObject") then
					dot.Visible = known and claimed[family] ~= true
				end
				local view = face:FindFirstChild("View")
				if view and view:IsA("ViewportFrame") then
					shade(view, known)
				end
				for _, ringName in { "Selected", "SelectedRing" } do
					local ring = face:FindFirstChild(ringName)
					if ring and ring:IsA("UIStroke") then
						ring.Enabled = family == picked
					end
				end
			end
			total += count
			local meter = frame:FindFirstChild("Progress") :: Frame
			local fill = meter:FindFirstChild("Fill") :: Frame
			fill.Size = UDim2.fromScale(count / math.max(#cards, 1), 1)
			local tier = Olympus.Tiers[frame.LayoutOrder]
			local done = tier ~= nil and gifts[tier.God] == true
			fill.BackgroundColor3 = if done then Color.Green500 else Color.Gold500
			local label = meter:FindFirstChild("Label") :: TextLabel
			label.Text = `{count}/{#cards}`
			local gift = frame:FindFirstChild("HerdGift")
			if gift and gift:IsA("ImageLabel") then
				gift.ImageTransparency = if done then 0.5 else 0
			end
		end
		foundLabel.Text = `Found: {total}/{TOTAL}`
		local fill = foundMeter:FindFirstChild("Fill") :: Frame
		fill.Size = UDim2.fromScale(math.max(total / math.max(TOTAL, 1), 0.04), 1)
		fill.BackgroundColor3 = Color.Blue500
		showDetail()
	end

	-- The first sheep with a reward waiting, else the first not found yet: what to look at on opening.
	local function firstToShow(): string
		local found, claimed = dexOf()
		local firstUnknown: string? = nil
		for _, tier in Olympus.Tiers do
			local herd: { string } = Herds.ByGod[tier.God] or { tier.Family }
			for _, family in herd do
				if found[family] and not claimed[family] then
					return family
				end
				if not found[family] and not firstUnknown then
					firstUnknown = family
				end
			end
		end
		return firstUnknown or Olympus.Tiers[1].Family
	end

	-- Scrolls the picked sheep's tier to the top of the list (CanvasPosition counts drawn pixels, UIScale included).
	local function scrollTo(family: string)
		local tier = Olympus.ByFamily[family]
		local frame = tier and list:FindFirstChild(`Tier{tier.Tier}`)
		if frame and frame:IsA("GuiObject") then
			local y = list.CanvasPosition.Y + (frame.AbsolutePosition.Y - list.AbsolutePosition.Y)
			local most = math.max(list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y, 0)
			list.CanvasPosition = Vector2.new(0, math.clamp(y - 8, 0, most))
		end
	end

	for _, frame in list:GetChildren() do
		if frame:IsA("Frame") then
			for _, button in cardsOf(frame) do
				trove:Connect(button.Activated, function()
					picked = button.Name
					refresh()
				end)
			end
		end
	end
	trove:Connect(list:GetPropertyChangedSignal("CanvasPosition"), drawNear)
	trove:Connect(claimButton.Activated, function()
		local family = picked
		local found, claimed = dexOf()
		if busy or not family or not found[family] or claimed[family] then
			Buttons.Shake(claimButton)
			return
		end
		busy = true
		Buttons.Loading(claimButton, true)
		local callOk, success, message = Remotes.ClaimDex:Invoke(family)
		Buttons.Loading(claimButton, false)
		busy = false
		if not callOk or not success then
			panel.Status(if callOk and message then message else "Try again", "Bad")
			sound:Play("Denied")
			refresh()
			return
		end
		-- The reward tiles beside the button already say what it gave.
		sound:Play("RevealCoins")
	end)
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
			picked = firstToShow()
			refresh()
			panel.Show()
			local target = picked
			-- Once the pop-in has finished: it changes the list's drawn size while it plays.
			task.delay(Theme.Motion.PopIn.Time + 0.05, function()
				if gui.Enabled and target then
					scrollTo(target)
					drawNear()
				end
			end)
			drawNear()
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
