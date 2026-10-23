import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { readdir, readFile } from "node:fs/promises";
import { basename, join } from "node:path";

const SNIPPETS_DIR = join(import.meta.dirname, "snippets");
const DONE_OPTION = "Apply to next message";
const CLEAR_OPTION = "Clear selection";

export interface PromptSnippet {
  id: string;
  label: string;
  instruction: string;
}

export interface SnippetCatalog {
  snippets: PromptSnippet[];
  failures: string[];
}

export function parseSnippet(id: string, markdown: string): PromptSnippet | undefined {
  const lines = markdown.replaceAll("\r\n", "\n").split("\n");
  const headingIndex = lines.findIndex((line) => line.trim().startsWith("# "));
  const label = headingIndex >= 0 ? lines[headingIndex]!.trim().slice(2).trim() : basename(id, ".md");
  const instruction = lines
    .filter((_line, index) => index !== headingIndex)
    .join("\n")
    .trim();

  if (!label || !instruction) return undefined;
  return { id, label, instruction };
}

export async function loadSnippetCatalog(directory = SNIPPETS_DIR): Promise<SnippetCatalog> {
  let names: string[];
  try {
    names = await readdir(directory);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    return { snippets: [], failures: [`Could not read ${directory}: ${reason}`] };
  }

  const snippets: PromptSnippet[] = [];
  const failures: string[] = [];
  await Promise.all(
    names
      .filter((name) => name.endsWith(".md"))
      .sort((a, b) => a.localeCompare(b))
      .map(async (name) => {
        try {
          const snippet = parseSnippet(name, await readFile(join(directory, name), "utf8"));
          if (snippet) snippets.push(snippet);
          else failures.push(`${name} has no instruction`);
        } catch (error) {
          const reason = error instanceof Error ? error.message : String(error);
          failures.push(`${name}: ${reason}`);
        }
      }),
  );

  snippets.sort((a, b) => a.id.localeCompare(b.id));
  failures.sort((a, b) => a.localeCompare(b));
  return { snippets, failures };
}

export async function loadSnippets(directory = SNIPPETS_DIR): Promise<PromptSnippet[]> {
  return (await loadSnippetCatalog(directory)).snippets;
}

export function applySnippets(systemPrompt: string, snippets: PromptSnippet[]): string {
  if (snippets.length === 0) return systemPrompt;

  const instructions = snippets.map((snippet) => `- ${snippet.instruction}`).join("\n");
  return `${systemPrompt}\n\n<temporary_prompt_snippets>\nApply these instructions to the current user request only:\n${instructions}\n</temporary_prompt_snippets>`;
}

function optionFor(snippet: PromptSnippet, selected: Set<string>): string {
  return `${selected.has(snippet.id) ? "[x]" : "[ ]"} ${snippet.label} · ${snippet.id}`;
}

async function chooseSnippets(
  ctx: ExtensionCommandContext,
  snippets: PromptSnippet[],
  initiallySelected: Set<string>,
): Promise<Set<string> | undefined> {
  const selected = new Set(initiallySelected);

  while (true) {
    const choices = snippets.map((snippet) => optionFor(snippet, selected));
    choices.push(`${DONE_OPTION} (${selected.size} selected)`, CLEAR_OPTION);

    const choice = await ctx.ui.select("Prompt snippets for the next message", choices);
    if (choice === undefined) return undefined;
    if (choice.startsWith(DONE_OPTION)) return selected;
    if (choice === CLEAR_OPTION) {
      selected.clear();
      continue;
    }

    const snippet = snippets.find((candidate) => optionFor(candidate, selected) === choice);
    if (!snippet) continue;
    if (selected.has(snippet.id)) selected.delete(snippet.id);
    else selected.add(snippet.id);
  }
}

export default function promptSnippetsExtension(pi: ExtensionAPI): void {
  let pendingSnippets: PromptSnippet[] = [];
  let armedSnippets: PromptSnippet[] | undefined;
  let snippetRequestStarting = false;
  let snippetRunActive = false;
  let selectorOpen = false;

  pi.registerCommand("snippets", {
    description: "Choose temporary instructions for the next message, or recover a failed request",
    handler: async (args, ctx) => {
      if (!ctx.hasUI) {
        console.error("/snippets requires an interactive Pi session");
        return;
      }

      if (args.trim() === "recover") {
        if (snippetRunActive) {
          ctx.ui.notify("The snippet-enabled request is still running", "warning");
          return;
        }
        if (!snippetRequestStarting || armedSnippets === undefined) {
          ctx.ui.notify("There are no snippets to recover", "info");
          return;
        }

        pendingSnippets = [...armedSnippets, ...pendingSnippets];
        armedSnippets = undefined;
        snippetRequestStarting = false;
        ctx.ui.notify("Recovered prompt snippets for the next idle request", "info");
        return;
      }

      if (snippetRequestStarting) {
        ctx.ui.notify("A snippet-enabled request is starting; use /snippets recover only if its preflight failed", "warning");
        return;
      }
      if (selectorOpen) {
        ctx.ui.notify("A prompt-snippet selector is already open", "warning");
        return;
      }

      selectorOpen = true;
      try {
        const catalog = await loadSnippetCatalog();
        if (catalog.failures.length > 0) {
          ctx.ui.notify(`Skipped ${catalog.failures.length} unreadable or invalid snippet file${catalog.failures.length === 1 ? "" : "s"}`, "warning");
        }

        const snippetsById = new Map<string, PromptSnippet>();
        for (const snippet of [...pendingSnippets, ...catalog.snippets]) snippetsById.set(snippet.id, snippet);
        const snippets = [...snippetsById.values()].sort((a, b) => a.id.localeCompare(b.id));
        if (snippets.length === 0) {
          ctx.ui.notify(`No prompt snippets found in ${SNIPPETS_DIR}`, "warning");
          return;
        }

        const selection = await chooseSnippets(ctx, snippets, new Set(pendingSnippets.map((snippet) => snippet.id)));
        if (selection === undefined) return;

        pendingSnippets = snippets.filter((snippet) => selection.has(snippet.id));
        if (pendingSnippets.length === 0) {
          ctx.ui.notify("Prompt snippets cleared", "info");
        } else {
          ctx.ui.notify(
            `${pendingSnippets.length} prompt snippet${pendingSnippets.length === 1 ? "" : "s"} queued for the next message`,
            "info",
          );
        }
      } finally {
        selectorOpen = false;
      }
    },
  });

  pi.on("input", (event, ctx) => {
    if (event.source === "extension") {
      if (!snippetRequestStarting && !snippetRunActive) return { action: "continue" };
      if (ctx.hasUI) {
        ctx.ui.notify("Blocked extension-generated input during a snippet-enabled request", "warning");
      }
      return { action: "handled" };
    }

    if (snippetRequestStarting || snippetRunActive) {
      if (ctx.hasUI) {
        ctx.ui.notify("Wait for the snippet-enabled request to finish before sending another message", "warning");
      }
      return { action: "handled" };
    }

    if (pendingSnippets.length === 0) return { action: "continue" };
    if (event.streamingBehavior !== undefined) {
      if (ctx.hasUI) {
        ctx.ui.notify("Prompt snippets are queued; send the next message after the current run finishes", "warning");
      }
      return { action: "handled" };
    }

    armedSnippets = pendingSnippets;
    pendingSnippets = [];
    snippetRequestStarting = true;
    return { action: "continue" };
  });

  pi.on("before_agent_start", (event) => {
    if (armedSnippets === undefined) return undefined;

    const snippets = armedSnippets;
    armedSnippets = undefined;
    snippetRequestStarting = false;
    snippetRunActive = true;
    return { systemPrompt: applySnippets(event.systemPrompt, snippets) };
  });

  pi.on("agent_settled", () => {
    snippetRequestStarting = false;
    snippetRunActive = false;
  });
}
