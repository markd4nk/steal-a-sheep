--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)

-- The free gift for liking and favoriting the game: Climbing and coins (Economy.GiftReward), once per player.
-- Roblox tells only the client whether a favorite went through (AvatarEditorService) and nobody whether a like did, so
-- the server can't check either: it takes the claim on trust and allows one per player, which caps what a forged
-- claim gets to what an honest one does.
local GiftService = { Name = "GiftService" }

local registry: Lifecycle.Registry = {}

local function claim(player: Player): (boolean, string?, number?, number?)
	local data = registry.DataService:GetData(player)
	if not data then
		return false, "Still loading", nil, nil
	end
	if data.FreeGift then
		return false, "You already claimed your gift", nil, nil
	end
	local coins, climb = Economy.GiftReward(data.WalkerLevel, registry.FlockService:Income(player))
	data.FreeGift = true
	data.ClimbPower += climb
	registry.DataService:AdjustCoins(player, coins)
	registry.DataService:Replicate(player)
	registry.FlockService:Push(player)
	return true, nil, coins, climb
end

function GiftService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function GiftService.Start(_self: any)
	Remotes.ClaimGift:Handle(claim)
end

function GiftService.Destroy(_self: any) end

return GiftService
