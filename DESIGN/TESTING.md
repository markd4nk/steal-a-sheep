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
| `GiveSheep` | tier, and after the point the herd slot (30.6 = Zeus's Mythic) | A Plain lamb of it straight into the flock, as if delivered |
| `FillDex` | how many of each herd, Common first (6) | Marks them found in the Sheepdex, rewards unclaimed |
| `GrowAll` | - | Every lamb grows up on the next tick (with its reveal) |
| `UnlockAll` | - | Zeus's Heavy target in Climbing and one delivery from every tier |
| `SetWalker` | level (1-30) | The stair walker at that level (its look, step speed and sign) |
| `ResetGift` | - | The free gift can be claimed again (its HUD button comes back) |
| `WipeSave` | - | A new player's save |

Set `ServerStorage`'s `DebugBlankProfile` attribute in Edit for a first-session playtest (pack feature).

The free gift in a playtest: `GiveSheep` 1 counts as the first delivery, and the menu opens by itself 30 s later at the
plot. Claim skips Roblox's favorite prompt while the place is unpublished (PlaceId 0).

UI mock-ups without playing: in Edit, `require` a screen module from `StarterPlayerScripts.UIController.Screens`, call
its `Build(StarterGui)`, name the ScreenGui `TEMP_...`, enable it, fill its labels, and set `Root.Scale.Scale` (1.25),
`Root.Size` (1/scale) and each `UITextSizeConstraint` from its `MaxPoints`/`MinPoints` attributes times the scale, as
`UIController/Scale` does in play. Delete the `TEMP_` guis after.

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
  require(m).Build({ Instance = Instance, CFrame = CFrame, Vector3 = Vector3, Color3 = Color3, Enum = Enum }, workspace);
  m:Destroy()`. It replaces `Stages.HighOlympus` each run.
- **Branch code without Rojo**: `rojo build tools/sync.project.json` (a Folder-rooted copy of the project:
  ReplicatedStorage, ServerScriptService, StarterPlayerScripts, Tests) into `content/sas/sync.rbxm`, then in Edit
  `GetObjects` it and swap each container's children.
- **Lane check**: every collidable part under a stretch's `Decor` in its frame (x across, y up from the floor) must have
  |x| >= 56 or sit 16+ studs up; 0 found.
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

- Slide: tier 1 Light lamb 20.1 studs/s, Stout 17.3; tier 7 Light at full training ~38.8. Gods: 21.1 (Demeter
  chasing a slider), 35.2 (Apollo), 12.6 (Demeter on the tutorial run, walking target).
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
