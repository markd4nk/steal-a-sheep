--!strict

-- Everything the Robux store sells (the user, 2026-10-05), keyed by name so Studio can grant a product before it
-- exists on Roblox. Prices here are what the store shows until Roblox reports the product's own price (a product's
-- price is set in Creator Hub; keep the two the same). Each step of a price ladder (2x Speed, the stair walker) is a
-- developer product of its own, because Roblox fixes a product's price.
--
-- Product keys: "Sheep.<Family>", "Speed.<buy number>", "Walker.<level it upgrades from>", "Climb.<n>", "Cash.<n>".
-- Pass keys: "DoubleMoney", "DoubleGrowth".

export type SheepOffer = { Key: string, Family: string, Price: number }
export type Pack = { Key: string, Amount: number, Price: number }
export type Pass = { Key: string, Name: string, Line: string, Price: number }

local Store = {}

-- Sold for Robux only; what they earn is Economy.RobuxSheep. The first is the big card.
Store.Sheep = table.freeze({
	{ Key = "Sheep.GoldenFleece", Family = "GoldenFleece", Price = 799 },
	{ Key = "Sheep.Kronos", Family = "Kronos", Price = 349 },
} :: { SheepOffer })

Store.Passes = table.freeze({
	{ Key = "DoubleMoney", Name = "2x Money", Line = "Earn 2x cash", Price = 249 },
	{ Key = "DoubleGrowth", Name = "2x Growth", Line = "Lambs grow 2x faster", Price = 149 },
} :: { Pass })

-- 2x Speed doubles Climbing; each buy costs three times the last, and after the seventh it's sold out.
Store.SpeedPrices = table.freeze({ 3, 9, 27, 81, 243, 729, 2187 })

-- The stair walker's next level for Robux, beside its cash price: 19 for the first, 20% more each level.
Store.WalkerFirstPrice = 19
Store.WalkerGrowth = 1.2

Store.Climb = table.freeze({
	{ Key = "Climb.1", Amount = 150e3, Price = 49 },
	{ Key = "Climb.2", Amount = 1e6, Price = 99 },
	{ Key = "Climb.3", Amount = 10e6, Price = 199 },
	{ Key = "Climb.4", Amount = 100e6, Price = 399 },
	{ Key = "Climb.5", Amount = 1e9, Price = 799 },
	{ Key = "Climb.6", Amount = 10e9, Price = 1499 },
} :: { Pack })

Store.Cash = table.freeze({
	{ Key = "Cash.1", Amount = 24e3, Price = 45 },
	{ Key = "Cash.2", Amount = 200e3, Price = 149 },
	{ Key = "Cash.3", Amount = 800e3, Price = 299 },
	{ Key = "Cash.4", Amount = 4e6, Price = 499 },
	{ Key = "Cash.5", Amount = 8e6, Price = 720 },
} :: { Pack })

-- Creator Hub ids by key, filled in once each product and pass exists (the game isn't published yet). A key
-- without one shows its price here and, in Studio, is granted at once with no dialog (StoreService).
local PRODUCT_IDS: { [string]: number } = {}
local PASS_IDS: { [string]: number } = {}

-- The stair walker's Robux price for the upgrade from `level` to the next: round(19 x 1.2^level).
function Store.WalkerPrice(level: number): number
	return math.floor(Store.WalkerFirstPrice * Store.WalkerGrowth ^ level + 0.5)
end

function Store.SpeedKey(buy: number): string
	return `Speed.{buy}`
end

function Store.WalkerKey(level: number): string
	return `Walker.{level}`
end

-- Every product key the store can sell, for Products and the tests. `maxWalker` is Economy.MaxWalker (levels 0 to
-- maxWalker - 1 can be upgraded); passed in so this config doesn't need the economy.
function Store.ProductKeys(maxWalker: number): { string }
	local keys: { string } = {}
	for _, offer in Store.Sheep do
		table.insert(keys, offer.Key)
	end
	for buy in Store.SpeedPrices do
		table.insert(keys, Store.SpeedKey(buy))
	end
	for level = 0, maxWalker - 1 do
		table.insert(keys, Store.WalkerKey(level))
	end
	for _, list in { Store.Climb, Store.Cash } do
		for _, pack in list do
			table.insert(keys, pack.Key)
		end
	end
	return keys
end

local packsByKey: { [string]: Pack } = {}
for _, list in { Store.Climb, Store.Cash } do
	for _, pack in list do
		packsByKey[pack.Key] = pack
	end
end
local sheepByKey: { [string]: SheepOffer } = {}
for _, offer in Store.Sheep do
	sheepByKey[offer.Key] = offer
end
local passesByKey: { [string]: Pass } = {}
for _, pass in Store.Passes do
	passesByKey[pass.Key] = pass
end

function Store.Pack(key: string): Pack?
	return packsByKey[key]
end

function Store.SheepOffer(key: string): SheepOffer?
	return sheepByKey[key]
end

function Store.Pass(key: string): Pass?
	return passesByKey[key]
end

-- "Speed.3" -> "Speed", 3.
function Store.Split(key: string): (string, number?)
	local kind, number = string.match(key, "^(%a+)%.(%d+)$")
	if kind then
		return kind, tonumber(number)
	end
	return key, nil
end

-- What the store shows as a product's price: its Creator Hub price is fetched when it has an id (Prices).
function Store.Price(key: string): number?
	local pack = packsByKey[key]
	if pack then
		return pack.Price
	end
	local offer = sheepByKey[key]
	if offer then
		return offer.Price
	end
	local pass = passesByKey[key]
	if pass then
		return pass.Price
	end
	local kind, number = Store.Split(key)
	if kind == "Speed" and number then
		return Store.SpeedPrices[number]
	elseif kind == "Walker" and number then
		return Store.WalkerPrice(number)
	end
	return nil
end

function Store.ProductId(key: string): number
	return PRODUCT_IDS[key] or 0
end

function Store.PassId(key: string): number
	return PASS_IDS[key] or 0
end

function Store.KeyOfProduct(productId: number): string?
	for key, id in PRODUCT_IDS do
		if id == productId then
			return key
		end
	end
	return nil
end

function Store.KeyOfPass(passId: number): string?
	for key, id in PASS_IDS do
		if id == passId then
			return key
		end
	end
	return nil
end

-- The player attribute StoreService sets while a pass counts for them.
function Store.PassAttribute(key: string): string
	return `Pass{key}`
end

return table.freeze(Store)
