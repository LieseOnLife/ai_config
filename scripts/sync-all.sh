#!/bin/bash
# Sync all AI configurations to backup repo + DataDog experimental
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

# Sync Codex
if [[ -f "$HOME/.codex/.ai-config-managed" ]]; then
    echo ">>> Syncing Codex..."
    "$SCRIPT_DIR/sync-codex.sh" "$@"
    echo ""
fi

# Sync pi
if [[ -f "$HOME/.pi/agent/.ai-config-managed" ]]; then
    echo ">>> Syncing pi..."
    "$SCRIPT_DIR/sync-pi.sh" "$@"
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
echo ""

# Push to DataDog experimental repo
if [[ -z "${1:-}" || "${1:-}" != "--dry-run" ]]; then
    "$SCRIPT_DIR/push-experimental.sh"
fi
