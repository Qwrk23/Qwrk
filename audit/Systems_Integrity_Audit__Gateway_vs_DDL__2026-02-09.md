# Systems Integrity Audit: Gateway Workflows vs. LIVE DDL

**Date:** 2026-02-09
**Auditor:** CC (Read-Only)
**DDL Source:** `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
**Gateway Version:** v47
**Sub-Workflows:** Save v25, Query v16, List v27, Update v11 (deployed), Promote v17 (active) / vNext (staged)

---

## 0. DDL Staleness — RESOLVED (2026-02-09)

~~The LIVE DDL file was dated **2026-01-04** — over five weeks old.~~

**Update (2026-02-09):** DDL file refreshed to v2 via PostgREST OpenAPI live schema export. All 16 tables now documented including 4 previously missing tables:

| Table | Status |
|-------|--------|
| `qxb_artifact_type_registry` | **Now in DDL** — confirmed in live DB |
| `qxb_artifact_instruction_pack` | **Now in DDL** — confirmed in live DB |
| `qxb_artifact_type_registry_audit` | **Now in DDL** — discovered in live DB (append-only audit for type registry) |
| `qxb_gateway_acl` | **Now in DDL** — confirmed in live DB (T24 multi-forest work) |

**Remaining gap:** PostgREST OpenAPI does not expose CHECK constraints, triggers, RLS policies, or indexes for the new tables. These are marked `[NEEDS VERIFICATION]` in the DDL. A `pg_dump` or direct SQL query is needed to fully verify. See verification checklist at end of DDL file.

---

## 1. Confirmed Alignments

These are areas where DDL enforcement and workflow behavior match correctly.

### 1.1 Structural Integrity

| Check | DDL | Workflow | Status |
|-------|-----|----------|--------|
| PK=FK extension pattern | All extension tables PK(artifact_id) FK→qxb_artifact | Save inserts spine first, uses returned artifact_id for extension | **Aligned** |
| FK CASCADE DELETE on extensions | All 7 extension FKs have ON DELETE CASCADE | Gateway delete soft-deletes spine only; cascade not triggered | **Aligned** (cascade is safety net) |
| Event log immutability | Triggers: block_update, block_delete on qxb_artifact_event | Promote inserts events; no workflow updates/deletes events | **Aligned** |
| updated_at auto-trigger | Triggers on: qxb_artifact, qxb_artifact_project, qxb_artifact_journal, qxb_user, qxb_workspace, qxb_workspace_user | Workflows do not manually set updated_at on updates (DB handles it) | **Aligned** |
| RLS enabled on all tables | All qxb_* tables have ENABLE ROW LEVEL SECURITY | Workflows use Supabase credentials that respect RLS | **Aligned** |
| Workspace membership check | RLS policies check qxb_workspace_user membership | Gateway Gatekeeper validates workspace_id; Supabase queries scoped by workspace | **Aligned** |
| Unique constraint: workspace_user | UNIQUE(workspace_id, user_id) on qxb_workspace_user | Not directly tested by workflows, but prevents duplicate membership | **Aligned** |
| auth_user_id uniqueness | UNIQUE(auth_user_id) on qxb_user | One Supabase auth user = one Qwrk user | **Aligned** |
| parent_artifact_id FK | FK→qxb_artifact(artifact_id) — self-referencing | Save/List/Query handle parent_artifact_id correctly | **Aligned** |
| Snapshot/Restart immutability | No UPDATE/DELETE RLS policies on these tables | Save blocks UPDATE (Check_Immutability); Update v11 blocks extension writes | **Aligned** |

### 1.2 Field-Level Alignments (Spine)

| Field | DDL | Save | Query | List | Update | Promote |
|-------|-----|------|-------|------|--------|---------|
| artifact_id (uuid, PK, auto) | gen_random_uuid() NOT NULL | Lets DB generate | Reads | Reads | WHERE filter | WHERE filter |
| workspace_id (uuid, NOT NULL, FK) | FK→qxb_workspace | Required input | WHERE filter | WHERE filter | WHERE filter | WHERE filter |
| owner_user_id (uuid, NOT NULL, FK) | FK→qxb_user | Forced to service principal | Reads | Reads | Not updated | Not updated |
| artifact_type (text, NOT NULL, CHECK) | CHECK enum | Validated via Type Registry | Switch routing | PostgREST filter | Validated | Validated |
| title (text, NOT NULL) | NOT NULL | Required for INSERT | Reads | Reads | PATCH if provided | Not updated |
| version (integer, NOT NULL, DEFAULT 1) | DEFAULT 1 | Not set (DB default) | Reads | Reads | Not updated | Not updated |
| created_at (timestamptz, NOT NULL) | DEFAULT now() | Not set (DB default) | Reads | ORDER BY + filter | Not updated | Not updated |
| updated_at (timestamptz, NOT NULL) | DEFAULT now() + trigger | Not set (trigger handles) | Reads | Reads | Trigger handles | Trigger handles |

### 1.3 Extension Table Alignments

| Table | Field | DDL | Workflow |
|-------|-------|-----|----------|
| project.lifecycle_stage | text NOT NULL, CHECK: seed/sapling/tree/retired | Save requires for INSERT; validates enum | **Aligned** |
| project.operational_state | text NOT NULL DEFAULT 'active', CHECK: active/paused/blocked/waiting | Save defaults to 'active'; Update allows modification | **Aligned** |
| project.state_reason | text, nullable | Save/Update: optional | **Aligned** |
| snapshot.payload | jsonb NOT NULL | Save validates as required object | **Aligned** |
| restart.payload | jsonb NOT NULL | Save validates as required object | **Aligned** |
| journal.entry_text | text, nullable | Save: optional | **Aligned with DDL** (see Section 2.5 for governance gap) |
| journal.payload | jsonb, nullable | Save: optional | **Aligned** |

---

## 2. Mismatches & Risks

### ~~2.1 CRITICAL~~ RESOLVED: `artifact_type` CHECK Constraint — Verified from Live DB

**Update (2026-02-09, Query 1):** CHECK constraint verified directly from live database.

**Live constraint:** `qxb_artifact_artifact_type_check_v5` (was `v2` in original DDL)

**Live CHECK values (12 types):**
```
project, journal, restart, snapshot, grass, thorn, forest, thicket, flower, branch, leaf, instruction_pack
```

| Type | In Live CHECK (v5)? | In Gatekeeper? | Has Extension Table? | Workflow Routes It? |
|------|---------------------|----------------|---------------------|---------------------|
| project | Yes | Yes | Yes | Yes |
| journal | Yes | Yes | Yes | Yes |
| snapshot | Yes | Yes | Yes | Yes |
| restart | Yes | Yes | Yes | Yes |
| instruction_pack | **Yes** | Yes | Yes | Yes |
| grass | Yes | No | Yes | No |
| thorn | Yes | No | Yes | No |
| forest | Yes | No | No (spine only) | No |
| thicket | Yes | No | No (spine only) | No |
| flower | Yes | No | No (spine only) | No |
| **branch** | **Yes (NEW)** | No | No | No |
| **leaf** | **Yes (NEW)** | No | No | No |
| video | **NO** | No | Yes (table exists) | No (separate pipeline) |

**New findings:**
- `branch` and `leaf` added to CHECK since original DDL — forestry hierarchy types with no extension tables
- `video` is NOT in the CHECK despite `qxb_artifact_video` table existing — video artifacts cannot be created via normal spine INSERT
- `instruction_pack` confirmed in CHECK — original CRITICAL finding fully resolved

**Status:** RESOLVED. DDL updated with live `v5` constraint.

### ~~2.2 CRITICAL~~ RESOLVED: DDL File Staleness — Missing Tables

**Update (2026-02-09):** All tables confirmed to exist in live DB via PostgREST OpenAPI. DDL refreshed to v2 with all 16 tables.

**`qxb_artifact_type_registry`** — CONFIRMED
- PK: artifact_type (text). Columns: enabled (bool), description (text), created_at, updated_at
- Referenced by: Save (Lookup + Guard), Update (Lookup + Guard), Promote (Lookup + Guard)

**`qxb_artifact_instruction_pack`** — CONFIRMED
- PK: artifact_id (uuid, FK→qxb_artifact). Columns match workflow assumptions exactly: workspace_id, scope, active, priority, pack_format, created_by_source, approved_at, checksum_sha256, created_at, updated_at

**`qxb_artifact_type_registry_audit`** — DISCOVERED (not previously known)
- PK: audit_id (uuid). Append-only audit log for type registry changes
- Columns: artifact_type, action, actor, old_enabled, new_enabled, reason, created_at

**`qxb_gateway_acl`** — CONFIRMED
- PK: acl_id (uuid). Columns: principal_name, workspace_id (FK→qxb_workspace), role (default 'owner'), created_at

**Status:** RESOLVED. All tables now documented in DDL v2.

### 2.3 HIGH: `lifecycle_status` (spine) vs. `lifecycle_stage` (project extension) Drift

Two fields track lifecycle with different enforcement:

| Field | Table | Constraint | Updated By |
|-------|-------|-----------|------------|
| `lifecycle_status` | qxb_artifact (spine) | **None** — accepts any string | Save (INSERT copy from extension), Promote (UPDATE to new state) |
| `lifecycle_stage` | qxb_artifact_project | CHECK: seed/sapling/tree/retired | Save (INSERT only), **never updated by Promote** |

**After a promotion:**
```
spine.lifecycle_status = "sapling"    ← Updated by Promote
project.lifecycle_stage = "seed"      ← Stale, never touched
```

**Current mitigation:** Query workflow strips `lifecycle_stage` from the extension merge, treating `lifecycle_status` as canonical. List and Update workflows also reference spine. So downstream consumers see the correct state.

**Risk:** If any consumer reads `qxb_artifact_project.lifecycle_stage` directly (bypassing Gateway), they get stale data. This is a **ticking inconsistency** — not broken today but brittle.

**Additional:** `lifecycle_status` on the spine has **no CHECK constraint**. The Promote workflow writes constrained values (seed/sapling/tree/retired), but nothing stops a direct DB write of an invalid lifecycle_status string.

### 2.4 MEDIUM: `tags` Column is JSONB — No Array Shape Enforcement

**DDL:** `tags jsonb` — nullable, no CHECK constraint

**Workflows assume:** tags is always a JSON array of strings (or null)

- Save normalizes: split comma-strings, lowercase, trim, dedupe → JSON array
- Update v11: reads existing tags as array, applies add/remove, writes back as array
- List: filters via PostgREST `cs.` operator (assumes JSONB array)

**Risk:** If any path writes a non-array value to tags (object, scalar, nested array), downstream workflows will:
- List: filter silently ignores the row (PostgREST `cs.` fails on non-arrays)
- Update v11: `currentTags.filter(...)` throws runtime error
- Query: returns whatever is stored (no validation)

**Severity:** Low probability (all current write paths normalize to array), but no DB-level guard exists.

### 2.5 MEDIUM: Journal `entry_text` — Governance Requires It, DDL Allows NULL

**DDL:** `entry_text text` — nullable
**Q System Instructions:** `extension.entry_text REQUIRED` for journal saves
**Save Workflow Validation:** entry_text is **not validated as required** for journal INSERT

**Gap:** A journal artifact can be saved with null entry_text. Q's governance says this shouldn't happen, but neither the database nor the workflow enforces it.

### 2.6 MEDIUM: Promote Updates Spine Only — No Event on Project Extension

The Promote workflow:
1. Updates `qxb_artifact.lifecycle_status` (spine)
2. Inserts into `qxb_artifact_event` (audit log)
3. Does NOT update `qxb_artifact_project.lifecycle_stage`

This is the cause of Mismatch 2.3. The event log records the transition, but the project extension table retains its original INSERT value indefinitely.

### 2.7 LOW: Delete/Restore/List_Deleted Bypass Standard Pipeline

Gateway handles these actions via direct HTTP Request nodes:
- No Type Registry validation
- No mutability check
- No event log creation
- No workspace membership check beyond Supabase RLS

| Operation | Creates Event? | Checks Mutability? | Checks Type Registry? |
|-----------|---------------|--------------------|-----------------------|
| artifact.save | Yes (via workflow) | Yes | Yes |
| artifact.update | No | Yes | Yes |
| artifact.promote | Yes | N/A | Yes |
| **artifact.delete** | **No** | **No** | **No** |
| **artifact.restore** | **No** | **No** | **No** |
| **artifact.list_deleted** | **N/A** | **N/A** | **No** |

**Risk:** Soft-deleting a snapshot or restart creates no audit trail. RLS still protects workspace boundaries.

### 2.8 LOW: `priority` on Spine — CHECK 1-5 But Workflows Don't Validate

**DDL:** `priority integer CHECK ((priority >= 1) AND (priority <= 5))`
**Save workflow:** Accepts priority as optional, passes through to Supabase INSERT
**No workflow validates** that priority is 1-5 before writing

**Current protection:** DB CHECK constraint catches invalid values, returning a constraint error that Save maps to `CONFLICT` or `INTERNAL_ERROR`. But the error message won't clearly say "priority out of range."

### 2.9 MEDIUM (upgraded from LOW): `video` Type — Table Exists But NOT in CHECK Constraint

`qxb_artifact_video` exists with full schema (14 columns, status CHECK, idempotency_key UNIQUE). But:
- **`video` is NOT in `artifact_type` CHECK constraint (v5)** — spine INSERT with `artifact_type='video'` will fail
- Gateway Gatekeeper TYPE_ALLOWLIST does not include `video`
- No Save/Query/List/Update routing for video type

**Impact:** Video artifacts **cannot be created at all** through normal spine INSERT — the CHECK constraint blocks it. Either:
1. Video artifacts don't exist yet (table was created but never populated)
2. Video artifacts were inserted via a mechanism that bypasses CHECK (e.g., service_role with `ALTER TABLE ... DISABLE TRIGGER ALL`)
3. The CHECK was updated to include `video` at some point and later removed

This is more significant than originally assessed. The video pipeline appears to be structurally blocked at the DB level, not just at the Gateway level.

### 2.10 LOW: Promote `actor_user_id` — FK Exists But No Pre-Validation

**DDL:** `qxb_artifact_event.actor_user_id uuid FK→qxb_user(user_id)` — nullable
**Promote workflow:** Passes `actor_user_id || null` to event INSERT

If an invalid (non-existent) user_id is provided, the FK constraint rejects the event INSERT. The Promote workflow has already updated `lifecycle_status` by this point — the promotion succeeds but the event fails. This leaves the audit log incomplete.

---

## 3. Silent Failure Risks

These are cases where bad data can pass without error or visibility.

| # | Scenario | What Happens | Visibility |
|---|----------|-------------|------------|
| **S1** | Non-array value written to `tags` column via direct SQL | List filters silently skip the row; Update v11 crashes on that artifact | **None** — no error on write, silent skip on read |
| **S2** | `lifecycle_status` set to arbitrary string via direct SQL | No CHECK, no error. Promote may fail on next transition (from_state won't match) | **Delayed** — discovered only when next promote is attempted |
| **S3** | Journal saved with null `entry_text` via Gateway | DDL allows it, workflow allows it. Governance says it shouldn't happen | **None** — looks like a valid save |
| **S4** | `project.lifecycle_stage` drift after promotion | Extension retains INSERT value; spine has promoted value | **None** — Query strips the extension field, so consumers never see the stale value. But direct DB queries are misleading |
| **S5** | Priority value 0 or 6 sent to Save | DB CHECK rejects. Error mapped to INTERNAL_ERROR (not VALIDATION_ERROR) — caller gets generic error, not "priority out of range" | **Obscured** — error exists but root cause unclear to caller |
| **S6** | Soft-delete of immutable artifact (snapshot/restart) | No mutability check on delete path. Artifact marked deleted. | **None** — delete succeeds silently, no event logged |
| ~~**S7**~~ | ~~`instruction_pack` save attempt (if CHECK constraint not updated)~~ | ~~Spine INSERT fails with check_violation~~ | **Likely resolved** — extension table exists in live DB, instruction_pack saves are working (CHECK was almost certainly updated) |
| **S8** | Promote succeeds but event INSERT fails (bad actor_user_id) | lifecycle_status updated, audit log incomplete | **Partial** — promotion visible, audit gap invisible |

---

## 4. Minimal Fixes (If Any)

Only fixes that enforce existing intent, reduce ambiguity, and do not expand system surface area.

### ~~Fix 1: Refresh LIVE DDL File~~ DONE (2026-02-09)

DDL refreshed to v2 via PostgREST OpenAPI export. 16 tables now documented (was 12). Original archived to `docs/schema/Archive/LIVE_DDL__Kernel_v1__2026-01-04__v1__2026-02-09.sql`.

**Remaining:** CHECK constraints, triggers, RLS policies, and indexes for the 4 new tables need verification via `pg_dump` or direct SQL query. See verification checklist at end of DDL file.

### Fix 2: Add `lifecycle_status` CHECK Constraint to Spine

```sql
ALTER TABLE qxb_artifact
ADD CONSTRAINT qxb_artifact_lifecycle_status_check
CHECK (lifecycle_status IS NULL OR lifecycle_status = ANY(ARRAY['seed','sapling','tree','retired']));
```

**Why:** Spine `lifecycle_status` accepts any string. Promote writes valid values, but nothing prevents garbage data. Matching the project extension's CHECK constraint on the spine makes the system honest.

**Effort:** One ALTER TABLE. Non-breaking — all existing data should already have valid values (or NULL).

**Risk:** Low. Verify no existing rows have non-standard lifecycle_status values before applying.

### Fix 3: Validate `priority` Range in Save Workflow

Add to Save's `Validate_Request` node:

```javascript
if (priority !== undefined && priority !== null) {
  if (typeof priority !== 'number' || priority < 1 || priority > 5) {
    errors.push('priority must be integer 1-5');
  }
}
```

**Why:** Currently the DB rejects invalid priority with a generic CHECK violation error that gets mapped to INTERNAL_ERROR. Workflow-level validation would produce a clear VALIDATION_ERROR with "priority must be integer 1-5."

**Effort:** ~3 lines in existing validation node.

**Risk:** Zero. Additive validation; existing valid requests unaffected.

### Fix 4: Add Event Logging to Delete/Restore Paths

The Gateway's `Handle_Delete` and `Handle_Restore` nodes write directly to Supabase without creating audit events. Adding an event INSERT after each operation would close the audit gap.

**Why:** Every other state-changing action (save, promote) creates events. Delete/restore is invisible.

**Effort:** Two new HTTP Request nodes (one per action) + Supabase INSERT to `qxb_artifact_event` with `event_type: "soft_delete"` or `"restore"`.

**Risk:** Low. Additive. If event INSERT fails, the delete/restore still succeeded (same pattern as current Promote behavior).

### Fix 5: Deploy Promote vNext (Staged Bug Fix)

**What:** Import `n8n_workflows/staged/BUG_PROMOTE_FROM_STATE_MISSING__gateway_promote_vNext.json` to n8n.

**Why:** The active v17 has a known HIGH-severity bug: n8n Merge node drops fields, causing `$json.artifact_id` and `$json.gw_workspace_id` to be empty in downstream nodes. vNext fixes this by reading from explicit `$node[...]` references.

**Effort:** Import + activate in n8n. No code changes needed.

**Risk:** Low. Same workflow ID (`OXxickY3S5Fxtv5F`), same contract. Fix is purely internal plumbing.

---

## 5. Appendix: Tables Analyzed

### DDL Tables (16 — updated 2026-02-09)

| Table | PK | Extension Pattern | RLS | Triggers |
|-------|----|----|-----|----------|
| qxb_artifact | artifact_id | Spine | Yes | set_updated_at |
| qxb_artifact_event | event_id | Audit log | Yes | block_update, block_delete |
| qxb_artifact_project | artifact_id | PK=FK | Yes | set_updated_at |
| qxb_artifact_journal | artifact_id | PK=FK | Yes | set_updated_at |
| qxb_artifact_snapshot | artifact_id | PK=FK | Yes | — |
| qxb_artifact_restart | artifact_id | PK=FK | Yes | — |
| qxb_artifact_video | artifact_id | PK=FK | Yes | — |
| qxb_artifact_grass | artifact_id | PK=FK | Yes | — |
| qxb_artifact_thorn | artifact_id | PK=FK | Yes | — |
| qxb_artifact_instruction_pack | artifact_id | PK=FK | [NEEDS VERIFY] | [NEEDS VERIFY] |
| qxb_artifact_type_registry | artifact_type | Registry | [NEEDS VERIFY] | [NEEDS VERIFY] |
| qxb_artifact_type_registry_audit | audit_id | Audit log | [NEEDS VERIFY] | [NEEDS VERIFY] |
| qxb_gateway_acl | acl_id | ACL | [NEEDS VERIFY] | — |
| qxb_user | user_id | Identity | Yes | set_updated_at |
| qxb_workspace | workspace_id | Workspace | Yes | set_updated_at |
| qxb_workspace_user | workspace_user_id | Membership | Yes | set_updated_at |

### Gateway Actions Analyzed (8)

| Action | Sub-workflow | Status |
|--------|-------------|--------|
| artifact.query | NQxb_Artifact_Query_v1 (v16) | Active |
| artifact.list | NQxb_Artifact_List_v1 (v27) | Active |
| artifact.save | NQxb_Artifact_Save_v1 (v25) | Active |
| artifact.update | NQxb_Artifact_Update_v1 (v11) | Active |
| artifact.promote | NQxb_Artifact_Promote_v1 (v17) | Active (vNext staged) |
| artifact.delete | Direct HTTP PATCH | Active |
| artifact.restore | Direct HTTP PATCH | Active |
| artifact.list_deleted | Direct HTTP GET | Active |

---

## CHANGELOG

### 2026-02-09 (update 3)
- CHECK constraint verified from live DB (Query 1): `qxb_artifact_artifact_type_check_v5`
- Section 2.1: Marked RESOLVED — `instruction_pack` confirmed in live CHECK
- Section 2.9: Upgraded from LOW to MEDIUM — `video` NOT in CHECK (structurally blocked)
- New types discovered: `branch`, `leaf` (forestry hierarchy, no extension tables)
- DDL updated to v2.1 with verified CHECK constraint

### 2026-02-09 (update 2)
- DDL refreshed to v2 — 4 new tables added from live PostgREST OpenAPI
- Section 0: DDL staleness marked RESOLVED
- Section 2.1: Downgraded from CRITICAL to MEDIUM (extension table confirmed in live DB; CHECK constraint needs verification)
- Section 2.2: Marked RESOLVED (all tables confirmed in live DB)
- Section 4 Fix 1: Marked DONE
- Section 5: Table count updated from 11 to 16
- Silent Failure S7: Likely resolved (instruction_pack saves are working)
- Discovered: `qxb_artifact_type_registry_audit` table (append-only audit log, not previously known)

### 2026-02-09 (initial)
- Initial systems integrity audit
- Scope: Gateway v47, Save v25, Query v16, List v27, Update v10/v11, Promote v17/vNext
- DDL: LIVE_DDL__Kernel_v1__2026-01-04.sql (STALE — see Section 0)
