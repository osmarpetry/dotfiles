# Debugging

Prefer a real debugger over `console.log`/`print`. Pair TDD's red/green
cycle with debugger-driven diagnosis: the failing test tells you *what*
broke, stepping through tells you *why*. Scoped to the stacks actually in
use here (Temporal, Python, Vue) and the editor in use (Zed) — not a
generic survey. This is a v1 starting point, meant to be corrected against
real debugging sessions, not treated as final.

## Temporal (workflows/activities)

- `temporal server start-dev` — local dev server, no external dependency.
- The Temporal Web UI (served by the dev server) — inspect an execution's
  full event history instead of guessing from logs. This is usually faster
  than adding logging and re-running.
- `temporal workflow show` — a specific execution's history from the CLI,
  for scripting/piping.
- Replay-test patterns and more detail: the vendored `temporal-developer`
  and `temporal-cloud` skills already cover this — load one of those rather
  than duplicating guidance here.

## Python

- `debugpy` + Zed's native debugger (Zed has a Debugger panel with DAP
  support) — set breakpoints directly in Zed, attach via a per-project
  `.zed/debug.json` targeting the `debugpy` adapter.
  - **Open item**: the exact current `debug.json` schema/adapter name for
    Python on this machine's Zed version hasn't been verified — check Zed's
    own docs/settings the first time this is actually needed, don't copy a
    schema from here without confirming it against the installed version.
- Fallback when no debug config exists yet: `pdb` / `breakpoint()`.

## Vue

Correcting a likely assumption before it causes confusion: Vue apps run
client-side in a browser, so **Zed does not debug them directly**. The right
tools are the browser's own DevTools (breakpoints in the Sources panel,
working through source maps) plus the Vue DevTools browser extension for
component/state inspection. Zed's debugger is relevant for any Node-side
code in a Nuxt/Vue project (SSR, API routes) — not the client-rendered
component tree itself.

## General

`dx man <tool>` first for any debugger CLI's actual flags — man page or
cached `--help`, same dx-before-memory rule as everything else in this repo.
