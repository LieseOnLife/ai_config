# Worktree Workflow Update

Copy and paste everything below into an existing Claude session:

---

## New Git Worktree Rules

I've updated my workflow for git branches and worktrees. Please follow these rules:

### Creating Branches
**Always use `git worktree` instead of `git switch`, `git checkout -b`, or `git branch`:**
```bash
# Create new branch with worktree
git worktree add ../saje/feature-name -b saje/feature-name
```

All branches must be prefixed with `saje/`.

### Worktree Conflicts
If a worktree/branch exists, create a new version (e.g., `saje/feature-v2`). Never delete existing worktrees without my approval.

### Spawning Subagents in Worktrees
When using the Task tool for work in a worktree:

1. First get worktree context:
```bash
~/.pi/agent/scripts/worktree-context.sh
```

2. Include in the subagent prompt:
```
Working directory: /full/path/to/worktree
Branch: saje/feature-name

CRITICAL: cd to the working directory before any operations.
```

3. Subagents must use absolute paths and `cd` to the worktree first.

### Deleting Worktrees/Branches
All deletions require my explicit approval. If you need to delete, ask me first, then prefix the command:
```bash
# APPROVED: git worktree remove /path/to/worktree
```

Use `/worktree-cleanup` for guided cleanup with approval flow.

### Cleanup Script
To see worktree status and cleanup candidates:
```bash
~/.pi/agent/scripts/worktree-cleanup.sh
```

### GitHub Operations
**Always use `gh` CLI instead of `git` for GitHub operations:**
- PRs: `gh pr create`, `gh pr view`, `gh pr merge`
- Issues: `gh issue create`, `gh issue view`
- Repos: `gh repo view`, `gh api`

Never use raw git commands for GitHub-specific operations when `gh` can do it.

---
