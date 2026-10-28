---
name: stacked-prs
description: Plan, execute, and restack stacked PRs — PR-stack table format, vertical slicing, per-PR stop gates, scope-drift flags, and the bottom-up restack procedure when main moves. Use when scoping any non-trivial feature, finishing a PR group, or updating a stack after main changes.
---

# Stacked PRs

## Slicing
- Each PR has one clear, independently reviewable purpose — a coherent unit of value, not just "a layer".
- **Slice vertically, not horizontally.** Each PR delivers one behavior end-to-end (model + handler + test for one capability), NOT "all the models" then "all the handlers".
- ~200-550 lines of diff per PR is a reviewability target, not a blocker. Prefer one cohesive vertical behavior over splitting to hit a number. Larger PRs are fine for generated code, tests, file moves, review-requested refactors, when splitting would create unsafe/incoherent intermediate states, or with explicit owner approval. PRs build in sequence; each merges once its parent lands.
- Branches: `saje/feature-name-pr1`, `-pr2`, etc.

## Plan-time gate (HARD — no code without it)
Every implementation plan opens with a PR-stack table. Group tasks by PR boundary; end each group with an explicit "Open PR" step. Explain rows above the target, but don't force a split on line count alone. A `pr-size-guard` warning is advisory.

| PR | Purpose (one behavior) | Est. diff | Depends on |
|----|------------------------|-----------|------------|
| pr1 | ... | ~250 lines | — |

## Execution-time gate
When a PR group is finished, **STOP** — open the PR (`create-pr` skill) and don't start the next group until Saje says go.

## Scope drift
Need files outside the agreed slice? STOP and flag it ("needs files X/Y outside the slice — expand scope, or follow-up PR?") instead of silently growing the PR.

## Restacking when `main` moves (HARD — this has burned us)
- **NEVER `git merge main` (or `origin/main`) into a child branch.** Merging `main` independently into two stacked branches makes them diverge — the merge-base regresses into `main`, the child diff balloons with unrelated commits/files, and DDCI task-sourcing breaks.
- **Bottom up:** merge latest `main` into the *base* branch (pr1) only, then cascade **parent → child** (`merge pr1 into pr2`, then `pr2 into pr3`, …). Each child gets `main` transitively.
- **Verify every parent→child pair — don't trust `git diff --stat` counts:**
  ```bash
  git merge-base --is-ancestor origin/saje/<parent> origin/saje/<child> && echo CLEAN || echo DIVERGED
  git diff --name-only origin/saje/<parent>...origin/saje/<child>   # must show ONLY the child's real files
  ```
  Files from other domains/teams in the 3-dot diff (e.g. `domains/apm/...` in a `domains/compute` PR) = tangled stack. Stop and restack; don't push.
