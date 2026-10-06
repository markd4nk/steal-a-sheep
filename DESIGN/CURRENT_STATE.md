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

- Not published. No Roblox place yet: the place is `StealASheep.rbxl`, built by `scripts/build-place.ps1` from the
  map (`vvs_map(commission) (1).rbxl`) with High Olympus built on top (`tools/UpperMountain.luau`), the Shear a Sheep
  assets (`assets/ShearASheepAssets.rbxm`) and the code.

## The game, and where each part lives

The MVP built in one pass on 2026-10-05 (HISTORY.md); the user now refines it as they go (GAME_DESIGN.md). Thirty
tiers: twelve up the commissioned map (Aeolus on its old summit) and eighteen on High Olympus above it, Zeus at the top.
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

- **Free gift** (like + favorite): Climbing and cash once (`Economy.GiftReward`), `GiftService`, `Screens/Gift`, the
  HUD's GIFT button; Claim needs the game favorited (Roblox's prompt, or favorited before). A like can't be seen.
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
  `art/store/make_store_art.py`. No products or passes exist on Roblox yet: Studio grants them with no dialog.
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
- **Sell Stall** (`UIController/Screens/SellStall`, `FlockService.Sell`, `Roster.CanSell`): the stall's prompt opens
  the stored sheep as cards; tap them or Select all, one Sell after a confirm, two minutes of income each. Sheep in the
  pen never show and the server refuses them; the Flock menu no longer sells.
- **From Shear a Sheep**: UIKit, Theme, Style (trimmed), Panel, Buttons, Motion, Scale, the sheep rig, add-ons and
  breed builds, Looks, CarryPose, CarryController, SheepClips, Sounds.
- **Merge Shrine** (merged 2026-10-05): the Laurel Ring replaces the
  Mutation Machine; three grown sheep of one family and cash make one rerolled lamb, carried home from the altar
  (GAME_DESIGN.md, *Merge Shrine*).

## In progress

- **The Robux store can't sell yet** (merged 2026-10-05; the user: Creator Hub later): once the game is published,
  make the 2 passes and 49 developer products (sheep 2, 2x Speed 7, stair walker 29, Climbing 6, Cash 5) at
  Config/Store's prices and put their ids in `Config/Store` (`PRODUCT_IDS`, `PASS_IDS`). `StealASheep.rbxl` wasn't
  rebuilt with the store: run `scripts/build-place.ps1` (or swap main's scripts into the open Studio).

- Nothing from the free gift session (merged into main 2026-10-05).
- Nothing from the pens session (merged into main 2026-10-05). The Munch eating face is uploaded and in the game
  (`Faces.MunchA`/`MunchB`; `art/faces/chew_faces.py` draws them).
- Nothing from the Sell Stall session (merged into main 2026-10-05, the user's go-ahead). DECISIONS.md's *To review*
  lists its calls; a Studio opened before the merge still shows the Flock menu's old Sell until it's rebuilt.
- Nothing from the Climbing session. DECISIONS.md's *To review* lists its calls.
- Nothing from the daily gifts session (merged into main 2026-10-05 on the user's word). The published place (the
  main Studio, Team Create) still holds main's scripts from before it until main is synced there and published.

## Not verified

- **Daily gifts over real days**: the 20-hour wait and the claims were tried with the debug day commands, not by
  waiting; keeping the day across a real rejoin is untested (the mock store). The HUD's wrapped column was seen on
  Studio's small phone (three columns of two), not on a tablet or a 390-point phone; the menu wasn't tried on PC
  after the compact layout, nor with a gamepad.

- **Real Robux purchases**: no product or pass exists yet, so nothing went through Roblox's dialog or ProcessReceipt;
  the store's buttons were tried with Studio's no-dialog grant. Pass ownership from Roblox, receipts while away and
  the one-dialog-at-a-time rule with a real dialog are untested. Store on a phone: Galaxy A06 sideways only.

- **Merge Shrine with two players** (another player mustn't see your picks, merge or lamb), **leaving with a lamb on
  the altar** (should go to the pen), **touch and gamepad** in its menu, and **a Titan's grow-up** (none rolled yet).
- **Friend boost with real friends**: tried with Studio's pretend count (debug "Friends in server"); real
  `IsFriendsWithAsync` pairs and the join notices between two real friends are untested until the place is published.
  The left column (GIFT, FLOCK, SHOP, SHEEPDEX, the friend tile) wasn't checked on a phone's short screen.

- **Sell Stall on a phone and a gamepad**: played on a PC window only (mouse); the layout matches the mock-up's phone
  frame, not checked in the Device Simulator.
- **Stair walker with two players**: another player's climb (posed on each device) and the owner-only sign prompts
  were only checked solo; the Robux upgrade can't be bought until its developer products exist.

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **All-servers leaderboards**: the place isn't published, so the boards ran on this server's players only; the
  store writes and reads, name lookups and the last write on leaving are untested.
- **Saving**: the place isn't published, so playtests used ProfileStore's mock store; rejoin, offline credit on a real
  rejoin and session locking are untested (the offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts (Steal, Put down), HUD buttons and the slide use
  Roblox's own input.
- **Pens with two players**: a lamb put down in someone else's plot is refused ("not your plot"), tried solo by
  teleporting into another plot; homes saved across a real rejoin and on a different plot number are untested.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **The free gift's favorite prompt**: skipped in Studio (PlaceId 0); `PromptSetFavorite` on the published place, its
  answer and the claim after it are untested.
- **Climbing in play**: playtested 2026-10-05 on tiers 1-3 and 6 with one player (TESTING.md); not on tiers 13-30,
  not with two players, not on touch or gamepad.
- **Upper tiers by foot**: tiers 7-12 weren't climbed on foot; tiers 13, 29 and 30 were (15 s a stretch, onto Zeus's
  plaza). By the numbers it's about 7.6 minutes from the plots to Zeus (a Humanoid walks its 18 studs/s along the slope) at normal speed;
  far under a tier's sign it's about 4 minutes a stretch.
- **High Olympus theft to delivery**: a tier-30 slide was measured through all eighteen stretches (no hops, Zeus
  falling behind), but no theft from tiers 13-30 was carried home and delivered on foot; and the climb speed check wasn't tried there.

## Known issues

- **The descent is full of the map's own trees, rocks and arches.** A slide that hits one slows, and stops if blocked;
  players steer round them; lanes stay as they are until the user adds obstacles (DECISIONS.md). Every run
  from High Olympus now passes through them: a straight slide from Zeus stuck on stage 6's pavilion (x 1890, mid-lane)
  and was caught. High Olympus's own lane is clear.
- **Long runs at the top**: about 7.6 minutes' climb to Zeus and about 2.5 minutes' slide home; the user keeps it all on
  foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **Pacing (2026-10-05 simulation)**: with walker upgrades at 10x, an efficient player reaches Zeus in about 6.5 hours
  (a real one maybe 2-3x that), Climbing about 1.3-5x the next sign. Trail prices are fixed and unreviewed (the user
  hasn't set them yet).
- **Very fast slides meet the trees hard**: at 150+ studs/s a slide that clips a tree stops dead and its god catches
  up (seen at x 944 on tier 3). Same decor issue, felt more at high speed.
- **Plots: 5.** A sixth player is kicked with "server full"; set Maximum Visitor Count to 5 in Creator Hub.
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are Shear a Sheep's uploads (Mark's account).
  They load if this game is published under the same owner.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- **Sheep may stroll across the map's flat hay scatter** (anything under 0.4 studs high isn't an obstacle), legs a
  little sunk in the straw.
- Studio MCP screenshots don't show ProximityPrompt buttons (Steal, Put down); they work in play.
