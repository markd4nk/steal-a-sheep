--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)

type Sheep = Economy.Sheep
type Flock = { [string]: Sheep }

-- Pen slots and the flock's numbers, as pure functions on a player's saved flock (FlockService, tests).
local Roster = {}

function Roster.Count(flock: Flock): number
	local count = 0
	for _ in flock do
		count += 1
	end
	return count
end

function Roster.IsEquipped(sheep: Sheep, penSlots: number): boolean
	return sheep.Slot >= 1 and sheep.Slot <= penSlots
end

-- What the equipped sheep earn a second together (before the 2x Money pass).
function Roster.Income(flock: Flock, penSlots: number): number
	local best = Economy.BestIncome(flock)
	local total = 0
	for _, sheep in flock do
		if Roster.IsEquipped(sheep, penSlots) then
			total += Economy.Income(sheep, best)
		end
	end
	return total
end

-- The lowest pen slot nobody stands in, or nil when the pen is full.
function Roster.FreeSlot(flock: Flock, penSlots: number): number?
	local taken: { [number]: boolean } = {}
	for _, sheep in flock do
		taken[sheep.Slot] = true
	end
	for slot = 1, penSlots do
		if not taken[slot] then
			return slot
		end
	end
	return nil
end

-- Makes slots consistent after a load: none past the pen's size, none shared (the later id goes to storage).
function Roster.Normalize(flock: Flock, penSlots: number)
	local ids: { string } = {}
	for id in flock do
		table.insert(ids, id)
	end
	table.sort(ids, function(a: string, b: string)
		return (tonumber(a) or 0) < (tonumber(b) or 0)
	end)
	local taken: { [number]: boolean } = {}
	for _, id in ids do
		local sheep = flock[id]
		if sheep.Slot > penSlots or taken[sheep.Slot] then
			sheep.Slot = 0
			sheep.Pinned = false
		end
		if sheep.Slot > 0 then
			taken[sheep.Slot] = true
		end
	end
end

-- Equip Best: pinned sheep keep their slots; the rest of the slots go to the highest current earners, ties to the
-- older sheep (lower id). Sheep that stay equipped keep the slot they had.
function Roster.EquipBest(flock: Flock, penSlots: number)
	local taken: { [number]: boolean } = {}
	local candidates: { Sheep } = {}
	for _, sheep in flock do
		if sheep.Pinned and Roster.IsEquipped(sheep, penSlots) then
			taken[sheep.Slot] = true
		else
			sheep.Pinned = false
			table.insert(candidates, sheep)
		end
	end
	local best = Economy.BestIncome(flock)
	table.sort(candidates, function(a: Sheep, b: Sheep)
		local incomeA, incomeB = Economy.Income(a, best), Economy.Income(b, best)
		if incomeA ~= incomeB then
			return incomeA > incomeB
		end
		return (tonumber(a.Id) or 0) < (tonumber(b.Id) or 0)
	end)
	local free = 0
	for slot = 1, penSlots do
		if not taken[slot] then
			free += 1
		end
	end
	local chosen: { Sheep } = {}
	for index, sheep in candidates do
		if index <= free then
			table.insert(chosen, sheep)
		else
			sheep.Slot = 0
		end
	end
	-- Chosen sheep already standing in a free slot stay there; the others take what's left.
	local moving: { Sheep } = {}
	for _, sheep in chosen do
		if Roster.IsEquipped(sheep, penSlots) and not taken[sheep.Slot] then
			taken[sheep.Slot] = true
		else
			table.insert(moving, sheep)
		end
	end
	local slot = 1
	for _, sheep in moving do
		while taken[slot] do
			slot += 1
		end
		sheep.Slot = slot
		taken[slot] = true
	end
end

return table.freeze(Roster)
