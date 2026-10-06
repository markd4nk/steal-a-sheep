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
braking and slide hits, pursuit, putting lambs down anywhere in your pen, roaming and grazing sheep, income, growth,
size reveal, Equip Best, locks, selling, merging, trails, pen space, the Sheepdex, offline earnings and the tutorial
lamb.

- **The pen** (2026-10-05): the whole fenced plot; carry a lamb in and press E to put it down where you like (no
  delivery pad, no pads). It holds 8 sheep, buyable up to 20. Sheep roam the plot (`FlockService/Pens`,
  `Utils/Wander`), avoiding trees, hay and the walker; lambs graze nearly all the time with the Munch face, adults now
  and then (`AnimController`, `Utils/SheepClips`). Where each was put down is saved (`HomeX`/`HomeZ`).

- **High Olympus** (tiers 13-30): one stretch a god, 275 studs along the floor, 32 rising to 52 degrees, from stage 3's
  floor slab and terraces and the stages' decor, recoloured, plus block props; Zeus's throne plaza on top. Built into
  the place by `tools/UpperMountain.luau` (Lune, in `build-place.ps1`); `tools/preview-upper-mountain.luau` previews it
  in an open Studio. Its layout and `Config/Olympus` (tier x ranges, `Ramp`) must agree: a test checks the chain.

- **Leaderboards**: the map's four boards by the plots (`workspace.Base.Leaderboard`): This Server (income now) and
  Top Income, Most Steals and Climbing (top 10 across all servers, this server's players drawn in live):
  `LeaderboardService` (OrderedDataStores, log-scaled values). The player list still shows Income and Climbing.

- **Server**: `DataService`, `PurchaseService` (pack, no products), `SheepService`, `PlotService`, `FlockService`,
  `GodService`, `WildService`, `MountainService`, `TrainingService`, `ShopService`, `LeaderboardService`,
  `DebugService` (Studio only).
- **Client**: `StateController`, `SoundController`, `UIController` (Hud, Flock, Shop, Sheepdex, Merge, Popup, Studio
  DebugPanel), `CarryController`, `MovementController`, `AnimController`, `PromptController`.
- **Shared**: `Config/Olympus` (tiers, gods, ramp profile), `Config/GameConfig` (looks, movement, carry, UI),
  `Utils/Economy` (every formula), `Utils/Mountain` (ramp height, tiers by position, floor checks).
- **Climbing** (merged 2026-10-05): one stat, no walls, one speed rule from Climbing and the lamb's hidden weight;
  gods at one set speed; weight saved and tilting size odds (`Economy.RollWeight`, `SizeOdds`, for the Merge Shrine).
  GAME_DESIGN.md, *Climbing* and *Lamb weight*.
- **From Shear a Sheep**: UIKit, Theme, Style (trimmed), Panel, Buttons, Motion, Scale, the sheep rig, add-ons and
  breed builds, Looks, CarryPose, CarryController, SheepClips, Sounds, the Mutation Machine (as the Merge Shrine).

## In progress

- **Gods in rank order** (branch `t3code/order-olympian-gods`, not merged): `Config/Olympus` reordered, new High
  Olympus stretches for the eleven Olympians who moved up. Main merged in (Climbing, pens, leaderboards, dropped
  lambs). Waiting for the user's OK on the new stretches before merging.
- **Real god models**: whole, fully clothed gods (the user's rule after Roblox removed two bare limb meshes; no bare
  chests). Zeus candidate (the user: bulky take 2's size, fully clothed): asset 135867199676206, short-sleeved tunic
  over chest and shoulders, red hem, angry, two arms, 5,954 triangles, one 1024 texture, a neon-block bolt welded in
  his raised right fist; shown in a playtest in place of the block Zeus. Waiting for the user's OK.
- Nothing from the pens session (merged into main 2026-10-05). The Munch eating face is uploaded and in the game
  (`Faces.MunchA`/`MunchB`; `art/faces/chew_faces.py` draws them).
- Nothing from the Climbing session. DECISIONS.md's *To review* lists its calls.

## Not verified

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **All-servers leaderboards**: the place isn't published, so the boards ran on this server's players only; the
  store writes and reads, name lookups and the last write on leaving are untested.
- **Saving**: the place isn't published, so playtests used ProfileStore's mock store; rejoin, offline credit on a real
  rejoin and session locking are untested (the offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts (Steal, Put down), HUD buttons and the slide use
  Roblox's own input.
- **Pens with two players**: a lamb put down in someone else's plot is refused ("not your plot"), tried solo by
  teleporting into another plot; homes saved across a real rejoin and on a different plot number are untested.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **Climbing in play**: playtested 2026-10-05 on tiers 1-3 and 6 with one player (TESTING.md); not on tiers 13-30,
  not with two players, not on touch or gamepad.
- **Upper tiers by foot**: tiers 7-12 weren't climbed on foot; tiers 13, 29 and 30 were (15 s a stretch, onto Zeus's
  plaza). By the numbers it's about 7.6 minutes from the plots to Zeus (a Humanoid walks its 18 studs/s along the slope) at normal speed;
  far under a tier's sign it's about 4 minutes a stretch.
- **High Olympus theft to delivery**: a tier-30 slide was measured through all eighteen stretches (no hops, Zeus
  falling behind), but no theft from tiers 13-30 was carried home and delivered on foot; and the climb speed check wasn't tried there.

## Known issues

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them; lanes stay as they are until the user adds obstacles (DECISIONS.md). Every run
  from High Olympus now passes through them: a straight slide from Zeus stuck on stage 6's pavilion (x 1890, mid-lane)
  and was caught. High Olympus's own lane is clear.
- **Long runs at the top**: about 7.6 minutes' climb to Zeus and about 2.5 minutes' slide home; the user keeps it all on
  foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **The economy is generous (2026-10-05 simulation)**: a walker level costs about a minute of one sheep's income
  from the tier below, at every tier, so Climbing races past the signs (10-70x them) and chases get easy fast. An
  efficient player reaches Zeus in about 4.3 hours (a real one maybe 2-3x that). Trails stop mattering after about
  tier 8 (fixed prices). Waiting for the user's call on slowing it (DESIGN/HISTORY.md, Climbing).
- **Very fast slides meet the trees hard**: at 150+ studs/s a slide that clips a tree stops dead and its god catches
  up (seen at x 944 on tier 3). Same decor issue, felt more at high speed.
- **Plots: 5.** A sixth player is kicked with "server full"; set Maximum Visitor Count to 5 in Creator Hub.
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are Shear a Sheep's uploads (Mark's account).
  They load if this game is published under the same owner.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- **Sheep may stroll across the map's flat hay scatter** (anything under 0.4 studs high isn't an obstacle), legs a
  little sunk in the straw.
- Studio MCP screenshots don't show ProximityPrompt buttons (Steal, Put down); they work in play.
