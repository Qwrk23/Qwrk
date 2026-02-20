# Final CC Instructions — Tier A Memory Compaction (Protected Core Model)

## Objective
Implement Tier A rolling memory compaction with a two-layer governance model that preserves invariant rules while safely rotating tactical context. The system must prevent loss of foundational governance while maintaining a bounded active memory window.

"Done" means:
- Compaction runs deterministically when trigger conditions are met
- Protected Core entries are never removed
- Rotating Shell entries are compacted safely and auditable
- All decisions below are encoded explicitly in logic and schema

---

## Non-Negotiable Constraints
- Never compact or mutate Protected Core entries
- Never invent or infer identifiers during compaction
- Compaction is destructive → must be auditable
- Favor clarity and determinism over clever inference

---

## Model Overview

Tier A memory is split into two layers:

1. **Protected Core**
   - Foundational governance and execution invariants
   - NEVER eligible for compaction

2. **Rotating Shell**
   - Tactical, contextual, or transitional rules
   - Eligible for compaction under defined rules

Target window:
- Trigger when total Tier A entries >= 50
- Compact Rotating Shell down to target of 35 total entries
- Protected Core may exceed target without compaction

---

## Schema / Metadata Decisions

### Compaction Eligibility
- Add optional field: `compaction_eligible: boolean`
- Precedence rules:
  1. If `compaction_eligible` is present → use it
  2. If absent → infer eligibility from `priority` + `scope`

Inference fallback (only when field absent):
- `priority = critical` AND `scope = global` → NOT eligible
- All others → eligible

No hard requirement to backfill legacy entries.

---

## Compaction Algorithm (Authoritative)

1. Partition Tier A entries into:
   - Protected Core
   - Rotating Shell

2. If total entries < trigger threshold → exit (no-op)

3. If compaction required:
   - Protected Core entries are locked and excluded
   - Sort Rotating Shell by:
     a. Priority (lowest first)
     b. Age (oldest first)

4. Remove entries from Rotating Shell until:
   - Total Tier A entries <= target OR
   - Rotating Shell is exhausted

5. Removed entries are archived to Section C as index-only references

6. Protected Core entries are never removed, even if count exceeds target

---

## Failure / Edge Handling

- If Protected Core alone exceeds target:
  - Allow overflow
  - Emit governance alert
  - Do NOT halt compaction or auto-raise ceilings

---

## Supersession Handling

When creating a new Tier A entry:
- If overlap detected (scope + tags):
  - Prompt user: does this supersede an existing entry?

If confirmed:
- Mark older entry with `superseded_by: [artifact_id]`

No auto-supersession without confirmation.

---

## Thrashing Detection

Detect oscillation when:
- An entry type is compacted
- Same type is recreated within **5 sessions**

Notes:
- Session boundaries may be inferred from restart artifacts
- Thrashing raises a governance alert only
- No automatic blocking or mutation

---

## Audit & Snapshot Requirements

Every compaction event MUST create a snapshot artifact containing:
- Timestamp
- Trigger reason
- List of removed artifact_ids
- List of retained artifact_ids

Tags (recommended):
- `memory-compaction`
- `for-q`

Snapshot payload may be minimal but must be complete.

---

## Protected Core Classification (Locked)

Treat the following entries as Protected Core:

1. Qwrk Naming and Identity Lock
2. Phase 1 Lock – Kernel v1 Governance
3. Production Implies Tree
4. System Instructions – Read Access Only
5. North Star v0.4 – Execution Anatomy
6. Chrome Extension Raw JSON Invariant
7. Governance / Execution Milestones

Treat the following as Rotating Shell:

- Memory Load vs Addressable Registry
- Snapshots at Sapling-to-Tree Transition
- T15 Completion Milestone

---

## Explicit Non-Goals
- No auto-merging of Protected Core entries
- No background or silent compaction
- No mutation of Tier B or registry-only memory

---

## Execution Instruction

Proceed to implement Tier A compaction exactly as specified.
If any ambiguity or missing data blocks implementation, STOP and ask before coding.