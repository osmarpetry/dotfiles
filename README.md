# osmar dotfiles

Mac (primary) and Linux workstation setup — plain shell scripts and
symlinks, no ansible, no framework.

## Platform support

**macOS is the primary target** — package installs use Homebrew, plus
Mac-only tooling (Hammerspoon, AeroSpace, Clop, `.app` backups in
`binary-apps/`). **On Linux**, `setup.sh` uses `apt` instead and
automatically skips every Mac-only step (no error, just a log line) — tmux,
zsh, nvim, ssh, git identity, and skills/agents all still work there.

## Run it

```sh
./setup.sh --dry-run   # see what would happen, changes nothing
./setup.sh              # do it
```

Runs, in order: `install-essential.sh` (Homebrew/apt bootstrap) →
`link.sh` (symlink every managed config into place) →
`install-configured.sh` (apps this repo also configures) →
`install-optional.sh` (everything else, plus opening download pages for
apps in `binary-apps/`).

## What this does not automate

- **SSH private keys** — never touch this repo, not even encrypted. Copied
  in by hand on a new machine. See `ssh/README.md`.
- A handful of apps with no Homebrew cask and no config to restore — see
  `docs/apps/` and `binary-apps/README.md`. Install is a manual drag to
  `/Applications` after `install-optional.sh` opens the download page.
- Machine-migration backups (unpushed git branches, `.env` secrets) are
  scripts you run deliberately before wiping a machine, not part of
  `setup.sh` — see `scripts/backup_unpushed_repos.zsh`,
  `scripts/backup_dotenv_files.zsh`.
- Scratch-workspace (`lixo`) backup lives in a personal cloud service now,
  out of this repo's scope entirely.

## Layout

| Folder | What's in it |
|---|---|
| `AGENTS.md` | Canonical agent working agreement — symlinked to both `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, so Claude Code and Codex read the same file |
| `agents/personas/` | Custom Claude Code subagents |
| `skills/` | Vendored agent skills, symlinked into `~/.claude/skills/` |
| `ssh/`, `git/` | SSH config/public keys, git config, personal/work identity split |
| `tmux/`, `nvim/`, `zsh/` | Per-tool config, each with its own README |
| `aerospace/`, `hammerspoon/` | Window management, mic-pin, meeting reminders |
| `zed/`, `clop/` | Minimal per-app setup |
| `dx/` | Offline versioned docs CLI + Claude/Codex skill |
| `binary-apps/` | Download links for apps with no Homebrew cask |
| `scripts/` | Everything not tied to a specific tool folder |
| `manifests/` | Repo clone list, dependabot skip list, package version lock |
| `docs/` | Migration checklist, per-app notes, superseded planning doc |
| `tests/` | Hand-rolled, dependency-free `*.zsh` tests — run each directly |

## Personal vs. work identity

Personal identity is the default everywhere. A work override only kicks in
for anything cloned under `~/workspace/work/**`, via git's `includeIf` and a
matching SSH Host alias. See `ssh/README.md` and `git/README.md`.

## Testing

No TDD requirement for this repo — every mutating script supports
`--dry-run`, which is the safety net. Run any test file directly:

```sh
./tests/skills_sync_test.zsh
```

Full checklist for a from-scratch machine: `less docs/WORKSTATION_TODO.md`.

## tmux worktree workflow

`workmux` drives git worktrees and tmux targets; the tmux layer here puts the
same actions behind two discovery surfaces.

| Surface | Key | Behaviour |
| --- | --- | --- |
| Key table | `prefix + w` | Enters `worktree-mode`; the status bar renders the hints and the next key runs an action, then drops back to root. |
| which-key | `C-Space` or `prefix + Space` | Popup menu, `w` opens `+Worktrees`. |

Same keys in both: `a` add (new branch), `b` add (existing branch), `s` switch,
`d` dashboard, `g` sidebar, `y` sync files, `r` remove, `m` merge, `l` list.

Cheatsheet for all of this plus stock tmux bindings: `prefix + ?`.

Per-repo behaviour comes from a `.workmux.yaml` at the repo root (`workmux init`
writes a commented example): which files to copy, which to symlink, and the
window/pane layout to open. Global settings live in `~/.config/workmux/config.yaml`.

```sh
./tests/tmux_worktree_test.zsh
```
