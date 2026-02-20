-- ============================================
-- MIGRATION: Artifact Type Registry — Fix updated_at Semantics
-- Version: 1.0
-- Date: 2026-01-20
-- ============================================
--
-- Issue: The AFTER UPDATE audit trigger attempted to set NEW.updated_at,
-- but AFTER triggers cannot modify persisted row data.
--
-- Fix: Add a separate BEFORE UPDATE trigger to set updated_at := now().
-- The audit trigger remains AFTER (append-only logging).
--
-- Receipt (executed 2026-01-20):
--   created_at = 2026-01-20 00:04:35.537412+00
--   updated_at = 2026-01-20 00:09:37.490303+00 (advanced after UPDATE)
--   Audit: UPDATE logged with old_enabled=true, new_enabled=false
--
-- ============================================

-- 1) Create BEFORE UPDATE function for updated_at
CREATE OR REPLACE FUNCTION public.fn_artifact_type_registry_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2) Create BEFORE UPDATE trigger (idempotent)
DROP TRIGGER IF EXISTS trg_artifact_type_registry_set_updated_at
ON public.qxb_artifact_type_registry;

CREATE TRIGGER trg_artifact_type_registry_set_updated_at
BEFORE UPDATE ON public.qxb_artifact_type_registry
FOR EACH ROW
EXECUTE FUNCTION public.fn_artifact_type_registry_set_updated_at();

-- 3) Clean up AFTER audit trigger function (remove ineffective NEW.updated_at assignment)
CREATE OR REPLACE FUNCTION public.fn_audit_artifact_type_registry()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'INSERT', NULL, NEW.enabled);
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (NEW.artifact_type, 'UPDATE', OLD.enabled, NEW.enabled);
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.qxb_artifact_type_registry_audit
            (artifact_type, action, old_enabled, new_enabled)
        VALUES
            (OLD.artifact_type, 'DELETE', OLD.enabled, NULL);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- A) Check current state before update
-- SELECT artifact_type, enabled, created_at, updated_at
-- FROM public.qxb_artifact_type_registry
-- WHERE artifact_type = 'journal';

-- B) Toggle enabled to trigger update
-- UPDATE public.qxb_artifact_type_registry
-- SET enabled = NOT enabled
-- WHERE artifact_type = 'journal';

-- C) Verify updated_at changed after update
-- SELECT artifact_type, enabled, created_at, updated_at
-- FROM public.qxb_artifact_type_registry
-- WHERE artifact_type = 'journal';

-- D) Verify latest audit rows show old/new enabled
-- SELECT artifact_type, action, old_enabled, new_enabled, actor, created_at
-- FROM public.qxb_artifact_type_registry_audit
-- WHERE artifact_type = 'journal'
-- ORDER BY created_at DESC
-- LIMIT 3;

-- E) Final state verification
-- SELECT
--     'Registry' AS source,
--     artifact_type,
--     enabled,
--     created_at,
--     updated_at
-- FROM public.qxb_artifact_type_registry
-- WHERE artifact_type = 'journal'
-- UNION ALL
-- SELECT
--     'Audit' AS source,
--     artifact_type,
--     new_enabled AS enabled,
--     created_at,
--     created_at AS updated_at
-- FROM public.qxb_artifact_type_registry_audit
-- WHERE artifact_type = 'journal'
-- ORDER BY created_at DESC;

-- ============================================
-- END OF MIGRATION
-- ============================================
