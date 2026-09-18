#!/usr/bin/env zsh
# Tests for scripts/check_prose_wrap.zsh: flagging a hard-wrapped paragraph
# while leaving lists, tables, fenced code, and frontmatter alone.
# Run: ./tests/prose_wrap_test.zsh
set -uo pipefail

DOTFILES="${0:A:h}/.."
CHECK="$DOTFILES/scripts/check_prose_wrap.zsh"

pass=0 fail=0
ok()   { print -r -- "  ok   $1"; pass=$(( pass + 1 )) }
nope() { print -r -- "  FAIL $1"; fail=$(( fail + 1 )) }
check(){ [[ $1 -eq 0 ]] && ok "$2" || nope "$2" }

print -- "script"
[[ -f "$CHECK" ]]; check $? "check_prose_wrap.zsh exists"
[[ -x "$CHECK" ]]; check $? "check_prose_wrap.zsh is executable"

print -- "a wrapped paragraph is flagged"
out="$(printf 'This is a line that wraps\nonto the next line here.\n' | "$CHECK")"
rc=$?
[[ $rc -ne 0 ]]; check $? "exits non-zero on a wrapped paragraph"
print -r -- "$out" | grep -q '^hard-wrapped prose'
check $? "reports the offending line(s)"
print -r -- "$out" | grep -qE ' 1($| )'
check $? "line 1 is named as the offender"

print -- "a single-line paragraph is clean"
printf 'One unbroken paragraph line, however long it might be in practice.\n\nAnother paragraph on its own line.\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on unwrapped paragraphs"

print -- "a long list is never flagged"
{ for i in {1..20}; do print -- "- item number $i in a fairly long list of things"; done } \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on a long list"

print -- "a table is never flagged"
printf '| column one | column two | column three |\n| --- | --- | --- |\n| a | b | c |\n| d | e | f |\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on a table"

print -- "fenced code is never flagged, even with wrapped-looking lines"
printf '```\nshort line one\nshort line two\nshort line three\n```\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on fenced code"

print -- "a wrapped-looking line inside a code fence is not flagged"
out="$(printf 'Real prose that wraps\nonto a second line.\n\n```\nfake wrap one\nfake wrap two\n```\n' | "$CHECK")"
rc=$?
[[ $rc -ne 0 ]]; check $? "still flags the real wrapped paragraph"
print -r -- "$out" | grep -qE ' 5| 6'
[[ $? -ne 0 ]]; check $? "does not name the fenced lines as offenders"

print -- "a fenced code block indented under a list item is never flagged"
printf '1. do the thing:\n   ```\n   short line one\n   short line two\n   ```\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on an indented fence"

print -- "YAML frontmatter is never flagged"
printf -- '---\nname: example\ndescription: a fairly long description that would otherwise look wrapped\n---\n\nBody paragraph alone.\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 with frontmatter present"

print -- "a markdown hard break (two trailing spaces) is not flagged"
printf 'line one with an intentional break  \nline two right after.\n' \
  | "$CHECK" >/dev/null 2>&1
check $? "exits 0 on an explicit hard break"

print -- ""
print -- "$pass passed, $fail failed"
(( fail == 0 ))
