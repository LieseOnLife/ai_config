---
name: cavm-staging-validation
description: Use when validating a CAVM API staging deployment — verifying cavmctl behavior before and after a code change, checking GetChangeAudits is live, finding accounts with ChangeAudit records, or testing that list/get/report-modules commands haven't regressed.
---

# CAVM Staging Validation

## Overview

Structured before/after test suite for CAVM staging deployments. Covers the five key CLI views, explains how to detect whether new code is actually live, and documents the ChangeAudit gotcha that makes naive testing misleading.

## Setup

**Cavmctl config** — staging is already set as the current environment:
```
host: cavm-api-http-staging.us1.staging.dog
```

**Build cavmctl from a branch** (to test pre-merge):
```bash
cd <worktree>
bzl build //domains/compute/apps/cavmctl:cavmctl
cp bazel-bin/domains/compute/apps/cavmctl/cavmctl_/cavmctl ~/.local/bin/cavmctl-pr
```
Run `~/.local/bin/cavmctl-pr` for the branch build, `cavmctl` for the installed version.

## The Five Tests

Run these in order. Capture all output as baseline before any deployment, then repeat after.

### 1. List accounts
```bash
cavmctl list accounts --page-size 5
```
Expected: same accounts, same columns. Count may grow naturally over time.

### 2. Get account — AWS, in new CSP table
```bash
cavmctl get account b31bb2fb-ab0f-47f3-bf16-77cbbf1f5f09
# sbx-aws-csp-table-1 — created 2026-04-23 specifically to test new DB writes
```
Key fields to compare: Status, Account Type, Cloud Provider, AWS Components table.

### 3. Get account — GCP deprecated
```bash
cavmctl get account f3bab42a-efd5-47a2-9ceb-8ab83a8dce27
# test auto deprecate 1 — GCP account, no AWS components
```

### 4. Report modules
```bash
cavmctl report modules
```
**Known behavior change after CLOUDA-5521:** total count increased (154 → 212+) because new `reportModules` code includes accounts with no Details (shows `-`), whereas old code excluded them. This is expected and correct.

### 5. GetChangeAudits (new endpoint — CLOUDA-5521)
```bash
# Via cavmctl
cavmctl get account <vendify-id>
# Shows "Provisioning History" table if ChangeAudit records exist
# Shows "No provisioning history available for this account." if empty

# Via curl (to detect if endpoint exists at all)
AUTH=$(ddtool auth token --datacenter us1.ddbuild.io orchestration --http-header)
curl -s "https://cavm-api-http-staging.us1.staging.dog/internal/v1/accounts/<vendify-id>/change-audits" -H "$AUTH"
```

## Detecting Whether New Code Is Live

The HTTP status code of `GET /change-audits` tells you the deployment state:

| Code | Meaning | Action |
|------|---------|--------|
| `5` (NOT_FOUND) | Old server — route doesn't exist yet | Wait for deployment |
| `16` (UNAUTHENTICATED) | **New server live** — route registered, curl auth differs from cavmctl auth | New code is deployed ✅ |
| `200` / empty `changeAudits: []` | New server, no records for this account | Check with cavmctl |

`code: 16` from curl = deployment succeeded. Use cavmctl (which handles auth correctly) for actual data.

## The ChangeAudit Records Gotcha

**Most accounts will show "No provisioning history available."** This is NOT a bug.

ChangeAudit records exist only for accounts that:
1. Were provisioned **after** the `DualWriteClient` was deployed (CLOUDA-5519)
2. Went through the full Terraform step workflow (`UpdateAccountDetails` calls)

The staging backfill (CLOUDA-5520) populated `AccountInstance` SUMMARY records but **not** ChangeAudit records — because ChangeAudit records require `Account.Details` to be non-empty, and most legacy staging accounts have no Details.

### Finding accounts WITH ChangeAudit records

```bash
AUTH=$(ddtool auth token --datacenter us1.ddbuild.io orchestration --http-header)
cavmctl list accounts --page-size 50 | grep -oE "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" | while read vid; do
  COUNT=$(curl -s --max-time 5 "https://cavm-api-http-staging.us1.staging.dog/internal/v1/accounts/$vid/change-audits" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('changeAudits', [])))" 2>/dev/null)
  [ "${COUNT:-0}" -gt 0 ] && echo "HAS_RECORDS: $vid — $COUNT audits"
done
```

**If all accounts are empty:** Create a fresh test account and let it go through full provisioning. Accounts created and fully provisioned after CLOUDA-5519 deployed will have ChangeAudit records. Use that account for GetChangeAudits testing.

### Creating a test account for ChangeAudit validation

```bash
# Create account — goes through full provisioning workflow
cavmctl create account --name sbx-changeaudit-test --type sandbox --cloud aws \
  --cost-allocation staging --description "ChangeAudit validation account" \
  --team "Compute - Cloud Accounts"

# Wait for provisioning to complete (check status)
cavmctl get account <vendify-id>

# Once STATUS = created, verify ChangeAudit records exist
cavmctl get account <vendify-id>
# Should show "Provisioning History" table with ordinal, step, module, version, requestor, applied-at
```

## Expected Post-Deploy Behavior (CLOUDA-5521)

After deploying PR #421803:

| Command | Before | After |
|---------|--------|-------|
| `list accounts` | N accounts | Same N accounts (identical) |
| `get account` — account with ChangeAudits | Shows Details | Shows Provisioning History table (ChangeAudit data) |
| `get account` — account without ChangeAudits | Shows Details | "No provisioning history available." + Details fallback |
| `report modules` | 154 accounts | 210+ accounts (includes no-Details accounts) |
| `GET /change-audits` curl | `code: 5` | `code: 16` (route exists) |

## Deployment Notes

- **AppGate required** for all staging operations
- **Rapid service deployment** (`cavm-api-staging`, `cavm-api-http-staging`) can take 15–40 minutes in k8s
- The **HTTP gateway** (`cavm-api-http-staging`) must be deployed alongside the gRPC server — cavmctl talks to the HTTP gateway, so new API routes (like `GetChangeAudits`) won't be available until BOTH services deploy
- Watch deployment: `ddr conductor describe --target staging cavm-api-http-staging`
- Manual deployment from branch: `ddr conductor run --target staging --release-from-head cavm-api-http-staging`
- If stuck in "Deploying" > 60 min: cancel and retry — `ddr conductor cancel --target staging <service>`

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Testing GetChangeAudits on backfilled accounts | Find/create accounts provisioned after CLOUDA-5519 |
| Concluding new code isn't live because `GetChangeAudits` returns empty | Check curl response code — `16` = new code live |
| Expecting `report modules` count to stay the same | Count increases by design — new code includes more accounts |
| Testing cavmctl before both gRPC server AND HTTP gateway are deployed | Check `cavm-api-http-staging` specifically, not just `cavm-api-staging` |
| Using `ddtool auth` token with curl for CAVM endpoints | cavmctl handles auth differently — use cavmctl for data, curl only for route existence check |
