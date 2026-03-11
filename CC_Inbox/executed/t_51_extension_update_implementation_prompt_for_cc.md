# T51 — Branch / Limb / Leaf Extension Update Implementation

## Objective
Implement deterministic extension update behavior for the following artifact types:

- branch
- limb
- leaf

Current state: routing intentionally fail-closed via `Return_Unimplemented_Type_Error`.
Goal: implement full extension update path equivalent in structure to project, but targeting execution anatomy types.

---

# Required Changes

## 1️⃣ Update Routing

Node:
`NQxb_Artifact_Update_v1__Switch_Type_For_Update`

Replace routing for:
- branch
- limb
- leaf

From:
- `NQxb_Artifact_Update_v1__Return_Unimplemented_Type_Error`

To:
- `Prepare_Branch_Extension_Update`
- `Prepare_Limb_Extension_Update`
- `Prepare_Leaf_Extension_Update`

Each must route to its own DB update node.

---

## 2️⃣ Implement Prepare_[Type]_Extension_Update (Code Nodes)

For each type, create a code node that:

- Extracts extension fields from `_normalized_request`
- Validates allowed fields
- Rejects empty extension
- Returns update payload

### Allowed Fields (v1 scope)
- execution_status (required if updating extension)
- execution_notes (optional, if column exists)

### Validation Rules

- If no allowed fields present → return VALIDATION_ERROR
- No silent drops
- No unknown field pass-through

### Output Shape

Must return:

```
{
  artifact_id,
  execution_status?,
  execution_notes?
}
```

---

## 3️⃣ DB Update Nodes

Create Supabase update nodes:

| Type   | Table                     |
|--------|---------------------------|
| branch | qxb_artifact_branch       |
| limb   | qxb_artifact_limb         |
| leaf   | qxb_artifact_leaf         |

Filter:

- artifact_id = eq.[artifact_id]

Update fields:

- execution_status
- execution_notes (if present)

Must use same deterministic pattern as project update.

No return-dependent logic.

---

## 4️⃣ Spine Version Increment

After extension update:

Reuse existing nodes:

- `NQxb_Artifact_Update_v1__Prepare_Spine_Version_Increment`
- `NQxb_Artifact_Update_v1__DB_Increment_Spine_Version`

Version must increment exactly +1.

---

## 5️⃣ Terminal Node

Reuse:

`NQxb_Artifact_Update_v1__Return_Update_Ack`

Requirements:

- ok: true
- operation: "UPDATE"
- updated_fields: Object.keys(extension)
- deterministic envelope

No hydration query.

---

# Close Criteria (T51 Complete)

For branch / limb / leaf:

- Extension table row updates correctly
- Spine version increments
- Correct routing
- Deterministic acknowledgement
- No spine corruption
- No silent success
- No UPDATE_NOT_IMPLEMENTED errors

---

# Constraints

- Fail-closed design preserved
- No widening of mutability rules
- No lifecycle_stage mutation
- No tags logic changes
- No schema modification in this thread

---

# Deliverable

Updated `NQxb_Artifact_Update_v1` workflow with:

- Branch, Limb, Leaf extension write paths implemented
- No regressions in project path
- All error nodes preserved
- Deterministic behavior maintained

End of spec.

