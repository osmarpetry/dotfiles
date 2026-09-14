# Mac workstation todo

Status model: every item below is already decided. `Decision: approved` means
implement it. `Decision: removed` means keep it out.

This file used to assume Ansible end-to-end. It doesn't anymore — Step 5 and
Step 11 are rewritten for the shell + symlink setup this repo now uses
(`setup.sh`, `install-*.sh`, `link.sh`). Everything else here is the same
shape as before.

## Scope

- macOS primary, Linux supported (package manager and Mac-only steps auto-skip
  on Linux — see root README's "Platform support" section).
- Repos go under `~/workspace/<github-username>/<repo>`.
- Install Oh My Zsh fresh; LazyVim fresh via `LazyVim/starter`, with your own
  overrides layered in from `nvim/lua/{config,plugins}` (see `nvim/README.md`)
  — this is new since the restructure: personal nvim config now persists.
- Transfer: SSH public keys + config (never private keys, see
  `ssh/README.md`), Raycast shortcut list, selected Clop preferences, repo
  clone manifest.
- No xbar, no Steam menu bar — dropped entirely.
- Clone repositories with `--depth=1`.
- Prefer Homebrew casks for apps. `binary-apps/` (download link opened on
  demand) or manual install only when no cask exists.

## Step 1: Create folders

Todo 1.1 — Create `~/workspace`. Decision: approved
Todo 1.2 — Create owner folders from the repo manifest. Decision: approved
Todo 1.3 — Clone this dotfiles repo to `~/dotfiles` (nowhere else — no copy
inside `~/workspace`). Decision: approved

## Step 2: Install base packages

Todo 2.1 — Install Homebrew (macOS) or apt packages (Linux) via
`install-essential.sh`. Decision: approved

Todo 2.2 — Install asdf-managed runtimes (nodejs, golang, python, pnpm, rust,
java) via `install-configured.sh`. No nvm, no fixed old versions beyond the
pins already in that script (python 3.14.7, java Temurin 21 LTS — see
`install-configured.sh`'s `setup_asdf`). Decision: approved

Todo 2.3 — Monthly Node update via `scripts/update-node-latest.zsh` +
LaunchAgent, installed by `install-configured.sh`. Decision: approved

Todo 2.4 — Verify asdf works in a fresh zsh shell: `asdf --version`,
`asdf plugin list`, shim lookup. Decision: approved

## Step 3: Install apps with Brew

Todo 3.1 — Install everything in `Brewfile`'s configured + optional sections.
Decision: approved

Todo 3.2 — Apps with no Homebrew cask: `install-optional.sh` opens the
download page for anything in `binary-apps/README.md`'s table with a known
URL; install is a manual drag to `/Applications` from there. Decision: approved

Todo 3.3 — Use `microsoft-office` instead of individual Word/Excel/PowerPoint
casks. Decision: approved

Todo 3.4 — Ignore Steam games in `~/Applications`; Steam manages them.
Decision: approved

## Step 4: Shell and editor setup

Todo 4.1 — Install Oh My Zsh fresh (`install-configured.sh`). Decision: approved

Todo 4.2 — `link.sh` adds `zsh/my-zsh.sh` and `dx/dx.zsh` source lines to
`.zshrc`; no old `.zshrc` is copied in wholesale. Decision: approved

Todo 4.3 — Install LazyVim fresh if `~/.config/nvim` is missing/not LazyVim.
Decision: approved

Todo 4.4 — Layer personal nvim config from `nvim/lua/{config,plugins}` via
`link.sh` (file-by-file symlinks, LazyVim's own files untouched).
Decision: approved

## Step 5: SSH — manual key transfer, no vault

Todo 5.1 — Copy `~/.ssh/id_ed25519` and `~/.ssh/tempo_id_rsa` by hand
(password manager, AirDrop, or a temporary HTTPS token for the first clone).
Never through this repo, never encrypted-in-git. Decision: approved

Todo 5.2 — `link.sh` symlinks `ssh/config`, `ssh/allowed_signers`, and both
`.pub` files into `~/.ssh/`. Decision: approved

Todo 5.3 — Set permissions: `.ssh` `0700`, private keys `0600` (do this by
hand after copying the keys in). Decision: approved

Todo 5.4 — Do not transfer GitHub CLI token/config; `gh auth login` again.
Decision: approved

Todo 5.5 — See `ssh/README.md` for the personal/work identity split
(`github-personal` / `github-work` Host aliases, `git/gitconfig`'s
`includeIf`). Decision: approved

## Step 6: Raycast minimal setup

Todo 6.1 — Install Raycast with Brew cask. Decision: approved

Todo 6.2 — Do not import full Raycast config/`.rayconfig`. Decision: approved

Todo 6.3 — Recreate hotkeys from `docs/apps/raycast.md`. Decision: approved

Todo 6.4 — Verify in Raycast Settings with "Show only customized" enabled.
Decision: approved

## Step 7: Clop configuration

Todo 7.1 — Install Clop with Brew cask. Decision: approved

Todo 7.2 — `install-configured.sh` runs `clop/restore_clop_prefs.py` against
`clop/preferences.selected.plist`, rewriting the home path. Decision: approved

Todo 7.3 — Verify: images watched in Desktop/Downloads, videos in
Desktop/Downloads/Movies, clipboard optimization enabled. Decision: approved

## Step 8: Hammerspoon

Todo 8.1 — Install Hammerspoon with Brew cask. Decision: approved

Todo 8.2 — `link.sh` symlinks `hammerspoon/{init,mic-pin,meeting-reminder}.lua`
into `~/.hammerspoon/`. Decision: approved

Todo 8.3 — Grant Accessibility and Calendar permissions in System Settings
(manual — cannot be automated). Decision: approved

Todo 8.4 — Verify: built-in mic stays default input when a Bluetooth/USB
device connects; a test calendar event triggers a 5-minute-before
notification and opens its URL at start time. Decision: approved

Todo 8.5 — `install-configured.sh`'s `setup_youtrack_cli()` installs `yt`
(YouTrack CLI) via `pipx install youtrack-cli`. Run `yt auth login` once by
hand afterward (manual — needs your YouTrack instance URL + API token
entered interactively, cannot be automated). Decision: approved

## Step 9: AeroSpace

Todo 9.1 — Install AeroSpace via `nikitabobko/tap/aerospace`. Decision: approved

Todo 9.2 — `link.sh` symlinks `aerospace/aerospace.toml` (community default,
not customized) to `~/.aerospace.toml`. Decision: approved

## Step 10: Clone repositories

Todo 10.1 — Regenerate `manifests/repos.json` from current `~/workspace` git
remotes when paths go stale. Decision: approved

Todo 10.2 — Clone repos into `~/workspace/<owner>/<repo>` with `--depth=1`
via `scripts/clone_repos.zsh`. Decision: approved

Todo 10.3 — Review dirty/local-only repos in `manifests/local_only.json`
before relying on clone-only restore. Decision: approved

## Step 11: Backups before migrating off a machine

Todo 11.1 — `./scripts/backup_unpushed_repos.zsh --apply` — bundles every
repo with unpushed local work into one dated 7z. Decision: approved

Todo 11.2 — `./scripts/backup_dotenv_files.zsh --apply` — archives every
`.env*` under the workspace into a second dated 7z (secrets — never commit
it, store only in your own cold storage). Decision: approved

Todo 11.3 — No app-bundle backup step — `binary-apps/README.md`'s download
links cover the next machine instead. Decision: removed

Todo 11.4 — Lixo-style scratch-workspace backup is no longer part of this
repo — handled via your own cloud service instead. Decision: removed

## Step 12: Run it

Todo 12.1 — `./setup.sh --dry-run` first, review the output. Decision: approved

Todo 12.2 — `./setup.sh` for real. Decision: approved

## Step 13: Verify restore

Todo 13.1 — Homebrew packages and apps installed. Decision: approved
Todo 13.2 — zsh opens with Homebrew, asdf, and pinned runtimes available.
Decision: approved
Todo 13.3 — Monthly Node update LaunchAgent loaded. Decision: approved
Todo 13.4 — SSH authenticates with GitHub. Decision: approved
Todo 13.5 — Hammerspoon mic-pin and meeting-reminder both running.
Decision: approved
Todo 13.6 — AeroSpace tiling active. Decision: approved
Todo 13.7 — Raycast shortcuts match `docs/apps/raycast.md`. Decision: approved
Todo 13.8 — Clop watches the approved folders, optimizes clipboard.
Decision: approved
Todo 13.9 — Cloned repos exist under `~/workspace/<owner>/<repo>`.
Decision: approved
Todo 13.10 — `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.claude/agents`
are real symlinks into the repo. Decision: approved
