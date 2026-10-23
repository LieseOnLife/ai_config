import { afterEach, describe, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import promptSnippetsExtension, { applySnippets, loadSnippetCatalog, parseSnippet } from "./index";

type InputEvent = {
  source: "interactive" | "rpc" | "extension";
  text: string;
  images?: unknown[];
  streamingBehavior?: "steer" | "followUp";
};
type BeforeAgentStartEvent = { prompt: string; systemPrompt: string };
type EventContext = {
  hasUI: boolean;
  isIdle: () => boolean;
  ui: { notify: (message: string, level: string) => void };
};
type Handler = (...args: never[]) => unknown;
type Command = { handler: (args: string, ctx: CommandContext) => Promise<void> };
type CommandContext = {
  hasUI: boolean;
  ui: {
    select: (title: string, choices: string[]) => Promise<string | undefined>;
    notify: (message: string, level: string) => void;
  };
};

const temporaryDirectories: string[] = [];
afterEach(async () => {
  await Promise.all(temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })));
});

function setupExtension() {
  const commands = new Map<string, Command>();
  const events = new Map<string, Handler>();
  const pi = {
    registerCommand(name: string, command: Command) {
      commands.set(name, command);
    },
    on(name: string, handler: Handler) {
      events.set(name, handler);
    },
  };
  promptSnippetsExtension(pi as never);
  const defaultEventContext: EventContext = { hasUI: true, isIdle: () => true, ui: { notify: () => undefined } };
  const inputHandler = events.get("input")! as unknown as (
    event: InputEvent,
    ctx: EventContext,
  ) => { action: "continue" | "handled" };
  return {
    command: commands.get("snippets")!,
    input: (event: InputEvent, ctx = defaultEventContext) => inputHandler(event, ctx),
    beforeAgentStart: events.get("before_agent_start")! as unknown as (
      event: BeforeAgentStartEvent,
    ) => { systemPrompt: string } | undefined,
    agentSettled: events.get("agent_settled")! as unknown as () => void,
  };
}

function contextWithChoices(choices: Array<string | undefined>, notifications: string[] = []): CommandContext {
  return {
    hasUI: true,
    ui: {
      select: async () => choices.shift(),
      notify: (message) => notifications.push(message),
    },
  };
}

const VERIFY_OPTION = "[ ] Verify rather than assume · verify-not-assume.md";
const VERIFY_SELECTED_OPTION = "[x] Verify rather than assume · verify-not-assume.md";

async function queueVerify(command: Command, notifications: string[] = []) {
  await command.handler("", contextWithChoices([VERIFY_OPTION, "Apply to next message (1 selected)"], notifications));
}

describe("parseSnippet", () => {
  test("uses the first heading as the label", () => {
    expect(parseSnippet("failure-modes.md", "# Focus on failure modes\n\nCheck rollback paths.\n")).toEqual({
      id: "failure-modes.md",
      label: "Focus on failure modes",
      instruction: "Check rollback paths.",
    });
  });

  test("falls back to the filename when no heading exists", () => {
    expect(parseSnippet("plain-language.md", "Explain this plainly.")).toEqual({
      id: "plain-language.md",
      label: "plain-language",
      instruction: "Explain this plainly.",
    });
  });

  test("ignores empty snippets", () => {
    expect(parseSnippet("empty.md", "# Empty\n")).toBeUndefined();
  });
});

describe("loadSnippetCatalog", () => {
  test("keeps readable snippets when another markdown entry cannot be read", async () => {
    const directory = await mkdtemp(join(tmpdir(), "prompt-snippets-"));
    temporaryDirectories.push(directory);
    await writeFile(join(directory, "good.md"), "# Good\n\nCheck the evidence.\n");
    await mkdir(join(directory, "bad.md"));

    const catalog = await loadSnippetCatalog(directory);

    expect(catalog.snippets.map((snippet) => snippet.id)).toEqual(["good.md"]);
    expect(catalog.failures).toHaveLength(1);
    expect(catalog.failures[0]).toContain("bad.md");
  });
});

describe("applySnippets", () => {
  test("leaves the system prompt unchanged without snippets", () => {
    expect(applySnippets("System prompt", [])).toBe("System prompt");
  });

  test("appends selected instructions to the system prompt", () => {
    const result = applySnippets("System prompt", [
      { id: "verify.md", label: "Verify", instruction: "Verify important claims." },
      { id: "plain.md", label: "Plain", instruction: "Explain plainly." },
    ]);

    expect(result).toContain("Apply these instructions to the current user request only:");
    expect(result).toContain("- Verify important claims.\n- Explain plainly.");
  });
});

describe("extension lifecycle", () => {
  test("applies a selection after expansion and consumes it once", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    const notifications: string[] = [];
    await queueVerify(command, notifications);

    expect(input({ source: "interactive", text: "/skill:example" })).toEqual({ action: "continue" });
    const first = beforeAgentStart({ prompt: "Expanded skill content", systemPrompt: "System prompt" });
    const second = beforeAgentStart({ prompt: "Another request", systemPrompt: "System prompt" });

    expect(first?.systemPrompt).toContain("Verify important claims against available source code");
    expect(second).toBeUndefined();
    expect(notifications).toEqual(["1 prompt snippet queued for the next message"]);
  });

  test("does not arm snippets for extension-generated input", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    await queueVerify(command);

    expect(input({ source: "extension", text: "Internal follow-up" })).toEqual({ action: "continue" });
    expect(beforeAgentStart({ prompt: "Internal follow-up", systemPrompt: "System prompt" })).toBeUndefined();

    expect(input({ source: "rpc", text: "User request" })).toEqual({ action: "continue" });
    expect(beforeAgentStart({ prompt: "User request", systemPrompt: "System prompt" })?.systemPrompt).toContain(
      "Verify important claims",
    );
  });

  test("cancelling a later selector preserves the queued selection", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    await queueVerify(command);
    await command.handler("", contextWithChoices([undefined]));

    input({ source: "interactive", text: "Investigate" });
    expect(beforeAgentStart({ prompt: "Investigate", systemPrompt: "System prompt" })?.systemPrompt).toContain(
      "Verify important claims",
    );
  });

  test("an explicit empty selection clears queued snippets", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    await queueVerify(command);
    await command.handler("", contextWithChoices([VERIFY_SELECTED_OPTION, "Apply to next message (0 selected)"]));

    input({ source: "interactive", text: "Investigate" });
    expect(beforeAgentStart({ prompt: "Investigate", systemPrompt: "System prompt" })).toBeUndefined();
  });

  test("disambiguates duplicate labels with filenames", async () => {
    const { command } = setupExtension();
    const seenChoices: string[][] = [];
    await command.handler("", {
      hasUI: true,
      ui: {
        select: async (_title, choices) => {
          seenChoices.push(choices);
          return undefined;
        },
        notify: () => undefined,
      },
    });

    const snippetOptions = seenChoices[0]!.filter((choice) => choice.startsWith("["));
    expect(new Set(snippetOptions).size).toBe(snippetOptions.length);
    expect(snippetOptions.every((choice) => choice.includes(".md"))).toBeTrue();
  });

  test("preserves queued snippets when input arrives during streaming", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    const notifications: string[] = [];
    await queueVerify(command);
    const context: EventContext = {
      hasUI: true,
      isIdle: () => true,
      ui: { notify: (message) => notifications.push(message) },
    };

    expect(input({ source: "interactive", text: "Steer this", streamingBehavior: "steer" }, context)).toEqual({
      action: "handled",
    });
    expect(input({ source: "interactive", text: "Now investigate" }, context)).toEqual({ action: "continue" });
    expect(beforeAgentStart({ prompt: "Now investigate", systemPrompt: "System prompt" })?.systemPrompt).toContain(
      "Verify important claims",
    );
    expect(notifications).toContain("Prompt snippets are queued; send the next message after the current run finishes");
  });

  test("blocks additional user messages until the snippet-enabled run settles", async () => {
    const { command, input, beforeAgentStart, agentSettled } = setupExtension();
    const notifications: string[] = [];
    await queueVerify(command);
    const context: EventContext = {
      hasUI: true,
      isIdle: () => true,
      ui: { notify: (message) => notifications.push(message) },
    };

    expect(input({ source: "rpc", text: "First request" }, context)).toEqual({ action: "continue" });
    beforeAgentStart({ prompt: "First request", systemPrompt: "System prompt" });
    expect(input({ source: "rpc", text: "Second request", streamingBehavior: "followUp" }, context)).toEqual({
      action: "handled",
    });
    expect(input({ source: "extension", text: "Internal follow-up", streamingBehavior: "followUp" }, context)).toEqual({
      action: "handled",
    });

    agentSettled();
    expect(input({ source: "rpc", text: "Second request" }, context)).toEqual({ action: "continue" });
    expect(notifications).toContain("Wait for the snippet-enabled request to finish before sending another message");
  });

  test("rejects overlapping RPC input even when preflight still reports idle", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    await queueVerify(command);
    const preflightContext: EventContext = { hasUI: true, isIdle: () => true, ui: { notify: () => undefined } };

    expect(input({ source: "rpc", text: "First request" }, preflightContext)).toEqual({ action: "continue" });
    expect(input({ source: "rpc", text: "Overlapping request" }, preflightContext)).toEqual({ action: "handled" });
    expect(input({ source: "extension", text: "Internal request" }, preflightContext)).toEqual({ action: "handled" });
    expect(beforeAgentStart({ prompt: "First request", systemPrompt: "System prompt" })?.systemPrompt).toContain(
      "Verify important claims",
    );
  });

  test("recovers snippets explicitly when an armed request fails before agent start", async () => {
    const { command, input, beforeAgentStart } = setupExtension();
    const notifications: string[] = [];
    const context = contextWithChoices([], notifications);
    await queueVerify(command);

    expect(input({ source: "rpc", text: "Rejected before start" })).toEqual({ action: "continue" });
    await command.handler("recover", context);
    expect(input({ source: "rpc", text: "Retry after preflight failure" })).toEqual({ action: "continue" });
    expect(beforeAgentStart({ prompt: "Retry after preflight failure", systemPrompt: "System prompt" })?.systemPrompt).toContain(
      "Verify important claims",
    );
    expect(notifications).toContain("Recovered prompt snippets for the next idle request");
  });

  test("rejects a concurrent selector", async () => {
    const { command } = setupExtension();
    const notifications: string[] = [];
    let finishFirst!: (choice: string | undefined) => void;
    let markStarted!: () => void;
    const started = new Promise<void>((resolve) => {
      markStarted = resolve;
    });
    const first = command.handler("", {
      hasUI: true,
      ui: {
        select: async () => {
          markStarted();
          return new Promise<string | undefined>((resolve) => {
            finishFirst = resolve;
          });
        },
        notify: (message) => notifications.push(message),
      },
    });

    await started;
    await command.handler("", contextWithChoices([], notifications));
    finishFirst(undefined);
    await first;

    expect(notifications).toContain("A prompt-snippet selector is already open");
  });
});
