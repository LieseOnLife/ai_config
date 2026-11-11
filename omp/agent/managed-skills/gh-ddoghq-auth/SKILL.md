---
name: gh-ddoghq-auth
description: "Fix gh failing on ddoghq repos (\"Could not resolve to a Repository with the name 'ddoghq/...'\") on Saje's machine by using the work GitHub account token without switching the active account. Also: which account sees DataDog/* vs ddoghq/* repos."
---

# gh access to ddoghq repos

## Symptom
`gh pr view N -R ddoghq/dd-source` (or `ddoghq/cloud-inventory`, `ddoghq/k8s-resources`) fails with
`GraphQL: Could not resolve to a Repository with the name 'ddoghq/...'`.

## Cause
`gh` keyring holds two github.com accounts. The active one is the personal account `LieseOnLife`, which can't see the ddoghq org. The work account `saje-liese_ddog` is logged in but inactive.

## Which account sees which org
| Org | Account | Example repos |
|---|---|---|
| `ddoghq/*` | `saje-liese_ddog` (work, EMU) | dd-source, cloud-inventory, k8s-resources |
| `DataDog/*` (repos not yet moved to ddoghq) | `LieseOnLife` | `DataDog/devtools` |

`saje-liese_ddog` gets the same "Could not resolve" error on `DataDog/*` repos. SSH (`git push`) authenticates as `LieseOnLife`, so pushes to `DataDog/*` work even when `gh` fails. If one account can't resolve a repo, try the other before concluding the repo moved.

## Fix (no global state change)
Scope the right token to the command instead of running `gh auth switch`, so Saje's default account stays as it is:

```bash
export GH_TOKEN=$(gh auth token -h github.com -u saje-liese_ddog)   # ddoghq/*
# export GH_TOKEN=$(gh auth token -h github.com -u LieseOnLife)    # DataDog/*
gh api user -q .login
gh pr view 124627 -R ddoghq/dd-source --json state,reviewDecision,mergedAt
```

- In the agent bash tool, put the `export` and the `gh` calls in the same command. Background or temporary shells don't keep the variable.
- Run `gh auth switch -u saje-liese_ddog` only if Saje asks to make the work account the default.
- Run `gh auth status` first if the token command fails. If `saje-liese_ddog` is missing, Saje has to run `gh auth login` interactively (browser SSO), so don't attempt it headlessly.
