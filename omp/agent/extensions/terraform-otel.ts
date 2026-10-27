// Shared with pi: loads /Users/saje.liese/.pi/agent/extensions/terraform-otel.ts through the pi-compat shim.
import ext from "/Users/saje.liese/.pi/agent/extensions/terraform-otel.ts";
import { piCompat } from "../lib/pi-compat.ts";

export default function (pi: any) {
	return ext(piCompat(pi));
}
