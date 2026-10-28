---
name: post-push-protocol
description: Mandatory follow-through after every `git push` (including force pushes and rebases) — hand the PR to the single `PrWatch` subagent (CI watch, flake re-runs, comment fetch), fix real failures, auto-review major diffs, handle PR comments, report back. Push hooks inject a pointer to this skill; run it automatically without being asked.
---

# Post-Push Protocol

A `git push` is not "done". Run every step automatically, every time. Don't declare a task complete while any step is outstanding.

1. **Hand the PR to `PrWatch` — exactly one PR-check subagent per session, never inline.** Never claim CI will pass.
   - **Reuse before spawning.** Check whether a `PrWatch` agent is still running (`read agent://` / `agent://PrWatch`). Running → `write agent://PrWatch` with the PR URL + pushed SHA (it adds the PR or restarts the watch on the new SHA). Not running → spawn one `task` agent named `PrWatch`. Never spawn a second PR watcher, and never spawn one per PR or per push — stacked PRs and re-pushes all go to the same agent.
   - **`PrWatch`'s job (read-only on code):** resolve each PR (`gh pr view --json url -q .url`), run `gh pr checks <url> --watch` until every check completes, re-run flaky/infra failures once (step 2), and fetch new PR comments via `get-pr-feedback`. It reports per PR: final check states, re-runs and their outcome, real failures with log excerpts, and new comments (bot vs. human). It never edits code, pushes, or replies to comments — the main session owns fixes and replies (one writer per worktree).
   - If subagent spawning is broken, say so and get approval before watching inline.
   - **`devflow/mergegate` on dd-source PRs requires a human approval** — it sits `pending`/`in_progress` indefinitely (observed 5.5+ hrs). If it's the *only* non-passing check, report "awaiting approval," not "stuck"; don't recommend a retrigger/empty-commit push.

2. **Triage failures before escalating:**
   - *Flaky/infra* (timeout, network, dead runner, known-flaky test): `PrWatch` re-runs the failed job **once** (`gh run rerun <run-id> --failed`). Passes → note it, continue. Fails the same way → treat as real.
   - *Real failure* (your change broke it): fix immediately and push (re-triggers this protocol). Don't hand a fixable failure back to Saje.
   - *Ambiguous / needs Saje's call*: bring the check name, log excerpt, and a recommendation.

3. **Auto-review your diff (major changes only** — new PR or ~50+ lines of real logic; skip typos/renames). Dispatch the full reviewer panel **simultaneously in one `task` call's `tasks[]` batch** — never sequentially:
   - `reviewer` (primary, default model from `task.agentModelOverrides`)
   - `security-reviewer` (default model)
   - `reviewer` with `model: ai-gw-openai/openai/gpt-6.1-sol:max` (secondary)
   - `reviewer` with `model: ai-gw-anthropic-200k/anthropic/claude-opus-5-5:xhigh` (secondary)

   Same diff and brief to each (BLOCKING/IMPORTANT findings with file:line + recommendation; security brief for `security-reviewer`). Merge and dedupe findings across reviewers, noting which models agreed. Auto-fix obvious/safe issues and push; surface design-tradeoff findings to Saje with file:line and a recommendation — don't auto-apply those. Small diffs skip the panel.

4. **Address PR comments** reported by `PrWatch` (the `/review-pr-comments` / `get-pr-feedback` process, unprompted):
   - *Bots* (codex, sonarcloud, codecov, github-actions, `*[bot]`): respond **definitively** — fix + reply, or reply why it's not applicable. Never leave an open question.
   - *Humans*: do NOT auto-reply. Surface to Saje with the link, summary, recommendation, and a draft reply for approval.
   - *Reply format*: reply body in a `>` blockquote, then one attribution line saying who wrote it: 🤖 agent-written and not reviewed, 🤖✅ agent-drafted and approved by Saje, 👩‍💻 Saje's own words. Templates are in `/review-pr-comments`.

5. **Report back** in-session: what CI did (incl. re-runs), auto-review findings (fixed vs. needs-decision), comments handled, and anything needing Saje's attention. Bring issues proactively — she shouldn't have to ask "what's the status."
