#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
SESSION="${SESH_SESSION_NAME:-$(tmux display-message -p '#S' 2>/dev/null || printf 'deelan-full')}"
WINDOW="dev"
ROOT="/Users/osmar/workspace/deelan"
SUPABASE_DIR="$ROOT/deelan-supabase"
BACKEND_DIR="$ROOT/deelan-backend"
FRONTEND_DIR="$ROOT/deelan/deelan"
BACKEND_URL="http://localhost:8000"
SUPABASE_READY_CHANNEL="deelan-full-supabase-ready"

frontend_cmd="cd '$FRONTEND_DIR' && DEELAN_BACKEND_URL='$BACKEND_URL' pnpm dev --host 127.0.0.1 --port 3000"
temporal_cmd="cd '$BACKEND_DIR' && exec poetry run poe temporal-dev"
backend_cmd="tmux wait-for '$SUPABASE_READY_CHANNEL' && cd '$BACKEND_DIR' && exec poetry run poe dev"
worker_cmd="tmux wait-for '$SUPABASE_READY_CHANNEL' && until nc -z localhost 7233 2>/dev/null; do sleep 1; done && cd '$BACKEND_DIR' && exec poetry run poe worker"
supabase_cmd="cd '$SUPABASE_DIR' && start_supabase && npx supabase migration up --local --include-all && BACKEND_ENV_FILE='$BACKEND_DIR/.env' ./scripts/configure-local-session-worker.sh; tmux wait-for -S '$SUPABASE_READY_CHANNEL'"

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
    if tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_title}:#{pane_dead}' 2>/dev/null | grep -qx 'frontend:0'; then
      tmux set-option -g mouse on
      tmux set-option -g history-limit 50000
      exec tmux attach-session -t "$SESSION"
    fi

    printf '%s\n' 'The previous deelan-full session lost its frontend pane; recreating it...'
    tmux kill-session -t "$SESSION"
  fi

  tmux new-session -d -s "$SESSION" -n "$WINDOW" -c "$ROOT" "$SCRIPT_PATH --inside-tmux"
  exec tmux attach-session -t "$SESSION"
fi

tmux set-option -g mouse on
tmux set-option -g history-limit 50000

if tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_title}' 2>/dev/null | grep -qx 'frontend'; then
  tmux select-window -t "$SESSION:$WINDOW"
  exit 0
fi

frontend_pane="$(tmux list-panes -t "$SESSION:$WINDOW" -F '#{pane_id}' | head -1)"
supabase_pane="$(tmux split-window -t "$frontend_pane" -c "$SUPABASE_DIR" -P -F '#{pane_id}')"
temporal_pane="$(tmux split-window -t "$frontend_pane" -c "$BACKEND_DIR" -P -F '#{pane_id}')"
backend_pane="$(tmux split-window -t "$frontend_pane" -c "$BACKEND_DIR" -P -F '#{pane_id}')"
worker_pane="$(tmux split-window -t "$frontend_pane" -c "$BACKEND_DIR" -P -F '#{pane_id}')"

tmux select-pane -t "$frontend_pane" -T "frontend"
tmux select-pane -t "$supabase_pane" -T "supabase"
tmux select-pane -t "$temporal_pane" -T "temporal"
tmux select-pane -t "$backend_pane" -T "backend"
tmux select-pane -t "$worker_pane" -T "worker"

tmux select-layout -t "$SESSION:$WINDOW" tiled

# Export the retry-aware start_supabase function into the supabase pane's own
# shell so its command (built above) can call it directly.
tmux send-keys -t "$supabase_pane" "SUPABASE_DIR='$SUPABASE_DIR'; $(declare -f start_supabase); $supabase_cmd" C-m
tmux send-keys -t "$temporal_pane" "$temporal_cmd" C-m
tmux send-keys -t "$frontend_pane" "$frontend_cmd" C-m
tmux send-keys -t "$backend_pane" "$backend_cmd" C-m
tmux send-keys -t "$worker_pane" "$worker_cmd" C-m

tmux select-window -t "$SESSION:$WINDOW"
tmux select-pane -t "$frontend_pane"
