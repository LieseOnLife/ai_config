---
name: cloud-admin-process
description: Process Cloud Admin JIRA tickets by creating PRs in cloud-inventory, getting Saje's review, then posting to Slack for teammate approval. Use when user invokes /cloud-admin-process or asks to process cloud admin tickets, create access request PRs, work through the cloud admin queue, or handle CLOUDA tickets.
---

# Cloud Admin Ticket Processor

Works through open Cloud Access Request tickets from the current week's Cloud Admin Obsidian page. For each ticket: assigns Saje, sets it in-progress in Jira, creates the Terraform PR, waits for review, then posts to `#cloud-accounts-team` for approval.

## Config

- **Obsidian Ops folder**: `/Users/saje.liese/Obsidian/Tech-2/Datadog/Ops/`
- **cloud-inventory repo**: `/Users/saje.liese/go/src/github.com/DataDog/cloud-inventory`
- **Slack channel for approval**: `#cloud-accounts-team` (private, channel ID: `C074GJ87RML`)
- **Jira project**: CLOUDA

---

## Step 1: Load Open Tickets

1. Find the current week's Cloud Admin page (Monday of current week, same logic as `/cloud-admin`)
2. Read it and extract all lines matching `- [ ] [CLOUDA-XXXX](...)` under `## Permissions`
3. Present the full list to Saje and ask: *"Which of these do you want to process today?"*

Separate the list into two groups when presenting:
- **Access requests** — human-filed tickets with a team/person description
- **Revoke tickets** — auto-generated "Revoke access for CLOUDA-XXXX" entries

Saje picks any combination. Then process them one by one in the order chosen.

---

## Step 2: For Each Selected Ticket

### 2a. Fetch & Assign

Via Atlassian MCP:
1. Fetch full ticket details (summary, description, reporter, comments, linked issues)
2. Self-assign the ticket to Saje
3. Transition the ticket status to **In Progress**

### 2a-pre. Check for recent ticket activity

Before doing any work, fetch and read all comments on the ticket. If there are recent comments from Saje (the current user) indicating the ticket was redirected, declined, or resolved through discussion — stop, note the outcome in Obsidian, and move to the next ticket. Do not create a PR for a ticket that has already been handled.

### 2b. Extract the 5 W's

Parse the ticket to fill in:

| Field | Source |
|---|---|
| **Who** | Reporter name + team; look for pack or team name in the description. Prefer pack access (see managing-human-access skill for pack vs. team guidance). |
| **Where** | Cloud provider (AWS/GCP/Azure/OCI) + account/project/subscription name or ID |
| **What** | The specific access being requested — resources + actions |
| **When** | Permanent or temporary; check for expiry date in description |
| **Why** | Business justification from description |

If any field is unclear from the ticket, ask Saje before proceeding.

### 2c. Create the Terraform Changes

**For access request tickets:**

Follow the `managing-human-access` skill at `/Users/saje.liese/go/src/github.com/DataDog/cloud-inventory/.claude/skills/managing-human-access/SKILL.md` exactly — read the relevant cloud provider AGENTS.md, make the Terraform changes, follow all the principles of access and per-provider guidelines defined there.

Key points:
- Work in the cloud-inventory repo at the path above
- Prefer pack/team access over individual access (per managing-human-access principles)
- Read `organizations/{aws|gcp|azure|oci}/AGENTS.md` before making changes
- Never read entire large files; Grep first, then read precisely

**For revoke tickets:**

1. Fetch the parent ticket (linked as "Revoke access for CLOUDA-XXXX") from Jira
2. Read the parent ticket to understand what access was originally granted and where
3. If there's a PR linked in the parent ticket, look at what Terraform changes were made
4. Create the reversal: remove the pack/team/individual from the role assignment(s) added in the original PR
5. Follow the same AGENTS.md guidance for structure

### 2d. Create the PR

Create a branch and PR in cloud-inventory using the `creating-prs` skill at `.claude/skills/creating-prs/SKILL.md`.

**PR title format** (from managing-human-access):
```
Added/Removed/Modified {role} for {pack/team/individual} in {account name}
```

**PR description format**:
```markdown
## Summary
Brief description of the access change.

## Access Details
- **Who**: {pack/team/individual}
- **What**: {specific access}
- **When**: {permanent / until YYYY-MM-DD}
- **Where**: {account/project/subscription}
- **Why**: {justification from ticket}

## JIRA
[CLOUDA-XXXX](https://datadoghq.atlassian.net/browse/CLOUDA-XXXX)

## Code Changes Made
- {list of files changed}

## Checklist
- [ ] I have received a +1 from my team

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 2e. Pause for Review

Present to Saje:
- PR URL
- Summary of the Terraform changes made
- Any concerns or edge cases noticed

Ask: *"Does this look right? Approve to post to #cloud-accounts-team, or let me know what to change."*

Do not proceed until Saje explicitly approves.

### 2f. Post to Slack

After approval, post to `#cloud-accounts-team`:

```
:cloud: *CLOUDA-XXXX* — {one-line summary of the request}

*PR:* {PR URL}
*Requested by:* {reporter name} ({team/pack})
*Access:* {brief what + where}

cc: {reporter's @slack handle if known}

Needs a +1 before merge :slightly_smiling_face:
```

### 2g. Update the Obsidian Doc

On the ticket's line in the Obsidian page, append the PR link:

```
- [ ] [CLOUDA-XXXX](jira-url) - Team (Reporter) - status - [PR](pr-url)
```

Leave the checkbox as `[ ]` — Saje marks it done when the PR is merged.

Also add a comment on the Jira ticket with the PR URL via Atlassian MCP.

---

## Step 3: Continue

After each ticket is done, move to the next selected one. When all are processed, print a brief summary:
- Tickets processed
- PRs created (with links)
- Any that were skipped or need follow-up
