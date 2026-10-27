import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

/**
 * Registers pi's model providers in omp, read from pi's models.json on each omp start.
 *
 * Replaces a ~/.omp/agent/models.yml symlink to the same file: omp checks models.yml
 * `compat` blocks against its own schema and warns on pi-only keys
 * (forceAdaptiveThinking, supportsToolSearch, ...), while runtime registrations are
 * not checked. Values pass through verbatim, so `!command` apiKeys resolve exactly
 * as they did from models.yml. pi edits (e.g. /refresh-models) apply on the next start.
 */
const PI_MODELS_PATH = join(homedir(), ".pi", "agent", "models.json");

interface PiModelsFile {
	providers?: Record<string, Parameters<ExtensionAPI["registerProvider"]>[1]>;
}

export default function piModels(pi: ExtensionAPI) {
	let raw: string;
	try {
		raw = readFileSync(PI_MODELS_PATH, "utf-8");
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return;
		throw error;
	}
	const { providers = {} } = JSON.parse(raw) as PiModelsFile;
	for (const [name, config] of Object.entries(providers)) {
		pi.registerProvider(name, config);
	}
}
