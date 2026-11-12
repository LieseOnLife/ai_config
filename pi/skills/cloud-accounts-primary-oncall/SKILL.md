---
name: cloud-accounts-primary-oncall
description: Cloud Accounts Primary On-call weekly Obsidian sync. Use when user invokes /cloud-accounts-primary-oncall or asks to sync the primary on-call note, pull cloud account creation tickets from CLOUDA or quota requests from CAPA, or capture Slack threads where Saje or @cloud-accounts-oncall was tagged in cloud-accounts-support, or requests in cloud-quota.
---

# Cloud Accounts Primary On-call Weekly Sync

Manages the weekly Cloud Accounts Primary On-call Obsidian note by pulling unassigned `Cloud Account Request` tickets from the CLOUDA Jira board, unassigned quota requests from the CAPA Jira board, Slack threads in `cloud-accounts-support` where Saje or `@cloud-accounts-oncall` was @mentioned, or Saje replied, and request threads in `cloud-quota`. Run via `/cloud-accounts-primary-oncall`.

## Config

- **Obsidian Ops folder**: `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/`
- **Template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/🌧️ Cloud Accounts Primary On Call.md` — **always read this file fresh at runtime; never inline its contents**
- **JIRA (accounts)**: CLOUDA project, `issuetype = "Cloud Account Request"`, unassigned, status ≠ Done/Closed/Resolved/Cancelled
- **JIRA (quotas)**: CAPA project, `labels = quota-management`, unassigned, status ≠ Done. CAPA is also the Capacity/Quota team's project backlog; only the `quota-management` label marks quota requests
- **Slack channel (accounts)**: `cloud-accounts-support` (`C08MPTABY23`) — **only threads where Saje (`U01D2L9K04T`) or the `@cloud-accounts-oncall` group (`S08BU18JQ0J`) was @mentioned, or Saje replied** (not a general channel digest)
- **Slack channel (quotas)**: `cloud-quota` (`C0A0P6WBZBP`) — the topic names `@cloud-accounts-oncall` as the interrupt handler, so **every request thread** counts, mentioned or not

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
4. Write the file. Proceed with Steps 3–6.

### Update mode

Read the file into memory. Add new items (Steps 3–5), and refresh the status of existing open items (Step 4c). Never remove existing lines.

---

## Step 3: Pull JIRA Tickets

### 3a: CLOUDA account requests

Query CLOUDA via Atlassian MCP. JQL:
```
project = CLOUDA AND issuetype = "Cloud Account Request" AND assignee is EMPTY AND statusCategory != Done
```

For each ticket, determine the **cloud provider** using both methods:
1. Check Jira labels and components.
2. Scan title/description for keywords:
   - `AWS`, `Amazon`, `S3`, `IAM`, `EC2` → **AWS**
   - `GCP`, `Google Cloud`, `BigQuery`, `GCS` → **GCP**
   - `Azure`, `Microsoft`, `AD`, `AAD`, `subscription`, `Standard…Family` vCPU families → **Azure**
   - `L-XXXXXXXX` service-quota codes, `service-quotas`, 12-digit account IDs → **AWS**
   - `OCI`, `Oracle` → bucket under closest match or ask the user (no OCI section in template)
   - Ambiguous → ask the user

Format each ticket as:
```
- [ ] [CLOUDA-XXXX](https://datadoghq.atlassian.net/browse/CLOUDA-XXXX) - [[👤First Last]] / {Team} - {status}
```

When the requester is an individual person, link as `[[👤First Last]]`. When it's a team or org unit, use the team name as plain text.

**Skip** any ticket that already has its own `[CLOUDA-XXXX](…)` task line in the doc. A key that only appears inside a Slack thread description doesn't count.

### 3b: CAPA quota requests

JQL:
```
project = CAPA AND labels = quota-management AND assignee is EMPTY AND statusCategory != Done
```

Without the label, the query returns the whole CAPA engineering backlog (sub-tasks, `tech-debt`, `interrupt-handler` improvement tickets). Those aren't requests, so leave them out. Assigned `quota-management` tickets are already being worked; skip them too.

The summary carries the provider (`AWS quota: …`, `GCP quota: …`, `Azure quota: …`). Take `quota name`, `account name`, and `location` from the description bullets, because Azure summaries leave out the location. Request `description` in the query's `fields`. Most tickets are filed by `Robot Slack SRE` on behalf of Cloud Quota Manager (CQM), so name the quota and account instead of the reporter. Format:
```
- [ ] [CAPA-XXXX](https://datadoghq.atlassian.net/browse/CAPA-XXXX) - `{quota}` on `{account}` ({location}) - {status}
```

If a human filed it, add ` - [[👤First Last]]` after `({location})`. If a human-filed ticket has no provider prefix or quota bullets, use Step 3a's provider logic and `{summary} - [[👤First Last]] - {status}`.

**Skip** any ticket that already has its own `[CAPA-XXXX](…)` task line in the doc. A key that only appears inside a Slack thread description doesn't count.

---

## Step 4: Pull Slack Threads

Search both channels from Monday of the current week through today (Slack `after:` is exclusive, so use the day before the window start).

### 4a: cloud-accounts-support

Include only threads where **Saje was @mentioned, `@cloud-accounts-oncall` was @mentioned, OR Saje posted a reply**. Do not include general channel activity.

How to find them:
1. **Saje mentions**: `keywords: ["<@U01D2L9K04T>"]`, `filters: in:<#C08MPTABY23> after:{date}`. **Saje replies**: `filters: in:<#C08MPTABY23> from:<@U01D2L9K04T> after:{date}`.
2. **`@cloud-accounts-oncall` mentions**: keyword search does NOT match user-group mentions. Page through every channel message in the window (`filters: in:<#C08MPTABY23> after:{date}`, `sort: timestamp`, `include_bots: true`) and collect distinct thread roots: `thread_ts` from the permalink, or `Message_ts` for a top-level message with no replies. `slack_read_thread` each root, and keep threads whose raw text contains `S08BU18JQ0J` (renders as `<!subteam^S08BU18JQ0J>`). The ping may predate the window, e.g. a weeks-old thread with new replies; include it if the thread had activity in the window. `Cloud Accounts Support Forwarder` crossposts from #cloudops carry the group mention, so bots must be included.
3. Skip `set the channel topic` bot posts — they mention the IH but aren't requests.

### 4b: cloud-quota

The channel exists for quota requests and the IH owns it, so include **every request thread with activity in the window**; nobody has to tag us. It's low-volume, so page through all of it: `filters: in:<#C0A0P6WBZBP> after:{date}`, `sort: timestamp`, `include_bots: true`. Collect distinct thread roots (as in 4a, including unanswered top-level requests) and `slack_read_thread` each.

- Skip `set the channel topic` posts and deleted messages.
- Off-topic asks (e.g. an unrelated PR review posted in the wrong channel): include them only if Saje replied; otherwise list them under "needs attention" in the report.
- If the thread is about a CAPA ticket, name the key in the description so the two entries can be matched.

### Classify (both channels)

**Read the full thread before including anything.** Classify each as open or completed:

**Completed** (`[x]`):
- Thread resolved (✅ / :done: / :white_check_mark: reaction, "thanks, that worked!", or otherwise clearly closed)
- Saje or a teammate answered and the requester acknowledged
- Saje or a teammate reviewed/approved a PR

**Cancelled / moved** (`[-]`):
- Saje or a teammate moved it somewhere else: another channel (e.g. the forwarder crossposted it to #cloudops), another team, or Corp IT / a Freshservice ticket
- A PR review request outside the review scope (below)
- Add a sub-bullet comment saying where it went, with a link when there is one

**Open** (`[ ]`):
- Question unanswered or awaiting follow-up
- PR in the review scope, needs review
- Acknowledged but not yet acted on

If Saje creates a Jira ticket from a thread (e.g. via the Jira bot), the work is still ours: keep the item open and add a `📋` sub-bullet naming the ticket.

Determine the cloud provider from context (same keyword logic as Step 3a). If unclear, ask the user.

Format open items:
```
- [ ] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description}
```

`{thread_url}` is the parent permalink: `https://dd.enterprise.slack.com/archives/{channel_id}/p{thread_ts without the dot}`, with no `?thread_ts=` query. Search results link to the matching reply, so convert it.

Format completed items:
```
- [x] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description} ✅ {YYYY-MM-DD}
```

Format cancelled / moved items:
```
- [-] [Slack thread]({thread_url}) - [[👤First Last]] - {brief description} ❌ {YYYY-MM-DD}
	- ➡️ Moved to {where, linked}
```

Sub-bullet comments are tab-indented and start with an emoji: `➡️` moved or not ours, `📋` tracked in a ticket.

Always link the person's name as `[[👤First Last]]`.

**Skip** any thread whose parent ID (`p{thread_ts without the dot}`) already appears in the doc.

#### PR review scope

On-call reviews only cloud-inventory changes under `organizations/` and the Terraform modules those configs source. Before classifying any PR thread, list its files (`gh pr view N -R ddoghq/cloud-inventory --json files -q '.files[].path'`). It's **in scope** when any file is:
- under `organizations/`, or
- under `terraform-modules/{name}/` for a module sourced from `organizations/`. As of 2026-11: `aws-chaos-cloud`, `aws-cloud-perimeter-fed`, `aws-gov-service-allowlist`, `aws-gov-valid-instance-types`, `aws-iam-common`, `aws-iam-human`, `aws-saml`, `aws-sso-account-assignments`, `aws-tfstate`, `azure-automated-log-forwarding`, `azure-emissary-ad-group`, `azure-iam-human`, `gcp-iam-human`, `gcp-log-forwarding`, `gcp-log-pubsub-export`, `gcp-organization`, `gcp-organization-iam`, `gcp-project`, `gcp-restricted-policies`, `nebius-*`, `oci-iam-human-sso`, `oci-tfstate`. For any other module, run `gh search code "terraform-modules/{name}" --repo ddoghq/cloud-inventory --json path`; it counts only if a hit sits under `organizations/`.

Everything else belongs to another team: `managed-iam/`, `domains/`, `datacenters/`, and other repos (dd-source, corpit-lambdas). Find the owner in cloud-inventory's `.github/CODEOWNERS` (the last matching pattern wins). CODEOWNERS names `@ddoghq/compute-cloud-accounts` on a few paths outside `organizations/` (e.g. `terraform_deployment_permission_sets.tf`, `logging-bucket`); those are still out of scope, so name the other owner listed.

- **Mixed PR**: review only the in-scope files, and name them in the description.
- **Out of scope**: `[-]` ending `❌ {date of the request or crosspost}`, with the sub-bullet `➡️ Not ours: only touches {paths}; {owning team} reviews it`.
- The scope covers PR reviews only. Access questions, account creation and deletion, and other asks in the thread stay ours.

### 4c: Refresh existing open items

Existing lines with status `[ ]`, `[?]`, `[/]` or `[*]` are open. Check each one and update it in place:

- **CLOUDA/CAPA ticket lines:** query the key (`key = CLOUDA-XXXX`, fields `status`, `assignee`, `resolutiondate`, `updated`). If it's Done, change the line to `- [x] … - Done ({assignee first name}) ✅ {resolution date, else updated date}`.
- **Slack thread lines:** re-read every thread whose root had activity in the window (the roots collected in 4a/4b). Use the Classify rules above:
  - Completed → change the status to `[x]`, rewrite any "waiting on…" / "needs our review" tail to say what happened (e.g. "we approved and it merged 11/10"), and end the line with `✅ {date it was resolved}`.
  - Moved → change the status to `[-]`, drop the "waiting on…" tail, end the line with `❌ {date}`, and add a `➡️ Moved to …` sub-bullet.
  - Still open but with new facts (a ticket was created, part of it moved) → keep the status and add a sub-bullet comment.
- For PR threads, check the PR state (`gh pr view N -R ddoghq/cloud-inventory --json state,reviewDecision,mergedAt,files`) before marking done, and re-apply the PR review scope: an open PR line that's out of scope becomes `[-]` with a `➡️ Not ours` sub-bullet, and any "needs our review" text in its existing sub-bullets is dropped.
- Use the date of the resolving event (approval, merge, acknowledgement, crosspost), not today's date.
- Keep the existing sub-bullets and any status Saje set by hand (e.g. `[*]` "Reviewing now") unless the thread shows it finished.

---

## Step 5: Write to the Document

Insert items under `# Account Requests Tasks`. Each provider section (`## AWS`, `## GCP`, `## Azure`) keeps this order:

1. **CLOUDA tickets**, directly under `## {Provider}` and above any `###` sub-heading. Insert new ones after the last existing CLOUDA line, not at the end of the section.
2. **`### Slack Mentions`**: `cloud-accounts-support` threads. Create it after the CLOUDA list if it doesn't exist; append at the end of this sub-section, above `### Quotas`.
3. **`### Quotas`**: CAPA tickets and `cloud-quota` threads. Create it last in the provider section if it doesn't exist; append at its end, above the next `##`/`#` heading.

Append new items only within the target sub-section. Change existing lines only as Step 4c describes, and never remove them. Leave `# Handoff`, `## Feedback`, and `# Last Week` (after initial create) untouched for manual entry.

---

## Step 6: Report

Print a brief summary:
- New JIRA tickets added (CLOUDA and CAPA, by provider)
- New Slack threads added (`cloud-accounts-support` mentions and `cloud-quota` requests)
- Existing items checked off (`[x]`) or cancelled as moved (`[-]`), with where they went
- PR reviews marked not ours, with the owning team, so Saje can redirect the requester
- Anything needing attention (unanswered questions, ambiguous provider, missing info)
