--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Olympus = require(ReplicatedStorage.Config.Olympus)

-- Every formula of the economy, as pure functions so the server, the UI and the tests agree. The values are the
-- first build's prototype settings: tune them freely.

export type Sheep = {
	Id: string,
	Family: string,
	Rarity: number, -- 1 Ordinary, 2 Rare, 3 Royal
	Weight: number, -- hidden, 1 (lightest) and up: slows its carrier and tilts its size odds (Economy.RollWeight)
	Size: number, -- 1 Standard to 4 Titan: rolled from its weight's odds when the lamb is made, hidden until grown
	Grown: number, -- seconds it has grown (only while it's in a pen slot)
	Rank: number, -- merge rank, 0 to 2
	Locked: boolean,
	Slot: number, -- its place in the pen (1 to PenSlots: it stands in the plot and earns), 0 when stored
	Pinned: boolean, -- kept in the pen by Equip Best
	Tutorial: boolean?, -- the first lamb, which grows faster
	-- Where it was put down, in studs from its owner's plot's middle (+X towards the gate): it roams round this spot.
	-- Nil until it's been put down; such a sheep gets a free spot in the pen.
	HomeX: number?,
	HomeZ: number?,
}

export type Rarity = { Name: string, Multiplier: number, Chance: number, Color: Color3 }
export type WeightBand = { From: number, To: number, Chance: number, LuckyChance: number }
export type Size = { Name: string, Multiplier: number, Scale: number }
export type Trail = { Id: string, Name: string, Cost: number, Multiplier: number, Color: Color3 }

local Economy = {}

Economy.Rarities = table.freeze({
	{ Name = "Ordinary", Multiplier = 1, Chance = 80, Color = Color3.fromRGB(196, 202, 214) },
	{ Name = "Rare", Multiplier = 1.5, Chance = 18, Color = Color3.fromRGB(90, 170, 255) },
	{ Name = "Royal", Multiplier = 2.5, Chance = 2, Color = Color3.fromRGB(255, 196, 40) },
} :: { Rarity })

-- A lamb's hidden weight: players never see it, they feel it. The carried lamb's tier's Reach counts that many times
-- bigger in its carrier's speed (Economy.Ratio), and heavier lambs tend to grow bigger (Economy.SizeOdds). A roll
-- lands in Huge with its chance, Heavy with its, otherwise Normal; `luck` (0 to 1, Economy.RollWeight) moves each
-- chance towards its LuckyChance. Wild lambs roll with no luck: never Huge, about 1.06 on average, so an average lamb
-- leaves its thief about 95% of the god's speed at the tier's Reach and only the lightest one matches it.
Economy.WeightBands = table.freeze({
	Normal = { From = 1, To = 1.1, Chance = 0, LuckyChance = 0 },
	Heavy = { From = 1.1, To = 1.5, Chance = 0.05, LuckyChance = 0.6 },
	Huge = { From = 1.5, To = 3, Chance = 0, LuckyChance = 0.03 },
} :: { [string]: WeightBand })

-- Percent odds of a Standard, Large, Giant and Titan adult at each anchor weight, straight lines between them and the
-- last above it. A light lamb can still grow Large or Giant, just less often; Titan needs a Huge one.
Economy.SizeAnchors = table.freeze({
	{ Weight = 1, Odds = { 85, 14, 1, 0 } },
	{ Weight = 1.1, Odds = { 60, 35, 5, 0 } },
	{ Weight = 1.5, Odds = { 15, 60, 25, 0 } },
	{ Weight = 3, Odds = { 0, 20, 50, 30 } },
} :: { { Weight: number, Odds: { number } } })

Economy.Sizes = table.freeze({
	{ Name = "Standard", Multiplier = 1, Scale = 1 },
	{ Name = "Large", Multiplier = 1.5, Scale = 1.35 },
	{ Name = "Giant", Multiplier = 2.5, Scale = 1.7 },
	{ Name = "Titan", Multiplier = 4, Scale = 2.1 },
} :: { Size })

Economy.RankNames = table.freeze({ [0] = "", [1] = "Merged", [2] = "Ascended" }) :: { [number]: string }
Economy.MaxRank = 2
Economy.LambShare = 0.5 -- a lamb earns this share of its family's base, times its fleece
Economy.TutorialGrowth = 30
Economy.SellSeconds = 15
Economy.DexRewardSeconds = 30
Economy.TutorialCoins = 60
Economy.TutorialClimb = 25
-- How many sheep the pen holds: 8 to start, bought one at a time up to 20 (the user, 2026-10-05: like Steal a
-- Brainrot's base, and very expensive to grow).
Economy.StartPens = 8
Economy.MaxPens = 20
Economy.MergeAfterDeliveries = 3
Economy.GodShare = 0.8 -- a god's set speed, as a share of its tier's SlideSpeed
Economy.SafeZoneCap = 7 -- the most times normal speed anyone walks below the safety line

-- Climbing a second on the stair walker, by its level (0 is the free one). Each level covers the gap between the
-- next two tiers' reach in about a minute, and the last carries Zeus's Heavy target.
Economy.WalkerRates = table.freeze({
	2,
	12,
	40,
	160,
	640,
	2200,
	9000,
	36000,
	100000,
	300000,
	900000,
	1800000,
	5e6,
	13e6,
	32e6,
	80e6,
	200e6,
	500e6,
	1.3e9,
	3e9,
	7.8e9,
	20e9,
	48e9,
	120e9,
	300e9,
	770e9,
	1.9e12,
	4.8e12,
	12e12,
	25e12,
})
Economy.MaxWalker = #Economy.WalkerRates - 1

Economy.Trails = table.freeze({
	{ Id = "Dust", Name = "Dust Trail", Cost = 250, Multiplier = 1.25, Color = Color3.fromRGB(214, 184, 140) },
	{ Id = "Laurel", Name = "Laurel Trail", Cost = 2500, Multiplier = 1.5, Color = Color3.fromRGB(110, 190, 90) },
	{ Id = "Sunlight", Name = "Sunlight Trail", Cost = 25000, Multiplier = 2, Color = Color3.fromRGB(255, 214, 80) },
	{ Id = "Storm", Name = "Storm Trail", Cost = 250000, Multiplier = 3, Color = Color3.fromRGB(140, 150, 255) },
} :: { Trail })

local trailsById: { [string]: Trail } = {}
for _, trail in Economy.Trails do
	trailsById[trail.Id] = trail
end

-- Half up (4687.5 -> 4688).
function Economy.Round(value: number): number
	return math.floor(value + 0.5)
end

function Economy.Tier(family: string): Olympus.Tier
	local tier = Olympus.ByFamily[family]
	assert(tier, `Economy: no tier for family {family}`)
	return tier
end

-- round(2 x 2.5^(tier - 1)): 2, 5, 13, 31, 78 ... 47,684 at tier 12 ... about 694 billion at Zeus's 30.
function Economy.BaseIncome(tier: number): number
	return Economy.Round(2 * 2.5 ^ (tier - 1))
end

-- Reach, Light and Heavy Climbing for a tier: from its Reach the lightest lamb's thief matches its god, from Reach
-- times the heaviest wild weight (1.5) any wild lamb's does.
function Economy.Targets(tier: number): (number, number, number)
	local reach = Olympus.Tiers[tier].Reach
	return reach, reach * Economy.WeightBands.Normal.From, reach * Economy.WeightBands.Heavy.To
end

-- How many times their need a player has on a tier: Climbing / (its Reach x the weight carried, 1 empty-handed).
function Economy.Ratio(climb: number, tier: number, weight: number): number
	local reach = Olympus.Tiers[math.clamp(tier, 1, Olympus.Count)].Reach
	return math.max(climb, 0) / math.max(reach * weight, 1e-9)
end

-- Times normal speed a ratio gives: the ratio itself below 1, then one more for every 4x (each tier outgrown, as each
-- Reach is about four times the last). Tier 1 never gives less than normal speed.
function Economy.SpeedFactor(ratio: number, tier: number): number
	local factor = if ratio < 1 then ratio else 1 + math.log(ratio, 4)
	return if tier <= 1 then math.max(factor, 1) else factor
end

-- A god's one set speed for the whole chase.
function Economy.GodSpeed(tier: number): number
	return Olympus.Tiers[math.clamp(tier, 1, Olympus.Count)].SlideSpeed * Economy.GodShare
end

-- A slide's speed, set when it starts and kept all the way down: the god's speed times the speed factor, for the
-- carried lamb's tier and weight, or the tier slid from (weight 1) empty-handed. At the Reach the lightest lamb's thief
-- matches the god and its head start gets them away; an average lamb leaves about 95%.
function Economy.EscapeSpeed(climb: number, tier: number, weight: number): number
	return Economy.GodSpeed(tier) * Economy.SpeedFactor(Economy.Ratio(climb, tier, weight), tier)
end

-- A hidden weight: Normal, Heavy or Huge band (Economy.WeightBands), anywhere in it, luck also leaning it towards the
-- band's top. `luck` 0 (nil) is a wild lamb's; up to 1 makes heavy ones likelier and opens the Huge tail.
function Economy.RollWeight(random: Random, luck: number?): number
	local lucky = math.clamp(luck or 0, 0, 1)
	local bands = Economy.WeightBands
	local function chance(band: WeightBand): number
		return band.Chance + (band.LuckyChance - band.Chance) * lucky
	end
	local roll = random:NextNumber()
	local band = bands.Normal
	if roll < chance(bands.Huge) then
		band = bands.Huge
	elseif roll < chance(bands.Huge) + chance(bands.Heavy) then
		band = bands.Heavy
	end
	local share = random:NextNumber() ^ (1 / (1 + 2 * lucky))
	return band.From + (band.To - band.From) * share
end

-- Percent odds of each size (Economy.Sizes) for a weight, from Economy.SizeAnchors.
function Economy.SizeOdds(weight: number): { number }
	local anchors = Economy.SizeAnchors
	if weight <= anchors[1].Weight then
		return table.clone(anchors[1].Odds)
	end
	for index = 1, #anchors - 1 do
		local a, b = anchors[index], anchors[index + 1]
		if weight <= b.Weight then
			local t = (weight - a.Weight) / (b.Weight - a.Weight)
			local odds = {}
			for size, chance in a.Odds do
				odds[size] = chance + (b.Odds[size] - chance) * t
			end
			return odds
		end
	end
	return table.clone(anchors[#anchors].Odds)
end

-- A lamb's size before it grows, a clue to its weight: 0.6 of an adult at the lightest, 0.8 at 1.5, at most 1.
function Economy.LambScale(weight: number): number
	return math.min(0.6 + 0.4 * (weight - 1), 1)
end

-- The highest tier whose Reach a Climbing has (normal speed there or better): what the HUD's goals aim at.
function Economy.ClimbTier(climb: number): number
	local reached = 1
	for tier = 2, Olympus.Count do
		if climb >= Olympus.Tiers[tier].Reach then
			reached = tier
		else
			break
		end
	end
	return reached
end

function Economy.TotalDeliveries(deliveries: { [string]: number }): number
	local total = 0
	for _, count in deliveries do
		total += count
	end
	return total
end

-- Which of a tier's stages a Climbing reaches: below its Reach, the lightest lambs, the heaviest wild ones.
function Economy.Readiness(climb: number, tier: number): string
	local reach, light, heavy = Economy.Targets(tier)
	if climb < reach then
		return "Locked"
	elseif climb < light then
		return "Reach"
	elseif climb < heavy then
		return "Light"
	end
	return "Heavy"
end

function Economy.GrowthSeconds(sheep: Sheep): number
	if sheep.Tutorial then
		return Economy.TutorialGrowth
	end
	return 45 + 15 * (Economy.Tier(sheep.Family).Tier - 1)
end

function Economy.IsAdult(sheep: Sheep): boolean
	return sheep.Grown >= Economy.GrowthSeconds(sheep)
end

function Economy.AdultIncome(sheep: Sheep): number
	local base = Economy.BaseIncome(Economy.Tier(sheep.Family).Tier)
	return base * Economy.Rarities[sheep.Rarity].Multiplier * Economy.Sizes[sheep.Size].Multiplier * 3 ^ sheep.Rank
end

function Economy.LambIncome(sheep: Sheep): number
	local base = Economy.BaseIncome(Economy.Tier(sheep.Family).Tier)
	return base * Economy.LambShare * Economy.Rarities[sheep.Rarity].Multiplier
end

-- What it earns a second in a pen slot right now.
function Economy.Income(sheep: Sheep): number
	return if Economy.IsAdult(sheep) then Economy.AdultIncome(sheep) else Economy.LambIncome(sheep)
end

-- A lamb's adult income from its smallest to its biggest possible size, for its weight (its size stays hidden).
function Economy.FutureRange(sheep: Sheep): (number, number)
	local odds = Economy.SizeOdds(sheep.Weight)
	local low, high = math.huge, 0
	for size, chance in odds do
		if chance > 0 then
			local copy = table.clone(sheep)
			copy.Size = size
			local income = Economy.AdultIncome(copy)
			low = math.min(low, income)
			high = math.max(high, income)
		end
	end
	return low, high
end

function Economy.SellValue(sheep: Sheep): number
	return Economy.Round(Economy.SellSeconds * Economy.Income(sheep))
end

function Economy.DexReward(tier: number): number
	return Economy.DexRewardSeconds * Economy.BaseIncome(tier)
end

-- The upgrade from walker level L to L + 1: round(120 x 2.5^L).
function Economy.WalkerCost(level: number): number?
	if level >= Economy.MaxWalker then
		return nil
	end
	return Economy.Round(120 * 2.5 ^ level)
end

function Economy.WalkerRate(level: number): number
	return Economy.WalkerRates[math.clamp(level, 0, Economy.MaxWalker) + 1]
end

-- Room for sheep n (9 to 20): round(25,000 x 6^(n - 9)): 25K, 150K, 900K, 5.4M ... about 9 trillion for the 20th.
function Economy.PenCost(slot: number): number?
	if slot > Economy.MaxPens or slot <= Economy.StartPens then
		return nil
	end
	return Economy.Round(25000 * 6 ^ (slot - 9))
end

function Economy.Trail(id: string?): Trail?
	return if id then trailsById[id] else nil
end

function Economy.TrainingRate(walkerLevel: number, trail: string?): number
	local equipped = Economy.Trail(trail)
	return Economy.WalkerRate(walkerLevel) * (if equipped then equipped.Multiplier else 1)
end

local function pick(random: Random, weights: { number }): number
	local total = 0
	for _, weight in weights do
		total += weight
	end
	local roll = random:NextNumber(0, total)
	for index, weight in weights do
		if roll < weight then
			return index
		end
		roll -= weight
	end
	-- Float rounding at the very top: the last entry with any weight.
	for index = #weights, 1, -1 do
		if weights[index] > 0 then
			return index
		end
	end
	return 1
end

-- A size from a weight's odds (Economy.SizeOdds).
function Economy.RollSize(random: Random, weight: number): number
	return pick(random, Economy.SizeOdds(weight))
end

-- A wild lamb's rolls: fleece rarity, weight (no luck), and its adult size (from its weight's odds).
function Economy.RollWild(random: Random): (number, number, number)
	local rarity = pick(random, { Economy.Rarities[1].Chance, Economy.Rarities[2].Chance, Economy.Rarities[3].Chance })
	local weight = Economy.RollWeight(random)
	return rarity, weight, Economy.RollSize(random, weight)
end

-- Three sheep merge when they're unlocked adults of one family, fleece and rank below the top. Returns why not.
function Economy.CanMerge(sheep: { Sheep }): (boolean, string?)
	if #sheep ~= 3 then
		return false, "Pick three sheep"
	end
	local first = sheep[1]
	local ids: { [string]: boolean } = {}
	for _, entry in sheep do
		if ids[entry.Id] then
			return false, "Pick three different sheep"
		end
		ids[entry.Id] = true
		if entry.Locked then
			return false, "Unlock it first"
		end
		if not Economy.IsAdult(entry) then
			return false, "Lambs can't merge yet"
		end
		if entry.Family ~= first.Family or entry.Rarity ~= first.Rarity or entry.Rank ~= first.Rank then
			return false, "Same family, fleece and rank"
		end
	end
	if first.Rank >= Economy.MaxRank then
		return false, "Already Ascended"
	end
	return true, nil
end

-- The merged sheep (without an Id): the family and fleece kept, the biggest size, one rank up, already grown.
function Economy.MergeResult(sheep: { Sheep }): Sheep
	local size = 1
	for _, entry in sheep do
		size = math.max(size, entry.Size)
	end
	local first = sheep[1]
	return {
		Id = "",
		Family = first.Family,
		Rarity = first.Rarity,
		Weight = first.Weight,
		Size = size,
		Grown = Economy.GrowthSeconds(first),
		Rank = first.Rank + 1,
		Locked = false,
		Slot = 0,
		Pinned = false,
	}
end

-- Coins an equipped sheep earns over `seconds`, growing as it goes (lamb rate until it's grown, adult rate after).
-- Returns the coins and the seconds it grew.
function Economy.Earn(sheep: Sheep, seconds: number): (number, number)
	if seconds <= 0 then
		return 0, 0
	end
	local need = Economy.GrowthSeconds(sheep)
	local lambSeconds = math.clamp(need - sheep.Grown, 0, seconds)
	local coins = lambSeconds * Economy.LambIncome(sheep) + (seconds - lambSeconds) * Economy.AdultIncome(sheep)
	return coins, seconds
end

-- The offline settlement: 25% of up to two hours of income, juvenile rate until each lamb matures in
-- that window; growth itself runs for the whole time away. Mutates each sheep's Grown. Returns the coins and the
-- sheep that grew up meanwhile.
function Economy.Offline(equipped: { Sheep }, elapsed: number, maxSeconds: number, share: number): (number, { Sheep })
	local coins = 0
	local matured: { Sheep } = {}
	local credited = math.clamp(elapsed, 0, maxSeconds)
	for _, sheep in equipped do
		local wasAdult = Economy.IsAdult(sheep)
		local earned = Economy.Earn(sheep, credited)
		coins += earned
		sheep.Grown = math.min(sheep.Grown + math.max(elapsed, 0), Economy.GrowthSeconds(sheep))
		if not wasAdult and Economy.IsAdult(sheep) then
			table.insert(matured, sheep)
		end
	end
	return coins * share, matured
end

-- The name a sheep goes by: "Large Royal Meadow Sheep", "Ascended Grape Sheep", "Meadow Lamb".
function Economy.Name(sheep: Sheep, showSize: boolean?): string
	local tier = Economy.Tier(sheep.Family)
	local parts: { string } = {}
	if sheep.Rank > 0 then
		table.insert(parts, Economy.RankNames[sheep.Rank])
	end
	local adult = Economy.IsAdult(sheep)
	if adult and showSize ~= false and sheep.Size > 1 then
		table.insert(parts, Economy.Sizes[sheep.Size].Name)
	end
	if sheep.Rarity > 1 then
		table.insert(parts, Economy.Rarities[sheep.Rarity].Name)
	end
	if adult then
		table.insert(parts, tier.FamilyName)
	else
		table.insert(parts, (string.gsub(tier.FamilyName, "Sheep$", "Lamb")))
	end
	return table.concat(parts, " ")
end

-- The model scale a sheep shows at: its weight's lamb size while it's young, its adult size after.
function Economy.Scale(sheep: Sheep, sheepSize: number): number
	if Economy.IsAdult(sheep) then
		return sheepSize * Economy.Sizes[sheep.Size].Scale
	end
	return sheepSize * Economy.LambScale(sheep.Weight)
end

return table.freeze(Economy)
