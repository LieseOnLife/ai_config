---
name: snippet
description: Generate weekly snippets for Obsidian and Confluence. Pulls from Slack activity and JIRA, prompts for gaps, writes to the weekly note, then posts to Confluence as a blog post after confirmation.
---

# Skill: Create Weekly Snippet

Generate a weekly snippet covering major accomplishments, meetings, things learned, and reading.
Auto-pull from Slack and JIRA, prompt for gaps, write to the Obsidian weekly note, then post to Confluence.

## Step 1: Compute Week Metadata

Run this to get all week details:

```bash
python3 -c "
from datetime import date, timedelta
today = date.today()
monday = today - timedelta(days=today.weekday())
iso = today.isocalendar()
year, week = iso[0], iso[1]
sunday = monday + timedelta(days=6)
print(f'YEAR={year}')
print(f'WEEK={week}')
print(f'MONDAY={monday.strftime(\"%Y-%m-%d\")}')
print(f'SUNDAY={sunday.strftime(\"%Y-%m-%d\")}')
for i in range(5):
    d = monday + timedelta(days=i)
    print(f'DAY{i}={d.strftime(\"%Y-%m-%d\")}')
"
```

From the output:
- **File name**: `{YEAR}-w{WEEK}-{MONDAY[5:]}.md` e.g. `2026-w16-04-13.md`
  (Month-day portion only: `MONDAY` without year, replacing `-` → keep as-is → format `MM-DD`)
  Full: `YEAR-wWEEK-MM-DD.md` where MM-DD comes from MONDAY
- **Obsidian path**: `/Users/saje.liese/Obsidian/Tech-2/Calendar/Weekly Notes/{filename}`
- **Confluence title**: `w{WEEK}: {MONDAY} Snippets` e.g. `w16: 2026-04-13 Snippets`
- **Date range for searches**: MONDAY through SUNDAY (inclusive)

## Step 2: Gather Data in Parallel

Run all three in parallel:

### 2a. Slack — Own Messages This Week
Use `slack_search_public_and_private` with:
```
from:<@U01D2L9K04T> after:{MONDAY-1day} before:{SUNDAY+1day}
```
(Use day before MONDAY and day after SUNDAY to ensure full week coverage.)

For long threads where Saje participated, use `slack_read_thread` to get full context.

Look for:
- Work done, decisions made, problems solved
- PRs created/reviewed/merged
- Architecture discussions
- People Saje had notable exchanges with (for Conversations section)

### 2b. JIRA — CLOUDA Tickets This Week
Use `mcp__plugin_atlassian_atlassian__search` (or `searchJiraIssuesUsingJql`) with JQL:
```
project = CLOUDA AND (updated >= "{MONDAY}" OR created >= "{MONDAY}") AND assignee = currentUser() ORDER BY updated DESC
```
Look for tickets Saje worked on, commented on, or transitioned this week.

### 2c. Check Existing Weekly Note
Read the Obsidian weekly note at the computed path. Check:
- Does the file exist?
- If yes, does it already have content under `# Snippets`?

If `# Snippets` already has substantive content, show it to the user and ask:
> "The weekly note already has snippets content. Do you want to (a) replace it, (b) append to it, or (c) cancel?"

## Step 3: Prompt for Gaps

Ask the user in a **single message** with all questions at once:

> "I've gathered your Slack and JIRA activity for w{WEEK} ({MONDAY} – {SUNDAY}). A few quick prompts to fill in the gaps:
>
> 1. **Things learned** — anything you learned this week (technical, process, domain knowledge)?
> 2. **Reading** — any articles, docs, books, or RFCs you read?
> 3. **Anything else** — notable conversations, random wins, or misc items I might have missed?"

Wait for the user's response before proceeding.

## Step 4: Synthesize Snippets

Organize the week's activity into **named project sections** based on what the work actually was — not a rigid template. Use the project/area names that make sense for the week.

**How to pick section names**: Group by the actual projects or areas you were in. Common ones at Saje's current work:
- `CAVM` — Cloud Account Vendor Management work
- `Tackle / AWS Partner Central` — Sales/partner integration work
- `ddtool` — CLI tool work
- `SDM` — Service delivery manager work
- `Leo` — Leo agent/automation work
- (Use whatever names fit the actual week — don't force categories that don't apply)

**Fixed trailing sections** (always include if there's content):
- `Conversations` — Notable 1:1s, architecture discussions, cross-team collabs
- `Things Learned` — From Step 3 prompt
- `Reading` — From Step 3 prompt
- `All the Other Stuff` — Misc items that don't fit elsewhere

**Format for each section**:
```markdown
### Project Name
- Accomplished X — [PR/ticket link](url) or [thread](slack-permalink)
- Helped Y figure out Z — [thread](slack-permalink)
```

Keep bullets concise — this is a snippet, not a journal. One line per notable item.
Skip links when there's nothing worth linking to.

## Step 5: Write to Obsidian

### If the weekly note does NOT exist:

Create it with the full template:

```markdown
---
date_start: {MONDAY}
date_end: {SUNDAY}
type: weekly_notes
template: "[[Weekly Notes]]"
---
# Goals

# Weekly Reflections
- Make a separate out of the week
- Review Reflections and take notes
- Time Box it!  1 Hour Max

## Reading


# Snippets

{SYNTHESIZED_SNIPPET_CONTENT}

# Daily Reflections

## Monday
![[{DAY0}#Reflections]]

## Tuesday
![[{DAY1}#Reflections]]

## Wednesday
![[{DAY2}#Reflections]]

## Thursday
![[{DAY3}#Reflections]]

## Friday
![[{DAY4}#Reflections]]

```

### If the weekly note already exists:

Replace only the `# Snippets` section content. Leave everything else (Goals, Weekly Reflections, Daily Reflections) unchanged.

To update: read the file, find the `# Snippets` heading, replace everything between it and the next `#`-level heading (or end of file) with the new snippet content. Use the Edit tool.

## Step 6: Wait for Review

After writing, tell the user:

> "Snippets written to `Calendar/Weekly Notes/{filename}`. Take a look in Obsidian and let me know when you're happy with it — I'll post it to Confluence as a blog post."

Wait for the user's confirmation before Step 7. If they want changes, make them and wait again.

## Step 7: Post to Confluence as Blog Post

Use `mcp__plugin_atlassian_atlassian__createConfluencePage` with:
- `cloudId`: `66c05bee-f5ff-4718-b6fc-81351e5ef659`
- `spaceId`: `795674614`
- `title`: `w{WEEK}: {MONDAY} Snippets`
- `contentType`: `blog`
- `contentFormat`: `markdown`
- `content`: The synthesized snippet content (just the section bodies — no `# Snippets` heading, no daily reflections)

**Do NOT include** the Obsidian-specific content (daily note embeds, Goals, Weekly Reflections) in the Confluence post. Only the snippet sections.

After posting, share the Confluence page URL with the user.

## Key Reference Values

| Item | Value |
|------|-------|
| Saje's Slack user ID | `U01D2L9K04T` |
| Confluence Cloud ID | `66c05bee-f5ff-4718-b6fc-81351e5ef659` |
| Personal Space ID | `795674614` |
| Personal Space Key | `~199081059` |
| Obsidian vault | `/Users/saje.liese/Obsidian/Tech-2/` |
| Weekly notes path | `Calendar/Weekly Notes/` |
