--!strict
-- Writes DESIGN/ui/data.json for the HTML mock-ups: every family's token colours (GameConfig.Breeds, as
-- UIController/SheepIcon paints them), the tiers, and a sample flock whose names, incomes and sell prices come from the
-- game's own Economy, so a mock-up's numbers are the game's. Rerun it after changing a family, a formula or the flock.
--
--   lune run DESIGN/ui/export-data.luau

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local modules: { [string]: any } = {}

-- Loads a shared module with what it needs: Roblox's datatypes, and `require` of ReplicatedStorage.Config.Olympus.
local function load(name: string, path: string): any
	local replicated = { Config = { Olympus = "Olympus" } }
	local chunk = luau.load(fs.readFile(path), {
		debugName = path,
		environment = {
			Color3 = roblox.Color3,
			Enum = roblox.Enum,
			game = {
				GetService = function(_self: any, _service: string)
					return replicated
				end,
			},
			require = function(key: string)
				return assert(modules[key], `export-data: {name} requires {key}, not loaded`)
			end,
		},
	})
	modules[name] = chunk()
	return modules[name]
end

local GameConfig = load("GameConfig", "src/shared/Config/GameConfig.luau")
local Olympus = load("Olympus", "src/shared/Config/Olympus.luau")
local Economy = load("Economy", "src/shared/Utils/Economy.luau")

local function hex(color: any): string
	return string.format(
		"#%02x%02x%02x",
		math.round(color.R * 255),
		math.round(color.G * 255),
		math.round(color.B * 255)
	)
end

local families = {}
for _, tier in Olympus.Tiers do
	local breed = GameConfig.Breeds[tier.Family]
	local mutation = if breed.Mutation then GameConfig.Mutations[breed.Mutation] else nil
	families[tier.Family] = {
		Tier = tier.Tier,
		God = tier.God,
		Name = tier.FamilyName,
		Short = (string.gsub(tier.FamilyName, " Sheep$", "")),
		Base = Economy.BaseIncome(tier.Tier),
		Wool = hex(if mutation then mutation.Color else breed.WoolColor),
		Face = hex(breed.FaceColor),
		Legs = hex(breed.LegColor),
		Spots = if breed.WoolSpotColor and not mutation then hex(breed.WoolSpotColor) else nil,
		Horn = if breed.HornStyle then hex(breed.HornColor) else nil,
		Rainbow = if mutation and mutation.Rainbow then true else nil,
	}
end

-- A player part way up the mountain (tiers 1 to 8 open, the pen's 8 to start): Equip Best's eight best earning in
-- the pen (two lambs among them, growing), the rest stored. Weight only matters for a lamb's size odds, so it's left at
-- the lightest. Each row: family, fleece, size (0 a lamb), merge rank, pen slot (0 stored), locked.
local PEN_SLOTS = 8
local flockSpec = {
	{ "Laurel", 1, 3, 0, 1 },
	{ "Laurel", 1, 1, 0, 2 },
	{ "Sun", 2, 2, 0, 3 },
	{ "Rose", 1, 3, 0, 4 },
	{ "Sun", 1, 0, 0, 5 },
	{ "War", 1, 2, 0, 6 },
	{ "Rose", 1, 0, 0, 7 },
	{ "Ember", 1, 1, 1, 8 },
	{ "War", 1, 1, 0, 0 },
	{ "Ember", 1, 2, 0, 0 },
	{ "Moon", 3, 1, 0, 0, true },
	{ "Moon", 1, 2, 0, 0 },
	{ "Moon", 1, 1, 0, 0 },
	{ "Grape", 2, 1, 0, 0 },
	{ "Grape", 1, 1, 0, 0 },
	{ "Meadow", 1, 2, 0, 0 },
	{ "Meadow", 1, 1, 0, 0 },
	{ "Meadow", 1, 1, 0, 0 },
}

local flock = {}
for index, spec in flockSpec do
	local family, rarity, size, rank, slot, locked = spec[1], spec[2], spec[3], spec[4], spec[5], spec[6]
	local lamb = size == 0
	local sheep = {
		Id = tostring(index),
		Family = family,
		Rarity = rarity,
		Weight = 1,
		Size = if lamb then 1 else size,
		Grown = 0,
		Rank = rank,
		Locked = locked == true,
		Slot = slot,
		Pinned = false,
	}
	if not lamb then
		sheep.Grown = Economy.GrowthSeconds(sheep)
	end
	table.insert(flock, {
		Id = sheep.Id,
		Family = family,
		Rarity = rarity,
		Size = if lamb then 0 else size,
		SizeName = if lamb then "Lamb" else Economy.Sizes[size].Name,
		Rank = rank,
		RankName = Economy.RankNames[rank],
		Locked = sheep.Locked,
		Slot = slot,
		Adult = not lamb,
		Name = Economy.Name(sheep),
		Income = Economy.Income(sheep),
		Sell = Economy.SellValue(sheep),
	})
end

local rarities = {}
for _, rarity in Economy.Rarities do
	table.insert(rarities, { Name = rarity.Name, Multiplier = rarity.Multiplier })
end

local data = {
	Families = families,
	Rarities = rarities,
	GoldWool = hex(GameConfig.Mutations.Gold.Color),
	SellSeconds = Economy.SellSeconds,
	PenSlots = PEN_SLOTS,
	Flock = flock,
}

fs.writeFile("DESIGN/ui/data.json", serde.encode("json", data, true) .. "\n")
print(`Wrote DESIGN/ui/data.json: {#Olympus.Tiers} families, a flock of {#flock}`)
