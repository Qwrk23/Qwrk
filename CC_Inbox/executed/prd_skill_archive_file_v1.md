# PRD: /archive-file — Pattern C Archive-Based Versioning Skill

> **Date:** 2026-03-09
> **Parent:** `CC_Inbox/prd_cc_skills_suite_v1__pre_planning.md`
> **Source Governance:** CLAUDE.md §3 (Absolute No-Overwrite Rule), §4 (Pre-Write Confirmation Gate), §5 (Changelog Requirement)

---

## Intent

Codify CLAUDE.md Pattern C (Archive-based versioning) into a deterministic skill that CC follows every time a file needs to be updated. Eliminates:

- **Forgotten steps** — CC skips Archive/ creation, version suffix, or changelog
- **Wrong naming** — CC uses inconsistent date formats or version numbering
- **Missing confirmation gate** — CC starts writing before listing what it will touch
- **Pattern confusion** — CC uses Pattern A or B when C is the default

This skill does NOT change any governance rules. It packages the existing rules into an executable checklist.

---

## Non-Goals

- Does NOT handle file creation (only versioned updates to existing files)
- Does NOT auto-detect version numbers from file content (asks user if ambiguous)
- Does NOT modify CLAUDE.md or any governance surface
- Does NOT apply to `.claude/commands/` skill files (those are lightweight, no archive needed)
- Does NOT auto-commit to git

---

## Trigger

User invokes `/archive-file` or CC recognizes it needs to update an existing file and self-invokes the pattern.

**Arguments (optional):** File path to archive. If not provided, CC asks.

---

## Prerequisites

1. The target file must already exist (this is an update, not a creation)
2. CC must have read the target file at least once in the current conversation
3. The user must have described what changes are needed

---

## Step Sequence

### Step 1: Identify Target File

If the user provided a file path, use it. Otherwise ask:
> "Which file are you updating?"

Read the file to understand its current content.

### Step 2: Determine Current Version

Extract the current version number using this precedence:

1. **CHANGELOG section** in the file (look for latest `### vN` entry) — PREFERRED
2. **Filename contains version** (e.g., `Schema_Reference__Kernel_v1__v2.9.md` → v2.9)
3. **Ask the user** if neither source exists:
   > "I can't determine the current version. What version number is this file currently at?"

Compute `NEXT_VERSION` = current version + 0.1 (for minor) or + 1 (for major, if user specifies).

### Step 3: Choose Pattern

Default to **Pattern C** unless the user explicitly requests otherwise.

**Decision tree:**
- Pattern C (DEFAULT): Archive/ subfolder, canonical filename preserved
- Pattern A: Both versions in main folder (user must request "side-by-side")
- Pattern B: Rename in place without Archive/ (user must request explicitly)

If the user hasn't specified, proceed with Pattern C silently.

### Step 4: Pre-Write Confirmation Gate (MANDATORY)

**Before touching ANY file**, output exactly this:

```
📋 Archive Plan (Pattern C):

FILES TO MOVE:
  [current path] → [same dir]/Archive/[filename]__v[CURRENT_VERSION]__[TODAY_DATE].[ext]

FILES TO CREATE:
  [current path] (new version v[NEXT_VERSION])

Archive/ directory: [EXISTS | WILL BE CREATED]

Pattern: C (Archive-based versioning)
```

Then WAIT for explicit user approval. Do NOT proceed without it.

### Step 5: Execute Archive

Once approved:

1. **Create `Archive/` directory** in the target file's parent directory (if it doesn't exist)
2. **Move current file** to `Archive/` with naming format:
   ```
   Archive/<filename>__v<CURRENT_VERSION>__<YYYY-MM-DD>.<ext>
   ```
   - Use `git mv` if the file is tracked by git
   - Use regular `mv` if untracked
3. **Write new file** at the original canonical path with:
   - Updated content (the changes the user requested)
   - Updated CHANGELOG (see Step 6)
   - Same filename (no version suffix in canonical name)

### Step 6: Update Changelog

The new file MUST include a CHANGELOG entry. Format:

```markdown
### v[NEXT_VERSION] - [YYYY-MM-DD]
**What changed:** [1-2 sentence summary]

**Why:** [Reason for the change]

**Scope of impact:** [What other files/systems are affected]

**How to validate:** [How to verify the change is correct]

**Previous version:** `Archive/[filename]__v[CURRENT_VERSION]__[YYYY-MM-DD].[ext]`
```

**Rules:**
- Archived file preserves its original CHANGELOG intact (do not modify it)
- New file adds the new entry at the TOP of the CHANGELOG section
- The `Previous version` line MUST reference the exact archived filename

### Step 7: Confirm Completion

After all files are written, output:

```
✅ Archive complete:
  Archived: Archive/[filename]__v[CURRENT_VERSION]__[DATE].[ext]
  Updated:  [canonical filename] (now v[NEXT_VERSION])
  Changelog: Updated with v[NEXT_VERSION] entry
```

---

## Decision Points

| Situation | CC Action |
|-----------|-----------|
| Can't determine current version | ASK user |
| User wants Pattern A or B | Follow their instruction, skip Archive/ |
| File has no CHANGELOG section | Add one (don't skip) |
| Archive/ already exists | Use it (don't recreate) |
| File is in a directory with spaces | Use bash commands with quoted paths |
| User hasn't approved the archive plan | WAIT — do not proceed |

---

## Output Format

Two outputs during execution:
1. **Pre-write confirmation** (Step 4) — must be approved before proceeding
2. **Completion summary** (Step 7) — confirms all files written

---

## Error Handling

| Error | Response |
|-------|----------|
| Target file doesn't exist | "This file doesn't exist. `/archive-file` is for updating existing files. Use Write tool for new files." |
| `git mv` fails | Fall back to regular `mv` + `git add` |
| Archive/ directory creation fails (permissions) | Report error, ask user to create manually |
| OneDrive EEXIST bug on Write/Edit | Use bash heredoc or bash `cat >` for file creation |

---

## Acceptance Criteria

1. After running `/archive-file`, the original file is in `Archive/` with correct version suffix
2. The canonical filename is unchanged (no version number in active file)
3. The new file has a CHANGELOG entry referencing the archived version
4. The archived file is unmodified (original content + original changelog preserved)
5. No file was written before the pre-write confirmation gate was approved
6. `Archive/` directory exists in the target file's parent directory

---

## Examples

### Example 1: Schema Reference Update

```
User: Update the Schema Reference to v3.0

CC runs /archive-file:

📋 Archive Plan (Pattern C):

FILES TO MOVE:
  docs/schema/Schema_Reference__Kernel_v1__v2.9.md
  → docs/schema/Archive/Schema_Reference__Kernel_v1__v2.9__v2.9__2026-03-09.md

FILES TO CREATE:
  docs/schema/Schema_Reference__Kernel_v1__v2.9.md (new version v3.0)

Archive/ directory: EXISTS

Pattern: C (Archive-based versioning)

[User approves]

✅ Archive complete:
  Archived: Archive/Schema_Reference__Kernel_v1__v2.9__v2.9__2026-03-09.md
  Updated:  Schema_Reference__Kernel_v1__v2.9.md (now v3.0)
  Changelog: Updated with v3.0 entry
```

### Example 2: CLAUDE.md Update

```
User: Add new section to CLAUDE.md (currently v22)

📋 Archive Plan (Pattern C):

FILES TO MOVE:
  CLAUDE.md → Archive/CLAUDE__v22__2026-03-09.md

FILES TO CREATE:
  CLAUDE.md (new version v23)

Archive/ directory: EXISTS

Pattern: C (Archive-based versioning)
```

---

## CHANGELOG

| Date | Entry |
|------|-------|
| 2026-03-09 | Initial PRD created |
