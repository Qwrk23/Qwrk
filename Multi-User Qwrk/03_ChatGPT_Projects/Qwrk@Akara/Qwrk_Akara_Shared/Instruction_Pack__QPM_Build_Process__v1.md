# Instruction Pack: QPM Build Process v1

> Canonical reference for how Qwrk projects are built through QPM (Qwrk Project Management).
> Distilled from governance snapshots created during the first QPM tree build (2026-03-08/09).

---

## 1. The 7-Phase Project Launch Procedure

Every new implementation initiative follows this sequence. No phase may be skipped.

### Phase 1 — Initiative Creation (Seed)

Save a new project artifact as a **seed**:
- `artifact_type: project`
- `extension.lifecycle_stage: seed`
- `parent_artifact_id`: correct domain container from Mother Tree Structural Map
- Include meaningful `summary` describing intent

The seed registers the initiative and anchors it within the Mother Tree topology.

### Phase 2 — Execution Structure Scaffolding

Before any work begins, construct the **full execution tree**:

```
project (seed) → branch → limb (optional) → leaves
```

- **Branch** = functional subsystem or domain
- **Limb** = feature slice or capability cluster within a branch
- **Leaf** = atomic execution unit (one task, one deliverable)

**Documentation Leaf Rule:** Every execution tree MUST include at least one leaf for updating downstream documentation (instruction packs, system instructions, canonical references). Documentation updates are deliverables, not follow-on work.

All execution leaves should exist before execution begins — including documentation and instruction-pack update leaves, not just implementation and test leaves.

### Phase 3 — Design Rationale Record

Before promotion, a design rationale artifact must exist:
- **Recommended:** Create a design journal parented to the project
- **Acceptable:** A detailed `project.summary` field

Purpose: capture architectural reasoning, scope boundaries, and explain the execution structure.

### Phase 4 — Promotion to Sapling

Promote the seed to sapling via `artifact.promote`:
- `transition: seed_to_sapling`
- **Precondition:** Execution structure AND design rationale both exist

Lifecycle model: seed (idea defined) → sapling (work in progress) → tree (completed) → archive (historical).

### Phase 5 — Execution Initialization

Initialize all leaf `execution_status` to `not_started`. This enables:
- CmdCtr visibility into execution progress
- Deterministic progress tracking
- Autonomous agent (CC) execution

### Phase 6 — Leaf Execution

Execution proceeds leaf-by-leaf:
- `not_started → in_progress → complete`
- Leaf completion rolls up: leaf → limb → branch → project

### Phase 7 — Project Completion (Tree)

Promote to tree via `artifact.promote`:
- `transition: sapling_to_tree`
- **Precondition:** All leaves complete, including documentation leaves
- Meaning: implementation finished, feature delivered

---

## 2. Project Navigation Snapshot

**When required:** Any project entering sapling execution or handed to a builder (Q, CC) must contain a project navigation snapshot.

**Naming convention:** `<Project Name> — Project Navigation Map`

**Required tags:** `for-q`, `for-cc`, `navigation`

**Required payload structure:**
- `project` — artifact_id, title, lifecycle status
- `design_snapshot` — pointer to design rationale artifact
- `execution_branches` — branch/limb/leaf tree with artifact_ids
- `builder_guidance` — what to build, constraints, dependencies

**Builder hydration sequence:**
1. Hydrate navigation snapshot
2. Hydrate architecture/design snapshot
3. Hydrate execution branches
4. Begin execution work

Navigation snapshots provide deterministic project hydration and prevent partial traversal or vertical anchoring errors during builds.

---

## 3. Branch Closure Protocol

A branch may only be closed after ALL direct children have been:
1. Hydrated
2. Initialized in the execution lifecycle (`execution_status` set)
3. Transitioned to `execution_status = complete`

**Operator procedure:**
1. Hydrate all direct children of the branch
2. Initialize NULL `execution_status` → `not_started`
3. Progress lifecycle: `not_started → in_progress → complete`
4. Verify all children `execution_status = complete`
5. Close the branch (`execution_status → complete`)

**Key invariant:** `execution_status = NULL` behaves as incomplete in CmdCtr scans. Historical or certification artifacts created outside the execution lifecycle will surface as active work until their lifecycle state is initialized and completed.

---

## 4. Build Governance Rules

### Payload Preflight (Required Before Execution)

Before emitting any executable payload, run this checklist:
- [ ] Surface format correct for QSB or TG
- [ ] `gw_action` and `artifact_type` are valid
- [ ] Required and forbidden fields respected
- [ ] Real dependency IDs present when needed (no placeholders)
- [ ] No invented UUIDs
- [ ] Payload is the smallest valid form needed

### Meaningful Content Rule

Twig, limb, branch, and other design artifacts MUST include content describing purpose, intent, or scope. Title-only payloads are not permitted unless explicitly allowed by artifact type.

### Twig Fast-Capture Protocol

Twigs are the default capture lane for add-on ideas, side sparks, micro-initiatives, and future architectural notes that are not yet full seeds.

**Trigger phrases:** "quick capture", "quick twig", "plant a twig", "capture this as a twig"

**No title-only twigs.** This is a special case of the Meaningful Content Rule above — twigs are the most at-risk type for losing intent over time.

**Minimal intent bundle.** Every quick-capture twig must include a `content` object with four fields:

| Field | Purpose |
|-------|---------|
| `idea` | What the idea is — one clear sentence |
| `why_now` | Why it surfaced in this moment or conversation |
| `problem_touched` | What problem, tension, or domain it relates to |
| `future_hook` | What future Joel / Q should look at when revisiting |

**Schema note:** Twig is spine-only (no extension table). The intent bundle lives in the spine `content` field (jsonb). The `summary` field should contain a one-line plain-text version of the idea for list/scan readability.

**Example `content`:**
```json
{
  "idea": "Gateway could return affected artifact count on bulk tag operations",
  "why_now": "Noticed missing feedback during T121 multi-artifact tag update",
  "problem_touched": "Gateway response contract — no bulk operation acknowledgment",
  "future_hook": "Revisit when Gateway response shaper audit (T113) is active"
}
```

**Parenting rule:**
- If the domain is known, parent the twig to the relevant branch or container in the Mother Tree (see `Instruction_Pack__Mother_Tree_Structural_Map__v1.md`)
- If the domain is unclear, parent to the Mother Tree root or ask Joel

**Promotion rule:** A twig remains lightweight until it becomes a real initiative with broader execution scope or architectural weight. At that point, promote or expand it into a seed (project) with full QPM Phase 1 treatment.

### Governance Documentation via Snapshots

Major governance decisions should be recorded as snapshot artifacts tagged `governance, for-q`. This creates a permanent, queryable record of system evolution discoverable through the forest itself.

---

## 5. Extending This Pack

As new process patterns emerge during builds, they should be captured and folded back into this instruction pack.

### When to create a new governance snapshot

Create a new snapshot when:
- A new build pattern is established that should be repeatable
- A rule is discovered that prevents a class of build errors
- A protocol is formalized that was previously ad-hoc

**Tag the snapshot:** `process`, `governance`, `for-q`, and optionally `for-cc`

**Parent the snapshot** to the appropriate domain branch in the Mother Tree to keep process documentation co-located.

### When to update this instruction pack

After accumulating 2-3 related governance snapshots on a topic, propose an instruction pack update that distills them into actionable rules. This keeps the IP concise while the snapshots preserve full historical reasoning.

---

## Source Artifacts

This instruction pack was distilled from the following governance snapshots (Qwrk Prime forest):

| Artifact ID | Title | Date |
|-------------|-------|------|
| `bd1b720f` | Canonical QPM Project Launch Procedure v1.1 | 2026-03-09 |
| `0b5ddef0` | Project Navigation Snapshot — Standard Pattern | 2026-03-12 |
| `24a9772b` | Governance Pattern — QPM Documentation via Snapshots | 2026-03-09 |
| `34f74800` | Governance Snapshot — Branch Closure Protocol | 2026-03-09 |
| `51baffb9` | Governance Update — Payload Preflight Required | 2026-03-08 |
| `7ecf902f` | Governance Update — Artifacts Must Contain Meaningful Content | 2026-03-08 |
| `968e6c3b` | Historical Milestone — Collaborative Build Through QPM | 2026-03-08 |
| `53b1b9cf` | Historic Moment — First QPM Execution Project Launch | 2026-03-09 |

---

*CHANGELOG: v1.1 (2026-03-15): Added Twig Fast-Capture Protocol as subsection under §4 Build Governance Rules — twigs as default quick-capture lane, minimal 4-field intent bundle in spine `content`, parenting rule, promotion rule. No sections renumbered. v1.0 (2026-03-12): Initial. Distilled from 8 governance snapshots created during first QPM tree build (List Filter Enhancement, `4c6c9395`). Covers 7-phase launch, navigation snapshots, branch closure, build governance rules, and extension guidance.*
