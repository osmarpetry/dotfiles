# agents/personas

Custom Claude Code subagents — different "personalities" you can dispatch by
name, on top of the built-in `general-purpose` and `claude-code-guide` agents.

This is Claude-Code-specific. Codex has no equivalent concept, so unlike
`AGENTS.md` this folder isn't dual-purposed — it only matters to Claude Code.

`link.sh` symlinks this whole directory to `~/.claude/agents`, so a new file
dropped here is picked up without re-running setup.

## Invoking a persona

Claude Code's Task/Agent tool picks a subagent by matching `subagent_type`
against a persona file's frontmatter `name:` — the filename doesn't matter,
the `name:` field does. Current personas:

| `name:` | For |
|---|---|
| `verifier` | Evidence-first double-checking — reproduce a claim, verify a fix, adversarial review. Default: read-only. |
| `maintainer` | Judgment calls — should this feature exist, is a PR correctly scoped, what to do about automated review noise. |
| `issue-auditor` | Read-only: is a reported issue still valid against current code, find related PRs. |
| `pr-auditor` | Read-only on GitHub/the tracker (does check branches out locally): prioritize open PRs across repos, assemble and check out a ticket's full cross-repo branch set, or deep-review one PR against its linked ticket. |
| `gh-stack-reconciler` | Read-only diagnosis, confirmed fast-forward pushes: fixes gh-stack PRs stuck open because their code landed in trunk outside the stack's own merge tooling. |
| `nuxt-ui-migration-reviewer` | Review a Nuxt UI major-version migration for silent regressions (renamed props, `:ui` slot drift, color/variant remaps, `v-model` mismatches), grounded in `dx doc nuxt-ui` and the installed theme source. Also fixes GitHub PR body Markdown (hard-wrap vs. GitHub's line-break rendering). |
| `local-stack-runner` | Set up or extend a project's local multi-service dev stack as a sesh+tmux launcher — reuses existing launch mechanisms before inventing new ones, sequences dependent services with `tmux wait-for`/port polling, checks for tmux session-name collisions first, never bakes a branch sync into the reusable script. |

### `pr-auditor` walkthrough — a full-stack project

Generic, not tied to any one org/tracker — first use in a workspace asks
what to configure. Worked example (real, tested against
`~/workspace/deelan/`, three sibling repos — frontend, backend, Supabase):

```sh
# first time in a new workspace — teach it what this project looks like
cd ~/workspace/deelan
dx pr init --tracker youtrack --org Deelan-AI \
  --repos deelan,deelan-backend,deelan-supabase \
  --ticket-pattern '[A-Z]+-[0-9]+'

# find every open PR/branch across repos for one ticket
dx pr stack DEV-580

# per PR: ticket + comments + related tickets + PR body + review comments
dx pr context Deelan-AI/deelan#958
```

Ask Claude Code to "use the pr-auditor agent" (or just describe the task —
"help me review DEV-580 across the deelan repos") and it takes it from
there: runs the commands above, checks the resulting branches out locally
(git worktrees, reusing one if it already exists, asking before forcing an
update on anything dirty), reads each PR's diff with a QA-style eye, and
drafts a PR description / test plan / "what the tracker says" summary. It
stops there — running the stack and the real code review stay yours. Full
behavior spec: `pr-auditor.md`.

## Adding a persona

One file per persona, frontmatter + system prompt body:

```markdown
---
name: terse-reviewer
description: Use for a quick, blunt code review pass before opening a PR.
---

You review code. Say what's wrong and where. No praise, no summary of what
the code does, no "great job" — just the defects, one line each, file:line.
```

`example-persona.md` is a minimal starter — duplicate it, don't keep it as-is.

Per `docs/PLAN.md`'s framing: agents carry judgment, skills carry procedure.
If what you're writing is a repeatable operational runbook, it belongs in
`skills/` instead.
