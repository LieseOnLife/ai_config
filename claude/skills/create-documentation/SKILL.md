---
name: create-documentation
description: Create documentation pages in Confluence with rich formatting. Use when creating Confluence pages, writing documentation, or making wiki pages.
---

# Skill: Create Confluence Documentation

Create documentation pages in Confluence using the Atlassian MCP server.

## MCP Server

Use the `atlassian` MCP server for all Confluence operations:
- `mcp__atlassian__createConfluencePage` - Create pages
- `mcp__atlassian__getConfluenceSpaces` - List spaces
- `mcp__atlassian__searchConfluenceUsingCql` - Search for pages
- `mcp__atlassian__getConfluencePage` - Get page content

## Key Formatting Rules

### 1. NO Title in Body
Confluence automatically displays the page title. **Never** include the title as the first line of the body content.

### 2. Use Appropriate Heading Levels
Start with H2 for top-level sections:
- `## Overview`
- `## Prerequisites`
- `## Steps`

### 3. Rich Formatting
Use varied formatting:
- **Callout panels** for important info (see ADF Panel Reference below)
- **Code blocks** with language hints
- **Tables** for structured data
- **Emojis** in headers and bullets
- **Screenshot placeholders** where helpful

## Callout Panels — ADF Format

Confluence panels use ADF (Atlassian Document Format). When using `contentFormat: "adf"`, panels are JSON objects. When using `contentFormat: "markdown"`, blockquotes (`>`) are converted to simple blockquotes — **not** colored panels.

**To get colored panels, you MUST use ADF format or Confluence storage format.**

### Standard Panels (built-in types with icons)

| Panel Type | Color | ADF `panelType` | Use Case |
|------------|-------|-----------------|----------|
| Info | 🔵 Blue | `info` | General information |
| Note | 🟣 Purple | `note` | Additional notes |
| Warning | 🟡 Yellow | `warning` | Caution/warnings |
| Success | 🟢 Green | `success` | Success confirmations |
| Error | 🔴 Red | `error` | Errors, critical issues |

### Custom Panels (any hex color, no built-in icon — use emoji)

| Name | Hex Color | Emoji | Use Case |
|------|-----------|-------|----------|
| Tip | `#FFFAE6` | 💡 | Tips, light yellow |
| Warning | `#FFF0B3` | ⚠️ | Stronger warning, darker yellow |
| Lavender Blush | `#FFF0F5` | 🌸 | Palest pink |
| Misty Rose | `#FFE4E1` | 🩰 | Soft blush pink |
| Cotton Candy | `#FFCCE5` | 🎀 | Light pink |
| Light Pink | `#FFB6C1` | 💕 | Classic light pink |
| Pink | `#FFC0CB` | 💗 | Standard pink |
| Cherry Blossom | `#F8BBD9` | 🍬 | Soft sakura |
| Pink Cloud | `#FCE4EC` | ☁️ | Whisper pink |
| Orchid Pink | `#EC79B8` | 💖 | Medium pink |
| Hot Pink | `#FF69B4` | 💝 | Vibrant pink |
| Deep Pink | `#FF1493` | 💘 | Intense pink |
| Rose | `#FF007F` | 🩷 | Bright rose |
| Barbie Pink | `#e0218a` | 🧚‍♀️ | Bold pink |
| Material Pink | `#E91E63` | 💋 | Google pink |
| Ice | `#E6FCFF` | 🧊 | Light cyan |
| Mint | `#E3FCEF` | 🌿 | Light green |
| Lavender | `#EAE6FF` | 💜 | Light purple |
| Sky | `#DEEBFF` | 💙 | Light blue |
| Peach | `#FFEBE6` | 🍑 | Warm blush |

### ADF Panel JSON Structure

```json
{
  "type": "panel",
  "attrs": {
    "panelType": "custom",
    "panelColor": "#FFCCE5"
  },
  "content": [
    {
      "type": "paragraph",
      "content": [
        { "text": "🎀 This is a pink callout!", "type": "text" }
      ]
    }
  ]
}
```

For standard panels (info, note, warning, success, error), omit `panelColor`:
```json
{
  "type": "panel",
  "attrs": { "panelType": "info" },
  "content": [...]
}
```

### Confluence Storage Format (for markdown contentFormat)

When using `contentFormat: "markdown"`, blockquotes render as simple quotes — not panels.
To get colored panels with markdown content, the MCP server converts markdown to storage format.
**Blockquotes in markdown will NOT become colored panels.**

If the user requests pink callouts or colored panels and you're using markdown, explain that
blockquotes are the best available approximation. For true colored panels, use ADF.

### Saje's Pink Palette — Use by Intensity

Use pink callouts by default when they make sense. Match the pink shade to the **intensity of the message**:

| Level | Color | Hex | Emoji | Use For |
|-------|-------|-----|-------|---------|
| Gentle | Lavender Blush | `#FFF0F5` | 🌸 | Soft context, nice-to-know, background info |
| Light | Cherry Blossom | `#F8BBD9` | 🍬 | Tips, helpful hints, minor notes |
| Medium | Cotton Candy | `#FFCCE5` | 🎀 | Important callouts, key information, gotchas |
| Strong | Hot Pink | `#FF69B4` | 💝 | Things you'll regret skipping, hard-won lessons |
| Intense | Deep Pink | `#FF1493` | 💘 | Critical warnings, things that cost hours to debug |
| Bold | Barbie Pink | `#e0218a` | 🧚‍♀️ | Showstopper issues, "do NOT skip this" |
| Bright | Rose | `#FF007F` | 🩷 | Urgent, most critical, emergency-level |

**Only use these 7 pinks.** Never use `#FFB6C1`, `#FFC0CB`, `#FCE4EC`, or other pinks not in this list.
Reserve standard panels (info/warning/error/success) for their semantic meanings; use pink for everything else.

## Content Structure Template

```markdown
## Overview

Brief description of what this document covers.

> ℹ️ **Info:** Key context the reader should know upfront.

---

## Prerequisites

- Requirement 1
- Requirement 2

> ⚠️ **Warning:** Important caveat here.

---

## Steps

### Step 1: First Action

Description and code:

```bash
command --flag value
```

> 📸 **Screenshot:** *Expected output*

---

## Troubleshooting

### Common Issue 1

> ❌ **Error:** `Error message`

**Solution:** Fix description.

---

## Related

- [Link to related page](url)
```

## Key IDs

| Resource | ID |
|----------|-----|
| Cloud ID | `66c05bee-f5ff-4718-b6fc-81351e5ef659` |
| Personal Space Key | `~199081059` |
| Personal Space ID | `795674614` |

## Formatting Checklist

- [ ] NO title as first line of body
- [ ] Proper heading hierarchy (H2 → H3 → H4)
- [ ] Callout panels for important info (use pink for Saje's docs)
- [ ] Code blocks with language hints
- [ ] Tables for structured data
- [ ] Emojis in headers and bullet points
- [ ] Screenshot placeholders where helpful
