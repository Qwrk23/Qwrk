# Mutability Gaps — Decision Packet (v1)

**Version**: 1
**Created**: 2026-01-02
**Status**: Open
**Purpose**: Formally document unresolved mutability decisions requiring explicit policy locks

---

## Default Policy (Until Decisions Made)

**BLOCK_UNTIL_DECIDED**

All fields/artifacts with unresolved mutability policies should be blocked from UPDATE operations until an explicit, locked decision is documented and enforced via Mutability Registry v2+.

**Rationale**: Safe default prevents inconsistent behavior and ensures deliberate design choices rather than accidental permissions.

---

## Decision 1: Are project.tags Mutable?

**Current Status**: Mutability Registry v1 does not explicitly address `tags` field (spine-level field, all artifact types)

**Question**: Should users be allowed to UPDATE the `tags` field on project artifacts (and potentially other artifact types)?

### Options

#### Option A: IMMUTABLE (CREATE_ONLY)
Tags can only be set at artifact creation. No updates allowed.

**Tradeoffs**:
- ✅ **Pro**: Simple semantics, prevents tag drift, audit trail preserved
- ✅ **Pro**: Clear categorization at creation time
- ❌ **Con**: Users cannot recategorize artifacts as project evolves
- ❌ **Con**: Typos in tags cannot be corrected
- ❌ **Con**: Organizational taxonomy changes require creating new artifacts

#### Option B: MUTABLE with REPLACE semantics
Tags can be updated by replacing entire tags object.

**Implementation**: User provides new tags object, which fully replaces existing tags.

**Tradeoffs**:
- ✅ **Pro**: Simple update logic (no merge complexity)
- ✅ **Pro**: Users can recategorize artifacts
- ✅ **Pro**: Typo correction possible
- ❌ **Con**: Risk of accidentally removing tags if partial update intended
- ❌ **Con**: No audit trail of tag history (unless versioning added later)

#### Option C: MUTABLE with MERGE semantics
Tags can be updated by merging provided keys with existing tags.

**Implementation**:
- User provides partial tags object
- Provided keys overwrite existing values
- Unprovided keys remain unchanged
- Special handling for array-valued tags (append vs replace?)

**Tradeoffs**:
- ✅ **Pro**: PATCH-like flexibility (only change what's needed)
- ✅ **Pro**: Lower risk of accidental tag removal
- ❌ **Con**: More complex merge logic, especially for nested/array values
- ❌ **Con**: Ambiguity about array merging (append vs replace)
- ❌ **Con**: Higher implementation complexity

#### Option D: BLOCK_UNTIL_DECIDED (Recommended Default)
Block all tags UPDATE operations until explicit decision is made.

**Tradeoffs**:
- ✅ **Pro**: Safe, prevents accidental permissions
- ✅ **Pro**: Forces deliberate design choice
- ❌ **Con**: Users cannot update tags at all (must recreate artifacts)

### Decision Criteria

Consider:
- How critical is tag recategorization to user workflow?
- Is tags field used for filtering/search (high stakes) or just metadata (lower stakes)?
- What is the expected tags schema (flat key-value vs nested vs arrays)?
- Should tag history be preserved for audit purposes?

**Recommended Default**: **Option D (BLOCK_UNTIL_DECIDED)** until requirements are clear.

---

## Decision 2: Are project.summary and project.priority Mutable?

**Current Status**: Mutability Registry v1 does not explicitly address `summary` or `priority` fields (spine-level fields)

**Question**: Should users be allowed to UPDATE `summary` and `priority` on project artifacts?

### Options

#### Option A: IMMUTABLE (CREATE_ONLY)
Summary and priority can only be set at artifact creation. No updates allowed.

**Tradeoffs**:
- ✅ **Pro**: Enforces upfront planning, prevents scope drift
- ✅ **Pro**: Preserves original project intent
- ❌ **Con**: Projects evolve; preventing updates is restrictive
- ❌ **Con**: Typos cannot be corrected
- ❌ **Con**: Priority cannot be adjusted as needs change

#### Option B: MUTABLE (UPDATE_ALLOWED with PATCH semantics)
Summary and priority can be updated independently.

**Implementation**:
- If `summary` provided in UPDATE, replace summary
- If `priority` provided in UPDATE, replace priority
- If not provided, leave unchanged (PATCH semantics)

**Tradeoffs**:
- ✅ **Pro**: Flexible, allows project metadata to evolve
- ✅ **Pro**: Typo correction and reprioritization possible
- ✅ **Pro**: Aligns with typical project management workflows
- ❌ **Con**: No audit trail of summary/priority history (unless versioning added)
- ❌ **Con**: Risk of losing original intent if frequently updated

#### Option C: BLOCK_UNTIL_DECIDED (Recommended Default)
Block all summary/priority UPDATE operations until explicit decision is made.

**Tradeoffs**:
- ✅ **Pro**: Safe, prevents accidental permissions
- ✅ **Pro**: Forces deliberate design choice
- ❌ **Con**: Users cannot update project metadata (must recreate artifacts)

### Sub-Decision: If Mutable, Should There Be Constraints?

If Option B chosen:
- **summary**: String length limits? Non-empty constraint?
- **priority**: Integer range constraint (e.g., 1-5)? Require justification for changes?
- **Audit trail**: Should updates be logged separately (e.g., in timeline/history table)?

### Decision Criteria

Consider:
- Are summary/priority considered "metadata" (flexible) or "core identity" (immutable)?
- How frequently will users need to update these fields?
- Is priority used for critical workflows (e.g., auto-scheduling) or just sorting?
- Should original values be preserved for audit/history?

**Recommended Default**: **Option C (BLOCK_UNTIL_DECIDED)** until workflow requirements are clear.

---

## Decision 3: Is Journal Append-Only or Patchable?

**Current Status**: Mutability Registry v1 marks journal as `UNDECIDED_BLOCKED`. Doctrine "Journal INSERT-ONLY (Temporary)" enforces append-only behavior until decision is locked.

**Question**: Should journal artifacts be permanently append-only (immutable), or should users be allowed to edit existing journal entries?

### Options

#### Option A: PERMANENTLY APPEND-ONLY (CREATE_ONLY)
Journal artifacts are fully immutable after creation. No updates allowed.

**Semantic Model**: Journals as "frozen reflections" — once written, entries become historical record.

**Tradeoffs**:
- ✅ **Pro**: Preserves authenticity (entries reflect state at time of writing)
- ✅ **Pro**: Privacy-friendly (users can trust past entries won't be retroactively altered)
- ✅ **Pro**: Audit trail integrity (no tampering with history)
- ✅ **Pro**: Aligns with "append-only log" mental model
- ❌ **Con**: Typos cannot be corrected (must create new entry)
- ❌ **Con**: No way to delete embarrassing/sensitive entries
- ❌ **Con**: Requires "correction by appending" pattern

**User Pattern**: To correct/amend previous entry, create new journal artifact with `parent_artifact_id` linking to original.

#### Option B: PATCHABLE (UPDATE_ALLOWED with constraints)
Users can edit existing journal entries with restrictions.

**Sub-Options** (if Option B chosen):

##### B1: Full Edit (entry_text + payload mutable)
Both `entry_text` and `payload` can be updated via PATCH semantics.

**Tradeoffs**:
- ✅ **Pro**: Maximum flexibility, typo correction easy
- ✅ **Pro**: Users can refine/expand entries over time
- ❌ **Con**: Loss of authenticity (what was originally written?)
- ❌ **Con**: Privacy concern (did I really write this, or edit it later?)
- ❌ **Con**: Requires audit trail/versioning to preserve history

##### B2: Metadata-Only Edit (payload mutable, entry_text immutable)
Only `payload` (tags, mood, structured data) can be updated. Entry text is frozen.

**Tradeoffs**:
- ✅ **Pro**: Preserves core entry text as written
- ✅ **Pro**: Allows metadata corrections (fix tags, update mood)
- ❌ **Con**: Typos in entry_text still cannot be corrected
- ❌ **Con**: Added complexity (field-level mutability rules)

##### B3: Time-Bounded Edit (updates allowed within X hours/days)
Users can edit journal entries only within a grace period (e.g., 24 hours after creation).

**Tradeoffs**:
- ✅ **Pro**: Balances flexibility (typo correction) with authenticity (eventual immutability)
- ✅ **Pro**: Aligns with "cooling off" period before entries become permanent
- ❌ **Con**: Requires timestamp-based enforcement logic
- ❌ **Con**: Adds state complexity (mutable → immutable transition)
- ❌ **Con**: Users may rush to edit before deadline

#### Option C: BLOCK_UNTIL_DECIDED (Current Default)
Block all journal UPDATE operations until explicit decision is made.

**Status**: This is the current enforced behavior via "Doctrine: Journal INSERT-ONLY (Temporary)".

**Tradeoffs**:
- ✅ **Pro**: Safe default, prevents accidental permissions
- ✅ **Pro**: Buys time for user feedback and design refinement
- ❌ **Con**: Users cannot correct typos or update entries at all

### Decision Criteria

Consider:
- What is the primary use case for journals? (private reflection? collaboration? notes?)
- How important is authenticity/audit trail vs. flexibility/UX?
- Are journals owner-private only, or can they be shared? (privacy implications)
- Should deleted/edited journal entries leave a trace (soft delete/edit history)?
- User feedback: Do users expect journals to be editable or frozen?

**Recommended Default**: **Option C (BLOCK_UNTIL_DECIDED)** until user requirements and semantic model are clear.

---

## Decision Process (When Ready to Lock)

For each decision above, the following steps are required:

1. **User Research/Feedback**: Gather input from Master Joel and/or actual users about workflow needs
2. **Design Decision Document**: Create versioned spec (e.g., `Decision__Project_Tags_Mutability__v1.0__YYYY-MM-DD.md`)
3. **Document Rationale**: Explain chosen option, tradeoffs accepted, and rejected alternatives
4. **Update Mutability Registry**: Publish Mutability Registry v2 with explicit rules for decided fields/types
5. **Update Workflows**: Modify `NQxb_Artifact_Update_v1` (or successor) to enforce new rules
6. **KGB Regression**: Verify existing artifacts are not broken by new policy
7. **Master Joel Approval**: Final sign-off per truth hierarchy
8. **Close Decision**: Mark decision as "LOCKED" in Decision Packet v2

---

## Summary Table

| Decision | Field/Type | Current Status | Options | Recommended Default |
|----------|-----------|----------------|---------|---------------------|
| **1** | project.tags | Not addressed | A: CREATE_ONLY<br>B: REPLACE<br>C: MERGE<br>D: BLOCK | **D: BLOCK_UNTIL_DECIDED** |
| **2** | project.summary, project.priority | Not addressed | A: CREATE_ONLY<br>B: UPDATE_ALLOWED<br>C: BLOCK | **C: BLOCK_UNTIL_DECIDED** |
| **3** | journal (all fields) | UNDECIDED_BLOCKED | A: CREATE_ONLY<br>B1: Full edit<br>B2: Metadata-only<br>B3: Time-bounded<br>C: BLOCK | **C: BLOCK_UNTIL_DECIDED** (current) |

---

## Related Documents

- **Mutability_Registry_v1.md** - Current locked registry (does not address these gaps)
- **Doctrine_Journal_InsertOnly_Temporary.md** - Temporary enforcement for Decision 3
- **NQxb_Artifact_Update_v1.json** - Workflow enforcing current blocks
- **CLAUDE.md** - Governance rules for decision-making and registry updates

---

## Snapshot Reference

This decision packet has been formalized as an immutable snapshot artifact:

**File**: `Mutability_Gaps_Decision_Packet_v1.snapshot.json`
**Artifact Type**: snapshot
**Title**: "Mutability Gaps — Decision Packet (v1)"

To save this packet to Qwrk, use `artifact.create` workflow with the snapshot payload.

---

**End of Decision Packet v1**
