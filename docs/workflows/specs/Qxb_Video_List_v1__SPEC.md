# Qxb_Video_List_v1 — Workflow Specification

**Version:** v1 (2026-01-04)
**Status:** Specification (Pre-Build)
**Purpose:** List video artifacts with filtering (Gateway subworkflow)

---

## Overview

This workflow implements the **list operation** for video artifacts. It queries `qxb_artifact` joined with `qxb_artifact_video` and returns a filtered, paginated list.

**Architecture:** Gateway read subworkflow (called by NQxb_Gateway_v1 for `artifact.list` + `artifact_type=video`)

---

## Trigger

**Type:** Execute Workflow (called by Gateway)

**Invocation Context:** Gateway `artifact.list` action with `artifact_type='video'`

---

## Input Contract

### Gateway Request

```json
{
  "action": "artifact.list",
  "workspace_id": "uuid (required)",
  "artifact_type": "video",
  "filters": {
    "status": "complete|failed|... (optional, default: complete)",
    "source_platform": "youtube|vimeo|... (optional)",
    "tags": ["tag1", "tag2"] (optional),
    "search": "text search in title/summary (optional)"
  },
  "pagination": {
    "limit": 50 (optional, default: 50, max: 100),
    "offset": 0 (optional, default: 0)
  },
  "sort": {
    "by": "created_at|updated_at|title (optional, default: created_at)",
    "order": "desc|asc (optional, default: desc)"
  }
}
```

---

## Output Contract

### Success Response

```json
{
  "status": "ok",
  "artifact_type": "video",
  "count": 15,
  "total": 42,
  "limit": 50,
  "offset": 0,
  "artifacts": [
    {
      "artifact_id": "uuid",
      "workspace_id": "uuid",
      "owner_user_id": "uuid",
      "artifact_type": "video",
      "title": "...",
      "summary": "...",
      "priority": 3,
      "tags": ["video", "youtube"],
      "created_at": "2026-01-04T10:00:00Z",
      "updated_at": "2026-01-04T10:05:00Z",
      "video": {
        "source_url": "https://...",
        "source_platform": "youtube",
        "source_video_id": "dQw4w9WgXcQ",
        "source_channel": null,
        "duration_seconds": 212,
        "status": "complete",
        "idempotency_key": "youtube:dQw4w9WgXcQ",
        "has_transcript": true
      }
    }
  ]
}
```

**Notes:**
- `count` = number of items in current page
- `total` = total matching items (for pagination UI)
- `video.has_transcript` = boolean indicating if `content.transcription.full_text` is non-empty

---

## Node-by-Node Specification

### Node 1: Normalize_Filters
**Type:** Code (JavaScript)
**Purpose:** Extract and normalize filter parameters

**Input:**
- `$json.workspace_id`
- `$json.filters` (optional)
- `$json.pagination` (optional)
- `$json.sort` (optional)

**Logic:**
```javascript
// Extract workspace_id (required)
if (!$json.workspace_id) {
  return {
    ok: false,
    error: {
      code: 'VALIDATION_ERROR',
      message: 'workspace_id is required'
    }
  };
}

// Normalize filters
const filters = $json.filters || {};
const status = filters.status || 'complete'; // Default: only show completed transcriptions
const source_platform = filters.source_platform || null;
const tags = filters.tags || null;
const search = filters.search || null;

// Normalize pagination
const pagination = $json.pagination || {};
const limit = Math.min(pagination.limit || 50, 100); // Max 100 items
const offset = pagination.offset || 0;

// Normalize sort
const sort = $json.sort || {};
const sortBy = sort.by || 'created_at';
const sortOrder = sort.order || 'desc';

return {
  ok: true,
  workspace_id: $json.workspace_id,
  status: status,
  source_platform: source_platform,
  tags: tags,
  search: search,
  limit: limit,
  offset: offset,
  sortBy: sortBy,
  sortOrder: sortOrder
};
```

**Output:**
- `ok: true/false`
- `workspace_id`
- `status`, `source_platform`, `tags`, `search`
- `limit`, `offset`, `sortBy`, `sortOrder`
- `error` (if validation failed)

---

### Node 2: Guard_Validation_Error
**Type:** IF
**Purpose:** Short-circuit if validation failed

**Condition:**
```
{{ $json.ok === false }}
```

**Branches:**
- **TRUE** → Return error envelope
- **FALSE** → Continue to query

---

### Node 3: Query_Spine_And_Extension
**Type:** Supabase (SELECT with JOIN)
**Purpose:** Fetch artifacts with joined extension data

**Credentials:** "Qwrk Supabase – Kernel v1"

**Table:** `qxb_artifact`

**Joins:**
- **INNER JOIN** `qxb_artifact_video` ON `qxb_artifact.artifact_id = qxb_artifact_video.artifact_id`

**Filters:**
- `workspace_id` = `{{ $json.workspace_id }}`
- `artifact_type` = `'video'`
- `deleted_at` IS NULL
- **Conditional:**
  - If `status` provided: `qxb_artifact_video.status` = `{{ $json.status }}`
  - If `source_platform` provided: `qxb_artifact_video.source_platform` = `{{ $json.source_platform }}`
  - If `tags` provided: `tags` @> `{{ $json.tags }}` (JSONB contains operator)
  - If `search` provided: `title` ILIKE `%{{ $json.search }}%` OR `summary` ILIKE `%{{ $json.search }}%`

**Sort:**
- `{{ $json.sortBy }}` `{{ $json.sortOrder }}`

**Pagination:**
- **LIMIT:** `{{ $json.limit }}`
- **OFFSET:** `{{ $json.offset }}`

**Return Fields:**
- All spine fields: `artifact_id`, `workspace_id`, `owner_user_id`, `artifact_type`, `title`, `summary`, `priority`, `tags`, `content`, `created_at`, `updated_at`
- Extension fields (prefixed with `video_`): `source_url`, `source_platform`, `source_video_id`, `source_channel`, `duration_seconds`, `status`, `idempotency_key`, `content` (JSONB)

**Notes:**
- n8n Supabase node may not support JOIN directly
- **Alternative:** Run two separate queries and merge in Code node (see Node 4 alternative)

---

### Node 4 (Alternative): Query_Spine_Only
**Type:** Supabase (SELECT)
**Purpose:** Fetch spine records first (if JOIN not supported)

**Table:** `qxb_artifact`

**Filters:**
- `workspace_id` = `{{ $json.workspace_id }}`
- `artifact_type` = `'video'`
- `deleted_at` IS NULL
- (Additional filters as above)

**Pagination & Sort:** As above

**Output:** Array of spine records

---

### Node 5 (Alternative): Fetch_Extensions
**Type:** Supabase (SELECT)
**Purpose:** Fetch extension records for returned artifact_ids

**Table:** `qxb_artifact_video`

**Filters:**
- `artifact_id` IN `{{ $('Query_Spine_Only').all().map(item => item.json.artifact_id) }}`

**Output:** Array of extension records

---

### Node 6 (Alternative): Merge_Spine_And_Extension
**Type:** Code (JavaScript)
**Purpose:** Merge spine and extension data

**Logic:**
```javascript
const spineRecords = $('Query_Spine_Only').all();
const extensionRecords = $('Fetch_Extensions').all();

// Build extension lookup map
const extensionMap = {};
extensionRecords.forEach(ext => {
  extensionMap[ext.json.artifact_id] = ext.json;
});

// Merge
const merged = spineRecords.map(spine => {
  const ext = extensionMap[spine.json.artifact_id] || {};

  return {
    artifact_id: spine.json.artifact_id,
    workspace_id: spine.json.workspace_id,
    owner_user_id: spine.json.owner_user_id,
    artifact_type: spine.json.artifact_type,
    title: spine.json.title,
    summary: spine.json.summary,
    priority: spine.json.priority,
    tags: spine.json.tags,
    created_at: spine.json.created_at,
    updated_at: spine.json.updated_at,
    video: {
      source_url: ext.source_url,
      source_platform: ext.source_platform,
      source_video_id: ext.source_video_id,
      source_channel: ext.source_channel,
      duration_seconds: ext.duration_seconds,
      status: ext.status,
      idempotency_key: ext.idempotency_key,
      has_transcript: !!(ext.content?.transcription?.full_text)
    }
  };
});

return merged;
```

**Output:** Array of merged artifact objects

---

### Node 7: Count_Total
**Type:** Supabase (SELECT COUNT)
**Purpose:** Get total count of matching records (for pagination)

**Table:** `qxb_artifact`

**Filters:** Same as Query_Spine_Only (without LIMIT/OFFSET)

**Aggregation:** COUNT(*)

**Output:** `total` (integer)

---

### Node 8: Format_Response
**Type:** Code (JavaScript)
**Purpose:** Build Gateway list response envelope

**Logic:**
```javascript
const artifacts = $('Merge_Spine_And_Extension').all().map(item => item.json);
const total = $('Count_Total').item.json.count || 0;
const limit = $('Normalize_Filters').item.json.limit;
const offset = $('Normalize_Filters').item.json.offset;

return {
  status: 'ok',
  artifact_type: 'video',
  count: artifacts.length,
  total: total,
  limit: limit,
  offset: offset,
  artifacts: artifacts
};
```

**Output:** Gateway-compliant list response

---

## Workflow Flow Diagram

```
Start (Called by Gateway)
  ↓
1. Normalize_Filters
  ↓
2. Guard_Validation_Error (IF)
  ↓ (ok=false)         ↓ (ok=true)
Return Error        4. Query_Spine_Only (artifact table)
                       ↓
                    5. Fetch_Extensions (artifact_video table)
                       ↓
                    6. Merge_Spine_And_Extension
                       ↓
                    7. Count_Total (for pagination)
                       ↓
                    8. Format_Response
                       ↓
                    Return to Gateway
```

---

## Default Filtering Behavior

**MVP Defaults:**
- **status:** `complete` (only show successfully transcribed videos)
- **deleted_at:** IS NULL (exclude soft-deleted artifacts)
- **Sort:** `created_at DESC` (newest first)
- **Limit:** 50 items per page
- **Offset:** 0

**Rationale:**
- Most users want to see completed videos, not failed/in-progress
- Failed videos can be queried explicitly with `filters.status = 'failed'`

---

## Query Performance

**Indexes Required (for performance):**
- `qxb_artifact`: (workspace_id, artifact_type, created_at)
- `qxb_artifact_video`: (artifact_id) - already PK
- `qxb_artifact_video`: (status) - for status filtering
- `qxb_artifact`: GIN index on `tags` - for tag filtering

**Expected Query Time:**
- < 50ms for typical workspace (< 1000 videos)
- < 200ms with full-text search

---

## Testing

### Test Cases

1. **List all completed videos** (default)
   ```json
   {
     "action": "artifact.list",
     "workspace_id": "...",
     "artifact_type": "video"
   }
   ```

2. **List failed videos**
   ```json
   {
     "action": "artifact.list",
     "workspace_id": "...",
     "artifact_type": "video",
     "filters": { "status": "failed" }
   }
   ```

3. **Search by title**
   ```json
   {
     "action": "artifact.list",
     "workspace_id": "...",
     "artifact_type": "video",
     "filters": { "search": "react tutorial" }
   }
   ```

4. **Filter by tag**
   ```json
   {
     "action": "artifact.list",
     "workspace_id": "...",
     "artifact_type": "video",
     "filters": { "tags": ["conference", "2024"] }
   }
   ```

5. **Pagination**
   ```json
   {
     "action": "artifact.list",
     "workspace_id": "...",
     "artifact_type": "video",
     "pagination": { "limit": 10, "offset": 20 }
   }
   ```

---

## Future Enhancements

1. **Full-text search** on transcript content (not just title/summary)
2. **Date range filters** (created_at between X and Y)
3. **Duration filters** (videos longer than N minutes)
4. **Channel/source filters**
5. **Advanced sorting** (by duration, by transcript length)

---

**End of Specification**

**Next Steps:**
1. Review and approve
2. Build in n8n GUI
3. Integrate routing in NQxb_Gateway_v1
4. Test with various filter combinations
5. Export JSON and commit
