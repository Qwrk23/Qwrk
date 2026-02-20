# Restart Prompt: BUG-011 First-Class Tags Implementation

**Created:** 2026-01-28
**Bug Reference:** BUG-011 (Write Contract Registry blocks spine fields on CREATE)
**Bug Tracker:** `docs/Qwrk_Bug_Tracker.md`
**Specification:** `CC_Inbox/cc_prompt_tags.md`

---

## Context

Currently, qfe (Qwrk front-end) preflight validation rejects spine fields like `tags`, `summary`, and `content` on artifact.save CREATE operations. The Write Contract Registry only allows `title` and `extension.lifecycle_stage`, blocking first-class metadata support.

This prevents:
- Tagging artifacts for search/filtering
- Adding summaries at creation time
- Structured content in the `content` field

---

## Goal

Enable first-class tags across ALL artifact types:
1. Accept `tags` on artifact.save CREATE
2. Persist to `qxb_artifact.tags` (JSONB array)
3. Enable `artifact.list` filtering by tag
4. Query: "Find all journals tagged 'conversation'" returns only matching journals

---

## Implementation Plan

### Phase 1: qfe Write Contract Registry Update

**Location:** qfe instruction pack (Write Contract section)

**Current (broken):**
```
For project CREATE, only extension.lifecycle_stage allowed.
```

**Target:**
```
For project CREATE, allowed fields:
- title (required)
- summary (optional)
- tags (optional, array of strings)
- content (optional)
- parent_artifact_id (optional)
- extension.lifecycle_stage (required)
```

**Apply to ALL artifact types:**
- project
- journal
- snapshot
- restart
- instruction_pack

**Task:** Locate the Write Contract Registry in qfe instructions and expand allow-lists.

---

### Phase 2: Gateway Validator Update

**Workflow:** NQxb_Artifact_Save_v1

**Changes needed:**
1. `Normalize_Request` node: Accept `tags` as top-level field
2. Add tag normalization logic:
   - Trim whitespace from each tag
   - Remove empty strings
   - De-duplicate
   - Lowercase for deterministic search
3. `DB_Insert_Spine` node: Map `tags` to `qxb_artifact.tags`

**Tag Normalization Expression (n8n):**
```javascript
{{
  ($json.tags || [])
    .map(t => t.trim().toLowerCase())
    .filter(t => t.length > 0)
    .filter((t, i, arr) => arr.indexOf(t) === i)
}}
```

---

### Phase 3: Gateway artifact.list Tag Filtering

**Workflow:** NQxb_Artifact_List_v1

**Changes needed:**
1. Accept new selector parameter: `filters.tags_any`
2. Build SQL WHERE clause for JSONB array containment
3. Apply filter before pagination

**SQL Pattern:**
```sql
-- Filter: tags_any = ["conversation", "important"]
WHERE tags ?| array['conversation', 'important']
```

**PostgREST equivalent:**
```
tags=ov.{"conversation","important"}
```

---

### Phase 4: Tests

**Required test cases:**

| # | Test | Expected |
|---|------|----------|
| 1 | Create journal with `tags: ["conversation"]` | Success, tags persisted |
| 2 | List journals with `tags_any: ["conversation"]` | Returns tagged journal |
| 3 | List projects with `tags_any: ["conversation"]` | Does NOT return the journal |
| 4 | Create artifact with unknown field `foo` | Still rejected (validation) |
| 5 | Query artifact, verify `tags` in hydrated response | Tags present |

---

## Files to Modify

| File | Change |
|------|--------|
| qfe instruction pack | Expand Write Contract allow-lists |
| `workflows/NQxb_Artifact_Save_v1 (XX).json` | Add tags normalization + DB mapping |
| `workflows/NQxb_Artifact_List_v1 (XX).json` | Add tags_any filter support |

---

## Acceptance Criteria

- [ ] qfe accepts `tags` on artifact.save CREATE (no preflight rejection)
- [ ] Gateway persists tags to `qxb_artifact.tags`
- [ ] Tags normalized (trimmed, lowercase, de-duped)
- [ ] `artifact.list` with `tags_any` filter returns only matching artifacts
- [ ] Cross-type isolation: journal tags don't match project queries
- [ ] Unknown fields still rejected (security)
- [ ] Tags hydrated correctly on query/list

---

## Order of Operations

1. **qfe first** — Unblock preflight so requests reach Gateway
2. **Gateway Save** — Persist tags correctly
3. **Gateway List** — Enable tag filtering
4. **Tests** — Verify end-to-end

Do NOT ship partial. All four phases must complete together.

---

## Start Command

To begin implementation:

> "I'm implementing BUG-011 (first-class tags). Let's start with Phase 1: locating the qfe Write Contract Registry. Show me the current instruction pack that defines allowed fields for artifact.save CREATE operations."
