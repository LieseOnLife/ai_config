---
name: slack-conversations
description: Record significant Slack conversations (DMs, group DMs, threads Saje joined) as 💬 Obsidian meeting notes with a verbatim transcript, summary, action items, and linked people/projects/topics/meetings. Used by /morning via the slack-scribe subagent; also run directly to capture or backfill conversations for a date range.
---

# Slack Conversations → 💬 Notes

Significant Slack conversations count as meetings. Each one gets a `💬` note in `Calendar/Meetings/` (not `📣`), so they're easy to tell apart.

- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Template: `Extras/Templates/💬 Slack Meeting.md`. Read it fresh on every run, drop the Templater `<%* … -%>` header, and never inline it here.
- Saje's Slack user ID: `U01D2L9K04T`

## Input

- **Date range** (`YYYY-MM-DD` to `YYYY-MM-DD`, inclusive, America/New_York).
- **Candidates** (optional, from `/morning`): one per line, `channel_id | thread_ts or - | participants | one-line hint`.
  - **With candidates:** check every candidate, plus any DM or thread that the candidates link or reference. Don't re-run discovery searches; `/morning` already did them, and Slack is rate-sensitive.
  - **Without candidates** (backfills, manual runs): build the list with `slack_search_public_and_private`, using `from:<@U01D2L9K04T>` and `to:<@U01D2L9K04T>`. Search `after:`/`before:` dates are **exclusive**, so use `after:<start − 1 day> before:<end + 1 day>`. Page through every cursor.

**Slack MCP pacing:** make Slack calls **one at a time**. `initialization_failed` and empty errors are transient: wait about 2 s and retry up to 4 times before you call a conversation unreadable.

## 1. Qualify

A conversation qualifies when it has:
- real back-and-forth: both sides, about 4 or more substantive messages, **or**
- any decision, commitment, scoping or design discussion, even if it's short.

Check every DM and group DM in the range, every channel thread Saje posted in, and any single-topic channel (e.g. `#incident-*`) where Saje posted at the top level. Skip:
- bots and system messages
- one-line asks or acks
- PR-review pings (`:ptal:` plus a stamp)
- routine on-call support Q&A (routing, form links, one-step fixes) that's already tracked in the on-call note. Support threads with a decision or design discussion still get a note.
- pure social chatter, unless Saje made a commitment in it

If you're unsure, include it. A short note is cheaper than a lost decision.

## 2. Read the whole conversation

- Channel threads: `slack_read_thread` (`response_format: detailed`).
- DMs, group DMs and single-topic channels: `slack_read_channel` (`response_format: detailed`), then open thread replies with `slack_read_thread`. `oldest`/`latest` take Unix timestamps: ET start of the first day to end of the last day.
- If a new conversation's earliest returned message is mid-conversation, page back before `oldest` to find its first message.
- **New note:** transcribe the whole conversation from its first message, even if that's before the range.
- **Continuation:** append only messages newer than the note's last transcript entry (see §3).
- **Either way,** stop at the end of the range. Later replies belong to the next run, which appends them.

## 3. Continue, don't duplicate

A conversation that runs across several days is **one note**, dated and named for the day it started. Before you create anything, grep `Calendar/Meetings/💬 *.md` for a matching `slack_channel:`:
- **Threads:** `slack_thread:` must match too.
- **DMs and channels:** one `slack_channel:` can have several notes, one per topic. Compare the transcripts' message times with this range, and use the **most recent** note with that `slack_channel:` to decide.

Three outcomes:
- **Already recorded:** every message in the range is already in that note's transcript (a re-run or an overlapping range). Edit nothing, and report it as `unchanged` **with the note's wikilink**.
- **Continuation:** the range picks up where the note's transcript ends, on the same topic, open questions or action items.
  - Append only messages newer than the last transcript entry, under a date header for each new day. Keep each speaker's emoji, and give anyone new the next unused one.
  - Update the AI-written summary bullets, and keep any prose Saje added.
  - Leave every existing action item exactly as it is (`[ ]`, `[!]`, `[?]`, `[/]`, `[x]`, `[-]`, `[i]`, `Tracked on …`, `Done …`), including its dates and tags. The only changes allowed: mark an item `[x]` with `✅ YYYY-MM-DD` when the new messages show it's done, and add brand-new items.
  - Don't rename the file or change `date:`/`slack_thread:`. Add any new people, projects or topics to the frontmatter lists.
- **New note:** nothing matches, or the DM or channel has clearly moved to a **new topic**.

## 4. Classify and name

- **Recurring:** the participants and topic match a `📢` parent in `Calendar/Meetings/` (e.g. a DM following up a 1-1). Name it `💬 YYYY-MM-DD - 📢 <Parent Title>.md`.
- **One-off DM or group DM:** `💬 YYYY-MM-DD - <Topic> with <Person>.md`. For a group DM, use the main counterpart.
- **One-off channel thread or single-topic channel:** `💬 YYYY-MM-DD - <Topic> in <channel-name>.md`

Keep `<Topic>` to 2–6 words, in title case. Strip any `/ \ : * ? " < > |` from it.

## 5. Link and tag

People are **always** linked by name. Projects, topics, Jira and meetings link **only to notes that already exist.** Never create any note other than the 💬 note itself. Resolve every name with `glob`/`grep` first:

| Kind | Where | Frontmatter | Inline |
|---|---|---|---|
| People | `People/👤*.md` | `people:` lists every non-Saje human participant, plus anyone central to the topic, as `"[[👤First Last]]"` **whether or not the note exists yet** | `[[👤First Last]]` on first mention in the summary and action items |
| Projects | `Datadog/Projects/*.md` (emoji-prefixed, e.g. `🎱 CAVM Account Pooling`) | `project:`, a single `"[[…]]"` for the main project; mention others inline | `[[🎱 CAVM Account Pooling\|Account Pooling]]` |
| Topics | `Topics/**/*💡*.md` and `Datadog/**/*💡*.md` (some carry a prefix, e.g. `🔵💡Azure Tennent Sync`) | `topics:` list | inline when useful |
| Jira | `Datadog/Tasks/🎞️ {KEY}*.md`; otherwise a Jira URL | — | `[[🎞️ CLOUDA-1234 …\|CLOUDA-1234]]` or `[CLOUDA-1234](https://datadoghq.atlassian.net/browse/CLOUDA-1234)` |
| Meetings | `📢` parents, `📣`/`💬` notes that this conversation follows up or sets up | `meeting:` (recurring parent only) | `→ [[📣 YYYY-MM-DD - …]]` |
| PRs/docs | — | — | Markdown links: `[dd-source #123](https://github.com/ddoghq/dd-source/pull/123)` |

Match people by Slack display name and email, and use full names (look them up with `slack_read_user_profile` or `slack_search_users` when Slack shows only a handle). When a vault note already exists with a different spelling (e.g. `👤Sean OConner`), use the vault spelling. Person links are the one exception to "only existing notes": always write `[[👤First Last]]`, so Saje can create the note later from the link. Bots never get person links.

Link a project or topic only when the conversation itself (or an invite or PR it links) is about it. Don't infer one from other vault notes.

Tags:
- Keep the template's `🟪` tag.
- Tag Saje's own action items with the ISO week of the **conversation's last message in the range**, `#week/YYYY-Www`. For `/morning` that's the current or previous week. In a backfill, older week tags keep stale items off this week's dashboard, and they land in the weekly page's untagged-triage query instead. They reach the weekly page through its live query, so never copy them there.

## 6. Write the note

Frontmatter (from the template):
- `date`, `type: meeting`, `medium: slack`
- `slack_channel:` (channel or DM ID) and `slack_thread:` (permalink to the first message)
- `people:`, `project:`, `topics:`, and `meeting:` (recurring only)
- `created:` (now)
- `authorship: mixed` (an AI summary plus a verbatim transcript)

Body:
- `>[!quote] Slack conversation · [thread](<permalink>)` goes directly under `# Overview`, as in the template.
- `## Summary`, **when relevant**:
  - For substantive conversations, write 2–6 bullets: what was discussed, `[k]` key decisions, commitments and **Open:** questions. Refer to Saje by name ("Saje said…") to match existing 💬 notes. Rewrite; don't paste.
  - For short conversations that only qualify because of one decision or commitment, write one sentence.
- `## Action Items`: keep the template's tasks block, then the items.
  - Saje's own: `- [ ]` (`- [!]` if urgent or blocked) with `#week/YYYY-Www` and `➕ YYYY-MM-DD`.
    - First grep the vault for an **unresolved** checkbox (`[ ]`, `[!]`, `[?]`, `[/]`) covering the same action, including the weekly page and other 📣/💬 notes. If one exists, write a plain reference bullet (`- Tracked on [[<note>]]: …`) rather than a second checkbox.
    - In a backfill, check later Slack messages and the vault before opening an item. If it was already done, write a plain `- Done MM-DD: …` bullet, not `[x]`.
  - Everyone else's: `- [i] [[👤Person]] …`, grouping one person's items on a single line joined with ` · `.
  - Omit the items when there are none, but keep the tasks block.
- `# Transcript`: the **full verbatim text** in one collapsed callout:
  ```markdown
  > [!quote]- Slack transcript (DM with <Person> | [#<channel>](https://dd.slack.com/archives/<channel_id>) thread)
  > **🔵 Person Name** · YYYY-MM-DD HH:MM
  > message text
  >
  > **🧚🏻‍♀️ Saje** · HH:MM
  > reply
  ```
  - Put the date in the header on the first message and whenever it changes. Otherwise use `HH:MM` (24h, ET).
  - **Verbatim** means keeping typos, emoji shortcodes (`:bufo-wave:`) and code blocks exactly as written. Nest quoted messages as `> >`.
  - Write forwarded messages as `> > _Forwarded from Name:_` followed by the text. Slack truncates them, so restore the full text from the original message (or an existing note) when you can.
  - Saje's replies relayed by the Jira sync bot are her words: write them as `**🧚🏻‍♀️ Saje** · HH:MM _(via Jira sync)_`, not as bot lines.
  - **Never transcribe secrets:** passwords, tokens, API keys, recovery codes or private keys. Replace each one with `_(secret redacted)_`, and skip conversations that exist only to hand one over.
  - Convert Slack mrkdwn links `<url|text>` → `[text](url)` and `<url>` → `<url>`. Resolve user mentions `<@U…|name>` → `@name`.
  - Escape every `$` as `\$`, in the transcript and the summary, so Obsidian doesn't render dollar amounts as math.
  - Note attachments as `_(file attached: name)_`. Note reactions only if they carry meaning. Slack doesn't say who reacted, so write `_(reacted 💯)_` and never name the reactor.
  - In channel transcripts, put each thread reply right after its parent, as `> ↳ **🟢 Name** · HH:MM`.
  - Speaker emoji go **before** the name. Saje is always `🧚🏻‍♀️ Saje`. Give other speakers markers in order of first appearance: `🔵` `🟢` `🟠` `🟣` `🔴` `🟡` `🟤` `⚫` `⚪`, then `🟦` `🟩` `🟧` `🟥` `🟨` `🟫` `🔷` `🔶` `🔹` `🔸`. Markers only stay consistent within one note.
  - Bots and system messages get no marker; write them as an italic line (`_Datadog: Incident #123 severity set to SEV-4_`).
  - For long channels such as incident channels, transcribe only the humans' messages plus key bot state changes (severity, state, cordon).

## 7. Link it into the vault

- **Recurring:** add `# [[YYYY-MM-DD]] 💬` and `![[💬 YYYY-MM-DD - 📢 <Parent>#Overview]]` to the parent, after the `![[Meetings.base#📢Meetings within a Recurring]]` line, in reverse-date order (below any newer `# [[YYYY-MM-DD]]` sections). Skip it if that 💬 section already exists.
- **Daily notes:** add a line to the `>[!meetings]` callout of `Calendar/Daily Notes/YYYY-MM-DD.md`, when that note exists, for the conversation's start date and for every day in the range that had messages.
  - Recurring: `> [[📢 <Parent>]] 💬`
  - One-off: `> [[💬 YYYY-MM-DD - <title>]]`
  - The link always uses the start-date filename. Skip lines that are already there, and preserve Saje's lines.
- **Never edit** Saje's own prose in any note.

## 8. Report

End with a table, one row per conversation:
- `status`: created / continued / unchanged / skipped
- `note`: the wikilink for created, continued and unchanged; the reason for skipped
- `channel_id`, `thread_ts`, `permalink`, `people`, `project`

Then list Saje's new action items, each with its note. `/morning` uses this table to add `[[💬 …|notes]]` links to the Slack Summary, including for unchanged notes.

A second run over the same range must create no duplicate note, transcript entry, daily-note link or parent section.
