# Working agreement

## Before any change

- **KISS.** The simplest thing that fully solves the ask. No speculative layers.
- **TDD.** Write the failing test first, watch it fail, then make it pass. A change
  presented without a test that failed before it is not finished.
- **Never assume the next assumption — ask me.** Judgment calls inside the stated
  scope are yours. Anything that widens, narrows, or reinterprets the scope stops
  and asks. When you do assume, say so out loud in the same message.

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
