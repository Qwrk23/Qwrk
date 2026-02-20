# AAA_New_Qwrk — Snapshot — Kernel v1 Freeze + Gateway Save Next (v1)
**Timestamp:** 2026-01-04 (America/Chicago)  
**Snapshot Type:** Build State / Governance  
**Status:** Locked  
**Build Phase:** Transition — Query Proven → Save Branch Build

---

## 1) Current Objective
Freeze what is **Known‑Good** for Kernel v1 (schema truth + DB patterns + Gateway query), and set the next gated objective: **Gateway v1 “save” routing + troubleshooting** (Call Subworkflow branch).

---

## 2) Triggers (why this Snapshot exists)
- Coherent decision branch completed (proof chain finished)
- Multiple decisions locked (Kernel v1 frozen scope, KG proofs committed)
- Phase transition (Query proven → Save branch build)

---

## 3) Decisions Locked
1. **Kernel v1 is frozen** for:
   - Canonical schema truth via LIVE DDL
   - NoFail insert patterns v1.1 (thorn corrected)
   - Proven event log append + query
   - Proven Gateway v1 `artifact.query` hydration for allow‑listed types

2. **Gateway “save” is NOT yet Known‑Good**
   - Requires troubleshooting and implementation of a **Call Subworkflow** branch for save in Gateway v1.

3. **No silent overwrites**
   - Any corrections to docs/templates must be versioned (v1 → v1.1) and prior versions marked superseded.

---

## 4) Known‑Good Evidence (Artifacts + Commits)
### Canonical DDL
- `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`

### Canonical Templates
- `docs/sql_templates/Kernel_v1__NoFail_Inserts__v1.1.md`

### KG Proof Log
- `docs/kg/KG_Proofs__Kernel_v1.md`

### Commits (repo)
- `513ebde` — Add KG proof record for Thorn insert/query
- `f42938d` — Add KG proof for Gateway v1 artifact.query (snapshot hydration)

---

## 5) KG Proof Results (Operational)
### A) Thorn write + read (PASS)
- Thorn artifact inserted and joined retrieval confirmed.
- Example Thorn artifact_id: `cf7e3447-8c42-445d-a925-83add6f30617`

### B) Event log append + read (PASS)
- Event appended and retrieved successfully.
- event_id: `fe36bb6c-cb33-46c7-90fa-3fc314ee7946`

### C) Gateway query hydration (PASS)
- Endpoint: `https://n8n.halosparkai.com/webhook/nqxb/gateway/v1`
- Allow‑listed type tested: `snapshot`
- artifact_id queried: `95f0ba11-27d5-4c8b-88f4-08f1fbcf9672`
- Response: `ok=true`, `_gw_route=ok`, hydrated `data.artifact` including `extension.payload`.

---

## 6) Open Work (Next Gated Objective)
### Gateway v1 — Save Branch
We still must:
1. Troubleshoot `artifact.save` behavior
2. Implement the **Gateway save routing branch** using **Call Subworkflow**
3. Align request/response contract for save with the live subworkflow inputs
4. Produce KG proofs:
   - Save (via Gateway) for an allow‑listed type (recommend: journal or snapshot)
   - Query back (via Gateway)
   - Record proof to `docs/kg/KG_Proofs__Kernel_v1.md` and commit

---

## 7) Next 1–2 Actions
1. Inspect attached/active Gateway v1 workflow to confirm current routing and missing save branch.
2. Design + implement Call Subworkflow branch for `gw_action = artifact.save`, then run KG save proof.

---

## 8) Notes / Guardrails
- Treat `artifact.save` as a separate proof track; do not expand allow‑lists or alter query behavior while save is being stabilized.
- Continue Old Bull discipline: prove → document → commit.
