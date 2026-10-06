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

- **Private test version 5 (2026-10-05)**: main @ 3989273, everything up to six sheep a tier and the new Sheepdex
  (save schema 3); every server restarted onto it. "Steal a Sheep", universe 10769564664, place 114389615931493
  (`https://www.roblox.com/games/114389615931493`), owned by getajobgle (who owns Shear a Sheep's assets). Audience
  Private: only the owner and people with edit permission can play. Max 5 players, Team Create on, Studio access to API
  services on; no products or passes yet. Earlier: version 1 = 3c5ee43, version 4 = a71cab4 (2-3 were autosaves).
  Each publish needs the user's OK.
- **Limited audience (the user wants it: Friends and Playtesters) is blocked**: Creator Hub greys out Save until the
  game has a content maturity label, and the questionnaire isn't started. It needs the user's answers (the Merge Shrine
  is likely a paid random item: cash buys a random lamb, and cash is sold for Robux; its menu shows the odds).
- The main Studio is now that cloud place (Team Create: edits there last without a Save and ship with the next
  publish). `StealASheep.rbxl` (`scripts/build-place.ps1`: the map, High Olympus, Shear a Sheep's assets, the code) is
  the local copy sessions build their own Studios from; the main checkout's was rebuilt from 3989273.

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

- **Settings menu** (built 2026-10-05 on branch `t3code/sheep-stud-style-mockups`, not merged; its look waits for
  Mark's OK, `DESIGN/ui/mockups/settings.html`): a gear in Roblox's top bar opens Music and Sound effects in four
  steps and Reduce motion (`Screens/Settings`, `SettingsService`, `Remotes.SetSetting`, `Settings` in the save,
  `SoundController` volumes).
- **Icons for the 49 products and 2 passes** (2026-10-05, files waiting for Mark's OK, not uploaded):
  `art/store/make_product_icons.py` writes them to `.t3/userdata/attachments/product_icons/` (HISTORY.md).
- **The map's studs on every sheep** (built 2026-10-05, branch `t3code/sheep-stud-style-mockups`, not merged): half-size
  copies of the map's `Studs` material over every sheep's wool (`Looks.Studs`, `GameConfig.Sheep.Studs`), glowing
  studs on Neon wool, see-through studs on glass. The cloud place needs `studio/SheepStuds.luau` run in Edit before
  the publish that ships it; without the materials the wool stays plain and the server warns once.

- **Gods in rank order and Zeus as a Roblox avatar** (merged into main 2026-10-05 on the user's word):
  `Config/Olympus` reordered (Pan tier 1 to Zeus 30), new High Olympus stretches for the eleven Olympians who moved
  up; Zeus a catalog-dressed avatar. Not in a published version yet.
- **All 30 gods as Roblox avatars** (merged into main 2026-10-05 on the user's word, after their changes to Hebe and
  Demeter): each god's catalog look in `GodService/Looks.luau`, its held symbol in `GodService/Props.luau`; all 30
  load, 76 tests pass. Review shots: `studio/GodLineup.luau`. Not in a published version yet.
- **Blender god models (parked: the user chose Roblox avatars, 2026-10-05)**: Zeus and Hera built from shapes in code
  (`art/gods/`, README there), rigged, with a walk and a run. Not wired in.
- **Planned, later**: gods lunge face first at a thief and chase on their bellies like penguins (DECISIONS.md).
- **The Robux store can't sell yet** (merged 2026-10-05; the user: Creator Hub later): the game now exists on Roblox,
  so the 2 passes and 49 developer products (sheep 2, 2x Speed 7, stair walker 29, Climbing 6, Cash 5) can be made in
  universe 10769564664 at Config/Store's prices, their ids put in `Config/Store` (`PRODUCT_IDS`, `PASS_IDS`). Until
  then a live server answers "Not on sale yet".

- Nothing from the free gift session (merged into main 2026-10-05).
- Nothing from the pens session (merged into main 2026-10-05). The Munch eating face is uploaded and in the game
  (`Faces.MunchA`/`MunchB`; `art/faces/chew_faces.py` draws them).
- Nothing from the Sell Stall session (merged into main 2026-10-05, the user's go-ahead). DECISIONS.md's *To review*
  lists its calls; a Studio opened before the merge still shows the Flock menu's old Sell until it's rebuilt.
- Nothing from the Climbing session. DECISIONS.md's *To review* lists its calls.
- Nothing from the daily gifts session (merged into main 2026-10-05 on the user's word). The published place (the
  main Studio, Team Create) still holds main's scripts from before it until main is synced there and published.
- **Six sheep a tier and the new Sheepdex** (merged 2026-10-05): each god's six families (`Config/Herds`), rolled for
  every wild lamb; fleeces Plain / Shiny / Royal; Sheepdex rewards claimed in the new Sheepdex (`SheepdexService`,
  save schema 3) with a herd gift for all six. HISTORY.md has the details. Zeus's Legendary is the Golden Ram (the
  store's Robux sheep is the Golden Fleece). The gods' new order (t3code/order-olympian-gods) still has to merge for
  tiers to match the lineup the user OK'd.

## Not verified

- **Studs on every sheep on a phone and in a live server**: seen in a Studio playtest and in Edit on all 183 families,
  not on a real device; their cost on a low-end phone wasn't measured (no extra parts, only materials).
- **The live game itself**: the user has been in a live server (one player, moved onto version 5 by the restart), but
  no agent has watched one: checked only in Studio on the cloud place (both bootstraps ready, 76 tests, ProfileStore
  "data will be saved", no warnings). Unconfirmed in a real server: Shear a Sheep's meshes, faces and sounds loading,
  the debug panel staying hidden, the store's "Not on sale yet", a save carried from version 4 to 5.

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
  `IsFriendsWithAsync` pairs and the join notices between two real friends are untested. The place is Private, so
  friends can't join until they get edit permission or the audience changes (Limited needs a maturity label first).
  The left column (GIFT, FLOCK, SHOP, SHEEPDEX, the friend tile) runs off the bottom of a Galaxy A06 (800 x 360):
  SHEEPDEX is half off and the friend tile gone (seen 2026-10-05).

- **Sheepdex claim pressed with the mouse or a finger**: claims were made through `Remotes.ClaimDex` in a playtest (the
  menu then showed Claimed!, the badges and the green herd bar); the button itself wasn't clicked. Saving the claims
  (schema 3) is unit-tested only: the place isn't published.
- **Sell Stall on a phone and a gamepad**: played on a PC window only (mouse); the layout matches the mock-up's phone
  frame, not checked in the Device Simulator.
- **Stair walker with two players**: another player's climb (posed on each device) and the owner-only sign prompts
  were only checked solo; the Robux upgrade can't be bought until its developer products exist.

- **Two players**: slide hits and knockback (server checks, client knockback) were never tried with a second player.
- **All-servers leaderboards**: their stores open on the published place (no warning in a Studio playtest of it), but
  writes and reads across servers, name lookups and the last write on leaving are untested.
- **Saving**: a Studio playtest of the published place loaded a save from the real DataStore (`PlayerData_Studio`);
  saves in the live game (`PlayerData`), rejoin, offline credit on a real rejoin and session locking are untested (the
  offline maths is unit-tested).
- **Touch and gamepad**: only keyboard and mouse in Studio. Prompts (Steal, Put down), HUD buttons and the slide use
  Roblox's own input.
- **Pens with two players**: a lamb put down in someone else's plot is refused ("not your plot"), tried solo by
  teleporting into another plot; homes saved across a real rejoin and on a different plot number are untested.
- **Sound by ear**: cues are Shear a Sheep's library sounds, not listened to.
- **The free gift's favorite prompt**: skipped in Studio before the publish (PlaceId 0); `PromptSetFavorite` in the
  live game, its answer and the claim after it are untested.
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
- **Long runs at the top**: about 7.6 minutes' climb to Zeus and about 2.5 minutes' slide home; the user keeps it all on
  foot (DECISIONS.md).
- **High Olympus is sparse**: the user will add obstacles to the higher levels later.
- **Pacing (2026-10-05 simulation)**: with walker upgrades at 10x, an efficient player reaches Zeus in about 6.5 hours
  (a real one maybe 2-3x that), Climbing about 1.3-5x the next sign. Trail prices are fixed and unreviewed (the user
  hasn't set them yet).
- **Very fast slides meet the trees hard**: at 150+ studs/s a slide that clips a tree stops dead and its god catches
  up (seen at x 944 on tier 3). Same decor issue, felt more at high speed.
- **Plots: 5.** The place's Maximum Visitor Count is 5 (Creator Hub); a sixth player would be kicked with "server full".
- **Asset ownership**: the sheep meshes, faces, UI images and sounds are uploads by getajobgle, the account that owns
  the game too. Publish it under that account only.
- **ViewportFrames (the menus' 3D sheep) don't show in Studio MCP screenshots while the window is minimized**; they do
  in play.
- **Sheep may stroll across the map's flat hay scatter** (anything under 0.4 studs high isn't an obstacle), legs a
  little sunk in the straw.
- Studio MCP screenshots don't show ProximityPrompt buttons (Steal, Put down); they work in play.
