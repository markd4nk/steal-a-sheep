# Decisions

*Confirmed rules* are the user's calls: keep them unless the user says otherwise, and don't ask again. *To review*
holds calls agents made that players would notice (rules, timings, ranges, prices, rewards, what the UI shows),
waiting for the user: add yours at the top, and move an item to *Confirmed rules* (or delete it) once the user has
confirmed or reversed it.

## Confirmed rules

- **The base design doc is the starting point; the user refines from here (2026-10-05).** The first build followed
  `DESIGN/BASE_DESIGN_DOC.md`; the user will rework a lot of it as they go. A request that changes what was built is
  the new rule: don't object that it goes against the base doc, the first build or the calls below; make it and update
  the docs.
- The first build reused Shear a Sheep's UI and assets and kept new things primitive (the user, 2026-10-05). That was
  how the MVP was made, not a limit on later changes.
- **Thirty gods, Zeus on top (2026-10-05)**: the user's list of thirty, a map part for each above the old summit
  (High Olympus), each god's section grouped, the new parts indistinguishable from the commissioned map (its own
  pieces, studs and textures).
- **High Olympus's grade rises gradually to 52 degrees at Zeus** (the user, 2026-10-05: no steeper than about 60,
  noticeable; then "keep it that").
- **Climbing is one stat, no walls (2026-10-05)**: speed and Climb Power are one thing, "Climbing". Every tier is
  open; steeper tiers need more and more Climbing to climb at a useful pace. Too little gives a very slow crawl, never
  a slip back down, so it's technically possible but nobody wants to, and a thief that weak is caught carrying the lamb
  down. No delivery lock between tiers. No god lunge.
- **Your speed vs its speed, like Steal an Egg (2026-10-05)**: each god has one set speed for the whole chase (never
  slower in lower stretches, never a walking speed); the thief's escape speed comes from Climbing; a slide keeps the
  speed it starts with all the way down (momentum). Checked against Steal an Egg: each zone has its own guardian,
  faster higher up, never scaled to the player; you escape with enough Speed over the zone's minimum.
- **One speed rule (2026-10-05)**: your speed on a tier comes from Climbing / (its sign number x the lamb's weight),
  as few numbers as possible. No cap on the mountain: more Climbing keeps making you faster. Walking in the safe zone
  (the plots and hub) is capped at 7x normal; tier 1 and the safe zone never go below normal. The sign's number is
  just enough for the lightest lamb on that tier; an average lamb leaves about 95% of the god's speed there.
- **Hidden lamb weight (2026-10-05)**: no Light/Stout/Heavy words and no numbers on screen: players feel it. A smooth
  range, not three kinds. Saved with the sheep; heavier lambs tend to grow bigger, but a light one can still grow
  large, just less likely. The carry card shows no speeds.
- **High Olympus's stretches are 275 studs along the floor** (the user, 2026-10-05: at 210 they felt shorter than the
  first levels, about 250, so a bit longer than those). 169-233 across the ground, so the steep ones still look
  shorter than they climb.
- **No shortcut up**: the climb stays on foot, however long (the user turned down a lift to the highest open gate,
  2026-10-05).
- **Obstacles on the higher levels come later, from the user** (2026-10-05: High Olympus is "very barren" now). Until
  then don't thin or fill the slide lanes, old stages included.
- **The game's money is cash, the only currency** (the user, 2026-10-05: no coins anywhere). Every word players see
  says cash; the code and saved data still call it `Coins`.
- **Leaderboards live on the map's billboards in the safe zone, not behind a HUD icon** (the user, 2026-10-05): This
  Server (the richest here, by income), Top Income (the richest overall, each player's best ever), Most Steals and
  Climb Power (titled CLIMBING since Climbing replaced Climb Power on screen). Titles are words only, no icon; otherwise the boards' look (dark panel, medal rows, headshots) is OK'd.

## To review

Calls made building the world leaderboards (2026-10-05); the user's own calls are under Confirmed rules.

- **Where each board stands**: the north pair has This Server (outer) and Top Income (inner), the south pair Most
  Steals (inner) and Climbing (outer). The inner ones stand nearest the hub.
- **This Server ranks income right now**, so it drops when a player sells; Top Income keeps their best.
- **Top 10 across all servers**, read once a minute, with this server's players redrawn every 5 s so a player sees
  their own rise at once. Players at 0 aren't listed; an empty board reads "No one yet".
- **Most Steals counts every delivery**, the tutorial lamb included.
- **A row**: rank badge (gold, silver, bronze for the top three, rows tinted to match), avatar headshot, display name,
  value in the board's colour (lime for income, gold for Climbing, white for steals). A small line at the bottom
  says "Right now" on This Server, and "All servers" on the others ("This server" where DataStores aren't available).
- **Studio uses its own stores** (`_Studio`), so playtests never reach the live boards. The player list (Income,
  Climbing) stays as it was.

Calls made building Climbing (2026-10-05):

- **Speed curve**: below the sign your speed is the ratio itself (a quarter of the sign, a quarter of normal speed),
  never under a 1 stud/s crawl; above it, +1x normal speed for every 4x (each tier outgrown). Slowed players still
  cross a slope or come down it at normal speed: only the uphill part is held down.
- **Weight bands**: wild lambs weigh 1-1.1 (95%) or 1.1-1.5 (5%), about 1.06 on average. The shrine's luck (0-1)
  raises the heavy chance up to 60% and opens a Huge band, 1.5-3, up to 3%.
- **Size odds by weight** (Standard / Large / Giant / Titan): 1.0: 85/14/1/0, 1.1: 60/35/5/0, 1.5: 15/60/25/0,
  3.0: 0/20/50/30, straight lines between. Wild lambs overall come out about 72/25/3 (was 75/23/2.5). Titan (x4 income,
  2.1 scale, placeholder numbers for the shrine to tune) only from Huge weights, so never wild.
- **Weight's only visible hint** is the lamb's size: 0.6 of an adult at the lightest, 0.8 at 1.5.
- **Slides**: the god's speed x your speed factor, at least walking speed, kept all the way down; they reach it in
  about 2 seconds (speeding up by at least 26 studs/s each second).
- **Gods**: 0.8 x the tier's SlideSpeed, 19 at tier 1 to 48 at tier 30; the tutorial lamb's god 0.7.
- **Tier 1's sign is 25** (what the tutorial gives), so a high level speeds you up there too.
- **On screen**: tier signs "<God>'s <Area> / Climbing N"; the HUD's goals "Train to climb", "Train for heavier
  sheep", "Ready for the heaviest sheep"; "<God>'s <Area> is in reach!" when Climbing passes the next sign; the player
  list column is Climbing; the HUD pill reads CLIMBING; the wild lamb's card and the flock menu no longer name a burden.
- **Server check**: a player found further up the ramp than their Climbing allows (30% slack, 10 studs or 1 second's
  lead for lag) is put back at their allowed spot.
- **Saved sheep**: schema 2 turns Burden 1/2/3 into Weight 1.05/1.2/1.35; sizes already rolled stay.

Calls made lengthening High Olympus's stretches to 275 (2026-10-05).

- **Decor density kept**: each stretch's trees, rocks, islands, clouds and scattered props scale with its length
  (x275/210), so the longer stretches look as full as the ones the user saw.
- **Eris's crystals start 14 studs outside the lane** (was 6): a leaning one reached 6 studs into the lane.
- **Zeus's summit plaza starts flush with the top of his stretch**: before, its edge was a chest-high ledge a walker
  couldn't get onto, so nobody could reach the throne on foot.

Calls made building High Olympus, thirty gods (2026-10-05); the user's own calls are under Confirmed rules.

- **Climb order**: the old summit is Aeolus's (12, "Windswept Peaks"); then Iris, Pan, Hebe, Eros, Tyche, Asclepius,
  Eris, Hecate, Hypnos, Morpheus, Phobos, Deimos, Thanatos, Nemesis, Themis, Nike, Hestia, Zeus (13-30): bright and wild
  first, then dusk, sleep, dreams, fear and death, then justice, victory and the hearth by Zeus's throne. The user's
  list ranks by fame; the old map's stages already hold the Olympians, so the minor gods are above them.
- **Look**: stage 3's floor slab and terrace blocks for every stretch, recoloured per god; trees, rocks, islands, clouds,
  spires, arches and the pavilion cloned from the stages; block props per god (a rainbow over the path, Pan's pipes and
  toadstools, goblets and a fountain, hearts, coins and a wheel of fortune, the serpent staff and pools, golden apples
  and crystals, torches and a moon, poppies, floating dream shapes and stars, craters, Mars beside Deimos, eyes,
  gravestones, ghosts and wisps, swords, columns and scales, trophies, wings and banners and a laurel arch, braziers and
  a hearth, lightning bolts and storm clouds). Decor stays out of the lane (no slide snags); trees stand upright, not
  tilted with the slope as the old stages' are. The old summit's end wall (stage 7's 80-block terrace) is removed.
- **Summit**: a flat 90-stud plaza past Zeus's stretch with his gold throne, steps and a marble colonnade.
- **Numbers, tiers 13-30**: reach about x2.5 a tier from 81M (200M, 500M, 1.3B ... 480T, 1.2Qa at Zeus), Light and Heavy
  at 1.5x and 2.25x as before; income keeps round(2 x 2.5^(tier - 1)) (Zeus ~694B/s); growth 45 + 15 per tier (Zeus 8
  minutes); slide speeds 50-60 (three tiers each at 50, 52 ... 60). Stair walker levels 12-29 added (5M up to 25T a
  second), each covering the next tier's reach gap in about a minute like levels 0-11; costs keep round(120 x 2.5^L).
- **Families**: Gale (Frost), Wild (Moss + goat horns), Ambrosia (Cupcake, honey frosting), Fortune (Pirate), Potion
  (Slime), Chaos (Glitch), Spirit (Ghost), Slumber (Dream), Starlit (Galaxy), Fright (Wolf in Sheep's Clothing), Dread
  (Black Hole), Bone (Skeleton), Avenger (Mecha), in Shear a Sheep's colours; Prism is a plain sheep in rainbow puffs;
  Cupid (pink Cloud wool), Victory (gold) and Justice and Hearth (Ringlets) are plain with new primitive extras: back
  wings, a blindfold, a flame.
- **Gods**: primitive block gods like the twelve, each with a signature: Aeolus's gusts and wind bag, Iris's rainbow
  halo, Pan's horns and pipes, Hebe's cup, Eros's bow and wings, Tyche's coin crown, Asclepius's serpent staff, Eris's
  golden apple, Hecate's two torches, Hypnos's nightcap, Morpheus's stars, Phobos's mask, Deimos's plumed helmet,
  Thanatos's hood and scythe, Nemesis's sword, Themis's scales and blindfold, Nike's wings and laurel, Hestia's flame.
- **Gods chase at the design's share of speed along the slope** (they used to step it across the ground, while a
  player's Humanoid moves its speed along the slope): on 31 degrees gods were ~17% quicker than designed and on 52 they'd
  have caught every thief. Old tiers' escapes are now slightly easier.
- **Slides hug the ramp**: a slide drops at least as fast as the ramp under it (not during a jump); without it, slides on
  45-52 degrees spent a third of the time in the air.

Calls made while building the MVP on 2026-10-05:

- **God order fits the map's stage themes**: Demeter (meadow), Dionysus (bamboo), Artemis (snow), Hephaestus and Ares
  (lava), Aphrodite and Apollo (rose garden), Athena and Poseidon (marble temple and aqueduct), Hermes, Hera and Zeus
  (cloud path to the summit). Each tier
  keeps its numbers (reach, income) in order. Reordering is a reorder of rows in `Config/Olympus`.
- **Twelve tiers on seven stages**: the long stages hold two or three tiers (stage 4: 2, stage 5: 2, stage 6: 2,
  stage 7: 3). Tier boundaries are x positions on the ramp (`Olympus.Tiers[].XStart`).
- **Families are Shear a Sheep breeds**: Scarecrow, Moon (silver), Lava, Cotton Candy, Solar System, Ocean, Cloud,
  Royal and Storm Sheep as they are; Grape (purple Ringlets + a leaf), War (red Racka + a helmet) and Laurel (white
  Merino + a wreath) are plain breeds with a primitive extra; the Wingfoot (Cloud) Sheep has small neon ankle wings.
- **Fleece rarity looks**: Rare sheep sparkle blue; Royal sheep have gold wool (Shear a Sheep's Gold paint) and sparkle.
- **Sizes on screen**: every sheep's base size is 1.6x the rig; lambs are 0.6 / 0.7 / 0.8 of it by burden (a clue to
  the burden) and grow towards 0.85 before the reveal; adults are 1 / 1.35 / 1.7 by size.
- **Slides**: start by themselves when moving downhill on the ramp past the safety line (the map's StartingLine,
  x 330); speed per stretch 24, 28, 32, 36, 36, 40, 40, 44, 44, 48, 48, 48 studs/s (tiers 1-12), times the carried
  lamb's burden share; steering within about 35 degrees either side of straight downhill; pulling back brakes; past the
  safety line the slide runs out to a stop. A scenery hit drops the slide to the speed the player really has; stuck for
  half a second ends it. The slide pose is Roblox's sit animation.
- **Gods**: one per tier, standing near the top of its stretch to one side of the lane; 1.5 s head start; chase at 0.88
  of the stretch's walk (18) or slide speed (whichever the target is doing); catch within 3.5 studs with a clear line
  of sight; a caught thief is sent home to their plot. Tutorial thieves are chased at 0.7. A god chases only its own
  tier's thieves, gives up at the safety line, then walks home at 16.
- **Theft card**: a wild lamb shows its name, "Grows to +low-high/s" and its burden (Light green, Stout yellow, Heavy
  red); hold E 0.5 s ("Steal"). Royal lambs are announced to players who have that tier open.
- **Pens**: twelve pads in a 4 x 3 grid in each plot (3 open, then bought in order), the delivery pad just inside the
  gate, the stair walker by the back fence; map hay and trees standing where they go are moved out of the way
  (kept in ServerStorage.ClearedDecor). Each penned sheep shows "+X/s" (and a lamb its growth %).
- **Manual Equip pins a sheep**: Equip Best keeps pinned sheep and refills the rest; Store unpins.
- **Selling is at the Sell Stall only** (the map's stall at z 175); the Flock menu opened there adds Sell with a
  confirm showing the coins and the income lost. The Shop is the stall at z 205; the Merge Shrine is Shear a Sheep's Mutation
  Machine between the stalls (opens after 3 deliveries).
- **Merge picks the three**: the biggest of the group, then the two that earn least (stored ones first). The preview
  shows the sizes used, the three's income against the result's, and the flock's income before and after.
- **HUD**: menu buttons (Flock, Shop, Sheepdex) appear after the first delivery; the objective line always shows the
  next useful step (steal, slide home, train, put sheep to work, train for Light/Heavy, climb to the next god), with a
  guide arrow to it; a training meter shows the next Climb Power target while on the walker.
- **Tutorial**: a new player's private, Light, ordinary Demeter lamb sits in the meadow (others can't take it); its
  run is protected from slide hits; any first delivery gives +60 coins and +25 Climb Power and removes it.
- **Sounds**: Shear a Sheep's cues: the danger music during a chase, WolfScare on the alert, IntroWhip on a slide,
  Yelp/Scuffle on hits, Coin/DexReward/Upgrade/Reveal on rewards.

## Calls left to the user

- Keep the theme-fitted god order, or change it?
