# Current state

The game as it is now. Agents read this at the start of every task and update it at the end. Newest state, not a
history: one line per item, details in the files below. Keep it under 300 lines (`check.ps1` fails past it).

| File | Holds | When to read it |
| --- | --- | --- |
| `DESIGN/GAME_DESIGN.md` | The game as it is now (the user refines it as they go: their requests win) | When the task touches gameplay |
| `DESIGN/BASE_DESIGN_DOC.md` | The base design the first build followed: background, not a spec | Why something was built the way it was |
| `DESIGN/HISTORY.md` | Every finished build, newest first: how it works, the user's calls, how it was checked | Search it for the feature you touch |
| `DESIGN/DECISIONS.md` | The user's confirmed rules, and agents' calls waiting for review | Before changing anything players notice |
| `DESIGN/STUDIO_CONTENT.md` | What the code expects in the place file, and what the place holds now | Before Studio-side work or a publish |
| `DESIGN/TESTING.md` | This game's test tools and how it was playtested | Before playtesting |
| `DESIGN/BRAIN_PROPOSALS.md` | Lessons proposed for the shared BRAIN, waiting for the user | When you learn something reusable |

## Live

- Not published. No Roblox place yet: the place is `StealASheep.rbxl`, built by `scripts/build-place.ps1` from the
  map (`vvs_map(commission) (1).rbxl`) with High Olympus built on top (`tools/UpperMountain.luau`), the Shear a Sheep
  assets (`assets/ShearASheepAssets.rbxm`) and the code.

## The game, and where each part lives

The MVP built in one pass on 2026-10-05 (HISTORY.md); the user now refines it as they go (GAME_DESIGN.md). Thirty
tiers, the gods in mythological rank: twelve minor gods up the commissioned map (Pan first, Aeolus on its old summit),
then five more and the thirteen Olympians on High Olympus above it, Zeus at the top.
A god each, four wild lambs each, stair walker training, overhead carrying, the automatic downhill slide with steering,
braking and slide hits, pursuit, delivery, pens, income, growth, size reveal, Equip Best, locks, selling, merging,
trails, pen slots, the Sheepdex, offline earnings and the tutorial lamb.

- **High Olympus** (tiers 13-30): one stretch a god, 275 studs along the floor, 32 rising to 52 degrees, from stage 3's
  floor slab and terraces and the stages' decor, recoloured, plus block props; Zeus's throne plaza on top. Built into
  the place by `tools/UpperMountain.luau` (Lune, in `build-place.ps1`); `tools/preview-upper-mountain.luau` previews it
  in an open Studio. Its layout and `Config/Olympus` (tier x ranges, `Ramp`) must agree: a test checks the chain.

- **Server**: `DataService`, `PurchaseService` (pack, no products), `SheepService`, `PlotService`, `FlockService`,
  `GodService`, `WildService`, `MountainService`, `TrainingService`, `ShopService`, `DebugService` (Studio only).
- **Client**: `StateController`, `SoundController`, `UIController` (Hud, Flock, Shop, Sheepdex, Merge, Popup, Studio
  DebugPanel), `CarryController`, `MovementController`, `AnimController`, `PromptController`.
- **Shared**: `Config/Olympus` (tiers, gods, ramp profile), `Config/GameConfig` (looks, movement, carry, UI),
  `Utils/Economy` (every formula), `Utils/Mountain` (ramp height, tiers by position, floor checks).
- **From Shear a Sheep**: UIKit, Theme, Style (trimmed), Panel, Buttons, Motion, Scale, the sheep rig, add-ons and
  breed builds, Looks, CarryPose, CarryController, SheepClips, Sounds, the Mutation Machine (as the Merge Shrine).

## In progress

- **Gods in rank order** (branch `t3code/order-olympian-gods`, not merged): `Config/Olympus` reordered, new High
  Olympus stretches for the eleven Olympians who moved up. Main (275-stud stretches) merged in, lanes clear, playtested.
  Waiting for the user's OK on the new stretches before merging.
- **Real god models**: two Zeus mock-ups made with `generate_mesh` (cartoon: asset 84879965895469; heroic:
  133271949323056), each split into head, torso, arms, legs and bolt so they can take the rig's joints. On hold: the
  user got a notice that Roblox removed one generated mesh for breaking its rules. Not identified: on 2026-10-05 all
  28 parts of both models (and every asset in the account's models) still loaded and none was marked deleted.

## Not verified

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **Saving**: the place isn't published, so playtests used ProfileStore's mock store; rejoin, offline credit on a real
  rejoin and session locking are untested (the offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts, HUD buttons and the slide use Roblox's own input.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **Upper tiers by foot**: tiers 7-12 weren't climbed on foot; tiers 13, 29 and 30 were (15 s a stretch, onto Zeus's
  plaza). By the numbers it's about 7.6 minutes from the plots to Zeus (a Humanoid walks its 18 studs/s along the slope).
- **High Olympus theft to delivery**: a tier-30 slide was measured through all eighteen stretches (no hops, Zeus
  falling behind), but no theft from tiers 13-30 was carried home and delivered on foot; gates there weren't walked into.

## Known issues

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them; lanes stay as they are until the user adds obstacles (DECISIONS.md). Every run
  from High Olympus now passes through them: a straight slide from Zeus stuck on stage 6's pavilion (x 1890, mid-lane)
  and was caught. High Olympus's own lane is clear.
- **Long runs at the top**: about 7.6 minutes' climb to Zeus and about 2.5 minutes' slide home; the user keeps it all on
  foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **Plots: 5.** A sixth player is kicked with "server full"; set Maximum Visitor Count to 5 in Creator Hub.
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are Shear a Sheep's uploads (Mark's account).
  They load if this game is published under the same owner.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- The map's four leaderboard boards are decoration; the player list shows Income and Climb.
