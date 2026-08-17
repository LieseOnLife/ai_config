/**
 * Terraform OTEL Protocol Fix
 *
 * Prefixes terraform invocations with OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf,
 * because Terraform only accepts 'grpc' or 'http/protobuf', not 'http/json'.
 * Ported from ~/.claude/hooks/terraform-otel-fix.sh (Claude PreToolUse:Bash).
 *
 * Implements the Claude hook's `{"decision":"replace","tool_input":{...}}` by
 * mutating event.input.command in place (pi's tool_call event supports this).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Single pattern for both detect and replace. The /m flag makes ^ match the
// start of every line (the original sed was line-based). \n[ \t]* covers a
// terraform on its own line within a multi-line bash block; &&/;/|| cover
// inline separators. `time terraform` and `TF_LOG=… terraform` are handled by
// the `\n[ \t]*` and separator alternatives.
const TF = /(^|&& *|; *|\|\| *|\n[ \t]*)terraform /gm;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash") return undefined;

    const command = (event.input.command as string) ?? "";
    if (!TF.test(command)) return undefined;
    // .test() on a /g regex advances lastIndex; reset before .replace().
    TF.lastIndex = 0;
    event.input.command = command.replace(
      TF,
      "$1OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf terraform ",
    );
    return undefined;
  });
}
