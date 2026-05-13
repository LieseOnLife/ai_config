---
name: cloud-accounts-primary-oncall
description: Cloud Accounts Primary On-call weekly Obsidian sync. Use when user invokes /cloud-accounts-primary-oncall or asks to sync the primary on-call note, pull cloud account creation tickets from CLOUDA, or capture Slack threads where Saje was tagged in cloud-accounts-support.
---

# Cloud Accounts Primary On-call Weekly Sync

Manages the weekly Cloud Accounts Primary On-call Obsidian note by pulling unassigned `Cloud Account Request` tickets from the CLOUDA Jira board and Slack threads in `cloud-accounts-support` where Saje was @mentioned or replied. Run via `/cloud-accounts-primary-oncall`.

## Config

- **Obsidian Ops folder**: `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/`
- **Template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/🌧️ Cloud Accounts Primary On Call.md` — **always read this file fresh at runtime; never inline its contents**
- **JIRA**: CLOUDA project, `issuetype = "Cloud Account Request"`, unassigned, status ≠ Done/Closed/Resolved/Cancelled
- **Slack channel**: `cloud-accounts-support` — **only threads where Saje was @mentioned or replied** (not a general channel digest)

---

## Step 1: Determine the Week

Compute Monday and Sunday of the **current calendar week**.

Glob `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/` for `🌧️* - Cloud Accounts Primary Oncall.md` whose date (extracted from filename) falls within the current week (Monday–Sunday).

- **Match found** → **update mode**. Use that file exactly as named; do not rename.
- **No match** → **create mode**. Filename:
  ```
  /Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/🌧️{YYYY-MM-DD} - Cloud Accounts Primary Oncall.md
  ```
  where `{YYYY-MM-DD}` is Monday's date.

---

## Step 2: Create or Open the Page

### Create mode

1. Read the template fresh.
2. Ask the user: *"What's the link to last week's handoff?"*
3. Drop the `<%* … %>` Templater block. Substitute variables:
   - `gcDate` / `date_start` → Monday's date
   - `date_end` → Monday + 5 days (Saturday)
   - Place the handoff link under `# Last Week`
4. Write the file. Proceed with Steps 3–5.

### Update mode

Read the file into memory. Append-only in Steps 3–5 — never modify or remove existing entries.

---

## Step 3: Pull JIRA Tickets

Query CLOUDA via Atlassian MCP. JQL:
```
project = CLOUDA AND issuetype = "Cloud Account Request" AND assignee is EMPTY AND statusCategory != Done
```

For each ticket, determine the **cloud provider** using both methods:
1. Check Jira labels and components.
2. Scan title/description for keywords:
   - `AWS`, `Amazon`, `S3`, `IAM`, `EC2` → **AWS**
   - `GCP`, `Google Cloud`, `BigQuery`, `GCS` → **GCP**
   - `Azure`, `Microsoft`, `AD`, `AAD` → **Azure**
   - `OCI`, `Oracle` → bucket under closest match or ask the user (no OCI section in template)
   - Ambiguous → ask the user

Format each ticket as:
```
- [ ] [CLOUDA-XXXX](https://datadoghq.atlassian.net/browse/CLOUDA-XXXX) - [[👤First Last]] / {Team} - {status}
```

When the requester is an individual person, link as `[[👤First Last]]`. When it's a team or org unit, use the team name as plain text.

**Skip** any ticket whose ID already appears in the doc.

---

## Step 4: Pull Slack Mentions and Replies

Search `cloud-accounts-support` from Monday of the current week through today. Include only threads where **Saje was @mentioned OR posted a reply**. Do not include general channel activity.

**Read the full thread before including anything.** Classify each as open or completed:

**Completed** (`[x]`):
- Thread resolved (✅ / :done: / :white_check_mark: reaction, "thanks, that worked!", or otherwise clearly closed)
- Saje answered and the requester acknowledged
- Redirected to another channel/team — note where it went
- Saje reviewed/approved a PR

**Open** (`[ ]`):
- Question unanswered or awaiting follow-up
- PR submitted, needs review
- Acknowledged but not yet acted on

Determine the cloud provider from context (same keyword logic as Step 3). If unclear, ask the user.

Format open items:
```
- [ ] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description}
```

Format completed items:
```
- [x] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description} ✅ {YYYY-MM-DD}
```

Always link the person's name as `[[👤First Last]]`.

**Skip** any thread URL already in the doc.

---

## Step 5: Write to the Document

Insert items under `# Account Requests Tasks`:

- JIRA tickets go under the matching provider heading: `## AWS`, `## GCP`, `## Azure`
- For Slack mentions, add a `### Slack Mentions` sub-heading under the provider if one doesn't already exist
- Only append — never modify existing lines
- Leave `# Handoff`, `## Feedback`, and `# Last Week` (after initial create) untouched for manual entry

---

## Step 6: Report

Print a brief summary:
- New JIRA tickets added (by provider)
- New Slack mentions added
- Anything needing attention (unanswered questions, ambiguous provider, missing info)
