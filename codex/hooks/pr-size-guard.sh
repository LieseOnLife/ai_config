#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — guards against silently opening oversized PRs.
# When a `gh pr create` would open a PR larger than Saje's budget (400 lines / 10
# files), it surfaces the size and asks for confirmation before proceeding.
# Backstop for the small-PR discipline in ~/.codex/CLAUDE.md "Stacked PRs".
#
# Runs in non-interactive bash — Saje's zsh aliases are NOT loaded, so `cat`/`grep`
# here are the real binaries.
set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null || true)"

# Only fire on an actual `gh pr create`.
if ! printf '%s' "$cmd" | grep -Eq '(^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
  exit 0
fi

[ -n "$cwd" ] && cd "$cwd" 2>/dev/null || true

# Find the base branch to diff against.
base=""
for b in origin/main origin/master main master; do
  if git rev-parse --verify --quiet "$b" >/dev/null 2>&1; then base="$b"; break; fi
done
[ -z "$base" ] && exit 0

stat="$(git diff --shortstat "${base}...HEAD" 2>/dev/null || true)"
[ -z "$stat" ] && exit 0

files="$(printf '%s' "$stat" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || true)"
ins="$(printf '%s' "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || true)"
del="$(printf '%s' "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || true)"
files=${files:-0}; ins=${ins:-0}; del=${del:-0}
lines=$((ins + del))

# Within budget — allow silently.
if [ "$lines" -le 400 ] && [ "$files" -le 10 ]; then
  exit 0
fi

REASON="PR SIZE GUARD: this PR is ~${lines} changed lines across ${files} files vs ${base}, over Saje's budget (400 lines / 10 files). Per the Stacked-PRs rule, prefer splitting it into smaller stacked PRs. Open it anyway only if it genuinely can't be split (and you've told Saje the size + why)."

python3 - "$REASON" <<'PY'
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": sys.argv[1]
    }
}))
PY
exit 0
