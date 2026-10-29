# Terminal Setup Scripts

One-click setup scripts for beautiful, productive terminal environments.

## Scripts

| Script | Platform | What it installs |
|--------|----------|------------------|
| `setup-linux-terminal.sh` | Linux / WSL2 | Zsh, Oh My Zsh, Spaceship theme, zsh-autosuggestions, zsh-syntax-highlighting, zoxide, eza, nvm |
| `setup-powershell-terminal.ps1` | Windows | Oh My Posh, Terminal-Icons, posh-git, FiraCode Nerd Font |

## Usage

**Linux / WSL2:**
```bash
chmod +x setup-linux-terminal.sh
./setup-linux-terminal.sh
```

**PowerShell** (no Administrator rights needed). Run it from the shell you use, Windows PowerShell 5.1 or PowerShell 7, since each has its own profile and modules:
```powershell
.\setup-powershell-terminal.ps1
```

If Windows blocks the script, allow local scripts for your user first. This also lets the generated profile load:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

The PowerShell script writes `$PROFILE` (Oh My Posh with the Spaceship theme, Terminal-Icons, posh-git). An existing profile is backed up first, the same way the Linux script backs up `~/.zshrc`.

## Post-Install

After running the scripts, configure your terminal to use FiraCode Nerd Font for icons to display correctly. Both scripts print the exact steps.

## Tests

The [CI workflow](.github/workflows/ci.yml) lints both scripts (ShellCheck, PSScriptAnalyzer), then runs each one on a fresh GitHub runner and checks the result:

- `tests/test-linux-setup.sh` after `setup-linux-terminal.sh` on Ubuntu 22.04 (x86_64 and arm64) and 24.04
- `tests/PowerShellSetup.Tests.ps1` (Pester) after `setup-powershell-terminal.ps1` on Windows, in PowerShell 7 and Windows PowerShell 5.1
