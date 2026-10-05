--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- This player's flock and progress as the server last sent it (FlockService.Snapshot): asked for once at the start,
-- then replaced whenever the server pushes a new one. Screens read State and listen to Changed.
local StateController = {
	Name = "StateController",
	Changed = Signal.new() :: Signal.Signal<{ [string]: any }>,
	-- The away summary from the first snapshot: (coins, lambs grown).
	Offline = Signal.new() :: Signal.Signal<number, number>,
}

export type SheepView = {
	Id: string,
	Family: string,
	Rarity: number,
	Burden: number,
	Size: number, -- 0 while it's a lamb
	Rank: number,
	Locked: boolean,
	Slot: number,
	Pinned: boolean,
	Adult: boolean,
	Growth: number,
	Income: number,
	Low: number,
	High: number,
	Sell: number,
	Name: string,
}

local trove = Trove.new()
local state: { [string]: any } = {}

local function apply(snapshot: { [string]: any })
	if type(snapshot) ~= "table" or snapshot.Sheep == nil then
		return
	end
	state = snapshot
	StateController.Changed:Fire(snapshot)
end

function StateController.Init(_self: any, _systems: Lifecycle.Registry) end

function StateController.Start(_self: any)
	trove:Add(Remotes.State:Connect(apply))
	task.spawn(function()
		-- The server may still be loading this player's data: ask until it answers with a flock.
		for _ = 1, 30 do
			local ok, snapshot = Remotes.GetState:Invoke()
			if ok and type(snapshot) == "table" and snapshot.Sheep ~= nil then
				apply(snapshot)
				local away = snapshot.Offline
				if type(away) == "table" and type(away.Coins) == "number" then
					StateController.Offline:Fire(away.Coins, away.Matured or 0)
				end
				return
			end
			task.wait(1)
		end
	end)
end

function StateController.Destroy(_self: any)
	trove:Clean()
end

function StateController.Get(_self: any): { [string]: any }
	return state
end

local ORDERS: { [string]: (a: SheepView, b: SheepView) -> boolean? } = {
	Income = function(a, b)
		return if a.Income ~= b.Income then a.Income > b.Income else nil
	end,
	Family = function(a, b)
		local tierA, tierB = Olympus.ByFamily[a.Family], Olympus.ByFamily[b.Family]
		if tierA and tierB and tierA.Tier ~= tierB.Tier then
			return tierA.Tier < tierB.Tier
		end
		return nil
	end,
	Size = function(a, b)
		return if a.Size ~= b.Size then a.Size > b.Size else nil
	end,
	Rank = function(a, b)
		return if a.Rank ~= b.Rank then a.Rank > b.Rank else nil
	end,
}

-- The flock as a list for menus: equipped first, then by `by` (Income, Family, Size or Rank; Income when left out),
-- then by income, then oldest first.
function StateController.Flock(_self: any, by: string?): { SheepView }
	local list: { SheepView } = {}
	local flock = state.Sheep
	if type(flock) ~= "table" then
		return list
	end
	for _, sheep in flock do
		table.insert(list, sheep :: any)
	end
	local order = ORDERS[by or "Income"] or ORDERS.Income
	table.sort(list, function(a: SheepView, b: SheepView)
		local aOn, bOn = a.Slot > 0, b.Slot > 0
		if aOn ~= bOn then
			return aOn
		end
		local first = order(a, b)
		if first ~= nil then
			return first
		end
		if a.Income ~= b.Income then
			return a.Income > b.Income
		end
		return (tonumber(a.Id) or 0) < (tonumber(b.Id) or 0)
	end)
	return list
end

return StateController
