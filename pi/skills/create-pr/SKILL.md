---
name: create-pr
description: Create pull requests with Saje's signature style - fun emojis, succinct content, varied formatting. Use when creating PRs, making pull requests, or submitting code for review.
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

🤖 Generated with [pi](https://pi.dev) by <your model name> (e.g., Claude, GPT, Gemini — whatever model you actually are)
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

**Always prefix the title before the emoji, per context:**
- **Part of a tracked project or stacked-PR series** → `{Project (or ticket)} - PR#{N}: ` — use the project's plain name (or ticket key) and the PR's position in its stack, not a git branch suffix.
- **One-off tied to a single ticket** → just the ticket number: `{TICKET-NUMBER}: `.
- **No ticket or project at all** → no prefix, title starts directly with the emoji.

Examples:
- `🚀 Add migration scripts: CAVM PK/SK schema` (no ticket/project)
- `CLOUDA-5555: 🔧 Fix auth bug: Token refresh race condition` (one-off, ticket only)
- `✨ Implement account pooling: Phase 1 scaffolding` (no ticket/project)
- `Account Pooling - PR#1: 🚀 Grant CAVM worker AWS Support case permissions` (stacked-PR series)
- `Account Pooling - PR#3: 🔧 Add standalone AWS Support client library`

### Step 4: Build Description
Use the template, adapting sections as needed:
- Skip sections that don't apply
- Add sections if needed (e.g., "⚠️ Breaking Changes")
- Keep it scannable

### Step 5: Create PR
> **🔑 GitHub account by repo:** repos owned by **`LieseOnLife`** (e.g. `LieseOnLife/ai_config`) use **`LieseOnLife`**. **Every other repo** (`dd-source`, `cloud-inventory`, anything under `DataDog`/`ddoghq`) uses **`saje-liese_ddog`**. Switch with `gh auth switch --user saje-liese_ddog` (or `--user LieseOnLife`) before running any `gh` command, and confirm with `gh auth status`.

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<description>
EOF
)"
```

## Emoji Reference by Category

| Category | Emojis |
|----------|--------|
| Actions | 🚀 ⚡ 🔧 ✨ 🔄 💥 🎯 |
| Status | ✅ ❌ ⚠️ 🔍 💡 🎉 |
| Files | 📜 📋 📁 🏗️ 📊 📇 |
| Languages | 🔵 (Go) 🐍 (Python) 🟨 (JS) 🔧 (Shell) |
| Data | 💾 📈 🗺️ 🔑 🧰 |
| Fun | 😬 🎨 🧪 🤖 |
