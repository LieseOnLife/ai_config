#!/usr/bin/env python3
"""Link ai_projects GSD archive docs to their Obsidian project-index notes.

For each project archive under ~/repos/ai_projects (cloud-inventory/*,
datadog/*, dd-source/*, ...), this picks the "top-level" docs, interactively
matches the archive to a project-index note in the Obsidian vault, and injects
frontmatter so the docs surface under that project in the `Project Docs.base`
view (which matches on `project == this.file`).

Frontmatter written (merged, never clobbered):

    project: "[[<index note name>]]"
    type: ai-doc
    tags: [🐶, ai_prompts]
    created: <file birth date> 00:00:00

Default is a dry run. Pass --apply to actually write.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

HOME = Path.home()
DEFAULT_ARCHIVES_ROOT = HOME / "repos" / "ai_projects"
DEFAULT_VAULT_PROJECTS = HOME / "Obsidian" / "Tech-2" / "Datadog" / "Projects"

# Top-level dirs under the archives root that are NOT project namespaces.
NAMESPACE_SKIP = {"templates", ".git", ".claude"}
# Subfolders inside an archive that hold noise we never want to link.
DOC_SKIP_DIRS = {"phases", "research", "planning"}

MANAGED_KEYS = ("project", "type", "tags", "created")
DOC_TYPE = "ai-doc"
DOC_TAGS = ["🐶", "ai_prompts"]

TICKET_RE = re.compile(r"\b([A-Z]{2,}-\d+)\b")
TOKEN_RE = re.compile(r"[a-z0-9]+")


# ---------------------------------------------------------------------------
# Frontmatter parsing / serialization (minimal, order-preserving)
# ---------------------------------------------------------------------------


def split_frontmatter(text: str):
    """Return (fm_lines, body, had_fm).

    fm_lines is the list of raw lines *between* the --- fences (no fences).
    """
    if not text.startswith("---\n") and not text.startswith("---\r\n"):
        return [], text, False
    lines = text.splitlines(keepends=True)
    # lines[0] is the opening fence
    for i in range(1, len(lines)):
        if lines[i].rstrip("\r\n") == "---":
            fm = lines[1:i]
            body = "".join(lines[i + 1 :])
            return fm, body, True
    # No closing fence -> treat whole thing as body, safest.
    return [], text, False


def group_fm_keys(fm_lines):
    """Group raw frontmatter lines into [(key, [raw lines]), ...].

    A top-level key starts at column 0 with `key:`. Continuation lines
    (indented, blank, or list items) belong to the preceding key.
    """
    groups = []
    current = None  # (key, [lines])
    key_re = re.compile(r"^([^\s:#][^:]*):(.*)$")
    for line in fm_lines:
        m = key_re.match(line)
        if m and not line.startswith((" ", "\t", "-")):
            if current is not None:
                groups.append(current)
            current = [m.group(1).strip(), [line]]
        else:
            if current is None:
                # Stray leading line; keep it attached to a synthetic group.
                current = ["", [line]]
            else:
                current[1].append(line)
    if current is not None:
        groups.append(current)
    return [(k, v) for k, v in groups]


def serialize_managed(key, value):
    """Serialize one managed key to YAML lines (list of strings w/ newlines)."""
    if key == "tags":
        out = ["tags:\n"]
        for item in value:
            out.append(f"  - {item}\n")
        return out
    if key == "project":
        # Quote because [[ ]] is YAML flow-sequence syntax otherwise.
        return [f'project: "{value}"\n']
    # scalar, unquoted (created / type)
    return [f"{key}: {value}\n"]


def build_frontmatter(existing_groups, managed):
    """Merge managed values into existing key groups, preserving others."""
    out_lines = []
    seen = set()
    for key, raw in existing_groups:
        if key in managed:
            out_lines.extend(serialize_managed(key, managed[key]))
            seen.add(key)
        else:
            out_lines.extend(raw)
    # Append managed keys that weren't already present, in canonical order.
    for key in MANAGED_KEYS:
        if key in managed and key not in seen:
            out_lines.extend(serialize_managed(key, managed[key]))
    return out_lines


def render_file(original_text: str, managed: dict) -> str:
    fm_lines, body, had_fm = split_frontmatter(original_text)
    groups = group_fm_keys(fm_lines) if had_fm else []
    new_fm = build_frontmatter(groups, managed)
    return "---\n" + "".join(new_fm) + "---\n" + ("" if had_fm else "\n") + body


# ---------------------------------------------------------------------------
# Discovery
# ---------------------------------------------------------------------------


def discover_archives(root: Path):
    """Yield project archive dirs: immediate children of each namespace dir."""
    archives = []
    for ns in sorted(root.iterdir()):
        if not ns.is_dir() or ns.name in NAMESPACE_SKIP:
            continue
        for child in sorted(ns.iterdir()):
            if child.is_dir() and not child.name.startswith("."):
                archives.append(child)
    return archives


def pick_docs(archive: Path):
    """Top-level docs rule: root .md, else the single non-hidden subdir's .md."""
    root_md = sorted(archive.glob("*.md"))
    if root_md:
        return root_md
    subdirs = [
        d
        for d in sorted(archive.iterdir())
        if d.is_dir() and not d.name.startswith(".") and d.name not in DOC_SKIP_DIRS
    ]
    if len(subdirs) == 1:
        return sorted(subdirs[0].glob("*.md"))
    return []


# ---------------------------------------------------------------------------
# Index-note matching
# ---------------------------------------------------------------------------


def load_index_notes(projects_dir: Path):
    """Return [{name, path, tickets:set, tokens:set, type}] for project-index notes."""
    notes = []
    for p in sorted(projects_dir.glob("*.md")):
        try:
            head = p.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        fm_lines, _, had_fm = split_frontmatter(head)
        if not had_fm:
            continue
        fm_text = "".join(fm_lines)
        if not re.search(r"^type:\s*project-index\s*$", fm_text, re.MULTILINE):
            continue
        name = p.stem  # filename without .md == wikilink target
        haystack = name + "\n" + fm_text
        notes.append(
            {
                "name": name,
                "path": p,
                "tickets": set(TICKET_RE.findall(haystack)),
                "tokens": set(TOKEN_RE.findall(name.lower())),
            }
        )
    return notes


def archive_signals(archive: Path, docs):
    """Gather ticket IDs + name tokens for an archive (name + doc contents)."""
    tickets = set(TICKET_RE.findall(archive.name.upper()))
    tokens = set(TOKEN_RE.findall(archive.name.lower()))
    for d in docs:
        try:
            tickets |= set(TICKET_RE.findall(d.read_text(encoding="utf-8")))
        except (OSError, UnicodeDecodeError):
            pass
    return tickets, tokens


def rank_candidates(tickets, tokens, notes):
    scored = []
    for note in notes:
        score = 0.0
        if tickets & note["tickets"]:
            score += 100.0
        if tokens and note["tokens"]:
            inter = len(tokens & note["tokens"])
            union = len(tokens | note["tokens"])
            score += 50.0 * (inter / union)
        scored.append((score, note))
    scored.sort(key=lambda s: s[0], reverse=True)
    return scored


# ---------------------------------------------------------------------------
# Interactive selection
# ---------------------------------------------------------------------------


def custom_search(notes):
    """Substring-search all index notes, let the user pick one. Returns name or None."""
    while True:
        q = input("    search (substring of note name, blank to cancel): ").strip()
        if not q:
            return None
        hits = [n for n in notes if q.lower() in n["name"].lower()]
        if not hits:
            print("    no matching project-index notes; try again.")
            continue
        for i, n in enumerate(hits[:15], 1):
            print(f"      [{i}] {n['name']}")
        sel = input("    pick number (blank to search again): ").strip()
        if sel.isdigit() and 1 <= int(sel) <= len(hits[:15]):
            return hits[int(sel) - 1]["name"]


def choose_note(archive: Path, scored, notes, interactive: bool):
    """Return the chosen index-note name, or None to skip."""
    top = scored[:3]
    print(f"\n=== Archive: {archive}")
    if not top or top[0][0] == 0:
        print("  No candidate project notes scored > 0.")
    for i, (score, note) in enumerate(top, 1):
        print(f"  [{i}] ({score:5.1f}) {note['name']}")

    if not interactive:
        if top and top[0][0] >= 50.0:
            print(f"  -> auto-selected [1] {top[0][1]['name']} (non-interactive)")
            return top[0][1]["name"]
        print("  -> skipped (non-interactive, no confident match)")
        return None

    while True:
        ans = input("  Pick [1-3], (c)ustom search, (s)kip, default=1: ").strip()
        if ans == "" and top and top[0][0] > 0:
            return top[0][1]["name"]
        if ans.lower() == "s":
            return None
        if ans.lower() == "c":
            chosen = custom_search(notes)
            if chosen:
                return chosen
            continue
        if ans.isdigit() and 1 <= int(ans) <= len(top):
            return top[int(ans) - 1][1]["name"]
        print("    ? try again.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def birth_date(path: Path) -> str:
    st = path.stat()
    ts = getattr(st, "st_birthtime", st.st_mtime)
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%d 00:00:00")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--archives-root", type=Path, default=DEFAULT_ARCHIVES_ROOT)
    ap.add_argument("--vault-projects", type=Path, default=DEFAULT_VAULT_PROJECTS)
    ap.add_argument(
        "--apply",
        action="store_true",
        help="Write changes. Without this, runs as a dry run.",
    )
    ap.add_argument(
        "--interactive",
        dest="interactive",
        action="store_true",
        default=None,
        help="Force interactive prompts (default: auto-detect a TTY).",
    )
    ap.add_argument(
        "--no-interactive",
        dest="interactive",
        action="store_false",
        help="Force non-interactive (auto-select confident matches only).",
    )
    args = ap.parse_args(argv)

    if not args.archives_root.is_dir():
        sys.exit(f"archives root not found: {args.archives_root}")
    if not args.vault_projects.is_dir():
        sys.exit(f"vault projects dir not found: {args.vault_projects}")

    notes = load_index_notes(args.vault_projects)
    if not notes:
        sys.exit(f"no project-index notes found in {args.vault_projects}")
    print(f"Loaded {len(notes)} project-index notes from {args.vault_projects}")

    interactive = sys.stdin.isatty() if args.interactive is None else args.interactive
    if not interactive:
        print("(no TTY: auto-selecting confident matches, skipping the rest)")

    mode = "APPLY" if args.apply else "DRY-RUN"
    archives = discover_archives(args.archives_root)
    print(f"Found {len(archives)} archive(s). Mode: {mode}\n")

    planned = []  # (doc_path, note_name, new_text)
    skipped_empty = []

    for archive in archives:
        docs = pick_docs(archive)
        if not docs:
            skipped_empty.append(archive)
            print(f"\n=== Archive: {archive}\n  !! no top-level docs found — skipped")
            continue
        tickets, tokens = archive_signals(archive, docs)
        scored = rank_candidates(tickets, tokens, notes)
        note_name = choose_note(archive, scored, notes, interactive)
        if not note_name:
            continue
        wikilink = f"[[{note_name}]]"
        for doc in docs:
            managed = {
                "project": wikilink,
                "type": DOC_TYPE,
                "tags": DOC_TAGS,
                "created": birth_date(doc),
            }
            original = doc.read_text(encoding="utf-8")
            new_text = render_file(original, managed)
            planned.append((doc, note_name, new_text, original != new_text))

    # ---- Report / apply ----
    print("\n" + "=" * 70)
    print(f"Planned frontmatter writes ({mode}):")
    changed = 0
    for doc, note_name, new_text, will_change in planned:
        rel = doc.relative_to(args.archives_root)
        flag = "write" if will_change else "no-op"
        print(f"  [{flag}] {rel}  ->  project: [[{note_name}]]")
        if will_change:
            changed += 1
            if not args.apply:
                # show the frontmatter block we'd write
                fm = new_text.split("---\n", 2)
                if len(fm) >= 2:
                    for ln in fm[1].splitlines():
                        print(f"          | {ln}")

    if args.apply:
        for doc, _, new_text, will_change in planned:
            if will_change:
                doc.write_text(new_text, encoding="utf-8")
        print(f"\nApplied {changed} file(s).")
    else:
        print(f"\nDRY RUN — {changed} file(s) would change. Re-run with --apply.")

    if skipped_empty:
        print("\nArchives with no top-level docs (review manually):")
        for a in skipped_empty:
            print(f"  - {a.relative_to(args.archives_root)}")


if __name__ == "__main__":
    main()
