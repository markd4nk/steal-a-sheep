# History

What was built, newest first: how each part works, the user's calls on it, and how it was checked. Don't read it
whole: search it for the feature you're touching and read that entry. Add an entry at the top of *Built* when you
finish a task. The current state is `DESIGN/CURRENT_STATE.md`.

## Built

- **World leaderboards (2026-10-05)**. The user: make the leaderboard actually work, on the map's billboard in the safe
  zone rather than inside a HUD icon. The map has four boards (`workspace.Base.Leaderboard`, two pairs at x 280, z
  28-66 and 303-341, facing the plots), so each ranks one thing. The first mock-up (Coins Earned, Top Income, Most
  Steals, Climb Power, a trophy by each title) drew the user's calls: the money is cash, not coins, so swap Coins
  Earned for This Server (the richest here) next to Top Income (the richest overall, best ever); the look is OK; drop
  the icon, words only.
  - *LeaderboardService* (folder): `Boards` (the four rankings, in the order of the boards sorted by z: This Server,
    Top Income, Most Steals, Climb Power), `Score` (store encoding and the merge), `Face` (the screen). Each board gets
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
    sample rows filled in on the client. Store writes and reads weren't run (unpublished place).

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
