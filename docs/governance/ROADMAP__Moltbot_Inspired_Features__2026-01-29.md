# Roadmap: Moltbot-Inspired Features

**Created:** 2026-01-29
**Updated:** 2026-01-29 (phase alignment)
**Status:** Queued (not started)
**Source Analysis:** `docs/governance/Moltbot_Feature_Assessment__Selective_Absorption__2026-01-29.md`

---

## Overview

Four features identified from Moltbot/Clawdbot analysis that align with Qwrk's philosophy. Mapped to Qwrk's phase structure for proper sequencing.

---

## Phase Alignment

| Feature | Phase | Type | Rationale |
|---------|-------|------|-----------|
| **Irreducible Core v1** | Pre-Phase / Governance | Philosophy | Defines what ALL phases must protect. Do ASAP. |
| **Durable Intent Capture** | Phase 2 amendment | Schema | Adds `durable_intent` field to snapshot/restart. Small addition. |
| **Interaction Log Layer** | Phase 4 (post-Kernel v1) | New table | Not in Kernel v1 scope. Aligns with deferred "Audit/event table" work. |
| **CQA1C** | Parallel | Application | Built ON Qwrk, not part of kernel. Can proceed independently. |

---

## Feature Queue

| # | Feature | Restart Prompt | Phase | Status |
|---|---------|----------------|-------|--------|
| 1 | **Irreducible Core v1** | `docs/restarts/RESTART__Moltbot_Inspired_1__Irreducible_Core_v1.md` | Pre-Phase | Queued |
| 2 | **Durable Intent Capture** | `docs/restarts/RESTART__Moltbot_Inspired_2__Durable_Intent_Capture.md` | Phase 2 | Queued |
| 3 | **Interaction Log Layer** | `docs/restarts/RESTART__Moltbot_Inspired_3__Interaction_Log_Layer.md` | Phase 4 | Queued |
| 4 | **CQA1C** | `docs/restarts/RESTART__Moltbot_Inspired_4__Proceed_to_CQA1C.md` | Parallel | Active |

---

## Execution Order

```
┌─────────────────────────────────────────────────────────┐
│  GOVERNANCE (do ASAP — not implementation, philosophy)  │
│                                                         │
│  [1] Irreducible Core v1                                │
│      Defines what Qwrk will NEVER trade away            │
│      Governs ALL downstream decisions                   │
└─────────────────────────────────────────────────────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
┌─────────────────────┐       ┌─────────────────────┐
│  KERNEL (Phase 2)   │       │  APPLICATION        │
│                     │       │                     │
│  [2] Durable Intent │       │  [4] CQA1C          │
│      Capture        │       │      (parallel)     │
│                     │       │                     │
│  Schema amendment:  │       │  Built on Qwrk      │
│  snapshot/restart   │       │  Not kernel work    │
└─────────────────────┘       └─────────────────────┘
          │
          ▼
┌─────────────────────┐
│  POST-KERNEL (Ph 4) │
│                     │
│  [3] Interaction    │
│      Log Layer      │
│                     │
│  New table/artifact │
│  Audit/evidence     │
└─────────────────────┘
```

---

## Dependencies

- **#1 (Irreducible Core)** — MUST come first. Governs what #2 and #3 can/cannot do.
- **#2 (Durable Intent Capture)** — Depends on #1. Phase 2 schema work.
- **#3 (Interaction Log)** — Depends on #1. Phase 4, after Kernel v1 stable.
- **#4 (CQA1C)** — No kernel dependencies. Can proceed in parallel.

---

## NOT Doing (from Moltbot)

These were explicitly rejected:

| Feature | Reason |
|---------|--------|
| Markdown-as-canonical-memory | Destroys historical truth |
| Gateway-as-source-of-truth | Artifacts own reality |
| Mutable session state | Qwrk records mistakes, doesn't erase them |

---

## How to Start

**Irreducible Core (do ASAP — governance, not code):**
1. Open `docs/restarts/RESTART__Moltbot_Inspired_1__Irreducible_Core_v1.md`
2. Follow the start command
3. Output: `docs/governance/Qwrk_Irreducible_Core__v1.md`

**Durable Intent Capture (Phase 2 amendment):**
1. Complete Irreducible Core first
2. Open `docs/restarts/RESTART__Moltbot_Inspired_2__Durable_Intent_Capture.md`
3. Amend Phase 2 schemas (snapshot/restart)

**Interaction Log (Phase 4):**
1. Wait until Kernel v1 stable
2. Open `docs/restarts/RESTART__Moltbot_Inspired_3__Interaction_Log_Layer.md`
3. Design new table/artifact type

**CQA1C (anytime):**
1. Open `docs/restarts/RESTART__Moltbot_Inspired_4__Proceed_to_CQA1C.md`
2. Proceed independently of kernel work

---

## Related Documents

- `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md` — Phase definitions
- `docs/governance/Moltbot_Feature_Assessment__Selective_Absorption__2026-01-29.md` — Source analysis
