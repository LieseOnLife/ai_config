#!/bin/bash
# Sync Claude Code configuration to backup repo
# Usage: ./sync-claude.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$REPO_DIR/claude"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
fi

# Directories to sync (relative to ~/.claude)
SYNC_DIRS=(
    "agents"
    "commands"
    "hooks"
    "scripts"
    "skills"
    "prompts"
)

# Individual files to sync
SYNC_FILES=(
    "CLAUDE.md"
    "settings.json"
    "settings.local.json"
    "package.json"
)

# Plugin metadata (not full plugin contents)
PLUGIN_FILES=(
    "plugins/installed_plugins.json"
    "plugins/known_marketplaces.json"
)

echo "Syncing Claude config to: $BACKUP_DIR"
echo ""

# Sync directories
for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$CLAUDE_DIR/$dir" ]]; then
        echo "Syncing $dir/"
        mkdir -p "$BACKUP_DIR/$dir"
        rsync -av --delete $DRY_RUN "$CLAUDE_DIR/$dir/" "$BACKUP_DIR/$dir/"
    fi
done

# Sync individual files
for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$CLAUDE_DIR/$file" ]]; then
        echo "Syncing $file"
        rsync -av $DRY_RUN "$CLAUDE_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

# Sync plugin metadata
mkdir -p "$BACKUP_DIR/plugins"
for file in "${PLUGIN_FILES[@]}"; do
    if [[ -f "$CLAUDE_DIR/$file" ]]; then
        echo "Syncing $file"
        rsync -av $DRY_RUN "$CLAUDE_DIR/$file" "$BACKUP_DIR/$(basename "$file")" 2>/dev/null || \
        rsync -av $DRY_RUN "$CLAUDE_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

echo ""
echo "Sync complete!"

# Show git status if not dry run
if [[ -z "$DRY_RUN" ]]; then
    echo ""
    echo "=== Git Status ==="
    cd "$REPO_DIR"
    git status --short
fi
