-- ============================================================================
-- Sapling C — Architectural Enforcement: Leaf Inserts
-- ============================================================================
-- Sapling C:   459fd517-cd1f-4017-993b-80a125d1b11e
-- Workspace:   be0d3a48-c764-44f9-90c8-e846d9dbbd0a
-- Owner:       c52c7a57-74ad-433d-a07c-4dcac1778672
--
-- 3 branches × 5 leaves each = 15 leaf inserts (Leaf 4 DERIVED excluded)
-- Idempotent: INSERT ... WHERE NOT EXISTS on (parent_artifact_id, title)
-- ============================================================================

-- ================================================================
-- BRANCH 1: Merge-Safe Content Structure Pattern (a091e2fd)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate content merge behavior by field and type',
  'Analysis: trace deep merge behavior and catalog real content shapes across artifact types',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a091e2fd-7471-404c-bf86-8477a7c8d5c0',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate content merge behavior by field and type","scope":"For each artifact type that supports content updates, trace the Update sub-workflow content merge path. Document: (1) how deep merge works (operator, depth, array handling), (2) which content fields use arrays vs objects in practice, (3) what happens when array is merged with object at same key. Query existing artifacts to catalog real content shapes.","excluded":"No fixes. Enumeration only.","completion_condition":"Full trace of merge behavior documented. Content shape census by type. Array vs object distribution known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a091e2fd-7471-404c-bf86-8477a7c8d5c0' AND title = 'Enumerate content merge behavior by field and type' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify merge-safety violations',
  'Analysis: classify each content field as merge_safe, merge_unsafe, mixed_risk, or unknown',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a091e2fd-7471-404c-bf86-8477a7c8d5c0',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify merge-safety violations","scope":"From Leaf 1, classify each content field/pattern: merge_safe (keyed object, additive merge works), merge_unsafe (array, full replacement required), mixed_risk (inconsistent shapes across artifacts), unknown (insufficient data). Document which fields are at risk.","excluded":"No fixes. Classification only.","completion_condition":"Every content field classified. At-risk fields identified with concrete examples."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a091e2fd-7471-404c-bf86-8477a7c8d5c0' AND title = 'Classify merge-safety violations' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define merge-safe content pattern contract',
  'Design: define keyed-object pattern spec with key constraints, migration rule, and merge guarantees',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a091e2fd-7471-404c-bf86-8477a7c8d5c0',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define merge-safe content pattern contract","scope":"Define: (1) keyed-object pattern specification (key naming: slugified, unique, stable), (2) which content fields must adopt the pattern, (3) migration strategy for existing array-based fields, (4) deep merge guarantees (existing keys preserved, new keys added, no array replacement), (5) backward compatibility approach. This becomes system-wide design doc for Team Qwrk review.","excluded":"No implementation. Design only.","key_constraints":{"deterministic":"Same input must always produce the same key","unique":"Keys must be unique within object","stable":"Keys must not change across updates","order_independent":"Keys must NOT depend on array index or insertion order"},"migration_rule":{"preservation":"Array-to-keyed-object transformation MUST preserve ALL entries","key_generation":"Key generation must be deterministic (slugified name, composite key, or content hash)","no_data_loss":"No entry may be dropped, merged, or deduplicated during migration unless explicitly authorized","ordering_independence":"Original array ordering must not be required for correctness after migration"},"completion_condition":"Written design document with: pattern spec, key constraints, migration rule, affected fields, migration plan, merge guarantees, review-ready for Q/Manus."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a091e2fd-7471-404c-bf86-8477a7c8d5c0' AND title = 'Define merge-safe content pattern contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate merge-safe behavior',
  'Validation: verify additive merge, no data loss, and correct replace behavior per migrated field',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a091e2fd-7471-404c-bf86-8477a7c8d5c0',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate merge-safe behavior","scope":"For each migrated field: (1) add single key via content merge — existing keys preserved, (2) add key that already exists — value updated not duplicated, (3) full replace via content_mode: replace — works correctly, (4) no array remnants, (5) forbidden states checked.","excluded":"No inline fixes.","completion_condition":"All migrated fields tested. Merge behavior confirmed additive. No data loss scenarios."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a091e2fd-7471-404c-bf86-8477a7c8d5c0' AND title = 'Validate merge-safe behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Merge-Safe Pattern',
  'Documentation: document merge-safe content pattern as system invariant with migration guide',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a091e2fd-7471-404c-bf86-8477a7c8d5c0',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document merge-safe content pattern as system invariant","scope":"Update Payload Discipline, Quick Reference, and CLAUDE.md with merge-safe content pattern as system invariant. Document key naming conventions. Add migration guide for future content fields.","excluded":"No code changes.","completion_condition":"Pattern documented as system invariant. Naming conventions documented. Migration guide available."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a091e2fd-7471-404c-bf86-8477a7c8d5c0' AND title = 'Documentation update — Merge-Safe Pattern' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 2: Enforce Workspace Consistency for References (c7d5263f)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate reference validation behavior',
  'Analysis: test parent_artifact_id with same-workspace, cross-workspace, and non-existent references',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'c7d5263f-71e8-4359-975a-ef13feeb1b4c',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate reference validation behavior","scope":"For each reference field (parent_artifact_id on save, depends_on_artifact_id on dependency creation), test: (1) valid same-workspace reference — succeeds, (2) valid cross-workspace reference — what happens, (3) non-existent reference — what happens. Document current behavior including whether FK constraint catches cross-workspace or just non-existent.","excluded":"No fixes. Enumeration only.","completion_condition":"Table: reference_field → scenario → current_behavior → error_returned (if any)."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'c7d5263f-71e8-4359-975a-ef13feeb1b4c' AND title = 'Enumerate reference validation behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify reference validation gaps',
  'Analysis: classify each reference scenario as enforced, unprotected cross-workspace, or opaque error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'c7d5263f-71e8-4359-975a-ef13feeb1b4c',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify reference validation gaps","scope":"From Leaf 1, classify each scenario: enforced (rejected correctly), unprotected_cross_workspace (accepted silently — FK passes because artifact exists in another workspace), unprotected_not_found (opaque DB error instead of clear Gateway error).","excluded":"No fixes. Classification only.","completion_condition":"Every reference scenario classified. Gap count known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'c7d5263f-71e8-4359-975a-ef13feeb1b4c' AND title = 'Classify reference validation gaps' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define reference validation contract',
  'Design: define workspace validation query, error codes, and performance budget',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'c7d5263f-71e8-4359-975a-ef13feeb1b4c',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define reference validation contract","scope":"Define: (1) before DB insert, verify parent_artifact_id exists in same workspace via SELECT, (2) REFERENCE_WORKSPACE_MISMATCH error if wrong workspace, (3) REFERENCE_NOT_FOUND if not found at all, (4) performance budget: one additional query per save with parent, (5) scope: parent_artifact_id on save initially, dependency references as extension. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: validation query, error codes, performance budget, scope boundaries."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'c7d5263f-71e8-4359-975a-ef13feeb1b4c' AND title = 'Define reference validation contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate reference workspace enforcement',
  'Validation: verify same-workspace passes, cross-workspace rejected, non-existent rejected',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'c7d5263f-71e8-4359-975a-ef13feeb1b4c',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate reference workspace enforcement","scope":"For parent_artifact_id: (1) same-workspace parent — succeeds, (2) cross-workspace parent — rejected with REFERENCE_WORKSPACE_MISMATCH, (3) non-existent parent — rejected with REFERENCE_NOT_FOUND, (4) null parent on non-child types — still allowed, (5) forbidden states checked.","excluded":"No inline fixes.","completion_condition":"All reference scenarios tested. Cross-workspace references rejected. Same-workspace references pass."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'c7d5263f-71e8-4359-975a-ef13feeb1b4c' AND title = 'Validate reference workspace enforcement' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Workspace Consistency',
  'Documentation: document workspace reference validation guarantees and error codes',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'c7d5263f-71e8-4359-975a-ef13feeb1b4c',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document workspace reference validation","scope":"Update Payload Discipline with workspace reference validation guarantees. Add REFERENCE_WORKSPACE_MISMATCH and REFERENCE_NOT_FOUND to error inventory.","excluded":"No code changes.","completion_condition":"Reference validation documented. Error codes documented."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'c7d5263f-71e8-4359-975a-ef13feeb1b4c' AND title = 'Documentation update — Workspace Consistency' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 3: Enforce Idempotency (2ada1580)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate current retry/duplicate behavior per action',
  'Analysis: test identical request pairs for each Gateway action and document duplicate behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2ada1580-8347-47c8-92ed-d6f1279d136f',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate current retry/duplicate behavior per action","scope":"For each Gateway action, test: (1) submit identical request twice in quick succession — does it create duplicates? (2) For messaging: does it send duplicate emails? (3) For save: does it create two artifacts? (4) For update/promote: is the second call a no-op or does it fail? Document current behavior per action.","excluded":"No fixes. Enumeration only.","completion_condition":"Table: action → duplicate_behavior → creates_duplicate_state (yes/no) → current_protection."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2ada1580-8347-47c8-92ed-d6f1279d136f' AND title = 'Enumerate current retry/duplicate behavior per action' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify idempotency risk by action',
  'Analysis: classify each action as naturally idempotent, duplicate risk, or low risk',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2ada1580-8347-47c8-92ed-d6f1279d136f',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify idempotency risk by action","scope":"From Leaf 1, classify each action: naturally_idempotent (update/promote — same state transition is no-op or fails gracefully), duplicate_risk (save/messaging — creates new state each time), low_risk (query/list — read-only). Identify which actions need idempotency protection.","excluded":"No fixes. Classification only.","completion_condition":"Every action classified. Priority-ordered list of actions needing protection."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2ada1580-8347-47c8-92ed-d6f1279d136f' AND title = 'Classify idempotency risk by action' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define idempotency strategy and contract',
  'Design: define key strategy, TTL, storage, scoped actions, and failure modes for Team Qwrk review',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2ada1580-8347-47c8-92ed-d6f1279d136f',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define idempotency strategy and contract","scope":"Define: (1) idempotency key strategy (client-provided header vs content hash), (2) dedup window (TTL), (3) storage mechanism (in-memory vs DB table), (4) response behavior on duplicate (return original result vs specific idempotency response), (5) scope: which actions get protection first. This becomes design doc for Team Qwrk review.","excluded":"No implementation. Design only.","initial_scope":{"phase_1_actions":["messaging.send_email","artifact.save (snapshot only)"],"rationale":"Highest duplicate-risk actions. Controlled Phase 1 prevents system-wide rollout before validation."},"key_strategy_decision":{"requirement":"Leaf 3 MUST choose ONE key strategy for Phase 1: client-provided idempotency key OR content-hash derived key. Phase 1 MUST NOT support both simultaneously.","rationale":"Eliminates dual-mode ambiguity and simplifies initial implementation."},"failure_modes":{"store_unavailable":"Define behavior when idempotency store is unreachable: fail closed (reject request) OR allow execution (degrade gracefully). Decision MUST be explicit.","original_result_missing":"Define fallback when duplicate detected but original result is no longer available: return idempotency acknowledgment OR reject with specific error.","partial_execution":"Define recovery when execution partially completed but idempotency record was not written: reject subsequent attempts OR allow re-execution with dedup on completion."},"completion_condition":"Written design document with: single key strategy chosen, initial scope (2 actions), TTL, storage mechanism, response behavior, failure mode decisions, review-ready for Q/Manus."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2ada1580-8347-47c8-92ed-d6f1279d136f' AND title = 'Define idempotency strategy and contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate idempotency behavior',
  'Validation: verify no duplicate state on retry, correct dedup window, and failure mode behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2ada1580-8347-47c8-92ed-d6f1279d136f',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate idempotency behavior","scope":"For each protected action: (1) first request — normal response, (2) identical request within window — original result returned, no duplicate state, (3) request after window expires — treated as new, (4) different request with same key — rejected or handled per contract, (5) forbidden states checked.","excluded":"No inline fixes.","completion_condition":"All protected actions tested. Zero duplicate state created on retry."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2ada1580-8347-47c8-92ed-d6f1279d136f' AND title = 'Validate idempotency behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Idempotency',
  'Documentation: document idempotency guarantees, key usage, and dedup window',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2ada1580-8347-47c8-92ed-d6f1279d136f',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document idempotency guarantees","scope":"Update Gateway README with idempotency guarantees. Update QSB Payload Format and Messaging pack with idempotency key usage. Document dedup window and behavior.","excluded":"No code changes.","completion_condition":"Idempotency guarantees documented. Client-side key usage documented."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2ada1580-8347-47c8-92ed-d6f1279d136f' AND title = 'Documentation update — Idempotency' AND deleted_at IS NULL);
