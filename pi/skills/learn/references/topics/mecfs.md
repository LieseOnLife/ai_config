# Topic add-on: ME/CFS and Long COVID

Use with the generic rules; these win where they conflict.

## The research vault holds the corpus; the docs go in Tech-2
Corpus vault: `/Users/saje.liese/Obsidian/research` (advanced knowledge). It holds graded
source notes (tag `mecfs`) built by the `mecfs-source-intake`, `mecfs-sweep`, and
`mecfs-synthesis` skills. The docs themselves go in the learning vault,
`/Users/saje.liese/Obsidian/Tech-2` (`Topics/📘ME-CFS/`). Find and grade sources in
research, then copy each cited source note and its PDFs into Tech-2 (see "Across
vaults" in `SKILL.md`). Passages and `type` are added to the research original first,
then copied, so both copies carry the same `^q` IDs. Copying over an existing Tech-2 copy
replaces it: re-add `docs: ["[[📘ME-CFS]]"]` to the Tech-2 copy afterwards.
**Read the rubric first:**
`/Users/saje.liese/Obsidian/research/Extras/Skills/mecfs-source-intake/references/rubric.md`.
It defines valid sources, case definitions, evidence tiers, quality flags, note schemas,
and the medical guardrail.

- **Search the corpus before the web.** Corpus notes record `evidence_tier`,
  `case_definition`, `pem_required`, `n`, and `quality_flags`. Prefer guideline,
  systematic-review, and rct notes for central claims. Never cite a note with
  `status: retracted` (or `retracted` in `quality_flags`) as evidence. A note with
  `status: new` (e.g. `intake: script`) has guessed fields: grade it through
  `mecfs-source-intake` before citing it.
- **Dedupe against rejections too.** Before fetching a candidate, check
  `Sources/🚫ME-CFS Rejected.md` and the `skipped:` list in `Sources/🔎ME-CFS Sweep Log.md`.
- **New research or first-person sources go through intake.** Follow the
  `mecfs-source-intake` procedure (dedupe, metadata, retraction check, gate, rubric
  frontmatter, filename) instead of the `📘 Docs Source` template. Rejected items go to
  `Sources/🚫ME-CFS Rejected.md` as that skill says. Peer-reviewed clinical statements,
  consensus papers, and commentaries by credentialed clinicians or researchers are in the
  rubric's scope (`🔬`, `evidence_tier: expert-opinion` or `guideline`). Patient-charity
  booklets and pages without a credentialed clinician author, and sources outside the
  rubric's scope (e.g. a physiology textbook page), use the generic `📘 Docs Source` template
  without the `mecfs` tag and live only in `Tech-2/Sources/` (research doesn't take them);
  footnotes call charity material "patient charity" guidance and charity polls "surveys",
  not studies.
- **Every corpus note you create gets `type`**, as a link: `[[🔬Research]]` for research,
  `[[🗣️First-person]]` for first-person accounts. Add it to the research original before
  copying, and to any Tech-2 copy that lacks it.
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
  r/covidlonghaulers, r/MECFS. The author is `r-<sub> member`, never a username. Mark
  passages on the `# Their account (paraphrased)` paragraphs (the privacy-preserving
  record, citable for what the person describes) and on the verbatim `# Quotes` (the
  only text that may appear in quotation marks). `# What helped` / `# What made it worse`
  are intake commentary.

## Writing pages
- Every page opens, right after the title, with:
  ```markdown
  >[!warning] Evidence log, not medical advice
  >This page explains what research found and what people report. It doesn't recommend
  >treatments. Talk through any change with a clinician who knows ME/CFS.
  ```
- "The evidence shows" / "people report", never "you should" or "try".
- Footnotes for cohort findings state the case definition, whether PEM was required, the
  evidence tier, n, and any `quality_flags` that bear on the claim (conflict of interest,
  industry funding, small n, preprint, correction): `**Keller 2024**, observational, n=84
  (CCC, PEM required); authors run the test for a fee`. Keep findings from cohorts
  without a PEM criterion (Fukuda, Oxford) apart from PEM-required cohorts in the prose
  too, and say which is which.
- When a page discusses a treatment with a `💊` note, state its `harm_signal: true` or
  `guideline_stance: not-recommended` if set.
- Name the evidence tier in prose for treatment claims ("one small RCT", "a preprint",
  "a registered trial with no results yet").
- Treat PACE-lineage CBT/GET work as history of the field: explain it and its critiques
  (cite both), don't present it as current evidence.
- Link treatments to the research vault's `💊` notes on first mention, with their
  guideline stance and harm signal read from the note's frontmatter, using `obsidian://`
  links, and to `💊 Treatments Overview` the same way. Leave `💊` notes themselves alone:
  `mecfs-synthesis` maintains them.
- **Tech-2 links:** its hub `[[🫩Myalgic Encephalomyelitis-Chronic Fatigue Syndrome (ME-CFS)]]`
  gets the "📘 New to ME/CFS?" callout and is the docs' `topics:` target; its
  `Topics.base` matches `type == link("📘 Docs Index")`, so the index shows under SubTopics.
- **Research links, via `obsidian://` to the Tech-2 docs:** research's hub (callout +
  nav line), `🏠 Home` (topic table), `📋 How to Use this` ("Where things are" table),
  and `💊 Treatments Overview` (nav line to the research page). The docs index links back
  to research's hub as "the graded research corpus".

## Extra reviewer checks (add to the brief)
- Guardrail: no recommendations, no "you should".
- Case definition and PEM status stated for cohort findings; no-PEM cohorts not
  presented as ME/CFS evidence without saying so.
- Evidence tier described accurately (a preprint isn't "a study showed", a registered
  trial has no results).
- Lived-experience boxes don't imply a treatment works.
- Retracted or ungraded (`status: new`) corpus notes aren't cited as evidence; footnotes
  carry the relevant `quality_flags`; treatment discussions state any harm signal or
  not-recommended guideline stance.
