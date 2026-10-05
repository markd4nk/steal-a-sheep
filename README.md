# Steal a Sheep

Climb Olympus, steal a god's lamb, hold it over your head and slide home with the god behind you. The design is
[`Steal-a-Sheep-Game-Design-Document-Draft.md`](Steal-a-Sheep-Game-Design-Document-Draft.md); what's built and what
isn't is in [`DESIGN/CURRENT_STATE.md`](DESIGN/CURRENT_STATE.md). Built on RobloxPack (below) with Shear a Sheep's UI
kit, sheep and sounds.

## Play it

1. `./scripts/install.ps1` once (it also installs Lune, used to build the place).
2. `./scripts/build-place.ps1`: builds `StealASheep.rbxl` from the commissioned map, `assets/ShearASheepAssets.rbxm`
   and the code.
3. Open `StealASheep.rbxl` in Studio and press Play. While working on code, `rojo serve` into it instead of
   rebuilding. Studio-only test tools are on the DEBUG button (`DESIGN/TESTING.md`).

The map stays as delivered in `vvs_map(commission) (1).rbxl`; Shear a Sheep's place-side pieces (sheep rig, add-ons,
the Mutation Machine) were copied once by `tools/extract-assets.luau`.

# RobloxPack

A base folder for every new Roblox game, built for AI agents (Claude Code, Codex) to work in:

- **Code skeleton**: Rojo + Wally, strict Luau, systems with enforced startup rules, validated and rate-limited
  networking, crash-safe player data and purchases, a UI controller, and tag-driven components.
- **One check command**: `scripts/check.ps1` formats, type-checks, lints (including deprecated Roblox APIs) and
  builds.
- **BRAIN/**: a small shared reference of patterns, deprecations and platform gotchas, sourced from official docs.
- **DESIGN/**: this game's design notes and current state, kept up to date by agents.

Agents start at [AGENTS.md](AGENTS.md). Claude Code loads it through [CLAUDE.md](CLAUDE.md).

## Start a new game

1. Copy this whole folder to a new location and rename it, then delete the copy's `.git` folder so the game
   starts its own history. Generated files come along; the install rebuilds them.
2. Install [Rokit](https://github.com/rojo-rbx/rokit) once per machine.
3. Set `Name` in `src/shared/Config/GameConfig.luau`, and `name` in `default.project.json` and `wally.toml`.
   Do this before installing, so `wally.lock` gets the new name.
4. In the game folder: `./scripts/install.ps1`, then `./scripts/check.ps1`. The first Rokit run may ask you to
   trust each tool.
5. Open Roblox Studio with a new or existing place, run `rojo serve`, and connect with the Rojo plugin. Give
   each game its own place: code synced from another project can survive in it.
6. Publish the place, then turn on **File > Experience Settings > Security > Enable Studio Access to API
   Services** so data saves in playtests (Studio uses its own `PlayerData_Studio` store).
7. Connect the Roblox Studio MCP so agents can playtest, screenshot and build UI: in Studio, **Assistant >
   Manage MCP Servers > Enable Studio as MCP server**. Claude Code picks the server up from `.mcp.json`
   (Windows); approve it the first time you start Claude Code in the folder
   (https://create.roblox.com/docs/studio/mcp).
8. Optional, once per machine: the `windows-computer-use` MCP, so agents can work outside the game window: Studio's
   own menus and dialogs (saving the place, Import 3D, Server & Clients tests, test purchase dialogs) and Creator Hub
   in the browser (store items, place settings). Agents use it whenever it's the best way, without asking first
   (`BRAIN/PATTERNS/desktop.md`).
   In PowerShell:
   ```powershell
   py -3 -m venv "$env:LOCALAPPDATA\wcu-venv"
   & "$env:LOCALAPPDATA\wcu-venv\Scripts\pip.exe" install "git+https://github.com/sshh12/windows-computer-use-mcp@8d367a868f49150c9dcc8ea4d70b6efe8ad8a892" "mcp>=1.2,<2"
   claude mcp add --scope user windows-computer-use -- "$env:LOCALAPPDATA\wcu-venv\Scripts\python.exe" -m windows_computer_use
   ```
   Then in Claude Code, `/permissions`, saved to User settings: allow `mcp__windows-computer-use`. It drives the
   real mouse and keyboard; agents say in one line what they're about to do, then do it. The install is pinned to a commit that was read before use, and to `mcp` 1.x because 2.x breaks it.
   Don't install it through its Claude Code plugin, which updates itself from GitHub on every start.
9. Fill in `DESIGN/GAME_DESIGN.md`.
10. `git init` and commit.

Press Play: the output should show `[Game] Server ready` and `[Game] Client ready`. In Studio a DEBUG button sits on
the left edge: the debug panel (cash, wipe save, grant a product or pass), and `ServerStorage.DebugBlankProfile` gives a
blank save that's never written (`BRAIN/PATTERNS/testing.md`).

Optional kits, off until a game wants them: `trailer/` with `TrailerController` (filming a trailer,
`BRAIN/PATTERNS/trailers.md`) and `scripts/stage_branch.py` (a branch's scripts into a shared Studio place and back,
without Rojo; `BRAIN/PATTERNS/sessions.md`).

## Keeping it current

- Tools: `rokit update`, then `./scripts/install.ps1`. Updating `luau-lsp` also refreshes the Roblox type
  definitions, which is how new APIs and new deprecations reach the check.
- Packages: edit `wally.toml`, then `./scripts/install.ps1`. Commit `wally.lock`.
- Brain: `BRAIN/`, `AGENTS.md`, `CLAUDE.md` and the scripts `check.ps1`, `install.ps1` and `brain-sync.ps1` are the
  same in every game and here. Agents write lessons into the game's `DESIGN/BRAIN_PROPOSALS.md`; once the user
  approves them, `./scripts/brain-sync.ps1 -ToPack` copies them here, commits and pushes. A game catches up with
  `./scripts/brain-sync.ps1 -FromPack` (`BRAIN/CHANGELOG.md` says what changed), and `check.ps1` says when its copies
  differ. Agents only edit these files when the user approves.

## Credits

The architecture (lifecycle registry, services/controllers, screen contract, receipt-safe purchases) is inspired
by [frrazer/roblox-game-boilerplate](https://github.com/frrazer/roblox-game-boilerplate). All code and text
here is written independently. Uses [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore),
[Signal](https://github.com/Sleitnick/RbxUtil) and [Trove](https://github.com/Sleitnick/RbxUtil). Deprecation
data comes from [Roblox/creator-docs](https://github.com/Roblox/creator-docs) (CC BY 4.0).
