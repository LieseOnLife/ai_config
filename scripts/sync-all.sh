#!/bin/bash
# Sync all AI configurations to backup repo
# Usage: ./sync-all.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "  AI Config Backup"
echo "========================================"
echo ""

# Sync Claude
if [[ -d "$HOME/.claude" ]]; then
    echo ">>> Syncing Claude Code..."
    "$SCRIPT_DIR/sync-claude.sh" "$@"
    echo ""
fi

# Future: Add other AI tools here
# if [[ -d "$HOME/.cursor" ]]; then
#     echo ">>> Syncing Cursor..."
#     "$SCRIPT_DIR/sync-cursor.sh" "$@"
#     echo ""
# fi

echo "========================================"
echo "  All syncs complete!"
echo "========================================"
