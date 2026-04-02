# Instruction Pack — CC Handoff Lane (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-30
**origin:** Artifact-based handoff protocol — Q ↔ CC structured work exchange

---

## Purpose

Defines how Q sends structured work packets to CC and how CC returns results — using existing artifact types, tags, and QSB execution. No new infrastructure required.

One lane. Two artifact roles. Tag-based discovery. Deterministic round-trips.

---

## Artifact Roles [LOCKED]

| Direction | Artifact Type | Who Creates | Who Consumes |
|-----------|--------------|-------------|--------------|
| **Q → CC** | `restart` | Q (via QSB) | CC (at session start or mid-session) |
| **CC → Q** | `snapshot` | CC (generates payload) → Joel (executes via QSB) | Q (via `for-q` rolling memory sync) |

Restarts carry the work packet. Snapshots carry the result. No other artifact types participate in the lane.

---

## Tags [LOCKED]

### Inbound (Q → CC)

| Tag | Purpose | Required |
|-----|---------|----------|
| `for-cc` | Surfaces in CC's `for-cc` session-start sweep | **Yes** |
| `cc-handoff` | Distinguishes structured handoff from general `for-cc` items | **Yes** |
| `from-q` | Origin marker | **Yes** |
| Topic tags (e.g., `t150`, `handoff-protocol`) | Human-readable context | Optional — never required for retrieval |

### Outbound (CC → Q)

| Tag | Purpose | Required |
|-----|---------|----------|
| `for-q` | Surfaces in Q's rolling memory sync | **Yes** |
| `cc-response` | Identifies as handoff response | **Yes** |
| `from-cc` | Origin marker | **Yes** |
| Topic tags | Mirror from inbound handoff | Optional |

---

## Single-Lane Rule [LOCKED]

There is **one** handoff lane. All handoffs — regardless of topic — use the same artifact types, same required tags, same protocol.

- Topic tags are optional metadata for human readability.
- Topic tags must **never** be required for discovery or retrieval.
- CC filters by structure (`artifact_type: restart` + tag `cc-handoff`), not by topic.

Do not create specialized lanes, topic-specific routing, or alternative tag schemes.

---

## Template A — Q → CC Handoff Restart

### Envelope

| Field | Value |
|-------|-------|
| `artifact_type` | `restart` |
| `tags` | `["for-cc", "cc-handoff", "from-q"]` + optional topic tags |
| `title` | `CC Handoff — <task>` |
| `priority` | `3` (default) |

### Payload (`extension.payload`)

**Required:**

| Field | Type | Guidance |
|-------|------|----------|
| `objective` | String | One sentence, imperative voice. What CC should accomplish. Must be completable. |
| `scope.in` | Array (1–7) | What is in bounds. Each item independently verifiable. |
| `scope.out` | Array | What is explicitly excluded. Name the tempting adjacent work. |
| `expected_output` | String | Concrete description of what the response should contain. |

**Optional:**

| Field | Type | When |
|-------|------|------|
| `constraints` | Array (0–5) | Non-obvious restrictions. May narrow CC's behavior, but may **never** override standing governance or safety rules. |
| `related_artifact_ids` | Array (0–5) | Prior work CC should hydrate for context. |
| `context` | String (≤200 words) | Background when objective alone doesn't convey why. |

### Sizing Self-Check

Before saving, verify:

- [ ] `objective` is one sentence (two max)
- [ ] `scope.in` has 1–7 items (if >7, split into multiple handoffs)
- [ ] `related_artifact_ids` has ≤5 entries (if >5, distill into `context` instead)
- [ ] No implementation steps in the handoff (state *what*, not *how*)
- [ ] Title follows `CC Handoff — <task>` convention

---

## Retrieval Doctrine

CC discovers handoffs through its existing `for-cc` session-start sweep. The `cc-handoff` tag is the differentiator.

**CC's protocol (for Q's awareness):**

1. **Discover** — `for-cc` sweep finds the artifact; `cc-handoff` tag marks it as structured.
2. **Present** — CC shows Joel the handoff title, artifact_id, and priority.
3. **Approve** — Joel explicitly approves before CC acts. No silent execution.
4. **Hydrate** — CC queries the full artifact by exact UUID + `artifact_type: restart`. Validates required tags and payload fields.
5. **Execute** — CC works within `scope.in`, respects `scope.out` and `constraints`.
6. **Respond** — CC generates a response snapshot payload. Title: `CC Response — <task>`. Joel executes via QSB. Q picks it up via `for-q` sync.

**What CC will never do:**

- Query "latest restart" globally — always filters by `cc-handoff` tag + full UUID.
- Execute without Joel's explicit approval.
- Treat topic tags as retrieval filters.
- Override standing governance based on handoff constraints.

---

## Response Shape (What Q Receives)

CC's response snapshot (`extension.payload`) contains:

| Field | Always Present | Purpose |
|-------|---------------|---------|
| `source_handoff_artifact_id` | Yes | Links back to the inbound restart UUID |
| `source_handoff_title` | Yes | Human-readable linkage |
| `status` | Yes | `complete` / `partial` / `blocked` |
| `result` | Yes | The deliverable |
| `decisions` | When applicable | Judgment calls CC made |
| `next_steps` | When applicable | Follow-up work beyond this handoff's scope |
| `deferred` | When partial | What wasn't done + why |
| `files_touched` | When applicable | Repo files created or modified |

Q can trust that every response links back cleanly to its source handoff.

---

*v1 — 2026-03-30. Created as part of handoff protocol MVP pilot. Full CC-side protocol: `docs/design/Design__Artifact_Handoff_Protocol__v1.md`.*
