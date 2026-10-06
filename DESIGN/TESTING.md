# Testing

This game's own test tools and measurements.

## Debug panel (Studio only)

The DEBUG button on the left edge, or `require(ReplicatedStorage.Remotes).Debug:Invoke(command, value)` from a Client
`execute_luau`:

| Command | Value | Does |
| --- | --- | --- |
| `AddCash` | coins (1000) | Coins |
| `AddClimb` | Climbing (100) | Climbing, and a fresh snapshot |
| `Steal` | tier | Teleports to that tier's first ready lamb and steals it (the climb check starts from there) |
| `Home` | - | Back inside the player's own gate (a carried lamb stays on their head), as the server's own teleports do |
| `GiveSheep` | tier, and after the point the herd slot (30.6 = Zeus's Mythic) | A Plain lamb of it straight into the flock, as if delivered |
| `FillDex` | how many of each herd, Common first (6) | Marks them found in the Sheepdex, rewards unclaimed |
| `GrowAll` | - | Every lamb grows up on the next tick (with its reveal) |
| `UnlockAll` | - | Zeus's Heavy target in Climbing and one delivery from every tier |
| `SetWalker` | level (1-30) | The stair walker at that level (its look, step speed and sign) |
| `ResetGift` | - | The free gift can be claimed again (its HUD button comes back) |
| `DailyReady` | - | Today's daily gift waits now, as if its 20 hours had passed |
| `DailyDay` | day (1-7) | The daily gifts' day to claim next, waiting now (7: the Pegasus Sheep) |
| `WipeSave` | - | A new player's save |

Set `ServerStorage`'s `DebugBlankProfile` attribute in Edit for a first-session playtest (pack feature).

The Robux store in a playtest (2026-10-05): until a product or pass has its Creator Hub id in `Config/Store`, every
store button grants it at once in Studio (a "Studio: no product yet" notice), so buy anything by clicking it, or from a
Client `execute_luau`: `Remotes.RequestPurchase:Invoke(key)` with "Cash.1", "Climb.6", "Sheep.Kronos", "DoubleMoney",
"Speed" or "Walker". A pass granted that way lasts the session. The STORE button shows after the first delivery
(`GiveSheep`); `GrowAll` then gives the Robux sheep a "best sheep" to multiply. Cards are named after their key without
the dot (`SheepGoldenFleece`, `Climb1`), so `user_mouse_input` can reach them by `instance_path`. On a Galaxy A06 in the
Device Simulator taps landed 47 px left of their aim (no vertical shift): tap a button at its centre + 47 in x.

The free gift in a playtest: `GiveSheep` 1 counts as the first delivery, and the menu opens by itself 30 s later at the
plot. Claim skips Roblox's favorite prompt while the place is unpublished (PlaceId 0).

UI mock-ups without playing: in Edit, `require` a screen module from `StarterPlayerScripts.UIController.Screens`, call
its `Build(StarterGui)`, name the ScreenGui `TEMP_...`, enable it, fill its labels, and set `Root.Scale.Scale` (1.25),
`Root.Size` (1/scale) and each `UITextSizeConstraint` from its `MaxPoints`/`MinPoints` attributes times the scale, as
`UIController/Scale` does in play. Delete the `TEMP_` guis after.

## Slide animation mock-ups (2026-10-06)

- **Is the surf or a god's clip on?** A `PreSimulation` connection made from `execute_luau` ran before the
  controllers' and read the Animator's transforms, not the clips'. Read the LowerTorso's frame in the
  HumanoidRootPart's space from `RenderStepped` instead: surfing it turns about -78 degrees and drops about 0.5 studs.
  A real theft in one call: `Debug:Invoke("Steal", 1)`, then a RenderStep at `Input + 1` calling `Humanoid:Move(-X)`;
  `Debug Home` and `Remotes.PutDown:Fire()` deliver a lamb still carried from the last try (a new steal is refused).
  Moving 1.2 s, then braking (`Move(+X)`) gets the thief caught at tier 1 with Climbing 25.
- `studio/SlideMockup.luau` is the mock-up the user picked from: its clips were copied into `Utils/BodyClips`, which is
  the one to change; the mock-up keeps the Penguin and Sled variants.
- **Rerun them**: build a place copy (`rojo build`, then `tools/assemble.luau` into `build/AnimMock.rbxl`), open it in
  its own Studio, play. `rojo build` a one-file project of `studio/SlideMockup.luau` into the Studio version's
  `content/sas-anim/mock.rbxm`; in a Client `execute_luau`, `game:GetObjects("rbxasset://sas-anim/mock.rbxm")[1]`,
  parent it to ReplicatedStorage, require it, then `Mock.Shot("Now" | "Chase" | "Penguin" | "Surf" | "Sled")`;
  `Mock.Done` turns true at the shot's end, `Mock.Stop()` puts the HUD, camera, Pan and the character back. Set
  `Mock.TimeScale = 0` to freeze a frame for `screen_capture`. A server `LoadCharacterWithHumanoidDescription` with the
  classic yellow, blue and green colours gave a plain blocky avatar for it (Studio's own is a skinned cat).
- **Tier 1's lane isn't empty**: `Stages.Stage1.Tree2` stands mid-lane at (517, 188), Tree3 at (488, 222), Tree1s at
  (437, 156), (546, 222) and (554, 136). Their leaves are `CanQuery = false`, so raycasts pass through them; the shots
  run x 500 to 440 near z 196 with the camera on the low-z side.
- **Filming without the screen**: Studio behind other windows shows a new picture every 4th captured frame. The shots
  run at `TimeScale = 0.25` (the wild lambs are hidden: they'd graze four times too fast), OBS records the Studio window
  by its title, and `build/mock/cut.py TAKE OFFSET 0.25` keeps each picture at its true time (`mpdecimate`, then the
  timestamps times 0.25). OBS crop for a maximised Studio with Explorer open and no emulator: 167 146 345 71, canvas
  1408 x 792 (the game view's middle, clear of Roblox's menu buttons). The phone emulator must be off (Test menu, only
  outside a playtest): with it on, the game view was 705 x 338.

## The chase's sounds and red screen (2026-10-06)

- Own place copy `build/ChasePlaytest.rbxl` (rojo build, then `tools/assemble.luau`, opened in its own Studio); code
  swapped in from `content/sas/chase-sync.rbxm`.
- A chase that lasts: `Debug Steal` (tier), then a Client `RenderStepped` loop that pivots the character a set
  distance downhill of its god (`god.PrimaryPart.Position.X - D`, `Mountain.Floor` + 3): D shrinking walks the level
  up; held at 18 studs it stays near the top. Past `Olympus.SafeLineX` = an escape. End the carry before the next
  steal, or it's refused ("You're already carrying one"): there's no giving up a run since the onboarding trail
  (no `Remotes.ReturnSheep`), so put it down at home (`Debug Home`, then `Remotes.PutDown:Fire()`) or let the god
  catch you.
- What to watch: `PlayerGui.ChaseScreen.Top.BackgroundTransparency` (edges), `Lighting.ChaseGrade.Saturation`,
  `SoundService.GameSounds.RunForYourLife`/`RunForYourLifeDrums` Volume and IsPlaying, the `Heartbeat1`/`2` pool, and
  `Sound.Played` on the god's descendants (its sounds are made on first use, so watch `DescendantAdded` too).

## Daily gifts (2026-10-05)

- Own place copy `build/DailyPlaytest.rbxl` (code swapped in from `content/sas/daily-sync.rbxm`). After `GiveSheep` (the
  first delivery) the free gift's menu opens at 30 s and the daily gifts' at 45 s once nothing else is open: claim the
  free gift first (`Remotes.ClaimGift:Invoke()`) to see the daily one open by itself.
- `Remotes.ClaimDaily` allows 2 calls in 2 seconds: space scripted claims out or the third is dropped ("[Net] Dropped
  ClaimDaily ... rate limit").
- That Studio had its Device Emulator on a phone (Samsung Galaxy A06, 800 x 360), so clicks arrive as touches
  (`UserInputService.MouseEnabled` false). The Studio MCP's `user_mouse_input` worked once (a click at a gui's
  `AbsolutePosition` + (0, 58) opened the menu) and later sent nothing at all, likely while another session's Studio
  was the front window; `VirtualInputManager` needs a higher capability than `execute_luau` has. The reliable route
  was the desktop tools on this Studio's window (announced, and handed back to the other sessions after).
- The Pegasus in daylight: clone `ReplicatedStorage.SheepLooks.Pegasus` to (0, 400, 0) in the sky, scale it, and
  `screen_capture` from about 12 studs off its front-left; delete it after.

## Sell Stall (2026-10-05)

- Own place copy `build/SellPlaytest.rbxl` (as the pens session's below), code swapped in from
  `content/sas/sell-sync.rbxm`. Flock for a test: `Debug UnlockAll`, `GiveSheep` a dozen times (the first 8 fill the
  pen, the rest are stored lambs), `GrowAll`, then `FlockAction Unequip` an adult or two to store them.
- Open it like a player: pivot the character 6 studs in front of `Workspace.Stations.SellStation`'s `StationPrompt`
  and press E (`user_keyboard_input`); cards are `SellStall.Root.Window.Pages.GridWell.List.Sheep<id>`, the buttons
  `...Pages.SellTile.SelectButton` / `SellButton`, the confirm's `...Root.Confirm.Dialog.Body.Buttons.ConfirmButton`.
- `Remotes.Sell` allows 4 calls a second: space out several refused-sale checks or the fifth is dropped.

## Pens in this session's own Studio (2026-10-05)

- **Own place copy**: with other sessions each in their own Studio and main's mid-playtest, `rojo build
  default.project.json --output build/game.rbxl` then `lune run tools/assemble.luau 'vvs_map(commission) (1).rbxl'
  assets/ShearASheepAssets.rbxm build/game.rbxl build/PenPlaytest.rbxl`, opened with `RobloxStudioBeta.exe <path>`, and
  addressed only by its MCP name. Code updates: `rojo build tools/sync.project.json` into the Studio version's
  `content/sas/pens-sync.rbxm` (a name of its own: other sessions write `sync.rbxm` there), then the GetObjects swap in
  Edit.
- **A theft in one command**: `Debug:Invoke("Steal", tier)`, then `character:PivotTo` into your plot and
  `Remotes.PutDown:Fire()` in the same `execute_luau` (left standing at the pasture between commands, the god catches
  you). `Debug UnlockAll` first for tiers above 1. Look for the prompt by name (`PutDownPrompt`): the carried lamb
  still holds its disabled `StealPrompt`.
- **Poses held still**: clone a pen sheep on the client, `RemoveTag(clone, "Sheep")` so AnimController leaves it alone,
  set its Motor6D `Transform`s from `SheepClips` and wait a frame before reading part positions. Ground in the plots is
  y 59.46; the graze puts the head's lowest corner at 59.56 on a Standard adult.
- **Filming**: `screen_capture`'s `camera_position` is temporary. To hold a camera for `windows-computer-use` `record`,
  bind a RenderStep at `Enum.RenderPriority.Last` that sets a Scriptable camera, hide the ScreenGuis, and undo both
  after. The recorder writes its mp4 into the repo (`windows-computer-use/`): move it out; crop the game view with
  ffmpeg. To film a face, follow the sheep's front each frame (`pivot + LookVector * 5 * scale`), finding the model by
  its `SheepId` (a lamb that grows up is rebuilt as a new model).
- **Face art before it's uploaded**: copy the PNGs into the Studio version's `content/sas-pens/faces/`, and in Edit
  point the place's own `GameConfig` Source at them (`MunchA = "rbxasset://sas-pens/faces/MunchA.png"`, `ChewFaces`);
  only that Studio sees them. Put the Source back after (compare its length with the file on disk).
- **Lambs grow up during a take**: a lamb is grown after 45 + 15 x (tier - 1) seconds in the pen (tier 2: a minute),
  and grown sheep graze far less. Film a tier 8+ lamb (150 s or more), or film soon after putting it down.
- **Is a sheep animating?** Log its `Head.Face.Texture` every RenderStepped for 20-30 s (and its `Spot` changes): a
  grazing lamb shows the chew frames about a third of the time, blinks every few seconds and baas now and then. Part
  positions read from a script don't show the animation (AnimController puts the joints back after each step).
- **Uploading pictures**: the Studio MCP's `upload_image` needs a Studio with a place open; serve the PNGs with
  `python -m http.server <free port> --bind 127.0.0.1` and stop it after. A new picture fails to load until Roblox's
  review clears it (a few minutes); a Studio that tried before then may keep reporting Failure, so check in a freshly
  opened Studio, or draw it in an ImageLabel (`IsLoaded`).
- **Closing your Studio**: other sessions' "Save changes to ...?" dialogs look the same as yours. `window list` with
  `details`, screenshot the dialog by its `hwnd`, `focus` that hwnd, then click Don't Save. Close the old window
  before opening a rebuilt copy of the same file, or its save prompt meets "file in use".

## High Olympus in an open Studio (2026-10-05)

- **Preview the map**: `lune run tools/preview-upper-mountain.luau "<Studio version folder>/content"`, then in Edit:
  `local m = game:GetObjects("rbxasset://sas/upper.rbxm")[1]; m.Parent = game.ServerStorage;
  require(m).Build({ Instance = Instance, CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum,
  NumberRange = NumberRange, NumberSequence = NumberSequence, NumberSequenceKeypoint = NumberSequenceKeypoint,
  ColorSequence = ColorSequence }, workspace); m:Destroy()`. It replaces `Stages.HighOlympus` each run.
- **A slide bot along the path (2026-10-06)**: in one Client `execute_luau` (standing still between calls, the god
  catches you): `Debug UnlockAll`, `Debug Steal 30`, then a RenderStep at `Input + 1` that calls `Humanoid:Move`
  towards the first `Path` tile 30 studs further down (tiles under `Stages.HighOlympus`, sorted by x), logging
  horizontal speed drops (a bump: under 0.6 of the last frame's) and jumps in x over 60 (a punch). `Move(-X)` instead
  slides straight. Measured: 51.7 s along the path, 54.0 s straight (10 bumps), Zeus's top to x 3060.
- **Branch code without Rojo**: `rojo build tools/sync.project.json` (a Folder-rooted copy of the project:
  ReplicatedStorage, ServerScriptService, StarterPlayerScripts, Tests) into `content/sas/sync.rbxm`, then in Edit
  `GetObjects` it and swap each container's children.
- **Filming High Olympus in play (2026-10-06)**: a Scriptable camera held over a stretch while the character stands at
  the plots draws only the sky there (seen on Hypnos's stretch, main's version too); pivot the character (anchored)
  near the shot first. With the character there and the normal camera it draws properly. `windows-computer-use`
  `record` on a background Studio window gave identical frames; foreground it (no input needed) for motion clips.
- **Lane check**: every collidable part under a stretch's `Decor` in its frame (x across, y up from the floor) must have
  |x| >= 56 or sit 16+ studs up; under its `Lane`, collidable parts lower than 16 must leave 28+ studs across the
  lane everywhere, keep off the `Path` tiles and 6 studs from the lamb and god spots. `lune run tools/check-lanes.luau` checks the built `StealASheep.rbxl` without Studio
  (exits 1 and lists the parts if any are in the lane); rerun it after changing a theme or the stretches' layout.
- **A mesh's cost**: in Edit, `AssetService:CreateEditableMeshAsync(part.MeshContent)` then `#mesh:GetFaces()` gives its
  triangles, and `AssetService:CreateEditableImageAsync(part.TextureContent).Size` its texture size (destroy both
  after). Measured 2026-10-05: `generate_mesh` gods come out at 8.8-9.9k triangles with a 1024x1024 texture unless
  `maxTriangles` caps them (at 4,000 a face up close turns blurry); split into seven pieces they carried seven
  1024 textures. Its prompt fails ("Character limit exceeded") somewhere past about 430 characters.
- **`check.ps1` doesn't read `tools/`**: a syntax error in `UpperMountain.luau` only shows when `build-place.ps1` runs
  it. Run `stylua --check tools/UpperMountain.luau` or build the place after editing the builder.
- **Slides on the steep stretches**: bind a RenderStep at `Input + 1` that calls `Humanoid:Move(-X)` (the slide reads
  MoveDirection) and sample `FloorMaterial` and height over `Mountain.RampY`. Measured from Zeus's pasture: 60 studs/s
  along the floor is 37 across it at 52 degrees; 0 of 74 samples in the air with the ramp hold, 29% without.
- `require` of a game module from `execute_luau` gets a fresh copy, not the running one (SheepService:Build returned
  nil): to look at families or gods side by side, clone the running game's own wild lambs and gods instead.

## Stair walker climbing test (2026-10-05)

- **Avatars measured**: the user's (a skinned R15 cat with the Avatar Joint Upgrade: AnimationConstraints, arms rest
  in a T-pose) has thigh 0.64, shin 0.56 (hip-to-ankle reach 1.2), foot 1.29 long, hip height 1.57. A default blocky
  R15 rig (`CreateHumanoidModelFromDescription` on the server) has reach 1.93 and a 1.0 foot. With 0.6 x 1.0 steps
  both reach the upper step comfortably.
- **Showing motion without the desktop tools**: drive the animation from a phase variable, set it from Client
  `execute_luau` (0, 0.25 ... 1.75), `screen_capture` from a fixed camera after each, and join the frames into a GIF
  with Pillow (140 ms a frame is real speed for a 0.55 s step).
- A side view hides the far leg; a camera a little in front of the side shows both.

## Playtesting through the Studio MCP from a script (2026-10-05)

The build session drove a second Studio holding a copy of the built place (`build/Playtest.rbxl`, opened with
`RobloxStudioBeta.exe <path>`) through Studio's MCP server (`%LOCALAPPDATA%\Roblox\Versions\<v>\StudioMCP.exe`,
JSON-RPC over stdio), always picking that Studio by name so the Shear a Sheep window was never touched. Code went in
without Rojo: `rojo build` of a project whose root is a Folder holding ReplicatedStorage, ServerScriptService,
StarterPlayerScripts and Tests, written into Studio's `content\sas\` folder, then an Edit `execute_luau` that
`game:GetObjects("rbxasset://sas/sync.rbxm")` and swaps each container's children.

Useful measurements:

- Slide: tier 1 Light lamb 20.1 studs/s, Stout 17.3; tier 7 Light at full training ~38.8. Gods: 21.1 (tier 1's
  chasing a slider), 35.2 (tier 7's), 12.6 (tier 1's on the tutorial run, walking target).
- Holding E for 0.7-0.9 s through `user_keyboard_input` steals a lamb; W held with the camera turned downhill starts a
  slide.
- Screenshots: `screen_capture` with `camera_position` turns on Freecam, which then eats the mouse; restart the
  playtest after using it. The world and ViewportFrames only render in captures while the Studio window isn't
  minimized.

## Leaderboards (2026-10-05)

- In an unpublished place the boards rank the players in the playtest only and say "This server". A new save is 0 in
  everything, so a board reads "No one yet" until the debug panel adds Climbing or sheep (`GiveSheep` gives
  income and counts as a steal); boards redraw every 5 s. Selling through `Remotes.FlockAction:Invoke("Sell", id)`
  checks This Server drops while Top Income keeps the best.
- To see full boards, set rows 2-10's `Visible`, `PlayerName.Text`, `Value.Text` and `Picture.Image` from a Client
  `execute_luau` (`workspace.Base.Leaderboard.<model>.<Id>Board.Screen.Back.Row<n>`): the server leaves rows it
  hides alone, so they stay until Stop. Hold the camera with a RenderStep bound after `RenderPriority.Last` (setting
  it once is undone by the camera scripts), and unbind it after.

## Climbing playtest (2026-10-05)

- **Swap a branch's scripts into the open place**: `rojo build tools/sync.project.json` into the Studio version's
  `content/sas/`, then in Edit move each same-named child of ReplicatedStorage, ServerScriptService and
  StarterPlayerScripts (and `ServerStorage.Tests`) into a `ServerStorage.TEMP_MainScripts` folder and parent the new
  ones; put them back the same way afterwards and don't save.
- **Drive a slide**: bind a RenderStep at `Input + 1` calling `Humanoid:Move` towards (-1, 0, dz) with dz steering to
  z 192: the lanes at z 168-198 run clear from tier 3 down (raycast check); a straight -X slide from the tier 3 lamb
  spot hits a tree at x 852.
- **Wait for the god to get home** between chases (Mood "Idle"): a returning god walks home at 16 studs/s and sits in
  the lane, and the next thief slides into it (up to 42 s on tier 3).
- **Measured**: uphill on tier 3 (sign 800): 1.0 studs/s at 0 Climbing, 4.4 at 200, 17.6 along x at 800. Tier 3
  chases (god 25.6): 200 caught in 7 s; 800 with a 1.03 lamb escaped in 29 s, god 39 studs behind; 3,200 in 15 s at
  50.7. At 1e9: 126 on the plots (7x cap), 245 uphill on tiers 1-2, slides of 200-260 on the floor.
- **Steal a dropped lamb from the MCP**: walk within 10 studs and stop first (at high Climbing the walk overshoots),
  then `prompt:InputHoldBegin()`, wait past HoldSeconds, `InputHoldEnd()`. Do it inside DropSeconds (30): a slow test
  script finds the lamb already back in its pasture.
- **Economy simulation**: an efficient player model (walker, pens, trails, trips timed from `Mountain.SpeedAt` and
  `Economy.EscapeSpeed`) lived in a throwaway script; its results are in HISTORY.md (Climbing). Rebuild it from
  Economy and Olympus if the economy changes.

## Merge Shrine playtest (2026-10-05)

- **Getting the character to the shrine**: `Humanoid:MoveTo` does nothing now (MovementController moves the humanoid
  every frame), and a jump uphill is pulled back by MountainService's climb ceiling (the shrine at x 287 is uphill of
  the plots). Step it there from a Client call: `PivotTo` 3 studs at a time every 0.35 s. A new character can spawn
  snapped onto the StairMaster: fire `Remotes.LeaveWalker` first.
- **A merge without the menu**: `Remotes.Merge:Invoke({ id1, id2, id3 })` from the client within 34 studs of the shrine
  (4 a second at most); the lamb lands after `GameConfig.Shrine.MergeSeconds`, then `Remotes.ShrineCollect:Fire()`
  within 18 studs of the altar picks it up, and `Remotes.PutDown:Fire()` inside the plot delivers it.
- **The flock from a Client call**: `Remotes.GetState:Invoke()` (a fresh `require` of StateController is empty).
- **Three grown sheep**: `Debug GiveSheep` three times, then `GrowAll` (only sheep in the pen grow).
- **Recording**: start `ffmpeg -f gdigrab` a second before the click (it takes about 1.5 s to start); the game view of
  a maximized Studio is at 6,166, 1732 x 792 on this PC.

## Sheep looks and the Sheepdex mock-up (2026-10-05)

- **Opening a menu without the mouse**: a `require` from `execute_luau` gets its own copy of UIController, so put a
  TEMP_ LocalScript in StarterPlayerScripts in Edit that requires `Controllers.UIController` (the game's copy) and
  calls `:Open(name)` when the LocalPlayer's `TempOpen` attribute changes; set the attribute from a Client
  `execute_luau`. Delete the script afterwards. Used for the Sheepdex because desktop clicks are unsafe while other
  sessions' Studios take the foreground.
- **Claims from a script**: `Remotes.ClaimDex:Invoke(family)` returns `callOk, success, message`.

- **Rendering looks without a playtest**: `studio/SheepIndexMockup.luau` builds a TEMP_ ScreenGui in Edit from the
  game's UI kit, with sheep dressed by SheepService's Looks and Extras in ViewportFrames. ServerStorage attributes pick
  the view: `MockView` = `Index` (the menu; `MockTier`/`MockSlot` the picked sheep), `Lineup`, `Herds` (`MockPage` 1-6,
  five gods a page) or `Catalog` (every build, style, horn and accessory; `MockCatalog` = `Extras` for the extras).
  To use the branch's GameConfig, Herds and Extras rather than the place's, wrap them with the script as ModuleScripts
  in one Folder in an .rbxmx under Studio's `content\sas_mock\` (a new file name each time), then in Edit
  `require(game:GetObjects("rbxasset://sas_mock/<file>")[1].SheepIndexMockup)`.
- **Builds that keep their own colours**: Galaxy, Scarecrow, Slime, Ocean, Doodle, BiblicallyAccurate and the
  Cotton Candy's second colour barely take WoolColor (their pieces are tinted "Own"); recolour plain wool styles instead.
- **Glow**: Neon wool in a pale colour renders almost white; saturated ones (255, 90, 0) keep their colour.
- **Where accessories show**: a sheep turned -35 degrees for a picture faces the camera with its -X side; the wool
  reaches about 1.5 studs out from the body, so anything on a flank (the shield) sits at x -1.6 or it's hidden.

## Overnight publish prep (2026-10-05)

- **Own place copy**: `build/Overnight.rbxl` from `lune run tools/assemble.luau` (the map, the assets, `build/game.rbxl`),
  code swapped in from `content/overnight/sync<time>.rbxm` (a new name each build, older ones deleted) by an Edit
  `execute_luau` that moves each child of the built folders over its namesake. That Studio opened in the Device
  Simulator's Galaxy A06 (705 x 338 drawn), so prompts showed their touch look.
- **Remotes answer `callOk` first**: `Remotes.Debug:Invoke("Steal", 1)` returns `true, false, "no ready lamb..."` when
  the steal itself is refused. Read the second value.
- **The game's prompts are billboards** (`PlayerGui.PromptUI`, PromptController/Look): `screen_capture` leaves them out.
  Shoot them with the desktop tools' `screenshot` of a screen region (the phone's screen in the simulator was
  x 140, y 249, 1445 x 652 on this PC with Studio maximized). Trigger one with `prompt:InputHoldBegin()` and
  `InputHoldEnd()`, as its button does.
- **Getting around**: a client `PivotTo` far across the map is put back by MountainService's ground-speed check. Use
  `Debug Steal` / `Debug Home`, or step 2.5 studs every 0.2 s (the walker's entry snaps a player on if the path
  crosses it; the sign's board is the `UpgradeSign.Board` part, not `SignAnchor`, which is the plot's name sign).
- **A held camera pins**: after a call that bound a Scriptable camera, release it with
  `task.delay(0.6, function() camera.CameraType = Enum.CameraType.Custom ... end)` from a call that returns at once;
  until then no prompt shows.
- **One monitor, several Studios**: `screen_capture` and the desktop screenshots need the Studio window in front;
  `start_stop_play` brings its window forward. Sessions took turns (a "screen free" message), running logic-only
  checks while another session's window was in front.

## Momentum slides (2026-10-06)

- **Own place copy**: `scripts/build-place.ps1` in the worktree (it builds the branch's code into `StealASheep.rbxl`),
  copied to `build/MomentumPlaytest.rbxl` and opened with `RobloxStudioBeta.exe <path>`: no code swap needed.
- **A chase log**: a Client `execute_luau` that sets Climbing (`Debug AddClimb` by the difference to the wanted value),
  `Debug Steal`s, drives the slide (Drive a slide, above) and logs every 0.15-0.5 s into `_G` from a `task.spawn`;
  a second call waits and returns the log. The gods' models (`workspace.Gods`) carry `Tier`, `Speed` and `Mood`
  attributes. Velocities read flat (x, z): on a 40-degree stretch a 40.9 slide reads 31.3.
- **Put the last lamb down first**: `Debug Home` keeps a carried lamb on the head, and `Debug Steal` then answers
  `true, nil` without stealing (no chase). `Remotes.PutDown:Fire()` after `Home` delivers it.
- **No straight lane through the map's middle**: from x 2300 down every z from 145 to 240 meets a part or mesh within
  about 400 studs (raycast scan along the floor at 2.5 and 5 studs up); tier 3 down is clear at z 185.

## Mystery lambs (2026-10-06)

- **Lamb looks without playing**: `studio/LambMockup.luau` (wrapped as a ModuleScript in an .rbxmx under Studio's
  `content\sas_mock\`, then `require(game:GetObjects(...)[1])` in Edit) builds lambs and adults as TEMP_ models in Pan's
  pasture: `Shots.Herd(god, x, adults?, pattern?, style?)`, `Styles`, `Weights`, `Cards`, `Growing` (in a plot's pen)
  and `One`. Its marking styles (Bold, Spots, Details, Count, Grow) were the mock-ups; the game's is Count (D), in
  `Utils/LambLook`. Cards over sheep are drawn on camera-facing SurfaceGuis there, since captures leave billboards out.
- **Staging the branch in the shared cloud Studio**: `rojo build tools/sync.project.json` into `content\sas\` under a
  name of its own, then in Edit move each same-named child of ReplicatedStorage, ServerScriptService and
  StarterPlayerScripts (and `ServerStorage.Tests`) into `ServerStorage.TEMP_MainScripts` and parent the new ones; to
  update, destroy the staged ones and parent the rebuilt ones (the backup stays); afterwards put the backup back.
- **The lamb flow in one call**: `Debug Steal` 1, `Debug Home`, step 8 studs in, `Remotes.PutDown:Fire()`; then
  `Debug GrowAll` with a `Remotes.Reveal` listener to see the grow-up. `Debug GiveSheep 30.6` gives a Zeus Mythic lamb
  that takes 8 minutes to grow (a tier 1 lamb grows up while you rejoin).
- **Opening menus**: a TEMP_ LocalScript in StarterPlayerScripts that calls `UIController:Open(name)` when the
  LocalPlayer's `TempOpen` attribute changes (Sheep looks, above). Cards on a Galaxy A06 need the 47 px x offset
  (Robux store, above): aim at `AbsolutePosition + AbsoluteSize / 2 + (47, 0)`.

## Asset audit (2026-10-05, before launch)

Every asset the game uses loads: 1,286 distinct ids, none broken, moderated, deleted or slow.

- **Collect**: `src/` (every `rbxassetid://` outside comments, plus `GodService/Looks.luau`'s catalog ids: 518) and
  the built place (`lune run tools/asset-scan.luau <place.rbxl> <out.json>`: MeshParts, SpecialMeshes, Decals,
  Textures; 779), plus the Sky's six faces (read in Studio: Lune can't read them). The economy API
  (`economy.roblox.com/v2/assets/<id>/details`) gives each one's type: 768 meshes, 328 images, 70 sounds, 7
  animations, 119 catalog items (accessories, clothing, two dynamic heads); none errored (not deleted).
- **Public thumbnails** (`thumbnails.roblox.com/v1/assets`, 100 a batch): all 1,286 Completed. Not proof alone: the
  same APIs said Completed for two meshes Roblox's moderation had removed.
- **Loading, in a playtest of a Studio copy of main**: images as Decals in `ContentProvider:PreloadAsync` (all 328
  Success, fetch status Success, 1.3 s); meshes by `AssetService:CreateMeshPartAsync` on the server, 12 at a time (all
  768, none over 4 s); sounds as Sounds preloaded on the client, then `IsLoaded` and `TimeLength > 0` (all 70, 0.7 s);
  animations through the character's Animator, `Length > 0` (all 7); catalog items through the gods themselves (all 30
  avatars have every accessory, shirt, pants and head their `Looks` lists, from `GetAppliedDescription`).
- **Don't preload ids as strings**: `PreloadAsync({"rbxassetid://..."})` reported Failure for every mesh and most
  images that load fine as Decals or MeshParts; give it instances.
- Not covered: a live server (Studio fetches the same CDN, so it should match), pictures uploaded after this audit.
- **A local copy acting as the published place**: in Edit, `game:SetPlaceId(114389615931493)` and
  `game:SetUniverseId(10769564664)` make a local `.rbxl`'s playtests use the universe's Studio DataStores ("data will be
  saved") and its products for test purchases, with no change to the cloud place. Its MCP name then reads like the
  cloud place's: address it by id only. Server & Clients test players (`Player1` -1, `Player2` -2) save under
  `Player_-1` / `Player_-2` in `PlayerData_Studio`, away from the owner's own Studio save.
- **Server & Clients from the desktop**: Test menu > Start Test Session > Server and Clients starts at once with the
  toolbar's client count (it was 0: only a server). End Session from the same menu, set the count with the arrows
  beside the person icon, then the blue Play. The windows show up in `list_roblox_studios` with no name: the server's
  `execute_luau` takes `Server`, each client's `Client` (find which by `LocalPlayer.Name`), and clients call
  `ReplicatedStorage.NetRemotes.<Name>:InvokeServer` (they can't `require` Remotes).
