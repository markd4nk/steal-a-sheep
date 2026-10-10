# BRAIN changelog

What changed in the shared files (`BRAIN/`, `AGENTS.md`, `CLAUDE.md`, `scripts/check.ps1`, `scripts/install.ps1`,
`scripts/brain-sync.ps1`), newest first, and which game it came from. A game that's behind RobloxPack can read what
it's missing here, then run `./scripts/brain-sync.ps1 -FromPack`. Add a line with every approved change.

- **2026-10-10**, from Steal a Sheep (Mark approved S63): `scripts/check.ps1` runs `install.ps1` itself when a
  worktree has no `Packages` or type definitions yet, instead of stopping with "Not installed".
- **2026-10-05**, from the starter code's first Studio test (Mark approved F1): `GOTCHAS.md`, a client script can
  start before its sibling folders are copied into `PlayerScripts`. RobloxPack's client bootstrap waits for them.
- **2026-10-05**, RobloxPack's starter code (Mark approved D1-D4): the debug panel and `DebugService`,
  `DebugBlankProfile`, `DataService:Reset` and `PlayerReleasing`'s reason, Studio pass tools in `PurchaseService`
  (ignore owned passes, `Grant`, `GrantPass`, `Granted`), the screen contract's `Build` for Studio-only tools, the
  trailer kit and `scripts/stage_branch.py`. Documented in `data.md`, `purchases.md`, `testing.md`,
  `testing-studio.md`, `ui.md`, `trailers.md` and `sessions.md`.
- **2026-10-05**, from Shear a Sheep (Mark approved the whole proposals list):
  - `PATTERNS/testing-studio.md`: the camera after an `execute_luau` call (corrected), clicking from the MCP
    (corrected: `instance_path` for buttons, `WorldToScreenPoint` for the world), a second Studio needs the user's
    OK, Server & Clients clients, Rojo's leftovers and restarts, the kick dialog, test teleports, seeing a join,
    client copies, profilers and long snippets, checking that pictures load, long measurements, test purchases,
    the Device Simulator's leftovers, prompts out of view.
  - `PATTERNS/desktop-recipes.md`: starting and ending a Server & Clients test (corrected), Creator Hub icons and
    custom events, the live game from this computer. `PATTERNS/desktop.md`: clicks use the last screenshot's frame,
    prompts that steal the foreground.
  - `GOTCHAS.md`: a server-made model arriving after the remote's answer, textures and see-through parts, licensed
    sounds (new Assets section). `PATTERNS/ui.md`: phone corners, scrolling. `PATTERNS/sessions.md`: tools on Windows.
  - `AGENTS.md`: Working with Mark (mock-ups first, short UI text, few questions, images in T3, the publish
    changelog) and Tizzy's playbook.
- **2026-10-05**, from Shear a Sheep (Mark asked):
  - `DESIGN/CURRENT_STATE.md` is a short index (300 lines at most, enforced by `check.ps1`), with `DESIGN/HISTORY.md`,
    `DECISIONS.md`, `STUDIO_CONTENT.md` and `BRAIN_PROPOSALS.md` beside it. `AGENTS.md` says what goes where.
  - New `PATTERNS/sessions.md` (several sessions at once: worktrees, sharing Studio, handing over, crashes) and
    `PATTERNS/publishing.md` (what's live, the release order, the changelog to report, badge and questionnaire
    limits, a private test experience for phones).
  - `PATTERNS/testing.md` split: the core stays, the situational sections moved to `PATTERNS/testing-studio.md`.
    `PATTERNS/desktop.md` split: the recipes moved to `PATTERNS/desktop-recipes.md`.
  - `scripts/brain-sync.ps1` and this changelog. `check.ps1` also fails on `TEMP-TEST` markers, text files git reads
    as binary (NUL bytes after a crash) and a long `CURRENT_STATE.md`, warns about CRLF, and says when the shared
    files differ from the pack's.
  - `AGENTS.md`: catch up with main at the start of a task; lessons go to `DESIGN/BRAIN_PROPOSALS.md`, not memory;
    the sync steps; game-only know-how goes in `DESIGN/`.
- **2026-10-05**, from Shear a Sheep (approved 2026-10-03): avatar NPC faces, `WorldPivot` and `PrimaryPart`,
  File > Import and its queue, meshes recreated from ids, posing arms by direction, `record` in place, a branch's
  code through `GetObjects`, thin outlines on small text.
- **2026-10-01**, from Shear a Sheep: trailers and gameplay videos; list layouts ignore `Rotation`,
  `BillboardGui.Active`, `screen_capture` skips billboards, two Rojo plugins, running `studio/` build scripts; the
  desktop tools used without asking first; the TizzyAi knowledge base readable without a prompt.
- **2026-09-29**: the desktop tools for Studio's own menus and dialogs, with the Save the place and Publish
  animations recipes.
- **2026-09-28**: phone checks in the Device Simulator, analytics gotchas, rigs and animations, part size limits,
  exact overlap checks, `CollisionFidelity`, imported pivots.
- **2026-09-26**: Studio MCP testing quirks, `Signal` handler order, multi-client testing, prompt triggers,
  constraint NPCs, the idle signal.
- **2026-09-25**: RobloxPack: the base folder and shared brain.
