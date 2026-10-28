# Obsidian Collector

Collect accomplishment evidence from the Obsidian vault within the range. Read-only except for writing the output file. This source is not in the original Claude plugin.

Inputs: `{start_date}`, `{end_date}`, `{vault}` (default `/Users/saje.liese/Obsidian/Tech-2`), `{tag}` (default `🟪`), `{output_dir}`.
Output: `{output_dir}/obsidian.md`.

## Steps

1. Scan the vault with `eval` (Python over the filesystem) for notes carrying `{tag}`, prioritizing `Calendar/Daily Notes`, `Datadog/Projects`, and `Datadog/Tasks`. Filter to the date range using path/frontmatter/inline dates. Keep raw note bytes out of context — print only structured findings.
2. Extract completed/shipped/reviewed/led work attributable to the user. Exclude unchecked, cancelled, and other people's work. Label inference and ambiguity explicitly.
3. Group by theme; dedupe repeated references to the same PR/rollout/incident into one achievement.
4. Cite exact note path (and line where useful) for each item. Preserve useful wiki-links and external links.
5. Write `{output_dir}/obsidian.md`: themed achievements with dates and source paths, plus a short coverage/ambiguity section.

If an Obsidian evidence pass already ran this session, reuse those artifact files instead of re-scanning.
