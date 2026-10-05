# Networking: Net and Remotes

Every remote is defined once in `src/shared/Remotes.luau` using `Net`. Net creates the RemoteEvent and
RemoteFunction instances, validates arguments with guards, and rate-limits per player on the server. Don't create
RemoteEvents or RemoteFunctions by hand.

## Three kinds of remote

| Kind | Direction | Server side | Client side |
| --- | --- | --- | --- |
| `Net.ToServer(name, guards, limit, unreliable?)` | client → server | `:Connect(function(player, ...) end)` | `:Fire(...)` |
| `Net.ToClient(name, unreliable?)` | server → client | `:Fire(player, ...)`, `:FireAll(...)`, `:FireExcept(player, ...)` | `:Connect(function(...) end)` |
| `Net.Request(name, guards, limit)` | client asks, server answers | `:Handle(function(player, ...) return ... end)` | `local ok, ... = :Invoke(...)` |

There is no server-to-client request. Official docs warn that `InvokeClient` can error or make the server wait
forever on a misbehaving client.

## Defining remotes

Cast each definition to its type so callers and handlers are type-checked. Firing the wrong type fails
`check.ps1`.

```lua
--!strict

local Net = require(script.Parent.Net)
local Guard = Net.Guard

local Remotes = {
	EquipItem = Net.ToServer("EquipItem", { Guard.String(40) }, { Count = 5, Window = 1 }) :: Net.ToServer<string>,
	BuyItem = Net.Request(
		"BuyItem",
		{ Guard.String(40), Guard.Integer(1, 99) },
		{ Count = 5, Window = 1 }
	) :: Net.Request<(string, number), (boolean, string?)>,
	RoundStarted = Net.ToClient("RoundStarted") :: Net.ToClient<number>,
	Aim = Net.ToServer("Aim", { Guard.Vector3(2048) }, { Count = 30, Window = 1 }, true) :: Net.ToServer<Vector3>,
}

return Remotes
```

- One guard per argument, in order. Extra arguments are rejected. Use `Guard.Optional(...)` for arguments that may
  be nil.
- Guards: `Boolean()`, `Number(min, max)`, `Integer(min, max)`, `String(maxBytes)`, `OneOf({ ... })`,
  `Instance(className)`, `Vector3(maxMagnitude)`, `CFrame(maxDistance)`, `Optional(guard)`,
  `Array(guard, maxLength)`. Number guards reject NaN and infinity. String guards reject invalid UTF-8.
- `limit = { Count = n, Window = seconds }` allows a burst of `n`, refilling to `n` per `Window`. It's required
  for everything a client can send. Set it just above what honest play needs, and debounce the client button.
- Pass `true` for `unreliable` only for frequent, disposable updates (aim direction, cosmetic effects). These use
  `UnreliableRemoteEvent`: messages can be dropped or arrive out of order.

## Handling on the server

- A `ToServer` remote has exactly one server handler; route inside it. A `Request` has exactly one `Handle`.
- Connect and handle in a service's `Start`. Guards check *shape*; the handler still checks *rules*: does the
  player own the item, are they close enough, is the cooldown over, can they afford it.
- `Invoke` returns `false` first if the call was rate-limited, rejected, the handler errored, or the network
  failed. Otherwise it returns `true` followed by the handler's results. Design handlers to return a result
  (`true` / `false, "reason"`), not to throw.
- In Studio, dropped calls are logged as `[Net] Dropped <name> from <player>: <reason>`. Live servers drop
  silently.

```lua
function ShopService.Start(_self: any)
	Remotes.BuyItem:Handle(function(player: Player, itemId: string, amount: number)
		local item = Catalog.Get(itemId)
		if not item then
			return false, "unknown item"
		end
		return Purchasing.Buy(registry, player, item, amount)
	end)
end
```

```lua
local ok, bought, reason = Remotes.BuyItem:Invoke("Sword", 1)
if not ok then
	-- network, rate limit or server error: show a generic retry message
end
```

## When not to use a remote

- Values every client should see, that change occasionally and are simple (cash, level, team, a round phase):
  set an attribute on the `Player` or an instance on the server; clients read it and listen with
  `GetAttributeChangedSignal`. `DataService` already mirrors `Cash`.
- Server-to-server events: use a `Signal` on the owning service (`systems.md`).

## Timing

- The server bootstrap requires `Remotes` then calls `Net.Publish()`. A remote defined after that errors.
- The client bootstrap waits for `ReplicatedStorage.NetRemotes` before requiring anything that uses remotes.
- `Invoke` yields until the server answers. Call it from `task.spawn` or input handlers, never from a lifecycle
  hook.
- Net remotes aren't Roblox signals, so `trove:Connect(Remotes.X, fn)` won't type-check. Own the connection
  with `trove:Add(Remotes.X:Connect(fn))`.

Reference: https://create.roblox.com/docs/scripting/events/remote
