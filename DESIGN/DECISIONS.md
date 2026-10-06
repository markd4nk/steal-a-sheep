# Decisions

*Confirmed rules* are the user's calls: keep them unless the user says otherwise, and don't ask again. *To review*
holds calls agents made that players would notice (rules, timings, ranges, prices, rewards, what the UI shows),
waiting for the user: add yours at the top, and move an item to *Confirmed rules* (or delete it) once the user has
confirmed or reversed it.

## Confirmed rules

- **The chase's sounds (2026-10-06)**: Steal an Egg's terror with human sounds, since the guardians are gods. The
  alarm is option C, APM "Electronic Alarms (D)" (over A, the buzzier Red Alert, and the mock-up's "heavy metal"
  one). Every voice is one person in one take, never two sounds layered ("it feels like it's layered rather than just
  one person"), and a laugh is one continuous laugh. The goddesses' voices are slowed deeper ("they're still huge
  beings"). Kept from the mock-up: the roar, the chase, "right behind you" and the god's laugh. From the voice board
  every take but M1 is in, said at random for "a little bit more variety every time, different voice lines": roars
  M2-M4 and F1-F3, laughs ML1-ML3 and FL1-FL3. A catch sound of each god's own comes later.
- **The base design doc is the starting point; the user refines from here (2026-10-05).** The first build followed
  `DESIGN/BASE_DESIGN_DOC.md`; the user will rework a lot of it as they go. A request that changes what was built is
  the new rule: don't object that it goes against the base doc, the first build or the calls below; make it and update
  the docs.
- The first build reused Shear a Sheep's UI and assets and kept new things primitive (the user, 2026-10-05). That was
  how the MVP was made, not a limit on later changes.
- **The map's studs on every sheep (2026-10-05)**: the user picked mock-up B, the map's stud material at half its
  size over the wool (face, ears and legs smooth), "build it on every sheep", and glowing studs for glowing wool.
- **Thirty gods, Zeus on top (2026-10-05)**: the user's list of thirty, a map part for each above the old summit
  (High Olympus), each god's section grouped, the new parts indistinguishable from the commissioned map (its own
  pieces, studs and textures).
- **Gods climb in mythological rank, Zeus's family at the top (2026-10-05)**: the user, "the Zeus family should end up
  at the top". The minor gods on the commissioned map, each on a stage that suits them; on High Olympus five more, then
  the thirteen Olympians youngest first: Dionysus, Hermes, Hephaestus, Ares, Aphrodite, Artemis, Apollo, Athena,
  Demeter, Hestia, Poseidon, Hera, Zeus. The user kept that order of 18-30 ("if in Greek mythology they don't have a
  hierarchy, then it doesn't really matter").
- **The gods are Roblox avatars (2026-10-05)**: after Roblox's mesh generator and a Blender model (`art/gods/`, kept
  as an option), the user asked for "a little cuter version that fits the Roblox niche" and chose R15 avatars dressed
  from the catalog: the "Classic Style Angry Face" head, a head bigger than the body's scale (the cute look), the
  gods' 9.6-stud height, Roblox's own idle, walk and run, and their symbols as glowing block props (Zeus's neon bolt
  raised). "We don't have to do the fully clothed method anymore": bare chests are fine.
- **Gods lunge and belly-slide (asked 2026-10-05, built 2026-10-06)**: when you steal a god's sheep, the god lunges at
  you face first, then glides on its stomach like a penguin, steering towards you. From the mock-up video the user
  kept the lunge "only at the start" (no second dive at the catch) and the dive carrying the god a little faster for a
  third of a second ("that's fine").
- **The slide is a surf (2026-10-06)**: of three mock-ups (A Penguin belly slide, B Surf, C Sled), the user: "I like
  the surf". It replaces Roblox's sit for R15 avatars.
- **High Olympus's grade rises gradually to 52 degrees at Zeus** (the user, 2026-10-05: no steeper than about 60,
  noticeable; then "keep it that").
- **Climbing is one stat, no walls (2026-10-05)**: speed and Climb Power are one thing, "Climbing". Every tier is
  open; steeper tiers need more and more Climbing to climb at a useful pace. Too little gives a very slow crawl, never
  a slip back down, so it's technically possible but nobody wants to, and a thief that weak is caught carrying the lamb
  down. No delivery lock between tiers. No god lunge.
- **Momentum on the way down, the god too (2026-10-06)**: the user found the slide from the top "very, very slow all
  the way down" and boring; wanted it to get faster going down "so it feels like momentum", the god speeding up as
  well so a thief who isn't at the tier's level still can't get away just by reaching the lower tiers; one bump
  must bring the god closer, never be an instant loss, but the god mustn't drop back to its normal speed either ("it
  can maybe drop a little bit ... but not a full reset", or a bump means nothing); recovery from a bump almost
  instant, never lying on the floor for two seconds; and the slide stops dead at the safety line ("they begin
  walking and it no longer carries them into random pens"). Napkin math, as few numbers as possible.
- **Your speed vs its speed, like Steal an Egg (2026-10-05)**: each god has its set speed (never slower in lower
  stretches, never a walking speed; since 2026-10-06 boosted by its thief's momentum, above); the thief's escape speed
  comes from Climbing and is where a slide's speed starts. Checked against Steal an Egg: each zone has its own
  guardian, faster higher up, never scaled to the player; you escape with enough Speed over the zone's minimum.
- **One speed rule (2026-10-05)**: your speed on a tier comes from Climbing / (its sign number x the lamb's weight),
  as few numbers as possible. No cap on the mountain: more Climbing keeps making you faster. Walking in the safe zone
  (the plots and hub) is capped at 7x normal; tier 1 and the safe zone never go below normal. The sign's number is
  just enough for the lightest lamb on that tier; an average lamb leaves about 95% of the god's speed there.
- **Caught thieves are punched three tiers down (2026-10-05)**, not sent home, and drop the lamb where they were caught.
  Walker upgrades are properly expensive (about ten minutes of income each). Most escapes should feel close: tune
  towards Climbing sitting just over the next sign, not far past it.
- **Hidden lamb weight (2026-10-05)**: no Light/Stout/Heavy words and no numbers on screen: players feel it. A smooth
  range, not three kinds. Saved with the sheep; heavier lambs tend to grow bigger, but a light one can still grow
  large, just less likely.
- **High Olympus's stretches are 275 studs along the floor** (the user, 2026-10-05: at 210 they felt shorter than the
  first levels, about 250, so a bit longer than those). 169-233 across the ground, so the steep ones still look
  shorter than they climb.
- **No shortcut up**: the climb stays on foot, however long (the user turned down a lift to the highest open gate,
  2026-10-05).
- **High Olympus has obstacles, terrain and moving scenery (the user, 2026-10-06)**: "feel like it's still alive and
  not just an empty path that needs to go up"; built from the existing structures in their style, each god's own
  things. The first mock-up's density less 20%; everything standing on the mountain tilted with the slope; scenery
  moving ("cogs turning, islands bopping ... much more immersive"); a winding path up each stretch that obstacles keep
  off.
- **Pulling back stops a slide dead; no auto-jump up the mountain (the user, 2026-10-06)**: "if they're sliding down,
  all they should be able to do is just move the other direction and just instantly stop" (momentum made it
  impossible to break out); running up "should just be like they're running normally up", not hopping. Pulling back
  stops a thief carrying a lamb too, even mid-chase (the user: "leave it as is").
- **Only ramps are solid on the descent (the user, 2026-10-06)**: "make the obstacles not have any sort of collision
  ... only the things that function as ramps should ... have collision", because dodging at a slide's speed is too
  hard; the mounds of the earlier levels that you can jump off, jump over or use for speed are the kind to keep.
- **The stair walker is a real StairMaster the player climbs (the user, 2026-10-05)**: level 1 looks like a plain gym
  machine and each upgrade looks better, ending in the Olympus look (marble and gold); the player snaps onto it like a
  treadmill and climbs the moving steps; the steps get faster with each machine level.
- **Its first five looks are the mock-up's** (Starter, Sport, Pro, Turbo, Champion), "stick with the five for a second";
  the level floats over the machine; the machine stands outside the pen, very close to it, like Steal an Egg's; its
  upgrade sign beside it upgrades it directly, for cash or Robux (the user, 2026-10-05).
- **The stair walker's spot by the gate is right** (the user, 2026-10-05). Its Robux prices are the store's walker
  ladder (below).
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
  Only the favorite can register (no game can see a like). The like step is gone (Roblox's review policy forbids
  rewarding a thumbs up; the user OK'd it, 2026-10-06), and **Claim still needs the favorite**: "that's something that
  actually is allowed because some games do it" (the user, 2026-10-06). Don't raise it again.
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
- **Six sheep a tier (the user, 2026-10-05)**: every god has six families, **Common, Uncommon, Rare, Epic, Legendary,
  Mythic**, their own family as the Common; the 150 new looks in the lineup (DESIGN/HISTORY.md) are OK'd ("that's
  good"). A wild lamb is Common 50%, Uncommon 25%, Rare 13%, Epic 7%, Legendary 4%, Mythic 1%; they earn x1, x1.5,
  x2.5, x4, x8, x15. The fleeces are renamed **Plain / Shiny / Royal** and roll on top of any family as before.

- **The Robux store (the user, 2026-10-05, over five mock-ups)**: Shear a Sheep's one scrolling store in its purple,
  with square studs and big art filling every card, the art growing with the pack (one, a pair, a pile, a sack, a
  chest, a gold chest). Each picture is one outlined icon: overlapping stickers "looked sloppy". The section tabs
  (Sheep, Passes, Speed, Climb, Cash) stand outside the window on its right, tight together and close to it; no
  scrollbar inside. The approved mock-up is `steal-a-sheep-store-mockup-e-pc.png` / `-e-full.png` in T3 Code's
  attachments folder.
- **Hermes' winged sandal is the climbing icon everywhere**, the HUD's too, with white wings; gold wings only on 2x
  Speed (the user, 2026-10-05, from a picture of a talaria).
- **Store prices**: Golden Fleece 799 (earns 10x your best sheep) and Kronos Sheep 349 (3x), Robux only; passes 2x Money
  249 and 2x Growth 149; Climbing packs +150K / 1M / 10M / 100M / 1B / 10B at 49 / 99 / 199 / 399 / 799 / 1,499; Cash
  packs 24K / 200K / 800K / 4M / 8M at 45 / 149 / 299 / 499 / 720 (the user set 24K, 8M and their prices and the first
  four Climbing amounts; the rest were proposed and accepted).
- **2x Speed doubles Climbing and can be bought again, each buy three times the last**: 3, 9, 27, 81, 243, 729, 2,187,
  then sold out.
- **The stair walker's next level for Robux, beside its cash price**: 19 for the first level, 20% more each level
  (3,132 for the last).
- **The store as built is OK (the user, 2026-10-05)**, with the STORE button on the right edge of the screen; merged.
  Creator Hub's products and passes come later.
- **Daily gifts (2026-10-05)**: a check-in every day, the prizes better each day, a super rare sheep on Day 7; the
  user picked layout B (Days 1-6 in a grid, Day 7 big beside Claim), the Pegasus Sheep with gold-tipped wings and a
  halo (the third look), and a missed day waits where it was (no reset). "Just this week for now": the same week
  repeats after Day 7 until later weeks are designed. Then, after playing it: the prize amounts are good, and so is the
  phone layout (the HUD's left column wrapping into more columns on a short screen).
- **The daily prizes** (the user's OK, 2026-10-05): Day 1 cash 3 minutes of the pen's income (at least 250), Day 2
  Climbing 1 minute of the stair walker (at least 150), Day 3 cash 10 minutes (800), Day 4 a Rare lamb from the
  highest god stolen from, Day 5 Climbing 3 minutes (450), Day 6 cash 30 minutes (2,500), Day 7 the Pegasus Sheep.

- **One message per moment, no always-on objective (the user, 2026-10-05, on the UI audit)**: the objective line
  "doesn't need to be a thing at all"; "train to climb as needed, put your sheep to work as needed". Not wanted: "Hold
  E" (and holding at all: a click or E on a computer, a tap on a phone, with a proper UI), "Claim its reward there",
  "Climbing gets you up steeper slopes", "take it home" and the escape notice, "Put it down where you like", "Yours has
  your name over the gate", the grow-up celebration; "you get the gist".
- **No hand-holding after onboarding (the user, 2026-10-06)**: "I don't want to tell the player anything that they
  need to do besides just playing the game. After the onboarding, it should just be their own experience. They can
  figure out how to do it." So no "<God>'s <Area> is in reach!", and no hint, tip or nudge that tells a player what to
  do once the onboarding is over. Onboarding itself is the onboarding session's (`t3code/simplify-onboarding-guidance`).
  On the audit's list the user said: cut the menu tips ("Bigger sheep in, more luck", "Tap the sheep to sell", the
  gift's "Tap here, or the star"; the Merge Shrine's empty list reads "No sheep to merge yet", or "Opens after 3
  deliveries"); refusals say the fact without the advice ("Your flock is full", "Your hands are full", "Not in your
  pen", "Too far from the altar", "Not ready yet", "It's locked", "Not found yet", "Needs the Dust Trail", "Not
  favorited yet"); **keep** the HUD's glows and red badges (GIFT, DAILY, SHEEPDEX) and the daily gift opening itself
  once a session; **keep** the rare-lamb notice ("A Royal ... appeared in Zeus's pasture!").
- **The stair walker (the user, 2026-10-06)**: no "Next" line or bar to the next god while training; "all it needs to
  indicate is that you're gaining plus speed, whatever you're making per second ... above the player". And "the
  player should be moving on the treadmill way faster ... at higher levels and higher speeds." Then, on the video
  mock-up: like other games, numbers pop off the player, more of them the faster you train ("level one, if it's two
  per second ... plus one, plus one in one second ... at level 30, I want like 10 things to say plus ... 2.5T"):
  "much better now". One decimal ("+2.5T"), the shoe stays on each pop, and the machine's floating level hides while
  you climb.

- **Onboarding is a trail on the floor to a place (the user, 2026-10-06)**: too much said "steal this god's sheep" and
  pointed at the sheep; instead chevrons on the floor "just like in Shear a Sheep" leading "to the place where the
  player has to actually go", only for the first lamb, "very simple ... I don't want to hand-hold them the entire
  time", modelled on Steal an Egg's. The words, the floating arrow with its distance, Train to climb and Put your sheep
  to work are gone (GAME_DESIGN.md, *Onboarding*).
- **No card for the lamb being carried (the user, 2026-10-06)**: "remove the thing that says wild lamb return. That is
  never necessary". The card at the bottom (the lamb's picture, its name, Return) is gone, and with it giving up a run:
  a lamb only goes back when its god catches the thief, or they fall, reset or leave.

- **The overnight work as summarized, merged and shipped (the user, 2026-10-06)**: "Yes, it looks good. You can merge
  it... just ship it. It still needs to stay private though." So version 8 went out with the audience left Private:
  publishing a new version is fine on their word, opening the game to players isn't yet. The overnight calls below
  (publish prep, Settings, studs) are confirmed with it; the product icons' OK came in the studs session's thread.
- **The game page keeps Roblox's default icon and thumbnails for now** (the user, 2026-10-06: "I wouldn't change any of
  the icons just yet"); the mock-ups in T3 Code's attachments (`gamepage_*`) wait.
- **Creator Hub (the user, 2026-10-06)**: Fear answered Mild in the questionnaire ("set it to mild"); **no genre yet**
  ("don't tick the genre yet"). VR stays ticked (not raised).

Calls made overnight preparing the publish (2026-10-05, branch `t3code/prepare-game-for-publishing`; confirmed
2026-10-06 with the overnight work):

- **Grow-ups**: Giant and Titan get one notice ("Fortune Sheep grew up GIANT!") with their fanfare; Standard and
  Large only update the label over the sheep.
- **Menus that open themselves**: none in a player's first session; after that the daily gifts once a session
  (45 s after a gift waits); the free gift never (its button glows).
- **The first delivery's bonus** (+60 cash, +25 Climbing) shows on the counters only; "That's not your plot!" once
  each time a thief walks into another plot.
- **Prompts**: the menus' studded button with the action's verb only (Steal, Put down, Pick up, Shop, Sell, Merge,
  Upgrade); green for actions, blue for the stalls, purple for the walker's Robux upgrade; on a phone a bigger button
  (52 pt) with no key; on a computer the key in a white cap beside it; prices and the shrine lamb's name in a small
  line above; prompts on one spot side by side; the Put down button over the carried lamb.
- **Wording**: the shrine's landing says SHINY! for a Shiny fleece; the walker row "8 → 12 Climbing/s"; trails
  "1.5x training"; Merge's button "Merge" (greyed until three picks); gods' nameplates show the name only.
- **Merge odds**: exact percentages, long ones to five significant digits; "Size and fleece roll separately. Odds
  are rounded, so they may not add up to exactly 100%." under the odds.
- **Names**: Eris's area is Chaos Rift and her Mythic shows as Mayhem Sheep (was "Discord"; the saved id is
  unchanged).
- **Old price steps**: a 2x Speed step the player is past pays its Robux price in Climbing at the smallest Climbing
  pack's rate (150K for 49); a walker level they're past pays that level's cash price.
- **Signs in studs**: the plots' name signs 24 x 6.8, the stalls' names 15 x 3.5, the walkers' level tags 6.3 x 2.35,
  the same size as before at their usual distance and smaller further away.
- **Layout fixes**: on a computer or a tablet the Climbing and cash counters stand left of Roblox's player list (it
  opens over the top right by default there); menus that open by themselves wait for the welcome-back card and 4 s after it; the HUD's STORE button
  hides while a menu is open.
- **Phone layouts**: the Flock menu's sheep picture shrinks so Store and Lock stay inside; the free gift's step shows
  its picture and words in a row; the Merge button stands under the shrine's list where the odds and the button
  don't fit one above the other (the odds keep the left side, shrinking only if they must).

Calls in the Settings menu (2026-10-05; the mock-up's A, agreed overnight with the coordinator; confirmed 2026-10-06
with the overnight work):

- **The gear sits in Roblox's top bar**, beside its buttons, round and dark like them; it's there from the first
  second, before the HUD's menu pictures show. The other place mocked up: after the cash pill.
- **Music and Sound effects in four steps** each (- and +, the steps lit up, greyed at either end), full by default;
  the meadow's ambience follows Music. The other way mocked up: On/Off switches only.
- **Reduce motion** is in (off by default; the menus' bounces and shakes already honour it). **Low graphics** and
  **Invite** are left out: nothing would use the first, and the HUD's friend tile does the second.
- Off is red and On green, as the mock-up's switches; each change saves at once.

Calls in the store's product and pass icons (2026-10-05; Mark, 2026-10-06: "good to upload"):

- **The seven 2x Speed icons are the same** (the card doesn't number the buys); the 29 walker icons show the card's
  level row for their step ("Lv 1 > 2" to "Lv 29 > 30").
- **No chips** ("ROBUX ONLY", "CHEAP!", "BEST VALUE"): only the words over or beside each card's picture.
- **The two Robux sheep have the store art's ink outline** (the Golden Fleece vanished into its gold card without it).
  Mark (2026-10-06): show the studs if they're visible; they are, so the sheep are Studio captures of the game's own.

Calls in the studs on every sheep (2026-10-05; merged and shipped in version 8, 2026-10-06):

- **What counts as wool**: the puffs (and anything hanging off them), the tail, and add-on pieces tinted as wool.
  Horns, hats, halos, wings and other extras stay smooth, as do the face, ears, legs and body.
- **Stud size**: half a stud a tile on every sheep, so bigger sheep (Giant, Titan) carry more studs, like bigger
  blocks on the map; lambs carry fewer.
- **Glass wool** (4 families) becomes see-through studded plastic at 25% transparency: Roblox draws no studs on glass,
  and the glassy shine goes. **Glowing wool** (10 families) glows at strength 1.6: a little less bright than Neon.
- **Royal (gold) fleeces and silver paints** take metal studs; on glowing or glass families the Royal gold replaces the
  glow or the see-through look, as the gold paint already did.
- Any other wool material keeps its look without studs (none uses one today).

- **Mystery lambs (the user, 2026-10-06; built on `t3code/mystery-lamb-mockup`)**: a lamb doesn't show what it will
  grow into. Wild lambs have nothing over them: no card, no name ("it should just be unnamed"). Lambs are bare white
  lambs (no wool, horn buds) marked in the colour of the sheep they grow into, the rarity hint subtle: mock-up **D**,
  one spot per step of rarity (A's bolder ladder was "that clear": out; C and E not picked). Weight shows as size,
  heavier lambs bigger and rounder ("that's fine"). The family, rarity and size show only when it grows up: it grows
  bigger in the pen until 100%, then its wool appears and it takes its real size, Titan included. Growing lambs earn
  nothing; a small timer shows the time left. A lamb sells for about two minutes of what it will really earn. Every
  grow-up gets a notice saying what it became ("keep it"), and every lamb is unnamed until grown, even a merged or gift
  lamb whose family is known ("sure"). How rare-lamb announcements work is for a later session; the user wants them
  simpler ("a rare lamb or a mythic lamb").
- **No words during a chase (the user, 2026-10-06)**: no "Pan wants their sheep back!" banner, with "Slide home!", the
  floating arrow and its distance, and the carried lamb's card ("Lamb", Return) gone too (the onboarding trail's
  removals); the chase's music and its scare sound stay.

## To review

Calls in the slide stop and climbing without auto-jump (2026-10-06):

- **"Pulling back" means a move whose uphill share is over 0.35**, as the old brake was: straight back, or back and to a
  side; steering sideways doesn't stop. The slide ends that frame, its speed along the ground zeroed, and the player
  walks from there; holding back never starts a new slide.
- **Auto-jump is off only on the mountain** (from the safety line up): phones still auto-jump at the plots and the hub,
  where fences and steps want it. Mobile players keep the jump button everywhere.

Calls in High Olympus's lanes and the ramps-only rule (2026-10-06; the user's own calls are under Confirmed rules):

- **The ramps-only rule covers the whole descent, tiers 1-30**: on the commissioned stages their trees, bamboo, small
  rocks, spires, arches, blossom trees, fences, the pavilion, lamps and the aqueduct's and temple's columns in the lane
  are passed through. Solid: the floors, terraces, stage 6 and 7's dunes, stage 4's pyramids (their faces lean into
  the lane's edges like banks) and the backdrop mountains. Easy to limit to High Olympus if wanted.
- **High Olympus's ramps are stage 7's dunes** (its own mesh), recoloured: a big one beside the path under the god's
  landmark (crest 11-13 studs over the floor) and two or three smaller ones at the lane's sides (7-11), gentle side
  uphill so a slide rides up and leaves the crest in a jump. Measured at about 160 studs/s: 0.7 s in the air, 11 studs
  over the crest, a clean landing. They keep off the path, the lamb and god spots and the gate.
- **Passed-through things are also left out of ground checks and the gods' line of sight** (CanQuery off), so they no
  longer give a thief cover; the dunes still do.
- **The stepped rock outcrops and knoll are gone**, replaced by the dunes.
- **Nothing solid within 10 studs of a wild lamb's spot or the god's**, nor in the first 30 studs of a stretch (its gate
  and sign) or its last 14.
- **The path**: swings 18 studs either side, one bend every 330 studs or so (gentle enough to follow at 100 studs/s,
  main's top slide speed); obstacles keep 11 studs from its centre line; 12 studs wide. Poseidon's is a stream and
  Hera's a royal carpet, the others a shade of the floor.
- **How many**: obstacles 10 at tier 13 rising to 14 at Zeus (12 to 18 less the user's 20%; a crowded stretch can
  come out one or two short), all scenery now; two smaller dunes a stretch up to tier 18, three above, plus the big one.
- **Which obstacles**: each god's own (HISTORY.md lists them).
- **Moving scenery is the player's own**: each device moves what's within 600 studs of its camera; Reduce motion holds
  it all still. Birds and bobbing things can't be touched.

Calls in the god lunge, belly glide and surf (2026-10-06, `Utils/BodyClips`, `GodController`, `SlideController`):

- **The lunge takes 0.84 s and the dive is 1.6x faster from 0.22 to 0.56 s in** (about 3 studs gained at tier 1), as
  in the mock-up the user saw. It plays on every new chase, including a god that turns from walking home straight to a
  new thief.
- **Getting up takes 0.62 s of the god's 1.6 s Taunt**, so its laugh shows for about a second (it was 1.6 s; the user:
  "the laugh is fine", another session is changing the laugh). When a thief escapes, it gets up the same way before
  walking home.
- **The glide's look**: flippers out about 26 degrees and flapping twice a 0.9 s stroke, chest and head up, feet up
  behind kicking, a lean into turns of a quarter of a degree per degree a second of turning (at most 22), lying along
  the slope. Zeus's raised bolt arm comes down while he glides.
- **The surf**: side on (78 degrees), crouched a quarter of the hips' height, carving +-8 degrees over 1.8 s, leaning a
  third of the way into the ramp's slope; empty hands out for balance, aimed by direction so T-pose avatars look the
  same. A carrier's arms and waist stay CarryController's. Seen by everyone near (200 studs). R6 avatars keep the sit.

Calls in the mystery lambs (2026-10-06, branch `t3code/mystery-lamb-mockup`):

- **The grow-up notice's words**: "Your lamb grew up: Epic Toadstool Sheep, GIANT!", the family's rarity named from
  Rare up, the size from Large up; sound louder for Epic+ or Giant+. No celebration (the user's earlier call).
- **Announcements name no family** already: a lamb's name is "Lamb", so they read "A Mythic Lamb appeared in Zeus's
  pasture!" (the user's simpler wording; anything more is the later session's).
- **A lamb's price shows as "?"** at the Sell Stall, and a pick with lambs totals "900 + ?"; the cash shows in the sold
  notice. Lambs sort after the priced sheep.
- **Equip Best ranks a lamb by its likely worth** (its god's base x the herd's average family multiplier x fleece x
  its weight's size odds x rank), not by its 0 income, so growing lambs aren't benched, and the same for every family
  of a herd so the order gives nothing away.
- **Shiny and Royal lambs keep their sparkle** (blue, gold) but not the gold paint.
- **Lamb cards** are Common's grey with no rarity chip; their number is the time left (clock icon), "Stored - not
  growing" when stored.
- **Sizes**: a lamb starts at 0.55 of an adult's rig (lightest) to 0.88 (the heaviest wild weight and up) and grows
  60% bigger by 100%; its body is 0.92 to 1.30 as wide.
- **The pen label** sits just over a lamb's back (it was at an adult's height) and reads like "0:42".
- **The Sheepdex finds a family when it grows up**, so Day 4's gift lamb now counts too.
- **The fleece pops on** piece by piece over about half a second with a burst of sparkles when a lamb grows up.
- **Delivery notice**: "Your lamb is home! Grows up in 0:45" (was the lamb's name and income).

Calls in the scarier steal and chase (2026-10-06; the user's own calls are under *Confirmed rules*; `art/chase/`,
GameConfig.Chase, Config/Sounds):

- **No repeats**: a god never says the take it said last, nor its previous take for the same moment (three laughs: never
  one laugh twice running), while there's another to choose. Each god keeps its own memory, on each player's device.
  The "got away" yells (one for gods, one for goddesses) and the snarl have one take each.
- **Alarm length**: 4 s from its first pulse, on every steal, the tutorial's too.
- **Scariness follows distance**: the god 90 studs or more away is the calmest a chase gets, 8 or closer the scariest;
  the head start sits at 0.3 of the way. Heartbeat 80 to 160 a minute; drums from 0.42, all in at 0.75.
- **Red edges**: 25% to 75% opaque, a throb on every heartbeat; colour drained 35% and a red cast at the scariest. Under
  the HUD (its buttons stay clear).
- **Shake and zoom**: a 6-degree zoom jolt and a small shake on the steal; the god's footsteps shake the view from 0.72;
  a big shake on the catch. None of it with Reduce Motion on (flashes stay).
- **The god's voice**: yells every 2.5-4.5 s while running, a snarl every 1.6-2.6 s within 16 studs of its thief; an
  angry yell when a thief gets away. The goddesses at 0.77 speed (the goddess board's "deeper"; "deepest" is 0.68).
- **Getting away**: the chase music stops within 0.3 s at the safety line, the Notice hit plays, the red fades over
  1.2 s with the heartbeat slowing. No special sound for each god's catch yet (Zeus's thunder was only in the mock-up).
- **Gone**: the horror sting on every steal (APM "FEAR HIT 12"), the cartoon boink on picking up a stolen lamb, the
  punch's comic clangs ("Scuffle", kept for slide hits). The chase music is now APM "Run For Your Life" (was "Evasion").

Calls in the momentum slide (2026-10-06, `Mountain.Momentum`, `GodService` pace):

- **+15% of the starting speed per sign passed, up to 100 studs/s.** From Zeus's pasture empty-handed: 1.5 min home at
  his sign's number (was 2.7), 2.6 min one sign short (was 6.8). 100 stays under the ~150 where a tree stops a slide
  dead; if 100 feels twitchy among the map's trees, 80 gives 1.7 min from Zeus.
- **Counted from the lamb's tier when carrying, from where the slide began empty-handed**, so an empty-handed slide
  that stops dead (stuck half a second) starts its momentum over; a carrier's comes straight back.
- **The god keeps its full boost through a thief's bump; the thief is back to speed in 0.25 s** (was 2 s) and never
  trips over (Roblox's FallingDown and Ragdoll states off). Simulated at Zeus's sign with the lightest lamb (the
  closest chase there is), 58 studs ahead clean: three 0.1 s knocks leave 19, two 0.3 s stops 9, one 0.6 s stop 21;
  one more of each is caught (before momentum, a second bump of any kind was). I picked no drop at all for the god
  rather than a small one: one number fewer, and the bump still costs ground.
- **The safety line stops a slide dead** (its speed along the ground zeroed), then normal walking: no run-out.

Calls in the onboarding trail (2026-10-06, merged into main):

- **Where the first trail ends**: the front of Pan's meadow, mid-lane (45% up tier 1), a few studs past the tutorial
  lamb; it stops once the player is within 4 studs of that line or past it, so it never points back.
- **No trail on the slope with the lamb**: the slide carries the player down; the trail home starts at the mountain's
  foot (off the ramp) and ends inside the player's own fence.
- **One trail to the stair walker after the first delivery**, no words, until the player steps on (Steal an Egg
  points at its treadmill only once it's bought, about $1K in).
- **No words at all**, unlike Steal an Egg's line per step ("Steal an Egg!", "Go to your Pen!").
- **The trail hides while a menu is open**, and follows the walkable way (pathfinding: out through the gate, round
  the stalls), straight when no way is found or it's over 1.3x the straight line plus 16 studs.

Calls in the trailer's first cut (2026-10-05, overnight; `trailer/stealasheep.md`, nothing uploaded):

- **Order**: steal, the god's alert, the chase, home, a full pen, the climb, a catch (Zeus punches the thief off),
  the 30 gods, the title. 31.9 s.
- **Captions** (game page): "Steal sheep from the gods", "Slide home before they catch you", "Fill your pens", "Climb
  to Zeus", "30 gods to rob". 9:16: "STEAL FROM THE GODS", "RUN!", "FILL YOUR PENS", "CLIMB TO ZEUS", "30 ANGRY GODS".
- **The chase god is Poseidon** (tier 28): Zeus's plaza edge stopped the slide; Zeus does the catch.
- **Sound**: the game's own music and sounds only; it fades out under the title card.


Calls in Zeus's Blender model (2026-10-05, a mock-up waiting for the user's OK):

- **Clothes** after the user's picture, covered up: a white knee-length tunic with short sleeves, a white drape with
  red edges over his left shoulder, gold brooches, belt, armlets and bracers, red hem bands, gold-strapped sandals.
- **Face**: thick white brows slanting down to the nose over glaring eyes, a frown under the moustache, a beard of
  five locks to a point on his chest, long white hair. No crown.
- **Walk** (going home): heavy steps, his right fist up holding the bolt, the left arm swinging. **Run** (the chase):
  leaning in, both fists pumping, the bolt kept upright in his right. The game would speed both up to his real speed.
- **The bolt** is 5 studs tall, gripped low.

Calls in Hera's Blender model (2026-10-05, a mock-up):

- **Her colours** are the game's (purple robe, gold): an ankle-length gown with a lighter front panel between gold
  lines, a gold hem under a row of peacock eyes (her bird), puffed cap sleeves, a dark purple cape edged in gold.
- **Face**: the same angry glare as Zeus with thin dark brows and a flick of liner, red lips in a frown; dark hair
  parted and swept into a bun, a ringlet over each shoulder; a gold diadem with five points and a purple gem.
- **Her symbol**: a gold sceptre topped with a glowing peacock eye (teal, blue, gold), carried upright in front of her
  as she walks; she runs like Zeus.
- **Shared style** (`art/gods/style.py`): the eyes and brows, fists, trims and the rig are the same for every god.

Calls dressing the thirty gods as Roblox avatars (2026-10-05; the user picked the route and Zeus's look, then "do
the rest"; three helpers chose catalog items by sight, every id checked and loaded):

- **Faces**: the gods wear the user's "Classic Style Angry Face"; the goddesses its match, "Furious Woman Face"
  (76927731769378: the same angry brows and bared teeth, with lashes and lipstick).
- **Size**: Height, Width and Depth scale 1.65 (9.6 studs, as before); head 1.3 times that, the cute look.
- **Looks** (`GodService/Looks.luau` lists every item): each god reads by hair, crown or helmet, outfit colour and
  wings, e.g. Pan a satyr with ram horns and goat legs, Phobos and Deimos Spartan armour, Thanatos a black hood and
  wings, Hermes a winged helmet and winged shoes, Hephaestus a fire crown and apron, Poseidon teal hair and a blue
  beard (it covers his mouth), Hera a gold crown and peacock tail. Bare chests where the outfit has them (the user
  dropped the fully clothed rule).
- **Held symbols** (`GodService/Props.luau`), blocks in the right fist: Zeus's bolt (raised), Poseidon's trident,
  Hera's peacock-eye sceptre, Athena's and Ares's spears, Artemis's silver and Eros's pink bow, Apollo's lyre,
  Hermes's caduceus, Asclepius's serpent staff, Hephaestus's hammer, Hecate's torch, Thanatos's scythe, Nemesis's
  and Themis's swords, Dionysus's thyrsus, Pan's pipes, Tyche's cornucopia, Iris's rainbow wand, Nike's wreath,
  Aeolus's wind, Hypnos's poppy, Morpheus's star wand, Demeter's wheat, Hestia's flame, Hebe's cup, Eris's golden
  apple, Phobos's and Deimos's dark spears, Aphrodite's rose.
- **Animations**: Roblox's own idle, walk (going home) and run (chasing), sped up to the god's speed; it points at
  the thief when it spots them and laughs when it catches them. Only gods within 220 studs of the camera animate.
- **Swapped after the first lineup**: Nike's windswept hair hid her face; she has an updo now. The user's calls:
  Hebe a coloured dress (her celestial gown in rose and gold, so she isn't white like Themis), Demeter a darker
  leaf green (a long dark green evening gown; the lime was too bright), Poseidon keeps his blue beard.

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
Calls made building six sheep a tier and the new Sheepdex (2026-10-05):

- **Sheepdex rewards are claimed**, as in the mock-up and Steal an Egg: delivering finds the family, the Claim button
  pays. Families found before the change count as claimed (they were paid on delivery; save schema 3).
- **Claim reward**: 30 s of the family's income in cash (rarity included) and 5% of its tier's sign number x the
  rarity's multiplier in Climbing, at least 5 (tier 1: 5 to 19). **Herd gift** for claiming all six: 10 minutes of the
  tier's Common income in cash and a quarter of the sign number in Climbing, at least 25 (tier 1: 1,200 and 25).
- **The section's bar counts sheep found** (x/6) and turns green once the herd's gift is paid.
- **Opening the Sheepdex shows the first sheep with a reward waiting** (else the first not found) and scrolls to it.
- **Six sheep in a 3 x 2 grid** beside a tall god banner, one tier to a screen, like the reference's 4 x 2.
- **The HUD's SHEEPDEX badge counts rewards waiting** (9+ past nine).

- **Rarity colours**: the menus' card colours (Theme.Fleece.Rarity). Flock and Sell Stall cards now take the family's
  rarity colour; a Shiny or Royal fleece shows as the token's sparkles and in the name ("Shiny Clover Sheep").
- **Mythic is a divine version of the god's sheep where it can be** (Golden Elixir, Eternal Harvest, Quicksilver...),
  so the top of each row is the most dressed: wings, halos, crowns, glowing wool.
- **No family wears the Gold paint**: a Royal fleece paints any sheep gold, so a gold family would look Royal. Golden
  Ram Sheep is gold foil wool instead (Golden Fleece is the store's Robux sheep).
- **The theft card shows the family's rarity** in its colour over the name ("EPIC", then "Gambler Lamb").
- **Legendary and Mythic lambs are announced** to players who have reached the tier, like Royal fleeces: "A Mythic
  King of Olympus Lamb appeared in Zeus's pasture!"
- **First finds pay per family**: the Sheepdex reward is 30 s of the family's income (rarity included), so a Mythic's
  first delivery pays 15 times a Common's. The Merge Shrine's price is 120 s of the family's income the same way.
- **Keyed by god, not tier** (`Config/Herds`), so the gods' new order (t3code/order-olympian-gods) needs no change here.

Calls made building the daily gifts (2026-10-05):

- **The prizes' fine print**: the walker's rate leaves trails out; the cash leaves out the friend boost and 2x Money.
  Amounts are worked out when claimed (the cards show what they'd give now).
- **The wait**: the next gift opens 20 hours after a claim (not a calendar day), so playing at about the same time
  each day works.
- **The Pegasus Sheep** earns as tier "highest stolen + 1" (a Royal of that god), saved on the sheep so it keeps its
  worth; it arrives as a lamb rolled with full luck (Heavy weights likely, Titan possible), white with sparkles, and
  hops into the pen (stored if full). Not in the Sheepdex, can't go in the Merge Shrine; it can be sold (two minutes of
  its income, like any sheep). A full flock (100) refuses Days 4 and 7 until there's room.
- **The menu** opens by itself once a session, 45 s after a gift waits, when the player is off the mountain, not
  carrying and no other menu is open (after the free gift's 30 s). Claiming leaves it open with a notice ("+197K cash",
  "Shiny Laurel Lamb is in your pen!") and the button counting down; Day 7 shows its own card ("Day 7!", the Pegasus,
  "In your pen now", Awesome!). After Day 7 every card shows a tick until the next Day 1.
- **The HUD**: DAILY sits under GIFT at the top of the left column, with a red "!" and a glow while a gift waits and
  its countdown in place of its name once claimed. The column stops 70 points above the bottom (the wrapping itself is
  the user's OK).
- **Pictures**: the store mock-up's cash (one stack, a pile, a chest) and Hermes' sandal (one, three) grow with the
  day; Day 4 shows the lamb's token; Day 7 the rendered Pegasus.

Calls made filling in the maturity questionnaire and making the store's products (2026-10-05; the user: "fill them
out based off what you know"). Restarting the questionnaire asks everything again: give these answers again and change
only what's new.

- **Answers**: Violence yes, Mild, Repeated (sliding into players knocks them back; the gods chase and catch thieves);
  Blood no; Fear yes, Mild, Repeated (since 2026-10-06, the user's OK: the chase music and its sting on every steal,
  the angry gods, Thanatos's ghosts and skeletons; it was "no" at first); Crude humor no; Unplayable gambling no; Strong
  language no; Romance no (the Cupid sheep's hearts aren't romance); Alcohol no (Dionysus's herd has grapes, no wine);
  Social hangout no; Free-form user creation no; Sensitive issues no (Greek myth isn't a current polarising issue);
  Cross-experience content no; AI interaction no; Paid random items yes (the Merge Shrine: cash, which the store sells
  for Robux, rolls a random lamb) and it respects `ArePaidRandomItemsRestricted`; Paid item trading no (stealing isn't
  trading); Media sharing no; Continuous media feed no. Result: **Mild**, Fear (Repeated/Mild) and Violence
  (Repeated/Mild), no non-compliant regions. Answering Violence "no" would have given Minimal; Mild was the honest
  reading of slide knockback.
- **The Merge Shrine is closed to players whose region restricts paid random items**: Merge answers "Merging isn't
  available in your region". It also stays closed while Roblox's answer is unknown (three tries, 5 s apart).
- **Product names and lines** (what Roblox's purchase dialog shows): "Golden Fleece Sheep" / "Kronos Sheep" ("A sheep
  that earns 10x (3x) your best sheep. Arrives grown."), "2x Speed 1" to "2x Speed 7" ("Doubles your Climbing."),
  "Stair Walker Level 2" to "Level 30" ("Upgrades your stair walker to level N."), "+150K Climbing" ... "+10B
  Climbing", "+24K Cash" ... "+8M Cash", passes "2x Money" ("Earn 2x cash.") and "2x Growth" ("Lambs grow 2x
  faster."). All on sale from creation, no pictures of their own yet.

Calls made publishing the private test version (2026-10-05):

- **The game page**: named "Steal a Sheep", described as "Climb the mountain, steal a god's sheep and slide home
  before they catch you."; Roblox's default icon and thumbnail, no genre.
- **Devices**: Computer, Phone, Tablet and VR (Roblox's defaults); not Console.
- **Five players a server**, one per plot.

Calls made building the Robux store (2026-10-05):

- **"Your best sheep"** is the highest income right now among the player's other sheep, stored ones included (a lamb
  at its lamb rate), and at least a tier 1 adult's 2/s. 2x Money doubles the Robux sheep's income too.
- **Robux sheep** arrive grown, Golden Fleece Giant-sized and Kronos Large (their income ignores size). They can't be
  sold ("Robux sheep stay with you") or merged, aren't in the Sheepdex, and go into the pen if there's room, stored if
  not; the flock limit never stops a purchase.
- **Their looks**: Golden Fleece in Shear a Sheep's colours (gold wool, cream curled horns, happy face) with gold
  sparkles (a new effect); Kronos Sheep is Shear a Sheep's Time Sheep.
- **2x Speed at 0 Climbing** gives +25: each buy doubles, and gives at least +25.
- **One Roblox dialog at a time** per player ("Finish your purchase first"), so a price step can't be bought twice at
  its price. A receipt for a step already counted still doubles; a walker receipt that finds the walker maxed pays the
  last level's cash price.
- **Passes count offline too**: 2x Money on the offline cash, 2x Growth on growth while away. Every income shown (HUD,
  flock cards, pen labels, the income boards) includes 2x Money.
- **HUD**: the STORE button (the icon pack's golden Robux coin) is hidden like the others until the first delivery
  (its place on the right edge is the user's OK). The store window's corner picture is the basket, as in the mock-ups.
- **The tabs**: 2 points apart, 6 from the window (the user: tighter and closer). Where the window is short (a phone held
  sideways) they start beside the header and shrink just enough for all five; on a phone they're about 0.8 size.
- **Climbing's icon everywhere is the white-winged sandal** (HUD, store, the free gift); 2x Speed's has gold wings.
- **Words**: "ROBUX ONLY" on the sheep, "CHEAP!" on 2x Speed with "Next: 9" under its price, "BEST VALUE" on +10B and
  +8M, "Owned", "Sold out" and "MAX" when done; the walker card counts levels from 1, as the shop does.
- **Before the products exist on Roblox**: in Studio a store button grants its product at once, with no dialog; a live
  server says "Not on sale yet".

Calls made building the Merge Shrine (2026-10-05):

- **Luck**: three Standard sheep bring 40%; each step of size above Standard adds, up to 100% for three Titans. 40%
  gives 58/34/8/0.2% Standard/Large/Giant/Titan; 100% gives 40/44/15/0.7% (the Climbing session's weight bands decide
  the tail).
- **Fleece**: three Plain in: 72/24/4% Plain/Shiny/Royal; three Royal in: 30/45/25%; mixes in between.
- **Menu**: the camera turns to the shrine with no dark backdrop and the HUD hidden; the odds in the lab's glass panel
  on the left, your grown sheep as the shop's rows on the right (the newest god's first, then the biggest), one big
  Merge button with the price at the bottom. The first sheep picked sets the family; the others' buttons say
  "Not <family>". Picks stand on the pedestals in order (1 left, 2 back, 3 right) at their real sizes. Walking 26
  studs from the shrine closes it.
- **One lamb at a time**: you can't merge again until the last lamb has left the altar ("Pick up your lamb first").
- **Pick up**: an instant E prompt ("Pick up", the lamb's name) within 14 studs of the altar.
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

- **Robux prices**: the store's walker ladder (Config/Store: 19 to level 2, then 20% more a level), the user's call in
  the store's session; the sign's R prompt asks the store (StoreService), so it sells the same products.
- **Levels 6-30 keep the Champion look** until more looks are designed.
- **The sign** stands by the machine's entry, turned to the gate, written on both sides ("UPGRADE", the next level, its
  price in cash and R$).
- **On and off**: walking into the entry snaps the owner on (only the owner, not while carrying a lamb); jumping puts
  them down behind the entry facing away; "Jump to get off" shows only on the onboarding's first climb. Training only counts
  while snapped on.
- **The sign's prompts**: E upgrades with cash, R with Robux; only the owner sees them; they go at the top level, and
  the board says MAX LEVEL. An empty plot's machine shows level 1 with no floating tag.
- **Step speed by training rate** (2026-10-06, replacing step speed by level): steps a second rise evenly with each
  tenfold of the climber's rate, so a trail speeds them up too. Without a trail a step takes 0.50 s at level 1 (two a
  second, the user's example), 0.36 at 3, 0.29 at 5, 0.20 at 10, 0.13 at 20, 0.10 at 30 (Sunlight trail on top: 0.10,
  the fastest).
- **The pops** (your own screen only): one a step, the shoe and "+N" in lime, N what that step earned; each starts
  just over your head somewhere across a 6-stud-tall space, rises about 4.8 studs in 0.9 s, fading for the last 0.3;
  sized in studs, so they keep their size beside the character on any screen. Reduce Motion: they fade in place.
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
- **Weight's only visible hint** is the lamb's size: 0.55 of an adult's rig at the lightest, 0.88 at 1.5, and
  rounder (mystery lambs, 2026-10-06).
- **Slides**: the god's speed x your speed factor, at least walking speed, kept all the way down; they reach it in
  about 2 seconds (speeding up by at least 26 studs/s each second).
- **Gods**: 0.8 x the tier's SlideSpeed, 19 at tier 1 to 48 at tier 30; the tutorial lamb's god 0.7.
- **Tier 1's sign is 25** (what the tutorial gives), so a high level speeds you up there too.
- **On screen**: tier signs "<God>'s <Area> / Climbing N"; the HUD's goals "Train to climb", "Train for heavier
  sheep", "Ready for the heaviest sheep"; the player
  list column is Climbing; the HUD pill reads CLIMBING; the wild lamb's card and the flock menu no longer name a burden.
- **Server check**: a player found further up the ramp than their Climbing allows (30% slack, 10 studs or 1 second's
  lead for lag) is put back at their allowed spot.
- **Saved sheep**: schema 2 turns Burden 1/2/3 into Weight 1.05/1.2/1.35; sizes already rolled stay.
- **Dropped lambs** (the user: a caught thief's lamb stays where it fell, anyone can steal it, its god chases them):
  being caught or dying on the ramp drops it; falling off the world, resetting or leaving puts it straight
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
- **Fleece looks**: Shiny sheep sparkle blue; Royal sheep have gold wool (Shear a Sheep's Gold paint) and sparkle.
- **Sizes on screen**: every sheep's base size is 1.6x the rig; lambs are 0.6 / 0.7 / 0.8 of it by burden (a clue to
  the burden) and grow towards 0.85 before the reveal; adults are 1 / 1.35 / 1.7 by size.
- **Slides**: start by themselves when moving downhill on the ramp past the safety line (the map's StartingLine,
  x 330); speed per stretch 24, 28, 32, 36, 36, 40, 40, 44, 44, 48, 48, 48 studs/s (tiers 1-12), times the carried
  lamb's burden share; steering within about 35 degrees either side of straight downhill; pulling back brakes; past the
  safety line the slide runs out to a stop. A scenery hit drops the slide to the speed the player really has; stuck for
  half a second ends it. The slide pose was Roblox's sit animation (R15 avatars surf since 2026-10-06).
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
- **HUD**: menu buttons (Flock, Shop, Sheepdex) appear after the first delivery; no hints in words (the onboarding's
  floor trail is the only guide, GAME_DESIGN.md, *Onboarding*).
- **Tutorial**: a new player's private, Light, ordinary tier 1 lamb (Pan's) sits just short of the meadow (others can't
  take it); its run is protected from slide hits; any first delivery gives +60 coins and +25 Climb Power and removes it.
- **Sounds**: Shear a Sheep's cues: the danger music during a chase, WolfScare on the alert, IntroWhip on a slide,
  Yelp/Scuffle on hits, Coin/DexReward/Upgrade/Reveal on rewards.
