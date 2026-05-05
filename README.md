# 🐶 AI Config Backup

Backup and restore configurations for AI coding assistants.

## 📦 What's in `claude/`

### ⚡ Slash commands (`claude/commands/`)
- 🌅 **morning** — generate standup + tiered Slack channel digest, write to today's Obsidian daily note
- 📚 **archive-plans** — move GSD plans from `.planning/` to `~/repos/ai_projects/` for long-term reference
- 🧹 **clean-obsidian-doc** — strip HTML/clutter from Obsidian web clippings
- 💬 **review-pr-comments** — pull and walk through unresolved PR comments
- 🌳 **worktree-cleanup** — list worktrees, flag stale ones, prompt for removal
- ☁️ **gcpprojects** — GCP project listing/scratch utility

### 🛠️ Skills (`claude/skills/`)
- 🏗️ **cloud-inventory** — Cloud Accounts team context for working on the cloud-inventory repo (GCP projects, AWS accounts, Azure subs, cloud-provider org mgmt)
- 🚀 **create-pr** — open PRs in Saje's signature style (fun emojis, succinct, varied formatting)
- 📝 **create-note** — Obsidian vault notes with the right template + location
- 📖 **create-documentation** — rich-formatted Confluence pages
- 🧭 **create-decision-log** — Cloud Accounts decision logs in Confluence
- 🗺️ **create-migration-plan** — comprehensive migration plans for DB/schema changes

### 🤖 Agents (`claude/agents/`)
- 🌲 **worktree-subagent** — subagent helper that respects worktree path conventions

### 🪝 Hooks (`claude/hooks/`)
- 🛡️ **git-worktree-guard.sh** — prevent committing on `main`/`master` directly
- 🔧 **terraform-otel-fix.sh** — Terraform OTEL workaround

### 📜 Claude helper scripts (`claude/scripts/`)
- 🌅 **morning-routine.sh** — wraps `claude --print /morning` for the daily Slack/standup digest
- 🧪 **check-pr-ci.sh** — poll a PR's CI status and dump failed-job logs for triage
- 🌳 **worktree-cleanup.sh** — list local worktrees with status flags (stale/uncommitted/merged)
- 🧭 **worktree-context.sh** — emit `{worktree_path, main_repo, branch, is_worktree}` JSON for subagents

### 🔄 Sync/install scripts (`scripts/`)
- 🔁 **sync-all.sh** — run every backup script (currently just Claude)
- ⬆️ **sync-claude.sh** — copy live `~/.claude/` config into this repo (`--dry-run` supported)
- ⬇️ **install-claude.sh** — restore the repo's Claude config back into `~/.claude/` (`--dry-run` supported)
- 🚀 **create-pr.sh** — open a PR with a templated body

### ⚙️ Claude settings (`claude/settings.json`)
- **Model**: `opus[1m]` (1M context window)
- **Permissions allowlist**: `gh`/`git` CLI, read-only Atlassian + Slack MCPs, `cd` into `~/go/src/github.com/DataDog/*` worktrees, edit/write under `~/repos/ai_projects-worktrees/**`
- **Permissions denylist**: no edits/writes under `~/dd/**` (work checkout — read-only)
- **Hooks**: PreToolUse `git-worktree-guard.sh` (block commits on `main`/`master`), `terraform-otel-fix.sh` (Terraform OTEL workaround)

### 🧩 Plugins (`claude/installed_plugins.json` + `claude/known_marketplaces.json`)
**Marketplaces tracked:**
- 🐶 `datadog-claude-plugins` (DataDog/claude-marketplace)
- 🤖 `claude-plugins-official` (anthropics/claude-plugins-official)
- 🗂️ `datadog-dd-source-claude-plugins` (local directory)
- 🪨 `obsidian-skills`
- ✨ `sttts-skills`

**Installed plugins:**
- DataDog: `dd`, `atlas`, `atlas-to-rapid-migrator`, `feature`, `appgate`, `go-code-reviewer`, `marketplace-auto-update`, `cloud-accounts`, `perf-feedback`, `squire`
- Anthropic official: `superpowers`, `skill-creator`, `atlassian`, `slack`, `gopls-lsp`, `playground`
- Obsidian: `obsidian`

## 🗂️ Structure

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
