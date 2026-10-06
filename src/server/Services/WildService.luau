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
local Theme = require(ReplicatedStorage.Config.Theme)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The gods' wild lambs: four spawns a tier, each rolled once (fleece, hidden weight, and the adult size it will grow
-- to) and kept until someone delivers it. A theft: hold Interact on a lamb, it goes over your head, its god gives chase
-- (GodService), and you either carry it into your own plot and put it down there (Remotes.PutDown: anywhere inside
-- your fence) or lose it. A thief who's caught or dies on the ramp drops it where they were: anyone can steal it from
-- there (its god then chases them), and it goes back to its pasture after DropSeconds. Giving up, falling off the world
-- or leaving puts it straight back. New players also get one private, light, ordinary tier 1 lamb for the tutorial.
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
	ReturnAt: number, -- os.clock() a dropped lamb goes back to its pasture, 0 when it's there
	Owner: Player?, -- a tutorial lamb's only thief
}

-- A merged lamb from the Merge Shrine, already its carrier's (ShrineService): its id in their flock and its model.
type Lamb = {
	Id: string,
	Model: Model,
}

-- One of the two: a stolen lamb (Spawn) or a merged lamb carried home from the shrine (Lamb).
type Carry = {
	Spawn: Spawn?,
	Lamb: Lamb?,
	Started: number,
}

local CARRY_CHECK = 0.1
-- How a theft ended -> whether the lamb is left lying where the thief was.
local DROPS: { [string]: boolean } = { Caught = true, Died = true }
local ANNOUNCED_RARITY = 5 -- Legendary and Mythic lambs are announced, like Royal fleeces
local FALL_Y = -50

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local spawns: { Spawn } = {}
local tutorialSpawns: { [Player]: Spawn } = {}
local carries: { [Player]: Carry } = {}
-- The plot a thief is standing in that isn't theirs, so they're told once each time they walk into one.
local wrongPlot: { [Player]: Instance } = {}
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
	local family = Economy.RollFamily(random, Olympus.Tiers[tier])
	return { Family = family, Rarity = rarity, Weight = weight, Size = size }
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

-- The inspection card over a wild lamb: its family's rarity, its name and what it will earn grown up. Its weight stays
-- hidden.
local function card(model: Model, rolled: Roll)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local sheep = asSheep(rolled)
	local low, high = Economy.FutureRange(sheep)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Card"
	billboard.Size = UDim2.fromOffset(190, 64)
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
	local kind = Economy.FamilyRarities[Economy.FamilyRarity(rolled.Family)].Name
	line(string.upper(kind), 18, Theme.Fleece.Rarity[kind].Hi)
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

-- Puts the lamb down, ready to steal: at its pasture spot, or at `at` (dropped by a thief).
local function place(spawn: Spawn, at: CFrame?)
	local model = spawn.Model
	if model then
		registry.SheepService:Place(model, at or spawn.At)
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
	-- Clients graze it like a lamb in a pen (AnimController).
	model:SetAttribute("Lamb", true)
	card(model, rolled)
	-- Just the action: the lamb's card over it already names it.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom -- drawn by each client (PromptController)
	prompt.ActionText = "Steal"
	prompt.ObjectText = ""
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

-- A Royal fleece, or a Legendary or Mythic family: "A Mythic King of Olympus Lamb appeared in Zeus's pasture!"
local function announce(spawn: Spawn)
	local tier = Olympus.Tiers[spawn.Tier]
	local rolled = spawn.Roll
	local kind = Economy.FamilyRarity(rolled.Family)
	local words = Economy.Name(asSheep(rolled))
	if kind >= ANNOUNCED_RARITY then
		words = `{Economy.FamilyRarities[kind].Name} {words}`
	end
	for _, player in Players:GetPlayers() do
		local reached = player:GetAttribute("ClimbTier")
		if type(reached) == "number" and reached >= spawn.Tier then
			notify(player, `A {words} appeared in {tier.God}'s pasture!`, "Rare", "Reveal")
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
	player:SetAttribute("InPen", nil)
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
	wrongPlot[player] = nil
	clearAttributes(player)
	registry.GodService:Release(player)
	Remotes.Chase:Fire(player, nil, nil)
	return carry
end

-- Where a thief who lost their lamb drops it: on the floor under them, if they're on the ramp.
local function dropSpot(player: Player): CFrame?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return nil
	end
	local position = root.Position
	if position.X < Olympus.SafeLineX or math.abs(position.Y - Mountain.RampY(position.X)) > 18 then
		return nil
	end
	return floorAt(position.X, Mountain.ClampLane(position.Z))
end

-- A theft that didn't make it home: the same lamb, rolls and all, lies where the thief was caught or died, or goes
-- back to its pasture. A merged lamb from the Merge Shrine is its carrier's already, so it goes to their pen instead.
function WildService.Fail(_self: any, player: Player, reason: string)
	local drop = if DROPS[reason] then dropSpot(player) else nil
	local carry = endCarry(player)
	if not carry then
		return
	end
	local lamb = carry.Lamb
	if lamb then
		lamb.Model:Destroy()
		registry.FlockService:ShrineArrive(player, lamb.Id, "Your lamb went to your pen")
		return
	end
	local spawn = carry.Spawn :: Spawn
	local tier = Olympus.Tiers[spawn.Tier]
	if spawn.Owner then
		drop = nil
	end
	place(spawn, drop)
	spawn.ReturnAt = if drop then os.clock() + GameConfig.Theft.DropSeconds else 0
	if reason == "Caught" then
		notify(player, `{tier.God} punched you! You dropped the lamb`, "Bad", "Denied")
		registry.MountainService:Punch(player)
	elseif reason == "Returned" then
		notify(player, `The lamb ran back to {tier.God}`, "Bad", "Notice")
	elseif reason == "Blocked" then
		notify(player, "The lamb slipped away", "Bad", "Denied")
	end
end

-- Put down in the thief's pen at `at`: the lamb joins their flock, hopping down from where it was held.
local function deliver(player: Player, carry: Carry, at: CFrame)
	if not endCarry(player) then
		return
	end
	local lamb = carry.Lamb
	if lamb then
		local heldAt = lamb.Model:GetPivot()
		lamb.Model:Destroy()
		registry.FlockService:ShrineArrive(player, lamb.Id, nil, at, heldAt)
		return
	end
	local spawn = carry.Spawn :: Spawn
	local heldAt: CFrame? = nil
	if spawn.Model then
		heldAt = spawn.Model:GetPivot()
		spawn.Model:Destroy()
		spawn.Model = nil
		spawn.Prompt = nil
	end
	registry.FlockService:Deliver(player, spawn.Roll, at, heldAt)
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
	spawn.ReturnAt = 0
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
		ReturnAt = 0,
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

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Thieves who fell off the world lose the lamb; one in their own pen may put it down (InPen, for their client's
-- prompt and objective); one in someone else's is told so.
local function checkCarriers()
	for player in carries do
		local root = rootOf(player)
		if not root then
			continue
		end
		if root.Position.Y < FALL_Y then
			WildService:Fail(player, "Fell")
			continue
		end
		local here = registry.PlotService:PenAt(root.Position, 0)
		local home = here ~= nil and here == registry.PlotService:GetPlot(player)
		if player:GetAttribute("InPen") ~= (if home then true else nil) then
			player:SetAttribute("InPen", if home then true else nil)
		end
		local elsewhere = if here and not home then here.Model else nil
		if elsewhere ~= wrongPlot[player] then
			wrongPlot[player] = elsewhere
			if elsewhere then
				notify(player, "That's not your plot!", "Bad", "Denied")
			end
		end
	end
end

-- The thief asked to put their lamb down (their client shows the prompt inside their own fence): on the floor just in
-- front of them, kept inside the fence. The server's view of them may be a step behind, so a little outside counts.
local function putDown(player: Player)
	local carry = carries[player]
	local root = rootOf(player)
	local plot = registry.PlotService:GetPlot(player)
	if not carry or not root or not plot then
		return
	end
	if registry.PlotService:PenAt(root.Position, -GameConfig.Theft.PutDownSlack) ~= plot then
		notify(player, "Bring it inside your own fence first", "Bad", "Denied")
		return
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = if look.Magnitude > 1e-3 then look.Unit else Vector3.xAxis
	local ahead = root.Position + look * GameConfig.Theft.PutDownAhead
	local spot = registry.PlotService:ClampToPen(plot, ahead, GameConfig.SheepMotion.WanderFenceGap)
	-- Facing the way its thief faced, as if set down in front of them.
	deliver(player, carry, CFrame.lookAt(spot, spot + look))
end

local function refill()
	local now = os.clock()
	for _, spawn in spawns do
		if spawn.State == "Ready" and spawn.ReturnAt > 0 and now >= spawn.ReturnAt then
			spawn.ReturnAt = 0
			place(spawn)
		elseif spawn.State == "Empty" and now >= spawn.RefillAt then
			spawn.Roll = roll(spawn.Tier)
			fill(spawn)
			if spawn.Roll.Rarity >= 3 or Economy.FamilyRarity(spawn.Roll.Family) >= ANNOUNCED_RARITY then
				announce(spawn)
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
					ReturnAt = 0,
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
		wrongPlot[player] = nil
	end)
	trove:Add(Remotes.ReturnSheep:Connect(function(player: Player)
		WildService:Fail(player, "Returned")
	end))
	trove:Add(Remotes.PutDown:Connect(putDown))

	local sinceCheck = 0
	local sinceRefill = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		sinceCheck += dt
		sinceRefill += dt
		if sinceCheck >= CARRY_CHECK then
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
		if carry.Spawn and carry.Spawn.Tier == tier then
			table.insert(list, player)
		end
	end
	return list
end

-- A merged lamb from the Merge Shrine (ShrineService) goes over its owner's head to be carried home like a stolen one,
-- with no god after it. False if they can't take it now.
function WildService.CarryLamb(_self: any, player: Player, model: Model, id: string, weight: number): boolean
	if carries[player] then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local family = model:GetAttribute("Family")
	local tier = if type(family) == "string" then Olympus.ByFamily[family] else nil
	if not character or not humanoid or humanoid.Health <= 0 or not tier then
		return false
	end
	if not registry.SheepService:Carry(model, character) then
		return false
	end
	model.Parent = carriedFolder
	carries[player] = { Lamb = { Id = id, Model = model }, Started = os.clock() }
	player:SetAttribute("CarriedFamily", family)
	player:SetAttribute("CarriedScale", model:GetScale())
	player:SetAttribute("CarryTier", tier.Tier)
	player:SetAttribute("CarryWeight", weight)
	player:SetAttribute("Carrying", true)
	return true
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
