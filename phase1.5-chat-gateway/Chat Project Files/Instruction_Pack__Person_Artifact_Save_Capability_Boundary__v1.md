# Instruction Pack — Person Artifact Save Capability Boundary (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-28
**origin:** T150 — Person Artifact Type, Branches 1-3 verified complete. Defines current capability boundary for person save.

---

## 1. Purpose

This pack defines the **current capability boundary** for the `person` artifact type as of 2026-03-28.

This is NOT a full system definition for person artifacts. Retrieval behavior, assistant integration, rolling person memory, and lifecycle management are **not implemented** and are explicitly excluded from this pack's scope.

This pack exists as a **constraint and accuracy guardrail** — preventing Q from over-claiming capabilities that do not yet exist while enabling correct use of what is implemented and verified.

---

## 2. What Is Implemented Now (Verified Only)

### 2A. Save Operation

`artifact.save` for `artifact_type: "person"` is **functional end-to-end**.

**Source:** `NQxb_Artifact_Save_v1 (46).json` — Switch_Type_For_Insert (case 9) → DB_Insert_Person_Extension → Merge_Context_For_Response → Return_Response. Verified via workflow JSON connection map.

**Evidence:** 17 person artifacts exist in Prime workspace. 14 have populated extension rows. MCP SQL query: `SELECT COUNT(*) FROM qxb_artifact WHERE artifact_type = 'person' AND workspace_id = 'be0d3a48-...' AND deleted_at IS NULL;`

### 2B. Required Fields — Spine

**Source:** `LIVE_DDL__Kernel_v1__2026-01-04.sql` (qxb_artifact table) + `NQxb_Artifact_Save_v1 (46).json` → Validate_Request node

| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | **YES** | Must be `"artifact.save"` |
| `gw_workspace_id` | **YES** | Valid workspace UUID |
| `artifact_type` | **YES** | Must be `"person"` |
| `title` | **YES** | Non-empty string |
| `semantic_type_id` | **YES** | Registry key string (e.g., `"execution-core"`). Person is a top-level type — semantic_type_id is mandatory. Gateway resolves key → UUID internally. |
| `tags` | Recommended | Array of lowercase strings (2-4) |
| `priority` | Optional | Integer 1-5 (default 3) |
| `artifact_id` | **FORBIDDEN** | Server generates via `gen_random_uuid()` — never include |

### 2C. Required Fields — Extension

**Source:** `LIVE_DDL__Kernel_v1__2026-01-04.sql` lines 621-657 (CREATE TABLE qxb_artifact_person) + `NQxb_Artifact_Save_v1 (46).json` → Validate_Request node (person validation block) + DB_Insert_Person_Extension node (25 field mappings)

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
| `extension.key_facts` | jsonb | Must be array or NULL (`jsonb_typeof = 'array'`) |
| `extension.what_they_care_about` | jsonb | Must be array or NULL (`jsonb_typeof = 'array'`) |
| `extension.preferences` | jsonb | Must be array or NULL (`jsonb_typeof = 'array'`) |

**System-managed (never in payload):** `artifact_id`, `created_at`, `updated_at`

### 2D. Validation Rules

**Source:** `NQxb_Artifact_Save_v1 (46).json` → Validate_Request node, code block: `artifact_type === 'person'`

**Hard validation (blocks save):**
- `extension.full_name` — required, non-empty string
- `extension.preferred_name` — required, non-empty string
- `extension.relationship_type` — required, string
- `extension.key_facts` — must be array if provided (not string, not object)
- `extension.what_they_care_about` — must be array if provided
- `extension.preferences` — must be array if provided
- `semantic_type_id` — required for person (top-level type enforcement in Assert_Semantic_UUID node: `TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart', 'person']`)

**Soft validation (warning only — does not block save):**
- Contact fields: if NONE of `personal_email`, `work_email`, `mobile_phone`, `work_phone`, `home_phone` are provided → warning: `"Person has no contact information; follow-up tracking may be limited"`

### 2E. Minimal Valid Payload

Constructed from DDL NOT NULL constraints + Gateway validation hard rules + semantic_type top-level enforcement. This payload will succeed but trigger a soft warning (no contact info).

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
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

Constructed from all 25 mapped fields in DB_Insert_Person_Extension node + DDL column types + JSONB CHECK constraints. No soft warnings — contact fields present.

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
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

Based on verified implementation state (T150 branch review + Gateway source inspection).

### 3A. Gateway Operations Blocked

**Source:** `NQxb_Gateway_v2.json` → NQxb_Gateway_v2__Gatekeeper node — TYPE_ALLOWLIST definition.

`person` is **not present** in the Gateway TYPE_ALLOWLIST. The allowlist (exact, as extracted):

```
project, journal, restart, snapshot, instruction_pack, branch, limb, leaf, twig
```

TYPE_ALLOWLIST is enforced on these actions (returns `ARTIFACT_TYPE_NOT_ALLOWED`):

| Action | Enforced? | Person Status |
|--------|-----------|---------------|
| `artifact.save` | **Not enforced** — save bypasses Gatekeeper, uses Save sub-workflow Type Registry | ✅ Works |
| `artifact.query` | **Enforced** at Gatekeeper code offset ~4230 | ❌ Blocked |
| `artifact.list` | **Enforced** at Gatekeeper code offset ~4840 | ❌ Blocked |
| `artifact.update` | **Enforced** at Gatekeeper code offset ~5544 | ❌ Blocked |
| `artifact.promote` | N/A | Person has no lifecycle_stage |
| `artifact.delete` | Not enforced | Likely works (unverified) |

### 3B. Capabilities NOT Implemented

**Source:** T150 branch review — project `843b6f36`, MCP SQL query against qxb_artifact. Branches 4, 5, 6 have 29 leaves total, all `execution_status: null`, all tagged `not_started`.

| Capability | T150 Branch | Leaf Count | Status |
|------------|-------------|------------|--------|
| Retrieval trigger detection | Branch 4 (16 leaves) | 0/16 complete | **Not started** |
| Person lookup & name matching | Branch 4 | 0/16 complete | **Not started** |
| Context assembly & prioritization | Branch 4 | 0/16 complete | **Not started** |
| Communication shaping | Branch 4 | 0/16 complete | **Not started** |
| Rolling person memory (read/write) | Branch 4 | 0/16 complete | **Not started** |
| Messaging auto-resolution | Branch 4 | 0/16 complete | **Not started** |
| Testing & certification | Branch 5 (8 leaves) | 0/8 complete | **Not started** |
| Documentation & operator guide | Branch 6 (5 leaves) | 0/5 complete | **Not started** |

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
- **Spine title** should match `full_name` unless Joel specifies otherwise.

---

## 5. Operational Posture for Q

### Q MAY:

- Construct valid `artifact.save` payloads for person artifacts
- Map structured profile input into schema-compliant payloads using the mapping rule in §4
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

## 6. Open Implementation Gaps (Verified)

### 6A. Gateway TYPE_ALLOWLIST — Confirmed Gap

**Source:** `NQxb_Gateway_v2.json` → NQxb_Gateway_v2__Gatekeeper node — TYPE_ALLOWLIST Set definition.

**Gap:** `"person"` is not in the TYPE_ALLOWLIST.

**Impact:** `artifact.query`, `artifact.list`, and `artifact.update` return `ARTIFACT_TYPE_NOT_ALLOWED` for person artifacts.

**Fix required:** Add `"person"` to the `TYPE_ALLOWLIST` Set in `NQxb_Gateway_v2__Gatekeeper`. This is a one-line change.

**Status:** Not yet deployed. Tracked under T150 Branch 4+.

### 6B. communication_style Field Mapping — Confirmed Bug

**Source:** `NQxb_Artifact_Save_v1 (46).json` → DB_Insert_Person_Extension node, field index 21.

**Bug:** The n8n expression for `communication_style` contains a malformed double-close (`}}`) with orphaned ternary text. May write literal string to a jsonb column when the field is omitted from payload.

**Impact:** Low — only affects saves where `communication_style` is omitted. Workaround: always include `communication_style` explicitly (as jsonb or null) if sending JSONB fields.

### 6C. Orphaned Extension Rows — Observed

**Source:** MCP SQL query — 17 spine rows, 14 extension rows (3 missing).

**Impact:** Low — pre-deployment artifacts or failed inserts. Does not affect new saves.

---

## 7. Accuracy Rule

- If any input data conflicts with the verified contract defined in this pack → **contract wins**
- If field mapping is uncertain or ambiguous → **surface uncertainty to the user, do not guess**
- If a user requests a capability listed in §3 (not implemented) → **state it is not yet available, cite this pack**
- This pack is authoritative for person save boundary. It does not override Payload Discipline or QSB Payload Format for rendering rules — those packs govern how payloads are rendered and delivered.

---

## Source References

| Source | Location | What It Provides |
|--------|----------|-----------------|
| Live DDL | `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` lines 621-657 | Table schema, NOT NULL constraints, CHECK constraints, indexes |
| Save v46 — Validate_Request | `workflows/NQxb_Artifact_Save_v1 (46).json` → node `Validate_Request` | Validation rules (hard + soft), person-specific block |
| Save v46 — DB_Insert_Person_Extension | Same file → node `DB_Insert_Person_Extension` | 25-field insert mapping, defaults, null handling |
| Save v46 — Switch_Type_For_Insert | Same file → node `Switch_Type_For_Insert` | Case 9 routes to person extension insert |
| Save v46 — Assert_Semantic_UUID | Same file → node `Assert_Semantic_UUID` | TOP_LEVEL_TYPES includes person |
| Gateway v2 — Gatekeeper | `workflows/NQxb_Gateway_v2.json` → node `NQxb_Gateway_v2__Gatekeeper` | TYPE_ALLOWLIST (person absent), enforcement points |
| T150 branch review | MCP SQL: qxb_artifact WHERE parent = `843b6f36` | Branch completion state, leaf execution_status |
| Existing data | MCP SQL: qxb_artifact + qxb_artifact_person join | 17 artifacts, 14 with extension |

---

## CHANGELOG

### v1 — 2026-03-28

Initial creation. Defines person artifact save capability boundary based on verified sources: Live DDL v2.10, Save v46 workflow, Gateway v2 Gatekeeper, T150 branch review, and MCP data queries. Documents what is implemented (save), what is blocked (query/list/update), and what is not started (retrieval, behavior, memory). Includes mapping rule, operational posture, and verified gap inventory.
