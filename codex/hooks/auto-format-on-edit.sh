#!/usr/bin/env bash
# PostToolUse hook for Edit, Write, and apply_patch. Format files changed by the
# completed tool when a suitable formatter is installed. Formatting failures do
# not block the original edit.

set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/go/bin:$PATH"
GOROOT_BIN="$(go env GOROOT 2>/dev/null)/bin" || true
[ -n "${GOROOT_BIN:-}" ] && [ -d "$GOROOT_BIN" ] && export PATH="$GOROOT_BIN:$PATH"

input="$(cat)"
files="$(printf '%s' "$input" | python3 -c '
import json, re, sys
data = json.load(sys.stdin)
tool_input = data.get("tool_input", {})
paths = []
if tool_input.get("file_path"):
    paths.append(tool_input["file_path"])
for path in re.findall(r"^\*\*\* (?:Add|Update) File: (.+)$", tool_input.get("patch", ""), re.M):
    if path not in paths:
        paths.append(path)
print("\n".join(paths))
' 2>/dev/null || true)"
[ -z "$files" ] && exit 0

has() { command -v "$1" >/dev/null 2>&1; }
sum() { shasum "$1" 2>/dev/null | awk '{print $1}'; }

messages=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
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
      if has prettier; then prettier --write "$f" >/dev/null 2>&1 || true
      elif has jq; then
        jq -e . "$f" >/dev/null 2>&1 || note="⚠️ ${f##*/} is not valid JSON — fix it before relying on the file."
      fi
      ;;
    *) continue ;;
  esac

  after="$(sum "$f")"
  if [ -n "$note" ]; then
    messages="${messages}${note}\n"
  elif [ "$before" != "$after" ]; then
    messages="${messages}🧹 Auto-formatted ${f##*/}. Re-read it before the next edit.\n"
  fi
done <<< "$files"

[ -z "$messages" ] && exit 0

python3 - "$messages" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": sys.argv[1].rstrip()}}))
PY
