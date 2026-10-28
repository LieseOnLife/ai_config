---
name: compose-google-docs
description: "Write or rewrite content in a Google Doc (including a specific tab) through the datadog-google-workspace MCP without broken formatting. Covers the emoji placeholder workaround for insert_markdown, formatting table cells, verifying, and keeping tab IDs stable."
---

# Compose Google Docs (datadog-google-workspace MCP)

Use this whenever you write formatted content (headings, bold, lists, tables, links, emoji) into a Google Doc or one of its tabs. Plain `insert_markdown` mangles formatting in ways that are easy to miss in a markdown export.

## Known `insert_markdown` bugs
1. **Emoji shift the formatting.** With any emoji in the markdown (non-BMP characters like 🎯, or sequences with a variation selector like 🛠️ ⚖️), the tool computes offsets in code points while Docs counts UTF-16 units. Result: bold, italic, code and link ranges land one character early (`**Microsof**t`), every list gets an **empty first bullet**, and blank lines become **empty `HEADING_2` paragraphs**.
2. **Table cells lose all inline formatting** (bold, code, links), with or without emoji.
3. `get_doc_as_markdown` output reflects these bugs faithfully, so read it critically. To confirm, use `read_document` (`content_only: true`) and inspect `textRun.textStyle`.

## Procedure
1. **Look before writing.** Run `list_tabs`, then `get_doc_as_markdown` with the `tab_id` of any sibling tab. Match its layout and section order, e.g. bold table headers, and `**Full design:** [link]` as a plain line rather than a heading.
2. **Create or reuse the tab.** Use `add_document_tab` (with `index` to place it). Don't delete and recreate tabs that already exist: the tab ID changes and breaks every `?tab=` link. To redo a tab's content, clear it in place (step 7).
3. **Replace every emoji with an ASCII placeholder** before inserting, e.g. `🎯`→`[[E1]]` and `✅`→`[[E9]]`. Replace multi-codepoint sequences (🛠️, ⚖️) whole, longest first. Assert that no emoji remain: `[\U0001F000-\U0001FFFF\u2600-\u27BF\uFE0F]`.
4. **`insert_markdown`** with `tab_id`. Without emoji, body formatting, lists and headings come out right.
5. **Fix table cells.** `read_document` → walk `table.tableRows[].tableCells[].content[].paragraph`. For each intended span, call `format_text` with:
   - `start_index = paragraph.startIndex + utf16_len(text_before_span)`
   - `end_index = start + utf16_len(span)`
   - `bold` / `italic` / `link_url`, or for inline code `font_family: "Courier New"` + `background_color: "#F2F2F2"`
   Compute UTF-16 lengths with `len(s.encode("utf-16-le")) // 2`.
6. **Put the emoji back** with one `batch_replace_text` (`tab_id`, `match_case: true`, `confirmed: true`), placeholder → emoji. Replaced text keeps the surrounding style. Always pass `tab_id`: without it, replacements hit every tab.
7. **Clearing a tab in place:** read the elements and call `delete_range` on each top-level element from the bottom up (tables can be deleted as one whole element range). Leave the body's final newline. First check that the tab only holds content you wrote.
8. **Verify** with `read_document`, not the markdown export:
   - Every intended bold span matches the bold `textRun`s, in body text and table cells.
   - Count list paragraphs whose only text is `\n` → must be 0.
   - Count `HEADING_*` paragraphs whose only text is `\n` → must be 0.
   - No placeholders remain, and the headings carry their emoji.
   - Code font and link runs cover the intended text.

## Gotchas
- `read_document` output for large docs is truncated. The MCP result's `details.xdev.inner.meta.truncation.artifactId` points to an artifact whose backing `.log` file holds the full JSON, so parse from the first `{`.
- `replace_text` / `batch_replace_text` can't match across newlines. Use unique placeholders instead of heading text. Plain words like "Why" may also appear in table headers.
- The Workspace MCP asks for confirmation before creating or overwriting. An explicit user request ("make a tab and put X in it") counts as confirmation; destructive steps still need `confirmed: true`.
- Docs indices are 1-based. The tab body starts at 1 and ends with a mandatory newline that can't be deleted.
