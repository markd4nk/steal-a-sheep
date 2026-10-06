--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Run = require(script.Parent.Run)

local function sheep(fields: { [string]: any }): Economy.Sheep
	local base: any = {
		Id = "1",
		Family = Olympus.Tiers[1].Family,
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
	t.Test("each friend in the server adds 20% income, up to 4 friends", function()
		t.Expect(near(Economy.FriendBoost(0), 1)).ToBe(true)
		t.Expect(near(Economy.FriendBoost(1), 1.2)).ToBe(true)
		t.Expect(near(Economy.FriendBoost(4), 1.8)).ToBe(true)
		t.Expect(near(Economy.FriendBoost(9), 1.8)).ToBe(true)
		t.Expect(near(Economy.FriendBoost(-2), 1)).ToBe(true)
	end)

	t.Test("base income follows round(2 x 2.5^(tier - 1))", function()
		local expected = { 2, 5, 13, 31, 78, 195, 488, 1221, 3052, 7629, 19073, 47684 }
		for tier, income in expected do
			t.Expect(Economy.BaseIncome(tier)).ToBe(income)
		end
	end)

	t.Test("Reach values and the derived Light and Heavy targets", function()
		local reach = { 25, 100, 800, 3200, 12800, 51200, 180000, 720000, 2900000, 9000000, 27000000, 81000000 }
		for tier, value in reach do
			t.Expect(Olympus.Tiers[tier].Reach).ToBe(value)
		end
		local _, light1, heavy1 = Economy.Targets(1)
		t.Expect(light1).ToBe(25)
		t.Expect(heavy1).ToBe(37.5)
		local _, light4, heavy4 = Economy.Targets(4)
		t.Expect(light4).ToBe(3200)
		t.Expect(heavy4).ToBe(4800)
		local reach30, _, heavy30 = Economy.Targets(30)
		t.Expect(reach30).ToBe(1.2e15)
		t.Expect(heavy30).ToBe(1.8e15)
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

	t.Test("speed: the ratio below 1, one more for every 4x above, never under 1 on tier 1", function()
		t.Expect(Economy.SpeedFactor(0.25, 5)).ToBe(0.25)
		t.Expect(Economy.SpeedFactor(1, 5)).ToBe(1)
		t.Expect(near(Economy.SpeedFactor(4, 5), 2)).ToBe(true)
		t.Expect(near(Economy.SpeedFactor(64, 5), 4)).ToBe(true)
		t.Expect(Economy.SpeedFactor(0, 1)).ToBe(1)
		t.Expect(near(Economy.SpeedFactor(16, 1), 3)).ToBe(true)
		t.Expect(Economy.Ratio(200, 2, 1)).ToBe(2)
		t.Expect(Economy.Ratio(200, 2, 2)).ToBe(1)
	end)

	t.Test("escape: the lightest lamb at the Reach matches the god, an average one leaves about 95%", function()
		local tier6 = Olympus.Tiers[6]
		t.Expect(near(Economy.GodSpeed(6), tier6.SlideSpeed * 0.8)).ToBe(true)
		t.Expect(near(Economy.EscapeSpeed(tier6.Reach, 6, 1), Economy.GodSpeed(6))).ToBe(true)
		local average = Economy.EscapeSpeed(tier6.Reach, 6, 1.06) / Economy.GodSpeed(6)
		t.Expect(average > 0.93 and average < 0.96).ToBe(true)
		t.Expect(near(Economy.EscapeSpeed(tier6.Reach * 4, 6, 1), Economy.GodSpeed(6) * 2)).ToBe(true)
		-- Tier 1's lambs never leave less than the god's speed.
		t.Expect(Economy.EscapeSpeed(0, 1, 1.5)).ToBe(Economy.GodSpeed(1))
	end)

	t.Test("income: nothing while a lamb, then fleece, size and merge rank", function()
		t.Expect(Economy.Income(sheep({ Rarity = 3, Size = 4 }))).ToBe(0)
		t.Expect(Economy.Income(adult({}))).ToBe(2)
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
		t.Expect(Economy.WalkerCost(0)).ToBe(1200)
		t.Expect(Economy.WalkerCost(1)).ToBe(3000)
		t.Expect(Economy.WalkerCost(2)).ToBe(7500)
		t.Expect(Economy.WalkerCost(3)).ToBe(18750)
		t.Expect(Economy.WalkerCost(11)).ToBe(28610229)
		t.Expect(Economy.WalkerCost(29)).ToBe(nil)
		t.Expect(Economy.WalkerRate(1)).ToBe(12)
		t.Expect(Economy.PenCost(8)).ToBe(nil)
		t.Expect(Economy.PenCost(9)).ToBe(25000)
		t.Expect(Economy.PenCost(12)).ToBe(5400000)
		t.Expect(Economy.PenCost(20)).ToBe(9069926400000)
		t.Expect(Economy.PenCost(21)).ToBe(nil)
		t.Expect(Economy.TrainingRate(2, "Laurel")).ToBe(60)
	end)

	t.Test("size odds add to 100 at every weight, heavier means bigger, Titan only from Huge", function()
		for _, weight in { 0.9, 1, 1.05, 1.1, 1.3, 1.5, 2, 3, 5 } do
			local odds = Economy.SizeOdds(weight)
			t.Expect(#odds).ToBe(#Economy.Sizes)
			local total = 0
			for _, chance in odds do
				total += chance
			end
			t.Expect(near(total, 100)).ToBe(true)
		end
		t.Expect(Economy.SizeOdds(1)[2] > 0).ToBe(true)
		t.Expect(Economy.SizeOdds(1.5)[1] < Economy.SizeOdds(1.05)[1]).ToBe(true)
		t.Expect(Economy.SizeOdds(1.5)[4]).ToBe(0)
		t.Expect(Economy.SizeOdds(2)[4] > 0).ToBe(true)
	end)

	t.Test(
		"weights: wild ones 1 to 1.5 averaging about 1.06; luck makes them heavier and opens the Huge tail",
		function()
			local random = Random.new(11)
			local total, most = 0, 0
			for _ = 1, 4000 do
				local weight = Economy.RollWeight(random)
				t.Expect(weight >= 1 and weight <= 1.5).ToBe(true)
				total += weight
			end
			local mean = total / 4000
			t.Expect(mean > 1.05 and mean < 1.08).ToBe(true)
			local lucky = 0
			for _ = 1, 4000 do
				local weight = Economy.RollWeight(random, 1)
				lucky += weight
				most = math.max(most, weight)
			end
			t.Expect(lucky / 4000 > mean + 0.1).ToBe(true)
			t.Expect(most > 1.5).ToBe(true)
			t.Expect(Economy.LambScale(1)).ToBe(0.55)
			t.Expect(near(Economy.LambScale(1.5), 0.88)).ToBe(true)
			t.Expect(near(Economy.LambScale(3), 0.88)).ToBe(true)
			-- The light end, where most wild lambs are, spread out: 1.1 is well over a tenth of the way.
			t.Expect(Economy.LambScale(1.1) - Economy.LambScale(1) > 0.1).ToBe(true)
			t.Expect(near(Economy.LambSize(1, 0), 0.55)).ToBe(true)
			t.Expect(near(Economy.LambSize(1, 1), 0.55 * (1 + Economy.LambGrowth))).ToBe(true)
		end
	)

	t.Test(
		"the Merge Shrine: three grown sheep of one family in, one fresh lamb out, rolled with their luck",
		function()
			local a = adult({ Id = "1", Size = 1 })
			local b = adult({ Id = "2", Size = 3, Rarity = 2 })
			local c = adult({ Id = "3", Size = 2 })
			t.Expect((Economy.CanShrine({ a, b, c }))).ToBe(true)
			t.Expect((Economy.CanShrine({ a, b }))).ToBe(false)
			t.Expect((Economy.CanShrine({ a, a, b }))).ToBe(false)
			t.Expect((Economy.CanShrine({ a, b, adult({ Id = "4", Locked = true }) }))).ToBe(false)
			t.Expect((Economy.CanShrine({ a, b, sheep({ Id = "5" }) }))).ToBe(false)
			t.Expect((Economy.CanShrine({ a, b, adult({ Id = "6", Family = "Grape" }) }))).ToBe(false)
			-- Different sizes and fleeces may go in together.
			t.Expect((Economy.CanShrine({ a, b, adult({ Id = "7", Rarity = 3 }) }))).ToBe(true)

			local standard = { a, adult({ Id = "8" }), adult({ Id = "9" }) }
			local titans =
				{ adult({ Id = "10", Size = 4 }), adult({ Id = "11", Size = 4 }), adult({ Id = "12", Size = 4 }) }
			t.Expect(near(Economy.ShrineLuck(standard), Economy.ShrineBaseLuck)).ToBe(true)
			t.Expect(near(Economy.ShrineLuck(titans), 1)).ToBe(true)
			t.Expect(Economy.ShrineLuck({ a, b, c }) > Economy.ShrineLuck(standard)).ToBe(true)
			t.Expect(Economy.ShrinePrice(Olympus.Tiers[1].Family))
				.ToBe(Economy.ShrinePriceSeconds * Economy.BaseIncome(1))

			-- The odds the menu shows add up, Titan only through the shrine's luck, likelier with bigger sheep in.
			for _, luck in { 0, Economy.ShrineBaseLuck, 1 } do
				local total = 0
				for _, chance in Economy.LuckySizeOdds(luck) do
					total += chance
				end
				t.Expect(math.abs(total - 100) < 1e-6).ToBe(true)
			end
			t.Expect(Economy.LuckySizeOdds(0)[4]).ToBe(0)
			local base, best = Economy.LuckySizeOdds(Economy.ShrineBaseLuck), Economy.LuckySizeOdds(1)
			t.Expect(base[4] > 0 and base[4] < 1).ToBe(true)
			t.Expect(best[4] > base[4]).ToBe(true)
			t.Expect(best[1] < base[1]).ToBe(true)
			local plain, royal =
				Economy.ShrineFleeceOdds(standard), Economy.ShrineFleeceOdds({
					adult({ Id = "13", Rarity = 3 }),
					adult({ Id = "14", Rarity = 3 }),
					adult({ Id = "15", Rarity = 3 }),
				})
			t.Expect(plain[3]).ToBe(Economy.ShrineFleece.Plain[3])
			t.Expect(royal[3]).ToBe(Economy.ShrineFleece.Royal[3])

			-- The roll: a fleece, a weight of at least 1 and a size in range; heavier on average than a wild lamb's.
			local random = Random.new(7)
			local shrine, wild = 0, 0
			for _ = 1, 4000 do
				local rarity, weight, size = Economy.ShrineRoll(random, standard)
				t.Expect(rarity >= 1 and rarity <= 3).ToBe(true)
				t.Expect(weight >= 1).ToBe(true)
				t.Expect(size >= 1 and size <= #Economy.Sizes).ToBe(true)
				shrine += weight
				wild += Economy.RollWeight(random)
			end
			t.Expect(shrine > wild).ToBe(true)
		end
	)

	t.Test("selling pays two minutes of its grown income, a lamb's too", function()
		t.Expect(Economy.SellValue(adult({ Size = 2 }))).ToBe(360)
		t.Expect(Economy.SellValue(sheep({}))).ToBe(240)
		t.Expect(Economy.SellValue(sheep({ Size = 2 }))).ToBe(360)
	end)

	t.Test("a lamb's name and worth give nothing of its family away", function()
		local herd = Olympus.Tiers[1]
		local common = sheep({ Family = herd.Family })
		local other = sheep({ Family = "GroveSpirit" })
		t.Expect(Economy.Name(common)).ToBe("Lamb")
		t.Expect(Economy.Name(sheep({ Rarity = 2 }))).ToBe("Shiny Lamb")
		t.Expect(Economy.Worth(common)).ToBe(Economy.Worth(other))
		t.Expect(Economy.Worth(sheep({ Weight = 1.5 })) > Economy.Worth(common)).ToBe(true)
		t.Expect(Economy.Worth(adult({ Size = 2 }))).ToBe(3)
		t.Expect(Economy.Name(adult({}))).ToBe(Economy.FamilyName(herd.Family))
	end)

	t.Test("offline: a quarter of at most two hours, nothing until a lamb's grown", function()
		local lamb = sheep({})
		local coins, matured = Economy.Offline({ lamb }, 100, 7200, 0.25)
		-- 45 s growing for nothing, then 55 s at 2/s, a quarter of it.
		t.Expect(coins).ToBe(110 * 0.25)
		t.Expect(#matured).ToBe(1)
		local capped = Economy.Offline({ adult({}) }, 100000, 7200, 0.25)
		t.Expect(capped).ToBe(7200 * 2 * 0.25)
	end)

	t.Test("the climb tier is the highest whose Reach the Climbing has", function()
		t.Expect(Economy.ClimbTier(0)).ToBe(1)
		t.Expect(Economy.ClimbTier(99)).ToBe(1)
		t.Expect(Economy.ClimbTier(100)).ToBe(2)
		t.Expect(Economy.ClimbTier(5000)).ToBe(4)
		t.Expect(Economy.ClimbTier(1e18)).ToBe(Olympus.Count)
	end)

	t.Test("wild rolls stay in range, and no wild lamb grows to Titan", function()
		local random = Random.new(7)
		for _ = 1, 500 do
			local rarity, weight, size = Economy.RollWild(random)
			t.Expect(rarity >= 1 and rarity <= 3).ToBe(true)
			t.Expect(weight >= 1 and weight <= 1.5).ToBe(true)
			t.Expect(size >= 1 and size <= 3).ToBe(true)
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

	t.Test("daily gifts: a week, cash and Climbing as minutes of income and walker, each at least its floor", function()
		t.Expect(#Economy.DailyWeek).ToBe(7)
		t.Expect(Economy.DailyWeek[4].Kind).ToBe("Lamb")
		t.Expect(Economy.DailyWeek[7].Kind).ToBe("Pegasus")
		-- A new player: the floors.
		t.Expect(Economy.DailyAmount(1, 0, 0)).ToBe(250)
		t.Expect(Economy.DailyAmount(2, 0, 0)).ToBe(150)
		t.Expect(Economy.DailyAmount(6, 0, 0)).ToBe(2500)
		-- The mock-up's player: 6,410.5 a second in the pen, a level-6 walker (9,000 a second).
		t.Expect(Economy.DailyAmount(1, 6410.5, 6)).ToBe(1153890)
		t.Expect(Economy.DailyAmount(2, 6410.5, 6)).ToBe(540000)
		t.Expect(Economy.DailyAmount(3, 6410.5, 6)).ToBe(3846300)
		t.Expect(Economy.DailyAmount(5, 6410.5, 6)).ToBe(1620000)
		t.Expect(Economy.DailyAmount(6, 6410.5, 6)).ToBe(11538900)
		t.Expect(Economy.DailyAmount(4, 6410.5, 6)).ToBe(0)
		t.Expect(Economy.DailyAmount(7, 6410.5, 6)).ToBe(0)
	end)

	t.Test("daily gifts: the next opens 20 hours after a claim", function()
		t.Expect(Economy.DailyReady(0, 1000)).ToBe(true)
		t.Expect(Economy.DailyReady(1000, 1000 + 20 * 3600 - 1)).ToBe(false)
		t.Expect(Economy.DailyReady(1000, 1000 + 20 * 3600)).ToBe(true)
	end)

	t.Test("the Pegasus Sheep earns one tier above the highest god stolen from", function()
		t.Expect(Economy.HighestStolen({})).ToBe(1)
		t.Expect(Economy.HighestStolen({ ["3"] = 2, ["8"] = 1, ["12"] = 0 })).ToBe(8)
		local tier = Economy.PegasusTier({ ["8"] = 1 })
		t.Expect(tier).ToBe(9)
		local pegasus = adult({ Family = "Pegasus", Tier = tier })
		local royal = adult({ Family = Olympus.Tiers[8].Family, Rarity = 3 })
		t.Expect(near(Economy.AdultIncome(pegasus), Economy.BaseIncome(9))).ToBe(true)
		-- About a Royal sheep of that god (bases round, so not to the cash).
		t.Expect(math.abs(Economy.AdultIncome(pegasus) / Economy.AdultIncome(royal) - 1) < 0.01).ToBe(true)
		t.Expect(Economy.Name(pegasus)).ToBe("Pegasus Sheep")
		t.Expect(Economy.Name(sheep({ Family = "Pegasus", Tier = tier }))).ToBe("Pegasus Lamb")
		t.Expect(Economy.FamilyOrder("Pegasus") > Economy.FamilyOrder("Thunder")).ToBe(true)
		t.Expect(GameConfig.Breeds.Pegasus ~= nil).ToBe(true)
	end)

	t.Test("the Pegasus Sheep can't go in the Merge Shrine", function()
		local three = {
			adult({ Id = "1", Family = "Pegasus", Tier = 5 }),
			adult({ Id = "2", Family = "Pegasus", Tier = 5 }),
			adult({ Id = "3", Family = "Pegasus", Tier = 5 }),
		}
		local ok, why = Economy.CanShrine(three)
		t.Expect(ok).ToBe(false)
		t.Expect(why).ToBe("Pegasus Sheep can't be merged")
	end)
end
