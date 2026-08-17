#!/usr/bin/env bash
# check-pr-ci.sh — Check CI status for one or more GitHub PRs
# Usage: check-pr-ci.sh <pr_number> [pr_number...]
# Must be run from within a git repo (uses gh CLI)

set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <pr_number> [pr_number...]"
  exit 1
fi

for pr in "$@"; do
  echo "=== PR #${pr} ==="

  checks=$(gh pr checks "$pr" --json link,state,name 2>&1) || {
    echo "  ERROR: Could not fetch checks for PR #${pr}"
    continue
  }

  total=$(echo "$checks" | jq 'length')
  success=$(echo "$checks" | jq '[.[] | select(.state=="SUCCESS")] | length')
  failed=$(echo "$checks" | jq '[.[] | select(.state=="FAILURE" or .state=="ERROR")] | length')
  pending=$(echo "$checks" | jq '[.[] | select(.state=="PENDING")] | length')

  echo "  Total: ${total}, Success: ${success}, Failed: ${failed}, Pending: ${pending}"

  # Show failures
  echo "$checks" | jq -r '.[] | select(.state=="FAILURE" or .state=="ERROR") | "  FAIL: \(.name) -> \(.link)"'

  # Show pending
  if [ "$pending" -gt 0 ]; then
    echo "$checks" | jq -r '.[] | select(.state=="PENDING") | "  PEND: \(.name)"'
  fi

  # Extract DDCI request_id if present
  ddci_link=$(echo "$checks" | jq -r '.[] | select(.name | test("DDCI|Task Sourcing"; "i")) | .link' | head -1)
  if [ -n "$ddci_link" ] && [ "$ddci_link" != "null" ]; then
    request_id=$(echo "$ddci_link" | grep -oP 'change-request/\K[^/]+' 2>/dev/null || echo "")
    if [ -n "$request_id" ]; then
      echo "  DDCI request_id: ${request_id}"
    fi
  fi

  # Green check
  if [ "$failed" -eq 0 ] && [ "$pending" -eq 0 ]; then
    echo "  ✅ All checks passed"
  elif [ "$failed" -eq 0 ]; then
    echo "  ⏳ Waiting on ${pending} check(s)"
  fi

  echo ""
done
