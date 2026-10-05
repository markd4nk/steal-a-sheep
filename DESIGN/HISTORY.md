# History

What was built, newest first: how each part works, the user's calls on it, and how it was checked. Don't read it
whole: search it for the feature you're touching and read that entry. Add an entry at the top of *Built* when you
finish a task. The current state is `DESIGN/CURRENT_STATE.md`.

## Built

- **The draft design doc deleted (2026-10-05)**. The user is taking the game their own way and asked that later sessions
  not hold changes against the old plan. GAME_DESIGN.md now describes the game as it is; DECISIONS.md says the user's
  requests win; code comments no longer cite the doc.
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
