# Snapshot — Video Artifact Type: Repo Truth Alignment Complete

**Date:** 2026-01-04 (CST)  
**Snapshot Type:** Governance  
**Status:** Locked  

---

## Why this snapshot exists

This snapshot captures the completion of a governance decision branch:

- `artifact_type = video` was introduced as a **first-class artifact type** (DDL-backed).
- The typed extension table `qxb_artifact_video` exists and is canonical.
- All repository contracts, architecture docs, and governance references have been updated and aligned.
- A formal version bump was applied where required.

This snapshot exists to prevent future semantic drift and to preserve **intent, scope, and invariants** for future builders and reviewers.

---

## Decisions locked

1. **Video is a first-class artifact type**
   - `video` is not encoded as `journal`.
   - It participates fully in the spine + typed-extension architecture.

2. **Storage model**
   - Spine: `qxb_artifact` (`artifact_type = video`)
   - Extension: `qxb_artifact_video` (PK = FK)
   - Transcripts, segments, metadata, and derived insights live in `qxb_artifact_video.content` (JSONB)

3. **Semantics**
   - Video artifacts represent long-form media (e.g., YouTube).
   - They may spawn child artifacts (gems, snapshots, projects).
   - They are workspace-visible, not owner-private.

4. **Governance discipline**
   - Schema Reference version bumped: **v1.1 → v1.2**
   - All allow-lists, Gateway contracts, and architecture docs updated.
   - No invented fields or tables; documentation reflects existing DDL only.

---

## Repository alignment summary

**Files modified (6):**
- Schema Reference (v1.2)
- Gateway Contract (write semantics)
- Gateway Query Contract (read semantics)
- CLAUDE.md (artifact types + extension tables)
- North Star Architecture
- README.md

**Files version-bumped:**
- Schema Reference: v1.1 → v1.2

**Explicitly deferred to execution phase:**
- NoFail SQL insert templates
- n8n Gateway workflows (save/query/list branching)
- KGB tests for video artifacts
- Workflow README examples

---

## Invariants going forward

- `artifact_type = video` must be treated as canonical everywhere.
- Any workflow saving video artifacts **must** write:
  - Spine row → `qxb_artifact`
  - Extension row → `qxb_artifact_video`
- Journals remain owner-private; videos are first-class shared content.
- Any future schema or contract change touching video **requires a new snapshot**.

---

## Next actions (gated)

1. Implement video ingest + transcription workflows.
2. Extend Gateway save/query/list logic for `video`.
3. Add KGB tests for save/query/update semantics.
4. Document NoFail SQL insert patterns for video.

---

**Snapshot Principle:**  
_When you learn something that protects the herd, carve it into stone._
