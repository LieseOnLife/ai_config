---
name: create-pr
description: Create pull requests with Saje's signature style - fun emojis, succinct content, varied formatting. Use when creating PRs, making pull requests, submitting code for review, or addressing Agentic Review (ARP) findings.
---

# Skill: Create Pull Request 🚀

Create a pull request with Saje's signature style: fun emojis, succinct content, varied formatting.

## Style Guide

### 🎨 Emoji Usage
Use a **plethora of unique fun emojis** throughout:
- Section headers: 🎯 🧰 🔑 🗺️ 🧪 📁 🚀 ⚡ 🎉 💡
- Tables: Add emoji column for visual flair
- File types: 📜 🔧 🐍 🔵 📋 🏗️ 📊
- Status: ✅ ❌ ⚠️ 🔄 💾 🔍
- Emphasis: 😬 (before) → 🎉 (after)

### 📝 Formatting Variety
Mix these formats in every PR:
- **Tables** → For listing files, features, comparisons
- **Bullet points** → For quick lists
- **Blockquotes (`>`)** → For TL;DR or key callouts
- **Code blocks** → For schemas, commands, file trees
- **Horizontal rules (`---`)** → To separate sections
- **Bold/italic** → For emphasis

### ✂️ Succinct Content
- Title: Action verb + what + context (max ~60 chars)
- Summary: One blockquote sentence
- Sections: Short, scannable
- No fluff, no filler

### 💬 Code Comments in the Diff
Make comments succinct, simple, and clear. **Default to none.**
- Write a comment only when WHY is non-obvious (hidden constraint, surprising behavior, empirical finding that contradicts docs).
- One or two short lines. Never a multi-paragraph block.
- Don't restate WHAT the code does — names and types already show that.
- Don't include investigation logs, error transcripts, dates, PR numbers, or "previously" narratives. That belongs in the commit message or PR description.
- If you find yourself writing a heading or numbered list inside a comment, it's too long — cut.

## Template Structure

```markdown
## 🎯 What's This All About?

> One-sentence summary of the change.

📋 **Related**: [Link to ticket/doc]

---

## 🧰 What's Changed

| Change | Description | 🎨 |
|--------|-------------|-----|
| File 1 | What it does | 🔧 |
| File 2 | What it does | 📜 |

---

## 🔑 Key Features

- ⚡ Feature one
- 🔒 Feature two
- 📈 Feature three

---

## 🗺️ Before/After (if applicable)

**Before** 😬
```
old state
```

**After** 🎉
```
new state
```

---

## 🚶 Code Walkthrough

> Read in this order. Hand-written code is `file_a.go` and `file_b.go`; the rest is generated.

**1. `file_a.go`**
- What changed and why, one bullet per notable decision

**2. `file_b.go`**

| Input | Result |
|---|---|
| case one | outcome |
| case two | outcome |

**3. Tests**
- 🧪 What each new test proves

---

## 🧪 Test Plan

- [ ] Test step one
- [ ] Test step two

---

## 📁 Files Changed

```
path/to/files/
├── 📜 file1.md
├── 🔧 file2.sh
└── 🔵 file3.go
```

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Process

### Step 0: Create Branch with Worktree
**Always use `git worktree` when creating new branches.**

Branch naming: All branches must start with `saje/`
```bash
# Create a new worktree with a new branch
git worktree add ../saje/feature-name -b saje/feature-name

# Or create a worktree from an existing branch
git worktree add ../saje/feature-name saje/feature-name
```

Benefits:
- Keep main worktree clean on main/master
- Work on multiple branches simultaneously
- Avoid stashing/committing work-in-progress
- Easy to compare changes across branches

### Step 0.5: Split Large Changes with Git Machete
**For large PRs, use `git machete` to create stacked PRs:**

When a change is too large for a single PR, break it into a stack of dependent branches:
```bash
# Define branch structure in .git/machete
git machete edit

# Example .git/machete file:
# main
#   saje/feature-part-1
#     saje/feature-part-2
#       saje/feature-part-3

# Discover and add branches automatically
git machete discover

# Slide out (rebase) branches to keep stack up to date
git machete traverse

# Create GitHub PRs for the entire stack
git machete github create-pr
```

When to split:
- PR exceeds ~400 lines of changes
- Multiple logical units of work
- Changes span unrelated areas of the codebase
- Easier to review in smaller chunks

Splitting strategy:
- **By layer**: infrastructure → schema → logic → API → tests
- **By feature**: core functionality → enhancements → polish
- **By file group**: related files together in each PR

### Step 1: Gather Context
```bash
git log main..HEAD --oneline
git diff --stat main...HEAD
```

### Step 2: Analyze Changes
- What's the main purpose?
- What files changed?
- What's the impact?

### Step 3: Craft Title
Format: `<emoji> <Action> <What>: <Context>`
Examples:
- `🚀 Add migration scripts: CAVM PK/SK schema`
- `🔧 Fix auth bug: Token refresh race condition`
- `✨ Implement account pooling: Phase 1 scaffolding`

### Step 4: Build Description
Use the template, adapting sections as needed:
- Skip sections that don't apply
- Add sections if needed (e.g., "⚠️ Breaking Changes")
- **Always include `🚶 Code Walkthrough`** for any PR with real logic: number the hand-written files in the order a reviewer should read them, say which files are generated, and use a small table when behavior branches on inputs. Skip it only for trivial PRs (typos, renames, version bumps).
- Keep it scannable

### Step 5: Create PR
```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<description>
EOF
)"
```

### Step 6: Run Agentic Review (ARP)
Required for every `ddoghq`/`DataDog` PR; skip for `LieseOnLife` repos.

**Tools missing?** If no `agentic_review_*` tools are mounted, tell Saje in your report: "ARP MCP isn't signed in: run `/mcp`, pick `agentic-review`, and authenticate" (add it first with `claude mcp add --transport http agentic-review https://agentic-review-mcp.mcp.us1.ddbuild.io/internal/mcp` if it's not listed). Until then, handle the ARP bot's GitHub threads (`dd-agentic-review-platform*`) through the post-push protocol, and run steps 1–4 once the tools mount.

1. `agentic_review_get_status` (`owner`, `repo`, `pull_number`). Drafts aren't reviewed automatically: when `allowed_action` is `REVIEW_ACTION_REVIEW_ANYWAY` (draft) or `REVIEW_ACTION_RETRY` (failed), call `agentic_review_request_review`.
2. Re-check status until the review finishes. An empty findings list while `QUEUED`/`RUNNING` means not done, not clean.
3. `agentic_review_get_findings` with `pull_number`. Fix each `open` finding; lines are relative to `reviewed_sha`, so re-anchor with `git diff <reviewed_sha>..HEAD`.
4. After the fix is pushed, record each outcome with `agentic_review_resolve_finding`:
   - `addressed` + `fix_commit_sha` + `fix_change_summary`.
   - `invalid` / `out_of_scope` + a one-sentence `reason`, only when certain; otherwise bring the finding to Saje first. Outcomes are permanent and write production review state.
5. ARP resolution leaves the GitHub thread open: reply to or resolve it per the post-push protocol (`github_thread_id` is the GraphQL thread ID).

Done when the status is finished and no finding is `open`.

## Emoji Reference by Category

| Category | Emojis |
|----------|--------|
| Actions | 🚀 ⚡ 🔧 ✨ 🔄 💥 🎯 |
| Status | ✅ ❌ ⚠️ 🔍 💡 🎉 |
| Files | 📜 📋 📁 🏗️ 📊 📇 |
| Languages | 🔵 (Go) 🐍 (Python) 🟨 (JS) 🔧 (Shell) |
| Data | 💾 📈 🗺️ 🔑 🧰 |
| Fun | 😬 🎨 🧪 🤖 |
