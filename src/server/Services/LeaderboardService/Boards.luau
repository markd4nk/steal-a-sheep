--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Theme = require(ReplicatedStorage.Config.Theme)

-- What each of the map's boards ranks. A value is a whole number (Score keeps whole numbers), never bought with Robux,
-- so the top spot can't be bought. A board across every server keeps each player's best, since income can fall
-- (selling a sheep); a server board shows this server's players as they are now, with no store.
export type Board = {
	Id: string, -- the store's name after "Leaderboard_", and the screen's
	Title: string,
	Color: Color3, -- the values' colour
	ThisServer: boolean?, -- ranks this server's players by their value now, and keeps no store
	Value: (registry: Lifecycle.Registry, player: Player, data: any) -> number,
	Show: (value: number) -> string,
}

local Color = Theme.Color

-- Income in tenths: a starting flock earns a little cash a second.
local function income(registry: Lifecycle.Registry, player: Player, _data: any): number
	return math.floor(registry.FlockService:Income(player) * 10 + 1e-6)
end

local function showIncome(value: number): string
	return `{Format.Rate(value / 10)}/s`
end

-- One a board, in the order of the map's four boards sorted by z: they stand in two pairs at the hub's north and south
-- ends, the income pair north and the stealing pair south, with Top Income and Most Steals on the inner board of each,
-- nearest the hub. Extra boards stay blank; with fewer, the last ones aren't shown.
local Boards: { Board } = {
	{
		Id = "Server",
		Title = "THIS SERVER",
		Color = Color.Lime,
		ThisServer = true,
		Value = income,
		Show = showIncome,
	},
	{
		Id = "Income",
		Title = "TOP INCOME",
		Color = Color.Lime,
		Value = income,
		Show = showIncome,
	},
	{
		Id = "Steals",
		Title = "MOST STEALS",
		Color = Color.Snow,
		Value = function(_registry, _player, data)
			return Economy.TotalDeliveries(data.Deliveries)
		end,
		Show = Format.Short,
	},
	{
		Id = "Climb",
		Title = "CLIMB POWER",
		Color = Color.Gold300,
		Value = function(_registry, _player, data)
			return math.floor(data.ClimbPower)
		end,
		Show = Format.Short,
	},
}

return table.freeze(Boards)
