Archive an existing file using Pattern C (Archive-based versioning).

Source: CLAUDE.md §3, §4, §5 — last synced 2026-03-10

## Instructions

This skill enforces the **Absolute No-Overwrite Rule** from CLAUDE.md. Every file update follows Pattern C unless the user explicitly requests Pattern A or B.

### Step 1: Identify Target File

If the user provided a file path, use it. Otherwise ask:
> "Which file are you updating?"

Read the file to understand its current content.

### Step 2: Determine Current Version

Extract the current version using this precedence:

1. **CHANGELOG section** in the file — look for latest `### vN` entry (PREFERRED)
2. **Filename contains version** — e.g., `Schema_Reference__Kernel_v1__v2.9.md` → v2.9
3. **Ask the user** if neither source exists:
   > "I can't determine the current version. What version number is this file currently at?"

Compute `NEXT_VERSION` = current + 0.1 (minor) or + 1 (major, if user specifies).

### Step 3: Choose Pattern

Default: **Pattern C** (Archive-based). Only deviate if user explicitly requests:
- **Pattern A** ("side-by-side") — both versions in main folder
- **Pattern B** ("rename in place") — no Archive/ subfolder

Proceed with Pattern C silently unless told otherwise.

### Step 4: Pre-Write Confirmation Gate (MANDATORY)

**Before touching ANY file**, output exactly this:

```
Archive Plan (Pattern C):

FILES TO MOVE:
  [current path] → [dir]/Archive/[filename]__v[CURRENT]__[DATE].[ext]

FILES TO CREATE:
  [current path] (new version v[NEXT])

Archive/ directory: [EXISTS | WILL BE CREATED]
```

Then WAIT for explicit user approval. Do NOT proceed without it.

### Step 5: Execute Archive

Once approved:

1. Create `Archive/` directory in the target file's parent (if it doesn't exist)
2. Move current file to Archive:
   - Format: `Archive/<filename>__v<CURRENT_VERSION>__<YYYY-MM-DD>.<ext>`
   - Use `git mv` if tracked, regular `mv` if untracked
3. Write new file at the original canonical path with updated content + changelog

### Step 6: Update Changelog

The new file MUST include a CHANGELOG entry at the TOP of the CHANGELOG section:

```markdown
### v[NEXT] - [YYYY-MM-DD]
**What changed:** [1-2 sentence summary]

**Why:** [Reason for the change]

**Scope of impact:** [What other files/systems are affected]

**How to validate:** [How to verify the change is correct]

**Previous version:** `Archive/[filename]__v[CURRENT]__[YYYY-MM-DD].[ext]`
```

Rules:
- Archived file preserves its original CHANGELOG intact (do not modify it)
- New file adds entry at TOP of CHANGELOG
- `Previous version` line MUST reference the exact archived filename

### Step 7: Confirm Completion

Output:
```
Archive complete:
  Archived: Archive/[filename]__v[CURRENT]__[DATE].[ext]
  Updated:  [canonical filename] (now v[NEXT])
  Changelog: Updated with v[NEXT] entry
```

## Decision Points

| Situation | Action |
|-----------|--------|
| Can't determine version | ASK user |
| User wants Pattern A or B | Follow their instruction |
| File has no CHANGELOG section | Add one |
| Archive/ already exists | Use it (don't recreate) |
| Paths with spaces (OneDrive) | Use bash with quoted paths |
| User hasn't approved archive plan | WAIT — do not proceed |

## NEVER DO

- Never overwrite a file without archiving the previous version first
- Never skip the Pre-Write Confirmation Gate (Step 4)
- Never modify the archived copy after moving it
- Never put a version suffix in the canonical filename (that's Pattern A)
- Never apply this to `.claude/commands/` skill files (they're lightweight, no archive needed)
