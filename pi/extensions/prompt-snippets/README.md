# Prompt snippets

Run `/reload` once after installing or editing the extension. Then use `/snippets` to toggle temporary instructions for the next message. Choose **Apply to next message** when finished. The selection is applied after skill or prompt-template expansion, consumed by the next idle interactive or RPC prompt, and then cleared.

To keep the instructions scoped to exactly one request, snippet-enabled prompts cannot be submitted as steering/follow-up messages, and additional user or extension messages are rejected until that run settles. If Pi rejects the prompt before the agent starts, run `/snippets recover`, then retry the request.

Snippet files live in `snippets/*.md`. Their first `#` heading is the selector label; the remaining Markdown is the instruction.

This extension intentionally registers no keyboard shortcut and makes no network calls.
