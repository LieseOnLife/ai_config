#!/usr/bin/env bash
# Install Zed configuration from backup repo
# Usage: ./scripts/install-zed.sh [--dry-run]
#
# Overwrites ~/.config/zed/settings.json (and keymap.json when backed up).
# Extensions, themes, the prompt library, and Zed's local database are left untouched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ZED_DIR="$HOME/.config/zed"
BACKUP_DIR="$REPO_DIR/zed"

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

if [[ ! -f "$BACKUP_DIR/settings.json" ]]; then
    echo "Error: Zed backup not found: $BACKUP_DIR/settings.json" >&2
    exit 1
fi

if [[ -z "$DRY_RUN" ]]; then
    echo "This will install Zed config from: $BACKUP_DIR"
    echo "To: $ZED_DIR"
    read -r -p "Continue? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    mkdir -p "$ZED_DIR"
fi

for file in "${ZED_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        if [[ -n "$DRY_RUN" && ! -d "$ZED_DIR" ]]; then
            echo "Would create $ZED_DIR/$file"
        else
            rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$ZED_DIR/$file"
        fi
    fi
done

if [[ -z "$DRY_RUN" ]]; then
    touch "$ZED_DIR/.ai-config-managed"
fi

echo ""
echo "Install complete! Zed reloads settings on save; see the header of settings.json"
echo "for launching Zed with a Datadog AI Gateway token."
