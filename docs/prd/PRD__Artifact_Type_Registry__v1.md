# PRD: Artifact Type Registry v1

**Version:** 1.1
**Date:** 2026-01-19
**Status:** Draft
**Author:** Claude Code (CC) — Build Assist for New Qwrk

---

## Document Governance

This PRD is authoritative for the Artifact Type Registry system component and aligns with:

- Qwrk V2 North Star
- Kernel v1 Snapshots
- Gateway Contract v1
- Known-Good Baseline (KGB) discipline
- Forest / Thicket Structure Lock v1.0

**Old-bull rule applies:** Correctness over speed.

---

## Governance Conflict Note: instruction_pack

`instruction_pack` is explicitly **out-of-scope** for v1 registry seeding.

**Rationale:**

If any external documentation (e.g., draft North Star updates, CLAUDE.md additions, or test definition files) claims `instruction_pack` is a Kernel v1 artifact type or an allowed type, that represents a **governance conflict**. Such documentation is not authoritative until:

1. A versioned North Star update (e.g., v0.4 or later) explicitly adds `instruction_pack` to the Kernel artifact type list
2. That update is published into the authoritative project documentation pack
3. The registry is updated via service_role INSERT to include `instruction_pack`

**Until these conditions are met:**

- `instruction_pack` remains in the DO-NOT-SEED list
- Gateway will reject `instruction_pack` saves with `TYPE_NOT_ALLOWED`
- Any existing documentation mentioning `instruction_pack` as Kernel v1 should be treated as draft/pending

This is not a technical limitation—it is a governance discipline requiring explicit versioned approval before new types enter production.

---

## Authoritative Sources: Structure Layer Types

The structure layer types (`forest`, `thicket`, `flower`) are **real, documented artifact types**, not placeholders.

**Authoritative sources:**

| Document | Content |
|----------|---------|
| Forest / Thicket Structure Lock v1.0 | Defines forest→thicket→tree(project) hierarchy and flower placement under thicket |
| No-Fail SQL Models | Includes save patterns for forest, thicket, and flower |
| Gateway JSON Payload Canonical Reference v1 | Lists forest, thicket, flower as allowed artifact_types with implementation status notes |

**Important distinction:**

- **"Seeded in the registry"** means the type is **recognized + governable** by the system
- It does **NOT** mean Gateway support is already implemented
- Implementation status is tracked separately from registry allow/deny status

A type can be:
- Seeded + enabled + Gateway-supported (fully operational)
- Seeded + enabled + Gateway-pending (recognized but save not yet implemented)
- Seeded + disabled (temporarily blocked)
- Not seeded (rejected by default)

For v1, all seeded types are intended to be Gateway-supported, but the registry design allows for future types to be registered before Gateway implementation is complete.

---

## Tree: Artifact Type Registry

**Goal:** Replace hardcoded artifact type allow-lists in Gateway workflows with a Supabase-managed registry table, enabling governed addition of new artifact types without workflow modification.

**Success state:** Adding a new artifact type to the system requires only an INSERT into `qxb_artifact_type_registry` (service_role access), with Gateway automatically recognizing and enforcing the type.

---

## 1. Purpose

The Artifact Type Registry provides a single source of truth for which artifact types are recognized by the Qwrk system. Gateway consults this registry before executing `artifact.save`, `artifact.update`, and `artifact.promote` operations.

**Key benefits:**

1. **Decoupled governance:** New types added via DB, not workflow edits
2. **Fail-closed security:** Unknown types rejected by default
3. **Audit trail:** All registry changes logged for compliance
4. **Graceful deprecation:** Types can be disabled without breaking historical data

---

## 2. Scope

### In Scope (v1)

- Registry table for artifact types
- Enabled/disabled status per type
- Audit table for registry changes
- Gateway integration (read-only lookup)
- Seed data for Kernel v1 + Structure Layer types

### Out of Scope (v1)

| Item | Rationale |
|------|-----------|
| Generic config registry | v1 is artifact-type-specific only |
| User/workspace-scoped types | Types are global |
| UI or Gateway mutation paths | service_role only |
| Per-workspace type overrides | Not in Kernel v1 |
| Automatic Gateway deployment | Manual workflow update required |

### Explicitly Excluded Types (Do-Not-Seed)

The following types are NOT seeded in v1 and are rejected by default:

| Type | Rationale |
|------|-----------|
| `branch` | Structure layer — not yet governed |
| `leaf` | Structure layer — not yet governed |
| `thorn` | Structure layer — not yet governed |
| `grass` | Structure layer — not yet governed |
| `history` | Reporting layer — out of Kernel v1 scope |
| `report` | Reporting layer — out of Kernel v1 scope |
| `instruction_pack` | **Governance conflict** — not present in authoritative North Star; requires versioned update before inclusion (see Governance Conflict Note above) |

---

## 3. Behavioral Rules

### 3.1 Registry Lookup

Gateway MUST query the registry before processing:
- `artifact.save` (INSERT)
- `artifact.update`
- `artifact.promote`

Gateway MAY skip registry lookup for:
- `artifact.query` (single fetch)
- `artifact.list` (paginated list)

**Rationale:** Historical artifacts of disabled types must remain readable.

### 3.2 Fail-Closed Behavior

If the registry lookup fails (DB error, timeout, empty result):
- Gateway MUST reject the operation
- Error code: `REGISTRY_UNAVAILABLE` or `TYPE_NOT_ALLOWED`
- No fallback to hardcoded lists

### 3.3 Enabled vs Disabled

| Type Status | save | update | promote | query | list |
|-------------|------|--------|---------|-------|------|
| Enabled     | ✅   | ✅     | ✅      | ✅    | ✅   |
| Disabled    | ❌   | ❌     | ❌      | ✅    | ✅   |
| Not in registry | ❌ | ❌   | ❌      | ❌    | ❌   |

**Note:** "Not in registry" returns `TYPE_NOT_ALLOWED`. "Disabled" returns `TYPE_DISABLED`.

### 3.4 Registry Characteristics

- **Global:** Not workspace-scoped
- **Immutable schema:** artifact_type is PK, never deleted
- **Soft-disable:** Use `enabled = false`, not DELETE
- **Audit-mandatory:** All changes logged

---

## 4. Governance & Security Model

### 4.1 Access Control

| Actor | Read | Write |
|-------|------|-------|
| Gateway (anon/authenticated) | ✅ | ❌ |
| Supabase Dashboard (service_role) | ✅ | ✅ |
| Application users | ❌ | ❌ |
| Workspace admins | ❌ | ❌ |

**Write access is restricted to service_role only.** There is no UI, API, or Gateway path to modify the registry.

### 4.2 RLS Policy

```sql
-- Read: Gateway needs SELECT access
CREATE POLICY "Registry read access"
ON qxb_artifact_type_registry
FOR SELECT
USING (true);

-- Write: service_role only (no user writes)
-- No INSERT/UPDATE/DELETE policies for authenticated role
```

### 4.3 Change Management

All registry modifications require:

1. Governance review (human approval)
2. Execution via Supabase Dashboard or migration script
3. Automatic audit log entry via trigger

---

## 5. Audit Strategy

### 5.1 Audit Table

All registry changes are logged to `qxb_artifact_type_registry_audit`:

| Column | Type | Description |
|--------|------|-------------|
| `audit_id` | UUID | Primary key |
| `artifact_type` | TEXT | Type affected |
| `action` | TEXT | INSERT, UPDATE, DELETE |
| `old_enabled` | BOOLEAN | Previous enabled state (NULL for INSERT) |
| `new_enabled` | BOOLEAN | New enabled state (NULL for DELETE) |
| `actor` | TEXT | Always 'service_role' for v1 |
| `reason` | TEXT | Optional human-provided reason |
| `created_at` | TIMESTAMPTZ | Timestamp of change |

### 5.2 Audit Trigger

A database trigger automatically logs all changes. The trigger:

- Fires AFTER INSERT, UPDATE, DELETE
- Captures before/after state
- Is append-only (audit rows never modified)

---

## 6. Failure Modes

| Failure | Gateway Behavior | Error Code |
|---------|------------------|------------|
| Registry table missing | Reject all write operations | `REGISTRY_UNAVAILABLE` |
| Registry query timeout | Reject operation | `REGISTRY_UNAVAILABLE` |
| Registry returns empty set | Reject operation | `REGISTRY_UNAVAILABLE` |
| Type not in registry | Reject operation | `TYPE_NOT_ALLOWED` |
| Type disabled | Reject write, allow read | `TYPE_DISABLED` |
| Type enabled | Allow operation | (success) |

**Fail-closed principle:** When in doubt, reject.

---

## 7. Data Model

### 7.1 Registry Table

```sql
-- ============================================
-- TABLE: qxb_artifact_type_registry
-- Purpose: Single source of truth for allowed artifact types
-- ============================================

CREATE TABLE qxb_artifact_type_registry (
    artifact_type   TEXT        PRIMARY KEY,
    enabled         BOOLEAN     NOT NULL DEFAULT true,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for Gateway lookup (enabled types only)
CREATE INDEX idx_artifact_type_registry_enabled
ON qxb_artifact_type_registry (artifact_type)
WHERE enabled = true;

COMMENT ON TABLE qxb_artifact_type_registry IS
'Authoritative registry of recognized artifact types. Gateway consults this before save/update/promote operations.';

COMMENT ON COLUMN qxb_artifact_type_registry.enabled IS
'When false, type cannot be saved/updated/promoted but existing artifacts remain queryable.';
```

### 7.2 Audit Table

```sql
-- ============================================
-- TABLE: qxb_artifact_type_registry_audit
-- Purpose: Append-only audit log for registry changes
-- ============================================

CREATE TABLE qxb_artifact_type_registry_audit (
    audit_id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    artifact_type   TEXT        NOT NULL,
    action          TEXT        NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_enabled     BOOLEAN,
    new_enabled     BOOLEAN,
    actor           TEXT        NOT NULL DEFAULT 'service_role',
    reason          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for querying audit history by type
CREATE INDEX idx_artifact_type_registry_audit_type
ON qxb_artifact_type_registry_audit (artifact_type, created_at DESC);

COMMENT ON TABLE qxb_artifact_type_registry_audit IS
'Append-only audit log for all changes to qxb_artifact_type_registry. Rows are never modified or deleted.';
```

### 7.3 Audit Trigger

```sql
-- ============================================
-- TRIGGER: Audit logging for registry changes
-- ============================================

CREATE OR REPLACE FUNCTION fn_audit_artifact_type_registry()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'INSERT', NULL, NEW.enabled);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'UPDATE', OLD.enabled, NEW.enabled);

        -- Update timestamp
        NEW.updated_at := now();
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (OLD.artifact_type, 'DELETE', OLD.enabled, NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_audit_artifact_type_registry
AFTER INSERT OR UPDATE OR DELETE ON qxb_artifact_type_registry
FOR EACH ROW EXECUTE FUNCTION fn_audit_artifact_type_registry();
```

### 7.4 RLS Policies

```sql
-- ============================================
-- RLS: Registry table
-- ============================================

ALTER TABLE qxb_artifact_type_registry ENABLE ROW LEVEL SECURITY;

-- Gateway needs SELECT access (uses anon or authenticated role)
CREATE POLICY "Registry read access"
ON qxb_artifact_type_registry
FOR SELECT
USING (true);

-- No INSERT/UPDATE/DELETE policies = service_role only writes

-- ============================================
-- RLS: Audit table
-- ============================================

ALTER TABLE qxb_artifact_type_registry_audit ENABLE ROW LEVEL SECURITY;

-- Read-only access for audit queries
CREATE POLICY "Audit read access"
ON qxb_artifact_type_registry_audit
FOR SELECT
USING (true);

-- No INSERT policy = trigger-only writes (SECURITY DEFINER)
-- No UPDATE/DELETE policies = append-only
```

### 7.5 Seed Data

```sql
-- ============================================
-- SEED: Initial artifact types (v1)
-- ============================================

INSERT INTO qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES
    ('project',  true, 'Core work container with lifecycle (seed→sapling→tree→retired)'),
    ('journal',  true, 'Timestamped narrative entries'),
    ('snapshot', true, 'Immutable point-in-time capture of artifact state'),
    ('restart',  true, 'Immutable session boundary marker with context'),
    ('forest',   true, 'Top-level organizational container (structure layer)'),
    ('thicket',  true, 'Grouping container within forest (structure layer)'),
    ('flower',   true, 'Lightweight artifact under thicket (structure layer)')
ON CONFLICT (artifact_type) DO NOTHING;
```

---

## 8. Implementation Plan

### Branch 1: Database Foundation

**Owner:** kg (Supabase execution) + CC (SQL generation)

| Leaf | Task | Owner | Depends On |
|------|------|-------|------------|
| 1.1 | Create `qxb_artifact_type_registry` table | kg | — |
| 1.2 | Create `qxb_artifact_type_registry_audit` table | kg | 1.1 |
| 1.3 | Create audit trigger function | kg | 1.2 |
| 1.4 | Create audit trigger | kg | 1.3 |
| 1.5 | Enable RLS on both tables | kg | 1.1, 1.2 |
| 1.6 | Create RLS policies | kg | 1.5 |
| 1.7 | Insert seed data | kg | 1.6 |
| 1.8 | Verify seed + audit entries | kg | 1.7 |

**Receipt required:** Query showing 7 rows in registry, 7 rows in audit table.

### Branch 2: Gateway Integration

**Owner:** ANQ (n8n workflow modification)

| Leaf | Task | Owner | Depends On |
|------|------|-------|------------|
| 2.1 | Add registry lookup query to Gateway workflow | ANQ | Branch 1 complete |
| 2.2 | Add registry lookup query to Save workflow | ANQ | Branch 1 complete |
| 2.3 | Replace hardcoded allow-list with registry check | ANQ | 2.1, 2.2 |
| 2.4 | Add `TYPE_NOT_ALLOWED` error response | ANQ | 2.3 |
| 2.5 | Add `TYPE_DISABLED` error response | ANQ | 2.3 |
| 2.6 | Add `REGISTRY_UNAVAILABLE` error response | ANQ | 2.3 |
| 2.7 | Test happy path (enabled type) | ANQ | 2.3 |
| 2.8 | Test rejection path (disabled type) | ANQ | 2.5 |

**Receipt required:** PowerShell test output showing save accepted for enabled type, rejected for disabled type.

### Branch 3: Validation & Documentation

**Owner:** CC (test definitions) + kg (execution)

| Leaf | Task | Owner | Depends On |
|------|------|-------|------------|
| 3.1 | Add registry tests to Gateway Test Definitions | CC | — |
| 3.2 | Execute Test 8.1: Save with enabled type | kg | Branch 2 complete |
| 3.3 | Execute Test 8.2: Save with disabled type | kg | Branch 2 complete |
| 3.4 | Execute Test 8.3: Query disabled type (should work) | kg | Branch 2 complete |
| 3.5 | Execute Test 8.4: Registry lookup failure | kg | Branch 2 complete |
| 3.6 | Update CLAUDE.md with registry documentation | CC | 3.2-3.5 pass |
| 3.7 | Create restart file documenting completion | CC | 3.6 |

**Receipt required:** All 4 tests pass, documentation updated.

---

## 9. Test Definitions

### Test Suite 8: Artifact Type Registry

#### Test 8.1: Save with Enabled Type — Happy Path

**Action:** `artifact.save`
**Description:** Save a project artifact (enabled in registry)

**Prerequisite:** Registry seeded, Gateway updated

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "title": "Registry Test - Enabled Type",
  "extension": {
    "lifecycle_status": "seed"
  }
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifact_id` (UUID)

**Success Criteria:** Enabled type passes registry check and saves successfully.

---

#### Test 8.2: Save with Disabled Type — Rejected

**Action:** `artifact.save`
**Description:** Attempt to save an artifact with a disabled type

**Prerequisite:** Disable one type in registry (e.g., `UPDATE qxb_artifact_type_registry SET enabled = false WHERE artifact_type = 'journal'`)

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "title": "Registry Test - Disabled Type",
  "extension": {
    "body": "This should be rejected"
  }
}
```

**Expected Behavior:**
- Error response with code: `TYPE_DISABLED`
- Message indicates type is disabled

**Success Criteria:** Disabled type rejected with appropriate error.

**Cleanup:** Re-enable journal: `UPDATE qxb_artifact_type_registry SET enabled = true WHERE artifact_type = 'journal'`

---

#### Test 8.3: Query Disabled Type — Allowed

**Action:** `artifact.query`
**Description:** Query an existing artifact whose type is currently disabled

**Prerequisite:**
1. Create a journal artifact while type is enabled
2. Disable journal type
3. Query the created artifact

**Input Payload:**
```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal",
  "artifact_id": "{{JOURNAL_ARTIFACT_ID}}"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains full artifact data

**Success Criteria:** Historical artifacts remain queryable when type is disabled.

---

#### Test 8.4: Save with Unregistered Type — Rejected

**Action:** `artifact.save`
**Description:** Attempt to save an artifact with a type not in the registry

**Input Payload:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "instruction_pack",
  "title": "Registry Test - Unregistered Type",
  "content": {
    "scope": "global"
  }
}
```

**Expected Behavior:**
- Error response with code: `TYPE_NOT_ALLOWED`
- Message indicates type is not recognized

**Success Criteria:** Unregistered types fail-closed with appropriate error.

---

#### Test 8.5: List Disabled Type — Allowed

**Action:** `artifact.list`
**Description:** List artifacts of a disabled type

**Prerequisite:** Disable journal type, existing journal artifacts in workspace

**Input Payload:**
```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "journal"
}
```

**Expected Behavior:**
- HTTP 200 response
- Response contains `ok: true`
- Response contains `artifacts` array (may be empty or have items)

**Success Criteria:** List operation allowed for disabled types.

---

#### Test 8.6: Update Disabled Type — Rejected

**Action:** `artifact.update`
**Description:** Attempt to update an artifact whose type is disabled

**Prerequisite:** Disable project type temporarily

**Input Payload:**
```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "{{TEST_WORKSPACE_ID}}",
  "artifact_type": "project",
  "artifact_id": "{{PROJECT_ARTIFACT_ID}}",
  "extension": {
    "operational_state": "paused"
  }
}
```

**Expected Behavior:**
- Error response with code: `TYPE_DISABLED`
- Message indicates type is disabled

**Success Criteria:** Update rejected for disabled types.

---

## 10. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | Registry table exists with 7 seeded types | `SELECT COUNT(*) FROM qxb_artifact_type_registry` = 7 |
| 2 | Audit table has 7 INSERT entries | `SELECT COUNT(*) FROM qxb_artifact_type_registry_audit` = 7 |
| 3 | RLS prevents authenticated writes | Attempt INSERT as authenticated user fails |
| 4 | Gateway accepts enabled types | Test 8.1 passes |
| 5 | Gateway rejects disabled types | Test 8.2 passes |
| 6 | Gateway rejects unregistered types | Test 8.4 passes |
| 7 | Query/list work for disabled types | Tests 8.3, 8.5 pass |
| 8 | Update/promote rejected for disabled types | Test 8.6 passes |
| 9 | Audit log captures enable/disable changes | Toggle enabled, verify audit row created |
| 10 | Fail-closed on registry error | Simulate error, verify rejection |

---

## 11. SQL Execution Script (Combined)

The following script can be executed in sequence via Supabase SQL Editor:

```sql
-- ============================================
-- ARTIFACT TYPE REGISTRY v1 — COMPLETE MIGRATION
-- Execute in Supabase SQL Editor (service_role)
-- ============================================

-- 1. Registry table
CREATE TABLE IF NOT EXISTS qxb_artifact_type_registry (
    artifact_type   TEXT        PRIMARY KEY,
    enabled         BOOLEAN     NOT NULL DEFAULT true,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_artifact_type_registry_enabled
ON qxb_artifact_type_registry (artifact_type)
WHERE enabled = true;

COMMENT ON TABLE qxb_artifact_type_registry IS
'Authoritative registry of recognized artifact types. Gateway consults this before save/update/promote operations.';

-- 2. Audit table
CREATE TABLE IF NOT EXISTS qxb_artifact_type_registry_audit (
    audit_id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    artifact_type   TEXT        NOT NULL,
    action          TEXT        NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_enabled     BOOLEAN,
    new_enabled     BOOLEAN,
    actor           TEXT        NOT NULL DEFAULT 'service_role',
    reason          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_artifact_type_registry_audit_type
ON qxb_artifact_type_registry_audit (artifact_type, created_at DESC);

COMMENT ON TABLE qxb_artifact_type_registry_audit IS
'Append-only audit log for all changes to qxb_artifact_type_registry.';

-- 3. Audit trigger function
CREATE OR REPLACE FUNCTION fn_audit_artifact_type_registry()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'INSERT', NULL, NEW.enabled);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'UPDATE', OLD.enabled, NEW.enabled);
        NEW.updated_at := now();
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (OLD.artifact_type, 'DELETE', OLD.enabled, NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Audit trigger
DROP TRIGGER IF EXISTS trg_audit_artifact_type_registry ON qxb_artifact_type_registry;
CREATE TRIGGER trg_audit_artifact_type_registry
AFTER INSERT OR UPDATE OR DELETE ON qxb_artifact_type_registry
FOR EACH ROW EXECUTE FUNCTION fn_audit_artifact_type_registry();

-- 5. RLS on registry
ALTER TABLE qxb_artifact_type_registry ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Registry read access" ON qxb_artifact_type_registry;
CREATE POLICY "Registry read access"
ON qxb_artifact_type_registry
FOR SELECT
USING (true);

-- 6. RLS on audit
ALTER TABLE qxb_artifact_type_registry_audit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Audit read access" ON qxb_artifact_type_registry_audit;
CREATE POLICY "Audit read access"
ON qxb_artifact_type_registry_audit
FOR SELECT
USING (true);

-- 7. Seed data
INSERT INTO qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES
    ('project',  true, 'Core work container with lifecycle (seed→sapling→tree→retired)'),
    ('journal',  true, 'Timestamped narrative entries'),
    ('snapshot', true, 'Immutable point-in-time capture of artifact state'),
    ('restart',  true, 'Immutable session boundary marker with context'),
    ('forest',   true, 'Top-level organizational container (structure layer)'),
    ('thicket',  true, 'Grouping container within forest (structure layer)'),
    ('flower',   true, 'Lightweight artifact under thicket (structure layer)')
ON CONFLICT (artifact_type) DO NOTHING;

-- 8. Verification queries
SELECT 'Registry count:' AS check, COUNT(*)::TEXT AS result FROM qxb_artifact_type_registry
UNION ALL
SELECT 'Audit count:', COUNT(*)::TEXT FROM qxb_artifact_type_registry_audit
UNION ALL
SELECT 'All enabled:', COUNT(*)::TEXT FROM qxb_artifact_type_registry WHERE enabled = true;
```

---

## 12. Gateway Integration Reference

**Query for Gateway to execute:**

```sql
SELECT artifact_type
FROM qxb_artifact_type_registry
WHERE artifact_type = $1
  AND enabled = true;
```

**Decision logic:**

```
IF query returns 0 rows:
  IF artifact_type exists in registry (enabled = false):
    RETURN error: TYPE_DISABLED
  ELSE:
    RETURN error: TYPE_NOT_ALLOWED
ELSE:
  PROCEED with operation
```

**Alternative single-query approach:**

```sql
SELECT
  artifact_type,
  enabled
FROM qxb_artifact_type_registry
WHERE artifact_type = $1;
```

Then in Gateway:
- No row → `TYPE_NOT_ALLOWED`
- Row with `enabled = false` → `TYPE_DISABLED`
- Row with `enabled = true` → proceed

---

## 13. Rollback Plan

If issues are discovered after deployment:

1. **Gateway rollback:** Revert n8n workflow to hardcoded allow-list
2. **DB rollback (optional):** Tables can remain; they're not destructive
3. **No data loss:** Registry is additive, doesn't modify artifact tables

---

## 14. Future Considerations (Out of Scope for v1)

- Admin UI for registry management
- Per-workspace type overrides
- Type metadata (icon, color, category)
- Automatic Gateway reload on registry change
- instruction_pack inclusion (pending versioned North Star update)

---

## Changelog

| Date | Version | Changes | Rationale |
|------|---------|---------|-----------|
| 2026-01-19 | 1.0 | Initial PRD created | Establish Artifact Type Registry v1 design |
| 2026-01-19 | 1.1 | Added "Governance Conflict Note: instruction_pack" section | Explicit documentation that instruction_pack is out-of-scope; any external docs claiming otherwise represent a governance conflict requiring versioned North Star update |
| 2026-01-19 | 1.1 | Added "Authoritative Sources: Structure Layer Types" section | Clarify that forest/thicket/flower are real documented types, not placeholders; cite authoritative source documents |
| 2026-01-19 | 1.1 | Updated instruction_pack rationale in Do-Not-Seed table | Link to Governance Conflict Note; make conflict explicit |
| 2026-01-19 | 1.1 | Clarified "seeded" semantics | "Seeded in registry" means recognized + governable, NOT Gateway-implemented; implementation status tracked separately |
| 2026-01-20 | 1.1.1 | Patch: Fix `updated_at` trigger semantics | Added BEFORE UPDATE trigger (`trg_artifact_type_registry_set_updated_at`) to maintain `updated_at`; removed ineffective `updated_at` assignment from AFTER audit trigger function. Migration: `2026-01-20__artifact_type_registry__fix_updated_at__v1.0.sql`. Receipt: journal row updated_at advanced from seed time (00:04:35) to update time (00:09:37); audit logged UPDATE with old_enabled=true, new_enabled=false. |

---

**End of PRD**
