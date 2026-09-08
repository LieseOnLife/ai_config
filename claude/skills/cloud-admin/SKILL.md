---
name: cloud-admin
description: Cloud Admin weekly Obsidian sync. Use when user invokes /cloud-admin or asks to sync cloud admin notes, update the cloud admin page, pull cloud admin tickets, check interrupt handler duty, or review cloud-accounts-support Slack activity.
---

# Cloud Admin Weekly Sync

Manages the weekly Cloud Admin Obsidian note by pulling unassigned CLOUDA access requests, active CAPA tickets outside both `Backlog` and `Blocked Backlog`, and Slack support questions from `cloud-accounts-support`. Run via `/cloud-admin`.

## Config

- **Obsidian Ops folder**: `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/`
- **Daily Notes folder**: `/Users/saje.liese/Obsidian/Tech-2/Calendar/Daily Notes/`
- **Cloud Admin template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/🌧️ Cloud Admin.md` — **always read this file fresh at runtime; never inline its contents**
- **Daily Note template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/Daily Note.md` — read fresh if today's daily note must be created
- **JIRA — CLOUDA**: type = `Cloud Access Request`, unassigned only
- **JIRA — CAPA**: unassigned, active tickets whose status is neither `Backlog` nor `Blocked Backlog`; also reconcile every CAPA ticket already in the note or referenced by an in-scope Slack thread
- **Slack channel**: `cloud-accounts-support`

---

## Step 1: Determine the Week

Compute the Monday and Sunday of the **current calendar week** to define the discovery range. This Monday–Sunday range selects the weekly note and Slack window; the note's `date_end` remains Monday + 5 days (Saturday) as defined by the template.

Search the Ops folder for any file matching `🌧️*-Cloud Admin.md` whose date (extracted from the filename) falls within the current week (Monday–Sunday). Use Glob on `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/` with pattern `🌧️* - Cloud Admin.md`.

- **If a matching file is found**: that is your target file — use it exactly as named. You are in **update mode**. Do not rename it.
- **If no matching file is found**: you are in **create mode**. The new file will be named using Monday's date:
  ```
  /Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/🌧️{YYYY-MM-DD} - Cloud Admin.md
  ```
  where `{YYYY-MM-DD}` is the Monday of the current week.

---

## Step 2: Create or Open the Page

### Create mode (file does not exist)

1. Read the template at `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/🌧️ Cloud Admin.md`
2. Ask the user: *"What's the link to last week's handoff?"*
3. Substitute Templater variables with real values:
   - `gcDate` / `date_start` → Monday's date
   - `date_end` → Monday + 5 days (Saturday)
   - `lastWeek` → handoff URL the user provided
   - Title/filename: `🌧️{YYYY-MM-DD} - Cloud Admin.md`
4. Write the file. Proceed with Steps 3–6 to populate it.

### Update mode (file already exists)

Read the file into memory. Add new items, remove future-dated tickets as required by Step 4, and reconcile existing Jira/Slack entries whose status changed. Preserve entries manually dismissed with `[-]` unless Saje asks to restore them.

### Weekly Dashboard Link
After create or open, read `~/.claude/skills/weekly/SKILL.md` and follow **Cloud Admin Integration**. Link to an existing current weekly page only; never create one. Reconcile only the managed `week` property and `# Links` entry; preserve user tasks and prose.

### Link from today's daily note (once per day)

On the first Cloud Admin run of each day, ensure today's daily note links to the current weekly Cloud Admin note:

1. Resolve today's daily note as `/Users/saje.liese/Obsidian/Tech-2/Calendar/Daily Notes/{YYYY-MM-DD}.md`.
2. If the daily note does not exist, read the Daily Note template fresh and render it for today's date before continuing.
3. Build an Obsidian wiki link from the weekly note's filename without `.md`, for example `[[🌧️2026-08-31 - Cloud Admin]]`.
4. If that exact link is already present anywhere in today's daily note, do nothing. Its presence is the idempotent signal that today's first-run step has already completed.
5. Otherwise, add the link directly beneath the daily note's `# {Weekday} Notes` heading, preserving all existing content and spacing.

Never add the same Cloud Admin link more than once to a daily note. Complete this step in both create and update mode.

---

## Step 3: Find Last Week's Interrupt Handler

Search `cloud-accounts-support` for the interrupt handler announcement from the **previous week**. Look for messages like "IH this week", "interrupt handler", "on call", or similar duty announcements. Extract the name of the person who was on duty.

If you can't find it in Slack, ask the user: *"Who was the interrupt handler last week?"*

Note this name — you'll use it in Step 4 to flag carry-over tickets.

---

## Step 4: Pull JIRA Tickets

Before querying the active queues, extract every `CLOUDA-*` and `CAPA-*` ID already present in the note, including IDs mentioned inside existing Slack-item descriptions, and fetch each issue directly via Atlassian MCP. Reconcile its task marker and status text even if the issue is now assigned or terminal (`Done`, `Closed`, `Resolved`, or `Cancelled`); those issues will not appear in the filtered queue queries. Preserve manually dismissed `[-]` entries unless Saje asks to restore them. Step 5 performs a second direct-fetch pass for Jira IDs discovered in newly read Slack threads.

Then query both Jira projects via Atlassian MCP. If authentication is needed, prompt the user.

CLOUDA filter:
- Type = `Cloud Access Request`
- Assignee = unassigned
- Status ≠ Done / Closed / Resolved / Cancelled

CAPA filter:
- Assignee = unassigned
- Status category ≠ Done
- Status ∉ Backlog / Blocked Backlog

Do not pull the general CAPA backlog into the weekly note. A CAPA ticket that was already added or is referenced by an in-scope Slack thread must still be fetched and reconciled after it becomes assigned, Done, Cancelled, or Backlog.

For each ticket, determine the **cloud provider** using both methods:
1. Check Jira labels and components
2. Scan the title and description for keywords:
   - `AWS`, `Amazon`, `S3`, `IAM`, `EC2` → **AWS**
   - `GCP`, `Google Cloud`, `BigQuery`, `GCS` → **GCP**
   - `Azure`, `Microsoft`, `AD`, `AAD` → **Azure**
   - `OCI`, `Oracle` → **OCI**
   - Ambiguous → ask the user or place under the closest match

Format CLOUDA tickets as:
```
- {marker} [CLOUDA-XXXX](https://datadoghq.atlassian.net/browse/CLOUDA-XXXX) - [[👤First Last]] / {Team} - {status}
```

Format CAPA tickets as:
```
- {marker} [CAPA-XXXX](https://datadoghq.atlassian.net/browse/CAPA-XXXX) - {summary} - {status}
```

Use Jira status—not the placeholder shown in the format examples—to select each ticket's marker:

| Jira state | Marker |
|------------|--------|
| Open / To Do / Backlog / Needs Triage | `[ ]` |
| In Progress / In Review / Needs Approval / Request Approved | `[/]` |
| Needs User Response / Awaiting Response | `[?]` |
| Blocked | `[!]` |
| Done / Closed / Resolved | `[x]` |
| Cancelled | `[-]` |

If an existing item was manually dismissed with `[-]`, preserve `[-]` regardless of its current Jira state unless Saje asks to restore it. If a tracked CAPA ticket moves to `Backlog` or `Blocked Backlog`, mark it `[-]` and retain it for audit rather than treating it as active or rediscovering the general backlog. Add `✅ {YYYY-MM-DD}` to terminal successful items when the completion date is known, and `❌ {YYYY-MM-DD}` to cancelled or dismissed items when that date is known.

When the requester is an individual person, link them as `[[👤First Last]]`. When the requester is a team or org unit (not a person), use the team name as plain text.

**No JIRA ticket exists yet** (e.g. a Slack-only report/investigation under a provider heading): link the Slack thread in place of the ticket link instead of writing "No ticket":
```
- [ ] [Slack thread]({thread_url}) - {description}
```

If a ticket ID already appears in the document, do not add a duplicate. Reconcile its task marker and status text with current Jira, except that manually dismissed `[-]` entries remain dismissed unless Saje asks to restore them. A CAPA ID mentioned only inside a Slack item's description does not replace the CAPA Jira entry; add the linked Jira ticket once under the matching provider.

### Due-date filter

Check every ticket's due date before adding it. If the due date is after today, do not add the ticket to the current week's list. If a future-dated ticket already appears in the current note, remove it; it should return to the active list when its due date arrives. Tickets due today, overdue, or without a due date remain eligible.

### Carry-over check

If last week's interrupt handler was identified in Step 3 and is someone other than Saje: flag any unassigned tickets whose `updated` date falls within last week. Present the list and ask:

*"These tickets may be carry-overs from {name}'s week — do you want me to self-assign them to you in Jira?"*

If yes, assign each via the Atlassian MCP.

---

## Step 5: Pull Slack Support Questions

Read all messages and threads in `cloud-accounts-support` from Monday of the current week through today.

Identify items where someone (not Saje) is asking a question, requesting follow-up, or needing cloud access help.

**Read the full thread before including anything.** A standalone message (a bump, follow-up, or `:crosspost:`/forward) is often *not* the real discussion — scan the surrounding channel history for the original parent message on the same topic/PR/ticket (same URL or subject, earlier timestamp, with replies) and read *that* thread too. The entry you write must reflect the whole conversation (Saje's replies, decisions, linked Jira/PRs, and the latest unresolved ask), not just the surface message. Link the **parent** thread URL when a standalone message belongs to a larger thread.

Include all items that touched Saje's domain — both open and resolved. Classify each as open or completed. **Always include completed Slack threads in the note and mark them completed (`[x]` / `[X]`) rather than skipping them.**

**Task status markers** — use the appropriate marker for each item. Importance variants (`[!]`, `[*]`, `[X]`) replace their normal counterparts when the item is high-priority/urgent:

| Status | Normal | Important |
|--------|--------|-----------|
| Open / not started | `[ ]` | `[!]` |
| In progress (Saje active, or awaiting teammate review) | `[/]` | `[*]` |
| Waiting on someone outside the team | `[?]` | `[?]` |
| Done | `[x]` | `[X]` |
| Dismissed from Saje's list | `[-]` | `[-]` |

**Done** (`[x]` / `[X]`) — add these but mark done:
- Thread is resolved: ✅/:done:/:white_check_mark: reaction, "thanks, that worked!", or otherwise clearly closed
- A 🔒 reaction means the response was sufficient and the thread is resolved
- Saje answered and the person acknowledged (e.g., `:ty:`, `:+1:`, or no follow-up needed)
- Redirected to another channel or team (e.g., #cloudops, #fabric) — note where it went
- Saje reviewed/approved a PR

**In progress** (`[/]` / `[*]`) — Saje is actively working on it, or has submitted something and is waiting on a teammate (cloud-accounts team):
- Saje opened a PR and is awaiting review from a teammate
- Saje is mid-investigation on the request

**Waiting on someone outside the team** (`[?]`) — Saje has asked a question or requested a review/response from someone outside cloud-accounts and is blocked on their reply:
- Left a PR review comment on someone else's PR, awaiting their response
- Asked the requester for clarification, awaiting reply
- Pinged another team for input, awaiting reply

**Open** (`[ ]` / `[!]`) — needs action from Saje but not yet started:
- Question unanswered or awaiting follow-up from Saje
- PR submitted by someone else and needs Saje's review
- Request acknowledged but not yet acted on

**Skip entirely** — do not add at all:
- Pure noise with no relevance to cloud accounts (e.g., bot messages, automated crossposts with no action)
- Items where another teammate (not Saje) is fully handling it with no need for Saje's involvement

Determine the cloud provider from context (same keyword logic as Step 4). If no provider is clear, use `### General`.

Format open items as:
```
- [ ] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description}
```

Format completed items as:
```
- [x] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description} ✅ {YYYY-MM-DD}
```

Always link the person's name as `[[👤First Last]]`.

If a thread URL already appears in the document, do not add a duplicate. Re-read the thread and reconcile its task marker and description when its state changed.

After reading all in-scope Slack threads, extract every `CLOUDA-*` and `CAPA-*` ID found in newly discovered thread content. Directly fetch any ID that was not already fetched in Step 4, then add or reconcile its Jira entry using the Step 4 filters, marker mapping, due-date rule, and provider placement. This second pass is mandatory so a Slack-linked ticket cannot escape reconciliation merely because it is assigned, terminal, or already moved to Backlog.

---

## Step 6: Write to the Document

Insert gathered items under the correct sections in `## Permissions`:

- CLOUDA tickets, CAPA tickets, and Slack items all go under the matching provider heading: `### AWS`, `### GCP`, `### Azure`, `### OCI`
- For Slack items, add a `#### Support Questions` sub-heading under the provider if one doesn't already exist
- For questions that span multiple providers or are unclear, add `### General` at the bottom of `## Permissions` with a `#### Support Questions` sub-heading
- Append new items; edit existing lines only to remove future-dated tickets or reconcile Jira/Slack status and descriptions. Preserve manually dismissed `[-]` entries unless Saje asks to restore them

---

## Step 7: Report

Print a brief summary after writing:
- How many new Jira tickets were added (by Jira project and provider)
- How many new Slack items were added
- Any items that need attention (unanswered questions, carry-over tickets offered for self-assignment)
