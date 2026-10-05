# Decisions

*Confirmed rules* are the user's calls: keep them unless the user says otherwise, and don't ask again. *To review*
holds calls agents made that players would notice (rules, timings, ranges, prices, rewards, what the UI shows),
waiting for the user: add yours at the top, and move an item to *Confirmed rules* (or delete it) once the user has
confirmed or reversed it.

## Confirmed rules

- From the design doc (user confirmed directions): climb uphill, slide downhill carrying a sheep; aimed slides knock back
  uphill walkers with no damage or sheep transfer; the stair walker replaces the treadmill and Climb Power both opens
  steeper slopes and reduces carrying slowdown; reach -> Light -> Heavy stages per tier; reuse Shear a Sheep's UI and
  assets wherever possible; the Sheepdex is a standard MVP collection book.
- Keep new things MVP primitive; reuse Shear a Sheep's UI and assets (the user, 2026-10-05).

## To review

Calls made while building the MVP on 2026-10-05:

- **God order fits the map's stage themes**: Demeter (meadow), Dionysus (bamboo), Artemis (snow), Hephaestus and Ares
  (lava), Aphrodite and Apollo (rose garden), Athena and Poseidon (marble temple and aqueduct), Hermes, Hera and Zeus
  (cloud path to the summit). The doc ordered Hermes 3rd and Artemis 7th, Aphrodite 4th and Hephaestus 5th; each tier
  keeps the doc's numbers (reach, income). Swapping back is a reorder of rows in `Config/Olympus`.
- **Twelve tiers on seven stages**: the long stages hold two or three tiers (stage 4: 2, stage 5: 2, stage 6: 2,
  stage 7: 3). Tier boundaries are x positions on the ramp (`Olympus.Tiers[].XStart`).
- **Families are Shear a Sheep breeds**: Scarecrow, Moon (silver), Lava, Cotton Candy, Solar System, Ocean, Cloud,
  Royal and Storm Sheep as they are; Grape (purple Ringlets + a leaf), War (red Racka + a helmet) and Laurel (white
  Merino + a wreath) are plain breeds with a primitive extra; the Wingfoot (Cloud) Sheep has small neon ankle wings.
- **Fleece rarity looks**: Rare sheep sparkle blue; Royal sheep have gold wool (Shear a Sheep's Gold paint) and sparkle.
- **Sizes on screen**: every sheep's base size is 1.6x the rig; lambs are 0.6 / 0.7 / 0.8 of it by burden (a clue to
  the burden) and grow towards 0.85 before the reveal; adults are 1 / 1.35 / 1.7 by size.
- **Gates**: a tinted force-field wall at the foot of each tier from 2 up, with "<God>'s <Area> / Climb Power N";
  solid for a player until that tier is open to them. Anyone found past a closed one is put back 10 studs below it
  ("Train to climb this slope" or "Deliver a lamb from <God> first"), which also ends a theft.
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

- Thin the corridor's decor (trees, rocks, arches) on a few slide lanes, or keep it as an obstacle course?
- Keep the theme-fitted god order, or the design doc's order?
