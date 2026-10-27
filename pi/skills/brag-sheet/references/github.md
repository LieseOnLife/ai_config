# GitHub Collector

Collect and organize GitHub PR contributions. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{github_usernames}` (comma-separated), `{output_dir}`.
Output: `{output_dir}/github.md`.

Use the `gh` CLI via `bash`. Do not switch accounts unless a username matches an authenticated `gh auth status` login; search works for any public user.

## Step 1: Collect merged PRs per user

For each username, use the search API with the `merged:` qualifier and paginate:

```bash
gh api --paginate --slurp "search/issues?q=author:USERNAME+type:pr+is:merged+merged:{start_date}..{end_date}&per_page=100"
```

The response is an array of page objects, each with an `items` array. Flatten all `items`. Each item has `number`, `title`, `html_url`, `repository_url`, `body`, `closed_at`, `pull_request.merged_at`. Derive the repo name from the last path segment of `repository_url`. If a command fails, write an error section and continue.

Process large output with `eval` so raw JSON does not flood context; print only the structured PR list.

## Step 2: Impact per PR

Write a 4-line IMPACT summary: (1) problem/need, (2) what changed, (3) result/improvement, (4) who benefited. Always render the title as a markdown link to `html_url`.

## Step 3: Group related PRs

Merge all users' PRs, dedupe by URL, and group related PRs (same repo+area, same stack, same JIRA ticket, or clearly one initiative). Give each group a descriptive name.

## Step 4: Write output

Write `{output_dir}/github.md`: a short header with total PR and repo counts, then grouped sections with linked PRs and impact lines.
