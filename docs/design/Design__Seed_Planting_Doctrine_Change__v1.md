# Plan: Seed Planting Doctrine Change — Direct Seed vs. Journal-First

## Context

Joel wants to change the seed planting doctrine. The current docs prescribe a **journal-first** pattern for ALL seed creation — save a companion journal, get its artifact_id, then save the seed project linked to it. This is wrong when Joel **already knows** he wants a seed. The journal-first pattern should only apply when he's **thinking through an idea** and doesn't yet know if it will become a seed.

**New doctrine (two modes):**
1. **Direct Seed** — Joel knows he wants a seed → create the project directly. Companion journal is optional, not required.
2. **Exploratory Capture** — Joel is thinking through an idea → journal first. If it crystallizes into something seed-worthy, THEN create a seed (optionally linked).

---

## Affected Files — Complete Inventory

### Tier 1: Canonical Doctrine (Primary authority — changes here propagate to Tier 2)

| # | File | Section | Current State | Change Required |
|---|------|---------|---------------|-----------------|
| 1 | `phase1.5-chat-gateway/Chat Project Files/Instruction_Pack__Payload_Discipline__v4.md` | **"Seed Planting Protocol (Project Genesis)"** (lines 84-95) | Journal-first is the ONLY path. "Never create an unlinked seed." Anti-pattern forbids seed-first. | **REWRITE.** Replace single-path protocol with two-mode doctrine. Remove anti-pattern warning (it's about T118 retroactive linking, not about direct seeds). |

### Tier 2: Examples & Quick References (Must align with Tier 1)

| # | File | Section(s) | Current State | Change Required |
|---|------|------------|---------------|-----------------|
| 2 | `phase1.5-chat-gateway/Chat Project Files/PAYLOAD_EXAMPLES.md` | **"With companion journal (Two-Step Pattern — REQUIRED for rich content)"** (lines 64-96) | Labels two-step as "REQUIRED for rich content." Only shows journal-as-companion. | **REWRITE heading + add direct seed example.** Two-step becomes optional, not required. Add a "Direct Seed (single payload)" example BEFORE the two-step example. |
| 3 | `phase1.5-chat-gateway/Chat Project Files/QUICK_REFERENCE.md` | **"Best Practice: Companion Journal Pattern (Strongly Recommended)"** (lines 202-226) AND **"Seed Planting" workflow pattern** (lines 251-266) | Companion journal is "strongly recommended." Seed planting shows "Project + optional companion Journal" (already closer to correct). | **Adjust §202-226** — reframe companion journal as one of two valid patterns, not the strongly-recommended default. **§251-266** is mostly fine (already says "optional") — minor wording tweak to make direct seed the primary path. |

### Tier 3: Workspace Copies (Propagate from Tier 2 canonical)

Each of these mirrors the Prime canonical. Same changes apply:

**PAYLOAD_EXAMPLES.md (4 copies):**
| # | File |
|---|------|
| 4 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/PAYLOAD_EXAMPLES.md` |
| 5 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@BlaggLife/PAYLOAD_EXAMPLES.md` |
| 6 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Akara/Qwrk_Akara_Shared/PAYLOAD_EXAMPLES.md` |
| 7 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Greg/Qwrk_Greg_Shared/PAYLOAD_EXAMPLES.md` |

**QUICK_REFERENCE.md (4 copies):**
| # | File |
|---|------|
| 8 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/QUICK_REFERENCE.md` |
| 9 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@BlaggLife/QUICK_REFERENCE.md` |
| 10 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Akara/Qwrk_Akara_Shared/QUICK_REFERENCE.md` |
| 11 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Greg/Qwrk_Greg_Shared/QUICK_REFERENCE.md` |

**Instruction_Pack__Payload_Discipline__v2.md (4 copies):**
| # | File |
|---|------|
| 12 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Wrk/Instruction_Pack__Payload_Discipline__v2.md` |
| 13 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@BlaggLife/Instruction_Pack__Payload_Discipline__v2.md` |
| 14 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Akara/Qwrk_Akara_Shared/Instruction_Pack__Payload_Discipline__v2.md` |
| 15 | `Multi-User Qwrk/03_ChatGPT_Projects/Qwrk@Greg/Qwrk_Greg_Shared/Instruction_Pack__Payload_Discipline__v2.md` |

### NOT Changed (no action needed)

| File | Reason |
|------|--------|
| System Instructions (all 5 SIs) | No seed planting protocol — just role labels ("Seed Capture") and type routing. Unaffected. |
| LIFECYCLE_GUIDE.md (all copies) | Describes lifecycle stages, not seed creation workflow. Unaffected. |
| QPM_Build_Process__v1.md | References Mother Tree parent routing for seeds, not journal-first. Already correct. |
| Artifact_Discovery_Playbook__v1.md | Mentions "companion journals" as a retrieval example. Read-only pattern — doesn't prescribe creation. Unaffected. |
| CLAUDE.md | No seed planting doctrine. Unaffected. |

---

## Execution Order

1. **Edit #1 (Payload Discipline v4)** — rewrite Seed Planting Protocol section
2. **Edit #2 (PAYLOAD_EXAMPLES.md, Prime)** — add direct seed example, reframe two-step
3. **Edit #3 (QUICK_REFERENCE.md, Prime)** — adjust companion journal section + seed planting pattern
4. **Propagate #1-3 to 4 workspace copies** (12 files total)

All edits use Pattern C (archive current → write new).

---

## Prompt to Manus

See below — this is the deliverable Joel will send to Manus for review.

---

# Manus Review Request: Seed Planting Doctrine Change

## Goal

We're changing the Seed Planting Protocol across all Qwrk instruction packs. The current doctrine forces a **journal-first** pattern for every seed creation. Joel wants a **two-mode** doctrine instead:

**Mode 1 — Direct Seed (new default):** When Joel knows he wants a seed, Q creates the project directly. Single payload. No companion journal required. This is the fast, clean path.

**Mode 2 — Exploratory Capture (journal-first):** When Joel is thinking through an idea and doesn't yet know if it will become a seed, Q captures it as a journal first. If the thinking crystallizes into something seed-worthy, Q then creates a seed project — optionally linked to that journal via `parent_artifact_id`.

**The key shift:** The companion journal pattern is demoted from "required/strongly recommended" to "one of two valid patterns, used when thinking precedes commitment." Direct seed becomes the primary path.

## What's Changing — Exact Sections

### File 1: `Instruction_Pack__Payload_Discipline__v4.md` (Canonical — Prime)
**Section:** "Seed Planting Protocol (Project Genesis)" (lines 84-95)

**CURRENT TEXT:**
```markdown
## Seed Planting Protocol (Project Genesis)

When creating a new project seed with companion context:

1. Save the companion journal FIRST (captures thinking/rationale)
2. Retrieve the journal's `artifact_id` from the Gateway response
3. Save the seed project with `parent_artifact_id` set to the journal's `artifact_id`

The seed is born linked to its context. **Never create an unlinked seed and attempt post-hoc topology repair** — the relationship must be present at creation time.

**Anti-pattern:** Save seed → save journal → try to link after. This fails because the Gateway does not support retroactive `parent_artifact_id` assignment via update (pending T118).
```

**PROPOSED REPLACEMENT:**
```markdown
## Seed Planting Protocol (Project Genesis)

Two valid paths for creating a seed. Choose based on intent clarity.

### Direct Seed (default when intent is clear)

When you know you want a seed, create the project directly — single payload, no journal required.

The seed registers the initiative. A companion journal can be added later if rich context is needed.

### Exploratory Capture (when thinking precedes commitment)

When capturing thinking that may or may not become a seed:

1. Save the journal FIRST (captures thinking/rationale)
2. If the thinking crystallizes into a seed: save the project with `parent_artifact_id` set to the journal's `artifact_id`

This is the correct path when you're journaling through an idea and it evolves into something worth tracking as a project.

**Technical constraint:** The Gateway does not support retroactive `parent_artifact_id` assignment via update (pending T118). If you know at journal-creation time that a seed will follow, the journal → seed order preserves the link. If not, the seed can exist unlinked — the journal is still discoverable by tags and title.
```

### File 2: `PAYLOAD_EXAMPLES.md` (Prime + 4 workspace copies)
**Section:** "With companion journal (Two-Step Pattern — REQUIRED for rich content)" (lines 64-96)

**CURRENT:** Labels two-step as "REQUIRED for rich content." Only shows seed → journal companion.

**PROPOSED CHANGE:**
- **Rename heading** from "With companion journal (Two-Step Pattern — REQUIRED for rich content)" → "With companion journal (Two-Step Pattern — optional for rich content)"
- **Add "Direct Seed (Single Payload)" example** ABOVE the two-step example, showing a seed project save with a meaningful `summary` on the extension — demonstrating that a seed can carry its own context without a journal
- **Change "Why two steps"** line from "Projects track lifecycle (seed -> sapling -> tree). The companion journal holds the actual content." → "Projects track lifecycle (seed -> sapling -> tree). A companion journal is useful when rich exploratory context preceded the decision to create a seed."

### File 3: `QUICK_REFERENCE.md` (Prime + 4 workspace copies)
**Section 1:** "Best Practice: Companion Journal Pattern (Strongly Recommended)" (lines 202-226)

**PROPOSED CHANGE:**
- **Rename heading** from "Best Practice: Companion Journal Pattern (Strongly Recommended)" → "Companion Journal Pattern (When Exploratory Context Exists)"
- **Add framing text** before Step 1: "Use this pattern when a journal captured exploratory thinking BEFORE you decided to create a seed. For direct seeds where intent is already clear, skip to the single-payload seed save — no companion journal needed."
- Keep the two-step example intact (it's still valid for the exploratory path)

**Section 2:** "Seed Planting" workflow pattern (lines 251-266)

**PROPOSED CHANGE:**
- Change trigger from "New idea, project concept, or direction worth tracking" → "New initiative, project concept, or direction Joel wants to track as a seed"
- Change "Artifacts: Project + optional companion Journal" → "Artifact: Project (primary). Optional companion Journal only if exploratory thinking was captured first."
- Keep the companion journal sub-section but add "(only when pre-existing thinking needs linking)" after its heading

## What's NOT Changing

| Item | Reason |
|------|--------|
| System Instructions (all 5 heads) | No seed planting workflow — just role labels. Unaffected. |
| LIFECYCLE_GUIDE.md | Describes stages, not creation workflow. Unaffected. |
| QPM Build Process | Already uses Mother Tree parent routing, not journal-first. Correct as-is. |
| Artifact Discovery Playbook | Read-only retrieval patterns — doesn't prescribe creation. Unaffected. |
| Gateway contract / DDL | No schema or API changes. Pure documentation/behavioral change. |

## Propagation Scope

The Prime canonical files (Payload Discipline v4, PAYLOAD_EXAMPLES.md, QUICK_REFERENCE.md) are the authority. Four workspace copies must receive identical changes:
- Q@W (Work/Resolve)
- BlaggLife
- Akara
- Greg

**Total files touched:** 15 (3 canonical × 5 workspaces)

## Review Questions for Manus

1. **Does the two-mode framing (Direct Seed vs. Exploratory Capture) correctly reflect the intent?** The distinction is: "I know this is a seed" vs. "I'm thinking and it might become one."

2. **Is the technical constraint note about T118 (no retroactive parent_artifact_id) correctly positioned?** It explains WHY journal-first order matters when you DO want linking — but doesn't make linking mandatory.

3. **Is the "NOT changing" list complete?** We want to confirm no other instruction surfaces prescribe journal-first seed creation that we missed.

4. **Does the Companion Journal Pattern rename (from "Strongly Recommended" → "When Exploratory Context Exists") correctly signal the demotion without discouraging legitimate use?**

---

## Verification

After implementation:
- Grep for "companion journal" across all active instruction packs — confirm no language implies it's required for seed creation
- Grep for "REQUIRED for rich content" — confirm zero matches (old heading removed)
- Grep for "Never create an unlinked seed" — confirm zero matches (old anti-pattern removed)
- Confirm all 5 workspace Payload Discipline files have the two-mode protocol
- Confirm all 5 workspace PAYLOAD_EXAMPLES files show direct seed as first example
- Confirm all 5 workspace QUICK_REFERENCE files have updated headings
