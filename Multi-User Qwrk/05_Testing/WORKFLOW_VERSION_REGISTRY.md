# Multi-User Qwrk — Workflow Version Registry

**Created:** 2026-02-17
**Updated:** 2026-03-04 (T69 alignment — sub-workflow versions, golden template, clone tracking)
**Purpose:** Track which version of the gateway template each clone is running.

---

## Golden Template

| Field | Value |
|-------|-------|
| Source File | `workflows/NQxb_Gateway_v1 (57).json` (Prime v59 era export, 2026-03-04) |
| Base Version | Gateway v59 — T69 semantic_type_id forwarding, 8 actions, EW typeVersion 1.3 |
| Sub-Workflow Versions | Save v42, Query v21, List v29, Update T69 (v38), Promote v23 |
| DDL Version | v2.6 |
| T69 Compliance | Full — semantic_type_id forwarding in Normalize_Request |
| Previous Template | `workflows/NQxb_Gateway_v1__ACL_Test.json` (v57-equivalent, Save v32 era) |

---

## Clone Version Tracking

| Gateway | Clone Version | Deployed Date | Last Updated | Matches Template? | Notes |
|---------|-------------|--------------|-------------|-------------------|-------|
| NQxb_Gateway_v1__Work_Joel | v2 | 2026-02-18 (v1), 2026-03-04 (v2) | 2026-03-04 | [x] Yes | Re-cloned from Prime v59 export. T69 compliant. |
| NQxb_Gateway_v1__Akara | — | `{{TBD}}` | `{{TBD}}` | [ ] Yes | Not yet deployed |
| NQxb_Gateway_v1__BlaggLife | — | `{{TBD}}` | `{{TBD}}` | [ ] Yes | Not yet deployed |
| NQxb_Gateway_v1__Krista | — | `{{TBD}}` | `{{TBD}}` | [ ] Yes | Not yet deployed |

---

## Sub-Workflow Registry (Shared)

All clones share these sub-workflows. When updated, changes propagate automatically.

| Sub-Workflow | Workflow ID | Version | Last Updated | Notes |
|-------------|------------|---------|-------------|-------|
| NQxb_Artifact_Save_v1 | `cEmJcbfQE2C92MNV` | Save v42 | 2026-03-03 | T69 semantic type registry enforcement, Contract B dual-mode, T75+T76 B01+T72 CREATE-only |
| NQxb_Artifact_Query_v1 | `27efKlNfdyu89YGD` | Query v21 | 2026-03-01 | T70 VIEW-based rollup |
| NQxb_Artifact_List_v1 | `RKDyfV4mdHCBDkmK` | List v29 | 2026-02-17 | Unchanged |
| NQxb_Artifact_Update_v1__T69 | `0FwKlCRJ1wV5qDhV` | Update T69 (v38) | 2026-03-03 | T71 base + semantic_type dedicated path via RPC, check #2.5 mixed-update guard |
| NQxb_Artifact_Promote_v1 | `DhcvKMsThjxbBReT` | Promote v23 | 2026-03-01 | T76 C01 + concurrency hardening |

---

## Version Propagation Log

Record each time the golden template or clones are updated.

| Date | Change | Affected Clones | Template Updated? |
|------|--------|----------------|-------------------|
| 2026-02-17 | Initial deployment (v1) | Work_Joel | Yes (baseline) |
| 2026-02-21 | Deterministic routing hardening (Switch fallbacks, neverError removal, Promote serialization, T51 fix, priority validation) | Template updated | Yes |
| 2026-03-04 | T69 Full Re-Baseline — re-cloned Work_Joel from Prime v59 export. Semantic_type_id forwarding, Save v42, Query v21, Update T69, Promote v23. Sub-workflow IDs migrated. | Work_Joel (v1→v2) | Yes (new golden template) |

---

## Propagation Rules

1. **Sub-workflow updates** (Save, Query, List, Update, Promote):
   - Automatically affect all clones (shared IDs)
   - No clone modifications needed
   - Record in "Sub-Workflow Registry" table above

2. **Gateway-level changes** (Gatekeeper logic, Normalizer, new actions):
   - Must be applied to golden template first
   - Then re-cloned to each gateway following `CLONE_GATEWAY_CHECKLIST.md`
   - Record in "Version Propagation Log"

3. **Credential rotation:**
   - Update n8n credential for affected gateway
   - Update ChatGPT Project system instructions with new password (if exposed)
   - Record rotation date in this registry

---

## Credential Rotation Log

| Gateway | Principal | Last Rotated | Next Due | Rotated By |
|---------|-----------|-------------|----------|------------|
| Work_Joel | qwrk-gw-work | `{{TBD}}` | `{{TBD + 90 days}}` | Joel |
| Akara | qwrk-gw-akara | `{{TBD}}` | `{{TBD + 90 days}}` | Joel |
| BlaggLife | qwrk-gw-blagglife | `{{TBD}}` | `{{TBD + 90 days}}` | Joel |
| Krista | qwrk-gw-krista | `{{TBD}}` | `{{TBD + 90 days}}` | Joel |
