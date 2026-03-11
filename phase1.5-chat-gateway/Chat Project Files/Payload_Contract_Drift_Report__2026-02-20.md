# Payload Contract Drift Report

**Date:** 2026-02-20
**Auditor:** CC (Payload Contract Alignment Audit v1)
**Gateway:** v56
**DDL:** v2.4
**Source workflows:** Save v31, Query v18, List v29, Update v12, Promote v2_HTTP

---

## Executive Summary

The canonical payload reference (`Qwrk_Gateway_JSON_Payload_Canonical_v1.md`, both v1 and v1.1) has **empty stub sections** for the actual payload specs (sections 3-7). The document references a "prior canonical reference" that does not exist in the repository. This means **no authoritative payload specification has ever been written** — only global rules and examples in the Quick Reference.

This audit extracted behavioral truth from all 6 live workflow JSON files and compared findings against all documentation. **31 drift findings** identified: 13 Critical, 12 Major, 6 Minor.

**Root cause of thorn `344f292f`** (snapshot save failure): `extension.payload` is required at runtime for snapshot/restart types, but this requirement appears nowhere in canonical documentation.

---

## Critical Findings (Would Cause Runtime Failure)

### C-01: Canonical Sections 3-7 Are Empty Stubs

**Affected doc:** Canonical v1 and v1.1
**Finding:** Both versions contain: "Sections 3.1 through 7 remain functionally identical to the prior canonical reference." The referenced "prior canonical reference" does not exist in the repository. No actual per-action payload specs were ever written into this document.
**Impact:** The document claiming to be the "single source of truth" for payloads contains no payload specifications.

### C-02: 3 Undocumented Gateway Actions Are Live

**Affected doc:** Canonical v1.1 (Section 1 scope exclusion)
**Finding:** Gateway v56 has 8 operational actions. The canonical doc lists 5 (save, query, list, update, promote) and explicitly says it "does not cover" delete/archive. Three additional actions are fully operational as inline handlers: `artifact.delete` (soft-delete via `deleted_at`), `artifact.restore` (clears `deleted_at`), `artifact.list_deleted` (queries soft-deleted artifacts).
**Impact:** Users have no documentation for 3 working Gateway actions.

### C-03: Gateway TYPE_ALLOWLIST Excludes 5 DDL Types

**Affected doc:** Canonical v1.1 (Section 2.5 Priority Mandate mentions 13 types)
**Finding:** The Gatekeeper's TYPE_ALLOWLIST permits only 8 types: `project`, `journal`, `restart`, `snapshot`, `instruction_pack`, `branch`, `limb`, `leaf`. Types `grass`, `thorn`, `forest`, `thicket`, `flower` pass DDL CHECK but are rejected by the Gateway with `ARTIFACT_TYPE_NOT_ALLOWED`.
**Impact:** Payloads using grass, thorn, forest, thicket, or flower will fail with a 403 error.

### C-04: `extension` Not Required for All Save Types

**Affected doc:** Canonical v1.1 (Section 2.2 says extension "Required for save, update")
**Finding:** `branch` and `leaf` have spine-only passthrough — no extension table write occurs. Extension is optional for these types. Extension requirements are type-specific:
- `project`: requires `extension.lifecycle_stage`
- `snapshot`, `restart`: requires `extension.payload` (non-null object)
- `instruction_pack`: requires `extension.scope`, `extension.active`, `extension.priority`, `extension.pack_format`
- `journal`: requires `extension.entry_text` (ONLY — strict allow-list)
- `branch`, `leaf`: no extension required
- `limb`: shell INSERT only (just `artifact_id`)
**Impact:** Telling users extension is always required for save is inaccurate. Omitting type-specific requirements causes runtime failures (thorn `344f292f`).

### C-05: `extension` Not Required for Update (Tags-Only Path)

**Affected doc:** Canonical v1.1 (Section 2.2)
**Finding:** `artifact.update` accepts EITHER `extension` OR `tags` (with `.add`/`.remove` arrays). Tags-only updates work for ALL types including immutable ones (snapshot, restart, journal). The canonical doc says extension is "Required for save, update."
**Impact:** Users think they need extension for every update.

### C-06: `reason` Required for Promote but Not Documented

**Affected doc:** Canonical v1.1 (Section 2.2 Conditionally Required Fields)
**Finding:** `transition` is listed as required for promote. `reason` is NOT listed. Runtime requires `reason` as a non-empty string, 1-280 characters. Missing reason triggers `VALIDATION_ERROR`.
**Impact:** Promote payloads without reason will fail.

### C-07: snapshot/restart Require `extension.payload` Object

**Affected doc:** Not documented anywhere
**Finding:** Save v31 validation requires `extension.payload` to be a non-null, non-array object for both snapshot and restart types. This is the runtime requirement that caused thorn `344f292f`.
**Impact:** Snapshot/restart save payloads without `extension.payload` fail with `VALIDATION_ERROR`.

### C-08: Journal Extension Strict Allow-List

**Affected doc:** Not documented anywhere
**Finding:** Save v31 enforces a strict allow-list on journal extension: ONLY `entry_text` is permitted. Any other key (including `payload`) triggers `JOURNAL_EXTENSION_INVALID`. On UPDATE, this restriction is relaxed (payload is accepted via PATCH merge).
**Impact:** Journal save payloads with extra extension keys fail silently or with validation error.

### C-09: instruction_pack Requires 4 Extension Fields

**Affected doc:** Not documented in canonical
**Finding:** Save v31 requires `extension.scope` (string), `extension.active` (boolean), `extension.priority` (number), `extension.pack_format` (string) for instruction_pack INSERT. `pack_format` is validated as required but hardcoded to `"json"` on write regardless of caller value.
**Impact:** instruction_pack save payloads missing any of these 4 fields will fail.

### C-10: project Requires `extension.lifecycle_stage` on Save

**Affected doc:** Not documented in canonical
**Finding:** Save v31 validates that `extension.lifecycle_stage` must be a non-empty string for project INSERT. The normalizer also aligns `lifecycle_status` from `extension.lifecycle_stage` if not provided separately.
**Impact:** Project save payloads without lifecycle_stage fail.

### C-11: Only `operational_state` and `state_reason` Are Updateable for Project

**Affected doc:** Not documented
**Finding:** Update v12 mutability check for project allows ONLY `extension.operational_state` and `extension.state_reason`. `lifecycle_stage` in extension triggers `MUTABILITY_ERROR` with `PROMOTE_ONLY` hint. Any other field triggers `MUTABILITY_ERROR` with disallowed field list.
**Impact:** Project extension updates with fields other than operational_state/state_reason fail.

### C-12: Tags Filter Is Set Containment (NOT "Any-Of")

**Affected doc:** Not documented
**Finding:** List v29 uses PostgREST `cs.` operator for tag filtering. Field name is `tags_any` but semantics are tags_all (the artifact must contain ALL specified tags, not any of them).
**Impact:** Clients expecting "any of these tags" matching will get "all of these tags" matching.

### C-13: Hydrate Defaults Differ Between Query and List

**Affected doc:** Not documented
**Finding:** Query v18 defaults to hydrate=true (extension data fetched unless `hydrate === false`). List v29 defaults to hydrate=false (spine-only unless `hydrate === true`). Both use strict boolean comparison.
**Impact:** Users expecting consistent hydrate defaults across actions may get unexpected results.

---

## Major Findings (Misleading but Not Failing)

### M-01: "artifact.save Is CREATE ONLY" Is Incomplete

**Affected doc:** Canonical v1.1 (Contract Alignment section)
**Finding:** Save v31 has a full UPDATE path triggered when `artifact_id` is present and non-empty. The Gatekeeper does not validate or block `artifact_id` on save. The canonical doc says "artifact.save is CREATE ONLY" and "artifact_id: Forbidden for save."
**Impact:** The statement is the intended contract but does not match runtime. Save CAN perform updates if artifact_id is provided. This is a governance vs. implementation gap.

### M-02: "Future Actions" List Is Stale

**Affected doc:** Canonical v1.1 (Section 1 — "Does not cover: artifact.delete, artifact.archive")
**Finding:** `artifact.delete` and `artifact.restore` are live in Gateway v56. `artifact.archive` is not a separate action — it's the `tree_to_archive` lifecycle promotion. The "future" framing is incorrect.

### M-03: Selector Behavior Completely Undocumented

**Finding:** List supports: `limit` (default 50, max 200), `offset`, `hydrate`, `as_of` (paging anchor), `include_fields` (field projection), `filters.tags_any`, `parent_artifact_id`. Query supports only `hydrate`. None of this appears in the canonical doc.

### M-04: Tags Update Shape Undocumented in Canonical

**Finding:** Tags-only update uses `{ "tags": { "add": [...], "remove": [...] } }`. Tags and extension are mutually exclusive — providing both causes tags to be silently ignored. Remove wins over add if same tag appears in both arrays. Quick Reference has examples but canonical has nothing.

### M-05: Version Increment Rules Undocumented

**Finding:** Save INSERT: DB default 1. Tags-only update: +1. Project extension update: +1. Promote: +1. Branch/limb/leaf extension update via artifact.update: NO increment (returns ack without DB write — T51 gap). No documentation exists for version behavior.

### M-06: Mutability Registry Undocumented

**Finding:** Update v12 enforces a mutability registry: `snapshot`/`restart` = CREATE_ONLY (extension updates blocked). `journal` = UNDECIDED_BLOCKED (extension updates blocked, INSERT-only doctrine). `deleted_at` = UNDECIDED_BLOCKED for all types. Only `project` has real extension update support. Tags-only updates bypass mutability for all types.

### M-07: QPM Guard Logic Undocumented

**Finding:** `seed_to_sapling`: requires summary on spine OR at least 1 journal child (parent_artifact_id match). `sapling_to_tree`: requires at least 1 branch or leaf child. `tree_to_archive`: no guards. `limb` is NOT counted as execution child (only branch/leaf).

### M-08: Error Code Inventory Not Documented

**Finding:** The canonical doc shows one TYPE_MISMATCH example. Actual error codes across all workflows: `VALIDATION_ERROR`, `ACTION_NOT_ALLOWED`, `WORKSPACE_FORBIDDEN`, `ARTIFACT_TYPE_NOT_ALLOWED`, `NOT_FOUND`, `TYPE_MISMATCH`, `QUERY_RETURN_SHAPE_INVALID`, `CONFLICT`, `IMMUTABLE_RECORD`, `IMMUTABILITY_ERROR`, `JOURNAL_EXTENSION_INVALID`, `JOURNAL_MUTABILITY_UNDECIDED`, `MUTABILITY_ERROR`, `UPDATE_ONLY`, `LIFECYCLE_TRANSITION_NOT_ALLOWED`, `LIFECYCLE_STATE_MISMATCH`, `LIFECYCLE_STATE_UNKNOWN`, `FROM_STATE_MISSING`, `ARTIFACT_NOT_FOUND`, `PROMOTION_BLOCKED_SEED_NOT_READY`, `PROMOTION_BLOCKED_NO_ANATOMY`, `JOURNAL_COUNT_UNAVAILABLE`, `EXECUTION_COUNT_UNAVAILABLE`, `PAGINATION_WINDOW_EXCEEDED`, `INTERNAL_ERROR`.

### M-09: Gateway Accepts Field Aliases (Undocumented)

**Finding:** Normalize_Request accepts: `action` → `gw_action`, `workspace_id` → `gw_workspace_id`, `patch` → `extension`, `owner_username`/`created_by` → `auth_username`. Not documented. Clients may rely on undocumented aliases.

### M-10: branch/limb/leaf Extension Update Returns Fake Success

**Finding:** Update v12 routes branch/limb/leaf to `Return_Update_Ack` with `UPDATE_CONFIRMED` status but performs NO database write and NO version increment. The response `updated_fields` lists the requested fields, falsely implying persistence. This is the T51 gap.

### M-11: Priority Mandate Vs Runtime Default

**Finding:** Canonical v1.1 Section 2.5 says "do NOT rely on database DEFAULT 3" and insists on explicit priority. But Save v31 normalizer defaults priority to 3 (`req.priority ?? 3`). The workflow provides the default the doc says not to rely on.

### M-12: Non-Project/Branch/Limb/Leaf Extension Updates Silently Dead-End

**Finding:** Update v12's `Switch_Type_For_Update` has no fallback output. Types `grass`, `thorn`, `instruction_pack`, `video`, `forest`, `thicket`, `flower` that pass mutability checks but have no Switch case produce no output — the workflow silently terminates with no response.

---

## Minor Findings (Style or Clarity)

### m-01: `gw_user_id` Listed as Forbidden — Field Doesn't Exist

**Affected doc:** Canonical v1.1 Section 2.3
**Finding:** `gw_user_id` is listed as forbidden. This field name doesn't exist anywhere in schema or workflows. The actual forbidden field is `owner_user_id`.

### m-02: QUICK_REFERENCE Missing Spine Fields

**Affected doc:** QUICK_REFERENCE.md v2.1
**Finding:** Save examples don't show `parent_artifact_id`, `execution_status`, `summary`, `content`. These are valid optional spine fields for INSERT.

### m-03: LIFECYCLE_GUIDE Doesn't Specify Auth Method

**Affected doc:** LIFECYCLE_GUIDE.md v2
**Finding:** Promote examples show payloads but don't mention which endpoint or authentication method to use.

### m-04: List Default Limit Inconsistency in Response Shape

**Finding:** List v29 normalizer defaults limit to 50. But `Format_Base_Response` and `Format_Hydrated_Response` have a fallback display default of 25 in the selector echo. Minor display inconsistency.

### m-05: Double-Format Path in List (Potential Bug)

**Finding:** List v29 non-hydrated path routes through `Format_Base_Response` → `Format_Hydrated_Response`. The base formatter builds a complete response envelope, then the hydrated formatter processes it as a single item. May produce incorrectly nested output for non-hydrated list responses. Needs runtime verification.

### m-06: `neverError:true` Masks DB Write Failures in Update

**Finding:** Both `DB_Update_Spine_Tags` and `DB_Increment_Spine_Version` in Update v12 use `neverError: true`. PostgREST 4xx/5xx errors are swallowed. The workflow returns success even if the DB write fails.

---

## Migration Note

### Documents to Deprecate

| Document | Action |
|----------|--------|
| `Qwrk_Gateway_JSON_Payload_Canonical_v1.md` (v1.1) | Archive. Superseded by vNext. |
| `Archive/Qwrk_Gateway_JSON_Payload_Canonical_v1__v1__2026-02-16.md` | Already archived. No action. |

### Documents to Preserve (With Updates Recommended)

| Document | Status | Notes |
|----------|--------|-------|
| `QUICK_REFERENCE.md` v2.1 | Working examples are correct | Add missing spine fields (m-02). Align with vNext field requirements. |
| `LIFECYCLE_GUIDE.md` v2 | Correct lifecycle stages | Add auth method note (m-03). Examples valid. |
| `Demo_Mode_IP_v2.md` | Correct payload rules | Section 7.2 hydration template is accurate. No changes needed. |
| `WORKFLOW_PATTERNS.md` | Pattern-level guidance only | No payload specs to update. |

### Examples That Must Be Removed or Updated

None of the existing Quick Reference examples would fail at runtime. However, they are incomplete — they lack type-specific extension requirements that ARE enforced. The vNext document provides complete minimal valid payloads for all action+type combinations.

---

## Resolution Status (2026-02-21)

**Canonical Authority Alignment — COMPLETE.**

- **Resolution anchor:** `Qwrk_Gateway_Payload_Canonical_v2.md` (Status: Authoritative, Date: 2026-02-20)
- **v1.1 archived:** `Archive/Qwrk_Gateway_JSON_Payload_Canonical_v1__v1.1__2026-02-20.md`. Removed from active directory 2026-02-21.
- **Instruction references updated:** Q system instructions v2_5_35 now points to Canonical v2 (3 pointer changes). Previous: `Archive/Qwrk_SYSTEM_INSTRUCTIONS_2_5_34__2026-02-20.md`.
- **No runtime logic modified.** Documentation alignment only.

All "vNext" references in this report refer to `Qwrk_Gateway_Payload_Canonical_v2.md`.

---

*Source: CC Payload Contract Alignment Audit v1, executed 2026-02-20. Behavioral truth extracted from Gateway v56, Save v31, Query v18, List v29, Update v12, Promote v2_HTTP.*
