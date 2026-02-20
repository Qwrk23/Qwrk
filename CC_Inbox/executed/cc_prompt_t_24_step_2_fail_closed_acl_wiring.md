# CC Prompt — T24 Step 2 — Fail-Closed ACL Wiring (Clone Only)

## Objective
Wire ACL enforcement into the cloned Gateway workflow in a strictly fail-closed manner.

This step introduces runtime ACL gating while preserving the existing OWNER_WORKSPACE_ID hard lock.

NO production workflow modification.
NO removal of hard lock yet.

---

## Context (Locked Architectural Stance)

Kernel Model (Qwrk Prime):
- Gateway enforces workspace isolation.
- service_role credential retained.
- Fail-closed behavior mandatory.

Production RLS enforcement is explicitly deferred.

We are implementing Gateway-layer ACL enforcement only.

---

## Required Wiring (Clone Workflow Only)

### Insert Order

1. `Normalize_Request`
2. `ACL_Lookup` (HTTP Request — already built)
3. `ACL_Guard__HasRow` (NEW IF node)
4. Existing `Gatekeeper_MVP_OwnerOnly`

Do NOT remove Gatekeeper hard lock yet.

---

## ACL_Guard__HasRow — Fail-Closed Logic (CRITICAL)

Node Type:
- IF

Allow Condition (ONLY condition that passes):

Expression must explicitly evaluate:

- Response exists
- Response is an array
- Array length >= 1

Pseudo-expression requirement:

```
Array.isArray($json) && $json.length >= 1
```

TRUE branch:
→ Continue to existing Gatekeeper

FALSE branch (ALL other conditions):
→ Return 403 envelope

This includes:
- Empty array
- null
- undefined
- Non-array object
- HTTP error response
- Timeout
- Any unexpected shape

There must be NO implicit truthy checks.

---

## 403 Response Node

Create deterministic error envelope:

```
{
  "ok": false,
  "_gw_route": "error",
  "error": {
    "code": "ACL_FORBIDDEN",
    "message": "Principal not authorized for requested workspace"
  },
  "gw_workspace_id": "{{ $json.gw_workspace_id }}",
  "artifact_type": "{{ $json.artifact_type }}",
  "_kgb": {
    "status": "ACL_DENIED"
  }
}
```

All ACL failures must terminate here.

---

## Critical Safeguards

1. Do NOT remove OWNER_WORKSPACE_ID hard lock.
2. Do NOT alter existing error routing.
3. Do NOT modify any Save/Update/List/Query workflows.
4. Do NOT activate clone workflow yet.
5. Do NOT merge back to production.

---

## Validation Scenarios (Must Test)

### Test 1 — Allowed principal + allowed workspace
Expected:
- Pass ACL_Guard
- Then fail at Gatekeeper (if not owner workspace)
- Confirm ACL layer does not override hard lock yet

### Test 2 — Allowed principal + disallowed workspace
Expected:
- Fail at ACL_Guard
- Return 403 ACL_FORBIDDEN

### Test 3 — Simulated malformed ACL response
Temporarily break URL or force bad shape.
Expected:
- Fail-closed
- Return 403 ACL_FORBIDDEN

No scenario should allow unauthorized workspace access.

---

## Required Output

Respond with:

1. Updated clone workflow JSON snippet (ACL wiring section only)
2. IF node expression used
3. Results of all 3 validation tests
4. Confirmation OWNER_WORKSPACE_ID lock untouched
5. Confirmation fail-closed behavior verified

Stop after reporting.

No production activation yet.

