#!/usr/bin/env zsh
# Tests for the `zed` shell shortcut: Zed.app's own CLI reachable on PATH the
# same way `code` is, reproducible on a fresh machine via zed/install.sh.
# Run: ./tests/zed_cli_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
INSTALL="$DOTFILES/zed/install.sh"
LINK_SH="$DOTFILES/link.sh"
BREWFILE="$DOTFILES/Brewfile"
LINK="$HOME/.local/bin/zed"
CLI="/Applications/Zed.app/Contents/MacOS/cli"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

print -- "setup is reproducible"
[[ -f "$INSTALL" ]]; check $? "zed/install.sh exists"
[[ -x "$INSTALL" ]]; check $? "zed/install.sh is executable"
grep -q "$CLI" "$INSTALL" 2>/dev/null
check $? "install.sh links Zed.app's bundled cli"
grep -q '\.local/bin/zed' "$INSTALL" 2>/dev/null
check $? "install.sh installs it as ~/.local/bin/zed"
grep -q 'setup_zed' "$DOTFILES/install-configured.sh"
check $? "install-configured.sh calls the zed setup step"
grep -q 'cask "zed"' "$BREWFILE"
check $? "Brewfile installs Zed so the app exists on a fresh machine"

print -- "the shortcut is on PATH for a fresh shell"
grep -q '\.local/bin' "$LINK_SH"
check $? "link.sh puts ~/.local/bin on the managed path set"

print -- "this machine"
[[ -L "$LINK" ]]; check $? "~/.local/bin/zed is a symlink"
[[ "$(readlink "$LINK" 2>/dev/null)" == "$CLI" ]]
check $? "it points at Zed.app's cli"
[[ -x "$LINK" ]]; check $? "it is executable"
zsh -c 'source ~/.zshrc >/dev/null 2>&1; command -v zed >/dev/null'
check $? "an interactive zsh resolves \`zed\`"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
