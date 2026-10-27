#!/usr/bin/env bash
# Fresh-Mac setup for AI tooling: install every missing tool, then install the
# configs backed up in this repo.
# Usage: ./scripts/setup.sh [--dry-run]
#
# Safe to re-run: installed tools are skipped, and each config installer asks
# before overwriting. General CLI tools and apps live in the dotfiles repo's
# install_apps.sh; Homebrew itself comes from that script or laptop-setup.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false
DRY_FLAG=()
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    DRY_FLAG=(--dry-run)
    echo "=== DRY RUN MODE ==="
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
fi

WARNINGS=()

# The Claude Code installer and open-gov live here; a fresh shell may not have it on PATH yet.
export PATH="$HOME/.local/bin:$PATH"

have() { command -v "$1" >/dev/null 2>&1; }
# installed <command or /absolute/path>
installed() { if [[ "$1" == /* ]]; then [[ -e "$1" ]]; else have "$1"; fi; }
step() { printf '\n>>> %s\n' "$*"; }
skip() { echo "    ✓ $1 already installed"; }
warn() { echo "    ⚠️  $*"; WARNINGS+=("$*"); }

run() {
    if $DRY_RUN; then
        printf '    Would run:'
        printf ' %q' "$@"
        echo
    else
        "$@"
    fi
}

# Jamf-managed Macs run as a standard user; casks that write to /Applications
# need sudo, which only works while Privileges has granted admin (the same
# elevation ~/.privilegesalias does for interactive brew). Admin granted here is
# revoked on exit.
PRIVILEGES_CLI=/Applications/Privileges.app/Contents/MacOS/PrivilegesCLI
ELEVATED=false
ensure_admin() {
    $DRY_RUN && return 0
    /usr/bin/groups | grep -qwE 'admin|wheel' && return 0
    [[ -x "$PRIVILEGES_CLI" ]] || return 0
    if "$PRIVILEGES_CLI" -a; then
        ELEVATED=true
        sleep 1
    fi
    return 0
}

WORK_DIR=""
cleanup() {
    [[ -n "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
    if $ELEVATED; then "$PRIVILEGES_CLI" -r || true; fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM
$DRY_RUN || WORK_DIR="$(mktemp -d)"

# fetch_and_run <url> <shell>: download fully before running, so a failed or
# truncated download is reported instead of piping a partial script into a shell.
# The installer keeps the terminal as stdin for its prompts.
fetch_and_run() {
    if $DRY_RUN; then
        echo "    Would run: $2 <(curl -fsSL $1)"
        return 0
    fi
    local script="$WORK_DIR/installer.sh"
    curl -fsSL "$1" -o "$script" || return 1
    "$2" "$script"
}

# Homebrew refuses third-party formulae/casks until they are trusted; trust only
# the item being installed. Older Homebrew has no `trust` and needs nothing.
# trust_item <formula|cask> <tap/name/item>
trust_item() {
    run brew tap "${2%/*}" || return 1
    brew trust --help >/dev/null 2>&1 || return 0
    run brew trust "--$1" "$2"
}

# A failed tool install is reported at the end instead of stopping setup.
# install_formula <command> <formula>   (tap-qualified names are trusted first)
install_formula() {
    if have "$1"; then skip "$1"; return 0; fi
    if [[ "$2" == */*/* ]] && ! trust_item formula "$2"; then warn "could not trust $2; not installed"; return 0; fi
    run brew install "$2" || warn "brew install $2 failed"
}

# install_cask <command or /Applications/X.app> <cask>
install_cask() {
    if installed "$1"; then skip "$1"; return 0; fi
    if [[ "$2" == */*/* ]] && ! trust_item cask "$2"; then warn "could not trust $2; not installed"; return 0; fi
    ensure_admin
    run brew install --cask "$2" || warn "brew install --cask $2 failed (needs admin: Privileges, then re-run)"
}

# install_script <command> <url> <shell>: vendor installers
install_script() {
    if have "$1"; then skip "$1"; return 0; fi
    if ! fetch_and_run "$2" "$3"; then warn "$1 installer ($2) failed"; return 0; fi
    hash -r
    $DRY_RUN || have "$1" || warn "$1 installer ran but $1 is still not on PATH"
}

confirm_default_yes() {
    local reply
    read -r -p "$1 [Y/n] " reply || return 1
    [[ ! "$reply" =~ ^[Nn] ]]
}

if ! have brew; then
    echo "Homebrew not found. Run the dotfiles repo's install_apps.sh (or laptop-setup.sh) first." >&2
    exit 1
fi

step "Coding agents"
install_script claude https://claude.ai/install.sh bash
install_cask codex codex
install_script pi https://pi.dev/install.sh sh
install_formula omp can1357/tap/omp
install_formula opencode opencode
if have pi-setup; then
    skip pi-setup
elif [[ -x /opt/dogbrew/bin/dogbrew ]]; then
    run /opt/dogbrew/bin/dogbrew install pi-setup || warn "dogbrew install pi-setup failed (on Appgate?)"
else
    warn "dogbrew not found; run laptop-setup.sh (on Appgate), then: dogbrew install pi-setup"
fi

step "Editors and companions"
install_cask zed zed
install_formula acli atlassian/homebrew-acli/acli
install_cask /Applications/Grinch.app bric3/tap/grinch
install_formula node node
if have openspec; then
    skip openspec
else
    run npm install -g @fission-ai/openspec@latest || warn "npm install -g @fission-ai/openspec failed"
fi

step "Configs from this repo"
for tool in claude codex pi zed grinch; do
    echo "--- install-$tool.sh"
    "$SCRIPT_DIR/install-$tool.sh" ${DRY_FLAG[@]+"${DRY_FLAG[@]}"} || warn "install-$tool.sh did not finish; re-run it on its own"
done

# Generated by the OpenSpec CLI instead of being backed up; install-pi.sh leaves them in place.
step "OpenSpec skills for pi/omp"
PI_SKILLS="$HOME/.pi/agent/skills"
hash -r # pick up tools installed above
if $DRY_RUN; then
    echo "    Would regenerate openspec-* skills into $PI_SKILLS via: openspec init <tmp> --tools pi"
elif ! have openspec; then
    warn "openspec not on PATH; re-run setup.sh after fixing npm"
elif openspec init "$WORK_DIR/openspec" --tools pi --no-animation </dev/null >/dev/null; then
    mkdir -p "$PI_SKILLS"
    for skill in "$WORK_DIR"/openspec/.pi/skills/openspec-*/; do
        [[ -d "$skill" ]] || { warn "openspec init produced no pi skills"; break; }
        rsync -a --delete "$skill" "$PI_SKILLS/$(basename "$skill")/"
        echo "    ✓ $(basename "$skill")"
    done
else
    warn "openspec init failed; openspec-* skills not regenerated"
fi

# Last, so it reconnects agents and re-adds the MCP entries the config installs just reset.
step "Trajectory (agent observability)"
TRAJECTORY_INSTALLER=https://raw.githubusercontent.com/datadog-labs/trajectory/main/install.sh
if [[ -x "$HOME/.trajectory/bin/trajectory" ]] && ! $DRY_RUN \
    && ! confirm_default_yes "Re-run the Trajectory installer? Config installs above reset its MCP entries."; then
    echo "    Skipped"
else
    fetch_and_run "$TRAJECTORY_INSTALLER" bash || warn "Trajectory installer failed; re-run: bash <(curl -fsSL $TRAJECTORY_INSTALLER)"
fi

echo ""
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "Setup finished with warnings:"
    printf '  - %s\n' "${WARNINGS[@]}"
else
    echo "Setup complete! Restart your shell so new tools are on PATH."
fi
echo "First-run sign-ins: claude, codex, opencode auth login, acli jira auth login."
