# cloud-inventory

Cloud infrastructure management for GCP projects, AWS accounts, and Azure subscriptions. Uses Bazel build system with Terraform for infrastructure-as-code.

**Structure:**
- `domains/` - Service domains (cloud-platform, api-platform, etc.)
- `aws/`, `gcp/`, `azure/` - Cloud provider configurations
- `datacenters/` - Datacenter-specific configs

**Build:** `bazel build //...` or `bzl build //...`

## Updating a branch from master: rebase, never merge

Bring a cloud-inventory branch up to date with `git rebase origin/master` + `git push --force-with-lease`. **Never `git merge master`** into a PR branch.
- Why: `terraform-pipeline-generate` (cloud-tf-ci `src/gitlab-ci/cloud-inventory.yml`) computes `MASTER_BRANCH_CHANGED_DIRECTORIES` from `git diff ${CI_COMMIT_SHA}^1 ${CI_COMMIT_SHA}`. On a merge commit `^1` is the old branch head, so the diff spans every master commit pulled in; on a stale branch that overflows exec with `Argument list too long` and the job fails after all retries (hit on ddoghq/cloud-inventory#130, 2005 commits behind).
- Stale branches also carry pre-org-move `@DataDog/*` CODEOWNERS; rebasing onto master picks up the `@ddoghq/*` owners.
- Stacks: rebase pr1 onto master, then each child onto its rebased parent (`git rebase --onto saje/<x>-pr1 <old-pr1-sha> saje/<x>-pr2`). This overrides the global "merge main into the base branch" stack rule for this repo.

## Terraform modules (`terraform-modules/<name>/`)

Every module change MUST include all of these in the same PR:
- **Version bump:** `terraform_module_version` in `@version.tf` (semver: new optional input/action → minor, fix → patch, breaking → major).
- **Changelog entry:** new `### [X.Y.Z](https://github.com/DataDog/cloud-inventory/tree/<module>_vX.Y.Z/terraform-modules/<module>)` at the top of `## Changelog` in the module `README.md`. Say what changed *and why* (the consumer need), not just the diff. Easy to forget: CI does not check it.
- **Test:** a `main.tftest.hcl` assertion for the new behavior; run `terraform init -backend=false && terraform test` and `terraform fmt -check` in the module dir.
- **Rationale in the PR body:** why the consumer needs it, plus blast radius.
- Consumers bump to the new version in a separate follow-up PR after the release tag (`<module>_vX.Y.Z`) is cut on merge.
- The repo moved to `ddoghq/cloud-inventory` (Oct 2026); `origin` points there and the old `DataDog/cloud-inventory` is the frozen `datadog` remote. Use the `saje-liese_ddog` account for `gh` (the default active account). Old PRs on `DataDog/cloud-inventory` need `GH_TOKEN=$(gh auth token --user LieseOnLife)`.

## IAM changes (anywhere: reusable modules, root configs, inline policies)

Applies to any IAM grant: reusable modules under `terraform-modules/`, root configurations like `managed-iam/aws/<account>/…`, inline and managed policies, trust policies, SCPs.
- **Verify every action exists** in AWS's service reference JSON (`https://servicereference.us-east-1.amazonaws.com/v1/<service>/<service>.json`) before adding it. Some API operations are not IAM actions: `dynamodb:TransactWriteItems` is authorized per item via `PutItem`/`UpdateItem`/`DeleteItem`/`ConditionCheckItem`, so granting it is a no-op. Look up the operation's `AuthorizedActions` to find what is actually needed.
- **Grant only the missing action.** Check what the policy already covers (wildcards like `Update*`, `Get*`) and add only what's not covered.
- **PR rationale:** what the consumer does that fails without the grant, why that exact action is required (link the AWS doc), and blast radius (same resources? new data access?).

**Where it lands changes how you verify it:**
- **Reusable module:** follow the module rules above, plus a `main.tftest.hcl` assertion that the action is in the rendered policy. Then roll out with a separate PR bumping each consumer (staging, then prod).
- **Root config (e.g. `managed-iam`):** no version or tftest. The PR's Terraform plan (`dd-prcommenter-cloudresources`) is the verification: confirm it shows only the intended policy diff on the intended roles.
