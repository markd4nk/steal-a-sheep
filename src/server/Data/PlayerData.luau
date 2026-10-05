--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)

export type Sheep = Economy.Sheep

export type Data = {
	SchemaVersion: number,
	Coins: number, -- fractions kept: income comes in fractions of a coin
	Receipts: { [string]: number },
	ClimbPower: number,
	WalkerLevel: number,
	Trails: { [string]: boolean }, -- owned, by Economy.Trails id
	Trail: string, -- the equipped one, "" for none
	PenSlots: number, -- earning slots, 3 to 12
	Sheep: { [string]: Sheep }, -- every owned sheep by id, equipped or stored
	NextId: number,
	Deliveries: { [string]: number }, -- successful deliveries by source tier ("1" to "12")
	Dex: { [string]: boolean }, -- families delivered at least once
	Tutorial: number, -- 0 until the first delivery, then 1; 2 once the stair walker was used
	LastSeen: number, -- os.time() of the last settlement, for offline earnings; 0 for a new player
}

local PlayerData = {}

PlayerData.SchemaVersion = 2

PlayerData.Template = {
	SchemaVersion = PlayerData.SchemaVersion,
	Coins = 0,
	Receipts = {},
	ClimbPower = 0,
	WalkerLevel = 0,
	Trails = {},
	Trail = "",
	PenSlots = Economy.StartPens,
	Sheep = {},
	NextId = 1,
	Deliveries = {},
	Dex = {},
	Tutorial = 0,
	LastSeen = 0,
} :: Data

-- migrations[n] upgrades data from schema n to n + 1, in place.
local migrations: { [number]: (data: any) -> () } = {}

-- Schema 2: a sheep's Burden (1 Light, 2 Stout, 3 Heavy) became a hidden Weight on a smooth range, each burden at its
-- band's middle. The size each sheep already rolled stays.
local BURDEN_WEIGHTS = { 1.05, 1.2, 1.35 }
migrations[1] = function(data: any)
	if type(data.Sheep) ~= "table" then
		return
	end
	for _, sheep in data.Sheep do
		if sheep.Weight == nil then
			sheep.Weight = BURDEN_WEIGHTS[sheep.Burden] or 1.05
		end
		sheep.Burden = nil
	end
end

local function isNatural(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value < 2 ^ 53 and value % 1 == 0
end

local function isAmount(value: any): boolean
	return type(value) == "number" and value == value and value >= 0 and value < math.huge
end

local function isWhole(value: any, min: number, max: number): boolean
	return isNatural(value) and value >= min and value <= max
end

local function validSheep(id: any, sheep: any): boolean
	return type(id) == "string"
		and type(sheep) == "table"
		and sheep.Id == id
		and type(sheep.Family) == "string"
		and isWhole(sheep.Rarity, 1, 3)
		and (isWhole(sheep.Burden, 1, 3) or (isAmount(sheep.Weight) and sheep.Weight >= 1))
		and isWhole(sheep.Size, 1, #Economy.Sizes)
		and isAmount(sheep.Grown)
		and isWhole(sheep.Rank, 0, Economy.MaxRank)
		and type(sheep.Locked) == "boolean"
		and isWhole(sheep.Slot, 0, Economy.MaxPens)
		and type(sheep.Pinned) == "boolean"
end

local function flags(value: any): boolean
	if type(value) ~= "table" then
		return false
	end
	for key, flag in value do
		if type(key) ~= "string" or type(flag) ~= "boolean" then
			return false
		end
	end
	return true
end

-- Checks saved data before anything touches it. Fields may be missing (Reconcile fills them);
-- fields that exist must have the right shape. Returns false instead of repairing: never reset progress.
function PlayerData.Validate(data: any): (boolean, string?)
	if type(data) ~= "table" then
		return false, "data is not a table"
	end
	local version = data.SchemaVersion
	if version ~= nil and (not isNatural(version) or version < 1 or version > PlayerData.SchemaVersion) then
		return false, `unsupported SchemaVersion {version}`
	end
	for _, field in { "Coins", "ClimbPower" } do
		if data[field] ~= nil and not isAmount(data[field]) then
			return false, `{field} is not an amount >= 0`
		end
	end
	for _, field in { "WalkerLevel", "PenSlots", "NextId", "Tutorial", "LastSeen" } do
		if data[field] ~= nil and not isNatural(data[field]) then
			return false, `{field} is not a whole number >= 0`
		end
	end
	if data.Receipts ~= nil then
		if type(data.Receipts) ~= "table" then
			return false, "Receipts is not a table"
		end
		for purchaseId, grantedAt in data.Receipts do
			if type(purchaseId) ~= "string" or not isNatural(grantedAt) then
				return false, "Receipts has an invalid entry"
			end
		end
	end
	if data.Trails ~= nil and not flags(data.Trails) then
		return false, "Trails is not a set"
	end
	if data.Dex ~= nil and not flags(data.Dex) then
		return false, "Dex is not a set"
	end
	if data.Trail ~= nil and type(data.Trail) ~= "string" then
		return false, "Trail is not a string"
	end
	if data.Deliveries ~= nil then
		if type(data.Deliveries) ~= "table" then
			return false, "Deliveries is not a table"
		end
		for tier, count in data.Deliveries do
			if type(tier) ~= "string" or not isNatural(count) then
				return false, "Deliveries has an invalid entry"
			end
		end
	end
	if data.Sheep ~= nil then
		if type(data.Sheep) ~= "table" then
			return false, "Sheep is not a table"
		end
		for id, sheep in data.Sheep do
			if not validSheep(id, sheep) then
				return false, `Sheep has an invalid entry {tostring(id)}`
			end
		end
	end
	return true, nil
end

function PlayerData.Migrate(data: any)
	local version = if data.SchemaVersion == nil then 1 else data.SchemaVersion
	while version < PlayerData.SchemaVersion do
		local migrate = migrations[version]
		assert(migrate, `No migration from schema {version}`)
		migrate(data)
		version += 1
		data.SchemaVersion = version
	end
	data.SchemaVersion = version
end

return PlayerData
