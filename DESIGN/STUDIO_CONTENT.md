# Studio-side content

What the code expects in the place file, which isn't on disk: names, tags, key properties, which `studio/` script
builds each, and what the place holds now (saved to Roblox or not). Instances the code creates at runtime don't belong
here. Newest first.

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
  place: `workspace.Stages.HighOlympus` (Folder) holds one Model a god, `Tier13 Iris` ... `Tier30 Zeus` (each `Floor`,
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
    `<Build>Wool` and `<Build>Extras`), `WorldKit.MutationMachine` (the Merge Shrine; a primitive altar if missing).
  - **The code**, from `rojo build default.project.json`.
- Made at runtime (not in the place): `workspace.Plots`, `Gods`, `WildSheep`, `CarriedSheep`, `PenSheep`,
  `TierSigns` (a floating sign at the foot of each tier from 2: "<God>'s <Area> / Climbing N"), `Stations`, `ReplicatedStorage.SheepLooks`, the leaderboards' screens,
  every ScreenGui.
- Before publishing: set Maximum Visitor Count to 5 (one player a plot) in Creator Hub, turn on Studio access to API
  services for saving, and publish under the account that owns Shear a Sheep's assets.
