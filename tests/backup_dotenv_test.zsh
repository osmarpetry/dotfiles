#!/usr/bin/env zsh
# Tests for scripts/backup_dotenv_files.zsh: archiving every .env* under the
# workspace, preserving relative paths.
# Run: ./tests/backup_dotenv_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
SCRIPT="$DOTFILES/scripts/backup_dotenv_files.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

WS="$TMPDIR_T/workspace"
DEST="$TMPDIR_T/backups"

seed_workspace() {
  rm -rf "$WS"
  mkdir -p "$WS/app-one" "$WS/app-two/node_modules/dep"
  print -- "SECRET=one"   > "$WS/app-one/.env"
  print -- "SECRET=local" > "$WS/app-one/.env.local"
  print -- "SECRET=two"   > "$WS/app-two/.env"
  print -- "SECRET=noise" > "$WS/app-two/node_modules/dep/.env"
}

run_backup() { WORKSPACE_DIR="$WS" BACKUP_DIR="$DEST" "$SCRIPT" "$@" }

print -- "script"
[[ -f "$SCRIPT" ]]; check $? "backup_dotenv_files.zsh exists"
[[ -x "$SCRIPT" ]]; check $? "backup_dotenv_files.zsh is executable"

print -- "dry run"
seed_workspace
out="$(run_backup 2>&1)"
check $? "runs with no arguments"
[[ ! -d "$DEST" ]]; check $? "dry run writes nothing"
print -r -- "$out" | grep -q 'summary:'
check $? "dry run prints a summary"
print -r -- "$out" | grep -q '3 .env file'
check $? "dry run counts node_modules out (3, not 4)"

print -- "apply"
out="$(run_backup --apply 2>&1)"
check $? "apply succeeds"
archive=$(print -r -- "$DEST"/dotenv-*.7z(N))
[[ -n "$archive" ]]; check $? "apply writes a dated 7z archive"
listing="$(7z l "$archive" 2>/dev/null)"
print -r -- "$listing" | grep -q 'app-one/.env$'
check $? "archive keeps app-one/.env's relative path"
print -r -- "$listing" | grep -q 'app-one/.env.local'
check $? "archive keeps app-one/.env.local"
print -r -- "$listing" | grep -q 'app-two/.env$'
check $? "archive keeps app-two/.env's relative path"
print -r -- "$listing" | grep -qv 'node_modules'
check $? "archive excludes node_modules"

print -- "empty workspace"
rm -rf "$WS/app-one" "$WS/app-two"
out="$(run_backup 2>&1)"
check $? "runs against an empty workspace"
print -r -- "$out" | grep -q '0 .env file'
check $? "reports 0 files found"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
