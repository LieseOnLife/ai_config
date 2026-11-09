#!/usr/bin/env bash
# Install Codex configuration from this repository.
# Usage: ./scripts/install-codex.sh [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$REPO_DIR/codex"
CODEX_DIR="$HOME/.codex"
SKILLS_DIR="$HOME/.agents/skills"
PI_SKILLS_DIR="$HOME/.pi/agent/skills"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "Error: Codex backup directory not found: $BACKUP_DIR" >&2
    exit 1
fi

LINKED_SKILLS=()
while IFS= read -r name || [[ -n "$name" ]]; do
    name="${name%$'\r'}"
    [[ -z "$name" || "$name" == \#* ]] && continue
    # Each name is later passed to rm -rf, so it must be a bare directory name.
    if [[ "$name" == */* || "$name" == "." || "$name" == ".." ]]; then
        echo "Error: invalid skill name in skills-from-pi.txt: $name" >&2
        exit 1
    fi
    LINKED_SKILLS+=("$name")
done < "$BACKUP_DIR/skills-from-pi.txt"

if [[ -z "$DRY_RUN" ]]; then
    echo "This will install Codex config from: $BACKUP_DIR"
    echo "Codex home: $CODEX_DIR"
    echo "User skills: $SKILLS_DIR"
    read -r -p "Continue? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

if [[ -z "$DRY_RUN" ]]; then
    mkdir -p "$CODEX_DIR" "$SKILLS_DIR"
fi

SYNC_DIRS=(agents hooks rules scripts)
SYNC_FILES=(AGENTS.md config.toml hooks.json)

for dir in "${SYNC_DIRS[@]}"; do
    if [[ -d "$BACKUP_DIR/$dir" ]]; then
        echo "Installing $dir/"
        if [[ -n "$DRY_RUN" && ! -d "$CODEX_DIR/$dir" ]]; then
            echo "Would create $CODEX_DIR/$dir and install its contents"
        else
            mkdir -p "$CODEX_DIR/$dir"
            rsync -av --delete $DRY_RUN "$BACKUP_DIR/$dir/" "$CODEX_DIR/$dir/"
        fi
    fi
done

for file in "${SYNC_FILES[@]}"; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        echo "Installing $file"
        rsync -av $DRY_RUN "$BACKUP_DIR/$file" "$CODEX_DIR/$file"
    fi
done

echo "Installing user skills/"
if [[ -n "$DRY_RUN" && ! -d "$SKILLS_DIR" ]]; then
    echo "Would create $SKILLS_DIR and install $(find "$BACKUP_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ') skills"
else
    # Merge personal skills so skills managed by other repositories are preserved.
    rsync -av $DRY_RUN "$BACKUP_DIR/skills/" "$SKILLS_DIR/"
fi

echo "Linking pi skills/"
for name in ${LINKED_SKILLS[@]+"${LINKED_SKILLS[@]}"}; do
    link="$SKILLS_DIR/$name"
    target="$PI_SKILLS_DIR/$name"
    if [[ -L "$link" && "$(readlink "$link")" == "$target" ]]; then
        continue
    fi
    echo "$link -> $target"
    if [[ -z "$DRY_RUN" ]]; then
        rm -rf "$link"
        ln -s "$target" "$link"
    fi
done

if [[ -z "$DRY_RUN" ]]; then
    touch "$CODEX_DIR/.ai-config-managed"
fi

echo
echo "Install complete. Restart Codex, then review and trust the hooks with /hooks."
