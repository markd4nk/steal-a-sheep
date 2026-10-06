# Game page art (icon and thumbnails)

Mock-ups for the user to pick from: rendered in a Studio copy of the place, composed with Python (Pillow).
Nothing here uploads anything.

- `tiles.py`: renders bigger than Studio's viewport. `plan` splits one virtual camera (position, target, vertical
  FOV, output size) into overlapping tiles, each the same camera turned a little in its own frame, and prints each
  tile's CFrame and FOV for `execute_luau`. Capture each tile with `screen_capture` (no camera arguments; pin the
  camera every frame with `BindToRenderStep`, or the game's camera script takes it back), then `stitch` maps them
  back onto the virtual image exactly (a pure rotation, no parallax) and reports any uncovered pixels.
- `compose.py`: the title ("STEAL A / SHEEP" in FredokaOne from Studio's own fonts, gold or white with the game's
  thick black edge, a soft shine and shadow), captions, a light vignette, final sizes and contact sheets.
- Scenes (2026-10-05): copies of the avatar gods and of the player's character, posed on the client with
  Roblox's run, idle and sit clips frozen at a chosen point and joint `Transform`s held in `PreSimulation` (the copy's
  BallSocketConstraints off so arms go straight up); live gods, wild and pen sheep, billboards and menus hidden on that
  device with `LocalTransparencyModifier`; still sheep from `ReplicatedStorage.SheepLooks`. The thief wears Roblox's
  "Shocked" head (131227297250373).

Outputs: `C:/Users/<name>/.t3/userdata/attachments/gamepage_*.png` (icons 512 x 512, thumbnails 1920 x 1080, contact
sheets). Working files go in `work/`, which git ignores.

## Gameplay thumbnails (2026-10-06)

`gameplay_thumbs.py` turns five Studio captures of a real playtest into `gamepage_play_*.png` (titled and `_clean`):
Pan diving at the thief in the meadow, Zeus diving with his bolt, Pan glaring behind a grinning thief, Tyche
belly-gliding after the surfing thief with the snow and lava stages behind, and a full pen in front of the mountain.
Each frame is the viewport (1914 x 960 with Studio's panels closed and Full Screen on) cropped to 16:9 and scaled up
1.125x. The frames themselves were in `work/gameplay/`.

How they were staged, in a place copy (`build-place.ps1`'s steps into `build/`, main's code), `DebugBlankProfile` on:

- **The thief**: the test account's own avatar is a licensed cartoon character, so the server gave it a classic noob
  (yellow, blue, green) with the "Shocked" head through a `HumanoidDescription` (`ApplyDescriptionAsync`). Its
  expression is set each frame after everything else on the head's `FaceControls` (`JawDrop`, `LipStretcher`, brows
  and lids for shock; `LipCornerPuller` and `CheekRaiser` for the grin).
- **A real theft**: `Debug Steal` (tier) with Climbing from `WipeSave` + `AddClimb` (the god only chases a thief it
  can catch). A client RenderStep then pins the character at a spot (the floor from `Mountain.Floor`, not a ray from
  above: arches and tree tops catch those) and keeps `Humanoid:Move` downhill so the slide (and the surf pose) stays on.
  Below the safety line the slide stops, for standing shots.
- **The god**: placed on that client beside the thief each frame (`PivotTo`, the model's hip height over the floor),
  with its `Mood` attribute set on the client (Alert points, Idle stands), and posed with the game's own clips:
  `BodyClips.Sample("Lunge", 0.4)` is the face-first dive, `"Belly"` the glide (Measure, Ground, Apply in
  PreSimulation, Restore in PostSimulation, as `GodController` does). The server's god stays at home.
- **Clutter off on that client**: every BillboardGui (names, labels), the tier signs, the leaderboards, the HUD,
  `ChaseScreen` and Lighting's `ChaseGrade` (the chase's red edges and drained colour), `ChaseShake`, CoreGui and
  ProximityPrompts.
- **The pen**: 16 grown sheep (`GiveSheep` tier.slot, `GrowAll`, 8 Pen Space bought with debug cash), each pinned on
  that client facing the camera; the thief carrying a fresh lamb in the middle.
- **Camera**: `TrailerRig` `Play` with a long `Seconds`, `Follow = "Character"` and a world `Offset`, then
  `screen_capture` with no camera arguments.
- `RunService:Pause()` from a Server `execute_luau` freezes the server (the gods stop where they are), but the
  client still simulates its own character; placing everything on the client each frame turned out simpler.
