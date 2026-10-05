--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Boards = require(script.Boards)
local Face = require(script.Face)
local Score = require(script.Score)

-- The map's four leaderboards (workspace.Base.Leaderboard), each ranking one thing (Boards). One ranks this server's
-- players as they are now; the others rank every server from an OrderedDataStore each, with this server's players
-- drawn in live between the store's once-a-minute reads, so a player sees their own rise straight away. Without
-- DataStores (an unpublished place, or Studio without API access) those rank this server's players alone and say so.
local LeaderboardService = { Name = "LeaderboardService" }

local STORE_SECONDS = 60 -- each store's read, and each changed player's write (BRAIN/PATTERNS/leaderboards.md budget)
local DRAW_SECONDS = 5 -- this server's players' values onto the boards
local ROWS = 10

type BoardState = {
	Board: Boards.Board,
	Face: Face.Face,
	Store: OrderedDataStore?,
	Stored: { Score.Entry }, -- the store's top entries at the last read
	HasRead: boolean, -- a read has worked: the board shows every server
}

local registry: Lifecycle.Registry = {}
local trove = Trove.new()
local states: { BoardState } = {}
-- Each loaded player's value on each board (their best this session; now, on a server board), and the last value each
-- board's store took from them.
local best: { [Player]: { [string]: number } } = {}
local written: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}
local warned = false

local function warnOnce(message: string)
	if not warned then
		warned = true
		warn(`[LeaderboardService] {message}`)
	end
end

-- The map's board panels, sorted by z (Boards' order): each board's biggest part; the rest are posts and studs.
local function findPanels(): { BasePart }
	local base = workspace:FindFirstChild("Base")
	local folder = base and base:FindFirstChild("Leaderboard")
	local panels: { BasePart } = {}
	if not folder then
		return panels
	end
	for _, model in folder:GetChildren() do
		local biggest: BasePart? = nil
		local biggestArea = 0
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local size = part.Size
				local area = size.X * size.Y + size.Y * size.Z + size.Z * size.X
				if area > biggestArea then
					biggest, biggestArea = part, area
				end
			end
		end
		if biggest then
			table.insert(panels, biggest)
		end
	end
	table.sort(panels, function(a: BasePart, b: BasePart): boolean
		return a.Position.Z < b.Position.Z
	end)
	return panels
end

local function openStore(id: string): OrderedDataStore?
	-- Studio has its own stores so playtests never touch the live boards.
	local name = if RunService:IsStudio() then `Leaderboard_{id}_Studio` else `Leaderboard_{id}`
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(name)
	end)
	if not ok then
		warnOnce(`Leaderboard unavailable, the boards show this server only: {result}`)
		return nil
	end
	return result
end

local function measure(player: Player, data: any)
	local mine = best[player]
	if not mine or not data then
		return
	end
	for _, state in states do
		local id = state.Board.Id
		local value = state.Board.Value(registry, player, data)
		mine[id] = if state.Board.ThisServer then value else math.max(mine[id] or 0, value)
	end
end

local function nameOf(userId: number): string
	local player = Players:GetPlayerByUserId(userId)
	if player then
		return player.DisplayName
	end
	-- Studio's test players have negative ids and no account.
	return names[userId] or if userId < 0 then `Player{-userId}` else "Player"
end

local function pictureOf(userId: number): string
	return if userId > 0 then `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150` else ""
end

local function learnNames(entries: { Score.Entry })
	local missing: { number } = {}
	for _, entry in entries do
		if entry.UserId > 0 and not names[entry.UserId] and not Players:GetPlayerByUserId(entry.UserId) then
			table.insert(missing, entry.UserId)
		end
	end
	if #missing == 0 then
		return
	end
	local ok, result = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(missing)
	end)
	if not ok then
		warn(`[LeaderboardService] Names didn't load, trying again next read: {result}`)
		return
	end
	for _, info in result do
		names[info.Id] = info.DisplayName
	end
end

local function draw()
	for _, state in states do
		local live: { Score.Entry } = {}
		for player, mine in best do
			table.insert(live, { UserId = player.UserId, Value = mine[state.Board.Id] or 0 })
		end
		local lines: { Face.Line } = {}
		for _, row in Score.Top(state.Stored, live, ROWS) do
			table.insert(lines, {
				Name = nameOf(row.UserId),
				Value = state.Board.Show(row.Value),
				Picture = pictureOf(row.UserId),
			})
		end
		local note = if state.Board.ThisServer
			then "Right now"
			elseif state.HasRead then "All servers"
			else "This server"
		Face.Paint(state.Face, lines, note)
	end
end

-- Only raises a score: a late write from an older session can't lower it.
local function write(store: OrderedDataStore, userId: number, value: number): boolean
	local encoded = Score.Encode(value)
	local ok, result = pcall(function()
		store:UpdateAsync(tostring(userId), function(old: number?): number
			return math.max(old or 0, encoded)
		end)
	end)
	if not ok then
		warnOnce(`A board's write failed: {result}`)
	end
	return ok
end

-- Writes whatever went up since the last write. Yields.
local function flush(player: Player, mine: { [string]: number })
	local done = written[player] or {}
	written[player] = done
	for _, state in states do
		local id = state.Board.Id
		local value = mine[id] or 0
		local store = state.Store
		if store and value > (done[id] or 0) and write(store, player.UserId, value) then
			done[id] = value
		end
	end
end

local function read(state: BoardState)
	local store = state.Store
	if not store then
		return
	end
	local ok, result = pcall(function()
		return store:GetSortedAsync(false, ROWS):GetCurrentPage()
	end)
	if not ok then
		warnOnce(`A board's read failed: {result}`)
		return
	end
	local entries: { Score.Entry } = {}
	for _, item in result do
		local userId = tonumber(item.key)
		if userId and type(item.value) == "number" then
			table.insert(entries, { UserId = userId, Value = Score.Decode(item.value) })
		end
	end
	learnNames(entries)
	state.Stored = entries
	state.HasRead = true
end

local function syncStores()
	-- A copy: players come and go while the writes yield.
	local players: { Player } = {}
	for player in best do
		table.insert(players, player)
	end
	for _, player in players do
		local mine = best[player]
		if mine then
			flush(player, table.clone(mine))
		end
	end
	for _, state in states do
		read(state)
	end
end

-- The last write, as the player's data is released (leaving, shutdown). Yields.
local function release(player: Player, data: any)
	measure(player, data)
	local mine = best[player]
	best[player] = nil
	if mine then
		flush(player, mine)
	end
	written[player] = nil
end

function LeaderboardService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function LeaderboardService.Start(_self: any)
	local panels = findPanels()
	if #panels == 0 then
		warn("[LeaderboardService] No boards in workspace.Base.Leaderboard: the leaderboards are off")
		return
	end
	for index, board in Boards do
		local panel = panels[index]
		if not panel then
			break
		end
		local face = Face.Build(panel, `{board.Id}Board`, board.Title, board.Color)
		face.Part.Parent = panel.Parent
		trove:Add(face.Part)
		table.insert(states, {
			Board = board,
			Face = face,
			Store = if board.ThisServer then nil else openStore(board.Id),
			Stored = {},
			HasRead = false,
		})
	end

	trove:Add(registry.DataService:ObserveLoaded(function(player: Player, data: any)
		best[player] = {}
		measure(player, data)
	end))
	trove:Add(registry.DataService.PlayerReleasing:Connect(function(player: Player, data: any)
		task.spawn(release, player, data)
	end))

	trove:Add(task.spawn(function()
		while true do
			for player in best do
				measure(player, registry.DataService:GetData(player))
			end
			draw()
			task.wait(DRAW_SECONDS)
		end
	end))
	trove:Add(task.spawn(function()
		while true do
			syncStores()
			task.wait(STORE_SECONDS)
		end
	end))
end

function LeaderboardService.Destroy(_self: any)
	-- Destroyed before DataService releases anyone (registry order), so the last writes start here.
	for player in best do
		task.spawn(release, player, registry.DataService:GetData(player))
	end
	trove:Clean()
end

return LeaderboardService
