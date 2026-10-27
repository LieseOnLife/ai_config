#!/usr/bin/env bash
# Sourced by the Grinch installer and sync script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$(dirname "$SCRIPT_DIR")/grinch"
CONFIG_DIR="$HOME/.config/grinch"
DRY_RUN=false
if [[ $# -eq 1 && "$1" == "--dry-run" ]]; then
    DRY_RUN=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

for competing in "$HOME/.grinch.js" "$HOME/.config/grinch.js" "/Library/Application Support/Grinch/grinch.js"; do
    if [[ -e "$competing" || -L "$competing" ]]; then
        echo "Conflicting Grinch config: $competing; migrate it explicitly first." >&2
        exit 1
    fi
done
for file in "$CONFIG_DIR/grinch.js" "$CONFIG_DIR/.ai-config-managed" "$BACKUP_DIR/grinch.js"; do
    if [[ -L "$file" || ( -e "$file" && ! -f "$file" ) ]]; then
        echo "Expected a regular, non-symlink file: $file" >&2
        exit 1
    fi
done
if [[ -L "$CONFIG_DIR" || -L "$BACKUP_DIR" ]]; then
    echo "Refusing to install or sync a symlinked Grinch configuration directory." >&2
    exit 1
fi

# Prints the Chrome profile directory whose display name is $1, or nothing when
# missing or ambiguous. Keep in sync with the lookup in grinch/open-gov.
chrome_profile_dir() {
    osascript -l JavaScript - "$HOME/Library/Application Support/Google/Chrome/Local State" "$1" <<'JS' || true
ObjC.import("Foundation");
function run(argv) {
    const text = $.NSString.stringWithContentsOfFileEncodingError(argv[0], $.NSUTF8StringEncoding, null);
    if (text.isNil()) return "";
    const cache = (JSON.parse(text.js).profile || {}).info_cache || {};
    const dirs = Object.keys(cache).filter((dir) => cache[dir].name === argv[1]);
    return dirs.length === 1 ? dirs[0] : "";
}
JS
}
