---
name: morning
description: Run the morning routine — generate standup + tiered channel digest and add to today's Obsidian daily page.
---

# Morning Routine

Generate standup and channel digests, then append to today's Obsidian daily note.

## Process

### Step 1: Generate Standup
Run `/slack:standup` to generate the standup from yesterday's Slack activity.

### Step 2: Generate Tiered Channel Digests
Run channel digests in 3 tiers:

**Core** (full digest — summarize threads, decisions, action items):
```
/slack:channel-digest cloud-accounts-team, cloud-accounts-resources, cavm-dev, transcendent, basement, compute-cloud-team, infra-all, infra-lifecycle-automation
```

**Ops** (flag anything needing attention):
```
/slack:channel-digest cavm-ops, cloud-accounts-conductor, cloud-accounts-ops, cloud-accounts-support, cloudops
```

**Secondary** (headlines only — brief 1-liner per notable message):
```
/slack:channel-digest cloud-accounts-finops-connect, trex-stacks, compute-cloud-security-collab, homelab, rainbowdogs, rainbowdogs-committees, snippets, unifi, aws-org-modernization, computers, eng-backroom, obsidian-md, eng-announcements, claude
```

For secondary channels, only include channels that had notable activity. Use separate bullet points when relevant.

### Step 3: Format as Obsidian Callouts
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

### Step 4: Show Preview
Present the formatted output to the user for review before writing.

### Step 5: Write to Slack Summary File
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

### Step 6: Offer to Post Standup
Ask: "Post the standup to Slack?" If yes, use Slack tools to post to the appropriate standup channel.

## Channel Configuration
To update channels, edit this file directly. The three tiers are:
- **Core**: Your team's primary channels — full summaries
- **Ops**: Operational channels — alert-focused
- **Secondary**: Channels you monitor — headlines only
