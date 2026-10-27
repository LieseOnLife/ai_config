#!/usr/bin/env bash
# Sync Zed configuration to backup repo
# Usage: ./scripts/sync-zed.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ZED_DIR="$HOME/.config/zed"
BACKUP_DIR="$REPO_DIR/zed"

# Hand-edited config only — not extensions, themes, prompts, or Zed's database
ZED_FILES=(
    "settings.json"
    "keymap.json"
)

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if [[ ! -f "$ZED_DIR/.ai-config-managed" ]]; then
    echo "Zed config is not managed by this repo yet; run ./scripts/install-zed.sh first." >&2
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "Syncing Zed config to: $BACKUP_DIR"
for file in "${ZED_FILES[@]}"; do
    if [[ -f "$ZED_DIR/$file" ]]; then
        echo "Syncing $file"
        rsync -av $DRY_RUN "$ZED_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

echo ""
echo "Sync complete!"

if [[ -z "$DRY_RUN" ]]; then
    echo ""
    echo "=== Git Status ==="
    git -C "$REPO_DIR" status --short
fi
