-- PROOF: Corrected Thorn Artifact Insert (v1.1)
-- Purpose: Demonstrate schema-accurate thorn insert using v1.1 corrections
-- Date: 2026-01-04
-- Status: Runnable in Supabase SQL Editor
-- Context: Uses KGB workspace and user IDs

-- **v1.1 Corrections Demonstrated:**
-- ✅ severity is INTEGER (1-5), not text enum
-- ✅ status (not review_status)
-- ✅ resolution_notes TEXT (not resolution enum)

BEGIN;

-- Step 1: Insert spine
WITH new_artifact AS (
  INSERT INTO qxb_artifact (
    workspace_id,
    owner_user_id,
    artifact_type,
    title,
    summary,
    tags
  ) VALUES (
    'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'::uuid,  -- Master Joel Workspace
    'c52c7a57-74ad-433d-a07c-4dcac1778672'::uuid,  -- Joel's qxb_user.user_id
    'thorn',
    'PROOF: v1.1 Template Validation — Schema-Accurate Thorn',
    'Test insert using corrected v1.1 template with INTEGER severity and correct column names',
    '["proof", "v1.1", "schema-validation", "thorn"]'::jsonb
  )
  RETURNING artifact_id
)

-- Step 2: Insert thorn extension with CORRECTED columns
INSERT INTO qxb_artifact_thorn (
  artifact_id,
  source_system,
  source_workflow,
  source_execution_id,
  severity,           -- ✅ INTEGER (1-5)
  status,             -- ✅ Correct column name (not review_status)
  summary,
  details_json,
  resolution_notes    -- ✅ TEXT column (not resolution enum)
)
SELECT
  artifact_id,
  'n8n',
  'PROOF_v1.1_Schema_Validation',
  'proof-execution-2026-01-04',
  4,                  -- ✅ INTEGER severity: 4 = High
  'open',             -- ✅ Status: 'open', 'acknowledged', 'resolved', 'ignored'
  'v1.1 template validation: INTEGER severity (4=high), status column, resolution_notes TEXT',
  '{
    "proof_purpose": "Validate v1.1 schema corrections",
    "corrections_validated": [
      "severity is INTEGER (value: 4 = high severity)",
      "status column exists (value: open)",
      "resolution_notes is TEXT (value: NULL for open status)"
    ],
    "v1_errors_fixed": [
      "severity was text enum (low/medium/high) - now INTEGER 1-5",
      "review_status column name - now status",
      "resolution enum - now resolution_notes TEXT"
    ],
    "test_date": "2026-01-04",
    "expected_result": "INSERT should succeed with no schema errors"
  }'::jsonb,
  NULL                -- ✅ resolution_notes: NULL for open status (set when resolved)
FROM new_artifact
RETURNING artifact_id, source_system, severity, status, resolution_notes;

COMMIT;

-- Expected Output:
-- ✅ Transaction completes successfully
-- ✅ Returns artifact_id (UUID), source_system ('n8n'), severity (4), status ('open'), resolution_notes (NULL)
-- ✅ No errors: "column does not exist" or "invalid input syntax"

-- Validation Queries (run after INSERT):
-- 1. Verify artifact spine:
-- SELECT artifact_id, artifact_type, title, tags FROM qxb_artifact WHERE title LIKE '%PROOF: v1.1%';

-- 2. Verify thorn extension with corrected columns:
-- SELECT artifact_id, severity, status, resolution_notes FROM qxb_artifact_thorn
-- WHERE source_workflow = 'PROOF_v1.1_Schema_Validation';

-- 3. Verify severity is stored as INTEGER:
-- SELECT pg_typeof(severity) AS severity_type, severity FROM qxb_artifact_thorn
-- WHERE source_workflow = 'PROOF_v1.1_Schema_Validation';
-- Expected: severity_type = 'integer', severity = 4

-- Cleanup (optional):
-- DELETE FROM qxb_artifact WHERE title LIKE '%PROOF: v1.1%';
