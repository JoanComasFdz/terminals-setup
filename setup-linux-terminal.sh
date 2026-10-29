#!/bin/bash

# =============================================================================
# Zsh + Oh My Zsh + Spaceship Setup Script
# Replicates Joan's WSL2/Linux configuration
# Works on: Ubuntu/Debian, WSL2, Linux
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Function to safely download and execute scripts
safe_curl_exec() {
    local url="$1"
    local shell="${2:-sh}"
    local extra_args="${3:-}"
    local tmpfile
    tmpfile=$(mktemp)

    if ! curl -fsSL "$url" -o "$tmpfile"; then
        print_error "Failed to download: $url"
        rm -f "$tmpfile"
        return 1
    fi

    if [ ! -s "$tmpfile" ]; then
        print_error "Downloaded file is empty: $url"
        rm -f "$tmpfile"
        return 1
    fi

    # "|| result=$?" keeps set -e from exiting before the temp file is removed
    local result=0
    if [ -n "$extra_args" ]; then
        "$shell" "$tmpfile" "$extra_args" || result=$?
    else
        "$shell" "$tmpfile" || result=$?
    fi
    rm -f "$tmpfile"
    return $result
}

# Prints the latest release tag of a GitHub repo (e.g. "v0.40.3"), or nothing on failure.
# Follows the releases/latest redirect instead of calling the API, which is rate limited.
latest_github_tag() {
    local url
    url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" || true)
    case "$url" in
        */releases/tag/*) echo "${url##*/}" ;;
    esac
}

# -----------------------------------------------------------------------------
# Step 1: System packages
# -----------------------------------------------------------------------------
print_step "[1/7] Installing system packages..."
sudo apt update
sudo apt install -y zsh git curl wget unzip fontconfig

# -----------------------------------------------------------------------------
# Step 2: Install Oh My Zsh
# -----------------------------------------------------------------------------
print_step "[2/7] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_warning "Oh My Zsh already installed, skipping..."
else
    safe_curl_exec "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "sh" "--unattended"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# -----------------------------------------------------------------------------
# Step 3: Install Spaceship theme
# -----------------------------------------------------------------------------
print_step "[3/7] Installing Spaceship prompt theme..."
if [ -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]; then
    print_warning "Spaceship theme already installed, skipping..."
else
    if ! git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1; then
        print_error "Failed to clone Spaceship prompt repository"
        exit 1
    fi
    ln -sf "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi

# -----------------------------------------------------------------------------
# Step 4: Install custom Oh My Zsh plugins
# -----------------------------------------------------------------------------
print_step "[4/7] Installing custom Oh My Zsh plugins..."

# zsh-autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_warning "zsh-autosuggestions already installed, skipping..."
else
    if ! git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth=1; then
        print_error "Failed to clone zsh-autosuggestions repository"
        exit 1
    fi
fi

# zsh-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_warning "zsh-syntax-highlighting already installed, skipping..."
else
    if ! git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth=1; then
        print_error "Failed to clone zsh-syntax-highlighting repository"
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Step 5: Install zoxide (smarter cd)
# -----------------------------------------------------------------------------
print_step "[5/7] Installing zoxide..."
if command -v zoxide &> /dev/null; then
    print_warning "zoxide already installed, skipping..."
else
    safe_curl_exec "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "sh"
fi

# -----------------------------------------------------------------------------
# Step 6: Install eza (modern ls replacement)
# -----------------------------------------------------------------------------
print_step "[6/7] Installing eza..."
if command -v eza &> /dev/null; then
    print_warning "eza already installed, skipping..."
else
    # eza is available in Ubuntu 24.04+ repos
    if sudo apt install -y eza; then
        print_step "eza installed from apt"
    else
        # Fallback: install from GitHub releases
        print_warning "eza not in apt repos, installing from GitHub releases..."
        case "$(uname -m)" in
            x86_64)        EZA_TARGET="x86_64-unknown-linux-gnu" ;;
            aarch64|arm64) EZA_TARGET="aarch64-unknown-linux-gnu" ;;
            armv7l)        EZA_TARGET="arm-unknown-linux-gnueabihf" ;;
            *)
                print_error "No prebuilt eza binary for architecture: $(uname -m)"
                exit 1
                ;;
        esac
        if ! wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_TARGET}.tar.gz"; then
            print_error "Failed to download eza binary"
            exit 1
        fi
        if ! sudo tar -xzf /tmp/eza.tar.gz -C /usr/local/bin; then
            print_error "Failed to extract eza binary"
            rm -f /tmp/eza.tar.gz
            exit 1
        fi
        rm -f /tmp/eza.tar.gz
        print_step "eza installed from GitHub releases"
    fi
fi

# -----------------------------------------------------------------------------
# Step 7: Install nvm (Node Version Manager)
# -----------------------------------------------------------------------------
print_step "[7/7] Installing nvm..."
if [ -d "$HOME/.nvm" ]; then
    print_warning "nvm already installed, skipping..."
else
    NVM_VERSION=$(latest_github_tag nvm-sh/nvm)
    if [ -z "$NVM_VERSION" ]; then
        print_error "Failed to fetch latest nvm version from GitHub"
        exit 1
    fi
    print_step "Installing nvm $NVM_VERSION..."
    safe_curl_exec "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" "bash"
fi

# -----------------------------------------------------------------------------
# Configure .zshrc
# -----------------------------------------------------------------------------
print_step "Configuring .zshrc..."

# Backup existing .zshrc
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    print_warning "Backed up existing .zshrc"
fi

cat > "$HOME/.zshrc" << 'EOF'
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"

# Theme
ZSH_THEME="spaceship"

# Disable auto-setting terminal title
DISABLE_AUTO_TITLE="true"

# Plugins
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  zoxide
  extract
  history
  docker
  npm
)

# Spaceship configuration (BEFORE sourcing oh-my-zsh)
SPACESHIP_USER_SHOW=always
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_ELAPSED=1
SPACESHIP_EXEC_TIME_PRECISION=2
SPACESHIP_EXEC_TIME_PREFIX="⏱ "
SPACESHIP_EXEC_TIME_SUFFIX=" "
SPACESHIP_EXEC_TIME_COLOR="yellow"

SPACESHIP_PROMPT_ORDER=(
  user
  dir
  host
  git
  exec_time
  line_sep
  jobs
  exit_code
  char
)

# Source Oh My Zsh (THIS MUST BE AFTER SPACESHIP CONFIG)
source $ZSH/oh-my-zsh.sh

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# zoxide (smarter cd) is initialized by the zoxide plugin above

# eza alias (modern ls)
alias l='eza --long --all --header --icons --group-directories-first --no-permissions --no-user'

# Editor: VS Code when available, otherwise a terminal editor
if (( $+commands[code] )); then
  export EDITOR="code --wait"
elif (( $+commands[nano] )); then
  export EDITOR="nano"
else
  export EDITOR="vi"
fi

# Snap packages path (for WSL2/Ubuntu)
export PATH="/snap/bin:$PATH"

# Tips on startup
echo "Tip: use 'z' instead of 'cd' to change directories!"
echo "Tip: use 'l' instead of 'ls' to explore directories!"
EOF

# -----------------------------------------------------------------------------
# Set zsh as default shell
# -----------------------------------------------------------------------------
print_step "Setting zsh as default shell..."
if [ "${SHELL:-}" != "$(which zsh)" ]; then
    # sudo reuses the credentials cached by apt above, so chsh doesn't prompt again
    sudo chsh -s "$(which zsh)" "$(id -un)"
    echo -e "${GREEN}Default shell changed to zsh${NC}"
else
    print_warning "zsh is already the default shell"
fi

# -----------------------------------------------------------------------------
# Done!
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo "What was installed:"
echo "  - zsh (shell)"
echo "  - Oh My Zsh (zsh framework)"
echo "  - Spaceship theme (prompt)"
echo "  - zsh-autosuggestions (plugin)"
echo "  - zsh-syntax-highlighting (plugin)"
echo "  - zoxide (smarter cd command)"
echo "  - eza (modern ls replacement)"
echo "  - nvm (Node Version Manager)"
echo ""
echo -e "${GREEN}Restart your terminal or run 'zsh' to start using the new setup!${NC}"
echo ""
# Fetch latest Nerd Fonts version for instructions
NERD_FONTS_VERSION=$(latest_github_tag ryanoasis/nerd-fonts)
NERD_FONTS_VERSION="${NERD_FONTS_VERSION:-v3.5.1}"  # Fallback if the lookup fails

echo -e "${YELLOW}══════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  NEXT STEPS${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Under WSL the terminal (Windows Terminal) renders the text, so the font must be installed on Windows
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "1. Install FiraCode Nerd Font (run in PowerShell as Administrator):"
    echo ""
    echo -e "${BLUE}\$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14); Invoke-WebRequest -Uri \"https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/FiraCode.zip\" -OutFile \"\$env:TEMP\\FiraCode.zip\"; Expand-Archive -Path \"\$env:TEMP\\FiraCode.zip\" -DestinationPath \"\$env:TEMP\\FiraCode\" -Force; Get-ChildItem \"\$env:TEMP\\FiraCode\" -Filter \"*.ttf\" | ForEach-Object { \$fonts.CopyHere(\$_.FullName, 0x10) }; Remove-Item \"\$env:TEMP\\FiraCode.zip\" -Force; Remove-Item \"\$env:TEMP\\FiraCode\" -Recurse -Force${NC}"
    echo ""
    echo "2. Set font in Windows Terminal:"
    echo "   Settings > Profiles > Ubuntu > Appearance > Font face > FiraCode Nerd Font"
    echo ""
    echo "3. Restart Windows Terminal"
    echo ""
    echo "   (Skip step 1 if you already ran setup-powershell-terminal.ps1, it installs the same font.)"
    echo ""
else
    echo "1. Install FiraCode Nerd Font:"
    echo "   https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/FiraCode.zip"
    echo "   Extract the .ttf files into ~/.local/share/fonts and run 'fc-cache -f'"
    echo ""
    echo "2. Set your terminal emulator's font to FiraCode Nerd Font"
    echo ""
    echo "3. Restart your terminal"
    echo ""
fi
