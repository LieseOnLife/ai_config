#!/bin/bash
# Install Claude Code configuration from backup repo
# Usage: ./install-claude.sh [--dry-run]
#
# WARNING: This will overwrite your current Claude config!

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

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: Backup directory not found: $BACKUP_DIR"
    echo "Run sync-claude.sh first to create a backup."
    exit 1
fi

# Confirm before overwriting (skip in dry-run)
if [[ -z "$DRY_RUN" ]]; then
    echo "This will install Claude config from: $BACKUP_DIR"
    echo "To: $CLAUDE_DIR"
    echo ""
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Ensure target directory exists
mkdir -p "$CLAUDE_DIR"

# Directories to install
SYNC_DIRS=(
    "agents"
    "commands"
    "hooks"
    "scripts"
    "skills"
    "prompts"
)

# Individual files to install
SYNC_FILES=(
    "CLAUDE.md"
    "settings.json"
    "settings.local.json"
    "package.json"
)

# Plugin metadata
PLUGIN_FILES=(
    "plugins/installed_plugins.json"
    "plugins/known_marketplaces.json"
)

echo "Installing Claude config from: $BACKUP_DIR"
echo ""

# Install directories
for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$BACKUP_DIR/$dir" ]]; then
        echo "Installing $dir/"
        mkdir -p "$CLAUDE_DIR/$dir"
        rsync -av --delete $DRY_RUN "$BACKUP_DIR/$dir/" "$CLAUDE_DIR/$dir/"
    fi
done

# Install individual files
for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$CLAUDE_DIR/$file"
    fi
done

# Install plugin metadata
mkdir -p "$CLAUDE_DIR/plugins"
for file in "${PLUGIN_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$CLAUDE_DIR/$file"
    fi
done

echo ""
echo "Install complete!"
echo ""
echo "Note: You may need to restart Claude Code for changes to take effect."
