# Qwrk Bug Tracker

**Created:** 2026-01-27
**Last Updated:** 2026-02-01 (BUG-011 Gateway VERIFIED — tags save/filter working; qfe + Telegram pending)

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

**Status:** Open — Tracked in seed project
**Severity:** Medium
**Component:** NQxb_Artifact_Query_v1 workflow

**Symptoms:**
- `hydrate: false` in request still returns hydrated response
- No conditional check on hydrate flag before extension fetch

**Tracking:**
- Seed project: `fcbf8b49-8662-48fd-8f49-2963b0352e59`
- Journal entry documenting analysis exists

**Fix Required:**
Add `If_Hydrate` conditional node (similar to List workflow pattern)

---

### BUG-004: instruction_pack Update not implemented

**Status:** Open — Fix specified, awaiting implementation
**Severity:** Medium (upgraded - blocks Qwrk self-modification of packs)
**Component:** NQxb_Artifact_Update_v1 workflow (v10)

**Symptoms:**
- Cannot PATCH existing instruction_pack artifacts
- No Switch branch for instruction_pack in Update workflow
- Qwrk cannot add shortcuts/rules to packs via conversation

**Root Cause:**
`Switch_Type_For_Update` only has a `project` branch. instruction_pack falls through with no handler.

**Approved Mutability Rules:**
| Field | Table | Mutability |
|-------|-------|------------|
| `content` | spine | UPDATE_ALLOWED |
| `active` | extension | UPDATE_ALLOWED |
| `priority` | extension | UPDATE_ALLOWED |
| `scope` | extension | IMMUTABLE |
| `pack_format` | extension | IMMUTABLE |

**Fix Specification:** `docs/BUG-004_Instruction_Pack_Update_Fix.md`

**Implementation Summary:**
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

**Status:** Open — CONFIRMED content-dependent, minimal payloads work
**Severity:** Medium (downgraded — workaround exists: simplify content)
**Component:** OpenAI GPT Actions framework (client-side serialization)

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

**Status:** PARTIAL — Gateway fixes deployed 2026-02-01; qfe changes pending
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
| 1 | qfe Write Contract | Update CREATE allow-lists for ALL types to permit spine fields | **PENDING** (frontend) |
| 2 | Gateway Save | Accept top-level `tags`, normalize and persist to `qxb_artifact.tags` | **DONE** (v25) |
| 3 | Gateway List | Add `selector.filters.tags_any` filter support | **DONE** (v27) |
| 4 | Tests | Tag filtering regression tests (see spec) | PENDING |

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
- [ ] qfe allows `tags`, `summary`, `content` etc. on CREATE (frontend change)
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

### BUG-015: artifact.promote has no validation requirements

**Status:** Open — Feature gap identified
**Severity:** Medium (governance gap; allows incomplete promotions)
**Component:** NQxb_Artifact_Promote_v1 workflow

**Symptoms:**
- `artifact.promote` from seed → sapling succeeds with no content validation
- Projects can be promoted even with empty summary/content
- No check for linked companion content
- No required fields or readiness criteria enforced

**Reproduction (2026-02-01):**
```
Promote fc09a422-a53e-4e85-b3bf-f692763bc07a to sapling
```
Promotion succeeded despite project having empty summary. Only lifecycle_status changed.

**Expected Behavior:**
Promotion should validate readiness criteria before allowing transition:

| Transition | Proposed Requirements |
|------------|----------------------|
| seed → sapling | Summary OR linked content exists; intent/goal defined |
| sapling → tree | Branches defined; acceptance criteria locked |
| tree → oak | All branches complete; KGB verification |
| oak → archive | Explicit archive reason |

**Impact:**
- Governance gap allows "empty" saplings
- Lifecycle stages lose semantic meaning
- No forcing function for content maturity

**Recommended Fix:**
1. Define formal promotion requirements per transition
2. Add validation node to Promote workflow
3. Return `PROMOTION_REQUIREMENTS_NOT_MET` error with missing fields
4. Document requirements in governance

**Related:**
- North Star v0.4 (lifecycle semantics)
- Kernel Semantics Lock (lifecycle definitions)

**Deferred Work:**
Full exercise needed to define seed → sapling → tree → oak requirements with all field/content gates.

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
