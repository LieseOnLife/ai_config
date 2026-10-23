# 🐶 AI Config Backup

Backup and restore personal configuration for Claude Code, Codex, pi, omp, and Grinch.

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

### omp (oh-my-pi)

- Global instructions in `omp/agent/AGENTS.md`
- Model roles, subagent model overrides, skill directories, extension paths, and UI defaults in `omp/agent/config.yml`
- MCP server config (Atlassian, Datadog, Gmail, Google Calendar/Workspace, Slack) in `omp/agent/mcp.json`
- Lifecycle extensions (worktree guard, PR size guard, post-push protocol, auto-format, terraform OTEL fix, prompt snippets, pi model/Baseten shims) in `omp/agent/extensions/` and shared helpers in `omp/agent/lib/`
- Prompt templates in `omp/agent/prompts/`, domain rules in `omp/agent/rules/`, and auto-learned skills in `omp/agent/managed-skills/`
- Plugin and marketplace metadata (`omp/marketplaces.json`, `omp/plugins/*.json`), but not plugin contents

Skills from `~/.pi/agent/skills` are loaded by omp through `config.yml` and are backed up under `pi/`.

Not backed up: credentials and OAuth state, `*.db` files (agent, history, models, skill descriptions), blobs, cache, logs, sessions, and runtime `*.lock` files.

### Grinch browser routing

- `grinch/grinch.js`: external web links default to Commercial Chrome (`Default`).
- `ddog-gov.com`, `fed.dog`, `amazonaws-us-gov.com` (AWS GovCloud console + regional subdomains), and the GovCloud SSO start host `d-9067f50546.awsapps.com` use GovCloud Chrome (`Profile 3`).
- `prod.dog`, `staging.dog`, `ddbuild.io`, all GitHub URLs, and unmatched URLs use Commercial.
- `grinch/open-gov`: a terminal helper for explicitly opening any HTTP(S) URL in GovCloud.

These directory names match Saje's Chrome profiles, not AppGate's connection labels
(Commercial Green / gov-green). Verify mappings before installing on another Mac.
Normal navigation inside Chrome stays in its current profile; no browser extension
or blanket AppGate/Terminal rule is installed. AppGate SSO on a different hostname
needs an explicit rule; `fed.dog` routing alone does not verify the login flow.

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
├── omp/
│   ├── agent/
│   │   ├── extensions/
│   │   ├── lib/
│   │   ├── managed-skills/
│   │   ├── prompts/
│   │   ├── rules/
│   │   ├── AGENTS.md
│   │   ├── config.yml
│   │   └── mcp.json
│   ├── plugins/
│   └── marketplaces.json
├── grinch/
│   ├── grinch.js
│   ├── open-gov
│   └── test_grinch.py
└── scripts/
    ├── grinch-common.sh
    ├── install-grinch.sh
    ├── sync-grinch.sh
    ├── install-claude.sh
    ├── install-codex.sh
    ├── install-pi.sh
    ├── install-omp.sh
    ├── sync-claude.sh
    ├── sync-codex.sh
    ├── sync-pi.sh
    ├── sync-omp.sh
    └── sync-all.sh
```

## Install

```bash
./scripts/install-claude.sh
./scripts/install-codex.sh
./scripts/install-pi.sh
./scripts/install-omp.sh
./scripts/install-grinch.sh
```

All installers support `--dry-run`. The Codex installer writes configuration to `~/.codex/` and global user skills to `~/.agents/skills/`. The pi installer writes to `~/.pi/agent/` (resource dirs only — credentials, cache, sessions, and the model registry are left untouched). The omp installer writes to `~/.omp/agent/` plus plugin/marketplace metadata under `~/.omp/` (databases, blobs, cache, logs, and sessions are left untouched). Restart Codex afterward and use `/hooks` to review and trust the installed hooks. Restart pi (or run `/reload` in an interactive session) to load the new extensions, skills, and prompts. Restart omp to pick up its config and extensions.

### Enable Grinch on macOS

Install Grinch first, then run `./scripts/install-grinch.sh --dry-run` and
`./scripts/install-grinch.sh`. This installs `~/.config/grinch/grinch.js` and
`~/.local/bin/open-gov`; keep `~/.local/bin` on PATH. Competing Grinch configs
must be migrated explicitly. Chrome profiles, credentials, and AppGate settings
are never copied or changed.

Launch Grinch. **If it was already running, choose Reload Config (⌘R) from its
menu after installation**—launching the app again does not reload its config.
An instance started before a config existed can otherwise keep ignoring links.
Then select **Grinch** in **System Settings → Desktop & Dock → Default web
browser**. The installer does not change that system preference or other URL-scheme
handlers. Use **Reload Config** after subsequent rule edits too.

```bash
open-gov 'https://identity.example/login' # explicitly bypass the Commercial default
python3 grinch/test_grinch.py            # requires macOS and Grinch (tested with 0.8.4)
```

Tests use a temporary HOME and mock the browser launcher; they do not open URLs.
Actual AppGate authentication and browser-window selection still need a manual check.

## Sync

```bash
# Everything
./scripts/sync-all.sh

# One tool
./scripts/sync-claude.sh
./scripts/sync-codex.sh
./scripts/sync-pi.sh
./scripts/sync-omp.sh
./scripts/sync-grinch.sh
```

Grinch sync requires a prior install and copies **only** `grinch.js`; its local
managed marker, diagnostic logs, and runtime files are excluded. Maintain the
`open-gov` helper in this repo and reinstall it after changes. Grinch install/sync
`--dry-run` performs no writes. Backups are on demand, not continuously scheduled.

**Note:** non-dry-run `sync-all.sh` also invokes the existing DataDog experimental
push script for Claude configuration. Use `sync-grinch.sh` for a Grinch-only backup
without commits or pushes.

All sync scripts support `--dry-run`. `sync-codex.sh`, `sync-pi.sh`, and `sync-omp.sh` require a prior install from this repo, which prevents an uninitialized machine from replacing the curated backup with empty or unrelated local directories.

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
