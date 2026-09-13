#!/usr/bin/env zsh
# Vendors agent skills into this repo and restores them onto a machine.
#
# Skills are installed from ~19 upstream GitHub repositories and pinned by hash
# in .skill-lock.json. Re-installing on a new machine would re-clone each of
# those repos and take whatever is on their default branch today, which is not
# what the lock file pinned. So we keep the skills as files in this repo and
# copy them into place instead. This script never touches the network.
#
#   ./scripts/sync_skills.zsh --export    # machine -> repo (snapshot)
#   ./scripts/sync_skills.zsh --install   # repo -> machine (restore)
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"

agents_dir="${AGENTS_DIR:-$HOME/.agents}"
claude_skills_dir="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
vendor_dir="${SKILLS_VENDOR_DIR:-$repo_dir/skills}"

lock_name=".skill-lock.json"
mode="${1:---export}"

die() { print -r -- "error: $*" >&2; exit 1 }

# Copy a skills tree plus its lock file. Mirrors, so a skill removed upstream
# also disappears here rather than lingering forever.
copy_tree() {
  local src_skills="$1" src_lock="$2" dst_skills="$3" dst_lock="$4"
  mkdir -p "$(dirname "$dst_skills")"
  # README.md lives alongside the skill dirs in the vendored copy; don't wipe it.
  local readme_bak=""
  if [ -d "$dst_skills" ] && [ -f "$dst_skills/README.md" ]; then
    readme_bak="$(cat "$dst_skills/README.md")"
  fi
  rm -rf "$dst_skills"
  mkdir -p "$dst_skills"
  for skill in "$src_skills"/*(N/); do
    cp -R "$skill" "$dst_skills/$(basename "$skill")"
  done
  [ -n "$readme_bak" ] && print -r -- "$readme_bak" > "$dst_skills/README.md"
  [ -f "$src_lock" ] && cp "$src_lock" "$dst_lock"
  return 0
}

count_skills() {
  local dir="$1"
  [ -d "$dir" ] || { print -- 0; return 0 }
  find "$dir" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' '
}

case "$mode" in
  --export)
    [ -d "$agents_dir/skills" ] ||
      die "no skills at $agents_dir/skills (set AGENTS_DIR)"

    copy_tree "$agents_dir/skills" "$agents_dir/$lock_name" "$vendor_dir" "$vendor_dir/$lock_name"
    n="$(count_skills "$vendor_dir")"

    if [ -f "$vendor_dir/$lock_name" ]; then locked="yes"; else locked="no"; fi
    print -- "summary: exported $n skill(s) to ${vendor_dir#$repo_dir/}, lock file: $locked"
    ;;

  --install)
    [ -d "$vendor_dir" ] ||
      die "nothing vendored at $vendor_dir (run --export first)"

    copy_tree "$vendor_dir" "$vendor_dir/$lock_name" "$agents_dir/skills" "$agents_dir/$lock_name"

    mkdir -p "$claude_skills_dir"
    linked=0
    kept=0
    for skill in "$agents_dir"/skills/*(N/); do
      name="$(basename "$skill")"
      target="$claude_skills_dir/$name"
      if [ -e "$target" ] && [ ! -L "$target" ]; then
        # A real (non-symlink) directory here is locally managed some other
        # way. Never overwrite it with a link.
        kept=$(( kept + 1 ))
        continue
      fi
      ln -sfn "$skill" "$target"
      linked=$(( linked + 1 ))
    done

    n="$(count_skills "$agents_dir/skills")"
    print -- "summary: installed $n skill(s), $linked linked, $kept local skill(s) kept"
    ;;

  *)
    die "unknown mode: $mode (use --export or --install)"
    ;;
esac
