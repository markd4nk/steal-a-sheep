--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)

-- The daily gifts (the user, 2026-10-05): one a day, a week of them better each day (Economy.DailyWeek), a Rare lamb on
-- Day 4 and the Pegasus Sheep on Day 7, then the same week again. The next opens DailyCooldown after a claim, and a
-- missed day waits where it was (the user's call). The server keeps the day and the time (DailyDay, DailyAt) and works
-- out every prize from the player's own income and stair walker when it's claimed.
local DailyService = { Name = "DailyService" }

local registry: Lifecycle.Registry = {}
local random = Random.new()

-- The day's lamb: a Rare one from the highest god stolen from, or the Pegasus Sheep (rolled lucky, so likely heavy and
-- big) earning one tier above that god.
local function lambFor(kind: string, deliveries: { [string]: number }): ({ [string]: any }, number?)
	if kind == "Pegasus" then
		local weight = Economy.RollWeight(random, Economy.PegasusLuck)
		local lamb = { Family = "Pegasus", Rarity = 1, Weight = weight, Size = Economy.RollSize(random, weight) }
		return lamb, Economy.PegasusTier(deliveries)
	end
	local weight = Economy.RollWeight(random)
	local family = Olympus.Tiers[Economy.HighestStolen(deliveries)].Family
	return { Family = family, Rarity = 2, Weight = weight, Size = Economy.RollSize(random, weight) }, nil
end

-- (ok, message, what was given: Day, Kind, Amount for cash and Climbing, Name and Family for a sheep).
local function claim(player: Player): (boolean, string?, { [string]: any }?)
	local data = registry.DataService:GetData(player)
	if not data then
		return false, "Still loading", nil
	end
	local now = os.time()
	if not Economy.DailyReady(data.DailyAt, now) then
		return false, "Come back when the timer's done", nil
	end
	local day = data.DailyDay
	local prize = Economy.DailyWeek[day]
	local isSheep = prize.Kind == "Lamb" or prize.Kind == "Pegasus"
	if isSheep and registry.FlockService:Count(player) >= GameConfig.Theft.InventoryLimit then
		return false, "Your flock is full: sell some first", nil
	end
	data.DailyDay = day % #Economy.DailyWeek + 1
	data.DailyAt = now
	local given: { [string]: any } = { Day = day, Kind = prize.Kind }
	if prize.Kind == "Cash" then
		local amount = Economy.DailyAmount(day, registry.FlockService:Income(player), data.WalkerLevel)
		registry.DataService:AdjustCoins(player, amount)
		given.Amount = amount
	elseif prize.Kind == "Climb" then
		local amount = Economy.DailyAmount(day, 0, data.WalkerLevel)
		data.ClimbPower += amount
		registry.DataService:Replicate(player)
		given.Amount = amount
	end
	if isSheep then
		local lamb, tier = lambFor(prize.Kind, data.Deliveries)
		local sheep = registry.FlockService:Grant(player, lamb :: any, tier)
		if sheep then
			given.Name = Economy.Name(sheep)
			given.Family = sheep.Family
			given.Stored = sheep.Slot == 0
		end
	else
		registry.FlockService:Push(player)
	end
	return true, nil, given
end

function DailyService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function DailyService.Start(_self: any)
	Remotes.ClaimDaily:Handle(claim)
end

function DailyService.Destroy(_self: any) end

return DailyService
