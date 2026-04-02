# Instruction Pack: Payload Discipline v4

## Payload Preflight Checklist [LOCKED]

Before emitting any Gateway payload, Q MUST complete this preflight:

1. **Identify the governing action** — Which `gw_action` is this? (e.g., `artifact.save`, `artifact.update`, `messaging.send_email`)
2. **Look up the instruction pack** — Open `Instruction_Pack_Index.md`, find the pack matching this action's Trigger column
3. **Open and reference the pack** — Read the authoritative payload schema from the governing pack
4. **Verify required shape** — Confirm all required keys, extension rules, and constraints match
5. **Emit** — Only after steps 1-4 are satisfied

Skipping this checklist is a governance violation. If uncertain about any step, ask ONE question before emitting.

---

## Artifact Selection

Before choosing an artifact type, consult this table:

| If you need to... | Use | Why |
|---|---|---|
| Capture a new idea or initiative | `project` (seed) | Ideas start as seeds |
| Reflect, think, or journal privately | `journal` | Owner-private, insert-only |
| Record a decision, state, or moment in time | `snapshot` | Immutable record |
| Continue work across sessions | `restart` | Session handoff artifact |
| Capture a side-spark or add-on idea quickly | `twig` | Lightweight, spine-only |

If the intent is ambiguous, ask Joel ONE question to clarify before selecting.

---

## Extension Field Requirements

Extension tables have strict column schemas. Only defined columns are persisted per type:

- **project:** `extension.lifecycle_stage` REQUIRED (seed/sapling/tree/archive). Also supports: `operational_state`, `state_reason`, `design_spine`.
- **journal:** `extension.entry_text` REQUIRED; `extension.payload` FORBIDDEN.
- **snapshot/restart:** `extension.payload` REQUIRED (object).
- **twig:** spine-only — no extension table, no extension required. Lightweight micro-initiative.

Unknown keys passed in `extension` are **silently dropped** — no error, no warning. Do not pass custom fields in `extension`.

To link artifacts, use `parent_artifact_id` (top-level spine field, not inside `extension`).

---

## Semantic Type Governance (T69)

- `semantic_type_id` is **REQUIRED** on save for top-level types: `project`, `snapshot`, `journal`, `restart`.
- `semantic_type_id` is **FORBIDDEN** for non-top-level types: `branch`, `leaf`, `limb`, `instruction_pack`, `twig`.
- Infer from context if unspecified. If ambiguous, ask ONE question.

**Registry values (9 active):** `execution-core`, `governance`, `infrastructure`, `platform`, `product`, `alignment`, `sales`, `marketing`, `exploratory`

---

## Content Field Governance (T140)

The `content` field on the artifact spine is a jsonb object supporting two update modes:

**Mutable types** (project, branch, leaf, limb, twig):
- `content` — deep merge (default) or explicit replace via `content_mode: "replace"`
- Can combine with tags and/or spine field updates in a single call

**Immutable types** (snapshot, journal, restart):
- `content_append` — append-only entries to `append_log` (system-managed array inside content)
- `content` merge/replace is BLOCKED for these types (`CONTENT_UPDATE_NOT_ALLOWED`)

**Rules:**
- `content` and `content_append` are mutually exclusive — never combine in one call
- `append_log` is a reserved namespace — never include it in `content` payloads
- Archived artifacts block ALL content operations (`ARCHIVE_FROZEN`)
- `append_log` max 100 entries per artifact (`APPEND_LIMIT_EXCEEDED`)

---

## Gateway Error Response Posture

When the Gateway returns an error, present the error code and message to Joel in plain language. Do not retry automatically. Do not guess the fix. Ask Joel what he wants to do.

---

## Seed Planting Protocol (Project Genesis)

Two valid paths for creating a seed. Choose based on intent clarity.

### Direct Seed (default when intent is clear)

When you know you want a seed, create the project directly — single payload, no journal required.

The seed registers the initiative. A companion journal can be added later if rich context is needed.

### Exploratory Capture (when thinking precedes commitment)

When capturing thinking that may or may not become a seed:

1. Save the journal FIRST (captures thinking/rationale)
2. If the thinking crystallizes into a seed: save the project with `parent_artifact_id` set to the journal's `artifact_id`

This is the correct path when you're journaling through an idea and it evolves into something worth tracking as a project.

**Technical constraint:** The Gateway does not support retroactive `parent_artifact_id` assignment via update (pending T118). If you know at journal-creation time that a seed will follow, the journal → seed order preserves the link. If not, the seed can exist unlinked — the journal is still discoverable by tags and title.

**Link recovery:** If a seed is created without a companion journal and later requires contextual linkage, association may be achieved via tags, title alignment, or a linking snapshot.

---

## Fast-Capture Carveout [LOCKED]

**Scope:** `journal` and `twig` saves in the home workspace only.

**Effect:** These two types may use pre-validated minimal patterns (see Quick Reference) without full pack lookup. Preflight steps 2-3 are waived; steps 1, 4, and 5 still apply.

**Constraints (non-negotiable):**
- `twig`: `parent_artifact_id` REQUIRED — must come from Mother Tree Structural Map or be confirmed by Joel. No orphaned twigs.
- `journal`: `semantic_type_id` + `extension.entry_text` still required.
- All other governance applies: cross-workspace write gate, sequential discipline, tagging rules, one-payload-per-response.

**Does NOT apply to:** update, promote, query, list, messaging, snapshot, project, restart, or any non-save action.

Strict mode (full preflight) remains the locked default for everything outside this carveout.

---

*CHANGELOG: v5.0 (2026-03-26): Added Content Field Governance (T140) — content merge/replace for mutable types, content_append for immutable types, append_log protection, archive freeze. Previous: `Archive/Instruction_Pack__Payload_Discipline__v4__2026-03-26.md`. v4.0 (2026-03-25): Added Fast-Capture Carveout [LOCKED] — narrow exception for journal + twig saves, preserving strict default. Previous: `Archive/Instruction_Pack__Payload_Discipline__v3__2026-03-25.md`. v3.0 (2026-03-25): Architecture refactor — Payload Discipline is now the single operational authority for payload construction. Added: Artifact Selection decision table (new), Extension Field Requirements (extracted from root SI v48), Semantic Type Governance with full registry (extracted from root SI v48), Gateway Error Response Posture (new). Previous: `Archive/Instruction_Pack__Payload_Discipline__v2__2026-03-25.md`. v2.0 (2026-03-12): Added Payload Preflight Checklist [LOCKED]. v1.0 (2026-03-11): Initial.*
