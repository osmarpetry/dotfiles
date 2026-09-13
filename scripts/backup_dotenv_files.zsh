#!/usr/bin/env zsh
# Bundles every .env* file under the workspace into one dated 7z archive,
# preserving relative paths so restore drops them back where they came from.
#
# This archive holds secrets. Never commit it. Store it only in your own cold
# storage (same destination as the old lixo backup — out of this repo).
#
#   ./scripts/backup_dotenv_files.zsh            # dry run
#   ./scripts/backup_dotenv_files.zsh --apply
set -euo pipefail

workspace="${WORKSPACE_DIR:-$HOME/workspace}"
dest_dir="${BACKUP_DIR:-$workspace/backups}"
mode="${1:---dry-run}"

case "$mode" in
  --dry-run|--apply) ;;
  *) print -r -- "error: unknown mode: $mode (use --dry-run or --apply)" >&2; exit 1 ;;
esac

[ -d "$workspace" ] || { print -r -- "error: no workspace at $workspace" >&2; exit 1 }

files=()
while IFS= read -r -d '' f; do
  files+=("$f")
done < <(find "$workspace" -type f -name '.env*' -not -path '*/node_modules/*' -print0)

if [ ${#files[@]} -eq 0 ]; then
  print -- "summary: found 0 .env file(s), nothing to do"
  exit 0
fi

if [ "$mode" = "--apply" ]; then
  mkdir -p "$dest_dir"
  archive="$dest_dir/dotenv-$(date +%Y-%m-%d).7z"
  (cd "$workspace" && 7z a "$archive" "${files[@]/#$workspace\//}" >/dev/null)
  print -- "summary: archived ${#files[@]} .env file(s) to $archive"
else
  print -- "summary: would archive ${#files[@]} .env file(s) (dry run, nothing written)"
  printf '  %s\n' "${files[@]}"
fi
