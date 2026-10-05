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
The commissioned map is one corridor climbing east (+X) from the plots in seven themed stages of rising grade (2, 7,
12, 17, 22, 29, 31 degrees). The twelve tiers are spread over them, two or three on the long stages, and the gods are
ordered to fit each stage's theme; every tier keeps the design doc's numbers in order (DECISIONS.md, To review).

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

## Economy
Coins (equipped sheep, first-discovery rewards, selling) buy stair walker levels, pen slots and trails. Climb Power
(stair walker) opens tiers and reduces carrying slowdown. No Robux products in the MVP.

## Out of scope
Per the design doc: player plot raiding, trading, breeding, rebirth, bespoke god attacks, mutations beyond the
fleece rarity, premium products.
