#!/usr/bin/env zsh
# PostToolUse hook: after a Write/Edit, flag hard-wrapped prose in a file
# written under ~/.claude/plans/. Repo files keep their own wrap convention
# (AGENTS.md §Style) and are skipped via two checks: the path must be under
# ~/.claude/plans/, and the file must not sit inside a git working tree.
#
# Reads the Claude Code PostToolUse hook payload on stdin. Prints a
# decision:block JSON on a violation; silent, exit 0, otherwise.
set -uo pipefail

DOTFILES="${0:A:h}/.."
CHECK="$DOTFILES/scripts/check_prose_wrap.zsh"

f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[[ -z "$f" ]] && exit 0

case "$f" in
  "$HOME/.claude/plans/"*) ;;
  *) exit 0 ;;
esac

git -C "$(dirname "$f")" rev-parse --is-inside-work-tree >/dev/null 2>&1 && exit 0

out=$("$CHECK" "$f" 2>/dev/null)
rc=$?
if (( rc != 0 )); then
  printf '%s' "$out" | jq -Rs '{decision: "block", reason: .}'
fi
exit 0
