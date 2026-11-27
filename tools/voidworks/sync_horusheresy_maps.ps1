# Local helper for Voidworks.
#
# Voidworks only scans _maps and voidcrew/_maps for its Available Maps list,
# so maps in Horusheresy/_maps are not listed. This script mirrors that folder
# into voidcrew/_maps/horusheresy using hardlinks. Both paths point at the same
# file, so saving through Voidworks edits the original Horusheresy map.
#
# Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File tools/voidworks/sync_horusheresy_maps.ps1
#
# Close any Horusheresy maps in Voidworks before running this.

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$src = Join-Path $root 'Horusheresy\_maps'
$dst = Join-Path $root 'voidcrew\_maps\horusheresy'

if (-not (Test-Path -LiteralPath $src)) {
    throw "Map source folder not found: $src"
}

# A previous run may have left a junction here. Remove the link itself without
# touching the target folder.
$existing = Get-Item -LiteralPath $dst -ErrorAction SilentlyContinue
if ($existing) {
    if ($existing.LinkType -eq 'Junction') {
        cmd /c rmdir "$dst"
    } else {
        Remove-Item -LiteralPath $dst -Recurse -Force
    }
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null

$count = 0
Get-ChildItem -LiteralPath $src -Recurse -File -Filter '*.dmm' | ForEach-Object {
    $relative = $_.FullName.Substring($src.Length).TrimStart('\')
    $target = Join-Path $dst $relative
    $targetDir = Split-Path -Parent $target

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    New-Item -ItemType HardLink -Path $target -Target $_.FullName | Out-Null
    $count++
}

Write-Host "Done: linked $count map(s) into $dst"
