#!/usr/bin/env python3
"""
Backfill `created:` frontmatter into Obsidian notes.

Priority for the created value:
  1. date_start (most semantically meaningful)
  2. date
  3. filesystem birthtime (fallback)

If date_start or date is found, always writes/overwrites created:.
If only birthtime is available, only writes if created: is missing.
"""
import os
import sys
import re
import datetime

VAULT = os.path.expanduser("~/Obsidian/Tech-2")
DRY_RUN = "--dry-run" in sys.argv

SKIP_DIRS = {".obsidian", ".trash", os.path.join("Extras", "Templates")}


def get_birthtime(path):
    s = os.stat(path)
    ts = s.st_birthtime if hasattr(s, "st_birthtime") else s.st_mtime
    return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d %H:%M:%S")


def extract_frontmatter_field(content, field):
    """Return value of a frontmatter field, or None if not present."""
    m = re.search(rf"^{field}:\s*(.+)$", content, re.MULTILINE)
    return m.group(1).strip() if m else None


def normalize_date(val):
    """Ensure date string has a time component."""
    val = val.strip().strip('"').strip("'")
    if re.match(r"^\d{4}-\d{2}-\d{2}$", val):
        return val + " 00:00:00"
    return val


def has_created(content):
    return bool(re.search(r"^created:", content, re.MULTILINE))


def set_created(content, value):
    """Insert or replace created: in frontmatter."""
    if has_created(content):
        return re.sub(r"^created:.*$", f"created: {value}", content, flags=re.MULTILINE)
    if content.startswith("---\n"):
        return content.replace("---\n", f"---\ncreated: {value}\n", 1)
    return f"---\ncreated: {value}\n---\n" + content


updated, skipped = 0, 0

for root, dirs, files in os.walk(VAULT):
    rel_root = os.path.relpath(root, VAULT)
    dirs[:] = [
        d for d in dirs
        if not d.startswith(".")
        and os.path.join(rel_root, d) not in SKIP_DIRS
        and d not in SKIP_DIRS
    ]
    for fname in files:
        if not fname.endswith(".md"):
            continue
        path = os.path.join(root, fname)
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        date_start = extract_frontmatter_field(content, "date_start")
        date_field = extract_frontmatter_field(content, "date")

        if date_start:
            source = "date_start"
            created_value = normalize_date(date_start)
        elif date_field:
            source = "date"
            created_value = normalize_date(date_field)
        elif not has_created(content):
            source = "birthtime"
            created_value = get_birthtime(path)
        else:
            skipped += 1
            continue

        # If only birthtime and created already exists, skip
        if source == "birthtime" and has_created(content):
            skipped += 1
            continue

        new_content = set_created(content, created_value)
        rel = os.path.relpath(path, VAULT)

        if DRY_RUN:
            print(f"  [{source}] {rel!r}  →  {created_value}")
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_content)
        updated += 1

label = "would update" if DRY_RUN else "updated"
print(f"\n{label}: {updated}  |  skipped: {skipped}")
