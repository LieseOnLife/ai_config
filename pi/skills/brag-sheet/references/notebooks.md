# Datadog Notebooks Collector

Collect Datadog notebooks authored by the user in range, tagged Postmortem or Analysis. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{user_handle}` (email), `{output_dir}`.
Output: `{output_dir}/notebooks.md`.

Use the Datadog MCP notebook devices (list `xd://`, look for `mcp__datadog_*notebook*`; read `xd://<tool>` for the schema).

## Steps

1. `search_datadog_notebooks` with `query: "*"`, `filter: "author.handle:{user_handle} modified_from:{start_date} modified_to:{end_date}"`, `sort_by: "-modified_at"`. No results → note and stop.
2. Classify each: **[PM]** if `type: postmortem` or the name contains postmortem/post mortem/post-mortem (case-insensitive); otherwise **[Analysis]**. Skip untitled scratch pads (`cell_count <= 2` with auto-generated names) unless `type` is set.
3. For [PM] notebooks, fetch details with `get_datadog_notebook`: the triggering incident and a brief what-happened/resolution summary.
4. Write `{output_dir}/notebooks.md` using the template shape; note counts of postmortems vs analysis.
