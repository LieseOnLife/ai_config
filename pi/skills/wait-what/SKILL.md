---
name: wait-what
description: "That last message didn't land: re-explain it plainly, then add the word that tripped me to my glossary."
disable-model-invocation: true
argument-hint: "The word or part you didn't follow (optional)"
---

Your last message didn't land. Re-pitch it, then fix the vocabulary gap so it doesn't happen again.

Glossary: `~/Obsidian/Tech-2/Topics/💡Glossary.md` (sections **My words** and **Agent words**, one `###` heading per term). If the repo has a `GLOSSARY.md`, read that too; it wins for that repo's terms.

1. **Read the glossary.** If I passed arguments, they name the part I didn't follow: aim at that.

2. **Re-pitch.** Use ASD-STE100 Simplified Technical English and the glossary's words:
   - First sentence: the outcome, meaning what changed or what you need from me.
   - Then only the context I'm missing to act on it. If an idea is abstract, give one concrete example (before/after, or a real value from this session).
   - Name things by what they do. A PR label, ticket ID, finding number, or codename comes after a one-line description of it, never in place of one.
   - Shorter than the original. If the original asked me to decide, end with the choice and your recommendation.

   Done when I could act on it without scrolling back.

3. **Find the word that tripped me.** Name the term, acronym, label, or coinage that caused the miss. If several caused it, name up to three.

4. **Propose glossary entries.** Draft one for each reusable term that isn't in the glossary yet. Skip one-off PR labels, ticket IDs, and finding numbers: the step 2 rule covers those.
   - My domain terms (a system, pool concept, team or process, workflow shorthand, or tool or repo) go under the matching **My words** subheading.
   - Agent jargon goes under **Agent words**, with `*Say:*` giving the plain phrase to use instead.
   - Format: `### Term`, then one or two sentences on what it **is**, then an optional `*Avoid:*` or `*Say:*` line. Ground it in the code, docs, or this session. Mark anything you couldn't check `[UNVERIFIED]`.

   If the term is already there but your message used it differently, quote the entry and ask which meaning is right.

5. **Ask, then write.** Show the drafts and ask whether to add them. Once I say yes, edit `💡Glossary.md` in place: insert under the right heading and set the frontmatter `updated:` to today.
