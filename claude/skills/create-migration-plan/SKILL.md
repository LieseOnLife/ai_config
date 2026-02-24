---
name: create-migration-plan
description: Create a comprehensive migration plan for database or schema migrations. Use when planning migrations, database changes, or schema updates.
---

# Skill: Create Migration Plan

Create a comprehensive migration plan for database or schema migrations.

## Inputs Required
- `--service`: Service name being migrated
- `--codebase-path`: Path to explore for current implementation
- `--target`: Description of target state

## Process
1. Explore the codebase to understand current state
2. Identify all files that need changes
3. Create:
   - Project plan markdown with phases
   - Migration scripts (dry-run, apply, validate, rollback)
   - Code changes TODO list
4. Store scripts in appropriate location

## Output Structure
```
<service>/migration/
├── README.md
├── 01_pre_migration_check.sh
├── 02_migrate_data.go
├── 03_validate_migration.go
├── 04_rollback.go
└── CODE_CHANGES_TODO.md
```
