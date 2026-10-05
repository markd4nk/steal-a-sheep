# Systems: services, controllers, startup

A **system** is a module table with a `Name` and optional `Init`, `Start` and `Destroy`, run by
`src/shared/Lifecycle.luau`. **Services** (server) own state, rules and validation. **Controllers** (client) own
input, camera, UI and presentation; they ask services for changes and never decide outcomes.

## Startup rules (enforced by Lifecycle)

- Every `Init` runs in registry order, then every `Start` in registry order. Once per session; no hot reload.
- `Init(self, registry)` gets the full name → system table. Store it and set up local state only. Other systems
  may not be initialised yet, so don't call them.
- `Start(self)` connects events, handles remotes and begins work. Calling other systems is safe from here on.
- **Hooks must not yield.** Lifecycle runs each hook in a coroutine and fails startup if it yields. Put waiting
  work in `task.spawn`.
- If any hook errors, startup stops, already-initialised systems are destroyed in reverse order, and the error
  is reported as `[SystemName.Phase]`.
- `Destroy(self)` disconnects, destroys and cancels what the system owns. It must cope with `Start` never having
  run. The server calls it from `BindToClose`; the client when its bootstrap is destroyed.
- Both bootstraps set a `Ready` attribute on their script when startup succeeds.

## Adding a system

1. Create `src/server/Services/NameService.luau` or `src/client/Controllers/NameController.luau`.
2. Return a table whose `Name` matches the file name, with all three hooks (an empty one is fine). Strict mode
   rejects a registered system that leaves one out.
3. Add its `require` to that side's `Registry.luau` after every system it depends on.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lifecycle = require(ReplicatedStorage.Lifecycle)
local Trove = require(ReplicatedStorage.Packages.Trove)

local RoundService = { Name = "RoundService" }

local registry: Lifecycle.Registry = {}
local trove = Trove.new()

function RoundService.Init(_self: any, systems: Lifecycle.Registry)
	registry = systems
end

function RoundService.Start(_self: any)
	-- State every client reads is replicated as attributes, not sent through remotes (networking.md).
	ReplicatedStorage:SetAttribute("RoundPhase", "Intermission")
	trove:Add(registry.DataService:ObserveLoaded(function(player: Player)
		player:SetAttribute("InRound", false)
	end))
end

function RoundService.Destroy(_self: any)
	trove:Clean()
end

return RoundService
```

## When to make a new system

Make a new service when a feature has its own state that others should change only through its methods (a
round timer, a shop's stock) **and** its own lifetime (per-player setup, connections, timers). Most also handle
their own client requests, but server-only simulations (NPCs, projectiles, spawners) with their own state and
loop are services too.

Don't make a system for:

- part of an existing feature: add a child module to that system (below);
- behaviour on many tagged instances: make a component (`components.md`);
- constants: `src/shared/Config`;
- stateless helpers: a plain module next to its user, or `Utils/` if several systems need it.

On the client all UI belongs to `UIController` (`ui.md`). Make a separate controller only for non-UI behaviour
with its own state or per-frame work: `CameraController`, `PlacementController`, `VehicleController`.

Split a system in two when its methods start being about two unrelated things, or other systems keep reaching
into its data.

## Big systems become folders

Once a system has more than one concern (or passes ~300 lines), make it a folder. Rojo turns a folder with
`init.luau` into one ModuleScript with the other files as children, so the registry `require` doesn't change.

```text
src/server/Services/ShopService/
	init.luau        -- the system: Name, hooks, state, connections, remote handlers
	Catalog.luau     -- one concern per child module
	Purchasing.luau
	Types.luau       -- types shared by the folder
```

- Only `init.luau` has hooks, owns state and connections, and appears in the registry.
- Child modules are plain functions with no module-level state. They get what they need (registry, player,
  state) as arguments. They may require `Types` and pure siblings, never `init.luau`, never in a cycle.
- Split by responsibility (lookup, validation and mutation, networking, presentation), not by line count.

## Talking to other systems

- Use the registry captured in `Init` (`registry.DataService:GetData(player)`), not a direct `require` of
  another system. Direct requires hide dependencies and break when registry order changes.
- Dependencies point one way. If two systems need each other, the lower one exposes a `Signal`
  (`ReplicatedStorage.Packages.Signal`) that the higher one connects to in `Start`, as `DataService.PlayerLoaded`
  does.
- `Signal` runs the newest connection first, so handlers that several systems connect to one signal (including
  `DataService:ObserveLoaded`) run in reverse registry order. Don't depend on that order: make each handler
  complete on its own, or have the lower system fire its own signal once its part is done, and connect to that.
- Clean up with `Trove` (`ReplicatedStorage.Packages.Trove`) or plain connection lists. Type a trove you pass
  to a helper as `typeof(trove)`: strict mode won't match the package's `Trove.Trove` type with what
  `trove:Extend()` returns.
