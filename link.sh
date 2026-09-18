#!/usr/bin/env sh
# Symlinks every managed config into place. Safe to re-run: link() in lib.sh
# is idempotent and only touches a target that isn't already the right link.
set -eu

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
. "$DOTFILES/lib.sh"

link_agents() {
  confirm_dir "$HOME/.claude"
  confirm_dir "$HOME/.codex"
  link "$DOTFILES/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  link "$DOTFILES/AGENTS.md" "$HOME/.codex/AGENTS.md"
  link "$DOTFILES/agents/personas" "$HOME/.claude/agents"
}

link_skills() {
  confirm_dir "$HOME/.claude/skills"
  for skill in "$DOTFILES"/skills/*/; do
    name="$(basename "$skill")"
    link "${skill%/}" "$HOME/.claude/skills/$name"
  done
}

link_ssh() {
  confirm_dir "$HOME/.ssh"
  # ssh/config Includes this; it must exist even empty or Include errors out.
  [ -f "$DOTFILES/local/ssh-config" ] || { [ "$DRY_RUN" = "1" ] || : > "$DOTFILES/local/ssh-config"; }
  link "$DOTFILES/ssh/config" "$HOME/.ssh/config"
  link "$DOTFILES/ssh/allowed_signers" "$HOME/.ssh/allowed_signers"
  link "$DOTFILES/ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
}

link_git() {
  link "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
}

link_tmux() {
  confirm_dir "$HOME/.config/tmux"
  link "$DOTFILES/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
  link "$DOTFILES/tmux/cheatsheet.md" "$HOME/.config/tmux/cheatsheet.md"
}

link_sesh() {
  link "$DOTFILES/sesh" "$HOME/.config/sesh"
}

link_nvim() {
  confirm_dir "$HOME/.config/nvim/lua/config"
  confirm_dir "$HOME/.config/nvim/lua/plugins"
  for f in "$DOTFILES"/nvim/lua/config/*.lua; do
    [ -e "$f" ] || continue
    link "$f" "$HOME/.config/nvim/lua/config/$(basename "$f")"
  done
  for f in "$DOTFILES"/nvim/lua/plugins/*.lua; do
    [ -e "$f" ] || continue
    link "$f" "$HOME/.config/nvim/lua/plugins/$(basename "$f")"
  done
}

link_zsh() {
  line='[ -f "$HOME/dotfiles/zsh/my-zsh.sh" ] && source "$HOME/dotfiles/zsh/my-zsh.sh"'
  if [ "$DRY_RUN" = "1" ]; then
    grep -qF "$line" "$HOME/.zshrc" 2>/dev/null || log "would add my-zsh.sh source line to ~/.zshrc"
  else
    touch "$HOME/.zshrc"
    grep -qF "$line" "$HOME/.zshrc" || printf '%s\n' "$line" >> "$HOME/.zshrc"
  fi

  dxline='[ -f "$HOME/.config/dx/dx.zsh" ] && source "$HOME/.config/dx/dx.zsh"'
  if [ "$DRY_RUN" = "1" ]; then
    grep -qF "$dxline" "$HOME/.zshrc" 2>/dev/null || log "would add dx.zsh source line to ~/.zshrc"
  else
    grep -qF "$dxline" "$HOME/.zshrc" || printf '%s\n' "$dxline" >> "$HOME/.zshrc"
  fi
}

link_dx() {
  confirm_dir "$HOME/.local/bin"
  confirm_dir "$HOME/.local/share/dx"
  confirm_dir "$HOME/.config/dx"
  link "$DOTFILES/dx/dx" "$HOME/.local/bin/dx"
  link "$DOTFILES/dx/core.zsh" "$HOME/.local/share/dx/core.zsh"
  link "$DOTFILES/dx/registry.tsv" "$HOME/.local/share/dx/registry.tsv"
  link "$DOTFILES/dx/dx.zsh" "$HOME/.config/dx/dx.zsh"
}

link_bin() {
  confirm_dir "$HOME/.local/bin"
  link "$DOTFILES/bin/toss" "$HOME/.local/bin/toss"
  link "$DOTFILES/bin/wm-add" "$HOME/.local/bin/wm-add"
  link "$DOTFILES/bin/wm-switch" "$HOME/.local/bin/wm-switch"
  link "$DOTFILES/bin/wm-remove" "$HOME/.local/bin/wm-remove"
  link "$DOTFILES/bin/wm-sync" "$HOME/.local/bin/wm-sync"
  link "$DOTFILES/scripts/clone_repos.zsh" "$HOME/.local/bin/clone-workspace-repos"
}

link_macos_only() {
  is_macos || { log "skip: aerospace/hammerspoon config (not macOS)"; return 0; }
  link "$DOTFILES/aerospace/aerospace.toml" "$HOME/.aerospace.toml"
  confirm_dir "$HOME/.hammerspoon"
  link "$DOTFILES/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
  link "$DOTFILES/hammerspoon/mic-pin.lua" "$HOME/.hammerspoon/mic-pin.lua"
  link "$DOTFILES/hammerspoon/meeting-reminder.lua" "$HOME/.hammerspoon/meeting-reminder.lua"
}

link_agents
link_skills
link_ssh
link_git
link_tmux
link_sesh
link_nvim
link_zsh
link_dx
link_bin
link_macos_only

log "link.sh done"
