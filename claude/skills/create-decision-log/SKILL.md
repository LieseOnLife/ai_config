---
name: create-decision-log
description: Create a decision log for the Cloud Accounts team in Confluence. Use when creating decision logs, documenting architectural decisions, or recording team decisions.
---

# Skill: Create Decision Log

Create a decision log for the Cloud Accounts team in Confluence using the team's live template.

## Reference
- **Decision Logs Page**: https://datadoghq.atlassian.net/wiki/spaces/CLOUDA/pages/5176984670/Decision+Logs
- **Template Page**: https://datadoghq.atlassian.net/wiki/spaces/CLOUDA/pages/5176689724/0000+Template

The Decision Logs page has a "Create a New Decision Log" button that creates from the template. This skill replicates that behavior via API.

## Inputs Required
- `--topic`: Brief description of the decision
- `--source-url`: URL to source material - Slack thread, Jira ticket, or RFC (optional)

## Process

### Step 1: Fetch Current Template (Storage Format)
```
mcp__atlassian__getConfluencePage(
  cloudId: "datadoghq.atlassian.net",
  pageId: "5176689724",  # 0000 Template page
  contentFormat: "adf"   # Use ADF to preserve status macros exactly
)
```
This fetches the template with all Confluence macros (status lozenges, mentions, etc.) intact.

### Step 2: Determine Next Decision Log Number
```
mcp__atlassian__getConfluencePageDescendants(
  cloudId: "datadoghq.atlassian.net",
  pageId: "5176984670",  # Decision Logs folder
  limit: 50
)
```
Find the highest numbered decision log (e.g., 0035) and increment (0036).

### Step 3: Create Decision Log FROM Template
```
mcp__atlassian__createConfluencePage(
  cloudId: "datadoghq.atlassian.net",
  spaceId: "3924951952",  # CLOUDA space
  parentId: "5176984670",  # Decision Logs folder
  title: "XXXX - <Topic>",
  body: <template body exactly as fetched>,
  contentFormat: "adf"   # Preserve the status macros
)
```
This creates the page with all status palettes and macros intact, just like clicking the "Create from template" button.

### Step 4: Update With Content
```
mcp__atlassian__updateConfluencePage(
  cloudId: "datadoghq.atlassian.net",
  pageId: <new page id>,
  body: <updated content>,
  contentFormat: "markdown"
)
```
Update the Decision, Context, Problem, and Proposal sections with the actual content while preserving the template structure.

**Important**: When updating, preserve:
- The status palette lines (📝 DRAFT, 👀 IN REVIEW, 🎉 Approved, ❌ REJECTED, ‼️ SUPERSEDED)
- The reviewer status palette (NOT REVIEWED, 📝 IN PROGRESS, ❌ REJECTED, ✅ Approved)
- The reviewer table structure with `<@ Reviewer Name>` placeholders
- Set initial status to `👀 IN REVIEW`

### Step 5: Add Source Reference (if applicable)
If content came from Slack, Jira, or other source, add a reference at the bottom:
```
---
_Source: [Slack thread](url) - Date_
```

## Key IDs
- CLOUDA Space ID: `3924951952`
- Decision Logs Parent: `5176984670`
- Template Page: `5176689724`

## Why This Approach
- Creates from template preserves all Confluence macros (status lozenges, etc.)
- Users can click on status lozenges to change them
- Template can be updated by the team without updating this skill
- Matches the behavior of the "Create a New Decision Log" button on the Decision Logs page
