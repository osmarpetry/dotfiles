# aerospace

Tiling window manager. `aerospace.toml` here is the stock community default
config shipped by AeroSpace itself (`config-version = 2`, the exact file
AeroSpace's own docs tell you to copy to `~/.aerospace.toml`) — intentionally
not heavily customized. `link.sh` symlinks it to `~/.aerospace.toml`.

Cask: `nikitabobko/tap/aerospace` (the tap was already in the Brewfile before
this restructure, just unused — this is what it was for).

If you do customize it later, edit `aerospace/aerospace.toml` in the repo
directly (it's a live symlink, not a copy) and see
https://nikitabobko.github.io/AeroSpace/guide for the option reference.
