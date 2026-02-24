# AI Config Backup

Backup and restore configurations for AI coding assistants.

## Structure

```
ai_config/
├── claude/           # Claude Code configuration
│   ├── agents/       # Custom agent definitions
│   ├── commands/     # Slash commands
│   ├── hooks/        # Event hooks
│   ├── scripts/      # Helper scripts
│   ├── skills/       # Custom skills
│   ├── prompts/      # Custom prompts
│   ├── plugins/      # Plugin metadata
│   ├── CLAUDE.md     # Global instructions
│   ├── settings.json # Permissions, model, hooks config
│   └── settings.local.json
├── scripts/          # Sync and install scripts
└── README.md
```

## Usage

### Backup (Sync to Repo)

```bash
# Sync all AI configs
./scripts/sync-all.sh

# Sync only Claude
./scripts/sync-claude.sh

# Dry run (preview changes)
./scripts/sync-claude.sh --dry-run
```

### Restore (Install from Repo)

```bash
# Install Claude config
./scripts/install-claude.sh

# Dry run (preview changes)
./scripts/install-claude.sh --dry-run
```

### Commit Changes

After syncing, review and commit:

```bash
git add -A
git commit -m "Backup AI configs"
git push
```

## What's Backed Up

### Claude Code

| Item | Description |
|------|-------------|
| `agents/` | Custom agent definitions (Task tool subagents) |
| `commands/` | Slash commands (user-invocable skills) |
| `hooks/` | Pre/Post tool hooks, session hooks |
| `scripts/` | Helper shell scripts |
| `skills/` | Custom skills with instructions |
| `prompts/` | Reusable prompt templates |
| `CLAUDE.md` | Global instructions for all projects |
| `settings.json` | Permissions, model selection, hook config |
| `settings.local.json` | Local/machine-specific settings |
| `plugins/*.json` | Plugin and marketplace metadata |

### Not Backed Up (Ephemeral/Sensitive)

- `.credentials.json` - Authentication tokens
- `history.jsonl` - Session history
- `projects/` - Per-project session data
- `cache/`, `debug/`, `todos/` - Temporary data
- `get-shit-done/` - Installed separately (has VERSION file)

## Adding New AI Tools

1. Create a new directory: `mkdir cursor/`
2. Create sync script: `scripts/sync-cursor.sh`
3. Create install script: `scripts/install-cursor.sh`
4. Add to `scripts/sync-all.sh`

## First-Time Setup

```bash
# Clone repo on new machine
git clone <repo-url> ~/repos/ai_config
cd ~/repos/ai_config

# Make scripts executable
chmod +x scripts/*.sh

# Install configs
./scripts/install-claude.sh
```
