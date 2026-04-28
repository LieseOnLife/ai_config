---
name: cloud-admin
description: Cloud Admin weekly Obsidian sync. Use when user invokes /cloud-admin or asks to sync cloud admin notes, update the cloud admin page, pull cloud admin tickets, check interrupt handler duty, or review cloud-accounts-support Slack activity.
---

# Cloud Admin Weekly Sync

Manages the weekly Cloud Admin Obsidian note by pulling unassigned JIRA access requests and Slack support questions from `cloud-accounts-support`. Run via `/cloud-admin`.

## Config

- **Obsidian Ops folder**: `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/`
- **Template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/🌧️ Cloud Admin.md` — **always read this file fresh at runtime; never inline its contents**
- **JIRA**: CLOUDA project, type = `Cloud Access Request`, unassigned only
- **Slack channel**: `cloud-accounts-support`

---

## Step 1: Determine the Week

Compute the Monday and Sunday of the **current calendar week** to define the week's date range.

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

Read the file into memory. You'll add only *new* items in Steps 4–6 — never modify or remove existing entries.

---

## Step 3: Find Last Week's Interrupt Handler

Search `cloud-accounts-support` for the interrupt handler announcement from the **previous week**. Look for messages like "IH this week", "interrupt handler", "on call", or similar duty announcements. Extract the name of the person who was on duty.

If you can't find it in Slack, ask the user: *"Who was the interrupt handler last week?"*

Note this name — you'll use it in Step 4 to flag carry-over tickets.

---

## Step 4: Pull JIRA Tickets

Query the CLOUDA board via Atlassian MCP. If authentication is needed, prompt the user.

Filter:
- Type = `Cloud Access Request`
- Assignee = unassigned
- Status ≠ Done / Closed / Resolved / Cancelled

For each ticket, determine the **cloud provider** using both methods:
1. Check Jira labels and components
2. Scan the title and description for keywords:
   - `AWS`, `Amazon`, `S3`, `IAM`, `EC2` → **AWS**
   - `GCP`, `Google Cloud`, `BigQuery`, `GCS` → **GCP**
   - `Azure`, `Microsoft`, `AD`, `AAD` → **Azure**
   - `OCI`, `Oracle` → **OCI**
   - Ambiguous → ask the user or place under the closest match

Format each ticket as:
```
- [ ] [CLOUDA-XXXX](https://datadoghq.atlassian.net/browse/CLOUDA-XXXX) - [[👤First Last]] / {Team} - {status}
```

When the requester is an individual person, link them as `[[👤First Last]]`. When the requester is a team or org unit (not a person), use the team name as plain text.

**Skip** any ticket whose ID already appears in the existing doc.

### Carry-over check

If last week's interrupt handler was identified in Step 3 and is someone other than Saje: flag any unassigned tickets whose `updated` date falls within last week. Present the list and ask:

*"These tickets may be carry-overs from {name}'s week — do you want me to self-assign them to you in Jira?"*

If yes, assign each via the Atlassian MCP.

---

## Step 5: Pull Slack Support Questions

Read all messages and threads in `cloud-accounts-support` from Monday of the current week through today.

Identify items where someone (not Saje) is asking a question, requesting follow-up, or needing cloud access help.

**Read the full thread before including anything.** Include all items that touched Saje's domain — both open and resolved. Classify each as open or completed:

**Completed** (`[x]`) — add these but mark done:
- Thread is resolved: ✅/:done:/:white_check_mark: reaction, "thanks, that worked!", or otherwise clearly closed
- Saje answered and the person acknowledged (e.g., `:ty:`, `:+1:`, or no follow-up needed)
- Redirected to another channel or team (e.g., #cloudops, #fabric) — note where it went
- Saje reviewed/approved a PR

**Open** (`[ ]`) — add these as needing action:
- Question unanswered or awaiting follow-up
- PR submitted and needs review
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

**Skip** any thread URL already in the existing doc.

---

## Step 6: Write to the Document

Insert gathered items under the correct sections in `## Permissions`:

- JIRA tickets and Slack items both go under the matching provider heading: `### AWS`, `### GCP`, `### Azure`, `### OCI`
- For Slack items, add a `#### Support Questions` sub-heading under the provider if one doesn't already exist
- For questions that span multiple providers or are unclear, add `### General` at the bottom of `## Permissions` with a `#### Support Questions` sub-heading
- Only append — never touch existing lines

---

## Step 7: Report

Print a brief summary after writing:
- How many new JIRA tickets were added (by provider)
- How many new Slack items were added
- Any items that need attention (unanswered questions, carry-over tickets offered for self-assignment)
