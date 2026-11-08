# Topic add-on: ME/CFS and Long COVID

Use with the generic rules; these win where they conflict.

## The research vault already has a corpus
Vault: `/Users/saje.liese/Obsidian/research`. It holds graded source notes (tag `mecfs`)
built by the `mecfs-source-intake`, `mecfs-sweep`, and `mecfs-synthesis` skills.
**Read the rubric first:**
`/Users/saje.liese/Obsidian/research/Extras/Skills/mecfs-source-intake/references/rubric.md`.
It defines valid sources, case definitions, evidence tiers, quality flags, note schemas,
and the medical guardrail.

- **Search the corpus before the web.** Corpus notes record `evidence_tier`,
  `case_definition`, `pem_required`, `n`, and `quality_flags`. Prefer guideline,
  systematic-review, and rct notes for central claims.
- **New research or first-person sources go through intake.** Follow the
  `mecfs-source-intake` procedure (dedupe, metadata, retraction check, gate, rubric
  frontmatter, filename) instead of `assets/source.md`. Rejected items go to
  `Sources/🚫ME-CFS Rejected.md` as that skill says. Sources that fall outside the rubric's
  scope but are needed for the docs (e.g. a physiology textbook page) use the generic
  `assets/source.md` without the `mecfs` tag.
- **Corpus notes keep their shape.** They already carry Summary and Limitations sections,
  so don't add an "About this source" box; the footnote description carries the tier,
  case definition, PEM status, and n instead.
- **Full text on top of intake:** intake doesn't paste paywalled text and that still
  holds. For open-access papers (PMC OA, open journals) and public guidelines, add a
  `# Full text` section at the end of the note with the passages the docs cite (or the
  whole text), and the PDF per the generic rules. Mark passages there. Never reorder or
  rewrite the intake sections, never change graded fields, and never clear
  `priority: true`. Passages may also be marked in the existing `# Abstract` section.
- **Reddit and forums:** first-person accounts are already a rubric category
  (`🗣️` notes, `voice`, `severity`, `helped`, `worsened`). Subreddits: r/cfs,
  r/covidlonghaulers, r/MECFS. Paraphrase; quote short passages only; no usernames.

## Writing pages
- Every page opens, right after the title, with:
  ```markdown
  >[!warning] Evidence log, not medical advice
  >This page explains what research found and what people report. It doesn't recommend
  >treatments. Talk through any change with a clinician who knows ME/CFS.
  ```
- "The evidence shows" / "people report", never "you should" or "try".
- Footnotes for cohort findings state the case definition, whether PEM was required, the
  evidence tier, and n: `**Keller 2024**, observational, n=84 (CCC, PEM required)`. Keep
  findings from cohorts without a PEM criterion (Fukuda, Oxford) apart from PEM-required
  cohorts in the prose too, and say which is which.
- Name the evidence tier in prose for treatment claims ("one small RCT", "a preprint",
  "a registered trial with no results yet").
- Treat PACE-lineage CBT/GET work as history of the field: explain it and its critiques
  (cite both), don't present it as current evidence.
- Link treatments to existing `💊` notes and concepts to the topic hub
  `[[🫩Myalgic Encephalomyelitis-Chronic Fatigue Syndrome (ME-CFS)]]`.

## Extra reviewer checks (add to the brief)
- Guardrail: no recommendations, no "you should".
- Case definition and PEM status stated for cohort findings; no-PEM cohorts not
  presented as ME/CFS evidence without saying so.
- Evidence tier described accurately (a preprint isn't "a study showed", a registered
  trial has no results).
- Lived-experience boxes don't imply a treatment works.
