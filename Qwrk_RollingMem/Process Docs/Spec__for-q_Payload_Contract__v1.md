# Spec: for-q Payload Contract

**Version:** 1.0
**Date:** 2026-02-04
**Status:** DRAFT
**Parent:** MVP_Plan__for-q_Rolling_Memory_Sync__v1.md

---

## Purpose

Define the **required payload structure** for any snapshot artifact to be eligible for `for-q` tagging. This contract ensures extraction never requires inference.

---

## Eligibility Rule

A snapshot MAY be tagged `for-q` **only if** its payload contains all required fields defined below.

Tagging a snapshot `for-q` without required fields is a **governance violation** — the extraction process will fail loudly.

---

## Payload Contract

### Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `for_q_why` | string | One sentence explaining why Q must know this. Max 100 words. | "This locks the artifact.save response envelope format so Q does not hallucinate fields." |
| `for_q_impact` | string | Actionable behavioral constraint. Must start with "Q MUST", "Q MUST NOT", or "Q SHOULD". | "Q MUST NOT suggest adding fields to the save response envelope beyond what is documented here." |
| `for_q_scope` | string | Where/when this applies. One of: `global`, `gateway`, `session`, or a specific named scope. | "gateway" |

### Optional Fields

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| `for_q_sunset` | string or null | Expiry condition. When does this constraint end? | `null` (permanent) |
| `for_q_priority` | string | Relative importance: `critical`, `high`, `normal` | `normal` |

---

## Field Specifications

### `for_q_why` (Required)

**Purpose:** Explains the reason Q needs this in memory.

**Rules:**
- Must be a complete sentence
- Must answer: "What goes wrong if Q doesn't know this?"
- Max 100 words
- No jargon without context

**Valid:**
- "This locks the KGB-verified save workflow so Q does not suggest untested modifications."
- "This establishes the artifact type registry so Q knows which types are valid."

**Invalid:**
- "Important governance decision" (too vague)
- "See related snapshot" (no inference allowed)
- "" (empty)

---

### `for_q_impact` (Required)

**Purpose:** The specific behavioral constraint Q must follow.

**Rules:**
- Must start with one of:
  - `Q MUST ...` — required action
  - `Q MUST NOT ...` — prohibited action
  - `Q SHOULD ...` — recommended action (soft constraint)
- Must be actionable and testable
- One constraint per field (use array if multiple)

**Valid:**
- "Q MUST NOT modify the artifact.save response envelope structure."
- "Q MUST reference the DDL before generating any SQL."
- "Q SHOULD recommend snapshots for governance decisions."

**Invalid:**
- "Be careful with saves" (not actionable)
- "The save workflow is important" (not a constraint)
- "Don't break things" (not testable)

**Multiple Constraints:**
If a snapshot has multiple behavioral impacts, use an array:
```json
{
  "for_q_impact": [
    "Q MUST validate workspace_id before any artifact operation.",
    "Q MUST NOT skip RLS policy checks."
  ]
}
```

---

### `for_q_scope` (Required)

**Purpose:** Defines where/when the constraint applies.

**Allowed Values:**

| Value | Meaning |
|-------|---------|
| `global` | Applies to all Q behavior, always |
| `gateway` | Applies only to Gateway operations (save, query, list, etc.) |
| `session` | Applies only to session management (start, end, handoff) |
| `schema` | Applies to database/SQL operations |
| `[specific]` | Named scope (e.g., "artifact.save", "journal-mode", "promotion-workflow") |

**Rules:**
- Use the narrowest applicable scope
- `global` should be rare — most constraints are contextual
- Specific scopes use kebab-case or dot-notation

---

### `for_q_sunset` (Optional)

**Purpose:** When does this constraint expire?

**Rules:**
- If omitted or `null`, constraint is permanent until explicitly revoked
- If specified, must describe a clear condition

**Valid:**
- `null` — permanent
- `"Until Phase 3 vector implementation"` — condition-based
- `"Until 2026-Q2"` — time-based
- `"Superseded by snapshot [uuid]"` — replacement-based

---

### `for_q_priority` (Optional)

**Purpose:** Helps curator decide what goes in Section A vs Section B.

**Allowed Values:**

| Value | Meaning | Section A Eligible |
|-------|---------|-------------------|
| `critical` | Violating this breaks core behavior | Yes (preferred) |
| `high` | Important but recoverable if missed | Yes (space permitting) |
| `normal` | Standard governance, good to know | Section B only |

**Default:** `normal`

---

## Example: Complete for-q Eligible Payload

```json
{
  "title": "KGB Proof: Gateway v1 artifact.save Response Envelope",
  "created_at": "2026-01-25T14:30:00Z",
  "payload": {
    "description": "Documents the verified response envelope structure for artifact.save...",
    "kgb_verified": true,
    "verified_date": "2026-01-25",

    "for_q_why": "This locks the KGB-verified save response envelope so Q does not hallucinate additional fields or suggest modifications to a working contract.",
    "for_q_impact": "Q MUST NOT suggest adding, removing, or renaming fields in the artifact.save response envelope.",
    "for_q_scope": "gateway",
    "for_q_sunset": null,
    "for_q_priority": "critical"
  }
}
```

---

## Extraction Mapping

When extracting for the rolling memory file:

| Payload Field | Extracts To |
|---------------|-------------|
| `artifact_id` | `artifact_id` (from spine) |
| `artifact_type` | `artifact_type` (from spine) |
| `title` | `title` (from spine) |
| `created_at` | `created_at` (from spine) |
| `payload.for_q_why` | `why_q_needs_this` |
| `payload.for_q_impact` | `behavioral_impact` |
| `payload.for_q_scope` | `scope` |
| `payload.for_q_sunset` | `sunset` |

---

## Validation Checklist

Before tagging any artifact `for-q`, verify:

- [ ] `payload.for_q_why` exists and is non-empty
- [ ] `payload.for_q_impact` exists and starts with "Q MUST" / "Q MUST NOT" / "Q SHOULD"
- [ ] `payload.for_q_scope` exists and is a valid scope value
- [ ] Content is explicit — no inference required to understand
- [ ] Constraint is actionable and testable

**If any check fails:** Do not tag. Fix the payload first.

---

## Migration Note

Existing snapshots that should be tagged `for-q` will need **payload updates** to add the required fields before tagging. This is intentional — it forces explicit articulation of why Q needs each piece of information.

---

## CHANGELOG

### v1 — 2026-02-04
- Initial spec
- Required fields: `for_q_why`, `for_q_impact`, `for_q_scope`
- Optional fields: `for_q_sunset`, `for_q_priority`
- Extraction mapping defined
