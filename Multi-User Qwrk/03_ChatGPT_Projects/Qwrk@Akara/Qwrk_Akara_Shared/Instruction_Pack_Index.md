# Instruction Pack Index

> Master index of all instruction packs and reference documents available to Qwrk (Akara Workspace).
>
> **Payload Lookup Mandate:** Before emitting any Gateway payload, find the governing pack in this index by matching the Trigger column, open it, and verify the required shape.

## Execution

| File | Purpose | Trigger |
|------|---------|---------|
| `QUICK_REFERENCE.md` | Save/update/promote/list/query examples | Any Gateway payload (quick lookup) |
| `Instruction_Pack__QSB_Payload_Format__v3.md` | QSB rendering contract + validation gate | Every execution-bound output (QSB format) |
| `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` | Search mode classification + query strategies | `artifact.query`, `artifact.list` |
| `Instruction_Pack__Payload_Discipline__v2.md` | Single operational authority for payload construction: extension field rules, semantic type governance, artifact selection, gateway error posture, content field governance, and fast-capture carveout | Every Gateway payload (preflight check), artifact type selection |
| `Instruction_Pack__Messaging__ACTIVE.md` | send_email + calendar_event contracts | `messaging.send_email`, `messaging.create_calendar_event` |
| `Instruction_Pack__Person_Artifact_Save_Capability_Boundary__v1.md` | Person artifact save contract boundary — implemented vs blocked capabilities, extension schema, mapping rules, operational posture | `artifact.save` with `artifact_type: "person"`, person profile capture |

## Governance

| File | Purpose | Trigger |
|------|---------|---------|
| `LIFECYCLE_GUIDE.md` | Lifecycle stage transitions | `artifact.promote`, lifecycle decisions |
| `CONVERSATION_RESTART_PROTOCOL.md` | Restart prompt format | Conversation restart |
| `Instruction_Pack__QPM_Build_Process__v1.md` | QPM 7-phase launch + twig fast-capture | QPM project launch, twig quick capture |

---

**Governance Rule:** Instruction Pack Index must be updated in the same change set as any pack version bump. ACTIVE alias files must be updated atomically with version changes.

*Updated: v4 (2026-03-30) — Messaging pack reference updated from `v2.2` to ACTIVE alias (`Instruction_Pack__Messaging__ACTIVE.md`). Added Index synchronization governance rule. Previous: `Archive/Instruction_Pack_Index__v3__2026-03-30.md`. v3 (2026-03-29): Added Person Artifact Save Capability Boundary. v2 (2026-03-21): Akara-specific index.*
