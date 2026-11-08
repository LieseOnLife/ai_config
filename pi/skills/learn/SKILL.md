---
name: learn
description: "Build, extend, or query a sourced reference wiki on a topic in Saje's Obsidian vault: index, subject pages with explanatory footnotes, FAQ, glossary, and a saved source note for every citation, checked by a reviewer on a different model. Use for /learn <topic>, 'teach me X', 'make docs on X', 'expand my X docs', or /learn ask <topic> <question>."
---

# Learn: sourced reference docs

Builds a set of Obsidian pages Saje can explore in any order and come back to with
questions. **Accuracy is the priority:** every factual claim carries a footnote that
explains its source and links the exact saved passage, and a reviewer subagent on a
different model checks every claim. Running it again on a topic extends the docs.

Modes:
- **Build / extend:** `/learn <topic>` (steps 0-7)
- **Ask:** `/learn ask <topic> <question>` (see "Ask mode")

Read before starting:
- `references/sources.md`: which sources count, saving, footnotes
- `references/review.md`: reviewer brief and acting on findings
- `assets/`: note formats (`index.md`, `page.md`, `faq.md`, `glossary.md`, `source.md`)
- A topic add-on from the table below when the topic matches. Its rules win where they
  conflict with the generic ones.

| Add-on | Use when the topic is about |
|---|---|
| `references/topics/mecfs.md` | ME/CFS, Long COVID, post-exertional malaise, or their treatments |

To add one: create `references/topics/<slug>.md` with only the rules that differ, and
add a row here.

## 0. Resolve the vault
Use the vault containing the working directory (walk up to the folder holding
`.obsidian/`); if none, ask which vault under `~/Obsidian/`. Attachments go to
`.obsidian/app.json` `attachmentFolderPath` (default `Extras/Attachments`).

Layout, with `<T>` the topic's short display name:

```
Topics/📘<T>/📘<T>.md                 index (type: docs)
Topics/📘<T>/📘<T> - <Page title>.md  subject pages
Topics/📘<T>/📘<T> - FAQ.md
Topics/📘<T>/📘<T> - Glossary.md
Sources/<emoji><Title> -by- <Author>.md
<attachments>/<source-slug>.pdf
```

Page names carry the topic so wikilinks stay unique across topics. Link existing vault
notes (topic hubs, `Topics/Topic-Details/` notes) instead of duplicating them.

## 1. New docs or extension?
Search `Topics/` for an index with `type: docs` whose `topic` or name matches.
- **Exists:** read the index (pages, `## Areas to expand`, review log) and the FAQ.
  Show Saje what's covered and ask which areas to expand: the index's listed areas plus
  2-4 gaps you noticed, multi-select with free text. New areas become new pages or new
  sections on existing pages. Reuse existing sources.
- **New:** step 2.

## 2. Scope (new docs)
Ask in one batch: current level (none / some / working), why she's learning it (goals,
questions she wants answered), size (3 / 5 / 8 pages, default 5), anything to skip or
emphasize. Turn the answers into a page plan: each page's title, the questions it answers,
and where it sits in a suggested reading path. Show the plan and get a go.

## 3. Research and save sources
Follow `references/sources.md`. Mix kinds: primary/authoritative sources for facts,
research for findings, secondary sources for context, first-person accounts (Reddit,
forums, blogs, interviews) for lived experience. Save every source note, with its
"About this source" box and marked passages, **before** writing pages that cite it.
Dedupe first. Aim for two independent sources behind each page's central claims. If
good sources don't exist for part of the plan, shrink or reshape that page and say so;
never fill from memory.

For more than a handful of sources, split the research into parallel subagent tasks by
source group (guidelines, research papers, carer or practical guides, first-person
accounts). Each task owns a disjoint set of source notes (no two tasks edit the same
note) and reports a passage manifest: note filename, access, PDF, and `^qN | what it
says` for every marked passage. Tell tasks to save notes as they go, and write the pages
yourself from the passages' actual text, not from the manifests' summaries.

## 4. Write the docs
Use the `assets/` formats.
- **Each page stands alone:** a `Quick answer` callout (3-5 cited lines), then sections.
  Define terms on first use or link the glossary. Link related pages where they connect.
- **Footnotes:** every factual claim ends with a named footnote (`[^iom-pem]`) whose text
  explains the source (who, kind, strength, size/population, caveat) and links the exact
  passage. Format in `references/sources.md`. Cite only what the passage says.
- Years, counts, and other numbers in prose need a passage like any other fact. A year
  that only appears in a source's frontmatter belongs in the footnote label, not the prose.
- Explanations and analogies you write yourself are allowed; start an analogy with
  "Analogy:", and it introduces no uncited facts.
- Where sources disagree or evidence is weak, say so and cite both sides.
- Boxes from `assets/page.md`: `🔬 Study spotlight`, `📰 In the news`, `🗣️ Lived
  experience` (aim for one per page where first-person accounts exist). Boxes illustrate;
  they never carry the page's facts, and a first-person account never supports a general
  claim. In lived-experience boxes, quote the account's verbatim passages (exact
  characters) rather than paraphrase.
- Frontmatter `answers:` lists the questions the page answers, in plain words. The FAQ
  links each question to the page section that answers it.
- Glossary: every term a page defines, with a footnoted definition.

## 5. Check, then review on a different model
Run `scripts/check_docs.py <vault> "Topics/📘<T>"` and fix everything it reports. It
catches undefined or unused footnotes, footnotes citing more than one source, links to
missing notes, headings, or `^q` IDs, and leftover `<%`.

Then follow `references/review.md`. The reviewer's model must be from a different family
than the writer's (omp: the `reviewer` agent's configured model; pass `model` explicitly
if it matches yours). Fix, re-run the check, re-review changed claims, at most 2 rounds. A
claim still not supported after round 2 **stays**, wrapped in the ⚠️ callout from
`review.md`.

## 6. Finish
Update the index: page map, suggested reading path, `## Areas to expand` (gaps, deeper
follow-ups, anything cut for lack of sources, questions the docs can't answer yet), and a
`## Review log` row. Update frontmatter counts. Add `topics:` links to existing topic
notes for the subject.

## 7. Report
- Index link; pages added or extended; sources saved (new / reused, PDFs, paywalled)
- Claims: checked / supported first time / fixed / ⚠️ flagged (list flagged ones)
- Clarity findings: fixed / declined with reason
- Areas to expand next time

## Ask mode
`/learn ask <topic> <question>`
1. Find the index (step 1). If there are no docs on the topic, offer to build them.
2. Find relevant pages through the FAQ, `answers:` frontmatter, and headings, then read
   the cited source passages.
3. Answer **only** from the docs and their saved sources. Reuse the pages' footnotes
   (same format) so every claim links its passage. Mention ⚠️ flagged claims as
   unverified if you rely on them.
4. Say plainly what the docs don't cover. Offer to extend: a new page or section goes
   through steps 3-6, including review. Add the question to the FAQ once it's answered
   in a page.
