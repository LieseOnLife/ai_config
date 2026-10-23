# dd-source

Datadog's multi-module monorepo organized by domain. Provides hermetic builds, remote caching, and isolated CI pipelines per domain.

**Structure:**
- `domains/` - 60+ service domains (logs, metrics, apm, etc.)
- Uses Bazel exclusively for building and testing

**Build/Test:**
```bash
bzl build //domains/<domain>/...
bzl test //domains/<domain>/...
bzl run //:gazelle -- update <path>  # Update BUILD files after Go/Python/Proto changes
bzl run //:snapshot -- //<path>/...  # Update generated code after proto changes
bzl run //:dd-doctor                 # Diagnose environment issues
```

See `dd-source/AGENTS.md` for detailed guidance on running builds and maintaining BUILD files.
