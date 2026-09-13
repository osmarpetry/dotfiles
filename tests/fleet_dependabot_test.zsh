#!/usr/bin/env zsh
# Tests for scripts/fleet_dependabot.zsh: planning and writing grouped
# dependabot configs across the workspace, without touching the network.
# Run: ./tests/fleet_dependabot_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
FLEET="$DOTFILES/scripts/fleet_dependabot.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_T" }
trap cleanup EXIT

WS="$TMPDIR_T/workspace"

seed_workspace() {
  rm -rf "$WS"
  # npm project
  mkdir -p "$WS/web-app"; print -- '{}' > "$WS/web-app/package.json"
  # go project
  mkdir -p "$WS/go-tool"; print -- 'module x' > "$WS/go-tool/go.mod"
  # maven project
  mkdir -p "$WS/java-svc"; print -- '<project/>' > "$WS/java-svc/pom.xml"
  # nothing to update: no manifest at all
  mkdir -p "$WS/just-docs"; print -- '# hi' > "$WS/just-docs/README.md"
  # already configured, must not be rewritten
  mkdir -p "$WS/done-already/.github"
  print -- 'version: 2\n# hand written, do not touch' \
    > "$WS/done-already/.github/dependabot.yml"
  # npm project that also has workflows
  mkdir -p "$WS/with-ci/.github/workflows"
  print -- '{}' > "$WS/with-ci/package.json"
  print -- 'name: ci' > "$WS/with-ci/.github/workflows/ci.yml"
}

run_fleet() { WORKSPACE_DIR="$WS" "$FLEET" "$@" }

print -- "script"
[[ -f "$FLEET" ]]; check $? "fleet_dependabot.zsh exists"
[[ -x "$FLEET" ]]; check $? "fleet_dependabot.zsh is executable"

print -- "dry run is the default"
seed_workspace
out="$(run_fleet 2>&1)"
check $? "runs with no arguments"
[[ ! -f "$WS/web-app/.github/dependabot.yml" ]]
check $? "dry run writes nothing"
print -r -- "$out" | grep -q 'web-app'
check $? "dry run names a repo it would change"
print -r -- "$out" | grep -q 'summary:'
check $? "dry run prints a summary"

print -- "ecosystem detection"
out="$(run_fleet 2>&1)"
print -r -- "$out" | grep -E 'web-app' | grep -q 'npm'
check $? "package.json is detected as npm"
print -r -- "$out" | grep -E 'go-tool' | grep -q 'gomod'
check $? "go.mod is detected as gomod"
print -r -- "$out" | grep -E 'java-svc' | grep -q 'maven'
check $? "pom.xml is detected as maven"
print -r -- "$out" | grep -E 'with-ci' | grep -q 'github-actions'
check $? "a workflows dir adds the github-actions ecosystem"
print -r -- "$out" | grep -E 'web-app' | grep -qv 'github-actions'
check $? "no workflows dir means no github-actions ecosystem"

print -- "skipping"
out="$(run_fleet 2>&1)"
# Verb first, then the name — the shape clone_repos.zsh already established.
print -r -- "$out" | grep -q 'skip.*just-docs'
check $? "a repo with no manifest is skipped"
print -r -- "$out" | grep -q 'skip.*done-already'
check $? "a repo that already has a config is skipped"

print -- "exclusion list"
seed_workspace
skipfile="$TMPDIR_T/skip.txt"
print -- "web-app" > "$skipfile"
print -- "# a comment line is ignored" >> "$skipfile"
print -- "" >> "$skipfile"
out="$(WORKSPACE_DIR="$WS" DEPENDABOT_SKIP_FILE="$skipfile" "$FLEET" 2>&1)"
check $? "runs with an exclusion list"
print -r -- "$out" | grep -q 'skip.*web-app'
check $? "an excluded repo is skipped"
print -r -- "$out" | grep -q 'plan.*go-tool'
check $? "a repo not on the list is still planned"
WORKSPACE_DIR="$WS" DEPENDABOT_SKIP_FILE="$skipfile" "$FLEET" --apply >/dev/null 2>&1
[[ ! -f "$WS/web-app/.github/dependabot.yml" ]]
check $? "apply writes nothing for an excluded repo"

print -- "apply"
seed_workspace
run_fleet --apply >/dev/null 2>&1
check $? "apply succeeds"
[[ -f "$WS/web-app/.github/dependabot.yml" ]]
check $? "apply writes the config"
[[ ! -f "$WS/just-docs/.github/dependabot.yml" ]]
check $? "apply still skips a repo with no manifest"
grep -q 'hand written' "$WS/done-already/.github/dependabot.yml"
check $? "apply never overwrites an existing config"

print -- "generated config shape"
cfg="$WS/web-app/.github/dependabot.yml"
grep -q 'version: 2' "$cfg";                check $? "declares version 2"
grep -q 'package-ecosystem: "npm"' "$cfg";  check $? "names the detected ecosystem"
grep -q 'groups:' "$cfg";                   check $? "groups updates into one PR"
grep -q 'patterns:' "$cfg";                 check $? "group matches every dependency"
grep -q 'interval: "monthly"' "$cfg";       check $? "uses a monthly schedule"
grep -q 'prefix: "chore"' "$cfg";           check $? "prefixes dependency commits"

# A repo with two ecosystems must get one update block per ecosystem.
n=$(grep -c 'package-ecosystem' "$WS/with-ci/.github/workflows/../dependabot.yml" 2>/dev/null || print -- 0)
[[ "$n" -eq 2 ]]
check $? "a repo with code plus workflows gets two update blocks (got $n)"

print -- "idempotent"
before="$(cat "$cfg")"
run_fleet --apply >/dev/null 2>&1
check $? "second apply succeeds"
[[ "$(cat "$cfg")" == "$before" ]]
check $? "second apply leaves the config byte for byte identical"

print -- "never touches the network"
stub="$TMPDIR_T/stub"; mkdir -p "$stub"
for bin in git curl gh; do
  print -- "#!/bin/sh\nprint -- \"NET: $bin\" >> \"$TMPDIR_T/net.log\"\nexit 42" > "$stub/$bin"
  chmod +x "$stub/$bin"
done
: > "$TMPDIR_T/net.log"
seed_workspace
PATH="$stub:$PATH" run_fleet --apply >/dev/null 2>&1
check $? "apply succeeds with no network tools"
[[ ! -s "$TMPDIR_T/net.log" ]]
check $? "apply invoked no git/curl/gh"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
