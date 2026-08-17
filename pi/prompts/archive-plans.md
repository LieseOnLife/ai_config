---
name: archive-plans
description: Archive GSD plans from .planning/ to ~/repos/ai_projects/ for future reference.
---

# Archive GSD Plans

Copy GSD planning artifacts to `~/repos/ai_projects/` for long-term reference and lessons learned.

## Process

### Step 1: Detect Context
Determine from the current working directory:
- **Repo name** (e.g., `cloud-inventory`, `dd-source`)
- **Feature/ticket name** — from branch name, .planning/STATE.md, or ask the user
- **Archive path**: `~/repos/ai_projects/{repo}/{ticket-or-feature}/`

### Step 2: Identify Files to Archive
Scan `.planning/` for:
- `ROADMAP.md`
- `PROJECT.md`
- `STATE.md`
- `phases/*/PLAN*.md`
- `phases/*/RESEARCH.md`
- `phases/*/VERIFICATION.md`
- `codebase/*.md` (if map-codebase was run)

Show the list to the user for confirmation.

### Step 3: Copy Files
Create the archive directory and copy files, preserving the phase structure:

```
~/repos/ai_projects/{repo}/{ticket-or-feature}/
├── ROADMAP.md
├── PROJECT.md
├── STATE.md
├── phase-1/
│   ├── PLAN.md
│   ├── RESEARCH.md
│   └── VERIFICATION.md
├── phase-2/
│   └── ...
└── NOTES.md          # Generated in Step 4
```

### Step 4: Generate NOTES.md
Create a `NOTES.md` using the template at `~/repos/ai_projects/templates/NOTES-template.md`.

Fill in:
- **Summary**: What was built/changed (from ROADMAP or PROJECT)
- **What Worked**: Phases that executed cleanly, good patterns used
- **What Didn't Work**: Failed plans, re-plans, debugging sessions
- **Lessons Learned**: Patterns to reuse, pitfalls to avoid
- **Time & Effort**: Number of phases, approximate session count

Present the draft to the user for review/edits before writing.

### Step 5: Commit to ai_projects
```bash
cd ~/repos/ai_projects
git add {repo}/{ticket-or-feature}/
git commit -m "Archive: {ticket-or-feature} ({repo})"
```

Ask the user if they want to push.

## Safety
- Never delete files from .planning/ — this is a copy operation only
- Always show what will be archived before copying
- Always show NOTES.md draft before writing
