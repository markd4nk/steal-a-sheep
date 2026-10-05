# Testing and verification

Four levels, cheapest first. Report which ones you actually ran.

| Level | What | When |
| --- | --- | --- |
| 1. Static | `./scripts/check.ps1`: format, strict types, lint (including deprecated APIs), build | Every change |
| 2. Unit tests | `tests/*.spec.luau`, run in a playtest | Logic modules: validation, math, catalogs, data migrations |
| 3. Playtest | Studio MCP: start Play, inspect, screenshot, read console | Anything with runtime behaviour or UI |
| 4. Multiplayer | Studio **Test > Server & Clients** with 2+ clients | Replication, anything involving other players |

Phones, several players, clicking and prompts from the MCP, screenshots and the camera, performance, test
purchases and running `studio/` build scripts: `testing-studio.md`.

## Unit tests

Tests live in `tests/` and sync to `ServerStorage.Tests`, so they never replicate to clients or run in live
servers. They cover logic modules (no services, no players). Test services by playtesting.

A spec file is `Name.spec.luau` returning a function that receives the suite:

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Catalog = require(ReplicatedStorage.Config.Catalog)
local Run = require(script.Parent.Run)

return function(t: Run.Suite)
	t.Test("every item has a positive price", function()
		for _, item in Catalog do
			t.Expect(item.Price > 0).ToBe(true)
		end
	end)
end
```

Assertions: `ToBe(value)` (==), `ToEqual(table)` (deep), `ToThrow()` (on a function).

**Run them** during a playtest, in the server context, with the Studio MCP `execute_luau` tool:

```lua
local ok, report = require(game:GetService("ServerStorage").Tests.Run)()
return report
```

The report ends with `N passed, M failed` and lists each failure. Run during Play, not Edit, so each run loads
fresh module code.

## Studio test tools

RobloxPack's starter code has these (since 2026-10-05; older games may have their own):

- **The debug panel**: a DEBUG button on the left edge in Studio playtests. `DebugService` runs its commands
  (`AddCash`, `WipeSave`, `GrantProduct`, `GrantPass`, `SetIgnorePasses`) and refuses them outside Studio. From the
  MCP, a Client `execute_luau`: `require(game:GetService("ReplicatedStorage").Remotes).Debug:Invoke("AddCash", 500)`.
  Add a game's own commands to `DebugService` and a button for each to `UIController/Screens/DebugPanel`.
- **A blank save**: `ServerStorage.DebugBlankProfile = true` in Edit before Play (`data.md`, Studio).

## Playtest checklist (Studio MCP)

1. `start_stop_play` to start. `get_studio_state` confirms it's running.
2. Server context, `execute_luau`:
   `return game:GetService("ServerScriptService").Bootstrap:GetAttribute("Ready")` → `true`.
3. Client context:
   `return game:GetService("Players").LocalPlayer.PlayerScripts.Bootstrap:GetAttribute("Ready")` → `true`.
4. Run the unit tests (above).
5. Exercise the change: `character_navigation`, `user_keyboard_input`, `user_mouse_input`, or `execute_luau` to
   inspect state through instances (attributes, values, the tree). `execute_luau` has its own module cache, so
   requiring a service there returns a fresh copy that was never started: `DataService:GetData` returns nil even
   when data loaded. Check the player's `DataLoaded` and mirrored attributes (e.g. `Cash`) instead.
6. `screen_capture` for anything visual. Look at it; don't assume.
7. `get_console_output`: no errors, and no warnings from our code (`[ServiceName]`, `[Net]`, `[UIController]`).
   A `[DataService] DataStores unavailable` warning is expected in unpublished places. With API access on, the
   console shows `[profilestore]: Roblox API services available - data will be saved` instead.
8. `start_stop_play` to stop.

The MCP can also delegate a whole playtest to a subagent (`subagent` tool, playtest type) for longer checks.

## Playtest quirks
- A call that returns `Target is closed` means the playtest ended by itself (`get_studio_state` shows Edit).
  Start Play again and redo steps 2-3. Per-playtest state, such as Cash earned, is gone.
- To watch behaviour over time, connect signals once in an `execute_luau` call and append what happens to a
  `StringValue` in `ServerStorage`. The connections last for the whole playtest, so read the log in a later
  call. Don't infer timing from gaps between calls: they include your own thinking time. Trust a server-side
  log over before/after reads inside one call, and measure changes rather than absolute values: the user may
  be clicking in the same playtest. Move the character off pickups and hazards before waiting.
- After a UI click, poll for the expected change (an attribute, a label's text) for a few seconds before
  deciding it failed. Don't click again while the UI shows a pending state; round trips can take seconds.
- `screen_capture` comes back as the UI over an empty dark 3D view while the Studio window is minimized or
  hidden behind other windows. Ask the user to keep Studio visible (it doesn't need focus), then capture again.
  The desktop tools' `screenshot` of the Studio window may work while it's covered (`desktop.md`).
- To test something that happens every few minutes (a spawn timer, a cooldown), shorten its numbers in Config for
  one playtest, mark each changed line with a `-- TEMP-TEST` comment. `check.ps1` fails while any `TEMP-TEST` is
  left in `src/` or `tests/`, so none of them ship.
- Send nothing else while `start_stop_play` is stopping a playtest, and wait for its answer before the next call.
  A Device Simulator query sent alongside a stop crashed Studio once: its log ended mid-close, the stop call timed
  out, and every Studio-side edit not yet saved to Roblox was only saved by Studio's auto-recovery.

## What Studio can't test

- `TeleportService` doesn't work in Studio playtests; publish and test in the Roblox client.
- Cross-server data (session locking, joining a second server) needs a published game.
- Store-page developer product purchases need Creator Hub test mode.
- Roblox resending a receipt can't be triggered, so the "granted once" rule can't be exercised directly.
  Check instead that the receipt is saved before the purchase is confirmed.

Ask the user to run these, and say in your report that they weren't verified.

References: https://create.roblox.com/docs/studio/mcp · https://create.roblox.com/docs/studio/testing-modes
