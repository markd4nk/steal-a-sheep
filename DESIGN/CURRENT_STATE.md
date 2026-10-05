# Current state

The game as it is now. Agents read this at the start of every task and update it at the end. Newest state, not a
history: one line per item, details in the files below. Keep it under 300 lines (`check.ps1` fails past it).

| File | Holds | When to read it |
| --- | --- | --- |
| `DESIGN/GAME_DESIGN.md` | The game as it is now (the user directs it: their requests win) | When the task touches gameplay |
| `DESIGN/HISTORY.md` | Every finished build, newest first: how it works, the user's calls, how it was checked | Search it for the feature you touch |
| `DESIGN/DECISIONS.md` | The user's confirmed rules, and agents' calls waiting for review | Before changing anything players notice |
| `DESIGN/STUDIO_CONTENT.md` | What the code expects in the place file, and what the place holds now | Before Studio-side work or a publish |
| `DESIGN/TESTING.md` | This game's test tools and how it was playtested | Before playtesting |
| `DESIGN/BRAIN_PROPOSALS.md` | Lessons proposed for the shared BRAIN, waiting for the user | When you learn something reusable |

## Live

- Not published. No Roblox place yet: the place is `StealASheep.rbxl`, built by `scripts/build-place.ps1` from the
  map (`vvs_map(commission) (1).rbxl`), the Shear a Sheep assets (`assets/ShearASheepAssets.rbxm`) and the code.

## The game, and where each part lives

The MVP built in one pass on 2026-10-05 (HISTORY.md); the user now takes it in their own direction (GAME_DESIGN.md): twelve tiers up the commissioned map, a god each,
four wild lambs each, stair walker training, overhead carrying, the automatic downhill slide with steering, braking and
slide hits, pursuit, delivery, pens, income, growth, size reveal, Equip Best, locks, selling, merging, trails, pen slots,
the Sheepdex, offline earnings and the tutorial lamb.

- **Server**: `DataService`, `PurchaseService` (pack, no products), `SheepService`, `PlotService`, `FlockService`,
  `GodService`, `WildService`, `MountainService`, `TrainingService`, `ShopService`, `DebugService` (Studio only).
- **Client**: `StateController`, `SoundController`, `UIController` (Hud, Flock, Shop, Sheepdex, Merge, Popup, Studio
  DebugPanel), `CarryController`, `MovementController`, `AnimController`, `PromptController`.
- **Shared**: `Config/Olympus` (tiers, gods, ramp profile), `Config/GameConfig` (looks, movement, carry, UI),
  `Utils/Economy` (every formula), `Utils/Mountain` (ramp height, tiers by position, floor checks).
- **From Shear a Sheep**: UIKit, Theme, Style (trimmed), Panel, Buttons, Motion, Scale, the sheep rig, add-ons and
  breed builds, Looks, CarryPose, CarryController, SheepClips, Sounds, the Mutation Machine (as the Merge Shrine).

## In progress

- Nothing. Waiting for the user's review of DECISIONS.md's *To review* list.

## Not verified

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **Saving**: the place isn't published, so playtests used ProfileStore's mock store; rejoin, offline credit on a real
  rejoin and session locking are untested (the offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts, HUD buttons and the slide use Roblox's own input.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **Upper tiers by foot**: tiers 7 and up were reached with the debug Unlock; climbing them on foot wasn't timed.

## Known issues

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them. Thinning the decor on the main lanes would make slides smoother (DECISIONS.md).
- **Plots: 5.** A sixth player is kicked with "server full"; set Maximum Visitor Count to 5 in Creator Hub.
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are Shear a Sheep's uploads (Mark's account).
  They load if this game is published under the same owner.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- The map's four leaderboard boards are decoration; the player list shows Income and Climb.
