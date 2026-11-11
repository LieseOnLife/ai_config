#!/usr/bin/env python3
"""List Claude Code and Codex sessions active on a date, as JSON lines.

Usage: other_sessions.py YYYY-MM-DD

One object per session: tool, file, cwd, branch, first prompt, last assistant text.
omp sessions aren't listed here; the evening skill reads those through `archive`.
"""
import datetime
import glob
import json
import os
import sys

CLIP = 600


def text_of(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") in ("text", "input_text", "output_text"))
    return ""


def active_on(path, day):
    mtime = datetime.date.fromtimestamp(os.path.getmtime(path))
    return mtime >= day


def claude(day):
    for f in glob.glob(os.path.expanduser("~/.claude/projects/*/*.jsonl")):
        if not active_on(f, day):
            continue
        first = last = cwd = branch = None
        touched = False
        for line in open(f, encoding="utf-8", errors="replace"):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            ts = r.get("timestamp", "")
            if ts[:10] == day.isoformat():
                touched = True
            cwd = r.get("cwd") or cwd
            branch = r.get("gitBranch") or branch
            msg = r.get("message") or {}
            if r.get("type") == "user" and isinstance(msg.get("content"), str) and not first:
                first = msg["content"]
            if r.get("type") == "assistant":
                t = text_of(msg.get("content")).strip()
                if t:
                    last = t
        if touched and first:
            yield {"tool": "claude-code", "file": f, "cwd": cwd, "branch": branch,
                   "first_prompt": first[:CLIP], "last_reply": (last or "")[:CLIP]}


def codex(day):
    for f in glob.glob(os.path.expanduser("~/.codex/sessions/*/*/*/*.jsonl")):
        if not active_on(f, day):
            continue
        first = last = cwd = None
        touched = False
        for line in open(f, encoding="utf-8", errors="replace"):
            try:
                r = json.loads(line)
            except ValueError:
                continue
            if r.get("timestamp", "")[:10] == day.isoformat():
                touched = True
            p = r.get("payload") or {}
            cwd = p.get("cwd") or cwd
            if p.get("type") == "user_message" and not first:
                first = p.get("message", "")
            if p.get("type") == "agent_message":
                last = p.get("message", "") or last
        if touched and first:
            yield {"tool": "codex", "file": f, "cwd": cwd, "branch": None,
                   "first_prompt": first[:CLIP], "last_reply": (last or "")[:CLIP]}


def main():
    day = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()
    for s in [*claude(day), *codex(day)]:
        print(json.dumps(s, ensure_ascii=False))


if __name__ == "__main__":
    main()
