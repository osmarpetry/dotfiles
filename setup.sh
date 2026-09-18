#!/usr/bin/env sh
# The one command to run on a new machine (or to bring this one up to date).
#   ./setup.sh              # real run
#   ./setup.sh --dry-run    # print every planned action, change nothing
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/lib.sh"

sh "$DOTFILES/install-essential.sh" "$@"
sh "$DOTFILES/link.sh" "$@"
sh "$DOTFILES/install-configured.sh" "$@"
sh "$DOTFILES/install-optional.sh" "$@"

# Local to this repo's own .git/config, not the globally-symlinked
# git/gitconfig — a fresh clone has no hook until this runs.
(cd "$DOTFILES" && run git config --local core.hooksPath git/hooks)

dry_run=0
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && dry_run=1
done

# sync_skills.zsh has no --dry-run mode of its own (copy+symlink, no preview),
# so a dry-run of setup.sh must skip it rather than call it unconditionally.
if [ "$dry_run" = "1" ]; then
  echo "would run: scripts/sync_skills.zsh --install"
else
  "$DOTFILES/scripts/sync_skills.zsh" --install
fi

echo "setup.sh done"
