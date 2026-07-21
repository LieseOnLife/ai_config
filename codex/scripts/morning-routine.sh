#!/bin/bash
# Morning routine: Runs the morning skill via Codex non-interactive mode
# Triggered by launchd at 9:15 AM weekdays
set -euo pipefail

CODEX="/opt/homebrew/bin/codex"
DATE=$(date +%Y-%m-%d)
LOG_PREFIX="[morning-routine ${DATE}]"

echo "${LOG_PREFIX} Starting morning routine..."

# Skip weekends
DOW=$(date +%u)
if [ "$DOW" -gt 5 ]; then
  echo "${LOG_PREFIX} Weekend — skipping."
  exit 0
fi

# Ensure Obsidian is running (needed for MCP tools)
if ! pgrep -q "Obsidian"; then
  echo "${LOG_PREFIX} Opening Obsidian..."
  open -a "Obsidian" && sleep 5
fi

# Run the morning skill, which handles everything.
"$CODEX" exec 'Use $morning to run my morning routine.' 2>&1

EXIT_CODE=$?
echo "${LOG_PREFIX} Finished with exit code ${EXIT_CODE}"
exit ${EXIT_CODE}
