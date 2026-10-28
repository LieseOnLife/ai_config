#!/usr/bin/env bash
# Usage: ./scripts/install-grinch.sh [--dry-run]
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/grinch-common.sh"

for file in grinch.js open-gov; do
    [[ -f "$BACKUP_DIR/$file" ]] || { echo "Missing $BACKUP_DIR/$file" >&2; exit 1; }
done
for profile in "datadoghq.com" "ddog-gov.com" "Your Chrome"; do
    dir=$(chrome_profile_dir "$profile")
    if [[ -z "$dir" || ! -d "$HOME/Library/Application Support/Google/Chrome/$dir" ]]; then
        echo "Missing or ambiguous Chrome profile named $profile; verify profile mappings before installing." >&2
        exit 1
    fi
done
HELPER="$HOME/.local/bin/open-gov"
if [[ -L "$HELPER" || -d "$HELPER" ]]; then
    echo "Refusing to replace a symlink or directory: $HELPER" >&2
    exit 1
fi
if $DRY_RUN; then
    echo "Would install grinch.js into $CONFIG_DIR and open-gov into $HOME/.local/bin."
    echo "Would mark the Grinch configuration as managed; no settings changed."
    exit 0
fi
read -r -p "Install Grinch config and open-gov (overwrites existing files)? [y/N] " REPLY
[[ "$REPLY" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
mkdir -p "$CONFIG_DIR" "$HOME/.local/bin"
install -m 644 "$BACKUP_DIR/grinch.js" "$CONFIG_DIR/grinch.js"
install -m 755 "$BACKUP_DIR/open-gov" "$HELPER"
touch "$CONFIG_DIR/.ai-config-managed"
echo "If Grinch is already running, choose Reload Config (⌘R) in its menu before testing links."
echo "Installed. Select Grinch in System Settings → Desktop & Dock → Default web browser."
echo "Keep ~/.local/bin on PATH to use: open-gov 'https://example.com'"
