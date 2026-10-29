# ======================================================
# PowerShell Terminal Setup Script
# Installs all dependencies for the PowerShell profile
# Run as Administrator for font installation
# ======================================================

Write-Host "Setting up PowerShell Terminal..." -ForegroundColor Cyan
Write-Host ""

# 1. Install oh-my-posh (prompt theme engine)
Write-Host "[1/6] Installing oh-my-posh..." -ForegroundColor Yellow
winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements

# Refresh PATH so oh-my-posh command is available
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# 2. Install a Nerd Font (required for icons to display correctly)
Write-Host ""
Write-Host "[2/6] Installing FiraCode Nerd Font..." -ForegroundColor Yellow
Write-Host "  (This font is required for icons to display properly)" -ForegroundColor Gray

try {
    oh-my-posh font install FiraCode --user
    Write-Host "  Font installed successfully!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  IMPORTANT: You must manually set your terminal font to:" -ForegroundColor Magenta
    Write-Host "  'FiraCode Nerd Font' or 'FiraCode NF'" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  In Windows Terminal: Settings > Profiles > Defaults > Appearance > Font face" -ForegroundColor Gray
} catch {
    Write-Host "  Font installation failed. You may need to run as Administrator." -ForegroundColor Red
    Write-Host "  Or manually install a Nerd Font from: https://www.nerdfonts.com/" -ForegroundColor Red
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

# 6. Set POSH_THEMES_PATH environment variable
Write-Host ""
Write-Host "[6/6] Setting POSH_THEMES_PATH environment variable..." -ForegroundColor Yellow

[Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesPath, "User")
$env:POSH_THEMES_PATH = $themesPath

Write-Host "  POSH_THEMES_PATH = $themesPath" -ForegroundColor Gray

# Done
Write-Host ""
Write-Host "======================================================" -ForegroundColor Green
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installed themes: $($themes -join ', ')" -ForegroundColor Gray
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
