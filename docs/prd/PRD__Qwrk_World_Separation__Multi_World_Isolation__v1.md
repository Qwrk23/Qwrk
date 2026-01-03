# PRD — Qwrk World Separation: Multi-World Isolation v1

**Status**: 🟢 **APPROVED** (Pending Phase 1 scheduling)
**Created**: 2026-01-02
**Approved**: 2026-01-02
**Owner**: Master Joel
**Phase Alignment**: Phase 2+ (Post-Kernel v1)

> **Naming Note**: This feature was originally termed "Domain Separation" in early drafts. Renamed to "Qwrk World Separation" to avoid confusion with ServiceNow's "Domain Separation" feature and align with Qwrk's terminology (Worlds, Forests, Thickets, Trees).

---

## 1. Purpose

Define a **Qwrk World separation** model that extends Qwrk's multi-tenancy architecture to support:
- **Beta users** (and eventually regular users) with **elevated build privileges** scoped to their world only
- **Data isolation** at the world level, preventing cross-world visibility
- **System-wide records** accessible across all worlds (e.g., templates, shared resources)
- **Immutable world assignment** on all relevant artifacts and records

This feature enables controlled delegation of Qwrk Build capabilities while maintaining strict data boundaries.

---

## 2. Motivation

### Problem Statement

**Current State (Kernel v1)**:
- Multi-tenancy operates at the **workspace level** only
- All users with elevated privileges have system-wide access
- No mechanism to grant "builder" capabilities to users while restricting their scope
- Cannot safely allow beta users to create/manage artifacts without full system access

**Desired State (Post-World Separation)**:
- Beta users can build within their assigned world
- Users only see artifacts and data within their world(s)
- System administrators can create world-agnostic resources (templates, shared configs)
- Clear data boundaries prevent accidental cross-world contamination

### Use Cases

**UC-1: SELECT Beta User with Build Privileges** *(Future - Not Initial Beta)*
- **IMPORTANT**: Initial beta users will have `member` role (read-only)
- Build privileges (`builder` role) granted to SELECT beta users only (future phase)
- User belongs to Qwrk World: "ACME Corp"
- User has role: `builder` within their world
- Can create/modify projects, journals, snapshots, restarts within "ACME Corp" world
- Cannot see or access artifacts in Qwrk World: "XYZ Inc"
- Cannot see or modify system-wide records (read-only access)

**UC-2: System Administrator Creating Shared Template**
- Admin creates a project template with `world_id = NULL` (system-wide)
- All worlds can read/clone this template
- No world can modify system-wide records (except system admins)

**UC-3: Multi-World User**
- User belongs to Qwrk World A and Qwrk World B (via workspace memberships)
- Can see artifacts from both worlds, properly segregated
- Cannot mix data across worlds (world_id is immutable)

---

## 3. Architecture Overview

### Hierarchy Model

```
System (Global)
  └── Qwrk World (Isolation Boundary)
      └── Workspace (Collaboration Unit)
          └── Artifact (Data)
```

**Key Principles**:
1. **Qwrk World** is the primary isolation boundary
2. **Workspace** remains the collaboration unit (unchanged from Kernel v1)
3. **Every workspace belongs to exactly one Qwrk World**
4. **Artifacts inherit world_id from their workspace** (immutable)
5. **System-wide records** have `world_id = NULL`

### Qwrk World Characteristics

- **Immutable Assignment**: Once created, `world_id` cannot be changed
- **Mandatory Scoping**: All artifacts must have either a `world_id` or be system-wide (NULL)
- **RLS Enforcement**: World membership controls visibility via RLS policies
- **Role-Based Privileges**: World-level roles grant capabilities within world scope

---

## 4. Data Model

### New Table: `qxb_world`

```sql
CREATE TABLE IF NOT EXISTS public.qxb_world (
  world_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_slug TEXT NOT NULL UNIQUE, -- e.g., "acme_corp", "system" (reserved)
  display_name TEXT NOT NULL,       -- e.g., "ACME Corporation"
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_system_world BOOLEAN NOT NULL DEFAULT false, -- Reserved for system-wide resources
  CONSTRAINT qxb_world_system_slug_reserved
    CHECK (NOT is_system_world OR world_slug = 'system')
);

COMMENT ON TABLE public.qxb_world IS
  'Qwrk World-level isolation boundary. Workspaces belong to exactly one world. System-wide resources use is_system_world = true.';

COMMENT ON COLUMN public.qxb_world.world_slug IS
  'URL-safe world identifier (immutable after creation).';
COMMENT ON COLUMN public.qxb_world.is_system_world IS
  'True for system-wide world (world_slug = "system"). Only one system world allowed.';

ALTER TABLE public.qxb_world ENABLE ROW LEVEL SECURITY;
```

### New Table: `qxb_world_user`

```sql
CREATE TABLE IF NOT EXISTS public.qxb_world_user (
  world_user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID NOT NULL,
  user_id UUID NOT NULL,
  world_role TEXT NOT NULL DEFAULT 'member'
    CHECK (world_role IN ('owner', 'admin', 'builder', 'member')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT qxb_world_user_world_fk
    FOREIGN KEY (world_id) REFERENCES public.qxb_world (world_id),
  CONSTRAINT qxb_world_user_user_fk
    FOREIGN KEY (user_id) REFERENCES public.qxb_user (user_id),
  CONSTRAINT qxb_world_user_unique_membership
    UNIQUE (world_id, user_id)
);

COMMENT ON TABLE public.qxb_world_user IS
  'Qwrk World membership and role assignment. Users may belong to multiple worlds.';

COMMENT ON COLUMN public.qxb_world_user.world_role IS
  'World-level role: owner (full control), admin (manage users/workspaces), builder (create/modify artifacts), member (read-only).';

ALTER TABLE public.qxb_world_user ENABLE ROW LEVEL SECURITY;
```

### Schema Changes: Add `world_id` to Existing Tables

**Tables Requiring `world_id` Field**:

1. **`qxb_workspace`** (workspaces belong to exactly one world)
```sql
ALTER TABLE public.qxb_workspace
  ADD COLUMN world_id UUID NOT NULL
  REFERENCES public.qxb_world (world_id);

COMMENT ON COLUMN public.qxb_workspace.world_id IS
  'Qwrk World this workspace belongs to (immutable).';
```

2. **`qxb_artifact`** (artifacts inherit world from workspace)
```sql
ALTER TABLE public.qxb_artifact
  ADD COLUMN world_id UUID
  REFERENCES public.qxb_world (world_id);

COMMENT ON COLUMN public.qxb_artifact.world_id IS
  'Qwrk World inherited from workspace (immutable). NULL for system-wide artifacts.';

-- Constraint: world_id must match workspace.world_id
ALTER TABLE public.qxb_artifact
  ADD CONSTRAINT qxb_artifact_world_matches_workspace
  CHECK (
    world_id IS NULL OR
    world_id = (SELECT world_id FROM public.qxb_workspace WHERE workspace_id = qxb_artifact.workspace_id)
  );
```

3. **`qxb_artifact_event`** (audit events inherit world from artifact)
```sql
ALTER TABLE public.qxb_artifact_event
  ADD COLUMN world_id UUID
  REFERENCES public.qxb_world (world_id);

COMMENT ON COLUMN public.qxb_artifact_event.world_id IS
  'Qwrk World inherited from artifact (immutable). NULL for system events.';
```

**Tables NOT requiring `world_id`**:
- `qxb_user` — Users exist globally, world membership via `qxb_world_user`
- Extension tables (`qxb_artifact_project`, etc.) — World inherited via FK to `qxb_artifact`

---

## 5. Qwrk World Roles & Privileges

### Role Definitions

| Role | Capabilities | Use Case |
|------|--------------|----------|
| **owner** | Full world control (delete world, manage admins, all builder/member privileges) | World creator, primary stakeholder |
| **admin** | Manage world users, create/delete workspaces, all builder/member privileges | Trusted administrators |
| **builder** | Create/modify artifacts, create workspaces, all member privileges | Beta users, power users with build capabilities |
| **member** | Read artifacts, participate in workspaces (if workspace member) | Standard users, viewers |

### Privilege Matrix

| Operation | owner | admin | builder | member |
|-----------|-------|-------|---------|--------|
| Create workspace in world | ✅ | ✅ | ✅ | ❌ |
| Delete workspace | ✅ | ✅ | ❌ | ❌ |
| Add/remove world users | ✅ | ✅ | ❌ | ❌ |
| Create artifacts in world | ✅ | ✅ | ✅ | ❌ |
| Update artifacts (owned/workspace) | ✅ | ✅ | ✅ | ❌ |
| Read artifacts in world | ✅ | ✅ | ✅ | ✅ |
| Delete world | ✅ | ❌ | ❌ | ❌ |

**System-wide artifacts**:
- All world users can READ system-wide artifacts (world_id = NULL)
- Only system administrators can CREATE/UPDATE system-wide artifacts

---

## 6. RLS Policy Design

### World Visibility Policy (qxb_artifact)

```sql
-- Users can see artifacts in worlds they belong to OR system-wide artifacts
CREATE POLICY qxb_artifact_select_world_member
  ON public.qxb_artifact
  FOR SELECT
  USING (
    world_id IS NULL OR -- System-wide artifacts
    world_id IN (
      SELECT world_id
      FROM public.qxb_world_user
      WHERE user_id = public.qxb_current_user_id()
    )
  );
```

### World Write Policy (qxb_artifact)

```sql
-- Users can create artifacts if they have builder+ role in world
CREATE POLICY qxb_artifact_insert_world_builder
  ON public.qxb_artifact
  FOR INSERT
  WITH CHECK (
    world_id IN (
      SELECT world_id
      FROM public.qxb_world_user
      WHERE user_id = public.qxb_current_user_id()
        AND world_role IN ('owner', 'admin', 'builder')
    )
  );
```

### Workspace World Constraint

```sql
-- Workspaces can only be created in worlds where user has builder+ role
CREATE POLICY qxb_workspace_insert_world_builder
  ON public.qxb_workspace
  FOR INSERT
  WITH CHECK (
    world_id IN (
      SELECT world_id
      FROM public.qxb_world_user
      WHERE user_id = public.qxb_current_user_id()
        AND world_role IN ('owner', 'admin', 'builder')
    )
  );
```

---

## 7. System-Wide Records

### Definition

**System-wide records** are artifacts/resources accessible across all worlds:
- Templates (project templates, workflow templates)
- Shared configuration (future)
- Reference data (future)

### Characteristics

- `world_id = NULL` (not associated with any world)
- Created by system administrators only
- **Read-only** for all world users
- **Cloneable** into world-scoped artifacts (creates new artifact with world_id)

### Example: Project Template

```json
{
  "artifact_id": "template-123",
  "workspace_id": "system-workspace-456",
  "world_id": null,
  "artifact_type": "project",
  "title": "Standard Project Template",
  "owner_user_id": "system-admin-789",
  "extension": {
    "is_template": true,
    "lifecycle_stage": "seed"
  }
}
```

When user clones:
- New artifact created with user's `workspace_id` (which has `world_id`)
- New artifact inherits `world_id` from workspace
- Original template remains system-wide

---

## 8. Migration Strategy

### Backward Compatibility

**For existing Kernel v1 deployments**:

1. **Create default world**: "Primary World" (slug: `primary`)
2. **Migrate all workspaces** to `world_id = <primary_world_id>`
3. **Migrate all artifacts** to inherit `world_id` from workspace
4. **Assign world roles** based on workspace roles:
   - Workspace owners → World owners
   - Workspace admins → World admins
   - Workspace members → World members

### Migration SQL (Conceptual)

```sql
-- Step 1: Create default world
INSERT INTO public.qxb_world (world_id, world_slug, display_name)
VALUES (gen_random_uuid(), 'primary', 'Primary World')
RETURNING world_id;

-- Step 2: Update all workspaces
UPDATE public.qxb_workspace
SET world_id = '<primary_world_id>';

-- Step 3: Update all artifacts
UPDATE public.qxb_artifact
SET world_id = (
  SELECT world_id
  FROM public.qxb_workspace
  WHERE workspace_id = qxb_artifact.workspace_id
);

-- Step 4: Migrate workspace_user roles to world_user
INSERT INTO public.qxb_world_user (world_id, user_id, world_role)
SELECT DISTINCT
  w.world_id,
  wu.user_id,
  CASE
    WHEN wu.role = 'owner' THEN 'owner'
    WHEN wu.role = 'admin' THEN 'admin'
    ELSE 'member'
  END
FROM public.qxb_workspace_user wu
JOIN public.qxb_workspace w ON wu.workspace_id = w.workspace_id;
```

---

## 9. Gateway Integration

### Request Envelope Changes

**Add optional `world_id` filter** to `artifact.list`:

```json
{
  "gw_action": "artifact.list",
  "gw_workspace_id": "workspace-123",
  "selector": {
    "world_id": "world-456",  // Optional: filter by world
    "include_system_wide": true  // Optional: include world_id = NULL
  }
}
```

### Validation Rules

**artifact.create**:
- Validate user has `builder+` role in target workspace's world
- Auto-populate `world_id` from workspace
- Reject attempts to set `world_id` explicitly (computed field)

**artifact.update**:
- Reject any attempt to modify `world_id` (immutable)
- Return error: `IMMUTABLE_FIELD_ERROR` with field: `world_id`

**artifact.query**:
- RLS automatically enforces world visibility
- Return `NOT_FOUND` if artifact exists but user lacks world access

---

## 10. UI/UX Implications

### Qwrk World Selector

**For multi-world users**:
- UI displays "Current Qwrk World" selector
- Switching worlds filters all artifact lists
- Clear visual indicator of current world context

**For single-world users**:
- World selector hidden
- World context implicit

### Build Capability Badge

**For users with `builder` role**:
- Display "Builder" badge in world context
- Enable create/modify operations
- Show build-specific UI elements (templates, advanced options)

**For users with `member` role**:
- Hide build capabilities
- Read-only interface
- "Request Builder Access" prompt (future enhancement)

---

## 11. Open Questions & Decisions Needed

### Q1: Can workspaces be moved between worlds?

**Options**:
- ❌ **No** (strict immutability) — Simpler, clearer boundaries
- ✅ **Yes, with admin approval** — Flexibility for org changes
- ⚠️ **Yes, but creates snapshot history** — Audit trail preserved

**DECISION (2026-01-02)**: ❌ **NO** — Workspaces cannot move between worlds (strict immutability).

**HOWEVER**: Workspaces CAN add collaborators from OTHER worlds via `qxb_workspace_user`. This enables cross-world collaboration at the workspace level without breaking world isolation.

**Example**:
- Workspace belongs to Qwrk World A (immutable)
- World A user invites World B user as workspace member
- World B user can now access THIS workspace (but not other World A workspaces)
- All artifacts created in workspace inherit World A's `world_id`

---

### Q2: Can users belong to multiple worlds?

**Options**:
- ✅ **Yes** (via `qxb_world_user` many-to-many) — Supports consultants, multi-org users
- ❌ **No** (one world per user) — Simpler, but limits flexibility

**DECISION (2026-01-02)**: ✅ **YES** — Users can belong to multiple worlds via `qxb_world_user`.

**Use cases**: Consultants, contractors, multi-organization employees, cross-world collaboration.

**RLS impact**: Users see artifacts from ALL worlds they belong to (via world membership OR workspace collaboration).

---

### Q3: How are system administrators designated?

**Options**:
- **Special world role**: `system_admin` (new role)
- **Membership in system world**: User belongs to `world_slug = 'system'`
- **Supabase service role**: Bypass RLS entirely

**DECISION (2026-01-02)**: ✅ **Membership in system world** (`world_slug = 'system'`)

**CRITICAL CONSTRAINT**: System admins can manage system-wide resources BUT **CANNOT read world content** unless they are also members of those worlds.

**Clarification**:
- System admin in "system" world → can create system-wide templates, manage global settings
- System admin accessing Qwrk World A content → must be added as member of World A
- RLS enforces strict world visibility (no automatic admin override)

**Rationale**: Prevents accidental cross-world data exposure; preserves privacy boundaries.

---

### Q4: Can artifacts reference cross-world artifacts?

**Options**:
- ❌ **No** (strict isolation) — Prevents data leakage
- ✅ **Yes, if both worlds permit** (future: world-to-world sharing)
- ⚠️ **Yes, for system-wide artifacts only** — One-way dependency (world → system)

**DECISION (2026-01-02)**: ⚠️ **System-wide artifacts only** for v1.

**Allowed**:
- World artifacts can reference system-wide artifacts (world_id = NULL)
- Example: World project clones system-wide template

**Blocked**:
- Qwrk World A artifacts cannot reference World B artifacts
- Cross-world sharing deferred to Phase 3+ (requires explicit collaboration model)

**Rationale**: Prevents data leakage; maintains strict world boundaries.

---

### Q5: What happens when a world is deleted?

**Options**:
- **Cascade delete**: Delete all workspaces, artifacts, users (destructive)
- **Soft delete**: Mark `deleted_at`, hide from UI (recoverable)
- **Prevent delete**: Require explicit workspace/artifact cleanup first

**DECISION (2026-01-02)**: 🛑 **PREVENT** — World deletion blocked until all workspaces and artifacts are removed.

**Enforcement**:
- Database constraint: Cannot delete world if workspaces exist
- UI: Display workspace/artifact count before delete attempt
- Error message: "World cannot be deleted. Remove all workspaces first."

**Rationale**: Safest approach; prevents accidental data loss; explicit cleanup required.

---

## 12. Phase 1 Design Review Required

**Before implementing Phase 1**, the following design edges must be addressed and documented:

### Edge 1: Cross-World Collaborator Artifact Ownership

**Issue**: When World B user joins World A workspace and creates artifact, artifact gets `world_id = World A` (inherited from workspace). Creator's world affiliation may cause audit trail confusion.

**Design questions**:
- How do we track creator's world membership in audit events?
- Should artifact display "created by World B user in World A workspace"?
- Do we need `creator_world_id` field separate from `artifact.world_id`?

**Priority**: MEDIUM — Affects audit trail clarity

---

### Edge 2: System-Wide Artifact Creation Controls

**Issue**: PRD states "system administrators only" can create system-wide artifacts (`world_id = NULL`), but no explicit RLS policy prevents World A admin from attempting this.

**Design questions**:
- Add RLS INSERT policy: Only users in system world can create `world_id = NULL` artifacts?
- Or: Gateway validation only (RLS allows, Gateway blocks)?
- What error code for unauthorized system-wide creation attempt?

**Priority**: HIGH — Security boundary

---

### Edge 3: Builder Role Scope Too Broad

**Issue**: `builder` role can create workspaces in world. Even SELECT beta users could spawn unlimited workspaces.

**Design questions**:
- Should `builder` include workspace creation, or separate `workspace_creator` privilege?
- Should workspace creation require admin approval for builders?
- Do we need workspace quotas even for builders?

**Priority**: MEDIUM — Abuse prevention

---

### Edge 4: World Quotas Critical for Beta

**Issue**: Currently deferred to Phase 4, but without quotas, beta world can create unlimited artifacts/workspaces.

**Design questions**:
- Should basic quotas (max artifacts, max workspaces) be part of Phase 1?
- Hard limits (block creates) or soft limits (warn but allow)?
- Who sets quotas (system admin, world owner)?

**Priority**: HIGH — Resource control for beta

**Recommendation**: Move basic quota enforcement to Phase 2 (after Phase 1 Schema, before Phase 3 UI)

---

### Edge 5: Multi-World UX — Implicit Context

**Issue**: User in 3 worlds creates artifact — which world? Answer: determined by workspace. Users may not understand this implicit behavior.

**Design questions**:
- How does UI communicate "current workspace context"?
- Does artifact creation dialog show "will be created in Qwrk World X"?
- Can users accidentally create in wrong world?

**Priority**: MEDIUM — UX clarity (Phase 3 concern, document now)

**Recommendation**: Define explicit context indicator in UI mockups before Phase 3 build

---

## 13. Implementation Phases

### Phase 1: Schema + RLS (Foundation)

**Deliverables**:
- Create `qxb_world` and `qxb_world_user` tables
- Add `world_id` to `qxb_workspace`, `qxb_artifact`, `qxb_artifact_event`
- Implement RLS policies for world visibility
- Migration script for existing deployments

**Success Criteria**:
- KGB tests pass with world isolation enforced
- Multi-world user can see artifacts from both worlds
- Single-world user cannot see cross-world artifacts

---

### Phase 2: Gateway + Workflows (Build Capabilities)

**Deliverables**:
- Update Gateway workflows to respect world boundaries
- Add world validation to `artifact.create` / `artifact.update`
- Add `world_id` filter to `artifact.list`
- Error handling for world permission violations

**Success Criteria**:
- Builder role can create artifacts in their world
- Member role cannot create artifacts (blocked by RLS)
- System-wide artifacts visible to all worlds

---

### Phase 3: UI + World Management (User-Facing)

**Deliverables**:
- Qwrk World selector UI component
- World user management (invite, role assignment)
- Builder badge / capability indicators
- World creation workflow (admin only)

**Success Criteria**:
- Multi-world users can switch context seamlessly
- Admins can invite users with builder role
- Clear visual indication of current world

---

### Phase 4: System-Wide Templates (Advanced)

**Deliverables**:
- Template cloning workflow
- System world creation + management
- Template library UI

**Success Criteria**:
- System admin can create templates
- World users can clone templates into their world
- Cloned artifacts inherit world_id correctly

---

## 14. Risks & Mitigations

### Risk 1: Migration Complexity

**Risk**: Existing deployments may have complex workspace structures that don't map cleanly to worlds.

**Mitigation**:
- Provide migration dry-run script
- Default to single "Primary World" for backward compatibility
- Document manual world splitting process for advanced users

---

### Risk 2: RLS Performance Impact

**Risk**: Adding world checks to RLS policies may degrade query performance.

**Mitigation**:
- Add index on `qxb_artifact.world_id`
- Add index on `qxb_world_user (user_id, world_id)`
- Profile queries pre/post migration
- Consider materialized view for user-world memberships if needed

---

### Risk 3: Cross-World Collaboration Requests

**Risk**: Users may need to share artifacts across worlds (future requirement).

**Mitigation**:
- Design assumes strict isolation for v1
- Document cross-world sharing as Phase 3+ enhancement
- System-wide artifacts provide one-way sharing pattern as interim solution

---

### Risk 4: Workspace-World Mismatch

**Risk**: Artifacts could be created with incorrect world_id if workspace.world_id changes.

**Mitigation**:
- Make `workspace.world_id` immutable (constraint)
- Make `artifact.world_id` immutable (constraint)
- Gateway auto-populates world_id from workspace (no manual input)

---

## 15. Success Metrics

**Post-Implementation (Phase 2)**:
1. ✅ 100% of artifacts have valid `world_id` (or NULL for system-wide)
2. ✅ 0 cross-world visibility violations in RLS audit
3. ✅ Beta users with builder role can create artifacts
4. ✅ Beta users cannot see artifacts outside their world
5. ✅ Migration script completes without data loss

**Post-UI (Phase 3)**:
6. ✅ Multi-world users successfully switch worlds in UI
7. ✅ World admins successfully invite users with builder role
8. ✅ Builder badge displayed correctly based on role

---

## 16. Future Enhancements (Out of Scope)

### World-to-World Sharing

**Concept**: Allow controlled sharing of artifacts across worlds via explicit sharing rules.

**Example**:
- Qwrk World A creates a project template
- World A admin grants "read" access to World B
- World B users can clone (but not modify) the template

**Requirements**:
- New table: `qxb_world_share`
- Sharing permissions: `read` | `clone` | `fork`
- RLS policy updates to check sharing table

---

### World Quotas & Limits

**Concept**: Enforce per-world resource limits (max artifacts, max workspaces, storage).

**Example**:
- Free tier: 100 artifacts per world
- Pro tier: 10,000 artifacts per world
- Enterprise: unlimited

**Requirements**:
- Add `quota` fields to `qxb_world`
- Gateway validation on `artifact.create`
- Usage tracking dashboard

---

### World Analytics

**Concept**: Aggregated metrics per world (artifact counts, active users, storage usage).

**Example**:
- World dashboard showing: 45 projects, 12 active users, 2.3 GB storage

**Requirements**:
- Analytics aggregation queries
- Materialized views for performance
- World admin UI panel

---

## 17. References

### Kernel v1 Architecture

- **Workspace Model**: `QXB Table Design Files/AAA_New_Qwrk__Schema__Qxb_Workspace__v1.0__2025-12-30.sql`
- **Workspace Membership**: `QXB Table Design Files/AAA_New_Qwrk__Schema__Qxb_Workspace_User__v1.0__2025-12-30.sql`
- **RLS Policies**: `QXB Table Design Files/AAA_New_Qwrk__RLS_Patch__Kernel_v1__v1.2__2025-12-30.sql`
- **Artifact Schema**: `QXB Table Design Files/AAA_New_Qwrk__Schema__Qxb_Artifact__v1.0__2025-12-30.sql`

### Governance

- **Mutability Registry**: `Mutability_Registry_v1.md`
- **CLAUDE.md**: Governance rules for schema changes

### Related PRDs

- **Operational Knowledge Sync**: `PRDs/PRD__Operational_Knowledge_Sync__Qwrk_to_CC_GitHub__v1.md` (mentions "scope exclusions")

### Naming Reference

- **ServiceNow Domain Separation**: This feature intentionally uses different terminology ("Qwrk World") to avoid confusion with ServiceNow's enterprise multi-tenancy feature of the same name.

---

## 18. CHANGELOG

### v1 - 2026-01-02

**What changed:**
- Created initial Qwrk World separation PRD
- Defined world model: world > workspace > artifact hierarchy
- Specified world roles: owner, admin, builder, member
- Designed schema changes: `qxb_world`, `qxb_world_user`, `world_id` field additions
- Outlined RLS policies for world isolation
- Documented system-wide artifact pattern
- Proposed 4-phase implementation plan
- Identified open questions and risks

**Why:**
- Enable beta users to have build capabilities scoped to their world
- Provide strict data isolation at world level
- Support future multi-world deployments
- Preserve workspace model from Kernel v1

**Scope of impact:**
- Schema: Major additions (2 new tables, 3 field additions)
- RLS: Policy updates required for all artifact tables
- Gateway: Validation and filtering logic updates
- UI: World selector, role indicators (Phase 3)
- Migration: Required for existing deployments

**Phase alignment:**
- Phase 1 (Schema): Post-Kernel v1, pre-Phase 2
- Phase 2-4: Phased rollout aligned with Structure Layer (Forest/Thicket)

**How to validate:**
- Review schema design for conflicts with Kernel v1
- Review RLS policies for correctness
- Discuss open questions (Q1-Q5) with stakeholders
- Approve phase plan and migration strategy
- Create world separation snapshot when approved for build

**Status**: 🟢 **APPROVED** — Pending Phase 1 scheduling (Post-Kernel v1)

### v1.1 - 2026-01-02 (Approval Update)

**Decisions finalized**:
1. **Q1 - Workspace mobility**: NO workspace moves; YES cross-world collaborators via workspace membership
2. **Q2 - Multi-world users**: YES — Users can belong to multiple worlds
3. **Q3 - System admins**: YES — Via system world membership; CANNOT read world content without explicit membership
4. **Q4 - Cross-world references**: NO — Only system-wide artifacts (world → system, one-way)
5. **Q5 - World deletion**: PREVENT — Require cleanup first

**Beta user clarification**:
- Initial beta users: `member` role (read-only)
- Build privileges (`builder` role): SELECT beta users only (future phase)

**Approval status**: Ready for Phase 1 implementation (Post-Kernel v1 completion)

**Next steps**:
1. Schedule Phase 1 (Schema + RLS) after Kernel v1 KGB passes
2. Create Qwrk World separation snapshot when implementation begins
3. Review RLS policy design with stakeholders

### v1.2 - 2026-01-02 (Naming Update)

**What changed:**
- Renamed from "Domain Separation" to "Qwrk World Separation"
- Updated all technical terminology: `domain_*` → `world_*`
- Updated schema: `qxb_domain` → `qxb_world`, `qxb_domain_user` → `qxb_world_user`
- Updated field names: `domain_id` → `world_id`, `domain_slug` → `world_slug`, etc.
- File renamed: `PRD__Domain_Separation__Multi_Domain_Isolation__v1.md` → `PRD__Qwrk_World_Separation__Multi_World_Isolation__v1.md`

**Why:**
- Avoid confusion with ServiceNow's "Domain Separation" feature (major enterprise product)
- Align with Qwrk's existing terminology (Worlds, Forests, Thickets, Trees)
- Establish unique, defensible naming for Qwrk's isolation model

**Scope of impact:**
- All documentation updated
- Schema names changed (before implementation)
- No code impact (feature not yet built)

**Old terminology preserved**:
- "life domains" (Forest concept) remains unchanged — refers to Forest categories, not isolation boundaries

---

**End of PRD**
