--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Run = require(script.Parent.Run)

local function sheep(fields: { [string]: any }): Economy.Sheep
	local base: any = {
		Id = "1",
		Family = "Meadow",
		Rarity = 1,
		Burden = 1,
		Size = 1,
		Grown = 0,
		Rank = 0,
		Locked = false,
		Slot = 0,
		Pinned = false,
	}
	for key, value in fields do
		base[key] = value
	end
	return base
end

local function adult(fields: { [string]: any }): Economy.Sheep
	local made = sheep(fields)
	made.Grown = Economy.GrowthSeconds(made)
	return made
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

-- These pin the current tuning: when the numbers are changed on purpose, change the expectations with them.
return function(t: Run.Suite)
	t.Test("base income follows round(2 x 2.5^(tier - 1))", function()
		local expected = { 2, 5, 13, 31, 78, 195, 488, 1221, 3052, 7629, 19073, 47684 }
		for tier, income in expected do
			t.Expect(Economy.BaseIncome(tier)).ToBe(income)
		end
	end)

	t.Test("reach thresholds and the derived Light and Heavy targets", function()
		local reach = { 0, 100, 800, 3200, 12800, 51200, 180000, 720000, 2900000, 9000000, 27000000, 81000000 }
		for tier, value in reach do
			t.Expect(Olympus.Tiers[tier].Reach).ToBe(value)
		end
		local _, light1, heavy1 = Economy.Targets(1)
		t.Expect(light1).ToBe(25)
		t.Expect(heavy1).ToBe(60)
		local _, light4, heavy4 = Economy.Targets(4)
		t.Expect(light4).ToBe(4800)
		t.Expect(heavy4).ToBe(7200)
		local _, _, heavy12 = Economy.Targets(12)
		t.Expect(heavy12).ToBe(182250000)
		local reach30, _, heavy30 = Economy.Targets(30)
		t.Expect(reach30).ToBe(1.2e15)
		t.Expect(heavy30).ToBe(2.7e15)
	end)

	t.Test("thirty tiers, each further up the ramp, harder to reach, with its own family", function()
		t.Expect(Olympus.Count).ToBe(30)
		t.Expect(Olympus.Tiers[30].God).ToBe("Zeus")
		local families: { [string]: boolean } = {}
		for index, tier in Olympus.Tiers do
			t.Expect(tier.Tier).ToBe(index)
			t.Expect(tier.XEnd > tier.XStart).ToBe(true)
			t.Expect(GameConfig.Breeds[tier.Family] ~= nil).ToBe(true)
			t.Expect(families[tier.Family]).ToBe(nil)
			families[tier.Family] = true
			if index > 1 then
				local below = Olympus.Tiers[index - 1]
				t.Expect(tier.Reach > below.Reach).ToBe(true)
				t.Expect(tier.XStart).ToBe(below.XEnd)
			end
		end
		local ramp = Olympus.Ramp
		for index = 2, #ramp do
			t.Expect(ramp[index][1] > ramp[index - 1][1]).ToBe(true)
			t.Expect(ramp[index][2] >= ramp[index - 1][2]).ToBe(true)
		end
		t.Expect(ramp[#ramp][1] >= Olympus.Tiers[30].XEnd).ToBe(true)
	end)

	t.Test("a minute on the walker the tier below needs covers each tier's reach gap", function()
		t.Expect(#Economy.WalkerRates).ToBe(Olympus.Count)
		for tier = 2, Olympus.Count do
			local gap = Olympus.Tiers[tier].Reach - Olympus.Tiers[tier - 1].Reach
			t.Expect(Economy.WalkerRate(tier - 2) * 60 >= gap * 0.9).ToBe(true)
		end
		local reach, _, heavy = Economy.Targets(30)
		t.Expect(Economy.WalkerRate(Economy.MaxWalker) * 60 >= heavy - reach).ToBe(true)
	end)

	t.Test("carry multipliers interpolate between the three targets", function()
		t.Expect(Economy.CarryMultiplier(1, 0, 1)).ToBe(0.84)
		t.Expect(Economy.CarryMultiplier(3, 0, 1)).ToBe(0.6)
		t.Expect(Economy.CarryMultiplier(3, 25, 1)).ToBe(0.76)
		t.Expect(Economy.CarryMultiplier(3, 1e9, 1)).ToBe(0.94)
		-- Halfway between Reach (100) and Light (150) for Dionysus.
		t.Expect(near(Economy.CarryMultiplier(1, 125, 2), 0.88)).ToBe(true)
		-- Below Reach keeps the first value: never divide by Demeter's 0.
		t.Expect(Economy.CarryMultiplier(2, 50, 2)).ToBe(0.72)
	end)

	t.Test("income: lamb share, fleece, size and merge rank", function()
		t.Expect(Economy.LambIncome(sheep({}))).ToBe(1)
		t.Expect(Economy.AdultIncome(adult({ Size = 2 }))).ToBe(3)
		t.Expect(Economy.AdultIncome(adult({ Rarity = 3, Size = 3 }))).ToBe(12.5)
		t.Expect(Economy.AdultIncome(adult({ Rank = 1 }))).ToBe(6)
		t.Expect(Economy.AdultIncome(adult({ Rank = 2 }))).ToBe(18)
	end)

	t.Test("growth takes 45 + 15 x (tier - 1) seconds, the tutorial lamb 30", function()
		t.Expect(Economy.GrowthSeconds(sheep({}))).ToBe(45)
		t.Expect(Economy.GrowthSeconds(sheep({ Family = "Gale" }))).ToBe(210)
		t.Expect(Economy.GrowthSeconds(sheep({ Family = "Thunder" }))).ToBe(480)
		t.Expect(Economy.GrowthSeconds(sheep({ Tutorial = true }))).ToBe(30)
	end)

	t.Test("stair walker, pen slot and trail prices", function()
		t.Expect(Economy.WalkerCost(0)).ToBe(120)
		t.Expect(Economy.WalkerCost(1)).ToBe(300)
		t.Expect(Economy.WalkerCost(2)).ToBe(750)
		t.Expect(Economy.WalkerCost(3)).ToBe(1875)
		t.Expect(Economy.WalkerCost(11)).ToBe(2861023)
		t.Expect(Economy.WalkerCost(29)).ToBe(nil)
		t.Expect(Economy.WalkerRate(1)).ToBe(12)
		t.Expect(Economy.PenCost(4)).ToBe(300)
		t.Expect(Economy.PenCost(7)).ToBe(4688)
		t.Expect(Economy.PenCost(13)).ToBe(nil)
		t.Expect(Economy.TrainingRate(2, "Laurel")).ToBe(60)
	end)

	t.Test("the burden size odds add up to 74.8 / 22.75 / 2.45 overall", function()
		local totals = { 0, 0, 0 }
		for _, burden in Economy.Burdens do
			for size, chance in burden.Sizes do
				totals[size] += burden.Chance * chance / 100
			end
		end
		t.Expect(near(totals[1], 74.8)).ToBe(true)
		t.Expect(near(totals[2], 22.75)).ToBe(true)
		t.Expect(near(totals[3], 2.45)).ToBe(true)
	end)

	t.Test("merging: three of a kind, the biggest size, one rank up, never less income", function()
		local a = adult({ Id = "1", Size = 1 })
		local b = adult({ Id = "2", Size = 3 })
		local c = adult({ Id = "3", Size = 2 })
		t.Expect((Economy.CanMerge({ a, b, c }))).ToBe(true)
		local result = Economy.MergeResult({ a, b, c })
		t.Expect(result.Size).ToBe(3)
		t.Expect(result.Rank).ToBe(1)
		t.Expect(Economy.IsAdult(result)).ToBe(true)
		local inputs = Economy.AdultIncome(a) + Economy.AdultIncome(b) + Economy.AdultIncome(c)
		t.Expect(Economy.AdultIncome(result) >= inputs).ToBe(true)
		t.Expect((Economy.CanMerge({ a, b, adult({ Id = "4", Rarity = 2 }) }))).ToBe(false)
		t.Expect((Economy.CanMerge({ a, b, adult({ Id = "5", Locked = true }) }))).ToBe(false)
		t.Expect((Economy.CanMerge({ a, b, sheep({ Id = "6" }) }))).ToBe(false)
		t.Expect((Economy.CanMerge({ a, a, b }))).ToBe(false)
		local top = { adult({ Id = "7", Rank = 2 }), adult({ Id = "8", Rank = 2 }), adult({ Id = "9", Rank = 2 }) }
		t.Expect((Economy.CanMerge(top))).ToBe(false)
	end)

	t.Test("selling pays 15 seconds of current income", function()
		t.Expect(Economy.SellValue(adult({ Size = 2 }))).ToBe(45)
		t.Expect(Economy.SellValue(sheep({}))).ToBe(15)
	end)

	t.Test("offline: a quarter of at most two hours, lamb rate until grown", function()
		local lamb = sheep({})
		local coins, matured = Economy.Offline({ lamb }, 100, 7200, 0.25)
		-- 45 s at 1/s as a lamb, then 55 s at 2/s, a quarter of it.
		t.Expect(coins).ToBe((45 + 110) * 0.25)
		t.Expect(#matured).ToBe(1)
		local capped = Economy.Offline({ adult({}) }, 100000, 7200, 0.25)
		t.Expect(capped).ToBe(7200 * 2 * 0.25)
	end)

	t.Test("a tier opens with its reach and a delivery from the one below", function()
		t.Expect(Economy.Unlocked(0, {})).ToBe(1)
		t.Expect(Economy.Unlocked(100, {})).ToBe(1)
		t.Expect(Economy.Unlocked(100, { ["1"] = 1 })).ToBe(2)
		t.Expect(Economy.Unlocked(5000, { ["1"] = 1, ["2"] = 1 })).ToBe(3)
		t.Expect(Economy.Unlocked(5000, { ["1"] = 1, ["2"] = 1, ["3"] = 1 })).ToBe(4)
	end)

	t.Test("wild rolls stay in range, and Heavy lambs never grow to Standard", function()
		local random = Random.new(7)
		for _ = 1, 500 do
			local rarity, burden, size = Economy.RollWild(random)
			t.Expect(rarity >= 1 and rarity <= 3).ToBe(true)
			t.Expect(burden >= 1 and burden <= 3).ToBe(true)
			t.Expect(size >= 1 and size <= 3).ToBe(true)
			if burden == 3 then
				t.Expect(size >= 2).ToBe(true)
			end
		end
	end)

	t.Test("the free gift: three minutes of walker and income, at least 500 of each", function()
		local coins, climb = Economy.GiftReward(0, 0)
		t.Expect(coins).ToBe(500)
		t.Expect(climb).ToBe(500)
		local laterCoins, laterClimb = Economy.GiftReward(2, 13.5)
		t.Expect(laterCoins).ToBe(2430)
		t.Expect(laterClimb).ToBe(7200)
	end)
end
