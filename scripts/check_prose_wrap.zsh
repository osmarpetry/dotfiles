#!/usr/bin/env zsh
# Heuristic checker for hard-wrapped markdown prose: a paragraph line under
# ~95 chars immediately followed by another prose line is the signature of a
# manual line break mid-paragraph — see AGENTS.md §Style.
#
# Skipped as non-prose: fenced code blocks, YAML frontmatter, headings, list
# items, table rows (pipe-prefixed), blockquotes, indented code, and a line
# ending in two trailing spaces (an intentional markdown hard break).
#
#   ./scripts/check_prose_wrap.zsh <file>
#   cat file.md | ./scripts/check_prose_wrap.zsh
#
# Exits non-zero and prints the offending line number(s) when it finds
# wrapped prose; exits 0 (silent) otherwise.
set -uo pipefail

WRAP_THRESHOLD=95

input="${1:-}"
if [[ -n "$input" && "$input" != "-" ]]; then
  content="$(cat -- "$input")"
else
  content="$(cat)"
fi

typeset -a lines
lines=("${(@f)content}")
n=${#lines[@]}

typeset -a is_prose
typeset -a lengths
tab=$'\t'
in_fence=0
# Frontmatter only counts when the file opens with a "---" line.
in_frontmatter=0
[[ $n -ge 1 && "${lines[1]}" == "---" ]] && in_frontmatter=1

for (( i = 1; i <= n; i++ )); do
  line="${lines[$i]}"

  if (( in_frontmatter )); then
    is_prose[$i]=0
    [[ "$line" == "---" && $i -gt 1 ]] && in_frontmatter=0
    continue
  fi

  if [[ "$line" =~ '^[[:space:]]*(```|~~~)' ]]; then
    (( in_fence = ! in_fence ))
    is_prose[$i]=0
    continue
  fi
  if (( in_fence )); then
    is_prose[$i]=0
    continue
  fi

  if [[ -z "${line//[[:space:]]/}" ]]; then
    is_prose[$i]=0
    continue
  fi

  is_other=0
  [[ "$line" =~ '^[[:space:]]*#' ]] && is_other=1
  [[ "$line" =~ '^[[:space:]]*[-*+][[:space:]]' ]] && is_other=1
  [[ "$line" =~ '^[[:space:]]*[0-9]+[.)][[:space:]]' ]] && is_other=1
  [[ "$line" =~ '^[[:space:]]*\|' ]] && is_other=1
  [[ "$line" =~ '^[[:space:]]*>' ]] && is_other=1
  [[ "$line" == '    '* ]] && is_other=1
  [[ "$line" == "${tab}"* ]] && is_other=1

  if (( is_other )); then
    is_prose[$i]=0
    continue
  fi

  is_prose[$i]=1
  lengths[$i]=${#line}
done

typeset -a offenders
for (( i = 1; i < n; i++ )); do
  next=$(( i + 1 ))
  [[ ${is_prose[$i]:-0} -eq 1 ]] || continue
  [[ ${is_prose[$next]:-0} -eq 1 ]] || continue
  [[ "${lines[$i]}" == *'  ' ]] && continue
  (( lengths[$i] < WRAP_THRESHOLD )) || continue
  offenders+=("$i")
done

if (( ${#offenders[@]} > 0 )); then
  print -- "hard-wrapped prose at line(s): ${offenders[*]}"
  exit 1
fi

exit 0
