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

Everything in this folder except `README.md` is gitignored.
