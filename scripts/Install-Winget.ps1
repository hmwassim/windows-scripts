# Install-Winget.ps1
# Installs winget (App Installer) on machines that don't have it (e.g. LTSC)
# Downloads VCLibs, UI.Xaml, and the latest winget release from GitHub

#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # speeds up Invoke-WebRequest

# Force TLS 1.2 – Windows PowerShell 5.1 on LTSC defaults to TLS 1.0/1.1.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Step  { param($msg) Write-Host "  >> $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  [!] $msg"  -ForegroundColor Yellow }
function Write-Fail  { param($msg) Write-Host "  [X] $msg"  -ForegroundColor Red }

# ── Check if winget is already present ──────────────────────────────────────────
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Ok "winget is already installed: $(winget --version)"
    exit 0
}

Write-Host ""
Write-Host "  Installing winget on LTSC / Server / Sandbox..." -ForegroundColor Magenta
Write-Host ""

$tmp = $env:TEMP

# ── 1. VCLibs (required dependency) ─────────────────────────────────────────────
Write-Step "Downloading VCLibs x64 14.00..."
$vcLibsPath = "$tmp\Microsoft.VCLibs.x64.14.00.Desktop.appx"
Invoke-WebRequest `
    -Uri "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" `
    -OutFile $vcLibsPath

Write-Step "Installing VCLibs..."
try {
    Add-AppxPackage -Path $vcLibsPath -ErrorAction Stop
    Write-Ok "VCLibs installed."
} catch {
    Write-Warn "VCLibs may already be present or failed silently: $_"
}

# ── 2. Microsoft.UI.Xaml (required dependency) ───────────────────────────────────
# Fetch the exact appx from the NuGet package (no Store required)
Write-Step "Downloading Microsoft.UI.Xaml 2.8..."
$xamlNupkg = "$tmp\microsoft.ui.xaml.nupkg"
Invoke-WebRequest `
    -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.6" `
    -OutFile $xamlNupkg

Write-Step "Extracting Microsoft.UI.Xaml appx..."
$xamlExtract = "$tmp\xaml_extract"
if (Test-Path $xamlExtract) { Remove-Item $xamlExtract -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($xamlNupkg, $xamlExtract)

$xamlAppx = Get-ChildItem "$xamlExtract\tools\AppX\x64\Release\*.appx" | Select-Object -First 1
if (-not $xamlAppx) {
    Write-Fail "Could not find UI.Xaml appx inside the NuGet package."
    exit 1
}

Write-Step "Installing Microsoft.UI.Xaml..."
try {
    Add-AppxPackage -Path $xamlAppx.FullName -ErrorAction Stop
    Write-Ok "Microsoft.UI.Xaml installed."
} catch {
    Write-Warn "UI.Xaml may already be present or failed silently: $_"
}

# ── 3. Latest winget release from GitHub ─────────────────────────────────────────
Write-Step "Fetching latest winget release info from GitHub..."
$release    = Invoke-RestMethod "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
$msixAsset  = $release.assets | Where-Object { $_.name -like "Microsoft.DesktopAppInstaller_*.msixbundle" } | Select-Object -First 1
$licAsset   = $release.assets | Where-Object { $_.name -like "*License*.xml" } | Select-Object -First 1

if (-not $msixAsset) {
    Write-Fail "Could not find winget msixbundle in the GitHub release."
    exit 1
}

Write-Step "Downloading winget $($release.tag_name)..."
$msixPath = "$tmp\Microsoft.DesktopAppInstaller.msixbundle"
$licPath  = "$tmp\winget_License.xml"
Invoke-WebRequest -Uri $msixAsset.browser_download_url -OutFile $msixPath

if ($licAsset) {
    Invoke-WebRequest -Uri $licAsset.browser_download_url -OutFile $licPath
}

# ── 4. Install winget ─────────────────────────────────────────────────────────────
Write-Step "Installing winget..."
try {
    if ($licAsset -and (Test-Path $licPath)) {
        Add-AppxProvisionedPackage -Online -PackagePath $msixPath -LicensePath $licPath | Out-Null
    } else {
        Add-AppxPackage -Path $msixPath -ErrorAction Stop
    }
    Write-Ok "winget installed successfully."
} catch {
    Write-Fail "winget installation failed: $_"
    exit 1
}

# ── 5. Refresh PATH so winget is usable in the same session ──────────────────────
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Ok "winget is ready: $(winget --version)"
} else {
    Write-Warn "winget was installed but is not yet in PATH. You may need to restart your shell."
}

# ── Cleanup ───────────────────────────────────────────────────────────────────────
Remove-Item $vcLibsPath  -Force -ErrorAction SilentlyContinue
Remove-Item $xamlNupkg   -Force -ErrorAction SilentlyContinue
Remove-Item $xamlExtract -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $msixPath    -Force -ErrorAction SilentlyContinue
Remove-Item $licPath     -Force -ErrorAction SilentlyContinue
