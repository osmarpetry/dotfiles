# agents/personas

Custom Claude Code subagents — different "personalities" you can dispatch by
name, on top of the built-in `general-purpose` and `claude-code-guide` agents.

This is Claude-Code-specific. Codex has no equivalent concept, so unlike
`AGENTS.md` this folder isn't dual-purposed — it only matters to Claude Code.

`link.sh` symlinks this whole directory to `~/.claude/agents`, so a new file
dropped here is picked up without re-running setup.

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
