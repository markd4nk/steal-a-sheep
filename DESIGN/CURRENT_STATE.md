# Current state

The game as it is now. Agents read this at the start of every task and update it at the end. Newest state, not a
history: one line per item, details in the files below. Keep it under 300 lines (`check.ps1` fails past it).

| File | Holds | When to read it |
| --- | --- | --- |
| `DESIGN/GAME_DESIGN.md` | The game as it is now (the user refines it as they go: their requests win) | When the task touches gameplay |
| `DESIGN/BASE_DESIGN_DOC.md` | The base design the first build followed: background, not a spec | Why something was built the way it was |
| `DESIGN/HISTORY.md` | Every finished build, newest first: how it works, the user's calls, how it was checked | Search it for the feature you touch |
| `DESIGN/DECISIONS.md` | The user's confirmed rules, and agents' calls waiting for review | Before changing anything players notice |
| `DESIGN/STUDIO_CONTENT.md` | What the code expects in the place file, and what the place holds now | Before Studio-side work or a publish |
| `DESIGN/TESTING.md` | This game's test tools and how it was playtested | Before playtesting |
| `DESIGN/BRAIN_PROPOSALS.md` | Lessons proposed for the shared BRAIN, waiting for the user | When you learn something reusable |
| `DESIGN/ui/` | HTML mock-ups in the menus' look, from the game's own numbers (`DESIGN/ui/README.md`) | Before showing a new screen |

## Live

- **Private test version 20 (2026-10-06, 17:34 UTC)**: main @ d8fc2b3, version 8 plus the momentum slides (below);
  nothing else in code went out since 8 (main's other commits since were art and docs). Roblox numbers Team Create's
  autosaves too, so 9-19 were never published. Same place, audience still Private.
- **Private test version 8 (2026-10-06)**: main @ 3667692, everything through the overnight work: one message per
  moment, the game's own prompt buttons, the Settings menu, studs on every sheep, the 30 gods as avatars in rank order
  with High Olympus rebuilt for it, the store's real products, the region check. No servers were running, so none to
  restart. "Steal a Sheep", universe 10769564664, place 114389615931493
  (`https://www.roblox.com/games/114389615931493`), owned by getajobgle (who owns Shear a Sheep's assets). Audience
  Private, on the user's word ("it still needs to stay private"): only the owner and people with edit permission can
  play. Max 5 players, Team Create on, Studio access to API services on. Earlier: 4 = a71cab4, 5 = 3989273 (Roblox's
  numbers count Team Create autosaves: 6 and 7 were). Each publish needs the user's OK.
- **Maturity label: Mild** (questionnaire resubmitted 2026-10-06; answers in DECISIONS.md): Fear (Repeated/Mild) and
  Violence (Repeated/Mild), no non-compliant regions. It declares the Merge Shrine as a paid random item and that the
  game respects `ArePaidRandomItemsRestricted`, live since version 8. No genre yet (the user). Going public also needs
  the owner account's checks (age check, and for all ages ID, 2-step verification, Plus or the 1,000 Robux fee).
- **Store on Roblox**: 49 developer products and 2 passes at `Config/Store`'s prices, on sale and live in version 8,
  each with its store card's icon (uploaded 2026-10-06: `art/store/make_product_icons.py`, then
  `upload_product_icons.py` through Open Cloud; Roblox's moderation was clearing them the same hour). The Open Cloud key
  "Steal a Sheep products and passes" (developer products and game passes, read and write, this game only, no expiry;
  Roblox drops keys unused for 60 days) is in `.roblox/steal-a-sheep-open-cloud.key` under `C:/Users/markf` (that PC only), never in git.
- The main Studio is that cloud place (Team Create: edits there last without a Save and ship with the next publish).
  `StealASheep.rbxl` (`scripts/build-place.ps1`: the map, High Olympus, Shear a Sheep's assets, the code) is the local
  copy sessions build their own Studios from; the main checkout's was rebuilt from 3667692.

## The game, and where each part lives

The MVP built in one pass on 2026-10-05 (HISTORY.md); the user now refines it as they go (GAME_DESIGN.md). Thirty
tiers, the gods in mythological rank: twelve minor gods up the commissioned map (Pan first, Aeolus on its old summit),
then five more and the thirteen Olympians on High Olympus above it, Zeus at the top.
A god each, four wild lambs each, stair walker training, overhead carrying, the automatic downhill slide with steering,
braking and slide hits, pursuit, putting lambs down anywhere in your pen, roaming and grazing sheep, income, growth,
size reveal, Equip Best, locks, selling, merging, trails, pen space, the Sheepdex, offline earnings and the tutorial
lamb.

- **The pen** (2026-10-05): the whole fenced plot; carry a lamb in and press E to put it down where you like (no
  delivery pad, no pads). It holds 8 sheep, buyable up to 20. Sheep roam the plot (`FlockService/Pens`,
  `Utils/Wander`), avoiding trees, hay and the walker; lambs graze nearly all the time with the Munch face, adults now
  and then (`AnimController`, `Utils/SheepClips`). Where each was put down is saved (`HomeX`/`HomeZ`).

- **High Olympus** (tiers 13-30): one stretch a god, 275 studs along the floor, 32 rising to 52 degrees, from stage 3's
  floor slab and terraces and the stages' decor, recoloured, plus block props; Zeus's throne plaza on top. Built into
  the place by `tools/UpperMountain.luau` (Lune, in `build-place.ps1`); `tools/preview-upper-mountain.luau` previews it
  in an open Studio. Its layout and `Config/Olympus` (tier x ranges, `Ramp`) must agree: a test checks the chain.

- **Free gift** (favorite): Climbing and cash once (`Economy.GiftReward`), `GiftService`, `Screens/Gift`, the HUD's
  GIFT button; Claim needs the game favorited (Roblox's prompt, or favorited before; the user keeps that gate). No like
  step (Roblox's review policy forbids rewarding a thumbs up).
- **Stair walker**: a StairMaster outside each pen by the gate (`PlotService/Walker`: five looks, the level floating
  over it, an upgrade sign with cash and Robux prompts); walk in to snap on, jump to get off (`TrainingService`); every
  client runs the steps and poses climbers' legs on them (`WalkerController`, `Utils/StairClimb`).

- **Leaderboards**: the map's four boards by the plots (`workspace.Base.Leaderboard`): This Server (income now) and
  Top Income, Most Steals and Climbing (top 10 across all servers, this server's players drawn in live):
  `LeaderboardService` (OrderedDataStores, log-scaled values). The player list still shows Income and Climbing.
- **Robux store** (2026-10-05, merged into main): the HUD's STORE (right edge) opens one
  scrolling page with its section tabs outside the window: two Robux-only sheep, 2x Money / 2x Growth passes, 2x Speed
  (re-buyable, tripling), the walker's next level, Climbing and Cash packs. `Config/Store` (catalog, prices, ladders),
  `StoreService` (dialogs, passes), `PurchaseService/Products` (grants by key), `Screens/Store`; art from
  `art/store/make_store_art.py`. The products and passes exist on Roblox (Live, above); with their ids in, Studio
  shows Roblox's test purchase dialog instead of granting at once (the debug panel still grants).
- **Friend boost** (2026-10-05): +20% live income per Roblox friend in the server, up to 4 (`FriendService`,
  `Economy.FriendBoost`); the HUD tile under Sheepdex shows "+N%" or INVITE and opens Roblox's invite.
- **Daily gifts** (2026-10-05, merged into main): a week of gifts, the Pegasus Sheep on Day 7
  (`DailyService`, `Economy.DailyWeek`/`Specials`, `Screens/Daily`, the HUD's DAILY; the Pegasus's wings, halo and
  hooves are `SheepService/Extras` "Pegasus"). GAME_DESIGN.md, *Daily gifts*. The HUD's left column wraps into a
  second column on short screens.

- **Server**: `DataService`, `PurchaseService` (grants by Config/Store key), `StoreService`, `SheepService`, `PlotService`, `FlockService`,
  `FriendService`, `GodService`, `WildService`, `MountainService`, `TrainingService`, `ShopService`, `LeaderboardService`,
  `GiftService`, `DailyService`, `ShrineService`, `DebugService` (Studio only).
- **Client**: `StateController`, `SoundController`, `UIController` (Hud, Flock, Shop, Sheepdex, Merge, Gift, Daily, Store,
  Popup, Studio DebugPanel), `CarryController`, `MovementController`, `AnimController`, `ShrineController`,
  `PromptController`.
- **Shared**: `Config/Olympus` (tiers, gods, ramp profile), `Config/GameConfig` (looks, movement, carry, UI),
  `Utils/Economy` (every formula), `Utils/Mountain` (ramp height, tiers by position, floor checks).
- **Climbing** (merged 2026-10-05): one stat, no walls, one speed rule from Climbing and the lamb's hidden weight;
  gods at one set speed; weight saved and tilting size odds (`Economy.RollWeight`, `SizeOdds`, for the Merge Shrine).
  GAME_DESIGN.md, *Climbing* and *Lamb weight*.
- **Momentum slides** (2026-10-06, live in version 20): +15% of a slide's starting speed per sign
  passed, up to 100 studs/s (`Mountain.SlideBase`/`Momentum`); the god gets the same boost and keeps it through
  bumps; a bump is won back in 0.25 s and never trips you; the slide stops dead at the safety line. GAME_DESIGN.md,
  *Climbing*.
- **Sell Stall** (`UIController/Screens/SellStall`, `FlockService.Sell`, `Roster.CanSell`): the stall's prompt opens
  the stored sheep as cards; tap them or Select all, one Sell after a confirm, two minutes of income each. Sheep in the
  pen never show and the server refuses them; the Flock menu no longer sells.
- **From Shear a Sheep**: UIKit, Theme, Style (trimmed), Panel, Buttons, Motion, Scale, the sheep rig, add-ons and
  breed builds, Looks, CarryPose, CarryController, SheepClips, Sounds.
- **Merge Shrine** (merged 2026-10-05): the Laurel Ring replaces the
  Mutation Machine; three grown sheep of one family and cash make one rerolled lamb, carried home from the altar
  (GAME_DESIGN.md, *Merge Shrine*).
- **The gods** (version 8): thirty in mythological rank, Pan tier 1 to Zeus 30, each a catalog-dressed Roblox avatar
  (`GodService/Looks.luau` and `Props.luau`, `GodController`), its block figure if the catalog fails to load.
- **Onboarding trail and less hand-holding** (merged into main 2026-10-06 on the user's word, not published yet): Shear
  a Sheep's floor chevrons (`UIController/GuidePath`) guide only the first lamb (to Pan's meadow, home from the
  mountain's foot, then to the stair walker), no words, no floating arrow, no carried lamb's card or Return. After
  onboarding nothing tells the player what to do: no hints, no "in reach", no menu tips; refusals say only the fact.
  GAME_DESIGN.md, *Onboarding*; DECISIONS.md, *No hand-holding after onboarding*.
- **Stair walker pops** (merged into main 2026-10-06, not published yet): steps run at the climber's training rate
  (0.5 s to 0.1 s a step), each popping a shoe and "+N" off your head ("+1" twice a second at level 1, about ten
  "+2.5T" at level 30); your machine's floating level hides while you climb; no training meter.
- **What the HUD says** (version 8): one message per moment (`Screens/Hud`); every ProximityPrompt drawn as the menus'
  button for the device, press or tap (`PromptController/Look`). HISTORY.md, the overnight entry. Since the merge above
  the HUD gives no hints in words at all.
- **Settings menu** (version 8; `DESIGN/ui/mockups/settings.html`): a gear in Roblox's top bar opens Music and Sound
  effects in four steps and Reduce motion (`Screens/Settings`, `SettingsService`, `Remotes.SetSetting`, `Settings` in
  the save, `SoundController` volumes).
- **Studs on every sheep** (version 8): half-size copies of the map's `Studs` material over the wool (`Looks.Studs`,
  `GameConfig.Sheep.Studs`), glowing on Neon wool, see-through on glass. The five MaterialVariants are made by
  `studio/SheepStuds.luau` (in the cloud place since 2026-10-06); without them the wool stays plain and the server warns
  once.

## In progress

- **Blender god models (parked: the user chose Roblox avatars, 2026-10-05)**: Zeus and Hera built from shapes in code
  (`art/gods/`, README there), rigged, with a walk and a run. Not wired in.
- **Planned, later**: gods lunge face first at a thief and chase on their bellies like penguins (DECISIONS.md).

- **Game page art and a trailer, first cuts** (overnight 2026-10-05, nothing uploaded): icon and thumbnail mock-ups
  (`art/gamepage/`), a 31.9 s trailer in 16:9 and 9:16 (`trailer/`). The user keeps Roblox's default icon and
  thumbnails for now (2026-10-06). The 9:16 cut still carries the game's APM music, which can't go to TikTok or Shorts
  (BRAIN trailers.md): it needs a licensed track first.

- Nothing from the free gift session (merged into main 2026-10-05).
- Nothing from the pens session (merged into main 2026-10-05). The Munch eating face is uploaded and in the game
  (`Faces.MunchA`/`MunchB`; `art/faces/chew_faces.py` draws them).
- Nothing from the Sell Stall session (merged into main 2026-10-05, the user's go-ahead). DECISIONS.md's *To review*
  lists its calls; a Studio opened before the merge still shows the Flock menu's old Sell until it's rebuilt.
- Nothing from the Climbing session. DECISIONS.md's *To review* lists its calls.
- Nothing from the daily gifts session (merged into main 2026-10-05 on the user's word).
- **Six sheep a tier and the new Sheepdex** (merged 2026-10-05): each god's six families (`Config/Herds`), rolled for
  every wild lamb; fleeces Plain / Shiny / Royal; Sheepdex rewards claimed in the new Sheepdex (`SheepdexService`,
  save schema 3) with a herd gift for all six. HISTORY.md has the details. Zeus's Legendary is the Golden Ram (the
  store's Robux sheep is the Golden Fleece).

## Not verified

- **The onboarding trail on a real phone**: seen in a Studio playtest with Studio's phone emulation, walked by script
  (pen to meadow, the trail home, the walker); a player's own first run, a real phone's frame rate with the trail's
  pathfinding (a route each 1.5 s) and other plots than Plot1 weren't tried.
- **Studs on every sheep on a phone and in a live server**: seen in a Studio playtest and in Edit on all 183 families,
  not on a real device; their cost on a low-end phone wasn't measured (no extra parts, only materials).
- **The live game itself**: version 8 was checked only in a Studio playtest of the cloud place before its publish
  (both bootstraps ready, 84 tests, all 30 gods as avatars, 121 of 121 wild lambs studded, ProfileStore "data will be
  saved", a clean console); nobody has played it live yet. Unconfirmed in a real server: the debug panel staying
  hidden, a real purchase, a save carried from version 5 to 8 (no schema change: Settings is filled in by Reconcile).
  Every asset (1,286) loads in a Studio playtest (TESTING.md, Asset audit, 2026-10-05).

- **Daily gifts over real days**: the 20-hour wait and the claims were tried with the debug day commands, not by
  waiting; keeping the day across a real rejoin is untested (the mock store). The HUD's wrapped column was seen on
  Studio's small phone (three columns of two), not on a tablet or a 390-point phone; the menu wasn't tried on PC
  after the compact layout, nor with a gamepad.
- **Real Robux purchases**: Roblox's test purchase dialog with the real products granted +24K cash and 2x Speed
  step 1 in Studio, receipts saved (overnight branch); a real charge, a pass bought in game and receipts while away
  are untested. Store on a phone: Galaxy A06 sideways only.

- **The Merge Shrine's region check** (`PolicyService`, live in version 8): not seen answering in a live server yet.
- **Merge Shrine with two players** (another player mustn't see your picks, merge or lamb), **leaving with a lamb on
  the altar** (should go to the pen), **touch and gamepad** in its menu, and **a Titan's grow-up** (none rolled yet).
- **Friend boost with real friends**: tried with Studio's pretend count (debug "Friends in server"); real
  `IsFriendsWithAsync` pairs and the join notices between two real friends are untested. The place is Private, so
  friends can't join until they get edit permission or the audience changes (Limited needs a maturity label first).
  On a Galaxy A06 (800 x 360) the left column wraps into three columns of two, all six showing (overnight branch).

- **Sheepdex claim pressed with the mouse or a finger**: claims were made through `Remotes.ClaimDex` in a playtest (the
  menu then showed Claimed!, the badges and the green herd bar); the button itself wasn't clicked. Saving the claims
  (schema 3) is unit-tested only: the place isn't published.
- **Menus on a phone**: every menu checked on a Galaxy A06 in the Device Simulator (overnight branch); not on a
  real phone, a tablet or with a gamepad (the Controller Emulator switched the menus' hints to B, but the prompts'
  controller glyph wasn't seen).
- **Stair walker with two players**: another player's climb (posed on each device) and the owner-only sign prompts
  were only checked solo; the Robux upgrade can't be bought until its developer products exist.

- **Two players**: checked in a Studio Server & Clients test on the overnight branch (slide hit and knockback,
  "That's not your plot!", owner-only walker buttons, the shrine's private show); not with real players online.
- **All-servers leaderboards**: their stores open on the published place (no warning in a Studio playtest of it), but
  writes and reads across servers, name lookups and the last write on leaving are untested.
- **Saving**: three Studio sessions of a test player against the real Studio DataStore (`PlayerData_Studio`) kept
  the sheep, tutorial, cash, settings and receipts, with the welcome-back card's offline cash (overnight branch); the
  live game's `PlayerData` and session locking across real servers are untested.
- **Touch and gamepad**: the overnight branch's prompts and HUD were checked on a Galaxy A06 in the Device Simulator
  (touch); a real phone, a tablet and a gamepad are untested. The slide uses Roblox's own input.
- **Pens with two players**: a lamb put down in someone else's plot is refused ("not your plot"), tried solo by
  teleporting into another plot; homes saved across a real rejoin and on a different plot number are untested.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **The free gift's favorite prompt**: `PromptSetFavorite` in the live game (version 8), its answer and the claim after
  it are untested.
- **Momentum slides in play**: a tier 20 chase (the god 43 -> 69 studs/s with its thief, caught on tier 16) and tier 3
  runs to the line in a Studio copy (TESTING.md); not a full Zeus run through the map's trees, not two players, not
  touch or gamepad, not how 100 studs/s feels to steer.
- **Climbing in play**: playtested 2026-10-05 on tiers 1-3 and 6 with one player (TESTING.md); not on tiers 13-30,
  not with two players, not on touch or gamepad.
- **Upper tiers by foot**: tiers 7-12 weren't climbed on foot; tiers 13, 29 and 30 were (15 s a stretch, onto Zeus's
  plaza). By the numbers it's about 7.6 minutes from the plots to Zeus (a Humanoid walks its 18 studs/s along the slope) at normal speed;
  far under a tier's sign it's about 4 minutes a stretch.
- **High Olympus theft to delivery**: a tier-30 slide was measured through all eighteen stretches (no hops, Zeus
  falling behind), but no theft from tiers 13-30 was carried home and delivered on foot; and the climb speed check wasn't tried there.

## Known issues

- **180 sheep previews**: SheepService builds a preview model of every family for the menus' 3D views at startup
  (`ReplicatedStorage.SheepLooks`, about 5,800 parts); the Sheepdex draws a tier's sheep only when it scrolls near.

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them; lanes stay as they are until the user adds obstacles (DECISIONS.md). Every run
  from High Olympus now passes through them: a straight slide from Zeus stuck on stage 6's pavilion (x 1890, mid-lane)
  and was caught. High Olympus's own lane is clear.
- **Long runs at the top**: about 7.6 minutes' climb to Zeus; the slide home is 2.7 minutes at his sign's number (6.8
  one sign short) on main, 1.5 (2.6) with the momentum branch. The user keeps it all on foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **Pacing (2026-10-05 simulation)**: with walker upgrades at 10x, an efficient player reaches Zeus in about 6.5 hours
  (a real one maybe 2-3x that), Climbing about 1.3-5x the next sign. Trail prices are fixed and unreviewed (the user
  hasn't set them yet).
- **Very fast slides meet the trees hard**: at 150+ studs/s a slide that clips a tree stops dead and its god catches
  up (seen at x 944 on tier 3). Same decor issue, felt more at high speed. Momentum takes many more slides to 100 on
  the map's tree-filled stages: no straight lane runs clear from x 2300 down (raycast scan, 2026-10-06).
- **Plots: 5.** The place's Maximum Visitor Count is 5 (Creator Hub); a sixth player would be kicked with "server full".
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are uploads by getajobgle, the account that owns
  the game too. Publish it under that account only.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- **Sheep may stroll across the map's flat hay scatter** (anything under 0.4 studs high isn't an obstacle), legs a
  little sunk in the straw.
- Studio MCP screenshots don't show the prompts' buttons (AlwaysOnTop billboards in `PlayerGui.PromptUI`, BRAIN
  proposal S49); they work in play.
- **Phones**: the map is about 31,700 parts with StreamingEnabled off, so all of it loads at join; untried on a real
  phone (memory, join time). Turning streaming on needs the client's mountain code checked first.
