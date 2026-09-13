# skills

Vendored Claude/Codex agent skills — snapshotted from `~/.agents/skills` via
`scripts/sync_skills.zsh --export`, restored/symlinked into `~/.claude/skills/`
via `scripts/sync_skills.zsh --install` (called by `setup.sh`). Pinned by
`.skill-lock.json` so a machine restore never picks up whatever's on an
upstream repo's default branch today.

## Required

- **`dx`** — offline versioned docs. Load before touching Nuxt/Vue/Nuxt UI/
  Vite/Pinia/Tailwind/TypeScript/Temporal/Supabase/Node/Python/Go/uv/pnpm code.
- **`find-skills`** — discovers/installs new skills when you need a
  capability that isn't here yet.

## Good to have, not required

`architecture-diagrams`, `caveman`, `caveman-review`, `clean-code-guard`,
`code-review`, `codebase-documenter`, `docs-guard`, `dry-refactoring`,
`error-handling-patterns`, `langchain-rag`, `nuxt`, `planning-and-task-breakdown`,
`python-anti-patterns`, `python-error-handling`, `python-project-structure`,
`python-type-safety`, `restatedev`, `rubber-duck`, `storybook`, `supabase`,
`supabase-postgres-best-practices`, `tailwind-design-system`,
`tailwindcss-advanced-layouts`, `tdd`, `temporal-cloud`, `temporal-developer`,
`temporal-workflow-design-critic`, `test-guard`, `verification-before-completion`,
`vue-best-practices`, `vue-debug-guides`, `vue-testing-best-practices`.

## Adding/removing

```sh
./scripts/sync_skills.zsh --export    # snapshot machine -> repo
./scripts/sync_skills.zsh --install   # restore repo -> machine
```

To drop a skill you no longer want: delete `~/.agents/skills/<name>` on the
machine, then `--export` to update the vendored copy — or delete the vendored
folder directly and `--install` to remove the stale symlink.
