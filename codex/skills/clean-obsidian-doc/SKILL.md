---
name: clean-obsidian-doc
description: Clean up messy Obsidian documents, especially web clippings. Removes HTML artifacts, duplicate content, and formats for readability.
---

# Clean Obsidian Document

Clean up a messy Obsidian document, particularly web clippings that contain raw HTML and artifacts.

## Process

### Step 1: Read and Analyze
Read the document and identify:
- Raw HTML tables, divs, spans
- GitHub/website UI elements (navigation, badges, stats)
- Duplicate or redundant content
- Broken markdown formatting
- Unnecessary links (internal site navigation, edit buttons, etc.)

### Step 2: Preserve Important Elements
Always keep:
- **Frontmatter** (YAML between `---`)
- **Notes section** (user's personal notes)
- **Core content** (the actual useful information)
- **Meaningful links** (external references, documentation)
- **Code blocks** (commands, examples, configurations)

### Step 3: Remove Artifacts
Remove or clean:
- Raw HTML tables → Convert to markdown tables
- GitHub UI elements (stars, forks, watchers, branches, tags, activity links)
- File trees with commit messages
- "Open in codespace" / "Open in github.dev" links
- Star history charts
- Sponsor/donation sections
- Package/release metadata (unless relevant)
- Duplicate headers or descriptions
- Empty sections

### Step 4: Format Consistently
Apply consistent formatting:
- Use markdown tables instead of HTML
- Clean up excessive whitespace
- Ensure proper heading hierarchy (h1 → h2 → h3)
- Format code blocks with language hints
- Keep tables aligned and readable

### Step 5: Structure the Document
Final structure should be:
```markdown
---
frontmatter preserved
---
# Notes

(user notes preserved or empty section for future notes)

# Content

(cleaned main content)
```

## Examples

### Before (web clipping)
```html
<table><thead><tr><th>Name</th>...</thead>
<tbody><tr><td><a href="...">file.js</a></td>...
[19.1k stars](link) [1.7k forks](link)
Open in github.dev | Open in codespace
```

### After (cleaned)
```markdown
## Files
| Name | Description |
|------|-------------|
| file.js | Main entry point |
```

## Output
After cleaning, briefly summarize what was removed and what was kept.
