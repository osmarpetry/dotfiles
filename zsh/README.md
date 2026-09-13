# zsh

`install-configured.sh` installs Oh My Zsh fresh if `~/.oh-my-zsh` is missing
(same behavior as before this restructure — no custom `~/.oh-my-zsh/custom`
is transferred, no old `.zshrc` is copied in).

`my-zsh.sh` is the new home for anything that isn't Oh My Zsh — personal
aliases, functions, env vars. `link.sh` adds one idempotent line to
`~/.zshrc` sourcing it, and another sourcing `dx/dx.zsh`. Starts empty; this
is scaffolding for whatever accumulates over time.

For inspiration on how this file might grow, look at
[ThePrimeagen/.dotfiles](https://github.com/ThePrimeagen/.dotfiles)'s
`scripts/` folder — a grab-bag of small personal shell helpers, added one at
a time as needed rather than designed up front. Same idea here, not copied
content.
