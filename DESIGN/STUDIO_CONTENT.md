# Studio-side content

What the code expects in the place file, which isn't on disk: names, tags, key properties, which `studio/` script
builds each, and what the place holds now (saved to Roblox or not). Instances the code creates at runtime don't belong
here. Newest first.

- **2026-10-05, the first build**. There is no Roblox place yet. `scripts/build-place.ps1` makes `StealASheep.rbxl`
  from three inputs on disk, so the place can always be rebuilt:
  - **The map**, `vvs_map(commission) (1).rbxl` (the user's commission), as it is. The code expects:
    `workspace.Base.PlayerPlots` (five `PlayerPlot` models; PlotService sorts them by z), `workspace.Base.Shop` (two
    stall models: the one at z 205 is the Shop, the one at z 175 the Sell Stall), `workspace.Stages.Stage1..7` (the ramp),
    `workspace.Decors` and `workspace.Base.Foliages`/`HayStacks` (decor PlotService may move out of a pad's way), and
    the ramp's shape in `Config/Olympus.Ramp` (measured; re-measure if the map changes). Workspace.StreamingEnabled is
    off in the map.
  - **Shear a Sheep's pieces**, `assets/ShearASheepAssets.rbxm` (from `tools/extract-assets.luau`), placed in
    `ServerStorage.Assets`: `SheepRig` (Model, PrimaryPart `Root`, pieces on Motor6Ds named after the piece, a `Face`
    Decal on `Head`), `SheepAddons` (73 Models of MeshParts with `Piece` and `Tint` attributes: wool styles, horns,
    `<Build>Wool` and `<Build>Extras`), `WorldKit.MutationMachine` (the Merge Shrine; a primitive altar if missing).
  - **The code**, from `rojo build default.project.json`.
- Made at runtime (not in the place): `workspace.Plots`, `Gods`, `WildSheep`, `CarriedSheep`, `PenSheep`,
  `ClimbGates`, `Stations`, `ReplicatedStorage.SheepLooks`, every ScreenGui.
- Before publishing: set Maximum Visitor Count to 5 (one player a plot) in Creator Hub, turn on Studio access to API
  services for saving, and publish under the account that owns Shear a Sheep's assets.
