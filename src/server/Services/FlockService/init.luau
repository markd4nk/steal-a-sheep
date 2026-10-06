--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Store = require(ReplicatedStorage.Config.Store)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Pens = require(script.Pens)
local Roster = require(script.Roster)

type Sheep = Economy.Sheep

-- A player's flock: delivering stolen lambs (put down in the pen), how many the pen holds, the sheep living in the
-- plot (Pens: where each stands and strolls), income and growth every second, offline credit on join, the Sheepdex's
-- first-delivery rewards, Equip Best, locking, selling, the Merge Shrine's trade (ShrineService runs the shrine), and
-- the snapshot each client shows (Remotes.State). Every change to the flock and its coins happens here in one go, with
-- no yields, so a save never catches half of it.
local FlockService = {
	Name = "FlockService",
	-- A sheep reached its owner's plot: (player, the new sheep).
	Delivered = Signal.new() :: Signal.Signal<Player, Sheep>,
}

export type Wild = {
	Family: string,
	Rarity: number,
	Weight: number,
	Size: number,
	Tutorial: boolean?,
}

-- A sheep about to appear in the pen: where its owner put it down and where it hops in from (their head), or
-- neither for one coming out of storage, which hops in where it lived before.
type Arrival = {
	At: CFrame?,
	From: CFrame?,
}

type PlayerState = {
	Shown: { [string]: Pens.Shown },
	Arrivals: { [string]: Arrival },
	Dirty: boolean,
	Offline: { Coins: number, Matured: number }?,
	ClimbTier: number,
}

local TICK = 1
local WANDER_CHECK = 0.25 -- seconds between passes over every penned sheep: strolls due, and where strollers are
local PEN_FOLDER = "PenSheep"
local HOP_IN_HEIGHT = 3 -- studs above its spot a sheep out of storage hops in from
local PASS_WAIT = 15 -- seconds the offline credit waits for StoreService to learn the player's passes

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local states: { [Player]: PlayerState } = {}
local penFolder: Folder? = nil
local random = Random.new()

local function dataOf(player: Player): any
	return registry.DataService:GetData(player)
end

local function notify(player: Player, message: string, kind: string, sound: string?)
	Remotes.Notify:Fire(player, message, kind, sound)
end

-- The 2x Money and 2x Growth passes (StoreService sets their attributes once it knows): what income and growth are
-- multiplied by for this player.
local function boosts(player: Player): (number, number)
	local money = if player:GetAttribute(Store.PassAttribute("DoubleMoney")) == true then 2 else 1
	local growth = if player:GetAttribute(Store.PassAttribute("DoubleGrowth")) == true then 2 else 1
	return money, growth
end

local function markDirty(player: Player)
	local state = states[player]
	if state then
		state.Dirty = true
	end
end

-- One sheep as its owner's client sees it: the numbers already worked out, a lamb's size kept secret.
local function view(sheep: Sheep, penSlots: number, best: number, money: number): { [string]: any }
	local adult = Economy.IsAdult(sheep)
	local low, high = Economy.FutureRange(sheep, best)
	return {
		Id = sheep.Id,
		Family = sheep.Family,
		Rarity = sheep.Rarity,
		Weight = sheep.Weight,
		Size = if adult then sheep.Size else 0,
		Rank = sheep.Rank,
		Locked = sheep.Locked,
		Slot = if Roster.IsEquipped(sheep, penSlots) then sheep.Slot else 0,
		Pinned = sheep.Pinned,
		Adult = adult,
		Growth = math.clamp(sheep.Grown / Economy.GrowthSeconds(sheep), 0, 1),
		Income = Economy.Income(sheep, best) * money,
		Low = low * money,
		High = high * money,
		Sell = Economy.SellValue(sheep, best),
		Name = Economy.Name(sheep),
		Robux = if Economy.IsRobuxSheep(sheep.Family) then true else nil,
		AtShrine = sheep.Shrine == true,
	}
end

function FlockService.Snapshot(_self: any, player: Player): { [string]: any }
	local data = dataOf(player)
	if not data then
		return {}
	end
	local best = Economy.BestIncome(data.Sheep)
	local money = boosts(player)
	local flock: { [string]: any } = {}
	for id, sheep in data.Sheep do
		flock[id] = view(sheep, data.PenSlots, best, money)
	end
	local state = states[player]
	local income = Roster.Income(data.Sheep, data.PenSlots)
	local giftCoins, giftClimb = Economy.GiftReward(data.WalkerLevel, income)
	-- The daily gifts' week as the menu shows it: each day's cash or Climbing for this player now, and whose lamb Day 4
	-- gives.
	local amounts: { number } = {}
	for day in Economy.DailyWeek do
		amounts[day] = Economy.DailyAmount(day, income, data.WalkerLevel)
	end
	local daily = {
		Day = data.DailyDay,
		ReadyAt = if data.DailyAt > 0 then data.DailyAt + Economy.DailyCooldown else 0,
		Amounts = amounts,
		LambFamily = Olympus.Tiers[Economy.HighestStolen(data.Deliveries)].Family,
	}
	return {
		Sheep = flock,
		Count = Roster.Count(data.Sheep),
		Limit = GameConfig.Theft.InventoryLimit,
		PenSlots = data.PenSlots,
		WalkerLevel = data.WalkerLevel,
		ClimbPower = data.ClimbPower,
		Trails = table.clone(data.Trails),
		Trail = data.Trail,
		Deliveries = table.clone(data.Deliveries),
		Dex = table.clone(data.Dex),
		DexClaimed = table.clone(data.DexClaimed),
		HerdGifts = table.clone(data.HerdGifts),
		Tutorial = data.Tutorial,
		ClimbTier = Economy.ClimbTier(data.ClimbPower),
		MergeReady = Economy.TotalDeliveries(data.Deliveries) >= Economy.MergeAfterDeliveries,
		Income = income * money,
		SpeedBuys = data.SpeedBuys,
		Offline = if state then state.Offline else nil,
		FreeGift = data.FreeGift,
		GiftCoins = giftCoins,
		GiftClimb = giftClimb,
		Daily = daily,
	}
end

local function push(player: Player)
	local state = states[player]
	if not state then
		return
	end
	state.Dirty = false
	local snapshot = FlockService:Snapshot(player)
	local reached = snapshot.ClimbTier
	if type(reached) == "number" then
		if reached > state.ClimbTier then
			local tier = Olympus.Tiers[reached]
			notify(player, `{tier.God}'s {tier.Area} is in reach!`, "Rare", "Upgrade")
		end
		state.ClimbTier = math.max(state.ClimbTier, reached)
		player:SetAttribute("ClimbTier", reached)
	end
	player:SetAttribute("Income", snapshot.Income)
	player:SetAttribute("MergeReady", snapshot.MergeReady)
	Remotes.State:Fire(player, snapshot)
end

local function build(family: string, rarity: number, scale: number): Model?
	return registry.SheepService:Build(family, rarity, scale)
end

-- What Pens needs to know about a plot's ground.
local function groundOf(plot: any): Pens.Ground
	return {
		CanStand = function(position: Vector3, radius: number): boolean
			return registry.PlotService:CanStand(plot, position, radius)
		end,
		PathClear = function(from: Vector3, to: Vector3, radius: number): boolean
			return registry.PlotService:PathClear(plot, from, to, radius)
		end,
	}
end

-- Where a sheep coming into the pen stands: where it was put down, else where it lived before (its home), else any
-- clear spot; moved to the nearest clear spot if another sheep or the decor is in the way.
local function arrivalSpot(state: PlayerState, plot: any, ground: Pens.Ground, sheep: Sheep, at: CFrame?): CFrame
	local scale = Pens.Scale(sheep)
	local turn = CFrame.Angles(0, random:NextNumber(0, 2 * math.pi), 0)
	local landed = if at then Pens.Landing(state.Shown, ground, at, scale) else nil
	if not landed and sheep.HomeX and sheep.HomeZ then
		local home = registry.PlotService:ToWorld(plot, sheep.HomeX, sheep.HomeZ)
		landed = Pens.Landing(state.Shown, ground, CFrame.new(home) * turn, scale)
	end
	if not landed then
		local pen: BasePart = plot.Pieces.Pen
		local half = pen.Size / 2
		landed = Pens.FreeSpot(state.Shown, ground, function(): Vector3
			local inside = pen.CFrame:PointToWorldSpace(
				Vector3.new(random:NextNumber(-half.X, half.X), 0, random:NextNumber(-half.Z, half.Z))
			)
			return Vector3.new(inside.X, plot.Origin.Y, inside.Z)
		end, scale)
	end
	-- A pen with no clear spot at all (never in practice): where it was asked to go, or the middle.
	return landed or at or CFrame.new(plot.Origin.Position) * turn
end

-- Builds, grows and removes the models in the owner's pen to match their flock. `arriving`: sheep that appear now
-- (out of storage, a merge's result) hop in rather than just being there, as on a join.
local function refreshPen(player: Player, arriving: boolean?)
	local state = states[player]
	local data = dataOf(player)
	local plot = registry.PlotService:GetPlot(player)
	local folder = penFolder
	if not state or not data or not plot or not folder then
		return
	end
	local now = workspace:GetServerTimeNow()
	local best = Economy.BestIncome(data.Sheep)
	local money = boosts(player)
	local function income(sheep: Sheep): number
		return Economy.Income(sheep, best) * money
	end
	local wanted: { [string]: Sheep } = {}
	for id, sheep in data.Sheep do
		if Roster.IsEquipped(sheep, data.PenSlots) then
			wanted[id] = sheep
		end
	end
	for id, shown in state.Shown do
		local sheep = wanted[id]
		if
			not sheep
			or (
				not Pens.Update(shown, sheep, now, income(sheep))
				and not Pens.Rebuild(shown, sheep, player.UserId, folder, build, now, income(sheep))
			)
		then
			shown.Model:Destroy()
			state.Shown[id] = nil
		end
	end
	local ground = groundOf(plot)
	for id, sheep in wanted do
		if state.Shown[id] then
			continue
		end
		local arrival = state.Arrivals[id]
		state.Arrivals[id] = nil
		local at = arrivalSpot(state, plot, ground, sheep, if arrival then arrival.At else nil)
		local from = if arrival and arrival.From
			then arrival.From
			elseif arrival or arriving then at + Vector3.new(0, HOP_IN_HEIGHT, 0)
			else nil
		local shown = Pens.Show(sheep, at, player.UserId, folder, build, from, income(sheep))
		if shown then
			state.Shown[id] = shown
			sheep.HomeX, sheep.HomeZ = registry.PlotService:ToLocal(plot, at.Position)
		end
	end
	table.clear(state.Arrivals)
	registry.PlotService:Refresh(player, data.WalkerLevel, Roster.Income(data.Sheep, data.PenSlots) * money)
end

-- Every penned sheep's strolls (Pens.Wander).
local function wander()
	local now = workspace:GetServerTimeNow()
	for player, state in states do
		local data = dataOf(player)
		local plot = registry.PlotService:GetPlot(player)
		if data and plot and next(state.Shown) then
			Pens.Wander(state.Shown, data.Sheep, groundOf(plot), now)
		end
	end
end

local function clearPen(player: Player)
	local state = states[player]
	if not state then
		return
	end
	for _, shown in state.Shown do
		shown.Model:Destroy()
	end
	table.clear(state.Shown)
end

local function leaderstats(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Income", "Climbing" } do
		local value = Instance.new("StringValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
end

local function updateLeaderstats(player: Player, income: number, climbPower: number)
	local stats = player:FindFirstChild("leaderstats")
	local incomeValue = stats and stats:FindFirstChild("Income")
	local climbValue = stats and stats:FindFirstChild("Climbing")
	if incomeValue and incomeValue:IsA("StringValue") then
		incomeValue.Value = `{Format.Rate(income)}/s`
	end
	if climbValue and climbValue:IsA("StringValue") then
		climbValue.Value = Format.Short(climbPower)
	end
end

-- Credits `elapsed` seconds away: income at the offline share and growth for the whole time, both with the passes.
local function settleOffline(player: Player, data: any, elapsed: number)
	local money, growth = boosts(player)
	local equipped: { Sheep } = {}
	for _, sheep in data.Sheep do
		if Roster.IsEquipped(sheep, data.PenSlots) then
			table.insert(equipped, sheep)
		end
	end
	local coins, matured = Economy.Offline(
		equipped,
		elapsed,
		GameConfig.Offline.MaxSeconds,
		GameConfig.Offline.Share,
		Economy.BestIncome(data.Sheep),
		growth
	)
	coins *= money
	if coins >= GameConfig.Offline.MinCredit or #matured > 0 then
		registry.DataService:AdjustCoins(player, coins)
		local state = states[player]
		if state then
			state.Offline = { Coins = coins, Matured = #matured }
		end
	end
end

local function onLoaded(player: Player, data: any)
	states[player] = {
		Shown = {},
		Arrivals = {},
		Dirty = true,
		Offline = nil,
		ClimbTier = Economy.ClimbTier(data.ClimbPower),
	}
	-- A save from when the pen started smaller is brought up to today's start.
	data.PenSlots = math.clamp(data.PenSlots, Economy.StartPens, Economy.MaxPens)
	Roster.Normalize(data.Sheep, data.PenSlots)
	local away = if data.LastSeen > 0 then math.max(0, os.time() - data.LastSeen) else 0
	data.LastSeen = os.time()
	leaderstats(player)
	refreshPen(player)
	push(player)
	if away > 0 then
		-- The time away is credited once StoreService knows the player's passes (2x Money and Growth count offline).
		task.spawn(function()
			local deadline = os.clock() + PASS_WAIT
			while player.Parent == Players and player:GetAttribute("PassesChecked") ~= true and os.clock() < deadline do
				task.wait(0.25)
			end
			local loaded = dataOf(player)
			if loaded and states[player] then
				settleOffline(player, loaded, away)
				refreshPen(player)
				push(player)
			end
		end)
	end
end

local function tick(dt: number)
	for player, state in states do
		local data = dataOf(player)
		if not data then
			continue
		end
		local income = 0
		local grewUp: { Sheep } = {}
		local best = Economy.BestIncome(data.Sheep)
		local money, growth = boosts(player)
		for _, sheep in data.Sheep do
			if Roster.IsEquipped(sheep, data.PenSlots) then
				income += Economy.Income(sheep, best) * money
				if not Economy.IsAdult(sheep) then
					sheep.Grown = math.min(sheep.Grown + dt * growth, Economy.GrowthSeconds(sheep))
					if Economy.IsAdult(sheep) then
						table.insert(grewUp, sheep)
					else
						state.Dirty = true
					end
				end
			end
		end
		if income > 0 then
			registry.DataService:AdjustCoins(player, income * registry.FriendService:Boost(player) * dt)
		end
		data.LastSeen = os.time()
		for _, sheep in grewUp do
			local size = Economy.Sizes[sheep.Size].Name
			Remotes.Reveal:Fire(player, Economy.Name(sheep), size)
			state.Dirty = true
		end
		refreshPen(player)
		updateLeaderstats(player, Roster.Income(data.Sheep, data.PenSlots) * money, data.ClimbPower)
		if state.Dirty then
			push(player)
		end
	end
end

function FlockService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function FlockService.Start(_self: any)
	local folder = Instance.new("Folder")
	folder.Name = PEN_FOLDER
	folder.Parent = workspace
	penFolder = folder
	trove:Add(folder)

	trove:Add(registry.DataService:ObserveLoaded(onLoaded))
	trove:Add(registry.PlotService.PlotAssigned:Connect(function(player: Player)
		refreshPen(player)
	end))
	-- Not disconnected in Destroy: on shutdown sessions may end after it (BRAIN/PATTERNS/data.md).
	registry.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		data.LastSeen = os.time()
		clearPen(player)
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		clearPen(player)
		states[player] = nil
	end)

	local elapsed = 0
	local sinceWander = 0
	trove:Connect(RunService.Heartbeat, function(dt: number)
		elapsed += dt
		sinceWander += dt
		if elapsed >= TICK then
			local step = elapsed
			elapsed = 0
			tick(step)
		end
		if sinceWander >= WANDER_CHECK then
			sinceWander = 0
			wander()
		end
		for player, state in states do
			if state.Dirty then
				push(player)
			end
		end
	end)

	Remotes.GetState:Handle(function(player: Player)
		local snapshot = FlockService:Snapshot(player)
		local state = states[player]
		if state then
			-- The away summary shows once, on the first snapshot the client asks for.
			state.Offline = nil
		end
		return snapshot
	end)
	Remotes.FlockAction:Handle(function(player: Player, action: string, id: string?)
		return FlockService:Act(player, action, id)
	end)
	Remotes.Sell:Handle(function(player: Player, ids: { string })
		return FlockService:Sell(player, ids)
	end)
end

function FlockService.Destroy(_self: any)
	for player in states do
		clearPen(player)
	end
	trove:Clean()
	penFolder = nil
end

-- Re-sends the snapshot and refreshes the pens (after a purchase, a level, a wipe).
function FlockService.Push(_self: any, player: Player)
	markDirty(player)
	refreshPen(player)
end

function FlockService.Count(_self: any, player: Player): number
	local data = dataOf(player)
	return if data then Roster.Count(data.Sheep) else math.huge
end

function FlockService.Income(_self: any, player: Player): number
	local data = dataOf(player)
	return if data then Roster.Income(data.Sheep, data.PenSlots) * (boosts(player)) else 0
end

-- A stolen lamb is put down in its owner's pen: it joins the flock, standing at `at` (or the nearest clear spot) after
-- hopping down from `from` (where it was held), if the pen has room; stored if not. Without `at` (Studio's GiveSheep)
-- it appears on a free spot.
function FlockService.Deliver(_self: any, player: Player, wild: Wild, at: CFrame?, from: CFrame?): Sheep?
	local data = dataOf(player)
	local tier = Olympus.ByFamily[wild.Family]
	if not data or not tier then
		return nil
	end
	local id = tostring(data.NextId)
	data.NextId += 1
	local slot = Roster.FreeSlot(data.Sheep, data.PenSlots)
	local sheep: Sheep = {
		Id = id,
		Family = wild.Family,
		Rarity = wild.Rarity,
		Weight = wild.Weight,
		Size = wild.Size,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = slot or 0,
		Pinned = false,
		Tutorial = if wild.Tutorial then true else nil,
	}
	data.Sheep[id] = sheep
	local key = tostring(tier.Tier)
	data.Deliveries[key] = (data.Deliveries[key] or 0) + 1

	local name = Economy.Name(sheep)
	local state = states[player]
	if slot then
		if state then
			state.Arrivals[id] = { At = at, From = from }
		end
		local rate = Economy.Income(sheep, Economy.BestIncome(data.Sheep)) * (boosts(player))
		notify(player, `{name} is home! +{Format.Rate(rate)}/s`, "Good", "Coin")
	else
		notify(player, "Stored - not earning. Your pen is full.", "Bad", "Notice")
	end
	if not data.Dex[wild.Family] then
		-- Its reward waits in the Sheepdex for a claim (SheepdexService).
		data.Dex[wild.Family] = true
		notify(
			player,
			`New in your Sheepdex: {Economy.FamilyName(wild.Family)}! Claim its reward there`,
			"Rare",
			"DexReward"
		)
	end
	if data.Tutorial == 0 then
		data.Tutorial = 1
		registry.DataService:AdjustCoins(player, Economy.TutorialCoins)
		data.ClimbPower += Economy.TutorialClimb
		registry.DataService:Replicate(player)
		notify(player, `+{Economy.TutorialCoins} cash and +{Economy.TutorialClimb} Climbing!`, "Rare", "Upgrade")
	end
	FlockService.Delivered:Fire(player, sheep)
	refreshPen(player)
	push(player)
	return sheep
end

local function act(player: Player, data: any, action: string, id: string?): (boolean, string?)
	if action == "EquipBest" then
		Roster.EquipBest(data.Sheep, data.PenSlots)
		return true, "Your best sheep are earning"
	end
	local sheep = if id then data.Sheep[id] else nil
	if not sheep then
		return false, "That sheep is gone"
	end
	if sheep.Shrine and (action == "Equip" or action == "Sell") then
		return false, "It's waiting at the Merge Shrine"
	end
	if action == "Equip" then
		if Roster.IsEquipped(sheep, data.PenSlots) then
			return true, nil
		end
		local slot = Roster.FreeSlot(data.Sheep, data.PenSlots)
		if not slot then
			return false, "Your pen is full"
		end
		sheep.Slot = slot
		sheep.Pinned = true
		return true, nil
	elseif action == "Unequip" then
		sheep.Slot = 0
		sheep.Pinned = false
		return true, "Stored - not earning"
	elseif action == "Lock" or action == "Unlock" then
		sheep.Locked = action == "Lock"
		return true, nil
	end
	return false, "Unknown action"
end

function FlockService.Act(_self: any, player: Player, action: string, id: string?): (boolean, string?)
	local data = dataOf(player)
	if not data then
		return false, "Still loading"
	end
	local ok, message = act(player, data, action, id)
	if ok then
		refreshPen(player, true)
		push(player)
	end
	return ok, message
end

-- The Sell Stall: stored, unlocked sheep sold together for Economy.SellValue each, as one change.
function FlockService.Sell(_self: any, player: Player, ids: { string }): (boolean, string?)
	local data = dataOf(player)
	if not data then
		return false, "Still loading"
	end
	if player:GetAttribute("Carrying") == true then
		return false, "Deliver your sheep first"
	end
	local ok, why = Roster.CanSell(data.Sheep, ids, data.PenSlots)
	if not ok then
		return false, why
	end
	local total = 0
	for _, id in ids do
		total += Economy.SellValue(data.Sheep[id])
		data.Sheep[id] = nil
	end
	registry.DataService:AdjustCoins(player, total)
	push(player)
	return true, `Sold {#ids} for {Format.Short(total)} cash`
end

-- The Merge Shrine's trade (ShrineService): the three sheep and the fee go and one fresh lamb of their family comes,
-- its fleece, weight and adult size rolled with the three's luck (Economy.ShrineRoll), saved as one change. The lamb
-- waits on the shrine's altar (Shrine) until its owner carries it home or it goes there by itself
-- (FlockService.ShrineArrive), and stays out of the pen meanwhile.
-- A gift sheep (the daily gifts' lambs) joins the flock straight away: it hops into the pen on a free spot if there's
-- room, else it's stored. `tier` is the tier a special family's sheep earns as. Nil when the flock is full.
function FlockService.Grant(_self: any, player: Player, wild: Wild, tier: number?): Sheep?
	local data = dataOf(player)
	if not data or Roster.Count(data.Sheep) >= GameConfig.Theft.InventoryLimit then
		return nil
	end
	local id = tostring(data.NextId)
	data.NextId += 1
	local slot = Roster.FreeSlot(data.Sheep, data.PenSlots)
	local sheep: Sheep = {
		Id = id,
		Family = wild.Family,
		Rarity = wild.Rarity,
		Weight = wild.Weight,
		Size = wild.Size,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = slot or 0,
		Pinned = false,
		Tier = tier,
	}
	data.Sheep[id] = sheep
	local state = states[player]
	if slot and state then
		state.Arrivals[id] = {}
	end
	refreshPen(player)
	push(player)
	return sheep
end

function FlockService.ShrineMerge(
	_self: any,
	player: Player,
	ids: { string },
	random: Random
): (boolean, string?, Sheep?)
	local data = dataOf(player)
	if not data then
		return false, "Still loading", nil
	end
	if player:GetAttribute("Carrying") == true then
		return false, "Take your sheep home first", nil
	end
	if Economy.TotalDeliveries(data.Deliveries) < Economy.MergeAfterDeliveries then
		return false, `Opens after {Economy.MergeAfterDeliveries} deliveries`, nil
	end
	for _, sheep in data.Sheep do
		if sheep.Shrine then
			return false, "Pick up your lamb first", nil
		end
	end
	local inputs: { Sheep } = {}
	for _, id in ids do
		local sheep = data.Sheep[id]
		if not sheep then
			return false, "That sheep is gone", nil
		end
		table.insert(inputs, sheep)
	end
	local ok, why = Economy.CanShrine(inputs)
	if not ok then
		return false, why, nil
	end
	local price = Economy.ShrinePrice(inputs[1].Family)
	if data.Coins < price then
		return false, `Need {Format.Short(price - data.Coins)} more cash`, nil
	end
	local rarity, weight, size = Economy.ShrineRoll(random, inputs)
	if not registry.DataService:AdjustCoins(player, -price) then
		return false, "Not enough cash", nil
	end
	for _, sheep in inputs do
		data.Sheep[sheep.Id] = nil
	end
	local id = tostring(data.NextId)
	data.NextId += 1
	local lamb: Sheep = {
		Id = id,
		Family = inputs[1].Family,
		Rarity = rarity,
		Weight = weight,
		Size = size,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = 0,
		Pinned = false,
		Shrine = true,
	}
	data.Sheep[id] = lamb
	refreshPen(player)
	push(player)
	return true, nil, lamb
end

-- A merged lamb leaves the shrine's altar for its owner's pen: put down there at `at` (hopping down from `from`, where
-- it was held), or by itself to a free spot. Into the pen if it has room. `reason` is what its owner is told.
function FlockService.ShrineArrive(_self: any, player: Player, id: string, reason: string?, at: CFrame?, from: CFrame?)
	local data = dataOf(player)
	local sheep = data and data.Sheep[id]
	if not data or not sheep or not sheep.Shrine then
		return
	end
	sheep.Shrine = nil
	local slot = Roster.FreeSlot(data.Sheep, data.PenSlots)
	if slot then
		sheep.Slot = slot
		local state = states[player]
		if state and at then
			state.Arrivals[id] = { At = at, From = from }
		end
	end
	local name = Economy.Name(sheep)
	if not slot then
		notify(player, `{name} is stored: your pen is full`, "Bad", "Notice")
	elseif reason then
		notify(player, reason, "Good", "Coin")
	else
		notify(player, `{name} is home! +{Format.Rate(Economy.Income(sheep) * (boosts(player)))}/s`, "Good", "Coin")
	end
	refreshPen(player)
	push(player)
end

-- A sheep bought in the store (PurchaseService's grant): grown, into the pen if there's room, stored if not. Its
-- record is saved before anything is shown, so a failure showing it never loses the purchase. Never yields.
function FlockService.AddRobuxSheep(_self: any, player: Player, family: string): Sheep?
	local data = dataOf(player)
	local robux = Economy.RobuxSheep[family]
	if not data or not robux then
		return nil
	end
	local id = tostring(data.NextId)
	data.NextId += 1
	local slot = Roster.FreeSlot(data.Sheep, data.PenSlots)
	local sheep: Sheep = {
		Id = id,
		Family = family,
		Rarity = 1,
		Weight = 1,
		Size = robux.Size,
		Grown = 1,
		Rank = 0,
		Locked = false,
		Slot = slot or 0,
		Pinned = slot ~= nil,
	}
	data.Sheep[id] = sheep
	local ok, problem = pcall(function()
		local state = states[player]
		if slot and state then
			state.Arrivals[id] = { At = nil, From = nil }
		end
		notify(
			player,
			if slot then `{robux.Name} joined your pen!` else `{robux.Name} is stored: your pen is full`,
			"Rare",
			"Upgrade"
		)
		refreshPen(player, true)
		push(player)
	end)
	if not ok then
		warn(`[FlockService] {player.Name}'s {family} is saved but couldn't be shown: {problem}`)
	end
	return sheep
end

return FlockService
