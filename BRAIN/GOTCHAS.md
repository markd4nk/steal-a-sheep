# Roblox gotchas

Traps that code review won't catch, and that cost games players, Robux, or moderation. Each links its source.

## Platform rules (breaking these gets a game moderated)

- **Filter all player-written text** that other players can see: sign text, pet names, custom titles,
  anything from a TextBox, even text loaded from DataStores. Server-side
  `TextService:FilterStringAsync(text, fromUserId)`, then `GetNonChatStringForBroadcastAsync()` (everyone) or
  `GetNonChatStringForUserAsync(userId)` (one viewer). If filtering fails, show nothing. Filter after submit, not
  per keystroke. Chat through `TextChatService` is filtered automatically.
  https://create.roblox.com/docs/ui/text-filtering
- **Paid random items** need odds shown before purchase, and a `PolicyService` check for restricted players.
  See `PATTERNS/purchases.md`.
  https://create.roblox.com/docs/production/monetization/paid-random-items

## Trust

- The client is hostile. It can fire any remote with any arguments at any rate, and read everything in
  `ReplicatedStorage`, `Workspace` and its own `PlayerGui`. Net guards check shapes; the server still checks rules.
- Clients simulate physics for assemblies they own, including their own character. Position, velocity and
  touches involving a player's character are client-influenced. Sanity-check distance and speed on the server
  before rewarding or damaging.
  https://create.roblox.com/docs/scripting/security/network-ownership
- Teleport data set with `TeleportOptions:SetTeleportData` passes through the client. Never put anything
  secure in it. https://create.roblox.com/docs/projects/teleport
- `Player.Idled` (the idle signal) fires only in client scripts, about 2 minutes after the last input and then
  every 30 s, so AFK is client-reported. Check it on the server too, for example by ending AFK when the character
  moves, and have the client report again on each `Idled` while the server doesn't count the player as AFK.
  Roblox disconnects players who stay idle for 20 minutes.
  https://create.roblox.com/docs/reference/engine/classes/Player

## Replication and timing

- The engine doesn't guarantee the order in which instances and property changes reach the client. A property
  change and a remote fired right after it can arrive in either order. Listen for the change itself
  (`GetPropertyChangedSignal`, `GetAttributeChangedSignal`) instead of assuming.
  https://create.roblox.com/docs/scripting/attributes
- A LocalScript in `PlayerScripts` can start before its sibling scripts and folders have been copied in from
  `StarterPlayerScripts`: a fresh place's client bootstrap found no `Controllers` folder ("Controllers is not a
  valid member of PlayerScripts"), while the same code ran in an older place. Wait for siblings by name; RobloxPack's
  client bootstrap waits for every child of `StarterPlayer.StarterPlayerScripts` (since 2026-10-05). They can index
  `ReplicatedStorage` directly: initial replication is done by then.
- `Workspace` is different from `ReplicatedStorage`: **instance streaming is on by default** for new places, so a part may not exist on
  the client yet or may stream out later. Use `WaitForChild` with a timeout, and handle `nil`. Set a model's
  `ModelStreamingMode` to `Persistent` if client code must always have it.
  https://create.roblox.com/docs/workspace/streaming
- With streaming on, a model the server creates in the same frame it answers a remote can reach the client
  100-300 ms (once 1.2 s) after the answer when the stream is busy, as on a phone's join. Idle, both arrive in the
  same frame, so a PC playtest looks fine. `ModelStreamingMode` `PersistentPerPlayer` didn't help (6 of 6 still
  late). Show the result on the client at once (a local stand-in) and swap in the server's model when it arrives.
  To reproduce in Studio: `settings().Network.IncomingReplicationLag = 1.5` from a Client call (Studio-wide; put it
  back to 0), plus a temporary flood of 20,000+ small parts created next to the player just before the action.
- `WaitForChild` without a timeout can hang forever. Always pass one outside bootstraps.
- `Players.PlayerAdded` misses players who joined before you connected, and fires before their data loads. Use
  `DataService:ObserveLoaded`.
- A new character model spawns on every respawn. Per-character connections must be redone on
  `Player.CharacterAdded`. `player.Character` can be `nil`.

## Physics and parts

- `Touched` fires repeatedly while touching, once per body part. Debounce per character.
- Collision groups are configured on `WorldRoot` (`workspace:RegisterCollisionGroup`, `CollisionGroupSetCollidable`)
  and assigned with `BasePart.CollisionGroup = "Name"`. `PhysicsService` collision methods are deprecated.
- Unanchored parts near a player may be owned (simulated) by that player's client. Server-critical objects
  (vehicles, projectiles) should be anchored or have network ownership set by the server.
- A part is at most 2048 studs along each side. A bigger `Size` is cut to 2048 without an error, so tile parts for
  anything larger (ground past the map's edge). https://create.roblox.com/docs/reference/engine/classes/BasePart#Size
- `GetPartBoundsInBox` and `GetPartBoundsInRadius` test parts' bounding boxes, so to them a mesh arch fills its whole
  gateway. To check that a path is really clear, move a probe part along it and query `GetPartsInPart` (exact
  shapes; the probe must be in the workspace), with `OverlapParams.RespectCanCollide = true` to count only solid
  parts. https://create.roblox.com/docs/reference/engine/classes/WorldRoot
- Setting a MeshPart's `CollisionFidelity` from a script reads back the old value until the next frame, and on a
  part with no parent (a fresh `:Clone()`) the change is dropped without an error. Parent the part first, then set
  it; copies keep the value.
- An imported MeshPart's pivot is its object's origin in the modelling tool (Studio's importer keeps it; older
  importers had a **Use Imported Pivot** box), which can sit well outside the part: a tree's needles pivot at the foot
  of its trunk. `PivotTo` moves that point, so place a part taken out of its group by its `CFrame` (its centre), or
  reset its `PivotOffset` first.
- Setting `Model.WorldPivot` on a model that has a `PrimaryPart` does nothing, with no error: such a model pivots on
  its primary part's pivot. Move the pivot with `PrimaryPart.PivotOffset` instead (an R15 rig's pivot is its
  `HumanoidRootPart`, about 3 studs above its feet).
  https://create.roblox.com/docs/reference/engine/classes/Model#WorldPivot
- A `Texture` on a Top face runs u along the part's local -X and v along -Z, from its +X+Z corner. Textures still
  draw on parts with `Transparency` 1.
- Roblox sorts see-through parts by distance, so a big see-through part with a Texture (ragged dirt edges) can draw
  over smaller see-through things lying on it: decals on the ground vanished. Make the big surface solid and keep
  only its edges see-through.

## Data and services

- DataStore values are limited to 4,194,304 characters (~4 MB) per key, and requests are throttled. Never save
  player data on a timer or per change; ProfileStore auto-saves. (Leaderboards are a separate store with their
  own rules: `PATTERNS/leaderboards.md`.) https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
- Studio playtests have no DataStore access unless the place is published and
  **File > Experience Settings > Security > Enable Studio Access to API Services** is on.
- `HttpService` requests are off by default (**Allow HTTP Requests**, same Security page). Keep API keys in
  server code or Secrets, never in `src/shared`. https://create.roblox.com/docs/cloud-services/http-service
- `TeleportService` doesn't work in Studio playtests. Test in the Roblox client after publishing.
- `ProcessReceipt` can have only one handler per server. `PurchaseService` owns it.

## Analytics

- `AnalyticsService` events count only when logged from the server of a published game. Studio sends nothing, so
  print events there to check them, and check the real ones with Creator Hub > Analytics > View Events.
  https://create.roblox.com/docs/production/analytics/event-types
- A funnel step logged before the steps ahead of it marks all of them done, and a repeated step counts once (but
  still costs rate limit). If players can do steps out of order, save which steps each player has reached and log
  them only in order, holding back one reached early. A last step logged whether or not the one before it happened
  (a "closed" after a "bought") counts as that earlier step too.
  https://create.roblox.com/docs/production/analytics/funnel-events
- Each server may make 120 + 20 x players `AnalyticsService` calls a minute. Sum frequent income into one economy
  event every minute or so, and cap what one player's actions (spamming a menu) can log.
- Custom fields: at most three, keyed `Enum.AnalyticsCustomFieldKeys.CustomField01.Name` to `...03.Name`, values
  strings only; past 8,000 combined values they're grouped as "Other". A game has at most 100 custom event names,
  so put details in fields, not names. Economy amounts are always positive (the flow type says source or sink).
  https://create.roblox.com/docs/production/analytics/custom-fields

## Assets

- Licensed sounds can be found without Studio or a login: search
  `https://apis.roblox.com/toolbox-service/v1/marketplace/3?keyword=<words>&num=30` (add "sfx" for effects), get
  details for up to about 25 ids from `.../toolbox-service/v1/items/details?assetIds=1,2,3` (name, duration,
  creator; the licensed creators are ProSoundEffects 7462895450 and APMOfficial 7462718749), and the file from
  `https://assetdelivery.roblox.com/v2/assetId/<id>` (a CDN `location`; gzipped OGG) to measure with ffmpeg. A
  person still has to listen.

## Time

- `os.time()`: Unix seconds (UTC). Use for saved timestamps and daily resets.
- `os.clock()`: high-precision elapsed time on this machine. Use for durations and cooldowns within a server.
- `workspace:GetServerTimeNow()`: a clock synced between server and clients. Use for countdowns both sides show.

## Language and engine

- Modules run once per side: server and each client get separate copies with separate state.
- Attributes hold simple values only (numbers, strings, booleans, Vector3, Color3, CFrame...), never tables or
  instances. Use a remote or an `ObjectValue` for those.
- Instances used as table keys keep them alive. Clear per-player tables on `PlayerRemoving` (or use weak keys).
- Connections to a destroyed instance's own events are disconnected by `Destroy`. Connections to services,
  players or other instances are not. Own them with a Trove.
- ScreenGuis default to `ResetOnSpawn = true` (rebuilt on respawn). Set `false` for UIController screens.
- Indexing a map `{ [K]: V }` is typed `V`, not `V?`. Annotate the local (`local pet: Pet? = pets[player]`) so
  strict mode makes you handle `nil`.
- Strict mode treats tables as invariant: a `{ Model }` can't be assigned where `{ Instance }` is expected (e.g.
  `RaycastParams.FilterDescendantsInstances`). Build the list typed `{ Instance }` from the start.
