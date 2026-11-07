---
name: retro-trends
description: Write a "📈 Trends since last retro" section into a retro meeting note, covering the window since the previous retro in the same series. It checks follow-through on the last retro's action items, Slack Summary markers, support/on-call load, incidents, weekly outcomes and themes that keep coming up in meetings. /morning calls it when it creates a retro note; you can also run it on demand for any `📣 … Retro …` note.
---
# Retro Trends
## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Retro notes: `Calendar/Meetings/📣 YYYY-MM-DD - <title>.md` where the title contains `retro` (case-insensitive).
- Slack Summaries: `Calendar/Daily Notes/YYYY-MM-DD - Slack Summary.md`. A file dated D covers the day(s) **before** D. Files exist on weekdays only; Monday's covers the weekend.
- Weekly pages: `Calendar/Weekly Notes/` (`type: weekly_notes`, `date_start`/`date_end`).
- On-call / Cloud Admin notes: `Datadog/Ops/🌧️YYYY-MM-DD - Cloud Admin.md`, `Datadog/Ops/🌧️YYYY-MM-DD - Cloud Accounts Primary Oncall.md`.
- Jira project: `CLOUDA` (cloudId `datadoghq.atlassian.net`).

## 1. Resolve the Series and Window
1. **Target:** the retro note you were given. Its `date:` frontmatter is the target date `T`.
2. **Series key:** take the basename without `.md`, drop `📣 YYYY-MM-DD - `, any leading `📢`, and a trailing ` with <…>` or ` (from #…)`, then lowercase and collapse whitespace. For example, `📣 2026-11-06 - Cloud Accounts Retro with Cloud Accounts team` becomes `cloud accounts retro`, which matches `📣 2026-07-17 - Cloud Accounts Retro`. Two notes with the same non-empty `meeting:` link are also the same series.
3. **Previous retro `P`:** the newest note in the same series dated before `T`. **`PP`** is the one before `P`.
4. **Windows:** current = dates `P` through `T−1`; previous = dates `PP` through `P−1`.
   - Slack Summaries: read the files dated `P+1` through `T` (previous window: `PP+1` through `P`).
   - Every other source: filter to the window's own dates. Exclude `P`'s retro note itself from source F.
   - A missing weekend file is expected. List missing **weekday** files once, in the header's Missing line.
5. **Rates:** Slack-marker rates are **per summary file** (divide by the number of files that exist). Every other rate is **per working day** (Mon–Fri). The header gives both denominators.
6. **Missing history:**
   - **No `P`** (first retro in the series): the current window is the 14 days before `T`. Omit *Last retro follow-through*, the Previous/Trend columns, and the directions in Headlines. Label the header "first retro in this series".
   - **No `PP`** (second retro in the series): omit the Previous/Trend columns and say "no earlier window to compare" in the header.

## 2. Gather Read-only Evidence
**Budget: about 15 minutes.** Use at most **three lanes** in parallel. Lanes are subagents when this skill runs at the top level; when it is already running as a subagent (e.g. `/morning` Step 6.6), do them yourself, in order. Every claim keeps its link: Slack permalink, Jira key, PR, incident, or the `[[note]]` it came from. Each lane returns every relevant item **with its date and link**, not themes already filtered; the synthesis groups themes across sources (§3). Record any source that's unavailable; a failure must not block the other lanes.
- **Vault lane** (no network): B, the vault parts of C and D, E, F.
- **Jira/Datadog lane:** the CLOUDA queries in C and the incident query in D.
- **Follow-through lane:** A. This is the only lane allowed Slack calls: at most **one** combined search, and only for items the vault can't settle.

Never page through Slack channel history.

**A. Last retro follow-through**
- Action items come from `P`'s note: Zoom/Gemini *Next steps*, `## 🤖AI notes`, and checkbox lines in any state (`- [ ]`, `[x]`, `[/]`, `[-]`, `[!]`, `[?]`, `[i]`). Also include any `💬` note that links `[[<P basename>` (aliased links `[[…|…]]` count too).
- If `P`'s note has none, fetch the recap instead. Search Gmail with `from:no-reply@zoom.us subject:"Meeting assets for" after:<P−1> before:<P+2>` and match it on the series title words. Failing that, search Drive for `name contains 'Notes by Gemini'` around `P`. If neither exists, write a single `⏸ no evidence` row reading "recap unavailable". Don't infer that there were no actions, and don't search further.
- Status for each item: checkbox state first, then linked Jira keys, PR state (`gh`), and vault mentions; the one Slack search is the last resort.
- Status values: ✅ done · 🔄 in progress · ⏸ no evidence · ❌ dropped or cancelled. "No evidence" is a finding; don't guess.

**B. Slack Summary markers** (both windows)
- Count `- [f]`, `- [w]`, `- [k]`, `- [I]`, `- [!]` and `- [?]` lines, only inside callouts (lines starting with `>`).
- Return each marked item with its date, channel and topic.

**C. Support / on-call load**
- **CLOUDA, both windows.** Use `searchResultMode: "count"` for count-only queries.
  - Created: `project = CLOUDA AND created >= "<start>" AND created < "<end+1>"`
  - Resolved: `project = CLOUDA AND resolved >= "<start>" AND resolved < "<end+1>"`
  - Open at window end: the Created query `AND (resolved is EMPTY OR resolved >= "<end+1>")`. This is a point-in-time count, so a re-run gives the same answer.
  - Top 3 categories: one current-window Created query with `searchResultMode: "all"`, `maxResults: 100` and `fields: ["summary","components","labels"]`. Give one example key per category; never list keys beyond that.
- **Support threads, both windows:** count the bullets under `### [cloud-accounts-support]` in the Slack Summaries. For the current window, classify each one as a redirect to another team (Cloud Security, IT/Beyond Identity, Procurement) or as real Cloud Accounts work. Don't call Slack for this.
- **On-call:** the Primary Oncall / Cloud Admin notes and the `Ops Review & Oncall Handoff` notes in each window. Return the handoff items, each with its date.

**D. Incidents and CAVM alerts** (both windows, same method in each)
- **Incidents:** deduplicated `IR-*` / `incident-*` / `app.datadoghq.com/incidents/*` IDs found in the window's Slack Summaries and meeting notes. Add **one** Datadog `search_datadog_incidents` query covering `PP` through `T−1` for Cloud Accounts / CAVM, and split the results at `P` by created date.
- **CAVM alerts:** alert bullets under `### [cavm-ops]` in the Slack Summaries: monitor, workflow or activity failures and warnings. Exclude the routine "CAVM bot requested approval/merge" PR bullets. **Repeat offenders** are the same monitor, workflow or activity on 2 or more distinct dates.

**E. Weekly pages**
- Each page belongs to the window that holds the majority of its Mon–Fri days, so it's counted once.
- Count outcomes only from **closed** weeks (those with *Outcome Review* or *Friday Close Snapshot*). Report them as `met (+partly)/total`.
- For an open current week, mention any outcome already met in Headlines rather than in the count.
- Also pull *Wins* and *Unexpected Work*, and anything carried forward 2 or more times.

**F. Meeting AI notes**
- `## 🤖AI notes` sections and `💬` note summaries dated in the window. Return each topic with its date, the note it came from, and who raised it.

## 3. Synthesize and Write
- **Themes:** group topics across B, C, D and F. Rank them by the count of **distinct dates**, deduplicated across sources, and keep themes with 2 or more.
- **Placement:** at the end of the target note's `# Overview`, after Saje's own notes and **before** `## 🤖AI notes` or any other `##`/`#` heading. This keeps it inside the parent's `#Overview` embed. Never change existing content.
- **Idempotent:** if `## 📈 Trends since last retro` exists, skip unless Saje asked for a refresh. A refresh replaces only the part from that heading up to the next `##` or `#` heading.
- **Read-only prep:** write no checkboxes. Open follow-ups already live in their source notes; link to them.
- **Style:** short, plain sentences. Refer to Saje as "you"; people are `[[👤First Last]]`. Every bullet and table row links its evidence, with **at most 2 links**. Synthesize rather than re-list. Write real dates, never the `P`/`T`/`PP` labels. Caveats go only in the header's Missing line.
- **Length caps:** at most 5 headlines of 30 words or fewer each, the 7 table rows below, at most 5 themes, at most 5 wins, and at most 4 topics. The whole section should fit on roughly one screen.

```markdown
## 📈 Trends since last retro
_[[📣 YYYY-MM-DD - …|MM-DD retro]] → MM-DD · N days, W working days, F summary files. Compared with MM-DD → MM-DD (W′ working days, F′ files). Missing: …_

### Headlines
- 3–5 biggest shifts, each with a number and a direction (e.g. "Fires ↑ 9 vs 4 (0.6 vs 0.2 per summary), mostly cloud-inventory CI").

### Last retro follow-through
|Action|Owner|Status|Evidence|
|---|---|---|---|
|…|[[👤…]]|✅ / 🔄 / ⏸ / ❌|[CLOUDA-…](…) · [thread](…)|

### By the numbers
Table cells hold numbers only. Links go in the Evidence column, at most 2 per row.

|Signal|This window|Previous window|Rate|Trend|Evidence|
|---|---|---|---|---|---|
|Fires `[f]`|…|…|… vs … /summary|↑ / ↓ / →|…|
|Wins `[w]` · Key decisions `[k]` · Ideas `[I]`|…|…|… vs … /summary|…|…|
|Asks of you `[!]` / `[?]`|…|…|… vs … /summary|…|…|
|CLOUDA created / resolved · open at end|… / … · …|… / … · …|created/resolved … vs … /day|…|…|
|Support items (redirect share)|… (x%)|…|… vs … /summary|…|…|
|Incidents · CAVM alert items|… · …|… · …|… vs … /day|…|…|
|Closed-week outcomes met (+partly)/total|…|…|—|…|…|

### Recurring themes
- **Theme**: D distinct dates across sources; one line on the pattern — [example](…) · [example](…)

### Wins
- Top 3–5, linked.

### Suggested retro topics
- 2–4 discussion prompts drawn from the above (repeat offenders, stalled follow-through, load shifts). Each one cites the row or theme it comes from.
```

## 4. Report
Return the target note, the window and its length, sources used or missing, and the headline bullets. Write only to the target note; the caller handles any reminders in the daily note.
