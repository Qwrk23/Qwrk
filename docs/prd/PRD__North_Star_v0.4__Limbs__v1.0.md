# PRD — North Star v0.4: Introducing Limbs as a Structural Layer

**Version:** 1.0
**Date:** 2026-01-24
**Status:** Design Only (No Schema Execution)
**Author:** Master Joel + Claude Code
**Supersedes:** Branch/Leaf Execution Anatomy Governance Lock (2026-01-18)
**Creates:** North Star v0.4

---

## Document Governance

This PRD is a **Northstar Update** that evolves the Qwrk execution anatomy.

It is binding upon approval. It explicitly supersedes the Branch/Leaf Governance Lock dated 2026-01-18.

**Old-bull rule applies:** clarity > cleverness, governance > speed.

---

## 1. Purpose

This PRD introduces **Limbs** as a new structural layer between **Branches** and **Leaves** in Qwrk's project execution anatomy.

The goal is to improve **clarity, execution flow, and real-world project alignment** without increasing cognitive load or diluting existing lifecycle and governance semantics.

This is not a feature PRD. It is a **model-level evolution** intended to act as a binding reference for:
- Future schema design
- Execution anatomy
- Prompting and reasoning behavior
- User mental models

---

## 2. Problem Statement

Qwrk's current execution anatomy (North Star v0.3) defines:

```
Project (Tree/Sapling)
  → Branch
    → Leaf
```

While structurally sound, real projects frequently exhibit an intermediate layer of organization that is:
- Too concrete to be a Branch (strategic domain)
- Too broad to be a Leaf (single action)

This gap forces one of two suboptimal behaviors:

1. **Overloaded Branches** — Branches become dumping grounds for loosely related work, losing strategic clarity
2. **Overgrown Leaves** — Leaves expand to contain multiple actions, violating atomicity

---

## 3. Design Insight

Real execution naturally clusters as:

| Layer | Role | Granularity |
|-------|------|-------------|
| **Branch** | Strategic or functional domain | Coarse |
| **Limb** | Coherent workstream or phase | Medium |
| **Leaf** | Single executable action | Fine |

**Limbs name an existing cognitive pattern** rather than inventing a new one. When builders naturally say "the auth piece" or "the migration phase," they are describing Limbs.

---

## 4. Updated Execution Anatomy (Binding)

### Current (v0.3)
```
Project (Tree/Sapling)
  → Branch
    → Leaf
```

### New (v0.4)
```
Project (Tree/Sapling)
  → Branch
    → Limb (optional)
      → Leaf
```

### Semantic Definitions

| Artifact | Definition | Example |
|----------|------------|---------|
| **Project** | Container for goal-directed work | "Qwrk V2 MVP" |
| **Branch** | Strategic or functional module | "Backend Development" |
| **Limb** | Coherent workstream or phase within a Branch | "Authentication System" |
| **Leaf** | Single executable action | "Implement JWT token refresh" |

---

## 5. Parent/Child Governance (Binding)

### Valid Parent Relationships

| Artifact | MUST Parent To |
|----------|----------------|
| Branch | Project |
| Limb | Branch |
| Leaf | Branch OR Limb |

### Optionality Rule

**Limbs are OPTIONAL.** Simple projects may use `Branch → Leaf` directly.

The addition of Limbs does not mandate their use. The valid patterns are:

```
# Simple (no Limbs)
Project → Branch → Leaf

# Complex (with Limbs)
Project → Branch → Limb → Leaf
```

### Explicit Prohibitions (Binding)

| Rule | Rationale |
|------|-----------|
| Branch MUST NOT parent Branch | Prevents infinite nesting |
| Limb MUST NOT parent Limb | Prevents infinite nesting |
| Leaf MUST NOT parent any artifact | Leaves are terminal |
| Project MUST NOT directly parent Leaf | Enforces structure |
| Project MUST NOT directly parent Limb | Limbs require Branch context |

---

## 6. Flower Exclusion (Binding)

Flowers remain **excluded from project execution anatomy**.

| Rule |
|------|
| Flowers MUST NOT appear under Projects, Branches, Limbs, or Leaves |
| Limbs MUST NOT appear under Flowers |
| Flowers are reflective/creative artifacts, not execution structure |

This is unchanged from v0.3.

---

## 7. Backward Compatibility

**Existing `Branch → Leaf` relationships remain valid.**

Limbs are additive — no migration required. Projects created before this update continue to function without modification.

---

## 8. Lifecycle Interaction (Unchanged)

No lifecycle semantics change.

- Lifecycle applies **only to Projects** (seed → sapling → tree → retired)
- Branches, Limbs, and Leaves do not have independent lifecycle states
- Lifecycle promotion affects the Project; structure artifacts inherit context

---

## 9. Cognitive Load Assessment

| Dimension | Impact |
|-----------|--------|
| New states | None |
| New lifecycle rules | None |
| New governance axes | None |
| New required artifacts | None (Limbs are optional) |

**Verdict:** Limbs add precision without adding complexity. They name what builders already do.

---

## 10. Implementation Staging

**Phase:** Design Only (No Schema Execution)

This PRD **authorizes** the Limb concept. Schema implementation is **deferred**.

| Stage | Status |
|-------|--------|
| Conceptual model | Approved (this PRD) |
| Prompting behavior | May reference Limbs conceptually |
| Schema design (`qxb_artifact_limb`) | Deferred to future phase |
| Gateway enforcement | Deferred to future phase |
| Type Registry entry | Deferred to future phase |

**Artifact type reservation:**
- `limb` — reserved for future use (joins `branch`, `leaf` in Structure Layer)

---

## 11. Governance Documents to Update

After approval, the following must be updated:

| Document | Change |
|----------|--------|
| `docs/architecture/North_Star_v0.3.md` | Version to v0.4; add Limb to execution anatomy |
| `docs/governance/CLAUDE.md` | Update Branch/Leaf section with Limb rules |
| `docs/architecture/Phase_1-3_Kernel_Semantics_Lock.md` | Add Limb reservation (if Limb becomes Kernel type) |
| Qwrk artifact | Create governance snapshot artifact |

---

## 12. Supersession Statement

This PRD explicitly supersedes the following locked rules from 2026-01-18:

| Old Rule | New Rule |
|----------|----------|
| Leaf MUST parent only to Branch | Leaf MUST parent only to Branch OR Limb |
| (No Limb concept) | Limb MUST parent only to Branch |

All other rules from the 2026-01-18 governance lock remain in effect.

---

## 13. Non-Goals

This PRD explicitly does **not** introduce:

- Scheduling or timeline management
- Dependency graphs between Limbs
- Automated execution or orchestration
- Limb-specific lifecycle states
- Mandatory Limb usage

---

## 14. Naming Rationale

**Why "Limb"?**

| Criterion | Assessment |
|-----------|------------|
| Fits tree metaphor | Limbs grow from Branches, bear Leaves |
| Avoids overloaded terms | Not "phase," "milestone," "task," "epic" |
| Intuitive hierarchy | Branch > Limb > Leaf is natural |
| Distinct from existing types | No collision with current artifact types |

---

## 15. Summary

Limbs are a **precision addition** to Qwrk's execution anatomy that:

1. Name an existing cognitive pattern (workstreams within strategic domains)
2. Improve structural clarity without adding governance complexity
3. Remain optional — simple projects continue to work unchanged
4. Preserve all existing lifecycle and governance semantics
5. Authorize future schema implementation without requiring it now

**This is evolution, not revolution.**

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-24 | Initial PRD |

---

**End of PRD**
