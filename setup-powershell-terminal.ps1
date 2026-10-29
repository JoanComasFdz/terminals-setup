# ======================================================
# PowerShell Terminal Setup Script
# Installs all dependencies and writes the PowerShell profile
# No Administrator rights needed: everything installs per user
# ======================================================

$ErrorActionPreference = "Stop"

Write-Host "Setting up PowerShell Terminal..." -ForegroundColor Cyan
Write-Host ""

# 1. Install oh-my-posh (prompt theme engine)
Write-Host "[1/6] Installing oh-my-posh..." -ForegroundColor Yellow
winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements

# Refresh PATH so oh-my-posh command is available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# winget exits non-zero when oh-my-posh is already installed, so check for the command instead
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "  oh-my-posh is not available after installing. Check the winget output above." -ForegroundColor Red
    exit 1
}

# 2. Install a Nerd Font (required for icons to display correctly)
Write-Host ""
Write-Host "[2/6] Installing FiraCode Nerd Font..." -ForegroundColor Yellow
Write-Host "  (This font is required for icons to display properly)" -ForegroundColor Gray

# Installs for the current user (system-wide when run as Administrator).
# oh-my-posh is a native command, so a failure sets $LASTEXITCODE instead of throwing
oh-my-posh font install FiraCode
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Font installed successfully!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  IMPORTANT: You must manually set your terminal font to:" -ForegroundColor Magenta
    Write-Host "  'FiraCode Nerd Font' or 'FiraCode NF'" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  In Windows Terminal: Settings > Profiles > Defaults > Appearance > Font face" -ForegroundColor Gray
} else {
    Write-Host "  Font installation failed (exit code $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "  Install FiraCode Nerd Font manually from: https://www.nerdfonts.com/font-downloads" -ForegroundColor Red
}

# 3. Install Terminal-Icons module (file/folder icons)
Write-Host ""
Write-Host "[3/6] Installing Terminal-Icons module..." -ForegroundColor Yellow
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -Scope CurrentUser

# 4. Install posh-git module (Git integration)
Write-Host ""
Write-Host "[4/6] Installing posh-git module..." -ForegroundColor Yellow
Install-Module -Name posh-git -Repository PSGallery -Force -Scope CurrentUser

# 5. Download oh-my-posh themes
Write-Host ""
Write-Host "[5/6] Downloading oh-my-posh themes..." -ForegroundColor Yellow

$themesPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"

# Create themes directory if it doesn't exist
if (-not (Test-Path $themesPath)) {
    New-Item -ItemType Directory -Path $themesPath -Force | Out-Null
    Write-Host "  Created themes directory: $themesPath" -ForegroundColor Gray
}

# Download spaceship theme (and a few popular ones as backup)
$themes = @(
    "spaceship",
    "agnoster",
    "paradox",
    "powerlevel10k_rainbow"
)

foreach ($theme in $themes) {
    $themeUrl = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/$theme.omp.json"
    $themeDest = "$themesPath\$theme.omp.json"

    try {
        Invoke-WebRequest -Uri $themeUrl -OutFile $themeDest -ErrorAction Stop
        Write-Host "  Downloaded: $theme.omp.json" -ForegroundColor Gray
    } catch {
        Write-Host "  Failed to download: $theme.omp.json" -ForegroundColor Red
    }
}

# 6. Write the PowerShell profile
Write-Host ""
Write-Host "[6/6] Writing PowerShell profile..." -ForegroundColor Yellow

# $PROFILE belongs to the shell running this script (Windows PowerShell 5.1 and PowerShell 7
# have separate profiles and module folders), so run the script from the shell you use.
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

if (Test-Path $PROFILE) {
    $backup = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $PROFILE $backup
    Write-Host "  Backed up existing profile to: $backup" -ForegroundColor Gray
}

$profileContent = @'
# Oh My Posh prompt (spaceship theme, downloaded locally by setup-powershell-terminal.ps1)
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ompShell = if ($PSVersionTable.PSEdition -eq "Core") { "pwsh" } else { "powershell" }
    $ompTheme = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\spaceship.omp.json"
    if (-not (Test-Path $ompTheme)) { $ompTheme = "spaceship" }
    oh-my-posh init $ompShell --config $ompTheme | Invoke-Expression
}

# File and folder icons in directory listings
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# Git tab completion (imported after Oh My Posh so it keeps the Oh My Posh prompt)
Import-Module posh-git -ErrorAction SilentlyContinue
'@

Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
Write-Host "  Profile written to: $PROFILE" -ForegroundColor Gray

# Done
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed themes: $($themes -join ', ')" -ForegroundColor Gray
Write-Host "Restart your terminal (or run '. `$PROFILE') to load the new prompt." -ForegroundColor Gray
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "CONFIGURE FONT IN WINDOWS TERMINAL" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To display icons correctly, you must configure Windows Terminal" -ForegroundColor White
Write-Host "to use the installed Nerd Font:" -ForegroundColor White
Write-Host ""
Write-Host "Option 1: Using the GUI" -ForegroundColor Yellow
Write-Host "  1. Open Windows Terminal" -ForegroundColor Gray
Write-Host "  2. Press Ctrl+, (or click the dropdown arrow > Settings)" -ForegroundColor Gray
Write-Host "  3. In the left sidebar, click 'Defaults' under 'Profiles'" -ForegroundColor Gray
Write-Host "  4. Click on 'Appearance'" -ForegroundColor Gray
Write-Host "  5. Under 'Font face', select 'FiraCode Nerd Font'" -ForegroundColor Gray
Write-Host "  6. Click 'Save' at the bottom right" -ForegroundColor Gray
Write-Host "  7. Close and reopen Windows Terminal" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Using settings.json" -ForegroundColor Yellow
Write-Host "  1. Open Windows Terminal" -ForegroundColor Gray
Write-Host "  2. Press Ctrl+Shift+, to open settings.json" -ForegroundColor Gray
Write-Host "  3. Find the 'profiles' > 'defaults' section" -ForegroundColor Gray
Write-Host "  4. Add or modify the font setting:" -ForegroundColor Gray
Write-Host ""
Write-Host '     "defaults": {' -ForegroundColor DarkGray
Write-Host '         "font": {' -ForegroundColor DarkGray
Write-Host '             "face": "FiraCode Nerd Font"' -ForegroundColor DarkGray
Write-Host '         }' -ForegroundColor DarkGray
Write-Host '     }' -ForegroundColor DarkGray
Write-Host ""
Write-Host "  5. Save the file (Ctrl+S) and restart Windows Terminal" -ForegroundColor Gray
Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""
