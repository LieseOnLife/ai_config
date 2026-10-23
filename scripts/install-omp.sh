#!/usr/bin/env bash
# Install omp (oh-my-pi) configuration from backup repo
# Usage: ./install-omp.sh [--dry-run]
#
# WARNING: This will overwrite your current omp config (resource dirs and config
# files only; credentials, databases, cache, logs, and sessions are left untouched)!

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OMP_DIR="$HOME/.omp"
AGENT_DIR="$OMP_DIR/agent"
BACKUP_DIR="$REPO_DIR/omp"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if [[ ! -d "$BACKUP_DIR/agent" ]]; then
    echo "Error: omp backup directory not found: $BACKUP_DIR/agent" >&2
    exit 1
fi

if [[ -z "$DRY_RUN" ]]; then
    echo "This will install omp config from: $BACKUP_DIR"
    echo "To: $OMP_DIR"
    echo ""
    echo "Credentials, databases, cache, logs, and sessions are NOT touched."
    read -r -p "Continue? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

mkdir -p "$AGENT_DIR"

# Directories to install (relative to ~/.omp/agent)
SYNC_DIRS=(
    "extensions"
    "lib"
    "managed-skills"
    "prompts"
    "rules"
)

# Individual files to install (relative to ~/.omp)
SYNC_FILES=(
    "agent/AGENTS.md"
    "agent/config.yml"
    "agent/mcp.json"
    "marketplaces.json"
    "plugins/installed_plugins.json"
    "plugins/omp-plugins.lock.json"
)

echo "Installing omp config from: $BACKUP_DIR"
echo ""

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$BACKUP_DIR/agent/$dir" ]]; then
        echo "Installing agent/$dir/"
        if [[ -n "$DRY_RUN" && ! -d "$AGENT_DIR/$dir" ]]; then
            echo "Would create $AGENT_DIR/$dir and install its contents"
        else
            mkdir -p "$AGENT_DIR/$dir"
            rsync -av --delete $DRY_RUN "$BACKUP_DIR/agent/$dir/" "$AGENT_DIR/$dir/"
        fi
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        if [[ -n "$DRY_RUN" && ! -d "$(dirname "$OMP_DIR/$file")" ]]; then
            echo "Would create $(dirname "$OMP_DIR/$file") and install $file"
        else
            mkdir -p "$(dirname "$OMP_DIR/$file")"
            rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$OMP_DIR/$file"
        fi
    fi
done

if [[ -z "$DRY_RUN" ]]; then
    touch "$AGENT_DIR/.ai-config-managed"
fi

echo ""
echo "Install complete!"
echo ""
echo "Note: Restart omp (or start a fresh session) for changes to take effect."
echo "Plugin metadata is restored, but plugin contents are not; reinstall plugins"
echo "if ~/.omp/plugins/cache is missing."
