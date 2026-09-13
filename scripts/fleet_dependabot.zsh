#!/usr/bin/env zsh
# Plans and writes grouped dependabot configs across the workspace.
#
# Dependabot only reads .github/dependabot.yml from the repository it runs in —
# there is no `uses:` and no inheritance, so the config cannot be centralised in
# a shared repo. It has to be copied into each one. This writes that copy.
#
# Grouping is the point: `groups: patterns: ["*"]` collapses what would be one
# pull request per dependency into one per ecosystem per month, which is the
# difference between a fleet that is maintainable and one that is noise.
#
#   ./scripts/fleet_dependabot.zsh            # dry run, writes nothing
#   ./scripts/fleet_dependabot.zsh --apply    # writes the files
#
# It never talks to the network and never commits. Review the diffs, then commit
# and push yourself.
set -euo pipefail

workspace="${WORKSPACE_DIR:-$HOME/workspace/osmarpetry}"
mode="${1:---dry-run}"

case "$mode" in
  --dry-run|--apply) ;;
  *) print -r -- "error: unknown mode: $mode (use --dry-run or --apply)" >&2; exit 1 ;;
esac

[ -d "$workspace" ] ||
  { print -r -- "error: no workspace at $workspace (set WORKSPACE_DIR)" >&2; exit 1 }

# Repos to leave alone: archived ones are read-only, so dependabot could never
# open a pull request against them, and ones with no remote have nowhere to push.
# Regenerate with: gh repo list <user> --limit 200 \
#   --json name,isArchived --jq '.[] | select(.isArchived) | .name'
skip_file="${DEPENDABOT_SKIP_FILE:-$(cd "$(dirname "$0")/.." && pwd)/manifests/dependabot_skip.txt}"
excluded=()
if [ -f "$skip_file" ]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [ -n "$line" ] && excluded+=("$line")
  done < "$skip_file"
fi

is_excluded() {
  local name="$1" e
  for e in "${excluded[@]}"; do [ "$e" = "$name" ] && return 0; done
  return 1
}

# One manifest file per ecosystem, in the order dependabot should list them.
manifest_for() {
  case "$1" in
    npm)      print -- "package.json" ;;
    gomod)    print -- "go.mod" ;;
    maven)    print -- "pom.xml" ;;
    pip)      print -- "requirements.txt" ;;
    cargo)    print -- "Cargo.toml" ;;
    bundler)  print -- "Gemfile" ;;
    composer) print -- "composer.json" ;;
    pub)      print -- "pubspec.yaml" ;;
  esac
}

# github-actions is deliberately last: it is an add-on to whatever the project
# actually is, not the reason the repo exists.
all_ecosystems=(npm gomod maven pip cargo bundler composer pub)

# Commit prefix per ecosystem, so dependency noise is greppable in the log.
prefix_for() {
  [ "$1" = "github-actions" ] && { print -- "ci"; return 0 }
  print -- "chore"
}

emit_block() {
  local eco="$1"
  cat <<YAML
  - package-ecosystem: "$eco"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
    commit-message:
      prefix: "$(prefix_for "$eco")"
      include: "scope"
    groups:
      $eco:
        patterns:
          - "*"
YAML
}

planned=0
skipped=0
written=0

for dir in "$workspace"/*(N/); do
  name="$(basename "$dir")"
  config="$dir/.github/dependabot.yml"

  if is_excluded "$name"; then
    print -- "  skip   $name (on the exclusion list)"
    skipped=$(( skipped + 1 ))
    continue
  fi

  if [ -f "$config" ]; then
    print -- "  skip   $name (already has a config)"
    skipped=$(( skipped + 1 ))
    continue
  fi

  ecosystems=()
  for eco in "${all_ecosystems[@]}"; do
    [ -f "$dir/$(manifest_for "$eco")" ] && ecosystems+=("$eco")
  done
  # Only worth tracking actions when the repo actually runs any.
  if [ -d "$dir/.github/workflows" ]; then
    ecosystems+=("github-actions")
  fi

  if [ ${#ecosystems[@]} -eq 0 ]; then
    print -- "  skip   $name (no manifest to update)"
    skipped=$(( skipped + 1 ))
    continue
  fi

  print -- "  plan   $name -> ${ecosystems[*]}"
  planned=$(( planned + 1 ))

  if [ "$mode" = "--apply" ]; then
    mkdir -p "$dir/.github"
    {
      print -- "version: 2"
      print -- "updates:"
      for eco in "${ecosystems[@]}"; do emit_block "$eco"; done
    } > "$config"
    written=$(( written + 1 ))
  fi
done

if [ "$mode" = "--apply" ]; then
  print -- "summary: wrote $written config(s), $skipped skipped"
else
  print -- "summary: would write $planned config(s), $skipped skipped (dry run, nothing changed)"
fi
