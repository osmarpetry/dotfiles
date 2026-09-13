#!/usr/bin/env sh
# Installs the bare minimum needed to run the rest of this repo's scripts.
# macOS: install Homebrew if missing, then the "essential" Brewfile slice.
# Linux: apt-get install an equivalent CLI list.
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/lib.sh"

if is_macos; then
  if ! command -v brew >/dev/null 2>&1; then
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  awk '/# ---- essential ----/,/# ---- configured ----/' "$DOTFILES/Brewfile" \
    | grep -v '# ---- configured ----' > /tmp/Brewfile.essential
  run brew bundle --file /tmp/Brewfile.essential
elif is_linux; then
  run sudo apt-get update
  run sudo apt-get install -y git zsh curl p7zip-full gh
else
  log "unsupported platform: $(uname -s)"
  exit 1
fi

log "install-essential.sh done"
