#!/usr/bin/env zsh
# Tests for git/hooks/pre-commit: blocking a commit that stages a secret.
# Run: ./tests/precommit_secrets_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
HOOK="$DOTFILES/git/hooks/pre-commit"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

command -v gitleaks >/dev/null 2>&1 || { print -- "SKIP: gitleaks not installed"; exit 0 }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

REPO="$TMPDIR_T/repo"

seed_repo() {
  rm -rf "$REPO"
  mkdir -p "$REPO/git/hooks"
  git -C "$REPO" init -q -b main
  git -C "$REPO" config user.email "test@example.com"
  git -C "$REPO" config user.name "Test"
  cp "$HOOK" "$REPO/git/hooks/pre-commit"
  chmod +x "$REPO/git/hooks/pre-commit"
  git -C "$REPO" config core.hooksPath git/hooks
}

print -- "script"
[[ -f "$HOOK" ]]; check $? "pre-commit hook exists"
[[ -x "$HOOK" ]]; check $? "pre-commit hook is executable"

print -- "a staged secret is blocked"
seed_repo
print -- "AKIAABCDEFGHIJKLMNOP" > "$REPO/secret.txt" # gitleaks:allow
git -C "$REPO" add secret.txt
git -C "$REPO" commit -q -m "add secret" >/dev/null 2>&1
[[ $? -ne 0 ]]; check $? "commit with an AWS key is refused"
[[ -z "$(git -C "$REPO" log --oneline 2>/dev/null)" ]]; check $? "no commit landed"

print -- "clean content commits fine"
seed_repo
print -- "hello world" > "$REPO/clean.txt"
git -C "$REPO" add clean.txt
git -C "$REPO" commit -q -m "add clean file" >/dev/null 2>&1
check $? "commit with no secret succeeds"
[[ -n "$(git -C "$REPO" log --oneline 2>/dev/null)" ]]; check $? "commit landed"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
