# Claude Code Execution Prompt

## Objective

Upgrade the Save sub-workflow from v29 to v30 by embedding strict Journal extension validation directly inside the workflow JSON.

No manual n8n editing.

You will:
1. Modify the existing workflow JSON file.
2. Inject strict journal validation logic into the Validate_Request node.
3. Increment version metadata to v30.
4. Archive the v29 file.
5. Output the full upgraded JSON as a new file ready for import.

---

## Source File (Current Live Version)

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Artifact_Save_v1 (29).json

---

## Target Output

New file:

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\NQxb_Artifact_Save_v1 (30).json

Archive current file to:

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\workflows\Archive\NQxb_Artifact_Save_v1__v29__ARCHIVED.json

If Archive folder does not exist, create it.

---

# Required Modifications

## 1️⃣ Inject Strict Journal Validation

Locate node:

"NQxb_Artifact_Save_v1__Validate_Request"

Replace its entire jsCode block with the following implementation.

---

### STRICT VALIDATION CODE (REPLACE ENTIRE jsCode)

```javascript
const input = $json;

if (!input.gw_action) {
  return [{
    ok: false,
    error: "VALIDATION_ERROR",
    message: "Missing gw_action"
  }];
}

if (!input.artifact_type) {
  return [{
    ok: false,
    error: "VALIDATION_ERROR",
    message: "Missing artifact_type"
  }];
}

// STRICT JOURNAL VALIDATION
if (input.artifact_type === "journal") {
  const ext = input.extension;

  if (!ext || typeof ext !== "object") {
    return [{
      ok: false,
      error: "VALIDATION_ERROR",
      code: "JOURNAL_EXTENSION_INVALID",
      message: "Journal artifacts require extension.entry_text (non-empty string)."
    }];
  }

  const keys = Object.keys(ext);

  if (keys.length !== 1 || !keys.includes("entry_text")) {
    return [{
      ok: false,
      error: "VALIDATION_ERROR",
      code: "JOURNAL_EXTENSION_INVALID",
      message: "Journal extension must contain exactly one field: entry_text."
    }];
  }

  if (typeof ext.entry_text !== "string" || ext.entry_text.trim().length === 0) {
    return [{
      ok: false,
      error: "VALIDATION_ERROR",
      code: "JOURNAL_EXTENSION_INVALID",
      message: "extension.entry_text must be a non-empty string."
    }];
  }
}

return [input];
```

---

## 2️⃣ Remove Journal payload Writes

Locate journal INSERT node:

"DB_Insert_Journal_Extension1"

Ensure it writes ONLY:

```
entry_text
```

Remove any reference to:

```
payload
```

Journal saves must no longer write to the payload column.

Do NOT modify table structure.

---

## 3️⃣ Version Bump

Inside workflow JSON:

- Update workflow name to:
  "NQxb_Artifact_Save_v1 (30)"

- If metadata.version exists, increment from 29 to 30.

---

## 4️⃣ Do NOT Modify

- Routing
- Update branch logic
- Switch nodes
- Supabase credentials
- Other artifact types
- Lifecycle logic

Only inject strict journal validation + remove payload write.

---

# Verification Requirements

After generating v30 JSON, confirm:

- Journal save with extension.entry_text passes.
- Journal save with extension.entry fails.
- Journal save with empty entry_text fails.
- Snapshot save unaffected.

---

# Output Requirements

1. Confirm archive file created.
2. Confirm new v30 file created.
3. Provide absolute paths of both files.
4. Do not modify any other workflows.

Execute precisely. No scope expansion.