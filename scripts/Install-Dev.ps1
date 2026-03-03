# Install-Dev.ps1
# Installs the base shell environment: PowerShell 7, Windows Terminal, eza, Starship,
# and deploys the PowerShell profile.
#
# !! Run this as your NORMAL USER – NOT as Administrator !!
#    These tools install per-user by default when not elevated, which is correct.
#    Running as admin installs them machine-wide and can cause path/permission quirks.
#
# You are expected to still be on Windows PowerShell 5.1 (the LTSC inbox shell)
# when you run this. PS7 will be available after reopening the terminal.

#Requires -Version 5.1

$ErrorActionPreference = 'Continue'

# Refuse to continue if elevated
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  [!] Do not run this script as Administrator." -ForegroundColor Yellow
    Write-Host "      Close this elevated shell and run it from a normal PowerShell window." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

function Write-Header { param($t) Write-Host "`n  -- $t --" -ForegroundColor Magenta }
function Write-Step   { param($t) Write-Host "  >> $t"      -ForegroundColor Cyan }
function Write-Ok     { param($t) Write-Host "  [OK] $t"    -ForegroundColor Green }
function Write-Warn   { param($t) Write-Host "  [!] $t"     -ForegroundColor Yellow }

$wingetBase = @('install', '--exact', '--accept-package-agreements', '--accept-source-agreements')

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "PowerShell 7"
# ════════════════════════════════════════════════════════════════════════════════

# -i launches the MSI interactively so you can uncheck telemetry and
# the 'update via Windows Update' option before clicking Install.
Write-Step "Launching PowerShell 7 installer (interactive)..."
winget @wingetBase --id Microsoft.PowerShell -i

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Windows Terminal"
# ════════════════════════════════════════════════════════════════════════════════

Write-Step "Installing Windows Terminal..."
winget @wingetBase --id Microsoft.WindowsTerminal --silent

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "eza  (modern ls)"
# ════════════════════════════════════════════════════════════════════════════════

Write-Step "Installing eza..."
winget @wingetBase --id eza-community.eza --silent

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "Starship prompt"
# ════════════════════════════════════════════════════════════════════════════════

Write-Step "Installing Starship..."
winget @wingetBase --id Starship.Starship --silent

# ════════════════════════════════════════════════════════════════════════════════
Write-Header "PowerShell Profile"
# ════════════════════════════════════════════════════════════════════════════════

$repoRoot   = Split-Path -Parent $PSScriptRoot
$srcProfile = Join-Path $repoRoot 'profile\Microsoft.PowerShell_profile.ps1'

if (-not (Test-Path $srcProfile)) {
    Write-Warn "Profile not found at: $srcProfile"
    Write-Warn "If you ran via irm|iex, clone the repo and copy profile\ manually."
} else {
    # Write to both PS7 and Windows PowerShell 5 profile locations
    $ps7Profile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    $ps5Profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

    foreach ($dest in @($ps7Profile, $ps5Profile)) {
        $destDir = Split-Path $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -Path $srcProfile -Destination $dest -Force
        Write-Ok "Profile copied to $dest"
    }
}

# Refresh PATH so eza/starship are usable immediately in this session
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('Path', 'User')

Write-Host ""
Write-Ok "Shell setup complete. Open Windows Terminal or PowerShell 7 to get started."
