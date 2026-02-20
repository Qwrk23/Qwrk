# Seed — Contract Version Alignment Decision

**Date:** 2026-01-04  
**Artifact Type:** Project (Seed)  
**Forest:** Qwrk  
**Thicket:** Platform Evolution

## Decision Captured

We are formalizing a governance decision regarding Gateway contract alignment:

**Decision framing:**  
Treat the newer Gateway contract as **v1.0** and **version Phase 3 forward to v1.1** to match it (versioned update), **or** declare the newer contract an **implementation draft** and bring it back into alignment with Phase 3.

**Lean / recorded recommendation:**  
➡️ **Version Phase 3 forward to v1.1**, since the system has already been operating in practice against the newer contract.

## Rationale

- Prevents silent contract drift between planning artifacts and live behavior.
- Keeps Gateway, workflows, tests, and error envelopes deterministic.
- Makes supersession explicit and auditable for future readers.
- Aligns documentation with reality instead of forcing rollback.

## Follow‑on Actions

1. Update **Phase 3 – Gateway Contract** document to **v1.1**, aligning all fields, envelopes, and examples to the newer contract.
2. Update the **Authoritative Index**:
   - Mark older Phase 3 version as **SUPERSEDED**.
   - Mark Phase 3 v1.1 as **ACTIVE**.
3. Add a short **Change Narrative** section to Phase 3 v1.1 explaining *why* the version bump occurred.

## Tags

gateway, contract, phase3, versioning, governance, kernel-v1
