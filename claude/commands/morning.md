---
name: morning
description: Run the morning routine — generate standup + tiered channel digest and add to today's Obsidian daily page.
---

# Morning Routine

Generate standup and channel digests, then append to today's Obsidian daily note.

## Process

### Step 0: Determine Date Range
Check what day today is and when the last Slack Summary was written:
- **Normal weekday (Tue-Fri):** Cover yesterday only.
- **Monday or after a gap:** Check `Calendar/Daily Notes/` for the most recent `*- Slack Summary.md` file. Cover from the day after that summary through yesterday. For example, on Monday cover Friday through Sunday.

Use the full date range for both the standup and all channel reads.

### Step 1: Today's Meetings

Fetch today's calendar events and create / link meeting notes before generating the standup.

**1. Fetch events** by running the Swift helper:

```bash
~/.claude/scripts/today-meetings.swift
```

It returns one line per event in the form `<title>|<start date>|<calendar>|<organizer email>|<attendee emails comma-separated, excluding self>`. The script filters to **only events you've accepted and that are marked Busy** (skipping declined/tentative/no-response, free/tentative-availability, and cancelled events). To change which calendars are queried, edit the `targetNames` list inside that script.

De-dupe events by `title + start time` (Google syncs can produce double entries across calendars).

**2. Classify each event.** Normalize the title (strip leading emojis, trailing ` (from #channel)`, extra whitespace).

**Always use the attendee list to disambiguate generic titles** (e.g. "Catchup!", "Sync", "Chat", "Quick chat", "1:1"). For generic titles, identify the non-self attendee(s) and search `Calendar/Meetings/` for a parent that mentions them by name. Never assume a generic title maps to a specific recurring parent without confirming via attendees.

For specific titles, search `Calendar/Meetings/` for a recurring parent file `📢 *<normalized-title>*.md` (case-insensitive substring match).

- **Parent found AND attendees match** → recurring. Use that parent's title.
- **No parent, or attendees don't match** → treat as one-off, name it `📣 YYYY-MM-DD - <Title> with <Person>.md` so it's promotable. Surface it in the summary at the end so the user can promote it later if it actually recurs.

**3. Create the occurrence file** at `Calendar/Meetings/📣 YYYY-MM-DD - <title>.md`, where `<title>` is:
- Recurring: `📢 <Parent Title>` (e.g. `📣 2026-05-13 - 📢 Samra 1-1.md`)
- One-off: the normalized event title

Skip if the file already exists. Use the template at `Extras/Templates/📣 Meeting.md` as the source of truth for the body — read it fresh each run, then substitute:

- `<% meetingDate %>` → today's date (`YYYY-MM-DD`)
- The Templater header (the `<%* ... -%>` block that prompts for title and renames the file) is **not** copied — you're creating the file directly at the final path.
- Populate frontmatter fields:
  - `date:` → `YYYY-MM-DD`
  - `meeting:` → `"[[📢 <Parent Title>]]"` for recurring, blank for one-off
  - `people:` → attendees as `[[👤First Last]]` if the AppleScript can surface them (optional)

Do **not** inline the template body in this skill — always read `Extras/Templates/📣 Meeting.md` from the vault so template edits flow through automatically.

**4. Append to the recurring parent** (recurring events only). Insert directly after the `![[Meetings.base#📢Meetings within a Recurring]]` embed line:

```markdown
# [[YYYY-MM-DD]] 
![[📣 YYYY-MM-DD - 📢 <Parent>#Overview]]
```

Skip if a section with today's date already exists in the parent.

**5. Update today's daily note** `>[!meetings]` callout. For each meeting:
- Recurring → `> [[📢 <Parent Title>]]`
- One-off → `> [[📣 YYYY-MM-DD - <Title>]]`

De-dupe against any wikilinks already in the callout. Preserve any lines the user has already added.

**6. Summarize** at the end of this step: list each meeting handled, whether it was recurring or one-off, and flag any one-offs that look like they might warrant a recurring parent.

**Calendar configuration:** edit the `targetNames` list in the Swift script to control which calendars are queried. Default: `saje.liese@datadoghq.com`, `Calendar`, `Infra Teams`.

### Step 1.5: Fill In Past Meeting Notes

For every day in the Step 0 date range, fill in that day's meeting notes from the AI summaries Zoom and Google Meet send after each meeting. Run this after Step 1 so today's notes exist, and before the standup so the standup can use the recaps.

**1. Collect the summaries.** Search the whole range plus today, because emails can arrive hours later:
- **Zoom:** in Gmail, `from:no-reply@zoom.us subject:"Meeting assets for" after:<first day, YYYY/MM/DD> before:<tomorrow>`. Fetch each message. The body is HTML, so strip the tags and keep the "View in Zoom" link (`datadog.zoom.us/launch/hub?type=summary&mid=…`) and each `tasks.zoom.us?…&stepId=…` link next to its next-step text. The sections are *Quick recap*, *Next steps* (grouped by owner) and *Summary* (topic headings), and the attendees are listed at the end.
- **Google Meet:** in Gmail, `from:gemini-notes@google.com after:… before:…`. The subjects look like `Notes: “<title>” <Mon D, YYYY>`. Read the full notes from the Drive doc named `<title> - YYYY/MM/DD HH:MM TZ - Notes by Gemini`: find it with `search_files` (`name contains 'Notes by Gemini' and modifiedTime > '<first day>T00:00:00'`) and read it with `get_doc_as_markdown`.
- List each day's calendar events (as in Step 1) so you can tie a summary to its meeting by title and start time. Zoom subjects use the raw calendar title (e.g. `⛵Mentoring-the-Ship`, `Cloud Accounts: Ops Review/Oncall Handoff`), not the note name.

**2. Find the note.** Glob `Calendar/Meetings/📣 YYYY-MM-DD - *` for the meeting's date. Match on title words, recurring parent and attendees, not the exact filename Step 1 created, because Saje often renames notes (e.g. drops ` with <Person>`). For generic titles, confirm by attendees, as in Step 1. If the meeting has no note (accepted late, or not created that morning), create it now under Step 1's rules and add it to that day's `>[!meetings]` callout if the daily note exists. If no note can be resolved, append the summary to that day's daily note under `## 🤖AI notes - <meeting title>`.

**3. Write `## 🤖AI notes`** at the end of the note, below anything already under `# Overview`. **Never change Saje's own notes.** If the note already has `## 🤖AI notes`, skip it, so re-runs never duplicate. Layout:

```markdown
## 🤖AI notes
_Zoom summary ([view in Zoom](<hub link>)). Attendees: <names, rooms>._

### Quick recap
<one tight paragraph>

### Next steps
- [ ] [<Saje's action>](<tasks.zoom.us link>) #week/YYYY-Www
- [i] [[👤First Last]] [<someone else's action>](<tasks.zoom.us link>)

### Summary
#### <Topic>
<2–4 short sentences>
```

- For Gemini, start with `_Gemini notes ([doc](<doc link>)). Attendees: …_` and use the doc's *Summary* and *Suggested next steps*.
- **Rewrite rather than paste.** Use short, plain sentences, refer to Saje as "you", and cut small talk (laptops, injuries) unless it matters.
- **Fix obvious transcription errors** (e.g. "Databricks"/"Cavum"/"Sage" → Datadog/CAVM/Saje) and say so in the italic line.
- **Rooms:** Zoom lists conference rooms as attendees (e.g. `NYC 17.06 Marigold`). Use a person's name only when the summary names them (e.g. "Roashan (NYC)"). Otherwise write `NYC room (attendee unclear)`.
- **Action items:** for Saje's own, use `- [ ]` (`- [!]` if urgent or blocked), tagged with the current week (`#week/YYYY-Www`). They appear on the weekly page through its live query, so Step 6.5 must not copy them. Note any that repeat an older meeting's open item, e.g. "carried over from 10-19". For everyone else's, use `- [i] [[👤Person]]`, grouping one person's items on a single line joined with ` · `. Link a follow-up to its next meeting when one is scheduled (`→ [[📣 YYYY-MM-DD - …]]`).

**4. Summarize** in the final report: each note filled in, each one with no summary (e.g. Meet calls without Gemini, or in-person meetings), and Saje's new action items.

### Step 2: Generate Standup
Run `/slack:standup` to generate the standup from the date range above.

### Step 3: Read DMs
Search for DMs received during the date range using `slack_search_public_and_private` with `to:me` and date filters (e.g., `to:me after:YYYY-MM-DD before:YYYY-MM-DD`).

- Group messages by sender
- For DM threads with multiple back-and-forth messages, summarize the conversation rather than listing every message
- Skip automated/bot DMs unless they contain something actionable
- If a DM conversation is long, use `slack_read_channel` with the sender's user ID to get the full context
- Include Slack permalinks for each conversation so you can jump straight to it
- Apply the same status markers as channel digests (use sparingly)

### Step 4: Generate Tiered Channel Digests
Run channel digests in 3 tiers:

**Core** (full digest — summarize threads, decisions, action items):
```
/slack:channel-digest cloud-accounts-team, cloud-accounts-resources, cavm-dev, transcendent, basement, compute-cloud-team, infra-all, infra-lifecycle-automation, cloud-account-sales-systems-collab, account-microchipping, dd-group-mentors
```

**Ops** (flag anything needing attention):
```
/slack:channel-digest cavm-ops, cloud-accounts-conductor, cloud-accounts-ops, cloud-accounts-support, cloudops
```

**Secondary** (headlines only — brief 1-liner per notable message):
```
/slack:channel-digest cloud-accounts-finops-connect, trex-stacks, compute-cloud-security-collab, homelab, rainbowdogs, rainbowdogs-committees, snippets, unifi, aws-org-modernization, computers, eng-backroom, obsidian-md, eng-announcements, claude, uk1-dc-deployment
```

For secondary channels, only include channels that had notable activity. Use separate bullet points when relevant.

### Step 5: Format as Obsidian Callouts
Combine all output into this format.

**Formatting rules:**
- Callouts use `>[!type]` (no space between `>` and `[`). All continuation lines use `>` prefix.
- Channel names must be **hyperlinks** to the Slack channel, not `#channel-name` (which creates Obsidian tags). Format: `[channel-name](https://dd.slack.com/archives/CHANNEL_ID)`
- **Omit channels with no notable activity.** Do not include "Quiet" entries — just skip them entirely.
- **Deduplicate cross-posted items.** If the same message, PR, or topic appears in multiple channels, include it only once — in the highest-tier channel where it first appears (Core > Ops > Secondary). Skip the duplicate in lower tiers.
- When someone is mentioned, link them as `[[👤First Last]]` (e.g., `[[👤Pierre Peronnet]]`). Use full names where known.
- Include links to Slack threads, PRs, Confluence pages, etc. inline. Capture permalinks during the channel read step.
- **Every item must have a Slack permalink** so the user can jump straight to the thread. This applies to standup Done/Doing items, channel digest bullets — everything.
- Use bullet points for channel summaries — each notable item gets its own bullet.
- Secondary headlines can have **separate bullet points** when there are multiple notable items (not forced to one line).
- Secondary channels must also include **hyperlinks** to the Slack channel, same as core/ops.
- **Status markers**: Most items should use plain `- ` bullets. Reserve custom checkbox statuses for items that truly stand out — use sparingly (a few per digest, not on every line). Available markers:
  - `- [f]` **fire** — urgent, blocking, or severe issues
  - `- [!]` **important** — action items or decisions requiring your attention
  - `- [?]` **question** — open questions needing answers
  - `- [I]` **idea** — insightful posts, useful analysis, novel approaches
  - `- [k]` **key** — key decisions made by the team
  - `- [w]` **win** — promotions, milestones, team wins
  - `- [>]` **forwarded** — items delegated or handed off to someone
  - `- [b]` **bookmark** — useful resources, docs, or tools worth saving
  - `- [i]` **information** — FYI announcements, policy changes, informational posts
  - If everything is marked, nothing stands out. Be selective.
- **False-positive prevention for `[!]` and `[?]`** — these are the markers Saje actually scans for action. If you mark too many, they get cancelled (`[-]`) and the signal degrades. Apply these rules strictly:
  - **`#cloud-accounts-support` questions default to plain `- ` bullets**, not `[?]` or `[!]`. The oncall handles routine support. Only escalate to `[!]` if Saje is @mentioned by name in-thread, or oncall has explicitly escalated to her, or it touches code/decisions only she owns (e.g., CAVM internals she authored).
  - **Homelab / computers / claude / unifi / obsidian-md / rainbowdogs / snippets / eng-backroom** — never `[!]` or `[?]`. Use plain bullets, or `[i]` / `[b]` / `[I]` if genuinely interesting.
  - **Status updates and FYI threads in group DMs** (Eyal/Tanya/Samra/Andy ownership-migration channel, etc.) — plain bullets unless there's a direct ask of Saje. "Eyal flagged X is blocked" is `[i]`, not `[!]`.
  - **`[?]` only when Saje is the most likely answerer** — not for open team-wide questions or oncall-routable questions. If anyone else on the team would answer it first, it's a plain bullet.
  - **Cross-team PR review pings** → `[!]` only if Saje is named on the PR or it lands in a channel where she's a default reviewer (cloud-accounts-team, cavm-dev, cloud-accounts-resources). Drive-by LFRs in cloudops/support → plain.
  - **Rule of thumb:** before marking `[!]` or `[?]`, ask "would Saje cancel this with `[-]`?" If yes, downgrade to plain.

The file starts with `# Slack Summary` (from the template), then a tasks block (all statuses, no filter), then the content below. Use `## Section` headers to separate standup and each tier. Each channel is a `### heading` inside its callout.

```markdown
# Slack Summary

(tasks block from template)

## Standup
>[!summary] Standup - YYYY-MM-DD
>**Done:**
>- [item with PR/Jira links] — [thread](slack-permalink)
>- [item without a notable thread, no Slack link needed]
>**Doing:**
>- [items — add Slack link if there's a relevant thread]
>**Blockers:** None

## DMs
>[!quote]+ Direct Messages
>### [[👤Person Name]]
>- [!] Asked about [topic/request](url) — [thread](slack-permalink)
>- Shared [info/update](url) — [thread](slack-permalink)
>### [[👤Person Name 2]]
>- Quick question about [topic] — [thread](slack-permalink)
>(only include people who sent DMs — skip if no DMs in the date range)

## Core Channels
>[!info]+ Core Channels
>### [channel-name](https://dd.slack.com/archives/CHANNEL_ID)
>- [[👤Person Name]] did [routine thing with link](url)
>- [k] [[👤Person Name]] decided [key decision](url) — [thread](slack-permalink)
>- [w] [[👤Person Name]] promoted to Senior Engineer!
>- [I] [[👤Person Name]] posted [insightful analysis](url) — [thread](slack-permalink)
>### [channel-name-2](https://dd.slack.com/archives/CHANNEL_ID)
>- [f] [[👤Person Name]] flagged [urgent/blocking issue](url) — [thread](slack-permalink)
>- [!] [[👤Person Name]] needs [action from you](url) — [thread](slack-permalink)
>- [?] [[👤Person Name]] asking about [open question](url)
>(continue for each core channel WITH activity — skip quiet channels)

## Ops Channels
>[!warning]+ Ops Channels
>### [channel-name](https://dd.slack.com/archives/CHANNEL_ID)
>- [i] Normal deployment activity — all services healthy
>- [f] [[👤Person Name]] flagged [urgent/blocking issue](url) — [thread](slack-permalink)
>- [!] [[👤Person Name]] needs [action required](url)
>- [?] [[👤Person Name]] asking about [unresolved ops question](url)
>(continue for each ops channel WITH activity — skip quiet channels)

## Secondary
>[!note]+ Secondary (Headlines)
>### [channel-name](https://dd.slack.com/archives/CHANNEL_ID)
>- [i] [[👤Person]] shared [policy change announcement](url)
>- [b] [[👤Person]] shared [useful resource/tool](url)
>### [channel-name-2](https://dd.slack.com/archives/CHANNEL_ID)
>- [w] [[👤Person]] achieved [milestone/win](url)
>- [I] [[👤Person]] posted [insightful analysis](slack-permalink)
>(only channels with notable activity)
```

### Step 6: Write to Slack Summary File
**Always write the file directly — do not show a preview or ask for confirmation.**
The digest goes in a **separate file** that is embedded in the daily note via the Daily Note template.

**File location:** `Calendar/Daily Notes/YYYY-MM-DD - Slack Summary.md`

**Use the Slack Summary template** from `Extras/Templates/Slack Summary.md`. The file should have:
- Frontmatter: `weekday`, `date`, `type: slack_summary`, `template: ["[[Slack Summary]]"]`, `tags: [🐶]`
- A tasks block at the top (no status filter — shows all statuses)
- Then all the formatted callouts

Write the file directly using the Write tool to the vault path:
```
/Users/saje.liese/Obsidian/Tech-2/Calendar/Daily Notes/YYYY-MM-DD - Slack Summary.md
```

The Daily Note template automatically embeds `![[YYYY-MM-DD - Slack Summary]]` on weekdays, so no need to touch the daily note.

If the Slack Summary file already exists for today, warn and ask whether to overwrite or skip.

### Step 6.5: Weekly Dashboard
After the Slack Summary is written, read `~/.claude/skills/weekly/SKILL.md` and follow **Morning Integration**. Preserve the `scheduled-headless` argument when present. This pass links today's daily note, imports only new actionable Slack/DM work, or handles a missing weekly page exactly as that skill specifies. Failure here must not undo the Slack Summary.

### Step 7: Done
Do **not** offer to post the standup to Slack. Include Step 1's meeting list and Step 1.5's notes report in the final reply.

## Channel Configuration
To update channels, edit this file directly. The three tiers are:
- **Core**: Your team's primary channels — full summaries
- **Ops**: Operational channels — alert-focused
- **Secondary**: Channels you monitor — headlines only
