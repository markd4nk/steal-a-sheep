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
- **High Olympus's grade rises gradually to 52 degrees at Zeus** (the user, 2026-10-05: no steeper than about 60,
  noticeable; then "keep it that").
- **High Olympus's stretches are 275 studs along the floor** (the user, 2026-10-05: at 210 they felt shorter than the
  first levels, about 250, so a bit longer than those). 169-233 across the ground, so the steep ones still look
  shorter than they climb.
- **No shortcut up**: the climb stays on foot, however long (the user turned down a lift to the highest open gate,
  2026-10-05).
- **Obstacles on the higher levels come later, from the user** (2026-10-05: High Olympus is "very barren" now). Until
  then don't thin or fill the slide lanes, old stages included.

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
- **Tutorial**: a new player's private, Light, ordinary tier 1 lamb (Pan's) sits in the meadow (others can't take it); its
  run is protected from slide hits; any first delivery gives +60 coins and +25 Climb Power and removes it.
- **Sounds**: Shear a Sheep's cues: the danger music during a chase, WolfScare on the alert, IntroWhip on a slide,
  Yelp/Scuffle on hits, Coin/DexReward/Upgrade/Reveal on rewards.
