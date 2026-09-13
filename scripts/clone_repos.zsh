#!/usr/bin/env zsh
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$repo_dir/manifests/repos.json"
workspace="$HOME/workspace"

cloned=0
existing=0
skipped=()
failed=()

while IFS= read -r repo; do
  owner="$(jq -r '.owner' <<<"$repo")"
  name="$(jq -r '.name' <<<"$repo")"
  remote="$(jq -r '.ssh_remote // .remote' <<<"$repo")"
  slug="$owner/$name"
  dest="$workspace/$owner/$name"

  mkdir -p "$workspace/$owner"
  if [ -d "$dest/.git" ]; then
    echo "exists: $dest"
    existing=$((existing + 1))
    continue
  fi

  if command -v gh >/dev/null 2>&1 && ! gh repo view "$slug" >/dev/null 2>&1; then
    echo "skip: $slug (repository not found or no access)"
    skipped+=("$slug")
    continue
  fi

  echo "clone: $slug -> $dest"
  if command -v gh >/dev/null 2>&1; then
    clone_cmd=(gh repo clone "$slug" "$dest" -- --depth=1)
  else
    clone_cmd=(git clone --depth=1 "$remote" "$dest")
  fi

  if "${clone_cmd[@]}"; then
    cloned=$((cloned + 1))
  else
    echo "failed: $slug" >&2
    failed+=("$slug")
  fi
done < <(jq -c '.repos[]' "$manifest")

echo
echo "clone summary: $cloned cloned, $existing already present, ${#skipped[@]} skipped, ${#failed[@]} failed"

if [ "${#skipped[@]}" -gt 0 ]; then
  printf 'skipped: %s\n' "${skipped[@]}"
fi

if [ "${#failed[@]}" -gt 0 ]; then
  printf 'failed: %s\n' "${failed[@]}" >&2
  exit 1
fi
