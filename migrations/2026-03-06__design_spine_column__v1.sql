-- Migration: Add design_spine JSONB column to qxb_artifact_project
-- Thread: T87 (gap closure)
-- Date: 2026-03-06
-- DDL: v2.6 -> v2.7
--
-- Context:
--   T87 deployed Check_Mutability_Rules v8 (design_spine in project extension allowlist),
--   Canonical v4 documentation, and Phase2C D20-D23 certification tests.
--   However, the actual DB column was never created.
--   Gateway accepted design_spine, processed it through the Update workflow,
--   returned ok:true, but values were silently discarded.
--
-- This migration closes the gap. No workflow or Gateway changes needed.
--
-- Safety: Non-destructive, nullable, backward compatible.
--   Existing rows get design_spine = NULL.

ALTER TABLE public.qxb_artifact_project
ADD COLUMN design_spine jsonb;
