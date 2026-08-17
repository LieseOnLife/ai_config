# Shell aliases (zsh, from `~/.zsh_aliases`)

Base UNIX commands are aliased to modern replacements. Commands you write for Saje to run (suggestions, code blocks, `! ...`) execute the *aliased* version — so reach for the unaliased form whenever alias behavior would break things (piping, scripting, output parsing). For interactive use the alias is fine.

| Alias | Unaliased form & when to use it |
|---|---|
| `rm` → `rip` | `rrm` for real `rm`. `rip` moves to a graveyard; `rip -rf` is wrong — use `rrm -rf` or `rmd`. |
| `grep` → `rg` | `ggrep` — only if you need POSIX behavior or `-P` PCRE. |
| `cat` → `bat` | `ccat` — for piping, heredocs, redirection, or anywhere ANSI escapes break the next command. |
| `cd` → `z` (zoxide) | `ccd` — when the target hasn't been visited yet. |
| `ls` → `lsd` | `lls` — when parsing output with `awk`/`cut`. |
| `top` → `btm` | `ttop`. |

# Intent Lock (before non-trivial work)

**Before writing code for anything beyond a trivial/obvious fix, post a short scope and wait for Saje's thumbs-up** — this catches intent drift at minute 1 instead of at PR review:
- **What I think you want** — 2-5 bullets restating the goal in my words.
- **The slice plan** — the PR-stack table (see Stacked PRs) with rough line estimates per PR.

This overrides any "bias toward acting" default — for non-trivial work, confirming intent first IS the action. **Skip it** for trivial fixes, typos, renames, or work where Saje already gave a detailed spec. When unsure, post the scope — it's cheap.

# Git

## Branching with Worktrees
**All development happens in a worktree — never commit on `main`/`master`. Create a worktree + branch before any implementation.** Always use `git worktree`, never `git switch`/`checkout`/`branch`.

```bash
REPO=$(basename $(pwd))
git worktree add ../${REPO}-worktrees/feature-name -b saje/feature-name   # new branch
git worktree add ../${REPO}-worktrees/feature-name saje/feature-name       # existing branch
```
- Branches are prefixed `saje/`; the worktree folder uses the bare feature name (no `saje/`, to avoid nesting).
- Location: a sibling `{repo}-worktrees/` dir — e.g. `/Users/saje.liese/go/src/github.com/DataDog/cloud-inventory-worktrees/feature-name`.

**Conflicts:** if the worktree/branch already exists, **don't delete it** — increment instead (`saje/feature-v2`, `-v3`, …).

**Deletion (requires explicit approval):** never run `git worktree remove`, `git branch -d/-D`, or `git push origin --delete` without asking. (A `worktree-guard` extension enforces this — prefix with `# APPROVED:` after Saje approves.)

**Subagents in worktrees:**
- Pass the full absolute worktree path in the prompt; the subagent must `cd` there first and use absolute paths for all file ops.
- Get worktree context via `~/.pi/agent/scripts/worktree-context.sh` (returns `worktree_path`, `main_repo`, `branch`, `is_worktree`).
- See the `/worktree-subagent` prompt template for the standard prompt format.

## GitHub
- Always use the `gh` CLI for github.com.
- When working in a repo, also load `{repo}.md` from `~/.pi/agent` (project context).
- PR descriptions: describe the diff between the whole PR and main/master, not commit-to-commit.
- **NEVER merge a PR** — no `gh pr merge`, no `/merge` comment, no merge queue. Saje merges when ready.

## Slack
- **No markdown tables in Slack messages or drafts.** Slack does not render them — they appear as raw pipes and dashes. Use bullets and bold instead.
- Use Slack's mrkdwn for links: `<url|display text>`, bold: `*text*`, code: `` `code` ``.

## Stacked PRs
When scoping or planning any project/feature, break the work into small stacked PRs by default:
- Each PR has one clear, independently reviewable purpose — a coherent unit of value, not just "a layer".
- **Slice vertically, not horizontally.** Each PR delivers one behavior end-to-end (model + handler + test for one capability), NOT "all the models" then "all the handlers". Vertical slices are independently reviewable and reveal intent.
- Target ~200-400 lines of diff per PR; smaller is better. PRs build in sequence; each merges independently once its parent lands.
- Branches: `saje/feature-name-pr1`, `-pr2`, etc.

**Plan-time gate (HARD — no code without it):** every implementation plan MUST open with a PR-stack table. Group tasks by PR boundary and end each group with an explicit "Open PR" step. **If any PR row estimates >400 lines, split it before writing code.** (A `pr-size-guard` extension warns on `gh pr create` over 400 lines / 10 files.)

| PR | Purpose (one behavior) | Est. diff | Depends on |
|----|------------------------|-----------|------------|
| pr1 | ... | ~250 lines | — |

**Execution-time gate:** when you finish a PR group, **STOP** — open the PR (use the `/skill:create-pr` skill) and don't start the next group until Saje says go.

**Scope-drift flag:** if you need to touch files outside the agreed slice, STOP and flag it ("needs files X/Y outside the slice — expand scope, or follow-up PR?") instead of silently growing the PR.

**Keeping a stack in sync when `main` moves (HARD — this has burned us):**
- **NEVER `git merge main` (or `origin/main`) into a child branch of a stack.** Merging `main` independently into two stacked branches makes them diverge — their merge-base regresses into `main`, so the child PR's diff balloons with dozens of unrelated commits/files and DDCI task-sourcing breaks.
- **Update a stack from the bottom up:** merge latest `main` into the *base* branch (pr1) only, then cascade **parent → child** merges up the stack (`merge pr1 into pr2`, then `merge pr2 into pr3`, …). Each child gets `main` transitively through its parent, so all branches share one `main` baseline.
- **Verify after any restack — do NOT trust `git diff --stat` counts alone.** For every parent→child pair run:
  ```bash
  git merge-base --is-ancestor origin/saje/<parent> origin/saje/<child> && echo CLEAN || echo DIVERGED
  git diff --name-only origin/saje/<parent>...origin/saje/<child>   # must show ONLY the child's real files
  ```
  If the 3-dot diff lists files from other domains/teams, the stack is tangled — stop and restack, don't push.
- **Audit the file list, not just the number.** An unexpected file from another team (e.g. `domains/apm/...` in a `domains/compute` PR) is the tell-tale sign of a tangled base.

# Advisor Checkpoints

Call an advisor subagent (fresh-context read-only reviewer) in these circumstances — add new entries as patterns emerge:

| Circumstance | When exactly |
|---|---|
| **Planning gate** | After self-reviewing a brainstorming spec or writing-plans plan, before presenting it to me |
| **Approach fork** | When choosing between two non-trivial implementation strategies — before committing |
| **Stuck** | After two failed attempts at the same problem |
| **Blast radius** | Before any action affecting shared infrastructure, published branches, or external services |
| **Task complete** | Before declaring a multi-step task done (write the deliverable first, then call advisor) |

# Post-Push Protocol (MANDATORY, AUTOMATIC)

**A `git push` is not "done" — it triggers this protocol, which you run automatically every time** (including force pushes and rebases). A `post-push` extension re-injects it on every push so it can't be forgotten. Don't declare a task complete while any step is outstanding.

1. **Watch CI.** Never claim CI will pass. Resolve the PR (`gh pr view --json url -q .url`) and run `gh pr checks <url> --watch` until every check completes. Don't switch tasks or report "done" while checks run.
   - **`devflow/mergegate` on dd-source PRs requires a human approval** — it will sit `pending`/`in_progress` indefinitely (observed 5.5+ hrs) purely waiting on that, not because it's hung. If it's the *only* non-passing check, report it as "awaiting approval," not "stuck" — don't recommend a retrigger/empty-commit push for it specifically.

2. **Triage failures before escalating:**
   - *Flaky/infra* (timeout, network, dead runner, known-flaky test): re-run the failed job **once** (`gh run rerun <run-id> --failed`). Passes → note it, continue. Fails the same way → treat as real.
   - *Real failure* (your change broke it): fix immediately and push the fix (re-triggers this protocol). Don't hand a fixable failure back to Saje.
   - *Ambiguous / needs Saje's call*: bring it to Saje with the check name, log excerpt, and a recommendation.

3. **Auto-review your diff (major changes only** — new PR or ~50+ lines of real logic; skip typos/renames). Run a `reviewer` subagent (pi-subagents) on the diff; for security-sensitive code (auth, secrets, IAM, infra/access) run a second `reviewer` with a security brief. Auto-fix obvious/safe issues and push; surface design-tradeoff findings to Saje with file:line and a recommendation.

4. **Address PR comments** (run the `/review-pr-comments` process unprompted):
   - *Bots* (codex, sonarcloud, codecov, github-actions, `*[bot]`): respond **definitively** — fix + reply, or reply why it's not applicable. Never leave an open question in a PR comment.
   - *Humans*: do NOT auto-reply. Surface to Saje with the link, summary, recommendation, and a draft reply for approval.

5. **Report back** in-session: what CI did (incl. re-runs), auto-review findings (fixed vs. needs-decision), comments handled, and anything needing Saje's attention. Bring issues proactively — he shouldn't have to ask "what's the status."

# Execution Style
- Maximize parallelism — use subagents, background agents, and parallel tool calls whenever possible.
- Prefer launching multiple independent agents in one message over sequential execution.
