#!/usr/bin/env sh
# Symlinks Zed.app's bundled CLI to ~/.local/bin/zed, same as `code` for VS Code.
set -eu

cli="/Applications/Zed.app/Contents/MacOS/cli"
target="$HOME/.local/bin/zed"

if [ -x "$cli" ]; then
  mkdir -p "$(dirname "$target")"
  ln -sfn "$cli" "$target"
  echo "linked: $target -> $cli"
else
  echo "skip: Zed.app not found at $cli"
fi
