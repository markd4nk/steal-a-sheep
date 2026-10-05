# Testing

This game's own test tools and measurements.

## Debug panel (Studio only)

The DEBUG button on the left edge, or `require(ReplicatedStorage.Remotes).Debug:Invoke(command, value)` from a Client
`execute_luau`:

| Command | Value | Does |
| --- | --- | --- |
| `AddCash` | coins (1000) | Coins |
| `AddClimb` | Climb Power (100) | Climb Power, and a fresh snapshot |
| `Steal` | tier | Teleports to that tier's first ready lamb and steals it (needs the tier open) |
| `GiveSheep` | tier | An ordinary lamb of that tier straight into the flock, as if delivered |
| `GrowAll` | - | Every lamb grows up on the next tick (with its reveal) |
| `UnlockAll` | - | Zeus's Heavy target in Climb Power and one delivery from every tier |
| `ResetGift` | - | The free gift can be claimed again (its HUD button comes back) |
| `WipeSave` | - | A new player's save |

Set `ServerStorage`'s `DebugBlankProfile` attribute in Edit for a first-session playtest (pack feature).

The free gift in a playtest: `GiveSheep` 1 counts as the first delivery, and the menu opens by itself 30 s later at the
plot. Claim skips Roblox's favorite prompt while the place is unpublished (PlaceId 0).

UI mock-ups without playing: in Edit, `require` a screen module from `StarterPlayerScripts.UIController.Screens`, call
its `Build(StarterGui)`, name the ScreenGui `TEMP_...`, enable it, fill its labels, and set `Root.Scale.Scale` (1.25),
`Root.Size` (1/scale) and each `UITextSizeConstraint` from its `MaxPoints`/`MinPoints` attributes times the scale, as
`UIController/Scale` does in play. Delete the `TEMP_` guis after.

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
