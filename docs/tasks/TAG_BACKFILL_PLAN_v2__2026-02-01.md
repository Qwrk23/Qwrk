# Tag Backfill Plan v2 (Prefix Taxonomy + Safe Execution)

**Created:** 2026-02-01
**Version:** 2.2 (CC + QP1 fully merged)
**Status:** PLAN ONLY — DO NOT EXECUTE WITHOUT REVIEW + SAMPLING
**Workspace:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
**Related:** BUG-011 (First-Class Tags Implementation - COMPLETE)

---

## Core Principles (v2)

1. **Governed truth stays governed:** `lifecycle_status` remains the canonical truth; tags are convenience.
2. **Machine-inferred semantics are clearly marked:** `auto:` prefix for pattern/topic tags.
3. **All backfill operations are idempotent:** safe to re-run; no duplicate tags.
4. **All updates are guarded:** only operate on rows where `tags` is null or JSON array; never risk object/other types.
5. **Preview before mutation:** every pattern rule requires a dry-run sample review before execution.

---

## Executive Summary

**Goal:** Backfill consistent, queryable tags onto existing artifacts with **low drift risk** and **high reversibility**.

**Key Changes from v1:**
- **Prefix taxonomy** to distinguish machine-derived from human-intent tags
- **Dry-run preview queries** for each rule before execution
- **Tightened regexes** to avoid over-tagging (Rule 3B for previously-broad patterns)
- **`jsonb_typeof` guards** for safety against non-array values
- **Separated structural vs semantic tags**
- **Tiered rollback strategy** (Tier 1: auto:, Tier 2: lc:, Tier 3: full reset)
- **Structured preview categories** (A: deterministic, B: high-confidence, C: semantic)
- **Approval gate** before mutation execution
- **Decision log** for governance traceability
- **Helper pattern** documentation for safe append operations

---

## Tag Taxonomy (v2)

### Prefix Conventions

| Prefix | Meaning | Backfill? | Example |
|--------|---------|-----------|---------|
| (none) | Structural fact | ✅ Safe | `project`, `journal`, `linked` |
| `lc:` | Lifecycle state | ✅ Safe (from governed field) | `lc:seed`, `lc:sapling` |
| `auto:` | Machine-inferred semantic | ✅ With review | `auto:bugfix`, `auto:gateway` |
| `p:` | Priority level | ✅ Safe (from governed field) | `p:critical`, `p:high` |
| (none) | Human-intent | ❌ Forward only | `important`, `review` |

### Why Prefixes?

1. **Reversibility** — Can remove all `auto:*` tags if inference was wrong
2. **Transparency** — Clear what was human vs machine
3. **Lifecycle integrity** — `lc:` tags mirror governed `lifecycle_status`, not replace it
4. **Query flexibility** — Can filter by prefix pattern

---

## Tag Normalization Rules (From BUG-011)

All tags must follow these rules (enforced by Gateway Save workflow v25):

1. **Lowercase** - All tags stored in lowercase
2. **Trimmed** - No leading/trailing whitespace
3. **Deduped** - No duplicate tags within an artifact
4. **Non-empty** - Empty strings filtered out
5. **Array format** - Stored as `["tag1", "tag2"]`

---

## Rule 1: Type-Based Tags (Structural)

Every artifact gets a tag matching its `artifact_type`. No prefix needed — these are facts.

| Artifact Type | Tag Applied |
|---------------|-------------|
| project | `project` |
| journal | `journal` |
| snapshot | `snapshot` |
| restart | `restart` |
| instruction_pack | `instruction-pack` |

### Dry-Run Preview Query (Rule 1)

```sql
-- SAFE TO EXECUTE: Preview only
-- Shows what Rule 1 would tag

SELECT
    artifact_id,
    artifact_type,
    title,
    tags as existing_tags,
    CASE
        WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack'
        ELSE artifact_type
    END as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> jsonb_build_array(
      CASE WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack' ELSE artifact_type END
  ))
ORDER BY artifact_type, created_at DESC;
```

### Backfill Script (Rule 1)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review dry-run preview first                  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || jsonb_build_array(
    CASE
        WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack'
        ELSE artifact_type
    END
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> jsonb_build_array(
      CASE WHEN artifact_type = 'instruction_pack' THEN 'instruction-pack' ELSE artifact_type END
  ));
```

---

## Rule 2: Lifecycle Tags (Projects Only)

Projects get `lc:` prefixed tags based on `lifecycle_status`. This is a **query convenience**, not semantic truth — lifecycle_status remains the governed field.

| Lifecycle Status | Tag Applied |
|------------------|-------------|
| seed | `lc:seed` |
| sapling | `lc:sapling` |
| tree | `lc:tree` |
| retired | `lc:retired` |

### Dry-Run Preview Query (Rule 2)

```sql
-- SAFE TO EXECUTE: Preview only
-- Shows what Rule 2 would tag

SELECT
    artifact_id,
    title,
    lifecycle_status,
    tags as existing_tags,
    'lc:' || lifecycle_status as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status IS NOT NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> jsonb_build_array('lc:' || lifecycle_status))
ORDER BY lifecycle_status, created_at DESC;
```

### Backfill Script (Rule 2)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review dry-run preview first                  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || jsonb_build_array('lc:' || lifecycle_status)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND artifact_type = 'project'
  AND lifecycle_status IS NOT NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> jsonb_build_array('lc:' || lifecycle_status));
```

---

## Rule 3: Pattern Tags (Auto-Inferred)

Apply `auto:` prefixed tags based on title patterns. These are machine-inferred and reversible.

**Tightened patterns (removed broad terms like `implementation`, `schema`, `session`):**

| Pattern | Tag Applied | Confidence |
|---------|-------------|------------|
| `^BUG-\d+` | `auto:bugfix` | High (anchored) |
| `^RESTART[:\s]` | `auto:restart-prompt` | High (anchored) |
| `^SNAPSHOT[:\s]` | `auto:milestone` | High (anchored) |
| `\bKGB\b` | `auto:kgb` | High (word boundary) |
| `\bGateway\b` | `auto:gateway` | High (word boundary) |
| `^PRD[:\s_]` | `auto:prd` | High (anchored) |
| `North\s*Star` | `auto:north-star` | High (specific phrase) |
| `^Seed\s*[—–-]` | `auto:seed-content` | High (anchored) |
| `\bTelegram\b` | `auto:telegram` | High (word boundary) |
| `\bMoltbot\b` | `auto:moltbot` | High (specific) |

**Removed from v1 (too broad):**
- `implementation` — matches too many unrelated artifacts
- `schema` — needs manual review
- `session` — too generic
- `test` — would over-tag

---

## Rule 3B: Previously-Broad Patterns (Manual Review Required)

These patterns were removed from automatic backfill due to over-matching risk. They can be applied **after manual review** with tightened regex options.

| Pattern (Broad) | Tightened Option | Tag Applied | Decision |
|-----------------|------------------|-------------|----------|
| `implementation` | `Implementation_Pack` (anchored) | `auto:implementation` | TBD after preview |
| `schema` | `Schema_Reference` or `_Schema.yaml` | `auto:schema` | TBD after preview |
| `session` | `Session:` (anchored) | `auto:session-log` | TBD after preview |
| `test` | `Test_Pack` or `TestHarness` | `auto:testing` | TBD after preview |

### Decision Process for Rule 3B

1. Run preview with **broad** pattern — count matches
2. Run preview with **tightened** pattern — count matches
3. If tightened ≥ 80% of broad and looks clean → use tightened
4. If tightened < 80% → manual tag or skip

### Dry-Run Preview (Rule 3B — Tightened)

```sql
-- Preview: Implementation Pack titles only (not just "implementation")
SELECT artifact_id, title, 'auto:implementation' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* 'Implementation[\s_]Pack'
ORDER BY created_at DESC;

-- Preview: Schema reference documents
SELECT artifact_id, title, 'auto:schema' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND (title ~* 'Schema[\s_]Reference' OR title ~* '_Schema\.yaml')
ORDER BY created_at DESC;

-- Preview: Session logs (anchored)
SELECT artifact_id, title, 'auto:session-log' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND title ~* '^Session:'
ORDER BY created_at DESC;
```

---

### Dry-Run Preview Query (Rule 3)

```sql
-- SAFE TO EXECUTE: Preview only
-- Shows what Rule 3 would tag (one pattern example)

-- BUG-XXX pattern
SELECT
    artifact_id,
    title,
    tags as existing_tags,
    'auto:bugfix' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^BUG-\d+'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:bugfix"]'::jsonb)
ORDER BY created_at DESC;

-- Gateway pattern
SELECT
    artifact_id,
    title,
    tags as existing_tags,
    'auto:gateway' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yGateway\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:gateway"]'::jsonb)
ORDER BY created_at DESC;

-- KGB pattern
SELECT
    artifact_id,
    title,
    tags as existing_tags,
    'auto:kgb' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yKGB\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:kgb"]'::jsonb)
ORDER BY created_at DESC;

-- PRD pattern
SELECT
    artifact_id,
    title,
    tags as existing_tags,
    'auto:prd' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^PRD[:\s_]'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:prd"]'::jsonb)
ORDER BY created_at DESC;

-- Telegram pattern
SELECT
    artifact_id,
    title,
    tags as existing_tags,
    'auto:telegram' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yTelegram\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:telegram"]'::jsonb)
ORDER BY created_at DESC;
```

### Backfill Script (Rule 3)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review dry-run previews first                 !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- BUG-XXX pattern (anchored to start)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:bugfix"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^BUG-\d+'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:bugfix"]'::jsonb);

-- RESTART pattern (anchored, for non-restart types)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:restart-prompt"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^RESTART[:\s]'
  AND artifact_type != 'restart'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:restart-prompt"]'::jsonb);

-- SNAPSHOT pattern (anchored, for non-snapshot types)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:milestone"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^SNAPSHOT[:\s]'
  AND artifact_type != 'snapshot'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:milestone"]'::jsonb);

-- KGB pattern (word boundary)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:kgb"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yKGB\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:kgb"]'::jsonb);

-- Gateway pattern (word boundary)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:gateway"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yGateway\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:gateway"]'::jsonb);

-- PRD pattern (anchored)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:prd"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^PRD[:\s_]'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:prd"]'::jsonb);

-- North Star pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:north-star"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* 'North\s*Star'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:north-star"]'::jsonb);

-- Seed — pattern (anchored, seed content documents)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:seed-content"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '^Seed\s*[—–-]'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:seed-content"]'::jsonb);

-- Telegram pattern (word boundary)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:telegram"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yTelegram\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:telegram"]'::jsonb);

-- Moltbot pattern
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["auto:moltbot"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND title ~* '\yMoltbot\y'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["auto:moltbot"]'::jsonb);
```

---

## Rule 4: Relationship Tags (Structural)

Artifacts with relationships get structural tags. No prefix — these are facts.

| Condition | Tag Applied |
|-----------|-------------|
| `parent_artifact_id IS NOT NULL` | `linked` |
| Has child artifacts | `has-children` |

### Dry-Run Preview Query (Rule 4)

```sql
-- SAFE TO EXECUTE: Preview only

-- Linked artifacts (have parent)
SELECT
    artifact_id,
    title,
    parent_artifact_id,
    tags as existing_tags,
    'linked' as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND parent_artifact_id IS NOT NULL
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["linked"]'::jsonb)
ORDER BY created_at DESC;

-- Parent artifacts (have children)
SELECT
    a.artifact_id,
    a.title,
    a.tags as existing_tags,
    'has-children' as proposed_tag,
    (SELECT COUNT(*) FROM qxb_artifact c WHERE c.parent_artifact_id = a.artifact_id AND c.deleted_at IS NULL) as child_count
FROM qxb_artifact a
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND a.deleted_at IS NULL
  AND jsonb_typeof(COALESCE(a.tags, '[]'::jsonb)) = 'array'
  AND EXISTS (
      SELECT 1 FROM qxb_artifact c
      WHERE c.parent_artifact_id = a.artifact_id
        AND c.deleted_at IS NULL
  )
  AND NOT (COALESCE(a.tags, '[]'::jsonb) @> '["has-children"]'::jsonb)
ORDER BY a.created_at DESC;
```

### Backfill Script (Rule 4)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review dry-run preview first                  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Rule 4a: linked
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["linked"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND parent_artifact_id IS NOT NULL
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["linked"]'::jsonb);

-- Rule 4b: has-children
UPDATE qxb_artifact a
SET tags = COALESCE(a.tags, '[]'::jsonb) || '["has-children"]'::jsonb
WHERE a.workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND a.deleted_at IS NULL
  AND jsonb_typeof(COALESCE(a.tags, '[]'::jsonb)) = 'array'
  AND EXISTS (
      SELECT 1 FROM qxb_artifact c
      WHERE c.parent_artifact_id = a.artifact_id
        AND c.deleted_at IS NULL
  )
  AND NOT (COALESCE(a.tags, '[]'::jsonb) @> '["has-children"]'::jsonb);
```

---

## Rule 5: Priority Tags (Prefixed)

Priority-based tags use `p:` prefix to indicate they derive from the governed `priority` field.

| Priority | Tag Applied |
|----------|-------------|
| 1 | `p:critical` |
| 2 | `p:high` |
| 3 | (no tag - default) |
| 4 | `p:low` |
| 5 | `p:backlog` |

### Dry-Run Preview Query (Rule 5)

```sql
-- SAFE TO EXECUTE: Preview only

SELECT
    artifact_id,
    title,
    priority,
    tags as existing_tags,
    CASE priority
        WHEN 1 THEN 'p:critical'
        WHEN 2 THEN 'p:high'
        WHEN 4 THEN 'p:low'
        WHEN 5 THEN 'p:backlog'
    END as proposed_tag
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND priority IN (1, 2, 4, 5)
ORDER BY priority, created_at DESC;
```

### Backfill Script (Rule 5)

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Review dry-run preview first                  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

-- Priority 1 (Critical)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["p:critical"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND priority = 1
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p:critical"]'::jsonb);

-- Priority 2 (High)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["p:high"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND priority = 2
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p:high"]'::jsonb);

-- Priority 4 (Low)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["p:low"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND priority = 4
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p:low"]'::jsonb);

-- Priority 5 (Backlog)
UPDATE qxb_artifact
SET tags = COALESCE(tags, '[]'::jsonb) || '["p:backlog"]'::jsonb
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND priority = 5
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["p:backlog"]'::jsonb);
```

---

## Helper Pattern: Append then Deduplicate

All backfill rules use the same safe append pattern:

```sql
-- Append tag only if not already present
SET tags = COALESCE(tags, '[]'::jsonb) || '["new-tag"]'::jsonb
WHERE ...
  AND jsonb_typeof(COALESCE(tags, '[]'::jsonb)) = 'array'
  AND NOT (COALESCE(tags, '[]'::jsonb) @> '["new-tag"]'::jsonb)
```

**Why this pattern?**
1. `COALESCE(tags, '[]'::jsonb)` — handles null safely
2. `jsonb_typeof(...) = 'array'` — guards against non-array values
3. `NOT ... @>` — idempotent, won't duplicate if already present
4. Post-backfill deduplication catches any edge cases

---

## Post-Backfill: Deduplicate Tags

```sql
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
-- !!                    DO NOT EXECUTE                     !!
-- !!         Run after all rules complete                  !!
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

UPDATE qxb_artifact
SET tags = (
    SELECT jsonb_agg(DISTINCT value ORDER BY value)
    FROM jsonb_array_elements_text(tags)
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND tags IS NOT NULL
  AND jsonb_typeof(tags) = 'array'
  AND tags != '[]'::jsonb;
```

---

## Verification Queries

### Tag Distribution

```sql
-- SAFE TO EXECUTE: Read-only

SELECT
    tag,
    COUNT(*) as count
FROM qxb_artifact,
     LATERAL jsonb_array_elements_text(COALESCE(tags, '[]'::jsonb)) as tag
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
GROUP BY tag
ORDER BY count DESC, tag;
```

### Artifacts Without Tags

```sql
-- SAFE TO EXECUTE: Read-only

SELECT artifact_id, artifact_type, title
FROM qxb_artifact
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND (tags IS NULL OR tags = '[]'::jsonb)
ORDER BY artifact_type, created_at DESC;
```

### Gateway Test

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "selector": {
    "limit": 10,
    "filters": {
      "tags_any": ["auto:bugfix"]
    }
  }
}
```

---

## Execution Checklist

### Phase 1: Dry-Run Previews (Approval Gate)

Run all previews and categorize results:

**Preview A — Deterministic (auto-approve):**
- [ ] Rule 1: Type-based tags — should match artifact count per type
- [ ] Rule 2: Lifecycle tags — should match projects with lifecycle_status
- [ ] Rule 4: Relationship tags — should match parent/child relationships
- [ ] Rule 5: Priority tags — should match non-default priorities

**Preview B — High Confidence (quick review):**
- [ ] Rule 3: `^BUG-\d+` → `auto:bugfix`
- [ ] Rule 3: `^RESTART[:\s]` → `auto:restart-prompt`
- [ ] Rule 3: `^SNAPSHOT[:\s]` → `auto:milestone`
- [ ] Rule 3: `^PRD[:\s_]` → `auto:prd`

**Preview C — Semantic (careful review):**
- [ ] Rule 3: `\yGateway\y` → `auto:gateway` — verify no false positives
- [ ] Rule 3: `\yKGB\y` → `auto:kgb` — verify matches governance docs
- [ ] Rule 3: `\yTelegram\y` → `auto:telegram`
- [ ] Rule 3: `North\s*Star` → `auto:north-star`
- [ ] Rule 3B: Review tightened patterns, record decision

**✅ APPROVAL GATE:** Do not proceed until A+B look clean and C has been manually sampled.

### Phase 2: Execution

1. [ ] Test on single artifact first (pick one journal)
2. [ ] Execute Rule 1 (type tags)
3. [ ] Execute Rule 2 (lifecycle tags)
4. [ ] Execute Rule 4 (relationship tags)
5. [ ] Execute Rule 5 (priority tags)
6. [ ] Execute Rule 3 (pattern tags — one at a time, anchored first)
7. [ ] Run deduplication

### Phase 3: Verification

8. [ ] Run tag distribution query
9. [ ] Run artifacts-without-tags query
10. [ ] Test Gateway `tags_any` filtering
11. [ ] Save execution snapshot to Qwrk

---

## Tag Vocabulary Reference (v2)

### Structural (no prefix)
`project`, `journal`, `snapshot`, `restart`, `instruction-pack`, `linked`, `has-children`

### Lifecycle (`lc:` prefix)
`lc:seed`, `lc:sapling`, `lc:tree`, `lc:retired`

### Auto-Inferred (`auto:` prefix)
`auto:bugfix`, `auto:restart-prompt`, `auto:milestone`, `auto:kgb`, `auto:gateway`, `auto:prd`, `auto:north-star`, `auto:seed-content`, `auto:telegram`, `auto:moltbot`

### Priority (`p:` prefix)
`p:critical`, `p:high`, `p:low`, `p:backlog`

### Human-Intent (forward only, no backfill)
`important`, `review`, `wip`, `blocked`, `urgent`

---

## Decision Log

Record decisions made during execution for governance traceability.

| Date | Rule | Decision | Rows Affected | Notes |
|------|------|----------|---------------|-------|
| _TBD_ | 3B: implementation | _TBD_ | _TBD_ | _After preview review_ |
| _TBD_ | 3B: schema | _TBD_ | _TBD_ | _After preview review_ |
| _TBD_ | 3B: session | _TBD_ | _TBD_ | _After preview review_ |
| _TBD_ | 3B: test | _TBD_ | _TBD_ | _After preview review_ |

---

## Tiered Rollback Strategy

If issues are discovered after execution:

### Tier 1: Remove `auto:` tags only (safest)
```sql
UPDATE qxb_artifact
SET tags = (
    SELECT COALESCE(jsonb_agg(value), '[]'::jsonb)
    FROM jsonb_array_elements_text(tags) as value
    WHERE value NOT LIKE 'auto:%'
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(tags) = 'array'
  AND EXISTS (
      SELECT 1 FROM jsonb_array_elements_text(tags) t WHERE t LIKE 'auto:%'
  );
```

### Tier 2: Remove `lc:` tags (lifecycle convenience)
```sql
UPDATE qxb_artifact
SET tags = (
    SELECT COALESCE(jsonb_agg(value), '[]'::jsonb)
    FROM jsonb_array_elements_text(tags) as value
    WHERE value NOT LIKE 'lc:%'
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(tags) = 'array'
  AND EXISTS (
      SELECT 1 FROM jsonb_array_elements_text(tags) t WHERE t LIKE 'lc:%'
  );
```

### Tier 3: Full reset (emergency only)
```sql
-- Preserves only human-intent tags that don't have prefixes
UPDATE qxb_artifact
SET tags = (
    SELECT COALESCE(jsonb_agg(value), '[]'::jsonb)
    FROM jsonb_array_elements_text(tags) as value
    WHERE value NOT LIKE 'auto:%'
      AND value NOT LIKE 'lc:%'
      AND value NOT LIKE 'p:%'
      AND value NOT IN ('project','journal','snapshot','restart','instruction-pack','linked','has-children')
)
WHERE workspace_id = 'be0d3a48-c764-44f9-90c8-e846d9dbbd0a'
  AND deleted_at IS NULL
  AND jsonb_typeof(tags) = 'array';
```

---

## Governance Snapshot Prompt

After successful execution, save this to Qwrk:

```
Save snapshot titled "Tag Backfill v2 Execution Complete" tagged governance, milestone:

## Summary
Executed Tag Backfill Plan v2 on [DATE].

## Scope
- Workspace: be0d3a48-c764-44f9-90c8-e846d9dbbd0a
- Rules executed: 1, 2, 3, 4, 5 [adjust as needed]
- Total artifacts tagged: [COUNT]

## Tag Distribution (post-execution)
[Paste output of tag distribution query]

## Decisions Made
[Copy from Decision Log above]

## Verification
- Gateway tags_any filter: PASSED
- Artifacts without tags: [COUNT]

## Related
- BUG-011: First-Class Tags Implementation
- Plan document: docs/tasks/TAG_BACKFILL_PLAN_v2__2026-02-01.md
```

---

**End of Plan v2.1 (CC + QP1 Merged)**
