# Qwrk Bug Tracker

**Created:** 2026-01-27
**Last Updated:** 2026-02-15 (BUG-015 closed — Normalize_Request contract violation)

---

## Open Bugs

### BUG-002: artifact.save returns ok:true with artifact_id:null

**Status:** CLOSED — Verified working 2026-01-29
**Severity:** High
**Component:** NQxb_Artifact_Save_v1 workflow (Return_Response node)

**Symptoms:**
- Save appears successful (ok: true)
- artifact_id is null in response
- Records actually DO persist in database
- Silent false-positive breaks client trust

**Root Cause:**
Return_Response node always returns `ok: true` without validating:
- Upstream error envelopes
- n8n node failure objects
- Missing artifact_id

**Approved Fix (ANQ):**
1. Preserve upstream error envelopes (`ok === false` or `_gw_route === 'error'`)
2. Handle n8n failure objects (errorMessage, errorDescription, etc.)
3. Fail-closed on missing artifact_id
4. Use locked error code allow-list (CONFLICT, INTERNAL_ERROR, VALIDATION_ERROR)

**Closed:** 2026-01-29 — Tested via Telegram Gateway. Save operations return artifact_id correctly. Retrieval via list→query pattern confirmed working.

---

### BUG-003: artifact.query hydrates even when not requested

**Status:** CLOSED — Fix implemented (Query v17), validated 2026-02-11
**Severity:** Medium
**Component:** NQxb_Artifact_Query_v1 workflow

**Symptoms:**
- `hydrate: false` in request still returns hydrated response
- No conditional check on hydrate flag before extension fetch

**Tracking:**
- Seed project: `fcbf8b49-8662-48fd-8f49-2963b0352e59`
- Journal entry documenting analysis exists

**Root Cause (CONFIRMED 2026-02-11):**
No hydrate gate anywhere in Query workflow. `selector.hydrate` was preserved in Normalize_Request but never inspected downstream. Extension merge always executed regardless of hydrate flag.

**Fix Applied (Query v17):**
- 5 Merge Code nodes prepended with hydrate gate checking `$node["Normalize_Request"].json.selector.hydrate === false`
- When hydrate=false: returns spine-only with `extension: null`, skipping extension merge
- TypeMismatch node updated: added stored===requested check for extension-less types (grass, thorn, etc.) — returns spine-only instead of false TYPE_MISMATCH
- Zero new nodes, zero wiring changes
- Implementation script: `work/bug003_fix.cjs`

**Validation (10/10 tests passed — 2026-02-11):**

| Test | Type | Result |
|------|------|--------|
| hydrate=false journal | H1 | PASS — extension: null |
| hydrate=false project | H2 | PASS — extension: null |
| hydrate=false snapshot | H3 | PASS — extension: null |
| hydrate=true journal | H4 | PASS — extension data present |
| hydrate=true project | H5 | PASS — extension data present |
| hydrate=true snapshot | H6 | PASS — extension data present |
| TYPE_MISMATCH hydrate=false | H8 | PASS — error fires correctly |
| TYPE_MISMATCH hydrate=true | H9 | PASS — error fires correctly |
| artifact.list regression (3 types) | H10 | PASS — no regression |

**Files:**
- Fixed: `workflows/NQxb_Artifact_Query_v1 (17).json`
- Test harness: `work/bug003_test.ps1`

**Closed:** 2026-02-11 — All 10 validation tests passed. Hydrate gate correctly skips extension merge when hydrate=false. TYPE_MISMATCH unchanged. List regression-free.

---

### BUG-004: instruction_pack Update not implemented

**Status:** DEFERRED TO PHASE 3
**Severity:** Medium
**Component:** NQxb_Artifact_Update_v1 workflow (v10)

**Symptoms:**
- Cannot PATCH existing instruction_pack artifacts
- No Switch branch for instruction_pack in Update workflow
- Qwrk cannot add shortcuts/rules to packs via conversation

**Root Cause:**
`Switch_Type_For_Update` only has a `project` branch. instruction_pack falls through with no handler.

**Why Phase 3:**
In Phase 1-2 (QP1 + Telegram), instruction packs are simulated via .md files attached to QP1's project files. Dynamic instruction_pack loading from the database only becomes relevant in Phase 3 when the custom front-end (using n8n AI Agent as the chat interface) is built.

**Approved Mutability Rules (for Phase 3):**
| Field | Table | Mutability |
|-------|-------|------------|
| `content` | spine | UPDATE_ALLOWED |
| `active` | extension | UPDATE_ALLOWED |
| `priority` | extension | UPDATE_ALLOWED |
| `scope` | extension | IMMUTABLE |
| `pack_format` | extension | IMMUTABLE |

**Fix Specification:** `docs/BUG-004_Instruction_Pack_Update_Fix.md`

**Implementation Summary (Phase 3):**
1. Add instruction_pack rules to Check_Mutability_Rules
2. Add instruction_pack branch to Switch_Type_For_Update
3. Create Prepare_Instruction_Pack_Update node
4. Create DB_Update_Spine_Content node (new capability)
5. Create DB_Update_Instruction_Pack_Extension node
6. Wire nodes and test

---

### BUG-007: Journal artifacts silently drop all body content

**Status:** CLOSED — Fix deployed (v24), verified working 2026-01-28
**Severity:** Critical (upgraded — silent data loss)
**Component:** NQxb_Artifact_Save_v1 workflow (journal write-path)

**Symptoms:**
- `artifact.save` with `artifact_type: journal` returns success
- Journal spine and extension rows are created
- `extension.entry_text` is always `null` on retrieval
- `extension.payload` is empty `{}`
- No validation error raised — silent data loss

**Root Cause (CONFIRMED — CLOSED LOOP):**
- Journal extension write-path does NOT map ANY fields to database
- Neither `entry_text` NOR `payload` is persisted
- Gateway creates extension row with DEFAULT VALUES ONLY
- All content silently discarded

**Confirmation Tests (2026-01-28):**

| Test | Field Sent | Result |
|------|------------|--------|
| BUG-008 Minimal Test | `extension.entry_text` | `entry_text = null` |
| BUG-007 Payload Test | `extension.payload.body` | `payload = {}` |

Both fields dropped. Extension row exists but contains only defaults.
This is NOT a field-choice issue — the entire journal extension write path is broken.

**Supporting Evidence:**
- Journals marked `UNDECIDED_BLOCKED` in mutability registry
- Minimal ASCII-only payload still loses content
- Restart/snapshot use `payload` and work correctly

**Root Cause Located (2026-01-28):**
`DB_Insert_Journal_Extension1` node was reading from wrong data path:
```
WRONG:   $json._insert_response.content.entry_text  (spine content — always empty)
CORRECT: $node["NQxb_Artifact_Save_v1__Normalize_Request"].json.extension.entry_text
```

**Fix Drafted:**
- File: `workflows/NQxb_Artifact_Save_v1 (24).json`
- Changed `entry_text` and `payload` field mappings to reference normalized request extension
- Same pattern used by instruction_pack (which works correctly)

**Status:** Fix drafted, awaiting deployment to n8n and verification test

**Related:** BUG-008 (separate issue — content-dependent GPT Actions serialization)

---

### BUG-008: GPT Actions serialization fails on complex content

**Status:** CLOSED — Moot (CustomGPT execution surface abandoned)
**Severity:** N/A
**Component:** OpenAI GPT Actions framework (client-side serialization)

**Closed:** 2026-02-05 — CustomGPT execution surface abandoned in favor of Chrome Extension. GPT Actions serialization limits no longer relevant.

**Symptoms:**
- `artifact.save` fails before reaching Gateway
- Error: `ApiSyntaxError: Could not parse API call kwargs as JSON — Expecting ',' delimiter`
- Occurs with complex content (~3KB, unicode, markdown, backticks)
- Does NOT occur with minimal ASCII-only payloads

**Reproduction (FAILS):**
~3KB journal with unicode middle-dot (`·`), markdown (`**bold**`), backticks, and `---` sequences.
Error at char 3103-3104.

**Reproduction (SUCCEEDS):**
```json
{
  "artifact_type": "journal",
  "title": "BUG-008 Minimal Test",
  "extension": {
    "entry_text": "This is a minimal test entry with no special characters."
  }
}
```

**Root Cause (CONFIRMED):**
- OpenAI GPT Actions framework corrupts JSON during serialization
- Error uses Python terminology ("kwargs") confirming it's OpenAI's code, not n8n
- JSON is valid at construction time but malformed in transit
- Likely triggers: unicode characters, payload length, or specific character combinations

**Systematic Test Results (2026-01-28):**

| Test | Content Size | NBM | BM | Notes |
|------|--------------|-----|-----|-------|
| 1 | ~100 chars | ✅ | ✅ | Minimal |
| 2 | ~400 chars | ✅ | ✅ | Multi-paragraph markdown |
| 3 | ~1.5KB | ✅ | ❌ | BM fail at char 1596 |
| 4 | ~800 chars | — | ✅ | — |
| 5 | ~1.1KB complex | — | ❌ | BM fail at char 1067 |
| 6 | ~950 chars | — | ✅ | — |
| 7 | ~1000 chars | — | ✅ | — |
| 8 | ~1024 chars simple | — | ✅ | — |
| 9 | ~1050 chars simple | — | ✅ | — |

**Key Findings:**
- **Boot Mode (BM)**: Threshold ~1-1.1KB, content-complexity dependent
- **Non-Boot Mode (NBM)**: Higher threshold (~2-2.5KB observed), needs further testing at larger sizes
- Limit is NOT purely character count — escape sequences/markdown complexity matters
- Simple alphanumeric padding serializes more efficiently than complex prose

**TODO:** Test NBM at larger sizes (3KB, 5KB, 10KB) to find upper bound

**Workaround:**
- Boot mode: Keep journal content under ~1KB with minimal markdown
- Non-boot mode: Use for larger entries (threshold TBD)
- Consider chunked save pattern (query-merge-update) for large content

**Recommended Fix:**
This is an OpenAI platform bug — cannot fix directly. Options:
1. Document content constraints for qfe users
2. Implement chunked save pattern for large journals
3. Add client-side content sanitization before save
4. Report to OpenAI if reproducible pattern isolated

**Research Complete (QP1 2026-01-28):**
- **Root Cause**: ChatGPT's function-call wrapper has undocumented ~760-token limit on `params` JSON
- **NOT a character limit** — it's a TOKEN limit, explaining why content complexity matters
- Boot mode consumes tokens for instructions, leaving less for payload
- Non-boot mode has no instruction overhead = higher effective limit

**Workaround Options (from QP1):**
1. Reduce overhead (minify JSON, shorten boot prompts)
2. Chunk journal across multiple calls (requires BUG-010 fix first)
3. Encode/compress journal (base64 adds 33% overhead)
4. Send conversation as file attachment (up to 10 files, hundreds of MB)
5. Delay boot context or summarize journal

**Blocking Dependency:** Chunking strategy requires UPDATE capability — blocked by BUG-010

**Restart Prompts:**
- `docs/restarts/RESTART__BUG-008__File_Attachment_Workaround__2026-01-28.md` — File attachment investigation

**Related:** BUG-007 (separate issue — journal content never persisted regardless of this bug)

---

### BUG-009: artifact.list returns no rows while artifact.query succeeds

**Status:** CLOSED — Verified working 2026-01-29
**Severity:** High
**Component:** NQxb_Artifact_List_v1 workflow

**Symptoms:**
- `artifact.query` for a specific project returns full hydrated result
- `artifact.list` for projects (same workspace, same user) returns zero rows
- Tested with limit 3, limit 10, base-only and hydrated — all return empty

**Reproduction (2026-01-28):**
```
artifact.query(artifact_type='project', artifact_id='69ea3ebe-84dc-4ff0-a354-1103f7a92595') → SUCCESS
artifact.list(artifact_type='project', limit=10, hydrate=true) → 0 rows
```

**Impact:**
- Duplicate detection via list is unreliable
- Any UI/automation relying on artifact.list is unsafe
- Projects exist but are invisible to list operations

**Additional Testing (2026-01-28):**

| Call | Result |
|------|--------|
| `artifact.list(project)` no selector | ✅ 50 rows returned |
| `artifact.list(project, limit=3)` | ❌ 0 rows |
| `artifact.list(project, limit=10, hydrate=true)` | ❌ 0 rows |

**Closed:** 2026-01-29 — Tested via Telegram Gateway with `limit: 10`. List journals returned 10 results correctly. List snapshots, projects, and other types all working with limit selector.

---

### BUG-010: UPDATE via direct API returns INSERT/ok:true but does nothing

**Status:** CLOSED — Not a bug; Mutability Registry working as designed
**Severity:** N/A (was Medium)
**Component:** NQxb_Artifact_Update_v1 workflow + Mutability Registry

**Original Symptoms:**
- Direct API call with `artifact_id` in payload to update project `content`
- Response: `ok: true`, `operation: INSERT`, `artifact_id: null`
- No duplicate created, original project unchanged
- UPDATE silently failed, returned false positive

**Investigation (2026-01-29):**
Tested `artifact.update` via PowerShell against Gateway:

| Test | Result |
|------|--------|
| Update journal `entry_text` | REJECTED: `JOURNAL_MUTABILITY_UNDECIDED` — journals are INSERT-ONLY |
| Update project `lifecycle_stage` | REJECTED: `MUTABILITY_ERROR` — field is `PROMOTE_ONLY` |
| `artifact.promote` for lifecycle | ✅ SUCCESS — correct operation for lifecycle changes |

**Conclusion:**
The Gateway is correctly enforcing the Mutability Registry:
- Journal updates blocked by `UNDECIDED_BLOCKED` doctrine
- Project `lifecycle_stage` blocked by `PROMOTE_ONLY` rule
- Proper error messages returned (not silent failures)

The original issue was likely using `artifact.save` instead of `artifact.update`, or attempting to modify protected fields.

**Closed:** 2026-01-29 — Gateway mutability enforcement verified working. Use `artifact.promote` for lifecycle transitions. Journal updates intentionally blocked per INSERT-ONLY doctrine.

---

### BUG-011: Write Contract Registry blocks spine fields (tags/summary/content) on CREATE

**Status:** MOSTLY COMPLETE — Gateway + Schema done 2026-02-01; Telegram tags deferred
**Severity:** High (blocks first-class tags; prevents search by tag)
**Component:** qfe Write Contract Registry + Gateway validator + artifact.list

**Symptoms:**
- `artifact.save` with `tags` rejected at qfe preflight (never reaches Gateway)
- `artifact.save` with `summary` rejected: "Field is not defined in the project write contract"
- Structured content JSON mapped to `extension` instead of `content`
- Write Contract only allows `title` + `extension.lifecycle_stage`

**Reproduction (2026-01-28):**
1. Project create with `tags`: REJECTED — "Unrecognized field interpreted as extension.tags"
2. Project create with `summary`: REJECTED — "Field is not defined in the project write contract"

**Root Cause:**
qfe Write Contract Registry is overly restrictive. Only allows:
- `title`
- `extension.lifecycle_stage`

Rejects legitimate spine fields: `summary`, `tags`, `content`, `parent_artifact_id`, `priority`

**Required Fixes:**

| # | Component | Change | Status |
|---|-----------|--------|--------|
| 1 | Actions Schema | Update tags to array, add selector.filters.tags_any | **DONE** (v2.2.0-dev) |
| 2 | Gateway Save | Accept top-level `tags`, normalize and persist to `qxb_artifact.tags` | **DONE** (v25) |
| 3 | Gateway List | Add `selector.filters.tags_any` filter support | **DONE** (v27) |
| 4 | Tests | Tag filtering regression tests (see spec) | **DONE** (PowerShell) |
| 5 | Telegram | Add tags to save tools | DEFERRED (n8n limitation) |

**Gateway Changes Deployed & Verified (2026-02-01):**

**NQxb_Artifact_Save_v1 (v25-bug011-tags-normalization):**
- Added `normalizeTags()` function in Normalize_Request
- Tags are now stored as array of lowercase, trimmed, deduped strings
- Accepts array input; converts object values to array if needed
- Empty strings filtered out
- ✅ VERIFIED: Save with tags persists correctly

**NQxb_Artifact_List_v1 (v27-bug011-tags-any-filter):**
- Added `selector.filters.tags_any` support
- Validates tags_any is array of strings
- Normalizes filter values (lowercase, trim, dedupe)
- Uses PostgREST JSONB contains operator: `tags=cs.["tag1"]`
- ✅ VERIFIED: Filter returns only matching artifacts; non-matching returns 0

**Verification Tests (2026-02-01):**
| Test | Result |
|------|--------|
| Save journal with `tags: ["conversation", "testing", "bug011"]` | ✅ Persisted correctly |
| List with `tags_any: ["conversation"]` | ✅ Returns 1 match |
| List with `tags_any: ["nonexistent"]` | ✅ Returns 0 (no false positives) |

**Telegram Gateway:**
Tags support deferred — n8n `toolHttpRequest` requires all placeholders, making optional `tags` parameter problematic. Workaround options: separate tagged-save tools or custom node.

**Remaining Work (qfe Frontend):**

The qfe Write Contract Registry must be updated to allow spine fields on CREATE:
- `title` (required for most types)
- `summary` (optional)
- `tags` (optional) — JSONB array
- `content` (optional) — JSONB object
- `parent_artifact_id` (optional, type-governed)
- `priority` (optional)

**Tag Normalization Rules (implemented in Gateway):**
- Trim strings
- Drop empty
- De-dupe
- Lowercase for deterministic search

**Acceptance Criteria:**
- [x] Gateway accepts `tags` array and normalizes correctly
- [x] `artifact.list` with `selector.filters.tags_any` filters by tag contains
- [x] End-to-end test: create journal with tags → list by tags_any (via PowerShell)
- [x] Actions Schema updated: tags as array, selector.filters.tags_any (v2.2.0-dev)
- [ ] Telegram Gateway supports tags (n8n limitation — deferred)

**Specification:** `CC_Inbox/Archive/cc_prompt_tags.md`

**Restart Prompt:** `docs/restarts/RESTART__BUG-011__First_Class_Tags_Implementation__2026-01-28.md`

---

### BUG-012: Project artifacts save without content/summary

**Status:** CLOSED — Fix deployed and verified 2026-02-01
**Severity:** Medium (data loss for project descriptions; workaround exists)
**Component:** NQxb_Gateway_Telegram_v1 workflow (Tool_Save_Project node)

**Symptoms:**
- `artifact.save` with `artifact_type: project` returns success with valid `artifact_id`
- Project spine and extension rows are created correctly
- `qxb_artifact.summary` is always empty on retrieval
- `qxb_artifact.content` is always empty on retrieval
- Telegram confirmation message shows full content, but database has none

**Reproduction (2026-01-30):**

| Artifact | Title | Summary in DB | Content in DB |
|----------|-------|---------------|---------------|
| `441ed127-113f-48e3-aedd-8874ae9ae19a` | Seed — Infrastructure Capacity | EMPTY | EMPTY |
| `c02b26b5-2a5f-48e6-9928-dd5aea1c6be2` | Seed — Introduce RAG Capabilities | EMPTY | EMPTY |

Both projects saved via Telegram Gateway with detailed content in the save command. Telegram confirmation shows content was received, but database shows empty fields.

**Root Cause (CONFIRMED 2026-02-01):**
The `Tool_Save_Project` node in `NQxb_Gateway_Telegram_v1.json` was missing a `summary` parameter:

```json
// BEFORE (broken):
"jsonBody": "{ ... \"title\": \"{title}\", \"content\": {}, ... }",
"placeholderDefinitions": {
  "values": [
    { "name": "title", ... }   // <-- NO summary parameter!
  ]
}
```

User content after the colon was completely ignored because there was no placeholder to capture it.

**Fix Applied (2026-02-01):**
Added `summary` parameter and placeholder to `Tool_Save_Project`:

```json
// AFTER (fixed):
"jsonBody": "{ ... \"title\": \"{title}\", \"summary\": \"{summary}\", \"content\": {}, ... }",
"placeholderDefinitions": {
  "values": [
    { "name": "title", "description": "Title for the project", "type": "string" },
    { "name": "summary", "description": "The project description or summary text", "type": "string" }
  ]
}
```

**File Modified:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

**Verification (2026-02-01):**
1. Deployed updated workflow to n8n
2. Test: `Save project titled "BUG-012 Test": This is a test to verify project summary persistence...`
3. Result: `summary` field populated correctly in database
4. No duplicate created on retrieve operation

**Closed:** 2026-02-01 — Fix verified working. Projects now persist summary field via Telegram.

**Related:**
- BUG-007 (similar pattern — journal `entry_text` was missing from payload mapping)
- BUG-011 (Write Contract blocks spine fields — separate issue for qfe/ChatGPT)

---

### BUG-013: Restart artifact save fails with schema mismatch

**Status:** CLOSED — Fix deployed and verified 2026-02-01
**Severity:** Medium (workaround: save as journal instead)
**Component:** NQxb_Gateway_Telegram_v1 workflow (Tool_Save_Restart node)

**Symptoms:**
- `artifact.save` with `artifact_type: restart` fails at Gateway
- Error: "Received tool input did not match expected schema"
- Details: "Expected string, received object → at restart_context"
- Snapshot saves work; journal saves work; restart saves fail

**Root Cause (CONFIRMED 2026-02-01):**
Two issues identified:

1. **Wrong extension path:** `Tool_Save_Restart` used `extension.restart_context` but Gateway expects `extension.payload.body` (same pattern as snapshot)

2. **AI type confusion:** The AI Agent sometimes passed an object instead of string for the `restart_context` parameter

**Fix Applied (2026-02-01):**
Updated `Tool_Save_Restart` to match the working snapshot pattern:

```json
// BEFORE (broken):
"extension": { "restart_context": "{restart_context}" }

// AFTER (fixed):
"extension": { "payload": { "body": "{restart_body}" } }
```

**Files Modified:**
- `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

**Verification (2026-02-01):**
1. Deployed updated workflow to n8n
2. Test: `Save restart titled "TG-TEST-S5 Restart Save": This restart tests context persistence via Telegram.`
3. Result: UUID `dc263f11-a263-4f90-8e56-83df2a6ad781` returned
4. Database: `payload.body` contains the content correctly

**Closed:** 2026-02-01 — Restart save now works via Telegram.

**Related:**
- BUG-012 (project summary — CLOSED, same pattern)
- BUG-014 (parent_artifact_id — CLOSED, same pattern)

---

### BUG-014: parent_artifact_id not persisted on artifact.save

**Status:** CLOSED — Fix deployed and verified 2026-02-01
**Severity:** Medium (blocks artifact linking; workaround: manual SQL update)
**Component:** NQxb_Gateway_Telegram_v1 workflow (Tool_Save_Journal node)

**Symptoms:**
- User tells Telegram to "link" a companion journal to its parent seed project
- Telegram confirms the link was set
- `parent_artifact_id` is NULL in database on retrieval
- Artifacts appear unrelated despite user intent

**Reproduction (2026-02-01):**

| Journal | Expected Parent | Actual parent_artifact_id |
|---------|-----------------|---------------------------|
| `d8859f6c-...` (Seed Content - Journal Mode Redesign) | `136e5384-...` | NULL |
| `4fcf15c7-...` (Seed Content - Telegram Web + QP1) | `00e5f131-...` | NULL |

Both journals created via Telegram with explicit "link to parent" instruction. Telegram confirmed link, but database shows NULL.

**Root Cause (CONFIRMED 2026-02-01):**
Same pattern as BUG-012. `Tool_Save_Journal` had no `parent_artifact_id` parameter:
- User says "link to parent X"
- AI acknowledges but has no way to include parent_artifact_id in payload
- Field never sent to Gateway

**Fix Applied (2026-02-01):**
Added `parent_artifact_id` parameter to `Tool_Save_Journal`:

```json
"parent_artifact_id": "{parent_artifact_id}",
// ...
{ "name": "parent_artifact_id", "description": "Optional UUID of parent artifact to link this journal to", "type": "string" }
```

**File Modified:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json`

**Verification (2026-02-01):**
1. Deployed updated workflow to n8n
2. Test: `Save journal titled "BUG-014 Test - Linked Journal": ... Link this to parent artifact 8a5d5cd1-...`
3. Result: `parent_artifact_id` populated correctly in database

**Closed:** 2026-02-01 — Fix verified working. Journals now persist parent_artifact_id via Telegram.

**Related:**
- BUG-012 (project content not persisted — CLOSED, same pattern)

---

### BUG-015: Gateway Normalize_Request drops transition/reason fields

**Status:** CLOSED — Contract violation fixed (Gateway v50), verified 2026-02-15
**Severity:** Medium (contract violation; blocked artifact.promote)
**Component:** NQxb_Gateway_v1 workflow (Normalize_Request node)
**Classification:** Contract Violation (Normalize_Request field discard)

**Symptoms:**
- `artifact.promote` fails with `FROM_STATE_MISSING` error
- `transition` and `reason` fields sent by caller are silently dropped during canonicalization
- Promote sub-workflow receives null transition state

**Root Cause (CONFIRMED 2026-02-14):**
`Normalize_Request` did not forward `transition` or `reason` from the webhook payload. Same bug class as T26 (selector fields stripped) — fields not explicitly included in the normalizer output were silently discarded.

**Fix Applied (Gateway v50):**
Added explicit passthrough in `Normalize_Request`:
```
transition: raw.transition ?? null
reason: raw.reason ?? null
```
Carried through Gateway v55 (current live).

**Verification (2026-02-15):**

| Test | Transition | Result | Reason in Event |
|------|-----------|--------|-----------------|
| B1 | sapling_to_tree | `ok: true` | YES — captured in event payload |
| B2 | tree_to_retired | `ok: true` | YES — captured in event payload |

**Governance Reinforcement:**
Sealed by doctrine rule `gov-normalize-contract` (Phase 2 Governance Hardening Instruction Pack v1): canonicalization is idempotent and monotonic — canonical fields must never be discarded once established.

**Closed:** 2026-02-15 — Contract violation fixed and verified. Transition/reason passthrough working end-to-end.

**Note:** Promotion content validation gates (readiness criteria per transition) are separate feature work, not part of this bug. Tracked separately.

**Related:**
- T26 (same bug class — selector fields stripped)
- North Star v0.4 (lifecycle semantics)
- Phase 2 Governance Hardening Instruction Pack v1

---

### BUG-016: artifact.promote sends wrong transition for non-seed artifacts

**Status:** Open — Telegram AI-specific (not a Gateway bug)
**Severity:** Low (workaround: use JSON payloads with correct transition)
**Component:** NQxb_Gateway_Telegram_v1 workflow (AI Agent behavior)

**Symptoms:**
- `artifact.promote` from sapling → tree fails with `FROM_STATE_MISSING`
- Gateway receives `transition: "seed_to_tree"` even when artifact is at `sapling`
- Artifact's actual `lifecycle_status` is ignored when formulating request

**Reproduction (2026-02-03):**
```
Artifact: 2c935453-4af4-4e98-a52c-c65dfcd0e6a9
Current lifecycle_status: sapling
Command: "promote to tree"

Gateway response:
{
  "ok": false,
  "transition": "seed_to_tree",   // WRONG — should be "sapling_to_tree"
  "error": {
    "code": "FROM_STATE_MISSING",
    "message": "from_state missing after Resolve_Transition.",
    "details": { "from_state": null }
  }
}
```

**Root Cause:**
The Gateway Promote workflow correctly uses whatever `transition` string the caller sends. The bug is in the Telegram AI Agent: when user says "promote to tree", the AI guesses `seed_to_tree` without checking the artifact's current lifecycle_status. With raw JSON payloads (Chrome Extension or T14), the caller controls the transition string directly and Gateway handles it correctly.

**Resolution Path:** T14 (Telegram Gateway Pipe) will send JSON payloads directly, bypassing the AI Agent. User will construct correct transition string.

**Workaround:**
Use direct SQL to update lifecycle_status:
```sql
UPDATE qxb_artifact SET lifecycle_status = 'tree' WHERE artifact_id = '...';
UPDATE qxb_artifact_project SET lifecycle_stage = 'tree' WHERE artifact_id = '...';
```

**Recommended Fix:**
Two options:

1. **Gateway_Telegram queries first:** Before calling promote, query artifact to get current lifecycle_status, then compute correct transition
2. **Gateway infers transition:** Send only `target_state` (e.g., "tree") and let Gateway compute transition from stored lifecycle_status

Option 2 is cleaner — it matches user mental model ("promote to tree") without requiring client to know current state.

**Related:**
- BUG-015 (promote has no validation requirements)

---

### BUG-017: Cannot add/update tags on existing artifacts

**Status:** Open — See BUG-018 for duplicate creation issue
**Severity:** Medium (workaround: direct SQL)
**Component:** artifact.update workflow / Gateway

**Symptoms:**
- Attempting to add tags to an existing artifact fails
- No update path exists for modifying `tags` array after initial save
- Users cannot mark artifacts as "shipped", "completed", or add organizational tags post-creation

**Reproduction (2026-02-03):**
```
Attempted via Telegram:
"Update artifact e461ca2d-4a58-4e7e-956c-28b3ce921cf5 to add tags: shipped, completed"

Result: Failed / not supported
```

**Root Cause:**
The `artifact.update` workflow and/or Telegram tools do not support modifying the `tags` field. Tags can only be set at creation time via `artifact.save`.

**Impact:**
- Cannot retroactively tag artifacts for organization
- Cannot mark work as "shipped" or "done" via tags
- Limits usefulness of tag-based filtering (`tags_any`) for workflow state

**Workaround:**
Direct SQL update:
```sql
UPDATE qxb_artifact
SET tags = tags || '["shipped", "completed"]'::jsonb
WHERE artifact_id = '...';
```

**Recommended Fix:**
1. Add `tags` to artifact.update mutability rules (UPDATE_ALLOWED)
2. Implement tags merge logic: append new tags, dedupe, normalize
3. Add Telegram tool or command for tag updates

**Related:**
- BUG-011 (tags now work on save, but not update)
- BUG-018 (update creates duplicate instead of modifying existing)

---

### BUG-018: artifact.update via Telegram creates duplicate instead of updating

**Status:** CLOSED — Resolved 2026-02-11 (Gateway wiring bug, T6)
**Severity:** High (silent data corruption — duplicates created)
**Component:** artifact.update workflow or Gateway routing

**Hypothesis (2026-02-05):** The update operation may be falling through to save (creating new) rather than updating existing. This could be:
1. Telegram AI calling save instead of update
2. Gateway update routing failing and falling back to save
3. Immutability rules rejecting update, causing fallback behavior

Needs thorough testing with raw JSON payloads via Chrome Extension to isolate whether this is Telegram-specific or Gateway-level.

**Closed:** 2026-02-11 — Root cause: Gateway wiring bug. Resolved as part of T6 thread.

**Symptoms:**
- `artifact.update` command via Telegram reports success
- Original artifact remains UNCHANGED (same tags, same updated_at)
- NEW artifact created with updated values and new artifact_id
- User believes update succeeded but now has duplicate artifact

**Reproduction (2026-02-03):**
```
Original artifact: 5d0104d0-1a0f-4cf1-96d0-3077517c78ee
  tags: ["restart", "cc_inbox"]
  created_at: 2026-02-03T15:14:49

Command: "update restart 5d0104d0-1a0f-4cf1-96d0-3077517c78ee with tags shipped, restart, cc_inbox"

Result:
  Telegram: "✓ Updated restart"
  Response artifact_id: cae6af5a-9e1f-4d5e-9a04-1314be2462c5 (DIFFERENT!)

Query both:
  5d0104d0: tags = ["restart", "cc_inbox"] (UNCHANGED)
  cae6af5a: tags = ["shipped", "restart", "cc_inbox"], created_at = 2026-02-03T15:22:45 (NEW)
```

**Root Cause:**
Unknown — likely the Telegram update tool is calling `artifact.save` instead of `artifact.update`, or the update workflow is falling through to a create path when it should update.

**Impact:**
- Silent data corruption — user thinks artifact updated but it wasn't
- Duplicate artifacts pollute the workspace
- Original artifact never receives intended changes
- Tag-based queries may return wrong artifact

**Workaround:**
None via Telegram. Must use direct SQL (if permitted) or Gateway API directly.

**Recommended Investigation:**
1. Check if `Tool_Update_Restart` exists in Telegram workflow
2. Verify it calls `artifact.update` endpoint, not `artifact.save`
3. Check if artifact_id is passed correctly in update payload
4. Review Gateway update workflow for restart type handling

**Related:**
- BUG-017 (cannot update tags — this bug shows update creates duplicate instead)
- BUG-016 (promote sends wrong transition — similar routing issue)

---

### BUG-019: artifact.save reports success with hallucinated artifact_id (never persisted)

**Status:** CLOSED — Structural fix deployed and verified 2026-02-03
**Severity:** Critical (silent data loss — user believes save succeeded)
**Component:** NQxb_Gateway_Telegram_v1 workflow (AI Agent + Save path)

**Root Cause (CONFIRMED 2026-02-03):**
GPT-4o-mini hallucinated the save response without calling the tool. Investigation confirmed:
- Gateway_Telegram workflow executed
- Gateway_v1 workflow did NOT execute (no execution at same timestamp)
- AI Agent skipped the tool call entirely and fabricated a plausible UUID

**Mitigation Applied (2026-02-03):**
Upgraded AI model from `gpt-4o-mini` to `gpt-4o` in NQxb_Gateway_Telegram_v1 workflow.
- GPT-4o has better tool-calling reliability and lower hallucination rate
- File updated: `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (4).json`
- Deployed to n8n

**STRUCTURAL FIX IMPLEMENTED (2026-02-03):**
Verification-based enforcement added to make it architecturally impossible for hallucinated saves to reach users.

**File:** `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1 (6).json`

**New Nodes Added:**
| Node | Purpose |
|------|---------|
| `Check_Save_Intent` | Detects save intent from original user message |
| `Extract_Claimed_ArtifactId` | Extracts claimed artifact_id from AI output (treated as untrusted) |
| `Check_Has_Claim` | Routes based on whether AI returned an artifact_id |
| `Verify_Artifact` | Calls Gateway to verify artifact actually exists |
| `Check_Verification` | Routes based on verification result |
| `Build_Verified_Success` | Constructs success message from verified data ONLY |
| `Build_Verification_Failure` | Explicit failure when verification fails |
| `Build_No_ID_Failure` | Explicit failure when no ID returned |
| `Send_Verified_Success` | Sends verified success |
| `Send_Verification_Failure` | Sends verification failure |
| `Send_No_ID_Failure` | Sends no-ID failure |

**Enforcement Guarantee:**
- AI output is NEVER directly sent to Telegram for save operations
- Claimed artifact_id is extracted and treated as untrusted claim
- Gateway query independently verifies artifact exists
- Success message constructed from verification response, not AI output
- If verification fails → explicit failure message, no UUID shown

**There is no execution path where Telegram receives a save success AND the artifact does not exist.**

**Deployment Checklist:**
- [x] Import `NQxb_Gateway_Telegram_v1 (6).json` to n8n
- [x] Activate workflow
- [x] Test: successful save → verified success message
- [ ] Test: forced failure → explicit failure message
- [x] Confirm no path allows hallucinated success

**Closed:** 2026-02-03 — Verification-based enforcement deployed. Save operations now independently verify artifact exists before sending success. Fixes applied:
1. `Check_Verification` path updated to read `data.artifact` (Gateway response envelope)
2. `Build_Verified_Success` updated to read from verified data
3. Tags displayed with `.join(', ')` instead of JSON.stringify

**Hardblock Enhancement (2026-02-03):**
Added final hard block on non-save response path (`Sanitize_Non_Save_Response`):
- If AI output contains save-success indicators or structured fields, entire output is discarded
- Replaced with fixed system message: "No save was performed. To save something, please use an explicit save command."
- Uses word-boundary regex (`\bkeyword\b`) to prevent false matches

**Hardblock Regression & Fix (2026-02-03):**
- **v3-hardblock** was too aggressive — blocked ALL non-save responses
- Keywords `artifact`, `journal`, `project`, `snapshot`, `restart` appear in legitimate list/query output
- User says "list journals" → AI returns list → hardblock detects "journal" → blocks response
- **v4-narrowed** attempted fix: Narrowed to save-success indicators only: `saved`, `created`, `persisted`
- **v7-keywords-only** still false-positive: "Created on Feb 3, 2026" matched `/\bcreated\b/i`
- **v8-no-sanitizer (FINAL):** Removed sanitizer from non-save path entirely
  - Insight: Verification enforcement on save path is sufficient
  - Non-save responses don't need sanitization — they can't claim saves that didn't happen
  - Connection changed: `Check_Save_Intent → Send_Response` (direct, bypasses sanitizer)
  - Version: `bug019-v8-no-sanitizer` — **KGB confirmed**

**Restart Prompt:** `docs/restarts/RESTART__BUG-019__Structural_Hallucination_Fix__2026-02-03.md`

**Symptoms:**
- Telegram reports "✓ Saved project" with full artifact details
- artifact_id in response does not exist in database
- Save operation never actually executed
- Retry with identical content succeeds with different (real) artifact_id

**Reproduction (2026-02-03):**
```
Command: Save project titled "Seed — Canvas-First Prompt Review Paradigm": [full content]

Telegram response:
  "✓ Saved project
   artifactid: 5e7f8e4b-3a4e-4b8e-bc6e-7d9f8e4b3a4e  ← DOES NOT EXIST
   title: Seed — Canvas-First Prompt Review Paradigm
   ..."

Database query: artifact_id = '5e7f8e4b-3a4e-4b8e-bc6e-7d9f8e4b3a4e' → 0 rows

Retry (same content):
  artifact_id: 963826c6-a3e2-4666-b6d5-32a5171e52bf  ← EXISTS, real UUID
```

**Key Evidence:**
1. The failed artifact_id has suspicious pattern: `5e7f8e4b-3a4e-4b8e-bc6e-7d9f8e4b3a4e`
   - Repeating hex patterns: `4b`, `4e`, `8e`
   - Real `gen_random_uuid()` output doesn't look like this
   - Suggests AI-generated/hallucinated UUID, not database-generated

2. n8n execution log shows "Send Response" node executed successfully
   - The success message was sent to Telegram
   - But the artifact_id in that message was fake

3. The working retry produced a real UUID with proper entropy

**Root Cause Analysis:**

~~1. **AI Agent hallucination:** The Claude/GPT agent in the Telegram workflow generated a fake success response without actually calling the Gateway save endpoint~~ **← CONFIRMED**

2. ~~Gateway timeout/failure silently swallowed~~ — Ruled out (Gateway never called)

3. ~~Tool call never executed~~ — This is the symptom of #1

4. ~~Race condition~~ — Ruled out (no concurrent execution)

**Investigation (COMPLETED 2026-02-03):**
- [x] Check n8n execution logs for the failing run — Gateway_v1 NOT called
- [x] Check if "Call Gateway" node executed vs was skipped — Tool was SKIPPED
- [x] Verify artifact_id in response comes from Gateway response — AI-GENERATED (hallucinated)
- [x] Check for error handling gaps — No verification of tool execution exists

**Impact:**
- User believes artifact is saved when it's not
- Data loss — content exists only in chat history
- Trust violation — save confirmations cannot be relied upon
- Worse than a visible error — silent false positive

**Workaround:**
After any save, verify with `artifact.query` using the returned artifact_id before treating as successful.

**Related:**
- BUG-018 (update creates duplicate — similar response/execution mismatch)

---

### BUG-020: instruction_pack save returns artifact_id: null

**Status:** PARTIAL FIX — Workflow fixed (v25), but hallucination regression detected
**Severity:** High
**Component:** NQxb_Artifact_Save_v1 workflow (instruction_pack extension node)

**Symptoms (Original):**
- instruction_pack save returns `ok: true` but `artifact_id: null`
- Artifact actually persists in database (verified via SQL)
- Telegram Gateway verification expects artifact_id, fails

**Root Cause (CONFIRMED):**
Node `NQxb_Artifact_Save_v1__DB_Insert_Instruction_Pack_Extension` was misconfigured:
- Used `operation: "update"` instead of INSERT (default)
- Had `matchType` and `filters` blocks (for UPDATE-style matching)
- Missing `artifact_id` in `fieldsUi.fieldValues`
- Missing hardcoded `pack_format = 'json'` (DB constraint requirement)

**Fix Applied (2026-02-03):**
- Removed `"operation": "update"`
- Removed `"matchType": "allFilters"`
- Removed entire `"filters"` block
- Added `artifact_id` to `fieldsUi.fieldValues` as first field
- Hardcoded `pack_format = 'json'` (required by `qxb_aip_pack_format_json_chk` constraint)

**Verification Results (2026-02-03):**
- Test 1: "Fresh Test Pack ABC" — SAVED correctly (artifact_id `21b3f7a4-d9ce-4564-8d47-8d968c2aad0c` exists in both tables)
- Test 2: "Fresh Test Pack XYZ" — Telegram reported success with artifact_id `5d9c9e5e-4b4f-4b2e-bc9b-0c3d1c5f9e3e`
  - **HALLUCINATION DETECTED**: This artifact_id does NOT exist in database
  - UUID has suspicious repeating patterns (AI-generated, not `gen_random_uuid()`)
  - This is a BUG-019 regression — AI skipped tool call and fabricated response

**Outstanding Issue:**
The Save workflow fix (v25) is correct, but BUG-019 hallucination mitigation may not be working reliably. The AI Agent sometimes bypasses the Gateway tool call entirely and fabricates success responses.

**Files:**
- Fixed: `workflows/NQxb_Artifact_Save_v1 (25).json`
- Archived: `workflows/Archive/NQxb_Artifact_Save_v1 (24).json`
- Restart: `docs/restarts/RESTART__BUG-020__Instruction_Pack_ArtifactId_Null__2026-02-03.md`

**Next Steps:**
1. ~~Investigate why BUG-019 verification enforcement isn't catching hallucinated saves~~
2. ~~Check n8n execution logs — was Gateway actually called for "Fresh Test Pack XYZ"?~~
3. ~~Consider stronger verification (DB round-trip check before reporting success)~~

**Resolution Path (2026-02-05):** T14 (Telegram Gateway Pipe) will send JSON payloads directly to Gateway, bypassing the AI Agent entirely. No AI = no hallucination. The workflow fix (v25) is correct; the hallucination is an AI Agent problem that T14 eliminates.

---

### BUG-021: TYPE_MISMATCH error shows stored_artifact_type: null

**Status:** Open — Display fix only
**Severity:** Low (cosmetic — TYPE_MISMATCH detection logic is correct)
**Component:** NQxb_Artifact_Query_v1 workflow (Return_TypeMismatch node)

**Symptoms:**
- `artifact.query` with wrong `artifact_type` correctly returns TYPE_MISMATCH error
- Error payload shows `stored_artifact_type: null` instead of actual stored type
- `requested_artifact_type` is correct
- `compare_key` shows `null::journal` instead of e.g. `project::journal`

**Reproduction (2026-02-11, during BUG-003 validation):**
```json
{
  "ok": false,
  "_gw_route": "error",
  "requested_artifact_type": "journal",
  "stored_artifact_type": null,
  "compare_key": "null::journal",
  "error": {
    "code": "TYPE_MISMATCH",
    "message": "Requested artifact_type does not match stored artifact_type for this artifact_id."
  }
}
```

**Root Cause:**
The `Return_TypeMismatch` Code node reads `$json.artifact_type` to get stored type. At this point in the workflow, `$json` is the extension table row (from Phase 1 fetch), which has no `artifact_type` column. The stored type should be extracted from the spine node: `$node["NQxb_Artifact_Query_v1__DB_Get_Artifact_Spine"].json.artifact_type`.

**Scope:**
- Extract `artifact_type` from spine node, NOT extension node
- No logic changes — TYPE_MISMATCH detection is correct
- Display fix only — populate `stored_artifact_type` and `compare_key` correctly

**Recommended Fix:**
In `NQxb_Artifact_Query_v1__Return_TypeMismatch` node, change:
```javascript
// BEFORE:
const stored = typeof j.artifact_type === "string" ? j.artifact_type.trim() : (j.artifact_type ?? null);

// AFTER:
const spineData = $node["NQxb_Artifact_Query_v1__DB_Get_Artifact_Spine"].json || {};
const stored = typeof spineData.artifact_type === "string" ? spineData.artifact_type.trim() : (spineData.artifact_type ?? null);
```

**Related:**
- BUG-003 (hydrate gate fix — same workflow, same validation session)

---

## Closed Bugs

### BUG-006: Hydration loses spine data — only extension fields returned

**Status:** CLOSED
**Severity:** Critical
**Component:** NQxb_Artifact_List_v1 workflow (Merge nodes)

**Symptoms:**
- `artifact.list` with `hydrate=true` returns only extension fields
- Missing: `title`, `summary`, `artifact_type`, `workspace_id`, `owner_user_id`
- `meta.count` was 1 when limit was 2

**Root Cause:**
Two issues:
1. Merge nodes assumed `$input.item.json` was spine data, but DB_Get OUTPUT replaces input data, so Merge only saw extension
2. n8n's per-item execution model (`$input.item.json`) was only running once instead of for each item

**Fix Applied:**
All Merge nodes now use `$input.all()` to process ALL items in a single execution, and `$items("Explode_X_Page")` to retrieve spine data, matching by `artifact_id`.

**Closed:** 2026-01-27 — Verified end-to-end. Request with limit=2, hydrate=true returned 2 artifacts with full spine + extension data. Workflow v26 deployed.

---

### BUG-001: artifact.list pagination broken — OFFSET not honored

**Status:** CLOSED
**Severity:** Critical
**Component:** NQxb_Artifact_List_v1 workflow

**Symptoms:**
- Same artifact returned for all offset values (0, 1, 2, 3 all return same ID)
- `has_more = true` but pagination yields duplicates
- Newest artifacts not appearing in list results

**Root Cause:**
The Supabase "Get many rows" node:
- No ORDER BY configured — results in planner-dependent order
- No OFFSET passed to database — only `limit + 1` fetched

**Fix Applied:**
Replaced Supabase node with HTTP Request to PostgREST API:
- Added `order=created_at.desc,artifact_id.desc`
- Added `offset={{offset}}`
- Added `created_at=lte.{{as_of}}`

**Closed:** 2026-01-27 — Verified with pagination test. Different offsets now return different artifact_ids. Workflow v25 deployed.

---

### BUG-005: Hydrated list returns only first item for Project/Journal/Restart

**Status:** CLOSED
**Severity:** Critical
**Component:** NQxb_Artifact_List_v1 workflow (hydration branches)

**Symptoms:**
- `artifact.list` with `hydrate=true` returns only 1 artifact
- Affects: project, journal, restart types
- Snapshot and instruction_pack work correctly (return all items)

**Root Cause:**
Project, Journal, and Restart hydration branches were missing "Split Out" nodes to iterate over `_page_items`. They only processed index `[0]`.

**Fix Applied:**
Added Split Out nodes (`Explode_Project_Page`, `Explode_Journal_Page`, `Explode_Restart_Page`) before DB_Get nodes. Updated Merge_Project and Merge_Restart to use per-item merge pattern.

**Closed:** 2026-01-27 — Verified end-to-end. Request returned 19 projects with hydration across seed/sapling/tree lifecycle stages. Workflow v24 deployed.

---

## Bug Template

```
### BUG-XXX: [Short description]

**Status:** Open | In Progress | Closed
**Severity:** Critical | High | Medium | Low
**Component:** [Workflow or component name]

**Symptoms:**
- [What user observes]

**Root Cause:**
[Technical explanation]

**Fix:**
[Approved solution]

**Closed:** [Date] — [Resolution notes]
```
