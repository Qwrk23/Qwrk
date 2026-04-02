-- =============================================================================
-- T150: Person Artifact Type — Forward Migration v1.1
-- =============================================================================
-- Date:    2026-03-22
-- Thread:  T150 (Branch 2 — Supabase Schema & Data Model)
-- DDL:     v2.9 → v2.10
-- CHECK:   v7 → v8 (14 → 15 types, adds 'person')
--
-- Covers Leaves: 2.1–2.12 (CHECK, semantic registry, CREATE TABLE, columns,
--   JSONB fields, indexes, RLS, trigger, migration bundle)
--
-- Execution: Run in Supabase SQL Editor as a single transaction.
-- Rollback:  See 2026-03-22__person_artifact_type__rollback__v1.sql
-- =============================================================================

BEGIN;

-- ============================================================================
-- STEP 0: Pre-validation — confirm existing data integrity
-- ============================================================================
-- Verify no unexpected artifact_type values exist before modifying constraint.
-- This SELECT should return exactly the 14 types in CHECK v7.
-- If any row appears that is NOT in the v7 set, STOP and investigate.

DO $$
DECLARE
  _unexpected_count integer;
BEGIN
  SELECT count(DISTINCT artifact_type) INTO _unexpected_count
  FROM public.qxb_artifact
  WHERE artifact_type NOT IN (
    'project', 'journal', 'restart', 'snapshot',
    'grass', 'thorn', 'forest', 'thicket', 'flower',
    'branch', 'leaf', 'instruction_pack', 'limb', 'twig'
  );
  IF _unexpected_count > 0 THEN
    RAISE EXCEPTION 'Pre-validation FAILED: % unexpected artifact_type value(s) found. Aborting migration.', _unexpected_count;
  END IF;
END $$;

-- ============================================================================
-- STEP 1: CHECK constraint upgrade v7 → v8 (Leaf 2.1)
-- ============================================================================
-- Drop existing v7, recreate as v8 with 'person' added.
-- No intermediate invalid state — both in same transaction.

ALTER TABLE public.qxb_artifact
  DROP CONSTRAINT qxb_artifact_artifact_type_check_v7;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_artifact_type_check_v8
  CHECK (artifact_type = ANY (ARRAY[
    'project'::text, 'journal'::text, 'restart'::text, 'snapshot'::text,
    'grass'::text, 'thorn'::text, 'forest'::text, 'thicket'::text, 'flower'::text,
    'branch'::text, 'leaf'::text, 'instruction_pack'::text, 'limb'::text, 'twig'::text,
    'person'::text
  ]));

-- ============================================================================
-- STEP 2: Update semantic_type_id conditional NOT NULL CHECK (Leaf 2.2)
-- ============================================================================
-- Person is a top-level type with its own extension table.
-- It MUST require semantic_type_id (same as project/snapshot/journal/restart).
-- Drop existing check, recreate with 'person' added to the required list.

ALTER TABLE public.qxb_artifact
  DROP CONSTRAINT qxb_artifact_semantic_type_required_for_top_level;

ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_semantic_type_required_for_top_level
  CHECK (
    (artifact_type NOT IN ('project', 'snapshot', 'journal', 'restart', 'person'))
    OR (semantic_type_id IS NOT NULL)
  );

-- ============================================================================
-- STEP 3: Register 'person' in qxb_artifact_type_registry (Leaf 2.2)
-- ============================================================================
-- Type registry controls Gateway Save routing. 'person' must be enabled.

INSERT INTO public.qxb_artifact_type_registry (artifact_type, enabled, description)
VALUES ('person', true, 'Person artifact type — represents real individuals in the operator''s network. Extension table: qxb_artifact_person. T150 (2026-03-22).')
ON CONFLICT (artifact_type) DO NOTHING;

-- ============================================================================
-- STEP 4: CREATE TABLE qxb_artifact_person (Leaves 2.3–2.6)
-- ============================================================================
-- Extension table following class-table inheritance (PK=FK to spine).
-- All columns derived from Branch 1 design (Leaves 1.1–1.12).
-- Flat columns from Leaf 2.4, text fields from Leaf 2.5, JSONB from Leaf 2.6.

CREATE TABLE public.qxb_artifact_person (
    -- PK=FK relationship to spine
    artifact_id                uuid        NOT NULL,

    -- Identity (Leaf 1.2 / Leaf 2.4)
    full_name                  text        NOT NULL,
    preferred_name             text        NOT NULL,
    relationship_type          text        NOT NULL,
    status                     text        NOT NULL DEFAULT 'active',
    pronouns                   text,

    -- Contact (Leaf 1.3 / Leaf 2.4)
    personal_email             text,
    work_email                 text,
    mobile_phone               text,
    work_phone                 text,
    home_phone                 text,
    preferred_contact_method   text,
    preferred_contact_channel  text,
    timezone                   text,

    -- Professional & Relationship Context (Leaf 1.4 / Leaf 2.4)
    company                    text,
    title                      text,
    department                 text,
    importance_level           text,

    -- Interaction Tracking (Leaf 1.7 / Leaf 2.4)
    interaction_frequency      text,
    last_contacted_at          timestamptz,
    next_follow_up_at          timestamptz,
    do_not_contact             boolean     NOT NULL DEFAULT false,

    -- JSONB Fields (Leaf 1.3–1.6 / Leaf 2.6)
    address                    jsonb,       -- mailing address object
    communication_style        jsonb,       -- {tone, detail_level, decision_style}
    what_they_care_about       jsonb,       -- array of priorities/interests
    key_facts                  jsonb,       -- array of durable facts
    preferences                jsonb,       -- array of communication preferences

    -- Timestamps
    created_at                 timestamptz  NOT NULL DEFAULT now(),
    updated_at                 timestamptz  NOT NULL DEFAULT now(),

    -- PATCH: JSONB array shape validation (Q audit finding)
    -- Enforces array type for fields documented as array-shaped.
    -- Does NOT constrain element content — only top-level type.
    CONSTRAINT qxb_artifact_person_key_facts_is_array
      CHECK (key_facts IS NULL OR jsonb_typeof(key_facts) = 'array'),
    CONSTRAINT qxb_artifact_person_what_they_care_about_is_array
      CHECK (what_they_care_about IS NULL OR jsonb_typeof(what_they_care_about) = 'array'),
    CONSTRAINT qxb_artifact_person_preferences_is_array
      CHECK (preferences IS NULL OR jsonb_typeof(preferences) = 'array')
);

COMMENT ON TABLE public.qxb_artifact_person IS
  'Person extension table. Extends qxb_artifact via PK=FK. Stores identity, contact, '
  'professional context, interaction tracking, and communication intelligence for '
  'real individuals in the operator''s network. T150 (2026-03-22).';

-- ============================================================================
-- STEP 5: Primary key + foreign key (Leaf 2.3)
-- ============================================================================

ALTER TABLE ONLY public.qxb_artifact_person
    ADD CONSTRAINT qxb_artifact_person_pkey PRIMARY KEY (artifact_id);

ALTER TABLE ONLY public.qxb_artifact_person
    ADD CONSTRAINT qxb_artifact_person_fk
    FOREIGN KEY (artifact_id) REFERENCES public.qxb_artifact(artifact_id)
    ON DELETE CASCADE;

-- ============================================================================
-- STEP 6: updated_at trigger (Required Adjustment #3)
-- ============================================================================
-- Uses existing shared trigger function qxb_set_updated_at().

CREATE TRIGGER qxb_artifact_person_set_updated_at
    BEFORE UPDATE ON public.qxb_artifact_person
    FOR EACH ROW
    EXECUTE FUNCTION public.qxb_set_updated_at();

-- ============================================================================
-- STEP 7: Indexes (Leaf 2.8)
-- ============================================================================
-- B-tree on full_name for name-based lookups.
-- GIN indexes on JSONB fields that benefit from containment queries.
-- key_facts and what_they_care_about are the primary assistant retrieval surfaces.

CREATE INDEX idx_qxb_artifact_person_full_name
    ON public.qxb_artifact_person USING btree (full_name);

CREATE INDEX idx_qxb_artifact_person_relationship_type
    ON public.qxb_artifact_person USING btree (relationship_type);

CREATE INDEX idx_qxb_artifact_person_key_facts
    ON public.qxb_artifact_person USING gin (key_facts)
    WHERE key_facts IS NOT NULL;

CREATE INDEX idx_qxb_artifact_person_what_they_care_about
    ON public.qxb_artifact_person USING gin (what_they_care_about)
    WHERE what_they_care_about IS NOT NULL;

CREATE INDEX idx_qxb_artifact_person_preferences
    ON public.qxb_artifact_person USING gin (preferences)
    WHERE preferences IS NOT NULL;

-- PATCH: Interaction tracking index (Q audit finding)
-- Enables follow-up workflows and sorting queries.
CREATE INDEX idx_qxb_artifact_person_last_contacted_at
    ON public.qxb_artifact_person USING btree (last_contacted_at)
    WHERE last_contacted_at IS NOT NULL;

-- ============================================================================
-- STEP 8: Row Level Security (Leaf 2.12)
-- ============================================================================
-- Pattern: spine delegation (same as limb, instruction_pack, video).
-- 3 policies: SELECT (workspace member), INSERT (owner), UPDATE (owner/admin).
-- No DELETE policy — deletion cascades from spine.

ALTER TABLE public.qxb_artifact_person ENABLE ROW LEVEL SECURITY;

-- PATCH: RLS SELECT — enforce workspace membership (Q audit finding)
-- Previous: spine-only join allowed any authenticated user to read all person records.
-- Fixed: requires caller to be a member of the artifact's workspace.
CREATE POLICY qxb_artifact_person_select_via_artifact
    ON public.qxb_artifact_person
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.qxb_artifact a
            JOIN public.qxb_workspace_user wsu
              ON wsu.workspace_id = a.workspace_id
            WHERE a.artifact_id = qxb_artifact_person.artifact_id
              AND wsu.user_id = public.qxb_current_user_id()
        )
    );

-- INSERT: owner only (via spine join)
CREATE POLICY qxb_artifact_person_insert_owner_via_artifact
    ON public.qxb_artifact_person
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.qxb_artifact a
            WHERE a.artifact_id = qxb_artifact_person.artifact_id
              AND a.owner_user_id = public.qxb_current_user_id()
        )
    );

-- UPDATE: owner or workspace admin (via spine join)
CREATE POLICY qxb_artifact_person_update_owner_or_admin
    ON public.qxb_artifact_person
    FOR UPDATE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.qxb_artifact a
            WHERE a.artifact_id = qxb_artifact_person.artifact_id
              AND (
                  a.owner_user_id = public.qxb_current_user_id()
                  OR EXISTS (
                      SELECT 1 FROM public.qxb_workspace_user wsu
                      WHERE wsu.workspace_id = a.workspace_id
                        AND wsu.user_id = public.qxb_current_user_id()
                        AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
                  )
              )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.qxb_artifact a
            WHERE a.artifact_id = qxb_artifact_person.artifact_id
              AND (
                  a.owner_user_id = public.qxb_current_user_id()
                  OR EXISTS (
                      SELECT 1 FROM public.qxb_workspace_user wsu
                      WHERE wsu.workspace_id = a.workspace_id
                        AND wsu.user_id = public.qxb_current_user_id()
                        AND wsu.role = ANY (ARRAY['owner'::text, 'admin'::text])
                  )
              )
        )
    );

COMMIT;

-- =============================================================================
-- NOTES
-- =============================================================================
--
-- Semantic Type Decision (Required Adjustment #2):
--   Person artifacts use EXISTING semantic types from qxb_semantic_type_registry.
--   No new 'person' semantic type is created. The operator assigns a semantic_type_id
--   at creation time. Expected common values:
--     - 'product' for personal contacts (family, friends)
--     - 'sales' for client/prospect contacts
--     - 'infrastructure' for service providers
--   Justification: Semantic types classify what an artifact is ABOUT, not what it IS.
--   'person' is an artifact_type (structural), not a semantic classification.
--   The conditional NOT NULL CHECK ensures every person artifact gets classified.
--
-- Controlled Vocabulary Fields (Leaf 2.7):
--   relationship_type, status, importance_level, interaction_frequency use free text
--   with documented conventions (enforced at application/assistant layer, not DB).
--   Per Branch 1 non-goals: avoid over-engineering with CHECK constraints on these.
--   Documented conventions:
--     - relationship_type: family, friend, coworker, client, mentor, partner, other
--     - status: active, inactive, archived
--     - importance_level: critical, high, medium, low
--     - interaction_frequency: daily, weekly, monthly, quarterly, rarely
--
-- CHECK Constraint Upgrade Hardening (OPTIONAL — not implemented in this patch):
--   For very large tables, the CHECK v7→v8 swap could use NOT VALID + VALIDATE
--   CONSTRAINT to avoid a full table scan under ACCESS EXCLUSIVE lock:
--     ALTER TABLE ... ADD CONSTRAINT ... CHECK (...) NOT VALID;
--     ALTER TABLE ... VALIDATE CONSTRAINT ...;
--   Current qxb_artifact row count is small enough that this is unnecessary,
--   but should be considered if the table exceeds ~1M rows in future migrations.
--
-- JSONB Structure Contracts (Leaf 2.7):
--   address:              { mailing_address_line1, mailing_address_line2, city,
--                           state_region, postal_code, country }
--   communication_style:  { tone, detail_level, decision_style }
--   what_they_care_about: [ "string", ... ]
--   key_facts:            [ "string", ... ]
--   preferences:          [ "string", ... ]
