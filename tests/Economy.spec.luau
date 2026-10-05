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

	t.Test("Reach values and the derived Light and Heavy targets", function()
		local reach = { 0, 100, 800, 3200, 12800, 51200, 180000, 720000, 2900000, 9000000, 27000000, 81000000 }
		for tier, value in reach do
			t.Expect(Olympus.Tiers[tier].Reach).ToBe(value)
		end
		local _, light1, heavy1 = Economy.Targets(1)
		t.Expect(light1).ToBe(0)
		t.Expect(heavy1).ToBe(0)
		local _, light4, heavy4 = Economy.Targets(4)
		t.Expect(light4).ToBe(3200)
		t.Expect(heavy4).ToBe(5120)
		local reach30, _, heavy30 = Economy.Targets(30)
		t.Expect(reach30).ToBe(1.2e15)
		t.Expect(heavy30).ToBe(1.92e15)
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

	t.Test("escape speed: Climbing against the lamb's Reach and weight, the god at 0.8 of the top", function()
		-- Demeter's lambs are always full speed.
		t.Expect(Economy.EscapeShare(0, 1, 1.6)).ToBe(1)
		t.Expect(Economy.EscapeShare(0, 2, 1)).ToBe(0)
		-- Level with the god at 0.8 x Reach x weight, a little faster at Reach x weight.
		local aphrodite = Olympus.Tiers[6]
		t.Expect(near(Economy.EscapeSpeed(0.8 * aphrodite.Reach, 6, 1), Economy.GodSpeed(6))).ToBe(true)
		t.Expect(near(Economy.EscapeSpeed(0.8 * aphrodite.Reach * 1.6, 6, 1.6), Economy.GodSpeed(6))).ToBe(true)
		t.Expect(Economy.EscapeSpeed(aphrodite.Reach, 6, 1) > Economy.GodSpeed(6)).ToBe(true)
		t.Expect(Economy.EscapeSpeed(aphrodite.Reach, 6, 1.6) < Economy.GodSpeed(6)).ToBe(true)
		t.Expect(near(Economy.EscapeShare(100, 2, 1), 1 / 1.2)).ToBe(true)
		t.Expect(near(Economy.CarryShare(3, 100, 2), 100 / 132)).ToBe(true)
		t.Expect(near(Economy.GodSpeed(6), aphrodite.SlideSpeed * 0.8)).ToBe(true)
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

	t.Test("a slope's climb share is Climbing / (Climbing + Reach), full on Demeter's meadow", function()
		t.Expect(Economy.ClimbShare(0, 1)).ToBe(1)
		t.Expect(Economy.ClimbShare(0, 2)).ToBe(0)
		t.Expect(Economy.ClimbShare(100, 2)).ToBe(0.5)
		t.Expect(near(Economy.ClimbShare(512000, 6), 10 / 11)).ToBe(true)
		t.Expect(Economy.ClimbShare(1e12, 0)).ToBe(1)
	end)

	t.Test("the climb tier is the highest whose Reach the Climbing has", function()
		t.Expect(Economy.ClimbTier(0)).ToBe(1)
		t.Expect(Economy.ClimbTier(99)).ToBe(1)
		t.Expect(Economy.ClimbTier(100)).ToBe(2)
		t.Expect(Economy.ClimbTier(5000)).ToBe(4)
		t.Expect(Economy.ClimbTier(1e18)).ToBe(Olympus.Count)
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
end
