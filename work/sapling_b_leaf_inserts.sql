-- ============================================================================
-- Sapling B — Gateway Strict Mode: Leaf Inserts
-- ============================================================================
-- Sapling B:   8a937ffd-ea52-4c7b-9c47-91eb740390af
-- Workspace:   be0d3a48-c764-44f9-90c8-e846d9dbbd0a
-- Owner:       c52c7a57-74ad-433d-a07c-4dcac1778672
--
-- 8 branches × 5 leaves each = 40 leaf inserts (Leaf 4 DERIVED excluded)
-- Idempotent: INSERT ... WHERE NOT EXISTS on (parent_artifact_id, title)
-- ============================================================================

-- ================================================================
-- BRANCH 1: Reject Unknown Extension Keys (228ab8ed)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate allowed extension keys per artifact type',
  'Analysis: extract extension field allowlist from Save DB insert nodes per type',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '228ab8ed-1224-48a6-b410-cbc16c7f1e59',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate allowed extension keys per artifact type","scope":"For each artifact type in TYPE_ALLOWLIST, extract the exact extension field allowlist from Save sub-workflow DB insert nodes. Document: artifact_type → allowed_keys[] → source_node. Trace from Validate_Request through type-switch to DB insert to confirm which keys are actually written.","excluded":"No classification. No fixes. Enumeration only.","completion_condition":"A table exists mapping every artifact type to its complete extension key allowlist with source node references."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '228ab8ed-1224-48a6-b410-cbc16c7f1e59' AND title = 'Enumerate allowed extension keys per artifact type' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify current unknown-key handling behavior',
  'Analysis: classify per-type behavior when unknown extension keys are submitted',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '228ab8ed-1224-48a6-b410-cbc16c7f1e59',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify current unknown-key handling behavior","scope":"For each artifact type, submit a save payload with a known-good extension plus one unknown key. Classify current behavior: silently_dropped (save succeeds, key not persisted), error_returned (save rejected), partial_write (some keys written, unknown dropped). Document actual behavior per type.","excluded":"No fixes. Classification only.","completion_condition":"Every artifact type tested. Each has classification: artifact_type → unknown_key_behavior → response_code → was_key_persisted."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '228ab8ed-1224-48a6-b410-cbc16c7f1e59' AND title = 'Classify current unknown-key handling behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define extension key validation contract',
  'Design: define per-type extension key allowlist and rejection contract',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '228ab8ed-1224-48a6-b410-cbc16c7f1e59',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define extension key validation contract","scope":"Using Leaf 1 allowlists, define the contract: (1) Save Validate_Request must check all incoming extension keys against type-specific allowlist, (2) any key not in allowlist triggers UNKNOWN_EXTENSION_KEY with artifact_type, allowed_keys, rejected_keys in error.details, (3) no partial acceptance. This becomes acceptance criteria.","excluded":"No implementation. Contract definition only.","completion_condition":"Written contract with: allowlist per type, error code and shape, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '228ab8ed-1224-48a6-b410-cbc16c7f1e59' AND title = 'Define extension key validation contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate extension key enforcement',
  'Validation: verify all types reject unknown extension keys with correct error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '228ab8ed-1224-48a6-b410-cbc16c7f1e59',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate extension key enforcement","scope":"For every artifact type: (1) submit save with valid extension keys only — verify save succeeds, (2) submit save with one unknown extension key — verify rejected with UNKNOWN_EXTENSION_KEY, (3) verify error.details contains artifact_type, allowed_keys, rejected_keys (exact field presence check), (4) verify no silent drops via post-save query confirming unknown key is NOT in DB, (5) test every forbidden state from gateway_boundary: silent drop, ok:true with ignored key, partial write, (6) verify correct error code string match.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All types tested. All pass against Leaf 3 contract. Zero silent drops. All forbidden states confirmed absent."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '228ab8ed-1224-48a6-b410-cbc16c7f1e59' AND title = 'Validate extension key enforcement' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Extension Key Allowlist',
  'Documentation: replace silent-drop language with rejection enforcement in Payload Discipline',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '228ab8ed-1224-48a6-b410-cbc16c7f1e59',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document extension key allowlist enforcement","scope":"Replace silently dropped language in Payload Discipline with rejected with validation error. Add extension key reference table per type. Update error inventory with UNKNOWN_EXTENSION_KEY.","excluded":"No code changes.","completion_condition":"Payload Discipline updated. Error inventory updated. Extension key allowlist table documented."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '228ab8ed-1224-48a6-b410-cbc16c7f1e59' AND title = 'Documentation update — Extension Key Allowlist' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 2: Reject Unknown Top-Level Fields (b84e1ccf)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate allowed top-level fields for Save action',
  'Analysis: extract canonical top-level field set for Save from Normalize_Request and Gatekeeper',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate allowed top-level fields for Save action","scope":"For the Save action only, extract the canonical top-level field set from Gateway Normalize_Request and Gatekeeper code. Document: allowed_fields[] → source_node → field_purpose. Include all fields the Save path references: gw_action, gw_workspace_id, artifact_type, title, summary, priority, tags, extension, content, parent_artifact_id, semantic_type_id, and any others.","excluded":"No other actions. No classification. No fixes. Enumeration only.","completion_condition":"Complete top-level field allowlist for Save action documented with source references."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76' AND title = 'Enumerate allowed top-level fields for Save action' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify current unknown-field handling for Save',
  'Analysis: test Save with unknown top-level fields and classify behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify current unknown-field handling for Save","scope":"Submit a Save payload with valid fields plus one unknown top-level field (e.g., foo: bar). Classify behavior: silently_ignored (save succeeds, field not referenced), error_returned (save rejected), field_forwarded (unknown field passed to sub-workflow). Test with multiple unknown fields to confirm consistent behavior.","excluded":"No fixes. Classification only.","completion_condition":"Save action tested with unknown fields. Behavior classified: unknown_field_behavior → response → was_field_forwarded."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76' AND title = 'Classify current unknown-field handling for Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define top-level field validation contract for Save',
  'Design: define Save-specific top-level field allowlist and rejection contract',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define top-level field validation contract for Save","scope":"Define the contract for Save action: (1) after action/type validation, check all top-level keys against Save-specific allowlist, (2) unknown keys trigger UNKNOWN_FIELD with action, allowed_fields, rejected_fields in error.details, (3) no partial acceptance. Determine placement: Gatekeeper (before routing) vs Save Normalize_Request. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: Save allowlist, error code and shape, placement decision, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76' AND title = 'Define top-level field validation contract for Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate top-level field enforcement for Save',
  'Validation: verify Save rejects unknown top-level fields with correct error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate top-level field enforcement for Save","scope":"For Save action: (1) valid Save payload with only allowlisted fields — verify save succeeds, (2) Save payload with one unknown top-level field — verify rejected with UNKNOWN_FIELD, (3) verify error.details contains action (artifact.save), allowed_fields (exact list), rejected_fields (exact list), (4) Save payload with multiple unknown fields — verify all listed in rejected_fields, (5) test every forbidden state from gateway_boundary: silent ignore, ok:true with stripped fields, partial processing, (6) verify non-Save actions are NOT affected by this change.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"Save action tested exhaustively. All pass against Leaf 3 contract. Zero silent ignores. Non-Save actions unaffected."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76' AND title = 'Validate top-level field enforcement for Save' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update + expansion plan — Top-Level Fields',
  'Documentation: document Save field allowlist and expansion plan for remaining actions',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document Save field allowlist and expansion plan","scope":"Add allowed top-level fields for Save to QSB Payload Format pack and Gateway README. Update error inventory with UNKNOWN_FIELD. Document expansion plan: after Save is validated, apply same pattern to Update → Promote → Query → List → Delete → Restore → Messaging actions. Each expansion is a separate future leaf set.","excluded":"No code changes. No implementation of other actions.","completion_condition":"Save field allowlist documented. Error code documented. Expansion plan written for remaining actions."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'b84e1ccf-6219-40be-b50b-1a2e27c0fa76' AND title = 'Documentation update + expansion plan — Top-Level Fields' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 3: Reject Empty Required Objects (2a4c0e50)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate required object fields per artifact type',
  'Analysis: catalog fields requiring presence AND non-empty content per type',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate required object fields per artifact type","scope":"For each artifact type, catalog fields where: (1) presence is required by Save Validate_Request, AND (2) content must be non-empty. Include: extension.payload (snapshot/restart), extension.entry_text (journal), extension.lifecycle_stage (project), extension.full_name/preferred_name/relationship_type (person). Document current validation: does it check presence only, or presence + non-empty?","excluded":"No fixes. Enumeration only.","completion_condition":"Table mapping: artifact_type → field → required (yes/no) → current_validation (presence_only/presence_and_content) → empty_value_behavior."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f' AND title = 'Enumerate required object fields per artifact type' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify empty-value handling behavior',
  'Analysis: test each required field with empty values and classify current behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify empty-value handling behavior","scope":"For each required field from Leaf 1, submit a save payload with the field present but empty (null, {}, or empty string as appropriate). Classify: rejected (validation error returned), accepted_and_written (empty value persisted to DB), accepted_and_defaulted (empty value replaced with default).","excluded":"No fixes. Classification only.","completion_condition":"Every required field tested with empty value. Each classified: field → empty_behavior → response → db_state."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f' AND title = 'Classify empty-value handling behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define empty-value rejection contract',
  'Design: define per-field empty value definitions and rejection rules',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define empty-value rejection contract","scope":"Define: (1) all required fields must be validated for non-empty content after presence check, (2) EMPTY_REQUIRED_FIELD error returned with field_name in details, (3) define empty per type: null for any, {} for objects, empty string for text. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: per-field empty definitions, error code and shape, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f' AND title = 'Define empty-value rejection contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate empty-value rejection',
  'Validation: verify all required fields reject empty values with correct error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate empty-value rejection","scope":"For every required field: (1) valid non-empty value — verify save succeeds, (2) null value — verify rejected with EMPTY_REQUIRED_FIELD, (3) empty object {} — verify rejected, (4) empty string — verify rejected for text fields, (5) verify error.details contains field_name (exact match), (6) test every forbidden state from gateway_boundary: silent null acceptance, empty object persisted, empty string persisted, (7) verify optional fields still accept null/empty without error.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All required fields tested. All empty values rejected. Optional fields unaffected. Zero silent acceptance."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f' AND title = 'Validate empty-value rejection' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Empty Required Objects',
  'Documentation: add per-field validation table and EMPTY_REQUIRED_FIELD error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document empty-value rejection enforcement","scope":"Update Payload Discipline with per-field validation table showing required + non-empty. Add EMPTY_REQUIRED_FIELD to error inventory.","excluded":"No code changes.","completion_condition":"Validation table documented. Error code documented."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '2a4c0e50-b229-42a7-ac0b-b46d6be2f23f' AND title = 'Documentation update — Empty Required Objects' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 4: Reject append_log Reserved Key (a5cfbc01)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate append_log usage in content pipeline',
  'Analysis: trace append_log read/write lifecycle in Update content merge and append paths',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a5cfbc01-0024-487d-97bc-03ce71036a1a',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate append_log usage in content pipeline","scope":"Trace the content merge and content_append paths in the Update sub-workflow. Document: (1) where append_log is read/written by the system, (2) where client content is merged, (3) whether any check for append_log currently exists. Cover both content (merge/replace) and content_append paths.","excluded":"No fixes. Enumeration only.","completion_condition":"Full trace of append_log lifecycle in Update sub-workflow documented. Current client-side protection status confirmed (exists or absent)."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a5cfbc01-0024-487d-97bc-03ce71036a1a' AND title = 'Enumerate append_log usage in content pipeline' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify current append_log handling',
  'Analysis: test both content paths with append_log key and classify behavior',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a5cfbc01-0024-487d-97bc-03ce71036a1a',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify current append_log handling","scope":"Submit content update with append_log key in payload. Test both content (merge) and content_append paths. Classify per path: rejected (error returned), silently_merged (append_log overwritten), silently_stripped (key removed before merge), partial (key accepted in one path, rejected in other).","excluded":"No fixes. Classification only.","completion_condition":"Both paths tested. Current behavior classified per path: path → classification → response_code → db_state."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a5cfbc01-0024-487d-97bc-03ce71036a1a' AND title = 'Classify current append_log handling' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define reserved-key rejection contract',
  'Design: define RESERVED_KEY_CONFLICT error and check placement for both content paths',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a5cfbc01-0024-487d-97bc-03ce71036a1a',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define reserved-key rejection contract","scope":"Define: (1) content and content_append payloads must be checked for append_log key before processing, (2) RESERVED_KEY_CONFLICT error returned with key_name in details, (3) check applies to both merge and append paths, (4) content_mode: replace also checked. Define placement in Update pipeline (before Compute_Mixed).","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: check placement, error code and shape, all paths covered, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a5cfbc01-0024-487d-97bc-03ce71036a1a' AND title = 'Define reserved-key rejection contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate reserved-key rejection',
  'Validation: verify append_log rejected on all content paths with correct error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a5cfbc01-0024-487d-97bc-03ce71036a1a',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate reserved-key rejection","scope":"For each content path (merge, replace, content_append): (1) content without append_log — verify accepted normally, (2) content with append_log — verify rejected with RESERVED_KEY_CONFLICT, (3) verify error.details contains key_name (exact match append_log), (4) verify system-managed append_log preserved after valid content_append operation, (5) test every forbidden state from gateway_boundary: silent merge, silent strip, partial acceptance, (6) verify correct error code string.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All paths tested. All append_log payloads rejected. System append_log preserved. All forbidden states confirmed absent."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a5cfbc01-0024-487d-97bc-03ce71036a1a' AND title = 'Validate reserved-key rejection' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Reserved Key',
  'Documentation: document append_log as system-reserved with RESERVED_KEY_CONFLICT error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'a5cfbc01-0024-487d-97bc-03ce71036a1a',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document reserved key enforcement","scope":"Update Quick Reference and Payload Discipline: document append_log as system-reserved with deterministic rejection (not just guidance). Add RESERVED_KEY_CONFLICT to error inventory.","excluded":"No code changes.","completion_condition":"Reserved key documented as enforced. Error code documented. Guidance language replaced with enforcement language."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'a5cfbc01-0024-487d-97bc-03ce71036a1a' AND title = 'Documentation update — Reserved Key' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 5: Snapshot for-q Auto-Injection (00aafb01)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate current for-q tagging behavior on snapshots',
  'Analysis: establish baseline for-q presence on snapshots and trace Save tag pipeline',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '00aafb01-67dc-485c-90d8-ac97287bee2e',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate current for-q tagging behavior on snapshots","scope":"Query existing snapshots to establish baseline: (1) what percentage have for-q tag, (2) correlation between semantic_type_id and for-q presence, (3) identify snapshots missing for-q that should have it. Document the current tag injection pipeline in Save sub-workflow — does any auto-injection exist today?","excluded":"No fixes. Baseline enumeration only.","completion_condition":"Baseline stats documented. Current Save pipeline tag handling traced. Gap between expected and actual for-q presence quantified."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '00aafb01-67dc-485c-90d8-ac97287bee2e' AND title = 'Enumerate current for-q tagging behavior on snapshots' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify qualifying vs non-qualifying semantic types',
  'Analysis: classify each semantic type for for-q auto-injection eligibility',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '00aafb01-67dc-485c-90d8-ac97287bee2e',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify qualifying vs non-qualifying semantic types","scope":"For each semantic_type_id in the registry (9 values), classify as qualifying (for-q auto-injection) or non-qualifying. Proposed qualifying set: governance, execution-core, infrastructure, platform. Proposed non-qualifying: sales, marketing, exploratory, alignment, product. Document rationale for each classification.","excluded":"No fixes. Classification only.","completion_condition":"Complete classification table: semantic_type_key → qualifying (yes/no) → rationale. All 9 registry values classified."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '00aafb01-67dc-485c-90d8-ac97287bee2e' AND title = 'Classify qualifying vs non-qualifying semantic types' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define for-q auto-injection contract',
  'Design: define trigger conditions, injection logic, edge cases, and placement',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '00aafb01-67dc-485c-90d8-ac97287bee2e',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define for-q auto-injection contract","scope":"Define: (1) injection trigger: artifact_type=snapshot AND semantic_type_id in qualifying set, (2) injection behavior: merge for-q into tags array, (3) dedup: if for-q already present, do not duplicate, (4) null handling: if tags is null, create array with for-q, (5) placement in Save pipeline: after semantic type resolution, before DB insert, (6) non-injection guarantee: non-qualifying types and non-snapshot types MUST NOT be affected. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: trigger conditions, injection logic, edge cases (null tags, existing for-q, non-qualifying types), placement, non-injection guarantees, forbidden states."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '00aafb01-67dc-485c-90d8-ac97287bee2e' AND title = 'Define for-q auto-injection contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate for-q auto-injection',
  'Validation: exhaustively test injection, non-injection, dedup, and null-tag scenarios',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '00aafb01-67dc-485c-90d8-ac97287bee2e',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate for-q auto-injection","scope":"Test exhaustively: (1) qualifying snapshot (governance semantic type) — verify for-q present in persisted tags, (2) non-qualifying snapshot (exploratory) — verify for-q NOT injected, (3) snapshot with for-q already in tags — verify no duplicate (tags array contains exactly one for-q), (4) snapshot with null tags — verify tags array created with for-q, (5) non-snapshot artifact (project, journal) with qualifying semantic type — verify for-q NOT injected, (6) test every forbidden state from gateway_boundary: missing for-q on qualifying, injected on non-qualifying, duplicate, injection on non-snapshot.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All scenarios tested. All pass against Leaf 3 contract. All forbidden states confirmed absent."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '00aafb01-67dc-485c-90d8-ac97287bee2e' AND title = 'Validate for-q auto-injection' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — for-q Auto-Injection',
  'Documentation: remove Q compliance requirement and document auto-injection',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '00aafb01-67dc-485c-90d8-ac97287bee2e',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document for-q auto-injection and remove Q compliance surface","scope":"Remove Q must remember for-q on snapshots from Prime SI and Akara SI. Document auto-injection in Payload Discipline with trigger conditions and qualifying type table. Update tagging governance section. Reduce Q compliance surface.","excluded":"No code changes.","completion_condition":"SI compliance requirement removed. Auto-injection documented with trigger table. Tagging governance updated."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '00aafb01-67dc-485c-90d8-ac97287bee2e' AND title = 'Documentation update — for-q Auto-Injection' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 6: Execution Status Auto-Default (89626be2)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate current execution_status behavior on insert',
  'Analysis: trace Save pipeline to determine execution_status default per type',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '89626be2-5f22-43e2-b439-6e6f0cabed21',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate current execution_status behavior on insert","scope":"For each execution-layer type (branch, limb, leaf, twig), trace the Save pipeline to determine: (1) is execution_status set in the DB insert node, (2) what value is used when caller omits it, (3) what is the actual DB state after insert without explicit status. Also check non-execution types to confirm they are NOT affected.","excluded":"No fixes. Enumeration only.","completion_condition":"Table: artifact_type → is_execution_type → current_default_behavior → actual_db_value_when_omitted."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '89626be2-5f22-43e2-b439-6e6f0cabed21' AND title = 'Enumerate current execution_status behavior on insert' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify defaulting gaps',
  'Analysis: classify each execution type as correctly defaulted, null on insert, or inconsistent',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '89626be2-5f22-43e2-b439-6e6f0cabed21',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify defaulting gaps","scope":"For each execution type from Leaf 1, classify: correctly_defaulted (already sets not_started), null_on_insert (no default, NULL written), inconsistent (some code paths default, others do not). Verify by creating test artifacts without execution_status and querying DB.","excluded":"No fixes. Classification only.","completion_condition":"Every execution type classified. Gap count known."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '89626be2-5f22-43e2-b439-6e6f0cabed21' AND title = 'Classify defaulting gaps' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define execution_status auto-default contract',
  'Design: define type list, default value, override rules, and exclusion list',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '89626be2-5f22-43e2-b439-6e6f0cabed21',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define execution_status auto-default contract","scope":"Define: (1) execution-layer types: branch, limb, leaf, twig, (2) default value: not_started, (3) behavior: apply default ONLY when caller omits execution_status, (4) never override explicit value, (5) never apply to non-execution types. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: type list, default value, override rules, exclusion list, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '89626be2-5f22-43e2-b439-6e6f0cabed21' AND title = 'Define execution_status auto-default contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate execution_status defaulting',
  'Validation: verify auto-default, explicit preservation, and non-execution type isolation',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '89626be2-5f22-43e2-b439-6e6f0cabed21',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate execution_status defaulting","scope":"For each execution type: (1) save without execution_status — verify DB shows not_started (exact value check), (2) save with explicit execution_status=in_progress — verify caller value preserved (not overridden), (3) save non-execution type (project) without execution_status — verify NULL preserved (no unwanted default), (4) test every forbidden state from gateway_boundary: NULL on execution type, override of explicit value, default on non-execution type, (5) verify correct DB state via post-save query.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All execution types tested. All default correctly. Non-execution types unaffected. All forbidden states confirmed absent."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '89626be2-5f22-43e2-b439-6e6f0cabed21' AND title = 'Validate execution_status defaulting' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Execution Status Auto-Default',
  'Documentation: document auto-default behavior and CmdCtr implications',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '89626be2-5f22-43e2-b439-6e6f0cabed21',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document execution_status auto-default","scope":"Document auto-default behavior in Quick Reference and Payload Discipline. Update CmdCtr docs if scan behavior changes (NULL no longer expected for execution types).","excluded":"No code changes.","completion_condition":"Auto-default documented. CmdCtr implications noted."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '89626be2-5f22-43e2-b439-6e6f0cabed21' AND title = 'Documentation update — Execution Status Auto-Default' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 7: Enforce Parent Requirement for Child Types (d93ed8e7)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate current parent validation behavior per type',
  'Analysis: test each child type with and without parent_artifact_id',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate current parent validation behavior per type","scope":"For each child type (branch, leaf, limb, twig), test: (1) save with parent_artifact_id — succeeds, (2) save without parent_artifact_id — what happens? Also test non-child types (project, journal, snapshot) to confirm they allow null parent. Document current behavior.","excluded":"No fixes. Enumeration only.","completion_condition":"Table: artifact_type → is_child_type → parent_required_currently → behavior_when_missing."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472' AND title = 'Enumerate current parent validation behavior per type' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify orphan creation gaps',
  'Analysis: classify which child types can currently create orphaned artifacts',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify orphan creation gaps","scope":"For each child type from Leaf 1, classify: enforced (already rejects null parent), unprotected (accepts null parent silently), partially_enforced (some code paths check, others do not). Document which types can currently create orphans.","excluded":"No fixes. Classification only.","completion_condition":"Every child type classified. Orphan-capable types identified."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472' AND title = 'Classify orphan creation gaps' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define parent requirement contract',
  'Design: define child type list, validation rule, error code, and exemptions',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define parent requirement contract","scope":"Define: (1) child types: branch, leaf, limb, twig, (2) parent_artifact_id must be present and non-null on save, (3) PARENT_REQUIRED error with artifact_type in details, (4) non-child types (project, journal, snapshot, restart, instruction_pack, person) explicitly exempt. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: child type list, validation rule, error code and shape, exemption list, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472' AND title = 'Define parent requirement contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate parent enforcement',
  'Validation: verify all child types reject orphan creation and non-child types unaffected',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate parent enforcement","scope":"For each child type: (1) save with valid parent — verify succeeds, (2) save without parent — verify rejected with PARENT_REQUIRED, (3) save with parent=null explicitly — verify rejected, (4) verify error.details contains artifact_type (exact match). For each non-child type: (5) save without parent — verify still succeeds. Test every forbidden state from gateway_boundary: NULL parent on child, absent parent on child, ok:true for orphan.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All child types reject orphan creation. All non-child types unaffected. All forbidden states confirmed absent."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472' AND title = 'Validate parent enforcement' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Parent Requirement',
  'Documentation: document parent requirement as Gateway-enforced with PARENT_REQUIRED error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document parent requirement enforcement","scope":"Update Payload Discipline: document parent requirement as Gateway-enforced (not Q guidance). Add PARENT_REQUIRED to error inventory. Update Mother Tree topology docs.","excluded":"No code changes.","completion_condition":"Parent requirement documented as enforced. Error code documented."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = 'd93ed8e7-2620-4fe7-9b9b-a17d42a5a472' AND title = 'Documentation update — Parent Requirement' AND deleted_at IS NULL);

-- ================================================================
-- BRANCH 8: Twig Content Completeness (11f1e134)
-- ================================================================

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Enumerate current twig content validation behavior',
  'Analysis: test Save pipeline for twigs with complete, empty, partial, and missing content',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '11f1e134-e929-482f-8046-f3853d71a092',
  '{"leaf_number":1,"leaf_type":"analysis","purpose":"Enumerate current twig content validation behavior","scope":"Test current Save pipeline for twigs: (1) save with complete content (all 4 keys) — succeeds, (2) save with no content — what happens, (3) save with partial content (1-3 keys) — what happens, (4) save with empty-string values for keys — what happens. Document current behavior.","excluded":"No fixes. Enumeration only.","completion_condition":"Table: scenario → current_behavior → content_persisted → response."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '11f1e134-e929-482f-8046-f3853d71a092' AND title = 'Enumerate current twig content validation behavior' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Classify content completeness gaps',
  'Analysis: classify each content scenario and confirm required key set',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '11f1e134-e929-482f-8046-f3853d71a092',
  '{"leaf_number":2,"leaf_type":"analysis","purpose":"Classify content completeness gaps","scope":"From Leaf 1, classify each scenario: enforced (already rejected), unprotected (accepted without required keys), partially_enforced (some keys checked, others not). Confirm the canonical required key set: idea, why_now, problem_touched, future_hook.","excluded":"No fixes. Classification only.","completion_condition":"Gap analysis complete. Required key set confirmed or revised. Each scenario classified."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '11f1e134-e929-482f-8046-f3853d71a092' AND title = 'Classify content completeness gaps' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Define twig content completeness contract',
  'Design: define required keys, validation rules, and TWIG_CONTENT_INCOMPLETE error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '11f1e134-e929-482f-8046-f3853d71a092',
  '{"leaf_number":3,"leaf_type":"design","purpose":"Define twig content completeness contract","scope":"Define: (1) required keys: idea, why_now, problem_touched, future_hook (or revised set from Leaf 2), (2) all must be present and non-empty strings, (3) content object itself must be present, (4) TWIG_CONTENT_INCOMPLETE error with missing_keys array in details. This becomes acceptance criteria.","excluded":"No implementation. Contract only.","completion_condition":"Written contract with: required key list, validation rules, error code and shape, forbidden states, pass/fail criteria."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '11f1e134-e929-482f-8046-f3853d71a092' AND title = 'Define twig content completeness contract' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Validate twig content enforcement',
  'Validation: exhaustively test complete, partial, empty, and missing content scenarios',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '11f1e134-e929-482f-8046-f3853d71a092',
  '{"leaf_number":5,"leaf_type":"validation","purpose":"Validate twig content enforcement","scope":"Test exhaustively: (1) complete twig (all 4 keys, non-empty) — verify succeeds, (2) no content object — verify rejected with TWIG_CONTENT_INCOMPLETE, (3) partial content (missing 1 key) — verify rejected with missing key listed in error.details.missing_keys, (4) empty-string value for a required key — verify rejected, (5) null value for a required key — verify rejected, (6) non-twig types with no content — verify unaffected, (7) test every forbidden state from gateway_boundary: no content, missing keys, empty values, ok:true for incomplete.","excluded":"No inline fixes. Failures create new implementation leaf.","completion_condition":"All scenarios tested. Complete twigs pass. Incomplete twigs rejected with correct error and missing_keys details. Non-twig types unaffected."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '11f1e134-e929-482f-8046-f3853d71a092' AND title = 'Validate twig content enforcement' AND deleted_at IS NULL);

INSERT INTO public.qxb_artifact (workspace_id, owner_user_id, artifact_type, title, summary, priority, tags, parent_artifact_id, content)
SELECT 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a', 'c52c7a57-74ad-433d-a07c-4dcac1778672', 'leaf',
  'Documentation update — Twig Content Completeness',
  'Documentation: document twig content as Gateway-enforced with TWIG_CONTENT_INCOMPLETE error',
  3, '["for-q", "compliance-to-enforcement", "leaf"]'::jsonb, '11f1e134-e929-482f-8046-f3853d71a092',
  '{"leaf_number":6,"leaf_type":"documentation","purpose":"Document twig content enforcement","scope":"Update QPM Build Process and Payload Discipline: document twig content as Gateway-enforced. Update fast-capture guidance to reflect required keys. Add TWIG_CONTENT_INCOMPLETE to error inventory.","excluded":"No code changes.","completion_condition":"Content requirement documented as enforced. Error code documented. Fast-capture guidance updated."}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.qxb_artifact WHERE parent_artifact_id = '11f1e134-e929-482f-8046-f3853d71a092' AND title = 'Documentation update — Twig Content Completeness' AND deleted_at IS NULL);
