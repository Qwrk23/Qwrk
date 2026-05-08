# Instruction Pack — Seed Pod Delivery & Retrieval v1

> Operational guidance for delivering Seed Pods to recipients and instructing them how to retrieve the content.

---

## 1. Purpose

This pack governs how Q generates retrieval guidance when a Seed Pod has been planted in a recipient's workspace. It exists because recipients cannot search or browse for Seed Pods — they need an exact, executable retrieval payload.

**Governing doctrine:** Decision `3b1bdb03` — Introduce Seed Pod as Portable Idea Primitive (locked).

**Operational context:** Seed Pods may be stored as different artifact types depending on implementation decisions at planting time. This pack governs retrieval behavior regardless of underlying artifact type.

---

## 2. Trigger

Apply this pack when:
- Q is composing a Seed Pod delivery notification (email, message, or in-conversation guidance)
- A user asks how to open or retrieve a Seed Pod
- Q is generating retrieval instructions for any planted Seed Pod

---

## 3. Scope

**In scope:**
- Seed Pod retrieval payload generation
- Delivery notification wording
- Execution boundary (who runs the payload)

**Out of scope:**
- Seed Pod creation or planting logic
- Seed Pod ontology or taxonomy design
- Messaging transport format (governed by Messaging pack)
- Artifact discovery across non-Seed-Pod types (governed by Artifact Discovery Playbook)
- T164 future phases (walk, run)

---

## 4. Rules

### Rule A — UUID-Based Retrieval

Every Seed Pod retrieval MUST use the exact artifact UUID via `artifact.query`. There is no search, browse, or keyword lookup path for Seed Pods.

### Rule B — Final Payload, Not Meta-Instructions

Q MUST provide the complete, ready-to-execute retrieval payload directly.

Q MUST NOT instruct the recipient to:
- "generate a query payload"
- "ask Q for a hydrated retrieval"
- "look up the artifact"
- construct their own payload from a UUID

The payload is the instruction.

### Rule C — Explicit Hydration

All Seed Pod retrieval payloads MUST include `"selector": { "hydrate": true }` to ensure extension content is returned in full.

This is required even though hydration may default to true on `artifact.query`. Explicit hydration prevents silent breakage if defaults change.

### Rule D — Execution Boundary

Q generates the payload. The user executes it via Qx or QSB.

Q does not execute retrieval payloads on behalf of the user. State this plainly in delivery instructions:

> "Run this payload in Qx, or share it with Q in your conversation."

### Rule E — No Assumed Search Surface

Q MUST NOT instruct a recipient to "search," "browse," "find," or "look for" a Seed Pod unless a search/browse UI is confirmed available in their workspace.

Current state: no such surface exists for any workspace. All retrieval is payload-based.

### Rule F — Wording Posture

Delivery instructions should be human-readable and direct. Write for the person receiving the Seed Pod, not for an operator reading a runbook.

**Do this:**
> "To open your Seed Pod, paste this into Qx and hit Run:"

**Not this:**
> "Generate a hydrated artifact.query payload using the following UUID..."

Match the recipient's familiarity level. If the recipient is new to Qwrk, include a brief framing sentence before the payload (e.g., "Joel planted an idea for you in Qwrk. To read it:").

---

## 5. Artifact Type Rule

Seed Pods are not restricted to a single artifact type. The retrieval payload MUST use the **actual stored artifact type** of the delivered Seed Pod.

When generating a retrieval payload, Q must know:
- The Seed Pod's `artifact_id` (full UUID)
- The Seed Pod's `artifact_type` as stored in the database
- The recipient's `workspace_id`

Do NOT default to `snapshot` or any other type. Use the type the Seed Pod was actually saved as.

If the artifact type is unknown, Q must ask the planter or check the planting record before generating the retrieval payload. Do not guess.

---

## 6. Canonical Retrieval Payload

When delivering a Seed Pod, Q provides this exact shape (substituting actual values):

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "<recipient_workspace_id>",
  "artifact_type": "<actual_artifact_type>",
  "artifact_id": "<seed_pod_uuid>",
  "selector": { "hydrate": true }
}
```

### Live Example — Akara Seed Pod

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
  "artifact_type": "project",
  "artifact_id": "ce667b59-7b4b-480a-9c5f-c627acc194ad",
  "selector": { "hydrate": true }
}
```

**Field rules:**
- `gw_workspace_id` — always the recipient's workspace (where the Seed Pod was planted)
- `artifact_type` — the actual stored type of the Seed Pod (not assumed)
- `artifact_id` — full UUID, never short prefix
- `selector.hydrate` — always `true`, always explicit

---

## 7. Delivery Notification Template

When notifying a recipient that a Seed Pod has arrived, Q should structure the message as:

1. **One-line framing** — what this is and who planted it
2. **The retrieval payload** — ready to paste into Qx
3. **Brief execution instruction** — "Run this in Qx to open it"

### Example wording

> Joel planted a Seed Pod in your workspace — an idea for you to explore when you're ready.
>
> To open it, paste this into Qx and hit Run:
>
> ```json
> {
>   "gw_action": "artifact.query",
>   "gw_workspace_id": "963973e0-a98c-4044-b421-71e7348eaeaf",
>   "artifact_type": "project",
>   "artifact_id": "ce667b59-7b4b-480a-9c5f-c627acc194ad",
>   "selector": { "hydrate": true }
> }
> ```
>
> Once you see the content, we can talk about it together.

Do not over-explain Qwrk internals. The recipient needs to open the Seed Pod, not understand the architecture.

---

## 8. Non-Goals

- Designing Seed Pod creation or planting workflows
- Defining how Qwrk Prime decides what to plant or where
- Governing the messaging transport (email formatting, calendar events)
- Building a browse/search UI for Seed Pods
- Modifying Gateway, DDL, or artifact type registry
- Locking Seed Pod to a single artifact type

---

*CHANGELOG: v1 (2026-04-10): Initial. Seed Pod delivery and retrieval operational guidance. Artifact type is variable (not hard-coded to snapshot) — reflects live state where Akara Seed Pod is a project. Motivated by Akara retrieval failure — instructions assumed search surface that does not exist. QA pass: QSB/Qx execution surface corrected (Qx is direct-execute, QSB is Q-mediated).*
