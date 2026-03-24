---
name: create-note
description: Create notes in the Obsidian vault using appropriate templates and locations. Use when creating Obsidian notes, documentation in the vault, topics, or command references.
---

# Skill: Create Obsidian Note

Create notes in the Obsidian vault using appropriate templates and locations.

## Vault Location

```
/Users/saje.liese/Obsidian/Tech-2/
```

## Templates Folder

```
/Users/saje.liese/Obsidian/Tech-2/Extras/Templates/
```

### Available Templates

| Template | Use Case |
|----------|----------|
| `💡 Topic.md` | General topic overview |
| `💡🖥️ Topic.md` | Technical/command-related topic |
| `💡 Topic-details.md` | Detailed breakdown of a topic |
| `💡🖥️ Topic-details.md` | Technical topic details |
| `🖥️ Command template.md` | CLI command reference |
| `📣 Meeting.md` | Meeting notes |
| `📽️ Project Index.md` | Project overview |
| `📽️ Project Details.md` | Project details |
| `👤🐶 Person.md` | Person/contact notes |

## Common Locations

| Type | Path |
|------|------|
| **Topics** | `/Topics/` |
| **Topic Details** | `/Topics/Topic-Details/` |
| **Commands** | `/Sources/Commands/` |
| **Meetings** | `/Meetings/` |
| **Projects** | `/Projects/` |
| **People** | `/People/` |

## Process

### Step 1: Read Template
Based on note type, read the appropriate template.

### Step 2: Determine Location
| Type | Location |
|------|----------|
| topic | `/Topics/💡<title>.md` |
| topic-details | `/Topics/Topic-Details/💡<title>.md` |
| command | `/Sources/Commands/🖥️ <title>.md` |
| meeting | `/Meetings/<title>.md` |
| project | `/Projects/<title>.md` |

### Step 3: Prepare Frontmatter
Match the template's YAML frontmatter structure.

### Step 4: Create Note
Write the file with proper content.

## Frontmatter by Type

### Topic
```yaml
---
type: topic
topics:           # Parent topics as [[links]]
commands:         # Related commands
projects:         # Related projects
template:
  - "[[💡 Topic]]"
people:           # Related people
link:             # External URLs
tags:             # Tags for categorization
---
```

### Command
```yaml
---
type: "[[🖥️Command]]"
command:          # The actual command
alias:            # Shell aliases
description:      # Brief description
topics:           # Related topics
template:
  - "[[🖥️ Command template]]"
tags:
---
```

## Callouts

Use `>[!type]` syntax for callouts (no space between `>` and `[`):

```markdown
>[!note] Note
>General information.

>[!warning] Warning
>Something to be careful about.

>[!tip] Tip
>Pro tip or best practice.

>[!example] Example
>An example or demonstration.
```

## Linking Conventions

### Internal Links
```markdown
[[💡Topic Name]]
[[🖥️ command name]]
[[💡Topic Name|Display Text]]
```

### External Links
```markdown
[Display Text](https://url.com)
```

## Emoji Usage

**Use emojis liberally** to make notes scannable:

```markdown
- 🔧 Configuration step
- 📝 Documentation task
- ✅ Completed item
- ⚠️ Warning item
- 🚀 Deployment step
```

## Formatting Checklist

- [ ] Correct emoji prefix for file type (💡, 🖥️, etc.)
- [ ] Proper frontmatter from template
- [ ] Wiki-links to parent/related topics
- [ ] Callouts for important info
- [ ] Code blocks with language hints
- [ ] Tables for structured data
- [ ] Proper heading hierarchy
- [ ] Tags matching conventions
