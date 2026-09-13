#!/usr/bin/env sh
# Installs everything with no config this repo manages: pure "have it on the
# machine" packages, plus opening download pages for binary-apps/ (no cask).
set -u

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/lib.sh"

setup_brew_optional() {
  is_macos || return 0
  awk '/# ---- optional ----/,0' "$DOTFILES/Brewfile" > /tmp/Brewfile.optional
  run brew bundle --file /tmp/Brewfile.optional
}

setup_apt_optional() {
  is_linux || return 0
  log "skip: optional GUI apps (Linux has no equivalent for this repo's optional list)"
}

open_binary_apps() {
  is_macos || { log "skip: binary-apps downloads (not macOS)"; return 0; }

  open_if_missing() {
    name="$1" url="$2"
    [ -e "/Applications/$name.app" ] && { log "skip: $name.app already present"; return 0; }
    run open "$url"
    log "opened download page for $name — install manually"
  }

  open_if_missing "Dropover" "https://dropoverapp.com"
  open_if_missing "Qwen" "https://chat.qwen.ai"
  [ -e "/Applications/Supercharge.app" ] || log "manual install, no reliable URL: Supercharge — see binary-apps/README.md"
  [ -e "/Applications/Hand Mirror.app" ] || log "manual install, no reliable URL: Hand Mirror — see binary-apps/README.md"
  [ -e "/Applications/Microsoft To Do.app" ] || log "manual install via Mac App Store: Microsoft To Do"
}

setup_brew_optional
setup_apt_optional
open_binary_apps

log "install-optional.sh done"
