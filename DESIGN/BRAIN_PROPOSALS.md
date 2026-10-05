# BRAIN proposals

Lessons proposed for the shared files (`BRAIN/`, `AGENTS.md`, the shared scripts), waiting for the user. Each has an
id, where it would go, the text as it would read there, and how and when it was seen. The user approves by id; the
agent then applies the text, adds a line to `BRAIN/CHANGELOG.md`, moves the id to *Done* with the date, and runs
`./scripts/brain-sync.ps1 -ToPack`.

## Waiting

- **S1** (`BRAIN/PATTERNS/characters.md`): "PlayerScripts may have no `PlayerModule`: in Studio 2026-10 the default
  control scripts weren't there, so `require(PlayerModule):GetControls():GetMoveVector()` is gone. Read the player's
  input as `Humanoid.MoveDirection` in a RenderStep bound after `Enum.RenderPriority.Character` (it still holds what
  Roblox's controls asked for this frame), then call `Humanoid:Move` in the same step to override the frame's
  movement." Seen 2026-10-05 building Steal a Sheep's slide: the slide never started until it read MoveDirection.
- **S2** (`BRAIN/PATTERNS/testing-studio.md`): "The Studio MCP server can be driven from a script (StudioMCP.exe in the
  Studio version folder speaks JSON-RPC over stdio: `initialize`, then `tools/call`), which lets a session without the
  MCP configured test in Studio. Always pick the Studio by name from `list_roblox_studios` and refuse any other: several
  Studios can be open. `screen_capture` with `camera_position` leaves Freecam on, which then swallows mouse clicks:
  restart the playtest after it. A minimized Studio window captures UI but no ViewportFrame contents." Seen 2026-10-05.
- **S3** (`BRAIN/GOTCHAS.md`): "Lune 0.10.5 panics ('Cannot clone an instance that does not exist') serializing clones
  of a place's instances with `roblox.serializeModel`; serialize the originals instead (trimmed in memory)." Seen
  2026-10-05 extracting Shear a Sheep's sheep rig.

- **S4** (`BRAIN/PATTERNS/characters.md`): "A Humanoid moves its WalkSpeed along the slope it stands on, so it covers
  WalkSpeed x cos(grade) across the ground (60 on 52 degrees: 37 studs/s of x). Anything a script moves beside it (NPCs
  stepped by AlignPosition or CFrame) must measure its steps along the slope too, or on steep ground it outruns
  players." Seen 2026-10-05 in Steal a Sheep: gods chasing at 0.88 of a slider's speed caught every thief on 52 degrees.
- **S5** (`BRAIN/PATTERNS/characters.md`): "A Humanoid driven fast down a steep slope leaves the floor: sliding at 60
  studs/s down 45-52 degrees it was in the air a third of the time. Each frame after your Move, cap its vertical
  velocity at minus (horizontal speed x slope) unless it's Jumping: it then stays on the floor." Seen 2026-10-05.
- **S6** (`BRAIN/GOTCHAS.md`): "Lune can't read derived properties: `part.Position` errors ('missing default value'),
  use `part.CFrame.Position`; reading `Texture.Texture` fails too (clone an existing Texture rather than make one); a
  Part made in Lune has Studs surfaces, not Studio's Smooth. Clones of a place's instances save fine with
  `serializePlace`." Seen 2026-10-05 building High Olympus in Lune.
- **S7** (`BRAIN/PATTERNS/testing-studio.md`): "`require` of a game ModuleScript from `execute_luau` runs a separate
  copy in the command's context: a service required there never ran Start and holds none of the game's state (a
  `Build` returned nil). To look at what the game made, read or clone its instances, or go through its remotes." Seen
  2026-10-05.
- **S8** (`BRAIN/PATTERNS/sessions.md`, Tools on Windows): "Claude Code's Bash tool fails a heredoc whose body has
  backticks ('unexpected EOF while looking for matching'), even with a quoted delimiter: write such files with the
  Write or Edit tools." Seen twice on 2026-10-05.
- **S9** (`BRAIN/PATTERNS/sessions.md`): "After `git merge`, list what's still conflicted with
  `git diff --name-only --diff-filter=U` before you commit: a merge's output piped through `tail` hides some of its
  CONFLICT lines, and `check.ps1` doesn't look for conflict markers in Markdown, so they get committed." Seen
  2026-10-05 in Steal a Sheep: DECISIONS.md and CURRENT_STATE.md went in with markers after only HISTORY.md was fixed.
  (Could also become a `check.ps1` test: fail on lines starting `<<<<<<<` or `>>>>>>>` in tracked text files.)
- **S10** (`BRAIN/PATTERNS/characters.md`): "Humanoids hold up at high WalkSpeed: 245 studs/s up a 7-12 degree ramp and
  slides of 200-260 down 12-29 degrees stayed on the floor (0 samples below it, 2 of 179 in the air), but anything they
  clip at 150+ stops them dead. Give a fast movement a short rise (here: reach the target in about 2 s) rather than a
  fixed acceleration, or high targets take ten seconds to reach." Seen 2026-10-05 playtesting Steal a Sheep's Climbing.
- **S11** (`BRAIN/PATTERNS/sessions.md`, Studio is shared): "Every Studio window of one Roblox version reads the same
  `content` folder, so a `GetObjects("rbxasset://...")` sync file there is shared between sessions: give yours a name of
  its own (`content/<game>/<task>-sync.rbxm`), or another session's code can end up in your place." Seen 2026-10-05,
  Steal a Sheep: three sessions each had their own Studio open on a place copy, one already using `sync.rbxm`.
- **S12** (`BRAIN/PATTERNS/testing-studio.md`, screenshots and the camera): "A camera set from `execute_luau` on the
  client is put back by Roblox's camera scripts the next frame, and `screen_capture`'s `camera_position` only lasts
  for that capture. To hold a shot (a recording), bind a RenderStep at `Enum.RenderPriority.Last` that sets a
  Scriptable camera every frame; unbind it and set `CameraType` back to Custom after." Seen 2026-10-05 filming
  grazing sheep.
- **S13** (`BRAIN/PATTERNS/desktop.md`): "The desktop tools' `record` saves its mp4 under the session's working
  directory (`windows-computer-use/` in the repo): move it out before committing. With a window target its `region`
  crop was ignored; crop afterwards with ffmpeg (`-vf crop=w:h:x:y`)." Seen 2026-10-05.
- **S14** (`BRAIN/PATTERNS/animations.md`): "A Motor6D `Transform` set from a script moves its parts only at the next
  simulation step: in a test, wait a frame (`task.wait()`) before reading the moved parts' positions." Seen 2026-10-05
  measuring a grazing pose.
- **S15** (`BRAIN/PATTERNS/components.md`): "A tagged model the server makes while players are in the game can reach
  a client in pieces: `CollectionService`'s added signal (and a Binder's) fires for the model before all its
  descendants have arrived. Code that collects a model's parts, joints or decals when its tag appears must also take
  them from `DescendantAdded`, or it keeps a partial set for good." Seen 2026-10-05, Steal a Sheep: lambs put down in
  the pen walked about stiff and never changed face in two takes of five; models made before the player joined were
  never affected.
- **S16** (`BRAIN/PATTERNS/testing-studio.md`): "A picture uploaded through `upload_image` reports
  `AssetFetchStatus.Failure` until Roblox's review clears it (minutes), and a Studio that fetched it before then may go
  on reporting Failure from `PreloadAsync` after it's cleared: check in a freshly opened Studio. In game code, swap in a
  new picture only once it has arrived, or a Decal shows nothing meanwhile." Seen 2026-10-05.

## Done

- None yet.
