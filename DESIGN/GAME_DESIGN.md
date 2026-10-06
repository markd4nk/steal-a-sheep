# Game design

**Where it started, and how it's changing.** The game was built from the user's base design doc,
[`DESIGN/BASE_DESIGN_DOC.md`](BASE_DESIGN_DOC.md) (draft v0.3, 2026-10-05), which explains why the first build is the
way it is. From here the user refines the game as they go, and much of what was first built will be reworked and made
better. So the base doc is background, not a spec, and this page describes the game *as it is now*. When the user asks
for a change, make it, even where it departs from the base doc or the first build; don't push back on those grounds.
Then update this page so it stays a true description.

## Pitch
Climb the mountain, steal a god's lamb, hold it over your head and slide downhill to escape (knocking back climbers
on the way), then grow your flock into the biggest earners in your pen.

## Core loop (as built)
Train on the stair walker -> climb to a god's pasture -> steal a lamb -> slide home with the god behind you ->
carry it into your pen and put it down wherever you like -> it grows up there, roaming and grazing, and only then shows
what it is and starts earning -> upgrade.

## Onboarding (the user, 2026-10-06: "it should be very simple, but the player should understand exactly what it is, and I don't want to hand-hold them the entire time")
- Only the first lamb is guided, by Shear a Sheep's trail of white chevrons running along the ground, and no words. The
  trail leads to a place, not to a sheep: from the pen, out of the gate, to the front of Pan's meadow (the tutorial
  lamb waits just short of it, the meadow's wild lambs past it). In the meadow it stops; the lambs' Steal buttons and
  the chase's music say the rest. No words come up during a chase either (no "Pan wants their sheep back!", the user,
  2026-10-06).
- With the lamb, nothing on the slope (the slide takes the player down); from the mountain's foot the trail leads
  into the player's own pen, where it stops and the Put down button takes over.
- After that first delivery the menus appear and one short trail leads out of the gate to the stair walker. Stepping
  on ends the onboarding for good (saved `Tutorial` 2). From then on nothing tells the player what to do.
- As in Steal an Egg (two first plays watched, 2026-10-06): a trail to the first egg and home, then nothing. Steal an
  Egg also shows a short line per step ("Steal an Egg!", "RUN!!", "Go to your Pen!"); this game leaves the words out.

## The pen (the user, 2026-10-05: "just like Steal an Egg ... bring them into the pen and then place them down", and
the sheep walking around on their own "just like in Shear a Sheep", lambs "mostly eating off the floor")
- The whole fenced plot is the pen. There's no delivery pad and no pads to stand sheep on or unlock: a thief carries
  the lamb through their gate and presses E (Put down, on the lamb over their head) anywhere inside their own fence;
  it hops down in front of them, happy to be home. That's the delivery.
- Each sheep roams the whole plot from where it was put down, at an easy pace (Shear a Sheep's wander: long spells
  standing, then a short stroll), never into the map's trees, hay or the stair walker, never on top of another sheep.
  Where it was put down is saved: it's back there after a rejoin.
- Lambs graze nearly all the time: head down to the grass, nibbling, then up to chew with the "Munch" face (eyes
  shut, cheeks full, a grass sprig working side to side). Grown sheep
  graze now and then and otherwise stand about, breathe, look round, blink and baa. Wild lambs graze in the pastures
  too.
- The pen holds 8 sheep to start; more room is bought in the Shop as Pen Space, one at a time and very expensive, up
  to 20 (the user: like Steal a Brainrot's base). One put down in a full pen is stored, not earning (Flock menu: Equip /
  Store / Equip Best).

## Systems
- Climbing, stair walker, trails: `TrainingService`, `ShopService`.
- Wild lambs, theft, carrying, putting down in the pen (delivery), failure rules, tutorial lamb: `WildService`
  (+ `SheepService` for models); the Put down prompt is the client's own (`PromptController`).
- Gods and pursuit: `GodService` (one state machine, primitive block rigs).
- Climb speed checks, tier signs, slide hits and knockback: `MountainService`; uphill speed, client slide, steering, braking: `MovementController`; slide speed and momentum: `Mountain.SlideBase`/`Momentum`.
- Flock, pen capacity, income, growth, offline credit, Sheepdex rewards, Equip Best, locks, selling, merging:
  `FlockService`; the Sell Stall's menu (stored sheep only, several at once): `UIController/Screens/SellStall`; the sheep living in the pen and their strolls: `FlockService/Pens` (+ `Utils/Wander`); walking,
  hopping in, grazing and faces on each device: `AnimController` (+ `Utils/SheepClips`).
- Plots (the map's five), the pen box, where a sheep may stand or walk, stair walkers: `PlotService`.
- Leaderboards on the map's four boards (This Server, Top Income, Most Steals, Climbing): `LeaderboardService`.
- The Robux store: what it sells and its prices in `Config/Store`; prompts and passes `StoreService`; grants
  `PurchaseService/Products`; the screen `Screens/Store`.
- Free gift for liking and favoriting the game (Climbing and cash, once): `GiftService`, `Screens/Gift`.
- Each god's six sheep: `Config/Herds` (looks, rarities); the Sheepdex's claims and herd gifts: `SheepdexService`,
  `Screens/Sheepdex`.
- Every formula: `src/shared/Utils/Economy.luau`; tiers and gods: `src/shared/Config/Olympus.luau`.

## The map
Thirty gods (the user, 2026-10-05: "build out 25 total ... based on the top Olympus gods", then a list of thirty with
"map parts for all of these gods"; Zeus on the new top), climbing in mythological rank (the user: "the Zeus family
should end up at the top"). The commissioned map is one corridor climbing east (+X) from the plots in seven themed
stages of rising grade (2, 7, 12, 17, 22, 29, 31 degrees) holding tiers 1-12, two or three on the long stages: the minor
gods and personifications, each on a stage that suits them. Above its old summit, High Olympus
(`tools/UpperMountain.luau`) carries the corridor on with one stretch a god, built from the map's own pieces, the grade
rising a degree or so a god from 32 to 52 (the user: no steeper than about 60, gradual but noticeable; 52 at the top
kept), up to Zeus's throne plaza: five more minor gods, then the thirteen Olympians from the youngest, Dionysus, to
Zeus's siblings, Hera and Zeus. Below the Twelve the myths set no order, so the minor gods follow the stages' themes.
The climb is all on foot. High Olympus is sparse for now: the user will add obstacles to it later.

Each god has six sheep families (below); the table's is the god's own, their Common. Their lambs all look alike but
for their marks (*Mystery lambs*).

| Tier | God | Where | Family (Shear a Sheep breed) |
| --- | --- | --- | --- |
| 1 | Pan | meadow: Shepherd's Meadow | Wild Sheep (Moss Sheep + horns) |
| 2 | Tyche | bamboo: Fortune Terraces | Fortune Sheep (Pirate Sheep) |
| 3 | Hecate | snow: Moonlit Crossroads | Spirit Sheep (Ghost Sheep) |
| 4 | Phobos | lava: Fear Ledge | Fright Sheep (Wolf in Sheep's Clothing) |
| 5 | Eris | lava: Chaos Rift | Chaos Sheep (Glitch Sheep) |
| 6 | Eros | rose garden: Heart Garden | Cupid Sheep (pink Cloud wool + back wings) |
| 7 | Hebe | rose garden: Ambrosia Garden | Ambrosia Sheep (Cupcake Sheep, honey) |
| 8 | Themis | marble temple: Court of Justice | Justice Sheep (white Ringlets + blindfold) |
| 9 | Asclepius | temple aqueduct: Healing Springs | Potion Sheep (Slime Sheep) |
| 10 | Iris | cloud path: Rainbow Bridge | Prism Sheep (rainbow puffs) |
| 11 | Nike | cloud path: Victory Stair | Victory Sheep (gold wool + back wings) |
| 12 | Aeolus | old summit's peaks: Windswept Peaks | Gale Sheep (Frost Sheep) |
| 13 | Hypnos | Poppy Fields | Slumber Sheep (Dream Sheep) |
| 14 | Morpheus | Dream Steps | Starlit Sheep (Galaxy Sheep) |
| 15 | Deimos | Dread Moon | Dread Sheep (Black Hole Sheep) |
| 16 | Thanatos | Asphodel Meadow | Bone Sheep (Skeleton Sheep) |
| 17 | Nemesis | Reckoning Ridge | Avenger Sheep (Mecha Sheep) |
| 18 | Dionysus | Vineyard Terraces | Grape Sheep (purple Ringlets + leaf) |
| 19 | Hermes | Messenger's Road | Wingfoot Sheep (Cloud Sheep + ankle wings) |
| 20 | Hephaestus | Great Forge | Ember Sheep (Lava Sheep) |
| 21 | Ares | War Camp | War Sheep (red Racka + helmet) |
| 22 | Aphrodite | Rose Garden | Rose Sheep (Cotton Candy Sheep) |
| 23 | Artemis | Moonlit Forest | Moon Sheep (Moon Sheep, silver) |
| 24 | Apollo | Sun Terrace | Sun Sheep (Solar System Sheep) |
| 25 | Athena | Olive Grove | Laurel Sheep (white Merino + wreath) |
| 26 | Demeter | Harvest Fields | Meadow Sheep (Scarecrow Sheep) |
| 27 | Hestia | Eternal Hearth | Hearth Sheep (orange Ringlets + flame) |
| 28 | Poseidon | Cloudwater Falls | Tide Sheep (Ocean Sheep) |
| 29 | Hera | Royal Courtyard | Crown Sheep (Royal Sheep) |
| 30 | Zeus | Throne of Olympus | Thunder Sheep (Storm Sheep) |

## Economy (as built)
Cash, the only currency (code calls it `Coins`), comes from grown sheep in the pen (lambs earn nothing),
first-discovery rewards, selling, the free gift and the daily gifts, and buys stair walker levels, pen space and trails. Robux buys from the store below.

## The Robux store (the user, 2026-10-05)
A STORE button on the HUD opens one page that scrolls, its section tabs outside the window on the right:
- **Sheep**: Golden Fleece (799) and Kronos Sheep (349), sold for Robux only. Each earns 10x / 3x the player's best
  other sheep, so it stays their top earner at every tier; they arrive grown and can't be sold or merged.
- **Passes**: 2x Money (all sheep income, offline too) and 2x Growth (lambs grow twice as fast, away too).
- **Speed**: 2x Speed doubles Climbing; it can be bought again, three times the price each time (3 to 2,187, seven
  buys). The stair walker's next level, for Robux (19, then 20% more a level) or its cash price.
- **Climbing** packs (+150K to +10B) and **Cash** packs (24K to 8M).
Hermes' winged sandal is the climbing icon everywhere (gold wings on 2x Speed).

## Friend boost (the user, 2026-10-05)
Each Roblox friend in your server adds +20% to your flock's cash income while they stay (servers hold 5, so +80% at
most); not offline earnings, not the leaderboards. A tile under the menu pictures shows it: two friends and "+40%",
or, with no friends here, the invite picture and INVITE. Tapping it opens Roblox's invite. When a friend joins:
"Sam joined: friend boost +20%"; the HUD's cash rate includes the boost.

## Daily gifts (the user, 2026-10-05)
Come back each day for a better gift; Day 7 is a super rare sheep found nowhere else, the **Pegasus Sheep**. Then the
same week starts again (the user: "just this week for now"; later weeks are still to design). A missed day waits
where it was. The next gift opens 20 hours after a claim.
- Days 1-6: cash (3, 10 and 30 minutes of the pen's income), Climbing (1 and 3 minutes of the stair walker), and on
  Day 4 a Rare lamb from the highest god the player has stolen from. Each is at least a small floor for new players.
- **The Pegasus Sheep**: white and fluffy, big feathered wings tipped in gold, a glowing halo and gold hooves (the
  user's pick: the third look in the mock-up). It arrives as a lamb with lucky size odds and earns as a sheep one god
  above the highest stolen from, as much as a Royal sheep of that god. It can't go in the Merge Shrine.
- The menu, layout B (the user's pick): Days 1-6 as cards, Day 7 big beside Claim; claimed days dark with a tick,
  today's gold, the countdown on the button once claimed. It opens by itself once a session while a gift waits; the
  HUD's DAILY (the golden calendar, under GIFT) opens it any time and shows the countdown once claimed.

## Stair walker (the user, 2026-10-05)
A real StairMaster just outside each pen, beside the gate, like Steal an Egg's treadmill. Walk into it and you snap on
and climb its moving steps (your legs on the steps, any avatar); jump to get off. Its level floats over it, its steps
run faster with your training rate (each level, each trail; 0.5 s a step on the free machine to 0.1 s at the top),
each step pops a "+N" off your head (what it earned: "+1" twice a second at first, about ten "+2.5T" a second at the
top) while the machine's floating level hides on your screen, and it looks better as it upgrades: Starter, Sport, Pro,
Turbo, Champion (levels 6 and up keep Champion's look for now, ending in an Olympus look later). The upgrade sign
beside it buys the next level straight away, for cash or Robux (the store's walker prices).

## Climbing (the user, 2026-10-05)
Like Steal an Egg: train one stat, **Climbing** (the stair walker; saved as `ClimbPower`), to get up the mountain
and to outrun its gods. No walls: every tier is open to everyone.

**Your ratio on a tier = Climbing / (its sign number x the carried lamb's weight)** (weight 1 empty-handed).

- **Your speed**: the ratio itself below 1 (a quarter of the sign, a quarter of normal speed; never under a 1 stud/s
  crawl), then +1x normal speed for every 4x above it, no cap on the mountain. Signs grow about 4x a tier, so every
  tier above you is a quarter speed (two above is a crawl) and every tier you've outgrown is +1x.
- **Walking and climbing** = 18 studs/s x your speed. Slowed, only the uphill part is held down. Tier 1 and the safe
  zone (plots, hub) never go below normal; walking in the safe zone stops at 7x.
- **Sliding away** = the god's speed x your speed (at least walking speed), set when the slide starts. It reaches it
  in about 2 seconds.
- **Momentum (the user, 2026-10-06)**: every sign you slide past adds 15% of that starting speed, up to 100 studs/s
  (a slide already faster keeps its own). Carrying, it counts from the lamb's tier; empty-handed, from where the slide
  began. A bump costs speed, won back in about a quarter of a second, and never trips you over. The slide **stops
  dead at the safety line**: from there you walk, so nobody is carried into the plots.
- **Gods**: 0.8 x its tier's `SlideSpeed` (19 at tier 1 up to 48 at tier 30), never walking, times its thief's
  momentum where they are: boosted as much as its thief, and it keeps that boost while they bump into things. The
  chase opens with a **lunge** (the user, 2026-10-06): after pointing for the head start the god crouches, dives face
  first and belly-flops (0.84 s), the dive carrying it 1.6x as fast for a third of a second; then it **glides on its
  belly like a penguin** for the rest of the chase, flippers flapping, steering after its thief and leaning into
  turns. One lunge per chase, at the start. A catch: it gets up, then laughs; a lost chase: it gets up and walks home.
- **The slide's look (the user, 2026-10-06)**: you **surf** down without a board, side on, left shoulder first,
  knees bent, looking downhill, carving and leaning into turns (instead of Roblox's sit); a carried lamb stays held
  overhead, empty hands go out for balance. Everyone sees everyone's. R6 avatars keep Roblox's sit.
- **So**: at the sign's number the lightest lamb's thief matches the god and the head start gets them away; an
  average lamb leaves about 95% (caught near the bottom); heavy ones need more. Momentum doesn't change who wins a
  clean chase or where, only how long it takes; a bump brings the god closer (at the sign's number, with the lightest
  lamb: three quick knocks or two half-second stops leave you ahead, the next gets you caught).

## Lamb weight (the user, 2026-10-05)
Hidden: no words or numbers on screen, players feel it. A smooth range from 1 (lightest) up, saved with the sheep
(`Weight`). Wild lambs: 1-1.1 mostly, 1.1-1.5 for one in twenty. Heavier lambs are slower to carry and tend to grow
bigger (size odds shift with weight; Titan only from the Merge Shrine's huge rolls), and look bigger and rounder as
lambs (*Mystery lambs*).

## Six sheep a tier (the user, 2026-10-05)
Every god's pasture holds six families (`Config/Herds`, keyed by god): **Common** (the god's own family), **Uncommon,
Rare, Epic, Legendary, Mythic**, the rarer ones built from Shear a Sheep's builds and wool with primitive extras. Each
wild lamb rolls its family: 50 / 25 / 13 / 7 / 4 / 1%. A family earns its tier's base income times x1, x1.5, x2.5, x4,
x8, x15. On top of that every lamb still rolls its **fleece: Plain, Shiny (x1.5, blue sparkles) or Royal (x2.5, gold)**.
A lamb doesn't show its family until it grows up (*Mystery lambs*). Legendary and Mythic lambs (and Royal fleeces)
are announced without naming the family ("A Mythic Lamb appeared in Zeus's pasture!"). Menus colour a grown sheep's
card by its family's rarity; a lamb's card is Common's grey.

## Sheepdex (Mark's mock-up, 2026-10-05)
Like Steal an Egg's Pet Index: one scrolling list with a section per tier (its god, its six sheep in a 3 x 2 grid in
their rarity's colours, dark silhouettes until found, a bar to the herd's gift) and the picked sheep beside it: its
picture, rarity, income, where it lives and its reward. Growing up the first of a family finds it; its reward (30 s of
the family's income in cash, and 5% of its tier's sign number x its rarity's multiplier in Climbing, at least 5) waits
for **Claim** in the Sheepdex. Claiming all six of a god pays the herd's gift (10 minutes of the tier's Common income,
and a quarter of its sign number in Climbing, at least 25). A red badge on the HUD's SHEEPDEX counts rewards waiting.

## Merge Shrine (the user, 2026-10-05)
The Laurel Ring in the hub, where the Mutation Machine stood: pick three grown sheep of one family in its menu, pay
cash, and they merge into one fresh lamb of that family. Its fleece and hidden weight are rerolled (so its adult size
too): bigger sheep in bring more luck, which makes heavy lambs likelier and opens the huge weights, the only way to a
Titan. It can come out worse than what went in; the menu shows the odds first. The lamb pops out of an orb that
appears over the altar only during the merge, lands on the altar, and its player picks it up and carries it home like
a stolen lamb (no god chases it; nobody else sees or takes it); left there 30 s it goes home by itself. It's a lamb
like any other: its size shows when it grows up in the pen. `ShrineService` (server), `ShrineController` (the scene on
each device), the Merge menu.

## Mystery lambs (the user, 2026-10-06)
"So that the player doesn't actually know what they're getting", like Steal an Egg's eggs: a lamb shows only a few
clues to what it will grow into, and what it is shows when it grows up.
- **The look** (mock-up D, the user's pick): every lamb is a bare white lamb, no wool ("you can tell that it's just a
  lamb"), its horns, if it'll have any, as buds, with **one spot for each step of its family's rarity**, Common one to
  Mythic six, in the main colour of the sheep it will be (taken from that sheep's own look). Heavier lambs are bigger
  and rounder (*Lamb weight*). Shiny and Royal fleeces show only their blue or gold sparkle.
- **Nothing names it**: nothing over a wild lamb (no card), nothing on screen while it's carried, and "Lamb" in the
  Flock menu, at the Sell Stall and in the notices, with its token and 3D look in its marks, even when its family is
  known (a merged lamb, the gift lambs).
- **Growing up**: in the pen a lamb earns nothing; its label is a clock and the time left (45 s on Pan up to 8 minutes
  on Zeus, half with 2x Growth; stored lambs don't grow). It grows bigger as it goes, and at 100% its wool pops on and
  it takes its real size, Titan included, with a notice for every one ("Your lamb grew up: Epic Toadstool Sheep,
  GIANT!", louder the rarer or bigger). The Sheepdex finds its family then.
- **Selling a lamb** (Sell Stall): two minutes of what it will really earn grown, its price shown as "?" until it's sold.
- **Equip Best** ranks a lamb by what it's likely worth from what shows (its god, fleece, weight and rank), the same
  for every family of its herd, so a growing lamb keeps its place in the pen without giving its family away.

## Not built
Player plot raiding, trading, breeding, rebirth, god attacks, mutations beyond the fleece, gifting store items.
These are just not built yet, not ruled out: build them if the user asks.
