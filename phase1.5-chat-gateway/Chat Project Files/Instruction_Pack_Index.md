# Instruction Pack Index

> Master index of all instruction packs and reference documents available to Qwrk.
>
> **Payload Lookup Mandate:** Before selecting an artifact type or emitting any Gateway payload, find the governing pack in this index by matching the Trigger column, open it, and verify the required shape.

## Core

| File | Purpose | Trigger |
|------|---------|---------|
| `north_star_january_joel_alignment_charter.md` | Alignment Prime — always-on reference | Session start, prioritization decisions |
| `Journal_Mode_Instructions.md` | Journal Mode behavioral rules | Entering/exiting Journal Mode |
| `Active_Context_Instructions.md` | Section A2 active context protocol | Session start (A2 check) |
| `CC_Prompt_Guidelines.md` | CC prompt generation rules | Generating CC prompts |

## Execution

| File | Purpose | Trigger |
|------|---------|---------|
| `Qwrk_Gateway_Payload_Canonical_v5.md` | Full Gateway payload specification | Any `artifact.save` payload |
| `QUICK_REFERENCE.md` | Save/update/promote/list/query examples + workflow patterns | Any Gateway payload (quick lookup) |
| `Instruction_Pack__QSB_Payload_Format__v3.md` | QSB rendering contract + validation gate | Every execution-bound output (QSB format) |
| `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` | Search mode classification + query strategies | `artifact.query`, `artifact.list` |
| `Instruction_Pack__Payload_Discipline__v4.md` | Single operational authority for payload construction: extension field rules, semantic type governance, artifact selection, gateway error posture, and fast-capture carveout | Every Gateway payload (preflight check), artifact type selection |
| `Instruction_Pack__Messaging__ACTIVE.md` | send_email + calendar_event contracts | `messaging.send_email`, `messaging.create_calendar_event` |
| `Instruction_Pack__Debt_Freedom_Plan_Operating_Protocol__v1.md` | Debt Freedom Plan operating protocol — snapshot taxonomy, monthly cycle, cross-workspace routing, derived metrics | Debt payment, debt snapshot, monthly debt update, debt payoff progress, statement upload |
| `Instruction_Pack__Feedback_Snapshot__v1.md` | Structured feedback capture contract for beta users | User expresses feedback, feature request, bug report, usability friction, praise |
| `Instruction_Pack__Person_Artifact_Save_Capability_Boundary__v1.md` | Person artifact save contract boundary — implemented vs blocked capabilities, extension schema, mapping rules, operational posture | `artifact.save` with `artifact_type: "person"`, person profile capture |

## Governance

| File | Purpose | Trigger |
|------|---------|---------|
| `LIFECYCLE_GUIDE.md` | Lifecycle stage transitions | `artifact.promote`, lifecycle decisions |
| `CONVERSATION_RESTART_PROTOCOL.md` | Restart prompt format | Conversation restart |
| `weekly_qwrk_stewardship_loop.md` | Weekly stewardship cadence | Weekly review |
| `Instruction_Pack__Phase2_Governance_Hardening__v1.md` | Phase 2 governance rules | Governance questions |
| `Instruction_Pack__CmdCtr_Session_Context__v1.md` | CmdCtr briefing protocol | Session start (CmdCtr present) |
| `Instruction_Pack__QPM_Build_Process__v1.md` | QPM 7-phase launch + twig fast-capture | QPM project launch, twig quick capture |
| `Instruction_Pack__Team_Qwrk_Bug_Resolution_Process__v1.md` | 10-phase bug resolution with authorization gate | Bug identified, bug fix planning, production mutation |

## Safety

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Cross_Workspace_Write_Gate__v1.md` | Cross-workspace write consent boundary for non-home workspace mutations | Before emitting any cross-workspace write payload |

## Infrastructure

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Mother_Tree_Structural_Map__v1.md` | Mother Tree branch UUIDs + routing | Setting `parent_artifact_id` |
| `Instruction_Pack__CC_Handoff_Lane__v1.md` | Q ↔ CC structured handoff protocol — artifact roles, tags, Template A, retrieval doctrine | Sending structured work to CC, receiving CC results |

## Overlay

| File | Purpose | Trigger |
|------|---------|---------|
| `Demo_Mode_IP_v2.md` | Demo Mode behavioral overlay (session-bound) | Entering Demo Mode |

## Onboarding

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Beta_User_Onboarding__v1.md` | Beta user provisioning (operator) + onboarding (user) — two-mode protocol | Joel declares new beta user OR user's first interaction in new workspace |

---

**Governance Rule:** Instruction Pack Index must be updated in the same change set as any pack version bump. ACTIVE alias files must be updated atomically with version changes.

*Updated: v12 — Messaging pack reference updated from `v2.1` to ACTIVE alias (`Instruction_Pack__Messaging__ACTIVE.md`). Added Index synchronization governance rule. Previous: `Archive/Instruction_Pack_Index__v11__2026-03-30.md`. v11 — Added CC Handoff Lane under Infrastructure. Pack count 24→25. v10 — Added Feedback Snapshot under Execution. v8 — Added Person Artifact Save Capability Boundary. v6 — Payload Discipline v3→v4. v5 — architecture refactor.*
