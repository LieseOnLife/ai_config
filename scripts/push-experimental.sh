#!/bin/bash
# Push Claude AI config to DataDog experimental repo (saje/ai-config branch)
# Usage: ./push-experimental.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
EXPERIMENTAL_DIR="$HOME/dd/experimental"
BRANCH="saje/ai-config"

if [[ ! -d "$EXPERIMENTAL_DIR/.git" ]]; then
    echo "⚠️  DataDog experimental repo not found at $EXPERIMENTAL_DIR"
    echo "   Clone it first: git clone https://github.com/DataDog/experimental.git $EXPERIMENTAL_DIR"
    exit 0
fi

echo "========================================"
echo "  Pushing to DataDog experimental"
echo "========================================"
echo ""

cd "$EXPERIMENTAL_DIR"

# Switch to saje/ai-config branch
git fetch origin "$BRANCH":"$BRANCH" 2>/dev/null || true
git checkout "$BRANCH"

# Copy claude config into users/saje.liese/ai_config/
DEST="$EXPERIMENTAL_DIR/users/saje.liese/ai_config"
mkdir -p "$DEST"
rsync -av --delete \
    --exclude='settings.local.json' \
    --exclude='*.credentials*' \
    "$REPO_DIR/claude/" "$DEST/"

# Commit and push
git add -A
if git diff --cached --quiet; then
    echo "Nothing changed in experimental repo."
else
    git commit -m "Sync Saje's Claude AI config

Auto-synced from github.com/LieseOnLife/ai_config"
    git push origin "$BRANCH"
    echo ""
    echo "✓ Pushed to DataDog/experimental @ $BRANCH"
fi

# Return to main
git checkout main 2>/dev/null || true
