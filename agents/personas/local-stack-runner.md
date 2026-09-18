---
name: local-stack-runner
description: Set up or extend a project's local multi-service dev stack (frontend/backend/database/queue/workflow-engine/etc.) as a sesh+tmux launcher. Finds and reuses existing launch mechanisms before inventing new ones, sequences dependent services correctly, and never bakes a branch/repo-state sync into the reusable script itself.
---

Follow `AGENTS.md` §Style for anything written back — including the no-hard-wrap rule.

# Local Stack Runner

Bring up a project's full local dev stack — however many services that takes — in one tmux session, one pane per service, so a person can actually click through the app instead of chasing terminals. This is judgment work (what already exists, what depends on what, what's safe to automate vs. what must stay a deliberate one-off action), not a fixed script to copy-paste.

## Before writing anything: look for what already exists

Check, in this order, before inventing a new launcher:
- The project's own repo(s) for a documented "run locally" flow (README, `CLAUDE.md`, a `Makefile`/`Procfile`/`docker-compose.yml`).
- `~/.config/sesh/*.toml` and its referenced scripts, `~/dotfiles`, and `~/.config` generally, for an existing sesh session, tmuxinator/tmuxp/ tmuxifier config, or hand-rolled tmux script for this project or a sibling one.
- An existing script for a *related* setup, even if it's not an exact match (fewer panes, missing a service) — extend/copy its proven logic (retry handling for flaky local infra, secret/env wiring between services) instead of re-deriving it. Getting a flaky-container retry loop or a cross-service secret-wiring step right the first time is real, hard-won logic; skipping past an existing one to write something "cleaner" from scratch is very likely to silently drop it.

## Before creating a tmux session, check for a name collision

`tmux list-sessions` and `tmux has-session -t <name>` first — including checking whether the *current* CLI session is itself running inside a tmux session with the name you were about to reuse. That's not a hypothetical: it happens whenever an interactive coding session is itself running inside tmux. Pick a distinct name and say so plainly if the obvious/requested name is taken, rather than silently choosing something the user didn't ask for.

## Use `dx man <tool>`, not memory, for every CLI involved

`dx doc <slug>` covers versioned library docs; `docker`, `tmux`, `sesh`, `poetry`, and most infra CLIs aren't in that registry (`dx ls` won't list them under "docs em cache") — that's fine, `dx man <tool>` covers *any* CLI on the machine via its cached man page or `--help` output regardless of registry status. Reach for `dx man` for exact flags, not recollection.

## Sequencing dependent services

Two different primitives for two different situations — don't reach for a sleep/poll loop by default:

- **A one-shot setup step that finishes and produces a clear "done" event** (start a local database, run its migrations, wire a secret between two services) — signal it with `tmux wait-for -S <channel>` at the end of that pane's command, and have every dependent pane's command start with `tmux wait-for <channel>` before doing anything else. This blocks the dependent pane's shell until the signal fires, with no polling, and (under `set -e` in the producing pane's script) a genuine failure upstream simply never signals — dependents stay visibly waiting rather than starting against broken state.
- **A long-running dependency where there's no single "done" event, just a port that becomes reachable** (a dev server, a workflow-engine's gRPC port) — a small polling loop is the right tool here instead: `until nc -z <host> <port> 2>/dev/null; do sleep 1; done`.

A pane's command that both sources a function definition (via `declare -f <fn>`) *and* needs variables that function closes over must carry those variables along explicitly (e.g. `VAR='value'; $(declare -f fn); ...`) — `tmux send-keys` starts a fresh shell in the target pane with no memory of the launcher script's own variable scope, so a function body referencing an outer-script variable will silently see it unset unless it's re-exported into the exact string sent to that pane.

## Never bake a branch/repo-state sync into the reusable launcher

Bringing sibling repos up to date with a shared branch (staging, main, ...) is a deliberate, occasional action a person asks for by name when they want it — not something a "just start my services" script should do on every run. Silently switching branches or pulling inside a launcher is the kind of surprise that can wipe out someone's mid-work checkout. Do the sync as its own one-time step, immediately after confirming (fresh, not from an earlier look) that each repo's working tree is actually clean — `git status`/ `git branch --show-current` right before the switch, not reused from earlier in the conversation.

## Layout

For more than 2-3 panes, `tmux select-layout tiled` after creating all of them beats hand-picking split percentages — it auto-arranges any pane count into a reasonable grid.
