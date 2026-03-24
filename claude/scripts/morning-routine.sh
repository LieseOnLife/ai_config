#!/bin/bash
# Morning routine: Runs /morning skill via Claude CLI headless mode
# Triggered by launchd at 9:15 AM weekdays
set -euo pipefail

CLAUDE="/opt/homebrew/bin/claude"
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

# Run the /morning skill which handles everything
"$CLAUDE" -p "Run /morning" --output-format text 2>&1

EXIT_CODE=$?
echo "${LOG_PREFIX} Finished with exit code ${EXIT_CODE}"
exit ${EXIT_CODE}
