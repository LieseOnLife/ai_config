---
name: iterative-pr-review
description: Use when dispatching subagents to review PRs, reviewing code before human review, or running any fix-then-review loop. Triggers on "review the PRs", "run a code review", "fix and re-review", or any request to check code quality with subagents.
---

# Iterative PR Review

## Core Principle

Each review round should find fewer issues than the last. If it doesn't, the process is wrong — not the code.

## The Loop

```
code-review (all PRs, parallel) → batch-fix BLOCKING+IMPORTANT → targeted diff review → repeat until clean
```

## Step 1: First pass — use `code-review`

**REQUIRED SUB-SKILL:** Use `code-review` (not raw subagents) for every review pass.

`code-review` runs 7 parallel finder angles + a verification step. It catches things a single broad-sweep reviewer misses (cross-file callers, removed behaviors, reuse opportunities). Never dispatch a "fresh eyes no context" subagent when `code-review` is available.

For stacked PRs, run `code-review` in each worktree against the relevant diff:
```bash
cd <worktree>
git diff origin/<base-branch>...HEAD
# code-review runs on this diff automatically
```

Run all PRs in parallel — one agent per PR.

## Step 2: Subsequent passes — targeted diff only

After the first fix batch, **only review what changed** since the last clean SHA:
```bash
git diff <last-clean-sha>...HEAD -- <changed files only>
```

BLOCKING issues only. If none, LGTM. Never re-review unchanged code.

## Step 3: Fix discipline

Every fix agent must:
1. Read the file before editing
2. **Grep for all instances of the bug pattern** before fixing any — fix the class, not one instance
3. Run build + tests before committing
4. One logical commit per bug class

## Convergence

| Round | Action |
|---|---|
| 1 | `code-review` all PRs → fix all BLOCKING + IMPORTANT in one batch |
| 2 | `code-review --diff-only` → fix BLOCKING only |
| 3+ | LGTM or one final targeted pass |

If round 4+ still has many findings: **stop and diagnose** before continuing. The fix agents are introducing regressions, or there's a systemic design issue.

## Common Mistakes

| Mistake | Fix |
|---|---|
| "Fresh eyes" subagent instead of `code-review` | Always use `code-review` — it has 7 angles + verify |
| Full PR re-review after each fix | Targeted diff only after round 1 |
| Fix one instance of a bug | Grep + fix all instances in one commit |
| Fix agent doesn't run tests | Explicit verify step in every fix prompt |
| MINOR/NITPICK holding up merge | Separate pass or human decision |
