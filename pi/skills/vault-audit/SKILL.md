---
name: vault-audit
description: Monthly health check of Saje's Tech-2 Obsidian vault. Reports broken links, island notes, loose root and Untitled notes, misplaced attachments, empty notes, missing frontmatter or type, leftover Templater tags, duplicate note names, tag case variants, and notes without an authorship property, then offers fixes she approves one by one. Use for /vault-audit, "audit my vault", "vault health check", or marking which notes are AI-written.
---

# Vault Audit

Report first. Change nothing until Saje picks the fixes.

## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Reports: `Extras/Vault Audits/YYYY-MM-DD - Vault Audit.md`
- Attachment folder: `Extras/Attachments` (from `.obsidian/app.json`)
- Scripts, both in `scripts/` next to this file:
  - `audit.py <vault>`: read-only. Prints the report body as Markdown.
  - `authorship.py <vault> [--apply]`: marks notes whose origin is obvious. Dry run by default.

## Authorship property
Every note can carry `authorship` in its frontmatter. It says who wrote the words, so `writing-style-setup` learns only from Saje's own writing.

| Value | Meaning |
|:--|:--|
| `human` | Saje wrote it. |
| `ai` | An agent wrote it, e.g. Slack Summaries and `/learn` docs pages. |
| `mixed` | Both, e.g. a meeting note with a `🤖AI notes` section, a 💬 note, a weekly page. |
| `external` | Someone else wrote it, e.g. Readwise imports and clippings. |

No property means unknown. Never set `human` by guessing: only Saje can vouch for a note. `authorship.py` lists its rules in `classify()`. It never changes a note that already has the property. It keeps each file's modified time, and with `--apply` it first copies every file it changes to `~/Obsidian/.authorship-backup-<date>/`.

## 1. Run the checks
```bash
python3 <skill-dir>/scripts/audit.py /Users/saje.liese/Obsidian/Tech-2 > /tmp/vault-audit.md
python3 <skill-dir>/scripts/authorship.py /Users/saje.liese/Obsidian/Tech-2
```
`audit.py` skips `Extras/Templates/`. It doesn't count these as broken: `type:` links (they name a category, e.g. `[[article]]`), links to dates with no note yet, and links inside Readwise/Omnivore imports. It reports 👤 links with no person note separately, as information only.

## 2. Write the report
Create `Extras/Vault Audits/` if needed and write the report there with this frontmatter:
```yaml
---
type: vault_audit
date: YYYY-MM-DD
authorship: ai
tags: [vault-audit]
---
```
Body: a one-paragraph summary (what's worse or better than the last report in `Extras/Vault Audits/`, if there is one), then the `audit.py` output, then the `authorship.py` dry-run counts.

## 3. Offer fixes
In chat, show the summary table and offer the fixes below, using the ask tool with a checkbox for each one. Apply only the ones she ticks, then report what changed.

- **Mark authorship:** run `authorship.py --apply`. Then offer to mark folders she vouches for as `human`, e.g. `Life/Fleeting Thoughts/`, `Life/Slip Box/`. Mark only the folders she names.
- **Move attachments** into `Extras/Attachments/`, and update links if any note links them by path. Obsidian's `alwaysUpdateLinks` doesn't apply to changes made outside the app, so check links yourself.
- **File root-level and Untitled notes:** propose a home for each one, ask, then move it. Untitled notes that are empty go to the `.trash/` folder (Obsidian's trash), never a permanent delete.
- **Broken links:** for each target, suggest the closest existing note name and ask before rewriting. Report the 5+ placeholder targets (e.g. `👥Compute Cloud`) and offer to create hub notes. Never rewrite those on your own.
- **Missing type or frontmatter:** propose a `type` from the folder's usual one. Add it only after she approves.
- **Tag case variants:** ask which spelling to keep, then replace the other one.

## Rules
- Never delete a note. Move it to `.trash/` only when she names it.
- Never change the body of a note marked `human`, beyond fixing a link she approved.
- Report only what the scripts found. Don't add an issue you didn't check.
