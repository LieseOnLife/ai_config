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
- **Callout boxes** for important info
- **Code blocks** with language hints
- **Tables** for structured data
- **Emojis** in headers and bullets
- **Screenshot placeholders** where helpful

## Callout Panels (ADF Format)

| Panel Type | Color | Use Case |
|------------|-------|----------|
| `info` | 🔵 Blue | General information |
| `note` | 🟣 Purple | Additional notes |
| `success` | 🟢 Green | Success confirmations |
| `error` | 🔴 Red | Errors, critical issues |
| Custom `#FFFAE6` | 🟡 Yellow | 💡 Tips |
| Custom `#FFF0B3` | 🟠 Orange | ⚠️ Warnings |

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
- [ ] Callout boxes for important info
- [ ] Code blocks with language hints
- [ ] Tables for structured data
- [ ] Emojis in headers and bullet points
- [ ] Screenshot placeholders where helpful
