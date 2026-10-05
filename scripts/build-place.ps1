$ErrorActionPreference = 'Stop'
# Builds StealASheep.rbxl, the place to open in Studio: the commissioned map, the sheep rig and add-ons borrowed from
# Shear a Sheep (assets/ShearASheepAssets.rbxm) and this repo's code. Rerun it after changing the map or the assets;
# for code alone, `rojo serve` into the open place is enough.
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    function Invoke-Step([string]$name, [scriptblock]$run) {
        Write-Host "== $name"
        & $run
        if ($LASTEXITCODE -ne 0) { throw "$name failed" }
    }
    New-Item -ItemType Directory -Force build | Out-Null
    Invoke-Step 'Code' { rojo build default.project.json --output build/game.rbxl }
    Invoke-Step 'Place' {
        lune run tools/assemble.luau 'vvs_map(commission) (1).rbxl' assets/ShearASheepAssets.rbxm build/game.rbxl StealASheep.rbxl
    }
    Write-Host 'Built StealASheep.rbxl: open it in Studio and press Play.' -ForegroundColor Green
} finally {
    Pop-Location
}
