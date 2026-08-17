/**
 * PR Size Guard
 *
 * When `gh pr create` would open a PR larger than Saje's budget (400 lines /
 * 10 files), surfaces the size and asks for confirmation before proceeding.
 * Ported from ~/.claude/hooks/pr-size-guard.sh (Claude PreToolUse:Bash).
 *
 * Backstop for the small-PR discipline in AGENTS.md "Stacked PRs".
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const MAX_LINES = 400;
const MAX_FILES = 10;

/** Extract a leading `cd <path> && ...` so we measure the right repo. */
function extractCwd(command: string): string | undefined {
  const m = command.match(/^\s*cd\s+(\S+)\s*&&/);
  return m?.[1];
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return undefined;

    const command = (event.input.command as string) ?? "";
    // Only fire on an actual `gh pr create`.
    if (!/(^|[;&|\s])gh\s+pr\s+create([\s]|$)/.test(command)) return undefined;

    // Measure in the repo the command targets, not the session cwd.
    const cwd = extractCwd(command) ?? ctx.cwd;

    // Exception: the ai_config backup repo is exempt (config ports are
    // inherently large single-unit adds that don't split into vertical slices).
    try {
      const remote = await pi.exec("git", ["remote", "get-url", "origin"], { cwd, signal: ctx.signal, timeout: 5000 });
      if (remote.code === 0 && /ai_config/.test(remote.stdout)) return undefined;
    } catch { /* ignore */ }

    // Find the base branch to diff against.
    let base = "";
    for (const b of ["origin/main", "origin/master", "main", "master"]) {
      try {
        const r = await pi.exec("git", ["rev-parse", "--verify", "--quiet", b], { cwd, signal: ctx.signal, timeout: 5000 });
        if (r.code === 0 && r.stdout.trim()) { base = b; break; }
      } catch { /* ignore */ }
    }
    if (!base) return undefined;

    let stat = "";
    try {
      const r = await pi.exec("git", ["diff", "--shortstat", `${base}...HEAD`], { cwd, signal: ctx.signal, timeout: 5000 });
      stat = r.stdout;
    } catch { return undefined; }
    if (!stat) return undefined;

    const files = Number(stat.match(/(\d+) file/)?.[1] ?? 0);
    const ins = Number(stat.match(/(\d+) insertion/)?.[1] ?? 0);
    const del = Number(stat.match(/(\d+) deletion/)?.[1] ?? 0);
    const lines = ins + del;

    // Within budget — allow silently.
    if (lines <= MAX_LINES && files <= MAX_FILES) return undefined;

    const reason =
      `PR SIZE GUARD: this PR is ~${lines} changed lines across ${files} files vs ${base}, ` +
      `over Saje's budget (${MAX_LINES} lines / ${MAX_FILES} files). Per the Stacked-PRs rule, ` +
      `prefer splitting it into smaller stacked PRs. Open it anyway only if it genuinely can't be split ` +
      `(and you've told Saje the size + why).`;

    if (ctx.hasUI) {
      const choice = await ctx.ui.select(
        `⚠️ ${reason}`,
        ["Split into smaller PRs", "Open anyway"],
      );
      if (choice !== "Open anyway") return { block: true, reason: "Cancelled — split the PR instead" };
      return undefined;
    }
    // Non-interactive: block so it surfaces.
    return { block: true, reason };
  });
}
