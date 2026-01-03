# KGB — Save Project (v1) — 2026-01-02

## Purpose
Prove `artifact.save` can create a **project** artifact correctly (spine + extension), under RLS, with stable response.

## Pre-reqs
- Gateway router is deployed
- Supabase tables exist: `qxb_artifact`, `qxb_artifact_project` (or current typed table names)
- Owner identity credentials available in n8n

## Test steps
1. Call `artifact.save` with a minimal valid Project payload.
2. Confirm response includes:
   - `artifact_id`
   - `artifact_type = project`
   - `title`
   - `created_at`
3. Call `artifact.query` on that `artifact_id`
4. Confirm the saved record matches exactly what was written (within allowed server-set fields).
5. Call `artifact.list` for `project`
6. Confirm the new artifact appears in list results.

## Expected results
- No orphan spine rows
- Typed row exists and joins correctly
- Event log appended (if enabled)
- Errors are allow-listed and meaningful

## Negative tests (minimum)
- Missing title → validation error
- Bad artifact_type → allow-list error
- Wrong workspace id → forbidden/guarded error

## Evidence to capture
- Request payload (redacted)
- Response JSON
- Query + list results
- Any workflow run IDs (if helpful)

