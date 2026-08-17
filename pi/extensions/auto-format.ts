/**
 * Auto-Format on Edit
 *
 * After a file is written/edited, runs whichever formatter is installed for that
 * file type. Degrades silently when a tool is absent so it never blocks an edit.
 * Ported from ~/.claude/hooks/auto-format-on-edit.sh (Claude PostToolUse:Edit|Write).
 *
 * Appends a note to the tool result so the LLM knows to re-read the file if it
 * has the old contents cached.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { resolve } from "node:path";
import { execFileSync } from "node:child_process";

// Augmented PATH for formatter discovery (does NOT mutate process.env).
const PATH_EXTRA = [
  "/opt/homebrew/bin",
  "/usr/local/bin",
  process.env.HOME ? `${process.env.HOME}/go/bin` : "",
].filter(Boolean);

const FORMAT_ENV = { ...process.env, PATH: [...PATH_EXTRA, process.env.PATH ?? ""].join(":") } as Record<string, string | undefined>;

let gorootBin: string | undefined;

function has(bin: string): boolean {
  try {
    execFileSync("command", ["-v", bin], { stdio: "ignore", env: FORMAT_ENV, timeout: 2000 });
    return true;
  } catch {
    return false;
  }
}

async function run(pi: ExtensionAPI, bin: string, args: string[], signal: AbortSignal | undefined, timeoutMs = 10000): Promise<boolean> {
  try {
    const r = await pi.exec(bin, args, { signal, timeout: timeoutMs });
    return r.code === 0;
  } catch {
    return false;
  }
}

function hash(file: string): string {
  try {
    return createHash("sha1").update(readFileSync(file)).digest("hex");
  } catch {
    return "";
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return undefined;

    const raw = (event.input.path as string) ?? "";
    if (!raw) return undefined;
    // Resolve relative paths against the session cwd, not process.cwd().
    const f = resolve(ctx.cwd, raw);
    if (!existsSync(f)) return undefined;

    const before = hash(f);
    let note = "";

    switch (true) {
      case /\.go$/.test(f): {
        // Lazily discover GOROOT/bin once, on the first .go file.
        if (gorootBin === undefined) {
          try {
            const r = await pi.exec("go", ["env", "GOROOT"], { signal: ctx.signal, timeout: 3000 });
            gorootBin = r.code === 0 ? `${r.stdout.trim()}/bin` : "";
          } catch {
            gorootBin = "";
          }
        }
        if (gorootBin) FORMAT_ENV.PATH = `${gorootBin}:${FORMAT_ENV.PATH}`;
        if (has("goimports")) await run(pi, "goimports", ["-w", f], ctx.signal);
        else if (has("gofmt")) await run(pi, "gofmt", ["-w", f], ctx.signal);
        break;
      }
      case /\.(tf|tfvars)$/.test(f): {
        if (has("terraform")) await run(pi, "terraform", ["fmt", f], ctx.signal);
        else if (has("tofu")) await run(pi, "tofu", ["fmt", f], ctx.signal);
        break;
      }
      case /\.py$/.test(f): {
        if (has("ruff")) await run(pi, "ruff", ["format", f], ctx.signal);
        else if (has("black")) await run(pi, "black", ["-q", f], ctx.signal);
        break;
      }
      case /\.(sh|bash)$/.test(f): {
        if (has("shfmt")) await run(pi, "shfmt", ["-w", f], ctx.signal);
        break;
      }
      case /\.(js|jsx|ts|tsx|css|scss|md|yaml|yml)$/.test(f): {
        if (has("prettier")) await run(pi, "prettier", ["--write", f], ctx.signal);
        break;
      }
      case /\.json$/.test(f): {
        if (has("prettier")) await run(pi, "prettier", ["--write", f], ctx.signal);
        else if (has("jq")) {
          const r = await pi.exec("jq", ["-e", ".", f], { signal: ctx.signal, timeout: 5000 });
          if (r.code !== 0) note = `⚠️ ${f.split("/").pop()} is not valid JSON — fix it before relying on the file.`;
        }
        break;
      }
      default:
        return undefined;
    }

    const after = hash(f);
    if (note) {
      // keep note
    } else if (before !== after) {
      note = `🧹 Auto-formatted ${f.split("/").pop()}. If you have its contents cached, re-read before the next edit.`;
    } else {
      return undefined;
    }

    // Append the note to the tool result content so the LLM sees it.
    const content = Array.isArray(event.content) ? event.content : [];
    return {
      content: [
        ...content,
        { type: "text", text: note },
      ],
    };
  });
}
