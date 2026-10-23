# consul-config

Dynamic configuration and legacy feature flags for Datadog services. Contains official configuration deployed to Consul clusters across datacenters.

**Structure:**
- `datadog/` - Configuration by datacenter (us1.prod.dog, eu1.prod.dog, etc.)
- `datadog/private-regions/` - Private region configs (files must use `.override` naming)

**Testing:**
```bash
virtualenv .venv && source .venv/bin/activate
pip install -r requirements.txt
pytest
```
