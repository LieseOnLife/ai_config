# vault-config

HashiCorp Vault configuration for secrets management across all Datadog environments. Policies, backends, and roles managed via Terraform.

**Structure:**
- `policies/` - Vault policy HCL files (named `policies/{policy-name}.hcl`)
- `modules/datacenter/` - Team group definitions and policy mappings

**Deployment:** PRs auto-apply to staging/prod via GitLab CI + Atlas/Terraform (except GovCloud prod which requires manual sync).
