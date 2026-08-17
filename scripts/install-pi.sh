#!/usr/bin/env bash
# Install pi configuration from backup repo
# Usage: ./install-pi.sh [--dry-run]
#
# WARNING: This will overwrite your current pi config (resource dirs only;
# credentials, cache, sessions, and the model registry are left untouched)!

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

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: pi backup directory not found: $BACKUP_DIR" >&2
    exit 1
fi

if [[ -z "$DRY_RUN" ]]; then
    echo "This will install pi config from: $BACKUP_DIR"
    echo "To: $PI_DIR"
    echo ""
    echo "Credentials, cache, sessions, and the model registry are NOT touched."
    read -r -p "Continue? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

mkdir -p "$PI_DIR"

# Directories to install
SYNC_DIRS=(
    "extensions"
    "prompts"
    "scripts"
    "skills"
)

# Individual files to install
SYNC_FILES=(
    "AGENTS.md"
    "settings.json"
    "mcp.json"
)

echo "Installing pi config from: $BACKUP_DIR"
echo ""

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$BACKUP_DIR/$dir" ]]; then
        echo "Installing $dir/"
        if [[ -n "$DRY_RUN" && ! -d "$PI_DIR/$dir" ]]; then
            echo "Would create $PI_DIR/$dir and install its contents"
        else
            mkdir -p "$PI_DIR/$dir"
            rsync -av --delete $DRY_RUN "$BACKUP_DIR/$dir/" "$PI_DIR/$dir/"
        fi
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$PI_DIR/$file"
    fi
done

if [[ -z "$DRY_RUN" ]]; then
    touch "$PI_DIR/.ai-config-managed"
    chmod +x "$PI_DIR/scripts/"*.sh "$PI_DIR/scripts/"*.swift "$PI_DIR/scripts/"*.applescript 2>/dev/null || true
fi

echo ""
echo "Install complete!"
echo ""
echo "Note: Restart pi for changes to take effect. Run /reload in an interactive"
echo "session to hot-reload extensions, or start a fresh session."
