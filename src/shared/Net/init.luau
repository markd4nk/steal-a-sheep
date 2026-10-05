--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Guard = require(script.Guard)
local RateLimit = require(script.Parent.Utils.RateLimit)

export type Guard = Guard.Guard

export type Limit = {
	Count: number,
	Window: number,
}

export type ToServer<T...> = {
	Name: string,
	Fire: (self: ToServer<T...>, T...) -> (),
	Connect: (self: ToServer<T...>, handler: (Player, T...) -> ()) -> RBXScriptConnection,
}

export type ToClient<T...> = {
	Name: string,
	Fire: (self: ToClient<T...>, player: Player, T...) -> (),
	FireAll: (self: ToClient<T...>, T...) -> (),
	FireExcept: (self: ToClient<T...>, except: Player, T...) -> (),
	Connect: (self: ToClient<T...>, handler: (T...) -> ()) -> RBXScriptConnection,
}

export type Request<A..., R...> = {
	Name: string,
	Invoke: (self: Request<A..., R...>, A...) -> (boolean, R...),
	Handle: (self: Request<A..., R...>, handler: (Player, A...) -> R...) -> (),
}

local FOLDER_NAME = "NetRemotes"

local isServer = RunService:IsServer()
local isStudio = RunService:IsStudio()
local serverFolder: Folder? = nil
local published = false
local claimed: { [string]: boolean } = {}

local Net = {
	FolderName = FOLDER_NAME,
	Guard = Guard,
}

local function folder(): Instance
	if isServer then
		if not serverFolder then
			local created = Instance.new("Folder")
			created.Name = FOLDER_NAME
			serverFolder = created
		end
		return serverFolder :: Folder
	end
	local found = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	assert(found, `ReplicatedStorage.{FOLDER_NAME} is missing: the client bootstrap must wait for it first`)
	return found
end

local function claim(name: string)
	assert(not claimed[name], `Duplicate remote name: {name}`)
	assert(not (isServer and published), `Remote {name} was defined after Net.Publish(); define it in Remotes.luau`)
	claimed[name] = true
end

local function remote(name: string, className: string): Instance
	local parent = folder()
	if isServer then
		local created: Instance = if className == "RemoteFunction"
			then Instance.new("RemoteFunction")
			elseif className == "UnreliableRemoteEvent" then Instance.new("UnreliableRemoteEvent")
			else Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = parent
		return created
	end
	local found = parent:WaitForChild(name, 10)
	assert(
		found and found.ClassName == className,
		`Remote {name} ({className}) is missing: the server did not define it`
	)
	return found
end

local function accepts(guards: { Guard }, ...: any): boolean
	if select("#", ...) > #guards then
		return false
	end
	for index, guard in guards do
		local value = select(index, ...)
		if not guard(value) then
			return false
		end
	end
	return true
end

local function drop(name: string, player: Player, reason: string)
	if isStudio then
		warn(`[Net] Dropped {name} from {player.Name}: {reason}`)
	end
end

local function limiter(name: string, limit: Limit)
	assert(type(limit) == "table", `Remote {name} needs a rate limit, e.g. \{ Count = 5, Window = 1 }`)
	return RateLimit.new(limit.Count, limit.Window)
end

function Net.ToServer(name: string, guards: { Guard }, limit: Limit, unreliable: boolean?): ToServer<...any>
	claim(name)
	local event = remote(name, if unreliable then "UnreliableRemoteEvent" else "RemoteEvent") :: RemoteEvent
	local rate = limiter(name, limit)
	local current: RBXScriptConnection? = nil

	local definition = { Name = name }

	function definition.Fire(_self: any, ...: any)
		assert(not isServer, `{name} goes client to server; the server cannot Fire it`)
		event:FireServer(...)
	end

	function definition.Connect(_self: any, handler: (Player, ...any) -> ()): RBXScriptConnection
		assert(isServer, `{name} goes client to server; only the server can Connect to it`)
		assert(not (current and current.Connected), `{name} already has a handler; route inside that one`)
		local connection = event.OnServerEvent:Connect(function(player: Player, ...: any)
			if not rate:Allow(player) then
				drop(name, player, "rate limit")
				return
			end
			if not accepts(guards, ...) then
				drop(name, player, "invalid arguments")
				return
			end
			handler(player, ...)
		end)
		current = connection
		return connection
	end

	return definition :: any
end

function Net.ToClient(name: string, unreliable: boolean?): ToClient<...any>
	claim(name)
	local event = remote(name, if unreliable then "UnreliableRemoteEvent" else "RemoteEvent") :: RemoteEvent

	if isServer then
		-- Without a listener Roblox queues client sends; drop them so a client can't fill the queue.
		event.OnServerEvent:Connect(function(player: Player)
			drop(name, player, "server-to-client remote")
		end)
	end

	local definition = { Name = name }

	function definition.Fire(_self: any, player: Player, ...: any)
		assert(isServer, `{name} goes server to client; only the server can Fire it`)
		event:FireClient(player, ...)
	end

	function definition.FireAll(_self: any, ...: any)
		assert(isServer, `{name} goes server to client; only the server can Fire it`)
		event:FireAllClients(...)
	end

	function definition.FireExcept(_self: any, except: Player, ...: any)
		assert(isServer, `{name} goes server to client; only the server can Fire it`)
		for _, player in Players:GetPlayers() do
			if player ~= except then
				event:FireClient(player, ...)
			end
		end
	end

	function definition.Connect(_self: any, handler: (...any) -> ()): RBXScriptConnection
		assert(not isServer, `{name} goes server to client; only clients can Connect to it`)
		return event.OnClientEvent:Connect(handler)
	end

	return definition :: any
end

function Net.Request(name: string, guards: { Guard }, limit: Limit): Request<...any, ...any>
	claim(name)
	local func = remote(name, "RemoteFunction") :: RemoteFunction
	local rate = limiter(name, limit)
	local handled = false

	if isServer then
		func.OnServerInvoke = function(player: Player)
			drop(name, player, "no handler yet")
			return false
		end
	end

	local definition = { Name = name }

	function definition.Invoke(_self: any, ...: any): ...any
		assert(not isServer, `{name} is invoked by clients; the server calls the service directly`)
		local results = table.pack(pcall(func.InvokeServer, func, ...))
		if not results[1] then
			warn(`[Net] {name} failed: {results[2]}`)
			return false
		end
		return table.unpack(results, 2, results.n)
	end

	function definition.Handle(_self: any, handler: (Player, ...any) -> ...any)
		assert(isServer, `{name} is handled on the server`)
		assert(not handled, `{name} already has a handler`)
		handled = true
		func.OnServerInvoke = function(player: Player, ...: any)
			if not rate:Allow(player) then
				drop(name, player, "rate limit")
				return false
			end
			if not accepts(guards, ...) then
				drop(name, player, "invalid arguments")
				return false
			end
			local results = table.pack(xpcall(handler, debug.traceback, player, ...))
			if not results[1] then
				warn(`[Net] {name} handler error: {results[2]}`)
				return false
			end
			return true, table.unpack(results, 2, results.n)
		end
	end

	return definition :: any
end

function Net.Publish()
	assert(isServer, "Net.Publish is server-only")
	assert(not published, "Net.Publish was already called")
	published = true
	folder().Parent = ReplicatedStorage
end

return Net
