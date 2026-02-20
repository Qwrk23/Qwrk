# Tag Backfill Plan

**Created:** 2026-02-01
**Status:** PLAN ONLY - DO NOT EXECUTE WITHOUT REVIEW
**Related:** BUG-011 (First-Class Tags Implementation - COMPLETE)

---

## Executive Summary

This document provides a plan to backfill tags on existing artifacts in workspace `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`. Tags are now supported in Gateway v1 (BUG-011 complete) and are stored in `qxb_artifact.tags` as a JSONB array.

**Goal:** Apply meaningful, queryable tags to all existing artifacts based on:
- Artifact type (every journal gets "journal", etc.)
- Title patterns (e.g., "BUG-XXX" gets "bugfix")
- Lifecycle status for projects
- Content/context patterns

---

## Tag Normalization Rules (From BUG-011)

All tags must follow these normalization rules (implemented in Gateway Save workflow v25):

1. **Lowercase** - All tags stored in lowercase for deterministic search
2. **Trimmed** - No leading/trailing whitespace
3. **Deduped** - No duplicate tags within an artifact
4. **Non-empty** - Empty strings filtered out
5. **Array format** - Stored as `["tag1", "tag2"]` not `{"key": "value"}`

---

## Proposed Tagging Strategy

### Rule 1: Type-Based Tags (Universal)

Every artifact gets a tag matching its `artifact_type`. This enables cross-type queries like "find all journals" via tag filtering.

| Artifact Type | Tag Applied |
|---------------|-------------|
| project | `project` |
| journal | `journal` |
| snapshot | `snapshot` |
| restart | `restart` |
| instruction_pack | `instruction-pack` |

**Rationale:** Enables homogeneous tag-based filtering across all artifact types.

---

### Rule 2: Lifecycle-Based Tags (Projects Only)

Projects get tags based on their `lifecycle_status` to enable lifecycle-aware queries.

| Lifecycle Status | Tag Applied |
|------------------|-------------|
| seed | `seed`, `ideation` |
| sapling | `sapling`, `in-progress` |
| tree | `tree`, `mature` |
| retired | `retired`, `archived` |

**Rationale:** Enables queries like "show all seed projects" or "show all in-progress work".

---

### Rule 3: Title Pattern Tags

Apply tags based on title patterns using case-insensitive matching.

| Pattern | Tag(s) Applied | Example Titles |
|---------|----------------|----------------|
| `BUG-\d+` | `bugfix`, `bug` | "BUG-011 First Class Tags" |
| `RESTART` or `Restart` | `restart-prompt` | "RESTART: Session Resume" |
| `SNAPSHOT` or `Snapshot` | `milestone` | "SNAPSHOT: Gateway v1 Lock" |
| `KGB` | `kgb`, `governance` | "KGB Proof: artifact.list" |
| `Gateway` | `gateway` | "Gateway v1 Test Harness" |
| `PRD` | `prd`, `planning` | "PRD: Artifact Type Registry" |
| `North Star` | `north-star`, `vision` | "North Star v0.4" |
| `Seed [—–-]` | `seed-doc` | "Seed — Infrastructure Capacity" |
| `Test` (word boundary) | `test` | "Test Journal 20260201" |
| `Session` | `session` | "Session: Strategic Analysis" |
| `Morning` or `Briefing` | `morning`, `briefing` | "Morning Briefing 2026-01-30" |
| `Telegram` | `telegram` | "Telegram Gateway Fixes" |
| `Moltbot` | `moltbot`, `inspiration` | "Moltbot Feature Assessment" |
| `Journal` (in title) | `reflection` | "Journal Entry: Build Session" |
| `Schema` | `schema`, `database` | "Schema Reference v1.1" |
| `Governance` | `governance` | "Governance Document Artifact PRD" |
| `Implementation` | `implementation` | "Implementation Pack: Tags" |

---

### Rule 4: Relationship-Based Tags

Artifacts with `parent_artifact_id` set get a `linked` tag. Projects that have child artifacts get a `has-children` tag (requires subquery).

| Condition | Tag Applied |
|-----------|-------------|
| `parent_artifact_id IS NOT NULL` | `linked` |
| Has child artifacts | `has-children` |

---

### Rule 5: Priority-Based Tags

For artifacts with priority set, add context tags.

| Priority | Tag Applied |
|----------|-------------|
| 1 | `critical`, `p1` |
| 2 | `high`, `p2` |
| 3 | (no tag - default) |
| 4 | `low`, `p4` |
| 5 | `plan`, `p5` |

---

## SQL Scripts

**WARNING: DO NOT EXECUTE WITHOUT EXPLICIT APPROVAL**

All scripts below are READ-ONLY analysis queries or UPDATE statements marked clearly.

---

### Analysis Query 1: Current Tag State

```sql
-- SAFE TO EXECUTE: Read-only analysis
-- Purpose: Count artifacts with/without tags

SELECT
    artifact_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN tags IS NOT NULL AND tags != '[]'::jsonb AND tags != 'null'::jsonb THEN 1 END) as with_tags,
    COUNT(CASE WHEN tags IS NULL OR tags = '[]'::jsonb OR tags = 'null'::jsonb THEN 1 END) as without_tags
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
GROUP BY artifact_type
ORDER BY total_count DESC;
```

---

### Analysis Query 2: Sample Titles by Type

```sql
-- SAFE TO EXECUTE: Read-only analysis
-- Purpose: View sample titles to verify pattern matching

SELECT
    artifact_type,
    title,
    lifecycle_status,
    tags
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
ORDER BY artifact_type, created_at DESC
LIMIT 100;
```

---

### Analysis Query 3: Title Pattern Counts

```sql
-- SAFE TO EXECUTE: Read-only analysis
-- Purpose: Count artifacts matching each pattern

SELECT
    'BUG-XXX' as pattern,
    COUNT(*) as matches
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'BUG-\d+'

UNION ALL

SELECT 'RESTART/Restart', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'restart'

UNION ALL

SELECT 'KGB', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'kgb'

UNION ALL

SELECT 'Gateway', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'gateway'

UNION ALL

SELECT 'PRD', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'prd'

UNION ALL

SELECT 'North Star', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'north\s*star'

UNION ALL

SELECT 'Seed —', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'seed\s*[—–-]'

UNION ALL

SELECT 'Test', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* '\ytest\y'

UNION ALL

SELECT 'Session', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* '\ysession\y'

UNION ALL

SELECT 'Morning/Briefing', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND (title ~* '\ymorning\y' OR title ~* '\ybriefing\y')

UNION ALL

SELECT 'Telegram', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'telegram'

ORDER BY pattern;
```

---

### Analysis Query 4: Parent Relationships

```sql
-- SAFE TO EXECUTE: Read-only analysis
-- Purpose: Count artifacts with parent relationships

SELECT
    'With parent_artifact_id' as category,
    COUNT(*) as count
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND parent_artifact_id IS NOT NULL

UNION ALL

SELECT 'Without parent_artifact_id', COUNT(*)
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND parent_artifact_id IS NULL;
```

---

### Backfill Script: Rule 1 - Type Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 1: Add artifact type as a tag
-- Effect: Every artifact gets its type as a tag

UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || jsonb_build_array(
    CASE
        WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack'
        ELSE artifact_type
    END
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND NOT (COALESCE(tags, '[]'::jsonb) @> jsonb_build_array(
      CASE
          WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack'
          ELSE artifact_type
      END
  ));

-- Expected row count: All artifacts without existing type tag
```

---

### Backfill Script: Rule 2 - Lifecycle Tags (Projects)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 2: Add lifecycle-based tags to projects
-- Effect: Projects get tags based on lifecycle_status

-- Seed projects
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["seed", "ideation"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status = 'seed'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["seed"]'::jsonb);

-- Sapling projects
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["sapling", "in-progress"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status = 'sapling'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["sapling"]'::jsonb);

-- Tree projects
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["tree", "mature"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status = 'tree'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["tree"]'::jsonb);

-- Retired projects
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["retired", "archived"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status = 'retired'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["retired"]'::jsonb);
```

---

### Backfill Script: Rule 3 - Pattern Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 3: Add title-pattern based tags
-- Effect: Artifacts matching patterns get relevant tags

-- BUG-XXX pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["bugfix", "bug"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'BUG-\d+'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["bugfix"]'::jsonb);

-- RESTART/Restart pattern (for non-restart artifact types)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["restart-prompt"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'restart'
  AND artifact_type != 'restart'  -- Restart artifacts already get 'restart' from Rule 1
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["restart-prompt"]'::jsonb);

-- KGB pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["kgb", "governance"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'kgb'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["kgb"]'::jsonb);

-- Gateway pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["gateway"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'gateway'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["gateway"]'::jsonb);

-- PRD pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["prd", "planning"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'prd'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["prd"]'::jsonb);

-- North Star pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["north-star", "vision"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'north\s*star'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["north-star"]'::jsonb);

-- Seed — pattern (seed documents)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["seed-doc"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'seed\s*[—–-]'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["seed-doc"]'::jsonb);

-- Test pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["test"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* '\ytest\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["test"]'::jsonb);

-- Session pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["session"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* '\ysession\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["session"]'::jsonb);

-- Morning/Briefing pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["morning", "briefing"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND (title ~* '\ymorning\y' OR title ~* '\ybriefing\y')
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["morning"]'::jsonb);

-- Telegram pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["telegram"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'telegram'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["telegram"]'::jsonb);

-- Moltbot pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["moltbot", "inspiration"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'moltbot'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["moltbot"]'::jsonb);

-- SNAPSHOT/Snapshot pattern (for non-snapshot artifact types)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["milestone"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'snapshot'
  AND artifact_type != 'snapshot'  -- Snapshot artifacts already get 'snapshot' from Rule 1
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["milestone"]'::jsonb);

-- Schema pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["schema", "database"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'schema'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["schema"]'::jsonb);

-- Governance pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["governance"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'governance'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["governance"]'::jsonb);

-- Implementation pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["implementation"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'implementation'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["implementation"]'::jsonb);
```

---

### Backfill Script: Rule 4 - Relationship Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 4a: Add 'linked' tag to artifacts with parent
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["linked"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND parent_artifact_id IS NOT NULL
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["linked"]'::jsonb);

-- Rule 4b: Add 'has-children' tag to artifacts that are parents
UPDATE qxb_artifact a
SET tags = COALESCE(a.tags, '[]'::jsonb) || '["has-children"]'::jsonb
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND a.deleted_at IS NULL
  AND EXISTS (
      SELECT 1 FROM qxb_artifact c
      WHERE c.parent_artifact_id = a.artifact_id
        AND c.deleted_at IS NULL
  )
  AND NOT (COALESCE(a.tags, '[]'::jsonb) @> '["has-children"]'::jsonb);
```

---

### Backfill Script: Rule 5 - Priority Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 5: Add priority-based tags

-- Priority 1 (Critical)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["critical", "p1"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND priority = 1
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p1"]'::jsonb);

-- Priority 2 (High)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["high", "p2"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND priority = 2
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p2"]'::jsonb);

-- Priority 4 (Low)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["low", "p4"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND priority = 4
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p4"]'::jsonb);

-- Priority 5 (Plan)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["plan", "p5"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND priority = 5
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p5"]'::jsonb);
```

---

### Post-Backfill: Deduplicate Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review and test on single row first           !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- After all backfill operations, deduplicate tags
-- This query uses DISTINCT to remove duplicates within each artifact's tag array

UPDATE qxb_artifact
SET tags = (
    SELECT jsonb_agg(DISTINCT value)
    FROM jsonb_array_elements_text(tags)
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND tags IS NOT NULL
  AND tags != '[]'::jsonb;
```

---

## Verification Queries

Run these AFTER backfill to verify success.

### Verification 1: Tag Distribution

```sql
-- SAFE TO EXECUTE: Read-only verification
-- Purpose: Show tag distribution after backfill

SELECT
    tag,
    COUNT(*) as artifact_count
FROM qxb_artifact,
     LATERAL jsonb_array_elements_text(COALESCE(tags, '[]'::jsonb)) as tag
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
GROUP BY tag
ORDER BY artifact_count DESC;
```

---

### Verification 2: Artifacts Still Without Tags

```sql
-- SAFE TO EXECUTE: Read-only verification
-- Purpose: Find artifacts that still have no tags

SELECT
    artifact_id,
    artifact_type,
    title,
    lifecycle_status
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND (tags IS NULL OR tags = '[]'::jsonb OR tags = 'null'::jsonb)
ORDER BY artifact_type, created_at DESC;
```

---

### Verification 3: Sample Tagged Artifacts

```sql
-- SAFE TO EXECUTE: Read-only verification
-- Purpose: Sample artifacts with their tags

SELECT
    artifact_type,
    title,
    tags,
    lifecycle_status
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND tags IS NOT NULL
  AND tags != '[]'::jsonb
ORDER BY artifact_type, created_at DESC
LIMIT 50;
```

---

### Verification 4: Test Tag Filtering via Gateway

After backfill, test the Gateway `artifact.list` with `tags_any` filter:

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "selector": {
    "limit": 10,
    "filters": {
      "tags_any": ["bugfix"]
    }
  }
}
```

Expected: Returns only journals with "bugfix" tag.

---

## Execution Order

Execute backfill scripts in this order:

1. **Run Analysis Queries** - Understand current state
2. **Test on Single Row** - Pick one artifact and run updates manually
3. **Rule 1** - Type tags (universal)
4. **Rule 2** - Lifecycle tags (projects only)
5. **Rule 3** - Pattern tags
6. **Rule 4** - Relationship tags
7. **Rule 5** - Priority tags
8. **Deduplication** - Clean up any duplicates
9. **Verification** - Run all verification queries
10. **Gateway Test** - Test `tags_any` filtering

---

## Estimated Impact

Based on typical workspace activity:

| Rule | Estimated Artifacts Affected |
|------|------------------------------|
| Rule 1 (Type Tags) | All artifacts (~100-500) |
| Rule 2 (Lifecycle) | All projects (~20-50) |
| Rule 3 (Patterns) | ~30-50% of artifacts |
| Rule 4 (Relationships) | ~10-20% of artifacts |
| Rule 5 (Priority) | ~10-20% of artifacts |

Total unique artifacts touched: **All artifacts in workspace**

---

## Rollback Plan

If backfill causes issues, rollback by setting tags to empty array:

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                EMERGENCY ROLLBACK ONLY                !!
-- !!     This removes ALL tags - use with extreme caution  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

UPDATE qxb_artifact
SET tags = '[]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL;
```

---

## Appendix: Tag Vocabulary Reference

### Type Tags
- `project`, `journal`, `snapshot`, `restart`, `instruction-pack`

### Lifecycle Tags
- `seed`, `ideation`, `sapling`, `in-progress`, `tree`, `mature`, `retired`, `archived`

### Pattern Tags
- `bugfix`, `bug`, `restart-prompt`, `kgb`, `governance`, `gateway`, `prd`, `planning`
- `north-star`, `vision`, `seed-doc`, `test`, `session`, `morning`, `briefing`
- `telegram`, `moltbot`, `inspiration`, `milestone`, `schema`, `database`, `implementation`

### Relationship Tags
- `linked`, `has-children`

### Priority Tags
- `critical`, `p1`, `high`, `p2`, `low`, `p4`, `plan`, `p5`

---

**End of Plan**
