# Game design

Owned by the user. Agents read it and ask before changing it. The full design is
[`Steal-a-Sheep-Game-Design-Document-Draft.md`](../Steal-a-Sheep-Game-Design-Document-Draft.md) at the repo root
(draft v0.3, 2026-10-05); this page is its short form and how it maps onto the commissioned map.

## Pitch
Train on a stair walker, climb Olympus, steal a god's lamb, hold it over your head and slide downhill to escape
(knocking back climbers on the way), then grow your flock into the biggest earners in your pen.

## Core loop
Train on the stair walker -> climb a steeper route -> steal a lamb -> slide home with the god behind you -> deliver ->
earn and grow -> upgrade. Each tier has three stages: reach its pasture, escape with Light lambs, then reliably bring
Heavy ones home.

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
"map parts for all of these gods"; Zeus on the new top). The commissioned map is one corridor climbing east (+X) from
the plots in seven themed stages of rising grade (2, 7, 12, 17, 22, 29, 31 degrees) holding tiers 1-12, two or three on
the long stages, gods ordered to fit each stage's theme. Above its old summit, High Olympus (`tools/UpperMountain.luau`)
carries the corridor on with one stretch a god, built from the map's own pieces, the grade rising a degree or so a god
from 32 to 52 (the user: no steeper than about 60, a gradual climb that's noticeable), up to Zeus's throne plaza. Every
tier keeps the design doc's numbers in order, and tiers 13-30 carry its curves on (DECISIONS.md, To review).

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

## Economy
Coins (equipped sheep, first-discovery rewards, selling) buy stair walker levels, pen slots and trails. Climb Power
(stair walker) opens tiers and reduces carrying slowdown. No Robux products in the MVP.

## Out of scope
Per the design doc: player plot raiding, trading, breeding, rebirth, bespoke god attacks, mutations beyond the
fleece rarity, premium products.
