# Spring Artifact Type — Phase 2+ Design Concept (v1)

**Date:** 2026-01-07
**Status:** Design Concept (Phase 2+ Feature, Excluded from Beta V1)
**Owner:** Master Joel
**Origin:** Restart artifact `2a8a5719-4734-4cd1-9fa1-3880a430c3a1`

---

## Core Concept

**Spring** is a proposed first-class artifact type that sits **above the execution layer** as a durable, generative semantic anchor.

Unlike projects (which have lifecycle stages and operational state), Springs are **idea-origin artifacts** that can spawn multiple seeds/saplings without themselves being projects.

---

## Metaphor: Qwrk as Prefrontal Cortex

In the automation ecosystem:
- **n8n / automation tools** = nervous system (execution layer)
- **LLMs / AI models** = muscles (capability layer)
- **Qwrk** = prefrontal cortex (intent, governance, continuity)

**Spring artifacts** represent the **originating intent** — the generative idea that gives rise to multiple projects, initiatives, or explorations.

---

## Use Cases

### 1. Strategic Themes
A Spring captures a high-level strategic theme that spawns multiple related projects.

**Example:**
- **Spring:** "AI-Assisted Creator OS"
- **Spawned Seeds/Saplings:**
  - Content Strategy & Creation workflows
  - Process Automation governance
  - Vibe Coding philosophy implementation

### 2. Recurring Ideation Contexts
A Spring represents a recurring context or perspective that generates ideas over time.

**Example:**
- **Spring:** "5 High Income AI Skills" (video topic)
- **Spawned Seeds:**
  - Content creation workflows
  - Automation orchestration layer
  - AI-assisted development patterns

### 3. Research Domains
A Spring captures a research domain or area of inquiry that branches into multiple investigations.

**Example:**
- **Spring:** "Governance Models for AI Agents"
- **Spawned Saplings:**
  - Behavioral Controls constitution
  - Qwrkflows (QF) approval-gate design
  - Personality Layer separation model

---

## How Spring Differs from Projects

| Aspect | Project | Spring |
|--------|---------|--------|
| **Purpose** | Execute specific work with defined outcomes | Generate ideas and spawn related projects |
| **Lifecycle** | seed → sapling → tree → retired | No lifecycle (always generative) |
| **Operational State** | active / paused / blocked / waiting | N/A (Springs don't "execute") |
| **Parent Relationship** | Can have parent (thicket or project) | Can exist standalone or in thickets |
| **Children** | Can have sub-projects (leaves, thorns) | Can spawn seeds/saplings (but remains separate) |

---

## Proposed Schema (Phase 2+)

### Artifact Type Enum Addition
```sql
-- Add 'spring' to artifact_type constraint
ALTER TABLE qxb_artifact
DROP CONSTRAINT qxb_artifact_artifact_type_check_v2;

ALTER TABLE qxb_artifact
ADD CONSTRAINT qxb_artifact_artifact_type_check_v3
CHECK ((artifact_type = ANY (ARRAY[
  'project'::text,
  'snapshot'::text,
  'restart'::text,
  'journal'::text,
  'forest'::text,
  'thicket'::text,
  'flower'::text,
  'thorn'::text,
  'grass'::text,
  'spring'::text  -- NEW
])));
```

### Extension Table: qxb_artifact_spring
```sql
CREATE TABLE qxb_artifact_spring (
    artifact_id uuid NOT NULL,
    spring_status text DEFAULT 'active'::text NOT NULL,
    spawned_count integer DEFAULT 0 NOT NULL,
    last_spawned_at timestamp with time zone,
    spring_context jsonb,  -- Flexible context/metadata
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT qxb_artifact_spring_pkey PRIMARY KEY (artifact_id),
    CONSTRAINT qxb_artifact_spring_artifact_id_fkey
      FOREIGN KEY (artifact_id)
      REFERENCES qxb_artifact(artifact_id)
      ON DELETE CASCADE,
    CONSTRAINT qxb_artifact_spring_status_check
      CHECK ((spring_status = ANY (ARRAY['active'::text, 'dormant'::text, 'archived'::text])))
);

COMMENT ON TABLE qxb_artifact_spring IS
  'Spring type table extending qxb_artifact. Idea-origin artifacts that spawn seeds/saplings. No lifecycle stages (always generative). RLS enabled; policies added later (deny-by-default).';
```

### Fields Explanation

**spring_status:**
- `active` - Spring is generating ideas / spawning projects
- `dormant` - Spring is temporarily inactive but may reactivate
- `archived` - Spring is no longer relevant

**spawned_count:**
- Tracks how many seeds/saplings have been spawned from this Spring
- Incremented when a new project references this Spring as its origin

**last_spawned_at:**
- Timestamp of most recent seed/sapling spawned from this Spring

**spring_context (jsonb):**
- Flexible metadata about the Spring's context
- Could include: themes, focus areas, related resources, inspiration sources

---

## Parent-Child Semantics

### Existing (Beta V1)
```
Thicket (parent)
  └─ Project (child)
       └─ Project (grandchild)
```

### With Springs (Phase 2+)
```
Thicket (parent)
  ├─ Spring (child) ← Idea-origin artifact
  │    └─ [spawns] → Seed/Sapling (separate artifact, references Spring)
  └─ Project (child)
```

**Key difference:** Springs **spawn** projects (via reference), they don't **contain** them hierarchically.

A spawned seed/sapling could have:
- `parent_artifact_id` = thicket (for organizational hierarchy)
- `spring_origin_id` = spring artifact_id (for conceptual lineage)

This requires adding a new field: `spring_origin_id` to `qxb_artifact` (nullable).

---

## Gateway Support (Phase 2+)

### New Actions

**`spring.create`**
- Creates a Spring artifact
- Sets spring_status = 'active'
- Initializes spawned_count = 0

**`spring.spawn`**
- Creates a new seed/sapling project
- Sets the new project's `spring_origin_id` = Spring's artifact_id
- Increments Spring's spawned_count
- Updates Spring's last_spawned_at timestamp

**`spring.list`**
- Lists all Springs in workspace
- Can filter by spring_status (active / dormant / archived)

**`spring.query`**
- Retrieves a Spring + list of spawned projects

---

## Migration Path (When Implementing Phase 2+)

1. **Schema Changes**
   - Add 'spring' to artifact_type enum
   - Create qxb_artifact_spring extension table
   - Add spring_origin_id to qxb_artifact (nullable)
   - Add RLS policies for qxb_artifact_spring

2. **Gateway Changes**
   - Add spring.create, spring.spawn, spring.list, spring.query actions
   - Update Gateway Contract to include Spring actions
   - Add Spring-specific validation logic

3. **Data Migration**
   - Identify existing restart artifacts that represent "Spring" concepts
   - Optionally migrate to Spring artifact type
   - Update any spawned projects to reference their Spring origin

4. **Documentation**
   - Update Artifact Schema Canon with Spring type
   - Add Spring semantics to user guides
   - Update Qwrk Conversation Contract if Spring spawning is user-facing

---

## Why Excluded from Beta V1

**Reasons:**
1. **Schema complexity** - Requires artifact_type enum change + new extension table
2. **Semantic model extension** - Adds new parent-child relationship pattern (spawn vs contain)
3. **Gateway dependency** - Needs new actions and validation logic
4. **Baseline stability** - Beta should lock down existing artifact types before adding new ones
5. **User complexity** - Introduces new mental model (Spring vs Project) that needs careful onboarding

**Current workaround (Beta V1):**
- Use Restart artifacts to capture "Spring-like" ideas
- Manually reference restart artifact_id when creating related seeds/saplings
- Track conceptual lineage in project summaries or tags

---

## Design Questions (To Resolve Before Implementation)

1. **Should Springs be workspace-scoped or user-scoped?**
   - Current design: workspace-scoped (like projects)
   - Alternative: user-scoped (like journals)

2. **Can Springs have children other than projects?**
   - Can a Spring spawn journals, snapshots, or other artifact types?
   - Current design: Only seeds/saplings (projects)

3. **Should Springs support lifecycle stages?**
   - Current design: No lifecycle (always generative)
   - Alternative: Introduce spring_status as a lightweight lifecycle

4. **How to represent "spawned from" in UI?**
   - Lineage visualization
   - Spring → Projects graph
   - Breadcrumb trail showing Spring origin

5. **Should spawning be automatic or manual?**
   - Automatic: When creating a seed, prompt "Is this spawned from a Spring?"
   - Manual: Explicit `spring.spawn` action
   - Current design: Manual (explicit control)

---

## References

**Origin Restart:**
- Artifact ID: `2a8a5719-4734-4cd1-9fa1-3880a430c3a1`
- Title: "Spring Capture — Qwrk as the Prefrontal Cortex of Automation"
- Date: 2026-01-07

**Related Documents:**
- Beta V1 Exclusions: `docs/saplings/core-build-cycle/2026-01-06__beta-readiness__governance-contract-locks__5da2d196-f8ec-4458-af9e-178ce72a09b7.md`
- Seed Project: `5bca1db6-27eb-4272-ae34-f68b91a8685e` (already exists in QB)
- Brand Narrative: `docs/snapshots/AAA_New_Qwrk__Snapshot__Brand_Narrative_v1__2026-01-05.md` (includes prefrontal cortex metaphor)

---

## Status

**Phase:** Design Concept (Phase 2+)
**Implementation:** Blocked until Beta V1 is complete and artifact schema is locked
**Next Steps:** Resolve design questions, create detailed implementation plan when ready for Phase 2

---

**Version:** v1
**Date:** 2026-01-07
**Owner:** Master Joel

---
