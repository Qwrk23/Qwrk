# Qwrk Rolling Memory — for-q Sync (v7)

**Generated:** 2026-03-09
**Architecture:** Rolling Memory v7 — Twig Governance + Payload Discipline + Forest Cleanup
**Source:** Supabase qxb_artifact (tags contains 'for-q')
**Tier A-System Active Window:** 27 entries
**Tier A-Prime:** 5 alignment entries
**Total for-q in DB:** 152 snapshots + 13 projects + 27 journals + 3 limbs + 2 branches + 1 twig + 1 leaf + 1 instruction_pack
**Compacted to Section C:** 141 (106 prior + 35 new snapshots/milestones)

---

## Classification Protocol (v3)

All new Tier entries must declare:

```
tier_layer: system | strategic | alignment
```

| Value | Definition | Destination |
|-------|-----------|-------------|
| `system` | Affects execution determinism or schema behavior | Tier A-System |
| `strategic` | Affects phase direction or build gating | Tier A-System |
| `alignment` | Affects Joel decision posture only | Tier A-Prime |

**Default rule:** If `tier_layer` is not declared, entry defaults to Tier B.

---

## Compaction Classification

| Layer | Count | Description |
|-------|-------|-------------|
| **Protected Core** | 8 | Never compacted — foundational governance |
| **Rotating Shell (A-System)** | 19 | 6 anchors + 4 rules + 7 canonical + 2 standalone |
| **Tier A-Prime** | 5 | Alignment & sovereignty — separate review threshold |

**Tier A-System trigger:** >= 50 entries | **Target:** 35 entries
**Status:** UNDER THRESHOLD (27 < 50) — strong headroom
**Last compaction:** 2026-03-09 — v7 regeneration: 2 new Tier A admissions (Anchor 2 twig subsection, Rule 4 payload discipline). 35 new snapshots to Section C Batch 8. Section B2 updated (22->13 projects after forest cleanup).

---

## Section A-System: System & Strategic Governance (READ FIRST)

**Token Budget:** Target 500-1,000 tokens | Hard ceiling 1,500 tokens

These are the active constraints and invariants you MUST honor.
Do not contradict these under any circumstances.

### Protected Core (8)

1. **Qwrk Naming and Identity Lock** [PROTECTED CORE]
   - Impact: Q MUST NOT use QP1 or ANQ as identity references. Q MUST refer to the system as Qwrk or Q only.
   - Scope: global

2. **Phase 1 Lock - Kernel v1 Governance Complete** [PROTECTED CORE]
   - Impact: Q MUST NOT suggest changes to Phase 1 locked decisions: Kernel Semantics (D1-D4), paper schemas, or Gateway Contract (P3-D1 through P3-D5).
   - Scope: global

3. **System Instructions — Read Access Only** [PROTECTED CORE]
   - Impact: Q MUST NOT ask for gw_workspace_id on simple list/query requests. Q MUST NOT call artifact.save, artifact.update, or artifact.promote.
   - Scope: gateway

4. **Production Implies Tree** [PROTECTED CORE]
   - Impact: Q MUST classify any deployed production system as tree (even MVPs). Q MUST NOT suggest oak promotion unless tree:hardened tag is present.
   - Scope: gateway

5. **North Star v0.4 — Execution Anatomy** [PROTECTED CORE]
   - Impact: Q MUST follow execution anatomy: Project -> Branch -> Limb (optional) -> Leaf. Q MUST NOT allow Branch->Branch, Limb->Limb, or Leaf->anything parenting.
   - Scope: global

6. **Chrome Extension Raw JSON Invariant** [PROTECTED CORE]
   - Impact: Q MUST output raw JSON only for Chrome Extension payloads (no markdown, no commentary). Sequential actions require save -> confirm -> extract artifact_id -> proceed.
   - Scope: chrome-extension

7. **Governance Milestones — Execution Discipline** [PROTECTED CORE]
   - Impact: Q MUST NOT invent UUIDs or assume persistence. Q MUST NOT expand Tier A context or mutate memory without explicit user intent.
   - Scope: global

8. **Two-Tier Memory Model** [PROTECTED CORE]
   - Impact: Q MUST treat rolling memory as Tier A (auto-loaded constraints) + Tier B (addressable on-demand). Q MUST NOT silently load Tier B content.
   - Scope: global

---

### Anchor Invariants (6)

> Anchors consolidate execution constraints into doctrinal blocks. Source artifacts preserved in Section C Batch 4.

#### Anchor 1 — Mutation Surface Invariant

- **MUST:** Save = CREATE-only (INSERT, no UPDATE). Update = mutation path for mutable fields. Promote = lifecycle transition path.
- **MUST NOT:** Save MUST NOT update existing artifacts. Update MUST NOT create new artifacts. Promote MUST NOT modify non-lifecycle fields.
- **Source:** Canonical E (T72, T64, Promote v23). Save v42. Update T69. Promote v23.

#### Anchor 2 — Lifecycle Determinism + Mutability (T87)

- **MUST:** Linear progression: seed -> sapling -> tree -> archive. Archive is terminal. C2: Dead seed archival via query-based surfacing only. C4: No skips, no reversals. Seasoned = explicit human-applied tag. Oak = project-level maturity requiring: tree lifecycle, all branches seasoned, owner confirmation, stabilization snapshot.
- **Lifecycle Mutability (T87):**
  - `archive` = ALL FROZEN. No field updates permitted. Error: `ARCHIVE_IMMUTABLE`.
  - `tree` = title FROZEN. Summary, priority, tags, extension, semantic_type remain mutable. Error: `FIELD_FROZEN`. **Rename projects before promoting to tree.**
  - `seed` / `sapling` = all fields mutable.
- **Journal Mutability (T46):** Journals are permanently INSERT-ONLY. No append, no update, no extension mutation. Error: `JOURNAL_INSERT_ONLY`. Thread-append convention (create new journal) is the canonical pattern.
- **Twig Governance (T94 + 2026-03-08):**
  - Twig lifecycle: `seed` and `sapling` only. Archive is terminal (`ARCHIVE_TERMINAL`).
  - **Twig placement:** Twigs may be planted directly on a branch when the domain is already known; otherwise they attach to the Mother Tree. Source: `bbf33255`.
  - **Twig promotion:** When a twig matures into a formal initiative (branch or limb), the originating twig `lifecycle_status` becomes `pruned`. CmdCtr ignores pruned twigs by default. Source: `57cc5372`.
- **MUST NOT:** No automation for dead seed archival. No journal mutation. No lifecycle skips or reversals. No implicit seasoned/oak — requires human review.
- **Source:** Canonical B. `a42b73c6`. `3816af87`. `2478953e`. `20389ab0` (T87). Check_Mutability_Rules v8. `bbf33255` (Twig Placement). `57cc5372` (Twig Pruned).

#### Anchor 3 — Semantic Registry Enforcement

- **MUST:** `semantic_type_id` required on save for project, snapshot, journal, restart. Must reference `qxb_semantic_type_registry` (9 active values). Updates via dedicated `update_semantic_type()` RPC only (SECURITY DEFINER).
- **MUST NOT:** Extension types (branch, leaf, limb, instruction_pack) MUST NOT include `semantic_type_id`. Mixed updates rejected by check #2.5 guard.
- **Source:** `8dacdd00` (T69 Phase 3 cert, 7/7 PASS). DDL v2.6.

#### Anchor 4 — Snapshot Immutability

- **MUST:** Snapshot, restart, and instruction_pack artifacts are immutable after creation. Event log is append-only. Q SHOULD recommend creating a snapshot when promoting sapling to tree.
- **MUST NOT:** No UPDATE policies on snapshot/restart/instruction_pack tables. No UPDATE/DELETE on event log.
- **Source:** `271046d8`. DDL constraints. Phase 1 Lock.

#### Anchor 5 — Sequential Discipline

- **MUST:** One Gateway operation at a time. Sequential action discipline: save -> confirm -> extract artifact_id -> proceed. Canonical v5 is sole payload authority. QSB = desktop default (`prime-exec` marker + fenced json). TG = mobile (raw JSON only).
- **Update routing (T87):** 5 modes — `spine_only`, `mixed`, `tags_only`, `extension`, `semantic_type`. Spine-only and mixed do NOT use `extension` key. Extension updates do NOT include spine fields.
- **Parent routing:** For Mother Tree structures, consult `Instruction_Pack__Mother_Tree_Structural_Map__v1.md` for authoritative UUIDs. If target not in map, ask Joel. Source: `579fb14d`.
- **MUST NOT:** No UUID invention. No parallel Gateway operations. No payload construction without Canonical v5. No mixing QSB/TG format. No mixing spine fields with extension.
- **Source:** `43100e90`. `3beb3832`. `5ad0db26`. `20389ab0` (T87). `579fb14d` (Mother Tree Map).

#### Anchor 6 — Certification Before Deployment

- **MUST:** Phase 2C certification must PASS before schema enrichment or feature expansion. Post-freeze changes require re-certification. Classification: Aligned / Suspect / Deferred.
- **MUST NOT:** No schema enrichment before certification. No feature expansion without reliability gain. No bypassing freeze-point model.
- **Source:** Canonical F. `07525efb`. `20389ab0` (T87 — 133 tests green).

---

### Standalone Rules (4)

**Rule 1 — Qwrk World Invariants and Anti-Footgun Rule** (`25e02429`)
- MUST: Qwrk_World is the highest sovereignty boundary. Private by default.
- MUST NOT: Nothing crosses worlds implicitly. No default sharing.
- Scope: global

**Rule 2 — Weekly Qwrk Stewardship Monday Rule** (`cbf7624e`)
- MUST: Every Monday, check stewardship loop. Pause and prompt Joel before design/build discussion if no Weekly Bet selected.
- Scope: global

**Rule 3 — Qwrk Self-Build Domain Topology** (`bbe9e957`)
- MUST: Organize under single Mother Tree with durable domain branches (Product, Platform, Marketing, Operations).
- MUST NOT: No branch-to-tree promotion without sustained multi-cycle justification.
- Scope: global

**Rule 4 — Q Payload Discipline** (`51baffb9`, `7ecf902f`) [NEW — 2026-03-08]
- MUST: Run payload preflight before emitting any executable payload. Checks: surface format, gw_action/artifact_type valid, required/forbidden fields, real dependency IDs, no placeholders, smallest valid form.
- MUST: Artifacts must include meaningful content. Title-only payloads not permitted for twig, limb, branch, or design artifacts.
- MUST NOT: No payload emission without preflight. No title-only design artifacts.
- Scope: gateway, payload-construction

---

### Phase Gating Doctrine

| Phase | Status | Gate |
|-------|--------|------|
| Phase 1 | **LOCKED** | Kernel v1 sealed. |
| Phase 2 | **SEALED** | DDL v2.9. Mutation perimeter: 47/47 PASS. |
| Phase 2B | **SEALED** | Walk complete. T70 + T71 certified. |
| Phase 2C | **GREEN** | 133 tests, all PASS (post-T87). |
| T69 | **CERTIFIED** | Semantic registry. 7/7 PASS. |
| T80 | **COMPLETE** | Security advisor fixes. DDL v2.9. |
| T87 | **CERTIFIED** | Lifecycle mutability. Check_Mutability_Rules v8. |
| T94 | **CERTIFIED** | Twig lifecycle. CHECK v7 (14 types). |
| T46 | **DECISION LOCKED** | Journals INSERT-ONLY. |
| T100 | **DEPLOYED** | CmdCtr observability: forest scan, execution awareness, session context. |

**Gating Rules:**
- **G1.** Phase 2 MUST NOT be reopened without explicit governance decision.
- **G2.** Walk gaps resolved (T70/T71).
- **G3.** Phase 2C MUST pass before Phase 3 expansion.
- **G4.** T69 = enforcement infrastructure, not new doctrine.
- **G5.** Phase 3 remains SEED — gated behind Phase 2C green + Walk seal.

---

## Section A-Prime: Alignment & Sovereignty Layer

### Alignment Entries

1. **Daily 8am Old Bull Planning Protocol** — Source: `137669a9`
2. **January Joel Bridge — Personal Alignment** — Source: `47784c6e`
3. **Joel Growth Trajectory Toward January 2027** — Source: `61be4fcb`
4. **Qwrk Restart Alignment — Reclaiming the Land** — Source: `668bd18f`
5. **Sovereignty Mirror Boundary** — Q MUST reflect patterns honestly, slow when precision matters. Q MUST NOT replace Joel's judgment or expand urgency beyond structural necessity.

---

## Section A2: Active Operational Contexts

| Context | Status | Latest Part | Reference |
|---------|--------|-------------|-----------|
| **The Hunt for Red October** | active | Part 2 | `a52f402e` |
| **The 5 Levels of Leadership** | active | Part 1 | `49881324` |

---

## Section B: Artifact Index

### B2: for-q Projects (13)

#### Mother Tree Topology (2026-03-09)

```
dec0597b  Qwrk Prime - Mother Tree [tree, P1]
+-- 3ccc694d  Product [branch]
+-- ae7b0467  Snapshots [branch]
+-- dd409298  Platform [tree, P1, branch]
    +-- 285d2b59  Qwrk Cognitive Architecture [tree, P1, limb]
        +-- fc849586  Memory Architecture - Registry vs RAG [tree, P1, limb]
```

| artifact_id | Title | Lifecycle | Priority |
|-------------|-------|-----------|----------|
| `dec0597b` | Qwrk Prime - Mother Tree | **tree** | 1 |
| `dd409298` | Platform | **tree** | 1 |
| `285d2b59` | Qwrk Cognitive Architecture | **tree** | 1 |
| `fc849586` | Memory Architecture - Registry vs RAG | **tree** | 1 |
| `297f9cf2` | Command Center | **archive** | 1 |
| `679fc921` | 2025 Tax Prep & CPA Submission | seed | 2 |
| `8ffbda90` | Gateway Resolve + Enhanced Search | **sapling** | 3 |
| `2ca3b6be` | ~~Rolling Registry~~ (DEPRECATED) | seed | 3 |
| `58667e8e` | Phase 2C Behavioral Type System | seed | 3 |
| `f5a60b9e` | App Module Framework (Phase 3/4) | seed | 3 |
| `cc7e8e2d` | Coach Qwrk:A1C | seed | 3 |
| `668bd18f` | Reclaiming the Land *(A-Prime #4)* | sapling | 4 |
| `2f3c6a9e` | Automate Daily Build Snapshot | sapling | 4 |

### B3: Execution Anatomy (branches, limbs, leaves)

| artifact_id | Type | Title |
|-------------|------|-------|
| `3ccc694d` | branch | Product |
| `ae7b0467` | branch | Snapshots |
| `4c02f865` | limb | Daily Execution Signal |
| `b00fc252` | limb | Command Center |
| `3df090e4` | limb | Mother Tree Architecture Snapshot — Epoch 2026-03 |
| `b5be60f8` | leaf | L5.4 — behavior_role Semantic Invariant |

### B4: Instruction Packs (1)

| artifact_id | Title |
|-------------|-------|
| `a6ae6d8d` | Qwrk PlatformX — App Build Process Contract Template |

### B5: Twigs (1)

| artifact_id | Title | Created |
|-------------|-------|---------|
| `38e505f3` | CmdCtr Control Loop Architecture Insight | 2026-03-07 |

### B6: Journals (27)

*2 recent highlighted. 25 additional queryable via `artifact.list` with `tags: for-q, artifact_type: journal`.*

| artifact_id | Title | Created |
|-------------|-------|---------|
| `8be22e4e` | Inflection Point - Build Velocity Arrives | 2026-03-06 |
| `c5d94c0a` | Registry vs RAG - Memory Architecture Decision | 2026-03-06 |

### Protected Core Snapshots (8)

| artifact_id | Title |
|-------------|-------|
| `041f678e` | Qwrk Naming and Identity Lock |
| `a59311c2` | Phase 1 Lock - Kernel v1 Governance Complete |
| `6159fea4` | Production Implies Tree |
| `b753a85e` | System Instructions - Read Access Enablement v1.2 |
| `0bf89bec` | North Star v0.4 - Execution Anatomy Lock |
| `8b98f42d` | Chrome Extension Raw JSON Invariant |
| `13dfa8fb` | Governance, Memory, Execution Discipline Milestones |
| `120812e8` | Memory Load vs Addressable Registry |

### Standalone Entries (2)

| artifact_id | Title | Created |
|-------------|-------|---------|
| `20389ab0` | T87 Complete / design_spine / T88 Deferred | 2026-03-06 |
| `968e6c3b` | Joel and Qwrk Collaboratively Build Through QPM | 2026-03-08 |

---

## Section C: Archived / Compacted References

### Batches 1-7 (106 entries)

*Full listings in archived `Qwrk_Rolling_Memory__for-q__2026-03-07.md`. Summary:*

| Batch | Date | Count | Description |
|-------|------|-------|-------------|
| 1 | 2026-02-17 | 8 | Strategic compaction (bug/milestone snapshots) |
| 2 | 2026-02-22 | 27 | Structural compaction -> Canonical A-D |
| 3 | 2026-03-01 | 17 | Wave 1 consolidation -> Canonical E-G |
| 4 | 2026-03-04 | 28 | Wave 2 anchor collapse (18 constraints -> 6 anchors + 3 rules) |
| 5 | 2026-03-06 | 3 | Resolved threads (T51, T64, credibility filter) |
| 6 | 2026-03-06 | 5 | T94 certification + baseline records |
| 7 | 2026-03-07 | 18 | CmdCtr deployment + standalone cleanup |

### Batch 8 — 2026-03-09 v7 (35 entries)

#### Absorbed into Tier A (4)

| artifact_id | Title | Destination |
|-------------|-------|-------------|
| `bbf33255` | Twig Placement May Target Branches | Anchor 2 |
| `57cc5372` | Twig Promotion Uses Pruned Lifecycle State | Anchor 2 |
| `51baffb9` | Payload Preflight Required Before Execution | Rule 4 |
| `7ecf902f` | Artifacts Must Contain Meaningful Content | Rule 4 |

#### Operational Patterns (2)

| artifact_id | Title | Created |
|-------------|-------|---------|
| `579fb14d` | Mother Tree Structural Map for Parent Routing | 2026-03-09 |
| `24a9772b` | QPM Documentation via Snapshots | 2026-03-09 |

#### Beta User Signals (2)

| artifact_id | Title | Created |
|-------------|-------|---------|
| `3af6c36f` | First Beta User Onboarding Signal | 2026-03-08 |
| `b9eb3888` | First Beta User Conversion Moment — QSB Engine Room | 2026-03-08 |

#### Forest Cleanup & Historical (4)

| artifact_id | Title | Created |
|-------------|-------|---------|
| `2803b7af` | Forest Cleanup — Historical Record Archive | 2026-03-08 |
| `63483697` | Forest Cleanup and Topology Stabilization | 2026-03-08 |
| `2db5da06` | Daisy Communication — Qwrk Self-Build Milestone | 2026-03-08 |
| `36c6e7db` | Historical Concept Seeds — Pre CmdCtr Era | 2026-03-07 |

#### CmdCtr Session Contexts (10)

`464731cc`, `707a8c74` (2026-03-09); `52281d18`, `ad0b9799`, `fc17d6aa`, `aba144fa` (2026-03-08); `9c369d77`, `6dab8af2`, `78fbd6c1`, `688a46a7` (2026-03-07)

#### Other Snapshots (13)

`968e6c3b` (QPM collaborative build), `ee9aa083` (product vision), `e514f11f` (one thing execution), `11abffb6` (CmdCtr Phase 3), `79cb75b2` (CmdCtr context). *8 additional in Batch 7.*

---

## Regeneration Notes

### 2026-03-09 v7

- **Previous:** v6 (25 A-System, 5 A-Prime, 100 snapshots + 22 projects)
- **Changes:** +2 Tier A (Anchor 2 twig, Rule 4 payload). Projects 22->13. +2 branches, +3 limbs, +1 leaf, +7 journals. Batch 8: 35 entries. Batches 1-7 by pointer.
- **Tier A-System: 25 -> 27** | A-Prime: 5 | Section C: 106 -> 141
- **Total for-q:** 200 artifacts
- **Previous version:** `Archive/Qwrk_Rolling_Memory__for-q__2026-03-07.md`
