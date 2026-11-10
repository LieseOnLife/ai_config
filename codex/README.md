# Codex configuration

This directory is the Codex-native counterpart to `claude/`.

| Claude surface | Codex surface | Location |
|---|---|---|
| `CLAUDE.md` | Global instructions | `AGENTS.md` |
| `settings.json` defaults | User configuration | `config.toml` |
| `settings.json` command permissions | Sandbox, approvals, and exec rules | `config.toml`, `rules/default.rules` |
| `commands/*.md` | User skills | `skills/*/SKILL.md` |
| `skills/*/SKILL.md` | User skills | `skills/*/SKILL.md` |
| `agents/*.md` | Custom agents | `agents/*.toml` |
| lifecycle hooks | Lifecycle hooks | `hooks.json`, `hooks/` |
| helper scripts | Helper scripts | `scripts/` |

The install script places instructions, config, agents, rules, hooks, and helper scripts under `~/.codex/`. Codex user skills are installed to `~/.agents/skills/`, their documented global discovery location.

Skills listed in `skills-from-pi.txt` are not copied. The install script symlinks each one to the pi skill of the same name (`~/.agents/skills/<name>` → `~/.pi/agent/skills/<name>`), and the sync script skips them, so `pi/skills/` is their only backup. Copies drift apart, and omp, which loads both directories, then lists a skill twice (`<name>` and `agents/<name>`). The links resolve once `install-pi.sh` has run. Those skills say `/skill-name` rather than Codex's `$skill-name`.

Claude plugin metadata is intentionally not copied. Codex plugins and connectors use their own installation and authentication state. Useful curated counterparts include `github@openai-curated`, `slack@openai-curated`, `atlassian-rovo@openai-curated`, `google-drive@openai-curated`, and `superpowers@openai-curated`; install and authenticate only the ones you need.

The Claude-only `nyolo` permission hook is not ported. Codex uses `approval_policy`, sandboxing, and `rules/default.rules`. The Terraform OTEL hook is represented by `shell_environment_policy.set` in `config.toml`.

Claude's path allowlist is represented by Codex writable roots for `ai_projects-worktrees` and `dd/experimental-worktrees`, plus the explicit read-only rule for `~/dd/**` in `AGENTS.md`.
