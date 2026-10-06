# Studio-side content

What the code expects in the place file, which isn't on disk: names, tags, key properties, which `studio/` script
builds each, and what the place holds now (saved to Roblox or not). Instances the code creates at runtime don't belong
here. Newest first.

- **2026-10-06, version 20 published** (saved and published; Team Create): main d8fc2b3's five changed scripts set
  in the cloud place (MountainService, GodService, MovementController, Utils/Mountain, Config/GameConfig) and
  `Tests/Mountain.spec` added; first checked that the place held exactly main b87e808's scripts (115 the same, only
  those five differing, nothing extra), after it 121 of 121 matching d8fc2b3. No Studio-side content changed.
- **2026-10-06, version 8 published** (saved and published; Team Create): main 3667692's scripts swapped into the
  cloud place (127, 0 differences). Two Studio-side changes since version 5, both rerunnable:
  - **High Olympus rebuilt** for the gods' new order: `workspace.Stages.HighOlympus` now holds `Tier13 Hypnos` ...
    `Tier30 Zeus` and `Summit` (23,317 instances), made in Edit by `tools/UpperMountain.luau` (packed into Studio's
    content folder by `tools/preview-upper-mountain.luau`, then `require(...).Build(...)` on `workspace`; it destroys
    and replaces its own folder).
  - **Five stud materials** in `MaterialService`: `SheepStuds`, `SheepStudsMetal`, `SheepStudsFabric`,
    `SheepStudsFoil`, `SheepStudsGlow` (`studio/SheepStuds.luau`), beside the map's `Studs`.
  - Against a fresh `build-place.ps1` build: the same 44,493 Workspace instances and names, and every part's position
    and size equal, except High Olympus's clouds, about 5% bigger in the cloud place. The builder takes the first of
    stage 7's matching cloud models, and Studio lists the map's children in a different order than the file, so it
    picked a near-twin (BRAIN proposal S46). They're pass-through decor off the lane. `StealASheep.rbxl` in the main
    checkout was rebuilt from 3667692.

- **2026-10-05, the Settings menu** (branch `t3code/sheep-stud-style-mockups`): no place changes. The menu and its
  gear (`PlayerGui.SettingsGear`, ScreenInsets TopbarSafeInsets) are made at runtime; the gear is the uploaded
  `Theme.Icons.MenuSettings`.

- **2026-10-05, the map's studs on every sheep** (branch `t3code/sheep-stud-style-mockups`): the code expects five
  MaterialVariants in `MaterialService`, copies of the map's `Studs` at 0.5 studs a tile: `SheepStuds` (Plastic),
  `SheepStudsMetal`, `SheepStudsFabric`, `SheepStudsFoil` and `SheepStudsGlow` (Plastic, its colour map as its
  emissive mask, strength 1.6). `studio/SheepStuds.luau` makes them (rerunnable, in Edit); `tools/assemble.luau` runs it
  on every built place. The cloud place got them with version 8 (above); without them the wool stays plain and the
  server warns once. The mock-ups' `TEMP_` models were deleted, and the borrowed `HerdsPlaytest.rbxl` Studio was closed
  without saving.

- **2026-10-05, daily gifts**: no place changes (the menu, the HUD's DAILY and the Pegasus Sheep are made at
  runtime; `SheepService` adds the Pegasus to `ReplicatedStorage.SheepLooks` with the other families). Its six
  pictures are uploaded images (`Theme.Icons.DailyCash1/3/5`, `DailyClimb1/3`, `Pegasus`). Tried in this session's own
  copy of the place (`build/DailyPlaytest.rbxl`); the main Studio wasn't touched.

- **2026-10-05, version 5 published**: main 3989273's scripts (six sheep a tier, the Sheepdex: 24 files, 120 scripts)
  swapped into the cloud place and checked (0 differences; Workspace fingerprint unchanged). No place changes.
- **2026-10-05, version 4 published**: main a71cab4's scripts (the daily gifts' 19 changed files) swapped into the
  cloud place and checked (117 scripts, 0 differences); its Studio-side content still matched a fresh build exactly.
  No place changes.
- **2026-10-05, published to Roblox** (private): the place now lives on Roblox as place 114389615931493 (universe
  10769564664, "Steal a Sheep", getajobgle's). Its first version is `scripts/build-place.ps1`'s output at main 3c5ee43:
  scripts checked one by one against `rojo build tools/sync.project.json`, the Studio-side content fingerprinted
  against a fresh `tools/assemble.luau` build (identical: 44,045 Workspace instances, same positions and sizes). No
  `TEMP_` instances, no debug attributes. Team Create is on and Drafts Mode off, so the main Studio holds the cloud
  place: edits there last without a Save. Open it with File > Open from Roblox, or Creator Hub's Edit in Studio.

- **2026-10-05, the Robux store**: no place changes (the store and its HUD button are made at runtime). Its 17
  pictures are uploaded images (ids in `Theme.Icons`). Tried in the main Studio with the branch's scripts swapped in
  and swapped back; nothing saved.

- **2026-10-05, friend boost**: no place changes (the HUD tile is made in code).

- **2026-10-05, the free gift**: no place changes (its menu and HUD button are made at runtime; its two step
  pictures are uploaded images). `StealASheep.rbxl` in the main checkout was rebuilt from main with it, and the open
  main Studio got main's scripts swapped in (not saved).
- **2026-10-05, free placement**: no place changes. The plots no longer get
  pads or a delivery pad, so the map's hay and trees inside the plots stay where the map has them (only the stair
  walker's spot is cleared); sheep walk round them. The code still expects `workspace.Base.Terrain` to be the ground
  (it's skipped by the sheep's obstacle checks) and each `PlayerPlot`'s parts to outline its fence (the pen box is
  measured from them).
- **2026-10-05, world leaderboards**. Nothing new in the place: `LeaderboardService` uses the map's
  `workspace.Base.Leaderboard` (a Folder of four `Leaderboard` Models, each with one big panel part whose front face,
  its LookVector, faces the plots; the rest are posts). It sorts the boards by the panel's z and adds a `<Id>Board`
  part with a `Screen` SurfaceGui to each Model at runtime. Without the folder the boards are off, with a warning.

- **2026-10-05, High Olympus at 275 studs a stretch**. Same instances as below, rebuilt longer by `build-place.ps1`:
  Zeus's top at x 6721.3, height 4439.1, the plaza from there to x 6811.3. `StealASheep.rbxl` in the main checkout
  was rebuilt with it; a Studio that had it open still shows the 210 version until reopened without saving.

- **2026-10-05, High Olympus**. `tools/assemble.luau` now runs `tools/UpperMountain.luau` on the map before saving the
  place: `workspace.Stages.HighOlympus` (Folder) holds one Model a god, `Tier13 Hypnos` ... `Tier30 Zeus` (each `Floor`,
  `Terraces`, `Decor`), and `Summit` (plaza, throne, colonnade). It destroys stage 7's end wall (the Model of 80 parts
  across the path at x 3077). It needs from the map: `Stages.Stage3`'s slab and its 198- and 67-part terrace models,
  the decor templates its `TEMPLATES` table names (stage, model name, part count, height), and `MaterialService.Studs`.
  The ramp's shape above x 3060 in `Config/Olympus.Ramp` comes from its layout, not a measurement. Nothing is saved in
  a place yet: the user's open Studio holds a preview of it, unsaved.
- **2026-10-05, the first build**. There is no Roblox place yet. `scripts/build-place.ps1` makes `StealASheep.rbxl`
  from three inputs on disk, so the place can always be rebuilt:
  - **The map**, `vvs_map(commission) (1).rbxl` (the user's commission), as it is. The code expects:
    `workspace.Base.PlayerPlots` (five `PlayerPlot` models; PlotService sorts them by z), `workspace.Base.Shop` (two
    stall models: the one at z 205 is the Shop, the one at z 175 the Sell Stall), `workspace.Stages.Stage1..7` (the ramp),
    `workspace.Decors` and `workspace.Base.Foliages`/`HayStacks` (decor PlotService may move out of the stair
    walker's way), and
    the ramp's shape in `Config/Olympus.Ramp` (measured; re-measure if the map changes). Workspace.StreamingEnabled is
    off in the map.
  - **Shear a Sheep's pieces**, `assets/ShearASheepAssets.rbxm` (from `tools/extract-assets.luau`), placed in
    `ServerStorage.Assets`: `SheepRig` (Model, PrimaryPart `Root`, pieces on Motor6Ds named after the piece, a `Face`
    Decal on `Head`), `SheepAddons` (73 Models of MeshParts with `Piece` and `Tint` attributes: wool styles, horns,
    `<Build>Wool` and `<Build>Extras`), and `WorldKit.MutationMachine`, which nothing uses since the Merge Shrine became
    the Laurel Ring (2026-10-05).
  - **The code**, from `rojo build default.project.json`.
- Made at runtime (not in the place): `workspace.Plots`, `Gods`, `WildSheep`, `CarriedSheep`, `PenSheep`,
  `TierSigns` (a floating sign at the foot of each tier from 2: "<God>'s <Area> / Climbing N"), `Stations`,
  `MergeShrine` (the Laurel Ring, ShrineService/Model; on each client `ShrineLocal` holds its pedestal previews and lamb), `ReplicatedStorage.SheepLooks` (a plain adult of
  every family, and the plain lambs `Lamb` and `Lamb<HornStyle>` that every lamb is marked on), the leaderboards' screens,
  every ScreenGui; on each client the chase's `ChaseScreen` (DisplayOrder -1, under the HUD) and
  `Lighting.ChaseGrade` (a ColorCorrectionEffect, off outside a chase), and the gods' chase sounds inside their Head
  and HumanoidRootPart (made on first use); and on a new player's client the onboarding's `workspace.GuidePath` (17 `Chevron` models of four
  parts, `UIController/GuidePath`). The trail needs nothing in the place: it reads each plot's `Pen` and the walker's
  `Zone` (PlotService) and walks round the map with PathfindingService.
- Set on the published place (2026-10-05): Maximum Visitor Count 5 (one player a plot, Creator Hub > Places > Access),
  Studio access to API services on (Experience Settings > Security), owned by getajobgle, who owns Shear a Sheep's
  assets.
