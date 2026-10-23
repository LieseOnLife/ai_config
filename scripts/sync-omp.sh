#!/usr/bin/env bash
# Sync omp (oh-my-pi) configuration to backup repo
# Usage: ./sync-omp.sh [--dry-run]

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

if [[ ! -f "$AGENT_DIR/.ai-config-managed" ]]; then
    echo "omp config is not managed by this repo yet; run ./scripts/install-omp.sh first." >&2
    exit 1
fi

# Directories to sync (relative to ~/.omp/agent)
SYNC_DIRS=(
    "extensions"
    "lib"
    "managed-skills"
    "prompts"
    "rules"
)

# Individual files to sync (relative to ~/.omp; durable config only, NO credentials/DBs/cache)
SYNC_FILES=(
    "agent/AGENTS.md"
    "agent/config.yml"
    "agent/mcp.json"
    "marketplaces.json"
    "plugins/installed_plugins.json"
    "plugins/omp-plugins.lock.json"
)

mkdir -p "$BACKUP_DIR/agent"

echo "Syncing omp config to: $BACKUP_DIR"
echo ""

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$AGENT_DIR/$dir" ]]; then
        echo "Syncing agent/$dir/"
        mkdir -p "$BACKUP_DIR/agent/$dir"
        rsync -av --delete $DRY_RUN "$AGENT_DIR/$dir/" "$BACKUP_DIR/agent/$dir/"
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$OMP_DIR/$file" ]]; then
        echo "Syncing $file"
        mkdir -p "$(dirname "$BACKUP_DIR/$file")"
        rsync -av $DRY_RUN "$OMP_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

echo ""
echo "Sync complete!"

if [[ -z "$DRY_RUN" ]]; then
    echo ""
    echo "=== Git Status ==="
    git -C "$REPO_DIR" status --short
fi
