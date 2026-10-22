/**
 * Post-Push Protocol
 *
 * Detects `git push` in a bash tool result and injects the mandatory Post-Push
 * Protocol into context, so CI-watch + flake triage + PR-comment handling happen
 * automatically without the user having to ask.
 * Ported from ~/.claude/hooks/post-push-protocol.sh (Claude PostToolUse:Bash).
 *
 * The protocol itself lives in the `post-push-protocol` skill (single source).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PROTOCOL = `🔁 POST-PUSH PROTOCOL (automatic — you just ran \`git push\`). Load the \`post-push-protocol\` skill and run every step now, without being asked. PR checks go to the single \`PrWatch\` subagent: if it is still running, message it (\`write agent://PrWatch\`) with the PR + SHA — do NOT spawn another. The push is not "done" until CI is green (or escalated), major diffs are reviewed, and comments are handled.`;

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event) => {
    if (event.toolName !== "bash") return undefined;
    // Don't inject the protocol when the push failed/was rejected.
    if (event.isError) return undefined;

    const cmd = (event.input.command as string) ?? "";
    // Only fire on an actual `git push` (not `git push --help`, not strings that merely mention it).
    if (!/(^|[;&|\s])git\s+([^;&|]*\s)?push(\s|$)/.test(cmd)) return undefined;
    // Ignore explicit dry runs.
    if (/--dry-run/.test(cmd)) return undefined;

    // Append the protocol to the tool result so the LLM acts on it next turn.
    const content = Array.isArray(event.content) ? event.content : [];
    return {
      content: [
        ...content,
        { type: "text", text: PROTOCOL },
      ],
    };
  });
}
