#!/usr/bin/env bash
# autoapprove-check.sh — Ask Change Policy whether a PR qualifies for auto-approval.
#
# Usage: autoapprove-check.sh [PR number | PR URL | branch] [--json]
#   No argument: the PR for the current branch (resolved with `gh pr view`).
#   --json: print the raw Evaluate response instead of the summary.
#
# Exit codes: 0 allowed, 1 denied, 2 pending (signals still computing; re-run
# in a few minutes), 3 error (auth, network, PR not found).
#
# API: POST /internal/v1alpha/change-policy:evaluate on changepolicy-http-gateway
# (alpha, internal; owner ai-devx-flow, questions in #risk-aware-review).
# Calling it records an evaluation but never approves or merges anything.

set -euo pipefail

GATEWAY="${CHANGEPOLICY_GATEWAY:-https://changepolicy-http-gateway.us1.ddbuild.io/internal/v1alpha}"
ACTION="prapprover:AutoApprove"

raw=false
target=""
for arg in "$@"; do
  case "$arg" in
    --json) raw=true ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) target="$arg" ;;
  esac
done

url=$(gh pr view ${target:+"$target"} --json url -q .url 2>/dev/null) || {
  echo "error: no PR found for '${target:-current branch}' (gh pr view failed)" >&2
  exit 3
}
# https://github.com/<owner>/<repo>/pull/<number>
IFS=/ read -r _ _ _ owner repo _ number <<<"$url"

header=$(ddtool auth token sdm --datacenter us1.ddbuild.io --http-header 2>/dev/null) || {
  echo "error: ddtool could not mint an sdm token (run: ddtool auth login)" >&2
  exit 3
}

body=$(jq -nc --arg o "$owner" --arg r "$repo" --argjson n "$number" --arg a "$ACTION" \
  '{pull_request: {owner: $o, repository: $r, number: $n}, actions: [$a]}')

resp=$(curl -sS -m 90 -w '\n%{http_code}' -X POST -H "$header" -H 'content-type: application/json' \
  -d "$body" "$GATEWAY/change-policy:evaluate") || { echo "error: request to $GATEWAY failed" >&2; exit 3; }
code=${resp##*$'\n'}
resp=${resp%$'\n'*}
if [[ "$code" != 200 ]]; then
  echo "error: HTTP $code from change-policy:evaluate" >&2
  echo "$resp" >&2
  exit 3
fi

if $raw; then
  echo "$resp"
else
  jq -r --arg url "$url" '
    def val: if . == null then "∅"
      elif has("string_value") then .string_value
      elif has("bool_value") then (.bool_value | tostring)
      elif has("number_value") then (.number_value | tostring)
      elif has("string_list_value") then ((.string_list_value.values // []) | if length == 0 then "[]" else join(",") end)
      else tostring end;
    def actual_list: (.actual.string_list_value.values // []);
    def is_pending: (.present | not) or ((.actual | val) == "pending");
    def hint:
      if .key == "service:Affected" then
        "SCOPE: move changes to these non-pilot services into another PR: \(actual_list - .expected | join(", "))."
      elif (.key | test("^(compliance:|service:Criticality)")) and (.actual | val) == "unknown" then
        "SCOPE: no changed file belongs to a service (libs, CLIs like cavmctl, openspec docs map to none). Lib-only/CLI-only PRs need human review."
      elif (.key | test("^(compliance:|service:Criticality)")) then
        "BLOCKED: property of the service/files; needs human review."
      elif .key == "reliability:RiskLevel" then
        "FIXABLE: smaller, single-purpose diff; split risky parts out."
      elif .key == "author:CodeOwnerTeamMembership" then
        "SCOPE: you do not own every file; move non-owned files to another PR."
      elif .key == "agentic-review:status" then
        "FIXABLE: resolve every Agentic Review comment (fix or reply), then push."
      elif .key == "ci:Status" then
        "FIXABLE: wait for or fix CI."
      elif .key == "security:BewaireVerdict" then
        "BLOCKED: BewAIre flagged it; ask in #risk-aware-review if wrong."
      elif .key == "author:Type" then
        "BLOCKED: agent-initiated PRs are ineligible in the pilot."
      else "check the policy condition" end;

    .decisions[0] as $d
    | "\($url)  head=\($d.head_sha[0:12])  registry=\($d.registry)@\($d.registry_version)",
      "RESULT: \($d.result)\(if ($d.pending_context_values | length) > 0 then "  (pending: \($d.pending_context_values | join(", ")))" else "" end)",
      ( [$d.statements[] | select(.action_matched and .resource_matched)] as $st
        | if ($st | length) == 0 then
            "No pilot policy covers this repo/PR (resources do not match) — needs human review."
          else
            $st[] | "",
              "\(.effect) \(.policy_id)/\(.sid // .statement_index):",
              ( .conditions[]
                | if .matched and .key == "service:Affected" and actual_list == [] then "  ⚠️  \(.key) = []  (no service matched; see compliance/criticality)"
                  elif .matched then "  ✅ \(.key) = \(.actual | val)"
                  elif is_pending then "  ⏳ \(.key) = \(.actual | val)  (still computing; re-run later)"
                  else "  ❌ \(.key) = \(.actual | val)  want \(if .key == "service:Affected" then "⊆ pilot services" else (.expected | join("|")) end)\n     → \(hint)" end )
          end )
  ' <<<"$resp"
fi

jq -e '.decisions[0].result == "allowed"' >/dev/null <<<"$resp" && exit 0
# A settled failure outranks "still computing": re-running will not change it.
jq -e 'any(.decisions[0].statements[] | select(.action_matched and .resource_matched) | .conditions[];
  .matched == false and .present and .actual.string_value != "pending")' >/dev/null <<<"$resp" && exit 1
jq -e '(.decisions[0].pending_context_values | length) > 0
  or any(.decisions[0].statements[].conditions[]; .matched == false)' >/dev/null <<<"$resp" && exit 2
exit 1
