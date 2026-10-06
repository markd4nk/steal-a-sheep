# History

What was built, newest first: how each part works, the user's calls on it, and how it was checked. Don't read it
whole: search it for the feature you're touching and read that entry. Add an entry at the top of *Built* when you
finish a task. The current state is `DESIGN/CURRENT_STATE.md`.

## Built

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
