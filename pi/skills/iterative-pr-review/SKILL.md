---
name: iterative-pr-review
description: Use when dispatching subagents to review PRs, reviewing code before human review, or running any fix-then-review loop. Triggers on "review the PRs", "run a code review", "fix and re-review", or any request to check code quality with subagents.
---

# Iterative PR Review

## Core Principle

Each review round should find fewer issues than the last. If it doesn't, the process is wrong — not the code.

## The Loop

```
reviewer (all PRs, parallel) → batch-fix BLOCKING+IMPORTANT → targeted diff review → repeat until clean
```

## Step 1: First pass — parallel `reviewer` subagents

Dispatch one `reviewer` subagent (pi-subagents) per PR, in parallel. Each reviewer gets the PR's worktree path and the diff to review:

```bash
cd <worktree>
git diff origin/<base-branch>...HEAD
```

Run all PRs in parallel — one `reviewer` subagent per PR via `subagent` with `async: true` (or `runs.all` in a workflowScript). Give each reviewer a focused brief: find BLOCKING issues (bugs, security, data loss) and IMPORTANT issues (design, correctness risks), each with file:line and a concrete recommendation.

For security-sensitive code (auth, secrets, IAM, infra/access), dispatch a second `reviewer` for that PR with a security brief.

## Step 2: Subsequent passes — targeted diff only

After fixes land, run `reviewer` again but scope it to **only the changed diff** (not a full re-review). This keeps round N+1 cheaper than round N and prevents the "each round finds new unrelated issues" failure mode.

## Step 3: Fix discipline

Batch all BLOCKING + IMPORTANT fixes from a round into one commit, then re-run the targeted review. Do NOT fix issues one at a time — that burns review budget and makes convergence impossible to measure.

## Convergence

| Round | Action |
|---|---|
| 1 | `reviewer` all PRs → fix all BLOCKING + IMPORTANT in one batch |
| 2 | `reviewer` (diff-only) → fix BLOCKING only |
| 3+ | LGTM or one final targeted pass |

If round 4+ still has many findings: **stop and diagnose** before continuing. The fix agents are introducing regressions, or there's a systemic design issue.

## Common Mistakes

- **Dispatching a single broad-sweep reviewer for all PRs at once.** One reviewer per PR, in parallel, catches more (cross-file callers, removed behaviors, reuse opportunities) and keeps each brief focused.
- **Re-reviewing the whole PR each round.** Scope subsequent rounds to the diff only.
- **Fixing one issue at a time.** Batch fixes per round so convergence is measurable.
- **Continuing past round 4 with no drop in findings.** Stop and diagnose — the loop is hiding a systemic problem.
