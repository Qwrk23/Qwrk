# CC Prompt — Tier A Rolling Memory Compaction (Deterministic Execution)

## Outcome
Perform a controlled structural compaction of the Tier A Rolling Memory file to reduce total entries from 64 to **≤ 45** while preserving all governance meaning and invariants.

Success criteria:
1. Protected Core (8 entries) remains unchanged.
2. No governance invariant is weakened, removed, or reinterpreted.
3. Rotating Shell entries are consolidated into canonical doctrine entries.
4. A clear mapping table shows which artifact_ids were merged into which new canonical entries.
5. The final Tier A count is ≤ 45.
6. No runtime behavior, schema, or lifecycle semantics are altered.

Non-goals:
- No schema edits
- No Gateway contract changes
- No lifecycle stage modifications
- No new artifact types
- No deletion of Protected Core

---

## Context
Pre-compaction state has been snapshotted.
Tier A = 64 entries
Protected Core = 8
Rotating Shell = 56

Compaction target: ≤ 45 total Tier A entries.

Reference file to modify:
Qwrk_Rolling_Memory__for-q__2026-02-21.md

---

# Execution Plan (Must Follow Sequentially)

## Phase 1 — Cluster Identification (No Edits Yet)

Identify Rotating Shell entries belonging to these clusters:

### Cluster A — Platform / Product / Prime Architecture Doctrine
Includes entries related to:
- Qwrk as Platform AND Commercial Product
- Qwrk as Foundation, Not Product
- Constellation Architecture
- Prime Naming + ERP Direction
- Platform-Internal / Product-External Boundary

Deliverable:
- List of artifact_ids included in Cluster A


### Cluster B — Phase 2B Walk Governance & Status
Includes entries related to:
- Walk gaps
- Walk clarification
- Unlock Walk
- Walk boundary lock
- Structural alignment sealed
- Phase 2 baseline

Deliverable:
- List of artifact_ids included in Cluster B


### Cluster C — Memory Architecture & Tier Model
Includes entries related to:
- Tier Model Staging Protocol
- Rolling Memory redesign
- Graduation + RAG roles
- Tier A Compaction Protocol
- Memory load vs addressable registry

Deliverable:
- List of artifact_ids included in Cluster C


### Cluster D — Milestone Confirmations
Includes entries that are implementation confirmations (T41, ACL enforcement, type registry expansion, restart architecture, etc.)

Deliverable:
- List of artifact_ids included in Cluster D

Do not edit file yet.
Return cluster lists for confirmation.

---

## Phase 2 — Canonical Consolidation Drafting

After confirmation, create ONE canonical entry per cluster:

### Canonical Entry A
Title:
Governance Doctrine — Qwrk Platform Architecture (Consolidated)

Must preserve:
- Platform vs Product boundary
- Prime ERP authority model
- Constellation structure
- Naming locks
- Control-plane doctrine


### Canonical Entry B
Title:
Phase 2B — Walk Status Canonical Snapshot

Must preserve:
- What Walk enables
- What remains incomplete
- Governance locks
- Open gaps
- Phase boundary doctrine


### Canonical Entry C
Title:
Memory Architecture Doctrine — Tier Model + Graduation + RAG

Must preserve:
- Two-tier model
- Protected Core concept
- Graduation rule
- Compaction protocol
- RAG boundary


### Canonical Entry D
Title:
Milestone Ledger — Phase 1 & Early Phase 2 Confirmations

Must preserve:
- Major system confirmations
- Architectural sealing moments
- Governance hardening

Must remove:
- Redundant per-bug confirmation language
- Duplicate milestone phrasing


Each canonical entry must:
- Be governance-tight
- Avoid duplication
- Avoid runtime ambiguity
- Preserve original intent


---

## Phase 3 — Replacement & Reclassification

1. Insert canonical entries into Section B (Rotating Shell).
2. Move all merged artifact references into Section C (Compacted References).
3. Preserve artifact_id references in an appendix table under each canonical entry.
4. Recalculate Tier A count.
5. Confirm final count ≤ 45.


---

## Enforcement Rules

- Do NOT modify Protected Core section.
- Do NOT edit Section A constraints.
- Do NOT weaken invariants.
- Do NOT introduce interpretation drift.
- Do NOT delete artifact_ids — only move to Compacted Section C.


---

## Required Output Format

Return:
1. Cluster identification table (Phase 1)
2. Draft canonical entries (Phase 2)
3. Final Tier A count after consolidation (Phase 3)
4. Mapping table: Old artifact_id → Canonical Entry
5. Confirmation statement: "Protected Core unchanged."


---

## Critical Guardrail

If any consolidation risks weakening a governance invariant, STOP and flag the risk before proceeding.

Determinism over speed.
Governance over density.

Proceed with Phase 1 only.

