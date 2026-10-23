---
name: zed-review
description: Post-implementation walkthrough when running inside Zed's integrated terminal (ZED_TERM=true or TERM_PROGRAM=zed) — kick off async validation, open changed files in the existing Zed window, walk Saje through them. Use after implementation changes are complete in a Zed terminal session.
---

# Zed review walkthrough

Only when `ZED_TERM=true` or `TERM_PROGRAM=zed`. Outside Zed, never launch Zed automatically.

After implementation changes are complete:
1. Delegate tests and validation to an asynchronous subagent; don't wait for Saje's go-ahead to start them.
2. While validation runs, open all actively changed source and test files in the **existing** Zed window, batched into one command, without `-n`:
   ```bash
   /Applications/Zed.app/Contents/MacOS/cli "$ABS_PATH_1" "$ABS_PATH_2" ...
   ```
3. Walk Saje through the changes file by file: what changed, why, notable behavior or trade-offs, with file:line references where useful.

- Skip generated, vendored, lock, and incidental files unless Saje asks.
- Never open a new Zed window or the whole worktree.
