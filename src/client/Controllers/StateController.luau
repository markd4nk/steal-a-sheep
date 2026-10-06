--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- This player's flock and progress as the server last sent it (FlockService.Snapshot): asked for once at the start,
-- then replaced whenever the server pushes a new one. Screens read State and listen to Changed.
local StateController = {
	Name = "StateController",
	Changed = Signal.new() :: Signal.Signal<{ [string]: any }>,
	-- The away summary, once a session: (coins, lambs grown). Read it with TakeAway, which hands it out once.
	Offline = Signal.new() :: Signal.Signal<number, number>,
}

export type SheepView = {
	Id: string,
	Family: string,
	Rarity: number,
	Weight: number,
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
	Robux: boolean?, -- bought in the store: can't be sold or merged
	AtShrine: boolean, -- a merged lamb still on the Merge Shrine's altar
}

local trove = Trove.new()
local state: { [string]: any } = {}
local firstSession: boolean? = nil
local awaySeen = false
-- The away summary until the welcome-back card takes it (TakeAway): it can arrive before that card exists.
local away: { Coins: number, Matured: number }? = nil

local function apply(snapshot: { [string]: any })
	if type(snapshot) ~= "table" or snapshot.Sheep == nil then
		return
	end
	state = snapshot
	if firstSession == nil then
		firstSession = snapshot.Tutorial == 0
	end
	StateController.Changed:Fire(snapshot)
	-- The away summary rides on one snapshot, whichever comes first: the one asked for, or one the server pushes once the
	-- time away is credited (after the player's passes are known).
	local summary = snapshot.Offline
	if not awaySeen and type(summary) == "table" and type(summary.Coins) == "number" then
		awaySeen = true
		away = { Coins = summary.Coins, Matured = summary.Matured or 0 }
		StateController.Offline:Fire(summary.Coins, summary.Matured or 0)
	end
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

-- The away summary (cash, lambs grown) the first time it's asked for after it arrived, then nil.
function StateController.TakeAway(_self: any): (number?, number?)
	local summary = away
	away = nil
	if summary then
		return summary.Coins, summary.Matured
	end
	return nil, nil
end

-- Whether this is the player's first session (their save had no delivery when they joined): menus don't open by
-- themselves in it.
function StateController.IsFirstSession(_self: any): boolean
	return firstSession ~= false
end

local ORDERS: { [string]: (a: SheepView, b: SheepView) -> boolean? } = {
	Income = function(a, b)
		return if a.Income ~= b.Income then a.Income > b.Income else nil
	end,
	Family = function(a, b)
		local orderA, orderB = Economy.FamilyOrder(a.Family), Economy.FamilyOrder(b.Family)
		return if orderA ~= orderB then orderA < orderB else nil
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
