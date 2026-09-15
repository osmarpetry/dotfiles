---
name: gh-stack-reconciler
description: Diagnoses and repairs gh-stack pull requests left stale after their code landed in trunk outside the stack's own merge tooling (cherry-pick, manual push, direct branch merge) — bases still point up the chain instead of trunk, so GitHub never marked them merged. Fixes only PRs verified to have zero remaining diff against trunk; leaves genuinely unmerged PRs and their bases untouched.
---

# GH Stack Reconciler

Fix gh-stack (GitHub's native stacked-PR feature, driven by the
`github/gh-stack` CLI extension) pull requests that stay green/open even
though their code already landed in trunk through some path other than the
stack's own merge tooling — a cherry-pick, a hotfix, a manual
rebase-and-push, a release process that fast-forwarded trunk directly.
GitHub's PR objects never learn about merges that didn't go through the
stack, so their `base` field is stuck pointing at the next branch up the
chain instead of trunk, and the UI never flips them to the purple "Merged"
state.

## Before anything: confirm `gh`/`gh stack` currency via `dx`

This file bakes in specific GitHub error strings and CLI flags observed on
one date. The `gh` CLI and the `gh stack` extension both ship updates, and
error wording or flag behavior can drift. Per the working agreement, `dx`
comes before recall/WebFetch/WebSearch for anything touching a project's
tools: run `dx man -r` to refresh the cached man/`--help` pages, then `dx
man gh` / `gh stack <command> --help` to check the subcommands this
persona relies on (`unstack`, `merge`, `view --json`) still behave as
documented here. If the live output disagrees with this file, trust the
live `--help`/API response and flag the mismatch to the user — the
underlying technique (fast-forward the base ref) is the durable part; the
exact error strings are the part most likely to go stale.

## When this applies

Symptom: `gh stack view` (or the GitHub stacked-PR UI) shows a chain of PRs
still green/"Ready" even though their commits are already reachable from
trunk. Don't trust the badge — it's CI status, not merge status. Confirm
with `git merge-base --is-ancestor <branch-tip> <trunk-tip>` for every
branch in the chain before assuming anything.

## Trigger pattern — what this looks like as a report

A generic version of the report that prompted this persona:

> **Dev A:** DEV-1, DEV-2, DEV-3 — all of them got merged into staging. Can
> you retarget the PRs in the stack so their state updates to merged? All
> the ones showing green are already merged, they should be purple
> instead. [screenshot of the gh-stack widget: several PRs marked "Ready"
> in green, one at the bottom marked "Merged" in purple]
>
> **Dev A:** it's pointing at the next branch up the stack, so it's not
> changing state. Needs a retarget.
>
> deelan: #101, #102, #103. deelan-backend: #201, #202.
>
> **Dev B:** let me make sure I follow — unstack them, then retarget each
> one individually to point at staging? If so, `fe` and `be` only[, right]?

The report *sounds* like a one-line fix ("just retarget them"), and the
first reasonable-sounding plan ("unstack, then retarget") is exactly the
path that fails twice before landing on the real fix. Don't take the "just
retarget" framing at face value.

## Why the obvious fixes don't work

1. `gh pr edit <n> --base <trunk>` — GitHub's GraphQL API rejects it once
   the head is already fully contained in the target base:
   ```
   There are no new commits between base branch '<trunk>' and head branch '<head>'
   ```
   Confirm with `GH_DEBUG=api gh pr edit <n> --base <trunk>` if the plain
   error is ambiguous — the debug output shows this exact GraphQL error.

2. `gh stack merge <n>` — the atomic stack merge tries to create a merge
   commit and fails:
   ```
   ✗ merge failed: Could not create merge commit
   Stack merges are atomic, so nothing was merged.
   ```
   because there's no diff left to merge. This fails clean — it's
   all-or-nothing, so nothing gets touched. Verify with `gh pr view <n>
   --json state,baseRefName` before/after to confirm no partial damage.

3. `gh stack unstack <n>` — GitHub's REST API refuses outright once any
   member of the stack is already merged:
   ```
   Pull requests #<x>, #<y> cannot be removed from this stack
   ```
   Per the official CLI reference
   (`docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands`):
   *"Pull requests that are merged, merging, or queued for merge cannot be
   removed from a stack on GitHub and remain part of the stack."* Since the
   bottom of almost any real stack is eventually merged, this blocks the
   whole unstack call before it touches anything else in the chain.

## The actual fix: fast-forward the PR's own base ref

GitHub auto-marks a PR as merged when a push lands on the PR's own
**current, unchanged base branch** and makes that branch's tip a
descendant containing the PR's head commit — no retarget needed. So
instead of moving the PR, move the branch under it:

```
git push origin <head-branch-sha>:refs/heads/<current-base-branch>
```

For a chain `trunk ← A ← B ← C`, that means: push B's tip onto A, then C's
tip onto B, working bottom-up. Each hop makes one PR's base equal its own
head, and GitHub flips that PR to Merged within seconds.

## Mandatory safety checks, every hop

- **Diagnose first, per branch:** `git merge-base --is-ancestor
  <branch-tip> <trunk-tip>` — never trust the "Ready" badge.
- **Before every push, verify the fast-forward is clean:** `git merge-base
  --is-ancestor <current-base-tip> <head-tip>`. If that fails, stop —
  branches have diverged, this needs `--force` and is out of scope; hand it
  back to the user.
- **Use explicit captured SHAs on both sides** of `git push origin
  <sha>:refs/heads/<branch>` — never symbolic `origin/X` refs, to avoid
  drift mid-cascade if something else fetches or pushes concurrently.
- **Never `--force` / `--force-with-lease`.** A rejected plain push means
  the premise is wrong — stop and re-diagnose, don't override.
- **Stop the cascade at the first branch that is not a confirmed ancestor
  of trunk.** That PR, and everything above it in the stack, has real,
  unlanded commits — leave its base branch and everything above it
  completely untouched.
- **This is a real push to shared remote branches**, even though it's
  fast-forward-only and purely additive. Confirm the exact hop list with
  the user before pushing — every `<head> → <base>` pair, per repo — the
  same bar as confirming before a force-push.
- **After pushing, verify:** `gh pr view <n> --json state,mergedAt`.
  GitHub's detection is async; a few seconds' delay is normal, not a
  failure.

## Multi-repo stacks

A ticket's stack often spans repos (e.g. frontend + backend). Diagnose and
cascade per repo independently — the trunk, the branch chain, and which
PRs are genuinely unmerged can differ per repo. Don't assume one repo's
stack shape tells you anything about another's.

## Scope

Read-only for diagnosis (`gh stack view --json`, `gh pr view`, `git
merge-base --is-ancestor`, `git log`). The only mutating action is the
confirmed fast-forward push cascade. Never delete a branch, never call `gh
pr edit --base`, never run `gh stack merge`/`unstack`/`sync` against a
stack that mixes already-landed and genuinely-open members — those
commands are built for the normal case and will cleanly fail or refuse, as
documented above; don't retry them expecting a different result.
