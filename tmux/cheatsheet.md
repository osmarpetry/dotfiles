# tmux cheatsheet — prefix + ?

## Stock tmux (prefix = C-b unless you've remapped it)

| Key | Action |
|---|---|
| `prefix c` | new window |
| `prefix ,` | rename window |
| `prefix n` / `p` | next / previous window |
| `prefix 0-9` | jump to window N |
| `prefix %` | split pane vertically |
| `prefix "` | split pane horizontally |
| `prefix o` | cycle panes |
| `prefix z` | zoom/unzoom pane |
| `prefix x` | kill pane |
| `prefix [` | enter copy mode (vi keys — `v` select, `y` copy) |
| `prefix d` | detach session |
| `prefix s` | list sessions |
| Mouse | click to select pane/window, drag to resize, scroll for copy mode (mouse is on) |

## This repo's worktree layer

Two ways to the same actions — `prefix w` for a one-shot key table (hints show in the status bar), or `C-Space` / `prefix Space` for the tmux-which-key popup menu (`w` for the `+Worktrees` submenu).

| Key (after `prefix w`) | Action |
|---|---|
| `a` | add worktree, new branch |
| `b` | add worktree, existing branch (fzf pick) |
| `s` | switch worktree (fzf pick, across repos) |
| `d` | workmux dashboard |
| `g` | workmux sidebar |
| `y` | sync files to all worktrees |
| `r` | remove worktree |
| `m` | merge worktree |
| `l` | list worktrees (with PR status) |
| `Enter` / `Esc` / `q` | back to root table |

Full reference for everything tmux-which-key knows: `C-Space`.
