# 🎨 Claude Skills Library

Personal skills that extend Claude's capabilities.

## 📁 Structure

Each skill has its own folder with a `SKILL.md` file:

```
~/.claude/skills/
├── create-pr/
│   └── SKILL.md         # PR creation with emoji style
├── create-note/
│   └── SKILL.md         # Obsidian notes with templates
├── create-documentation/
│   └── SKILL.md         # Confluence pages
├── create-decision-log/
│   └── SKILL.md         # Cloud Accounts decision logs
├── create-migration-plan/
│   └── SKILL.md         # DB migration planning
└── cloud-inventory/
    └── SKILL.md         # Cloud-inventory context (auto-loaded)
```

## 🚀 Available Skills

| Skill | Invokable | Description |
|-------|-----------|-------------|
| `/create-pr` | ✅ Yes | Create PRs with fun emojis & varied formatting |
| `/create-note` | ✅ Yes | Create Obsidian notes using vault templates |
| `/create-documentation` | ✅ Yes | Create rich Confluence pages |
| `/create-decision-log` | ✅ Yes | Create Cloud Accounts decision logs |
| `/create-migration-plan` | ✅ Yes | Plan database migrations |
| `cloud-inventory` | ❌ Auto | Background context for cloud-inventory work |

## 🎯 How Skills Work

1. **Auto-invoked**: Claude reads the `description` field and loads the skill when relevant
2. **Manual invoke**: Type `/skill-name` to invoke directly
3. **Background context**: Skills with `user-invocable: false` load automatically but aren't slash commands

## ➕ Adding New Skills

1. Create folder: `mkdir ~/.claude/skills/my-skill`
2. Create `SKILL.md` with frontmatter:

```yaml
---
name: my-skill
description: What this skill does. Claude uses this to decide when to load it.
---

Your instructions here...
```

## 📝 Frontmatter Options

| Field | Description |
|-------|-------------|
| `name` | Skill name (becomes `/name` command) |
| `description` | When to use - Claude reads this to auto-invoke |
| `disable-model-invocation` | `true` = only user can invoke |
| `user-invocable` | `false` = hidden from menu, auto-load only |
| `allowed-tools` | Tools Claude can use without asking |
