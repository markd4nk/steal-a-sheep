$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    function Invoke-Step([string]$name, [scriptblock]$run) {
        Write-Host "== $name"
        & $run
        if ($LASTEXITCODE -ne 0) { throw "$name failed" }
    }

    Invoke-Step 'Tools (rokit)' { rokit install }

    $lspVersion = (Select-String -Path rokit.toml -Pattern 'luau-lsp@([\d.]+)').Matches[0].Groups[1].Value
    $installed = if (Test-Path globalTypes.version) { (Get-Content globalTypes.version -Raw).Trim() } else { '' }
    if (-not (Test-Path globalTypes.d.luau) -or $installed -ne $lspVersion) {
        Write-Host "== Roblox type definitions (luau-lsp $lspVersion)"
        Invoke-WebRequest "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/$lspVersion/scripts/globalTypes.d.luau" -OutFile globalTypes.d.luau
        Set-Content globalTypes.version $lspVersion
    }

    Invoke-Step 'Packages (wally)' { wally install }
    Invoke-Step 'Sourcemap' { rojo sourcemap default.project.json --output sourcemap.json }
    Invoke-Step 'Package types' { wally-package-types --sourcemap sourcemap.json Packages/ }
    Invoke-Step 'Server package types' { wally-package-types --sourcemap sourcemap.json ServerPackages/ }
    Write-Host 'Install complete. Run ./scripts/check.ps1 next.' -ForegroundColor Green
} finally {
    Pop-Location
}
