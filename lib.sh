#!/usr/bin/env sh
# Shared helpers for every install/link/backup script in this repo.
# Sourced, never executed directly: `. "$(dirname "$0")/lib.sh"`

DRY_RUN=0
for _arg in "$@"; do
  [ "$_arg" = "--dry-run" ] && DRY_RUN=1
done

log() { printf '%s\n' "$*"; }

is_macos() { [ "$(uname -s)" = "Darwin" ]; }
is_linux() { [ "$(uname -s)" = "Linux" ]; }

confirm_dir() {
  if [ "$DRY_RUN" = "1" ]; then
    [ -d "$1" ] || log "would mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

# link SRC DEST — symlink SRC at DEST, backing up a pre-existing real file once.
link() {
  src="$1"
  dest="$2"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return 0
  fi
  if [ "$DRY_RUN" = "1" ]; then
    log "would link $dest -> $src"
    return 0
  fi
  confirm_dir "$(dirname "$dest")"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.pre-dotfiles.bak"
    log "backed up existing $dest -> $dest.pre-dotfiles.bak"
  fi
  ln -sfn "$src" "$dest"
  log "linked $dest -> $src"
}

run() {
  if [ "$DRY_RUN" = "1" ]; then
    log "would run: $*"
  else
    "$@"
  fi
}
