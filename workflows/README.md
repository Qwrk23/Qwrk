# n8n Workflows — New Qwrk Gateway v1

**Artifact-first gateway workflows for New Qwrk Kernel v1**

---

## Overview

This directory contains n8n workflow JSON files that implement the Qwrk Gateway v1 contract. The Gateway enforces behavioral rules, validates requests, and coordinates with the Supabase backend.

**Platform**: n8n (workflow automation)
**Architecture**: Artifact-first routing with flat envelope design
**Status**: Kernel v1 MVP complete

---

## Directory Structure

```
workflows/
├── NQxb_Gateway_v1.json           # Main gateway router
├── NQxb_Artifact_Query_v1.json    # Query single artifact by ID
├── NQxb_Artifact_List_v1.json     # List artifacts with filters
├── NQxb_Artifact_Save_v1.json     # Create/update artifacts (deprecated)
├── NQxb_Artifact_Create_v1.json   # Create new artifacts
├── NQxb_Artifact_Update_v1.json   # Update existing artifacts
├── changelogs/                    # Workflow documentation
│   ├── NQxb_Artifact_Save_v1__README.md
│   ├── NQxb_Artifact_List_v1__README.md
│   ├── NQxb_Artifact_Create_v1__CHANGELOG.md
│   ├── NQxb_Artifact_Update_v1__Test_Cases.md
│   ├── NQxb_Artifact_Create_v1__Audit_Report.md
│   └── NQxb_Artifact_Update_v1__Audit_Report.md
└── README.md                      # This file
```

---

## Gateway Actions (Kernel v1)

| Action | Workflow | Status | Purpose |
|--------|----------|--------|---------|
| `artifact.query` | NQxb_Artifact_Query_v1 | ✅ Complete | Retrieve single artifact by ID (hydrated by default) |
| `artifact.list` | NQxb_Artifact_List_v1 | ✅ Complete | List artifacts with filtering/pagination (base-only by default) |
| `artifact.create` | NQxb_Artifact_Create_v1 | ✅ Complete | Create new artifacts (replaces Save for INSERT) |
| `artifact.update` | NQxb_Artifact_Update_v1 | ✅ Complete | Update existing artifacts (PATCH semantics) |
| `artifact.save` | NQxb_Artifact_Save_v1 | ⚠️ Deprecated | Combined create/update (kept for backward compatibility) |
| `artifact.promote` | (planned) | 📋 Planned | Lifecycle transitions with snapshot creation |

---

## Quick Start

### Prerequisites

- n8n instance (self-hosted or cloud)
- Supabase project connection configured
- Supabase credentials (URL, anon key, service role key)

### Import Workflows

1. Import `NQxb_Gateway_v1.json` first (main router)
2. Import artifact operation workflows (Query, List, Create, Update)
3. Configure Supabase credentials in each workflow's HTTP Request nodes

### Test Workflows

Each workflow includes **pinned test data** for manual execution:

1. Open workflow in n8n
2. Click "Execute Workflow" (uses pinned data)
3. Verify response envelope structure

---

## Gateway Contract

### Request Envelope (Flat Design)

```json
{
  "gw_user_id": "uuid (required)",
  "gw_workspace_id": "uuid (required)",
  "gw_action": "artifact.query | artifact.list | artifact.create | artifact.update",
  "gw_request_id": "string (optional)",
  "artifact_type": "project | snapshot | restart | journal",
  "artifact_id": "uuid (for query/update)",
  "artifact_payload": { /* type-specific fields */ },
  "selector": { /* filters, pagination, hydration */ }
}
```

### Response Envelope

**Success (single artifact):**
```json
{
  "ok": true,
  "artifact": { /* merged spine + extension fields */ }
}
```

**Success (list):**
```json
{
  "ok": true,
  "_gw_route": "ok",
  "items": [ /* array of artifacts */ ],
  "meta": {
    "count": 10,
    "limit": 50,
    "offset": 0
  }
}
```

**Error:**
```json
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": { /* additional context */ }
  }
}
```

---

## Workflow Details

### NQxb_Gateway_v1

**Purpose**: Main router that validates requests and routes to appropriate artifact operation workflows

**Features**:
- Request normalization
- Artifact type validation
- Action routing (query/list/create/update)
- Type mismatch guards
- Error envelope standardization

**Latest Version**: NQxb_Gateway_v1 (8).json

### NQxb_Artifact_Query_v1

**Purpose**: Retrieve a single artifact by ID

**Features**:
- Spine-first architecture (fetch `Qxb_Artifact` first)
- Type branching (routes to correct extension table)
- Hydrated response by default
- Optional `selector.base_only = true` for spine-only
- Type mismatch detection

**Response**: Merged spine + extension fields

### NQxb_Artifact_List_v1

**Purpose**: List artifacts with filtering and pagination

**Features**:
- Base-only by default (fast lists)
- Optional `selector.hydrate = true` (full hydration)
- Filters: artifact_type, parent_artifact_id
- Pagination: limit (default 50, max 100), offset
- Workspace-scoped (RLS enforced)

**Response**: Array of artifacts with meta (count, limit, offset)

### NQxb_Artifact_Create_v1

**Purpose**: Create new artifacts (INSERT only)

**Features**:
- Auto-generates artifact_id
- Comprehensive validation
- Spine + extension INSERT coordination
- Lifecycle alignment (project lifecycle_status ↔ lifecycle_stage)
- Returns created artifact via query

**Supported Types**: project, journal, snapshot, restart

See `changelogs/NQxb_Artifact_Create_v1__CHANGELOG.md` for details.

### NQxb_Artifact_Update_v1

**Purpose**: Update existing artifacts (PATCH semantics)

**Features**:
- PATCH semantics (only update provided fields)
- Immutability enforcement (snapshot, restart blocked)
- Journal INSERT-ONLY doctrine enforcement
- NOT_FOUND detection
- Extension UPSERT (auto-creates missing rows)
- Mutability registry compliance

**Supported Types**: project (mutable), journal (blocked by doctrine)

See `changelogs/NQxb_Artifact_Update_v1__Test_Cases.md` for validation.

### NQxb_Artifact_Save_v1 (Deprecated)

**Status**: ⚠️ Deprecated in favor of separate Create/Update workflows

**Purpose**: Combined create/update workflow (auto-detects based on artifact_id)

**Deprecation Reason**:
- Ambiguous semantics (INSERT vs UPDATE)
- Separate workflows provide clearer contracts
- Kept for backward compatibility only

**Recommendation**: Use `artifact.create` or `artifact.update` instead.

---

## Workflow Configuration

### Supabase Connection

Each workflow uses HTTP Request nodes to call Supabase REST API:

- **URL**: `https://[project-ref].supabase.co/rest/v1/[table]`
- **Headers**:
  - `apikey`: Supabase anon key
  - `Authorization`: `Bearer [service-role-key]` (for admin operations)
  - `Content-Type`: `application/json`

### Environment Variables (Recommended)

Create n8n credentials for:

- `SUPABASE_URL`: `https://npymhacpmxdnkdgzxll.supabase.co`
- `SUPABASE_ANON_KEY`: (from Supabase project settings)
- `SUPABASE_SERVICE_KEY`: (from Supabase project settings)

---

## Hard Rules (CRITICAL - DO NOT VIOLATE)

These rules are enforced by governance and must be followed when editing workflows:

### 1. Expression Syntax
- **DO NOT** type a leading `=` in n8n expressions; n8n adds it automatically

### 2. Supabase Nodes
- Supabase nodes are dumb column writers
- Flatten payloads before DB nodes; don't auto-map wrapped payloads

### 3. Node Naming
- Use `NQxb`-prefixed names consistently
- Example: `NQxb_Artifact_Query_v1__Fetch_Spine`

### 4. Switch Comparison Safety
- Guard against hidden whitespace/newlines using `.trim()`
- Example: `$json.artifact_type.trim() === 'project'`

### 5. No Guessing
- Do not guess schemas, enums, endpoints, or commands
- Stop and ask for canonical source if unclear

---

## Testing

### Manual Testing (Pinned Data)

Each workflow includes pinned test data accessible via "Execute Workflow" button.

### Contract Tests

Run these scenarios to validate Gateway compliance:

**Query Tests**:
- ✅ Query existing project by ID → returns hydrated artifact
- ✅ Query with base_only=true → returns spine fields only
- ❌ Query non-existent ID → returns NOT_FOUND error

**List Tests**:
- ✅ List all artifacts in workspace → returns base-only by default
- ✅ List with hydrate=true → returns merged objects
- ✅ List with artifact_type filter → returns only matching type
- ✅ List with pagination (limit/offset) → returns correct subset

**Create Tests**:
- ✅ Create project with lifecycle_stage → spine.lifecycle_status aligned
- ✅ Create snapshot → immutable payload stored
- ❌ Create with missing required fields → VALIDATION_ERROR

**Update Tests**:
- ✅ Update project with partial fields → PATCH semantics (unspecified fields preserved)
- ❌ Update snapshot → IMMUTABILITY_ERROR
- ❌ Update journal → JOURNAL_MUTABILITY_UNDECIDED error
- ❌ Update non-existent artifact → NOT_FOUND

---

## Known Issues & Limitations

### Pagination (List Workflow)

- **Issue**: Pagination is manual (code-based slicing)
- **Reason**: n8n Supabase node limitations
- **Workaround**: Fetch up to limit, then filter/slice in code
- **Future**: Native Supabase filters when n8n supports them

### No Total Count (List Workflow)

- **Issue**: Response does not include total matching artifacts
- **Reason**: Requires separate COUNT query
- **Workaround**: `meta.count` reflects returned items only
- **Future**: Add optional total_count query

### Journal Mutability

- **Issue**: Journal UPDATE operations are blocked
- **Reason**: Mutability policy not locked (see Doctrine)
- **Status**: Temporary INSERT-ONLY enforcement
- **Future**: Unlock when design decision made

---

## Changelog

See individual workflow changelogs in `changelogs/` directory.

### Recent Updates

**2026-01-02**:
- Split Save workflow into Create + Update
- Added immutability enforcement for snapshot/restart
- Added journal doctrine enforcement
- Improved error envelopes (standardized codes)

**2026-01-01**:
- Added PATCH semantics to Update workflow
- Added extension UPSERT (missing row handling)
- Added lifecycle alignment (project)
- Added error short-circuiting

---

## References

- [Gateway Contract (Phase 3)](../docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md#phase-3-gateway-contract-v1-planning-lock)
- [Mutability Registry](../docs/governance/Mutability_Registry_v1.md)
- [Journal Doctrine](../docs/governance/Doctrine_Journal_InsertOnly_Temporary.md)
- [CLAUDE.md](../docs/governance/CLAUDE.md) - Workflow editing governance

---

**Last Updated**: 2026-01-02
**Gateway Version**: v1 (Kernel v1)
