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
| `GiveSheep` | tier | An ordinary lamb of that tier straight into the flock, as if delivered |
| `GrowAll` | - | Every lamb grows up on the next tick (with its reveal) |
| `UnlockAll` | - | Zeus's Heavy target in Climbing and one delivery from every tier |
| `SetWalker` | level (1-30) | The stair walker at that level (its look, step speed and sign) |
| `WipeSave` | - | A new player's save |

Set `ServerStorage`'s `DebugBlankProfile` attribute in Edit for a first-session playtest (pack feature).

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
