---
name: evening
description: End-of-day close-out for Saje's Tech-2 daily note. Captures last thoughts, logs the day's AI coding sessions (omp, Claude Code, Codex) as 🤖 AI sessions, writes the Reflections summary, and asks keep, reschedule, park or drop about open tasks stuck 3+ days. Use for /evening, "end of day", "wrap up the day", or "close out today". /morning runs the session step alone for weekdays /evening missed.
---

# Evening Close-out

## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Daily note: `Calendar/Daily Notes/YYYY-MM-DD.md`; template `Extras/Templates/Daily Note.md` (read fresh; never inline it here)
- Today's Slack Summary, `Calendar/Daily Notes/YYYY-MM-DD - Slack Summary.md`, covers the days *before* its date, not today.
- Task statuses come from the Obsidian Tasks plugin. Open: `[ ]`, `[/]`, `[\]`, `[<]`, `[?]`, `[!]`, `[*]`. Done: `[x]`, `[X]`, `[>]`. Cancelled: `[-]`. Other letters (`[i]`, `[I]`, `[k]`, `[w]`, `[f]`, `[b]` …) aren't tasks.
- Dates on tasks: `➕` created, `⏳` scheduled, `📅` due, `✅` done, `❌` cancelled.
- Helper: `scripts/other_sessions.py YYYY-MM-DD` (next to this file).

Open tasks carry over by themselves: the daily note's query is `scheduled on or before <today>`. So this skill never copies tasks into tomorrow's note.

## 0. Resolve the day
Run `date`. The target day is today unless the caller passes one (e.g. `/morning` catching up on a missed day). Open its daily note. If it doesn't exist, render the Daily Note template for that date: substitute every Templater tag with literal values and leave no `<%` behind. If the note has no `authorship`, or has `authorship: human`, set `authorship: mixed`.

## 1. Last thoughts (interactive runs only)
Ask: "Anything to add before I close out the day?" Wait for the answer. Add her words, as she wrote them, as bullets under the `# <Weekday> Notes` heading. Don't rewrite them. Skip this step when the caller is `/morning` or the run is headless.

## 2. AI sessions
Collect every AI session that was active on the target day (local time, America/New_York):
1. **omp:** in Python eval, run `rows = await archive.sessions(project="*", limit=200, silent=True)`. The times are UTC: keep the rows whose `created` or `modified` falls on the target day once converted to America/New_York. Use `title` and `row.get("recap")` (the key is missing when there's no recap; a busy day has 30 to 40 sessions). For a row with no recap, run `await archive.session(row["id"], limit=5)` and read its recaps and last prompts. Skip the session running this skill. `archive` exists only in omp: in another harness, skip this source and say so in the report.
2. **Claude Code and Codex:** `python3 <skill-dir>/scripts/other_sessions.py YYYY-MM-DD`. Each line has the first prompt and last reply.
3. **Skip** scripted runs: the same prompt across many sessions, `claude -p` experiments, temporary `*-exp*` folders. Also skip one-question lookups that produced nothing.

Write one bullet per piece of work, not per session. Group sessions about the same PR, ticket or topic together. Each bullet: the session's emoji and title (e.g. `🛂 SCP`), then the goal and the outcome in one or two plain sentences, then links to PRs, Jira keys or vault notes the recaps name. Say plainly whether the work was finished, still open, or abandoned. Leave out code, diffs, prompts, secrets, and customer data (org IDs, account details, ticket contents: link the ticket instead).

Put them under Reflections, on their own lines directly above `### Tasks Completed` (below the `>[!meetings]` callout and the tasks query that follows it):
```markdown
### 🤖 AI sessions
- 🛂 **SCP:** Getting the six piper pool accounts vended. 4 of 6 are done; staging vault and hub failed on an SCP IAM deny, and the fix is in [dd-source#<PR>](<PR link>). Still open.

### Tasks Completed
```
The section belongs to this skill. On a re-run, replace only the `### 🤖 AI sessions` heading and its bullets, stopping at `### Tasks Completed`; never add a second one. If there were no sessions, write `- None today.`

## 3. Summary
Fill the `>[!Summary]` callout under Reflections. Change its first line to `>[!Summary] 🤖 Evening summary` so the AI-written text is visible. Write 3 to 6 plain sentences addressed to Saje as "you". Cover what got done, what moved, what's waiting on someone, and anything that will matter tomorrow. Sources:
- Her notes under `# <Weekday> Notes`
- The meetings in the `>[!meetings]` callout, and their `## 🤖AI notes` if they exist yet (the Zoom and Gemini summaries often arrive later, and `/morning` fills them in)
- Tasks with `✅`/`❌` on the target day, and tasks created on the target day (`➕`)
- The 🤖 AI sessions from step 2
- Notes whose `created` property is the target day

If the callout already has text and no `🤖` title, it's hers: leave it, and put your summary in a new `>[!Summary] 🤖 Evening summary` callout right below it. If a `🤖 Evening summary` callout already exists, replace it in place instead of adding another. Don't invent anything: every sentence has to trace back to a source above.

## 4. Stuck tasks (interactive runs only)
Find open tasks anywhere in the vault, except `Extras/Templates/`, whose `⏳` date is 3 or more workdays before the target day. Skip tasks tagged `#parked`. List the 10 oldest. Use one ask-tool form with a radio group per task and these choices:
- **Keep:** leave it as it is (the default).
- **Tomorrow:** set `⏳` to the next workday.
- **Park:** remove the `⏳` date and add `#parked`. The task leaves the daily query but stays open, and `/weekly` still lists it, since it gathers every unresolved checkbox.
- **Drop:** change the checkbox to `[-]` and add `❌ YYYY-MM-DD` (the target day).

Edit each task's line in place, in its own file. Never move it or copy it. Change only the status, the `⏳` date, and the added tag or `❌` date. Keep the rest of the line, including `➕`, `📅` and `#week/…`. If the line ends in a `^block-id`, insert your additions before it: Obsidian only recognizes a block ID as the last thing on the line.

## 5. Report
In chat, in this order:
1. The summary you wrote.
2. How many sessions were logged and how many skipped (with the reason).
3. The stuck-task decisions.
4. Anything that needs her tomorrow.

Never send or post anything.
