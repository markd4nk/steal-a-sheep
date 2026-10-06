--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Format = require(ReplicatedStorage.Utils.Format)
local Herds = require(ReplicatedStorage.Config.Herds)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Olympus = require(ReplicatedStorage.Config.Olympus)
local Remotes = require(ReplicatedStorage.Remotes)

-- The Sheepdex's rewards. Delivering the first of a family finds it (FlockService); its reward, cash and Climbing,
-- waits here for the player to claim it in the Sheepdex. Claiming the last of a god's six pays that herd's gift too.
local SheepdexService = { Name = "SheepdexService" }

local registry: Lifecycle.Registry = {}

local function notify(player: Player, message: string, kind: string, sound: string?)
	Remotes.Notify:Fire(player, message, kind, sound)
end

local function claim(player: Player, family: string): (boolean, string?)
	local data = registry.DataService:GetData(player)
	if not data then
		return false, "Still loading"
	end
	local tier = Olympus.ByFamily[family]
	if not tier then
		return false, "No such sheep"
	end
	if data.Dex[family] ~= true then
		return false, "Steal one first"
	end
	if data.DexClaimed[family] == true then
		return false, "Already claimed"
	end
	data.DexClaimed[family] = true
	data.ClimbPower += Economy.DexClimb(family)
	registry.DataService:AdjustCoins(player, Economy.DexReward(family))
	local god = Herds.GodOf[family]
	local herd = if god then Herds.ByGod[god] else nil
	if god and herd and not data.HerdGifts[god] then
		local complete = true
		for _, member in herd do
			if data.DexClaimed[member] ~= true then
				complete = false
				break
			end
		end
		if complete then
			data.HerdGifts[god] = true
			local coins, climb = Economy.HerdReward(tier.Tier)
			data.ClimbPower += climb
			registry.DataService:AdjustCoins(player, coins)
			notify(
				player,
				`{god}'s herd complete! +{Format.Short(coins)} cash, +{Format.Short(climb)} Climbing`,
				"Rare",
				"Reveal"
			)
		end
	end
	registry.DataService:Replicate(player)
	registry.FlockService:Push(player)
	return true, nil
end

function SheepdexService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function SheepdexService.Start(_self: any)
	Remotes.ClaimDex:Handle(claim)
end

function SheepdexService.Destroy(_self: any) end

return SheepdexService
