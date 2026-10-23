# Slack Collector

Collect substantive Slack messages authored by the user within the range, grouped by topic. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{slack_username}`, `{channel_list}`, `{output_dir}`.
Output: `{output_dir}/slack.md`.

Use the `xd://mcp__slack_*` devices: `search_public_and_private` (message search), `read_thread`, `read_channel`, `read_user_profile`. Read `xd://<tool>` for each schema.

## Steps

1. Resolve the user profile from the Slack user ID / name.
2. Search authored messages in range. Per channel: `from:@{slack_username} in:#{channel} after:{start_date} before:{end_date}`. With no channels, drop the `in:#…` clause and search broadly.
3. Keep substantive messages; drop reactions, greetings, and sub-50-char acks unless they contain links or decisions.
4. Group by thread and by project/topic.
5. Summarize each group's contribution and impact.
6. Write `{output_dir}/slack.md` using the template shape (grouped, with links where available). On tool failure, write an error section and stop this source.
