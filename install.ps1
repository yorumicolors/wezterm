# Yorumi theme installer for WezTerm (Windows PowerShell)
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# a base to install under must be absolute; Windows PowerShell's IsPathRooted
# also says yes to C:foo and \foo, which resolve against the current directory,
# so the shape is tested instead
function Test-AbsolutePath([string] $path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $false }
    if ([IO.Path]::DirectorySeparatorChar -eq '\') {
        return ($path -match '^[A-Za-z]:[\\/]' -or $path -match '^[\\/]{2}[^\\/]')
    }
    return $path.StartsWith('/')
}

if (Test-AbsolutePath $env:XDG_CONFIG_HOME) {
    $base = $env:XDG_CONFIG_HOME
} else {
    $base = Join-Path $env:USERPROFILE '.config'
}
$destDir = Join-Path $base 'wezterm\colors'
$rawBase = "https://raw.githubusercontent.com/yorumicolors/wezterm/main"
$files = @("yorumi-ether.toml", "yorumi-abyss.toml", "yorumi-bifrost.toml", "yorumi-kraken.toml", "yorumi-kabocha.toml", "yorumi-cosmic.toml", "yorumi-ryujin.toml")

# download beside the target and move it in: a failed fetch leaves nothing behind
function Save-One([string] $name, [string] $target) {
    $url = "$rawBase/$name"
    $part = "$target.part.$PID"
    try {
        Invoke-WebRequest -Uri $url -OutFile $part -UseBasicParsing
    } catch {
        Remove-Item -LiteralPath $part -ErrorAction SilentlyContinue
        throw "yorumi: download failed for $url (target $target): $($_.Exception.Message)"
    }
    Move-Item -LiteralPath $part -Destination $target -Force
}

if (-not (Test-Path -Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

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
        Save-One $f $target
    }
    Write-Host "Installed: $target" -ForegroundColor Green
}

Write-Host "`nSuccessfully installed Yorumi for WezTerm!" -ForegroundColor Green
Write-Host "Fragments are in $destDir; no scheme was selected."
Write-Host "WezTerm names a scheme after its file, so add one line to your wezterm.lua,"
Write-Host "using the file stem of the flavour you want. For example:"
Write-Host ""
Write-Host "    config.color_scheme = `"yorumi-ether`""
Write-Host ""
Write-Host "That is the ether flavour; the seven stems are yorumi-ether, yorumi-abyss,"
Write-Host "yorumi-bifrost, yorumi-kraken, yorumi-kabocha, yorumi-cosmic, yorumi-ryujin."
