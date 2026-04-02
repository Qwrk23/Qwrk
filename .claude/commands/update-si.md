Update any Qwrk system-instruction head (Q-Prime, Q@W, Akara, BlaggLife, Greg, or template).

Source: CLAUDE.md §3, §4, §5, §7.5 — last synced 2026-03-25
Anti-drift formula locked: 2026-03-25

## Context

Qwrk System Instructions (SI) are uploaded to ChatGPT as project files. They have an **8,000 character hard limit**. Every SI head is a routing document that points to instruction packs — not a place to inline full protocols.

**Scope:** This skill governs ALL Qwrk heads, not just Q-Prime.

| Head | Location |
|------|----------|
| **Q-Prime** | `phase1.5-chat-gateway/Chat Project Files/Qwrk_SYSTEM_INSTRUCTIONS_2_5_*.md` |
| **Template** | `Multi-User Qwrk/03_ChatGPT_Projects/SYSTEM_INSTRUCTIONS_TEMPLATE.md` |
| **Q@W / Akara / BlaggLife / Greg** | Workspace-specific folders under `Multi-User Qwrk/03_ChatGPT_Projects/` |

## Head Content Formula (What Belongs in a Head)

A Qwrk head may contain ONLY these three categories:

**1. Identity** — Who the system is, its role, stable posture/tone, governing stance.

**2. Hard Invariants** — Rules that MUST always be in-context because failure-to-retrieve is catastrophic. Test: "What happens if Q doesn't have this loaded?" If the answer is "Q looks it up in a pack" → it's routing, not an invariant.

**3. Routing Pointers** — Version-agnostic references to supporting docs via `Instruction_Pack_Index.md`. Maximum 2-4 lines: one-sentence summary + index lookup reference.

**Everything else is REJECTED** — field tables, JSON examples, extension schemas, registries, decision trees, numbered protocols, error posture, state bundles. These belong in instruction packs.

### Anti-Drift Gate

Before adding ANY content to a head, CC MUST classify it:

1. Is this identity? → Keep in head
2. Is this a hard invariant? → Keep in head (with justification)
3. Is this a routing pointer? → Keep in head (version-agnostic only)
4. Is this operational detail? → **REJECT** — extract to the appropriate pack, add routing pointer only

### Version-Agnostic Routing Rule

Heads MUST route through `Instruction_Pack_Index.md` rather than naming versioned filenames directly. No version-pinned pack or reference filenames in heads unless truly unavoidable. If an exception is ever required, it must be explicitly justified in the completion output.

- **Correct:** "See the active Payload Discipline pack in `Instruction_Pack_Index.md`"
- **Wrong:** "See `Instruction_Pack__Payload_Discipline__v3.md`"

### Archive Rule

When a Qwrk head is rewritten, use the established archive-then-write pattern already used elsewhere in Qwrk governance (Pattern C).

## Hard Rules

1. **8k character ceiling.** After edits, the SI MUST be under 8,000 characters. Measure with `wc -c`. If the edit would exceed 8k, stop and report — do not write. Near limit (7,500-8,000): compress by extracting operational detail to packs BEFORE removing behavior. Never hollow out identity or hard invariant sections to save space.
2. **Pointer pattern only.** New capabilities get a 2-4 line section: one-sentence summary + file reference. Never inline full protocols, tables, numbered step lists, or state bundles into the SI. Those belong in the instruction pack.
3. **Follow existing patterns.** Look at how CmdCtr, Messaging, Discovery, and QPM are referenced — brief description + `See <filename>`. Match that density.
4. **No section may exceed 5 lines** (excluding the heading). If your draft section is longer, it's too detailed — move the detail to the instruction pack.
5. **Instruction pack count and category list must be updated** if a new pack is being added.
6. **Archive previous SI version** using Pattern C before writing the new one.
7. **Version-agnostic pointers only.** Do not embed versioned filenames in heads. Route through `Instruction_Pack_Index.md`.

## Instructions

### Step 1: Identify What's Being Added

If not clear from the user's message, ask:
> "What capability or instruction pack are you adding to the SI?"

Determine:
- The section name (e.g., "Beta User Onboarding Protocol")
- The instruction pack filename it points to
- Where it should be inserted (between which existing sections)

### Step 2: Read Current SI

Find and read the latest SI file:
```
phase1.5-chat-gateway/Chat Project Files/Qwrk_SYSTEM_INSTRUCTIONS_2_5_*.md
```

Note the current version number (from filename suffix) and character count.

### Step 3: Classify and Draft

**Before drafting, run the Anti-Drift Gate on every line of new content:**

For each piece of content being added, ask:
1. Identity? → OK for head
2. Hard invariant? → OK for head (note justification)
3. Routing pointer? → OK for head (must be version-agnostic — route via `Instruction_Pack_Index.md`)
4. Operational detail? → **REJECT** — move to instruction pack, add routing pointer only

Then write a **pointer-only** section following this template:

```markdown
## [Section Name]

[1-2 sentence summary of what this capability does and when it activates.]

See the active [pack name] in `Instruction_Pack_Index.md`.
```

Maximum: heading + 3-4 lines of text + index lookup reference. That's it.

**Anti-patterns (NEVER do these):**
- Inline numbered step lists (e.g., "1. Do X  2. Do Y  3. Do Z")
- Tables (state bundles, field definitions, rules)
- Sub-headings (###) within the new section
- Duplicating content that exists in the instruction pack
- Adding "Rules" sections (provisioning rules, onboarding rules, etc.)
- Version-pinned filenames (e.g., `Instruction_Pack__Foo__v3.md`) — route through Index

### Step 4: Size Check

Calculate: `current_chars + new_section_chars`

| Result | Action |
|--------|--------|
| Under 7,500 | Proceed — comfortable headroom |
| 7,500–8,000 | Proceed with warning — near limit |
| Over 8,000 | STOP — trim the section or suggest moving existing content to an IP |

Report the projected size to the user before proceeding.

### Step 5: Pre-Write Confirmation Gate

Output:
```
SI Update Plan:

CURRENT FILE: Qwrk_SYSTEM_INSTRUCTIONS_2_5_[N].md ([X] chars)
NEW VERSION:  Qwrk_SYSTEM_INSTRUCTIONS_2_5_[N+1].md ([Y] chars projected)

SECTION ADDED: [Section Name] (between [Before] and [After])
CONTENT:
  [Show the exact 2-4 lines that will be inserted]

IP COUNT: [old] → [new] (if changed)
ARCHIVE: Qwrk_SYSTEM_INSTRUCTIONS_2_5_[N].md → Archive/

Projected size: [Y] / 8,000 chars ([Z]% used)
```

WAIT for approval.

### Step 6: Execute

1. Archive current SI using Pattern C (use /archive-file skill or manual archive)
2. Write new SI file with incremented version suffix
3. Update the Instruction Packs count/category line if a new pack was added
4. Verify final character count with `wc -c`
5. Report final size

### Step 7: Remind About Uploads

After completion, remind the user:
> "Upload the new SI to the ChatGPT project (replaces the previous version)."

If an instruction pack or IP Index was also modified, list all files that need uploading.

## Also Update IP Index If Needed

If a new instruction pack is being pointed to, check `Instruction_Pack_Index.md` and add the entry if missing. This is a separate file edit — confirm with the user.

## Preflight Checklist (MANDATORY — Print Before Any Head Write)

CC MUST print this checklist to the console and confirm every item before writing any Qwrk head:

```
=== QWRK HEAD UPDATE PREFLIGHT ===
[ ] HEAD SCOPE: Which head? (Prime / Template / Q@W / Akara / BlaggLife / Greg)
[ ] CONTENT CLASSIFICATION: Every added line is Identity, Hard Invariant, or Routing — no operational detail
[ ] OPERATIONAL DETAIL EXTRACTED: Any rejected content moved to correct instruction pack
[ ] NO DUPLICATED AUTHORITY: Head does not repeat what a pack already says
[ ] VERSION-AGNOSTIC ROUTING: All pointers use Instruction_Pack_Index.md, no versioned filenames
[ ] CHARACTER COUNT: _____ / 8,000 (under limit confirmed)
[ ] ARCHIVE EXISTS: Prior version archived via Pattern C
[ ] SUPPORTING DOCS UPDATED: IP Index and/or packs updated if needed
[ ] IP COUNT CORRECT: Instruction pack count in head matches IP Index
===============================
```

Do NOT skip this checklist. Do NOT write the head if any item fails.

## NEVER DO

- Never inline more than 4 lines of content into an SI section
- Never exceed 8,000 characters
- Never skip the size check or preflight checklist
- Never skip the archive step
- Never add sub-headings (###) inside a new SI section
- Never duplicate instruction pack content in the SI
- Never embed version-pinned filenames in a head — route through `Instruction_Pack_Index.md`
- Never add operational detail to a head without running the Anti-Drift Gate first
