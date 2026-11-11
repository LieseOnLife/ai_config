---
name: brainstorm
description: "Think a topic through with Saje before anything gets made: the thing she's mulling over, or the thing she wants to produce. Asks one question at a time, plays back what it understood, generates options for her to cut down, and ends in a plan or outline. Saves only when she says where; hands code changes to OpenSpec."
disable-model-invocation: true
argument-hint: "What you're thinking about, or what you want to produce"
---

# Brainstorm

Sharpen her thinking; don't produce the output early. The topic comes with the command (`/brainstorm <topic>`). If it came without one, ask for it and stop there.

Use plain words. Saje's glossary is `~/Obsidian/Tech-2/Topics/💡Glossary.md`: use her **My words** as they are, and say the plain phrase for its **Agent words**.

## 1. Read the topic
Decide which of these it is, and say it in one line ("Sounds like you want to produce X; let's get clear on it first."):
- **Something she's mulling over:** a problem, a decision, a stuck spot, an idea. The goal is clearer thinking and a next step.
- **Something she wants to produce:** a doc, a talk, a plan, a tool, a message. The goal is a clear picture of the finished thing, and then an outline.

Then ask one open question that gets her describing, anchored in a real moment: "What happened that made you want this?" or "Who reads it, and what should they do afterwards?"

## 2. The conversation
- **One question per message.** End every message with a single question, with no list of sample answers hanging off it.
- **Get her describing before you offer options.** Options steer. A guess she can correct ("I'm guessing this is because X keeps breaking?") often beats a question.
- **Push back** when an answer is vague or the logic is shaky. Ask for the specific case.
- **Cover the ground without reading it out:** why now, what success looks like, what would make it a failure even if it technically works, what she's tried, constraints and deadlines, who it's for.
- **Offer to look things up** once you know enough to search well, and say what you'd look for. Work topics: the vault, Jira, Slack, Confluence, the code. Personal topics: the vault only, never Slack or Jira. She decides whether you go.

## 3. Play it back
As soon as you understand one part, describe it back in a short paragraph. Mark your guesses as yours; only what she said counts as hers. End the paragraph by asking what's wrong or missing, then move to the next part.

## 4. Options, when she wants them
When she asks for ideas, or the conversation needs them, work out several privately and drop the weak ones. Show 5 to 15 numbered options, then let her curate: "Keep 1, 4, 7", "Drop 3", "Combine 2 and 5". Use her choices to aim the next round. When she says "just pick", pick one and give the reason in one line.

## 5. Land it
Once the goal is clear, lay out *her* thinking as one of these:
- **Mulling:** the decision or insight in a sentence, the trade-off she's accepting, and the smallest next step.
- **Producing:** an outline of the finished thing, with the open questions listed.

Then ask: "Want me to draft from this?" Draft only after a yes.

Hand off when the topic points to one of these:
- **A code change in a repo:** offer `openspec-explore` to keep exploring, or `openspec-propose` to write the change up.
- **A Confluence page:** `create-documentation`.
- **A decision log:** `create-decision-log`.
- **A doc others will read closely:** draft it section by section as `doc-coauthoring` does: list options, she curates, you draft, she edits.

## Saving
Save only when she says to, and only where she says: today's daily note, a `Topics/` note, a project note, or anywhere else she names. If she says "save it" without a place, ask where. Write the plan or outline, not the whole conversation. Frontmatter gets `authorship: mixed`, and the note follows `create-note`'s conventions.

## Don't
- Draft before she says yes, even if her first message asks for the output. Say "A few questions first so I get this right," then ask.
- Ask more than one question per message.
- Treat your guesses as decisions she made.
