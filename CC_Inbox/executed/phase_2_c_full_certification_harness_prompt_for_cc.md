# PROMPT — Build Reusable Phase 2C Black-Box Certification Harness (Gateway Only)

## INTENT
Build a reusable PowerShell-based regression and certification harness that tests the live Gateway endpoint as a pure black-box surface.

This harness must:
- Call ONLY the live Gateway endpoint (no internal n8n workflow calls)
- Execute deterministic happy-path + fuzz tests
- Capture raw responses
- Perform structured assertions
- Produce machine-readable + human-readable findings
- Be reusable for future regressions

No workflow edits.
No schema edits.
No deployment actions.
Testing only.

---

# 1️⃣ Directory Structure

Create the following structure:

```
/Phase2C_Cert/
    Run-Phase2C-Cert.ps1
    /tests/
        01_journal_insert.json
        02_project_insert.json
        03_project_tag_update.json
        ...
    /results/
        /raw/
        summary.csv
        findings.md
```

The harness must be reusable for future releases (Phase 3, Phase 4, etc.).

---

# 2️⃣ Gateway Configuration

Inside Run-Phase2C-Cert.ps1 define:

- `$GatewayUrl`
- `$WorkspaceId`
- `$RunTimestamp`

Do NOT hardcode credentials.
Allow endpoint override via parameter.

---

# 3️⃣ Test File Format

Each test JSON file must include:

```
{
  "name": "Journal INSERT — Valid",
  "expected": {
    "ok": true,
    "error_code": null
  },
  "payload": { ... actual gateway payload ... }
}
```

For negative tests:

```
"expected": {
  "ok": false,
  "error_code": "VALIDATION_ERROR"
}
```

---

# 4️⃣ Required Test Groups

## Group A — Happy Path

Journal
- INSERT valid
- QUERY by artifact_id
- TAG update

Project
- INSERT seed
- UPDATE tags.add/remove
- UPDATE extension.state_reason
- Promote blocked
- Add linked journal
- Promote allowed

Snapshot
- INSERT valid
- UPDATE attempt (must fail — immutability)

Restart
- INSERT valid
- UPDATE attempt (must fail — immutability)

---

## Group B — Fuzz / Contract Enforcement

F1 — Stringified extension
F2 — Tags as comma string
F3 — Unknown extension key
F4 — Missing required extension field
F5 — Unknown gw_action
F6 — Invalid UUID in query

All must assert correct error code and structure.

---

# 5️⃣ Assertion Rules

The script must validate:

- `extension` always returns as object
- `tags` always return as array
- `version` increments by exactly 1 on update
- Promote transitions only when allowed
- Error responses contain:
  - `ok: false`
  - `error.code`
  - Stable error shape

On systemic failure (e.g., extension returned as string), abort run.

---

# 6️⃣ PowerShell Execution Logic

For each test:
1. Load test file
2. POST via `Invoke-RestMethod`
3. Save raw JSON response to `/results/raw/`
4. Evaluate assertions
5. Append result row to summary.csv

CSV Columns:

| TestName | Expected | Actual | Pass | Notes |

---

# 7️⃣ Findings Report (Auto-Generated)

Create findings.md with:

```
# Phase Certification Report
Timestamp:
Gateway Version:
Save Version:

## Summary
Total Tests:
Passed:
Failed:

## Failures
...

## Observations
...

## Conclusion
PASS / FAIL
```

---

# 8️⃣ Determinism Requirements

- Tests must run sequentially
- No parallel execution
- Suite must be runnable multiple times
- Must cleanly handle artifact IDs generated during run

---

# 9️⃣ Safety Constraints

Do NOT:
- Modify workflows
- Modify database
- Modify registry
- Modify MEMORY.md

Testing only.

---

# 10️⃣ Deliverable

Provide:
- Completed PowerShell script
- Complete /tests/ library
- Sample summary.csv
- Sample findings.md

No execution. Build only.

