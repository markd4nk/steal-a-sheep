--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Store = require(ReplicatedStorage.Config.Store)

-- [Config/Store product key] = grant. A grant changes only the buyer's saved data through registry.DataService, must
-- not yield, and returns true once the reward is applied. It never refuses: a receipt Roblox has charged for always
-- gets its reward, whatever has changed since the dialog opened. What the reward does in the world (the pen, the
-- walker, the HUD) follows, and a failure there never fails the grant. See BRAIN/PATTERNS/purchases.md.
export type Grant = (player: Player, registry: { [string]: any }) -> boolean

-- The snapshot, the pen and the walker catch up with a change to the data; the change is saved already.
local function follow(player: Player, registry: { [string]: any }, what: string)
	local ok, problem = pcall(function()
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
	end)
	if not ok then
		warn(`[PurchaseService] {player.Name}'s {what} is saved but couldn't be shown: {problem}`)
	end
end

local function cash(amount: number): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		return registry.DataService:AdjustCoins(player, amount)
	end
end

local function climb(amount: number): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		local data = registry.DataService:GetData(player)
		data.ClimbPower += amount
		follow(player, registry, "Climbing")
		return true
	end
end

-- What a Robux spent on a price step the player is already past is worth in Climbing: the second Climbing pack's rate.
local CLIMB_PER_ROBUX = Store.Climb[2].Amount / Store.Climb[2].Price

-- The `buy`th 2x Speed: Climbing doubled when it's the player's next step (a step further on, bought outside the
-- store, counts as the next). A step they're already past, or one after it sold out (two dialogs racing, or a cheap
-- step prompted again by a client), pays its price in Climbing instead: a cheap step never doubles twice.
local function speed(buy: number): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		local data = registry.DataService:GetData(player)
		local nextBuy = data.SpeedBuys + 1
		if buy >= nextBuy and nextBuy <= #Store.SpeedPrices then
			data.ClimbPower = Economy.DoubleClimb(data.ClimbPower)
			data.SpeedBuys = nextBuy
		else
			data.ClimbPower += Store.SpeedPrices[buy] * CLIMB_PER_ROBUX
		end
		follow(player, registry, "2x Speed")
		return true
	end
end

-- The stair walker from `level` to the next: a level up when the player's walker is at `level` (one further on,
-- bought outside the store, counts as the next). A level they're already past or a maxed walker (a cash upgrade
-- while the dialog was open, or an old price prompted again) pays that level's cash price instead, so nothing charged
-- is lost and a cheap level can't be bought twice.
local function walker(level: number): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		local data = registry.DataService:GetData(player)
		if level >= data.WalkerLevel and data.WalkerLevel < Economy.MaxWalker then
			data.WalkerLevel += 1
		else
			registry.DataService:AdjustCoins(player, Economy.WalkerCost(math.min(level, Economy.MaxWalker - 1)) or 0)
		end
		follow(player, registry, "stair walker level")
		return true
	end
end

local function sheep(family: string): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		return registry.FlockService:AddRobuxSheep(player, family) ~= nil
	end
end

local Products: { [string]: Grant } = {}
for _, pack in Store.Cash do
	Products[pack.Key] = cash(pack.Amount)
end
for _, pack in Store.Climb do
	Products[pack.Key] = climb(pack.Amount)
end
for buy in Store.SpeedPrices do
	Products[Store.SpeedKey(buy)] = speed(buy)
end
for level = 0, Economy.MaxWalker - 1 do
	Products[Store.WalkerKey(level)] = walker(level)
end
for _, offer in Store.Sheep do
	Products[offer.Key] = sheep(offer.Family)
end

return Products
