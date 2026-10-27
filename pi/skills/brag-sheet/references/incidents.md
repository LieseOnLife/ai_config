# Datadog Incidents Collector

Collect resolved Datadog incidents where the user was a responder/commander in range. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{user_email}`, `{output_dir}`.
Output: `{output_dir}/incidents.md`.

Use the Datadog MCP incident devices (list `xd://`, look for `mcp__datadog_*incident*`, e.g. search/get incident; read `xd://<tool>` for the schema). If none are mounted, note it and stop this source (Datadog MCP not connected).

## Steps

1. Search `state:resolved responder:{user_email}` with `from: {start_date}`, `to: {end_date}`. No results → write a note and stop.
2. Per incident, extract: ID, title, severity (SEV-1..5), created/resolved dates, commander handle, whether the user was commander (compare to `{user_email}`), URL, customer impact.
3. For sparse SEV-1/2/3 incidents, fetch details with `get_datadog_incident`.
4. Write `{output_dir}/incidents.md` using the template shape; note count and how many as commander.
