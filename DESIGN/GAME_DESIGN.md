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
deliver -> earn and grow -> upgrade.

## Systems
- Climb Power, stair walker, trails: `TrainingService`, `ShopService`.
- Wild lambs, theft, carrying, delivery, failure rules, tutorial lamb: `WildService` (+ `SheepService` for models).
- Gods and pursuit: `GodService` (one state machine, primitive block rigs).
- Climb gates, slide hits and knockback: `MountainService`; client slide, steering, braking: `MovementController`.
- Flock, pens, income, growth, offline credit, Sheepdex rewards, Equip Best, locks, selling, merging: `FlockService`.
- Plots (the map's five), pen pads, delivery pads, stair walkers: `PlotService`.
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

| Tier | God | Where | Family (Shear a Sheep breed) |
| --- | --- | --- | --- |
| 1 | Pan | meadow: Shepherd's Meadow | Wild Sheep (Moss Sheep + horns) |
| 2 | Tyche | bamboo: Fortune Terraces | Fortune Sheep (Pirate Sheep) |
| 3 | Hecate | snow: Moonlit Crossroads | Spirit Sheep (Ghost Sheep) |
| 4 | Phobos | lava: Fear Ledge | Fright Sheep (Wolf in Sheep's Clothing) |
| 5 | Eris | lava: Discord Rift | Chaos Sheep (Glitch Sheep) |
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
Coins (equipped sheep, first-discovery rewards, selling) buy stair walker levels, pen slots and trails. Climb Power
(stair walker) opens tiers and reduces carrying slowdown. No Robux products.

## Not built
Player plot raiding, trading, breeding, rebirth, god attacks, mutations beyond the fleece rarity, premium products.
These are just not built yet, not ruled out: build them if the user asks.
