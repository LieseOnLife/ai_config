"""Shared parsing for the vault-audit scripts."""
import re

# Opening fence, optional body, closing fence. Handles a BOM, CRLF and empty frontmatter.
FM_RE = re.compile(r"\A\ufeff?---[ \t]*\r?\n(?:(.*?)\r?\n)?---[ \t]*(?:\r?\n|\Z)", re.S)


def split_frontmatter(text):
    """Return (match, frontmatter text, body). match is None when there's no frontmatter."""
    m = FM_RE.match(text)
    if not m:
        return None, "", text
    return m, m.group(1) or "", text[m.end():]


def fm_value(fm, key):
    """The scalar value on `key:`'s own line ('' when empty or a list follows)."""
    m = re.search(rf"^{re.escape(key)}:[ \t]*(.*?)[ \t]*\r?$", fm, re.M)
    return m.group(1) if m else None


def fm_has_value(fm, key):
    """True when `key` has a scalar value or at least one list item."""
    if fm_value(fm, key):
        return True
    return bool(re.search(rf"^{re.escape(key)}:[ \t]*\r?\n[ \t]+-[ \t]*\S", fm, re.M))


def drop_keys(fm, keys):
    """Remove the given keys, and their indented list items, from frontmatter text."""
    out, skipping = [], False
    for line in fm.splitlines():
        if re.match(r"[ \t]", line) or line.startswith("-"):
            if not skipping:
                out.append(line)
            continue
        skipping = any(re.match(rf"{re.escape(k)}:", line) for k in keys)
        if not skipping:
            out.append(line)
    return "\n".join(out)
