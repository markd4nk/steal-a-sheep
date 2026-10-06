--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Store = require(ReplicatedStorage.Config.Store)

type Entry = { Price: number?, Loading: boolean, FailedAt: number? }

local RETRY_SECONDS = 60

-- Robux prices for the store: Roblox's own once a product or pass has an id (with Managed Pricing a player may pay a
-- different price, and Creator Hub can change it without a code change), Config/Store's until then. Fetched the
-- first time a screen asks and kept for the session; a failed fetch is tried again after a minute.
local Prices = {
	Changed = Signal.new() :: Signal.Signal<string>,
}

local entries: { [string]: Entry } = {}

local function fetch(key: string, id: number, infoType: Enum.InfoType, entry: Entry)
	entry.Loading = true
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, id, infoType)
		local price = if ok and type(info) == "table" then info.PriceInRobux else nil
		entry.Loading = false
		if type(price) == "number" then
			entry.Price = price
			entry.FailedAt = nil
			Prices.Changed:Fire(key)
		else
			entry.FailedAt = os.clock()
			warn(`[UIController] No price for {key} ({id}): {if ok then "no PriceInRobux" else info}`)
		end
	end)
end

-- The price to show for a product or pass key ("Cash.1", "Speed.3", "DoubleMoney").
function Prices.Of(key: string): number?
	local isPass = Store.Pass(key) ~= nil
	local id = if isPass then Store.PassId(key) else Store.ProductId(key)
	if id == 0 then
		return Store.Price(key)
	end
	local entry = entries[key]
	if not entry then
		entry = { Price = nil, Loading = false, FailedAt = nil }
		entries[key] = entry
	end
	local failedAt = entry.FailedAt
	if not entry.Price and not entry.Loading and (not failedAt or os.clock() - failedAt >= RETRY_SECONDS) then
		fetch(key, id, if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product, entry)
	end
	return entry.Price or Store.Price(key)
end

return table.freeze(Prices)
