#!/bin/bash
# Git Worktree Guard Hook
# Blocks deletion of worktrees and branches without explicit approval

# Read the command from stdin (passed by Claude Code hook)
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Exit early if no command
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Allow commands that have been explicitly approved (prefixed with "# APPROVED:")
if echo "$COMMAND" | grep -q "^# APPROVED:"; then
  # Strip the prefix and allow
  exit 0
fi

# Allow prune - it only cleans up references to missing directories (safe)
if echo "$COMMAND" | grep -qE "^git worktree prune$"; then
  exit 0
fi

# Patterns that indicate deletion (require approval)
BLOCKED_PATTERNS=(
  "git worktree remove"
  "git branch -d"
  "git branch -D"
  "git branch --delete"
  "git push.*--delete"
  "git push [^ ]+ :"  # Push with colon prefix deletes remote branch
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    # Extract what's being deleted for clearer message
    TARGET=""
    if echo "$COMMAND" | grep -qE "git worktree remove"; then
      TARGET=$(echo "$COMMAND" | sed 's/.*git worktree remove[[:space:]]*//')
    elif echo "$COMMAND" | grep -qE "git branch"; then
      TARGET=$(echo "$COMMAND" | sed 's/.*git branch[[:space:]]*-[dD][[:space:]]*//')
    fi

    echo "🛑 BLOCKED: Worktree/branch deletion requires approval"
    echo ""
    echo "Command: $COMMAND"
    if [ -n "$TARGET" ]; then
      echo "Target: $TARGET"
    fi
    echo ""
    echo "To proceed, get user approval then prefix with '# APPROVED:':"
    echo "  # APPROVED: $COMMAND"
    echo ""
    echo "Or use /worktree-cleanup for guided cleanup with approval flow."
    exit 2
  fi
done

exit 0
