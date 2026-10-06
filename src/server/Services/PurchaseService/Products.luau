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

-- The `buy`th 2x Speed: Climbing doubled. A receipt for a buy already counted (two dialogs racing) still doubles.
local function speed(buy: number): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		local data = registry.DataService:GetData(player)
		data.ClimbPower = Economy.DoubleClimb(data.ClimbPower)
		data.SpeedBuys = math.max(data.SpeedBuys, buy)
		follow(player, registry, "2x Speed")
		return true
	end
end

-- The stair walker's next level. A receipt that finds it maxed already (a cash level bought while the dialog was
-- open) pays the last level's cash price instead, so nothing charged is lost.
local function walker(): Grant
	return function(player: Player, registry: { [string]: any }): boolean
		local data = registry.DataService:GetData(player)
		if data.WalkerLevel < Economy.MaxWalker then
			data.WalkerLevel += 1
		else
			registry.DataService:AdjustCoins(player, Economy.WalkerCost(Economy.MaxWalker - 1) or 0)
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
	Products[Store.WalkerKey(level)] = walker()
end
for _, offer in Store.Sheep do
	Products[offer.Key] = sheep(offer.Family)
end

return Products
