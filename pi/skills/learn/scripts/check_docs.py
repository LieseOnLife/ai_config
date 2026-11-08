#!/usr/bin/env python3
"""Check a learn-skill docs folder before review.

Usage: check_docs.py <vault> <docs-folder>   (e.g. ~/Obsidian/research "Topics/📘ME-CFS")

Fails (exit 1) on: footnotes referenced but not defined (or the reverse), duplicate
footnote definitions, footnotes citing more than one source note, links to notes,
headings, or ^block IDs that don't exist, and Templater syntax (<%) in docs pages.
"""
import re
import sys
from pathlib import Path

LINK = re.compile(r"\[\[([^\]|#]+?)\\?(#[^\]|]+)?(\\?\|[^\]]*)?\]\]")
FOOTNOTE_DEF = re.compile(r"^\[\^([A-Za-z0-9_-]+)\]:(.*)$", re.M)
FOOTNOTE_REF = re.compile(r"\[\^([A-Za-z0-9_-]+)\](?!:)")
BLOCK_ID = re.compile(r"\s\^([A-Za-z0-9-]+)\s*$", re.M)
HEADING = re.compile(r"^#+ (.+?)\s*$", re.M)


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    vault = Path(sys.argv[1]).expanduser()
    docs = vault / sys.argv[2]
    notes = {p.stem: p for p in vault.rglob("*.md") if ".trash" not in p.parts}
    cache: dict[Path, str] = {}

    def text(p: Path) -> str:
        if p not in cache:
            cache[p] = p.read_text(encoding="utf-8")
        return cache[p]

    errors = []
    pages = sorted(docs.glob("*.md"))
    for page in pages:
        body = text(page)
        name = page.name
        if "<%" in body:
            errors.append(f"{name}: contains Templater syntax '<%'")
        defs = FOOTNOTE_DEF.findall(body)
        labels = [d[0] for d in defs]
        refs = set(FOOTNOTE_REF.findall(body))
        for label in sorted({x for x in labels if labels.count(x) > 1}):
            errors.append(f"{name}: footnote [^{label}] defined more than once")
        for label in sorted(refs - set(labels)):
            errors.append(f"{name}: footnote [^{label}] used but not defined")
        for label in sorted(set(labels) - refs):
            errors.append(f"{name}: footnote [^{label}] defined but never used")
        for label, rest in defs:
            sources = {m.group(1).strip().rstrip("\\") for m in LINK.finditer(rest)}
            if len(sources) != 1:
                errors.append(f"{name}: footnote [^{label}] should cite exactly one source note, cites {len(sources)}")
        for m in LINK.finditer(re.sub(r"`[^`\n]*`", "", body)):
            target, frag = m.group(1).strip().rstrip("\\"), (m.group(2) or "")[1:]
            if target not in notes:
                errors.append(f"{name}: link to missing note [[{target}]]")
                continue
            if frag.startswith("^"):
                if frag[1:] not in BLOCK_ID.findall(text(notes[target])):
                    errors.append(f"{name}: [[{target}#{frag}]] has no matching block ID")
            elif frag and frag not in HEADING.findall(text(notes[target])):
                errors.append(f"{name}: [[{target}#{frag}]] has no matching heading")
    for e in errors:
        print(e)
    print(f"{len(pages)} pages checked, {len(errors)} problems")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
