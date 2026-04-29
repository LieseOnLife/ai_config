#!/usr/bin/env python3
import sys
import json
import os


def load_allowed_prefixes():
    prefixes = set()
    settings_path = os.path.expanduser("~/.claude/settings.json")
    try:
        with open(settings_path) as f:
            settings = json.load(f)
        for rule in settings.get("permissions", {}).get("allow", []):
            if not rule.startswith("Bash("):
                continue
            inner = rule[5:]
            if inner.endswith(":*)"):
                prefixes.add(inner[:-3])
            elif inner.endswith(")"):
                prefixes.add(inner[:-1])
    except Exception:
        pass
    return prefixes


def is_pipeline_part(line):
    return line.startswith(("|", "&&", "||", ";", "2>", ">", "<"))


def is_data_content(line):
    return line.startswith(("{", "}", "[", "]", '"', "'"))


def is_description(line):
    words = line.split()
    if not words:
        return False
    first = words[0]
    return first[0].isupper() and not first.isupper()


def get_effective_lines(cmd):
    effective = []
    current = None
    for raw in cmd.split("\n"):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.endswith("\\"):
            if current is None:
                current = stripped[:-1].strip()
        else:
            if current is not None:
                effective.append(current)
                current = None
            else:
                effective.append(stripped)
    if current is not None:
        effective.append(current)
    return effective


def line_is_allowed(line, prefixes):
    if is_pipeline_part(line):
        return True
    if is_data_content(line):
        return True
    if is_description(line):
        return True
    return any(line.startswith(p) for p in prefixes)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return

    cmd = data.get("tool_input", {}).get("command", "")
    if not cmd:
        return

    prefixes = load_allowed_prefixes()
    if not prefixes:
        return

    lines = get_effective_lines(cmd)
    if not lines:
        return

    if all(line_is_allowed(line, prefixes) for line in lines):
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": "All commands match allowed prefixes"
            }
        }))


if __name__ == "__main__":
    main()
