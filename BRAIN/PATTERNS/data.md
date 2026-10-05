# Player data

`DataService` is the only code that touches ProfileStore. Profiles are session-locked: one server owns a
player's data at a time, and it auto-saves periodically and when the session ends.

## API

| Call | Use |
| --- | --- |
| `DataService:GetData(player)` | The live data table, or `nil` if not loaded or already released. Check for `nil` every time. |
| `DataService:ObserveLoaded(callback)` | Per-player setup. Runs for players already loaded, then for each new one. Returns a connection. |
| `DataService.PlayerReleasing:Connect(fn)` | Per-player teardown, `fn(player, data, reason)` (`"Manual"` left, `"Shutdown"`, `"External"` another server took it). Fires right before the session's final save: on leave, on server shutdown, and when another server takes the session cooperatively. (A forced steal has no final save, so it doesn't fire; the player is kicked. Clean up non-data state on `PlayerRemoving` too.) Write final state into `data` here, without yielding; it's guaranteed to be in that save. |
| `DataService:AdjustCash(player, amount)` | Example of a validated mutation: whole numbers only, never below 0. Mirrors `Cash` to a player attribute. |
| `DataService:Replicate(player)` | Re-mirror attributes after changing a mirrored field yourself. |
| `DataService:Reset(player, keep?)` | Every field back to the template except `Receipts` (so no product is granted twice) and the fields named in `keep`. For a debug "wipe save"; never to reset a player's progress. |
| `DataService:SaveNow(player, isSaved)` | Force a save and wait for it. Costs a DataStore write. **Purchases only.** |

## Rules

- Mutating `data` is enough: ProfileStore saves it. Don't call `SaveNow` for ordinary progress. ProfileStore's
  docs say `Profile:Save()` is only for critical moments. Each call is one `UpdateAsync` against DataStore
  limits.
- Use `ObserveLoaded`, not `Players.PlayerAdded`. `PlayerAdded` fires before data exists.
- Never keep a `data` reference across a yield. Call `GetData` again afterwards; the player may have left.
- On shutdown, ProfileStore may end sessions (and fire `PlayerReleasing`) before or after the lifecycle's
  `Destroy` runs. Don't disconnect your `PlayerReleasing` handler in your own `Destroy`, or you may miss it.
- On the client, wait for the player's `DataLoaded` attribute to be `true` before showing saved values.
- Keep one key per player under the DataStore value limit (4,194,304 characters, about 4 MB). Store ids and counts, not instances or
  descriptions.

## Adding a field

Update these together in `src/server/Data/PlayerData.luau`:

1. the `Data` type;
2. `Template` (the default for new players; `Reconcile` copies missing fields into existing profiles);
3. `Validate`: if the field exists, check its shape. Missing is fine.

A new field with a sensible default needs no migration. Reconcile adds it, including missing keys inside nested
tables (string keys only).

## Before changing the data of a game that has players

Read a few real saves first: in an Edit-mode `execute_luau`, read-only `ListKeysAsync` + `GetAsync` on
`PlayerData_Studio` and `PlayerData`. ProfileStore keeps the game's data under `.Data`. Write the migration and
its test from the shapes you find, not from the template. Empty tables come back as empty arrays.

## Changing or removing a field (migration)

1. Bump `PlayerData.SchemaVersion`.
2. Add `migrations[oldVersion] = function(data) ... end`, which upgrades one version in place. Migrations run in
   order on load, after `Validate` and before `Reconcile`.
3. Make `Validate` accept every older shape that a migration can still upgrade.
4. Add a test in `tests/PlayerData.spec.luau` that feeds old-shaped data through `Migrate`.

A server running old code refuses data with a newer `SchemaVersion` and kicks the player, so an old server never
overwrites newer data. After publishing a schema change, restart outdated servers: Creator Hub > Configure >
Server Management > Restart Servers > "Restart only servers with outdated versions".

## Never reset progress

If `Validate` rejects saved data, the player is kicked with a message and their data is left untouched. Don't
"fix" this by loosening validation to accept garbage or by wiping the field. Find out what wrote it.

## Studio

- Studio uses the `PlayerData_Studio` store, so playtests never touch live data.
- For a brand-new player's first session, set the `DebugBlankProfile` attribute on `ServerStorage` to `true` in Edit
  before Play: every player starts from an empty save in memory that's never written, and the tester's Studio save is
  untouched. Clear it afterwards: it's saved with the place (RobloxPack since 2026-10-05).
- Saving in Studio needs the place published and **File > Experience Settings > Security > Enable Studio Access to
  API Services** turned on. Without it, `DataService` warns once and data resets when Play stops.

References:
https://madstudioroblox.github.io/ProfileStore/api/ ·
https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits ·
https://create.roblox.com/docs/projects/update-games
