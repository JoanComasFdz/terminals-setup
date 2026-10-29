# Terminal Setup Scripts

Two scripts that set up a terminal with the same look and tools on Linux/WSL2 and Windows PowerShell: a Spaceship-style prompt, file icons, git info and FiraCode Nerd Font.

## Linux / WSL2: `setup-linux-terminal.sh`

Installs:
- **zsh** with **Oh My Zsh**, set as the default shell
- **Spaceship** prompt theme
- **zsh-autosuggestions** and **zsh-syntax-highlighting** plugins
- **zoxide**: `z` jumps to directories you've visited before
- **eza**: `l` lists files with icons
- **nvm** (Node Version Manager)

Also:
- Writes `~/.zshrc` and backs up the existing one first
- Prints how to install FiraCode Nerd Font: on Windows under WSL, locally on plain Linux

Run:
```bash
bash setup-linux-terminal.sh
```

## Windows: `setup-powershell-terminal.ps1`

Installs:
- **Oh My Posh** prompt engine, with the Spaceship, agnoster, paradox and powerlevel10k_rainbow themes
- **FiraCode Nerd Font**
- **Terminal-Icons**: file and folder icons in listings
- **posh-git**: git tab completion
- **zoxide**: `z` jumps to directories you've visited before
- **eza**: `l` lists files with icons

Also:
- Writes `$PROFILE` (Spaceship theme, Terminal-Icons, posh-git, `z`, `l`) and backs up the existing one first
- Prints how to set the font in Windows Terminal

Run (no Administrator needed):
```powershell
.\setup-powershell-terminal.ps1
```

Notes:
- Run it from the shell you use: Windows PowerShell 5.1 and PowerShell 7 each have their own profile and modules
- If Windows blocks the script, first run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

## After running

- Set your terminal's font to **FiraCode Nerd Font**, or the icons won't display
- Restart the terminal

## Tests

[CI](.github/workflows/ci.yml) runs on every push to `main` and every pull request:
- Lints both scripts (ShellCheck, PSScriptAnalyzer)
- Runs the Linux script on Ubuntu 24.04, 22.04 and 22.04 ARM, then `tests/test-linux-setup.sh`
- Runs the PowerShell script on Windows in PowerShell 7 and 5.1, then `tests/PowerShellSetup.Tests.ps1` (Pester)
