# Worktree-Aware Subagent Template

Use this template when spawning subagents that need to work in a git worktree.

## Prompt Template

```
## Working Directory Context
- **Worktree Path**: {WORKTREE_PATH}
- **Branch**: {BRANCH}
- **Main Repo**: {MAIN_REPO}

CRITICAL: All operations MUST be performed in the worktree directory.
- Always `cd {WORKTREE_PATH}` before any git or file operations
- Use absolute paths for all file reads/writes
- Do NOT operate in the main repo directory

## Your Task
{TASK_DESCRIPTION}

## First Steps
1. Verify you're in the correct directory:
   ```bash
   cd {WORKTREE_PATH} && pwd && git status
   ```
2. Then proceed with the task.
```

## Example Usage

Before spawning, gather context:
```bash
CONTEXT=$(~/.pi/agent/scripts/worktree-context.sh)
WORKTREE_PATH=$(echo $CONTEXT | jq -r '.worktree_path')
BRANCH=$(echo $CONTEXT | jq -r '.branch')
MAIN_REPO=$(echo $CONTEXT | jq -r '.main_repo')
```

Then include in your Task prompt:
```
Working directory: $WORKTREE_PATH
Branch: $BRANCH
Main repo: $MAIN_REPO

CRITICAL: cd to $WORKTREE_PATH before any operations.

Task: Implement feature X...
```

## Permissions

If subagents are blocked, ensure these paths are in permissions:
- The worktree path itself
- Parent directories that worktrees are created in (e.g., `/Users/saje.liese/go/src/github.com/DataDog/`)
