# PRD — Opportunity Management v0 (Hybrid Frame)

---

## 1. Executive Intent (Strategic Layer)

### Purpose
Establish a governed execution system for managing opportunities inside Qwrk using existing QPM primitives.

The subsystem must:
- Increase execution clarity
- Enforce lifecycle discipline
- Surface political and execution risk early
- Avoid premature schema mutation
- Remain expandable into a future product subsystem

### Design Principles

- **Lifecycle disciplined** — Strict adherence to seed → sapling → tree → archive
- **Execution-first** — Forward motion prioritized over documentation
- **Intelligence evolves organically** — Narrative before structure
- **No premature enforcement** — Discipline without bureaucracy
- **Expandable by design** — Future-proofed for Phase C/D evolution

### Phase Target

- **Phase A:** Personal clarity and execution discipline
- **Future Phase C:** Predictability and political foresight
- **Future Phase D:** Productized subsystem capability

---

## 2. Scope (Operational Layer)

### In Scope (v0)

- Lifecycle gating rules
- Sapling structural blueprint
- Tree promotion trigger
- Tree expansion checklist
- Review workflow command
- Risk logic (⚠ No Next Action)
- On Hold convention
- Close Strategy activation rules

### Out of Scope (v0)

- CRM integration
- Probability scoring
- Automation enforcement
- Rolling memory integration
- Dashboard layer
- Artifact type mutation
- Schema expansion

---

## 3. Lifecycle Model

### 3.1 Seed

**Trigger:**
- Discovery invite
- Awareness event
- Early inbound/outbound signal

**Behavior:**
- Lightweight project creation
- No branches
- Minimal structure

Seeds are cheap. Promotion requires signal.

---

### 3.2 Sapling

**Promotion Criteria:**
- Defined problem
- Named stakeholder
- Mutual next step scheduled

**Required Structure:**

Branch 1 — Opp Intelligence (Living)
Branch 2 — Execution

Sapling marks committed pursuit.

---

### 3.3 Tree

**Promotion Criteria (Buyer Behavior Driven):**
- NDA executed
- PoV / PoC initiated
- Security review triggered
- RFP issued
- Procurement involved
- Defined evaluation timeline

**Behavior:**
- Promote via Gateway
- Create "Tree Expansion Checklist – <Account>" journal
- Activate additional branches deliberately
- No auto branch creation

Tree reflects external validation, not internal optimism.

---

## 4. Structural Blueprint

### 4.1 Opp Intelligence (Living Branch)

#### Default Limbs
- Account Context
- Stakeholder Map
- Problem & Outcomes
- Deal Signals Log

#### Optional Limb
- Close Strategy
  - Available at Sapling
  - Required to exist at Tree
  - Narrative-only in v0

#### Close Strategy Definition (v0)
Narrative articulation of the political path to yes.

It should implicitly answer at least one of:
- Who ultimately says yes?
- What must happen for them to say yes?
- What could stop them?

No structured fields in v0.

---

### Intelligence Update Discipline

After meaningful call:

1. Save linked journal (deep intelligence capture)
2. Summarize insights into Intelligence limbs
3. Add 1–3 Deal Signal entries max

Signal discipline > note hoarding.

---

### 4.2 Execution Branch

#### Rules
- One limb per motion
- Leaves = atomic actions
- Exactly one visible Next Action per opportunity
- "ON HOLD – <reason>" leaf allowed

#### Governance
Every active opportunity must:

- Have a clear Next Action
- OR be explicitly On Hold
- OR surface ⚠ No Next Action

Parallel motion may exist, but only one Next Action is visible at opportunity level.

Constraint is intentional.

---

## 5. Review Workflow

### Command
"Let’s review our opps."

### System Behavior

- Filter: tags = sales, opportunity
- Exclude archived
- Sort by updated_at DESC

Display per opportunity:
- Title
- Lifecycle
- Last Updated
- Next Action Preview:
  - Action
  - ⏸ On Hold
  - ⚠ No Next Action
- Close Strategy Status (narrative awareness)

Close Strategy surfaces as:
- 🧭 Clear Path Identified
- ⚠ Political Risk
- ❓ Unknown Buyer Path
- 🔁 Champion Dependent
- 🧱 Procurement Barrier

No automation required in v0.

---

## 6. Tree Expansion Protocol

Upon Tree promotion:

Create linked journal:
"Tree Expansion Checklist – <Account>"

Checklist determines activation of:
- PoV branch
- RFP branch
- Security branch
- Procurement branch
- Close Strategy limb (if not already active)

Branch activation remains deliberate.

No automatic structural expansion.

---

## 7. Risk Logic & Soft Gate

### Close Strategy Soft Gate (Sapling → Tree)

If Close Strategy status is:
- ❓ Unknown Buyer Path
- 🔁 Champion Dependent
- ⚠ Political Risk

Promotion to Tree is allowed.

System surfaces:

⚠ Tree without Political Clarity

No blocking.
No artificial gating.
Signal only.

---

## 8. Data Classification Strategy

### v0
Tag-based filtering:
- sales
- opportunity
- contextual tags (resolve, qwrk, partnership, etc.)

No artifact_type mutation.

### Future
Potential structured type:
- type = opportunity

Tags remain contextual, not structural.

---

## 9. Future Evolution Hooks

- Explicit Next Action metadata
- Structured operational_state
- Probability scoring
- Rolling Registry integration
- Automated signal extraction from journals
- UI dashboard layer
- Productized template instantiation engine
- Opportunity artifact_type (if required)

---

## 10. Architectural Position

This subsystem is architected generically.

It supports:
- Resolve sales
- Enterprise Qwrk deals
- Partnerships
- Expansion motions
- Strategic pursuits

Deployment may be scoped.
Structure remains universal.

---

## Summary

Opportunity Management v0 defines a governed execution system built entirely from existing QPM primitives.

It enforces:
- Lifecycle discipline
- Execution clarity
- Political awareness
- Risk visibility

Without introducing:
- Schema mutation
- Automation complexity
- CRM bloat

This is Qwrk Sales OS v0.

Lean.
Governed.
Expandable.