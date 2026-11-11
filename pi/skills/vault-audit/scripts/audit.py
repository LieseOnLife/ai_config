#!/usr/bin/env python3
"""Read-only health check for an Obsidian vault. Prints a Markdown report.

Usage: audit.py <vault> [--limit N]

Never writes to the vault. The vault-audit skill saves the report and offers fixes.
"""
import argparse
import collections
import os
import re
import sys

SKIP_DIRS = {".obsidian", ".trash", ".git", "node_modules"}
DATED_RE = re.compile(r"^\d{4}-\d{2}-\d{2}( - Slack Summary)?$")  # nav links to days with no note
ATTACH_EXT = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".pdf", ".heic", ".mp4", ".mov"}
IMPORTS = ("Sources/Readwise/", "Sources/Omnivore/")
# Notes where "nothing links here" is normal: dated logs, imports, templates, hubs.
ORPHAN_EXEMPT = ("Calendar/", "Extras/", "Sources/Readwise/", "Sources/Omnivore/", "01 Maps of Content/")
LINK_RE = re.compile(r"!?\[\[([^\]\n]+?)\]\]")
FENCE_RE = re.compile(r"^(```|~~~).*?^\1", re.M | re.S)
INLINE_CODE_RE = re.compile(r"`[^`\n]*`")
FM_RE = re.compile(r"\A---\n(.*?)\n---[ \t]*(?:\n|\Z)", re.S)
AUTHORSHIP = ("human", "ai", "mixed", "external")


def walk(vault):
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if f.startswith("."):
                continue
            yield os.path.relpath(os.path.join(root, f), vault)


def link_target(raw):
    t = raw.split("|", 1)[0].rstrip("\\")
    t = re.split(r"#|\^", t, 1)[0].strip()
    return t


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vault")
    ap.add_argument("--limit", type=int, default=40, help="max items listed per check")
    a = ap.parse_args()
    vault = os.path.abspath(os.path.expanduser(a.vault))

    files = sorted(walk(vault))
    notes = [f for f in files if f.endswith(".md")]
    by_name = collections.defaultdict(list)  # lowercased basename (no .md) -> paths
    by_file = collections.defaultdict(list)  # lowercased file name with extension -> paths
    for f in files:
        base = os.path.basename(f)
        by_file[base.lower()].append(f)
        if f.endswith(".md"):
            by_name[base[:-3].lower()].append(f)
    lower_paths = {f.lower(): f for f in files}

    def resolve(t):
        tl = t.lower()
        if "/" in tl:
            for cand in (tl, tl + ".md"):
                if cand in lower_paths:
                    return True
                if any(p.endswith("/" + cand) for p in lower_paths):
                    return True
            return False
        return tl in by_name or tl in by_file

    broken = collections.defaultdict(set)  # missing target -> notes linking to it
    missing_people = collections.defaultdict(set)  # 👤 links with no person note yet
    incoming = collections.Counter()
    outgoing = collections.Counter()
    empty, no_fm, no_type, templater, untitled = [], [], [], [], []
    authorship = collections.Counter()
    unmarked_by_folder = collections.Counter()
    tags = collections.defaultdict(set)

    for n in notes:
        try:
            text = open(os.path.join(vault, n), encoding="utf-8").read()
        except (UnicodeDecodeError, OSError):
            continue
        is_template = n.startswith("Extras/Templates/")
        m = FM_RE.match(text)
        fm = m.group(1) if m else ""
        body = text[m.end():] if m else text
        if os.path.basename(n).lower().startswith("untitled"):
            untitled.append(n)
        if is_template:
            continue
        if not m:
            no_fm.append(n)
        elif not re.search(r"^type:\s*\S", fm, re.M):
            no_type.append(n)
        if not body.strip():
            empty.append(n)
        if "<%" in text:
            templater.append(n)
        am = re.search(r"^authorship:\s*['\"]?(\w+)", fm, re.M)
        value = am.group(1).lower() if am else None
        if value in AUTHORSHIP:
            authorship[value] += 1
        else:
            authorship["unmarked" if value is None else f"invalid ({value})"] += 1
            if value is None:
                unmarked_by_folder[os.path.dirname(n).split("/")[0] or "<root>"] += 1
        for t in re.findall(r"(?:^|\s)#([^\s#,\]\)]+)", INLINE_CODE_RE.sub("", FENCE_RE.sub("", body))):
            if not t[0].isdigit():
                tags[t.lower()].add(t)
        # `type: "[[article]]"` links name a category on purpose; they aren't meant to resolve.
        type_line = re.search(r"^type:.*$", fm, re.M)
        scan = text.replace(type_line.group(0), "", 1) if type_line else text
        for raw in LINK_RE.findall(INLINE_CODE_RE.sub("", FENCE_RE.sub("", scan))):
            t = link_target(raw)
            if not t or "{{" in t or "<%" in t or t.startswith(("http:", "https:", "obsidian:")):
                continue
            outgoing[n] += 1
            if resolve(t):
                hits = by_name.get(t.lower()) or by_file.get(t.lower()) or []
                for h in hits:
                    incoming[h] += 1
            elif n.startswith(IMPORTS):
                continue  # imported text: its [[1]]-style links aren't yours to fix
            elif t.startswith("👤"):
                missing_people[t].add(n)
            elif not DATED_RE.match(t):
                broken[t].add(n)

    islands = [
        n for n in notes
        if not n.startswith(ORPHAN_EXEMPT) and "/" in n and incoming[n] == 0 and outgoing[n] == 0
    ]
    root_files = [f for f in files if "/" not in f and f.endswith(".md")]
    attachments = [
        f for f in files
        if os.path.splitext(f)[1].lower() in ATTACH_EXT and not f.startswith("Extras/")
    ]
    dupes = {k: v for k, v in by_name.items() if len(v) > 1}
    tag_variants = {k: v for k, v in tags.items() if len(v) > 1}

    def section(title, items, hint, fmt=lambda x: f"[[{x[:-3] if x.endswith('.md') else x}]]"):
        items = list(items)
        out = [f">[!{'success' if not items else 'warning'}]- {title} ({len(items)})", f">{hint}"]
        for it in items[: a.limit]:
            out.append(f">- {fmt(it)}")
        if len(items) > a.limit:
            out.append(f">- …and {len(items) - a.limit} more")
        return "\n".join(out) + "\n"

    broken_rows = sorted(broken.items(), key=lambda kv: (-len(kv[1]), kv[0]))
    placeholders = [kv for kv in broken_rows if len(kv[1]) >= 5]
    typos = [kv for kv in broken_rows if len(kv[1]) < 5]
    counts = [
        ("Broken links (linked from 1–4 notes)", len(typos)),
        ("Missing notes linked from 5+ notes", len(placeholders)),
        ("👤 people linked but with no note (info)", len(missing_people)),
        ("Island notes (no links in or out)", len(islands)),
        ("Root-level notes", len(root_files)),
        ("Untitled notes", len(untitled)),
        ("Attachments outside Extras/", len(attachments)),
        ("Empty notes", len(empty)),
        ("No frontmatter", len(no_fm)),
        ("Frontmatter without type", len(no_type)),
        ("Unrendered Templater tags", len(templater)),
        ("Duplicate note names", len(dupes)),
        ("Tags with case variants", len(tag_variants)),
        ("No authorship", authorship["unmarked"]),
    ]
    print(f"Scanned {len(notes)} notes and {len(files) - len(notes)} other files.\n")
    print("| Check | Count |\n|:--|--:|")
    for k, v in counts:
        print(f"| {k} | {v} |")
    print("\n**Authorship:** " + ", ".join(f"{k} {v}" for k, v in authorship.most_common()) + "\n")
    if unmarked_by_folder:
        print("**Unmarked by top folder:** " + ", ".join(f"{k} {v}" for k, v in unmarked_by_folder.most_common()) + "\n")
    linked_from = lambda kv: f"`{kv[0]}` ← " + ", ".join(f"[[{n[:-3]}]]" for n in sorted(kv[1])[:3]) + (
        f" +{len(kv[1]) - 3} more" if len(kv[1]) > 3 else "")
    print(section("Broken links (linked from 1–4 notes)", typos,
                  "Usually a renamed or misspelled note: fix the link, or create the note.", linked_from))
    print(section("Missing notes linked from 5+ notes", placeholders,
                  "Probably a placeholder on purpose (a hub you never created). Create the hub, or leave it.", linked_from))
    print(section("Island notes", islands, "Nothing links here and it links nowhere. Link it to a topic, or archive it."))
    print(section("Root-level notes", root_files, "Loose notes at the vault root. File each one in its real home."))
    print(section("Untitled notes", untitled, "Rename, file, or delete (to Obsidian's trash)."))
    print(section("Attachments outside Extras/", attachments, "Attachment folder is `Extras/Attachments`.", lambda x: f"`{x}`"))
    print(section("Empty notes", empty, "Nothing after the frontmatter."))
    print(section("No frontmatter", no_fm, "Add frontmatter from the matching template."))
    print(section("Frontmatter without type", no_type, "Bases and skills key on `type`."))
    print(section("Unrendered Templater tags", templater, "`<%` left in a note outside Extras/Templates."))
    print(section("Duplicate note names", sorted(dupes.items()), "`[[name]]` can resolve to the wrong one.",
                  lambda kv: f"`{kv[0]}`: " + ", ".join(f"`{p}`" for p in kv[1])))
    print(section("Tags with case variants", sorted(tag_variants.items()), "Pick one spelling.",
                  lambda kv: ", ".join(f"`#{t}`" for t in sorted(kv[1]))))


if __name__ == "__main__":
    sys.exit(main())
