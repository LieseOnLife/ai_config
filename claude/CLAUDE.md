# Git

## Branching with Worktrees
**Always use `git worktree` instead of `git switch`, `git checkout`, or `git branch` when creating or switching branches.**

```bash
# Instead of: git checkout -b saje/feature-name
# Use:
git worktree add ../saje/feature-name -b saje/feature-name

# Instead of: git switch existing-branch
# Use:
git worktree add ../saje/existing-branch saje/existing-branch
```

All branches must be prefixed with `saje/`.

### Worktree Conflicts
If a worktree or branch already exists, **do not delete it**. Instead, create a new version:
```bash
# If saje/feature exists, create:
git worktree add ../saje/feature-v2 -b saje/feature-v2
# Or increment further:
git worktree add ../saje/feature-v3 -b saje/feature-v3
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
   Task prompt: "Working directory: /Users/saje.liese/go/src/github.com/DataDog/saje/feature-name

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
Create worktrees as siblings to the main repo, not inside it:
```bash
# Main repo at: /Users/saje.liese/go/src/github.com/DataDog/cloud-inventory
# Worktree at:  /Users/saje.liese/go/src/github.com/DataDog/saje/feature-name
#               (sibling directory, not inside cloud-inventory)
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
`/Users/saje.liese/go/src/github.com/DataDog/`

## Github
When interacting with Github (github.com), ALWAYS use `gh` on the command line.

### Github Repos
When in a repo, also include {repo}.md in the `~/.claude` folder

### Pull Requests
- When making a PR description, only note changes between the whole current PR and main/master branch, not between the current commit and previous commits
