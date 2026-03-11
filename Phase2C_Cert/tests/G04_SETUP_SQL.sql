-- G04 — T71 Manual Dependency Setup
-- Run this SQL in Supabase SQL Editor AFTER G01-G03 pass
-- and BEFORE running G05+.
--
-- Replace the UUIDs below with the captured values from G02 and G03:
--   T71_LEAF_A_ID → from G02 output
--   T71_LEAF_B_ID → from G03 output
--
-- This inserts: LEAF_B depends on LEAF_A
-- (LEAF_B cannot complete until LEAF_A is complete)

INSERT INTO public.qxb_artifact_dependency (
  artifact_id,
  depends_on_artifact_id,
  workspace_id
)
VALUES (
  '<T71_LEAF_B_ID>',   -- LEAF_B (the dependent)
  '<T71_LEAF_A_ID>',   -- LEAF_A (the dependency / blocker)
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'  -- Qwrk Personal workspace
);

-- Verify:
SELECT d.*, a.title, a.execution_status
FROM public.qxb_artifact_dependency d
JOIN public.qxb_artifact a ON a.artifact_id = d.depends_on_artifact_id
WHERE d.artifact_id = '<T71_LEAF_B_ID>';
