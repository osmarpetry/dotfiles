---
name: nuxt-ui-migration-reviewer
description: Review a Nuxt UI major-version migration branch for silent regressions — things that compile, lint, and typecheck clean but are visually or behaviorally wrong. Grounds every claim in the real docs/theme source via dx, not memory. Also fixes GitHub PR/issue body Markdown so it renders correctly.
---

Follow `AGENTS.md` §Style for anything written back — including the no-hard-wrap rule.

# Nuxt UI Migration Reviewer

Review a `@nuxt/ui` major-version bump (v2->v3, v3->v4, ...) for regressions that survive lint/typecheck/tests: renamed props that silently fall through to `$attrs`, `:ui` overrides pointing at slot names that no longer exist, color/variant remaps that change what a component actually looks like, `v-model` type mismatches, and damage from any bulk regex/codemod script used to do the mechanical parts. Read-only by default — report findings, fix only what's explicitly approved.

**Always use `dx doc nuxt-ui` for the pinned version first.** Read the real component docs, and when they're ambiguous, the actual installed theme source (`node_modules/@nuxt/ui/dist/shared/*.mjs`, or per-component theme files in older layouts) for the exact slot names, variant classes, and prop types. Never answer from memory — it's reliably a different major version than the project.

## Checklist

- **`:ui="{...}"` overrides** — cross-check every key against the real theme's `slots` object for that component. An unrecognized key doesn't error, it silently no-ops.
- **Renamed/removed props with no compiler error** — a v2 boolean/string prop that doesn't exist on the v3 component (e.g. `preventClose`, `inputClass`, `padded`) falls through to `$attrs` and does nothing. Diff every prop that disappeared from a component's type between versions, then grep the codebase for lingering usages.
- **`color`/`variant` remaps** — a mechanical rename (e.g. `gray`->`neutral`) can change what actually renders. Check the real theme's `variant` class strings for the target component, not just that the prop compiles — a "light secondary" color in the old version can land on a "near-black solid" default in the new one.
- **`v-model` type mismatches** — some components (e.g. `UTabs`) compare values strictly. A numeric model bound against string-keyed items can silently break visual/selected state while content still switches, so a quick click-through won't catch it.
- **Bulk-script/codemod damage** — if the migration used find/replace scripts, check for corrupted `:class` bindings, wrong insertion points, and duplicate attributes. A regex bug that hit once often recurs elsewhere in the same pass.
- **Re-derive every PR-description claim/count from the diff directly** — don't trust a number written down mid-migration; recount it.
- **Verify line-number citations against current file content before planning a fix** — findings drift as files change; don't propagate a stale line number or a false positive (e.g. a hand-rolled tab-like UI that never used the real component) into a fix plan.

## Process

Sweep across independent angles first (parallel agents, one narrow category each — the checklist above is a good starting split). Then run one adversarial verification pass over the sweep's findings: try to refute each one, and separately hunt for defect classes nobody was specifically told to look for. Report findings; don't auto-fix without the user's go-ahead on scope — especially anything that's a design decision rather than a bug (see below).

**Scope judgment**: a uniform, library-wide default change that hits many sites identically (e.g. v2 and v3 using different size scales for the same `size="xs"` value, showing up everywhere that prop is used) is a design-token decision, not a bug to silently patch. Flag it for the design team instead of guessing new pixel values or overriding the theme globally without buy-in.

## PR description hygiene

The no-hard-wrap rule (`AGENTS.md` §Style) explicitly covers PR/issue bodies — GitHub's renderer treats a single `\n` as a hard `<br>`, unlike a repo `.md` file's normal CommonMark soft-wrap, so 80-column-wrapped prose renders as jagged fragmented lines instead of flowing paragraphs. Before considering a PR description done, check it isn't wrapped: `gh pr view <N> --json body -q .body | awk '{print length}' | sort -rn | head -1` — a max line length near the terminal wrap width (~80) is the tell. Compare against an already-correct PR in the same repo if unsure.
