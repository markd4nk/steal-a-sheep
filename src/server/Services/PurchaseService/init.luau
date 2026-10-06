--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Products = require(script.Products)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Store = require(ReplicatedStorage.Config.Store)

local MAX_RECEIPTS = 50
local LOAD_WAIT = 60
local PASS_TRIES = 3 -- a failed pass check is asked again, 1 s then 2 s later

local PurchaseService = {
	Name = "PurchaseService",
	-- Fires when a player buys a pass in this server, so systems can switch its perk on without a rejoin.
	PassPurchased = Signal.new() :: Signal.Signal<Player, number>,
	-- (player, product key from Config/Store, from a real receipt): the product's reward is in their data, so systems
	-- can show it. False for the Studio grant, which analytics should ignore.
	Granted = Signal.new() :: Signal.Signal<Player, string, boolean>,
}

local isStudio = RunService:IsStudio()
local registry: Lifecycle.Registry = {}
local passCache: { [Player]: { [number]: boolean } } = {}
-- Studio: the account that made the passes owns them all, so solo tests play as a non-owner unless this is false.
local ignorePasses: { [Player]: boolean } = {}
local connections: { RBXScriptConnection } = {}

local function prune(receipts: { [string]: number })
	local ids: { string } = {}
	for purchaseId in receipts do
		table.insert(ids, purchaseId)
	end
	if #ids <= MAX_RECEIPTS then
		return
	end
	table.sort(ids, function(a, b)
		return receipts[a] < receipts[b]
	end)
	for index = 1, #ids - MAX_RECEIPTS do
		receipts[ids[index]] = nil
	end
end

-- Roblox only re-sends an unprocessed receipt on the next purchase or rejoin, so a receipt that arrives
-- while the player's data is still loading must wait for it rather than be declined.
local function waitForData(player: Player): any
	local dataService = registry.DataService
	local data = dataService:GetData(player)
	local deadline = os.clock() + LOAD_WAIT
	while not data and player.Parent == Players and os.clock() < deadline do
		task.wait(0.5)
		data = dataService:GetData(player)
	end
	return data
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local dataService = registry.DataService
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local data = if player then waitForData(player) else nil
	if not player or not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	if data.Receipts[purchaseId] == nil then
		local key = Store.KeyOfProduct(receipt.ProductId)
		local grant = if key then Products[key] else nil
		if not key or not grant then
			warn(`[PurchaseService] No grant for product {receipt.ProductId}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(grant, player, registry)
		if not ok then
			warn(`[PurchaseService] Grant for product {receipt.ProductId} errored: {granted}`)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if granted ~= true or dataService:GetData(player) ~= data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.Receipts[purchaseId] = os.time()
		prune(data.Receipts)
		PurchaseService.Granted:Fire(player, key, true)
	end

	-- Acknowledge only once a saved copy holds the receipt (and so the reward granted with it).
	local saved = dataService:SaveNow(player, function(snapshot)
		return type(snapshot.Receipts) == "table" and snapshot.Receipts[purchaseId] ~= nil
	end)
	return if saved then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
end

function PurchaseService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function PurchaseService.Start(_self: any)
	MarketplaceService.ProcessReceipt = processReceipt
	table.insert(
		connections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased)
			if purchased and player.Parent == Players then
				local cache = passCache[player] or {}
				passCache[player] = cache
				cache[passId] = true
				PurchaseService.PassPurchased:Fire(player, passId)
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			passCache[player] = nil
			ignorePasses[player] = nil
		end)
	)
	if isStudio then
		local function mirror(player: Player)
			player:SetAttribute("DebugIgnorePasses", ignorePasses[player] ~= false)
		end
		table.insert(connections, Players.PlayerAdded:Connect(mirror))
		for _, player in Players:GetPlayers() do
			mirror(player)
		end
	end
end

function PurchaseService.Destroy(_self: any)
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
end

-- Yields on first check per player and pass. Server-side ownership check; never trust the client's claim.
function PurchaseService.OwnsPass(_self: any, player: Player, passId: number): boolean
	if player.Parent ~= Players then
		return false
	end
	local cache = passCache[player]
	if not cache then
		cache = {}
		passCache[player] = cache
	end
	local known = cache[passId]
	if known ~= nil then
		return known
	end
	-- A pass bought in this session still counts (it's in the cache above).
	if isStudio and ignorePasses[player] ~= false then
		return false
	end
	-- Asked again after a failure (a Marketplace hiccup at join would otherwise leave an owner at 1x all session).
	local ok, owns = false, nil :: any
	for try = 1, PASS_TRIES do
		ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
		if ok or player.Parent ~= Players or try == PASS_TRIES then
			break
		end
		task.wait(try)
	end
	-- Bought while this was asking: that answer stands.
	local bought = cache[passId]
	if bought ~= nil then
		return bought
	end
	if not ok then
		warn(`[PurchaseService] Pass check failed for {player.UserId}/{passId}: {owns}`)
		return false
	end
	if passCache[player] == cache and cache[passId] == nil then
		cache[passId] = owns
	end
	return owns
end

-- Studio: gives a product's reward (by its Config/Store key) through its grant, as a purchase would, with no dialog
-- or receipt. The store uses it for products that don't exist on Roblox yet.
function PurchaseService.Grant(_self: any, player: Player, key: string): (boolean, string?)
	if not isStudio then
		return false, "Studio only"
	end
	local grant = Products[key]
	if not grant or not registry.DataService:GetData(player) then
		return false, "no such product in Products, or data not loaded"
	end
	if not grant(player, registry) then
		return false, "the grant refused"
	end
	PurchaseService.Granted:Fire(player, key, false)
	return true, nil
end

-- Studio debug: a pass as if bought in this server just now, with no dialog. It counts for the rest of the session
-- (until SetIgnorePasses asks Roblox again), and PassPurchased fires so its perk switches on as a real purchase's would.
function PurchaseService.GrantPass(_self: any, player: Player, passId: number): (boolean, string?)
	if not isStudio then
		return false, "Studio only"
	end
	if passId <= 0 or passId % 1 ~= 0 or player.Parent ~= Players then
		return false, "not a pass id"
	end
	local cache = passCache[player] or {}
	passCache[player] = cache
	cache[passId] = true
	PurchaseService.PassPurchased:Fire(player, passId)
	return true, nil
end

-- Studio debug: whether OwnsPass ignores the passes the player's account already owns (on by default in Studio,
-- where the testing account made them all). Passes bought or granted in the session count while it's on; switching
-- forgets them and asks Roblox again. Mirrored as the DebugIgnorePasses attribute. Systems that checked passes at
-- load see the change after a rejoin.
function PurchaseService.SetIgnorePasses(_self: any, player: Player, ignore: boolean)
	if not isStudio then
		return
	end
	ignorePasses[player] = ignore
	passCache[player] = nil
	player:SetAttribute("DebugIgnorePasses", ignore)
end

return PurchaseService
