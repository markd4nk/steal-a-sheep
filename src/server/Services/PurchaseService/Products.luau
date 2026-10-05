--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)

-- [developerProductId] = grant. A grant changes only the player's saved data through registry.DataService,
-- must not yield, and returns true once the reward is applied. See BRAIN/PATTERNS/purchases.md.
export type Grant = (player: Player, registry: { [string]: any }) -> boolean

local Products: { [number]: Grant } = {}

-- The next stair walker level, bought at its upgrade sign (ShopService). The sign only offers it below the top level.
local function walkerLevel(player: Player, registry: { [string]: any }): boolean
	local data = registry.DataService:GetData(player)
	if not data then
		return false
	end
	if data.WalkerLevel < Economy.MaxWalker then
		data.WalkerLevel += 1
	end
	registry.DataService:Replicate(player)
	registry.FlockService:Push(player)
	return true
end

for _, offer in GameConfig.StairWalker.Robux do
	if offer.ProductId > 0 then
		Products[offer.ProductId] = walkerLevel
	end
end

return Products
