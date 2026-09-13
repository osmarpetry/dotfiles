#!/usr/bin/env zsh
# Tests for scripts/sync_skills.zsh: vendoring agent skills into the repo and
# restoring them onto a machine without cloning any upstream repository.
# Run: ./tests/skills_sync_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
SYNC="$DOTFILES/scripts/sync_skills.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

# A fake machine: source skills live here, claude links point at them.
FAKE_AGENTS="$TMPDIR_T/agents"
FAKE_CLAUDE="$TMPDIR_T/claude-skills"
VENDOR="$TMPDIR_T/repo/skills"

seed_machine() {
  rm -rf "$FAKE_AGENTS" "$FAKE_CLAUDE"
  mkdir -p "$FAKE_AGENTS/skills/alpha" "$FAKE_AGENTS/skills/beta/refs" "$FAKE_CLAUDE"
  print -- "# alpha"            > "$FAKE_AGENTS/skills/alpha/SKILL.md"
  print -- "# beta"             > "$FAKE_AGENTS/skills/beta/SKILL.md"
  print -- "deep"               > "$FAKE_AGENTS/skills/beta/refs/notes.md"
  cat > "$FAKE_AGENTS/.skill-lock.json" <<'JSON'
{
  "version": 1,
  "skills": {
    "alpha": { "source": "someone/pack", "skillFolderHash": "aaa111" },
    "beta":  { "source": "other/pack",   "skillFolderHash": "bbb222" }
  }
}
JSON
  ln -s "$FAKE_AGENTS/skills/alpha" "$FAKE_CLAUDE/alpha"
}

run_sync() {
  AGENTS_DIR="$FAKE_AGENTS" \
  CLAUDE_SKILLS_DIR="$FAKE_CLAUDE" \
  SKILLS_VENDOR_DIR="$VENDOR" \
  "$SYNC" "$@"
}

print -- "script"
[[ -f "$SYNC" ]]; check $? "sync_skills.zsh exists"
[[ -x "$SYNC" ]]; check $? "sync_skills.zsh is executable"

print -- "export"
seed_machine
rm -rf "$VENDOR"
run_sync --export >/dev/null 2>&1
check $? "export succeeds"
[[ -f "$VENDOR/alpha/SKILL.md" ]]; check $? "export vendors a skill file"
[[ -f "$VENDOR/beta/refs/notes.md" ]]; check $? "export vendors nested files"
[[ -f "$VENDOR/.skill-lock.json" ]]; check $? "export vendors the lock file"
[[ ! -L "$VENDOR/alpha" ]]; check $? "vendored skill is a real dir, not a symlink"

# The lock file is the pin: it must survive the round trip byte for byte.
diff -q "$FAKE_AGENTS/.skill-lock.json" "$VENDOR/.skill-lock.json" >/dev/null 2>&1
check $? "lock file is copied verbatim"

print -- "export refuses a missing source"
MISSING="$TMPDIR_T/nope"
AGENTS_DIR="$MISSING" CLAUDE_SKILLS_DIR="$FAKE_CLAUDE" SKILLS_VENDOR_DIR="$VENDOR" \
  "$SYNC" --export >/dev/null 2>&1
[[ $? -ne 0 ]]; check $? "export fails when AGENTS_DIR is absent"

print -- "install onto a clean machine"
# Vendored content is already in $VENDOR from the export above.
rm -rf "$FAKE_AGENTS" "$FAKE_CLAUDE"
mkdir -p "$FAKE_CLAUDE"
run_sync --install >/dev/null 2>&1
check $? "install succeeds"
[[ -f "$FAKE_AGENTS/skills/alpha/SKILL.md" ]]; check $? "install restores a skill"
[[ -f "$FAKE_AGENTS/skills/beta/refs/notes.md" ]]; check $? "install restores nested files"
[[ -f "$FAKE_AGENTS/.skill-lock.json" ]]; check $? "install restores the lock file"
[[ -L "$FAKE_CLAUDE/alpha" ]]; check $? "install links the skill into claude"
[[ "$(readlink "$FAKE_CLAUDE/alpha")" == "$FAKE_AGENTS/skills/alpha" ]]
check $? "link points at the restored skill"

print -- "install never clones"
# No network tool may be invoked: stub them to fail loudly if they are.
stub="$TMPDIR_T/stub"; mkdir -p "$stub"
for bin in git curl gh; do
  print -- "#!/bin/sh\nprint -- \"NETWORK: $bin \$*\" >> \"$TMPDIR_T/net.log\"\nexit 42" > "$stub/$bin"
  chmod +x "$stub/$bin"
done
: > "$TMPDIR_T/net.log"
rm -rf "$FAKE_AGENTS"; mkdir -p "$FAKE_CLAUDE"
PATH="$stub:$PATH" run_sync --install >/dev/null 2>&1
check $? "install succeeds with no network tools available"
[[ ! -s "$TMPDIR_T/net.log" ]]
check $? "install invoked no git/curl/gh ($(cat "$TMPDIR_T/net.log" 2>/dev/null | head -1))"

print -- "install preserves a real local skill"
# A skill dropped in as a real directory some other way (not by this script)
# must never be clobbered by a symlink.
rm -rf "$FAKE_AGENTS" "$FAKE_CLAUDE"
mkdir -p "$FAKE_CLAUDE/local-skill"
print -- "# local" > "$FAKE_CLAUDE/local-skill/SKILL.md"
run_sync --install >/dev/null 2>&1
check $? "install succeeds alongside a real local skill"
[[ -f "$FAKE_CLAUDE/local-skill/SKILL.md" && ! -L "$FAKE_CLAUDE/local-skill" ]]
check $? "a real local skill dir is left untouched"
[[ "$(cat "$FAKE_CLAUDE/local-skill/SKILL.md")" == "# local" ]]
check $? "local skill content is not overwritten"

print -- "install is idempotent"
run_sync --install >/dev/null 2>&1
check $? "second install succeeds"
[[ -L "$FAKE_CLAUDE/alpha" ]]; check $? "links survive a second install"
n=$(find "$FAKE_AGENTS/skills" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
[[ "$n" -eq 2 ]]; check $? "no duplicate skills after reinstall (got $n)"

print -- "reporting"
out="$(run_sync --install 2>&1)"
print -r -- "$out" | grep -q 'summary:'
check $? "prints a summary line"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
