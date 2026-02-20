# Design Memo — Design Sandbox Access Model for Aesthetic Collaboration

**Status:** Design Complete — Awaiting Workspace Creation
**Seed Project:** `f761db4f-b05c-4315-bcad-3b6b25cefe54`
**Milestone Snapshot:** `2180b740-eac9-4ec7-92fa-894a496ad415`
**Phase:** Crawl (planning container only)
**Constraint:** No DDL, no ACL, no execution types, no registry mutation

---

## CHANGELOG

### v1 — 2026-02-15

**What changed:** Initial design memo for Akara collaboration access model.

**Why:** Akara joins Team Qwrk as Devil's Advocate of Aesthetics. Need to define a safe collaboration model that preserves Prime sovereignty while enabling aesthetic experimentation.

**Scope of impact:** Architecture/UX design decision. Recommends Sandbox Forest model. No schema changes, no new types, no ACL enforcement.

**How to validate:** Create sandbox workspace (3 INSERTs), save test artifact, verify isolation from Prime.

---

## Preamble: Akara's Execution Surface

Akara is an AI persona (Devil's Advocate of Aesthetics), not a Supabase auth user. Akara operates through Joel's auth credentials. "Access" means: where do Akara's artifacts land, what can Akara see, and how is Akara's work isolated from Prime governance. All Gateway interactions are mediated through Joel's existing auth.

---

## A. Access Models (Comparative)

### Model 1: Sandbox Forest

**Description:** Create a new workspace (forest) dedicated to design experimentation. Akara's feedback, prototypes, and aesthetic reviews are saved as artifacts in this workspace. Prime workspace (`be0d3a48`) is untouched.

| Dimension | Assessment |
|-----------|-----------|
| **Sovereignty impact** | **Zero.** Prime workspace is never written to by Akara. Complete isolation at the workspace boundary. |
| **Phase boundary compliance** | **Full.** Uses existing primitives: `qxb_workspace` + `qxb_workspace_user`. No new types, no registry changes. Workspace creation is an INSERT into existing tables. |
| **ACL implications** | **None.** Joel is owner of both workspaces. Existing RLS isolates workspace data by membership. No multi-user ACL needed — Joel mediates all access. Gateway ACL row needed only if Gateway must route to new workspace (one INSERT into `qxb_gateway_acl`). |
| **Scalability** | **Good.** Additional demographic testers (future personas) get their own sandbox forests or share Akara's. One workspace per collaboration axis is clean. |
| **Reversibility** | **High.** Delete workspace_user entry, then workspace. All artifacts are contained. Git-like clean cut. |
| **Blast radius** | **Contained.** Only the sandbox forest is affected by any experimentation. Prime data is never exposed. |

---

### Model 2: Scoped Head Under Prime

**Description:** Akara operates within the Prime workspace but artifacts are scoped by convention (tags, naming prefix, or parent_artifact_id under a designated "sandbox" project).

| Dimension | Assessment |
|-----------|-----------|
| **Sovereignty impact** | **Medium.** Akara's artifacts live alongside governance artifacts in Prime. Convention-based separation is not enforceable at the schema level. |
| **Phase boundary compliance** | **Partial.** No schema changes needed, but relies on behavioral discipline (correct tags, correct parent). A single mis-tagged save pollutes Prime's artifact space. |
| **ACL implications** | **Risky.** Joel's auth has full owner access to Prime. Any artifact saved in Prime by Akara-mediated action is indistinguishable from Joel's own governance work at the RLS level. Fine-grained scoping requires ACL enforcement (T24 — not built, blocked). |
| **Scalability** | **Poor.** Additional testers multiply the convention-enforcement burden. Tag-based isolation doesn't scale without automation. |
| **Reversibility** | **Medium.** Artifacts mixed into Prime require identification and cleanup. No clean workspace-level boundary to cut at. |
| **Blast radius** | **Prime workspace.** A bad save, wrong tag, or missed convention writes directly into the governance-protected artifact space. |

---

### Model 3: Artifact Mirroring

**Description:** Akara works in a separate workspace. Selected Prime artifacts are manually copied (mirrored) to Akara's workspace for review. Akara's feedback returns as new artifacts (snapshots, journals) in the sandbox workspace.

| Dimension | Assessment |
|-----------|-----------|
| **Sovereignty impact** | **Low.** Prime is read-source only. Copies are inert — no back-propagation to Prime. |
| **Phase boundary compliance** | **Full.** Uses existing artifact types (snapshot for copies, journal for feedback). No new types or registry changes. |
| **ACL implications** | **None.** Same as Sandbox Forest — Joel mediates all mirroring. No multi-user access required. |
| **Scalability** | **Manual burden.** Every artifact Akara needs to review must be copied. Grows linearly with review volume. No automation permitted in Crawl phase. |
| **Reversibility** | **High.** Mirrored copies are in sandbox workspace. Delete workspace = clean. |
| **Blast radius** | **Contained.** Same as Sandbox Forest for writes. But the mirroring process introduces operational friction and copy-staleness risk. |

---

### Model 4: External UX Prototype Layer

**Description:** Akara operates entirely outside the Qwrk system. Design work happens in external tools (Figma, Canva, documents). Joel manually captures relevant feedback as Qwrk artifacts when decisions are made.

| Dimension | Assessment |
|-----------|-----------|
| **Sovereignty impact** | **Zero.** No system interaction whatsoever. |
| **Phase boundary compliance** | **Full.** Nothing touches schema, registry, or workflows. |
| **ACL implications** | **None.** No system access. |
| **Scalability** | **Unlimited externally, bottlenecked at ingestion.** Joel is the sole bridge between external work and Qwrk artifacts. |
| **Reversibility** | **Full.** Nothing in system to reverse. |
| **Blast radius** | **Zero.** |

**Limitation:** Akara never builds familiarity with Qwrk's artifact model. Aesthetic feedback is disconnected from the artifacts it references. Demographic testing can't operate on actual Qwrk data shapes. This model treats Akara as an external consultant, not a team member.

---

## B. Recommended Model: Sandbox Forest

**Model 1 — Sandbox Forest** is the recommended access model.

**Rationale:**

| Requirement | Sandbox Forest |
|-------------|---------------|
| Preserves Prime sovereignty | Yes — workspace-level isolation, zero write exposure to Prime |
| Enables aesthetic experimentation | Yes — Akara's workspace accepts any Crawl-legal artifact types |
| Allows demographic contrast testing | Yes — artifacts in sandbox can reference Prime artifacts by ID without modifying them |
| Avoids ACL footguns | Yes — Joel owns both workspaces, existing RLS handles isolation, no multi-user ACL needed |
| Avoids phase boundary violations | Yes — uses existing `qxb_workspace` + `qxb_workspace_user`, no new types or registry changes |
| Avoids premature schema changes | Yes — zero DDL mutation |
| Aligns with future multi-user architecture | Yes — when ACL is implemented (T24), sandbox workspaces become the natural multi-user segmentation unit |

**Why not the others:**
- **Model 2 (Scoped Head):** Sovereignty risk. Unenforceable without ACL. Convention-based isolation is fragile.
- **Model 3 (Mirroring):** Operationally correct but manual burden is high and scales poorly. If mirroring were automated, this would be Model 1 with extra steps.
- **Model 4 (External):** Disconnects Akara from the artifact model. Aesthetic feedback that can't reference artifact shapes is less useful.

---

## C. Minimal Next Build Step

**The smallest reversible action that moves this seed forward:**

Create a "Design Sandbox" workspace and seed Gateway access.

This requires **3 INSERTs** into existing tables (no DDL, no schema mutation, no new types):

1. **`qxb_workspace`** — Create workspace named "Design Sandbox" (or "Akara Sandbox")
2. **`qxb_workspace_user`** — Add Joel as `owner` of the new workspace
3. **`qxb_gateway_acl`** — Add `qwrk-gateway` principal access to the new workspace_id

All three use existing table structures. All three are reversible via DELETE. No execution types activated. No registry modified.

After these 3 rows exist:
- Joel can save artifacts into the sandbox workspace via Chrome Extension
- Akara-mediated feedback becomes artifacts in an isolated forest
- Prime workspace is untouched
- CC can query the sandbox workspace via Gateway (read-only)

---

## D. Explicitly Deferred

| Item | Reason for Deferral |
|------|-------------------|
| Execution types (leaf, branch, limb) | Not active in registry. Phase 2B Walk prerequisite. |
| DDL mutation | No schema changes required for Sandbox Forest model. |
| New artifact types | Sandbox uses existing types (project, journal, snapshot, etc.). |
| ACL rollout / multi-user auth | Joel mediates all access. ACL enforcement is T24 (blocked). When unblocked, sandbox workspaces are the natural unit for ACL segmentation. |
| Automation / scheduled workflows | Crawl phase. No automation. |
| Akara as Supabase auth user | Not needed while Joel mediates. Becomes relevant only if Akara gains independent execution surface (future, post-ACL). |
| Cross-workspace artifact references | Artifacts in sandbox can mention Prime artifact IDs in content/payload fields. Formal cross-workspace linking (FK across workspaces) is not needed and not built. |
| UI / frontend for Akara | No speculative UI. Akara interacts through the same surfaces as Q — Gateway payloads mediated by Joel. |
| Mirroring automation | If artifacts need to move from Prime to Sandbox for review, Joel copies manually. Automation deferred to post-Crawl. |
