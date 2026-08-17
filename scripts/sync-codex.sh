#!/usr/bin/env bash
# Sync the durable Codex configuration into this repository.
# Usage: ./scripts/sync-codex.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$REPO_DIR/codex"
CODEX_DIR="$HOME/.codex"
SKILLS_DIR="$HOME/.agents/skills"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$CODEX_DIR/.ai-config-managed" ]]; then
    echo "Codex config is not managed by this repo yet; run ./scripts/install-codex.sh first." >&2
    exit 1
fi

SYNC_DIRS=(agents hooks rules scripts)
SYNC_FILES=(AGENTS.md config.toml hooks.json)

echo "Syncing Codex config to: $BACKUP_DIR"

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$CODEX_DIR/$dir" ]]; then
        echo "Syncing $dir/"
        mkdir -p "$BACKUP_DIR/$dir"
        rsync -av --delete $DRY_RUN "$CODEX_DIR/$dir/" "$BACKUP_DIR/$dir/"
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$CODEX_DIR/$file" ]]; then
        echo "Syncing $file"
        rsync -av $DRY_RUN "$CODEX_DIR/$file" "$BACKUP_DIR/$file"
    fi
done

if [[ -d "$SKILLS_DIR" ]]; then
    echo "Syncing user skills/"
    mkdir -p "$BACKUP_DIR/skills"
    rsync -av --delete $DRY_RUN "$SKILLS_DIR/" "$BACKUP_DIR/skills/"
fi

echo
echo "Sync complete."

if [[ -z "$DRY_RUN" ]]; then
    echo
    echo "=== Git Status ==="
    git -C "$REPO_DIR" status --short
fi
