#!/bin/bash
# Worktree Context Helper
# Returns worktree info for subagent prompts

set -e

# Get the current worktree path (works in any subdirectory)
WORKTREE_PATH=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

if [ -z "$WORKTREE_PATH" ]; then
  echo "ERROR: Not in a git repository"
  exit 1
fi

# Get main repo path (the original, not the worktree)
MAIN_REPO=$(git rev-parse --git-common-dir 2>/dev/null | sed 's/\.git$//' | sed 's/\/$//')

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Check if this is a worktree (not the main repo)
IS_WORKTREE="false"
if [ "$WORKTREE_PATH" != "$MAIN_REPO" ] && [ -f "$WORKTREE_PATH/.git" ]; then
  IS_WORKTREE="true"
fi

# Output as JSON for easy parsing
cat << EOF
{
  "worktree_path": "$WORKTREE_PATH",
  "main_repo": "$MAIN_REPO",
  "branch": "$BRANCH",
  "is_worktree": $IS_WORKTREE
}
EOF
