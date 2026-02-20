# Qwrk — Database Interaction Patterns (LOCKED)

**Status:** Locked  
**Source of Truth:**  
Beta Readiness — Governance & Contract Locks  
content.db_patterns.jsonb_content_updates_v1

This document defines the **canonical, non-negotiable patterns** for reading and updating Qwrk database records.  
It applies to **humans, Claude Code (CC), Gateway v1+, and the future Qwrk UI**.

---

## 1. Core Principle

> **Thin reads by default. Hydrated reads by intent.**

Qwrk separates *browsing* from *understanding*.

---

## 2. Read Patterns (Authoritative)

### 2.1 Artifact List = Thin Read

**Rule**  
`artifact.list` **MUST NOT** return `content` by default.

**Why**
- Keeps list views fast and calm  
- Prevents accidental over-fetching  
- Avoids mixing summaries with canonical intent  

**Allowed fields (example)**
- artifact_id  
- artifact_type  
- title  
- summary  
- lifecycle_status  
- operational_state  
- parent_artifact_id  
- created_at / updated_at  

---

### 2.2 Artifact Query = Hydrated Read

**Rule**  
`artifact.query` **MUST** return:
- artifact spine  
- artifact extension  
- full `content`  

**Canonical SQL Shape**
```sql
SELECT jsonb_build_object(
  'artifact', to_jsonb(a),
  'project',  to_jsonb(p)
) AS full_record
FROM public.qxb_artifact a
JOIN public.qxb_artifact_project p
  ON p.artifact_id = a.artifact_id
WHERE a.artifact_id = $1;
```

---

### 2.3 Content-Only Read

```sql
SELECT a.content
FROM public.qxb_artifact a
WHERE a.artifact_id = $1;
```

---

## 3. Write Patterns (Critical)

### 3.1 content Mutability
`qxb_artifact.content` is mutable unless explicitly governed otherwise.

---

### 3.2 Sentinel Write (Diagnostic)

```sql
UPDATE public.qxb_artifact
SET content =
  COALESCE(content, '{}'::jsonb)
  || jsonb_build_object(
    '_write_test',
    jsonb_build_object(
      'at', now(),
      'note', 'sentinel write'
    )
  )
WHERE artifact_id = $1
  AND deleted_at IS NULL
RETURNING artifact_id, version, updated_at, content;
```

---

### 3.3 Preferred Nested JSON Merge

```sql
UPDATE public.qxb_artifact a
SET content =
  COALESCE(a.content, '{}'::jsonb)
  || jsonb_build_object(
    'some_parent_key',
    COALESCE(a.content->'some_parent_key', '{}'::jsonb)
    || jsonb_build_object('child_key', $2::jsonb)
  ),
  version = COALESCE(a.version,1) + 1,
  updated_at = now()
WHERE a.artifact_id = $1
  AND a.deleted_at IS NULL;
```

---

## 4. Lookup Patterns (Zero Manual IDs)

```sql
SELECT
  artifact_id,
  title,
  created_at
FROM public.qxb_artifact
WHERE workspace_id = $1
  AND artifact_type = $2
  AND deleted_at IS NULL
  AND lower(title) = lower($3)
ORDER BY created_at DESC;
```

---

## 5. Applicability

**Applies To**
- Assistant behavior  
- Claude Code (CC)  
- Gateway v1+  
- Future Qwrk frontend  

**Tables**
- public.qxb_artifact  
- public.qxb_artifact_project  

---

## Final Rule of Thumb

> If something feels confusing, ask:
> **“Am I doing a thin read or a hydrated read?”**
