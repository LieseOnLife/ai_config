/**
 * Adapts pi (@earendil-works/pi-coding-agent) extensions to omp's ExtensionAPI.
 * Source extensions stay in ~/.pi/agent/extensions so pi and omp share one copy.
 *
 * - `agent_settled` (pi-only) -> `agent_end` (fires when the agent loop finishes)
 * - `model_select` (pi-only) -> ignored
 */
const EVENT_MAP: Record<string, string | null> = {
	agent_settled: "agent_end",
	model_select: null,
};

export function piCompat<T extends { on: (...args: any[]) => any }>(pi: T): T {
	return new Proxy(pi, {
		get(target, prop, receiver) {
			if (prop === "on") {
				return (event: string, handler: unknown) => {
					const mapped = event in EVENT_MAP ? EVENT_MAP[event] : event;
					if (mapped === null) return;
					return target.on(mapped, handler);
				};
			}
			const value = Reflect.get(target, prop, receiver);
			return typeof value === "function" ? value.bind(target) : value;
		},
	});
}
