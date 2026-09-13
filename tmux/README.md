# tmux

`tmux.conf` — mouse on, vi copy-mode keys, 256color, 50k scrollback, and a
custom worktree-mode key table (see below). Nothing fancy beyond that; it
stays simple on purpose.

`which-key.yaml` — the `tmux-which-key` plugin's menu config. `C-Space` or
`prefix Space` opens it; mirrors every worktree-mode binding under `w` so
there are two ways to find the same action.

`cheatsheet.md` — static reference card, `prefix ?` opens it in a popup
(`display-popup` + `less`). No plugin dependency for this — I looked for a
maintained tmux plugin that replicates tmuxcheatsheet.com as a popup and
wasn't confident one exists/is maintained, so a plain markdown file plus one
keybinding is the simpler, zero-dependency answer.

## Worktree workflow

`workmux` drives git worktrees and tmux targets; this config puts the same
actions behind two discovery surfaces — `prefix w` (key table) and `C-Space`
(which-key popup). Helper scripts (`bin/wm-add`, `wm-switch`, `wm-remove`,
`wm-sync`) get symlinked to `~/.local/bin` by `link.sh`. Per-repo behavior
comes from `.workmux.yaml` at the repo root; global settings live in
`~/.config/workmux/config.yaml`.

See the root README's "tmux worktree workflow" section for the full key
table.
