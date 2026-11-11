#!/usr/bin/env python3
"""Mark notes whose origin is obvious with an `authorship` frontmatter property.

Usage: authorship.py <vault> [--apply] [--backup-dir DIR]

Dry run by default: prints what each rule would mark. With --apply it backs up every
file it changes to DIR (default ~/Obsidian/.authorship-backup-<date>/), keeps each
file's modification time, and never touches a note that already has `authorship`.
Notes no rule matches stay unmarked (unknown).
"""
import argparse
import collections
import datetime
import os
import re
import shutil
import sys

FM_RE = re.compile(r"\A---\n(.*?)\n---[ \t]*(?:\n|\Z)", re.S)
SKIP_DIRS = {".obsidian", ".trash", ".git"}


def classify(rel, fm, body):
    """Return (value, rule) for the first rule that matches, or (None, None)."""
    name = os.path.basename(rel)
    ty = re.search(r"^type:\s*(.*)$", fm, re.M)
    ty = ty.group(1).strip() if ty else ""
    if rel.startswith("Extras/Templates/"):
        return None, None
    if ty == "slack_summary":
        return "ai", "Slack Summary (/morning)"
    if "📘 Docs" in ty:
        return "ai", "/learn docs page"
    if rel.startswith("Datadog/Career/brag-sheet"):
        return "ai", "brag-sheet output"
    if rel.startswith(("Sources/Readwise/", "Sources/Omnivore/")):
        return "external", "Readwise/Omnivore import"
    if name.startswith("💬"):
        return "mixed", "💬 Slack conversation note"
    if ty == "weekly_notes":
        return "mixed", "weekly page (/weekly, /snippet)"
    if ty in ("cloud_admin", "interrupt_handler") or name.startswith("🌧️"):
        return "mixed", "Cloud Admin / on-call note"
    if ty == '"[[🎞️ Task]]"':
        return "mixed", "Jira task note (/weekly)"
    if re.search(r"^docs:\s*\S", fm, re.M) or re.search(r"^docs:\s*\n\s+-", fm, re.M):
        return "mixed", "/learn source note"
    if re.search(r"^## (🤖AI notes|📈 Trends since last retro)", body, re.M):
        return "mixed", "meeting note with 🤖AI notes or retro trends"
    return None, None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vault")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--backup-dir")
    a = ap.parse_args()
    vault = os.path.abspath(os.path.expanduser(a.vault))
    backup = os.path.expanduser(
        a.backup_dir or f"~/Obsidian/.authorship-backup-{datetime.date.today():%Y-%m-%d}"
    )

    by_rule = collections.Counter()
    by_value = collections.Counter()
    already = 0
    changed = []
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if not f.endswith(".md"):
                continue
            path = os.path.join(root, f)
            rel = os.path.relpath(path, vault)
            try:
                text = open(path, encoding="utf-8").read()
            except (UnicodeDecodeError, OSError):
                continue
            m = FM_RE.match(text)
            fm = m.group(1) if m else ""
            if re.search(r"^authorship:", fm, re.M):
                already += 1
                continue
            value, rule = classify(rel, fm, text[m.end():] if m else text)
            if not value:
                continue
            by_rule[(value, rule)] += 1
            by_value[value] += 1
            if m:
                new = text[: m.start(1)] + fm + f"\nauthorship: {value}" + text[m.end(1):]
            else:
                new = f"---\nauthorship: {value}\n---\n" + text
            changed.append((path, rel, new))

    for (value, rule), n in sorted(by_rule.items(), key=lambda kv: -kv[1]):
        print(f"{n:5}  {value:8}  {rule}")
    print(f"\nWould mark {len(changed)} notes: " + ", ".join(f"{k} {v}" for k, v in by_value.most_common()))
    print(f"Already marked (left alone): {already}")
    if not a.apply:
        print("Dry run. Re-run with --apply to write.")
        return 0

    for path, rel, new in changed:
        dest = os.path.join(backup, rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(path, dest)
        st = os.stat(path)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
        os.utime(path, (st.st_atime, st.st_mtime))
    print(f"Wrote {len(changed)} notes. Originals backed up to {backup}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
