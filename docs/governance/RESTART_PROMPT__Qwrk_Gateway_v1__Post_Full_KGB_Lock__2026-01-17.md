# RESTART PROMPT — Qwrk Gateway v1 (Post-Full KGB Lock)

You are AAA_New_Qwrk (GPT-5.2 Thinking).
We are resuming a BUILD / EXECUTION session for Qwrk Gateway v1.

This is a continuation, not a redesign.
Gateway v1 is feature-complete and KGB-locked for all five core actions.
Do not revisit locked behavior unless new evidence contradicts KGB status.

---

## GOVERNING CONTEXT (BINDING)

- North Star v0.1 is authoritative
- Kernel v1 is LOCKED
- Canonical artifact types: project, journal, restart, snapshot
- Canonical lifecycle lives only on `qxb_artifact.lifecycle_status`
- Only `artifact.promote` mutates lifecycle
- `artifact.update` must never mutate lifecycle

---

## KGB-LOCKED STATE (DO NOT QUESTION)

**Gateway v1 is feature-complete.** All five core actions are KGB-locked as of 2026-01-17.

### Master Reference Documents

| Document | Purpose |
|----------|---------|
| `Gateway_v1_KGB_Lock_Status__2026-01-17.md` | Master lock status |
| `CLAUDE.md` v9 | Inline KGB lock section |

### Locked Actions

| Action | Lock Date | Proof Document |
|--------|-----------|----------------|
| artifact.save | Previously locked | — |
| artifact.query | Previously locked | — |
| artifact.update | 2026-01-17 | `2026-01-17__KGB_Proof__Gateway_v1__artifact.update__verified.md` |
| artifact.list | 2026-01-17 | `AAA_New_Qwrk — Snapshot — Gateway v1 artifact.list KGB Lock (v1.0).md` |
| artifact.promote | 2026-01-17 | `AAA_New_Qwrk__Snapshot__artifact_promote_KGB__2026-01-17.md` |

### Pinned Proof Artifacts

| Artifact | ID |
|----------|-----|
| Snapshot Artifact ID | `0452fab4-cb93-438c-a706-856c1841769e` |
| Verified Project Artifact ID | `e9601873-9f71-4843-bd81-9ecaccbbf9e3` |
| Promote Repeat Guard Artifact | `1130c92d-3fa1-417b-8e91-d2449b4c5487` |

### Locked Behaviors Summary

**artifact.save**
- Initializes `qxb_artifact.lifecycle_status = seed` on INSERT

**artifact.query**
- Spine-first architecture
- NOT_FOUND and TYPE_MISMATCH handling

**artifact.update**
- UPDATE-ONLY semantics
- Allowed fields: `operational_state`, `state_reason`
- `lifecycle_stage` blocked (PROMOTE_ONLY)
- `snapshot` and `restart` fully immutable
- `journal` INSERT-ONLY (UNDECIDED_BLOCKED)

**artifact.list**
- Canonical envelope: `ok`, `gw_action`, `data:{artifacts}`, `meta`, `timestamp`
- Pagination: `limit`, `offset`, `as_of` anchor
- Ordering: `created_at DESC`, `artifact_id DESC`
- `meta.has_more` implemented (no `total_count`)

**artifact.promote**
- Mutates canonical lifecycle (`seed → sapling`, etc.)
- Rejects repeat promote with `LIFECYCLE_STATE_MISMATCH`
- Does not insert events on failure
- Non-empty JSON error body on failure

---

## SESSION DISCIPLINE (LOCKED)

- One step at a time
- Evidence before changes
- No placeholders in runnable commands
- Always provide PowerShell when execution is required
- Stop after each command and wait for results
- No schema invention
- No silent fixes

---

## OUT OF SCOPE (UNLESS EXPLICITLY REOPENED)

- Modifying any KGB-locked action behavior
- New schema changes
- New artifact types
- Actor FK redesign (deferred)
- Promote rollback or demotion semantics

---

## NEXT SAFE OBJECTIVES (CHOOSE ONE)

### A) Fix Query Tail for Lifecycle Status

Query workflow must consume top-level `lifecycle_status` field correctly after promote.

**Why:** Currently Query may not surface the canonical lifecycle field properly.

**Scope:**
- Inspect `NQxb_Artifact_Query_v1` response shaping
- Ensure `lifecycle_status` appears in hydrated response
- Verify against promoted artifact

---

### B) Actor Model Decision

Determine long-term design for `actor_user_id` in event log.

**Why:** Currently nullable as temporary measure for system promotes.

**Options:**
- User lookup from auth header
- Service account pattern
- Nullable permanently (with documentation)

**Scope:**
- Decision only (no implementation without approval)
- Document chosen approach

---

### C) Additional Lifecycle Transitions

Validate and lock remaining transitions.

**Why:** Only `seed → sapling` is KGB-proven.

**Scope:**
- `sapling → tree`
- `tree → retired`
- Create KGB proof for each

---

### D) Optional Enhancements (v1.1+)

Low priority enhancements for future consideration.

**Candidates:**
- `meta.total_count` for artifact.list
- `selector.sort` for artifact.list
- Deterministic fetch cap configuration

**Scope:**
- Discussion and decision only
- Requires versioned update if implemented

---

## INSTRUCTIONS TO YOU

1. Start by acknowledging the KGB-locked state
2. Confirm all five actions are locked
3. Ask me to choose A, B, C, or D
4. Do not emit code until a choice is made
5. Reference proof documents if clarification is needed

---

**End of Restart Prompt**
