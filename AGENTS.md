# Roblox game: agent instructions

This game is built on the RobloxPack base. Code lives on disk and Rojo syncs it into Studio. `BRAIN/` is a small
shared reference library copied into every game; `DESIGN/` belongs to this game. Explicit user instructions
override anything here.

## Start of every task

1. Make sure you aren't behind: `git log --oneline HEAD..main` (in a worktree or on a branch). If it lists commits
   and your tree is clean, `git merge --ff-only main`. New worktrees have started 20 commits behind.
2. Read `DESIGN/CURRENT_STATE.md`, a short index of the game as it is now that points to the rest of `DESIGN/`. If
   the task touches gameplay, skim `DESIGN/GAME_DESIGN.md`.
3. Open the BRAIN file that matches the task. Read only what applies.

| Task | Read |
| --- | --- |
| New service or controller, splitting a system, startup order | `BRAIN/PATTERNS/systems.md` |
| Anything the client sends or receives | `BRAIN/PATTERNS/networking.md` |
| Saved player data, new fields, migrations | `BRAIN/PATTERNS/data.md` |
| Developer products, passes, paid random items | `BRAIN/PATTERNS/purchases.md` |
| Screens, HUD, menus | `BRAIN/PATTERNS/ui.md` |
| Behaviour on tagged instances (doors, pickups, hazards) | `BRAIN/PATTERNS/components.md` |
| Moving characters, spawns, respawns, tools and weapons, melee hits, input on every device | `BRAIN/PATTERNS/characters.md` |
| NPCs, enemies, pets, pathfinding | `BRAIN/PATTERNS/npcs.md` |
| Custom rigs, Motor6D joints, Animation Editor animations, animating many models | `BRAIN/PATTERNS/animations.md` |
| Global leaderboards, top-N boards | `BRAIN/PATTERNS/leaderboards.md` |
| Tests, playtesting, Studio MCP | `BRAIN/PATTERNS/testing.md` |
| Phones (Device Simulator), several players, clicks and prompts from the MCP, screenshots and the camera, performance, test purchases, running `studio/` build scripts | `BRAIN/PATTERNS/testing-studio.md` |
| Anything outside the game window: Studio's own menus and dialogs (saving the place, publishing animations, Import 3D, Server & Clients tests, Buy in a test purchase), Creator Hub in the browser (store items, place settings) | `BRAIN/PATTERNS/desktop.md`, then the job's steps in `BRAIN/PATTERNS/desktop-recipes.md` |
| Several agent sessions on one computer: worktrees, sharing Studio, handing over, after a crash | `BRAIN/PATTERNS/sessions.md` |
| Publishing, what's live, the release order, badges, the maturity questionnaire, a private test place | `BRAIN/PATTERNS/publishing.md` |
| A trailer or gameplay video: filming shots in Studio, OBS, cutting with ffmpeg, game-page video rules | `BRAIN/PATTERNS/trailers.md` |
| Physics, characters, camera, teleports between places, groups, badges, marketplace, UI tweens | `BRAIN/DEPRECATIONS.md` |
| Any Roblox feature you have not used in this repo | `BRAIN/GOTCHAS.md` |

## Always

- `--!strict` at the top of every Luau file.
- Run `./scripts/check.ps1` after every change (formats, type-checks, lints, builds). Fix everything it reports
  and rerun until it prints `check passed`. A `DeprecatedApi` lint means: use the replacement it names.
- The server decides; the client asks. Validate and rate-limit everything a client sends (Net does both).
  Never trust client-reported positions, damage, prices, cooldowns or ownership.
- Server-only rules, data and secrets live in `src/server`. Everything in `src/shared` is readable by exploiters.
- Requiring a module has no side effects (no connections, instances, yields), except `src/shared/Remotes.luau`.
  Plain objects such as `RaycastParams.new()` or `Trove.new()` are fine.
- Lifecycle hooks can't yield, and data and screens aren't ready during `Start`. Do per-player work in
  `DataService:ObserveLoaded`, and waiting work in `task.spawn` or event handlers.
- Comments explain *why*, not *what*. No commented-out code.
- Never edit generated files: `Packages/`, `ServerPackages/`, `build/`, `sourcemap.json`, `globalTypes.d.luau`.
- Ask the user before: adding a package, changing saved data in a way that can't be migrated, anything involving
  Robux, or deleting anything a player owns.
- Everything else is your call, including design decisions `DESIGN/GAME_DESIGN.md` doesn't cover: choose what
  best fits the design's intent and keep going. List the calls players would notice (rules, timings, ranges,
  speeds, rewards, what the UI shows, when things end early) under *To review* in `DESIGN/DECISIONS.md`.
  Technical choices players can't tell apart (tick rates, collision groups) don't need listing.

## Layout

| Disk | Studio | Holds |
| --- | --- | --- |
| `src/server` | `ServerScriptService` | `Bootstrap`, `Registry`, `Services/`, `Data/`, `Components/` (create when needed) |
| `src/client` | `StarterPlayer.StarterPlayerScripts` | `Bootstrap`, `Registry`, `Controllers/`, `Components/` |
| `src/shared` | `ReplicatedStorage` | `Lifecycle`, `Net/`, `Remotes`, `Binder`, `Config/`, `Utils/` |
| `tests` | `ServerStorage.Tests` | `Run` and `*.spec` modules |
| `studio` | (not synced) | Scripts that build Studio-side content, run with `execute_luau` in Edit (create when needed) |
| `Packages`, `ServerPackages` | `ReplicatedStorage.Packages`, `ServerScriptService.ServerPackages` | Wally output |

- Rojo owns the folders above. Maps, models, lighting and UI are built in Studio and saved in the place file,
  not on disk. Build them with `execute_luau` scripts in Edit that destroy and rebuild what they make, so a
  change is one rerun, and keep those scripts in `studio/` so the next agent can rerun them. After
  Studio-side changes, save the place yourself if the desktop tools are connected
  (`BRAIN/PATTERNS/desktop-recipes.md`); otherwise remind the user to save it.
- Tunable numbers go in `src/shared/Config` as frozen tables, or in a server module if clients mustn't see them.
  Give config tables an explicit type (e.g. `{ [string]: Item }`), or strict mode can't index them in loops.
- Helpers used by one system stay in that system's folder. Helpers shared by several go in `src/shared/Utils`
  (or `src/server/Utils` if server-only), one module each.

## Naming

| Thing | Style | Example |
| --- | --- | --- |
| Files, modules, types, services, controllers | PascalCase; file name = what it returns | `ShopService.luau`, `PlayerData.Data` |
| Public functions, methods, fields, signals, attributes, tags, remotes | PascalCase | `DataService:GetData`, `PlayerLoaded`, `SpinSpeed` |
| Constructors | `.new` | `RateLimit.new(5, 1)` |
| Locals, local functions, private module state | camelCase | `local openScreens`, `local function refresh()` |
| Module constants | UPPER_SNAKE_CASE | `local MAX_RECEIPTS = 50` |
| Unused parameters | `_` prefix | `_self`, `_player` |

Name things for what they are (`Catalog`, not `ShopHelper`). Booleans read as questions (`isOpen`, `StartsOpen`).

## Packages

`Signal` (events between systems), `Trove` (cleanup), `ProfileStore` (server; used only by `DataService`).
Everything else is in-house: `Lifecycle`, `Net` + `Guard`, `Binder`, `RateLimit`. Don't add packages that
duplicate these (Knit, Comm, Net libraries, Janitor, Component) without the user's agreement.

## Looking things up

- Roblox Studio MCP connected: use its `http_get` tool on official pages, such as
  `https://create.roblox.com/docs/reference/engine/classes/<ClassName>`.
- Not connected: fetch the same URLs directly.
- The type checker decides whether an API exists and what it takes. If it disagrees with your memory, it wins.
  If it rejects an API that the official docs clearly document, the pinned type definitions are behind: tell
  the user (fix: `rokit update luau-lsp`, then `./scripts/install.ps1`). Don't work around it with `:: any`.
- Your memory of Roblox is out of date. Methods keep gaining `Async` versions and whole services get
  deprecated (e.g. `PhysicsService` collision groups moved to `WorldRoot`). Check `BRAIN/DEPRECATIONS.md` first.
- For design and economy questions (retention, pricing, progression, what top games do), read Tizzy's Roblox
  playbook: `TizzyAi\kb_human` on the Desktop (`topics/*.md`, `glossary.md`; `C:\Users\markf\OneDrive\Desktop`
  on one PC, `C:\Users\Mark\Desktop` on the other), a clone of `markd4nk/TizzyAi`. It's readable without a prompt.
  Cite its videos by number (#NN), and don't copy it into the game.

## Working with Mark

- Show new art or a new look as a mock-up (a render, or a `TEMP_` model screenshotted and deleted) and wait for his
  OK before building it. Offer a variant when unsure. Picking an option isn't an OK.
- Keep UI text short: a name and one short line. No long descriptions or reward maths on screen.
- End a task's open choices as 2-4 short questions, each with your recommended pick and one line on what it
  changes. Ask for open feedback ("is it OK, or what should change?") in plain text, not as a form option.
- To show an image in chat, copy it into `.t3/userdata/attachments/` in the user's home folder and give its full
  path with forward slashes (`C:/Users/<name>/.t3/userdata/attachments/shot.png`); other paths don't render in T3
  Code.
- When publishing, list every change that went out since the last live version, not only your task's
  (`BRAIN/PATTERNS/publishing.md`).

## Done means

1. `./scripts/check.ps1` passes.
2. If the Roblox Studio MCP is connected: playtest, confirm both bootstraps set `Ready = true`, run the tests,
   read the console for errors and warnings from our code, and screenshot any UI you touched
   (`BRAIN/PATTERNS/testing.md`). Stop the playtest.
3. Update `DESIGN/`, newest state only:
   - `CURRENT_STATE.md`: what's live, in progress, not verified and known issues, one line each. 300 lines at
     most (`check.ps1` fails past it); details go in the files below.
   - `HISTORY.md`: an entry at the top for what you built: how it works, the user's calls, how you checked it.
   - `DECISIONS.md`: the calls players would notice, under *To review*.
   - `STUDIO_CONTENT.md`: the Studio-side instances the code expects (names, tags, key properties) and what the
     place holds now, since the place file isn't on disk.

   Know-how about this game alone (its test tools, its measurements) goes in `DESIGN/` too, never in `BRAIN/`.
4. Tell the user what you verified and what you couldn't (for example: "not playtested, Studio MCP not
   connected").

## The brain

`BRAIN/` is shared knowledge, the same in every game and in RobloxPack (the base this game was copied from). So are
this file, `CLAUDE.md` and the scripts `check.ps1`, `install.ps1` and `brain-sync.ps1`. Don't edit them during normal
work, and don't log routine fixes or decisions there; those go in `DESIGN/`.

- When you learn something reusable and non-obvious (a Roblox behaviour that surprised you, a trap that cost time),
  add it to `DESIGN/BRAIN_PROPOSALS.md`: the lesson as it would read in the BRAIN, the file it belongs in, and how
  and when you saw it. Then tell the user. Write it there, not only in your memory: other sessions and the other
  Claude account can't read your memory.
- Edit the shared files only for proposals the user approves. Then add a line to `BRAIN/CHANGELOG.md`, mark the
  proposal done, commit, and run `./scripts/brain-sync.ps1 -ToPack -Message "BRAIN: ..."`: it copies the shared
  files into RobloxPack, commits and pushes it.
- `check.ps1` says when the shared files differ from RobloxPack's. `./scripts/brain-sync.ps1` lists which and who
  changed them last; `-FromPack` brings in what other games added (`BRAIN/CHANGELOG.md` says what).
