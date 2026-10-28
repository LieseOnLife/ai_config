---
name: brag-sheet
description: Generates a brag sheet summarizing the user's impact over a configurable period (default 6 months) by collecting data in parallel from GitHub, JIRA, Confluence, Slack, Google Workspace, Datadog Incidents/Notebooks/Dashboards, and the Obsidian vault. Use when preparing facts for a performance review, self-eval, or promo packet. Each source is a parallel subagent writing a standalone markdown file, then a combined summary is produced. Invoke with /skill:brag-sheet or by asking to build a brag sheet.
---

# Brag Sheet Generator

Generate a brag sheet for a configurable period (default: last 6 months) to gather facts for a performance review. Data is collected in parallel from multiple sources; each source produces a standalone markdown file, then a combined `summary.md` organizes everything into performance-review categories.

Port of the Datadog `perf-feedback` Claude plugin to omp tools. MCP tools are `xd://` devices: read `xd://<tool>` for its schema, write the JSON args to execute.

| Purpose | omp tool |
|---|---|
| Delegation / parallelism | `task` tool, one `tasks[]` batch |
| GitHub | `gh` CLI via `bash` |
| JIRA | `xd://mcp__atlassian_searchjiraissuesusingjql`, `xd://mcp__atlassian_lookupjiraaccountid` |
| Confluence | `xd://mcp__atlassian_searchconfluenceusingcql`, `xd://mcp__atlassian_getconfluencepage`, `xd://mcp__atlassian_getaccessibleatlassianresources` |
| Slack | `xd://mcp__slack_*` (`search_public_and_private`, `read_thread`, `read_channel`, `search_users`, `read_user_profile`) |
| Google Workspace | `xd://mcp__datadog_google_workspace_*` (`search_files`, `get_file_metadata`, `get_doc_as_markdown`, `get_presentation`) |
| Datadog incidents/notebooks/dashboards | Datadog MCP devices — list `xd://` and look for `mcp__datadog_*` / `mcp__datadog_golden_*` (not Google Workspace) |
| Obsidian | filesystem via `eval` (Python) / `read` over the vault |
| Clarify | `ask` |

## Arguments

`$ARGUMENTS` — optional email followed by space-separated flags:
- `email@datadoghq.com` — person to profile. If omitted, resolve the current user.
- `--github` — GitHub authored/merged PRs
- `--jira` — JIRA assigned issues resolved in range
- `--confluence` — Confluence authored/updated pages
- `--slack=#chan1,#chan2` — Slack authored messages (restrict to listed channels; omit list to search broadly)
- `--google-workspace` — Google Docs/Slides owned by the user
- `--incidents` — Datadog incidents where the user responded/commanded
- `--notebooks` — Datadog notebooks authored (Postmortem/Analysis)
- `--dashboards` — Datadog dashboards authored
- `--obsidian` — Obsidian vault notes (see reference)
- `--output-dir=<path>` — default `~/Obsidian/Tech-2/Datadog/Career/brag-sheet-{period}`
- `--months=<N>` — lookback window (default 6)

If no source flags are provided, use `ask` to ask which sources to include (`multi: true`).

## Step 0: Parse arguments and identify the user

1. Parse `$ARGUMENTS` for an optional email and enabled sources.
2. Compute the date range: `--months` ago (default 6) → today. Use `bash` with the unaliased `date` to compute the start date, e.g. `date -v-6m +%F` (macOS) — do not rely on the `date` alias.
3. Resolve identity once and store the handles other steps need:
   - **GitHub**: `gh auth status` for authenticated logins; the target login when profiling someone else.
   - **Email**: the provided email, or the current user's `@datadoghq.com` email.
   - **Atlassian account ID**: `xd://mcp__atlassian_lookupjiraaccountid` (`cloudId`, `searchString: email`) — Confluence CQL `creator`/`contributor` require the account ID, not the email. Never use `currentUser()`.
   - **Slack user**: `xd://mcp__slack_search_users` by name/email (current user: `xd://mcp__slack_read_user_profile` with no `user_id`).
4. **Cloud ID / base URL**: call `xd://mcp__atlassian_getaccessibleatlassianresources` once. Use the returned `id` (UUID) or site hostname (e.g. `datadoghq.atlassian.net`) as `{cloud_id}`; store the site URL as `{jira_base_url}`.
5. **Datadog**: if any of `--incidents/--notebooks/--dashboards` are enabled, read `xd://` and confirm Datadog MCP incident/notebook/dashboard devices are mounted. If none are, tell the user the Datadog MCP server isn't connected (authenticate it in omp) and skip those sources.
6. Create the output directory with `bash` `mkdir -p`.

## Step 1: Validate access, then report

Before spawning collectors, verify each enabled source with a minimal probe (1-result search / `gh auth status` / a single MCP call). Report which sources passed and which are skipped, and proceed only with validated sources. A failing source must not abort the whole run.

## Step 2: Spawn collectors in parallel

Make **one** `task` call with a `tasks[]` batch — one `task`-agent item per validated source (not `scout`: scouts are read-only and can't write the output file). Put the shared date range, identities, and output dir in `context`. Give each item:
- the source-specific identity and the absolute output file path (`{output_dir}/<source>.md`);
- the matching collector instructions from `references/` (read the file, inline its steps into the task);
- a stable CamelCase `name` (e.g. `BragGithub`);
- explicit read-only boundary (only writes its own output file) and "write an error section, do not abort the run" on tool failure; skip formatters/linters/tests.

Collector references (read the one you need and inline it per child):
- GitHub → [references/github.md](references/github.md)
- JIRA → [references/jira.md](references/jira.md)
- Confluence → [references/confluence.md](references/confluence.md)
- Slack → [references/slack.md](references/slack.md)
- Google Workspace → [references/google-workspace.md](references/google-workspace.md)
- Incidents → [references/incidents.md](references/incidents.md)
- Notebooks → [references/notebooks.md](references/notebooks.md)
- Dashboards → [references/dashboards.md](references/dashboards.md)
- Obsidian → [references/obsidian.md](references/obsidian.md)

Collectors are read-only except for writing their own output file. Keep the writer count to one per output file.

### Reusing already-collected data

If a source has already been collected this session (for example, an Obsidian evidence pass), **do not re-run it**. Pass the existing artifact path(s) into Step 4 as that source's file instead of spawning a new collector. Only spawn collectors for sources without fresh output.

## Step 3: Monitor and collect

Results auto-deliver when each task finishes — don't poll. Read each validated source's output file to confirm it was written. Report any collector that failed.

## Step 4: Combined summary

Write `{output_dir}/summary.md` using [assets/template.md](assets/template.md):
1. List every collected source with a relative link and a one-line count.
2. High-level overview across sources.
3. Top 5-10 most impactful contributions.
4. Organize into the performance-review categories in the template.

Keep claims evidence-bound: cite the source file for each contribution, and label incomplete/ambiguous work rather than overstating it. When a read-only reviewer is available, run one fresh-context `reviewer` on `summary.md` against the source files before declaring done.
