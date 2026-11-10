// Keeps the kepano/obsidian-skills clone current; ~/.agents/skills and ~/.claude/skills symlink into it.
import { existsSync, rmSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const REPO = join(homedir(), "repos", "obsidian-skills");
const FETCH_HEAD = join(REPO, ".git", "FETCH_HEAD");
const DAY_MS = 24 * 60 * 60 * 1000;

// Anonymous HTTPS with no prompts: the global gitconfig rewrites github.com to SSH (1Password).
const GIT_ENV = ["GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_NOSYSTEM=1", "GIT_TERMINAL_PROMPT=0"];

let started = false;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.agent.kind !== "main" || started) return;
		started = true;
		if (!existsSync(join(REPO, ".git"))) return;
		// git rewrites FETCH_HEAD on every fetch, so its mtime is the last pull.
		if (existsSync(FETCH_HEAD) && Date.now() - statSync(FETCH_HEAD).mtimeMs < DAY_MS) return;

		const abort = new AbortController();
		pi.on("session_shutdown", () => abort.abort());
		pi.exec("env", [...GIT_ENV, "git", "-C", REPO, "pull", "--ff-only", "--quiet"], {
			timeout: 60_000,
			signal: abort.signal,
		})
			.then((r) => {
				if (abort.signal.aborted || r.code === 0) return;
				// A fetch that succeeded before a failed fast-forward still bumps FETCH_HEAD; retry next session.
				rmSync(FETCH_HEAD, { force: true });
				ctx.ui.notify(`obsidian-skills pull failed: ${r.stderr.trim() || `exit ${r.code}`}`, "warning");
			})
			.catch(() => {});
	});
}
