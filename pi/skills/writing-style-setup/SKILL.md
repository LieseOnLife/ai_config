---
name: writing-style-setup
description: Build or update Saje's writing-style profile, Topics/💡Writing Style.md in Tech-2, from writing she did herself. Sources are her Slack messages, vault notes marked authorship human, and docs she vouches for. AI-written or unmarked notes are never used as samples. Use for /writing-style-setup, "learn my writing style", "make drafts sound like me", or when she corrects the voice of a draft and wants the profile updated.
---

# Writing Style Setup

The profile describes how Saje writes, so text drafted *as her* (Slack replies, emails, Confluence pages, PR descriptions, review comments) sounds like her. It doesn't change how agents explain things *to* her: `AGENTS.md` and `Topics/💡Glossary.md` cover that.

## Configuration
- Vault: `/Users/saje.liese/Obsidian/Tech-2/`
- Profile: `Topics/💡Writing Style.md`
- Saje's Slack user ID: `U01D2L9K04T`

If the profile exists, this is an update: go to **Updating**.

## 1. Rules she already knows
Ask: "Any writing rules you already know you have? For example 'no em dashes', 'always the Oxford comma', 'we, not I', or words you hate." Wait for the answer. These go into the profile word for word, above anything you infer.

## 2. Collect samples she wrote herself
Most notes in the vault are AI-written or mixed, so only these count:
1. **Slack (main source):** `slack_search_public_and_private` with `from:<@U01D2L9K04T>` over the last 3 months, paging until you have 150 to 200 substantive messages across DMs, threads and channels. Skip one-word acks, emoji-only replies, and pasted links. Skip any message with a `🤖` header or an AI blockquote (the `ai-authored-pr-replies` format).
2. **Vault notes marked `authorship: human`.** Find them with `grep -rl '^authorship: human' <vault> --include=*.md`. Also use the text under `# <Weekday> Notes` in daily notes since `/evening` started logging (`/evening` saves her words there as she wrote them).
3. **Folders she vouches for.** Ask whether any folders are entirely her own writing (e.g. `Life/Fleeting Thoughts/`, `Life/Slip Box/`). Use only the folders she names. Offer to mark their notes `authorship: human`.
4. **Docs she vouches for:** Google Docs she owns (`search_files` with `'me' in owners`) and Confluence pages she authored. Show her the list and use only the ones she confirms she wrote without AI help.

Never sample notes marked `ai`, `mixed` or `external`, or unmarked notes she hasn't vouched for. If something she vouched for reads like generated text (stock phrases, perfectly parallel bullets, chains of em dashes), ask before you use it.

## 3. Analyze
Do this separately for **formal** writing (docs, proposals) and **informal** writing (Slack):
- Voice and person: "we" vs "I", direct vs impersonal
- Sentence length and rhythm; how paragraphs open
- Punctuation: dashes, colons, semicolons, ellipses, the Oxford comma, emoji
- Structure: headings, lists vs prose, how she introduces a list, tables
- Connecting phrases she actually uses, and ones she never uses
- Tone: hedging, humor, directness, how she disagrees, how she signs off (if she does)
- Technical vocabulary and how much jargon she uses; her own terms from the **My words** section of `Topics/💡Glossary.md`

## 4. Draft the profile
Frontmatter: `type: topic`, `template: ["[[💡 Topic]]"]`, `tags: [writing-style, ai]`, `authorship: mixed`. Sections:
1. **Rules Saje gave directly** (from step 1, word for word)
2. **Formal register**: each pattern with a short real example quoted from her own writing
3. **Informal register**: the same, from Slack
4. **De-AI checklist**: the specific AI habits to strip from text drafted as her
5. **Sources**: which docs and folders, how many Slack messages, and what was left out and why
6. **Changelog**: dated lines

Quote only her own writing, in short excerpts. Leave out secrets and customer data.

## 5. Review
Show her the profile and ask what's wrong or missing. Revise until she approves.

## 6. Save and wire it in
1. Write `Topics/💡Writing Style.md`.
2. Offer to add this line to the global agent instructions (`AGENTS.md` and its copies, through the `ai-config-pr` skill): "When you write anything as Saje (Slack, email, Confluence, PR descriptions, review comments), follow `~/Obsidian/Tech-2/Topics/💡Writing Style.md`, and run the `de-aiify` checklist before showing it." Add it only after she says yes.
3. Offer a test: rewrite one of her recent messages, or draft a short reply, so she can check the voice.

## Updating
When she edits a draft or says it doesn't sound like her:
1. Work out the rule behind the correction.
2. Add it to the right section, with her corrected version as the example.
3. Add a dated changelog line and save.

Don't rebuild the profile from scratch.
