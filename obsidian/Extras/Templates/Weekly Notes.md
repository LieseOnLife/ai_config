<%*
const raw = await tp.system.prompt("Date in the week to plan (YYYY-MM-DD)", tp.date.now("YYYY-MM-DD"));
const anchor = window.moment(raw || tp.date.now("YYYY-MM-DD"), "YYYY-MM-DD", true);
if (!anchor.isValid()) throw new Error("Weekly Notes requires YYYY-MM-DD.");
const monday = anchor.clone().startOf("isoWeek"), sunday = monday.clone().add(6, "days");
const isoYear = monday.isoWeekYear(), isoWeek = String(monday.isoWeek()).padStart(2, "0");
const dateStart = monday.format("YYYY-MM-DD"), dateEnd = sunday.format("YYYY-MM-DD");
const weekName = `${isoYear}-W${isoWeek}`, weekTag = `#week/${weekName}`;
const title = `${isoYear}-w${isoWeek}-${monday.format("MM-DD")}`, folder = "Calendar/Weekly Notes";
const current = tp.file.path(true);
const existing = app.vault.getMarkdownFiles().find(file =>
  file.path.startsWith(`${folder}/`) && app.metadataCache.getFileCache(file)?.frontmatter?.date_start === dateStart && file.path !== current);
if (existing) throw new Error(`Weekly note already exists: ${existing.path}`);
if (current !== `${folder}/${title}.md`) await tp.file.move(`/${folder}/${title}`);
-%>
---
date_start: <% dateStart %>
date_end: <% dateEnd %>
week: <% weekName %>
type: weekly_notes
template: "[[Weekly Notes]]"
tags: [🐶, weekly, week/<% weekName %>]
goals_confirmed: false
goals_confirmed_at:
last_planning_refresh:
last_morning_sync:
last_weekly_close:
sources_checked: {jira: null, obsidian_tasks: null, slack_summaries: null, slack_gap_scan: null, calendar_capacity: null}
created: <% tp.file.creation_date("YYYY-MM-DD HH:mm:ss") %>
---
# Weekly Dashboard
>[!summary] <% dateStart %> to <% dateEnd %>
>**Capacity:** · **Goals confirmed:** No · **Last refreshed:** · **Unavailable sources:**
>[!check]- Source Status
>**Jira:** · **Projects/TODOs:** · **Daily Slack Summaries:** · **DM/Slack gap:** · **Calendar:** · **Friday close:**
## 🎯 Outcomes
### 1.
- **Done when:** · **Supports:** · **Risk:**
### 2.
- **Done when:** · **Supports:** · **Risk:**
### 3.
- **Done when:** · **Supports:** · **Risk:**
## 📌 Committed This Week
### Jira and Projects
### Live Weekly Tasks from Other Notes
```tasks
ignore global query
tags include <% weekTag %>
path does not include {{query.file.path}}
path does not include Extras/Templates
sort by status
sort by priority
sort by due
```
## 🔴 Waiting / Blocked
## 🌱 New & Unplanned
### Jira
### Projects
### Unfocused TODOs to Triage
```tasks
ignore global query
not done
NOT (tags include <% weekTag %>)
path does not include {{query.file.path}}
path does not include Extras/Templates
filename does not include Slack Summary
sort by urgency
```
### Slack from Daily Summaries
### DMs and Targeted Slack Gap Scan
## 🔄 Plan Changes
## 🚫 Not This Week
## 📅 Notes from This Week
```base
views:
  - type: table
    name: Daily Notes
    filters:
      and:
        - type == "daily_note"
        - date(file.basename) >= this.file.properties.date_start
        - date(file.basename) <= this.file.properties.date_end
    order: [file.name, weekday]
  - type: table
    name: Weekly Operations
    filters:
      and:
        - week == this.file
        - file.inFolder("Datadog/Ops")
    order: [file.name, type]
```
# Weekly Review
## Outcome Review
## Wins
## Unexpected Work
## Friday Close Snapshot
- **Closed at:** · **Completed:** · **Carried forward:** · **Deferred:** · **Cancelled:**
## Carry Forward
