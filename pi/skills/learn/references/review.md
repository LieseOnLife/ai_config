# Review: facts and clarity, on a different model

The writer can't check its own work: it believes what it wrote. A reviewer on another
model family reads each page against **only** the saved source passages its footnotes
link.

## Spawning
- omp: `task` with `agent: "reviewer"` (its configured model differs from the default
  writer). If you're running on that same model, set `model` to one from another family.
  pi: the `reviewer` subagent with an explicit `model`.
- One reviewer task per 1-2 pages, in one `tasks[]` batch. Each gets absolute paths to
  its pages, the index, FAQ, glossary, and every source note those pages cite.
  Glossary and FAQ get their own task when they're new or changed.
- Read-only: reviewers report, the writer edits.
- Record the reviewer model for the review log.

## Brief (paste into each task, filling the paths)

```markdown
# Goal
Check reference pages for accuracy and clarity. You did not write them. Assume nothing
is correct until a cited passage shows it.

# Inputs
Pages: <paths>. Index, FAQ, glossary: <paths>. Cited source notes: <paths>.
Each claim ends with a footnote like [^keller-cpet]; the footnote text describes one
source note and links one or more `[[Note#^qN|passage]]`: the paragraph or list item
ending in `^qN` in that note. Text in quotation marks must match a passage exactly; for
forum posts, the note's paraphrase passages are the citable record of what was said.
Read ONLY these files. Do not use your own knowledge to mark a claim supported.
Footnote descriptions (kind, n, case definition, flags, year) may be checked against the
source note's frontmatter and About box. Claims in the page text need a marked passage
of source text; a note's own Summary/Findings/Limitations commentary doesn't count.

# Facts: every claim (a sentence or clause stated as true), including in boxes,
# the Quick answer, footnote descriptions, and "About this source" boxes
Verdict: supported | partial (passage supports only part, or is weaker/narrower) |
unsupported (no footnote, or the passage doesn't say it) | misrepresented (passage says
something different or opposite) | missing-caveat (drops a limitation the source states:
size, preprint, population, date, disagreement).
Also check:
- Footnote descriptions (kind, design, n, population, year) match the source note.
- 🗣️ Lived experience boxes say only what that account says and don't generalize.
- "Analogy:" passages introduce no uncited facts.
- Paywalled sources are cited only for their abstract; superseded material is labelled.
- Cited `*EN:*` translation paragraphs say what the original paragraph above them says.

# Clarity
Flag: a Quick answer that doesn't match the page body; pages that don't answer the
questions in their `answers:` frontmatter; terms used without definition or glossary
link; misleading simplifications; FAQ entries pointing at sections that don't answer them.

# Output (only this)
## Facts
| Page | Claim (quoted, short) | Footnote | Verdict | Why | Suggested fix |
List every claim, including supported ones (Why may be "-").
## Clarity
| Page | Severity (high/medium/low) | Finding | Suggested fix |
## Counts
claims: N, supported: N, partial: N, unsupported: N, misrepresented: N, missing-caveat: N
```

## Acting on findings
- **partial / unsupported / misrepresented / missing-caveat:** narrow the claim to what
  the passage says, cite a better passage (save and mark it first), add the caveat, or
  delete the claim. Disagree only by quoting the passage; a disputed verdict goes back to
  the reviewer in round 2.
- **Clarity high/medium:** fix, or record why not in the review log. Low: use judgment.
- **Round 2:** send only the changed or disputed claims, with their pages and sources.
  At most 2 rounds.
- **Still not supported after round 2:** the claim stays, wrapped like this:

```markdown
> [!warning] ⚠️ Not verified
> <the claim, unchanged, with its footnote>
> *Reviewer (<model>, <date>): <verdict> — <why>.*
```

List every flagged claim in the index's review log so they can be revisited.
