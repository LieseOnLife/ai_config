/**
 * Git Worktree Guard
 *
 * Blocks deletion of worktrees and branches without explicit approval.
 * Ported from ~/.claude/hooks/git-worktree-guard.sh (Claude PreToolUse:Bash).
 *
 * A command prefixed with `# APPROVED:` is allowed through. `git worktree prune`
 * is always safe (only cleans references to missing directories).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DELETION_PATTERNS: RegExp[] = [
  /git worktree remove/,
  /git branch -d/,
  /git branch -D/,
  /git branch --delete/,
  /git push.*--delete/,
  /git push\s+\S+\s+:/, // push with colon prefix deletes remote branch
];

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return undefined;

    const command = (event.input.command as string) ?? "";

    // Explicitly approved — let it through.
    if (command.trimStart().startsWith("# APPROVED:")) return undefined;

    // prune only cleans references to missing directories — safe.
    if (/^git worktree prune$/.test(command.trim())) return undefined;

    for (const pattern of DELETION_PATTERNS) {
      if (pattern.test(command)) {
        const target =
          command.match(/git worktree remove\s+(\S+)/)?.[1] ??
          command.match(/git branch\s+-[dD]\s+(\S+)/)?.[1] ??
          "";

        const reason = [
          "🛑 BLOCKED: Worktree/branch deletion requires approval",
          "",
          `Command: ${command}`,
          target ? `Target: ${target}` : "",
          "",
          "To proceed, get user approval then prefix with '# APPROVED:':",
          `  # APPROVED: ${command}`,
          "",
          "Or use /worktree-cleanup for guided cleanup with approval flow.",
        ]
          .filter(Boolean)
          .join("\n");

        if (ctx.hasUI) ctx.ui.notify("🛑 Worktree/branch deletion blocked", "warning");
        return { block: true, reason };
      }
    }

    return undefined;
  });
}
