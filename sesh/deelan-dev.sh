#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
SESSION="${SESH_SESSION_NAME:-$(tmux display-message -p '#S' 2>/dev/null || printf 'deelan-dev')}"
WINDOW="dev"
ROOT="/Users/osmar/workspace/deelan"
SUPABASE_DIR="$ROOT/deelan-supabase"
BACKEND_DIR="$ROOT/deelan-backend"
FRONTEND_DIR="$ROOT/deelan/deelan"
CLAAP_WEBHOOK_BASE_URL="https://uncaring-bagel-stimulus.ngrok-free.dev"
BACKEND_URL="http://localhost:8000"
NGROK_URL="https://uncaring-bagel-stimulus.ngrok-free.dev"

frontend_cmd="cd '$FRONTEND_DIR' && CLAAP_WEBHOOK_BASE_URL='$CLAAP_WEBHOOK_BASE_URL' DEELAN_BACKEND_URL='$BACKEND_URL' pnpm dev --host 127.0.0.1 --port 3000"
ngrok_cmd="ngrok http 3000 --url '$NGROK_URL'"

start_supabase() {
  local start_output

  if start_output="$(cd "$SUPABASE_DIR" && npx supabase start 2>&1)"; then
    printf '%s\n' "$start_output"
    return 0
  fi

  printf '%s\n' "$start_output" >&2

  if [[ "$start_output" != *"container is not running: exited"* ]]; then
    return 1
  fi

  printf '%s\n' 'Supabase has stopped containers; restarting the local stack while preserving volumes...'
  (
    cd "$SUPABASE_DIR"
    npx supabase stop
    npx supabase start
  )
}

if [[ -z "${TMUX:-}" && "${1:-}" != "--inside-tmux" ]]; then
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    if tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_title}:#{pane_dead}' 2>/dev/null | grep -qx 'backend:0'; then
      start_supabase
      tmux set-option -g mouse on
      tmux set-option -g history-limit 50000
      exec tmux attach-session -t "$SESSION"
    fi

    printf '%s\n' 'The previous development session lost its backend pane; recreating it...'
    tmux kill-session -t "$SESSION"
  fi

  tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$ROOT" "$SCRIPT_PATH --inside-tmux"
  exec tmux attach-session -t "$SESSION"
fi

tmux set-option -g mouse on
tmux set-option -g history-limit 50000

if tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_title}' 2>/dev/null | grep -qx 'backend'; then
  tmux select-window -t "$SESSION:$WINDOW"
  exit 0
fi

tmux rename-window -t "$SESSION:0" "$WINDOW"

backend_pane="$(tmux display-message -p -t "$SESSION:$WINDOW.0" '#{pane_id}')"
ngrok_pane="$(tmux split-window -t "$backend_pane" -v -p 33 -c "$ROOT" -P -F '#{pane_id}')"
frontend_pane="$(tmux split-window -t "$backend_pane" -h -p 50 -c "$FRONTEND_DIR" -P -F '#{pane_id}')"

tmux select-pane -t "$backend_pane" -T "backend"
tmux select-pane -t "$frontend_pane" -T "frontend"
tmux select-pane -t "$ngrok_pane" -T "ngrok"

tmux send-keys -t "$frontend_pane" "$frontend_cmd" C-m
tmux send-keys -t "$ngrok_pane" "$ngrok_cmd" C-m

tmux select-window -t "$SESSION:$WINDOW"
tmux select-pane -t "$backend_pane"
printf 'Starting backend after Supabase is up and local migrations are applied...\n'
start_supabase
cd "$SUPABASE_DIR"
npx supabase migration up --local --include-all
BACKEND_ENV_FILE="$BACKEND_DIR/.env" "$SUPABASE_DIR/scripts/configure-local-session-worker.sh"
cd "$BACKEND_DIR"
exec poetry run poe dev
