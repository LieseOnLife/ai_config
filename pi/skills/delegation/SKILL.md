---
name: delegation
description: Rules for spawning, supervising, and stopping subagents (omp task agents) plus when to call an advisor. Use before dispatching any subagent, when a child hits needs_attention/active_long_running, on SIGKILL/retry decisions, and at planning gates, approach forks, stuck loops, blast-radius actions, or task completion.
---

# Delegation

## Routing
- Coding work (implementation, refactors, bug fixes, test edits) → `coder`. Everything else (research writeups, data gathering, tickets/docs, ops) → `task`. Read-only exploration → `scout`. Mechanical bulk edits → `sonic`. Bazel → `bzl` only.
- PR checking (CI watch, flake re-runs, comment fetch) → the single `PrWatch` `task` agent per session, per `post-push-protocol`. If it's running, `write agent://PrWatch` with the new PR/SHA; never spawn a second.
- Whenever you spawn, report on, or summarize subagents, name each one's model (e.g. `PrWatch` — task — gpt-6-sol:high), resolved from `~/.omp/agent/config.yml` (`task.agentModelOverrides`, `modelRoles`) or the agent's `model:` frontmatter. Can't resolve it → say so; don't guess.

## Briefing
- Cold-start complete and narrowly bounded: exact objective, cwd/ref, authority boundary, success criteria, validation, expected output, explicit stop conditions.
- Worktrees: pass the full absolute worktree path; the child `cd`s there first and uses absolute paths. Context via `~/.pi/agent/scripts/worktree-context.sh`; standard prompt format in the `/worktree-subagent` template.
- No hard tool-call budgets on mutation-capable workers. Bound them by delivery slice and require a checkpoint: changed files, validation state, remaining work, commit/PR state. Don't use the removed `turnBudget` field.

## Parallelism
- Maximize **safe** parallelism within concurrency/memory caps; omission is cheaper than unnecessary commissions. Parallelize only genuinely independent lanes.
- One writer per cwd/worktree. When a `bzl` subagent is active, don't launch or keep other subagents running — Bazel is memory-heavy and exclusive across worktrees.

## Waiting and decisions
- Children never `sleep`, poll, or repeatedly ping the supervisor. Ask once via `hub send` to `Main` with `await: true` and wait.
- If the decision needs user input, advisor work, or investigation, pause/interrupt the writer and resume it with the resolved decision — don't tell it to hold. Pre-authorize expected branch movement; batch foreseeable questions into one packet.

## Intervention
`needs_attention` / `active_long_running` are triggers, not noise:
1. Inspect status or transcript once.
2. Idle, wrong tool/path, repeating a failure, or out of scope → interrupt immediately.
3. Resume at most once with narrower instructions and an answer-now/checkpoint request.
4. Second attention event → stop the run. Don't nudge again.

A healthy expected long-running tool (especially an exact Bazel command) may continue; elapsed time alone isn't drift.

## Failures
- Startup `SIGKILL`: retry at most once, after other children settle. Second `SIGKILL` is terminal — surface it. No retry storms.
- Don't retry a task/tool failure until it's classified transient. Ordinary code/test failures are results to fix or report.
- Hard elapsed/tool timeouts are backstops, not checkpoint mechanisms.

## Advisor checkpoints
Call `advisor` (fresh-context read-only reviewer):

| Circumstance | When exactly |
|---|---|
| **Planning gate** | After self-reviewing a spec or plan, before presenting it to Saje |
| **Approach fork** | Choosing between two non-trivial strategies — before committing |
| **Stuck** | After two failed attempts at the same problem |
| **Blast radius** | Before actions affecting shared infra, published branches, or external services |
| **Task complete** | Before declaring a multi-step task done (write the deliverable first) |
