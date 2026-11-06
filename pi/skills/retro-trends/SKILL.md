---
name: retro-trends
description: Write a "📈 Trends since last retro" section into a retro meeting note, covering the window since the previous retro in the same series. It checks follow-through on the last retro's action items, Slack Summary markers, support/on-call load, incidents, weekly outcomes and themes that keep coming up in meetings. /morning calls it when it creates a retro note; you can also run it on demand for any `📣 … Retro …` note.
---
# Retro Trends
## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Retro notes: `Calendar/Meetings/📣 YYYY-MM-DD - <title>.md` where the title contains `retro` (case-insensitive).
- Slack Summaries: `Calendar/Daily Notes/YYYY-MM-DD - Slack Summary.md`. A file named for day D covers the day(s) **before** D.
- Weekly pages: `Calendar/Weekly Notes/` (`type: weekly_notes`, `date_start`/`date_end`).
- On-call / Cloud Admin notes: `Datadog/Ops/🌧️YYYY-MM-DD - Cloud Admin.md`, `Datadog/Ops/🌧️YYYY-MM-DD - Cloud Accounts Primary Oncall.md`.
- Jira project: `CLOUDA`. Support channel: `cloud-accounts-support` (`C08MPTABY23`). CAVM alerts: `cavm-ops` (`C06UGQPFU5A`).

## 1. Resolve the Series and Window
1. **Target:** the retro note you were given. Its `date:` frontmatter is the target date `T`.
2. **Series key:** take the filename, drop `📣 YYYY-MM-DD - ` and any leading `📢`, drop a trailing ` with <…>`, then lowercase and collapse whitespace. For example, `📣 2026-11-06 - Cloud Accounts Retro with Cloud Accounts team` becomes `cloud accounts retro`, which matches the older `📣 2026-07-17 - Cloud Accounts Retro`.
3. **Previous retro `P`:** the newest note in the same series with a date before `T`. **The retro before that, `PP`,** sets the comparison window.
4. **Window:** `P` through `T−1` inclusive. That's the Slack Summary files dated `P+1` through `T`, plus every other source filtered to those dates. **Previous window:** `PP` through `P−1`.
   - Slack Summaries are written on **weekdays only**: Monday's file covers the weekend. A missing Saturday or Sunday file is expected. Report only missing **weekday** files, as a single line in the header.
5. **Length:** calendar days `T − P` and working days (Mon–Fri). Windows often differ in length, so compare counts **per working day**. For Slack-marker rates, divide by the number of weekday summary files that exist in the window, not by the window's working days.
6. **No `P`** (first retro in a series): use the 14 days before `T`, label it "first retro in this series", and leave out the Previous column.

## 2. Gather Read-only Evidence
Run the six sources in parallel, with one subagent per source; each one returns facts plus links, not prose. For every claim, keep its link: Slack permalink, Jira key, PR, incident, or the `[[note]]` it came from. Record any source that's unavailable; a failed source must not block the others.

**Time budget: the whole skill should take about 15 minutes.** Each source subagent gets an 8-minute budget and returns what it has, marked `partial`, when the budget runs out. Prefer counts from the vault and from single queries over paging through Slack history:
- **Never page through channel history** (`slack_read_channel`) for either window. Use one search per count and read threads only for samples.
- **The previous window is counts-only.** It comes from vault files and JQL. Don't sample Slack, read threads, or search incidents for it.

**A. Last retro follow-through**
- Action items come from `P`'s note: Zoom/Gemini *Next steps*, `## 🤖AI notes`, `- [ ]`/`- [i]` lines, plus any `💬` note that links `[[P's basename]]` (e.g. "Retro Tasks in cloud-accounts-team").
- If `P`'s note has no action items, fetch its recap instead. Search Gmail with `from:no-reply@zoom.us subject:"Meeting assets for" <raw calendar title>` dated `P`, or the Gemini doc for that date. If neither exists, write a single `⏸ no evidence` row: "recap unavailable". Don't infer that there were no actions, and don't search further.
- For each item, find its status from linked Jira keys (Atlassian MCP), checkbox state, PR state (`gh`), and Slack mentions in the window.
- Status values: ✅ done · 🔄 in progress · ⏸ no evidence · ❌ dropped or cancelled. "No evidence" is a finding; don't guess.

**B. Slack Summary markers** (window files, and the previous window's files for comparison)
- Count `- [f]`, `- [w]`, `- [k]`, `- [I]`, `- [!]` and `- [?]` lines, only inside callouts (lines starting with `>`).
- Group items into themes by topic (e.g. "CAVM pooling", "cloud-inventory CI", "AppGate"). Keep themes that show up on 2 or more **distinct dates**, and note which channels they came from.

**C. Support / on-call load** (window vs previous window)
- CLOUDA: JQL `project = CLOUDA AND created >= "<start>" AND created < "<end+1>"` gives the count created. The same query with `resolved` gives the count resolved, and `AND statusCategory != Done` gives the count still open. Report counts only, plus the top 3 categories from summary keywords, components or labels. **Don't list ticket keys** beyond one example per category.
- #cloud-accounts-support, **current window only:** one search, `in:<#C08MPTABY23> after:<start−1> before:<end+1>`, for the count of top-level threads. Then sample 15 threads and estimate the share that were redirects to other teams (Cloud Security, IT/Beyond Identity, Procurement) versus real Cloud Accounts work.
- On-call: the Primary Oncall / Cloud Admin notes and the `Ops Review & Oncall Handoff` meeting notes dated in the window. Look for handoff themes and anything that kept coming back.

**D. Incidents**
- `IR-*` / `app.datadoghq.com/incidents/*` links in the window's Slack Summaries and meeting notes, plus **one** Datadog `search_datadog_incidents` query for Cloud Accounts / CAVM incidents created in the current window.
- CAVM alerts: count alert items in the `cavm-ops` section of the Slack Summaries, for both windows; don't read the channel. **Repeat offenders** are the same monitor, workflow or activity alerting on 2 or more distinct dates.

**E. Weekly pages**
- Each page belongs to the window that holds the **majority of its Mon–Fri days**. A week that spans a retro is counted once, and the current week counts toward the current window.
- For each approved outcome, report met, partly met or missed, using *Outcome Review* / *Friday Close Snapshot* (or the live state for the current week). Also pull *Wins* and *Unexpected Work*, and anything carried forward 2 or more times.

**F. Meeting AI notes**
- `## 🤖AI notes` sections and `💬` note summaries dated in the window. The unit is the **distinct date**: keep themes raised on 2 or more distinct dates (e.g. "testing/validation", "reporting lines"), and include who raised them.

## 3. Write
- **Placement:** at the end of the target note's `# Overview` section, after Saje's own notes and **before** any `## 🤖AI notes` or the next `#` heading, so the parent's `#Overview` embed shows it. Never change existing content.
- **Idempotent:** if `## 📈 Trends since last retro` already exists, skip it unless Saje asked for a refresh. A refresh replaces only that section.
- **Style:** short, plain sentences. Refer to Saje as "you" and use `[[👤First Last]]` for people. Every bullet and table row links its evidence, with **at most 2 links each**. Synthesize; don't re-list items. Write real dates, never the `P`/`T`/`PP` labels. Caveats belong only in the header's Missing list, not in each bullet. Plain bullets only; this is prep material, not a task list. Saje's own follow-ups are the only exception: write those as `- [ ] … #week/YYYY-Www ➕ YYYY-MM-DD`.
- **Length caps:** at most 5 headlines of 30 words or fewer each, the 7 table rows shown below, at most 5 recurring themes (ranked by distinct dates), at most 5 wins, and at most 4 topics. The whole section should fit on roughly one screen.

```markdown
## 📈 Trends since last retro
_[[📣 YYYY-MM-DD - …|MM-DD retro]] → MM-DD (yesterday) · N days, W working days. Compared with MM-DD → MM-DD (W′ working days), per working day. Missing: …_

### Headlines
- 3–5 biggest shifts, each with a number and a direction (e.g. "Fires ↑ 9 vs 4 (0.6 vs 0.2 per day), mostly cloud-inventory CI").

### Last retro follow-through
|Action|Owner|Status|Evidence|
|---|---|---|---|
|…|[[👤…]]|✅ / 🔄 / ⏸ / ❌|[CLOUDA-…](…) · [thread](…)|

### By the numbers
Table cells hold numbers only. Put links in the Evidence column, at most 2 per row.

|Signal|This window|Previous window|Per working day|Trend|Evidence|
|---|---|---|---|---|---|
|Fires `[f]`|…|…|… vs …|↑ / ↓ / →|…|
|Wins `[w]` · Key decisions `[k]` · Ideas `[I]`|…|…|…|…|…|
|Asks of you `[!]` / `[?]`|…|…|…|…|…|
|CLOUDA created / resolved / still open|…|…|…|…|…|
|Support threads (redirect share)|… (x%)|—|…|—|…|
|Incidents · CAVM alert items|…|…|…|…|…|
|Weekly outcomes met|x/y|x/y|—|…|…|

### Recurring themes
- **Theme**: N mentions on D days across sources; one line on the pattern — [example](…) · [example](…)

### Wins
- Top 3–5, linked.

### Suggested retro topics
- 2–4 discussion prompts drawn from the above (repeat offenders, stalled follow-through, load shifts). Each one cites the row or theme it comes from.
```

## 4. Report
Return the target note, the window and its length, sources used or missing, the headline bullets, and any follow-up `- [ ]` items you created.
