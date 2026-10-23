# corpit-lambdas

Collection of Enterprise Engineering serverless functions (AWS Lambda) managed via Serverless Framework.

**Structure:** Each subdirectory is a separate Lambda project (Python or Go).

**New Lambda:**
```bash
make go-lambda      # Create Go lambda
make python-lambda  # Create Python lambda
```

**Remove Lambda:** Run `aws-vault exec xuxu-corpit -- sls remove` from project directory before merging removal PR.
