$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    if (-not (Test-Path globalTypes.d.luau) -or -not (Test-Path Packages)) {
        throw 'Not installed. Run ./scripts/install.ps1 first.'
    }
    function Invoke-Step([string]$name, [scriptblock]$run) {
        Write-Host "== $name"
        & $run
        if ($LASTEXITCODE -ne 0) { throw "$name failed" }
    }

    Invoke-Step 'Format' { stylua src tests }
    Invoke-Step 'Sourcemap' { rojo sourcemap default.project.json --output sourcemap.json }
    Invoke-Step 'Types and lint' { luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json src tests }
    New-Item -ItemType Directory -Force build | Out-Null
    Invoke-Step 'Build' { rojo build default.project.json --output build/game.rbxl }

    Write-Host '== Repo'
    $problems = @()
    # Config shortened for one playtest is marked with this comment (BRAIN/PATTERNS/testing.md).
    foreach ($match in Get-ChildItem src, tests -Recurse -File -Include *.luau | Select-String -SimpleMatch 'TEMP-TEST') {
        $problems += "TEMP-TEST left in $($match.RelativePath((Get-Location).Path)):$($match.LineNumber)"
    }
    # git's view of each tracked file: a text file it reads as binary is full of NUL bytes, which is what a crash
    # leaves in a file it was writing (BRAIN/PATTERNS/sessions.md).
    $textFile = '\.(luau|lua|md|json|toml|ps1|py|txt|ya?ml|html|css|js|csv)$'
    $wrongEndings = @()
    foreach ($line in (& git -c core.quotepath=false ls-files --eol)) {
        if ($line -notmatch '^i/(\S*)\s+w/(\S*)\s+attr/(.*?)\s*\t(.+)$') { continue }
        $worktree = $Matches[2]; $attributes = $Matches[3]; $path = $Matches[4]
        if ($path -notmatch $textFile) { continue }
        if ($worktree -eq '-text') {
            $problems += "$path looks binary (NUL bytes?): restore it from git"
        } elseif ($worktree -in @('crlf', 'mixed') -and $attributes -notmatch 'eol=crlf') {
            $wrongEndings += $path
        }
    }
    $state = 'DESIGN/CURRENT_STATE.md'
    $stateLimit = 300
    if (Test-Path $state) {
        $stateLines = @(Get-Content $state).Count
        if ($stateLines -gt $stateLimit) {
            $problems += "$state is $stateLines lines (at most $stateLimit): keep one line per item there and move " +
                'details to DESIGN/HISTORY.md, DESIGN/DECISIONS.md or DESIGN/STUDIO_CONTENT.md'
        }
    }
    if ($wrongEndings.Count -gt 0) {
        Write-Host "Windows line endings (CRLF) in $($wrongEndings.Count) file(s), first: $($wrongEndings[0]). Write files with LF." -ForegroundColor Yellow
    }
    if ($problems.Count -gt 0) {
        $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        throw 'Repo checks failed'
    }
    $sync = Join-Path $PSScriptRoot 'brain-sync.ps1'
    if (Test-Path $sync) {
        try { & $sync -Quiet } catch { Write-Host "brain-sync: $_" -ForegroundColor Yellow }
    }
    Write-Host 'check passed' -ForegroundColor Green
} finally {
    Pop-Location
}
