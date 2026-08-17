#!/bin/bash
# Worktree Cleanup Helper
# Lists worktrees and their status, helps identify candidates for cleanup

set -e

MAIN_REPO=$(git rev-parse --git-common-dir 2>/dev/null | sed 's/\.git$//' | sed 's/\/$//')

if [ -z "$MAIN_REPO" ]; then
  echo "ERROR: Not in a git repository"
  exit 1
fi

echo "=== Worktree Status Report ==="
echo "Main repo: $MAIN_REPO"
echo ""

# Get all worktrees
git worktree list --porcelain | while read -r line; do
  if [[ $line == worktree* ]]; then
    WORKTREE_PATH="${line#worktree }"

    # Skip main repo
    if [ "$WORKTREE_PATH" == "$MAIN_REPO" ]; then
      continue
    fi

    # Get branch info
    BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")

    # Check if branch is merged into main/master
    MERGED="no"
    if git -C "$MAIN_REPO" branch --merged main 2>/dev/null | grep -q "$BRANCH" || \
       git -C "$MAIN_REPO" branch --merged master 2>/dev/null | grep -q "$BRANCH"; then
      MERGED="yes"
    fi

    # Check for uncommitted changes
    DIRTY="clean"
    if [ -n "$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null)" ]; then
      DIRTY="dirty"
    fi

    # Check last commit date
    LAST_COMMIT=$(git -C "$WORKTREE_PATH" log -1 --format="%cr" 2>/dev/null || echo "unknown")

    # Check if directory exists
    EXISTS="yes"
    if [ ! -d "$WORKTREE_PATH" ]; then
      EXISTS="no (missing)"
    fi

    echo "---"
    echo "Path: $WORKTREE_PATH"
    echo "Branch: $BRANCH"
    echo "Merged: $MERGED"
    echo "Status: $DIRTY"
    echo "Last commit: $LAST_COMMIT"
    echo "Exists: $EXISTS"

    # Suggest action
    if [ "$EXISTS" == "no (missing)" ]; then
      echo ">>> RECOMMEND: Prune (directory missing)"
    elif [ "$MERGED" == "yes" ] && [ "$DIRTY" == "clean" ]; then
      echo ">>> RECOMMEND: Safe to remove (merged & clean)"
    elif [ "$DIRTY" == "dirty" ]; then
      echo ">>> CAUTION: Has uncommitted changes"
    fi
  fi
done

echo ""
echo "=== Cleanup Commands ==="
echo "To remove a worktree (requires approval):"
echo "  git worktree remove <path>"
echo ""
echo "To prune missing worktrees:"
echo "  git worktree prune"
echo ""
echo "To delete the branch after removing worktree:"
echo "  git branch -d <branch-name>"
