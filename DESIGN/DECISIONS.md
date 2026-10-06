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
- **Gods climb in mythological rank, Zeus's family at the top (2026-10-05)**: the user, "the Zeus family should end up
  at the top". The minor gods on the commissioned map, each on a stage that suits them; on High Olympus five more, then
  the thirteen Olympians youngest first: Dionysus, Hermes, Hephaestus, Ares, Aphrodite, Artemis, Apollo, Athena,
  Demeter, Hestia, Poseidon, Hera, Zeus. The user kept that order of 18-30 ("if in Greek mythology they don't have a
  hierarchy, then it doesn't really matter").
- **Real god models (2026-10-05)**: each god is one whole mesh (never split into separate limb meshes: Roblox's
  moderation removed two bare limbs), fully clothed (no bare chests), as bulky as the user's pick, angry, exactly two
  arms, about 6,000 triangles and one texture; symbols as glowing block props (Zeus's neon bolt). Made in Blender from
  now on (Roblox's generator couldn't be steered) and rigged so they walk.
- **Later: gods lunge and belly-slide (2026-10-05)**: when you steal a god's sheep, the god lunges at you face first,
  then glides on its stomach like a penguin, steering towards you. Rig the gods so they can dive and lie prone.
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
- **Caught thieves are punched three tiers down (2026-10-05)**, not sent home, and drop the lamb where they were caught.
  Walker upgrades are properly expensive (about ten minutes of income each). Most escapes should feel close: tune
  towards Climbing sitting just over the next sign, not far past it.
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
- **The stair walker is a real StairMaster the player climbs (the user, 2026-10-05)**: level 1 looks like a plain gym
  machine and each upgrade looks better, ending in the Olympus look (marble and gold); the player snaps onto it like a
  treadmill and climbs the moving steps; the steps get faster with each machine level.
- **Its first five looks are the mock-up's** (Starter, Sport, Pro, Turbo, Champion), "stick with the five for a second";
  the level floats over the machine; the machine stands outside the pen, very close to it, like Steal an Egg's; its
  upgrade sign beside it upgrades it directly, for cash or Robux (the user, 2026-10-05).
- **The stair walker's spot by the gate is right** (the user, 2026-10-05). Its Robux prices are being decided in
  another session; the ones in `GameConfig.StairWalker.Robux` are placeholders until then.
- **Put lambs down anywhere in the pen (2026-10-05)**: like Steal an Egg, the thief brings the lamb into their pen and
  places it where they choose; no delivery platform, no fixed pads to unlock and stand sheep on. Sheep walk around on
  their own like Shear a Sheep's; lambs mostly eat off the floor, head down and chewing, with an eating face: the
  user picked A, "Munch" (eyes shut, cheeks full, a grass sprig in the corner of a mouth working side to side), over B
  (eyes on the grass, mouth opening on a green mouthful), after seeing both on a grazing lamb (2026-10-05).
- **The pen holds 8 sheep to start, up to 20, and growing it is very expensive** (the user, 2026-10-05, from Steal a
  Brainrot: its base starts at 10 and is very expensive to upgrade).
- **Sheep roam the full plot**, at the easy stroll pace they have (the user, 2026-10-05: "they can roam the full plot
  ... I wouldn't change much about that").
- **The game's money is cash, the only currency** (the user, 2026-10-05: no coins anywhere). Every word players see
  says cash; the code and saved data still call it `Coins`.
- **Leaderboards live on the map's billboards in the safe zone, not behind a HUD icon** (the user, 2026-10-05): This
  Server (the richest here, by income), Top Income (the richest overall, each player's best ever), Most Steals and
  Climb Power (titled CLIMBING since Climbing replaced Climb Power on screen). Titles are words only, no icon; otherwise the boards' look (dark panel, medal rows, headshots) is OK'd.
- **The Sell Stall shows stored sheep only** (the user, 2026-10-05): sheep in the pen never appear there, so a player
  can't sell their best by mistake (a way to move the best stored ones into the pen comes later); the server refuses
  pen sheep too. Layout A of `DESIGN/ui/mockups/sell-stall.html`: the grid with a sell tile on the right, nothing
  picked when it opens, each sheep tapped, and a Select all (kept, 2026-10-05).
- **Selling pays two minutes of the sheep's income** (the user, 2026-10-05: "two minutes' worth would be fine", Steal
  an Egg pays about 100 s; a start, to be tuned later). It was 15 s.

- **The free gift (2026-10-05)**: worth 3 minutes of the player's stair walker in Climbing and 3 minutes of their
  income in cash, at least 500 of each, so it keeps up with them (the user: "I do like how the reward size is always
  adjusting"); the look with both rewards on one cyan stage and the steps as lit-up pictures of Roblox's game page.
  Only the favorite can register (no game can see a like); the like step is asked, not checked.
- **The Merge Shrine is a gamble, like Steal an Egg's Fuse Machine (the user, 2026-10-05).** It replaced Shear a
  Sheep's Mutation Machine in the hub. The model is mock-up C, the **Laurel Ring**: a round dais, three pedestals round
  a centre altar, three fire columns and a floating laurel crown. **The pole of light and the orb exist only during a
  merge.** The menu mixes Shear a Sheep's Mutation Machine with the Shop: pick any three grown sheep of the **same
  family** (sizes and fleeces may differ), pay cash, and one fresh lamb of that family comes out with its potential
  hidden. **Fleece and weight are rerolled**: weight usually comes out heavier, with a very small chance of a huge one,
  and a new top size, **Titan**. The result **can be worse** than what went in, and the shrine **shows the odds**
  first. Rarity is the family's, so it never goes up (Steal an Egg's fuse keeps the species too). The merge plays as in
  the approved mock-up video (speed approved): the three turn to light and merge into one, it rises on the pole to the
  orb, pops out as a lamb, spins, and drops onto the altar. The player **picks it up and carries it home** like a
  stolen lamb. **Other players can't take it**; left on the altar for 30 s, or when its player leaves, it goes to
  their pen by itself. Its **size shows only when it grows up in the pen**. A sheep's hidden Weight shifts its size
  odds; no kg on screen. Confirmed after the build: the **price** is 120 seconds of one Standard adult's income of the
  family (tier 1: 240 cash, tier 6: 23.4K) "for now"; a **Titan earns x5**; the lamb waits **30 s** on the altar.

## To review

Calls made ordering the gods by rank (2026-10-05):

- **Which minor god takes which stage**: Pan on the meadow (the shepherds' god), Tyche on the bamboo, Hecate on the
  moonlit snow, Phobos and Eris on the lava, Eros and Hebe in the rose garden, Themis at the marble temple, Asclepius at
  the aqueduct, Iris and Nike on the cloud path, Aeolus on the old summit; Hypnos, Morpheus, Deimos, Thanatos and
  Nemesis on High Olympus 13-17, as before.
- **New area names**: Shepherd's Meadow, Moonlit Crossroads, Fear Ledge, Ambrosia Garden, Messenger's Road, Great
  Forge, War Camp, Moonlit Forest, Olive Grove, Harvest Fields; the others kept theirs.
- **Each god keeps their sheep family and look**, so families move with them: Wild Sheep are tier 1's now, Meadow
  (Scarecrow) Sheep tier 26's. Plain-looking families (Scarecrow, Merino) now come late and flashy ones (Galaxy, Black
  Hole) mid-climb.
- **The Olympians' High Olympus stretches** (new): Dionysus's vines, wine barrels and grapes; Hermes's herms,
  caduceus, winged sandals and coins; Hephaestus's furnaces, anvils, molten pools and braziers; Ares's banners, tents,
  shields and spears and helmets; Aphrodite's roses, hearts, pink arches and a scallop shell with its pearl; Artemis's
  dark pines, the moon, archery targets and silver lights; Apollo's sun, laurel arch, golden tripods and lyres;
  Athena's columns, temple, owls and oil jars; Demeter's wheat, hay bales and scarecrows; Poseidon's waterfalls from
  floating rocks, rock pools, coral and tridents; Hera's golden urns, peacocks, crown and golden apples. The minor gods
  who moved down lost their stretches' props (rainbow, pipes, fountain, wheel of fortune, serpent staff, crystals,
  crossroads, fear moon, scales, laurel arch): the commission's stages are as they were.

Calls made building the Merge Shrine (2026-10-05):

- **Luck**: three Standard sheep bring 40%; each step of size above Standard adds, up to 100% for three Titans. 40%
  gives 58/34/8/0.2% Standard/Large/Giant/Titan; 100% gives 40/44/15/0.7% (the Climbing session's weight bands decide
  the tail).
- **Fleece**: three Ordinary in: 72/24/4% Ordinary/Rare/Royal; three Royal in: 30/45/25%; mixes in between.
- **Menu**: the camera turns to the shrine with no dark backdrop and the HUD hidden; the odds in the lab's glass panel
  on the left, your grown sheep as the shop's rows on the right (the newest god's first, then the biggest), one big
  Merge button with the price at the bottom. The first sheep picked sets the family; the others' buttons say
  "Not <family>". Picks stand on the pedestals in order (1 left, 2 back, 3 right) at their real sizes. Walking 26
  studs from the shrine closes it.
- **One lamb at a time**: you can't merge again until the last lamb has left the altar ("Pick up your lamb first").
- **Pick up**: an instant E prompt ("Pick up", the lamb's name) within 14 studs of the altar; the carry card's Return
  button sends a shrine lamb to the pen.
- **Celebration** when it lands: "NEW LAMB!" ("RARE!" or "ROYAL!" by fleece) with "Pick it up and take it home";
  sounds: LabZap at the merge, LabRiser on the rise, RevealSparkle at the pop, PenDrop on landing. A Titan grow-up
  plays RevealFireworks.

Calls building the friend boost (2026-10-05). The user chose: the tile under the menus (mock-up B), the invite state
with no friends, +20% a friend, written "+20%"; then no notice when a friend leaves, and the tile staying hidden with
the menus during the tutorial was left to the agent (kept).

- **Live income only**: the boost isn't in offline earnings, the leaderboards, the player list's Income, the pen signs
  or the Flock menu's per-sheep rates; only the HUD's cash rate shows it.
- **Capped at 4 friends** (+80%), the most a 5-player server can hold.
- **Notices**: friends already here get "<name> joined: friend boost +40%"; the joiner gets "Friends here: friend
  boost +20%". Nothing when a friend leaves (the tile updates; the user agreed).
- **The tile hides with the other menu pictures** until the first lamb is home; the boost works meanwhile.
- **Tapping it opens Roblox's invite** with friends here too, not only at 0; where invites aren't allowed it says
  "Invites aren't available here".

Calls made building the free gift (2026-10-05).

- **Once per player, ever**; a new player's 25 Climbing becomes 525.
- **What unlocks Claim**: favoriting, through Roblox's own favorite prompt that Claim opens. The like is asked (step 1)
  but can't be checked by any game. Roblox's rules forbid rewards "in exchange for a thumb up"; see the question to the
  user in this task's summary.
- **When it shows**: a GIFT button at the top of the left column (red "!", glowing) until claimed; the menu also opens
  by itself once a session, 30 s after the first delivery (or after joining), when the player is off the mountain, not
  carrying and in no other menu, every session until claimed.
- **Look**: the Shop's Prize Fleece menu (Large, 470 tall), cyan header like the reference, no cash chip in its header,
  no "LIMITED TIME" (it isn't). Step pictures are Roblox's real game page (another game's, counts hidden), lit up.
  Tapping the favorite card opens the prompt too. A player who favorited the game before can claim without a prompt.

Calls building the Sell Stall (2026-10-05).

- **Order**: cheapest first; the header's button switches to Best (dearest first). Oldest first on a tie.
- **Locked sheep show**, dark with their padlock, and can't be picked ("Locked: unlock it in Your Flock"); Select all
  skips them. Select all reads Clear once everything pickable is picked.
- **Cards**: the family's name, what it sells for, and a chip over the picture's foot: LAMB (green), MERGED or
  ASCENDED (purple), or the size above Standard (LARGE, GIANT, TITAN). No income on the card (the price is two minutes
  of it).
- **The tile**: the four dearest picked as a fan with "+N" for the rest, the total, Select all / Clear, Sell N.
- **One confirm for the lot**: "Sell 7 sheep?", the dearest one's token with "x7", the cash, "This can't be undone".
  Afterwards: "Sold 7 for 5.1K cash".
- **Never the whole flock**: a sale that would leave no sheep is refused (only possible when the pen is empty).
- **The Flock menu no longer sells**: its Sell button and confirm are gone; the stall is the one place to sell.
- **The header picture** is the HUD's cash stack (`Theme.Icons.HudCash`); the mock-up had the pack's single bill,
  which isn't uploaded.

Calls building the stair walker (2026-10-05).

- **Placeholder Robux prices (another session is deciding them; nothing is on sale)**: the next level costs R$ 19 (to
  level 2), 39, 59, 99, then 149 for every level after. A developer product per price; ids 0 until they're made in Creator Hub, and the Robux
  prompt says "Robux upgrades aren't on sale yet" meanwhile.
- **Levels 6-30 keep the Champion look** until more looks are designed.
- **The sign** stands by the machine's entry, turned to the gate, written on both sides ("UPGRADE", the next level, its
  price in cash and R$).
- **On and off**: walking into the entry snaps the owner on (only the owner, not while carrying a lamb); jumping puts
  them down behind the entry facing away; "Jump to get off" shows the first time each session. Training only counts
  while snapped on.
- **The sign's prompts**: E upgrades with cash, R with Robux; only the owner sees them; they go at the top level, and
  the board says MAX LEVEL. An empty plot's machine shows level 1 with no floating tag.
- **Step speed by level**: a step takes `0.25 + 0.35 x 0.9^(level-1)` seconds: 0.60 at level 1, 0.48 at 5, 0.40 at
  10, 0.30 at 20, 0.27 at 30.
- **Machine size**: treads 3 wide, 0.6 up and 1.0 deep (about 31 degrees), the player about 2 studs off the floor; the
  machine's sides, hood, console and the sign are solid, the entry step and stairs aren't.

Calls made building free placement and roaming sheep (2026-10-05):

- **The pen is the whole fenced plot**; sheep keep 3 studs from the fence and out of the map's trees and hay (the stair
  walker now stands outside the fence, so there's no keep-out box). The map's hay and trees in the plots stay where the
  map has them (only the walker's and its sign's spots outside the fence are cleared).
- **Pen Space prices**: room for sheep 9 to 20 costs round(25,000 x 6^(n - 9)): 25K, 150K, 900K, 5.4M, 32M, 194M,
  1.2B, 7B, 42B, 252B, 1.5T, 9T. With eight tier 10 sheep the 13th takes about 9 minutes of income; the 20th is for
  tier 23 and up. A save with less room (the old 3) is raised to 8 when it loads. A lamb put down in a full pen is
  stored; the objective warns "Your pen is full: it'll be stored".
- **Putting down**: E / tap / ButtonX on "Put down" (the lamb's name under it) anywhere inside your own fence (the server
  allows 3 studs outside it, for lag); the lamb lands 4 studs in front of you facing your way, or the nearest clear spot
  (rings 3.5 studs apart), hopping down from your head (0.45 s, 2.5 studs high), then a happy hop and the Happy face for
  1.2 s. In someone else's plot: "That's not your plot! Yours has your name over the gate." every 3 s. Objective while
  carrying: "Bring it into your pen" (arrow to your plot), inside "Put it down where you like".
- **Roaming**: strolls of 3-12 studs at 3 studs/s, anywhere in the plot, every 5-14 s for grown sheep and 12-26 s for
  lambs; 30% go on for another leg, 20% are a turn on the spot; sheep keep 3.5 studs (or their sizes) apart. Where it was
  put down is saved and it comes back there on rejoin; one out of storage hops in there; a merged lamb carried home lands
  where it's put down; one with no home yet (Studio's GiveSheep) gets any clear spot.
- **Grazing**: lambs graze 90% of their standing time, adults 45% (3-9 s apart): bouts of 1-3 bites, each the head down
  to the grass for 1.6-2.8 s nibbling and tugging, then up a little chewing for 1.8-3 s, the head working side to side;
  0.4-1.6 s between a lamb's bouts. Wild lambs graze too. Faces: Munch's two frames in turn (0.22 s each) while
  chewing, Baa while baa-ing, a blink every 2.5-6 s on a plain face.
- **Flock menu** says "In your pen" (or "(pinned)") instead of "In pen slot N".

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
  3.0: 0/20/50/30, straight lines between. Wild lambs overall come out about 72/25/3 (was 75/23/2.5). Titan (x5 income,
  2.1 scale; x5 the user's call) only from Huge weights, so never wild.
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
- **Dropped lambs** (the user: a caught thief's lamb stays where it fell, anyone can steal it, its god chases them):
  being caught or dying on the ramp drops it; giving up, falling off the world, resetting or leaving puts it straight
  back, and the tutorial lamb always goes back. A dropped lamb lies there 30 s, then returns to its pasture. Gods still
  walk home slowly (the user's call).
- **The punch** (the user: a caught thief is launched down about three or four tiers, not sent home): three tiers
  down, to the same share along that tier (caught 80% along tier 6, you land 80% along tier 3); from tiers 1-3, the
  mountain's foot. A tumbling arc of 1 to 2.5 s (longer the further), peaking 12% of its length above the straight line,
  then 0.5 s held still. The message reads "<God> punched you! You dropped the lamb".
- **Walker upgrades cost 10x** (the user agreed they should cost more): round(1200 x 2.5^L), about ten minutes of
  income from the tier below. Simulated, Climbing then sits about 1.3-5x the next sign instead of 10-70x, and an
  efficient player reaches Zeus in about 6.5 h (was 4.3).
- **Server ground-speed check**: each player may cover ground at the fastest they could legally go there (walking,
  their escape speed, or a knockback), 30% slack and up to a second banked for lag; anyone faster is put back where they
  were. Server teleports (home after a catch, onto the plot, debug steals) reset it.

Calls made lengthening High Olympus's stretches to 275 (2026-10-05).

- **Decor density kept**: each stretch's trees, rocks, islands, clouds and scattered props scale with its length
  (x275/210), so the longer stretches look as full as the ones the user saw.
- **Zeus's summit plaza starts flush with the top of his stretch**: before, its edge was a chest-high ledge a walker
  couldn't get onto, so nobody could reach the throne on foot.

Calls made building High Olympus, thirty gods (2026-10-05); the user's own calls are under Confirmed rules.

- **Look**: stage 3's floor slab and terrace blocks for every stretch, recoloured per god; trees, rocks, islands, clouds,
  spires, arches and the pavilion cloned from the stages; block props per god (poppies, floating dream shapes and
  stars, craters and Mars beside Deimos, gravestones, ghosts and wisps, swords and a wheel, the Olympians' props above,
  braziers and a hearth, lightning bolts and storm clouds). Decor stays out of the lane (no slide snags); trees stand upright, not
  tilted with the slope as the old stages' are. The old summit's end wall (stage 7's 80-block terrace) is removed.
- **Summit**: a flat 90-stud plaza past Zeus's stretch with his gold throne, steps and a marble colonnade.
- **Numbers, tiers 13-30**: reach about x2.5 a tier from 81M (200M, 500M, 1.3B ... 480T, 1.2Qa at Zeus), Light and Heavy
  at 1.5x and 2.25x as before; income keeps round(2 x 2.5^(tier - 1)) (Zeus ~694B/s); growth 45 + 15 per tier (Zeus 8
  minutes); slide speeds 50-60 (three tiers each at 50, 52 ... 60). Stair walker levels 12-29 added (5M up to 25T a
  second), each covering the next tier's reach gap in about a minute like levels 0-11; costs keep round(120 x 2.5^L) (since raised to round(1200 x 2.5^L)).
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
- **Plots**: the stair walker by the back fence (map hay and trees where it goes are moved out of the way, kept in
  ServerStorage.ClearedDecor). Each penned sheep shows "+X/s" (and a lamb its growth %).
- **Manual Equip pins a sheep**: Equip Best keeps pinned sheep and refills the rest; Store unpins.
- **Selling is at the Sell Stall only** (the map's stall at z 175), in its own menu (Screens/SellStall). The Shop is
  the stall at z 205; the Merge Shrine (opens after 3 deliveries) stands between the stalls.
- **HUD**: menu buttons (Flock, Shop, Sheepdex) appear after the first delivery; the objective line always shows the
  next useful step (steal, slide home, train, put sheep to work, train for Light/Heavy, climb to the next god), with a
  guide arrow to it; a training meter shows the next Climb Power target while on the walker.
- **Tutorial**: a new player's private, Light, ordinary tier 1 lamb (Pan's) sits in the meadow (others can't take it); its
  run is protected from slide hits; any first delivery gives +60 coins and +25 Climb Power and removes it.
- **Sounds**: Shear a Sheep's cues: the danger music during a chase, WolfScare on the alert, IntroWhip on a slide,
  Yelp/Scuffle on hits, Coin/DexReward/Upgrade/Reveal on rewards.
