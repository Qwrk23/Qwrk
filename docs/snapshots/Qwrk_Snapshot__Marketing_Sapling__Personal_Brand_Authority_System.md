# Qwrk Snapshot — Marketing Sapling: Personal Brand Authority System (8 Modules)
Snapshot ID: f587939c-ed35-4db4-ab1c-3873e5677a25  
Captured (UTC): 2026-01-17 22:34:25Z

## Canonical IDs
- Forest (Qwrk): e8e5db75-724a-4d33-9694-5903a6e30e8f
- Thicket (marketing): d6fd2d51-ee9e-45b4-bf5d-7f39496f06e6
- Sapling Project: e359bedf-8cb0-47a1-9e65-70ffdef685e6

## Locked structure
Forest → Thicket → Sapling(Project) → Branch(8) → Leaf(24)

## Schema change (completed)
- Constraint updated: qxb_artifact_artifact_type_check_v4
- Added artifact types: branch, leaf

## Sapling extension row
- lifecycle_stage = sapling
- operational_state = paused
- state_reason = Branches created; ready for leaf planning

## Branches (IDs)
1. 633bef48-18ca-4927-b73b-f44ca815625e — Authority Content Pillar Generator
2. 9adfc418-8a69-495c-9ab2-f0ffacebb37d — LinkedIn Profile Optimizer
3. d96478c9-5eea-4e93-9b3e-37e5e9a986f9 — Contrarian Thought Leader
4. 894ccb00-77ae-4ea0-9fb6-5bfbdade1ead — Origin Story Script
5. 97335300-86b0-46a2-bd14-b076ad6c3413 — High-Value Lead Magnet Brainstormer
6. 9b08d331-6c45-4c81-9fe1-b7155824da7b — Networking Outreach Architect
7. 6f9198e6-d8b5-4a64-af77-1e9a63c59605 — Help Me Help You Market Research
8. 98e59fa4-3669-4e3c-9b2f-d6c579fffbf6 — Signature Framework Creator

## Leaves template (applied)
Per branch (3):
1) Define Inputs
2) Draft Outputs
3) Review + Finalize
Total leaves expected: 24

## SQL — Save Snapshot (Executed)
```sql
INSERT INTO public.qxb_artifact (
  artifact_id,
  workspace_id,
  owner_user_id,
  artifact_type,
  title,
  summary,
  priority,
  lifecycle_status,
  tags,
  content,
  parent_artifact_id,
  version,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  'be0d3a48-c764-44f9-90c8-e846d9dbbd0a',
  'c52c7a57-74ad-433d-a07c-4dcac1778672',
  'snapshot',
  'SNAPSHOT — Marketing Sapling — Personal Brand Authority System (8 Modules) — 2026-01-17',
  'Snapshot captures the created forest/thicket/sapling, 8 branches, and 24 leaves (3 per branch), with sapling lifecycle_stage=sapling and operational_state=paused.',
  3,
  'captured',
  jsonb_build_array('snapshot','marketing','personal-brand','authority','content-strategy'),
  jsonb_build_object(
    'kind','qwrk_snapshot',
    'captured_at_utc', to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'forest_id','e8e5db75-724a-4d33-9694-5903a6e30e8f',
    'thicket_id','d6fd2d51-ee9e-45b4-bf5d-7f39496f06e6',
    'sapling_project_id','e359bedf-8cb0-47a1-9e65-70ffdef685e6',
    'sapling_project_state', jsonb_build_object(
      'lifecycle_stage','sapling',
      'operational_state','paused',
      'state_reason','Branches created; ready for leaf planning'
    ),
    'schema_changes', jsonb_build_array(
      jsonb_build_object(
        'change','artifact_type allowlist expanded',
        'constraint','qxb_artifact_artifact_type_check_v4',
        'added_types', jsonb_build_array('branch','leaf')
      )
    ),
    'branches', jsonb_build_array(
      jsonb_build_object('order',1,'branch_id','633bef48-18ca-4927-b73b-f44ca815625e','title','Authority Content Pillar Generator'),
      jsonb_build_object('order',2,'branch_id','9adfc418-8a69-495c-9ab2-f0ffacebb37d','title','LinkedIn Profile Optimizer'),
      jsonb_build_object('order',3,'branch_id','d96478c9-5eea-4e93-9b3e-37e5e9a986f9','title','Contrarian Thought Leader'),
      jsonb_build_object('order',4,'branch_id','894ccb00-77ae-4ea0-9fb6-5bfbdade1ead','title','Origin Story Script'),
      jsonb_build_object('order',5,'branch_id','97335300-86b0-46a2-bd14-b076ad6c3413','title','High-Value Lead Magnet Brainstormer'),
      jsonb_build_object('order',6,'branch_id','9b08d331-6c45-4c81-9fe1-b7155824da7b','title','Networking Outreach Architect'),
      jsonb_build_object('order',7,'branch_id','6f9198e6-d8b5-4a64-af77-1e9a63c59605','title','Help Me Help You Market Research'),
      jsonb_build_object('order',8,'branch_id','98e59fa4-3669-4e3c-9b2f-d6c579fffbf6','title','Signature Framework Creator')
    ),
    'leaf_template', jsonb_build_object(
      'per_branch', 3,
      'pattern', jsonb_build_array(
        jsonb_build_object('leaf_order',1,'suffix','Define Inputs'),
        jsonb_build_object('leaf_order',2,'suffix','Draft Outputs'),
        jsonb_build_object('leaf_order',3,'suffix','Review + Finalize')
      ),
      'total_leaves_expected', 24
    )
  ),
  'e359bedf-8cb0-47a1-9e65-70ffdef685e6',
  1,
  now(),
  now()
)
RETURNING artifact_id AS snapshot_id, created_at;
