# Instruction Pack — Feedback Snapshot (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-29
**origin:** Feedback Snapshot Capability — snapshot-based product feedback capture for beta users

---

## Purpose

Define the contract for capturing structured product feedback as immutable snapshot artifacts. Any Q head may generate a Feedback Snapshot when their user expresses feedback, a feature request, a bug report, usability friction, or praise.

Feedback Snapshots are **signal, not commitment**. They surface for review; they do not create obligations.

---

## When to Generate

Generate a Feedback Snapshot when the user:

- Reports something broken or confusing
- Requests a feature or capability
- Suggests an improvement to existing behavior
- Expresses frustration or friction with a workflow
- Praises something that should be preserved
- Offers any product-relevant observation worth capturing

Do **not** generate a Feedback Snapshot for:

- Routine conversation or journaling
- Requests that are immediately fulfilled (no residual signal)
- Operational commands (save, query, promote)

When uncertain, ask: "Would you like me to capture this as feedback for Team Qwrk?"

---

## Snapshot Contract

### Artifact-Level Fields

| Field | Value |
|-------|-------|
| `gw_action` | `artifact.save` |
| `artifact_type` | `snapshot` |
| `semantic_type_id` | `product` |
| `priority` | `3` (default) or `2` if impact is `blocking` |
| `parent_artifact_id` | `null` (unless explicitly linked to a project) |

### Required Tags

All Feedback Snapshots must include these tags:

| Tag | Purpose |
|-----|---------|
| `feedback` | Identifies artifact as feedback |
| `for-cc` | Triggers CC for-cc sweep pickup |
| `feedback-{head_slug}` | Head attribution (e.g., `feedback-akara`, `feedback-greg`, `feedback-joel`) |

### Title Convention

```
Feedback — [Short Subject]
```

Example: `Feedback — Snapshot save confirmation is unclear`

### Required Payload Fields

| Field | Type | Description |
|-------|------|-------------|
| `feedback_type` | string | One of: `feature_request`, `bug_report`, `usability_friction`, `improvement`, `praise`, `general` |
| `subject` | string | One-line summary, under 120 characters. Must be triageable without reading the body. |
| `feedback_body` | string | Full feedback content. May be multiple paragraphs. Capture the user's voice. |
| `submitted_by_head` | string | Which Q head captured this. E.g., `Q@Akara`, `Q@Greg`, `Q-Prime`. |
| `submitted_by_user` | string | Human name. E.g., `Akara`, `Greg`, `Joel`. |
| `workspace_origin` | uuid | Workspace ID where feedback was created. |

### Optional Payload Fields

| Field | Type | Description |
|-------|------|-------------|
| `context` | string | What the user was doing when the feedback arose. |
| `impact` | string | One of: `blocking`, `significant`, `minor`, `cosmetic`. |
| `requested_outcome` | string | What the user wants to happen. Freeform. |
| `related_artifact_id` | uuid | If feedback is about a specific artifact. |
| `urgency` | string | One of: `blocking_now`, `soon`, `whenever`. |

---

## Controlled Values

### feedback_type

| Value | When |
|-------|------|
| `feature_request` | User wants something that doesn't exist |
| `bug_report` | Something is broken or behaving incorrectly |
| `usability_friction` | Something works but is confusing or hard to use |
| `improvement` | Something works but could be better |
| `praise` | Something works well and should be preserved |
| `general` | Doesn't fit other categories |

### impact (optional)

| Value | When |
|-------|------|
| `blocking` | Prevents the user from accomplishing their goal |
| `significant` | Noticeably degrades the experience |
| `minor` | Small friction, workaround exists |
| `cosmetic` | Not functional, just feels off |

### urgency (optional)

| Value | When |
|-------|------|
| `blocking_now` | User is stuck right now |
| `soon` | Affects near-term work |
| `whenever` | No time pressure |

---

## Behavioral Rules

1. **Ask before capturing.** If the user hasn't explicitly asked to submit feedback, confirm: "Would you like me to capture this as feedback for Team Qwrk?"
2. **Capture the user's voice.** The `feedback_body` should reflect what the user said, not a sanitized summary. Preserve tone and specificity.
3. **Classify honestly.** Use the `feedback_type` that fits. Do not inflate `bug_report` for feature requests or soften `usability_friction` into `improvement`.
4. **One feedback per snapshot.** Do not bundle multiple unrelated observations. If the user has three things to say, that's three snapshots.
5. **Do not promise outcomes.** After saving, confirm the feedback was captured and will be reviewed. Do not commit to timelines, fixes, or specific actions.
6. **Cross-Workspace Write Gate still applies.** If Q-Prime is capturing feedback and saving to another workspace, the Write Gate fires as normal.

---

## Post-Save Response

After successful save, confirm to the user:

> "Feedback captured — Team Qwrk will review this. Thank you."

Do not elaborate on the review process. Do not promise follow-up unless Joel has established that expectation.

---

## Review Model

Feedback Snapshots are reviewed by Joel via CC's for-cc sweep at session start. CC presents each new feedback item with:

- `feedback_type`
- `subject`
- `submitted_by_head`

Joel triages. Possible outcomes:

- No action needed
- Clarification needed (follow up with user)
- Convert to bug (enter Bug Resolution Process)
- Convert to seed or twig
- Documentation fix
- Direct follow-up via messaging

**Feedback is signal, not backlog.** "No action" is a valid and complete triage outcome.

---

## What This Pack Does NOT Cover

- Review queue UI or dashboard
- Automated notification on feedback save
- Feedback aggregation or trending
- Review state tracking (snapshots are immutable — review state lives elsewhere)
- Feedback across non-Qwrk channels

---

## CHANGELOG

### v1 — 2026-03-29

Initial creation. Snapshot-based feedback capture contract for beta users. Covers payload contract, tagging convention, behavioral rules, and review model. Source seed: `a2877162-45ea-4cb7-a8d5-badb47a9a62a`.
