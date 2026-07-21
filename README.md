# 🐶 AI Config Backup

Backup and restore personal configuration for Claude Code and Codex.

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
└── scripts/
    ├── install-claude.sh
    ├── install-codex.sh
    ├── sync-claude.sh
    ├── sync-codex.sh
    └── sync-all.sh
```

## Install

```bash
./scripts/install-claude.sh
./scripts/install-codex.sh
```

Both installers support `--dry-run`. The Codex installer writes configuration to `~/.codex/` and global user skills to `~/.agents/skills/`. Restart Codex afterward and use `/hooks` to review and trust the installed hooks.

## Sync

```bash
# Everything
./scripts/sync-all.sh

# One tool
./scripts/sync-claude.sh
./scripts/sync-codex.sh
```

All sync scripts support `--dry-run`. `sync-codex.sh` requires a prior install from this repo, which prevents an uninitialized machine from replacing the curated backup with empty or unrelated local directories.

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
