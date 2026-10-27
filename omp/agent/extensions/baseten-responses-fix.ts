import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

/**
 * Fix Baseten 400s on the openai-responses wire (GLM-5.2/5.3, DeepSeek, ...).
 * Source: "Using oh-my-pi in Datadog with AI Gateway" (Confluence, Oliver Li).
 * Synthesizes `id` (and `status` on messages) for Baseten-routed requests only.
 */
const BASETEN_HOST_MARKERS = ["baseten.co"] as const;
const BASETEN_ID_PREFIX = "baseten/";

interface ResponseInputItem {
	type?: string;
	role?: string;
	id?: unknown;
	status?: unknown;
	content?: unknown;
	[key: string]: unknown;
}

export default function basetenResponsesFix(pi: ExtensionAPI) {
	pi.on("before_provider_request", async (event, ctx) => {
		const payload = event.payload as { input?: unknown } & Record<string, unknown>;
		if (!Array.isArray(payload?.input)) return;

		const model = ctx.model as { api?: string; id?: string; baseUrl?: string } | undefined;
		if (model?.api !== "openai-responses") return;
		const baseUrl = model.baseUrl ?? "";
		const isBasetenRouted =
			BASETEN_HOST_MARKERS.some(marker => baseUrl.includes(marker)) ||
			model.id?.startsWith(BASETEN_ID_PREFIX) === true;
		if (!isBasetenRouted) return;

		const input = payload.input as ResponseInputItem[];
		let seq = 0;
		let modified = false;
		const patched = input.map(item => {
			if (item?.type === "reasoning" && typeof item.id !== "string") {
				modified = true;
				return { ...item, id: `rs_bx_${Date.now().toString(36)}_${seq++}` };
			}
			const isAssistantOutputMessage =
				item?.type === "message" &&
				item.role === "assistant" &&
				Array.isArray(item.content) &&
				(item.content as Array<{ type?: string }>).some(part => part?.type === "output_text");
			if (!isAssistantOutputMessage) return item;
			const hasId = typeof item.id === "string";
			const hasStatus =
				item.status === "in_progress" || item.status === "completed" || item.status === "incomplete";
			if (hasId && hasStatus) return item;
			modified = true;
			return {
				...item,
				id: hasId ? item.id : `msg_bx_${Date.now().toString(36)}_${seq++}`,
				status: hasStatus ? item.status : "completed",
			};
		});
		if (!modified) return;
		return { ...payload, input: patched };
	});
}
