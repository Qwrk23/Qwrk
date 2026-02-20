# Multi-User Qwrk — Workflow Version Registry

**Created:** 2026-02-17
**Purpose:** Track which version of the gateway template each clone is running.

---

## Golden Template

| Field | Value |
|-------|-------|
| Source File | `workflows/NQxb_Gateway_v1__ACL_Test.json` |
| Base Version | Gateway v56 (ACL wiring) |
| Sub-Workflow Versions | Save v29, Query v18, List v29, Update v11, Promote v2_HTTP |
| ACL Validation Snapshot | `ee8d3c9f` |

---

## Clone Version Tracking

| Gateway | Clone Version | Deployed Date | Last Updated | Matches Template? | Notes |
|---------|-------------|--------------|-------------|-------------------|-------|
| NQxb_Gateway_v1__Work_Joel | v1 | `{{TBD}}` | `{{TBD}}` | [ ] Yes | |
| NQxb_Gateway_v1__Akara | v1 | `{{TBD}}` | `{{TBD}}` | [ ] Yes | |
| NQxb_Gateway_v1__BlaggLife | v1 | `{{TBD}}` | `{{TBD}}` | [ ] Yes | |
| NQxb_Gateway_v1__Krista | v1 | `{{TBD}}` | `{{TBD}}` | [ ] Yes | |

---

## Sub-Workflow Registry (Shared)

All clones share these sub-workflows. When updated, changes propagate automatically.

| Sub-Workflow | Workflow ID | Version | Last Updated |
|-------------|------------|---------|-------------|
| NQxb_Artifact_Save_v1 | `mlUCDPRRdWp286ja` | Save v29 | 2026-02-17 |
| NQxb_Artifact_Query_v1 | `LGYSXI586inagTPk` | Query v18 | 2026-02-17 |
| NQxb_Artifact_List_v1 | `RKDyfV4mdHCBDkmK` | List v29 | 2026-02-17 |
| NQxb_Artifact_Update_v1 | `1L2HKncP2Dh0K3DI` | Update v11 | 2026-02-17 |
| NQxb_Artifact_Promote_v1 | `SaKD4o4FKrXfSYt6` | Promote v2_HTTP | 2026-02-17 |

---

## Version Propagation Log

Record each time the golden template or clones are updated.

| Date | Change | Affected Clones | Template Updated? |
|------|--------|----------------|-------------------|
| 2026-02-17 | Initial deployment (v1) | All 4 | Yes (baseline) |

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
