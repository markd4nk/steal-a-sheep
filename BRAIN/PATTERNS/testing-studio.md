# Testing in Studio: situations

The situational half of testing: read the section your task needs. The levels, unit tests, the playtest checklist
and the quirks every playtest meets are in `testing.md`.

## Screenshots, the camera and what loads

- `screen_capture` leaves out BillboardGuis. Check billboards with the desktop tools' `screenshot` of the Studio
  window (`desktop.md`).
- To aim a screenshot, pass `camera_position` and `look_at_position` to `screen_capture`; it works during Play as well
  as Edit. Hide the HUD first on the test client (`PlayerGui.<Gui>.Enabled = false`), or in Edit with
  `StarterGui.ShowDevelopmentGui = false` (set it back afterwards).
- When an `execute_luau` call ends, Studio's Assistant puts the camera type back to what it was when the call
  *started* ("The execute_luau changed camera type. Resetting..."). A first call made while a cutscene holds the
  camera `Scriptable` therefore pins it `Scriptable` for the rest of the playtest: it stops following the character
  and no ProximityPrompt shows. Wait out join cutscenes (a Server call with `task.wait`) before the first Client
  call. To unstick it, run a Client call that does `task.delay(0.5, function() camera.CameraType =
  Enum.CameraType.Custom; camera.CameraSubject = humanoid end)`: it lands after the reset. Setting `camera.CFrame`
  while the type is `Custom` doesn't stick either (the camera module puts it back).
- MCP calls can't catch a join: the first Client `execute_luau` after `start_stop_play` ran only once a 7.7 s join
  cutscene had ended. To see the first seconds, add a temporary LocalScript (a `TEMP_` name) to `ReplicatedFirst`
  in Edit that polls and `print`s each change, play, read `get_console_output`, then delete it. It showed
  streaming at the join: most of a big set arrived 0.2-0.4 s after the first parts, so code that hides things as a
  scene starts must also watch `DescendantAdded`.
- `ContentProvider:PreloadAsync` from an Edit `execute_luau` reports `Failure` for every id, working ones too. In a
  playtest's Client call, `ImageLabel.IsLoaded` and `ContentProvider:GetAssetFetchStatus(id)` are real (only drawn
  labels load). `MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Asset)` tells an Image (`AssetTypeId`
  1) from a Decal id (13) pasted by mistake. Moderation of many images at once, no login:
  `https://thumbnails.roblox.com/v1/assets?assetIds=<ids>&size=420x420&format=Png` (`state` Completed, Blocked or
  Pending). Studio showing a picture doesn't clear a phone.

## Performance and long measurements

- Studio throttles a window that isn't focused to about 15 fps (`Stats.FrameTime` read 0.066 s while render CPU
  work was 2 ms), so raw fps says nothing about your code. For performance checks, compare `Stats.FrameTime`,
  `RenderCPUFrameTime` and `RenderGPUFrameTime` (seconds) with and without the load, count server `Heartbeat`s
  per second, and time the per-frame loop itself in a client `execute_luau` microbenchmark. `HeartbeatTimeMs`
  and `PhysicsStepTimeMs` are deprecated.
- `ScriptProfilerService` driven from a Client `execute_luau` returns data whose every time is 0: time code with
  your own `os.clock` stopwatch instead. `HeapProfilerService:ClientRequestDataAsync` works (the client's Luau heap
  by script).
- Long snippets for Edit (tens of KB) don't need pasting: `rojo build` a Folder project of `.txt` files (each
  becomes a StringValue), copy the `.rbxm` into Studio's `content` folder, and in Edit run
  `loadstring(game:GetObjects("rbxasset://<dir>/<file>.rbxm")[1].<Name>.Value)()`. Edit has `loadstring`; Client
  and Server calls don't.
- A thread spawned from a Client `execute_luau` keeps running after the call returns, as connections do. For
  measurements that take minutes, start a bot that way, have it append to a StringValue, and read the log in later
  calls. `task.wait(29)` inside a call waits without spamming calls.
- `Humanoid:MoveTo` from the client walks the character like a player (the client owns it). Route through gates
  round fences; MoveTo gives up after 8 s.
- Take results from the bot's own last lines: a rolling window keeps moving once the bot stops.

## Running `studio/` build scripts

They build Studio-side content and run in Edit (AGENTS.md). Two traps:

- Edit keeps what `require` returned, so a script run after a change to a module it requires (a theme, a UI kit)
  builds with the old version. Run it against fresh copies: rename each original (`Theme` -> `Theme_Cached`), parent
  a `:Clone()` under the original name, run, then destroy the clones and rename the originals back.
- A long script (tens of KB) is costly to paste into `execute_luau`. With Rojo connected, copy it into `tests/`
  under a name the test runner skips (`tests/_StudioBuild.luau`, not `*.spec`), wait until it shows in
  `ServerStorage.Tests` with the new `Source`, and `require` a `:Clone()` of it: a new instance is never cached, and
  the script's closing `return` becomes the module's value (it must end with one). Then delete the file, and check
  Rojo removed it and no `_Cached` names are left.

## Studio windows, Rojo and several players

- Several Studio windows can be connected, and every MCP call takes a `studio_id`. Playtest windows show up as
  extra studios with no name: one for a solo test's server, one for each window of a Server & Clients test.
- Find this game's window before running anything: `get_studio_state` shows Edit, and
  `ReplicatedStorage.Config.GameConfig.Source` contains this game's `Name`. Leave other games' windows alone.
- A place once synced from another project keeps that project's code directly under a service (e.g.
  `ServerScriptService.Components`) after a re-sync, because `default.project.json` sets
  `$ignoreUnknownInstances` so Rojo keeps Studio-built content. Compare the Rojo-managed folders with disk and
  delete leftovers.
- `start_stop_play` only runs solo playtests. For two or more players, start **Test > Start Test Session > Server
  and Clients** (then **Test > Add Clients** if needed) and end it with the red stop button beside the client count,
  using the desktop tools (`desktop-recipes.md`); without them, ask the user to. Test players are `Player1`,
  `Player2`… with user IDs -1, -2… and their own saved data.
- The server and each client can list the same children in a different order. Match instances by name or
  position, not by index.
- `screen_capture` of a Server & Clients client window can come back as UI over a black 3D view. Check what
  that player sees through its client's instances instead.
- Server & Clients client windows are small, so Roblox's own UI (the chat window top left, the menu buttons top
  right) covers parts of the game's, and `user_mouse_input` there fails with `hits CoreGUI`. Hide the chat from
  that client's `execute_luau` (`TextChatService.ChatWindowConfiguration.Enabled = false`, and the same for
  `ChatInputBarConfiguration`), and close a menu some other way than a button under the top bar, such as walking
  away when it closes itself. An open modal menu's backdrop also swallows clicks meant for screens under it.
- A test client nobody touches goes AFK: `Player.Idled` fires on it about 2 minutes after its last input. Features
  that check AFK treat it that way.
- Ask the user before opening a second Studio: each takes about 3 GB (`sessions.md`, One Studio window). With their
  OK, a local copy of the place (a second Studio on an `.rbxl`, leaving the shared place to other sessions) can take a
  whole branch's code at once, with no Rojo and no mouse (seen 2026-10-03): build a model of the Rojo folders with a
  project file kept outside the repo whose root is a `Folder` holding `ReplicatedStorage`, `ServerScriptService`,
  `StarterPlayerScripts` and `Tests` (each `$path` pointing at the branch's folder), `rojo build` it to an `.rbxm`
  (run from the repo, where rokit finds the tool), copy that into Studio's own `content` folder
  (`%LOCALAPPDATA%\Roblox\Versions\<version>\content\<dir>`), and in Edit load it with
  `game:GetObjects("rbxasset://<dir>/<file>.rbxm")[1]`, moving each child over its namesake in the real containers.
  `InsertService:LoadLocalAsset` is refused from `execute_luau` (it needs a higher capability). Delete the copy in
  `content` afterwards.
- Two Rojo plugins (the file `rojo plugin install` writes and the Creator Store one) can both connect to one
  `rojo serve`, and then every new file is created twice in Studio: `require` takes the first copy silently, but
  specs run twice and the doubles get saved into the place. Keep one plugin: look for two Rojo buttons on the
  Plugins tab. To clean up, disconnect, destroy the second copy of each same-named script and reconnect one.
- Clicking Disconnect in the Rojo plugin leaves `ServerStorage.__Rojo_SessionLock` in the place: delete it in Edit
  before saving. After `rojo serve` restarts, or the Studio MCP's id changes, the plugin shows a WebSocket error:
  Okay, Connect, then Accept the initial sync. Files added or deleted while it was down only reach Studio then.
  Run `rojo serve` as a background command with a long timeout (Claude Code: `timeout: 7200000`); the default 30
  minutes stops it mid-task.
- A Server & Clients client's `execute_luau` can't `require` the game's `Remotes` (a Capabilities error) and has no
  `_G`. Call the remote instance directly (`ReplicatedStorage.NetRemotes.<Name>:InvokeServer(...)`; Net answers
  `callOk, ...results`) and keep state between calls in a StringValue under `PlayerGui`. A call returning
  `LocalPlayer.Name` tells the clients apart. Calls sent to two clients in one message run one after the other.
- `player:Kick()` in a playtest (to test `PlayerRemoving`) leaves a modal "Disconnected" dialog after the stop. It
  blocks the whole Studio window, Rojo's Connect included. Close it before handing Studio over: it's a window of
  its own titled RobloxStudio, and a desktop click on its blue Close worked where `click_element` didn't.

## Clicking, prompts, combat and NPCs

- Keep the test player alive: raise the Humanoid's `MaxHealth` and `Health`, and delete the character's
  `Health` script. It regenerates 1% of `MaxHealth` per second, which hides damage.
- To see what a client sent, connect to `ReplicatedStorage.NetRemotes.<Name>.OnServerEvent` from a server
  `execute_luau`. The remote instance is shared even though modules aren't.
- Test NPC movement from ground level towards raised parts (spawn pads, curbs), not only from where it
  spawned. A pet that passed every test starting on the spawn pad got stuck walking into it from the ground.
- `user_mouse_input` clicks work, including on tools. Outside the Device Simulator (below) touch can't be emulated,
  and gamepad buttons sent with `user_keyboard_input` didn't activate a tool. `tool:Activate()` in a client
  `execute_luau` runs the same `Activated` path. Report gamepad as unverified, or ask the user to try
  **Test > Controller Emulator**.
- Aim at GUI buttons with `instance_path` (`LocalPlayer.PlayerGui.Hud.Root.BuyButton`): it lands on the element's
  centre. x/y worked out from `AbsolutePosition` minus the top bar landed below a button whose ScreenGui has
  `IgnoreGuiInset` on.
- Aim at the world with `camera:WorldToScreenPoint(position)`: like `user_mouse_input`'s x/y it leaves out the top
  bar (`WorldToViewportPoint` counts from the window's top). Game code turns such a point into a ray with
  `ScreenPointToRay`. The first action of every call needs a position; a click on its own is rejected.
- In the Device Simulator, small buttons near the edges (a menu's close X, the HUD's top row) were missed by both
  `instance_path` and x/y. A desktop-tools click on a fresh screenshot of the Studio window hit every time. Confirm
  a click with an `Activated` probe connected from a Client call before blaming the game.
- `prompt:InputHoldBegin()` then `prompt:InputHoldEnd()` in a client `execute_luau` triggers a `ProximityPrompt`
  the same way pressing its key does, without keyboard emulation, once the prompt is showing. After teleporting the
  character, wait for `ProximityPromptService.PromptShown` to fire for that prompt rather than for a fixed time
  (0.35 s waits missed, and one-second waits missed now and then). It doesn't fire again for a prompt that's already
  showing, so first move the character out of range if it may still be near. Position-based server logic also needs
  about a second to see the character's new position. `InputHoldBegin` does nothing while the prompt is off screen
  (a filming camera pointed elsewhere): aim the camera at it first. A menu a prompt opened closes itself when the
  character walks out of range, a way to close one on cue.
- A client-side `PivotTo` of the character isn't a jump to the server: it sees the character slide there over a
  few frames, so server checks along the way fire (a "walked into the pen" check fired mid-path). Route test
  teleports round such areas with waypoints about 0.7 s apart, and log positions on the server.
- A client-side copy of a model whose unanchored parts hang off an anchored root falls apart once the root is taken
  out, and `FallenPartsDestroyHeight` deletes it about 2 s later. Anchor every part of such test copies.

## Phones: the Device Simulator

The MCP can drive Studio's Device Simulator for phone checks. The Studio MCP's `rbx-device-simulator-lua` skill has
its API.

- Pick the device in Edit with `StudioDeviceSimulatorService` (`GetDeviceListAsync`, `SetDeviceAsync`, then
  `SetOrientationAsync`, which errors until a phone is active) **before** Play: its setters fail during a playtest.
  Call `StopSimulationAsync()` in Edit afterwards to give the user their normal viewport back. It returns fine but
  can leave the device bar and the phone viewport up: close it with the X at the bar's right end (a desktop click)
  and check it's gone.
- Studio counts every screen as pixel density 1, even in the simulator, so icon sizes picked by density only show on
  a real phone.
- In the simulator, `UserInputService.PreferredInput` is `Touch` and `user_mouse_input` clicks arrive as touches,
  so touch-only code paths run. Gamepad Y sent with `user_keyboard_input` works; B is reserved by Roblox and
  can't be sent.
- `user_mouse_input` doesn't map positions through the simulator's scaling, so taps land off target:
  `instance_path` aiming missed buttons away from the middle of the screen, and `x`/`y` taps landed 62 px left of
  and 20 px above the given point (iPhone 17 Pro, sideways, in a 1274 px wide Studio viewport). Measure the offset
  first: connect `UserInputService.InputBegan` in a client `execute_luau`, log each `input.Position`, tap two known
  points, and compare. Then tap a button at its `AbsolutePosition + AbsoluteSize / 2` plus the offset.
- Hide Studio-only panels on the test client (`PlayerGui.<Panel>.Enabled = false`) before judging the layout; on
  a phone-sized screen they cover the HUD.

## Purchases and saving

Needs a published place with **Enable Studio Access to API Services** on, and the product created in Creator
Hub (`purchases.md`).

- Prompt from a client `execute_luau` with `MarketplaceService:PromptProductPurchase(player, productId)`.
  Roblox's purchase dialog doesn't appear in `screen_capture`, so click **Buy** with the desktop tools
  (`desktop-recipes.md`), or ask the user to. Studio test purchases don't charge.
- The user's own account owns the passes it created. Studio's `PurchaseService` ignores them until
  `SetIgnorePasses` is switched off (`purchases.md`), but Roblox's dialog still knows: to test buying a pass, play as
  a Server & Clients test player (`Player1`), who owns nothing.
- Log it on the server: the mirrored attribute (e.g. `Cash`) changes, and
  `MarketplaceService.PromptProductPurchaseFinished` fires with `purchased = true`. It fires when the player clicks
  OK on "Purchase completed", not at Buy, while the receipt is granted at Buy. The Buy button fills like a progress
  bar first: wait about 2 s before clicking it.
- An off-sale developer product can't be test-bought ("This item is not currently for sale"); grant it through a
  debug command instead.
- Read what was actually saved, on the server:
  `DataStoreService:GetDataStore("PlayerData_Studio"):GetAsync("Player_" .. userId)`. ProfileStore keeps the
  game's data under `.Data`, including `Receipts`. Then stop and start Play and check the value comes back.

References: https://create.roblox.com/docs/studio/mcp · https://create.roblox.com/docs/studio/testing-modes
