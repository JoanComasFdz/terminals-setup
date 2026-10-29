#!/bin/bash

# =============================================================================
# Checks the result of setup-linux-terminal.sh. Run it after the setup script.
# =============================================================================

set -uo pipefail

FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        pass "$description"
    else
        fail "$description"
    fi
}

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

check "zsh is installed" command -v zsh
check "Oh My Zsh is installed" test -f "$HOME/.oh-my-zsh/oh-my-zsh.sh"
check "Spaceship theme is linked" test -f "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
check "zsh-autosuggestions is installed" test -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
check "zsh-syntax-highlighting is installed" test -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
check "nvm is installed" test -s "$HOME/.nvm/nvm.sh"
check ".zshrc was written" grep -q 'ZSH_THEME="spaceship"' "$HOME/.zshrc"
check "global compinit is skipped" grep -q '^skip_global_compinit=1' "$HOME/.zshenv"
LOGIN_SHELL=$(getent passwd "$(id -un)" | cut -d: -f7)
check "zsh is the default shell" test "$LOGIN_SHELL" = "$(command -v zsh)"

# zoxide is started by the Oh My Zsh plugin only, not a second time by .zshrc
if grep -q 'zoxide init' "$HOME/.zshrc"; then
    fail "zoxide is initialized only by the plugin"
else
    pass "zoxide is initialized only by the plugin"
fi

# An interactive zsh loads .zshrc. It must start without errors and provide the tools.
ZSH_STDERR=$(zsh -i -c 'exit' 2>&1 >/dev/null)
if [ -z "$ZSH_STDERR" ]; then
    pass "interactive zsh starts without errors"
else
    fail "interactive zsh starts without errors: $ZSH_STDERR"
fi

check "zoxide is on PATH in zsh" zsh -i -c 'command -v zoxide'
check "'z' command is defined in zsh" zsh -i -c 'whence z'
check "eza runs in zsh" zsh -i -c 'eza --version'
check "'l' alias is defined in zsh" zsh -i -c 'alias l'
check "nvm is loaded in zsh" zsh -i -c 'command -v nvm'
# shellcheck disable=SC2016  # expanded by zsh, not here
check "EDITOR is set to an installed editor" zsh -i -c 'command -v ${EDITOR%% *}'

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All checks passed."
else
    echo "$FAILURES check(s) failed."
    exit 1
fi
