---
name: dd-source-bazel-private-git-fetch
description: "Fix dd-source bzl builds/tests aborting with \"Repository not found\" while fetching git_repository crates (e.g. crates_vendor_do_not_use_directly__tonic-0.14.6 from ddoghq/grpc-rust-private) on Saje's machine."
---

# Bazel git_repository fetch fails with "Repository not found"

## Symptom
`bzl test` on a target (even a Go one: Go code links `libcoreconfig`, which is built from Rust) aborts with no test results. `aborted_targets` lists the targets with reason `UNKNOWN`, and `bazel-err.log` shows:
```
An error occurred during the fetch of repository 'crates_vendor_do_not_use_directly__tonic-0.14.6'
ERROR: Repository not found.
```
The remote is `https://github.com/ddoghq/grpc-rust-private` (see `third_party/crates/crates.bzl`). `git ls-remote` on that URL works from the shell.

## Cause
`~/.gitconfig` loads the Datadog config, which rewrites `https://github.com/ddoghq/` → `git@ddoghq.github.com:` (the ddoghq SSH identity), only through `includeIf "gitdir:~/go/src/github.com/DataDog/"`. Bazel clones into `/private/var/tmp/_bazel_*/external/...`, outside that gitdir, so only the generic `https://github.com/` → `git@github.com:` rewrite applies. That authenticates as the personal account, which can't see ddoghq repos.

`--repo_env=GIT_CONFIG_COUNT/KEY/VALUE` does NOT work: `git_worker.bzl` unsets `GIT_CONFIG_COUNT` (`_GIT_LOCAL_ENV_VARS`). Exporting the vars in the shell doesn't help either.

## Fix (local, no permanent config change)
```bash
G=$(mktemp -t bzl-gitconfig)
printf '[include]\n\tpath = %s/.gitconfig\n[include]\n\tpath = %s/.config/datadog/git/config\n' "$HOME" "$HOME" > $G
bzl test <targets> --repo_env=GIT_CONFIG_GLOBAL=$G
```
`GIT_CONFIG_GLOBAL` isn't on the git_worker unset list. The longest `insteadOf` match wins, so the ddoghq rewrite takes precedence. Once the repos are fetched into the output base, later runs don't need the flag until they're refetched. Delete the temp file afterwards. Don't edit Saje's `~/.gitconfig` without asking.

## Repro check
```bash
T=$(mktemp -d); git -C $T init -q; git -C $T remote add origin https://github.com/ddoghq/grpc-rust-private
git -C $T ls-remote --get-url origin   # git@github.com:... → broken; git@ddoghq.github.com:... → fine
```
