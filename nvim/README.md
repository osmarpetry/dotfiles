# nvim

`install-configured.sh` clones [LazyVim/starter](https://github.com/LazyVim/starter)
to `~/.config/nvim` if it's missing or doesn't look like a LazyVim setup
(checked via `lua/config/lazy.lua`). That scaffold — `lua/config/{options,
keymaps,autocmds,lazy}.lua`, `lua/plugins/example.lua`, `lazy-lock.json` — is
never touched by this repo, so LazyVim's own upstream updates aren't fought.

`lua/config/` and `lua/plugins/` here are for **your own additions only**.
`link.sh` symlinks each `.lua` file in these two folders (individually, not
the whole directory — a directory-level link would collide with LazyVim's own
files) into the matching path under `~/.config/nvim`. Both start empty; add a
file here when you have your first real override, pick a name that doesn't
collide with LazyVim's stock files (`options.lua`, `keymaps.lua`, `autocmds.lua`,
`lazy.lua`, `example.lua`).

Because the link is per-file and bidirectional, editing either the repo copy
or the `~/.config/nvim` copy is the same file — no separate sync step.
