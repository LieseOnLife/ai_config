#!/bin/bash
# Create a PR with Claude config changes
# Usage: ./create-pr.sh <branch-name> [commit-message]
#
# Example: ./create-pr.sh sync-config-updates "Update worktree convention"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
REPO_NAME=$(basename "$REPO_DIR")
CLAUDE_DIR="$HOME/.claude"

BRANCH_NAME="${1:-}"
COMMIT_MSG="${2:-Update Claude configuration}"

if [[ -z "$BRANCH_NAME" ]]; then
    echo "Usage: $0 <branch-name> [commit-message]"
    echo "Example: $0 sync-config-updates \"Update worktree convention\""
    exit 1
fi

WORKTREE_DIR="$(dirname "$REPO_DIR")/${REPO_NAME}-worktrees/${BRANCH_NAME}"
FULL_BRANCH="saje/${BRANCH_NAME}"

echo "=== Creating PR for Claude config changes ==="
echo "Branch: $FULL_BRANCH"
echo "Worktree: $WORKTREE_DIR"
echo ""

# Check if worktree already exists
if [[ -d "$WORKTREE_DIR" ]]; then
    echo "Error: Worktree already exists at $WORKTREE_DIR"
    echo "Remove it first or use a different branch name"
    exit 1
fi

# Create worktree
echo ">>> Creating worktree..."
cd "$REPO_DIR"
git worktree add "$WORKTREE_DIR" -b "$FULL_BRANCH"

# Sync directly to worktree
echo ""
echo ">>> Syncing Claude config to worktree..."
BACKUP_DIR="$WORKTREE_DIR/claude"

# Directories to sync
SYNC_DIRS=(agents commands hooks scripts skills prompts)
SYNC_FILES=(CLAUDE.md settings.json settings.local.json package.json)
PLUGIN_FILES=(plugins/installed_plugins.json plugins/known_marketplaces.json)

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$CLAUDE_DIR/$dir" ]]; then
        mkdir -p "$BACKUP_DIR/$dir"
        rsync -a --delete "$CLAUDE_DIR/$dir/" "$BACKUP_DIR/$dir/"
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$CLAUDE_DIR/$file" ]]; then
        rsync -a "$CLAUDE_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

mkdir -p "$BACKUP_DIR/plugins"
for file in "${PLUGIN_FILES[@]}"; do
    if [[ -f "$CLAUDE_DIR/$file" ]]; then
        rsync -a "$CLAUDE_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

# Stage and show changes
echo ""
echo ">>> Staging changes..."
cd "$WORKTREE_DIR"
git add -A

echo ""
echo "=== Changes to commit ==="
git status --short

echo ""
echo "=== Diff summary ==="
git diff --cached --stat

# Commit
echo ""
echo ">>> Committing..."
git commit -m "$(cat <<EOF
$COMMIT_MSG

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

# Push
echo ""
echo ">>> Pushing..."
git push -u origin "$FULL_BRANCH"

# Create PR
echo ""
echo ">>> Creating PR..."
PR_URL=$(gh pr create --title "🔄 $COMMIT_MSG" --body "$(cat <<EOF
## Summary
- Sync Claude Code configuration changes

## Changes
$(git diff --stat HEAD~1)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)")

echo ""
echo "=== Done ==="
echo "PR: $PR_URL"
echo "Worktree: $WORKTREE_DIR"
