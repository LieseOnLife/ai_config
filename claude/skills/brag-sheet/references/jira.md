# JIRA Collector

Collect JIRA issues assigned to the user and resolved within the range, grouped by epic. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{user_email}`, `{cloud_id}`, `{jira_base_url}`, `{output_dir}`.
Output: `{output_dir}/jira.md`.

Never use `currentUser()`; always use the explicit email.

## Step 1: Find resolved issues

Use `xd://mcp__atlassian_searchjiraissuesusingjql` with `cloudId: {cloud_id}` and:

```
assignee = "{user_email}" AND resolved >= "{start_date}" AND resolved <= "{end_date}" ORDER BY resolved DESC
```

Page with `nextPageToken` until exhausted. Request fields: summary, status, resolution, resolutiondate, priority, labels, parent, and the epic link. If the search fails, write an error section and stop this source.

## Step 2: Extract per issue

Issue key, summary, status, resolution date, epic key, labels, priority. Always render the key as a markdown link `[{KEY}]({jira_base_url}/browse/{KEY})`. Write a 4-line IMPACT summary: problem/need, what was done, result, who benefited.

## Step 3: Group by epic

Group issues under their epic key heading; issues with no epic go under "No Epic".

## Step 4: Write output

Write `{output_dir}/jira.md` with a header count (issues, epics) and grouped sections using linked keys and impact lines.
