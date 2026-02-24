---
name: worktree-cleanup
description: List worktrees and their status, identify candidates for cleanup, and remove with approval.
---

# Worktree Cleanup

Clean up old git worktrees safely with user approval.

## Process

### Step 1: Run Status Report
```bash
~/.claude/scripts/worktree-cleanup.sh
```

This shows all worktrees with:
- Path and branch name
- Whether merged into main/master
- Whether clean or dirty (uncommitted changes)
- Last commit date
- Recommendations for each

### Step 2: Present Cleanup Candidates
Show the user which worktrees are safe to remove:
- **Safe**: Merged into main AND clean (no uncommitted changes)
- **Caution**: Has uncommitted changes (warn user)
- **Prune**: Directory is missing (safe to prune reference)

### Step 3: Get Explicit Approval
For each worktree to remove, ask:
> "Remove worktree `{path}` (branch: `{branch}`)? This will delete the directory and can optionally delete the branch."

Options:
1. Remove worktree only (keep branch)
2. Remove worktree and delete branch
3. Skip

### Step 4: Execute Approved Removals
Only after explicit approval for each:

```bash
# Remove worktree
git worktree remove /path/to/worktree

# If also deleting branch
git branch -d branch-name
```

### Step 5: Prune Stale References
After removals, clean up any stale references:
```bash
git worktree prune
```

## Safety Rules
- NEVER remove without explicit per-worktree approval
- ALWAYS warn if worktree has uncommitted changes
- ALWAYS show what will be deleted before executing
- If branch deletion fails with -d, ask before using -D (force)
