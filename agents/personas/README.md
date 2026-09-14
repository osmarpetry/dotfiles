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
| `pr-auditor` | Read-only: prioritize open PRs across repos, or deep-review one PR against its linked YouTrack ticket. See `skills/dx/SKILL.md`'s "Revisão de PR" section for the underlying `dx pr` commands. |

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
