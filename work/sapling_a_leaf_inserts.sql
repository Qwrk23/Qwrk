-- ============================================================================
-- Sapling A — Response & Error Integrity: Leaf Inserts
-- ============================================================================
-- Parent seed: fb5bccd0-1e64-4407-95d8-989b7e08aa17
-- Sapling A:   20d27f2d-9464-4ab4-884f-34ee2aa0b5b1
-- Workspace:   be0d3a48-c764-44f9-90c8-e846d9dbbd0a
-- Owner:       c52c7a57-74ad-433d-a07c-4dcac1778672
--
-- Branches:
--   1. Deterministic Error Surfacing  (1ed8973a) — 5 leaves (1,2,3,5,6)
--   2. Consistent Response Shape      (f4a98705) — 6 leaves (1,2,3,5,6,7)
--   3. Reject No-Op Extension Updates (10687dfc) — 5 leaves (1,2,3,5,6)
--
-- Leaf 4 (DERIVED) is NOT created — generated dynamically after Leaf 2.
-- Idempotent: uses INSERT ... WHERE NOT EXISTS on (parent_artifact_id, title).
-- ============================================================================

-- ================================================================
-- BRANCH 1: Deterministic Error Surfacing (1ed8973a)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate error emission points in Save sub-workflow',
  'Analysis: enumerate all error-producing nodes in Save sub-workflow',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '1ed8973a-d841-4239-9764-453fac3cf26b',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate every node in the Save sub-workflow that can produce an error","scope":"Save sub-workflow only. Read the build script (build_save_v47_comms_fix.py) and/or n8n workflow export. List every node that can produce an error: validation rejects, semantic type lookup failures, DB insert failures, type-switch fallthrough.","excluded":"No fixes. No classification. Just enumeration.","completion_condition":"A table exists mapping: node_name → error_condition → output_path (success/error) for every node in the Save chain."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '1ed8973a-d841-4239-9764-453fac3cf26b' AND title = 'Enumerate error emission points in Save sub-workflow' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Trace and classify error handling behavior',
  'Analysis: classify each error path as propagated, swallowed, masked, or false_success',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '1ed8973a-d841-4239-9764-453fac3cf26b',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify error handling behavior for each error emission point","scope":"For each error emission point from Leaf 1, trace the path from that node to the final response. Classify each as: propagated (reaches response correctly), swallowed (never reaches response), masked (reaches response but code/message altered incorrectly), or false_success (error occurred, response says ok:true).","excluded":"No fixes. No design. Classification only.","completion_condition":"Every row in the Leaf 1 table has a classification. The number and identity of non-propagated error classes is known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '1ed8973a-d841-4239-9764-453fac3cf26b' AND title = 'Trace and classify error handling behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define error propagation contract for Save',
  'Design: define the explicit error propagation contract for Save sub-workflow',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '1ed8973a-d841-4239-9764-453fac3cf26b',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define the explicit error propagation contract for Save","scope":"Using Leaf 2 classifications, write the explicit contract: (1) every error emission point must reach Shape_Save_Response, (2) error code and message must be preserved end-to-end, (3) ok:true is forbidden when any upstream error occurred. Define the response shape contract for error cases.","excluded":"No implementation. Contract definition only.","completion_condition":"A written contract exists that can be used as acceptance criteria for implementation leaves. Includes: required error response shape, forbidden states, and the truth boundary definition."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '1ed8973a-d841-4239-9764-453fac3cf26b' AND title = 'Define error propagation contract for Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate Save error propagation',
  'Validation: verify all error paths propagate correctly per contract',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '1ed8973a-d841-4239-9764-453fac3cf26b',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate that all Save error paths propagate correctly","scope":"For each error emission point from Leaf 1, inject a failure condition and verify: (1) response is ok:false, (2) error code matches expected, (3) no ok:true on failure. Test against Leaf 3 contract.","excluded":"No new fixes during validation. Failures create new implementation leaf, not inline fix.","completion_condition":"Every error emission point tested. All pass against Leaf 3 contract. If any fail, a new implementation leaf is created (not fixed inline)."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '1ed8973a-d841-4239-9764-453fac3cf26b' AND title = 'Validate Save error propagation' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update',
  'Documentation: add no-silent-failure invariant to Gateway README',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '1ed8973a-d841-4239-9764-453fac3cf26b',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document the no-silent-failure invariant","scope":"Add No silent failure paths invariant to Gateway README. Update Payload Discipline if error handling guidance changes. Document the Save error propagation contract from Leaf 3 as permanent reference.","excluded":"No code changes.","completion_condition":"Invariant documented. Contract referenced in canonical docs."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '1ed8973a-d841-4239-9764-453fac3cf26b' AND title = 'Documentation update' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 2: Consistent Response Shape (f4a98705)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate response shapes from Save',
  'Analysis: trace response shape from DB Insert through Shape_Save_Response to Webhook Response',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate actual response outputs from Save across full pipeline","scope":"Trace response shape across the full pipeline: from DB Insert node output, through Shape_Save_Response transformations, to the final Webhook Response returned to the client. For both success and error paths, document every field at each stage: field name, type, nullability, source node. Identify any field loss or mutation between DB output and final response. Cover the normal save path and each known error branch (validation error, semantic type error, DB insert error, type mismatch).","excluded":"No classification of issues. No fixes. Enumeration only.","completion_condition":"A table exists mapping: response_path (success/validation_error/db_error/etc) → fields present → field type → nullable for every output shape from Save."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Enumerate response shapes from Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify shape inconsistencies',
  'Analysis: classify each response shape inconsistency by type',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify response shape inconsistencies","scope":"For each response shape from Leaf 1, compare against expected canonical structure. Classify each inconsistency as: missing_field (required field absent), null_violation (required field present but null, e.g., version:null), structural_mismatch (wrong nesting, wrong type), inconsistent_optional_field (field present on some paths, absent on others without justification).","excluded":"No fixes. No contract definition. Classification only.","completion_condition":"Every response path from Leaf 1 has been compared. Each inconsistency is classified with: path, field, issue_type, current_behavior, expected_behavior. The number and identity of inconsistencies is known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Classify shape inconsistencies' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define response shape contract for Save',
  'Design: define canonical Save response schema for success and error paths',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define the canonical Save response schema","scope":"Define the canonical Save response schema for success and error paths. Specify: required fields (must always be present and non-null), optional fields (may be absent), nullability rules, forbidden state combinations. Align error shape with Branch 1 propagation contract. This becomes the acceptance criteria for all implementation leaves.","excluded":"No implementation. Contract definition only.","completion_condition":"A written contract exists defining: success response shape (exact fields), error response shape (exact fields), required/optional classification per field, forbidden states list, and explicit alignment note with Branch 1 error contract."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Define response shape contract for Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate Save response shape',
  'Validation: deterministic pass/fail checks against response shape contract',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate Save response shape against contract","scope":"For each response path (success + each error type), validate the actual output against Leaf 3 contract. Validation must be deterministic with explicit pass/fail checks: (1) exact field set match — no missing required fields, no unexpected fields, (2) correct field types — string, object, boolean, integer as specified in contract, (3) nullability compliance — no null where contract forbids it, (4) forbidden state detection — test every combination from gateway_boundary.forbidden_states, (5) structural consistency — same nesting and field organization across all response paths. Test version field populated on success, error.code/message present on all error paths.","excluded":"No new fixes during validation. Failures create new implementation leaf, not inline fix.","completion_condition":"Every response path tested against Leaf 3 contract. All pass. If any fail, a new implementation leaf is created (not fixed inline)."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Validate Save response shape' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Action expansion control',
  'Planning: define expansion plan for applying response shape pattern to other actions',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":6,"leaf_type":"planning","purpose":"Define expansion plan for remaining actions","scope":"After Save response shape is validated, define the plan for applying the same pattern to Update, Promote, Query, and List. Determine if the Leaf 3 contract applies directly or needs per-action variations. Produce a scoping note for each remaining action.","excluded":"No implementation of other actions. Planning only.","completion_condition":"A written expansion plan exists defining: which actions share the Save contract vs need variations, and the recommended leaf sequence for each."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Action expansion control' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Response Shape',
  'Documentation: add canonical response schema to Gateway README',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  'f4a98705-d4c5-4a7c-b4cb-4e67836d2465',
  '{"leaf_number":7,"leaf_type":"documentation","purpose":"Document canonical response schema","scope":"Add canonical response schema to Gateway README. Update QSB Payload Format pack if client-side parsing guidance changes. Document the Save response shape contract from Leaf 3 as permanent reference. Reinforce Gateway as source of truth for response structure.","excluded":"No code changes.","completion_condition":"Canonical response schema documented. Contract referenced in Gateway README and relevant instruction packs."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'f4a98705-d4c5-4a7c-b4cb-4e67836d2465' AND title = 'Documentation update — Response Shape' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 3: Reject No-Op Extension Updates (10687dfc)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate extension persistence behavior by artifact type',
  'Analysis: determine extension persistence path for each artifact type in Update sub-workflow',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '10687dfc-3b8d-4ba5-8500-bc0489fb8c28',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate extension persistence behavior by artifact type","scope":"For each artifact type in the TYPE_ALLOWLIST (project, journal, restart, snapshot, instruction_pack, branch, limb, leaf, twig), determine: (1) does an extension table exist (PK=FK pattern), (2) does the Update sub-workflow route extension updates to a DB write for this type, (3) what is the storage path (table name or none). Trace from incoming extension payload through Update Normalize_Request → Check_Mutability_Rules → type routing → DB update node (or absence thereof).","excluded":"No classification of issues. No fixes. Enumeration of current behavior only.","completion_condition":"A table exists mapping: artifact_type → has_extension_table (yes/no) → update_routed_to_db (yes/no) → storage_table_name for every type in the allowlist."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '10687dfc-3b8d-4ba5-8500-bc0489fb8c28' AND title = 'Enumerate extension persistence behavior by artifact type' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify no-op scenarios',
  'Analysis: classify current extension update behavior per artifact type',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '10687dfc-3b8d-4ba5-8500-bc0489fb8c28',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify no-op scenarios for extension updates","scope":"For each artifact type from Leaf 1, classify the current behavior when an extension update is submitted. Categories: non_persistent_type (no extension table, update silently ignored), silently_ignored_extension (extension table exists but update path does not write), partial_write (some extension fields written, others dropped), overwritten_without_effect (write occurs but has no observable state change). Also check: does the response return ok:true for any of these no-op cases?","excluded":"No fixes. No contract definition. Classification only.","completion_condition":"Every artifact type from Leaf 1 has a classification: artifact_type → scenario → current_behavior → classification. The number and identity of no-op scenarios is known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '10687dfc-3b8d-4ba5-8500-bc0489fb8c28' AND title = 'Classify no-op scenarios' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define extension mutability contract',
  'Design: define which types support extension updates and required rejection behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '10687dfc-3b8d-4ba5-8500-bc0489fb8c28',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define the extension mutability contract","scope":"Using Leaf 1 and Leaf 2 output, define the contract: (1) which artifact types support extension updates (mutable list), (2) which do not (immutable list), (3) required behavior for mutable types (persist and confirm), (4) required behavior for immutable types (reject with EXTENSION_NOT_MUTABLE, include artifact_type in error.details). Define forbidden states from gateway_boundary. This becomes acceptance criteria for implementation leaves.","excluded":"No implementation. Contract definition only.","completion_condition":"A written contract exists with: mutable type list, immutable type list, required error code and shape for rejection, forbidden states, and explicit pass/fail criteria for each type."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '10687dfc-3b8d-4ba5-8500-bc0489fb8c28' AND title = 'Define extension mutability contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate extension update behavior',
  'Validation: verify all types either persist or reject extension updates correctly',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '10687dfc-3b8d-4ba5-8500-bc0489fb8c28',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate extension update behavior across all types","scope":"For each artifact type in the allowlist, submit an extension update and validate: (1) mutable types — update persists, response reflects new state, (2) immutable types — request rejected with EXTENSION_NOT_MUTABLE, error.details includes artifact_type, (3) no silent no-op behavior on any type, (4) no ok:true when no mutation occurred, (5) forbidden states from gateway_boundary are not present in any response.","excluded":"No new fixes during validation. Failures create new implementation leaf, not inline fix.","completion_condition":"Every artifact type tested. All mutable types persist correctly. All immutable types reject correctly. Zero silent no-ops. If any fail, a new implementation leaf is created (not fixed inline)."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '10687dfc-3b8d-4ba5-8500-bc0489fb8c28' AND title = 'Validate extension update behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Extension Mutability',
  'Documentation: add extension mutability table and no-silent-no-op invariant',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb,
  '10687dfc-3b8d-4ba5-8500-bc0489fb8c28',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document extension mutability table and invariant","scope":"Add extension mutability table to Payload Discipline pack showing: artifact_type → supports_extension_update (yes/no) → behavior (persist/reject). Document EXTENSION_NOT_MUTABLE error code in error inventory. Add no silent no-op invariant to Gateway README.","excluded":"No code changes.","completion_condition":"Extension mutability table documented in Payload Discipline. Error code documented. Invariant in Gateway README."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '10687dfc-3b8d-4ba5-8500-bc0489fb8c28' AND title = 'Documentation update — Extension Mutability' AND deleted_at IS NULL);
