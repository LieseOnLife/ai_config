#!/usr/bin/env bash
# Sync pi configuration to backup repo
# Usage: ./sync-pi.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PI_DIR="$HOME/.pi/agent"
BACKUP_DIR="$REPO_DIR/pi"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if [[ ! -f "$PI_DIR/.ai-config-managed" ]]; then
    echo "pi config is not managed by this repo yet; run ./scripts/install-pi.sh first." >&2
    exit 1
fi

# Directories to sync (relative to ~/.pi/agent)
SYNC_DIRS=(
    "extensions"
    "prompts"
    "scripts"
    "skills"
)

# Individual files to sync (durable config only — NO credentials/cache)
SYNC_FILES=(
    "AGENTS.md"
    "settings.json"
    "mcp.json"
)

mkdir -p "$BACKUP_DIR"

echo "Syncing pi config to: $BACKUP_DIR"
echo ""

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$PI_DIR/$dir" ]]; then
        echo "Syncing $dir/"
        mkdir -p "$BACKUP_DIR/$dir"
        rsync -av --delete $DRY_RUN "$PI_DIR/$dir/" "$BACKUP_DIR/$dir/"
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$PI_DIR/$file" ]]; then
        echo "Syncing $file"
        rsync -av $DRY_RUN "$PI_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

echo ""
echo "Sync complete!"

if [[ -z "$DRY_RUN" ]]; then
    echo ""
    echo "=== Git Status ==="
    git -C "$REPO_DIR" status --short
fi
