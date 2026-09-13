#!/usr/bin/env zsh
# TDD harness for dx pure functions. No network, no filesystem writes.
set -uo pipefail

source "${0:A:h}/core.zsh"

typeset -g pass=0 fail=0

check() {
  local label="$1" want="$2" got="$3"
  if [[ "$got" == "$want" ]]; then
    (( pass++ ))
  else
    (( fail++ ))
    print -r -- "FAIL  $label"
    print -r -- "        want: ${(qqq)want}"
    print -r -- "        got:  ${(qqq)got}"
  fi
}

# --- dx_clean_version: npm range -> bare semver -------------------------------
check "clean ^"        "3.15.3"  "$(dx_clean_version '^3.15.3')"
check "clean ~"        "4.5.2"   "$(dx_clean_version '~4.5.2')"
check "clean exact"    "4.10.0"  "$(dx_clean_version '4.10.0')"
check "clean range"    "3.0.0"   "$(dx_clean_version '>=3.0.0 <4.0.0')"
check "clean v-prefix" "26.7.0"  "$(dx_clean_version 'v26.7.0')"
check "clean latest"   "latest"  "$(dx_clean_version 'latest')"
check "clean partial"  "22"      "$(dx_clean_version '22')"
check "clean workspace" ""       "$(dx_clean_version 'workspace:*')"

# --- dx_pick_tag: wanted version + tag list -> best tag -----------------------
tags_nuxt=$'v3.15.2\nv3.15.3\nv4.5.0\nv4.5.2'
check "tag exact v"      "v3.15.3" "$(dx_pick_tag '3.15.3' $tags_nuxt)"
check "tag exact bare"   "1.9.0"   "$(dx_pick_tag '1.9.0' $'1.8.0\n1.9.0')"
check "tag nearest patch" "v3.15.3" "$(dx_pick_tag '3.15.9' $tags_nuxt)"
check "tag nearest major" "v3.15.3" "$(dx_pick_tag '3.99.0' $tags_nuxt)"
check "tag latest"       "v4.5.2"  "$(dx_pick_tag 'latest' $tags_nuxt)"
check "tag no match"     ""        "$(dx_pick_tag '2.0.0' $tags_nuxt)"
check "tag skips rc"     "v1.8.2"  "$(dx_pick_tag 'latest' $'v1.8.1\nv1.8.2\nv1.8.3-server-1.32.0-162.0')"

# --- dx_eol_verdict: endoflife.date cycle -> status ---------------------------
# args: eol_field support_field today
check "eol passed"   "EOL"      "$(dx_eol_verdict '2026-07-31' '2025-07-16' '2026-09-01')"
check "eol false"    "OK"       "$(dx_eol_verdict 'false' 'true' '2026-09-01')"
check "eol future"   "OK"       "$(dx_eol_verdict '2028-04-30' '2026-10-20' '2026-09-01')"
check "security only" "SECURITY" "$(dx_eol_verdict '2028-04-30' '2025-04-02' '2026-09-01')"
check "eol today"    "EOL"      "$(dx_eol_verdict '2026-09-01' 'false' '2026-09-01')"

# --- dx_registry_field: slug + column -> value --------------------------------
check "reg repo"    "nuxt/nuxt" "$(dx_registry_field nuxt repo)"
check "reg strategy" "tag"      "$(dx_registry_field nuxt strategy)"
check "reg missing"  ""         "$(dx_registry_field nope repo)"

print -r -- "----"
print -r -- "pass=$pass fail=$fail"
(( fail == 0 ))
