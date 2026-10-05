--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local PlayerData = require(script.Parent.Parent.Data.PlayerData)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Data = PlayerData.Data

type Connection = { Disconnect: (self: any) -> () }
type ProfileSignal = { Connect: (self: any, callback: (...any) -> ()) -> Connection }
type Profile = {
	Data: Data,
	LastSavedData: Data,
	IsActive: (self: Profile) -> boolean,
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
	AddUserId: (self: Profile, userId: number) -> (),
	Save: (self: Profile) -> (),
	OnAfterSave: ProfileSignal,
	OnLastSave: ProfileSignal,
	OnSessionEnd: ProfileSignal,
}

local SAVE_TIMEOUT = 20
-- Studio only: with this attribute on ServerStorage set to true in Edit before pressing Play, every player starts from
-- an empty save that lives in memory and is never written, so a playtest can be a new player's first session without
-- wiping the testing account's Studio save. Clear it afterwards: it's saved with the place.
local BLANK_PROFILE_ATTRIBUTE = "DebugBlankProfile"

local DataService = {
	Name = "DataService",
	PlayerLoaded = Signal.new() :: Signal.Signal<Player, Data>,
	-- With ProfileStore's reason: "Manual" when the player left, "Shutdown" when the server closed, "External" when
	-- another server took the session.
	PlayerReleasing = Signal.new() :: Signal.Signal<Player, Data, string>,
}

local store: any = nil
local profiles: { [Player]: Profile } = {}
local connections: { RBXScriptConnection } = {}
local closing = false
local warnedMock = false
local blankProfiles = false

local function isPresent(player: Player): boolean
	return not closing and player.Parent == Players
end

local function activeProfile(player: Player): Profile?
	local profile = profiles[player]
	if profile and profile:IsActive() then
		return profile
	end
	return nil
end

-- The saved values every client shows, mirrored as player attributes (the flock goes through FlockService's State).
local function replicate(player: Player, data: Data)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("ClimbPower", data.ClimbPower)
	player:SetAttribute("WalkerLevel", data.WalkerLevel)
	player:SetAttribute("PenSlots", data.PenSlots)
	player:SetAttribute("Trail", data.Trail)
	player:SetAttribute("Tutorial", data.Tutorial)
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, child in value do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function load(player: Player)
	player:SetAttribute("DataLoaded", false)
	local ok, result = pcall(function()
		local source = if blankProfiles then store.Mock else store
		return source:StartSessionAsync(`Player_{player.UserId}`, {
			Cancel = function()
				return not isPresent(player)
			end,
		})
	end)
	if not ok then
		warn(`[DataService] Session start failed for {player.UserId}: {result}`)
	end
	local profile = if ok then result :: Profile? else nil
	if not profile then
		if isPresent(player) then
			player:Kick("Your data couldn't be loaded. Please rejoin.")
		end
		return
	end
	if not isPresent(player) then
		profile:EndSession()
		return
	end

	local valid, reason = PlayerData.Validate(profile.Data)
	if not valid then
		warn(`[DataService] Refusing to load data for {player.UserId}: {reason}. Progress was not changed.`)
		profile:EndSession()
		player:Kick("Your saved data couldn't be opened. Please try again later.")
		return
	end
	PlayerData.Migrate(profile.Data)
	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- OnLastSave fires right before the final save of every session end: leaving, server shutdown
	-- (ProfileStore's own BindToClose may run before ours) and another server taking the session.
	-- Handlers' writes therefore always make it into the last save.
	local endReason: string? = nil
	profile.OnLastSave:Connect(function(reason: string)
		endReason = reason
		if profiles[player] == profile then
			DataService.PlayerReleasing:Fire(player, profile.Data, reason)
		end
	end)
	profile.OnSessionEnd:Connect(function()
		if profiles[player] ~= profile then
			return
		end
		profiles[player] = nil
		player:SetAttribute("DataLoaded", false)
		-- No reason means another server forcibly took the session, which fires no OnLastSave.
		if (endReason == nil or endReason == "External") and isPresent(player) then
			player:Kick("Your data session ended because you joined another server. Please rejoin.")
		end
	end)

	if not warnedMock and not blankProfiles and ProfileStore.DataStoreState ~= "Access" then
		warnedMock = true
		warn(
			`[DataService] DataStores unavailable ({ProfileStore.DataStoreState}): using temporary data that resets when Play stops. Publish the place and turn on File > Experience Settings > Security > Enable Studio Access to API Services to test saving.`
		)
	end

	profiles[player] = profile
	replicate(player, profile.Data)
	player:SetAttribute(BLANK_PROFILE_ATTRIBUTE, if blankProfiles then true else nil)
	player:SetAttribute("DataLoaded", true)
	DataService.PlayerLoaded:Fire(player, profile.Data)
end

local function release(player: Player)
	local profile = profiles[player]
	if profile and profile:IsActive() then
		profile:EndSession()
	end
	profiles[player] = nil
	player:SetAttribute("DataLoaded", false)
end

function DataService.Init(_self: any, _registry: Lifecycle.Registry)
	-- Studio uses its own store so playtests never touch live player data.
	local storeName = if RunService:IsStudio() then "PlayerData_Studio" else "PlayerData"
	store = ProfileStore.New(storeName, PlayerData.Template)
	blankProfiles = RunService:IsStudio() and ServerStorage:GetAttribute(BLANK_PROFILE_ATTRIBUTE) == true
	if blankProfiles then
		print(
			`[DataService] ServerStorage.{BLANK_PROFILE_ATTRIBUTE} is on: every player starts from an empty save that is never saved. Turn it off in Edit to play your real Studio save.`
		)
	end
end

function DataService.Start(_self: any)
	table.insert(connections, Players.PlayerAdded:Connect(load))
	table.insert(connections, Players.PlayerRemoving:Connect(release))
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
end

function DataService.Destroy(_self: any)
	closing = true
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	for _, player in Players:GetPlayers() do
		release(player)
	end
end

function DataService.GetData(_self: any, player: Player): Data?
	local profile = activeProfile(player)
	return if profile then profile.Data else nil
end

-- Runs callback for every player whose data is already loaded, then for each one that loads later.
function DataService.ObserveLoaded(_self: any, callback: (Player, Data) -> ()): Signal.Connection
	for player in profiles do
		local data = DataService:GetData(player)
		if data then
			task.spawn(callback, player, data)
		end
	end
	return DataService.PlayerLoaded:Connect(callback)
end

-- Refreshes the player attributes that mirror saved data. Call after changing a mirrored field.
function DataService.Replicate(_self: any, player: Player)
	local data = DataService:GetData(player)
	if data then
		replicate(player, data)
	end
end

-- Adds coins (income arrives in fractions of a coin); a negative amount spends, refused if it would go below 0.
function DataService.AdjustCoins(_self: any, player: Player, amount: number): boolean
	if type(amount) ~= "number" or amount ~= amount or math.abs(amount) == math.huge then
		warn(`[DataService] AdjustCoins refused {player.Name} an invalid amount: {amount}`, debug.traceback())
		return false
	end
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	local balance = data.Coins + amount
	if balance < 0 then
		return false
	end
	data.Coins = balance
	player:SetAttribute("Coins", balance)
	return true
end

-- Puts every field back to the template's value except purchase receipts, which must survive so a product is never
-- granted twice, and the fields named in keep. For a debug "wipe save"; never reset a player's progress otherwise.
function DataService.Reset(_self: any, player: Player, keep: { string }?): boolean
	local data = DataService:GetData(player)
	if not data then
		return false
	end
	for key, value in PlayerData.Template :: any do
		local kept = key == "Receipts" or key == "SchemaVersion" or (keep ~= nil and table.find(keep, key) ~= nil)
		if not kept then
			(data :: any)[key] = deepCopy(value)
		end
	end
	replicate(player, data)
	return true
end

-- Forces a save and waits until the saved copy satisfies isSaved. Costs a DataStore write:
-- only for things that must survive a crash right now, i.e. purchase receipts.
function DataService.SaveNow(_self: any, player: Player, isSaved: (saved: Data) -> boolean): boolean
	local profile = activeProfile(player)
	if not profile then
		return false
	end
	if isSaved(profile.LastSavedData) then
		return true
	end

	local thread = coroutine.running()
	local finished = false
	local connection: Connection
	local function finish(result: boolean)
		if finished then
			return
		end
		finished = true
		connection:Disconnect()
		task.spawn(thread, result)
	end
	connection = profile.OnAfterSave:Connect(function(saved: Data)
		if isSaved(saved) then
			finish(true)
		end
	end)
	local timer = task.delay(SAVE_TIMEOUT, finish, false)
	profile:Save()
	local result = coroutine.yield()
	if coroutine.status(timer) == "suspended" then
		task.cancel(timer)
	end
	return result == true
end

return DataService
