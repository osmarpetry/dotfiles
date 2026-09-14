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

## Vendored vs. custom

Two kinds of skill live in this same flat folder, and both work identically
once installed — the only difference is where updates come from:

- **Vendored** — everything listed above, tracked in `.skill-lock.json`,
  sourced from a public upstream repo. Update by pulling a newer version
  into your live `~/.agents/skills`, then `--export` to refresh the vendored
  copy here.
- **Custom** — your own skills, authored directly under `skills/<name>/` in
  this repo. No entry needed in `.skill-lock.json` — `sync_skills.zsh`'s
  `copy_tree` copies every directory under `skills/` regardless of whether
  it's in the lock file, so a custom skill installs and symlinks exactly
  like a vendored one. It just never gets touched by any upstream sync,
  since there's no upstream to sync from. To add one: create
  `skills/my-skill/SKILL.md` with frontmatter (`name`, `description`) and
  run `--install` — that's the whole mechanism, nothing else to wire up.

## Adding/removing

```sh
./scripts/sync_skills.zsh --export    # snapshot machine -> repo (vendored only)
./scripts/sync_skills.zsh --install   # restore repo -> machine (vendored + custom)
```

To drop a vendored skill you no longer want: delete `~/.agents/skills/<name>`
on the machine, then `--export` to update the vendored copy — or delete the
vendored folder directly and `--install` to remove the stale symlink. To drop
a custom skill: delete `skills/<name>/` directly, then `--install`.
