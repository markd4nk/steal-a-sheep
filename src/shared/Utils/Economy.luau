--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Olympus = require(ReplicatedStorage.Config.Olympus)

-- Every formula of the design's economy, as pure functions so the server, the UI and the tests agree. All values are
-- the design's proposed prototype settings ("Steal a Sheep Game Design Document Draft.md").

export type Sheep = {
	Id: string,
	Family: string,
	Rarity: number, -- 1 Ordinary, 2 Rare, 3 Royal
	Burden: number, -- 1 Light, 2 Stout, 3 Heavy
	Size: number, -- 1 Standard, 2 Large, 3 Giant: rolled when the wild lamb is made, hidden until it's grown
	Grown: number, -- seconds it has grown (only while it's in a pen slot)
	Rank: number, -- merge rank, 0 to 2
	Locked: boolean,
	Slot: number, -- its pen slot, 0 when stored
	Pinned: boolean, -- kept in its slot by Equip Best
	Tutorial: boolean?, -- the first lamb, which grows faster
}

export type Rarity = { Name: string, Multiplier: number, Chance: number, Color: Color3 }
export type Burden = { Name: string, Chance: number, Carry: { number }, Sizes: { number }, Scale: number }
export type Size = { Name: string, Multiplier: number, Scale: number }
export type Trail = { Id: string, Name: string, Cost: number, Multiplier: number, Color: Color3 }

local Economy = {}

Economy.Rarities = table.freeze({
	{ Name = "Ordinary", Multiplier = 1, Chance = 80, Color = Color3.fromRGB(196, 202, 214) },
	{ Name = "Rare", Multiplier = 1.5, Chance = 18, Color = Color3.fromRGB(90, 170, 255) },
	{ Name = "Royal", Multiplier = 2.5, Chance = 2, Color = Color3.fromRGB(255, 196, 40) },
} :: { Rarity })

-- Carry: the movement multiplier at the sheep's tier's Reach, Light and Heavy targets. Sizes: percent odds of a
-- Standard, Large and Giant adult. Scale: the wild lamb's size, a clue to its burden.
Economy.Burdens = table.freeze({
	{ Name = "Light", Chance = 70, Carry = { 0.84, 0.92, 0.97 }, Sizes = { 89, 10, 1 }, Scale = 0.6 },
	{ Name = "Stout", Chance = 25, Carry = { 0.72, 0.84, 0.95 }, Sizes = { 50, 47, 3 }, Scale = 0.7 },
	{ Name = "Heavy", Chance = 5, Carry = { 0.60, 0.76, 0.94 }, Sizes = { 0, 80, 20 }, Scale = 0.8 },
} :: { Burden })

Economy.Sizes = table.freeze({
	{ Name = "Standard", Multiplier = 1, Scale = 1 },
	{ Name = "Large", Multiplier = 1.5, Scale = 1.35 },
	{ Name = "Giant", Multiplier = 2.5, Scale = 1.7 },
} :: { Size })

Economy.RankNames = table.freeze({ [0] = "", [1] = "Merged", [2] = "Ascended" }) :: { [number]: string }
Economy.MaxRank = 2
Economy.LambShare = 0.5 -- a lamb earns this share of its family's base, times its fleece
Economy.TutorialGrowth = 30
Economy.SellSeconds = 15
Economy.DexRewardSeconds = 30
Economy.TutorialCoins = 60
Economy.TutorialClimb = 25
Economy.StartPens = 3
Economy.MaxPens = 12
Economy.MergeAfterDeliveries = 3

-- Climb Power a second on the stair walker, by its level (0 is the free one).
Economy.WalkerRates = table.freeze({ 2, 12, 40, 160, 640, 2200, 9000, 36000, 100000, 300000, 900000, 1800000 })
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

-- Half up, as the design's tables round (4687.5 -> 4688).
function Economy.Round(value: number): number
	return math.floor(value + 0.5)
end

function Economy.Tier(family: string): Olympus.Tier
	local tier = Olympus.ByFamily[family]
	assert(tier, `Economy: no tier for family {family}`)
	return tier
end

-- round(2 x 2.5^(tier - 1)): 2, 5, 13, 31, 78 ... 47,684.
function Economy.BaseIncome(tier: number): number
	return Economy.Round(2 * 2.5 ^ (tier - 1))
end

-- Reach, Light and Heavy Climb Power for a tier: Light 1.5x and Heavy 2.25x its reach; Demeter is 0, 25, 60.
function Economy.Targets(tier: number): (number, number, number)
	if tier == 1 then
		return 0, 25, 60
	end
	local reach = Olympus.Tiers[tier].Reach
	return reach, reach * 1.5, reach * 2.25
end

-- The share of normal speed and acceleration a carrier keeps: the burden's three values at the source tier's Reach,
-- Light and Heavy targets, straight lines between them, the first below Reach and the last above Heavy.
function Economy.CarryMultiplier(burden: number, climb: number, tier: number): number
	local carry = Economy.Burdens[burden].Carry
	local reach, light, heavy = Economy.Targets(tier)
	if climb <= reach then
		return carry[1]
	elseif climb <= light then
		return carry[1] + (carry[2] - carry[1]) * (climb - reach) / (light - reach)
	elseif climb <= heavy then
		return carry[2] + (carry[3] - carry[2]) * (climb - light) / (heavy - light)
	end
	return carry[3]
end

-- The highest tier a player may climb into: each needs its reach in Climb Power and one delivery from the tier below.
-- Tier 1 is always open. Neither ever goes down, so a tier stays open.
function Economy.Unlocked(climb: number, deliveries: { [string]: number }): number
	local unlocked = 1
	for tier = 2, Olympus.Count do
		if climb >= Olympus.Tiers[tier].Reach and (deliveries[tostring(tier - 1)] or 0) > 0 then
			unlocked = tier
		else
			break
		end
	end
	return unlocked
end

function Economy.TotalDeliveries(deliveries: { [string]: number }): number
	local total = 0
	for _, count in deliveries do
		total += count
	end
	return total
end

-- "Train for Light sheep" and so on: which of a tier's three stages a Climb Power reaches.
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

-- A lamb's adult income from its smallest to its biggest possible size, for its burden (its size stays hidden).
function Economy.FutureRange(sheep: Sheep): (number, number)
	local odds = Economy.Burdens[sheep.Burden].Sizes
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

-- Pen slot n (4 to 12): round(300 x 2.5^(n - 4)).
function Economy.PenCost(slot: number): number?
	if slot > Economy.MaxPens then
		return nil
	end
	return Economy.Round(300 * 2.5 ^ (slot - 4))
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

-- A wild lamb's rolls: fleece rarity, burden, and its adult size (from its burden's odds).
function Economy.RollWild(random: Random): (number, number, number)
	local rarity = pick(random, { Economy.Rarities[1].Chance, Economy.Rarities[2].Chance, Economy.Rarities[3].Chance })
	local burden = pick(random, { Economy.Burdens[1].Chance, Economy.Burdens[2].Chance, Economy.Burdens[3].Chance })
	local size = pick(random, Economy.Burdens[burden].Sizes)
	return rarity, burden, size
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
		Burden = first.Burden,
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

-- The offline settlement: the design's 25% of up to two hours of income, juvenile rate until each lamb matures in
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

-- The model scale a sheep shows at: a lamb's burden size while it's young, its adult size after.
function Economy.Scale(sheep: Sheep, sheepSize: number): number
	if Economy.IsAdult(sheep) then
		return sheepSize * Economy.Sizes[sheep.Size].Scale
	end
	return sheepSize * Economy.Burdens[sheep.Burden].Scale
end

return table.freeze(Economy)
