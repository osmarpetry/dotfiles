# Working agreement

## Before any change

- **KISS.** The simplest thing that fully solves the ask. No speculative layers.
- **TDD.** Write the failing test first, watch it fail, then make it pass. A change
  presented without a test that failed before it is not finished.
- **Never assume the next assumption — ask me.** Judgment calls inside the stated
  scope are yours. Anything that widens, narrows, or reinterprets the scope stops
  and asks. When you do assume, say so out loud in the same message.
- **DRY has limits.** It applies to pure functions and genuinely reusable
  components. Don't force a shared abstraction onto a complex component built
  for one specific need — a little duplication in a single-purpose,
  complicated piece beats a wrong abstraction that has to flex for cases that
  don't actually recur.
- **Consider a named pattern before inventing structure.** When planning a
  new task or diagnosing a bug, check whether a known pattern (Gang of Four)
  fits. Name the pattern you're using — or the one you considered and
  rejected, and why — rather than silently picking a shape.
- **Debug with a debugger, not print statements.** Prefer a real debugger
  over `console.log`/`print` when the repo has one available — breakpoints
  and step-through beat scattering print statements. Pair TDD's red/green
  cycle with debugger-driven diagnosis: the failing test tells you *what*
  broke, the debugger tells you *why*. Check `dx man <tool>` for a debugger
  CLI's actual flags before guessing, and `docs/debugging.md` for the
  per-stack workflow.

## Docs before code

Load the `dx` skill and use it before writing or reviewing code that touches Nuxt,
Vue, Nuxt UI, Vite, Pinia, Tailwind, TypeScript, Temporal, Supabase, Node, Python,
Go, uv or pnpm.

```bash
dx doctor              # what this project runs that is out of support
dx doc <slug> --path   # docs pinned to the version THIS project uses
```

Your memory of these APIs is frequently a different major version than the project.
The cache is not. `dx` comes before WebFetch, WebSearch, and recall.

## Commits

- One line, prefixed with the ticket code. Reviewable at a glance.
- **One independent feature per commit.** Each commit must be cherry-pickable on its
  own and leave the tree functional.
- If a commit of mine mixed two features, split it. If my last commits are iterations
  of the same feature, squash them. Concretely: commit A had features 1+2, commit B
  had features 1+3 → the end state is three commits, one per feature, each standalone.
- Before proposing any of this, read the actual history and diff it by author, task
  and date — do not reorganize commits from the message text alone.
- Stage only the files belonging to the commit you are making. If the working tree
  has unrelated changes already in it, say so and leave them alone.
- **Never attribute assistant co-authorship.** No `Co-Authored-By:` naming
  Claude/Anthropic, no "Generated with", no robot emoji, nothing that suggests
  an assistant wrote the commit, the PR or the description. The work ships under
  my name and only my name.
- **Everything written into a repo is en-US.** Commit messages, code comments,
  PR titles and bodies, docs, test names. Never pt-BR, even when we are talking
  in Portuguese.

## Delivery strategy

When the work outgrows a single branch, say so and propose a split before writing
code. A branch carrying too much context is a delivery problem, not a review problem.

## Style

`caveman` and KISS are the point. Short, dense, technically exact. No filler, no
restating my request back to me, no summarizing what you are about to do.

- **Never hard-wrap prose.** Every paragraph you write for me to read — chat
  replies, plan-mode text, PR/issue descriptions, comments, explanations of
  any kind — is one unbroken line, however long, with no manual line break
  mid-paragraph. A blank line between paragraphs is real structure, keep
  that. Code blocks, tables, and list items keep their own line breaks. This
  does not apply to files meant to be hand-edited in an editor — this file,
  commit messages, code comments — which keep their existing wrap
  conventions.
