--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Economy = require(ReplicatedStorage.Utils.Economy)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)

-- Studio-only test tools behind the debug panel (client `UIController/Screens/DebugPanel`) and the Studio MCP:
-- `require(ReplicatedStorage.Remotes).Debug:Invoke("AddCash", 500)` from a Client `execute_luau`. Every command is
-- refused outside Studio, so the remote is harmless in a live server. Add a game's own commands to `commands`, and a
-- button for each to the panel. See BRAIN/PATTERNS/testing.md.
type Command = (player: Player, value: number?) -> (boolean, string?)

local CASH_GRANT = 1000
local CLIMB_GRANT = 100

local DebugService = { Name = "DebugService" }

local registry: Lifecycle.Registry = {}

local commands: { [string]: Command } = {
	-- value: how many coins (CASH_GRANT if left out); a negative value takes coins away.
	AddCash = function(player, value)
		if registry.DataService:AdjustCoins(player, value or CASH_GRANT) then
			return true, nil
		end
		return false, "the balance would go below 0"
	end,
	-- value: how much Climbing (CLIMB_GRANT if left out).
	AddClimb = function(player, value)
		local data = registry.DataService:GetData(player)
		data.ClimbPower = math.max(0, data.ClimbPower + (value or CLIMB_GRANT))
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- value: a tier. Teleports to its first ready lamb and steals it.
	Steal = function(player, value)
		if registry.WildService:DebugSteal(player, value or 1) then
			return true, nil
		end
		return false, "no ready lamb on that tier"
	end,
	-- value: how many times normal speed the player moves (1 for normal), for this play session.
	SetSpeed = function(player, value)
		local boost = math.clamp(value or 1, 0.1, 20)
		player:SetAttribute("DebugSpeed", if boost == 1 then nil else boost)
		return true, nil
	end,
	-- value: how many friends the player counts as having in the server, for the friend boost; a negative value goes
	-- back to their real friends.
	SetFriends = function(player, value)
		local friends = math.floor(value or 0)
		player:SetAttribute("DebugFriends", if friends >= 0 then friends else nil)
		registry.FriendService:Refresh(player)
		return true, nil
	end,
	-- value: a tier. An ordinary lamb of that tier's family goes straight into the flock, as if delivered.
	GiveSheep = function(player, value)
		local tier = Olympus.Tiers[math.clamp(math.floor(value or 1), 1, Olympus.Count)]
		local size = math.random(1, 3)
		registry.FlockService:Deliver(player, { Family = tier.Family, Rarity = 1, Weight = 1.05, Size = size })
		return true, nil
	end,
	-- Every lamb in the pen grows up now.
	GrowAll = function(player)
		local data = registry.DataService:GetData(player)
		for _, sheep in data.Sheep do
			sheep.Grown = Economy.GrowthSeconds(sheep) - 1
		end
		return true, nil
	end,
	-- Every tier easy: Zeus's Heavy target in Climbing, and one delivery from each tier.
	UnlockAll = function(player)
		local data = registry.DataService:GetData(player)
		data.ClimbPower = math.max(data.ClimbPower, Olympus.Tiers[Olympus.Count].Reach * 2.25)
		for tier = 1, Olympus.Count do
			local key = tostring(tier)
			data.Deliveries[key] = math.max(data.Deliveries[key] or 0, 1)
		end
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- The free gift can be claimed again.
	ResetGift = function(player)
		local data = registry.DataService:GetData(player)
		data.FreeGift = false
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- Today's daily gift waits now, as if the timer had run out.
	DailyReady = function(player)
		local data = registry.DataService:GetData(player)
		data.DailyAt = 0
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- value: the daily gifts' day to claim next (1 to 7), waiting now.
	DailyDay = function(player, value)
		local data = registry.DataService:GetData(player)
		local day = math.floor(value or 1)
		if day < 1 or day > #Economy.DailyWeek then
			return false, `Day 1 to {#Economy.DailyWeek}`
		end
		data.DailyDay = day
		data.DailyAt = 0
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- value: the stair walker level to show (1 is the free machine).
	SetWalker = function(player, value)
		local data = registry.DataService:GetData(player)
		data.WalkerLevel = math.clamp(math.floor(value or 1) - 1, 0, Economy.MaxWalker)
		registry.DataService:Replicate(player)
		registry.FlockService:Push(player)
		return true, nil
	end,
	-- A new player's save again. Receipts stay, so no product is granted twice.
	WipeSave = function(player)
		if registry.DataService:Reset(player) then
			registry.FlockService:Push(player)
			return true, nil
		end
		return false, "data not loaded"
	end,
	-- value: the developer product's id. Its grant runs as a purchase's would, with no dialog or receipt.
	GrantProduct = function(player, value)
		if not value then
			return false, "which product id?"
		end
		return registry.PurchaseService:Grant(player, value)
	end,
	-- value: the pass's id. It counts as bought in this session.
	GrantPass = function(player, value)
		if not value then
			return false, "which pass id?"
		end
		return registry.PurchaseService:GrantPass(player, value)
	end,
	-- value: 1 ignores the passes the testing account owns (Studio's default), 0 asks Roblox again.
	SetIgnorePasses = function(player, value)
		registry.PurchaseService:SetIgnorePasses(player, value ~= 0)
		return true, nil
	end,
}

local function handle(player: Player, command: string, value: number?): (boolean, string?)
	if not RunService:IsStudio() then
		return false, "debug tools only work in Studio"
	end
	local run = commands[command]
	if not run then
		return false, `no debug command named {command}`
	end
	if not registry.DataService:GetData(player) then
		return false, "data not loaded"
	end
	return run(player, value)
end

function DebugService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function DebugService.Start(_self: any)
	Remotes.Debug:Handle(handle)
	if not RunService:IsStudio() then
		return
	end
	-- ServerStorage's DebugSpeed attribute, set in Edit, starts every playtest at that speed (clear it after).
	local function boost(player: Player)
		local speed = ServerStorage:GetAttribute("DebugSpeed")
		if type(speed) == "number" and speed > 0 and speed ~= 1 then
			player:SetAttribute("DebugSpeed", speed)
		end
	end
	for _, player in Players:GetPlayers() do
		boost(player)
	end
	Players.PlayerAdded:Connect(boost)
end

function DebugService.Destroy(_self: any) end

return DebugService
