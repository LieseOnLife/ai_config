# About Saje

Saje uses **she/her** pronouns. Refer to her as such in all writing, commit messages, PR descriptions, and comments.

Prefer simple, succinct explanations. Start with what changed and where; provide deeper implementation details only when asked.

**Repo context:** when working in a repo, read `~/.pi/agent/{repo}.md` if it exists (e.g. `cloud-inventory.md`, `dd-source.md`). Personal per-repo notes live there, not in the repo.

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
- **The slice plan** — the PR-stack table (`stacked-prs` skill) with rough line estimates per PR.

This overrides any "bias toward acting" default — for non-trivial work, confirming intent first IS the action. **Skip it** for trivial fixes, typos, renames, or work where Saje already gave a detailed spec. When unsure, post the scope — it's cheap.

# Zed-integrated terminal

In Zed's terminal (`ZED_TERM=true` or `TERM_PROGRAM=zed`), after implementation is complete, run the `zed-review` skill. Outside Zed, never launch Zed automatically.

# Git

## Datadog Commit Signing (HARD)
- Never use `--no-gpg-sign`, `--no-verify`, or any configuration override that bypasses signing or hooks in a Datadog repository.
- Before committing, merging, amending, cherry-picking, or rebasing, verify the effective email is `saje.liese@datadoghq.com`, commit signing is enabled, and the signing key is the Datadog key.
- Immediately after every created commit—including merge commits—run `git verify-commit` and require the fingerprint matching whichever GitHub account owns Git transport for that repo: `SHA256:b0S6/+yKXM0hqrLOZf/jJkvuwEcUIpBw2isExbmx3F0` for `saje-liese_ddog`/`ddoghq`, or `SHA256:w43nH0j9/33U01dHa1hNiKkNANjz3Te6zDYddVLS884` for `LieseOnLife`. Stop before any push if verification fails.
- For `ddoghq` Git transport, explicitly select the `GitHub · ddoghq` authentication key and disable SSH connection multiplexing; the default multiplexed connection may authenticate as the personal account.

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

**Deletion (requires explicit approval):** never run `git worktree remove`, `git branch -d/-D`, or `git push origin --delete` without asking, except for merged PRs (see the standing approval below). (A `worktree-guard` extension enforces this — prefix with `# APPROVED:` after Saje approves.)

**Standing approval: merged PR → remove its worktree and branches.** When Saje says a PR is merged, or you find it merged (`gh pr view --json state` = `MERGED`), clean up right away without asking (`# APPROVED: PR merged` prefix): run `git worktree remove` on its worktree, delete the local branch with `git branch -D`, and delete the remote branch with `git push origin --delete` if GitHub didn't auto-delete it. Run `git status --porcelain` in the worktree first. If there are uncommitted changes, stop and ask. Branches of unmerged or closed-unmerged PRs still need explicit approval.

**Subagents in worktrees:** pass the full absolute worktree path; the child `cd`s there first. Details in the `delegation` skill.

## GitHub
- Always use the `gh` CLI for github.com.
- Format every GitHub comment or review reply authored by the assistant entirely as Markdown blockquotes (`>`), and clearly label it as AI-authored (for example, `> 🤖 **AI-authored**`). Apply this by default unless Saje explicitly requests otherwise.
- PR descriptions: describe the diff between the whole PR and main/master, not commit-to-commit.
- **NEVER merge a PR** — no `gh pr merge`, no `/merge` comment, no merge queue. Saje merges when ready.

## Slack
- **No markdown tables in Slack messages or drafts.** Slack does not render them — they appear as raw pipes and dashes. Use bullets and bold instead.
- Use Slack's mrkdwn for links: `<url|display text>`, bold: `*text*`, code: `` `code` ``.

## Stacked PRs (HARD)
Break non-trivial work into small, vertically sliced stacked PRs (`saje/feature-name-pr1`, `-pr2`, …; ~200-550 lines each as a target). Every implementation plan opens with a PR-stack table; STOP after each PR group until Saje says go; flag scope drift instead of growing a PR. **NEVER `git merge main` into a child branch** — restack bottom-up. Load the `stacked-prs` skill for the table format, gates, and restack/verify procedure. **Exception:** in `cloud-inventory`, never merge `master` into any branch; restack with `git rebase --onto` (see `cloud-inventory.md`).

# Execution Momentum (HARD)

- Do not send a status-only response when an executable, in-scope next step is available. State the next action briefly and execute it in the same turn unless approval is required.
- Treat optional tooling, local hardening, and unrelated cleanup as follow-ups unless they directly block the requested delivery. Do not let them replace feature work.
- Keep investigation decision-driven: batch related reads and queries, then act. Additional investigation must name the concrete unanswered question or risk it resolves.
- After compaction, resume from the recorded critical path and next unfinished step; do not re-run completed discovery or gates without evidence that state changed.
- Put implementation-, review-, and publication-specific momentum rules in their existing skills so the rule appears where the work happens; do not duplicate the full workflow here.

# Delegation & Advisor

Before spawning or supervising subagents (omp `task` agents), load the `delegation` skill. Always-on essentials: coding → `coder`, other work → `task`, read-only → `scout`, bulk mechanical → `sonic`, Bazel → one `bzl` only (exclusive — no other subagents while it runs). Name each subagent's model when reporting. Call `advisor` at planning gates, approach forks, after two failed attempts, before blast-radius actions, and before declaring multi-step work done.

# Post-Push Protocol (MANDATORY, AUTOMATIC)

Every `git push` (including force pushes/rebases) triggers the `post-push-protocol` skill: hand the PR to the single `PrWatch` subagent (message it if running; spawn only if not), fix real failures, auto-review major diffs, handle PR comments, report back. A push hook injects a reminder; run it without being asked.
