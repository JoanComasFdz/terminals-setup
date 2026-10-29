# ======================================================
# Checks the result of setup-powershell-terminal.ps1 (Pester 5).
# Run it after the setup script, from the same shell edition.
# ======================================================

BeforeAll {
    # Pick up PATH changes made by winget during setup
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $script:themesPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
}

Describe "setup-powershell-terminal.ps1" {
    It "installs oh-my-posh" {
        Get-Command oh-my-posh -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It "installs FiraCode Nerd Font" {
        # Per user normally, system-wide when the script runs as Administrator (as on CI runners)
        $fontDirs = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts"
        Get-ChildItem $fontDirs -Filter "FiraCodeNerdFont*" -ErrorAction SilentlyContinue |
            Should -Not -BeNullOrEmpty
    }

    It "installs the <_> module" -ForEach @("Terminal-Icons", "posh-git") {
        Get-Module -ListAvailable -Name $_ | Should -Not -BeNullOrEmpty
    }

    It "downloads the <_> theme" -ForEach @("spaceship", "agnoster", "paradox", "powerlevel10k_rainbow") {
        "$script:themesPath\$_.omp.json" | Should -Exist
    }

    It "writes the profile" {
        $PROFILE | Should -Exist
        $PROFILE | Should -FileContentMatch "oh-my-posh init"
    }

    It "loads the profile without errors and sets the Oh My Posh prompt" {
        $shell = (Get-Process -Id $PID).Path
        $script = @'
$ErrorActionPreference = "Stop"
. $PROFILE
if (-not (Get-Module Terminal-Icons)) { throw "Terminal-Icons not loaded" }
if (-not (Get-Module posh-git)) { throw "posh-git not loaded" }
if (-not (Get-Module oh-my-posh-core)) { throw "Oh My Posh prompt not initialized" }
"OK"
'@
        # -EncodedCommand avoids Windows PowerShell 5.1 stripping the quotes in a -Command argument
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
        $output = & $shell -NoLogo -EncodedCommand $encoded 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output | Out-String)
        $output | Select-Object -Last 1 | Should -Be "OK"
    }
}
