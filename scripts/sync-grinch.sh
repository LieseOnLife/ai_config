#!/usr/bin/env bash
# Usage: ./scripts/sync-grinch.sh [--dry-run]
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/grinch-common.sh"

if [[ ! -f "$CONFIG_DIR/.ai-config-managed" || ! -f "$CONFIG_DIR/grinch.js" ]]; then
    echo "Missing managed Grinch config; run ./scripts/install-grinch.sh first." >&2
    exit 1
fi
if $DRY_RUN; then
    echo "Would sync only $CONFIG_DIR/grinch.js to $BACKUP_DIR/grinch.js."
    exit 0
fi
mkdir -p "$BACKUP_DIR"
rsync -av -- "$CONFIG_DIR/grinch.js" "$BACKUP_DIR/grinch.js"
echo "Grinch config synced. Review the diff before committing; nothing was pushed."
