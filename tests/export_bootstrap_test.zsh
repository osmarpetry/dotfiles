#!/usr/bin/env zsh
# Tests for scripts/export_machine_bootstrap.zsh: bundling ~/workspace
# (minus node_modules), the SSH files that exist on this machine, and every
# populated Claude auto-memory directory into one passphrase-encrypted 7z
# archive.
# Run: ./tests/export_bootstrap_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
SCRIPT="$DOTFILES/scripts/export_machine_bootstrap.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

WS="$TMPDIR_T/workspace"
SSH="$TMPDIR_T/ssh"
CLAUDE="$TMPDIR_T/claude-projects"
DEST="$WS/backups"

seed() {
  rm -rf "$WS" "$SSH" "$CLAUDE"

  mkdir -p "$WS/acme/repo-a/.git" "$WS/acme/repo-b/node_modules/dep"
  print -- "hi" > "$WS/acme/repo-a/f.txt"
  print -- "ref: refs/heads/main" > "$WS/acme/repo-a/.git/HEAD"
  print -- "noise" > "$WS/acme/repo-b/node_modules/dep/f.js"
  print -- "code" > "$WS/acme/repo-b/main.js"
  # a decoy previous archive already sitting under the default backups dir
  mkdir -p "$DEST"
  print -- "old archive" > "$DEST/machine-export-2025-01-01.7z"

  mkdir -p "$SSH"
  print -- "PRIVATE KEY" > "$SSH/id_ed25519"
  print -- "public key"  > "$SSH/real-id_ed25519.pub"
  ln -s "real-id_ed25519.pub" "$SSH/id_ed25519.pub"
  print -- "Host github" > "$SSH/real-config"
  ln -s "real-config" "$SSH/config"
  print -- "allowed signer" > "$SSH/allowed_signers"
  # tempo_id_rsa / tempo_id_rsa.pub deliberately absent

  mkdir -p "$CLAUDE/-Users-test-projA/memory" "$CLAUDE/-Users-test-projB/memory"
  print -- "some memory" > "$CLAUDE/-Users-test-projA/memory/MEMORY.md"
  # projB's memory dir exists but is empty, must be skipped
}

run_export() {
  WORKSPACE_DIR="$WS" BACKUP_DIR="$DEST" SSH_DIR="$SSH" CLAUDE_PROJECTS_DIR="$CLAUDE" "$SCRIPT" "$@"
}

print -- "script"
[[ -f "$SCRIPT" ]]; check $? "export_machine_bootstrap.zsh exists"
[[ -x "$SCRIPT" ]]; check $? "export_machine_bootstrap.zsh is executable"

print -- "dry run"
seed
before="$(find "$DEST" -type f | wc -l)"
out="$(run_export 2>&1)"
check $? "runs with no arguments"
after="$(find "$DEST" -type f | wc -l)"
[[ "$before" == "$after" ]]; check $? "dry run writes nothing new to the backups dir"
print -r -- "$out" | grep -q 'summary:'
check $? "dry run prints a summary"
print -r -- "$out" | grep -q '1 repo'
check $? "dry run counts exactly one repo (repo-a has .git, repo-b does not)"
print -r -- "$out" | grep -q '4/6 ssh file'
check $? "dry run counts 4 of 6 known ssh files present"
print -r -- "$out" | grep -q '1 claude memory dir'
check $? "dry run counts only the populated memory dir"

print -- "apply requires EXPORT_PASSPHRASE"
seed
out="$(run_export --apply 2>&1)"
rc=$?
[[ $rc -ne 0 ]]; check $? "apply refuses to run without EXPORT_PASSPHRASE"
print -r -- "$out" | grep -qi 'EXPORT_PASSPHRASE'
check $? "error message names EXPORT_PASSPHRASE"

print -- "apply"
seed
out="$(EXPORT_PASSPHRASE=test run_export --apply 2>&1)"
check $? "apply succeeds"
archive="$DEST/machine-export-$(date +%Y-%m-%d).7z"
[[ -f "$archive" ]]; check $? "apply writes today's dated 7z archive"

7z l -ptest "$archive" >/dev/null 2>&1
check $? "archive opens with the right passphrase"
7z l -pwrong "$archive" </dev/null >/dev/null 2>&1
[[ $? -ne 0 ]]; check $? "archive refuses the wrong passphrase"

listing="$(7z l -ptest "$archive" 2>/dev/null)"
print -r -- "$listing" | grep -q 'workspace/acme/repo-a/f.txt'
check $? "archive keeps repo-a's file under workspace/"
print -r -- "$listing" | grep -q 'workspace/acme/repo-b/main.js'
check $? "archive keeps repo-b's non-node_modules file"
! print -r -- "$listing" | grep -q 'node_modules'
check $? "archive excludes node_modules"
! print -r -- "$listing" | grep -q 'machine-export-2025-01-01.7z'
check $? "archive excludes its own backups dir (no self-inclusion)"

print -r -- "$listing" | grep -q 'ssh/id_ed25519$'
check $? "archive contains the private key"
print -r -- "$listing" | grep -q 'ssh/id_ed25519.pub'
check $? "archive contains the dereferenced pub key symlink"
print -r -- "$listing" | grep -q 'ssh/config'
check $? "archive contains the dereferenced config symlink"
print -r -- "$listing" | grep -q 'ssh/allowed_signers'
check $? "archive contains allowed_signers"
! print -r -- "$listing" | grep -q 'tempo_id_rsa'
check $? "archive excludes the tempo_id_rsa files that don't exist on this machine"

print -r -- "$listing" | grep -q 'claude-memory/-Users-test-projA/memory/MEMORY.md'
check $? "archive contains the populated memory dir under its project name"
! print -r -- "$listing" | grep -q 'projB'
check $? "archive excludes the empty memory dir"

7z x -ptest -o"$TMPDIR_T/extracted" "$archive" >/dev/null 2>&1
check $? "archive extracts with the right passphrase"
diff -q "$TMPDIR_T/extracted/workspace/acme/repo-a/.git/HEAD" "$WS/acme/repo-a/.git/HEAD" >/dev/null 2>&1
check $? "extracted .git contents match the original (unpushed local state survives)"
diff -q "$TMPDIR_T/extracted/ssh/id_ed25519" "$SSH/id_ed25519" >/dev/null 2>&1
check $? "extracted private key content matches the original"
diff -q "$TMPDIR_T/extracted/ssh/config" "$SSH/real-config" >/dev/null 2>&1
check $? "extracted config content matches the symlink target, not a broken link"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
