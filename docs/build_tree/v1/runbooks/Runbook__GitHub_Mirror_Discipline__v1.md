# Runbook — GitHub Mirror Discipline v1

**Governance rules for maintaining GitHub mirror of New Qwrk Kernel**

---

## Purpose

This runbook establishes discipline for keeping the GitHub repository (`new-qwrk-kernel`) in sync with the canonical OneDrive source.

**Repository**: `new-qwrk-kernel` (GitHub)

**Canonical Source**: `C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\`

**Principle**: GitHub is a MIRROR, not the source of truth. OneDrive master → GitHub mirror.

---

## Core Rules

### 1. OneDrive is Master

- All authoritative work happens in OneDrive folder first
- GitHub receives pushed commits from OneDrive
- NEVER edit files directly on GitHub web interface
- NEVER pull from GitHub to overwrite OneDrive changes

### 2. Commit Frequently, Push Strategically

**Commit locally** after:
- Completing a leaf node
- Creating a new documentation file
- Making schema or workflow changes
- Reaching a stable checkpoint

**Push to GitHub** after:
- Completing a Build Tree milestone
- Locking a governance document
- Finishing a feature branch
- Daily end-of-work snapshot (recommended)

### 3. Git Commit Message Format

All commits must follow this format:

```
<Short summary in imperative mood>

<Optional detailed description>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Examples**:

✅ Good:
```
Add Build Tree Management Pack v1

Includes tree docs, runbooks, KGB, templates, and manual SQL for
executing the Save Query List build tree.

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

✅ Good:
```
Lock Mutability Registry v1

Defines CREATE_ONLY, UPDATE_ALLOWED, PROMOTE_ONLY mutation rules
for all artifact fields.

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

❌ Bad:
```
updates
```

❌ Bad:
```
Fixed stuff and added files
```

---

## Commit Workflow

### Step 1: Verify Working Directory

```bash
cd "C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel"
pwd
```

**Expected Output**: `/c/Users/j_bla/OneDrive/AAA QwrkX/new-qwrk-kernel`

### Step 2: Check Git Status

```bash
git status
```

**Review**:
- Which files have changed?
- Are there untracked files?
- Are there files that should be in .gitignore?

### Step 3: Review Changes

```bash
git diff
```

**Verify**:
- No credentials are being committed
- No binary files (.docx, .xlsx) are being committed
- Changes are intentional

### Step 4: Stage Files

**Stage all changes**:
```bash
git add .
```

**Stage specific files**:
```bash
git add docs/build_tree/v1/tree/Build_Tree__Save_Query_List__v1.md
git add docs/build_tree/v1/runbooks/*.md
```

### Step 5: Commit with Message

Use HEREDOC for multi-line commit messages:

```bash
git commit -m "$(cat <<'EOF'
Add Build Tree Management Pack v1

Includes tree docs, runbooks, KGB, templates, seed, and manual SQL
for executing the Save Query List build tree.

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 6: Push to GitHub

```bash
git push origin main
```

**If first push**:
```bash
git push -u origin main
```

---

## What to Commit

### ✅ Always Commit

- Markdown documentation (*.md)
- SQL schema files (*.sql)
- JSON workflow files (*.json)
- JSON snapshots (*.snapshot.json)
- .gitignore file
- README files

### ❌ Never Commit

- Credentials files (`*credentials*`, `*secrets*`)
- .env files (`.env`, `.env.*`)
- Binary Office docs (`.docx`, `.xlsx`, `.pptx`)
- Archive folders (`Archive/`, `Archived/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- Editor configs (`.vscode/`, `.idea/`)

### ⚠️ Conditional Commit

- Temporary test files (commit only if needed for documentation)
- Personal notes (avoid committing unless intentional)
- Work-in-progress drafts (commit with clear WIP marker)

---

## Branch Strategy

### Main Branch

- **Purpose**: Stable, production-ready code
- **Protection**: Only merge after KGB tests pass
- **Commits**: Must be well-formed and documented

### Feature Branches (Optional)

For major features:

```bash
git checkout -b feature/tree-management-pack
# Work on feature
git add .
git commit -m "Add tree management pack"
git push origin feature/tree-management-pack
# Create PR on GitHub
# Merge to main after review
```

### No Development Branch

**Simplification**: For Kernel v1, work directly on `main` branch.

Rationale:
- Single developer (Master Joel + Claude Code)
- Fast iteration cycle
- Governance docs prevent breaking changes

---

## Sync Discipline

### Daily End-of-Work Snapshot

At end of each work session:

1. Review all changes: `git status`
2. Stage intentional changes: `git add <files>`
3. Commit with descriptive message
4. Push to GitHub: `git push origin main`

**Why**: Ensures GitHub mirror is up-to-date for collaboration and backup.

### After Completing a Leaf

After marking a Build Tree leaf as DONE:

1. Commit changes related to that leaf
2. Include leaf number in commit message
3. Push to GitHub

**Example**:
```bash
git commit -m "$(cat <<'EOF'
Complete Leaf 1: Create root artifact in Qwrk

Executed manual SQL to create root node for Build Tree.
Root artifact verified in Supabase.

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
git push origin main
```

### After Locking a Governance Document

When a governance document reaches LOCKED status:

1. Commit the locked document
2. Update version in commit message
3. Push to GitHub
4. Tag release (optional)

**Example**:
```bash
git commit -m "Lock Mutability Registry v1"
git tag -a mutability-registry-v1 -m "Mutability Registry v1 locked"
git push origin main --tags
```

---

## GitHub Integration Features

### @claude PR Reviews

When using GitHub PR workflow:

1. Create feature branch
2. Push to GitHub
3. Open Pull Request
4. Comment `@claude review this PR`
5. Claude Code reviews changes and suggests improvements

### Issue → Implementation

When GitHub issue is created:

1. Reference issue number in commit: `Fixes #123`
2. Claude Code can read issue and implement solution
3. Commit references issue for auto-closure

**Example**:
```bash
git commit -m "$(cat <<'EOF'
Add artifact.promote workflow

Implements lifecycle transitions with snapshot creation.
Fixes #42

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Troubleshooting

### Problem: Merge Conflict

**Cause**: GitHub and OneDrive diverged

**Solution**:
```bash
git fetch origin
git status
# Review conflicts
git merge origin/main
# Resolve conflicts manually
git add <resolved-files>
git commit -m "Resolve merge conflict"
git push origin main
```

**Prevention**: Always push after local commits; never edit on GitHub web.

### Problem: Committed Credentials

**Cause**: Accidentally staged credentials file

**Solution (IMMEDIATE)**:
```bash
# Remove from staging
git reset HEAD <credentials-file>

# If already committed (NOT pushed):
git reset --soft HEAD~1
git reset HEAD <credentials-file>
git commit -m "Remove credentials from commit"

# If already pushed (NUCLEAR OPTION):
# Contact GitHub support to purge commit history
# Rotate all credentials immediately
```

**Prevention**: Maintain comprehensive .gitignore; review `git diff` before committing.

### Problem: Binary File Committed

**Cause**: .docx or .xlsx staged by mistake

**Solution**:
```bash
# Remove from staging
git reset HEAD <binary-file>

# Add to .gitignore
echo "*.docx" >> .gitignore
git add .gitignore
git commit -m "Update .gitignore to exclude binary files"
```

**Prevention**: Convert all .docx to Markdown before committing.

---

## Best Practices

### 1. Review Before Commit

Always run before committing:
```bash
git status
git diff
```

Ask yourself:
- Are these changes intentional?
- Do commit messages explain WHY, not just WHAT?
- Are there any credentials or secrets?

### 2. Atomic Commits

Each commit should represent ONE logical change:

✅ Good:
- "Add TreeNode schema documentation"
- "Create Build Tree execution runbook"
- "Lock Mutability Registry v1"

❌ Bad:
- "Add lots of files and update stuff"
- "Work from today"

### 3. Commit Messages Tell a Story

Future you (or Claude Code) should be able to read commit history and understand:
- What was built
- Why it was built
- When it was locked
- What changed between versions

### 4. Use Tags for Milestones

Tag important milestones:
```bash
git tag -a kernel-v1-complete -m "Kernel v1 schema and workflows complete"
git push origin --tags
```

### 5. Keep .gitignore Updated

When you discover a new file type that shouldn't be committed:
```bash
echo "<pattern>" >> .gitignore
git add .gitignore
git commit -m "Update .gitignore to exclude <pattern>"
```

---

## Governance Compliance

### CLAUDE.md Integration

This runbook complies with `docs/governance/CLAUDE.md` rules:

- ✅ No file overwrites (versioned clones for edits)
- ✅ Pre-commit review (git diff before commit)
- ✅ Changelog in commit messages
- ✅ Truth hierarchy respected (governance docs locked)

### Mutability Registry Compliance

- ✅ Locked governance docs are not edited (only versioned)
- ✅ Schema files are version-controlled
- ✅ Workflows use version numbers in filenames

---

## References

- [CLAUDE.md](../../governance/CLAUDE.md) - AI collaboration governance
- [Main README](../../../README.md) - Repository overview
- [Build Tree Documentation](../tree/Build_Tree__Save_Query_List__v1.md)
- [How to Execute Leaves](Runbook__How_to_Execute_Leaves__v1.md)

---

**Version**: v1
**Status**: Active
**Last Updated**: 2026-01-02
