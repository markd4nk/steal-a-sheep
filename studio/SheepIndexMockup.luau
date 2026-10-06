--!strict

-- A mock-up of the reworked Sheepdex for Mark's OK (2026-10-05), not game code. One scrolling list with a section per
-- tier (its god, its five sheep from Common to Legendary, a bar to the tier's reward) and the picked sheep beside it:
-- what it earns, its rarity and what claiming it gives. Run it with execute_luau in Edit on a copy of the place: it
-- builds StarterGui.TEMP_SheepIndexMockup (replaced on each run) from the game's own UI kit and sheep looks, with
-- sample designs for tiers 1-3. Delete TEMP_SheepIndexMockup once it's screenshotted.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

-- build/push-mock.sh sends this script with the branch's Extras, GameConfig and Herds beside it (newer than the
-- place's copies); without them, the place's own.
local bundle = script.Parent
local services = ServerScriptService:FindFirstChild("Services") :: any
local function newest(name: string, fallback: Instance): any
	local sent = bundle and bundle:FindFirstChild(name)
	return require(if sent and sent:IsA("ModuleScript") then sent else fallback :: ModuleScript)
end
local GameConfig = newest("GameConfig", ReplicatedStorage.Config.GameConfig)
local Extras = newest("Extras", services.SheepService.Extras)
local Herds = if bundle and bundle:FindFirstChild("Herds") then require(bundle.Herds :: ModuleScript) :: any else nil
local Olympus = require(ReplicatedStorage.Config.Olympus) :: any
local Theme = require(ReplicatedStorage.Config.Theme) :: any
local UIKit = require(ReplicatedStorage.Utils.UIKit) :: any
local Looks = require(services.SheepService.Looks) :: any
local GodRig = require(services.GodService.Rig) :: any
local ui = (StarterPlayer :: any).StarterPlayerScripts.Controllers.UIController
local MenuParts = require(ui.MenuParts) :: any

local Color = Theme.Color
local Fleece = Theme.Fleece
local rgb = Color3.fromRGB

local GUI_NAME = "TEMP_SheepIndexMockup"
local SCALE = 1.45 -- the Root's UI scale in the Studio viewport
local PANEL_WIDTH = 880
local LIST_WIDTH = 600
local CARD = Vector2.new(86, 106)
local CARD_GAP = 6
local BANNER_WIDTH = 112
local BAR_HEIGHT = 22
local SECTION_HEIGHT = CARD.Y + 6 + BAR_HEIGHT

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
local MULTIPLIERS = { 1, 1.5, 2.5, 4, 8 }

-- Sample designs: each tier's family as its Common, then four new looks from Shear a Sheep's builds and paints.
local function family(id: string): { [string]: any }
	return table.clone(GameConfig.Breeds[id])
end

local GOLD_SPARKLE = rgb(255, 214, 90)

type Sheep = { Name: string, Look: { [string]: any }, Found: boolean, Claimed: boolean }
type Section = { Tier: number, Sheep: { Sheep } }

local SECTIONS: { Section } = {
	{
		Tier = 1,
		Sheep = {
			{ Name = "Meadow Sheep", Look = family("Meadow"), Found = true, Claimed = true },
			{
				Name = "Clover Sheep",
				Look = {
					WoolStyle = "Spotted",
					WoolColor = rgb(246, 250, 236),
					WoolSpotColor = rgb(96, 176, 72),
					Extra = "Leaf",
					Face = "Happy",
				},
				Found = true,
				Claimed = true,
			},
			{
				Name = "Sunflower Sheep",
				Look = {
					WoolStyle = "Cloud",
					WoolColor = rgb(255, 204, 40),
					FaceColor = rgb(110, 72, 40),
					LegColor = rgb(110, 72, 40),
					Extra = "Leaf",
					Face = "Happy",
				},
				Found = true,
				Claimed = false,
			},
			{
				Name = "Mushroom Sheep",
				Look = {
					Build = "MossSheep",
					WoolColor = rgb(120, 180, 80),
					WoolSpotColor = rgb(150, 200, 90),
					FaceColor = rgb(150, 110, 80),
					LegColor = rgb(120, 90, 64),
					SpecialFX = "Spores",
				},
				Found = true,
				Claimed = true,
			},
			{
				Name = "Golden Ram",
				Look = {
					WoolStyle = "Ringlets",
					WoolSize = 1.25,
					Mutation = "Gold",
					HornStyle = "BigCurl",
					HornColor = rgb(190, 110, 40),
					Face = "Happy",
					Extra = "Wreath",
					Sparkle = GOLD_SPARKLE,
				},
				Found = false,
				Claimed = false,
			},
		},
	},
	{
		Tier = 2,
		Sheep = {
			{ Name = "Grape Sheep", Look = family("Grape"), Found = true, Claimed = true },
			{
				Name = "Bamboo Sheep",
				Look = {
					WoolStyle = "Icicle",
					WoolColor = rgb(150, 205, 95),
					FaceColor = rgb(232, 226, 190),
					LegColor = rgb(120, 160, 70),
				},
				Found = true,
				Claimed = false,
			},
			{
				Name = "Panda Sheep",
				Look = {
					WoolStyle = "Spotted",
					WoolColor = rgb(250, 250, 250),
					WoolSpotColor = rgb(35, 35, 40),
					FaceColor = rgb(40, 40, 44),
					LegColor = rgb(35, 35, 40),
					EarInnerColor = rgb(70, 70, 74),
				},
				Found = false,
				Claimed = false,
			},
			{
				Name = "Berry Sheep",
				Look = { Build = "CupcakeSheep", WoolColor = rgb(235, 90, 150), SpecialFX = "Sparkles" },
				Found = false,
				Claimed = false,
			},
			{
				Name = "Royal Grape Sheep",
				Look = { Build = "RoyalSheep", WoolColor = rgb(130, 70, 180), Extra = "Leaf" },
				Found = false,
				Claimed = false,
			},
		},
	},
	{
		Tier = 3,
		Sheep = {
			{ Name = "Moon Sheep", Look = family("Moon"), Found = false, Claimed = false },
			{
				Name = "Snow Sheep",
				Look = {
					WoolStyle = "Cloud",
					WoolColor = rgb(252, 253, 255),
					FaceColor = rgb(200, 215, 235),
					LegColor = rgb(200, 215, 235),
				},
				Found = false,
				Claimed = false,
			},
			{
				Name = "Fawn Sheep",
				Look = {
					WoolStyle = "Spotted",
					WoolColor = rgb(196, 132, 78),
					WoolSpotColor = rgb(250, 240, 225),
					FaceColor = rgb(170, 110, 64),
					LegColor = rgb(150, 96, 56),
					EarInnerColor = rgb(240, 200, 170),
				},
				Found = false,
				Claimed = false,
			},
			{
				Name = "Stag Sheep",
				Look = {
					Mutation = "Silver",
					WoolSize = 1.2,
					HornStyle = "BigCurl",
					HornColor = rgb(150, 162, 200),
					FaceColor = rgb(150, 156, 186),
					LegColor = rgb(120, 126, 160),
				},
				Found = false,
				Claimed = false,
			},
			{
				Name = "Starlight Sheep",
				Look = {
					Build = "GalaxySheep",
					WoolColor = rgb(40, 50, 120),
					FaceColor = rgb(70, 80, 160),
					LegColor = rgb(31, 29, 71),
					Face = "CosmicNebula",
					HornStyle = "Spiral",
					HornColor = rgb(230, 235, 255),
				},
				Found = false,
				Claimed = false,
			},
		},
	},
}

-- What to show, from ServerStorage's attributes: MockView "Index" (the menu) or "Lineup" (every sample sheep, big);
-- MockTier and MockSlot, the picked sheep.
local VIEW = ServerStorage:GetAttribute("MockView") or "Index"
local PICKED_TIER = ServerStorage:GetAttribute("MockTier") or 1
local PICKED_SLOT = ServerStorage:GetAttribute("MockSlot") or 3
local TOTAL_SHEEP = 150

-- Sheep and gods -----------------------------------------------------------------------------------------------------

local assets = ServerStorage:FindFirstChild("Assets") :: any
local kit = Looks.new(assets.SheepAddons)
local rig = assets.SheepRig :: Model
rig:PivotTo(CFrame.identity)

local function breed(overrides: { [string]: any }): { [string]: any }
	local look: { [string]: any } = {
		Id = "Mock",
		DisplayName = "Mock",
		WoolColor = rgb(248, 248, 242),
		WoolMaterial = Enum.Material.SmoothPlastic,
		WoolSize = 1,
		WoolStyle = "Puffs",
		FaceColor = rgb(238, 216, 182),
		Face = "Idle",
		LegColor = rgb(238, 216, 182),
		SkinColor = rgb(242, 186, 180),
		SkinMaterial = Enum.Material.SmoothPlastic,
		HornColor = rgb(238, 222, 190),
		BaaPitch = 1,
	}
	for key, value in overrides do
		look[key] = value
	end
	look.Scale = 1
	return look
end

local function buildSheep(overrides: { [string]: any }): Model
	local look = breed(overrides)
	local model = rig:Clone()
	Looks.Dress(kit, model, look)
	Looks.Paint(model, look, look.Mutation)
	if look.Extra then
		Extras.Add(model, look.Extra)
	end
	for _, extra in look.Extras or {} do
		Extras.Add(model, extra.Kind, extra.Color)
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	return model
end

-- A model in a ViewportFrame, turned to face the camera a little from the side; `lift` moves the camera's aim up (the
-- model sits lower), `distance` is in bounding-box diagonals.
local function show(view: ViewportFrame, model: Model, turn: number, distance: number, lift: number)
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

local function viewport(parent: Instance, name: string, size: UDim2): ViewportFrame
	local view = Instance.new("ViewportFrame")
	view.Name = name
	view.BackgroundTransparency = 1
	view.Size = size
	view.Ambient = rgb(200, 200, 200)
	view.LightColor = rgb(255, 255, 255)
	view.LightDirection = Vector3.new(-0.4, -1, 0.6)
	view.Parent = parent
	return view
end

-- UI pieces ----------------------------------------------------------------------------------------------------------

local function lit(frame: GuiObject, look: { Hi: Color3, Lo: Color3 })
	UIKit.Lit(frame, look.Hi, look.Lo, 1)
end

local function rays(parent: Instance, size: number, y: number, transparency: number)
	local burst = UIKit.Icon(parent, "Rays", Theme.Icons.Burst, size, Color.Snow)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.Position = UDim2.fromScale(0.5, y)
	burst.ImageTransparency = transparency
	return burst
end

local function badge(parent: Instance, text: string)
	local dot = UIKit.Text(parent, "ClaimBadge", text, 15, Color.Snow, UDim2.fromOffset(24, 24), { Stroke = Color.Line })
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.new(1, -2, 0, 0)
	dot.BackgroundTransparency = 0
	dot.BackgroundColor3 = Color.Red500
	dot.ZIndex = 8
	UIKit.Corner(dot)
	UIKit.Surface(dot, Color.Red800, 2, Color.Line, 1.5)
end

local function card(parent: Instance, sheep: Sheep, rarity: string, order: number, picked: boolean)
	local button = Instance.new("TextButton")
	button.Name = `Card{order}`
	button.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	button.BackgroundTransparency = 1
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = order
	button.Parent = parent
	local look = Fleece.Rarity[rarity]
	local face = UIKit.Frame(button, "Face", UDim2.fromScale(1, 1), look.Hi)
	lit(face, look)
	UIKit.Corner(face, Fleece.CardRadius)
	UIKit.Surface(face, Color.Line, 4, Color.Line, 2)
	face.ClipsDescendants = false
	rays(face, 110, 0.56, 0.8)
	local view = viewport(face, "View", UDim2.new(1, -4, 1, -18))
	view.Position = UDim2.fromOffset(2, 16)
	view.ZIndex = 2
	show(view, buildSheep(sheep.Look), -35, 1.25, 0.12)
	if not sheep.Found then
		-- A flat dark silhouette with the card's colour showing through, so it still says how rare it is.
		view.Ambient = Color3.new(0, 0, 0)
		view.LightColor = Color3.new(0, 0, 0)
		view.ImageTransparency = 0.35
	end
	local name = if sheep.Found then (string.gsub(sheep.Name, " Sheep$", "")) else "???"
	local label = UIKit.Text(face, "NameLabel", name, 14, Color.Snow, UDim2.new(1, -8, 0, 18), {
		Stroke = Color.Line,
		Fit = true,
	})
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 4)
	label.ZIndex = 4
	if sheep.Found and not sheep.Claimed then
		badge(face, "!")
	end
	if picked then
		for _, ring in
			{ { "Selected", Color.Snow, 3.5, 2 }, { "SelectedRing", Color.Line, 2, 5.5 } } :: { { any } }
		do
			local stroke = Instance.new("UIStroke")
			stroke.Name = ring[1]
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
			stroke.BorderOffset = UDim.new(0, ring[4])
			stroke.Color = ring[2]
			stroke.Thickness = ring[3]
			stroke.Parent = face
		end
	end
end

local function banner(parent: Instance, tier: any)
	local frame = UIKit.Frame(parent, "Banner", UDim2.fromOffset(BANNER_WIDTH, SECTION_HEIGHT), tier.Robe)
	local look = { Hi = tier.Robe:Lerp(Color.Snow, 0.35), Lo = tier.Robe:Lerp(Color3.new(0, 0, 0), 0.45) }
	lit(frame, look)
	UIKit.Corner(frame, Fleece.TileRadius)
	UIKit.Surface(frame, Color.Line, 4, Color.Line, 2)
	frame.ClipsDescendants = true
	rays(frame, 170, 0.55, 0.78)
	local view = viewport(frame, "God", UDim2.new(1, 0, 1, -22))
	view.Position = UDim2.fromOffset(0, 20)
	view.ZIndex = 2
	local god = GodRig.Build(tier)
	for _, descendant in god:GetDescendants() do
		if descendant:IsA("BillboardGui") then
			descendant:Destroy()
		end
	end
	-- Head and shoulders: the bounding box takes in staffs and wings, so aim at the head instead.
	god:PivotTo(CFrame.Angles(0, math.rad(-20), 0))
	local world = Instance.new("WorldModel")
	god.Parent = world
	world.Parent = view
	local head = god:FindFirstChild("Head") :: BasePart
	local aim = head.Position - Vector3.new(0, 0.75, 0)
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(aim + Vector3.new(0, 0.9, -11), aim)
	camera.Parent = view
	view.CurrentCamera = camera
	local name = UIKit.Text(frame, "GodLabel", tier.God, 17, Color.Snow, UDim2.new(1, -8, 0, 20), {
		Stroke = Color.Line,
		Fit = true,
	})
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 4)
	name.ZIndex = 4
	local chip = UIKit.DarkChip(frame, "TierChip", nil, "TierLabel", true)
	chip.AnchorPoint = Vector2.new(0.5, 1)
	chip.Position = UDim2.new(0.5, 0, 1, -6)
	chip.ZIndex = 4
	for _, child in chip:GetDescendants() do
		if child:IsA("GuiObject") then
			child.ZIndex = 4
		end
	end
	local tierLabel = chip:FindFirstChild("TierLabel") :: TextLabel
	tierLabel.Text = `TIER {tier.Tier}`
end

local function section(list: Instance, data: Section)
	local tier = Olympus.Tiers[data.Tier]
	local frame = UIKit.Frame(list, `Tier{data.Tier}`, UDim2.new(1, 0, 0, SECTION_HEIGHT))
	frame.LayoutOrder = data.Tier
	banner(frame, tier)
	local cards = UIKit.Frame(frame, "Cards", UDim2.new(1, -(BANNER_WIDTH + 8), 0, CARD.Y))
	cards.Position = UDim2.fromOffset(BANNER_WIDTH + 8, 0)
	UIKit.List(cards, true, CARD_GAP)
	local found = 0
	for slot, sheep in data.Sheep do
		card(cards, sheep, RARITIES[slot], slot, data.Tier == PICKED_TIER and slot == PICKED_SLOT)
		if sheep.Found then
			found += 1
		end
	end
	local meter = UIKit.Meter(frame, "Progress", UDim2.new(1, -(BANNER_WIDTH + 8 + 22), 0, BAR_HEIGHT))
	meter.Position = UDim2.new(0, BANNER_WIDTH + 8, 1, -BAR_HEIGHT)
	local fill = meter:FindFirstChild("Fill") :: Frame
	fill.Size = UDim2.fromScale(found / #data.Sheep, 1)
	fill.BackgroundColor3 = if found == #data.Sheep then Color.Green500 else Color.Gold500
	local label = meter:FindFirstChild("Label") :: TextLabel
	label.Text = `{found}/{#data.Sheep}`
	label.TextSize = 16
	-- The tier's reward for finding all five, at the end of its bar.
	local gift = UIKit.Icon(frame, "TierReward", Theme.Icons.MenuGift, 40)
	gift.AnchorPoint = Vector2.new(1, 0.5)
	gift.Position = UDim2.new(1, 4, 1, -BAR_HEIGHT / 2 - 2)
	gift.Rotation = 10
	gift.ZIndex = 5
end

local function rewardTile(parent: Instance, name: string, icon: string, text: string, order: number)
	local tile = UIKit.Frame(parent, name, UDim2.fromOffset(62, 50), Fleece.Tile.Base)
	tile.LayoutOrder = order
	lit(tile, Fleece.Tile)
	UIKit.Corner(tile, 10)
	UIKit.Surface(tile, Color.Line, 3, Color.Line, 1.5)
	local picture = UIKit.Icon(tile, "Icon", icon, 30)
	picture.AnchorPoint = Vector2.new(0.5, 0)
	picture.Position = UDim2.new(0.5, 0, 0, 2)
	local amount = UIKit.Text(tile, "AmountLabel", text, 15, Color.Snow, UDim2.new(1, -4, 0, 18), {
		Stroke = Color.Line,
		Fit = true,
	})
	amount.AnchorPoint = Vector2.new(0.5, 1)
	amount.Position = UDim2.new(0.5, 0, 1, -2)
end

local function short(value: number): string
	if value >= 1000 then
		return string.format("%.1fK", value / 1000)
	end
	return if value == math.floor(value) then tostring(value) else string.format("%.1f", value)
end

-- Build --------------------------------------------------------------------------------------------------------------

local function fitText(gui: ScreenGui, scale: number)
	-- Text size limits count screen pixels, so they grow with the scale (as UIController/Scale does in play).
	for _, limit in gui:GetDescendants() do
		if limit:IsA("UITextSizeConstraint") then
			local most = limit:GetAttribute("MaxPoints")
			local least = limit:GetAttribute("MinPoints")
			if type(most) == "number" and type(least) == "number" then
				limit.MaxTextSize = math.floor(most * scale + 0.5)
				limit.MinTextSize = math.floor(least * scale + 0.5)
			end
		end
	end
end

local function scaled(gui: ScreenGui)
	local root = gui:FindFirstChild("Root") :: Frame
	local scale = root:FindFirstChild("Scale") :: UIScale
	scale.Scale = SCALE
	root.Size = UDim2.fromScale(1 / SCALE, 1 / SCALE)
end

local function paintChip(chip: Frame, rarity: string)
	local look = Fleece.Rarity[rarity]
	UIKit.Lit(chip, look.Hi, look.Base, 1)
	local lip = chip:FindFirstChild("Lip")
	if lip and lip:IsA("UIShadow") then
		lip.Color = look.Lo
	end
	local label = chip:FindFirstChild("Label") :: TextLabel
	label.Text = string.upper(rarity)
end

local function buildIndex(): ScreenGui
	local gui, window = UIKit.MenuGui(GUI_NAME, "Day", "Sheepdex", nil, false, nil, {
		Accent = "Dex",
		Badge = Theme.Icons.MenuSheepdex,
		Size = "Large",
		Width = PANEL_WIDTH,
	})
	scaled(gui)
	local header = window:FindFirstChild("Header") :: Frame
	local cash = header:FindFirstChild("CashChip", true)
	if cash then
		cash:Destroy()
	end
	local page = window:FindFirstChild("Pages") :: Frame

	-- The list: every tier, one after another.
	local well = UIKit.Well(page, "ListWell", UDim2.new(0, LIST_WIDTH, 1, -46))
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
	list.ZIndex = 2
	list.Parent = well
	UIKit.List(list, false, 14)
	UIKit.Padding(list, 12, 14, 12, 14)
	for _, data in SECTIONS do
		section(list, data)
	end

	-- How many of all the sheep you've found.
	local foundBar = UIKit.Frame(page, "FoundBar", UDim2.new(0, LIST_WIDTH, 0, 36))
	foundBar.AnchorPoint = Vector2.new(0, 1)
	foundBar.Position = UDim2.fromScale(0, 1)
	local foundCount = 0
	for _, data in SECTIONS do
		for _, sheep in data.Sheep do
			if sheep.Found then
				foundCount += 1
			end
		end
	end
	local foundMeter = UIKit.Meter(foundBar, "FoundMeter", UDim2.new(1, -24, 0, 30))
	foundMeter.AnchorPoint = Vector2.new(1, 0.5)
	foundMeter.Position = UDim2.fromScale(1, 0.5)
	local foundFill = foundMeter:FindFirstChild("Fill") :: Frame
	foundFill.Size = UDim2.fromScale(math.max(foundCount / TOTAL_SHEEP, 0.06), 1)
	foundFill.BackgroundColor3 = Color.Blue500
	local foundLabel = foundMeter:FindFirstChild("Label") :: TextLabel
	foundLabel.Text = `Found: {foundCount}/{TOTAL_SHEEP}`
	foundLabel.TextSize = 19
	local book = UIKit.Icon(foundBar, "Book", Theme.Icons.MenuSheepdex, 54)
	book.AnchorPoint = Vector2.new(0, 0.5)
	book.Position = UDim2.new(0, -14, 0.5, -3)
	book.Rotation = -10
	book.ZIndex = 5

	-- The picked sheep: found, or its silhouette and where to steal one.
	local detail = MenuParts.Detail(page, LIST_WIDTH)
	local pickedTier = Olympus.Tiers[PICKED_TIER]
	local picked = SECTIONS[PICKED_TIER].Sheep[PICKED_SLOT]
	local rarity = RARITIES[PICKED_SLOT]
	local detailCard = detail:FindFirstChild("Card") :: Frame
	detailCard.Size = UDim2.new(1, 0, 0, 138)
	local stage = detail:FindFirstChild("Stage", true) :: Frame
	lit(stage, Fleece.Rarity[rarity])
	local bigView = stage:FindFirstChild("View") :: ViewportFrame
	show(bigView, buildSheep(picked.Look), -35, 1.35, 0.05)
	if not picked.Found then
		bigView.Ambient = Color3.new(0, 0, 0)
		bigView.LightColor = Color3.new(0, 0, 0)
		bigView.ImageTransparency = 0.35
	end
	local nameLabel = detail:FindFirstChild("NameLabel", true) :: TextLabel
	nameLabel.Text = if picked.Found then picked.Name else "???"
	paintChip(detail:FindFirstChild("RarityChip", true) :: Frame, rarity)
	local income = 2 * 2.5 ^ (PICKED_TIER - 1) * MULTIPLIERS[PICKED_SLOT]
	local rateLabel = detail:FindFirstChild("RateLabel", true) :: TextLabel
	rateLabel.Text = `+{short(income)}/s`
	local info = detail:FindFirstChild("Info") :: Frame
	local line1 = info:FindFirstChild("Line1") :: TextLabel
	line1.Text = if picked.Found then `{pickedTier.God}'s {pickedTier.Area}` else `Steal one from {pickedTier.God}`
	for _, name in { "Line2", "Line3" } do
		local line = info:FindFirstChild(name)
		if line and line:IsA("GuiObject") then
			line.Visible = false
		end
	end

	-- What claiming it gives, then the claim button.
	local rewards = UIKit.Frame(detail, "Rewards", UDim2.new(1, 0, 0, 58), Fleece.Well)
	rewards.LayoutOrder = 3
	rewards.BackgroundTransparency = Fleece.WellTransparency
	UIKit.Corner(rewards, 12)
	local rewardsTitle = UIKit.Text(rewards, "Title", "Rewards", 15, Color.Snow, UDim2.new(0, 70, 1, 0), {
		Stroke = Color.Line,
	})
	rewardsTitle.Position = UDim2.fromOffset(8, 0)
	rewardsTitle.TextXAlignment = Enum.TextXAlignment.Left
	local tiles = UIKit.Frame(rewards, "Tiles", UDim2.new(1, -80, 1, 0))
	tiles.Position = UDim2.fromOffset(76, 0)
	local tilesList = UIKit.List(tiles, true, 8, Enum.HorizontalAlignment.Center)
	tilesList.VerticalAlignment = Enum.VerticalAlignment.Center
	rewardTile(tiles, "CashReward", Theme.Icons.HudCash, short(income * 30), 1)
	rewardTile(tiles, "ClimbReward", Theme.Icons.HudShoe, "+" .. short(10 * MULTIPLIERS[PICKED_SLOT] * PICKED_TIER), 2)
	local buttons = detail:FindFirstChild("Buttons") :: Frame
	buttons.LayoutOrder = 4
	local kind, text = "Buy", "Claim!"
	if not picked.Found then
		kind, text = "Disabled", "Not found yet"
	elseif picked.Claimed then
		kind, text = "Disabled", "Claimed!"
	end
	local claim = UIKit.Button(buttons, "ClaimButton", kind, 210, Theme.ButtonHeight.Standard, text)
	UIKit.Grow(claim)
	UIKit.LightText(window)
	return gui
end

-- Every sample sheep revealed and big, a row a tier, for judging the designs.
local function buildLineup(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.None
	UIKit.Backdrop(gui, 0.25)
	local root = UIKit.Root(gui)
	scaled(gui)
	local board = UIKit.Frame(root, "Board", UDim2.fromOffset(940, 520))
	board.AnchorPoint = Vector2.new(0.5, 0.5)
	board.Position = UDim2.fromScale(0.5, 0.5)
	UIKit.List(board, false, 12, Enum.HorizontalAlignment.Center)
	for _, data in SECTIONS do
		local tier = Olympus.Tiers[data.Tier]
		local row = UIKit.Frame(board, `Tier{data.Tier}`, UDim2.fromOffset(940, 160))
		row.LayoutOrder = data.Tier
		local rowList = UIKit.List(row, true, 10, Enum.HorizontalAlignment.Center)
		rowList.VerticalAlignment = Enum.VerticalAlignment.Center
		local god = UIKit.Text(row, "GodLabel", `{tier.God}\nTier {tier.Tier}`, 22, Color.Snow, UDim2.fromOffset(100, 160), {
			Stroke = Color.Line,
			Wrap = true,
		})
		god.LayoutOrder = 0
		for slot, sheep in data.Sheep do
			local rarity = RARITIES[slot]
			local look = Fleece.Rarity[rarity]
			local face = UIKit.Frame(row, `Sheep{slot}`, UDim2.fromOffset(152, 156), look.Hi)
			face.LayoutOrder = slot
			lit(face, look)
			UIKit.Corner(face, Fleece.CardRadius)
			UIKit.Surface(face, Color.Line, 4, Color.Line, 2)
			rays(face, 190, 0.5, 0.8)
			local view = viewport(face, "View", UDim2.new(1, -6, 1, -50))
			view.Position = UDim2.fromOffset(3, 24)
			view.ZIndex = 2
			show(view, buildSheep(sheep.Look), -35, 1.2, 0.08)
			local name = UIKit.Text(face, "NameLabel", sheep.Name, 17, Color.Snow, UDim2.new(1, -10, 0, 20), {
				Stroke = Color.Line,
				Fit = true,
			})
			name.AnchorPoint = Vector2.new(0.5, 0)
			name.Position = UDim2.new(0.5, 0, 0, 5)
			name.ZIndex = 4
			local chip = UIKit.RarityChip(face, "RarityChip", true)
			chip.AnchorPoint = Vector2.new(0.5, 1)
			chip.Position = UDim2.new(0.5, 0, 1, -7)
			chip.ZIndex = 4
			paintChip(chip, rarity)
		end
	end
	return gui
end

-- The gods in their new climbing order (t3code/order-olympian-gods, the user's pick; not merged yet).
local GOD_ORDER = {
	"Pan",
	"Tyche",
	"Hecate",
	"Phobos",
	"Eris",
	"Eros",
	"Hebe",
	"Themis",
	"Asclepius",
	"Iris",
	"Nike",
	"Aeolus",
	"Hypnos",
	"Morpheus",
	"Deimos",
	"Thanatos",
	"Nemesis",
	"Dionysus",
	"Hermes",
	"Hephaestus",
	"Ares",
	"Aphrodite",
	"Artemis",
	"Apollo",
	"Athena",
	"Demeter",
	"Hestia",
	"Poseidon",
	"Hera",
	"Zeus",
}
local HERD_PAGE_SIZE = 5
local HERD_SCALE = 1.08

-- Every god's herd (Config/Herds), revealed: five gods a page (MockPage), a row each, Common to Mythic.
local function buildHerds(): ScreenGui
	local pageIndex = ServerStorage:GetAttribute("MockPage") or 1
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.None
	UIKit.Backdrop(gui, 0.2)
	local root = UIKit.Root(gui)
	local uiScale = root:FindFirstChild("Scale") :: UIScale
	uiScale.Scale = HERD_SCALE
	root.Size = UDim2.fromScale(1 / HERD_SCALE, 1 / HERD_SCALE)
	local board = UIKit.Frame(root, "Board", UDim2.fromOffset(1000, 700))
	board.AnchorPoint = Vector2.new(0.5, 0.5)
	board.Position = UDim2.fromScale(0.5, 0.5)
	UIKit.List(board, false, 8, Enum.HorizontalAlignment.Center)
	local first = (pageIndex - 1) * HERD_PAGE_SIZE + 1
	for tierNumber = first, math.min(first + HERD_PAGE_SIZE - 1, #GOD_ORDER) do
		local god = GOD_ORDER[tierNumber]
		local herd = Herds.ByGod[god]
		local row = UIKit.Frame(board, god, UDim2.fromOffset(1000, 132))
		row.LayoutOrder = tierNumber
		local rowList = UIKit.List(row, true, 8, Enum.HorizontalAlignment.Center)
		rowList.VerticalAlignment = Enum.VerticalAlignment.Center
		local label = UIKit.Text(row, "GodLabel", `{tierNumber}\n{god}`, 22, Color.Snow, UDim2.fromOffset(120, 132), {
			Stroke = Color.Line,
			Wrap = true,
		})
		label.LayoutOrder = 0
		for slot, family in herd do
			local rarity = Herds.Rarities[slot]
			local look = Fleece.Rarity[rarity]
			local breed = GameConfig.Breeds[family]
			local face = UIKit.Frame(row, family, UDim2.fromOffset(136, 130), look.Hi)
			face.LayoutOrder = slot
			lit(face, look)
			UIKit.Corner(face, Fleece.CardRadius)
			UIKit.Surface(face, Color.Line, 4, Color.Line, 2)
			rays(face, 170, 0.5, 0.8)
			local view = viewport(face, "View", UDim2.new(1, -6, 1, -44))
			view.Position = UDim2.fromOffset(3, 20)
			view.ZIndex = 2
			if breed then
				show(view, buildSheep(breed), -35, 1.2, 0.08)
			end
			local name = (string.gsub(if breed then breed.DisplayName else family, " Sheep$", ""))
			local nameLabel = UIKit.Text(face, "NameLabel", name, 15, Color.Snow, UDim2.new(1, -8, 0, 18), {
				Stroke = Color.Line,
				Fit = true,
			})
			nameLabel.AnchorPoint = Vector2.new(0.5, 0)
			nameLabel.Position = UDim2.new(0.5, 0, 0, 4)
			nameLabel.ZIndex = 4
			local chip = UIKit.RarityChip(face, "RarityChip", true)
			chip.AnchorPoint = Vector2.new(0.5, 1)
			chip.Position = UDim2.new(0.5, 0, 1, -6)
			chip.ZIndex = 4
			paintChip(chip, rarity)
		end
	end
	return gui
end

-- Every Shear a Sheep build, wool style, horn and accessory on a plain white sheep, named, for picking looks.
local function buildCatalog(): ScreenGui
	local BreedBuilds = require(ReplicatedStorage.Config.BreedBuilds) :: any
	local entries: { { Name: string, Look: { [string]: any } } } = {}
	local names = {}
	for name in BreedBuilds.Builds do
		table.insert(names, name)
	end
	table.sort(names)
	for _, name in names do
		table.insert(entries, { Name = name, Look = { Build = name } })
	end
	for _, style in { "Ringlets", "Cloud", "Icicle", "Spotted" } do
		table.insert(entries, { Name = style, Look = { WoolStyle = style, WoolSpotColor = rgb(90, 90, 100) } })
	end
	for _, horn in { "SmallCurl", "BigCurl", "Spiral", "FourHorn" } do
		table.insert(entries, { Name = horn, Look = { HornStyle = horn, HornColor = rgb(150, 110, 70) } })
	end
	for _, accessory in { "Antennae", "WolfHead" } do
		table.insert(entries, { Name = accessory, Look = { Accessory = accessory } })
	end
	if ServerStorage:GetAttribute("MockCatalog") == "Extras" then
		entries = {}
		local kinds = string.split(
			"Leaf Helmet Wreath BackWings Blindfold Flame Wings Halo Crown Flower Bow Clover Mushroom Collar Bell Candle "
				.. "Moon Star Heart Bolt Trident Shield Nightcap WitchHat TopHat Antlers UnicornHorn BackSpikes Sword "
				.. "Hammer Scythe Dice Coin SunRays Cloud Wheat Grapes Apple HeadWings Potion Shades Eyeball Crystal",
			" "
		)
		for _, kind in kinds do
			table.insert(entries, { Name = kind, Look = { Extras = { { Kind = kind } } } })
		end
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.None
	UIKit.Backdrop(gui, 0.25)
	local root = UIKit.Root(gui)
	scaled(gui)
	local board = UIKit.Frame(root, "Board", UDim2.fromOffset(960, 520))
	board.AnchorPoint = Vector2.new(0.5, 0.5)
	board.Position = UDim2.fromScale(0.5, 0.5)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(88, 100)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = board
	for index, entry in entries do
		local look = Fleece.Rarity.Common
		local face = UIKit.Frame(board, entry.Name, UDim2.fromOffset(88, 100), look.Hi)
		face.LayoutOrder = index
		lit(face, look)
		UIKit.Corner(face, 10)
		local view = viewport(face, "View", UDim2.new(1, -4, 1, -18))
		view.Position = UDim2.fromOffset(2, 16)
		view.ZIndex = 2
		show(view, buildSheep(entry.Look), -35, 1.2, 0.08)
		local name = UIKit.Text(face, "NameLabel", entry.Name, 13, Color.Snow, UDim2.new(1, -6, 0, 16), {
			Stroke = Color.Line,
			Fit = true,
		})
		name.AnchorPoint = Vector2.new(0.5, 0)
		name.Position = UDim2.new(0.5, 0, 0, 2)
		name.ZIndex = 4
	end
	return gui
end

local existing = StarterGui:FindFirstChild(GUI_NAME)
if existing then
	existing:Destroy()
end
local gui = if VIEW == "Lineup"
	then buildLineup()
	elseif VIEW == "Catalog" then buildCatalog()
	elseif VIEW == "Herds" then buildHerds()
	else buildIndex()
gui.Enabled = true
fitText(gui, if VIEW == "Herds" then HERD_SCALE else SCALE)
gui.Parent = StarterGui
return `built {GUI_NAME} ({VIEW})`
