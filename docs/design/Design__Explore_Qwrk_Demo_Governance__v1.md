# Design — Explore Qwrk Demo Governance

> **Version:** v1
> **Date:** 2026-03-15
> **Sapling:** `ed978e03-5899-49cf-b72f-a09898399a36`
> **Demo Workspace:** `0af5712b-2534-47c1-8e28-45be4a2131dc`
> **Status:** DRAFT — Awaiting Joel review

---

## 1. Purpose

Governance rules for the Shareable Qwrk Exploratory GPT demo environment. These rules are enforced by the demo proxy webhook before any request reaches Gateway v68. The demo workspace is fully isolated from all production workspaces.

## 2. Architecture Overview

```
User → ChatGPT CustomGPT → OpenAI Actions
                                ↓
                       n8n Demo Proxy Webhook
                       (enforce all rules below)
                                ↓
                       Gateway v68 (existing, unmodified)
                       (Save / Query / List sub-workflows)
                                ↓
                       Supabase → Demo Workspace (0af5712b)
```

**Principle:** The proxy is a thin enforcement and translation layer. Gateway v68 remains the canonical execution engine. No production workflows are modified.

## 3. Allowed Actions

| Action | Allowed | Notes |
|--------|---------|-------|
| `artifact.save` | YES | Create new artifacts only |
| `artifact.list` | YES | Browse demo workspace (max 20 results per request) |
| `artifact.query` | YES | View specific artifacts |
| `artifact.update` | NO | Rejected by proxy |
| `artifact.promote` | NO | Rejected by proxy |
| `artifact.delete` | NO | Rejected by proxy |
| `artifact.restore` | NO | Rejected by proxy |
| `artifact.list_deleted` | NO | Rejected by proxy |
| `messaging.send_email` | NO | Rejected by proxy |
| `messaging.create_calendar_event` | NO | Rejected by proxy |

**Rejection response for disallowed actions:**

```json
{
  "ok": false,
  "error": {
    "code": "ACTION_NOT_ALLOWED",
    "message": "This action is not available in the demo environment."
  }
}
```

## 4. Allowed Artifact Types

| Type | Allowed | Rationale |
|------|---------|-----------|
| `journal` | YES | Core demo scenario — reflective entries |
| `project` | YES | Core demo scenario — seed project creation |
| `snapshot` | YES | Core demo scenario — decision capture |
| `restart` | NO | Internal system artifact |
| `branch` | NO | Execution anatomy — not demo-appropriate |
| `leaf` | NO | Execution anatomy — not demo-appropriate |
| `limb` | NO | Execution anatomy — not demo-appropriate |
| `twig` | NO | Execution anatomy — not demo-appropriate |
| `instruction_pack` | NO | System infrastructure |
| `grass` | NO | Operational tracking |
| `thorn` | NO | Exception tracking |
| `forest` | NO | Reserved |
| `thicket` | NO | Reserved |
| `flower` | NO | Reserved |

**Rejection response for disallowed types:**

```json
{
  "ok": false,
  "error": {
    "code": "TYPE_NOT_ALLOWED",
    "message": "This artifact type is not available in the demo environment."
  }
}
```

## 5. Workspace Injection

**Rule:** Every request forwarded to the Gateway MUST have:

```
workspace_id = 0af5712b-2534-47c1-8e28-45be4a2131dc
```

- The proxy overwrites any `workspace_id` in the incoming request
- The client cannot override this value
- This is the sole isolation mechanism — all demo artifacts land in this workspace

**Gateway field name:** `gw_workspace_id` (per Gateway v68 contract)

## 6. Tag Injection

### 6.1 Auto-injected Tags (every `artifact.save`)

Every save request forwarded to the Gateway MUST include:

```json
"tags": ["demo-mode", "explore-qwrk"]
```

If the incoming request includes additional tags, the proxy merges them:
- User-provided tags are appended to the mandatory tags
- Duplicates are removed
- Maximum 10 tags total (user-provided tags truncated if exceeding limit)

### 6.2 Seed Artifact Tags

Seed artifacts (pre-populated by admin) carry an additional tag:

```json
["demo-mode", "explore-qwrk", "demo-seed"]
```

The `demo-seed` tag is NOT available to demo users — the proxy strips it from incoming requests. Only admin-created seed data carries this tag.

### 6.3 Forbidden Tags

The proxy strips the following tags from incoming requests before forwarding:

- `demo-seed` — reserved for admin seed data
- `for-q` — reserved for Qwrk governance memory
- `for-cc` — reserved for CC work queue

## 7. Owner Identity

All demo artifacts are created with:

```
owner_user_id = c52c7a57-74ad-433d-a07c-4dcac1778672  (Joel)
```

The proxy injects this on every `artifact.save`. Demo users do not have individual Supabase identities — all artifacts are owned by the system owner.

## 8. Semantic Type

All demo artifacts use:

```
semantic_type_id = "exploratory"
```

The proxy injects this on every `artifact.save`. The Gateway resolves the key string to the UUID internally.

## 9. Parent Artifact Validation

### v1 Behavior

`parent_artifact_id` is **NOT supported** in v1. If present on `artifact.save`, the proxy rejects the request:

```json
{
  "ok": false,
  "error": {
    "code": "PARENT_NOT_SUPPORTED",
    "message": "Parent-linked artifacts are not supported in the demo. Please create top-level artifacts."
  }
}
```

All demo artifacts are created as top-level entries.

### v2 (Planned)

`parent_artifact_id` will become OPTIONAL on `artifact.save`. If present, the proxy MUST verify the parent artifact belongs to workspace `0af5712b` before forwarding. Verification will call `artifact.query` **directly on Gateway v68** (not back through the proxy) to prevent recursive proxy loops.

Rejection for invalid parent (v2):

```json
{
  "ok": false,
  "error": {
    "code": "PARENT_NOT_IN_DEMO",
    "message": "The referenced parent artifact does not belong to the demo workspace."
  }
}
```

## 10. Size Limits

The proxy enforces payload size limits before forwarding to the Gateway.

| Field | Max Length | Enforcement |
|-------|-----------|-------------|
| `title` | 200 characters | Reject with error |
| `summary` | 1000 characters | Reject with error |
| `content` (jsonb) | 4 KB serialized | Reject with error |
| `extension.payload` (jsonb) | 4 KB serialized | Reject with error |

**Rejection response for oversized fields:**

```json
{
  "ok": false,
  "error": {
    "code": "FIELD_TOO_LONG",
    "message": "Titles must be under 200 characters and summaries under 1000 characters."
  }
}
```

**Rejection response for oversized payloads:**

```json
{
  "ok": false,
  "error": {
    "code": "PAYLOAD_TOO_LARGE",
    "message": "The content exceeds the demo size limit. Please keep entries concise."
  }
}
```

## 11. Rate Limiting

The proxy enforces basic rate limiting at the webhook level.

| Limit | Value |
|-------|-------|
| Global | 50 requests per minute |
| Per-IP | 10 requests per minute |

**Rate limit response:**

```json
{
  "ok": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "The demo is receiving a lot of activity right now. Please try again in a moment."
  }
}
```

**Implementation:** In-memory counters in the n8n Code node. Counters reset every 60 seconds. IP extracted from `$request.headers['x-forwarded-for']` or `$request.remoteAddress`.

## 12. Payload Translation

OpenAI Actions sends simplified JSON. The proxy translates to canonical Gateway format.

### 12.1 artifact.save

**Incoming (from CustomGPT):**

```json
{
  "action": "artifact.save",
  "artifact_type": "journal",
  "title": "Morning reflection",
  "summary": "Thinking about a new project"
}
```

**Translated (to Gateway v68):**

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "0af5712b-2534-47c1-8e28-45be4a2131dc",
  "artifact_type": "journal",
  "title": "Morning reflection",
  "summary": "Thinking about a new project",
  "tags": ["demo-mode", "explore-qwrk"],
  "semantic_type_id": "exploratory",
  "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672"
}
```

**Translation rules:**
- `action` → `gw_action`
- Inject `gw_workspace_id`
- Inject `tags` (merged with user tags)
- Inject `semantic_type_id`
- Inject `owner_user_id`
- Pass through: `artifact_type`, `title`, `summary`, `content`, `parent_artifact_id`
- Strip: `workspace_id`, `demo-seed` tag, `for-q` tag, `for-cc` tag

### 12.2 artifact.list

**Incoming:**

```json
{
  "action": "artifact.list",
  "artifact_type": "journal",
  "limit": 10
}
```

**Translated:**

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "0af5712b-2534-47c1-8e28-45be4a2131dc",
  "artifact_type": "journal",
  "selector": {
    "limit": 10,
    "offset": 0
  }
}
```

**Translation rules:**
- `action` → `gw_action`
- Inject `gw_workspace_id`
- `limit` → `selector.limit` (capped at 20, default 10 — any value > 20 is silently reduced to 20)
- `offset` → `selector.offset` (default 0)
- Pass through: `artifact_type`, `tags`
- `artifact_type` is REQUIRED for list in v1 (underlying sub-workflow constraint)

### 12.3 artifact.query

**Incoming:**

```json
{
  "action": "artifact.query",
  "artifact_type": "journal",
  "artifact_id": "abc12345-..."
}
```

**Translated:**

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "0af5712b-2534-47c1-8e28-45be4a2131dc",
  "artifact_type": "journal",
  "artifact_id": "abc12345-..."
}
```

**Translation rules:**
- `action` → `gw_action`
- Inject `gw_workspace_id`
- Pass through: `artifact_type`, `artifact_id`
- `artifact_type` is REQUIRED (Gateway contract)
- `artifact_id` is REQUIRED

## 13. Response Shaping

Gateway responses are passed back to the CustomGPT with minimal transformation.

**Success responses:** Pass through the `data` object. Strip internal fields:
- `workspace_id` — not useful to demo users
- `owner_user_id` — not useful to demo users
- `semantic_type_id` — not useful to demo users

**Error responses:** Translate Gateway error codes to friendly messages:

| Gateway Error | Demo Response |
|---------------|---------------|
| `TYPE_MISMATCH` | "That artifact is a different type than requested." |
| `NOT_FOUND` | "I couldn't find that artifact. It may have been cleaned up." |
| `VALIDATION_ERROR` | "Something wasn't quite right with that request. Let me try again." |
| Other errors | "Something unexpected happened. Let's try something else." |

## 14. Service Principal

| Property | Value |
|----------|-------|
| **Principal name** | `qwrk-gw-demo` |
| **ACL workspace** | `0af5712b-2534-47c1-8e28-45be4a2131dc` |
| **ACL role** | `owner` |
| **Basic auth** | Configured in n8n credentials (same pattern as other principals) |

The proxy authenticates to Gateway v68 using this principal's basic auth credentials.

## 15. Cleanup Strategy

### 15.1 Nightly Cleanup Job

All artifacts in workspace `0af5712b` that do NOT carry the `demo-seed` tag and are older than 24 hours are deleted.

```sql
DELETE FROM qxb_artifact
WHERE workspace_id = '0af5712b-2534-47c1-8e28-45be4a2131dc'
  AND NOT (tags @> '["demo-seed"]')
  AND created_at < now() - interval '24 hours';
```

### 15.2 Seed Artifact Protection

Seed artifacts carry `["demo-mode", "explore-qwrk", "demo-seed"]` and are excluded from cleanup. They represent the pre-populated demo content that users explore.

### 15.3 Manual Reset

Full workspace reset (including seeds) requires:

```sql
DELETE FROM qxb_artifact
WHERE workspace_id = '0af5712b-2534-47c1-8e28-45be4a2131dc';
```

Followed by re-running the seed script.

## 16. Lifecycle Restrictions

| Operation | Allowed | Notes |
|-----------|---------|-------|
| Create artifact | YES | Via `artifact.save` |
| Read artifact | YES | Via `artifact.query` and `artifact.list` |
| Update artifact | NO | Proxy rejects `artifact.update` |
| Delete artifact | NO | Proxy rejects `artifact.delete` |
| Promote lifecycle | NO | Proxy rejects `artifact.promote` |
| Set lifecycle_status | NO | Not included in save payload |
| Set execution_status | NO | Not included in save payload |
| Set parent_artifact_id | NO (v1) | Rejected by proxy. Planned for v2. |

Demo artifacts are created at default state: `lifecycle_status = null`, `execution_status = null`, `priority = 3`.

## 17. Security Considerations

| Concern | Mitigation |
|---------|------------|
| Cross-workspace access | Proxy forces workspace_id — cannot be overridden |
| Production data exposure | ACL restricts `qwrk-gw-demo` to demo workspace only |
| Spam / abuse | Rate limiting (50/min global, 10/min per-IP) + nightly cleanup |
| Payload injection | Size limits + tag stripping + workspace injection |
| Internal metadata exposure | Response shaping strips workspace_id, owner_user_id, semantic_type_id |
| Gateway contract bypass | Proxy forwards to Gateway — all standard validation applies |

---

## CHANGELOG

### v1.2 — 2026-03-15
**What changed:** Two v1 scope constraints aligned with runtime behavior
**Why:** Simplify v1 proxy — parent validation deferred to v2, list requires type
**Scope:**
1. `parent_artifact_id` NOT supported in v1 — rejected with `PARENT_NOT_SUPPORTED` error. Planned for v2 with PostgREST validation.
2. `artifact.list` requires `artifact_type` in v1 (underlying sub-workflow constraint). Friendly error on omission.
3. Lifecycle Restrictions table updated: parent_artifact_id = NO (v1)
**How to validate:** Send save with parent_artifact_id → rejected. Send list without artifact_type → rejected.

### v1.1 — 2026-03-15
**What changed:** Three refinements per Joel review
**Why:** Tighten edges before proxy implementation
**Scope:**
1. Size limits: reject oversized title/summary instead of truncating (new `FIELD_TOO_LONG` error code)
2. List cap: explicit max 20 governance rule on `artifact.list` (was implicit in translation only)
3. Parent validation: must call Gateway directly, not through proxy (prevents recursive loops)
**How to validate:** Each change is a single enforcement point in the proxy Code node

### v1 — 2026-03-15
**What changed:** Initial governance document for Explore Qwrk Demo
**Why:** Establish enforceable rules before building the demo proxy workflow
**Scope:** All demo proxy enforcement rules, payload translation, security constraints
**How to validate:** Each rule maps to a proxy node; verify during end-to-end testing
