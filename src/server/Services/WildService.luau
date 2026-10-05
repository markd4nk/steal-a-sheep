--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Mountain = require(ReplicatedStorage.Utils.Mountain)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The gods' wild lambs: four spawns a tier, each rolled once (fleece, burden, and the adult size it will grow to) and
-- kept until someone delivers it; a failed theft puts the same lamb back. A theft: hold Interact on a lamb, it goes
-- over your head, its god gives chase (GodService), and you either reach your own delivery pad or lose it (caught,
-- dead, reset, left, gave up, blocked at a gate). New players also get one private, Light, ordinary Demeter lamb of
-- their own for the tutorial.
local WildService = { Name = "WildService" }

type Roll = {
	Family: string,
	Rarity: number,
	Weight: number,
	Size: number,
	Tutorial: boolean?,
}

type Spawn = {
	Tier: number,
	At: CFrame,
	State: "Ready" | "Carried" | "Empty",
	Roll: Roll,
	Model: Model?,
	Prompt: ProximityPrompt?,
	Carrier: Player?,
	RefillAt: number,
	Owner: Player?, -- a tutorial lamb's only thief
}

type Carry = {
	Spawn: Spawn,
	Started: number,
}

local DELIVERY_CHECK = 0.1
local WRONG_PLOT_EVERY = 3
local FALL_Y = -50

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local spawns: { Spawn } = {}
local tutorialSpawns: { [Player]: Spawn } = {}
local carries: { [Player]: Carry } = {}
local wrongPlotAt: { [Player]: number } = {}
local random = Random.new()
local wildFolder: Folder? = nil
local carriedFolder: Folder? = nil
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude

local function notify(player: Player, message: string, kind: string, sound: string?)
	Remotes.Notify:Fire(player, message, kind, sound)
end

local function roll(tier: number): Roll
	local rarity, weight, size = Economy.RollWild(random)
	return { Family = Olympus.Tiers[tier].Family, Rarity = rarity, Weight = weight, Size = size }
end

local function asSheep(rolled: Roll): Economy.Sheep
	return {
		Id = "",
		Family = rolled.Family,
		Rarity = rolled.Rarity,
		Weight = rolled.Weight,
		Size = rolled.Size,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = 0,
		Pinned = false,
		Tutorial = rolled.Tutorial,
	}
end

-- The inspection card over a wild lamb: its name and what it will earn grown up. Its weight stays hidden.
local function card(model: Model, rolled: Roll)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local sheep = asSheep(rolled)
	local low, high = Economy.FutureRange(sheep)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Card"
	billboard.Size = UDim2.fromOffset(190, 46)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	billboard.MaxDistance = 45
	billboard.LightInfluence = 0
	billboard.Parent = root
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Parent = billboard
	local function line(text: string, height: number, color: Color3)
		local words = Instance.new("TextLabel")
		words.BackgroundTransparency = 1
		words.Size = UDim2.new(1, 0, 0, height)
		words.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		words.TextScaled = true
		words.TextColor3 = color
		words.Text = text
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = words
		words.Parent = billboard
	end
	local rarity = Economy.Rarities[rolled.Rarity]
	line(Economy.Name(sheep), 24, if rolled.Rarity > 1 then rarity.Color else Color3.new(1, 1, 1))
	line(`Grows to +{Format.Rate(low)}-{Format.Rate(high)}/s`, 20, Color3.fromRGB(190, 255, 90))
end

local function setCard(model: Model?, visible: boolean)
	local root = model and model.PrimaryPart
	local found = root and root:FindFirstChild("Card")
	if found and found:IsA("BillboardGui") then
		found.Enabled = visible
	end
end

local function place(spawn: Spawn)
	local model = spawn.Model
	if model then
		registry.SheepService:Place(model, spawn.At)
		model.Parent = wildFolder
		setCard(model, true)
	end
	local prompt = spawn.Prompt
	if prompt then
		prompt.Enabled = true
	end
	spawn.State = "Ready"
	spawn.Carrier = nil
end

local tryPickUp: (player: Player, spawn: Spawn) -> ()

local function fill(spawn: Spawn)
	if spawn.Model then
		spawn.Model:Destroy()
		spawn.Model = nil
		spawn.Prompt = nil
	end
	local rolled = spawn.Roll
	local scale = GameConfig.SheepSize * Economy.LambScale(rolled.Weight)
	local model = registry.SheepService:Build(rolled.Family, rolled.Rarity, scale)
	if not model then
		return
	end
	model.Name = `Wild_{rolled.Family}`
	model:SetAttribute("Tier", spawn.Tier)
	card(model, rolled)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = Economy.Name(asSheep(rolled))
	prompt.HoldDuration = GameConfig.Theft.HoldSeconds
	prompt.MaxActivationDistance = GameConfig.Theft.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	if spawn.Owner then
		-- Clients hide another player's tutorial lamb's prompt (PromptController); the server refuses it anyway.
		prompt:SetAttribute("OwnerId", spawn.Owner.UserId)
	end
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player: Player)
		tryPickUp(player, spawn)
	end)
	spawn.Model = model
	spawn.Prompt = prompt
	place(spawn)
end

local function announceRoyal(spawn: Spawn)
	local tier = Olympus.Tiers[spawn.Tier]
	for _, player in Players:GetPlayers() do
		local reached = player:GetAttribute("ClimbTier")
		if type(reached) == "number" and reached >= spawn.Tier then
			notify(player, `A Royal {tier.FamilyName} lamb appeared in {tier.God}'s pasture!`, "Rare", "Reveal")
		end
	end
end

local function floorAt(x: number, z: number): CFrame
	local y = Mountain.Floor(x, z, groundParams)
	-- Facing downhill (towards the plots), turned a little either way.
	return CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(90 + random:NextNumber(-35, 35)), 0)
end

local function clearAttributes(player: Player)
	player:SetAttribute("Carrying", false)
	player:SetAttribute("CarriedFamily", nil)
	player:SetAttribute("CarriedScale", nil)
	player:SetAttribute("CarryTier", nil)
	player:SetAttribute("CarryWeight", nil)
	player:SetAttribute("CarryTutorial", nil)
end

local function endCarry(player: Player): Carry?
	local carry = carries[player]
	if not carry then
		return nil
	end
	carries[player] = nil
	clearAttributes(player)
	registry.GodService:Release(player)
	Remotes.Chase:Fire(player, nil, nil)
	return carry
end

-- A theft that didn't make it home: the same lamb goes back to its spawn, rolls and all.
function WildService.Fail(_self: any, player: Player, reason: string)
	local carry = endCarry(player)
	if not carry then
		return
	end
	local spawn = carry.Spawn
	local tier = Olympus.Tiers[spawn.Tier]
	place(spawn)
	if reason == "Caught" then
		notify(player, `{tier.God} took their lamb back!`, "Bad", "Denied")
		registry.PlotService:SendHome(player)
	elseif reason == "Returned" then
		notify(player, `The lamb ran back to {tier.God}`, "Bad", "Notice")
	elseif reason == "Blocked" then
		notify(player, "The lamb slipped away", "Bad", "Denied")
	end
end

local function deliver(player: Player, carry: Carry)
	if not endCarry(player) then
		return
	end
	local spawn = carry.Spawn
	if spawn.Model then
		spawn.Model:Destroy()
		spawn.Model = nil
		spawn.Prompt = nil
	end
	registry.FlockService:Deliver(player, spawn.Roll)
	if spawn.Owner then
		-- The tutorial lamb is a one-off.
		tutorialSpawns[spawn.Owner] = nil
		return
	end
	spawn.State = "Empty"
	spawn.RefillAt = os.clock() + GameConfig.Theft.RefillSeconds
end

tryPickUp = function(player: Player, spawn: Spawn)
	if spawn.State ~= "Ready" or not spawn.Model then
		notify(player, "Someone got there first!", "Bad", "Denied")
		return
	end
	if spawn.Owner and spawn.Owner ~= player then
		notify(player, "That lamb is someone else's", "Bad", "Denied")
		return
	end
	if carries[player] then
		notify(player, "You're already carrying one", "Bad", "Denied")
		return
	end
	local data = registry.DataService:GetData(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not data or not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not registry.PlotService:GetPlot(player) then
		return
	end
	if registry.FlockService:Count(player) >= GameConfig.Theft.InventoryLimit then
		notify(player, "Your flock is full: merge or sell first", "Bad", "Denied")
		return
	end
	local model = spawn.Model :: Model
	if (model:GetPivot().Position - root.Position).Magnitude > GameConfig.Theft.PromptDistance + 6 then
		return
	end
	spawn.State = "Carried"
	spawn.Carrier = player
	if spawn.Prompt then
		spawn.Prompt.Enabled = false
	end
	setCard(model, false)
	if not registry.SheepService:Carry(model, character) then
		place(spawn)
		return
	end
	model.Parent = carriedFolder
	carries[player] = { Spawn = spawn, Started = os.clock() }
	local rolled = spawn.Roll
	player:SetAttribute("CarriedFamily", rolled.Family)
	player:SetAttribute("CarriedScale", model:GetScale())
	player:SetAttribute("CarryTier", spawn.Tier)
	player:SetAttribute("CarryWeight", rolled.Weight)
	player:SetAttribute("CarryTutorial", if spawn.Owner then true else nil)
	player:SetAttribute("Carrying", true)
	local tier = Olympus.Tiers[spawn.Tier]
	Remotes.Chase:Fire(player, tier.God, spawn.Tier)
	registry.GodService:Chase(spawn.Tier, player, spawn.Owner ~= nil)
end

local function makeTutorialLamb(player: Player)
	if tutorialSpawns[player] then
		return
	end
	local tier = Olympus.Tiers[1]
	local x = tier.XStart + (tier.XEnd - tier.XStart) * 0.42
	local spawn: Spawn = {
		Tier = 1,
		At = floorAt(x, Olympus.LaneMiddleZ),
		State = "Empty",
		Roll = { Family = tier.Family, Rarity = 1, Weight = 1, Size = 1, Tutorial = true },
		Model = nil,
		Prompt = nil,
		Carrier = nil,
		RefillAt = 0,
		Owner = player,
	}
	tutorialSpawns[player] = spawn
	fill(spawn)
end

local function dropTutorialLamb(player: Player)
	local spawn = tutorialSpawns[player]
	if spawn then
		tutorialSpawns[player] = nil
		if spawn.Model then
			spawn.Model:Destroy()
		end
	end
end

local function checkCarriers()
	for player, carry in carries do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			continue
		end
		if root.Position.Y < FALL_Y then
			WildService:Fail(player, "Fell")
			continue
		end
		local plot = registry.PlotService:GetPlot(player)
		for _, other in registry.PlotService:Plots() do
			local pad = other.Pieces.Delivery
			local offset = root.Position - pad.Position
			if
				Vector2.new(offset.X, offset.Z).Magnitude <= GameConfig.Theft.DeliverStuds
				and math.abs(offset.Y) < 10
			then
				if other == plot then
					deliver(player, carry)
				elseif os.clock() - (wrongPlotAt[player] or 0) > WRONG_PLOT_EVERY then
					wrongPlotAt[player] = os.clock()
					notify(player, "That's not your plot! Yours has your name over the gate.", "Bad", "Denied")
				end
				break
			end
		end
	end
end

local function refill()
	local now = os.clock()
	for _, spawn in spawns do
		if spawn.State == "Empty" and now >= spawn.RefillAt then
			spawn.Roll = roll(spawn.Tier)
			fill(spawn)
			if spawn.Roll.Rarity >= 3 then
				announceRoyal(spawn)
			end
		end
	end
end

local function watchCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			WildService:Fail(player, "Died")
		end)
	end
end

function WildService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function WildService.Start(_self: any)
	local wild = Instance.new("Folder")
	wild.Name = "WildSheep"
	wild.Parent = workspace
	wildFolder = wild
	trove:Add(wild)
	local carried = Instance.new("Folder")
	carried.Name = "CarriedSheep"
	carried.Parent = workspace
	carriedFolder = carried
	trove:Add(carried)
	groundParams.FilterDescendantsInstances = { wild, carried }

	task.spawn(function()
		-- Building 48 sheep takes a moment; the sheep kit loads in SheepService.Start.
		for tierNumber = 1, Olympus.Count do
			for _, spot in Mountain.PastureSpots(tierNumber) do
				local spawn: Spawn = {
					Tier = tierNumber,
					At = floorAt(spot.X, spot.Y),
					State = "Empty",
					Roll = roll(tierNumber),
					Model = nil,
					Prompt = nil,
					Carrier = nil,
					RefillAt = 0,
					Owner = nil,
				}
				table.insert(spawns, spawn)
				fill(spawn)
			end
			task.wait()
		end
	end)

	trove:Add(registry.DataService:ObserveLoaded(function(player: Player, data: any)
		if data.Tutorial == 0 and next(data.Sheep) == nil then
			makeTutorialLamb(player)
		end
	end))
	-- The tutorial lamb is for a first delivery; any first delivery ends it.
	trove:Add(registry.FlockService.Delivered:Connect(function(player: Player)
		local spawn = tutorialSpawns[player]
		if spawn and spawn.State ~= "Carried" then
			dropTutorialLamb(player)
		end
	end))
	trove:Add(registry.GodService.Caught:Connect(function(player: Player)
		WildService:Fail(player, "Caught")
	end))
	local function watch(player: Player)
		trove:Connect(player.CharacterAdded, function(character: Model)
			task.spawn(watchCharacter, player, character)
		end)
		trove:Connect(player.CharacterRemoving, function()
			WildService:Fail(player, "Reset")
		end)
		if player.Character then
			task.spawn(watchCharacter, player, player.Character)
		end
	end
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	trove:Connect(Players.PlayerAdded, watch)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		WildService:Fail(player, "Left")
		dropTutorialLamb(player)
		wrongPlotAt[player] = nil
	end)
	trove:Add(Remotes.ReturnSheep:Connect(function(player: Player)
		WildService:Fail(player, "Returned")
	end))

	local sinceCheck = 0
	local sinceRefill = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceCheck += dt
		sinceRefill += dt
		if sinceCheck >= DELIVERY_CHECK then
			sinceCheck = 0
			checkCarriers()
		end
		if sinceRefill >= 1 then
			sinceRefill = 0
			refill()
		end
	end)
end

function WildService.Destroy(_self: any)
	trove:Clean()
end

function WildService.IsCarrying(_self: any, player: Player): boolean
	return carries[player] ~= nil
end

-- The players carrying a lamb from `tier`, for its god.
function WildService.CarriersFrom(_self: any, tier: number): { Player }
	local list: { Player } = {}
	for player, carry in carries do
		if carry.Spawn.Tier == tier then
			table.insert(list, player)
		end
	end
	return list
end

-- Studio tests: the first ready spawn of a tier, so a test can steal without walking there.
function WildService.DebugSteal(_self: any, player: Player, tier: number): boolean
	local character = player.Character
	if not character then
		return false
	end
	for _, spawn in spawns do
		if spawn.Tier == tier and spawn.State == "Ready" and spawn.Model then
			local at = spawn.At * CFrame.new(0, 4, 3)
			registry.MountainService:Teleported(player, at.Position.X)
			character:PivotTo(at)
			tryPickUp(player, spawn)
			return carries[player] ~= nil
		end
	end
	return false
end

return WildService
