# Instruction Pack Index

> Master index of all instruction packs and reference documents available to Qwrk.
>
> **Payload Lookup Mandate:** Before emitting any Gateway payload, find the governing pack in this index by matching the Trigger column, open it, and verify the required shape.

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
| `QUICK_REFERENCE.md` | Save/update/promote/list/query examples | Any Gateway payload (quick lookup) |
| `WORKFLOW_PATTERNS.md` | Common workflow patterns | Multi-step workflows (seed+journal, promote) |
| `Instruction_Pack__QSB_Payload_Format__v3.md` | QSB rendering contract + validation gate | Every execution-bound output (QSB format) |
| `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` | Search mode classification + query strategies | `artifact.query`, `artifact.list` |
| `Instruction_Pack__Payload_Discipline__v2.md` | Payload invariants + extension rules + preflight | Every Gateway payload (preflight check) |
| `Instruction_Pack__Messaging__ACTIVE.md` | send_email + calendar_event contracts | `messaging.send_email`, `messaging.create_calendar_event` |
| `Instruction_Pack__BlaggLife_Debt_Query_Routing__v1.md` | Debt Freedom Plan — BlaggLife query routing, retrieval rules, response behavior | Debt payment, debt snapshot, debt progress, debt balances, statement upload |
| `Instruction_Pack__Debt_Freedom_Plan_Operating_Protocol__v1.md` | Canonical debt operating protocol — snapshot taxonomy, monthly cycle, cross-workspace routing, derived metrics | Referenced by BlaggLife Debt Query Routing adapter |

## Governance

| File | Purpose | Trigger |
|------|---------|---------|
| `LIFECYCLE_GUIDE.md` | Lifecycle stage transitions | `artifact.promote`, lifecycle decisions |
| `CONVERSATION_RESTART_PROTOCOL.md` | Restart prompt format | Conversation restart |
| `weekly_qwrk_stewardship_loop.md` | Weekly stewardship cadence | Weekly review |
| `Instruction_Pack__Phase2_Governance_Hardening__v1.md` | Phase 2 governance rules | Governance questions |
| `Instruction_Pack__CmdCtr_Session_Context__v1.md` | CmdCtr briefing protocol | Session start (CmdCtr present) |
| `Instruction_Pack__QPM_Build_Process__v1.md` | QPM 7-phase launch + twig fast-capture | QPM project launch, twig quick capture |

## Infrastructure

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Mother_Tree_Structural_Map__v1.md` | Mother Tree branch UUIDs + routing | Setting `parent_artifact_id` |

## Overlay

| File | Purpose | Trigger |
|------|---------|---------|
| `Demo_Mode_IP_v2.md` | Demo Mode behavioral overlay (session-bound) | Entering Demo Mode |

---

**Governance Rule:** Instruction Pack Index must be updated in the same change set as any pack version bump. ACTIVE alias files must be updated atomically with version changes.

*Updated: v4 (2026-03-30) — Messaging pack reference updated from `v2.1` to ACTIVE alias (`Instruction_Pack__Messaging__ACTIVE.md`). Added Index synchronization governance rule. Previous: `Archive/Instruction_Pack_Index__v3__2026-03-30.md`. v3: BlaggLife Debt Query Routing + Debt Freedom Plan. v2: Trigger column. v1: extraction.*
