# Datadog Dashboards Collector

Collect Datadog dashboards authored by the user in range, categorized by purpose. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{user_handle}` (email), `{output_dir}`.
Output: `{output_dir}/dashboards.md`.

Use the Datadog MCP dashboard devices (list `xd://`, look for `mcp__datadog_*dashboard*`; read `xd://<tool>` for the schema).

## Steps

1. `search_datadog_dashboards` with `query: "author.handle:{user_handle}"`, `sort_by: "-modified_at"`. Paginate with `start_at` if needed. No results → note and stop.
2. Keep only dashboards whose `modified_at` or `created_at` is within range.
3. Fetch metadata per kept dashboard with `get_datadog_dashboard` (`include_widgets: false`).
4. Classify: Operational/Monitoring; Performance/Analysis; Product/Business; Investigation/Debug; Other.
5. Write a 4-line IMPACT summary per dashboard: purpose, key metrics, decisions/actions enabled, audience.
6. Write `{output_dir}/dashboards.md` using the template shape; note operational vs analysis counts.
