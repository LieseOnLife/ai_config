#!/usr/bin/env python3
"""Move `created:` to the last field in frontmatter for all Obsidian notes."""
import os
import re
import sys

VAULT = os.path.expanduser("~/Obsidian/Tech-2")
DRY_RUN = "--dry-run" in sys.argv
SKIP_DIRS = {".obsidian", ".trash", os.path.join("Extras", "Templates")}

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

        if not content.startswith("---\n"):
            skipped += 1
            continue

        end = content.find("\n---", 4)
        if end == -1:
            skipped += 1
            continue

        fm = content[4:end]          # frontmatter body (between the two ---)
        rest = content[end:]          # \n---\n... (body of note)

        if "\ncreated:" not in ("\n" + fm):
            skipped += 1
            continue

        # Extract the created line (may span just one line)
        created_match = re.search(r"^created:.*$", fm, re.MULTILINE)
        if not created_match:
            skipped += 1
            continue

        created_line = created_match.group(0)

        # Already last? Skip
        if fm.rstrip("\n").endswith(created_line):
            skipped += 1
            continue

        # Remove created: line and trailing blank line if any
        new_fm = re.sub(r"^created:.*\n?", "", fm, flags=re.MULTILINE)
        new_fm = new_fm.rstrip("\n") + "\n" + created_line

        new_content = f"---\n{new_fm}{rest}"

        if DRY_RUN:
            rel = os.path.relpath(path, VAULT)
            print(f"  {rel!r}")
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_content)
        updated += 1

label = "would update" if DRY_RUN else "updated"
print(f"\n{label}: {updated}  |  skipped: {skipped}")
