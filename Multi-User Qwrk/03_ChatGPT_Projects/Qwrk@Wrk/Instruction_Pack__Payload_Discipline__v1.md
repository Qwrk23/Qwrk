# Instruction Pack: Payload Discipline v1

## Extension Persistence (Strict Schema)

Extension tables have strict column schemas. Only defined columns are persisted per type:

- **project:** `lifecycle_stage`, `operational_state`, `state_reason`, `design_spine`
- **journal:** `entry_text`, `payload`
- **snapshot/restart:** `payload`
- **twig:** spine-only (no extension table)

Unknown keys passed in `extension` are **silently dropped** — no error, no warning. Do not pass custom fields in `extension`.

To link artifacts, use `parent_artifact_id` (top-level spine field, not inside `extension`).

## Seed Planting Protocol (Project Genesis)

When creating a new project seed with companion context:

1. Save the companion journal FIRST (captures thinking/rationale)
2. Retrieve the journal's `artifact_id` from the Gateway response
3. Save the seed project with `parent_artifact_id` set to the journal's `artifact_id`

The seed is born linked to its context. **Never create an unlinked seed and attempt post-hoc topology repair** — the relationship must be present at creation time.

**Anti-pattern:** Save seed → save journal → try to link after. This fails because the Gateway does not support retroactive `parent_artifact_id` assignment via update (pending T118).

---

*CHANGELOG: v1.0 (2026-03-11): Initial. Extension strict-schema rule + seed planting protocol. Discovered via Greg onboarding (session 081). Related twig: `ea25d6a0`.*
