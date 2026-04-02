# Instruction Pack — Person Artifact Save Capability Boundary (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-29
**origin:** T150 — Person Artifact Type. Defines current capability boundary for person save.

---

## 1. Purpose

This pack defines the **current capability boundary** for the `person` artifact type as of 2026-03-29.

This is NOT a full system definition for person artifacts. Retrieval behavior, assistant integration, rolling person memory, and lifecycle management are **not implemented** and are explicitly excluded from this pack's scope.

This pack exists as a **constraint and accuracy guardrail** — preventing Q from over-claiming capabilities that do not yet exist while enabling correct use of what is implemented and verified.

---

## 2. What Is Implemented Now (Verified Only)

### 2A. Save Operation

`artifact.save` for `artifact_type: "person"` is **functional end-to-end**.

### 2B. Required Fields — Spine

| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | **YES** | Must be `"artifact.save"` |
| `gw_workspace_id` | **YES** | `963973e0-a98c-4044-b421-71e7348eaeaf` |
| `artifact_type` | **YES** | Must be `"person"` |
| `title` | **YES** | Non-empty string |
| `semantic_type_id` | **YES** | Registry key string (e.g., `"execution-core"`). Person is a top-level type — semantic_type_id is mandatory. |
| `tags` | Recommended | Array of lowercase strings (2-4) |
| `priority` | Optional | Integer 1-5 (default 3) |
| `artifact_id` | **FORBIDDEN** | Server generates — never include |

### 2C. Required Fields — Extension

**Hard required (validation blocks save if missing):**

| Field | Type | Constraint |
|-------|------|------------|
| `extension.full_name` | text | NOT NULL — non-empty string |
| `extension.preferred_name` | text | NOT NULL — non-empty string |
| `extension.relationship_type` | text | NOT NULL — string |

**Defaulted (NOT NULL in DB, but have defaults):**

| Field | Type | Default |
|-------|------|---------|
| `extension.status` | text | `"active"` |
| `extension.do_not_contact` | boolean | `false` |

**Optional — text fields:**

| Field | Type | Notes |
|-------|------|-------|
| `extension.pronouns` | text | |
| `extension.personal_email` | text | Contact group |
| `extension.work_email` | text | Contact group |
| `extension.mobile_phone` | text | Contact group |
| `extension.work_phone` | text | Contact group |
| `extension.home_phone` | text | Contact group |
| `extension.preferred_contact_method` | text | |
| `extension.preferred_contact_channel` | text | |
| `extension.timezone` | text | |
| `extension.company` | text | |
| `extension.title` | text | Job title |
| `extension.department` | text | |
| `extension.importance_level` | text | |
| `extension.interaction_frequency` | text | |

**Optional — JSONB fields:**

| Field | Type | DB CHECK Constraint |
|-------|------|---------------------|
| `extension.address` | jsonb | None |
| `extension.communication_style` | jsonb | None |
| `extension.key_facts` | jsonb | Must be array or NULL |
| `extension.what_they_care_about` | jsonb | Must be array or NULL |
| `extension.preferences` | jsonb | Must be array or NULL |

**System-managed (never in payload):** `artifact_id`, `created_at`, `updated_at`

### 2D. Validation Rules

**Hard validation (blocks save):**
- `extension.full_name` — required, non-empty string
- `extension.preferred_name` — required, non-empty string
- `extension.relationship_type` — required, string
- `extension.key_facts` — must be array if provided (not string, not object)
- `extension.what_they_care_about` — must be array if provided
- `extension.preferences` — must be array if provided
- `semantic_type_id` — required for person (top-level type)

**Soft validation (warning only — does not block save):**
- Contact fields: if NONE of `personal_email`, `work_email`, `mobile_phone`, `work_phone`, `home_phone` are provided → warning about limited follow-up tracking

### 2E. Minimal Valid Payload

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "person",
  "title": "Jane Doe",
  "semantic_type_id": "execution-core",
  "tags": ["people", "contact"],
  "extension": {
    "full_name": "Jane Doe",
    "preferred_name": "Jane",
    "relationship_type": "contact"
  }
}
```

### 2F. Full Example Payload

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "person",
  "title": "Marcus Chen",
  "semantic_type_id": "execution-core",
  "tags": ["people", "work", "engineering"],
  "priority": 3,
  "extension": {
    "full_name": "Marcus Chen",
    "preferred_name": "Marcus",
    "relationship_type": "colleague",
    "status": "active",
    "pronouns": "he/him",
    "work_email": "marcus.chen@example.com",
    "mobile_phone": "555-867-5309",
    "preferred_contact_method": "email",
    "preferred_contact_channel": "work",
    "timezone": "America/Chicago",
    "company": "Acme Corp",
    "title": "Staff Engineer",
    "department": "Platform",
    "importance_level": "high",
    "interaction_frequency": "weekly",
    "do_not_contact": false,
    "key_facts": ["Led the API migration project", "Reports to VP of Eng"],
    "what_they_care_about": ["system reliability", "developer experience"],
    "preferences": ["prefers async over meetings", "morning availability best"]
  }
}
```

---

## 3. What Is NOT Implemented / BLOCKED

### 3A. Gateway Operations Blocked

`person` is **not present** in the Gateway TYPE_ALLOWLIST. This means:

| Action | Person Status |
|--------|---------------|
| `artifact.save` | Works (save bypasses Gatekeeper allowlist) |
| `artifact.query` | Blocked (`ARTIFACT_TYPE_NOT_ALLOWED`) |
| `artifact.list` | Blocked (`ARTIFACT_TYPE_NOT_ALLOWED`) |
| `artifact.update` | Blocked (`ARTIFACT_TYPE_NOT_ALLOWED`) |
| `artifact.promote` | N/A (person has no lifecycle_stage) |

### 3B. Capabilities NOT Implemented

| Capability | Status |
|------------|--------|
| Retrieval trigger detection | **Not started** |
| Person lookup & name matching | **Not started** |
| Context assembly & prioritization | **Not started** |
| Communication shaping | **Not started** |
| Rolling person memory (read/write) | **Not started** |
| Messaging auto-resolution | **Not started** |

**Q MUST NOT claim or imply any of these capabilities exist.**

---

## 4. Mapping Rule (STRICT)

When converting captured profile information into a person save payload, Q MUST:

### 4A. Field Mapping

Map all input data into canonical schema fields using exact column names from `qxb_artifact_person`. No aliases permitted.

| Input Concept | Maps To | Type |
|---------------|---------|------|
| Full legal/display name | `extension.full_name` | text |
| Nickname / short name | `extension.preferred_name` | text |
| Relationship category | `extension.relationship_type` | text |
| Active/inactive | `extension.status` | text |
| Pronouns | `extension.pronouns` | text |
| Personal email | `extension.personal_email` | text |
| Work email | `extension.work_email` | text |
| Mobile phone | `extension.mobile_phone` | text |
| Work phone | `extension.work_phone` | text |
| Home phone | `extension.home_phone` | text |
| How to reach them | `extension.preferred_contact_method` | text |
| Which channel | `extension.preferred_contact_channel` | text |
| Time zone | `extension.timezone` | text |
| Employer / org | `extension.company` | text |
| Job title / role | `extension.title` | text |
| Department / team | `extension.department` | text |
| How important (text) | `extension.importance_level` | text |
| How often to contact | `extension.interaction_frequency` | text |
| Do not contact flag | `extension.do_not_contact` | boolean |
| Physical address | `extension.address` | jsonb |
| Communication personality | `extension.communication_style` | jsonb |
| Things they value | `extension.what_they_care_about` | jsonb array |
| Notable facts | `extension.key_facts` | jsonb array |
| Working preferences | `extension.preferences` | jsonb array |

### 4B. Constraints

- **No invented fields.** If a field name is not in the table above, it cannot appear in `extension`.
- **No silent dropping.** If input contains meaningful data that does not map to any schema field, Q MUST surface it to the user: `"The following data does not map to the person schema: [list]. Should I include it in key_facts or discard it?"`
- **No aliases.** Use exact column names. `email` is not valid — use `personal_email` or `work_email`.
- **JSONB array fields** (`key_facts`, `what_they_care_about`, `preferences`) MUST be arrays of strings if provided. Not objects, not nested arrays.
- **Spine title** should match `full_name` unless Akara specifies otherwise.

---

## 5. Operational Posture for Q

### Q MAY:

- Construct valid `artifact.save` payloads for person artifacts
- Map structured profile input into schema-compliant payloads using the mapping rule in $4
- Explain the current save contract and its required/optional fields
- Include `for-q` tag on person artifacts when explicitly requested
- Warn when contact fields are missing (matches Gateway soft validation)

### Q MUST NOT:

- Claim that person artifacts support query, list, or update via Gateway
- Claim that person data is used for retrieval, context assembly, or communication shaping
- Claim that rolling person memory exists or is functional
- Treat person artifacts as an active retrieval substrate (they are storage-only in current state)
- Claim full lifecycle support for person artifacts
- Emit query/list/update payloads with `artifact_type: "person"` (will return `ARTIFACT_TYPE_NOT_ALLOWED`)
- Invent extension fields not present in the schema
- Silently drop unmappable data without surfacing it

---

## 6. Accuracy Rule

- If any input data conflicts with the verified contract defined in this pack → **contract wins**
- If field mapping is uncertain or ambiguous → **surface uncertainty to the user, do not guess**
- If a user requests a capability listed in $3 (not implemented) → **state it is not yet available, cite this pack**
- This pack is authoritative for person save boundary. It does not override Payload Discipline or QSB Payload Format for rendering rules — those packs govern how payloads are rendered and delivered.

---

## CHANGELOG

### v1 — 2026-03-29

Initial creation (Akara workspace adaptation). Defines person artifact save capability boundary. Documents what is implemented (save), what is blocked (query/list/update), and what is not started (retrieval, behavior, memory). Includes mapping rule, operational posture, and gap inventory. Adapted from Prime workspace pack with workspace_id `963973e0-a98c-4044-b421-71e7348eaeaf`.
