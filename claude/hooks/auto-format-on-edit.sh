#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write) — auto-formats the file just edited,
# using whichever formatter is installed. Degrades silently when a tool is
# absent, so it never blocks an edit. Keeps formatting cheap-to-fix by doing it
# continuously instead of letting it pile up to CI.
#
# Runs in non-interactive bash — Saje's zsh aliases are NOT loaded, so `cat`,
# `grep`, etc. here are the real binaries.
set -euo pipefail

# Make common tool locations reachable (hook PATH is minimal).
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/go/bin:$PATH"
GOROOT_BIN="$(go env GOROOT 2>/dev/null)/bin" || true
[ -n "${GOROOT_BIN:-}" ] && [ -d "$GOROOT_BIN" ] && export PATH="$GOROOT_BIN:$PATH"

input="$(cat)"
f="$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
[ -z "$f" ] && exit 0
[ -f "$f" ] || exit 0

has(){ command -v "$1" >/dev/null 2>&1; }
sum(){ shasum "$1" 2>/dev/null | awk '{print $1}'; }

before="$(sum "$f")"
note=""

case "$f" in
  *.go)
    has goimports && goimports -w "$f" 2>/dev/null || true
    has gofmt && gofmt -w "$f" 2>/dev/null || true
    ;;
  *.tf|*.tfvars)
    if has terraform; then terraform fmt "$f" >/dev/null 2>&1 || true
    elif has tofu; then tofu fmt "$f" >/dev/null 2>&1 || true; fi
    ;;
  *.py)
    if has ruff; then ruff format "$f" >/dev/null 2>&1 || true
    elif has black; then black -q "$f" >/dev/null 2>&1 || true; fi
    ;;
  *.sh|*.bash)
    has shfmt && shfmt -w "$f" 2>/dev/null || true
    ;;
  *.js|*.jsx|*.ts|*.tsx|*.css|*.scss|*.md|*.yaml|*.yml)
    has prettier && prettier --write "$f" >/dev/null 2>&1 || true
    ;;
  *.json)
    # Reformat with prettier if present; otherwise at least validate (cheap, high value).
    if has prettier; then prettier --write "$f" >/dev/null 2>&1 || true
    elif has jq; then
      jq -e . "$f" >/dev/null 2>&1 || note="⚠️ ${f##*/} is not valid JSON — fix it before relying on the file."
    fi
    ;;
  *) exit 0 ;;
esac

after="$(sum "$f")"
if [ -n "$note" ]; then
  msg="$note"
elif [ "$before" != "$after" ]; then
  msg="🧹 Auto-formatted ${f##*/}. If you have its contents cached, re-read before the next edit."
else
  exit 0
fi

python3 - "$msg" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": sys.argv[1]}}))
PY
exit 0
