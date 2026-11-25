#!/usr/bin/env bash
# autoapprove-check.sh — Ask Change Policy whether a PR qualifies for auto-approval.
#
# Usage: autoapprove-check.sh [PR URL | PR number | branch] [--json]
#   No argument: the PR for the current branch (resolved with `gh pr view`).
#   --json: print the raw Evaluate response instead of the summary.
#
# Exit codes: 0 allowed, 1 denied, 2 pending (signals still computing; re-run
# in a few minutes), 3 error (auth, network, PR not found, bad response).
#
# API: POST /internal/v1alpha/change-policy:evaluate on changepolicy-http-gateway
# (alpha, internal; owner ai-devx-flow, questions in #risk-aware-review).
# Calling it records an evaluation but never approves or merges anything.

set -euo pipefail

GATEWAY="${CHANGEPOLICY_GATEWAY:-https://changepolicy-http-gateway.us1.ddbuild.io/internal/v1alpha}"
ACTION="prapprover:AutoApprove"
PR_URL_RE='^https://github\.com/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)/pull/([0-9]+)([/?#].*)?$'

die() { echo "error: $*" >&2; exit 3; }

raw=false
target=""
while (($#)); do
  case "$1" in
    --json) raw=true ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --) shift; target="${1:-}"; break ;;
    -*) die "unknown flag: $1" ;;
    *) target="$1" ;;
  esac
  shift
done

[[ "$GATEWAY" =~ ^https://[A-Za-z0-9.-]+\.ddbuild\.io(/|$) ]] || die "CHANGEPOLICY_GATEWAY must be an https://*.ddbuild.io URL"

url="$target"
if [[ ! "$url" =~ $PR_URL_RE ]]; then
  gh_args=(--json url -q .url)
  [[ -n "$target" ]] && gh_args+=(-- "$target")
  url=$(gh pr view "${gh_args[@]}" 2>/dev/null) || die "no PR found for '${target:-current branch}' (gh pr view failed)"
  [[ "$url" =~ $PR_URL_RE ]] || die "unexpected PR URL from gh: $url"
fi
owner="${BASH_REMATCH[1]}" repo="${BASH_REMATCH[2]}" number="${BASH_REMATCH[3]}"
url="https://github.com/$owner/$repo/pull/$number"

header=$(ddtool auth token sdm --datacenter us1.ddbuild.io --http-header 2>/dev/null) || die "ddtool could not mint an sdm token (run: ddtool auth login)"
[[ -n "$header" ]] || die "ddtool returned an empty auth header"

body=$(jq -nc --arg o "$owner" --arg r "$repo" --argjson n "$number" --arg a "$ACTION" \
  '{pull_request: {owner: $o, repository: $r, number: $n}, actions: [$a]}')

# Header goes over stdin so the bearer token never appears in argv.
resp=$(printf '%s\n' "$header" | curl -sS --proto '=https' -m 90 -w '\n%{http_code}' -X POST \
  -H @- -H 'content-type: application/json' -d "$body" "$GATEWAY/change-policy:evaluate") \
  || die "request to $GATEWAY failed"
code=${resp##*$'\n'}
resp=${resp%$'\n'*}
if [[ "$code" != 200 ]]; then
  msg=$(jq -r '.message // empty' <<<"$resp" 2>/dev/null || true)
  [[ -n "$msg" ]] || msg=$(printf '%s' "$resp" | tr -cd '[:print:]' | head -c 300)
  die "HTTP $code from change-policy:evaluate: $msg"
fi
jq -e '(.decisions | type) == "array" and (.decisions | length) > 0' >/dev/null 2>&1 <<<"$resp" \
  || die "malformed response from change-policy:evaluate (no decisions)"

# Shared definitions for the summary and the exit code.
DEFS='
  def clean: tostring | gsub("[\u0000-\u001f\u007f]"; " ");
  def pending: (.present | not) or (.actual.string_value == "pending");
  def applicable: select(.action_matched and .resource_matched);
  def is_allow: (.effect | ascii_downcase) == "allow";
  # 0 allowed, 1 denied, 2 an applicable Allow statement can still pass once pending signals land.
  def status: .decisions[0] as $d
    | if $d.result == "allowed" then 0
      elif $d.result == "explicitDeny" then 1
      elif any($d.statements[] | applicable | select(is_allow);
               all(.conditions[]; .matched or pending) and any(.conditions[]; .matched | not))
        or (($d.pending_context_values | length) > 0 and any($d.statements[] | applicable; is_allow))
      then 2
      else 1 end;
'

if $raw; then
  printf '%s\n' "$resp"
else
  jq -r --arg url "$url" "$DEFS"'
    def val: if . == null then "∅"
      elif has("string_value") then .string_value
      elif has("bool_value") then (.bool_value | tostring)
      elif has("number_value") then (.number_value | tostring)
      elif has("string_list_value") then ((.string_list_value.values // []) | if length == 0 then "[]" else join(",") end)
      else tostring end | clean;
    def actual_list: (.actual.string_list_value.values // []);
    def hint:
      if .key == "service:Affected" then
        "SCOPE: move changes to these non-pilot services into another PR: \(actual_list - .expected | join(", ") | clean)."
      elif (.key | test("^(compliance:|service:Criticality)")) and (.actual | val) == "unknown" then
        "SCOPE: no changed file belongs to a service (libs, CLIs like cavmctl, openspec docs map to none). Lib-only/CLI-only PRs need human review."
      elif (.key | test("^(compliance:|service:Criticality)")) then
        "BLOCKED: property of the service/files; needs human review."
      elif .key == "reliability:RiskLevel" then
        "SCOPE: risk score too high; split risky parts into their own PR."
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
    | "\($url)  head=\($d.head_sha[0:12] | clean)  registry=\($d.registry | clean)@\($d.registry_version | clean)",
      "RESULT: \($d.result | clean)\(if ($d.pending_context_values | length) > 0 then "  (pending: \($d.pending_context_values | map(clean) | join(", ")))" else "" end)",
      ( [$d.statements[] | applicable] as $st
        | if ($st | length) == 0 then
            "No pilot policy covers this repo/PR (resources do not match) — needs human review."
          else
            $st[] | "",
              "\(.effect | clean) \(.policy_id | clean)/\(.sid // .statement_index | clean):",
              if is_allow then
                ( .conditions[]
                  | if .matched and .key == "service:Affected" and actual_list == [] then "  ⚠️  \(.key) = []  (no service matched; see compliance/criticality)"
                    elif .matched then "  ✅ \(.key | clean) = \(.actual | val)"
                    elif pending then "  ⏳ \(.key | clean) = \(.actual | val)  (still computing; re-run later)"
                    else "  ❌ \(.key | clean) = \(.actual | val)  want \(if .key == "service:Affected" then "⊆ pilot services" else (.expected | join("|") | clean) end)\n     → \(hint)" end )
              elif .conditions_matched then
                "  ⛔ deny statement matched → BLOCKED: needs human review."
              else
                "  ✅ deny statement not triggered"
              end
          end )
  ' <<<"$resp"
fi

exit "$(jq -r "$DEFS"' status' <<<"$resp")"
