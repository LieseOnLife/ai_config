---
name: people-interactions
description: Log, recall, and summarize interactions with colleagues in Obsidian to build context for peer feedback, 1:1s, and performance reviews. Use whenever the user mentions an interaction with a colleague (PR review, Slack thread, meeting, incident), wants to remember something about a person, shares a PR URL or Slack link and mentions a coworker, or asks for a summary of their history with someone. Also use when the user says things like "note that X did...", "log this about Rob", "I want to remember that...", "add this to [person]'s note", or after gathering data about a colleague for feedback.
---

# Skill: People Interactions

Log notable interactions with colleagues into their Obsidian person notes, so you can recall context at feedback time, 1:1s, or whenever you need it.

## Vault Details

- **Vault root**: `/Users/saje.liese/Obsidian/Tech-2/`
- **People folder**: `/Users/saje.liese/Obsidian/Tech-2/People/`
- **File naming**: `👤{First Last}.md` (e.g., `👤Rob Biagi.md`)
- **Person template**: `/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/👤🐶 Person.md`

## Interaction Entry Format

Add entries to a `# Log` section (top-level heading, same level as `# Meetings`). Use `## YYYY-MM` (or `## YYYY-MM-DD` for precision) as date subheadings. Under each date, write one bold-title entry per interaction followed by a type label and optional link, then a brief description.

```markdown
# Log

## 2026-04

**GCP bucket compliance flag** · [Slack](url)
Proactively identified ~60% of eu1 buckets outside expected region. Proposed org-policy enforcement before anyone asked.

**[cloud-inventory#56979](url)** · PR
Clean GCP project grant for Applied AI team.

## 2026-03

**[CLOUDA-5312 Strategic Sourcing SCIM Sync](url)** · PR
Multi-repo coordinated change (cloud-inventory + corpit-lambdas). End-to-end ownership.
```

**Type labels**: `PR`, `Slack`, `Meeting`, `RFC`, `On-Call`, `Documentation`, `Incident`, `1:1`, or anything descriptive.

Keep descriptions brief but specific — enough context to reconstruct the memory months later. Group multiple interactions from the same month under one `## date` heading. Newest month at the top.

## Step-by-Step

### Step 1: Identify the person

Determine their full name. Check if a note exists:
```bash
ls "/Users/saje.liese/Obsidian/Tech-2/People/" | grep -i "{name}"
```

### Step 2: Create the note if it doesn't exist

If no note exists, create `👤{First Last}.md` with this structure:

**Important:** Obsidian frontmatter does not support nested key-value objects. All fields must be flat strings or flat lists. Do NOT write `social_media:\n  github: foo` — use flat fields only.

```markdown
---
type: person
aliases:
  - Common Name
team:
social_media:
github:
website:
template:
  - "[[👤🐶 Person]]"
tags:
  - 🐶
---
# Meetings
![[Meetings.base#👤People]]

## Mentioned
![[Meetings.base#👤 People Mentioned]]

# Other Links
![[Not Meetings.base#👤People]]

# Log

```

### Step 3: Add the interaction entry

Read the existing note, then find or create the right `## YYYY-MM` date heading inside `# Log`:
- If the month heading already exists: add the new entry under it (newest entry first within the month).
- If the month doesn't exist yet: insert a new `## YYYY-MM` heading, keeping months in descending order (newest at top).
- If `# Log` doesn't exist at all: append it to the end of the note.

Use today's date (`currentDate` from context, or `date +%Y-%m-%d`).

### Step 4: Confirm

Tell the user what was logged and the note path.

---

## Bulk Logging

When logging multiple interactions at once (e.g., after gathering data about a colleague for feedback), write all entries in a single pass. Group them chronologically, newest first. It's fine to write a paragraph of context for rich entries — don't force brevity when the detail matters.

Example:

```markdown
### 2026-02-18 · RFC · [Deprecation of OrganizationAccountAccessRole](https://...)
Authored this RFC and drove it through review. Raised careful security considerations about blast radius of the root org access role. Approved by Cloud Security.

### 2026-01-30 · PR Review · [CLOUDA-4966 revoke access](https://github.com/...)
Quick, clean PR for access revocation. Well-scoped change.
```

---

## Slack Retention Caveat

Datadog Slack has ~30 day message retention for DMs and many channel types. When searching Slack for interactions and finding nothing, **do not conclude they didn't interact** — the history is simply gone. Always note this caveat when reporting on Slack-based collaboration research.

## Feedback Summary Mode

When the user asks to "summarize interactions with X for feedback" or "prepare feedback for X", read their `## Interaction Log` and generate SBI-format bullets:

- **Situation**: When / context
- **Behavior**: What they did specifically
- **Impact**: Why it mattered

Group by theme (e.g., "Security Thinking", "Documentation", "Operational Reliability"). Aim for 3–5 strong bullets rather than exhaustive coverage.
