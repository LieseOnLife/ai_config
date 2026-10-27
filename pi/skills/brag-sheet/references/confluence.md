# Confluence Collector

Collect Confluence pages authored or updated by the user within the range, categorized by type. Read-only except for writing the output file.

Inputs: `{start_date}`, `{end_date}`, `{atlassian_account_id}`, `{cloud_id}`, `{output_dir}`.
Output: `{output_dir}/confluence.md`.

CQL `creator`/`contributor` require the Atlassian account ID, not an email. Never use `currentUser()`.

## Step 1: Collect pages (two passes, paginate each)

Use `xd://mcp__atlassian_searchconfluenceusingcql` with `cloudId: {cloud_id}`, `limit: 100`, paging with the returned cursor until fewer than `limit` results remain.

- Authored: `type = page AND creator = "{atlassian_account_id}" AND created >= "{start_date}" ORDER BY created DESC`
- Updated: `type = page AND contributor = "{atlassian_account_id}" AND lastmodified >= "{start_date}" ORDER BY lastmodified DESC`

Dedupe Updated against Authored by page ID. If both searches fail, write an error section and stop this source.

## Step 2: Extract per page

Title, space title, created date, last modified date, and full URL. If the search excerpt is insufficient, fetch the body with `xd://mcp__atlassian_getconfluencepage` (`cloudId: {cloud_id}`, `pageId`, `contentFormat: "markdown"`). Write a 4-line IMPACT summary: purpose, key decisions/info captured, outcome driven, audience.

## Step 3: Categorize

Within Authored and Updated, bucket pages: RFCs/Design Docs; Product Briefs; Documentation/Guides; Runbooks/Operational; Meeting Notes/Decision Logs; Other.

## Step 4: Write output

Write `{output_dir}/confluence.md`; every page title is a markdown link to its URL, with impact lines.
