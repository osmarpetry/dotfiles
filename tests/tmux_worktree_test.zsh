#!/usr/bin/env zsh
# Tests for the tmux worktree layer: workmux + tmux-which-key + key-table hints.
# Run: ./tests/tmux_worktree_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
CONF="$DOTFILES/tmux/tmux.conf"
WK="$DOTFILES/tmux/which-key.yaml"
BIN="$DOTFILES/bin"

# Actions that must exist identically in the key table and the which-key menu.
ACTIONS=(a b s d g y r)

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

TMPDIR_T=$(mktemp -d)
SOCK="wmtest-$$"
cleanup() { tmux -L "$SOCK" kill-server 2>/dev/null; rm -rf "$TMPDIR_T" }
trap cleanup EXIT

print -- "tmux.conf"
err="$TMPDIR_T/tmux.err"
tmux -L "$SOCK" -f "$CONF" new-session -d -s probe 2>"$err"
check $? "config loads without error"
[[ ! -s "$err" ]]; check $? "config emits no warnings ($(head -c 200 "$err"))"

keys=$(tmux -L "$SOCK" list-keys -T worktree-mode 2>/dev/null)
for k in $ACTIONS; do
  print -r -- "$keys" | awk '{print $4}' | grep -qx -- "$k"
  check $? "worktree-mode binds '$k'"
done
for k in Escape Enter; do
  print -r -- "$keys" | awk '{print $4}' | grep -qx -- "$k"
  check $? "worktree-mode binds '$k' to leave the table"
done

# tmux popups run a non-interactive shell, so ~/.local/bin is not on PATH.
for k in a b s r y; do
  print -r -- "$keys" | grep -E "^bind-key +-T worktree-mode +$k " | grep -q '/\.local/bin/wm-'
  check $? "worktree-mode '$k' calls its helper by absolute path"
done

tmux -L "$SOCK" show-options -gv status-right | grep -q 'client_key_table'
check $? "status-right reacts to the active key table"
tmux -L "$SOCK" show-options -gv status-right | grep -q 'worktree-mode'
check $? "status-right renders worktree-mode hints"
[[ $(tmux -L "$SOCK" show-options -gv status-interval) -le 5 ]]
check $? "status-interval low enough for the hint bar to feel live"

tmux -L "$SOCK" list-keys -T prefix 2>/dev/null | grep -E '^bind-key +-T prefix +w ' | grep -q 'worktree-mode'
check $? "prefix+w enters worktree-mode"

print -- "which-key config"
python3 - "$WK" "${(j:,:)ACTIONS}" <<'PY'
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1]))
want = set(sys.argv[2].split(","))
assert cfg["command_alias_start_index"] >= 200, "command_alias_start_index"
assert cfg["keybindings"]["prefix_table"], "prefix_table"
root = cfg["items"]
wt = [i for i in root if i.get("key") == "w" and "menu" in i]
assert wt, "no worktree submenu bound to 'w'"
got = {i["key"] for i in wt[0]["menu"] if "key" in i}
missing = want - got
assert not missing, f"which-key worktree menu missing {sorted(missing)}"
assert cfg["keybindings"].get("root_table"), "no root_table keybinding"
for i in wt[0]["menu"]:
    cmd = i.get("command", "")
    if "wm-" in cmd:
        assert "$HOME/.local/bin/wm-" in cmd, f"which-key {i['key']!r} relies on PATH: {cmd}"
PY
check $? "valid yaml, worktree submenu mirrors the key table"

print -- "scripts"
for s_ in wm-add wm-switch; do
  [[ -x "$BIN/$s_" ]]; check $? "$s_ is executable"
done

print -- "wm-switch"
stub="$TMPDIR_T/stub"; mkdir -p "$stub"
make_stub() {
  cat > "$stub/workmux" <<'STUB'
#!/usr/bin/env zsh
print -r -- "$@" >> "$WM_STUB_LOG"
if [[ "$1" == "list" ]]; then
  # `--all` only reports repos with tracked agents; plain `list` is this repo.
  if [[ " $* " == *" --all "* ]]; then cat "$WM_STUB_ALL_JSON"; else cat "$WM_STUB_JSON"; fi
fi
exit 0
STUB
  chmod +x "$stub/workmux"
}
make_stub
export WM_STUB_LOG="$TMPDIR_T/calls.log" WM_STUB_JSON="$TMPDIR_T/list.json" WM_STUB_ALL_JSON="$TMPDIR_T/all.json"
print -r -- "[]" > "$TMPDIR_T/all.json"
mkdir -p "$TMPDIR_T/app" "$TMPDIR_T/app__worktrees/feat-login"
cat > "$WM_STUB_JSON" <<JSON
[{"project":"app","project_path":"$TMPDIR_T/app","handle":"app","branch":"main","path":"$TMPDIR_T/app","is_main":true,"is_open":false,"has_uncommitted_changes":false,"agent_statuses":[]},
 {"project":"app","project_path":"$TMPDIR_T/app","handle":"feat-login","branch":"feat/login","path":"$TMPDIR_T/app__worktrees/feat-login","is_main":false,"is_open":true,"has_uncommitted_changes":true,"agent_statuses":[{"status":"waiting"}]}]
JSON

: > "$WM_STUB_LOG"
PATH="$stub:$PATH" "$BIN/wm-switch" feat-login >/dev/null 2>&1
check $? "exact filter needs no picker"
grep -q '^open feat-login$' "$WM_STUB_LOG"
check $? "opens the matched worktree"

: > "$WM_STUB_LOG"
PATH="$stub:$PATH" "$BIN/wm-switch" nope-not-here >/dev/null 2>&1
[[ $? -ne 0 ]]; check $? "unmatched filter fails"
! grep -q '^open' "$WM_STUB_LOG"
check $? "unmatched filter opens nothing"

print -- "wm-sync"
: > "$WM_STUB_LOG"
PATH="$stub:$PATH" "$BIN/wm-sync" >/dev/null 2>&1
check $? "wm-sync succeeds"
grep -q '^sync-files --all$' "$WM_STUB_LOG"
check $? "wm-sync syncs every worktree"

cat > "$stub/workmux" <<'STUB'
#!/usr/bin/env zsh
print -u2 -- "boom"
exit 3
STUB
chmod +x "$stub/workmux"
PATH="$stub:$PATH" "$BIN/wm-sync" >/dev/null 2>&1
[[ $? -eq 3 ]]; check $? "wm-sync propagates workmux's exit code"
make_stub

print -- "wm-add"
: > "$WM_STUB_LOG"
print -n "" | PATH="$stub:$PATH" "$BIN/wm-add" >/dev/null 2>&1
[[ $? -ne 0 ]]; check $? "empty branch name is rejected"
[[ ! -s "$WM_STUB_LOG" ]]
check $? "empty branch name never reaches workmux"

: > "$WM_STUB_LOG"
print -n "  feat/login  " | PATH="$stub:$PATH" "$BIN/wm-add" >/dev/null 2>&1
check $? "branch name read from stdin"
grep -q '^add feat/login$' "$WM_STUB_LOG"
check $? "branch name is trimmed before workmux add"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
