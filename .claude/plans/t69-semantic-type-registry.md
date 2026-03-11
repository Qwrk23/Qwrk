# T69 Phase 3.1 — Semantic Type Registry Implementation Plan

**Thread:** T69
**Sapling:** `621d7dba`
**Phase:** 3.1
**DDL:** v2.5 → v2.6
**Canonical Payload:** v2 → v3
**Status:** PLAN — awaiting approval

---

## Resolved Design Decisions (from Q)

| # | Decision | Source |
|---|----------|--------|
| Q1 | Value set: 9 Manus-aligned values (execution-core, governance, infrastructure, platform, product, alignment, sales, marketing, exploratory) | Q response |
| Q2 | RPC function `update_semantic_type()` for fail-closed atomic audit | Q response |
| Q3 | `actor_id` defaults to `owner_user_id`, NOT NULL, TODO comment for future multi-user | Q response |
| Q4 | Registry includes `parent_id` (nullable FK to self) + `governance_snapshot_id` (FK to qxb_artifact) | Q response |
| Q5 | UUID FK throughout (`semantic_type_id` on both registry PK and spine FK) | Q response |
| D1 | Scope: top-level only (project/snapshot/journal/restart). Exclude instruction_pack/branch/limb/leaf. | Delta directive |
| D2 | Fail-closed audit: single transaction, rollback entire update if audit fails | Delta directive |
| D3 | `semantic_type_audit` table (not audit snapshots) | Delta directive |
| D4 | Registry table = sole source of truth. `SEMANTIC_TYPE_REGISTRY.md` = mirror only | Delta directive |
| D5 | Payload v2 → v3 | Delta directive |
| D6 | DDL v2.5 → v2.6 | Delta directive |
| D7 | Registry key: UNIQUE, immutable, no renames, active boolean (no deletes) | Delta directive |
| D8 | Backfill: idempotent, dry-run mode, top-level types only | Delta directive |

---

## Architecture Summary

### New DB Objects (DDL v2.6)

1. **`qxb_semantic_type_registry`** — controlled vocabulary table (9 seed values)
2. **`qxb_semantic_type_audit`** — append-only audit log for semantic_type changes
3. **`qxb_artifact.semantic_type_id`** — new UUID column on spine (FK to registry)
4. **`update_semantic_type()`** — RPC function for atomic update + audit
5. **Conditional CHECK constraint** — NOT NULL for top-level types only (follows `lifecycle_status` pattern)
6. **Updated rollup view** — `qxb_artifact_rollup_view` add `semantic_type_id` column

### Workflow Changes

1. **Gateway** `Normalize_Request`: forward `semantic_type_id`
2. **Save** `Normalize_Request`: extract `semantic_type_id`
3. **Save** `Validate_Request`: require for top-level types
4. **Save** `DB_Insert_Spine`: include `semantic_type_id` field mapping
5. **Update** `Normalize_Request`: extract `semantic_type_id` + `reason`
6. **Update** `Check_Mutability_Rules`: detect semantic_type update → dedicated path
7. **Update** new nodes: IF → HTTP RPC → Guard → response

---

## Execution Phases

### Phase 1: Migration SQL (DDL v2.6)

**Deliverable:** `migrations/2026-03-XX__t69_semantic_type_registry__v1.sql`

**Contains:**

#### 1a. Registry Table

```sql
CREATE TABLE public.qxb_semantic_type_registry (
    semantic_type_id UUID DEFAULT gen_random_uuid() NOT NULL,
    key TEXT NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT true NOT NULL,
    parent_id UUID,                    -- structural reservation (hierarchy)
    governance_snapshot_id UUID,        -- FK to qxb_artifact (required for new additions post-bootstrap)
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    created_by TEXT DEFAULT 'service_role' NOT NULL
);

-- PK
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_pkey PRIMARY KEY (semantic_type_id);

-- UNIQUE on key (immutable after creation)
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_key_unique UNIQUE (key);

-- Self-referential FK for hierarchy
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_parent_fk
    FOREIGN KEY (parent_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

-- FK to governance snapshot artifact
ALTER TABLE ONLY public.qxb_semantic_type_registry
    ADD CONSTRAINT qxb_semantic_type_registry_snapshot_fk
    FOREIGN KEY (governance_snapshot_id) REFERENCES public.qxb_artifact(artifact_id);

-- RLS
ALTER TABLE public.qxb_semantic_type_registry ENABLE ROW LEVEL SECURITY;

-- RLS Policies: read for authenticated, write for service_role only
CREATE POLICY qxb_semantic_type_registry_select_authenticated
    ON public.qxb_semantic_type_registry FOR SELECT TO authenticated USING (true);
-- No INSERT/UPDATE/DELETE policies for authenticated → deny-all for writes
-- service_role bypasses RLS

COMMENT ON TABLE public.qxb_semantic_type_registry IS
  'T69: Controlled vocabulary for artifact semantic classification. Sole source of truth. key is immutable. Deactivate via active=false, never delete.';
```

#### 1b. Audit Table

```sql
CREATE TABLE public.qxb_semantic_type_audit (
    id UUID DEFAULT gen_random_uuid() NOT NULL,
    artifact_id UUID NOT NULL,
    old_semantic_type_id UUID,          -- NULL for first-time assignment
    new_semantic_type_id UUID NOT NULL,
    reason TEXT NOT NULL,
    actor_id UUID NOT NULL,             -- TODO: replace with authenticated user context when multi-user auth introduced
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- PK
ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_pkey PRIMARY KEY (id);

-- FKs
ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_artifact_fk
    FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id);

ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_old_type_fk
    FOREIGN KEY (old_semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

ALTER TABLE ONLY public.qxb_semantic_type_audit
    ADD CONSTRAINT qxb_semantic_type_audit_new_type_fk
    FOREIGN KEY (new_semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

-- RLS
ALTER TABLE public.qxb_semantic_type_audit ENABLE ROW LEVEL SECURITY;

-- Append-only: read for authenticated, no UPDATE/DELETE
CREATE POLICY qxb_semantic_type_audit_select_authenticated
    ON public.qxb_semantic_type_audit FOR SELECT TO authenticated USING (true);

CREATE POLICY qxb_semantic_type_audit_insert_authenticated
    ON public.qxb_semantic_type_audit FOR INSERT TO authenticated WITH CHECK (true);
-- No UPDATE/DELETE policies

-- Block UPDATE/DELETE via triggers (same pattern as qxb_artifact_event)
CREATE TRIGGER qxb_semantic_type_audit_block_update
    BEFORE UPDATE ON public.qxb_semantic_type_audit
    FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();

CREATE TRIGGER qxb_semantic_type_audit_block_delete
    BEFORE DELETE ON public.qxb_semantic_type_audit
    FOR EACH ROW EXECUTE FUNCTION public.qxb_block_update_delete();

COMMENT ON TABLE public.qxb_semantic_type_audit IS
  'T69: Append-only audit log for semantic_type_id changes. Triggers block UPDATE/DELETE. actor_id defaults to owner_user_id (TODO: auth context for multi-user).';
```

#### 1c. Spine Column + FK

```sql
-- Add nullable column first (backfill comes later)
ALTER TABLE public.qxb_artifact
    ADD COLUMN semantic_type_id UUID;

-- FK to registry
ALTER TABLE ONLY public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_semantic_type_fk
    FOREIGN KEY (semantic_type_id) REFERENCES public.qxb_semantic_type_registry(semantic_type_id);

-- Index for FK lookups
CREATE INDEX idx_qxb_artifact_semantic_type ON public.qxb_artifact USING btree (semantic_type_id);
```

#### 1d. Seed Data (9 v1 values)

```sql
-- Bootstrap seed — governance_snapshot_id is NULL for initial registry population.
-- Post-implementation: Joel creates governance snapshot, backfills governance_snapshot_id.
INSERT INTO public.qxb_semantic_type_registry (key, description, created_by) VALUES
  ('execution-core', 'Core execution and lifecycle operations', 'bootstrap'),
  ('governance', 'Governance rules, policies, and enforcement', 'bootstrap'),
  ('infrastructure', 'System infrastructure and platform plumbing', 'bootstrap'),
  ('platform', 'Platform capabilities and features', 'bootstrap'),
  ('product', 'Product-facing functionality and user features', 'bootstrap'),
  ('alignment', 'Strategic alignment and direction-setting', 'bootstrap'),
  ('sales', 'Sales operations and pipeline', 'bootstrap'),
  ('marketing', 'Marketing operations and content', 'bootstrap'),
  ('exploratory', 'Undeclared meaning — default for unclassified artifacts', 'bootstrap');
```

#### 1e. RPC Function

```sql
CREATE OR REPLACE FUNCTION public.update_semantic_type(
    p_artifact_id UUID,
    p_new_semantic_type_id UUID,
    p_reason TEXT,
    p_actor_id UUID DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_artifact RECORD;
    v_old_semantic_type_id UUID;
    v_registry_active BOOLEAN;
    v_top_level_types TEXT[] := ARRAY['project', 'snapshot', 'journal', 'restart'];
BEGIN
    -- 1. Validate reason is non-empty
    IF p_reason IS NULL OR length(trim(p_reason)) = 0 THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'VALIDATION_ERROR',
                'message', 'reason is required and must be non-empty'
            )
        );
    END IF;

    -- 2. Fetch artifact
    SELECT artifact_id, artifact_type, semantic_type_id, owner_user_id
    INTO v_artifact
    FROM public.qxb_artifact
    WHERE artifact_id = p_artifact_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'NOT_FOUND',
                'message', 'Artifact not found'
            )
        );
    END IF;

    -- 3. Validate top-level type
    IF NOT (v_artifact.artifact_type = ANY(v_top_level_types)) THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'SEMANTIC_TYPE_NOT_APPLICABLE',
                'message', 'semantic_type_id applies only to top-level artifact types',
                'details', jsonb_build_object(
                    'artifact_type', v_artifact.artifact_type,
                    'allowed_types', to_jsonb(v_top_level_types)
                )
            )
        );
    END IF;

    -- 4. Validate new semantic type exists and is active
    SELECT active INTO v_registry_active
    FROM public.qxb_semantic_type_registry
    WHERE semantic_type_id = p_new_semantic_type_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'INVALID_SEMANTIC_TYPE',
                'message', 'semantic_type_id not found in registry'
            )
        );
    END IF;

    IF NOT v_registry_active THEN
        RETURN jsonb_build_object(
            'ok', false,
            'error', jsonb_build_object(
                'code', 'SEMANTIC_TYPE_INACTIVE',
                'message', 'Target semantic type is inactive in registry'
            )
        );
    END IF;

    -- 5. Capture old value
    v_old_semantic_type_id := v_artifact.semantic_type_id;

    -- 6. No-op detection (same value = skip)
    IF v_old_semantic_type_id = p_new_semantic_type_id THEN
        RETURN jsonb_build_object(
            'ok', true,
            'noop', true,
            'message', 'semantic_type_id unchanged'
        );
    END IF;

    -- 7. Atomic: UPDATE spine + version increment
    UPDATE public.qxb_artifact
    SET semantic_type_id = p_new_semantic_type_id,
        version = version + 1
    WHERE artifact_id = p_artifact_id;
    -- NOTE: updated_at is auto-set by qxb_artifact_set_updated_at trigger

    -- 8. Atomic: INSERT audit row (same transaction)
    INSERT INTO public.qxb_semantic_type_audit (
        artifact_id, old_semantic_type_id, new_semantic_type_id,
        reason, actor_id, created_at
    ) VALUES (
        p_artifact_id, v_old_semantic_type_id, p_new_semantic_type_id,
        trim(p_reason), COALESCE(p_actor_id, v_artifact.owner_user_id), now()
    );

    -- 9. Return success
    RETURN jsonb_build_object(
        'ok', true,
        'artifact_id', p_artifact_id,
        'old_semantic_type_id', v_old_semantic_type_id,
        'new_semantic_type_id', p_new_semantic_type_id,
        'version', (SELECT version FROM public.qxb_artifact WHERE artifact_id = p_artifact_id)
    );
    -- If step 7 or 8 raises an exception, PostgreSQL rolls back the entire function call (fail-closed)
END;
$$;

COMMENT ON FUNCTION public.update_semantic_type(UUID, UUID, TEXT, UUID) IS
  'T69: Atomic semantic type update + audit. Validates artifact exists, is top-level, new type is active. Increments version. Inserts audit row. Fail-closed: any failure rolls back entire transaction.';
```

#### 1f. Updated Rollup View

```sql
-- Replace existing view to include semantic_type_id
CREATE OR REPLACE VIEW public.qxb_artifact_rollup_view AS
SELECT
    p.artifact_id,
    p.artifact_type,
    p.workspace_id,
    p.semantic_type_id,
    COUNT(c.artifact_id) AS total_active_children_count,
    COUNT(c.artifact_id) FILTER (WHERE c.execution_status = 'complete') AS completed_children_count,
    CASE
        WHEN COUNT(c.artifact_id) = 0 THEN NULL
        ELSE ROUND(
            COUNT(c.artifact_id) FILTER (WHERE c.execution_status = 'complete')::numeric
            / COUNT(c.artifact_id)::numeric, 2
        )
    END AS completion_ratio
FROM public.qxb_artifact p
LEFT JOIN public.qxb_artifact c
    ON c.parent_artifact_id = p.artifact_id
    AND c.deleted_at IS NULL
WHERE p.artifact_type IN ('project', 'branch', 'limb')
    AND p.deleted_at IS NULL
GROUP BY p.artifact_id, p.artifact_type, p.workspace_id, p.semantic_type_id;
```

**Note:** The existing view definition must be read from live DB before writing the replacement. The SQL above is based on T70 migration file — verify exact GROUP BY columns match live before deploying.

---

### Phase 2: Backfill SQL

**Deliverable:** `migrations/2026-03-XX__t69_backfill__v1.sql`

```sql
-- T69 Backfill: Set all top-level artifacts to 'exploratory'
-- Idempotent: WHERE semantic_type_id IS NULL prevents double-application
-- Dry-run: Comment out the UPDATE, run only the SELECT to preview

-- Step 1: Preview (dry-run)
SELECT artifact_id, artifact_type, title, semantic_type_id
FROM public.qxb_artifact
WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
  AND semantic_type_id IS NULL
  AND deleted_at IS NULL
ORDER BY artifact_type, created_at;

-- Step 2: Execute backfill (uncomment to run)
-- UPDATE public.qxb_artifact
-- SET semantic_type_id = (
--     SELECT semantic_type_id FROM public.qxb_semantic_type_registry WHERE key = 'exploratory'
-- )
-- WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
--   AND semantic_type_id IS NULL;

-- Step 3: Verification
-- SELECT artifact_type, COUNT(*) AS total,
--        COUNT(semantic_type_id) AS has_semantic_type,
--        COUNT(*) - COUNT(semantic_type_id) AS missing
-- FROM public.qxb_artifact
-- WHERE artifact_type IN ('project', 'snapshot', 'journal', 'restart')
--   AND deleted_at IS NULL
-- GROUP BY artifact_type
-- ORDER BY artifact_type;
```

---

### Phase 3: Conditional NOT NULL Constraint

**Deliverable:** Included in backfill SQL (Step 4), run AFTER backfill verified.

```sql
-- Step 4: Add conditional NOT NULL (same pattern as lifecycle_status)
-- Only add after backfill verification shows 0 missing
ALTER TABLE public.qxb_artifact
    ADD CONSTRAINT qxb_artifact_semantic_type_required_for_top_level
    CHECK (
        (artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart'))
        OR (semantic_type_id IS NOT NULL)
    );
```

**Pattern precedent:** `qxb_artifact_lifecycle_status_check` uses identical conditional pattern:
```sql
CHECK ((artifact_type <> 'project') OR (lifecycle_status = ANY (...)))
```

---

### Phase 4: Workflow Changes

#### 4a. Gateway `Normalize_Request`

**File:** Current Gateway workflow JSON
**Node:** `NQxb_Gateway_v1__Normalize_Request`
**Change:** Add `semantic_type_id` to field extraction

```javascript
// Add to the output object in Normalize_Request:
semantic_type_id: raw.semantic_type_id ?? null,
// reason is already forwarded (added in v50 for Promote)
```

**Risk:** Same bug class as T26/BUG-015. If forgotten, semantic_type_id silently drops.

#### 4b. Save `Normalize_Request`

**File:** Save sub-workflow JSON
**Node:** `NQxb_Artifact_Save_v1__Normalize_Request`
**Change:** Extract `semantic_type_id` from input

```javascript
// Add to canonical output object:
semantic_type_id: req.semantic_type_id ?? null,
```

#### 4c. Save `Validate_Request`

**Node:** `NQxb_Artifact_Save_v1__Validate_Request`
**Change:** Add validation rule for top-level types

```javascript
// After existing type-specific validation, add:
const topLevelTypes = ['project', 'snapshot', 'journal', 'restart'];
if (topLevelTypes.includes(r.artifact_type) && !r.is_update) {
    if (!r.semantic_type_id) {
        errors.push('semantic_type_id is required for ' + r.artifact_type + ' artifacts');
    }
}
```

#### 4d. Save `DB_Insert_Spine`

**Node:** `DB_Insert_Spine` (Supabase node)
**Change:** Add `semantic_type_id` field mapping

Add column mapping: `semantic_type_id` ← `semantic_type_id` from previous node output.

**Note:** Supabase node field mappings are JSON configuration. The exact modification depends on the node's `fieldsUi` structure.

#### 4e. Update `Normalize_Request`

**Node:** Update sub-workflow `Normalize_Request`
**Change:** Extract `semantic_type_id` and ensure `reason` forwarded

```javascript
// Add to output:
semantic_type_id: req.semantic_type_id ?? null,
reason: req.reason ?? null,
```

#### 4f. Update `Check_Mutability_Rules` — Semantic Type Detection

**Change:** Add detection BEFORE existing type-specific routing. After tags-only bypass, before immutability check:

```javascript
// Semantic-type-only update detection
const hasSemanticType = !!normalized.semantic_type_id;
const hasExtension = !!normalized.extension && Object.keys(normalized.extension).length > 0;
const hasTags = !!normalized.tags;

if (hasSemanticType) {
    // Reject mixed updates
    if (hasExtension || hasTags) {
        return [{json: {
            ok: false, _gw_route: 'error',
            error: { code: 'MIXED_UPDATE_NOT_ALLOWED',
                     message: 'semantic_type_id changes must be standalone (no tags or extension in same request)' }
        }}];
    }
    // Validate reason present
    if (!normalized.reason || normalized.reason.trim().length === 0) {
        return [{json: {
            ok: false, _gw_route: 'error',
            error: { code: 'VALIDATION_ERROR',
                     message: 'reason is required for semantic_type_id changes' }
        }}];
    }
    // Route to RPC
    return [{json: {
        ...parentData,
        _needs_semantic_type_update: true,
        semantic_type_id: normalized.semantic_type_id,
        reason: normalized.reason.trim()
    }}];
}
```

#### 4g. Update — New Nodes (3 nodes)

**Pattern:** Same as T71 dependency enforcement (IF → HTTP RPC → Guard)

1. **`Switch_Semantic_Type_Update`** (IF node v2)
   - Condition: `{{ $json._needs_semantic_type_update === true }}`
   - True → `DB_RPC_Update_Semantic_Type`
   - False → existing spine update path

2. **`DB_RPC_Update_Semantic_Type`** (HTTP Request v4.2)
   ```json
   {
     "method": "POST",
     "url": "https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/rpc/update_semantic_type",
     "authentication": "predefinedCredentialType",
     "nodeCredentialType": "supabaseApi",
     "sendBody": true,
     "specifyBody": "json",
     "jsonBody": "={{ JSON.stringify({ p_artifact_id: $json.artifact_id, p_new_semantic_type_id: $json.semantic_type_id, p_reason: $json.reason, p_actor_id: null }) }}",
     "options": {},
     "alwaysOutputData": true,
     "credentials": { "supabaseApi": { "id": "n4R4JdOIV9zrCGIT", "name": "Qwrk Supabase – Kernel v1" } },
     "onError": "continueErrorOutput"
   }
   ```

3. **`Guard_Semantic_Type_Result`** (Code node v2)
   ```javascript
   const result = $input.first().json;
   // RPC returns jsonb directly
   if (result.ok === true) {
       if (result.noop) {
           return [{ json: { ok: true, _gw_route: 'ok', noop: true, message: result.message } }];
       }
       return [{ json: {
           ok: true, _gw_route: 'ok',
           artifact_id: result.artifact_id,
           semantic_type_update: {
               old: result.old_semantic_type_id,
               new: result.new_semantic_type_id,
               version: result.version
           }
       }}];
   }
   // Error passthrough
   return [{ json: { ok: false, _gw_route: 'error', error: result.error } }];
   ```

   Success output routes to `Return_Response` (existing response node).
   Error output routes to `Return_Response` via error path.

**Node count change:** Update workflow: 35 → 38 nodes (+3: IF, HTTP RPC, Guard)

---

### Phase 5: Documentation

#### 5a. LIVE DDL v2.5 → v2.6

Update `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`:
- Archive current as `Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.5__2026-03-XX.sql`
- Add new tables, column, function, RLS, constraints to DDL
- Update CHANGELOG header

#### 5b. Schema Reference v2.6

Update `docs/schema/Schema_Reference__Kernel_v1__v2.3.md`:
- Archive current version
- Add `qxb_semantic_type_registry` and `qxb_semantic_type_audit` table docs
- Add `semantic_type_id` column to `qxb_artifact` section
- Add `update_semantic_type()` function docs

#### 5c. SEMANTIC_TYPE_REGISTRY.md (New Mirror File)

**Deliverable:** `docs/schema/SEMANTIC_TYPE_REGISTRY.md`

Human-readable mirror of registry table. Contains:
- Value set with descriptions
- Governance rules (how to add new values)
- Source of truth declaration (registry table is authoritative, this file is mirror)

#### 5d. Canonical Payload v3

**Deliverable:** Update `phase1.5-chat-gateway/Chat Project Files/Qwrk_Gateway_Payload_Canonical_v2.md`
- Archive as v2
- Write v3 with:
  - `artifact.save` contract: `semantic_type_id` required for project/snapshot/journal/restart
  - `artifact.update` contract: dedicated `semantic_type_id` + `reason` path
  - New error codes: `SEMANTIC_TYPE_NOT_APPLICABLE`, `INVALID_SEMANTIC_TYPE`, `SEMANTIC_TYPE_INACTIVE`, `MIXED_UPDATE_NOT_ALLOWED`

#### 5e. CLAUDE.md Header Update

Update DDL version reference: v2.5 → v2.6
Update Gateway version if workflow version increments

#### 5f. MEMORY.md Update

Update Deployed State: DDL v2.6, new tables, new function, new RLS count

---

### Phase 6: Testing (H-Series)

**Deliverable:** `Phase2C_Cert/tests/H01-H17` (17 test fixtures)

| Test | Action | Payload Summary | Expected |
|------|--------|-----------------|----------|
| H01 | save | project with semantic_type_id=governance | ok |
| H02 | save | snapshot with semantic_type_id=exploratory | ok |
| H03 | save | journal with semantic_type_id=alignment | ok |
| H04 | save | restart with semantic_type_id=execution-core | ok |
| H05 | save | project WITHOUT semantic_type_id | VALIDATION_ERROR |
| H06 | save | snapshot WITHOUT semantic_type_id | VALIDATION_ERROR |
| H07 | save | branch without semantic_type_id | ok (not required) |
| H08 | save | leaf without semantic_type_id | ok (not required) |
| H09 | save | instruction_pack without semantic_type_id | ok (excluded) |
| H10 | query | H01 project artifact | ok, semantic_type_id in response |
| H11 | update | Change semantic_type_id with reason | ok, version incremented |
| H12 | update | Change semantic_type_id WITHOUT reason | VALIDATION_ERROR |
| H13 | update | Change to inactive semantic_type_id | SEMANTIC_TYPE_INACTIVE |
| H14 | update | Change semantic_type_id on branch | SEMANTIC_TYPE_NOT_APPLICABLE |
| H15 | update | Mixed: semantic_type_id + tags | MIXED_UPDATE_NOT_ALLOWED |
| H16 | update | Tags-only on H01 artifact | ok (regression: tags path unaffected) |
| H17 | list | List projects, verify semantic_type_id in response | ok |

**Regression:** Full A-G series re-run after H-series passes (101 existing tests must remain stable).

---

## Deployment Order (Joel Executes)

| Step | Action | Surface | Prerequisite |
|------|--------|---------|-------------|
| 1 | Run migration SQL (Phase 1) | Supabase SQL Editor | None |
| 2 | Verify: registry seeded (9 rows), column exists, RPC available | Supabase | Step 1 |
| 3 | Run backfill dry-run (Phase 2 Step 1) | Supabase SQL Editor | Step 2 |
| 4 | Run backfill execute (Phase 2 Step 2) | Supabase SQL Editor | Step 3 reviewed |
| 5 | Run backfill verification (Phase 2 Step 3) | Supabase SQL Editor | Step 4 |
| 6 | Add CHECK constraint (Phase 3) | Supabase SQL Editor | Step 5 shows 0 missing |
| 7 | Import Save workflow (version increment) | n8n | Step 6 |
| 8 | Import Update workflow (version increment) | n8n | Step 7 |
| 9 | Import Gateway workflow (version increment) | n8n | Step 8 |
| 10 | Run H-series tests (Phase 6) | Phase2C harness | Step 9 |
| 11 | Run full A-G regression | Phase2C harness | Step 10 |
| 12 | Certify: all PASS, 0 regressions | Manual review | Step 11 |

---

## Explicit Non-Goals (Enforced)

- No new artifact types
- No lifecycle mutations or new lifecycle stages
- No automatic classification inference
- No nondeterministic behavior
- No UI/product-surface features
- No dependence on Walk completion (moot — Walk is complete)
- No mutation of existing Phase 2 test surfaces
- No extension table changes
- No mixed semantic_type + extension/tags updates

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Gateway Normalize_Request silent drop (T26 bug class) | High | Explicit test H01-H06 verify save with semantic_type_id |
| Rollup view column mismatch | Medium | Verify live view definition before deploying replacement |
| Backfill misses soft-deleted artifacts | Low | WHERE clause excludes deleted_at IS NOT NULL; CHECK constraint only enforces on INSERT |
| RPC error format incompatible with Guard node | Medium | H11-H15 tests validate all RPC paths |
| Canonical Payload v3 breaks existing clients | Medium | No compatibility shim per delta directive; clients updated before deployment |
| governance_snapshot_id NULL in seed data | Low | Bootstrap exception documented; enforced going forward |

---

## Files to Create/Modify

### Create
| File | Description |
|------|-------------|
| `migrations/2026-03-XX__t69_semantic_type_registry__v1.sql` | Migration SQL (registry + audit + column + RPC + view) |
| `migrations/2026-03-XX__t69_backfill__v1.sql` | Backfill SQL (idempotent, dry-run) |
| `docs/schema/SEMANTIC_TYPE_REGISTRY.md` | Mirror file |
| `Phase2C_Cert/tests/H01-H17*.json` | Test fixtures |

### Modify
| File | Description |
|------|-------------|
| `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` | v2.5 → v2.6 |
| `docs/schema/Schema_Reference__Kernel_v1__v2.3.md` | Add new tables + column + function |
| Gateway workflow JSON | Normalize_Request: add semantic_type_id forwarding |
| Save workflow JSON | Normalize + Validate + DB_Insert: add semantic_type_id |
| Update workflow JSON | Normalize + Mutability + 3 new nodes |
| `CLAUDE.md` | DDL header v2.6, payload v3 |
| `MEMORY.md` | Deployed state update |

### Archive (Pattern C)
| File | Destination |
|------|-------------|
| LIVE DDL v2.5 | `docs/schema/Archive/LIVE_DDL__Kernel_v1__2026-01-04__v2.5__2026-03-XX.sql` |
| Schema Reference v2.5 | `docs/schema/Archive/Schema_Reference__Kernel_v1__v2.3__2026-03-XX.md` |
| Canonical Payload v2 | `phase1.5-chat-gateway/Chat Project Files/Archive/Qwrk_Gateway_Payload_Canonical_v2__2026-03-XX.md` |

---

## Open Questions (None Blocking)

All 5 blocking questions resolved by Q. No new blockers identified during exploration.

Minor consideration: H13 (inactive semantic_type test) requires temporarily deactivating a registry value — test fixture may need companion setup SQL similar to G04.

---

END OF PLAN.
