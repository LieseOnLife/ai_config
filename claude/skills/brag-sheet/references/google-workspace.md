# Google Workspace Collector

Collect Google Docs/Slides owned by the user within the range. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{user_email}`, `{output_dir}`.
Output: `{output_dir}/google-workspace.md`.

Use the `xd://mcp__datadog_google_workspace_*` devices: `search_files`, `get_file_metadata`, `get_doc_as_markdown`, `get_presentation` (read `xd://<tool>` for each schema).

## Steps

1. Search owned docs: `mimeType='application/vnd.google-apps.document' and '{user_email}' in owners and modifiedTime >= '{start_date}T00:00:00'`. Repeat for `application/vnd.google-apps.presentation`.
2. Get metadata per doc; prioritize RFCs, product briefs, design docs.
3. Read content of significant docs to understand them.
4. Write a 4-line IMPACT summary per doc: purpose, key decisions/info, outcome, audience.
5. Write `{output_dir}/google-workspace.md`. On failure/no auth, write an error section and stop this source.
