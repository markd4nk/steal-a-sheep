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
The commissioned map is one corridor climbing east (+X) from the plots in seven themed stages of rising grade (2, 7,
12, 17, 22, 29, 31 degrees), with twelve tiers spread over them.

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
| 12 | Zeus | summit | Thunder Sheep (Storm Sheep) |

## Economy (as built)
Coins (equipped sheep, first-discovery rewards, selling) buy stair walker levels, pen slots and trails. Climb Power
(stair walker) opens tiers and reduces carrying slowdown. No Robux products.

## Not built
Player plot raiding, trading, breeding, rebirth, god attacks, mutations beyond the fleece rarity, premium products.
These are just not built yet, not ruled out: build them if the user asks.
