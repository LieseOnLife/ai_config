#!/usr/bin/env bash
# PostToolUse hook (matcher: Bash)
# Detects `git push` and injects the mandatory Post-Push Protocol into context,
# so CI-watch + flake triage + PR-comment handling happen automatically without
# the user having to ask. See ~/.claude/CLAUDE.md "Post-Push Protocol".

set -euo pipefail

# Note: this script runs in non-interactive bash, so Saje's zsh aliases
# (cat->bat, grep->rg, ...) are NOT loaded here. `cat`/`grep` ARE the real binaries.
input="$(cat)"

# Extract the bash command that was run.
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"

# Only fire on an actual `git push` (not e.g. `git push --help`, not strings that merely mention it).
if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+([^;&|]*[[:space:]])?push([[:space:]]|$)'; then
  exit 0
fi
# Ignore explicit dry runs.
if printf '%s' "$cmd" | grep -Eq -- '--dry-run'; then
  exit 0
fi

read -r -d '' CONTEXT <<'EOF' || true
🔁 POST-PUSH PROTOCOL (automatic — you just ran `git push`). Do ALL of this now, without being asked:

1. WATCH CI. Resolve the PR URL (`gh pr view --json url -q .url`) and run
   `gh pr checks <url> --watch` until every check completes. Do NOT declare the
   task done or move on while checks are running.

2. ON ANY FAILURE, triage before reporting:
   • Flaky/infra (timeout, network, runner died, known-flaky test) → re-run the
     failed job (`gh run rerun <run-id> --failed`) ONCE. If it passes, note it
     and continue. If it fails again the same way, treat as real.
   • Real failure (your change broke it) → investigate and fix immediately, then
     push the fix (which re-triggers this protocol).
   • Genuinely ambiguous or needs a decision only Saje can make → bring it to
     Saje with the failing check, the log excerpt, and a recommendation.

3. AUTO-REVIEW YOUR OWN DIFF — only if this was a MAJOR change (new PR, new
   files, real logic, ~50+ lines; skip trivial typo/comment/rename pushes).
   • Run the right reviewer agent: go-code-reviewer for Go,
     dd:platform-security-reviewer for security-sensitive code (auth, secrets,
     IAM, infra/access). Use both when relevant.
   • Auto-fix obvious, safe issues and push the fix (re-triggers this protocol).
   • Surface judgment-call / design-tradeoff findings to Saje with file:line and
     a recommendation — do NOT auto-apply those.

4. ADDRESS PR COMMENTS automatically (do not wait to be told). Follow the
   /review-pr-comments process:
   • Bot comments (codex, sonar, codecov, github-actions, *[bot]) → evaluate and
     respond DEFINITIVELY: fix + reply, or reply why not applicable. Never leave
     an open question in a PR comment.
   • Human comments → do NOT auto-reply. Surface to Saje in-session with the
     link, summary, your recommendation, and a draft reply for approval.

5. REPORT BACK in-session: what CI did (incl. any re-runs), auto-review findings
   (fixed vs. needs-decision), what comments you handled, and a clear list of
   anything that needs Saje's attention.

This is mandatory and automatic. The push is not "done" until CI is green (or
escalated), major diffs are reviewed, and comments are handled.
EOF

python3 - "$CONTEXT" <<'PY'
import json, sys
ctx = sys.argv[1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": ctx
    }
}))
PY
exit 0
