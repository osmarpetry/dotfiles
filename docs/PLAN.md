# Plan: portable setup, fleet updates, agents

**Superseded 2026-09-13** by the ansible → shell/symlink restructure. What's
below is trimmed to what's still true; the rest was carried out or replaced.

## 1. One dotfiles — done

The duplicate-dotfiles-path bug (`ansible/tasks/folders.yml` creating
`~/workspace/osmarpetry/dotfiles`) and the stale `/Users/osmarpetry` paths in
`manifests/` are both fixed by the restructure: there's no more ansible task
to create a second copy, and the manifests were regenerated with real paths.

## 2. SSH keys across machines — superseded

Superseded: manual-only SSH, no ansible-vault. See `ssh/README.md` for the
current approach (private keys never in the repo, `github-personal` /
`github-work` Host aliases, `git/gitconfig`'s `includeIf`). The one part of
this section that survived unchanged: SSH commit signing via
`ssh/allowed_signers` + `gpg.format = ssh` — that's live in `git/gitconfig`.

## 3. Dependabot across the fleet — still open, unblocked

Still valid, not touched by the restructure:

- `scripts/fleet_dependabot.zsh --apply` — writes grouped configs across the
  workspace. Last dry run: would write 44 config(s), 26 skipped.
- Expect the first month noisy — 44 repos with no prior dependency updates
  will each open one PR per ecosystem. Group the first pass by ecosystem.
- Do not add CI automerge yet — only 6 repos have real test suites.
- Adopt `caarlos0/dotfiles/skills/dependabot-merge/` as a vendored skill
  instead: it triages by reading the diff, not by trusting a green check that
  doesn't exist for most of this fleet.

## 4. How the agents are run — informed the restructure's design

The split this section identified — **agents carry judgment, skills carry
procedure** — is now the literal design of `agents/personas/` (judgment,
Claude-Code-specific, one persona per file) vs. `skills/` (procedure, vendored
via `scripts/sync_skills.zsh`, symlinked by `link.sh`). See
`agents/personas/README.md`, which quotes this line directly.

Still open, unblocked by the restructure:

1. Write `AGENTS.md` files in the repos with active work (`dns-cv`,
   `obsidian-2025`, `yan-template-next-2026`) — hand-written, not templated,
   describing that project's commands/layout/gotchas. This repo's own
   `AGENTS.md` is the global working agreement, not a per-project one.
2. Adopt `dependabot-merge` (see section 3).
