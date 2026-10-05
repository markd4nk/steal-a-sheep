<#
Keeps the files every game shares with RobloxPack the same in both: BRAIN/, AGENTS.md, CLAUDE.md and the scripts
check.ps1, install.ps1 and this one. README.md, DESIGN/ and the code belong to each game.

  ./scripts/brain-sync.ps1                              Lists what differs, and when each side last committed it.
  ./scripts/brain-sync.ps1 -ToPack -Message "BRAIN: ..."  Copies this game's versions into the pack, commits, pushes.
  ./scripts/brain-sync.ps1 -FromPack                    Copies the pack's versions here; run check.ps1, then commit.

Both directions pull the pack first and skip a file the other side committed more recently (another game updated the
pack, or this game is behind it), or that has uncommitted changes on the side being copied from or over, unless
-Force. -Only limits a run to the listed files (-Only AGENTS.md,BRAIN/PATTERNS/ui.md). A file that exists on one side
only is listed and never deleted: remove it by hand where it no longer belongs. The pack is found at $env:ROBLOXPACK,
else Desktop\RobloxPack (OneDrive's Desktop first).
#>
param(
    [switch]$ToPack,
    [switch]$FromPack,
    [string]$Message = '',
    [string[]]$Only = @(),
    [switch]$Force,
    # For check.ps1: one line when anything differs, nothing otherwise, and no pull.
    [switch]$Quiet
)
$ErrorActionPreference = 'Stop'

$SharedPaths = @('BRAIN', 'AGENTS.md', 'CLAUDE.md', 'scripts/check.ps1', 'scripts/install.ps1', 'scripts/brain-sync.ps1')

function Find-Pack {
    $candidates = @()
    if ($env:ROBLOXPACK) { $candidates += $env:ROBLOXPACK }
    $candidates += (Join-Path $env:USERPROFILE 'OneDrive\Desktop\RobloxPack')
    $candidates += (Join-Path $env:USERPROFILE 'Desktop\RobloxPack')
    foreach ($candidate in $candidates) {
        if (Test-Path (Join-Path $candidate 'BRAIN')) { return (Resolve-Path $candidate).Path.TrimEnd([char]'\', [char]'/') }
    }
    return $null
}

# Native git writes progress to stderr, which Windows PowerShell turns into errors under 'Stop'.
function Invoke-Git([string]$root, [string[]]$gitArgs) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & git -C $root @gitArgs 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
    $lines = @($output | ForEach-Object { "$_" })
    if ($code -ne 0) { throw "git $($gitArgs -join ' ') failed in ${root}:`n$($lines -join "`n")" }
    return $lines
}

function Get-SharedFiles([string]$root) {
    $files = @()
    foreach ($path in $SharedPaths) {
        $full = Join-Path $root $path
        if (Test-Path $full -PathType Leaf) {
            $files += $path
        } elseif (Test-Path $full -PathType Container) {
            foreach ($item in Get-ChildItem $full -Recurse -File) {
                $files += $item.FullName.Substring($root.Length + 1) -replace '\\', '/'
            }
        }
    }
    return $files
}

# Line endings don't count: .ps1 files are CRLF on disk and LF in git.
function Read-Normalized([string]$path) {
    if (-not (Test-Path $path -PathType Leaf)) { return $null }
    return [System.IO.File]::ReadAllText($path) -replace "`r", ''
}

function Get-CommitTime([string]$root, [string]$file) {
    $time = Invoke-Git $root @('log', '-1', '--format=%ct', '--', $file) | Select-Object -First 1
    if ($time) { return [int64]$time }
    return [int64]0
}

function Test-Uncommitted([string]$root, [string]$file) {
    return [bool](Invoke-Git $root @('status', '--porcelain', '--', $file))
}

function Format-Side([string]$root, [string]$file, [bool]$exists) {
    if (-not $exists) { return 'missing' }
    if (Test-Uncommitted $root $file) { return 'uncommitted changes' }
    $time = Get-CommitTime $root $file
    if ($time -eq 0) { return 'never committed' }
    return 'committed ' + [DateTimeOffset]::FromUnixTimeSeconds($time).LocalDateTime.ToString('yyyy-MM-dd HH:mm')
}

$game = (Resolve-Path (Split-Path $PSScriptRoot -Parent)).Path
$pack = Find-Pack
if (-not $pack) {
    if (-not $Quiet) { Write-Host 'RobloxPack not found: set $env:ROBLOXPACK to its folder.' }
    exit 0
}
if ($game -ieq $pack) {
    if (-not $Quiet) { Write-Host 'This is RobloxPack itself: nothing to compare.' }
    exit 0
}
if ($ToPack -and $FromPack) { throw 'Pick -ToPack or -FromPack, not both.' }
if ($ToPack -and -not $Message) { throw 'Give -ToPack a commit message for the pack: -Message "BRAIN: ..."' }

if ($ToPack -or $FromPack) {
    $packChanges = Invoke-Git $pack (@('status', '--porcelain', '--') + $SharedPaths)
    if ($packChanges) {
        throw "RobloxPack has uncommitted changes to shared files. Commit or discard them there first:`n$($packChanges -join "`n")"
    }
    Invoke-Git $pack @('pull', '--ff-only', '--quiet') | Out-Null
}

$wanted = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { $_.Trim() -replace '\\', '/' })
$files = @(@(Get-SharedFiles $game) + @(Get-SharedFiles $pack) | Sort-Object -Unique)
if ($wanted.Count -gt 0) { $files = @($files | Where-Object { $wanted -contains $_ }) }

$differences = @(foreach ($file in $files) {
        $ours = Read-Normalized (Join-Path $game $file)
        $theirs = Read-Normalized (Join-Path $pack $file)
        if ($ours -cne $theirs) {
            [pscustomobject]@{ File = $file; InGame = $null -ne $ours; InPack = $null -ne $theirs }
        }
    })

if ($Quiet) {
    if ($differences.Count -gt 0) {
        Write-Host "BRAIN: $($differences.Count) shared file(s) differ from RobloxPack; ./scripts/brain-sync.ps1 lists them." -ForegroundColor Yellow
    }
    exit 0
}
if ($differences.Count -eq 0) {
    Write-Host "The shared files match RobloxPack ($pack)." -ForegroundColor Green
    exit 0
}

if (-not ($ToPack -or $FromPack)) {
    Write-Host "Shared files that differ from RobloxPack ($pack):"
    foreach ($difference in $differences) {
        $ourSide = Format-Side $game $difference.File $difference.InGame
        $theirSide = Format-Side $pack $difference.File $difference.InPack
        Write-Host ('  {0}' -f $difference.File)
        Write-Host ('      this game: {0}; pack: {1}' -f $ourSide, $theirSide)
    }
    Write-Host 'Copy with -ToPack -Message "..." (approved BRAIN changes) or -FromPack (to catch up with the pack).'
    exit 0
}

if ($ToPack) { $from = $game; $to = $pack; $fromName = 'this game'; $toName = 'the pack' }
else { $from = $pack; $to = $game; $fromName = 'the pack'; $toName = 'this game' }

$copied = @()
foreach ($difference in $differences) {
    $file = $difference.File
    $existsFrom = if ($ToPack) { $difference.InGame } else { $difference.InPack }
    $existsTo = if ($ToPack) { $difference.InPack } else { $difference.InGame }
    if (-not $existsFrom) {
        Write-Host "  skipped $file : only in $toName. Delete it there by hand if it was removed on purpose." -ForegroundColor Yellow
        continue
    }
    if (-not $Force) {
        if (Test-Uncommitted $from $file) {
            Write-Host "  skipped $file : uncommitted in $fromName. Commit it first." -ForegroundColor Yellow
            continue
        }
        if ($existsTo -and (Test-Uncommitted $to $file)) {
            Write-Host "  skipped $file : uncommitted changes in $toName would be overwritten." -ForegroundColor Yellow
            continue
        }
        if ($existsTo -and (Get-CommitTime $to $file) -gt (Get-CommitTime $from $file)) {
            Write-Host "  skipped $file : $toName changed it more recently. Compare them; -Force copies anyway." -ForegroundColor Yellow
            continue
        }
    }
    $target = Join-Path $to $file
    New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path $from $file) -Destination $target -Force
    Write-Host "  copied $file"
    $copied += $file
}

if ($copied.Count -eq 0) {
    Write-Host 'Nothing copied.'
    exit 0
}
if ($FromPack) {
    Write-Host "Copied $($copied.Count) file(s) from the pack. Run ./scripts/check.ps1, then commit them." -ForegroundColor Green
    exit 0
}
Invoke-Git $pack (@('add', '--') + $copied) | Out-Null
# A file, because Windows PowerShell mangles quotes inside native arguments.
$messageFile = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($messageFile, $Message + "`n", (New-Object System.Text.UTF8Encoding $false))
    Invoke-Git $pack @('commit', '--quiet', '-F', $messageFile) | Out-Null
} finally {
    Remove-Item $messageFile -ErrorAction SilentlyContinue
}
Invoke-Git $pack @('push', '--quiet') | Out-Null
$commit = Invoke-Git $pack @('log', '-1', '--format=%h %s') | Select-Object -First 1
Write-Host "RobloxPack: committed and pushed $($copied.Count) file(s) as $commit" -ForegroundColor Green
