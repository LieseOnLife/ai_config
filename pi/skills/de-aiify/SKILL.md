---
name: de-aiify
description: Rewrite text so it reads as written by Saje, not an AI. Strips AI tells (throat-clearing, inflated words, em-dash chains, padded lists of three, sign-offs), applies her writing-style profile when one exists, keeps every fact, and flags anything cut. Use for /de-aiify, "de-AI this", "make this sound like me", "strip the AI tells", and as the last pass before a draft written as Saje goes out.
---

# De-AI-ify

More human, not different: keep her meaning, change only the voice.

## 1. Get the text
Use the pasted text, the note or draft she points to, or ask: "What should I rewrite?" Say whether it's **formal** (a doc, proposal or PR description) or **informal** (Slack, a quick email), and ask if you can't tell.

## 2. Load her voice
Read `~/Obsidian/Tech-2/Topics/💡Writing Style.md` if it exists. Its direct rules and its register for this kind of text win over everything below. If it doesn't exist, use the defaults below and mention once that `/writing-style-setup` would make the rewrite closer to her voice.

## 3. Strip the tells
- Throat-clearing: "It's worth noting", "It's important to note", "In conclusion", "To summarize", "Let's dive in"
- Inflated words: "delve", "leverage" (as a verb), "robust", "seamless", "tapestry", "landscape" (as a metaphor), "game-changer", "cutting-edge", "best-in-class", "streamline"
- Filler connectors: "Furthermore", "Moreover", "Additionally" at the start of a sentence
- Sign-offs: "I hope this helps", "Let me know if you have any questions", "Happy to help"
- Chains of em dashes: split the sentence, or use a comma or a colon
- Padded lists of three, where two items say it all
- Bullets where a sentence or two reads better, and bold on every other phrase
- Describing the process ("I looked into this carefully") instead of stating the finding
- Hedge stacks ("might potentially", "could possibly")
- A summary at the end that repeats the opening

## 4. Keep the meaning
Keep every fact, number, link, name, decision and ask. If you cut something because it was filler, flag it: "Cut X because Y. Fine to leave out?"

## 5. Return
Return only the rewritten text, ready to paste, followed by the list of flagged cuts if there are any. If the text was already clean, say so and return it unchanged.

## Updating her profile
If she edits your rewrite, offer to record the correction with `/writing-style-setup` (its **Updating** section).
