# Git

## Branching with Worktrees
**All development work must be done inside a worktree. Never commit code directly on `main`/`master`. Always create a worktree + branch before starting any implementation work.**

**Always use `git worktree` instead of `git switch`, `git checkout`, or `git branch` when creating or switching branches.**

```bash
# Instead of: git checkout -b saje/feature-name
# Use (from repo root):
REPO=$(basename $(pwd))
git worktree add ../${REPO}-worktrees/feature-name -b saje/feature-name

# Instead of: git switch existing-branch
# Use:
REPO=$(basename $(pwd))
git worktree add ../${REPO}-worktrees/existing-branch saje/existing-branch
```

All branches must be prefixed with `saje/`.
Worktree folders use the feature name directly (no `saje/` prefix to avoid nested directories).

### Worktree Conflicts
If a worktree or branch already exists, **do not delete it**. Instead, create a new version:
```bash
# If saje/feature exists, create:
REPO=$(basename $(pwd))
git worktree add ../${REPO}-worktrees/feature-v2 -b saje/feature-v2
# Or increment further:
git worktree add ../${REPO}-worktrees/feature-v3 -b saje/feature-v3
```

### Deletion Policy
**All worktree and branch deletions require explicit user approval.**
- Never run `git worktree remove` without asking
- Never run `git branch -d` or `git branch -D` without asking
- Never run `git push origin --delete` without asking

Benefits:
- Keep main worktree clean on main/master
- Work on multiple branches simultaneously
- No need to stash or commit work-in-progress
- Easy to compare changes across branches

### Worktrees with Subagents
When spawning subagents (via Task tool) that need to work in a worktree:

**Before spawning, get worktree context:**
```bash
~/.claude/scripts/worktree-context.sh
```

This returns JSON with `worktree_path`, `main_repo`, `branch`, and `is_worktree`.

1. **Always pass the full worktree path explicitly** in the prompt:
   ```
   Task prompt: "Working directory: /Users/saje.liese/go/src/github.com/DataDog/cloud-inventory-worktrees/feature-name

   Your task is to..."
   ```

2. **Subagents must cd first** before any operations:
   ```bash
   cd /full/path/to/worktree && git status
   ```

3. **Use absolute paths** for all file operations in subagents.

4. **Detect current worktree** before spawning:
   ```bash
   # Get the current worktree path
   WORKTREE=$(git rev-parse --show-toplevel)
   ```

5. **Grant permissions if needed** - Ask user to approve permissions for worktree paths if subagents are blocked.

### Worktree Location Convention
Create worktrees in a `{repo-name}-worktrees` sibling directory:
```bash
# Main repo at: /Users/saje.liese/go/src/github.com/DataDog/cloud-inventory
# Worktree at:  /Users/saje.liese/go/src/github.com/DataDog/cloud-inventory-worktrees/feature-name
# Branch:       saje/feature-name
```

### Subagent Permissions for Worktrees
If a subagent cannot access a worktree, **ask the user** to grant permissions:
1. Identify the worktree path the subagent needs
2. Ask: "The subagent needs access to `{path}`. Should I request this permission?"
3. If approved, add to project's `.claude/settings.local.json`:
   ```json
   {
     "permissions": {
       "allow": [
         "Read(/path/to/worktree/**)",
         "Write(/path/to/worktree/**)",
         "Bash(cd /path/to/worktree:*)"
       ]
     }
   }
   ```

For DataDog repos, worktrees are typically under:
`/Users/saje.liese/go/src/github.com/DataDog/{repo-name}-worktrees/`

## Github
When interacting with Github (github.com), ALWAYS use `gh` on the command line.

### Github Repos
When in a repo, also include {repo}.md in the `~/.claude` folder

### Pull Requests
- When making a PR description, only note changes between the whole current PR and main/master branch, not between the current commit and previous commits
- **NEVER merge a PR.** Never run `gh pr merge`, never comment `/merge` on a PR, never add a PR to the merge queue. Saje merges when ready — do not trigger merges under any circumstances.

# Execution Style
- Always maximize parallelism — use subagents, background agents, and parallel tool calls whenever possible
- Prefer launching multiple independent agents in a single message over sequential execution
