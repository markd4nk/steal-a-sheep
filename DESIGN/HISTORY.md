# History

What was built, newest first: how each part works, the user's calls on it, and how it was checked. Don't read it
whole: search it for the feature you're touching and read that entry. Add an entry at the top of *Built* when you
finish a task. The current state is `DESIGN/CURRENT_STATE.md`.

## Built

- **Momentum slides, the god boosted too, quick bump recovery, a dead stop at the safety line (2026-10-06, branch
  `t3code/speed-up-downhill-sliding`, merged into main on the user's word)**.
  The user: sliding home from the top was "very, very slow all the way down" and boring (a slide kept the speed it
  started with, so a player weak at the top crawled home at 18 studs/s, 6.8 minutes from Zeus); wanted it to speed up
  "like momentum", with as few numbers as possible; then "I want the guardian to also speed up on the way down" so a
  thief below the tier's level can't just escape once they reach the lower tiers; a single bump must bring the god
  closer, never be an instant loss, yet not reset the god to its normal speed ("it means nothing"); "almost an
  instantaneous recovery" instead of lying on the floor for two seconds; and "as soon as they hit the safe zone, they
  begin walking", nothing carrying them into the pens. Then: "merge it to main ... publish it too", to try it.
  - *How it works*: a slide's base is the old escape speed (`Mountain.SlideBase`); `Mountain.Momentum` adds 15% of it
    for every tier below where it counts from (the carried lamb's tier, or where an empty-handed slide began), never
    lifting it past 100 studs/s (a faster slide keeps its own) and none below the safety line
    (`GameConfig.Movement.MomentumPerTier`/`MomentumTop`). `MovementController` aims for base x momentum; a bump drops
    the push once, and it climbs back to full in `SlideRecoverSeconds` (0.25) even while still against the obstacle,
    so steering slides the character off it (the old rule held the push at the speed it really had, about 8, and a
    blocked slider crept along an edge for 1.5 s); a slide restarted within 2 s of getting stuck recovers as fast; the
    character's FallingDown and Ragdoll states are off, so a hit at speed never lays it on the floor. At the safety
    line it zeroes the slide's ground speed and hands over to walking (no more run-out). `GodService` runs each god at
    its set speed times its thief's momentum where they are, through bumps too. `MountainService`'s ground budget
    allows the momentum (empty-handed: as if the slide began at the top).
  - *Why chases still end in the same place*: with both speeds scaled by the same share, the gap changes per stud slid
    exactly as without momentum, so every clean chase ends on the same tier (45 simulated steals, tiers 3-30, at, one
    and two signs short, three weights: all matched). A first version had the god follow its thief's measured pace
    (dropping to its own speed during a crash, since with a 2 s recovery a kept boost made one crash fatal); the user
    wanted the god to keep its speed and the thief to recover almost at once instead (DECISIONS.md has the numbers).
  - *Checked*: `check.ps1`; a Studio copy built from the branch (`build/MomentumPlaytest.rbxl`, the cloud place left
    alone): both bootstraps ready, 86 tests (2 new in `Mountain.spec`), a clean console. Tier 20 at its sign with a
    1.057 lamb: the god 43.2 -> 49.4 -> 56 -> 62.5 -> 69 a tier with its thief, the gap closing about 1.5 studs/s as
    an average lamb's should, caught on tier 16. Tier 3 at 4x its sign: 49.6, 57.1, 64.5 studs/s on tiers 3, 2, 1, two
    bumps won back in about 2 s, a dead stop at x 329.4 (64.5 to 0 in a frame, then walking at 79.9). After the bump
    changes, the same tier-3 bump at x 738: free of it in 0.45 s (it had crept 1.5 s) and back to 57.2 a tenth of a
    second later, the god at 29.4 throughout and 33.3 on tier 1, FallingDown and Ragdoll off, 86 tests, a clean
    console.
  - *Shipped as version 20* (the user: "merge it to main, and then ... publish it too", to try it): main
    fast-forwarded to d8fc2b3; the cloud place's five changed scripts set and the new test added (it held main
    b87e808's scripts and nothing else first; 121 of 121 matching after); a playtest of the cloud place (both
    bootstraps ready, 86 tests, 30 gods, "data will be saved", a clean console); File > Save to Roblox, then Publish
    to Roblox at 17:34 UTC: "Place published. Editors can now play this place in Roblox", v20. Audience still Private;
    no schema or remote changes, so no servers to restart.

- **Version 8: the overnight work merged and shipped, private (2026-10-06)**. The user, on the morning summary: "Yes,
  it looks good. You can merge it"; the free gift's favorite gate stays ("allowed because some games do it"); no game
  page icon change yet; "set it to mild" (Fear) but no genre yet; "just ship it. It still needs to stay private".
  - *Merge*: main fast-forwarded to `t3code/overnight-rc` (3667692): the publish prep, the studs, the Settings menu,
    the gods' asset audit, game page tools and trailer on top of the avatar gods. `check.ps1` passes on main.
  - *The cloud place* (the main Studio, Team Create; reopened at 00:05 after a mistaken close, BRAIN proposal S45):
    main's 127 scripts swapped in (`rojo build tools/sync.project.json`, then `GetObjects` in Edit; 0 differences, none
    missing or extra); High Olympus rebuilt in place for the gods' new order by `tools/UpperMountain.luau` (loaded as
    `tools/preview-upper-mountain.luau` writes it); the five stud materials made by `studio/SheepStuds.luau`. Against a
    fresh `build-place.ps1` build of main: the same 44,493 Workspace instances and names, every part's position and
    size equal except High Olympus's clouds (STUDIO_CONTENT.md).
  - *Checked*: a playtest of the cloud place: both bootstraps ready, 84 tests, all 30 gods as avatars, 121 of 121 wild
    lambs studded, "data will be saved", a clean console; no `TEMP_` instances or debug attributes after it.
  - *Shipped*: File > Save to Roblox, then Publish to Roblox: "Place published. Editors can now play this place in
    Roblox", version 8 (Team Create had autosaved the edits as 8 at 08:42; published 08:51). Version History marks 8
    published. No servers were running, so none restarted. The audience stays Private.
  - *Questionnaire*: restarted and answered as before except Fear: Yes, Mild, Repeated. The label is still Mild, now
    with Fear (Repeated/Mild) beside Violence (Repeated/Mild), confirmed after a reload.

- **Overnight publish prep (2026-10-05, branch `t3code/prepare-game-for-publishing`)**. The user asked an overnight
  session to answer the other sessions for them, then fill the gaps so the game is ready to publish, all on a branch
  for their approval in the morning. It merged the store products' branch (`t3code/publish-readiness-checklist`) and
  main (all 30 avatar gods) in, then:
  - *Say each moment once* (the user's calls on the UI audit in `t3code/audit-ui-hod`: the objective "doesn't need
    to be a thing at all", train to climb and put your sheep to work "as needed", no "Hold E", no "claim its reward
    there", no "steeper slopes", no "take it home" or escape notice, no "put it down where you like", no "yours has
    your name over the gate", no grow-up celebration, "you get the gist"). The HUD's hint (`Hud.goal`) shows only
    for the first lamb (Steal Pan's lamb, then Slide home! with the arrow), Train on your Stair Walker after it, Put
    your sheep to work for 12 s when room opens up in the pen while sheep are stored (`watchPen`; the FLOCK button
    glows), and Train to climb while a slope holds the player under half speed. A delivery is one notice; the
    Sheepdex badge and the HUD counters say the rest. Giant and Titan grow-ups get one notice, others none. Menus
    don't open themselves in a first session; afterwards only the daily gifts, once (the free gift never does). The
    welcome-back card no longer goes missing when the away credit is settled after the first snapshot
    (`StateController.TakeAway`). Notice sounds play when their words show. Wording trimmed in the shop, Sheepdex,
    flock, merge and gift menus, and gods' nameplates show the name only.
  - *Prompts for each device* (`PromptController/Look`): every ProximityPrompt is Style Custom and drawn as the menus'
    studded button: the key in a cap beside it on a computer (a click works too), a bigger tap button on a phone, the
    controller's glyph on a gamepad. Prompts on one spot stand side by side (the walker sign's cash and Robux
    upgrades); the Put down button floats over the carried lamb (`PromptLift`). Stealing is a press or a tap
    (`Theft.HoldSeconds` 0).
  - *Compliance* (a review of Roblox's October 2026 rules): the free gift no longer asks for a like (the review
    policy forbids rewarding a thumbs up); the Merge Shrine's odds are exact or five significant digits, with "Size
    and fleece roll separately. Odds are rounded..."; Eris's area is Chaos Rift and her Mythic shows as Mayhem Sheep
    (filters treat "Discord" as an off-platform app; the id is unchanged).
  - *Security* (a server audit): no steal or put-down during a punch's flight (`MountainService:IsLaunched`); a god
    under or over its thief for a second catches them at any height; the 2x Speed and walker products grant their
    step only when it's the player's next (a step they're past pays its price in Climbing or cash: the ladders could
    be bought at the first step's price); a lag spike's overshoot is placed at the furthest legal point, with 2 s of
    budget; pass lookups retry; each player's tick and the leaderboards' loops run guarded; a thief who steals before
    their god has loaded is chased once it has.
  - *Phone layout* (Galaxy A06 in the Device Simulator): the hint, notices and chase banner stand right of the
    wrapped menu pictures; the edge arrow keeps clear of them and of the thumbstick; the plots', stalls' and
    walkers' signs are sized in studs, so from the mountain's foot they no longer pile up across the screen.
  - *Checked*: `check.ps1`; 78 unit tests (a new one for the price steps); playtests in this session's own copy of
    the place (`build/Overnight.rbxl`, phone emulation): the first lamb's hints, the steal and put-down buttons, one
    notice per delivery, training, Put your sheep to work after buying pen space, Train to climb on tier 5, no menu
    opening itself in a first session, a Giant's notice, a god's catch and punch with a steal refused mid-flight, the
    walker sign's two buttons. Pictures in T3 Code's attachments (`night_before_*`, `night_after_*`).
- **Settings menu (2026-10-05)**. On branch `t3code/sheep-stud-style-mockups`, not merged, its look waiting for Mark's
  OK. The overnight coordinator (t3code-60160304) asked for it: the game had music and no way to turn it down
  (`Utils/PlayerSettings` was there from Shear a Sheep, unused).
  - *Mock-up* (`DESIGN/ui/mockups/settings.html`, renders in `.t3/userdata/attachments/settings/`): the gear in
    Roblox's top bar (A) or after the cash pill (B); three rows, Music and Sound effects in four steps and Reduce
    motion, or switches only. The coordinator picked A with steps; Mark sees the switches as the alternative.
  - *How it works*: Shear a Sheep's design, ported to code-built UI. `Screens/Settings` builds the menu (a Medium
    Settings-accent panel, 480 x 300) and the gear (`PlayerGui.SettingsGear`, ScreenInsets TopbarSafeInsets, so it sits
    in Roblox's bar wherever its buttons end); - and + send `Remotes.SetSetting` (12 a player per 2 s), which
    `SettingsService` cleans (`PlayerSettings.Clean`, steps of `GameConfig.Settings.VolumeStep` = 0.25), saves in
    `Settings` (new in `PlayerData`, defaults filled into old saves by Reconcile, no schema bump) and mirrors as
    `Setting<Name>` attributes. `SoundController` sets each SoundGroup to its mix volume times the setting (Music and
    Ambience: MusicVolume; Effects: SfxVolume) and again when it changes. Reduce motion was already honoured by the
    menus' motion and button shakes.

- **Icons for the store's 49 developer products and 2 passes (2026-10-05)**. Files for Mark to approve, not uploaded:
  asked for by the overnight coordinator (t3code-60160304) for Creator Hub, where the products had Roblox's default
  picture. `art/store/make_product_icons.py` reads the products and passes from `Config/Store.luau` (`--store` for a
  branch with the Creator Hub ids), the walker's levels from `Economy`, and the card colours from `Screens/Store`'s
  TINTS. Each 512 x 512 icon is its store card's picture (`make_store_art.py`'s export, pixel for pixel the store's) on
  the card's colour shading darker downwards, with the cards' studs (`DESIGN/ui/assets/studs.png`), white rays and the
  card's own words in Fredoka One ("+150K CLIMB", "2x SPEED", "Lv 1 > 2"); passes keep everything inside the circle the
  game page crops them to. The two Robux sheep are Blender renders of Shear a Sheep's fluffy sheep in this game's
  looks (`art/store/render_robux_sheep.py`, as `DESIGN/ui/art/pegasus.py` does), in the store art's ink outline.
  Output: `.t3/userdata/attachments/product_icons/<Key>.png` and `contact_sheet.png` (gitignored pictures: the icon
  pack may be used in the game, not shared). Checked by eye on the contact sheet and at full size.
  - *Mark, 2026-10-06*: "good to upload"; the two Robux sheep should show the studs unless they're barely visible.
    They show plainly, so both are now Studio captures of the game's own sheep (`studio/RobuxSheepIcons.luau` in a
    playtest of a copy built from main: the store card's turn, lens and light, the camera closer) on black and on
    white, cut out with their transparency by `art/store/cut_out_sheep.py` (Kronos's glass cape stays see-through),
    then given the same ink outline.
  - *Uploaded (2026-10-06)*: on Mark's word ("use the Windows MCP tool to just make your own upload key", no expiry),
    an agent made the Open Cloud key in Creator Hub as getajobgle with the desktop tools (read off the page by UI
    Automation into `~/.roblox/steal-a-sheep-open-cloud.key`, no clipboard). `art/store/upload_product_icons.py` sent
    each PNG as its product's or pass's `imageFile` (PATCH, picture only): 51 of 51 took, each icon asset id changed,
    and Roblox's public product APIs agreed; `uploaded.json` beside the icons has the ids. Roblox serves the passes
    cropped to a circle with picture and words inside, as drawn.

- **The map's studs on every sheep (2026-10-05)**. On branch `t3code/sheep-stud-style-mockups`, not merged. The user
  asked for mock-ups of the map's stud style layered over the sheep, picked B, then: "build it on every sheep, and then
  you can use the glowing studs".
  - *The map's studs*: `MaterialService.Studs`, a Plastic MaterialVariant (colour and normal maps, one stud a tile) on
    about 26,000 of the map's parts: a grid of square insets with a bevel. The other Texture on 14,700 faces
    (`6905003203`, 9 studs a tile, 90% transparent) is a soft shading gradient, not studs.
  - *Mock-ups* (`studio/StudSheepMockup.luau`, rendered in HerdsPlaytest.rbxl by the first plot): A the map's variant
    (1 stud) on the wool, B a half-size copy on the wool, C B all over (face, ears, legs, extras). On the sheep's meshes
    the tiles follow each mesh's UVs but keep their size in studs; at the map's size they came out uneven where UV
    islands meet, and C's faces looked quilted. Dropped: the studs' colour map as a projected `Texture` (an even grid,
    but flat L-shaped marks without the bump map).
  - *How it works*: `GameConfig.Sheep.Studs` gives each wool material the material it becomes and its variant
    (Plastic and SmoothPlastic `SheepStuds`, Metal, Fabric and Foil their own copies, Glass `SheepStuds` at
    Transparency 0.25 or more, Neon `SheepStudsGlow`). `Looks.Studs`, called by `SheepService.Build` after the paint,
    extras and sparkle, puts them on the fleece: the Wool folder, the tail and add-ons tinted Wool or Spot. A variant
    missing from the place leaves the part as it was (warned once). Every sheep model comes from `Build` (wild, pens,
    carried, the shrine's lamb, `SheepLooks` for the menus), so nothing else changed. The five variants are copies of
    the map's Studs at 0.5 studs a tile, made by `studio/SheepStuds.luau`: their BaseMaterial, maps and glow mask (the
    studs' own colour map) can only be set in Studio or Lune. `tools/assemble.luau` runs that same file on every place it
    builds, through `@lune/luau` with `game` set to the place.
  - *Checked*: `check.ps1`; a Lune build holds the five variants as made; in HerdsPlaytest.rbxl with the branch's code
    synced (`content/sas/studs-sync.rbxm`) and the studio script run: both bootstraps ready, 78 tests (2 new in
    `SheepStuds.spec`), console clean. The client had the five variants; 121 wild lambs and a pen of eight special
    wools (glowing, glass, fabric, metal, foil, silver) came out right; the Flock menu's 3D sheep shows the studs. All 183
    families, plus Royal and Shiny fleeces, rendered in Edit: nothing broken (the Scarecrow's denim and checker
    pictures still show). Rechecked after merging main's avatar gods (78 tests, 121 of 121 wild lambs studded, console
    clean). Not run on the cloud place or on a phone.
- **Trailer, first cut (2026-10-05, overnight)**. The overnight coordinator asked for 30-45 s of real gameplay, no
  voice-over or promo text, HUD hidden, 1920x1080 at 30 fps plus a 9:16 cut. Nothing was uploaded or merged.
  - *How it was made*: a Studio copy of the branch (`build/Trailer.rbxl`, deleted after) with `TrailerController` in
    the client Registry (Studio only), staged with the debug remote (`DebugBlankProfile` on), filmed with OBS
    (`trailer/obs.py`, a 1708x960 crop of the viewport at 60 fps), and cut by `trailer/edit.py` from
    `trailer/stealasheep.cut.json`. `edit.py` gained a cut list `fps` and keeps the game's sound under the title card,
    fading out. `studio/TrailerSummit.luau` puts client copies of all 30 gods on risers for the last shot.
  - *What it took*: the slide only starts if the scripted `Humanoid:Move` runs in `BindToRenderStep` at
    `Input + 1` (later, Roblox's controls zero MoveDirection before MovementController's check). `Climbing` set
    close to the tier's Reach makes the slide about as fast as the god, for a close chase. Lowering Climbing while on
    the summit knocks the thief down, so lower it lower down. The chase is Poseidon's (tier 28) because Zeus's plaza
    edge stopped the slide. The Free Gift menu, which opens after the first delivery, is kept closed on the client.
    The stage signs in the world sit where lower-third captions go, so "Climb to Zeus" sits at the top.
  - *Not filmed*: a clean put-down (the thief stuck on the pen's fence corner or walked into the camera; the cut uses
    the swoop into the full pen), the wide slide shot (occluded), a store or Sheepdex moment (optional).
  - *Checked*: contact sheets of every take and of both cuts, every caption against the frame, loudness (-17 LUFS),
    no silent gaps. Studio's layout was put back after (panels, view selector, ribbon, Device Simulator on).
  - *Then, on the combined build* (this branch with the studs, the Settings menu and the gods' tools,
    `t3code/overnight-rc`), with the copy acting as the published place (`SetPlaceId`, TESTING.md): 84 unit tests;
    a two-player Server & Clients test (slide hit and knockback, "That's not your plot!" once, the walker sign's
    buttons hidden from another player, the shrine's show private to its player); saving across three sessions of
    a test player (sheep, tutorial, cash, settings, receipts), the welcome-back card with offline cash, the daily
    gifts opening by themselves in a second session; Roblox's test purchase dialog with real products (+24K cash,
    2x Speed step 1), and the same cheap step bought again outside the store not doubling; every menu on the phone
    and the HUD on a computer.
  - *Fixed from those tests*: the counters stand left of Roblox's player list on a computer; the daily gifts wait for
    the welcome-back card (they had opened under it); the guide arrow never covers the hint; on a phone the Flock's
    buttons stay inside its window, the free gift's step is a row, the Merge button moves under the shrine's list so
    every odd shows at a readable size, and the HUD's STORE hides while a menu is open; an old Speed step pays at the
    smallest Climbing pack's rate.

- **The thirty gods as Roblox avatars (2026-10-05)**. The user wanted real god models. Roblox's mesh generator kept
  missing (third arms, bare chests; moderation removed two limb meshes), and a Blender pipeline (`art/gods/`, Zeus and
  Hera built from shapes, rigged) looked good. Then they asked for "a little cuter version that fits the Roblox niche"
  and whether a player model would do. An R15 avatar dressed from the catalog did: they picked the classic angry face
  ("the left one"), said do the rest, and dropped the fully clothed rule.
  - *How it works*: `GodService/Avatar` makes each god with `Players:CreateHumanoidModelFromDescription` from
    `Looks` (head, accessories, layered and classic clothing, the tier's skin), scaled 1.65 with the head 1.3 times
    bigger, no Humanoid state machine (the root's AlignPosition still moves it), the nameplate and the held symbol
    (`Props`: blocks welded to the right hand). Building yields while Roblox fetches the items, so `GodService.Start`
    builds the thirty side by side in the background; a god whose avatar fails falls back to its block figure
    (`Rig`). Its hip height (feet to root) comes from the avatar. `GodController` (client) plays Roblox's idle, walk,
    run, point and laugh by the god's Mood and Speed within 220 studs of the camera, and keeps a `Raise` god's
    (Zeus's) right arm up after the Animator; AnimController keeps the block figures.
  - *Looks*: three helpers searched the catalog ten gods each, checked every id and judged each by its picture;
    DECISIONS.md lists the calls, `Looks.luau` every item.
  - *Checked*: a playtest of the branch in a Studio copy: all 30 avatars load with every item and symbol, 76 tests
    pass, the console is clean; Zeus's alert (points), chase, catch (laughs) and walk home ran on a real theft; Hera's
    run checked; review lineups five at a time on the summit (`studio/GodLineup.luau`). Nike's hair hid her face in the
    first lineup and was swapped. The Sheepdex's god pictures lost layered clothing (dresses, Pan's goat legs) because
    the copy dropped every constraint, an avatar's joints among them; it now drops only the movement drivers and keeps
    the joints (checked in the menu). Not checked: a live server.

- **Maturity questionnaire, the store's products, the gods merged (2026-10-05)**. The user asked what was missing to
  publish, then: fill in the maturity questions from what's known, make the store's passes and products, and merge
  the gods branch.
  - *Questionnaire*: answered in Creator Hub (answers in DECISIONS.md), label **Mild**. Its paid random items page
    asks whether the game respects `ArePaidRandomItemsRestricted`; it didn't, so `ShrineService` now fetches each
    player's `PolicyService` info on join and refuses a merge while it's restricted or unknown.
  - *Products*: made with one script in the Creator Hub tab's DevTools console, using the page's sign-in against the
    Open Cloud endpoints (`POST apis.roblox.com/developer-products/v2/universes/<id>/developer-products` and
    `/game-passes/v1/universes/<id>/game-passes`, multipart name, description, price, isForSale; the CSRF token from
    the first 403). It skips names that already exist, so a rerun is safe. All 51 checked through the public details
    APIs (name, price, on sale), ids into `Config/Store`; a Store spec test checks every key has its own id.
  - *Merge*: `t3code/order-olympian-gods` at 9206503 merged into main (4e3585d) after its session confirmed it ready
    (check passes, 76 tests in its playtest, 30 gods spawn, Zeus as an avatar). Doc conflicts only.
  - *Checked*: `check.ps1` passes on this branch and on main. Not playtested in Studio (no Studio of mine open;
    the shrine's policy check and real purchases are untested).
- **Gods in mythological rank (2026-10-05)**. The user asked whether the thirty gods were in Mount Olympus's order.
  They weren't: the Olympians had been placed to fit the commissioned map's stage themes and the minor gods sat above
  them, ordered by mood. The user chose rank: "the Zeus family should end up at the top", and kept the proposed order of
  tiers 18-30 ("if in Greek mythology they don't have a hierarchy, then it doesn't really matter").
  - *Order*: tiers 1-12 on the commissioned map, each minor god on a stage that suits them: Pan, Tyche, Hecate, Phobos,
    Eris, Eros, Hebe, Themis, Asclepius, Iris, Nike, Aeolus. 13-17 on High Olympus as before: Hypnos, Morpheus,
    Deimos, Thanatos, Nemesis. 18-30 the Olympians, youngest first: Dionysus, Hermes, Hephaestus, Ares, Aphrodite,
    Artemis, Apollo, Athena, Demeter, Hestia, Poseidon, Hera, Zeus. Each tier keeps its numbers (reach, income, x range,
    slide speed, grade) and each god keeps their family, colours and signature, so the `Config/Olympus` rows swapped
    names, areas, families and looks. Ten areas were renamed to fit their new places (DECISIONS.md).
  - *High Olympus*: new themes in `tools/UpperMountain.luau` for the eleven Olympians who moved up (their props are
    listed in DECISIONS.md), new pixel sprites (grapes, helmet, lyre, owl, trident, crown) and `Props.Fan` (Aphrodite's
    shell, Hera's peacocks). The themes, sprites and arc prop only the departed minor gods used are gone, and Deimos's
    moon helper is inlined (same draws, same stretch). Main's 275-stud stretches merged in.
  - *Code*: the tutorial objective names tier 1's god ("Steal Pan's lamb"); the Economy and Roster specs take tier 1's
    family from `Olympus` instead of "Meadow" (five tests failed on the reorder). `tools/check-lanes.luau` checks the
    slide lanes in the built place with Lune, no Studio needed.
  - *Checked*: `check.ps1` passes; `check-lanes` finds 0 of 8475 decor parts in the lane (it caught leaves of
    Hermes's and Artemis's trees and one of Aphrodite's arches, moved further out). In a separate Studio on the built
    place: both bootstraps ready, the 30 gods spawn in the new order, 36 tests pass, the console is clean, the HUD reads
    "Steal Pan's lamb", Pan stands in the first pasture under Tyche's gate. Screenshots of all eleven new stretches;
    three colour fixes after them (Hephaestus's caps charcoal, not Ares's red; Aphrodite's blossoms pink; Artemis's
    floor slate). Not walked: the new stretches by foot, a theft from them.

- **Version 5: six sheep a tier, servers restarted (2026-10-05)**. The user, through the six-sheep session: "merge to
  main and then tell the other session to publish with this new version and then refresh all the servers". Main
  3989273's 24 changed files swapped into the cloud place (120 scripts, 0 differences; Workspace fingerprint
  unchanged); a playtest had both bootstraps ready, 76 tests passing, a clean console, and the Studio test save went
  from schema 2 to 3 without a kick. Published as version 5. Creator Hub > Server management > Restart Servers, all
  servers, no delay: 1 server with 1 player (on an older version) migrated, Completed 100%; the browser then showed 1
  server, 1 player, none outdated. Restarting mattered: an old server refuses a save with a newer SchemaVersion.

- **Republished: version 4, with the daily gifts (2026-10-05)**. The user: "look at what main has and then republish
  what's already there", and keep it Limited. Main was a71cab4 then: the only code since version 1 was the daily
  gifts (19 files; their debug commands go through the Studio-only DebugService). Swapped into the cloud place and
  checked (117 scripts, 0 differences; Studio-side content identical to a fresh build); a playtest had both bootstraps
  ready, 72 tests passing and a clean console with real DataStores; File > Publish to Roblox logged "Published new
  changes" as version 4. Six sheep a tier (3989273) landed on main minutes later and isn't in it: its session is
  waiting on the user. *Limited* couldn't be saved: Creator Hub greys out Save until the game has a content maturity
  label, and the questionnaire needs the user's answers. Still Private.

- **Six sheep a tier, and the new Sheepdex (2026-10-05)**. Merged into main at the user's request, after main's Robux
  store: Zeus's Legendary became the Golden Ram (id `GoldenRam`), since the store's Robux sheep is `GoldenFleece`, and
  GameConfig now refuses a herd id that's already a family; the put-down prompt, the carry card and the shrine menu
  name a sheep by its family. Rechecked after the merge: check.ps1, 70 tests, a playtest (Golden Ram and King of
  Olympus income and claim, console clean). Then main's daily gifts: the Pegasus Sheep (a special family on no
  tier) earns at its own tier times Common, keeps its name, and never counts on the SHEEPDEX badge; Day 4's prize is
  now a Shiny lamb (the card says so); DAILY and SHEEPDEX share the HUD's badge helper.
  - *How it works*: `Config/Herds` lists each god's six families, Common (the god's own) to Mythic, keyed by god, and
    the 150 new looks (Shear a Sheep builds, wool styles, materials and paints with 36 new primitive extras in
    `SheepService/Extras`: halo, crown, antlers, witch hat, trident, bolt...); GameConfig turns them into Breeds and
    Olympus maps every family to its god's tier. `Economy.FamilyRarities` holds the odds and multipliers;
    `RollFamily` picks each wild lamb's family (WildService), `FamilyBase` is its income before fleece, size and rank,
    `FamilyName` its name. Fleeces are Plain / Shiny / Royal. The theft card adds the rarity; Legendary and Mythic
    lambs are announced. The Flock and Sell Stall cards take the family's rarity colour. `Screens/Sheepdex` is
    rewritten from the mock-up (`studio/SheepIndexMockup.luau`): sections per tier, 3D sheep and gods drawn when a tier
    scrolls near, silhouettes, badges, the picked sheep with its reward and Claim (`Remotes.ClaimDex`,
    `SheepdexService`, which also pays the herd gift). `FlockService.Deliver` only finds a family now. Save schema 3
    adds `DexClaimed` and `HerdGifts`. The HUD's SHEEPDEX shows a count badge. Debug: `GiveSheep` 30.6 gives Zeus's
    Mythic; `FillDex` n marks n of every herd found.
  - *The user's calls*: six a tier, Common to Mythic; the lineup's designs ("that's good"); odds 50/25/13/7/4/1 and
    income x1/1.5/2.5/4/8/15; fleeces renamed Plain / Shiny / Royal; the gods' new order used before it merges; the
    Sheepdex mock-up ("looks pretty good"). The design rules (Mythic as the god's sheep made divine, no family in the
    Gold paint) and the reward numbers are in DECISIONS.md *To review*.
  - *Checked*: check.ps1; 64 tests (new: herds data, schema 3 migration). Playtested in my own Studio copy built from
    the branch: server and client Ready, 180 previews (5,846 parts), 121 wild lambs rolled about 50/30/13/5/2.5%,
    six tier-1 families' income matching the formula, the theft card ("LEGENDARY / Grape King Lamb"), carrying a
    Legendary, the Flock menu's colours, claims (cash and Climbing paid, a second claim and an unfound one refused),
    the herd gift (+1,200 and +25 on the sixth), the Sheepdex on the Galaxy A06 (fits after giving the picture the
    spare height), lazy drawing (tier 2 drawn when scrolled to, tier 5 not), console clean. Not checked: clicking
    Claim (a script opened the menu after my desktop clicks went astray), saving, two players.
- **Daily gifts, with the Pegasus Sheep on Day 7 (2026-10-05)**. The user: a daily gift to check in for every day,
  better and better prizes, "day seven could be some like super rare sheep", then keep it standard; mock-ups first.
  - *Mock-ups* (`DESIGN/ui/mockups/daily-gifts.html`, the Sell Stall's kit): A (seven in a row) and B (Days 1-6 in a
    grid, Day 7 big beside Claim), the week in B, three looks for the sheep, the HUD button on a real screenshot. The
    sheep was rendered in Blender from Shear a Sheep's fluffy sheep with feathered wings (`DESIGN/ui/art/pegasus.py`,
    reading `C:\Users\markf\breed_render`); the cash and sandal pictures are the Robux store mock-up's.
  - *The user's calls*: B; the third look (gold-tipped wings and a halo); a missed day waits; "just this week for
    now" (the week repeats).
  - *Server*: `DailyService` (`Remotes.ClaimDaily`, 2 in 2 s): saved `DailyDay` (1-7) and `DailyAt` (os.time of the
    last claim); ready 20 h after a claim (`Economy.DailyCooldown`); cash and Climbing from `Economy.DailyWeek`
    (seconds of the pen's income or the walker's rate, each with a floor); Day 4 a Rare lamb of
    `Economy.HighestStolen`'s family and Day 7 a Pegasus lamb (`Economy.PegasusLuck` 1) through the new
    `FlockService.Grant` (into the pen, hopping in, else stored; refused when the flock is full). The Pegasus is a
    special family (`Economy.Specials`): a sheep's optional saved `Tier` sets what it earns and how long it grows
    (`Economy.SheepTier`), `Economy.FamilyName`/`FamilyOrder` name and sort it (the Robux sheep too), `CanShrine`
    refuses it. Its look: `GameConfig.Breeds.Pegasus` (white, Sparkles) and `Extras` "Pegasus": two wings of stretched
    spheres (an arch, then primaries tipped gold, secondaries, coverts), a ring of 26 neon gold beads, gold hoof bands.
    The snapshot's `Daily` carries the day, when the next opens and each day's amount for this player. Debug:
    `DailyReady`, `DailyDay`.
  - *Client*: `Screens/Daily` (laid out at the compact panel height, 600 x 318, so it's the same on a phone): day
    cards from `UIKit.SheepCard` (blue ahead, gold and lifted with a ring today, dark with a tick claimed), Day 7 a
    sky stage with the rendered Pegasus, SUPER RARE in a rainbow chip, Claim or "Next in 19:59:58"; a Day 7 card
    ("Day 7!", Awesome!). The HUD's DAILY under GIFT; the left column now has a height and wraps
    (`UIListLayout.Wraps`). Six pictures uploaded through the Studio MCP (`Theme.Icons.DailyCash1/3/5`,
    `DailyClimb1/3`, `Pegasus`).
  - *Checked*: `check.ps1` passes; 72 tests pass (new: the week's amounts and floors, the 20 hours, the Pegasus's
    tier, income, name and shrine refusal, the saved fields). Played in this session's own Studio
    (`build/DailyPlaytest.rbxl`, Studio's phone emulator): both bootstraps ready; the free gift's menu opened at 30 s
    and, once closed, the daily menu at 45 s by itself; Claim on Day 1 gave its cash, ticked the card and counted down
    from 19:59:57 (the HUD's DAILY too); a second claim was refused; Day 4 put a Rare lamb of the highest god in the
    pen; Day 7 showed the Pegasus card and put a Pegasus Lamb in the pen (1,526/s for a tier-8 player, 3K-7.6K grown);
    after it every day showed its tick and Day 1 came next. The Pegasus model, screenshotted in the sky, has the
    render's wings, halo, hooves and sparkles. Fixed on the way: the 340-point panel ran off the phone's bottom (now
    318), and the extra button pushed the left column off the screen (now it wraps). Replayed after merging main's
    Robux store: the menu opened by itself at 44 s, Day 1 and Day 7 claims worked, 72 tests pass, console clean.
  - *Merged into main* on the user's word: the prize amounts are good and the phone layout (the wrapping column) is
    fine.

- **First publish: a private test experience (2026-10-05)**. The user: "save everything that's currently there and
  then publish it to a real Roblox experience ... keep it private for now, just to test it out". Published main at
  3c5ee43 (everything merged by then) as "Steal a Sheep": universe 10769564664, place 114389615931493, owned by
  getajobgle, audience Private. The daily gifts, merged into main just after, aren't in it.
  - *The place*: the main Studio held scripts from before the store, the Merge Shrine gamble and friend boost (31
    changed, 10 missing). Main's scripts went in from `rojo build tools/sync.project.json` (GetObjects swap); all 115
    then matched main and the old ones were deleted. Its Studio-side content matched a fresh `assemble.luau` build
    exactly (fingerprint: instance counts, names, part positions and volumes per service).
  - *Before publishing*: the debug panel, debug speed, pretend friends and the store's free grants are all Studio-only
    (`RunService:IsStudio()`); a live server answers "Not on sale yet" for every store item. Saves and leaderboards use
    separate `_Studio` stores in Studio.
  - *Publishing*: File > Publish to Roblox > Create (Creator Me; Computer, Phone, Tablet and VR; Team Create and Data
    Sharing left at Roblox's defaults, on). Turning on Team Create logged HTTP 429 failures for the scripts' version
    history, but the reopened cloud place's 115 scripts still matched main. Then Studio access to API services on, and
    Maximum Visitor Count 5 in Creator Hub (it read 50).
  - *Checked*: `check.ps1` passes; before the publish a playtest of the place had both bootstraps ready, 66 tests
    passing and only the "not published" notices; after it, `develop.roblox.com/v1/universes/10769564664` says
    `privacyType` Private, Creator Hub shows Access and Audience Reach Private, and a Studio playtest of the cloud place
    had both bootstraps ready, 66 tests, ProfileStore "data will be saved" and no warnings. Not joined in a real
    server yet.
- **The Robux store (2026-10-05)**. The user: a shop "just to buy stuff for Robux", reusing Shear a Sheep's store:
  pay-to-win sheep, 2x Growth and 2x Money passes, 2x Speed (3 Robux in Steal an Egg), the treadmill's upgrade for
  Robux beside its cash price, six Climbing ("speed") packs and five cash packs (24K for 45 up to 8M for 720); mock-ups
  first. Five rounds: A (HTML in the game's icons, from Studio's cache), B (their reference: square studs, bigger art
  that grows with the pack, a designed 2x Speed), C (containers redrawn as single icons: "the chest ... looks sloppy"),
  D (the climbing shoe as Hermes' winged sandal, from their picture; cash, never coins), E (the tabs outside the window,
  no scrollbar). Their calls: red then the sandal with white wings (gold on 2x Speed only), 2x Speed re-buyable at
  three times the price each buy, the walker 19 then +20% a level, the filled-in prices kept, tabs tighter and closer.
  - *Shared*: `Config/Store` (what's sold, prices, ladders, product keys; Creator Hub ids empty), `Economy.RobuxSheep`
    (Golden Fleece 10x, Kronos 3x the flock's best other sheep: `BestIncome`), income functions take `best`,
    `Earn`/`Offline` take the growth multiplier, `DoubleClimb`; `GameConfig` looks for the two (Shear a Sheep's Golden
    Fleece colours with new gold sparkles, its Time Sheep build); `Theme.Icons.Store*` and `HudRobux`, `HudShoe` now
    the sandal.
  - *Server*: `StoreService` (the remote `RequestPurchase`: picks 2x Speed's next step or the walker's level, one dialog
    at a time, Studio grants what isn't on Roblox; mirrors `Pass<Key>` and `PassesChecked`); `PurchaseService` maps a
    receipt's product id to its key, `Products` grants by key (cash, Climbing, 2x Speed, walker, sheep); `FlockService`
    multiplies income by 2x Money everywhere it shows and growth by 2x Growth (offline credit waits for the passes),
    `AddRobuxSheep`; Robux sheep can't be sold (`Roster.CanSell`) or merged. Main's StairMaster sign (its placeholder
    Robux prices were waiting on this session) now asks `StoreService` too, and shows the store's price.
  - *Client*: `Screens/Store` (built at runtime from UIKit: sections, cards, the 3D sheep, the outside tabs that light
    with the section in view and scroll on a tap, shrinking on a short window), `Prices` (Roblox's price once a product
    has an id), the HUD's STORE on the right edge, the Flock menu's line for store sheep. `Motion.PopIn` now follows a
    window's Fit if it changes mid-pop: on a phone the store and the Free Gift opened at full size, past the bottom.
  - *Art*: `art/store/make_store_art.py` draws every picture (SVG containers and sandals, gvesster's pack icons placed
    as they are, one outline round each) and exports them for upload; the output stays out of git (the pack's licence).
  - *Checked*: `check.ps1` passes; 66 tests pass in Studio (new: prices and ladders, every product key granted, Robux
    sheep income, 2x Growth offline). Main's Studio with the branch's scripts swapped in (put back after, not saved):
    both bootstraps ready, no errors; STORE opens the store; Golden Fleece bought (income 79K/s to 794K/s, its label
    +715K/s, 10x the best other sheep's 71.5K/s); 2x Speed twice (Climbing 25 to 50 to 100, price 3 to 9 to 27); the
    walker for Robux then cash (level 1 to 3, prices 19 to 27 and 1.2K to 7.5K); 2x Money doubled income exactly and
    showed Owned, a second buy refused; a Robux sheep refused at the Sell Stall and the Merge Shrine. Galaxy A06
    sideways: the window fits after the Motion fix, all five tabs fit, the Cash tab scrolls there. Screenshots in the
    session (`steal-a-sheep-store-built-*.jpg` in T3 Code's attachments). After merging main's Merge Shrine gamble: 66
    of 66 tests, Kronos bought (3x), the shrine's menu lists only the mountain's sheep with Kronos in the flock, console
    clean. The user: merge it, STORE on the right edge is fine, Creator Hub later.
- **The Merge Shrine: the Laurel Ring, a gamble like Steal an Egg's Fuse Machine (2026-10-05)**. Merged into main at
  the user's request.
  - *How it works*: `ShrineService` builds the Laurel Ring (`ShrineService/Model`) where the Mutation Machine stood
    (`GameConfig.Shrine.At`) and runs the merge: `FlockService.ShrineMerge` checks three grown, unlocked sheep of one
    family and the price (`Economy.ShrinePrice`), takes them and the cash, and makes one lamb from `Economy.ShrineRoll`
    (fleece from `ShrineFleeceOdds`, weight from the Climbing session's `RollWeight` with `ShrineLuck`, size from
    `RollSize`), saved at once with `Shrine = true` (out of the pen, can't be equipped or sold). Its owner's client
    plays the merge (`ShrineController/Show`, the approved mock-up's beats) and leaves the lamb on the altar with a
    Pick up prompt; `Remotes.ShrineCollect` puts it over their head (`WildService.CarryLamb`, no god), and main's put
    down delivers it (`FlockService.ShrineArrive`, at the spot). Return, dying, leaving, or 30 s on the altar send it to
    the pen. The Merge menu (rewritten) is the camera on the shrine with no backdrop, the odds panel
    (`Economy.LuckySizeOdds`, the real roll's spread), the shop's rows and a big Merge button; picks stand on the
    pedestals (`ShrineController:Preview`). Titan grow-ups get the biggest sound.
  - *The user's calls*: DECISIONS.md, *The Merge Shrine is a gamble*. Steal an Egg research: three of the same species,
    a cash fee, an egg of that species with its weight rerolled (it can come out smaller), mutations lost, rarity never
    changes; plus a separate secret shrine for two-pet recipes.
  - *Checked*: check.ps1; 56 tests (a new shrine test: rules, luck, odds summing to 100, the roll). Playtested in my
    own Studio copy, before and after rebasing onto main's free-roaming pens: the menu, picks on the pedestals, the
    merge end to end (cash and the three taken, the lamb in the flock), the merge show recorded, pick up and carry
    (weight on the carry attribute), put down in the pen (the lamb hops in and grazes), the Return button, the 30 s
    auto send home, and the refusals (too far, mixed families, a lamb in, two, the same twice, a second merge while
    a lamb waits, rate limit). Not checked: two players, leaving with a lamb waiting, touch and gamepad, a Titan.
    The user then: commit and merge it; the price is fine for now; Titan x5; 30 s on the altar is good. After merging
    main (the Sell Stall, friend boost, free gift): the Sell Stall leaves a waiting lamb out and the server refuses it;
    60 of 60 tests, console clean, a merge paid, picked up and sent to the pen in a fresh build.

- **Friend boost (2026-10-05)**. The user asked for a simple friend multiplier like other games: each friend in the
  server multiplies your income. Mock-ups A (a pill under the cash) and B (a tile under the menus, tap to invite) on
  a real HUD screenshot; the user picked B, the INVITE state at 0 friends, and +20% a friend (over the proposed +10%).
  - *Shared*: `Economy.FriendShare` 0.2, `MaxFriends` 4, `FriendBoost(friends)`. `Theme.Icons.HudFriend` and
    `HudInvite`: gvesster's Free Icon Pack v3.1 `Player/Friend` and `Player/Add Player` (1st Outline, 256 px), the
    cash icon's pack, uploaded through the Studio MCP.
  - *Server*: `FriendService` asks `IsFriendsWithAsync` once per pair (the later joiner asks), keeps pairs while both
    stay, sets the `Friends` attribute and sends the join notices. `FlockService`'s tick multiplies the income it pays
    by `FriendService:Boost`. Studio: `DebugFriends` attribute, debug panel "Friends in server (id)" (`SetFriends`, -1
    for the real count).
  - *Client*: `Hud` adds `Tiles.FriendButton` (order 4): HudFriend and "+N%" in lime with friends here, HudInvite
    and INVITE without; a tap runs `CanSendGameInviteAsync` then `PromptGameInvite`. The cash rate shows income x
    boost.
  - *Checked*: `check.ps1`; 57 of 57 tests (FriendBoost new) in a Studio copy of the place with this branch's code;
    both bootstraps ready, console clean. INVITE tile with the uploaded icon; pretend 2 friends: tile "+40%", cash
    paid 6.57/s -> 9.19/s (x1.40); 4 friends +80%, 9 capped at +80%, back to INVITE at -1; the join notice drawn;
    tapping the tile opened Roblox's Invite Friends dialog (closed without inviting). Real friends untested.
    After merging main (the free gift's GIFT button now tops the same column): 60 of 60 tests, console clean, the
    five buttons fit a 793-pixel-tall window (INVITE ends at y 690), 1 friend showed +20% and +7.8/s on 6.5/s. The
    user then: commit and merge it; no notice when a friend leaves; the tile's tutorial hiding left to the agent.

- **Free gift for liking and favoriting (2026-10-05)**. The user, with a reference from another game (a "Free Gift!"
  panel: the reward big, numbered steps with a picture of the game page's button, Claim): give players something
  like climbing speed and cash for liking and favoriting the game (no community to join yet), in the Shop's UI.
  - *Reward*: `Economy.GiftReward(walkerLevel, income)`: 180 s of the stair walker's rate (no trail) in Climbing and
    180 s of the flock's income in coins, at least 500 of each, so it's worth the same few minutes whenever it's
    claimed. The snapshot carries `FreeGift`, `GiftCoins`, `GiftClimb`; the menu shows those.
  - *Claim*: `GiftService` (`Remotes.ClaimGift`, no arguments) gives it once per player (saved `FreeGift`) and returns
    what it gave. Claim first opens Roblox's favorite prompt (`AvatarEditorService:PromptSetFavorite(PlaceId, Asset,
    true)`) and claims only on `PromptSetFavoriteCompleted` = Success; in an unpublished place (PlaceId 0) the prompt is
    skipped. No game can see a like, so step 1 is asked, not checked; the server can't check the favorite either and
    takes the claim on trust, capped at one.
  - *UI*: `Screens/Gift` (a Medium Prize Fleece menu, cyan `Lab` header, the gift on a stage, the two rewards, two
    step tiles with a thumb-up row and a Favorite star under red pointers, a green Claim). HUD: `GiftButton` (GIFT,
    top of the left column) with a red "!" and the hint glow, gone once claimed. It opens by itself once a session, 30 s
    after it can be claimed (after the first delivery), once the player is off the mountain, not carrying, and no menu
    is open. Claiming closes it and plays the "FREE GIFT!" celebration with what was given.
  - *Checked*: `check.ps1` passes. Own Studio on `build/GiftPlaytest.rbxl` (branch code via `rojo build` +
    `GetObjects`): both bootstraps ready, 38 tests pass, no warnings. After a debug delivery the menu opened by itself
    at 31 s; Claim gave +500 Climb Power and +500 coins (25 → 525, opening tier 2, before main's Climbing rework), celebrated, hid the HUD button; a
    second claim was refused; `ResetGift` brought the button back and it opened the menu; the coin line then read +900
    (income 5/s). Two looks rendered as mock-ups (cyan, gold). Not checked: the real favorite prompt (needs a published
    place), phones. Then main's Climbing rework merged in: the gift now reads +500 Climbing; replayed on the
    merged build (42 tests pass, opened at 31 s, Claim gave +500 Climbing and +500 coins, console clean).
  - *Redesign, the user's notes*: no gift picture inside (the header's badge is enough), show off what they get, and
    the like and favorite steps looked too basic (emoji, plain arrows): make them professional and say exactly what to
    do. Now a Large panel 470 tall: the rewards ("+500 CLIMBING + +500 CASH") big on one stage of rays (variant B: each
    on its own gold or green stage, `SPLIT_PRIZE`); each step a numbered card with a picture of Roblox's real game page
    (roblox.com in its dark theme via Playwright at 4x, vote counts hidden, the other buttons faded, the one to tap
    glowing green or gold with a 👆 tapping it; `build/gift-art`) and one line ("Tap 👍 on the game's page", "Tap
    here, or ⭐ on its page"). Tapping the favorite card opens the prompt and ticks it. The pictures are Studio-local
    (`rbxasset://sas/gift-*-2.png`) until uploaded. Checked after merging main (pens, leaderboards, cash): 54 tests
    pass, opened at 31 s, the favorite card ticked with "Favorited! Now claim your gift", Claim gave +500 Climbing
    and +500 cash, console clean.
  - *The user's calls*: variant A (one stage); upload the pictures; it has to really register the like and the
    favorite and give the gift. No game can see a like (no API: AvatarEditorService covers favorites only; nothing
    in the docs for votes), so the gift registers the favorite: Claim or the favorite card checks
    `GetFavoriteAsync` first (someone who favorited before has nothing to say yes to), then prompts, then checks
    again. Pictures uploaded through the Studio MCP's `upload_image` (served on 127.0.0.1): like
    rbxassetid://79093897520396, favorite rbxassetid://94266843104437; `art/gift/step-pictures.js` remakes them.
    Checked in a playtest: both pictures load from Roblox, Claim gave +500 Climbing and the cash, a second claim was
    refused, 54 tests pass, console clean. Not checked: the real favorite prompt (needs a published place).
  - *Merged into main* on the user's word, after main's StairMaster walker, Sell Stall and punch were merged in and
    played again (59 tests pass, opened at 31 s, +500 Climbing and +900 cash at 5/s income, second claim refused).

- **The Sell Stall's menu, and a two-minute sell price (2026-10-05)**. The user sent Steal an Egg's Sell Pets (and
  its Free Gift) and asked for mock-ups of the menu the Sell Stall by the plots opens: like the reference, made easier.
  - *Mock-ups* (`DESIGN/ui/mockups/sell-stall.html`, two rounds): A, the grid four across with a sell tile on the
    right; B, the reference's layout (sort on the left, the total along the bottom); a pick-everything-stored button;
    one confirm for the lot.
  - *The user's calls*: A; it opens with nothing picked and each sheep is tapped; keep Select all; the pen's sheep
    don't show at the stall at all, so the best can't be sold by mistake (moving the best stored ones into the pen
    comes later); selling pays two minutes of income to start (Steal an Egg pays about 100 s).
  - *Server*: `Economy.SellSeconds` 120 (was 15). `Remotes.Sell` (ids, up to the flock's 100; 4 a second) ->
    `FlockService.Sell`: `Roster.CanSell` (stored only, unlocked, each once, never the whole flock), then every price
    paid at once and one snapshot. The one-at-a-time `FlockAction "Sell"` is gone.
  - *Client*: `Screens/SellStall`, built at runtime from UIKit like the other menus: `MenuParts.CardGrid` cards with a
    red ring and tick when picked and a LAMB / MERGED / size chip, a `SellTile` (fan of picked tokens, total, Select
    all / Clear, Sell N), the menu's confirm with the count, the Sell accent (`Theme.Fleece.Accent.Sell`). The stall's
    prompt opens it (`PromptController`); the Flock menu lost its sell mode. UIController mounts screens from an
    explicit order list: the new screen had to go in it (it was missing at first and never mounted).
  - *Kit*: `DESIGN/ui/` (README): Shear a Sheep's Prize Fleece CSS, `kit.js` with this game's token and HUD,
    `export-data.luau` (Lune loads `GameConfig`, `Olympus` and `Economy`, so every price is the game's) and
    `render.mjs`. The mock-ups were HTML: when they were made, five Studios were open and 2.6 GB of RAM was free.
  - *Checked*: `check.ps1` passes; 57 tests pass in Studio (new: `CanSell`, the two-minute price). Playtested in this
    session's own Studio (`build/SellPlaytest.rbxl`, code swapped in from `content/sas/sell-sync.rbxm`), on main's
    code too after merging it: both bootstraps ready; the stall's prompt (E) opened the menu with only the 8 stored
    sheep (the 6 in the pen absent); taps picked with ring and tick and summed (120 + 360 = 480); the locked lamb
    refused with its notice; Select all took the 7 unlocked (5.1K) and turned into Clear; the confirm showed x7 and
    5.1K; Sell left only the locked lamb, income unchanged (3,865/s), "Sold 7 for 5.1K cash". Called directly, the
    server refused a pen sheep, a locked one and a missing id, and the old FlockAction Sell. Your Flock has no Sell.
    Console clean. Not checked: a phone screen, gamepad, two players. The user then said build it and merge it; it
    was checked again on main's latest code (57 tests, a sale, a pen sheep refused) and merged into main.
- **Stair walker: a StairMaster outside the pen (2026-10-05)**. After the study below, the user: the first five looks
  are good, stick with five for now; the level floats over the machine; place it outside the pen, very close, like
  Steal an Egg's treadmill; an upgrade sign beside it to upgrade directly with cash or Robux. Earlier calls: gym at
  level 1 getting better each level, snap on like a treadmill, steps faster each level.
  - *Shared*: `Utils/StairClimb` holds the machine's stair geometry (treads 3 x 0.6 x 1.0, eight steps, those between
    -1.9 and 3.5 steps from the lower foot on show), `StepSeconds(level)`, `StepAt`/`StepParts` (where each step's
    three parts are at a given cycle), `Rig(character)` (R15 joints from Motor6Ds or AnimationConstraints, the root's
    spot from the avatar's leg length; R6 hips), `Pose` (two-bone leg IK, arms forward, lean and bob; R6 swings),
    `Release`, `ExitAt`, `RobuxOffer`. `GameConfig.StairWalker`: step speed, animation range, Robux offers.
  - *Server*: `PlotService/Walker` builds the machine (model pivot = machine frame; `Body`, `Steps`, `Zone`,
    `TagAnchor` with the floating "LV n") and the `UpgradeSign` (two-sided board, `CoinPrompt` E and `RobuxPrompt` R
    with the owner's id); `Paint` rebuilds the body when the look changes and updates the level, screen, sign and
    prompts. `Build` places it at plot (61, 25) facing +z and the sign at (65.5, 18.5) facing the gate, clearing map
    decor there; the old in-pen walker is gone. `TrainingService` snaps the owner on when their root enters the zone
    (root anchored at the rig's spot, `OnWalker` attribute, the machine's `Climber`), steps them off on
    `Remotes.LeaveWalker`, death, carrying or being moved, and trains only while on. `ShopService` handles the sign:
    coins through the shop's own walker purchase, Robux by `PromptProductPurchase` (or the not-on-sale notice);
    `PurchaseService/Products` grants a level for each configured product. Debug: "Stair walker level (id)".
  - *Client*: `WalkerController` moves each nearby machine's steps (`BulkMoveTo`, its own cycle advancing only while
    someone climbs), poses every nearby climber after the Animator, releases their joints when they get off, and sends
    `LeaveWalker` on a jump. `MovementController`'s walk-on-the-spot is gone. `PromptController` hides other plots'
    sign prompts.
  - *Checked*: `check.ps1`; 44 of 44 tests (4 new in `StairClimb.spec`) in Studio; a solo playtest in a copy of the
    place with this branch's scripts: both bootstraps ready, console clean; walking into the entry snapped on (+2
    Climbing/s, meter shown), the sign's coin prompt took the machine to level 2 live (look, steps, tag, sign: LV 3,
    300 coins, R$ 39), the Robux prompt gave the not-on-sale notice, a jump put the player down behind the entry with
    animations back, walking in again snapped on; levels 3, 4 and 5 shown on the real machine; both sign faces
    readable; an R6 rig stood on the steps at the right height; empty plots show no tag. Screenshots shown to the user.
- **Stair walker study: free models, a climbing test, two mock-ups (2026-10-05)**. Not built yet. The user wants a
  proper StairMaster in place of the MVP machine (a base, five sliding planks, rails), free models first, and the
  player walking up the steps instead of walking on the spot in front of them.
  - *Free models*: none fits. Creator Store (stairmaster, stair climber, stepper, gym/cardio packs): treadmills,
    ellipticals, weights, a granite "Fancy Stairmaster" that isn't one. Sketchfab, Poly Pizza, Free3D, CGTrader,
    TurboSquid, Meshy, itch.io: none free. The only free genuine stepmills are realistic grey brand replicas on SketchUp
    3D Warehouse (Spiffysmile "Stair Master", 3.8k polygons, its General Model License allows use inside a game):
    wrong style for the map, and their steps are one mesh, so they couldn't move.
  - *Climbing test* (Studio copy, the user's skinned R15 avatar, then a default blocky R15 rig): the root is anchored;
    each frame after the Animator (`PreSimulation`) a two-bone IK sets hip, knee and ankle `Transform` in the leg's
    plane from the joints' own attachments (works on Motor6D and AnimationConstraint rigs), so the stance foot rides
    its step down and back and the other foot lifts onto the next step, toes at the tread's front edge, heel over the
    edge. Steps scroll one rise and one run per 0.55 s; 8 degrees of lean, a small bob, arms forward and pumping. The
    root height comes from each avatar's leg length (bottom foot at 96% reach), so feet land on the steps for both
    rigs. Frozen-phase screen captures made a GIF for the user.
  - *Mock-ups*: one geometry (treads 3 wide, 0.6 rise, 1.0 run, about 31 degrees; wedge side bodies, entry step, a hood
    the steps run into, rails at hand height, a console), two looks: A gym machine (light grey, dark trim, yellow
    accents and tread noses, a tilted screen on a post) and B Olympus (marble, gold trim and rails, two columns holding
    a marble tablet).
  - *The user's calls*: A's gym look is level 1 and each upgrade looks better, ending in the Olympus look; snap on
    like a treadmill; steps faster with each level. Then: mock-ups of levels 1-5.
  - *Levels 1-5 mock-up* (same shape, five copies in a row on plot 1, each with a climbing copy of the user's avatar,
    steps at `0.25 + 0.35 x 0.9^(level-1)` s): 1 Starter, plain grey with grey noses and black grips; 2 Sport, white
    with blue bands, grips and screen, yellow noses, silver rails; 3 Pro, black with red bands, red-and-chrome rails, a
    glowing red screen frame and a fan; 4 Turbo, black with cyan neon edges, noses, underglow and screen, diamond-plate
    treads, side vents; 5 Champion, white with a black band and gold trim and rails, glowing white noses, flaming
    torches either side of the console and a green laurel over it. Bronze and dark gold came out plain orange and
    yellow under the map's colour correction (saturation +0.7), hence white and gold. Shown as a line-up, close-ups and
    a 4 s clip filmed from the Studio window.
  - *Open for production*: every client must run the IK for every training player (`Transform` doesn't replicate) and
    scroll every machine's steps from a shared clock; the server places and anchors the player on the machine and
    releases them on jump or move; R6 needs a simpler leg swing.
- **Put lambs down anywhere in the pen; sheep roam and graze (2026-10-05)**.
  The user: instead of the delivery platform and fixed pads you unlock, be like Steal an Egg (bring the lamb into the
  pen and place it where you choose); sheep walk around on their own like Shear a Sheep's; lambs mostly eat off the
  floor, looking down and chewing with an eating face; make it fluid.
  - *Delivery*: the carry lasts until the thief puts the lamb down inside their own plot's fence. `PlotService/Build`
    makes an invisible `Pen` box filling each plot's fence (measured from the plot model's parts) and a `Keepout` box
    round the stair walker; the pads, the delivery pad and their decor clearing are gone. `WildService` sets the
    `InPen` attribute and warns in other plots; `PromptController` makes a local Put down prompt on the carried lamb
    while the player stands in their own `Pen` (`Utils/PenArea`, the same test on server and client); its
    `Remotes.PutDown` has the server put the lamb 4 studs ahead (clamped inside the fence) and call
    `FlockService:Deliver(player, wild, at, from)`.
  - *Pen sheep* (`FlockService/Pens`): models stand at a spot and stroll with Shear a Sheep's `Utils/Wander` (copied
    with its tests): the server picks each stroll every 0.25 s (within RoamRadius of home, inside the fence, off the
    walker, `PlotService:CanStand` (an overlap box, solid parts only, ground and game folders skipped) and
    `PathClear` (keep-out samples and a spherecast)), and sets `WalkAt` then `Spot`; the model moves on the server only
    when shown, grown or rebuilt. Arrivals (`DropFrom`, `DroppedAt`) land on the put-down spot or the nearest clear one.
    Saved sheep gained optional `HomeX`/`HomeZ` (studs from the plot's middle; validated, no migration). Slots still
    mean "in the pen" (1 to PenSlots), so Roster, Equip Best, merging and income are unchanged.
  - *Each device* (`AnimController`, rewritten): every penned sheep follows its hop or stroll (re-pivoted when the
    server moves the model), legs in step with the ground (`SheepClips.Walk`); the nearest 50 in 70 studs graze
    (`SheepClips.Graze`/`GrazeStage`: body tips 14 degrees, sinks a little, head tips 80 and the neck reaches so the nose
    touches the grass; bites tug and sweep, chews bob and roll), idle, happy-hop after landing, and swap faces (chew
    frames, Happy, Baa, Blink). Wild lambs carry `Lamb` and graze too.
  - *Eating face*: two variants drawn with Shear a Sheep's face helpers (`art/faces/chew_faces.py`, renders in
    `art/faces/renders/`, ignored), shown as a sheet and then filmed on a grazing tier 8 lamb (pictures loaded from
    Studio's content folder, nothing uploaded); the user picked A, "Munch". MunchA and MunchB were uploaded through the
    Studio MCP's `upload_image` (served on 127.0.0.1) as rbxassetid://140615494609777 and 118466923824368 and set as
    `ChewFaces`. AnimController preloads its face pictures one request each and swaps in only those that have
    arrived (or whose fetch status says Success), so a picture still in Roblox's review never shows as a blank face.
    Seen in a fresh Studio: the lamb chews with the uploaded Munch frames (filmed).
  - *The user's calls after seeing it*: merge it; the pen holds 8 to start, up to 20, very expensive to grow (Pen
    Space prices x6 a slot from 25K; older saves raised to 8 on load); sheep roam the whole plot at the same pace (the
    18-stud range round home is gone). Checked with `check.ps1` and the unit tests in Studio.
  - *A fix found filming*: a sheep made while the player is in the game (every put-down) could reach the client in
    pieces, its `Sheep` tag before its Motor6Ds and face: AnimController rigged it at once and it walked about stiff,
    never grazing or changing face (two takes in five). It now takes joints and the face from `DescendantAdded` too;
    three lambs put down in a row then all grazed, chewed, blinked and baa-ed (25 s face log).
  - *UI*: objective "Bring it into your pen" / "Put it down where you like" (and the full-pen warning); Flock card "In
    your pen"; Shop "Pen Space n/20".
  - *Checked*: `check.ps1` passes; 43 tests pass in Studio (Wander, PlayerData homes). Playtested solo in this session's
    own Studio on `build/PenPlaytest.rbxl` (main's Studio was in someone's playtest): a stolen lamb carried home, no
    prompt outside the gate or in another plot (the notice showed), "Put down" pressed with E landed it 4 studs ahead
    after a 0.47 s hop from head height; 8 then 12 sheep: 560 samples over 40 s found none outside the fence, on the
    walker or in solid decor, the nearest two 5.7 studs apart, all strolling; grazing seen (nose on the grass, chewing
    with the stand-in face) and filmed; store, equip (hops back in at home), grow-up rebuilds in place, merge (hops in
    at the first sheep's home), sell, and a full pen (stored, warning shown). Console clean. Not checked: two players,
    touch, gamepad, a real rejoin.

- **Coins renamed cash (2026-10-05)**. The user: there are no coins, just cash, all through the game. The nine messages
  that said coins now say cash (selling, the Shop's "Need ... more", Sheepdex rewards, the tutorial reward, the
  welcome-back card, the debug panel). Code names and saved data keep `Coins`; the map and the borrowed assets have
  no coin text (scanned with Lune). Tyche's crown of coins and the coin-clink sounds stay: decoration, not money.

- **World leaderboards (2026-10-05)**. The user: make the leaderboard actually work, on the map's billboard in the safe
  zone rather than inside a HUD icon. The map has four boards (`workspace.Base.Leaderboard`, two pairs at x 280, z
  28-66 and 303-341, facing the plots), so each ranks one thing. The first mock-up (Coins Earned, Top Income, Most
  Steals, Climb Power, a trophy by each title) drew the user's calls: the money is cash, not coins, so swap Coins
  Earned for This Server (the richest here) next to Top Income (the richest overall, best ever); the look is OK; drop
  the icon, words only.
  - *LeaderboardService* (folder): `Boards` (the four rankings, in the order of the boards sorted by z: This Server,
    Top Income, Most Steals, Climbing), `Score` (store encoding and the merge), `Face` (the screen). Each board gets
    an upright invisible part just in front of its panel with a SurfaceGui (50 px a stud), since the map's panels lie
    on their side. Every 5 s it measures each loaded player's values (their best this session; This Server takes
    their income now) and redraws the boards from the store's top 10 merged with this server's players. This Server
    has no store. Every 60 s it writes what went up
    (`UpdateAsync` with `math.max`) and reads each store's top 10 (`GetSortedAsync`), looking names up in one
    `UserService:GetUserInfosByUserIdsAsync` call. The last write happens on `DataService.PlayerReleasing`, and from
    `Destroy` for anyone still in at shutdown (it's destroyed before DataService releases them).
  - *Stores*: `Leaderboard_Income`, `_Steals`, `_Climb` (`_Studio` in Studio). Values are
    `floor(log10(1 + value) x 1e13)`: late-game income (about 5e14/s for a full pen at Zeus, stored in tenths) and
    Climb Power head past what an OrderedDataStore and Luau hold exactly. The order holds, and whole numbers come back
    exact below about 2e12. No saved data changed.
  - *Checked*: `check.ps1` passes. Playtests in a second Studio on a copy of the built place: both bootstraps ready, 41
    tests pass (5 new for `Score`: exact round trip to a trillion, order, under 2^53 at 1e300, the merge). Without
    DataStores the boards say "This server" and the console has one line saying so. After debug Climb Power and three
    sheep, all four boards showed the player within 5 s, matching the player list (2.38K/s, 48K); after selling the
    best sheep, This Server read 854/s and Top Income kept 2.38K/s. Screenshots of both pairs, words-only titles, with
    sample rows filled in on the client. Store writes and reads weren't run (unpublished place). Merging main
    (Climbing) retitled the last board CLIMBING, as everything on screen now says.

- **Climbing: one stat, no walls (2026-10-05)**. The user asked how chaser speed worked, then: climbing and speed
  should be one thing called Climbing; the steeper the slope the less it works, so going higher needs almost
  exponentially more; you can still climb when far too weak, just painfully slowly ("crawl", not slip back), and that
  slowness gets you caught on the way down. Walls removed completely, no delivery lock, no god lunge. For the gods
  they chose a fixed speed like Steal an Egg's and asked for it to be checked: guides say each zone has its own,
  faster guardian that never scales with the player, and you escape with enough Speed over the zone's minimum. Ours
  already did that, so `GodService` is unchanged.
  How it works: `Economy.ClimbShare` (Climbing / (Climbing + Reach)), `Mountain.ClimbSpeedAt` (18 studs/s times that,
  at least `Movement.CrawlSpeed` 1), `MovementController` caps the uphill part of a walk to it,
  `MountainService` keeps a per-player ceiling rising at that speed (x1.3, with 10 studs or 1 s of lead) and puts
  anyone above it back. `Economy.CarryMultiplier` keeps falling below Reach (to `UnderTrainedFloor` 0.45 of the
  burden's first value). `Economy.ClimbTier` (highest Reach held) replaces `Unlocked` for HUD goals, the training
  meter, Royal-lamb notices and the "in reach" notice. Gates became `TierSigns`. Every "Climb Power" on screen now
  says "Climbing"; the saved field stays `ClimbPower`.
  Then, after a napkin-maths explanation, the user made the chase "your speed vs its speed" like Steal an Egg: one set
  speed per god for the whole chase (`Economy.GodSpeed`, 0.8 x the tier's `SlideSpeed`), no god walking speed, and
  the escape speed from Climbing (`Economy.EscapeSpeed`, with burden weights replacing the old Carry tables), set when
  a slide starts and kept all the way down because momentum carries you (`MovementController` slideTarget).
  `Mountain.SlideSpeedAt` and the under-trained floor went. The carry card shows "you N, god N".
  Then, wanting as few numbers as possible, the user settled on one rule: your ratio is Climbing / (sign x lamb weight),
  your speed is the ratio below 1 and +1x per 4x above, no cap on the mountain, 7x for walking in the safe zone, tier 1
  never below normal; the sign is just enough for the lightest lamb, an average one leaving about 95%. Weight became
  hidden and a smooth range, saved with the sheep and tilting (not deciding) adult size; the Light/Stout/Heavy words
  and the carry card's speeds went. The Merge Shrine session asked for the weight interface: `Economy.RollWeight(random,
  luck)`, `SizeOdds(weight)`, `RollSize`, `LambScale`, a placeholder Titan size. Schema 2 migrates Burden to Weight.
  `Mountain.SpeedAt` replaced `ClimbSpeedAt`; slides now reach their speed in about 2 s.
  Checked: `check.ps1`; 40 of 40 tests in Studio; a playtest in StealASheep.rbxl with this branch's scripts swapped in
  (main's put back after, not saved): the server put a client teleport to x 900 back to x 235; tier 3 uphill at 0,
  200, 800 and 12,800 Climbing measured 1.0, 4.4, 17.6 and ~54 studs/s; chases on tier 3 (god 25.6) with a 1.03
  lamb: caught at 200, escaped at 800 (24.9, god 39 studs behind), easy at 3,200 (50.7); at 1e9 Climbing walking on
  the plots stopped at 126, uphill ran 245 with no airborne samples, slides of 200-260 stayed on the floor; the carry
  card shows only the lamb's name. Console clean.
  Then the user kept gods walking home slowly and asked for dropped lambs: a caught (or dead) thief's lamb lies where
  they were for 30 s, anyone may steal it and its god chases them. Also a server ground-speed check (a budget refilled
  at the fastest legal speed; server teleports reset it). Checked in Studio: 45 of 45 tests; a thief caught on tier 3
  dropped the lamb 5 studs from the catch spot, the player walked back and stole it 16.5 s later and the god ran at
  them at once; left alone it went back to its pasture; a 200-stud sideways teleport was put back; no pull-backs on
  legal chases or a 254 studs/s slide.
  The user asked for a final scaling pass before playtesting. A simulated efficient player (steals once Climbing is
  1.15x the next sign, buys every walker level, pen and trail it can) reaches tier 10 in 30 min, tier 20 in 1.8 h and
  Zeus in 4.3 h; climbs never take over a minute (lower tiers zoom); every tier's numbers are in the same proportion
  (a walker level costs 60 s of one adult from the tier below), so nothing breaks, but Climbing outruns the signs
  10-70x between new tiers, so chases are easy most of the time.
  The user then raised walker costs (10x: about ten minutes of income per upgrade; simulated 6.5 h to Zeus, Climbing
  1.3-5x the signs), left trails alone (no prices decided yet), and replaced being sent home after a catch with a punch:
  the god launches the thief three tiers down (same share along the tier; the foot from tiers 1-3). The server picks
  the landing (`MountainService:Punch`), the thief's device flies them there on a tumbling arc (Remotes.Punch,
  MovementController), both movement checks wait for the flight, and the server puts them on the spot if they aren't
  there by then. Checked in Studio: 52 of 52 tests; caught 81% along tier 6, the thief flew 1.7 s and landed 82% along
  tier 3, 0.4 studs from the spot, no correction; a tier 3 catch landed at the foot (x 342); no script errors.

- **High Olympus's stretches lengthened to 275 (2026-10-05)**. The user felt tiers 13-30 were shorter than the first
  levels; measured from `Config/Olympus` they were: 210 studs along the floor against about 250 for tiers 1-3 and 6-9
  (4-5 are 126, 10-12 are 325), and 129-178 across the ground. The user picked 275.
  - *Builder*: `SURFACE_LENGTH` 275 (tiers 13-30 now 169-233 across, summit at x 6721, height 4439, was 3661).
    Stage 3's terrace unit covers only about 272 studs, so each stretch also takes the ends of the neighbouring
    copies, 251.16 studs along the floor, the map's own repeat (measured: stage 5 holds two copies that far apart, in
    their frame 251 along and 9.1 up, the 2 degrees between terrace and slab; shifting by the 9.1 too left the end
    copies floating 4 studs up). Decor counts scale by 275/210 (`DECOR_SCALE`, `c.Count`). Eris's crystals start at
    lane + 14 (one leaned 6 studs into the lane). Zeus's floor now stops at the top and the plaza starts flush with
    it: before, the plaza's edge was a ledge no walker could climb (pre-existing at 210).
  - *Config*: tiers 13-30's `XStart`/`XEnd` and the `Ramp` points regenerated from `UpperMountain.Layout()` (Lune).
  - *Checked*: `check.ps1` passes. Lune: no gaps along any stretch's terraces at floor level; at the joints only the
    terrace's own 2-stud notches. Second Studio on the built place: both bootstraps ready, 36 tests pass, 30 gods and
    72 High Olympus lambs on the floor, 29 gates, 0 collidable decor in any lane (5,013 checked), 13,519 parts (was
    10,547). On foot: 15 s a stretch at 17.5-18 studs/s, onto the summit plaza. Zeus theft slid down all eighteen
    stretches in 93 s, 0 of 843 samples in the air, Zeus falling behind (59 to 473 studs). Joints screenshotted.
- **High Olympus: thirty gods (2026-10-05)**. The user, liking the map: build out the next tiers from its parts and
  pieces, the top Olympus gods; then a list of thirty ("map parts for all of these gods"), Zeus on the new top, the
  look and studs indistinguishable from the original, each section grouped, the climb no steeper than about 60 degrees,
  gradual but noticeable. They asked for a preview mid-build and were shown screenshots of every stretch. Afterwards:
  keep 52 degrees at the top, no shortcut up the climb, obstacles on the higher levels later (they'll add them; it's
  barren now), and merge it to main.
  - *Map audit*: each old stage is a 190-wide floor slab (Studs material variant, a 0.9-transparent checker texture,
    tilted to the grade) between terraces of stacked blocks, repeated in 268-stud units (stage 3: a 198-block body
    model and a 67-part caps model holding the slab), plus decor models tilted with the stage. All colours are the
    parts' (the map's colour correction pushes saturation +0.7). Stage 7 ended in an 80-block wall across the path.
  - *Builder*: `tools/UpperMountain.luau` lays out eighteen stretches (210 studs along each floor, 32 to 52 degrees)
    from the old summit's top (3060, 1148.8), clones stage 3's slab and terrace units into each, trimmed and recoloured
    by source colour, un-tilts decor templates found by stage, name and part count, places them upright off the lane
    (ground heights from the terrace blocks' tops, no raycasts), and adds each god's block props and pixel sprites.
    Zeus's plaza and throne cap it. Seeded per tier, so one god's changes don't reshuffle another's. It runs in Lune
    (`tools/assemble.luau`) and in Studio (`tools/preview-upper-mountain.luau`); both builds came out at 10,547 parts.
  - *Code*: `Config/Olympus` holds thirty tiers (old summit to Aeolus, Zeus to 30) and the extended ramp profile;
    `GameConfig` eighteen families (Shear a Sheep's own colours for its builds, read from its GameConfig), five more
    faces and a Rainbow fleece paint; `SheepService/Extras` back wings, blindfold and flame; `GodService/Rig` hair and a
    signature for each new god; `Economy` stair walker levels 12-29. Two fixes the steep stretches needed:
    `GodService` steps gods' speed along the slope (a Humanoid's WalkSpeed is along it, so gods were outrunning
    sliders), and `MovementController` holds a slide down to the ramp (`Mountain.RampSlope`).
  - *Checked*: `check.ps1` passes; 36 tests pass in Studio (new: thirty tiers chain up the ramp, each with a family, and
    a minute of the right walker covers each reach gap). Playtest in the user's Studio with the branch synced in: both
    bootstraps ready, 30 gods on the floor, 29 gates, 121 lambs, none off the floor; lane check: no colliding decor in any
    stretch's lane; a slide from Zeus's pasture at 60 (37 across the ground at 52 degrees) went from 29% in the air to
    none; a Light Zeus theft at full training kept ahead of Zeus (gap 48 to 323 studs over High Olympus), then a
    straight-line slide stuck on stage 6's mid-lane pavilion and was caught; Sheepdex shows x/30 and scrolls; 27k parts,
    58 fps. Screenshots of every stretch, the families and the gods in the session.
- **The base design doc kept as background (2026-10-05)**. The user used the draft design doc as the base and will now
  refine the game as they go; later sessions mustn't hold changes against it. It lives in `DESIGN/BASE_DESIGN_DOC.md`
  with a note saying so; GAME_DESIGN.md describes the game as it is; DECISIONS.md says the user's requests win.
- **The MVP in one pass (2026-10-05)**. The user: copy the RobloxPack into the Steal a Sheep folder, read the game
  document, use the map in the folder and as much of Shear a Sheep as possible, keep new things MVP primitive, and
  complete it in one go.
  - *Base*: RobloxPack copied (no .git), renamed (StealASheep / studio/steal-a-sheep / "Steal a Sheep"), installed.
  - *Map audit*: the commissioned `vvs_map(commission) (1).rbxl` read with Lune and raycast in Studio: five fenced plots
    (x 121-231, gates east), two stalls, four leaderboards, a barn, and one ramp corridor east from the StartingLine
    (x 330) to the summit (x 3060, y 1149) in seven stages of 2-31 degrees. No terrain voxels. The ramp's floor profile
    is `Olympus.Ramp`; `Mountain.Floor` snaps to the real floor near it and looks through trees.
  - *Reused from Shear a Sheep*: UI kit (Theme, UIKit, Panel, Buttons, Motion, Scale, a trimmed Style), the sheep rig,
    73 add-ons and the breed builds (`BreedBuilds`, `SheepRigLayout`, `Looks`), the overhead carry (`CarryPose`,
    `CarryController` without the purchase stand-in), the procedural idle (`SheepClips`), `Sounds`, `Format`,
    `PlayerSettings`, `Preload`, and the Mutation Machine model as the Merge Shrine. The place-side pieces are copied
    once into `assets/ShearASheepAssets.rbxm` by `tools/extract-assets.luau` from a local copy of Shear a Sheep's place.
  - *Screens are built at runtime* from UIKit (the Shear a Sheep builders' pieces), so the place needs no Studio-side UI.
  - *Server*: SheepService (models: rig + Looks + primitive extras + fleece sparkle), PlotService (plots, pads,
    delivery pads, walkers, signs), FlockService (roster, pens, income/growth tick, offline credit, Sheepdex rewards,
    tutorial reward, Equip Best, lock, sell, merge, snapshot), GodService (12 block gods driven by AlignPosition/
    AlignOrientation along the floor; Idle/Alert/Run/Taunt/Return), WildService (48 spawns + private tutorial lambs,
    pickup, carry, delivery, failure rules, refills, royal announcements), MountainService (gates and their
    enforcement, slide-hit checks), TrainingService (walker), ShopService (walker levels, pen slots, trails, stations).
  - *Client*: StateController, SoundController (trimmed), UIController (Hud, Flock, Shop, Sheepdex, Merge, Popup),
    CarryController, MovementController (carry speed, slide, knockback, local gates, walker stepping), AnimController
    (sheep idle/carried, god limbs, baas), PromptController.
  - *Checked*: `check.ps1` passes; 34 unit tests pass in Studio (Economy formulas, Roster, PlayerData);
    solo playtests in a local copy of the built place through the Studio MCP (driven from a script): all spawns, gods,
    gates and plots built; tutorial lamb stolen by holding E, slid home at 20.1 studs/s (24 x 0.84) with Demeter
    chasing at the gentle rate, escaped at the safety line, delivered (+60 coins, +60 Sheepdex reward, +25 Climb Power),
    grew up in 30 s; a standing thief caught and sent home; a Stout lamb carried at 72% speed; stair walker training at
    2/s with the meter; walker upgrade bought; the gate pushed an untrained player back and ended their theft; a tier 7
    slide at ~38 studs/s with Apollo at 35.2; three adults merged (+8/s -> +9/s, as previewed); a sheep sold through the
    confirm; Flock, Shop, Sheepdex, Merge and Sell screens screenshotted. Not checked: two players, saving, touch,
    gamepad (CURRENT_STATE.md).
