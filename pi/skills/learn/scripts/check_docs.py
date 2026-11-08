#!/usr/bin/env python3
"""Check a learn-skill docs folder before review.

Usage: check_docs.py <vault> <docs-folder>   (e.g. ~/Obsidian/Tech-2 "Topics/📘ME-CFS")

Docs pages fail on: footnotes referenced but not defined (or the reverse), duplicate
footnote definitions, footnotes without a ^passage link or citing passages from more
than one source note, footnotes inside callouts (use citation chips there), links to
notes, headings, or ^block IDs that don't exist, and Templater syntax (<%). Cited source
notes fail on: <%, duplicate block IDs, and filename characters Obsidian can't sync.
Exit 0 = clean, 1 = problems, 2 = bad usage.
"""
import re
import sys
from collections import Counter
from pathlib import Path

CODE = re.compile(r"```[\s\S]*?```|`[^`\n]*`")
LINK = re.compile(r"(?<!!)\[\[([^\]|#\\]*?)\\?(#[^\]|\\]+)?\\?(\|[^\]]*)?\]\]")
FOOTNOTE_DEF = re.compile(r"^\[\^([A-Za-z0-9_-]+)\]:(.*(?:\n(?:    |\t).*)*)", re.M)
FOOTNOTE_REF = re.compile(r"\[\^([A-Za-z0-9_-]+)\](?!:)")
BLOCK_ID = re.compile(r"\s\^([A-Za-z0-9-]+)\s*$", re.M)
HEADING = re.compile(r"^#+ (.+?)(?:\s+\^[A-Za-z0-9-]+)?\s*$", re.M)
BAD_FILENAME = re.compile(r'[\\/:*?"<>|#^\[\]]')
QUOTE_PREFIX = re.compile(r"^(?:[ \t]*>[ \t]?)+")
CALLOUT_START = re.compile(r"^\[![^\]]+\]")


def blank_code(m: re.Match) -> str:
    """Blank out code but keep line count and blockquote prefixes, so line numbers and
    callout nesting survive."""
    out = []
    for ln in m.group(0).split("\n"):
        q = QUOTE_PREFIX.match(ln)
        out.append(q.group(0) if q else "")
    return "\n".join(out)


def callout_footnotes(body: str) -> list[int]:
    """Line numbers of footnote references inside callouts ('> [!type]' blocks, nested
    ones included). Plain blockquotes render footnotes fine and aren't flagged."""
    hits, depth = [], None
    for lineno, line in enumerate(body.split("\n"), 1):
        q = QUOTE_PREFIX.match(line)
        if not q:
            depth = None
            continue
        level, rest = q.group(0).count(">"), line[q.end():]
        if depth is not None and level < depth:
            depth = None
        if depth is None and CALLOUT_START.match(rest):
            depth = level
        if depth is not None and FOOTNOTE_REF.search(rest):
            hits.append(lineno)
    return hits


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    vault = Path(sys.argv[1]).expanduser()
    docs = vault / sys.argv[2]
    pages = sorted(docs.glob("*.md"))
    if not pages:
        print(f"no .md files in {docs}")
        return 2
    notes: dict[str, Path] = {}
    for p in vault.rglob("*.md"):
        if ".trash" in p.parts:
            continue
        notes.setdefault(p.stem, p)
        notes[p.relative_to(vault).with_suffix("").as_posix()] = p
    cache: dict[Path, str] = {}

    def text(p: Path) -> str:
        if p not in cache:
            cache[p] = p.read_text(encoding="utf-8")
        return cache[p]

    errors: list[str] = []
    cited: set[Path] = set()
    for page in pages:
        raw = text(page)
        body = CODE.sub(blank_code, raw)
        name = page.name
        if "<%" in raw:
            errors.append(f"{name}: contains Templater syntax '<%'")
        defs = FOOTNOTE_DEF.findall(body)
        labels = [d[0] for d in defs]
        refs = set(FOOTNOTE_REF.findall(body))
        for label in sorted(x for x, n in Counter(labels).items() if n > 1):
            errors.append(f"{name}: footnote [^{label}] defined more than once")
        for label in sorted(refs - set(labels)):
            errors.append(f"{name}: footnote [^{label}] used but not defined")
        for label in sorted(set(labels) - refs):
            errors.append(f"{name}: footnote [^{label}] defined but never used")
        for lineno in callout_footnotes(body):
            errors.append(f"{name}:{lineno}: footnote inside a callout (Obsidian shows it as plain text); use a citation chip [[Source#^qN|Label]]")
        for label, rest in defs:
            sources = {m.group(1).strip() for m in LINK.finditer(rest) if m.group(1).strip() and (m.group(2) or "").startswith("#^")}
            if len(sources) != 1:
                errors.append(f"{name}: footnote [^{label}] must link ^passages in exactly one source note (found {len(sources)})")
        for m in LINK.finditer(body):
            target, frag = m.group(1).strip() or page.stem, (m.group(2) or "")[1:].strip()
            if target not in notes:
                errors.append(f"{name}: link to missing note [[{target}]]")
                continue
            dest = notes[target]
            if frag.startswith("^"):
                cited.add(dest)
                if frag[1:] not in BLOCK_ID.findall(text(dest)):
                    errors.append(f"{name}: [[{target}#{frag}]] has no matching block ID")
            elif frag and frag not in HEADING.findall(text(dest)):
                errors.append(f"{name}: [[{target}#{frag}]] has no matching heading")
    for src in sorted(cited):
        if src.parent == docs:
            continue
        rel = src.relative_to(vault)
        if "<%" in text(src):
            errors.append(f"{rel}: contains unescaped Templater syntax '<%'")
        for bid, n in Counter(BLOCK_ID.findall(text(src))).items():
            if n > 1:
                errors.append(f"{rel}: block ID ^{bid} appears {n} times")
        if BAD_FILENAME.search(src.stem):
            errors.append(f"{rel}: filename has characters Obsidian can't sync (\\ / : * ? \" < > | # ^ [ ])")
    for e in errors:
        print(e)
    print(f"{len(pages)} pages and {len(cited)} cited source notes checked, {len(errors)} problems")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
