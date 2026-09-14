# local

Gitignored, machine-only overrides — never committed. This is the "secret
folder" pattern from ThePrimeagen's `.dotfiles` (his `personal/` folder),
adapted here.

- `ssh-config` — included as the first line of `ssh/config`. Anything
  machine-specific that shouldn't be shared across machines goes here.
  Created empty automatically by `link.sh` if missing.
- `.gitconfig-work` (lives at `~/.gitconfig-work`, not actually in this
  folder — see `git/README.md`) is the same idea: real values, never
  committed, copied by hand from the matching `.example` file in `git/`.
- `backups/` — where `link.sh` moves a real file it's about to replace with
  a symlink (named `<path-with-slashes-as-underscores>`). Deliberately
  outside every directory Claude Code scans for skills/agents
  (`~/.claude/skills/`, `~/.claude/agents/`) — the first real run of
  `link.sh` backed those up as siblings instead, and Claude Code promptly
  listed each backup as a bogus extra skill. Safe to delete anything in here
  once you've confirmed you don't need the pre-dotfiles version back.

Everything in this folder except `README.md` is gitignored.
