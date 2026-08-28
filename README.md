# 🐶 AI Config Backup

Backup and restore personal configuration for Claude Code, Codex, and pi.

## What is backed up

### Claude Code

- Global instructions, settings, hooks, commands, skills, agents, prompts, and helper scripts under `claude/`
- Plugin and marketplace metadata, but not plugin contents or credentials

### Codex

- Global guidance in `codex/AGENTS.md`
- Model, sandbox, approval, MCP, and agent defaults in `codex/config.toml`
- Codex-native user skills converted from both Claude commands and Claude skills
- Custom agents, lifecycle hooks, command rules, and helper scripts

The detailed Claude-to-Codex mapping and deliberate omissions are documented in `codex/README.md`.

### pi

- Global instructions in `pi/AGENTS.md` (ported from `claude/CLAUDE.md`)
- Provider, model, thinking, and package defaults in `pi/settings.json`
- MCP server config (Atlassian, Datadog, Slack, Google Workspace) in `pi/mcp.json`
- Five lifecycle extensions ported from Claude hooks (worktree guard, PR size guard, terraform OTEL fix, auto-format-on-edit, post-push protocol) in `pi/extensions/`
- Slash-command prompt templates in `pi/prompts/`
- Helper scripts (worktree context, morning routine, CI checks, Obsidian tooling) in `pi/scripts/`
- Twelve skills ported from Claude in `pi/skills/`

Not backed up: credentials (`auth.json`, `models-store.json`), the model registry (`models.json`), MCP cache, installed npm packages, sessions, and trust decisions.

## Structure

```text
ai_config/
├── claude/
│   ├── agents/
│   ├── commands/
│   ├── hooks/
│   ├── prompts/
│   ├── scripts/
│   ├── skills/
│   ├── CLAUDE.md
│   └── settings.json
├── codex/
│   ├── agents/
│   ├── hooks/
│   ├── rules/
│   ├── scripts/
│   ├── skills/
│   ├── AGENTS.md
│   ├── config.toml
│   └── hooks.json
├── pi/
│   ├── extensions/
│   ├── prompts/
│   ├── scripts/
│   ├── skills/
│   ├── AGENTS.md
│   ├── mcp.json
│   └── settings.json
└── scripts/
    ├── install-claude.sh
    ├── install-codex.sh
    ├── install-pi.sh
    ├── sync-claude.sh
    ├── sync-codex.sh
    ├── sync-pi.sh
    └── sync-all.sh
```

## Install

```bash
./scripts/install-claude.sh
./scripts/install-codex.sh
./scripts/install-pi.sh
```

Both installers support `--dry-run`. The Codex installer writes configuration to `~/.codex/` and global user skills to `~/.agents/skills/`. The pi installer writes to `~/.pi/agent/` (resource dirs only — credentials, cache, sessions, and the model registry are left untouched). Restart Codex afterward and use `/hooks` to review and trust the installed hooks. Restart pi (or run `/reload` in an interactive session) to load the new extensions, skills, and prompts.

## Sync

```bash
# Everything
./scripts/sync-all.sh

# One tool
./scripts/sync-claude.sh
./scripts/sync-codex.sh
./scripts/sync-pi.sh
```

All sync scripts support `--dry-run`. `sync-codex.sh` and `sync-pi.sh` require a prior install from this repo, which prevents an uninitialized machine from replacing the curated backup with empty or unrelated local directories.

## Not backed up

- Authentication tokens and credential files
- Conversation/session history
- Logs, caches, temporary files, and SQLite runtime state
- Codex memories and cloud task state
- Installed plugin contents, OAuth state, and machine-generated plugin caches

Review changes before committing:

```bash
git status --short
git diff
```
