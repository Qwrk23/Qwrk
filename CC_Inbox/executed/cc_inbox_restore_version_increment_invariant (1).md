# TASK: Restore Mutation Invariants (Version + Save Default Priority)

This supersedes the prior prompt limited to extension updates.

We have identified two regressions introduced during E3 hygiene cleanup:

1) Version increment invariant broken (Update + Promote paths)
2) Save workflow no longer defaulting priority (NOT NULL violation)

These must be corrected deterministically and centrally.

---

# PART A — Restore Version Increment Invariant (All Mutation Paths)

## Canonical Rule

artifact.version MUST increment by exactly +1 on ANY successful mutation:

- TAG_UPDATE
- Extension UPDATE
- Spine-level UPDATE (if allowed)
- Lifecycle PROMOTE

Version must NOT increment on:

- Validation failure
- Mutability rejection
- QPM promotion block
- No-op update
- Any failed DB operation

Version must increment exactly once per successful mutation.

---

## Scope

Workflows to review and correct if necessary:

- NQxb_Artifact_Update_v1 (12)
- NQxb_Artifact_Promote_v2_HTTP

Do NOT modify:
- Query
- Gateway routing
- Save (except Part B below)
- Mutability registry logic
- Tags-only logic (already correct)

---

## Required Architectural Outcome

Version increment must be centralized.

Preferred implementation:

All successful artifact mutations must route through a single canonical artifact UPDATE node that:

- Updates necessary fields
- Performs version = version + 1
- Executes atomically

Promote must use the same canonical artifact mutation node as Update.

No duplicate increment logic.
No parallel increment nodes.
No race conditions.

---

## Verification Checklist

After implementation confirm:

- TAG_UPDATE increments version
- Extension UPDATE increments version
- Promote increments version
- Version increments exactly once
- No increment on failed validation
- No increment on QPM block
- No increment on mutability error
- No increment on no-op
- Node IDs preserved
- Connection topology preserved
- Envelope shape unchanged

Return:

1) Summary of architectural adjustment
2) Node(s) modified
3) Exact expression used for version increment
4) Confirmation Promote and Update share canonical mutation path

---

# PART B — Restore Save Default Priority

## Regression Observed

artifact.save fails when priority not provided:

null value in column "priority" violates not-null constraint

Save previously defaulted priority (expected default: 3).

---

## Required Behavior

On artifact.save:

If priority is null or missing:
- Inject default priority = 3

This must occur BEFORE DB insert.

Do NOT:
- Modify DB schema
- Remove NOT NULL constraint
- Add DB-level default

Default must be applied at workflow layer.

---

## Verification Checklist

After fix confirm:

- Save without priority succeeds
- Saved artifact priority = 3
- Save with explicit priority still respected
- No envelope shape changes
- No routing changes
- No side effects on other artifact types

Return:

1) Node modified to inject default
2) Exact expression used
3) Confirmation default applies only when priority missing/null

---

This is a deterministic invariant restoration.

No refactoring beyond what is required.
No optimization passes.
No architectural drift.

Restore mutation integrity and save stability only.