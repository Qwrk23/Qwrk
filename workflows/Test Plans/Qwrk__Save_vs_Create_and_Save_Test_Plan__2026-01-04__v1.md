# Qwrk Kernel v1 — Save vs Create Decision + Save Workflow Test Plan (v1)
**Date:** 2026-01-04 (CST)  
**Scope:** NQxb_Artifact_Save_v1 + NQxb_Artifact_Create_v1 + Gateway “artifact.save” routing

---

## Synopsis (what we’re doing)
We’re standardizing how Qwrk writes artifacts to Supabase through n8n so the future front-end can **always** send a consistent JSON payload and get back a fully-hydrated artifact.  
To get “right the first time, every time,” we’re:
1) choosing a clean contract (**create** vs **save**),  
2) proving the **save** path end-to-end via Gateway (auth → routing → DB write → query hydration), and  
3) hardening the Gateway so “save” calls the correct subworkflow branch.

---

## Decision: should we use Save or Create?
### Recommended: use **both** (now), converge later if desired
**Use `artifact.create` when you want strict insert-only behavior**:
- safest for **immutable** types (snapshot, restart)
- prevents accidental updates because it *rejects* `artifact_id`

**Use `artifact.save` when you want “smart write” behavior**:
- INSERT when `artifact_id` is absent
- UPDATE (PATCH semantics) when `artifact_id` is present
- best for **mutable** types (project, journal)

### Why both is the “Old Bull” move
- **Create** is a guardrail endpoint that can never mutate history.
- **Save** is the ergonomic endpoint the UI will want (one button, one contract).
- Keeping both avoids painting ourselves into a corner: the UI can use Save, while governance tools can still enforce Create-only for immutable records.

### Suggested contract rule (simple)
- `snapshot`, `restart` → **CREATE only** (and Save should reject UPDATE already)
- `project`, `journal` → **SAVE** (INSERT + UPDATE)

---

## What we will test next (Save workflow)
We’ll do an end-to-end proof that **Gateway → Save → Supabase → Query hydration** works for:
1) **INSERT project** (no artifact_id)  
2) **UPDATE project** (with artifact_id, partial PATCH)  
3) **INSERT journal**  
4) **UPDATE journal** (entry_text and/or payload)  
5) Negative tests: validation errors, NOT_FOUND, immutability error

---

## Quick health check on the workflows you uploaded
### NQxb_Artifact_Create_v1
- Enforces create-only by rejecting any request that includes `artifact_id`.
- Validates required fields for INSERT.
- Inserts spine → inserts extension by type → calls Query to return hydrated artifact.

### NQxb_Artifact_Save_v1
- Supports INSERT vs UPDATE based on presence of `artifact_id`.
- Implements PATCH semantics using `_provided_fields` for spine, and “field existence” checks for extensions.
- Blocks UPDATE for `restart` and `snapshot` (immutability guard).
- For UPDATE project/journal, performs extension UPSERT behavior (update if exists, else insert).
- Ends by calling Query to return hydrated artifact.

---

## Gateway work required (what will likely break first)
To test “save via Gateway,” the Gateway must:
- accept `gw_action: "artifact.save"`
- route to the **Execute Workflow** node that calls `NQxb_Artifact_Save_v1`
- pass through the request payload **without nesting surprises** (Save handles both “flat” and `{ body: ... }`, which is good)

If routing fails, you’ll see:
- `_gw_route` missing / wrong
- the gateway returning “ok route” but empty `data`
- or the gateway’s auth guard failing before it reaches the save branch

---

## CC Prompt: build the Gateway “artifact.save” branch
Paste this into Claude Code:

```markdown
You are working in repo: new-qwrk-kernel.

Goal: Add Gateway routing for gw_action="artifact.save" to call subworkflow NQxb_Artifact_Save_v1, matching the existing query routing pattern.

Constraints:
- Use docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql as schema truth.
- Do NOT change Save workflow logic unless required for routing compatibility.
- Gateway must return consistent envelope:
  { ok: true/false, _gw_route: "...", data: {...} }.

Tasks:
1) Open and inspect workflow export: docs (or root) file for NQxb_Gateway_v1 (the latest).
2) Identify the existing Switch (or router) that selects gw_action.
3) Add a new case for "artifact.save" that:
   - calls Execute Workflow node pointing to workflow name "NQxb_Artifact_Save_v1"
   - forwards the inbound request object as inputData
4) Ensure the gateway returns the Save subworkflow output as:
   data: { artifact: <hydrated artifact response from Query> }
   preserving ok/_gw_route if provided by downstream.
5) Add a short KG proof section in docs/kg/KG_Proofs__Kernel_v1.md describing:
   - what changed
   - how to test via gateway
   - expected success response shape

Deliverables:
- Updated Gateway workflow export file committed
- KG proof committed
```

---

## How to run the Save tests (step-by-step)
1) **Confirm the Save workflow exists in n8n** as `NQxb_Artifact_Save_v1` and is enabled.
2) **Confirm the Gateway includes an `artifact.save` route** that calls that subworkflow.
3) Use the **Gateway webhook** (production or test) with Basic Auth.
4) Start with **INSERT project**:
   - omit `artifact_id`
   - include `gw_workspace_id`, `owner_user_id`, `artifact_type`, `title`
   - for project: include `extension.lifecycle_stage`
5) Capture the returned `artifact_id`.
6) Run **UPDATE project**:
   - include `artifact_id`
   - send only one changed field (ex: `summary`) to verify PATCH semantics
7) Repeat for **journal** (insert then update entry_text).

---

## Expected “good” response shape
From Gateway, success should look like:
- `ok: true`
- `_gw_route: ok`
- `data.artifact.artifact_id` present
- `data.artifact.extension` present for the type (project/journal)
- `created_at/updated_at` populated

---

## Common failure modes & what they mean
- **403 Forbidden**: Basic Auth missing/wrong at gateway ingress.
- **VALIDATION_ERROR**: Save/Create validator correctly rejected your payload.
- **NOT_FOUND** on UPDATE: artifact_id doesn’t exist in that workspace.
- **extension insert error**: type switch mismatch or missing required extension fields.
- **Supabase update returns empty**: RLS or filters didn’t match (workspace_id mismatch is common).

---
