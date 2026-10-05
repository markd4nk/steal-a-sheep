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
tiers: twelve up the commissioned map (Aeolus on its old summit) and eighteen on High Olympus above it, Zeus at the top.
A god each, four wild lambs each, stair walker training, overhead carrying, the automatic downhill slide with steering,
braking and slide hits, pursuit, putting lambs down anywhere in your pen, roaming and grazing sheep, income, growth,
size reveal, Equip Best, locks, selling, merging, trails, pen space, the Sheepdex, offline earnings and the tutorial
lamb.

- **The pen** (branch `t3code/free-roaming-sheep-pens`, 2026-10-05): the whole fenced plot; carry a lamb in and press
  E to put it down where you like (no delivery pad, no pads). Sheep roam round where they were put down
  (`FlockService/Pens`, `Utils/Wander`), avoiding trees, hay and the walker; lambs graze nearly all the time, adults now
  and then (`AnimController`, `Utils/SheepClips`). Homes are saved (`HomeX`/`HomeZ`).

- **High Olympus** (tiers 13-30): one stretch a god, 210 studs along the floor, 32 rising to 52 degrees, from stage 3's
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

- **Eating faces**: two mock-ups shown to the user (A "Munch": eyes shut, cheeks full, a grass sprig in the corner of
  a mouth working side to side; B "Nom": eyes on the grass, mouth opening on a green mouthful). Waiting for a pick;
  then upload both frames and set `GameConfig.Sheep.Faces` + `ChewFaces`. Blink stands in. Drawn by
  `art/faces/chew_faces.py` with Shear a Sheep's `art/sheep/mock_faces.py` helpers.
- **Free-roaming pens are on their branch**, not yet merged into main (the user's call).

## Not verified

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **Saving**: the place isn't published, so playtests used ProfileStore's mock store; rejoin, offline credit on a real
  rejoin and session locking are untested (the offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts (Steal, Put down), HUD buttons and the slide use
  Roblox's own input.
- **Pens with two players**: a lamb put down in someone else's plot is refused ("not your plot"), tried solo by
  teleporting into another plot; homes saved across a real rejoin and on a different plot number are untested.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **Upper tiers by foot**: tiers 7 and up were reached with the debug Unlock; climbing them on foot wasn't timed. By
  the numbers it's about 6.5 minutes from the plots to Zeus (a Humanoid walks its 18 studs/s along the slope).
- **High Olympus theft to delivery**: a tier-30 slide was measured through all eighteen stretches (no hops, Zeus
  falling behind), but no theft from tiers 13-30 was carried home and delivered on foot; gates there weren't walked into.

## Known issues

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them; lanes stay as they are until the user adds obstacles (DECISIONS.md). Every run
  from High Olympus now passes through them: a straight slide from Zeus stuck on stage 6's pavilion (x 1890, mid-lane)
  and was caught. High Olympus's own lane is clear.
- **Long runs at the top**: about 6.5 minutes' climb to Zeus and over 2 minutes' slide home; the user keeps it all on
  foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **Plots: 5.** A sixth player is kicked with "server full"; set Maximum Visitor Count to 5 in Creator Hub.
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are Shear a Sheep's uploads (Mark's account).
  They load if this game is published under the same owner.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- The map's four leaderboard boards are decoration; the player list shows Income and Climb.
- **Sheep may stroll across the map's flat hay scatter** (anything under 0.4 studs high isn't an obstacle), legs a
  little sunk in the straw.
- Studio MCP screenshots don't show ProximityPrompt buttons (Steal, Put down); they work in play.
