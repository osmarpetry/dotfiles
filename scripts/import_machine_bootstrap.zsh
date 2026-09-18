#!/usr/bin/env zsh
# New-machine counterpart to export_machine_bootstrap.zsh: extracts the
# passphrase-encrypted archive and drops workspace/, ssh/, and Claude
# auto-memory back into place. Run this by hand in a terminal — there's no
# Claude Code set up yet at this point in a fresh-machine bootstrap.
#
# Assumes the new machine reuses the same $HOME username as the one that
# produced the archive: Claude memory directories are keyed by absolute
# project path (e.g. ~/.claude/projects/-Users-osmar-dotfiles), so a
# different username restores memory to the wrong project.
#
#   export EXPORT_PASSPHRASE='...'
#   ./scripts/import_machine_bootstrap.zsh ~/machine-export-2026-01-01.7z
set -euo pipefail

archive="${1:-}"
[ -n "$archive" ] || { print -r -- "error: usage: import_machine_bootstrap.zsh <archive>" >&2; exit 1 }
[ -f "$archive" ] || { print -r -- "error: no archive at $archive" >&2; exit 1 }
[ -n "${EXPORT_PASSPHRASE:-}" ] || { print -r -- "error: EXPORT_PASSPHRASE not set (export EXPORT_PASSPHRASE='...' first)" >&2; exit 1 }

workspace="${WORKSPACE_DIR:-$HOME/workspace}"
ssh_dir="${SSH_DIR:-$HOME/.ssh}"
claude_dir="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

tmp=$(mktemp -d)
cleanup() { rm -rf "$tmp" }
trap cleanup EXIT

rc=0
7z x -p"$EXPORT_PASSPHRASE" -o"$tmp" "$archive" >/dev/null || rc=$?
if [ "$rc" -gt 1 ]; then
  print -r -- "error: 7z extraction failed (wrong passphrase?)" >&2
  exit 1
fi

restored_repos=0
if [ -d "$tmp/workspace" ]; then
  mkdir -p "$workspace"
  cp -R "$tmp/workspace/." "$workspace/"
  restored_repos=$(find "$tmp/workspace" -maxdepth 3 -type d -name .git 2>/dev/null | wc -l | tr -d ' ')
fi

restored_ssh=0
if [ -d "$tmp/ssh" ]; then
  mkdir -p "$ssh_dir"
  for f in "$tmp"/ssh/*(N); do
    name="${f:t}"
    cp "$f" "$ssh_dir/$name"
    case "$name" in
      id_ed25519|tempo_id_rsa) chmod 600 "$ssh_dir/$name" ;;
    esac
    restored_ssh=$(( restored_ssh + 1 ))
  done
fi

restored_memory=0
if [ -d "$tmp/claude-memory" ]; then
  mkdir -p "$claude_dir"
  for d in "$tmp"/claude-memory/*(N); do
    name="${d:t}"
    mkdir -p -- "$claude_dir/$name/memory"
    cp -R "$d/memory/." "$claude_dir/$name/memory/"
    restored_memory=$(( restored_memory + 1 ))
  done
fi

print -- "summary: restored $restored_repos repo(s) under $workspace, $restored_ssh ssh file(s) under $ssh_dir, $restored_memory claude memory dir(s) under $claude_dir"
