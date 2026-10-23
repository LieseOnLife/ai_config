// Shared with pi: loads /Users/saje.liese/.pi/agent/extensions/post-push.ts through the pi-compat shim.
import ext from "/Users/saje.liese/.pi/agent/extensions/post-push.ts";
import { piCompat } from "../lib/pi-compat.ts";

export default function (pi: any) {
	return ext(piCompat(pi));
}
