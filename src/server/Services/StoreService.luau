--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Remotes = require(ReplicatedStorage.Remotes)
local Store = require(ReplicatedStorage.Config.Store)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The Robux store's server side (Config/Store has what it sells): the client asks for an item by key and this picks
-- the product (2x Speed's next step, the stair walker's current level) and opens Roblox's dialog; PurchaseService
-- grants it when the receipt comes. One dialog at a time per player, so a price step can't be bought twice at its
-- price. Passes: whether each counts for the player is mirrored as Pass<Key> attributes (FlockService multiplies
-- income and growth by them), and PassesChecked once all are known. In Studio, a product or pass that doesn't exist
-- on Roblox yet is granted at once with no dialog, so the store can be tried before the game is published.
local StoreService = { Name = "StoreService" }

local PENDING_SECONDS = 60 -- a dialog that never reports back stops blocking new ones after this

local isStudio = RunService:IsStudio()
local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local pending: { [Player]: number } = {} -- os.clock() a dialog opened
local studioPasses: { [Player]: { [string]: boolean } } = {}

local function setPass(player: Player, key: string, owned: boolean)
	if player.Parent ~= Players then
		return
	end
	player:SetAttribute(Store.PassAttribute(key), owned)
	registry.FlockService:Push(player)
end

-- Yields (Roblox is asked once per pass, then PurchaseService caches it).
local function checkPasses(player: Player)
	for _, pass in Store.Passes do
		local id = Store.PassId(pass.Key)
		local granted = studioPasses[player]
		local owned = (granted ~= nil and granted[pass.Key] == true)
			or (id > 0 and registry.PurchaseService:OwnsPass(player, id))
		setPass(player, pass.Key, owned)
	end
	if player.Parent == Players then
		player:SetAttribute("PassesChecked", true)
	end
end

local function request(player: Player, key: string): (boolean, string?)
	local data = registry.DataService:GetData(player)
	if not data then
		return false, "Still loading"
	end
	local opened = pending[player]
	if opened and os.clock() - opened < PENDING_SECONDS then
		return false, "Finish your purchase first"
	end

	local pass = Store.Pass(key)
	if pass then
		if player:GetAttribute(Store.PassAttribute(key)) == true then
			return false, "You own it already"
		end
		local passId = Store.PassId(key)
		if passId == 0 then
			if not isStudio then
				return false, "Not on sale yet"
			end
			local granted = studioPasses[player] or {}
			studioPasses[player] = granted
			granted[key] = true
			setPass(player, key, true)
			return true, `{pass.Name} is on (Studio: no pass yet)`
		end
		pending[player] = os.clock()
		MarketplaceService:PromptGamePassPurchase(player, passId)
		return true, nil
	end

	local productKey = key
	if key == "Speed" then
		local buy = data.SpeedBuys + 1
		if buy > #Store.SpeedPrices then
			return false, "2x Speed is sold out"
		end
		productKey = Store.SpeedKey(buy)
	elseif key == "Walker" then
		if data.WalkerLevel >= Economy.MaxWalker then
			return false, "Your stair walker is maxed"
		end
		productKey = Store.WalkerKey(data.WalkerLevel)
	elseif not Store.Pack(key) and not Store.SheepOffer(key) then
		return false, "Not for sale"
	end
	local productId = Store.ProductId(productKey)
	if productId == 0 then
		if not isStudio then
			return false, "Not on sale yet"
		end
		local ok, why = registry.PurchaseService:Grant(player, productKey)
		return ok, if ok then "Granted (Studio: no product yet)" else why
	end
	pending[player] = os.clock()
	MarketplaceService:PromptProductPurchase(player, productId)
	return true, nil
end

function StoreService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function StoreService.Start(_self: any)
	Remotes.RequestPurchase:Handle(request)
	trove:Add(registry.DataService:ObserveLoaded(function(player: Player)
		task.spawn(checkPasses, player)
	end))
	trove:Add(registry.PurchaseService.PassPurchased:Connect(function(player: Player, passId: number)
		local key = Store.KeyOfPass(passId)
		local pass = if key then Store.Pass(key) else nil
		if key and pass then
			setPass(player, key, true)
			Remotes.Notify:Fire(player, `{pass.Name} is on!`, "Rare", "Upgrade")
		end
	end))
	trove:Connect(MarketplaceService.PromptProductPurchaseFinished, function(userId: number)
		local player = Players:GetPlayerByUserId(userId)
		if player then
			pending[player] = nil
		end
	end)
	trove:Connect(MarketplaceService.PromptGamePassPurchaseFinished, function(player: Player)
		pending[player] = nil
	end)
	trove:Connect(Players.PlayerRemoving, function(player: Player)
		pending[player] = nil
		studioPasses[player] = nil
	end)
end

function StoreService.Destroy(_self: any)
	trove:Clean()
end

return StoreService
