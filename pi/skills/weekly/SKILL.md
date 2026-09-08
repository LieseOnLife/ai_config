---
name: weekly
description: Build and maintain Saje's focused weekly Obsidian dashboard from Jira, projects, TODOs, Slack, DMs, and calendar capacity. Use for /weekly, weekly planning or review, refreshing weekly tasks, closing the week, or linking daily and Cloud Admin notes to the week.
---
# Weekly Planning
## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Weekly folder: `Calendar/Weekly Notes/`
- Template: `Extras/Templates/Weekly Notes.md` — always read it fresh; never inline it here
- Jira task notes: `Datadog/Tasks/🎞️ {KEY} {summary}.md`
- Week tag: `#week/{ISO-YEAR}-W{ISO-WEEK}`
- Canonical filename for a new page: `{ISO-YEAR}-w{WW}-{MM-DD}.md`
## Modes
- `/weekly` and `/weekly refresh`: create the current week if absent; otherwise reconcile it.
- `/weekly close`: reconcile, then write the immutable close snapshot and carry work forward.
- `/morning` uses **Morning Integration** only; `/cloud-admin` uses **Cloud Admin Integration** only.
## 1. Resolve the Week
Compute ISO Monday and Sunday. Find a weekly file by frontmatter `type: weekly_notes` and `date_start: {Monday}`; filenames may be legacy. Refuse to create a second page for the same Monday. On every run, read the target and template fresh.

## 2. Gather Read-only Evidence

Before changing goals, commitments, task tags, or Jira notes, gather:

1. Previous weekly close/carry-forward items.
2. Every unresolved Obsidian checkbox outside templates, plus open standalone `[[🎞️ Task]]` notes. Do not limit discovery to this ISO week. Track each by vault-relative path and original line or note path.
3. All active Jira issues assigned to Saje across projects. Reconcile by normalized uppercase Jira key; inspect existing `Datadog/Tasks/🎞️ {KEY}*.md` before proposing a new note.
4. Daily Slack Summaries from the later of Monday or the last successful refresh through today. Record missing dates; do not infer existence from daily-note embeds.
5. A Slack gap scan for missing-summary dates, DMs/direct asks, unresolved threads involving Saje, and channels tied to candidate outcomes. Read full threads. Normalize permalinks by channel/message identity, ignoring host aliases and query fragments.
6. Monday–Sunday calendar load, PTO, duty weeks, and deadlines for capacity only. Do not create tasks from ordinary meetings.

Record unavailable sources. `last_planning_refresh` advances only when all required planning sources succeed; scan inclusively from the prior watermark and keep it unchanged on partial failure.

## 3. Goal Approval Gate

Present **exactly three** numbered proposals in chat, each with **Outcome**, **Done when**, **Supports**, and **Risk**, plus the capacity assessment. Do not write outcomes, commitments, task tags, or new Jira notes before Saje explicitly approves. She may approve fewer than three. Rejection or edits require a revised proposal and another explicit approval; silence and unrelated replies are not approval.

For a confirmed week, preserve outcomes. New evidence may enter **New & Unplanned** or prompt a proposed goal change, but rewriting an outcome requires the same approval gate and a timestamped **Plan Changes** entry.

## 4. Write or Reconcile

After approval, render a new page from the live template or update the existing page while preserving manual prose and task state. Set `goals_confirmed`, `goals_confirmed_at`, source timestamps, capacity, and the successful watermark.

Task rules:

- One active checkbox per action. Move it between weekly sections; never copy it.
- Existing project/Obsidian checkbox: add or replace the concrete week tag on that canonical line in place. Do not create a weekly duplicate.
- Jira: create/update the standalone task note using the nearest existing Jira-note schema, then add one weekly checkbox linking to it. Reconcile status from Jira. Deduplicate by Jira key.
- Slack/DM with no existing task: create one checkbox on the weekly page linking to the canonical permalink. Deduplicate by normalized message identity.
- Include `➕ YYYY-MM-DD` on newly created checkboxes. `[?]` means waiting, `[!]` blocked/urgent, and `[-]` only cancelled. Deferred tasks remain open and lose the current week tag.
- Link supporting tasks from outcomes; do not create extra outcome checkboxes.

## 5. Reconcile Week Links

For every existing `Calendar/Daily Notes/YYYY-MM-DD.md` from Monday through Sunday, excluding Slack Summary files, add/repair `date: YYYY-MM-DD`, `week: "[[{weekly basename}]]"`, and one visible `**Week:** [[{weekly basename}|Weekly Plan]]` near Previous/Next navigation. Preserve unrelated frontmatter and prose.

For matching Cloud Admin notes in `Datadog/Ops/`, add/repair the same scalar `week` property and one managed `[p] [Weekly Plan](obsidian://open...)` or wikilink entry under `# Links`. Identify the Cloud Admin note by its filename/template and date range, not `type: cloud_admin` alone. Repeated runs must make no duplicate links or properties.

## Morning Integration

Determine whether invocation includes `scheduled-headless`.

- No weekly page, interactive: ask whether to run `/weekly`; run it only after explicit yes.
- No weekly page, scheduled: add exactly once to today's daily note: `- [!] Run /weekly to create and approve this week's plan ➕ YYYY-MM-DD`; continue morning; do not create a weekly page.
- Weekly exists: reconcile today's daily link/property; remove an open missing-week reminder; read today's generated Slack Summary and new DM/thread evidence since `last_morning_sync`; add only new actionable items under the two Slack sections. Never change confirmed goals. Advance `last_morning_sync` only after this pass succeeds.

## Cloud Admin Integration

Never create a weekly page. If one exists, reconcile the Cloud Admin note's managed `week` property and Weekly Plan link. This is the sole exception to Cloud Admin's append-only rule; never rewrite user tasks or prose.

## Close

Run a final reconciliation. Under **Friday Close Snapshot**, write static non-checkbox linked bullets for every selected action and final state; this is historical authority after live queries change. For carry-forward, keep one active checkbox: move weekly-owned tasks to the next page when it exists, or retag source-owned tasks in place; never recreate them. Record wins, unexpected work, outcome evidence, failures, and `last_weekly_close`.

## Report

Report approved goals, capacity, Jira notes created/updated, tasks focused, Slack/DM tasks added, links repaired, missing/unavailable sources, watermark state, and close/carry-forward results. A second unchanged run must produce no duplicate task, note, tag, property, or link.
