// Keeps the kepano/obsidian-skills clone current; ~/.agents/skills and ~/.claude/skills symlink into it.
import { existsSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const REPO = join(homedir(), "repos", "obsidian-skills");
const DAY_MS = 24 * 60 * 60 * 1000;

let started = false;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (started) return;
		started = true;
		if (!existsSync(join(REPO, ".git"))) return;
		// git rewrites FETCH_HEAD on every fetch, so its mtime is the last pull.
		const fetchHead = join(REPO, ".git", "FETCH_HEAD");
		if (existsSync(fetchHead) && Date.now() - statSync(fetchHead).mtimeMs < DAY_MS) return;
		pi.exec("git", ["-C", REPO, "pull", "--ff-only", "--quiet"], { timeout: 60_000 }).then(
			(r) => {
				if (r.code !== 0) ctx.ui.notify(`obsidian-skills pull failed: ${r.stderr.trim()}`, "warning");
			},
			() => {},
		);
	});
}
