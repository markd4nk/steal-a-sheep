--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Store = require(ReplicatedStorage.Config.Store)
local Products = require(ServerScriptService.Services.PurchaseService.Products)
local Roster = require(ServerScriptService.Services.FlockService.Roster)
local Run = require(script.Parent.Run)

local function sheep(id: string, fields: { [string]: any }): Economy.Sheep
	local made: any = {
		Id = id,
		Family = "Meadow",
		Rarity = 1,
		Weight = 1,
		Size = 1,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = 0,
		Pinned = false,
	}
	for key, value in fields do
		made[key] = value
	end
	return made
end

local function grown(id: string, fields: { [string]: any }): Economy.Sheep
	local made = sheep(id, fields)
	made.Grown = Economy.GrowthSeconds(made)
	return made
end

-- The user's prices and ladders from the store's mock-ups (2026-10-05): change these with them on purpose.
return function(t: Run.Suite)
	t.Test("2x Speed triples in price each buy, seven buys, then sold out", function()
		t.Expect(Store.SpeedPrices).ToEqual({ 3, 9, 27, 81, 243, 729, 2187 })
		for buy = 2, #Store.SpeedPrices do
			t.Expect(Store.SpeedPrices[buy]).ToBe(Store.SpeedPrices[buy - 1] * 3)
		end
		t.Expect(Store.Price(Store.SpeedKey(1))).ToBe(3)
		t.Expect(Store.Price(Store.SpeedKey(8))).ToBe(nil)
	end)

	t.Test("the stair walker in Robux starts at 19 and grows 20% a level", function()
		t.Expect(Store.WalkerPrice(0)).ToBe(19)
		t.Expect(Store.WalkerPrice(3)).ToBe(33)
		t.Expect(Store.WalkerPrice(Economy.MaxWalker - 1)).ToBe(3132)
		for level = 1, Economy.MaxWalker - 1 do
			t.Expect(Store.WalkerPrice(level) > Store.WalkerPrice(level - 1)).ToBe(true)
		end
		t.Expect(Store.Price(Store.WalkerKey(3))).ToBe(33)
	end)

	t.Test("packs, passes and sheep at the user's prices", function()
		local climb = {}
		for _, pack in Store.Climb do
			table.insert(climb, { pack.Amount, pack.Price })
		end
		t.Expect(climb)
			.ToEqual({ { 150e3, 49 }, { 1e6, 99 }, { 10e6, 199 }, { 100e6, 399 }, { 1e9, 799 }, { 10e9, 1499 } })
		local cash = {}
		for _, pack in Store.Cash do
			table.insert(cash, { pack.Amount, pack.Price })
		end
		t.Expect(cash).ToEqual({ { 24e3, 45 }, { 200e3, 149 }, { 800e3, 299 }, { 4e6, 499 }, { 8e6, 720 } })
		t.Expect(Store.Price("DoubleMoney")).ToBe(249)
		t.Expect(Store.Price("DoubleGrowth")).ToBe(149)
		t.Expect(Store.Price("Sheep.GoldenFleece")).ToBe(799)
		t.Expect(Store.Price("Sheep.Kronos")).ToBe(349)
	end)

	t.Test("every product key is unique, priced and granted; every store sheep has a look", function()
		local keys = Store.ProductKeys(Economy.MaxWalker)
		t.Expect(#keys).ToBe(#Store.Sheep + #Store.SpeedPrices + Economy.MaxWalker + #Store.Climb + #Store.Cash)
		local seen: { [string]: boolean } = {}
		for _, key in keys do
			t.Expect(seen[key]).ToBe(nil)
			seen[key] = true
			t.Expect(type(Store.Price(key))).ToBe("number")
			t.Expect(type(Products[key])).ToBe("function")
		end
		for _, offer in Store.Sheep do
			t.Expect(Economy.IsRobuxSheep(offer.Family)).ToBe(true)
			t.Expect(GameConfig.Breeds[offer.Family] ~= nil).ToBe(true)
		end
		local kind, number = Store.Split("Walker.12")
		t.Expect(kind).ToBe("Walker")
		t.Expect(number).ToBe(12)
	end)

	t.Test("a Robux sheep earns its times the flock's best other sheep, and stays out of merges and names", function()
		local meadow = grown("1", { Size = 3 })
		local best = Economy.Income(meadow)
		local fleece = grown("2", { Family = "GoldenFleece", Size = 3 })
		local kronos = grown("3", { Family = "Kronos", Size = 2 })
		local flock = { ["1"] = meadow, ["2"] = fleece, ["3"] = kronos }
		t.Expect(Economy.BestIncome(flock)).ToBe(best)
		t.Expect(Economy.Income(fleece, best)).ToBe(10 * best)
		t.Expect(Economy.Income(kronos, best)).ToBe(3 * best)
		-- With no other sheep, a tier 1 adult's income stands in.
		t.Expect(Economy.BestIncome({ ["2"] = fleece })).ToBe(Economy.BaseIncome(1))
		t.Expect(Economy.Name(fleece)).ToBe("Golden Fleece")
		t.Expect(Economy.IsAdult(sheep("4", { Family = "Kronos", Grown = 1 }))).ToBe(true)
		local ok, why = Economy.CanShrine({
			fleece,
			grown("5", { Family = "GoldenFleece" }),
			grown("6", { Family = "GoldenFleece" }),
		})
		t.Expect(ok).ToBe(false)
		t.Expect(why).ToBe("Robux sheep can't merge")
		meadow.Slot, fleece.Slot = 1, 2
		t.Expect(Roster.Income(flock, 8)).ToBe(11 * best)
	end)

	t.Test("a price step doubles or levels only once: one the player is past pays its price instead", function()
		local data = { ClimbPower = 100, SpeedBuys = 0, WalkerLevel = 0, Coins = 0 }
		local registry = {
			DataService = {
				GetData = function()
					return data
				end,
				AdjustCoins = function(_self: any, _player: any, amount: number)
					data.Coins += amount
					return true
				end,
				Replicate = function() end,
			},
			FlockService = { Push = function() end },
		}
		local player = {} :: any
		t.Expect(Products["Speed.1"](player, registry)).ToBe(true)
		t.Expect(data.ClimbPower).ToBe(200)
		t.Expect(data.SpeedBuys).ToBe(1)
		-- Speed.1 again (a client prompting the 3 R$ step twice): its price in Climbing, no doubling.
		Products["Speed.1"](player, registry)
		t.Expect(data.SpeedBuys).ToBe(1)
		t.Expect(math.abs(data.ClimbPower - (200 + 3 * Store.Climb[1].Amount / Store.Climb[1].Price)) < 1e-6).ToBe(true)
		-- A step further on counts as the next one.
		local before = data.ClimbPower
		Products["Speed.4"](player, registry)
		t.Expect(data.SpeedBuys).ToBe(2)
		t.Expect(data.ClimbPower).ToBe(Economy.DoubleClimb(before))

		t.Expect(Products["Walker.0"](player, registry)).ToBe(true)
		t.Expect(data.WalkerLevel).ToBe(1)
		Products["Walker.0"](player, registry)
		t.Expect(data.WalkerLevel).ToBe(1)
		t.Expect(data.Coins).ToBe(Economy.WalkerCost(0))
		data.WalkerLevel = Economy.MaxWalker
		Products[Store.WalkerKey(Economy.MaxWalker - 1)](player, registry)
		t.Expect(data.WalkerLevel).ToBe(Economy.MaxWalker)
	end)

	t.Test("2x Speed doubles Climbing, at least +25", function()
		t.Expect(Economy.DoubleClimb(0)).ToBe(25)
		t.Expect(Economy.DoubleClimb(10)).ToBe(35)
		t.Expect(Economy.DoubleClimb(1000)).ToBe(2000)
	end)

	t.Test("2x Growth grows lambs twice as fast while away", function()
		local plain = sheep("1", {})
		local fast = sheep("2", {})
		local need = Economy.GrowthSeconds(plain)
		local _, maturedPlain = Economy.Offline({ plain }, need / 2, 7200, 1)
		local _, maturedFast = Economy.Offline({ fast }, need / 2, 7200, 1, nil, 2)
		t.Expect(#maturedPlain).ToBe(0)
		t.Expect(#maturedFast).ToBe(1)
		-- Grown halfway through the time away, it earns the adult rate for the second half.
		local coins = Economy.Earn(sheep("3", {}), need, nil, 2)
		local half = need / 2
		t.Expect(math.abs(coins - (half * Economy.LambIncome(plain) + half * Economy.AdultIncome(plain))) < 1e-6)
			.ToBe(true)
	end)
	t.Test("every product and pass has its own Roblox id", function()
		local seen: { [number]: string } = {}
		for _, key in Store.ProductKeys(Economy.MaxWalker) do
			local id = Store.ProductId(key)
			t.Expect(id > 0).ToBe(true)
			t.Expect(seen[id]).ToBe(nil)
			seen[id] = key
			t.Expect(Store.KeyOfProduct(id)).ToBe(key)
		end
		for _, pass in Store.Passes do
			local id = Store.PassId(pass.Key)
			t.Expect(id > 0).ToBe(true)
			t.Expect(Store.KeyOfPass(id)).ToBe(pass.Key)
		end
	end)
end
