--!strict

-- A board's numbers: how they're kept in an OrderedDataStore, and the rows a board shows.
--
-- An OrderedDataStore holds whole numbers below 2^63 (and Luau is exact only to 2^53), and late-game income heads past
-- that (a full pen at Zeus earns about 5e14 cash a second). So a store keeps log10(1 + value) in fixed point: the order
-- stays the same, every value fits below 2^53, and a value comes back exact below about a trillion and to twelve
-- digits above it, far finer than a board shows.
local Score = {}

export type Entry = { UserId: number, Value: number }

local SCALE = 1e13
local LARGEST = 1e300

function Score.Encode(value: number): number
	if value ~= value or value <= 0 then
		return 0
	end
	return math.floor(math.log10(1 + math.min(value, LARGEST)) * SCALE)
end

-- Values are whole numbers, so rounding takes back what the fixed point lost.
function Score.Decode(stored: number): number
	if stored ~= stored or stored <= 0 then
		return 0
	end
	return math.floor(10 ^ (stored / SCALE) - 1 + 0.5)
end

-- The rows: each player's best value from the store's top entries and from this server's players, who may be ahead of
-- the store (it's written once a minute), highest first. Ties go to the lower UserId so rows don't swap places between
-- redraws. Players at 0 aren't shown.
function Score.Top(stored: { Entry }, live: { Entry }, count: number): { Entry }
	local best: { [number]: number } = {}
	for _, list in { stored, live } do
		for _, entry in list do
			if entry.Value > 0 then
				best[entry.UserId] = math.max(best[entry.UserId] or 0, entry.Value)
			end
		end
	end
	local rows: { Entry } = {}
	for userId, value in best do
		table.insert(rows, { UserId = userId, Value = value })
	end
	table.sort(rows, function(a: Entry, b: Entry): boolean
		if a.Value ~= b.Value then
			return a.Value > b.Value
		end
		return a.UserId < b.UserId
	end)
	for index = #rows, count + 1, -1 do
		rows[index] = nil
	end
	return rows
end

return table.freeze(Score)
