#!/usr/bin/env zsh
# Bundles ~/workspace (minus node_modules), the SSH files that live outside
# this repo (ssh/README.md's "never a private key" rule means git clone
# can't restore them), and every populated Claude auto-memory directory
# under ~/.claude/projects/*/memory into one passphrase-encrypted 7z
# archive — everything a fresh git clone of dotfiles doesn't restore.
#
# This archive holds a private SSH key in cleartext once decrypted. Never
# commit it. Store it only in your own cold storage, out of this repo.
#
# --apply requires EXPORT_PASSPHRASE set in your own shell first — 7z has
# no terminal to prompt on when this is run through an agent's tool call.
#
#   ./scripts/export_machine_bootstrap.zsh                          # dry run
#   export EXPORT_PASSPHRASE='...'
#   ./scripts/export_machine_bootstrap.zsh --apply
set -euo pipefail

workspace="${WORKSPACE_DIR:-$HOME/workspace}"
dest_dir="${BACKUP_DIR:-$workspace/backups}"
ssh_dir="${SSH_DIR:-$HOME/.ssh}"
claude_dir="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
mode="${1:---dry-run}"

case "$mode" in
  --dry-run|--apply) ;;
  *) print -r -- "error: unknown mode: $mode (use --dry-run or --apply)" >&2; exit 1 ;;
esac

[ -d "$workspace" ] || { print -r -- "error: no workspace at $workspace" >&2; exit 1 }

if [ "$mode" = "--apply" ] && [ -z "${EXPORT_PASSPHRASE:-}" ]; then
  print -r -- "error: EXPORT_PASSPHRASE not set (export EXPORT_PASSPHRASE='...' first)" >&2
  exit 1
fi

repo_count=$(find "$workspace" -maxdepth 3 -type d -name .git 2>/dev/null | wc -l | tr -d ' ')

ssh_files=(id_ed25519 id_ed25519.pub config allowed_signers tempo_id_rsa tempo_id_rsa.pub)
ssh_present=()
ssh_missing=()
for f in "${ssh_files[@]}"; do
  if [ -e "$ssh_dir/$f" ]; then
    ssh_present+=("$f")
  else
    ssh_missing+=("$f")
  fi
done

memory_candidates=("$claude_dir"/*/memory(N))
memory_present=()
for d in "${memory_candidates[@]}"; do
  [ -n "$(find "$d" -type f -print -quit 2>/dev/null)" ] && memory_present+=("$d")
done

if [ "$mode" = "--dry-run" ]; then
  print -- "summary: would archive $repo_count repo(s) under workspace, ${#ssh_present[@]}/${#ssh_files[@]} ssh file(s), ${#memory_present[@]} claude memory dir(s) (dry run, nothing written)"
  print -- "  ssh present: ${ssh_present[*]:-none}"
  print -- "  ssh missing: ${ssh_missing[*]:-none}"
  print -- "  memory dirs:"
  for d in "${memory_present[@]}"; do
    print -r -- "    ${d:h:t}"
  done
  exit 0
fi

mkdir -p "$dest_dir"
archive="$dest_dir/machine-export-$(date +%Y-%m-%d).7z"

stage=$(mktemp -d)
cleanup() { rm -rf "$stage" }
trap cleanup EXIT

if [ ${#ssh_present[@]} -gt 0 ]; then
  mkdir -p "$stage/ssh"
  for f in "${ssh_present[@]}"; do
    cp "$ssh_dir/$f" "$stage/ssh/$f"
  done
fi

for d in "${memory_present[@]}"; do
  name="${d:h:t}"
  mkdir -p -- "$stage/claude-memory/$name/memory"
  cp -R "$d/." "$stage/claude-memory/$name/memory/"
done

# p7zip 17.05 exits 1 on warnings (e.g. a file vanishing mid-scan) and 2+ on
# real errors; only treat 2+ as fatal so `set -e` doesn't abort on a warning.
#
# -mx1 (fastest, not default -mx5): on a real ~9GB workspace, -mx5 measured
# ~30s/GB (multi-minute, close to a Bash tool call's timeout) for a ~30%
# smaller archive than -mx1's ~13s/GB — git pack files are already
# compressed, so the extra LZMA2 effort buys little. This is meant to run
# from a single Claude Code prompt, so fast and slightly bigger wins.
run_7z() {
  local rc=0
  7z a -mx1 -p"$EXPORT_PASSPHRASE" -mhe=on "$@" >/dev/null || rc=$?
  if [ "$rc" -gt 1 ]; then
    print -r -- "error: 7z exited $rc" >&2
    exit 1
  fi
}

# node_modules is excluded recursively (any depth); the backups dir is
# excluded only at the workspace root, so a repo's own backups/ subdir
# (an unrelated, legitimate tracked path) still gets archived.
excludes=(-xr\!node_modules)
case "$dest_dir" in
  "$workspace"/*)
    rel="${dest_dir#"$workspace"/}"
    excludes+=(-x\!"${workspace:t}/$rel")
    ;;
esac

( cd "${workspace:h}" && run_7z "$archive" "${workspace:t}" "${excludes[@]}" )

extra=()
[ -d "$stage/ssh" ] && extra+=(ssh)
[ -d "$stage/claude-memory" ] && extra+=(claude-memory)
if [ ${#extra[@]} -gt 0 ]; then
  ( cd "$stage" && run_7z "$archive" "${extra[@]}" )
fi

print -- "summary: archived $repo_count repo(s), ${#ssh_present[@]} ssh file(s), ${#memory_present[@]} claude memory dir(s) to $archive"
