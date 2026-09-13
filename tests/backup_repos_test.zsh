#!/usr/bin/env zsh
# Tests for scripts/backup_unpushed_repos.zsh: bundling repos with unpushed
# local work into one dated 7z archive.
# Run: ./tests/backup_repos_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
SCRIPT="$DOTFILES/scripts/backup_unpushed_repos.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

WS="$TMPDIR_T/workspace"
MANIFEST="$TMPDIR_T/repos.json"
DEST="$TMPDIR_T/backups"

git_init() {
  git -C "$1" init -q -b main
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
}

seed_workspace() {
  rm -rf "$WS"
  mkdir -p "$WS/acme/clean" "$WS/acme/dirty" "$WS/acme/no-remote"

  # clean: has a commit, an upstream, nothing ahead
  git_init "$WS/acme/clean"
  print -- hi > "$WS/acme/clean/f"; git -C "$WS/acme/clean" add f
  git -C "$WS/acme/clean" commit -q -m init
  git -C "$WS/acme/clean" remote add origin "$TMPDIR_T/clean-remote.git"
  git -C "$TMPDIR_T" init -q --bare clean-remote.git
  git -C "$WS/acme/clean" push -q origin main -u 2>/dev/null || true

  # dirty: local commit ahead of its upstream
  git_init "$WS/acme/dirty"
  print -- hi > "$WS/acme/dirty/f"; git -C "$WS/acme/dirty" add f
  git -C "$WS/acme/dirty" commit -q -m init
  git -C "$TMPDIR_T" init -q --bare dirty-remote.git
  git -C "$WS/acme/dirty" remote add origin "$TMPDIR_T/dirty-remote.git"
  git -C "$WS/acme/dirty" push -q origin main -u 2>/dev/null || true
  print -- more > "$WS/acme/dirty/f"; git -C "$WS/acme/dirty" commit -q -am more

  # no-remote: never pushed anywhere
  git_init "$WS/acme/no-remote"
  print -- hi > "$WS/acme/no-remote/f"; git -C "$WS/acme/no-remote" add f
  git -C "$WS/acme/no-remote" commit -q -m init

  cat > "$MANIFEST" <<JSON
{"repos":[
  {"owner":"acme","name":"clean"},
  {"owner":"acme","name":"dirty"},
  {"owner":"acme","name":"no-remote"}
]}
JSON
}

run_backup() { REPOS_MANIFEST="$MANIFEST" WORKSPACE_DIR="$WS" BACKUP_DIR="$DEST" "$SCRIPT" "$@" }

print -- "script"
[[ -f "$SCRIPT" ]]; check $? "backup_unpushed_repos.zsh exists"
[[ -x "$SCRIPT" ]]; check $? "backup_unpushed_repos.zsh is executable"

print -- "dry run"
seed_workspace
out="$(run_backup 2>&1)"
check $? "runs with no arguments"
[[ ! -d "$DEST" ]]; check $? "dry run writes nothing"
print -r -- "$out" | grep -q 'acme/dirty'
check $? "dry run names the dirty repo"
print -r -- "$out" | grep -q 'acme/no-remote'
check $? "dry run names the no-remote repo"
print -r -- "$out" | grep -qv 'bundle: acme/clean'
check $? "dry run does not name the clean repo"

print -- "apply"
out="$(run_backup --apply 2>&1)"
check $? "apply succeeds"
archive=$(print -r -- "$DEST"/repos-unpushed-*.7z(N))
[[ -n "$archive" ]]; check $? "apply writes a dated 7z archive"
7z l "$archive" 2>/dev/null | grep -q 'acme-dirty.bundle'
check $? "archive contains the dirty repo's bundle"
7z l "$archive" 2>/dev/null | grep -q 'acme-no-remote.bundle'
check $? "archive contains the no-remote repo's bundle"
7z l "$archive" 2>/dev/null | grep -qv 'acme-clean.bundle'
check $? "archive does not contain the clean repo's bundle"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
