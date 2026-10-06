--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local Store = require(ReplicatedStorage.Config.Store)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- Coin purchases (the next stair walker level, the next pen slot, trails in order) and the hub's three stations: the
-- map's two stalls become the Shop and the Sell Stall, and the Merge Shrine's prompt (ShrineService builds the shrine)
-- stands on its front steps. A station's prompt
-- carries an Opens attribute; the client opens that screen (PromptController). Trails train faster and show on the
-- player as a coloured trail. Each stair walker's sign upgrades it straight away, for cash or Robux (the Robux store's
-- walker products, through StoreService).
local ShopService = { Name = "ShopService" }

local SHRINE_PROMPT = CFrame.new(0, 4, -12) -- from the shrine's centre: on the front of its dais
local TRAIL_NAME = "PlayerTrail"

local registry: Lifecycle.Registry = {}
local trove = Trove.new()

local function anchorPart(parent: Instance, name: string, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function station(
	parent: Instance,
	name: string,
	at: CFrame,
	opens: string,
	action: string,
	title: string,
	color: Color3
)
	local anchor = anchorPart(parent, name, at)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StationPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom -- drawn by each client (PromptController)
	prompt:SetAttribute("PromptKind", "Action")
	-- The verb only: the sign over the stall names it.
	prompt.ActionText = action
	prompt.ObjectText = ""
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt:SetAttribute("Opens", opens)
	prompt.Parent = anchor
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(260, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 14, 0)
	billboard.MaxDistance = 220
	billboard.LightInfluence = 0
	billboard.Parent = anchor
	local words = Instance.new("TextLabel")
	words.BackgroundTransparency = 1
	words.Size = UDim2.fromScale(1, 1)
	words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
	words.TextScaled = true
	words.TextColor3 = color
	words.Text = title
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = words
	words.Parent = billboard
end

local function stallFront(model: Model): CFrame
	local cframe, size = model:GetBoundingBox()
	return CFrame.new(cframe.Position.X - size.X / 2 - 2, 63, cframe.Position.Z)
end

local function applyTrail(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local old = root:FindFirstChild(TRAIL_NAME)
	if old then
		old:Destroy()
	end
	for _, name in { "TrailTop", "TrailBottom" } do
		local attachment = root:FindFirstChild(name)
		if attachment then
			attachment:Destroy()
		end
	end
	local data = registry.DataService:GetData(player)
	local trail = data and Economy.Trail(data.Trail)
	if not trail then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, 0.8, 0.4)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -1.8, 0.4)
	bottom.Parent = root
	local effect = Instance.new("Trail")
	effect.Name = TRAIL_NAME
	effect.Attachment0 = top
	effect.Attachment1 = bottom
	effect.Color = ColorSequence.new(trail.Color)
	effect.Transparency = NumberSequence.new(0.2, 1)
	effect.Lifetime = 0.6
	effect.LightEmission = 0.5
	effect.Parent = root
end

local function buy(player: Player, item: string, which: string?): (boolean, string?)
	local data = registry.DataService:GetData(player)
	if not data then
		return false, "Still loading"
	end
	if item == "Walker" then
		local cost = Economy.WalkerCost(data.WalkerLevel)
		if not cost then
			return false, "Your stair walker is maxed"
		end
		if not registry.DataService:AdjustCoins(player, -cost) then
			return false, `Need {Format.Short(cost - data.Coins)} more cash`
		end
		data.WalkerLevel += 1
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		return true,
			`Stair walker level {data.WalkerLevel + 1}: +{Format.Short(Economy.WalkerRate(data.WalkerLevel))} Climbing/s`
	elseif item == "PenSlot" then
		local slot = data.PenSlots + 1
		local cost = Economy.PenCost(slot)
		if not cost then
			return false, "Your pen is as big as it gets"
		end
		if not registry.DataService:AdjustCoins(player, -cost) then
			return false, `Need {Format.Short(cost - data.Coins)} more cash`
		end
		data.PenSlots = slot
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		return true, "One more sheep can earn"
	elseif item == "Trail" then
		local trail = Economy.Trail(which)
		if not trail then
			return false, "No such trail"
		end
		if data.Trails[trail.Id] then
			data.Trail = if data.Trail == trail.Id then "" else trail.Id
		else
			local index = table.find(Economy.Trails, trail) or 1
			local previous = Economy.Trails[index - 1]
			if previous and not data.Trails[previous.Id] then
				return false, `Buy the {previous.Name} first`
			end
			if not registry.DataService:AdjustCoins(player, -trail.Cost) then
				return false, `Need {Format.Short(trail.Cost - data.Coins)} more cash`
			end
			data.Trails[trail.Id] = true
			data.Trail = trail.Id
		end
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		applyTrail(player)
		return true, if data.Trail == trail.Id then `{trail.Name}: x{trail.Multiplier} training` else "Trail off"
	end
	return false, "Unknown item"
end

function ShopService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function ShopService.Start(_self: any)
	local folder = Instance.new("Folder")
	folder.Name = "Stations"
	folder.Parent = workspace
	trove:Add(folder)
	local base = workspace:FindFirstChild("Base")
	local shops = base and base:FindFirstChild("Shop")
	local stalls: { Model } = {}
	if shops then
		for _, child in shops:GetChildren() do
			if child:IsA("Model") then
				table.insert(stalls, child)
			end
		end
	end
	table.sort(stalls, function(a: Model, b: Model)
		return a:GetBoundingBox().Position.Z > b:GetBoundingBox().Position.Z
	end)
	local shopAt = if stalls[1] then stallFront(stalls[1]) else CFrame.new(275, 63, 205)
	local sellAt = if stalls[2] then stallFront(stalls[2]) else CFrame.new(275, 63, 175)
	station(folder, "ShopStation", shopAt, "Shop", "Shop", "SHOP", Color3.fromRGB(255, 214, 90))
	station(folder, "SellStation", sellAt, "Sell", "Sell", "SELL STALL", Color3.fromRGB(140, 235, 120))
	station(
		folder,
		"MergeStation",
		GameConfig.Shrine.At * SHRINE_PROMPT,
		"Merge",
		"Merge",
		"MERGE SHRINE",
		Color3.fromRGB(200, 160, 255)
	)

	Remotes.Buy:Handle(function(player: Player, item: string, which: string?)
		return buy(player, item, which)
	end)
	for _, plot in registry.PlotService:Plots() do
		local walker = plot.Pieces.Walker
		trove:Connect(walker.CoinPrompt.Triggered, function(player: Player)
			if plot.Owner ~= player then
				return
			end
			local ok, message = buy(player, "Walker")
			Remotes.Notify:Fire(player, message or "", if ok then "Good" else "Bad", if ok then "Upgrade" else "Denied")
		end)
		trove:Connect(walker.RobuxPrompt.Triggered, function(player: Player)
			local data = registry.DataService:GetData(player)
			if plot.Owner ~= player or not data or not Economy.WalkerCost(data.WalkerLevel) then
				return
			end
			-- The store's own walker products (Config/Store), so one dialog at a time and the price ladder are kept.
			local ok, message = registry.StoreService:Request(player, "Walker")
			if message then
				Remotes.Notify:Fire(player, message, if ok then "Good" else "Bad", if ok then "Upgrade" else "Denied")
			end
		end)
	end
	trove:Add(registry.PurchaseService.Granted:Connect(function(player: Player, key: string)
		if Store.Split(key) == "Walker" then
			local data = registry.DataService:GetData(player)
			local level = if data then data.WalkerLevel + 1 else 0
			Remotes.Notify:Fire(player, `Stair walker level {level}!`, "Good", "Upgrade")
		end
	end))
	local function watch(player: Player)
		trove:Connect(player.CharacterAdded, function(character: Model)
			character:WaitForChild("HumanoidRootPart", 10)
			applyTrail(player)
		end)
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	trove:Connect(Players.PlayerAdded, watch)
	trove:Add(registry.DataService:ObserveLoaded(function(player: Player)
		applyTrail(player)
	end))
end

function ShopService.Destroy(_self: any)
	trove:Clean()
end

return ShopService
