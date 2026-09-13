#!/usr/bin/env zsh
# Pure helpers for dx. Sourcing this file must have no side effects.

DX_HOME="${DX_HOME:-${0:A:h}}"
DX_CACHE="${DX_CACHE:-$HOME/.cache/dx}"
DX_REGISTRY="${DX_REGISTRY:-$DX_HOME/registry.tsv}"

# "^3.15.3" -> "3.15.3". Empty when the range is not a resolvable version.
dx_clean_version() {
  local raw="${1:-}"
  [[ "$raw" == latest ]] && { print -r -- latest; return }
  [[ "$raw" == (workspace:*|link:*|file:*|catalog:*|npm:*|git+*|*/*) ]] && return
  local v="${raw//[\^~=<>]/}"
  v="${v## }"
  v="${v%% *}"
  v="${v#v}"
  [[ "$v" =~ '^[0-9]+(\.[0-9]+)*$' ]] || return
  print -r -- "$v"
}

# Best tag for a wanted version: exact match, else greatest tag <= wanted
# within the same major. "latest" picks the highest stable tag.
dx_pick_tag() {
  local want="$1" tags="$2" stable exact major
  stable=$(print -r -- "$tags" | grep -E '^v?[0-9]+(\.[0-9]+)*$') || return
  [[ -z "$stable" ]] && return

  if [[ "$want" == latest ]]; then
    print -r -- "$stable" | sort -V | tail -1
    return
  fi

  exact=$(print -r -- "$stable" | grep -xE "v?${want//./\\.}" | head -1)
  [[ -n "$exact" ]] && { print -r -- "$exact"; return }

  major="${want%%.*}"
  print -r -- "$stable" | grep -E "^v?${major}\." | sort -V | awk -v want="$want" '
    function vcmp(a, b,   x, y, i, n) {
      n = split(a, x, "."); split(b, y, ".")
      for (i = 1; i <= 3; i++) {
        if ((x[i] + 0) < (y[i] + 0)) return -1
        if ((x[i] + 0) > (y[i] + 0)) return 1
      }
      return 0
    }
    { bare = $0; sub(/^v/, "", bare); if (vcmp(bare, want) <= 0) best = $0 }
    END { if (best != "") print best }
  '
}

# endoflife.date cycle -> OK | SECURITY | EOL
dx_eol_verdict() {
  local eol="$1" support="$2" today="${3:-$(date +%F)}"
  [[ "$eol" == true ]] && { print -r -- EOL; return }
  if [[ "$eol" == <->-<->-<-> && ! "$eol" > "$today" ]]; then
    print -r -- EOL; return
  fi
  if [[ "$support" == false ]] || [[ "$support" == <->-<->-<-> && ! "$support" > "$today" ]]; then
    print -r -- SECURITY; return
  fi
  print -r -- OK
}

# Look up one column of the registry row for a slug.
dx_registry_field() {
  local slug="$1" col="$2"
  [[ -r "$DX_REGISTRY" ]] || return
  awk -F'\t' -v s="$slug" -v c="$col" '
    /^#/ && !seen { for (i = 1; i <= NF; i++) { h = $i; sub(/^# ?/, "", h); idx[h] = i } ; seen = 1; next }
    /^#/ || NF < 2 { next }
    $1 == s { if (c in idx) print $(idx[c]) }
  ' "$DX_REGISTRY"
}
