# History

What was built, newest first: how each part works, the user's calls on it, and how it was checked. Don't read it
whole: search it for the feature you're touching and read that entry. Add an entry at the top of *Built* when you
finish a task. The current state is `DESIGN/CURRENT_STATE.md`.

## Built

- **Put lambs down anywhere in the pen; sheep roam and graze (2026-10-05, branch `t3code/free-roaming-sheep-pens`)**.
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
  - *Eating faces*: not built; two variants drawn as mock-ups with Shear a Sheep's face helpers
    (`art/faces/chew_faces.py`, renders in `art/faces/renders/`, ignored) and shown to the user. Blink stands in
    (`ChewFaces`).
  - *UI*: objective "Bring it into your pen" / "Put it down where you like" (and the full-pen warning); Flock card "In
    your pen"; Shop "Pen Space n/12".
  - *Checked*: `check.ps1` passes; 43 tests pass in Studio (Wander, PlayerData homes). Playtested solo in this session's
    own Studio on `build/PenPlaytest.rbxl` (main's Studio was in someone's playtest): a stolen lamb carried home, no
    prompt outside the gate or in another plot (the notice showed), "Put down" pressed with E landed it 4 studs ahead
    after a 0.47 s hop from head height; 8 then 12 sheep: 560 samples over 40 s found none outside the fence, on the
    walker or in solid decor, the nearest two 5.7 studs apart, all strolling; grazing seen (nose on the grass, chewing
    with the stand-in face) and filmed; store, equip (hops back in at home), grow-up rebuilds in place, merge (hops in
    at the first sheep's home), sell, and a full pen (stored, warning shown). Console clean. Not checked: two players,
    touch, gamepad, a real rejoin.
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
