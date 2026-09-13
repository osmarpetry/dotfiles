#!/usr/bin/env zsh
# Bundles every local branch/ref not on its upstream (or with no upstream at
# all) into one dated 7z archive, so nothing is lost migrating machines.
#
#   ./scripts/backup_unpushed_repos.zsh            # dry run
#   ./scripts/backup_unpushed_repos.zsh --apply
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
manifest="${REPOS_MANIFEST:-$repo_dir/manifests/repos.json}"
workspace="${WORKSPACE_DIR:-$HOME/workspace}"
dest_dir="${BACKUP_DIR:-$workspace/backups}"
mode="${1:---dry-run}"

case "$mode" in
  --dry-run|--apply) ;;
  *) print -r -- "error: unknown mode: $mode (use --dry-run or --apply)" >&2; exit 1 ;;
esac

[ -f "$manifest" ] || { print -r -- "error: no manifest at $manifest" >&2; exit 1 }

has_unpushed_work() {
  local dir="$1"
  git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  local branch upstream
  for branch in $(git -C "$dir" for-each-ref --format='%(refname:short)' refs/heads); do
    upstream=$(git -C "$dir" rev-parse --abbrev-ref --symbolic-full-name "$branch@{u}" 2>/dev/null) || { return 0 }
    git -C "$dir" rev-list --count "$upstream..$branch" 2>/dev/null | grep -qv '^0$' && return 0
  done
  return 1
}

bundled=0
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

while IFS= read -r repo; do
  owner="$(jq -r '.owner' <<<"$repo")"
  name="$(jq -r '.name' <<<"$repo")"
  dir="$workspace/$owner/$name"
  [ -d "$dir/.git" ] || continue

  if has_unpushed_work "$dir"; then
    print -- "bundle: $owner/$name"
    if [ "$mode" = "--apply" ]; then
      git -C "$dir" bundle create "$tmp_dir/$owner-$name.bundle" --all
    fi
    bundled=$(( bundled + 1 ))
  fi
done < <(jq -c '.repos[]' "$manifest")

if [ "$mode" = "--apply" ] && [ "$bundled" -gt 0 ]; then
  mkdir -p "$dest_dir"
  archive="$dest_dir/repos-unpushed-$(date +%Y-%m-%d).7z"
  7z a "$archive" "$tmp_dir"/*.bundle >/dev/null
  print -- "summary: bundled $bundled repo(s) with unpushed work, archived to $archive"
else
  print -- "summary: would bundle $bundled repo(s) with unpushed work (dry run, nothing written)"
fi
