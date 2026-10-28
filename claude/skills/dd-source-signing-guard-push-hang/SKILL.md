---
name: dd-source-signing-guard-push-hang
description: "Fix a dd-source git push or fetch that hangs for many minutes (Datadog Signing Guard pre-push hook walking thousands of main commits, or a wedged 1Password SSH agent)."
---

# dd-source push hangs after merging main

## Symptom
`git push` on a dd-source branch hangs 15+ minutes (or times out) right after `git merge origin/main`. `GIT_TRACE=1 git push --dry-run ...` shows the pre-push hook (`.git/hooks/pre-push`, "Datadog Signing Guard") looping `git show -s --format=%cn%x1f%ce <oid>` + `git for-each-ref --points-at <oid> refs/remotes/origin/` over main's commits.

## Cause
The hook excludes merged main commits only when a first-parent merge's other parent equals a **live** remote head at push time. dd-source main moves every minute or two, so if the fetch→push gap is long (a cold fetch takes ~50s+), the merge parent is stale and every merged main commit is checked one by one.

## Fix (never bypass hooks / `--no-verify`)
1. Warm the object store first: `git fetch origin main` on its own (may take a minute).
2. Then, in ONE command, fetch again (small delta, ~30s), merge, verify, push:
```bash
git fetch -q origin main && git merge -q --no-edit origin/main && git verify-commit HEAD && git push -q origin <branch>
```
A healthy push prints `info: Datadog Signing Guard: verified N Saje commit(s).` within ~1-2 min. If it hangs again, repeat step 2 — main just moved.
Child branches of a stack don't need this: merge the freshly pushed parent branch (a live head) and push right away; the parent boundary excludes main's commits.

## Fetch/SSH itself hangs (no hook involved)
If `git fetch` or `ssh -T git@ddoghq.github.com` stalls at `Authentications that can continue: publickey`, the 1Password SSH agent is wedged. Probe: `SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" timeout 10 ssh-add -l` — a timeout confirms it. Unlocking may not help; ask the user to fully quit (⌘Q) and reopen 1Password, then re-probe (it answers a few seconds after restart).

## Also check
- Disk space (`df -h /System/Volumes/Data`): a full disk also stalls pushes and Bazel (ENOSPC). Idle Bazel output bases live in `/private/var/tmp/_bazel_$USER/<hash>`; `DO_NOT_BUILD_HERE` inside each names its workspace. Delete only idle ones (no `pgrep -f output_base=<dir>`) after `chmod -R u+w`, with the user's approval.
