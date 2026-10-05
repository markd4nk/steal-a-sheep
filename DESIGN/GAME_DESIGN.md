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
carry it into your pen and put it down wherever you like -> it lives there, roaming and grazing, earning and growing ->
upgrade.

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
- Climb speed checks, tier signs, slide hits and knockback: `MountainService`; uphill speed, client slide, steering, braking: `MovementController`.
- Flock, pen capacity, income, growth, offline credit, Sheepdex rewards, Equip Best, locks, selling, merging:
  `FlockService`; the sheep living in the pen and their strolls: `FlockService/Pens` (+ `Utils/Wander`); walking,
  hopping in, grazing and faces on each device: `AnimController` (+ `Utils/SheepClips`).
- Plots (the map's five), the pen box, where a sheep may stand or walk, stair walkers: `PlotService`.
- Leaderboards on the map's four boards (This Server, Top Income, Most Steals, Climbing): `LeaderboardService`.
- Free gift for liking and favoriting the game (Climbing and cash, once): `GiftService`, `Screens/Gift`.
- Every formula: `src/shared/Utils/Economy.luau`; tiers and gods: `src/shared/Config/Olympus.luau`.

## The map
Thirty gods (the user, 2026-10-05: "build out 25 total ... based on the top Olympus gods", then a list of thirty with
"map parts for all of these gods"; Zeus on the new top). The commissioned map is one corridor climbing east (+X) from
the plots in seven themed stages of rising grade (2, 7, 12, 17, 22, 29, 31 degrees) holding tiers 1-12, two or three on
the long stages, gods ordered to fit each stage's theme. Above its old summit, High Olympus (`tools/UpperMountain.luau`)
carries the corridor on with one stretch a god, built from the map's own pieces, the grade rising a degree or so a god
from 32 to 52 (the user: no steeper than about 60, gradual but noticeable; 52 at the top kept), up to Zeus's throne
plaza. The climb is all on foot. High Olympus is sparse for now: the user will add obstacles to it later.

| Tier | God | Stage | Family (Shear a Sheep breed) |
| --- | --- | --- | --- |
| 1 | Demeter | meadow | Meadow Sheep (Scarecrow Sheep) |
| 2 | Dionysus | bamboo | Grape Sheep (purple Ringlets + leaf) |
| 3 | Artemis | snow | Moon Sheep (Moon Sheep, silver) |
| 4 | Hephaestus | lava | Ember Sheep (Lava Sheep) |
| 5 | Ares | lava | War Sheep (red Racka + helmet) |
| 6 | Aphrodite | rose garden | Rose Sheep (Cotton Candy Sheep) |
| 7 | Apollo | rose garden | Sun Sheep (Solar System Sheep) |
| 8 | Athena | marble temple | Laurel Sheep (white Merino + wreath) |
| 9 | Poseidon | temple aqueduct | Tide Sheep (Ocean Sheep) |
| 10 | Hermes | cloud path | Wingfoot Sheep (Cloud Sheep + ankle wings) |
| 11 | Hera | cloud path | Crown Sheep (Royal Sheep) |
| 12 | Aeolus | old summit's peaks | Gale Sheep (Frost Sheep) |
| 13 | Iris | Rainbow Bridge | Prism Sheep (rainbow puffs) |
| 14 | Pan | Wild Grove | Wild Sheep (Moss Sheep + horns) |
| 15 | Hebe | Ambrosia Orchard | Ambrosia Sheep (Cupcake Sheep, honey) |
| 16 | Eros | Heart Garden | Cupid Sheep (pink Cloud wool + back wings) |
| 17 | Tyche | Fortune Terraces | Fortune Sheep (Pirate Sheep) |
| 18 | Asclepius | Healing Springs | Potion Sheep (Slime Sheep) |
| 19 | Eris | Discord Rift | Chaos Sheep (Glitch Sheep) |
| 20 | Hecate | Torchlit Crossroads | Spirit Sheep (Ghost Sheep) |
| 21 | Hypnos | Poppy Fields | Slumber Sheep (Dream Sheep) |
| 22 | Morpheus | Dream Steps | Starlit Sheep (Galaxy Sheep) |
| 23 | Phobos | Fear Moon | Fright Sheep (Wolf in Sheep's Clothing) |
| 24 | Deimos | Dread Moon | Dread Sheep (Black Hole Sheep) |
| 25 | Thanatos | Asphodel Meadow | Bone Sheep (Skeleton Sheep) |
| 26 | Nemesis | Reckoning Ridge | Avenger Sheep (Mecha Sheep) |
| 27 | Themis | Court of Justice | Justice Sheep (white Ringlets + blindfold) |
| 28 | Nike | Victory Stair | Victory Sheep (gold wool + back wings) |
| 29 | Hestia | Eternal Hearth | Hearth Sheep (orange Ringlets + flame) |
| 30 | Zeus | Throne of Olympus | Thunder Sheep (Storm Sheep) |

## Economy (as built)
Cash, the only currency (code calls it `Coins`), comes from sheep in the pen, first-discovery rewards, selling and the free gift, and
buys stair walker levels, pen space and trails. No Robux products.

## Climbing (the user, 2026-10-05)
Like Steal an Egg: train one stat, **Climbing** (the stair walker; saved as `ClimbPower`), to get up the mountain
and to outrun its gods. No walls: every tier is open to everyone.

**Your ratio on a tier = Climbing / (its sign number x the carried lamb's weight)** (weight 1 empty-handed).

- **Your speed**: the ratio itself below 1 (a quarter of the sign, a quarter of normal speed; never under a 1 stud/s
  crawl), then +1x normal speed for every 4x above it, no cap on the mountain. Signs grow about 4x a tier, so every
  tier above you is a quarter speed (two above is a crawl) and every tier you've outgrown is +1x.
- **Walking and climbing** = 18 studs/s x your speed. Slowed, only the uphill part is held down. Tier 1 and the safe
  zone (plots, hub) never go below normal; walking in the safe zone stops at 7x.
- **Sliding away** = the god's speed x your speed (at least walking speed), set when the slide starts and kept all the
  way down. It reaches it in about 2 seconds.
- **Gods**: one set speed each for the whole chase, 0.8 x its tier's `SlideSpeed` (19 at tier 1 up to 48 at tier 30),
  never walking, never scaled by the thief.
- **So**: at the sign's number the lightest lamb's thief matches the god and the head start gets them away; an
  average lamb leaves about 95% (caught near the bottom); heavy ones need more.

## Lamb weight (the user, 2026-10-05)
Hidden: no words or numbers on screen, players feel it. A smooth range from 1 (lightest) up, saved with the sheep
(`Weight`). Wild lambs: 1-1.1 mostly, 1.1-1.5 for one in twenty. Heavier lambs are slower to carry and tend to grow
bigger (size odds shift with weight; Titan only from the Merge Shrine's huge rolls), and look a little bigger as lambs.

## Not built
Player plot raiding, trading, breeding, rebirth, god attacks, mutations beyond the fleece rarity, premium products.
These are just not built yet, not ruled out: build them if the user asks.
