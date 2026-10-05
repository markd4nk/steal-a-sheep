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

## Done

- None yet.
