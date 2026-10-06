--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Economy = require(ReplicatedStorage.Utils.Economy)
local Remotes = require(ReplicatedStorage.Remotes)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- The friend boost: each Roblox friend in the server multiplies a player's live income (Economy.FriendBoost, applied in
-- FlockService's tick; not offline earnings, not the leaderboards). A pair is asked about once, by whichever joined
-- later, and kept while both stay. The count is the player's Friends attribute, which the HUD's friend tile shows.
-- Studio's test players are nobody's friends, so in Studio a DebugFriends attribute (DebugService's SetFriends) stands
-- in for the real count.
local FriendService = { Name = "FriendService" }

local trove = Trove.new()
local friendsOf: { [Player]: { [Player]: true } } = {}
-- When each player joined, in order: only the later of a pair asks Roblox, so a pair is asked once.
local joinedAt: { [Player]: number } = {}
local joins = 0

local function count(player: Player): number
	local pretend = player:GetAttribute("DebugFriends")
	if RunService:IsStudio() and type(pretend) == "number" then
		return pretend
	end
	local total = 0
	local friends = friendsOf[player]
	if friends then
		for _ in friends do
			total += 1
		end
	end
	return total
end

local function boostText(player: Player): string
	return `+{math.round((Economy.FriendBoost(count(player)) - 1) * 100)}%`
end

local function refresh(player: Player)
	player:SetAttribute("Friends", count(player))
end

local function onJoined(player: Player)
	joins += 1
	joinedAt[player] = joins
	friendsOf[player] = {}
	refresh(player)
	local found = 0
	for _, other in Players:GetPlayers() do
		local otherJoined = joinedAt[other]
		if other == player or not otherJoined or otherJoined > joinedAt[player] then
			continue
		end
		local ok, isFriend = pcall(function()
			return player:IsFriendsWithAsync(other.UserId)
		end)
		local mine, theirs = friendsOf[player], friendsOf[other]
		-- Either may have left while Roblox answered.
		if ok and isFriend and mine and theirs then
			mine[other] = true
			theirs[player] = true
			found += 1
			refresh(other)
			Remotes.Notify:Fire(other, `{player.DisplayName} joined: friend boost {boostText(other)}`, "Good", "Notice")
		end
	end
	if found > 0 and friendsOf[player] then
		refresh(player)
		Remotes.Notify:Fire(player, `Friends here: friend boost {boostText(player)}`, "Good", "Notice")
	end
end

local function onLeft(player: Player)
	local mine = friendsOf[player]
	friendsOf[player] = nil
	joinedAt[player] = nil
	if not mine then
		return
	end
	for friend in mine do
		local theirs = friendsOf[friend]
		if theirs then
			theirs[player] = nil
			refresh(friend)
		end
	end
end

function FriendService.Init(_self: any) end

function FriendService.Start(_self: any)
	trove:Connect(Players.PlayerAdded, function(player: Player)
		task.spawn(onJoined, player)
	end)
	trove:Connect(Players.PlayerRemoving, onLeft)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoined, player)
	end
end

function FriendService.Destroy(_self: any)
	trove:Clean()
end

-- How much the player's live income is multiplied by now.
function FriendService.Boost(_self: any, player: Player): number
	return Economy.FriendBoost(count(player))
end

-- After DebugFriends changes (Studio).
function FriendService.Refresh(_self: any, player: Player)
	refresh(player)
end

return FriendService
