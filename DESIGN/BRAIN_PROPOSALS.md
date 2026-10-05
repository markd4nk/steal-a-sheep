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

- **S9** (`BRAIN/PATTERNS/purchases.md`, or a new "Free rewards" note): "A reward for favoriting: open Roblox's own
  prompt with `AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)` on the client
  and wait for `PromptSetFavoriteCompleted` = `Success`; the server can't see favorites, so it takes the claim on trust
  and allows one per player. No API shows whether a player liked (voted on) the game, and Roblox's Community Rules
  forbid prizes 'in exchange for a thumb up on your game': ask for likes without tying the reward to them. In an
  unpublished place PlaceId is 0 and there's nothing to favorite." Seen 2026-10-05 building Steal a Sheep's free gift
  (docs and DevForum; the live prompt itself not yet tried).

## Done

- None yet.
