-- =============================================================================
-- Multi-User Qwrk — Supabase User & Workspace Setup
-- =============================================================================
-- TEMPLATE — Replace all {{placeholders}} with actual values before execution.
-- Execute in Supabase SQL Editor with service_role context.
-- Created: 2026-02-17
-- =============================================================================

-- STEP 1: Create qxb_user rows (run AFTER auth users are confirmed in Dashboard)
-- Capture auth_user_id from Supabase Auth → Users for each email.

INSERT INTO qxb_user (auth_user_id, display_name, email)
VALUES
  ('{{auth_user_id_work}}',      'Joel (Work)',    'espressivedemojoel@gmail.com'),
  ('{{auth_user_id_akara}}',     'Akara Blagg',    'akarablagg@gmail.com'),
  ('{{auth_user_id_blagglife}}', 'Joel (BlaggLife)','j_blagg@hotmail.com'),
  ('{{auth_user_id_krista}}',    'Krista Blagg',   'kristablagg@gmail.com')
RETURNING user_id, auth_user_id, display_name, email;

-- Record returned user_id values in WORKSPACE_REGISTRY_TRACKING.md


-- =============================================================================
-- STEP 2: Create NEW workspaces (skip existing ones)
-- BlaggLife ALREADY EXISTS: b4e7f648-96d5-44a7-80b9-c39cac4efbd1
-- Work (Resolve) MAY EXIST: 635bb8d7-7b93-4bea-8ca6-ee2c924c9557 — VERIFY
-- =============================================================================

INSERT INTO qxb_workspace (name)
VALUES
  -- ('Qwrk@Work'),    -- UNCOMMENT ONLY if NOT reusing Work (Resolve)
  ('Akara_Blagg'),
  ('Krista_Blagg')
RETURNING workspace_id, name;

-- Record returned workspace_id values in WORKSPACE_REGISTRY_TRACKING.md


-- =============================================================================
-- STEP 3: Create workspace_user membership rows
-- =============================================================================

INSERT INTO qxb_workspace_user (workspace_id, user_id, role)
VALUES
  ('{{workspace_uuid_work}}',      '{{user_id_work}}',      'owner'),
  ('{{workspace_uuid_akara}}',     '{{user_id_akara}}',     'owner'),
  ('{{workspace_uuid_blagglife}}', '{{user_id_blagglife}}', 'owner'),
  ('{{workspace_uuid_krista}}',    '{{user_id_krista}}',    'owner')
RETURNING workspace_user_id, workspace_id, user_id, role;

-- NOTE: For BlaggLife, if Joel's primary qxb_user (c52c7a57-...) already has
-- a workspace_user row for BlaggLife, you may want to skip the BlaggLife row
-- above and only add it for the new j_blagg@hotmail.com identity.


-- =============================================================================
-- STEP 4: Seed ACL rows (one per principal x workspace)
-- =============================================================================

INSERT INTO qxb_gateway_acl (principal_name, workspace_id)
VALUES
  ('qwrk-gw-work',      '{{workspace_uuid_work}}'),
  ('qwrk-gw-akara',     '{{workspace_uuid_akara}}'),
  ('qwrk-gw-blagglife', '{{workspace_uuid_blagglife}}'),
  ('qwrk-gw-krista',    '{{workspace_uuid_krista}}')
RETURNING acl_id, principal_name, workspace_id, role;


-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify all users
SELECT user_id, auth_user_id, display_name, email
FROM qxb_user
WHERE email IN (
  'espressivedemojoel@gmail.com',
  'akarablagg@gmail.com',
  'j_blagg@hotmail.com',
  'kristablagg@gmail.com'
);

-- Verify all workspaces
SELECT workspace_id, name
FROM qxb_workspace
ORDER BY name;

-- Verify all memberships
SELECT wu.workspace_user_id, w.name AS workspace, u.display_name, wu.role
FROM qxb_workspace_user wu
JOIN qxb_workspace w ON w.workspace_id = wu.workspace_id
JOIN qxb_user u ON u.user_id = wu.user_id
ORDER BY w.name;

-- Verify all ACL rows
SELECT acl_id, principal_name, workspace_id, role
FROM qxb_gateway_acl
ORDER BY principal_name;
