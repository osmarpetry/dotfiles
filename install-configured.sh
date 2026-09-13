#!/usr/bin/env sh
# Installs + configures everything link.sh already placed a config file for.
# Each function is its own step so a failure in one doesn't hide the rest.
set -u

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/lib.sh"

setup_brew_configured() {
  is_macos || return 0
  awk '/# ---- configured ----/,/# ---- optional ----/' "$DOTFILES/Brewfile" \
    | grep -v '# ---- optional ----' > /tmp/Brewfile.configured
  run brew bundle --file /tmp/Brewfile.configured
}

setup_apt_configured() {
  is_linux || return 0
  run sudo apt-get install -y tmux zsh-syntax-highlighting neovim fzf ripgrep jq
}

setup_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    run sh -c 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi
}

setup_asdf() {
  command -v asdf >/dev/null 2>&1 || { log "skip: asdf plugins (asdf not installed)"; return 0; }
  for plugin in nodejs golang python pnpm rust java; do
    run sh -c "asdf plugin add $plugin >/dev/null 2>&1 || true"
  done
  run asdf install nodejs latest
  run asdf set -u nodejs latest
  run asdf install golang latest
  run asdf set -u golang latest
  # "latest" python resolves to the free-threaded "t" build, pin a stable release instead
  run asdf install python 3.14.7
  run asdf set -u python 3.14.7
  run asdf install pnpm latest
  run asdf set -u pnpm latest
  run asdf install rust latest
  run asdf set -u rust latest
  run asdf install java temurin-21.0.12+101.0.LTS
  run asdf set -u java temurin-21.0.12+101.0.LTS

  export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
  confirm_dir "$ASDF_DATA_DIR/completions"
  if [ "$DRY_RUN" = "1" ]; then
    log "would write $ASDF_DATA_DIR/completions/_asdf"
  else
    asdf completion zsh > "$ASDF_DATA_DIR/completions/_asdf"
  fi

  confirm_dir "$HOME/.local/bin"
  link "$DOTFILES/scripts/update-node-latest.zsh" "$HOME/.local/bin/update-node-latest"
  confirm_dir "$HOME/Library/LaunchAgents"
  if is_macos; then
    if [ "$DRY_RUN" = "1" ]; then
      log "would render launchagents/dev.osmar.update-node-latest.plist.j2 -> ~/Library/LaunchAgents"
    else
      sed "s#{{ home_dir }}#$HOME#g" "$DOTFILES/launchagents/dev.osmar.update-node-latest.plist.j2" \
        > "$HOME/Library/LaunchAgents/dev.osmar.update-node-latest.plist"
    fi
  fi
}

setup_tmux() {
  confirm_dir "$HOME/.config/tmux/plugins"
  if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
  fi
  if [ ! -f "$HOME/.config/tmux/plugins/tmux-which-key/plugin.sh.tmux" ]; then
    run env TMUX_PLUGIN_MANAGER_PATH="$HOME/.config/tmux/plugins/" "$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
  fi
  confirm_dir "$HOME/.config/tmux/plugins/tmux-which-key"
  link "$DOTFILES/tmux/which-key.yaml" "$HOME/.config/tmux/plugins/tmux-which-key/config.yaml"
  if command -v python3 >/dev/null 2>&1 && [ -f "$HOME/.config/tmux/plugins/tmux-which-key/plugin/build.py" ]; then
    run python3 "$HOME/.config/tmux/plugins/tmux-which-key/plugin/build.py" \
      "$HOME/.config/tmux/plugins/tmux-which-key/config.yaml" \
      "$HOME/.config/tmux/plugins/tmux-which-key/plugin/init.tmux"
  fi
  command -v workmux >/dev/null 2>&1 && run workmux setup
  if tmux info >/dev/null 2>&1; then
    run tmux source-file "$HOME/.config/tmux/tmux.conf"
  fi
}

setup_dx() {
  confirm_dir "$HOME/.claude/skills/dx"
  confirm_dir "$HOME/.codex/skills/dx"
  link "$DOTFILES/skills/dx/SKILL.md" "$HOME/.claude/skills/dx/SKILL.md"
  link "$DOTFILES/skills/dx/SKILL.md" "$HOME/.codex/skills/dx/SKILL.md"
  confirm_dir "$HOME/Library/LaunchAgents"
  if is_macos; then
    if [ "$DRY_RUN" = "1" ]; then
      log "would render launchagents/dev.osmar.dx-refresh.plist.j2 -> ~/Library/LaunchAgents"
    else
      sed "s#{{ home_dir }}#$HOME#g" "$DOTFILES/launchagents/dev.osmar.dx-refresh.plist.j2" \
        > "$HOME/Library/LaunchAgents/dev.osmar.dx-refresh.plist"
      launchctl bootout "gui/$(id -u)/dev.osmar.dx-refresh" 2>/dev/null || true
      launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/dev.osmar.dx-refresh.plist" 2>/dev/null || true
    fi
  fi
  if [ -x "$HOME/.local/bin/dx" ] && [ ! -f "$HOME/.cache/dx/man-index.tsv" ]; then
    run "$HOME/.local/bin/dx" refresh
  fi
}

setup_clop() {
  is_macos || { log "skip: Clop (not macOS)"; return 0; }
  command -v python3 >/dev/null 2>&1 || { log "skip: Clop (no python3)"; return 0; }
  run python3 "$DOTFILES/clop/restore_clop_prefs.py" "$DOTFILES/clop/preferences.selected.plist" "$HOME"
}

setup_zed() {
  is_macos || { log "skip: Zed CLI (not macOS)"; return 0; }
  run sh "$DOTFILES/zed/install.sh"
}

setup_brew_configured
setup_apt_configured
setup_zsh
setup_asdf
setup_tmux
setup_dx
setup_clop
setup_zed

log "install-configured.sh done"
