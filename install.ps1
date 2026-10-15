# Yorumi theme installer for WezTerm (Windows PowerShell)
$ErrorActionPreference = "Stop"

$destDir = "$env:USERPROFILE\.config\wezterm\colors"
if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$rawBase = "https://raw.githubusercontent.com/yorumicolors/wezterm/main"
$files = @("yorumi-abyss.toml", "yorumi-mist.toml", "yorumi-ether.toml", "yorumi-bifrost.toml")

$scriptDir = $PSScriptRoot

Write-Host "Installing Yorumi theme for WezTerm..." -ForegroundColor Cyan

foreach ($f in $files) {
    $basename = Split-Path $f -Leaf
    $target = Join-Path $destDir $basename
    $localPath = if ($scriptDir) { Join-Path $scriptDir $f } else { $null }
    $localFlat = if ($scriptDir) { Join-Path $scriptDir $basename } else { $null }

    if ($localPath -and (Test-Path $localPath)) {
        Copy-Item -Path $localPath -Destination $target -Force
    } elseif ($localFlat -and (Test-Path $localFlat)) {
        Copy-Item -Path $localFlat -Destination $target -Force
    } else {
        $url = "$rawBase/$f"
        Invoke-RestMethod -Uri $url -OutFile $target
    }
    Write-Host "✓ Installed: $target" -ForegroundColor Green
}

Write-Host "`nSuccessfully installed Yorumi for WezTerm!" -ForegroundColor Green
Write-Host "Set color_scheme in your wezterm.lua:"
Write-Host "    config.color_scheme = `"yorumi-abyss`""
