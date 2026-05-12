# Instruction Pack Index

> Master index of all instruction packs and reference documents available to Qwrk (Akara Workspace).
>
> **Payload Lookup Mandate:** Before emitting any Gateway payload, find the governing pack in this index by matching the Trigger column, open it, and verify the required shape.

## Execution

| File | Purpose | Trigger |
|------|---------|---------|
| `QUICK_REFERENCE.md` | Save/update/promote/list/query examples | Any Gateway payload (quick lookup) |
| `Instruction_Pack__QSB_Payload_Format__v3.md` | QSB rendering contract + validation gate | Every execution-bound output (QSB format) |
| `Instruction_Pack__Artifact_Discovery_Playbook__v1.md` | Search mode classification + query strategies + intent recognition + candidate scoring + ghost-like demotion + presentation/disambiguation + test corpus reference | `artifact.query`, `artifact.list`, fuzzy artifact discovery requests |
| `Instruction_Pack__Payload_Discipline__v2.md` | Single operational authority for payload construction: extension field rules, semantic type governance, artifact selection, gateway error posture, content field governance, and fast-capture carveout | Every Gateway payload (preflight check), artifact type selection |
| `Instruction_Pack__Messaging__ACTIVE.md` | send_email + calendar_event contracts | `messaging.send_email`, `messaging.create_calendar_event` |
| `Instruction_Pack__Person_Artifact_Save_Capability_Boundary__v1.md` | Person artifact save contract boundary — implemented vs blocked capabilities, extension schema, mapping rules, operational posture | `artifact.save` with `artifact_type: "person"`, person profile capture |

## Domain

| File | Purpose | Trigger |
|------|---------|---------|
| `Instruction_Pack__Gardenomicon__v1.md` | Gardenomicon plant-care memory — record model, content keys, retrieval + save behavior, controlled vocabulary | Gardenomicon / plant-related requests |

## Governance

| File | Purpose | Trigger |
|------|---------|---------|
| `LIFECYCLE_GUIDE.md` | Lifecycle stage transitions | `artifact.promote`, lifecycle decisions |
| `CONVERSATION_RESTART_PROTOCOL.md` | Restart prompt format | Conversation restart |
| `Instruction_Pack__QPM_Build_Process__v1.md` | QPM 7-phase launch + twig fast-capture | QPM project launch, twig quick capture |

---

**Governance Rule:** Instruction Pack Index must be updated in the same change set as any pack version bump. ACTIVE alias files must be updated atomically with version changes.

*Updated: v6 (2026-05-12) — Artifact Discovery Playbook v1.1 → v1.3. T209 Crawl-1 Pass 2 propagation (Akara). Absorbed v1.2 T166 Step 2.5 enforcement + v1.3 Crawl-1 additions (Sections H Intent Recognition, I Candidate Scoring v1, J Ghost-like Demotion, K Candidate Presentation and Disambiguation, L Test Corpus Reference). Front-matter `pack_version` corrected from drifted `v1` to `v1.3`. Trigger column expanded to surface fuzzy artifact discovery requests. Manus TQR `Ready with amendments` applied (ghost-like "flag" → "indicator/caveat"; "recommend hydrate" → "offer for Joel's confirmation"; Section L fixture-authority sentence). Source: Artifact Discovery Layer seed `542cf4c1-c6df-4504-8a1e-9ca799a9c38c`, Crawl-0 Audit Snapshot `b532f87c-5b25-4c92-bb41-1a3cfd06022e`. Previous: `Archive/Instruction_Pack_Index__v5__2026-05-12.md`. v5 (2026-04-09) — Added Gardenomicon instruction pack (Domain category). v4 (2026-03-30): Messaging ACTIVE alias, Index sync rule. v3 (2026-03-29): Person Artifact Save. v2 (2026-03-21): Akara-specific index.*
