// Keeps upstream skill clones current; ~/.agents/skills and ~/.claude/skills symlink into them.
import { existsSync, rmSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// kepano/obsidian-skills and mattpocock/skills; each clone's origin must be HTTPS (see GIT_ENV).
const REPOS = ["obsidian-skills", "skills"].map((name) => join(homedir(), "repos", name));
const DAY_MS = 24 * 60 * 60 * 1000;

// Anonymous HTTPS with no prompts: the global gitconfig rewrites github.com to SSH (1Password).
const GIT_ENV = ["GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_NOSYSTEM=1", "GIT_TERMINAL_PROMPT=0"];

let started = false;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.agent.kind !== "main" || started) return;
		started = true;

		const abort = new AbortController();
		pi.on("session_shutdown", () => abort.abort());

		for (const repo of REPOS) {
			if (!existsSync(join(repo, ".git"))) continue;
			// git rewrites FETCH_HEAD on every fetch, so its mtime is the last pull.
			const fetchHead = join(repo, ".git", "FETCH_HEAD");
			if (existsSync(fetchHead) && Date.now() - statSync(fetchHead).mtimeMs < DAY_MS) continue;

			pi.exec("env", [...GIT_ENV, "git", "-C", repo, "pull", "--ff-only", "--quiet"], {
				timeout: 60_000,
				signal: abort.signal,
			})
				.then((r) => {
					if (abort.signal.aborted || r.code === 0) return;
					// A fetch that succeeded before a failed fast-forward still bumps FETCH_HEAD; retry next session.
					rmSync(fetchHead, { force: true });
					ctx.ui.notify(`${basename(repo)} pull failed: ${r.stderr.trim() || `exit ${r.code}`}`, "warning");
				})
				.catch(() => {});
		}
	});
}
