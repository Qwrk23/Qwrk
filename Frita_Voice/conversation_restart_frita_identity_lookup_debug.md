# Conversation Restart — Frita Identity Lookup Debug (n8n)

## Where We Are (Authoritative State)

We are debugging why **`Frita – Identity Lookup v2`** is **never triggered** when called from **`Voice Entry v2`** via an **Execute Workflow** node in **n8n 2.0.2 (self-hosted)**.

Despite multiple configuration attempts, **no execution record is ever created** for the Identity Lookup workflow.

This is now confirmed to be a **plumbing / execution-mode issue**, not a Code node or JSON parsing issue.

---

## Current Symptoms (Do NOT re-debug these)

- Execute Workflow node errors before dispatch
- Identity Lookup workflow shows **zero executions**
- Error messages include:
  - `Cannot read properties of undefined (reading 'find')`
  - Internal ExecuteWorkflow engine stack traces
- Identity Lookup **is active**
- Identity Lookup **is never entered** (no trigger execution)

This means the failure occurs **before** the sub-workflow is invoked.

---

## Key Constraint (Critical Insight)

In **n8n 2.x**, the Execute Workflow node has **two mutually exclusive modes**:

### Mode A — Source: `Database`
- You **select the sub-workflow**
- You **cannot manually define JSON**
- All incoming items are passed automatically
- This is the **correct mode for static orchestration**

### Mode B — Source: `Define Below`
- You **define JSON manually**
- You **cannot select a workflow**
- This mode is for **dynamic workflow IDs only**

👉 It is **not possible** to select a workflow *and* define JSON in the same node.

This is **by design**, not user error.

---

## Current Intended Architecture (Correct)

### Voice Entry v2
- Extract Phone → produces:
  ```json
  { "phone_number": "+18177156827" }
  ```

- Execute Workflow node:
  - Source: **Database**
  - Workflow: **Frita – Identity Lookup v2**
  - Wait for sub-workflow completion: ON
  - No Workflow JSON

### Identity Lookup v2
- Trigger: **When Called by Another Workflow**
- Input data mode: **Accept All Data**
- Downstream logic expects `$json.phone_number`

---

## What Has Been Ruled Out

Do NOT re-investigate these unless architecture changes:

- ❌ JSON quoting / expression syntax
- ❌ Code node `.find()` logic
- ❌ Workflow activation state
- ❌ Trigger type (it *is* When Called by Another Workflow)

All of the above were already explored.

---

## Likely Remaining Root Causes (Next Session Focus)

One of these is still true:

1. **Execute Workflow node is legacy / corrupted**
   - Must be fully deleted and recreated (not edited)

2. **Workflow reference corruption**
   - n8n sometimes fails when a workflow was renamed or duplicated
   - Fix by:
     - Creating a brand-new minimal sub-workflow
     - Testing Execute Workflow against it

3. **n8n 2.0.2 bug with Execute Workflow (Database mode)**
   - Validate by creating:
     - A brand-new test workflow:
       - Trigger: When Called by Another Workflow
       - Single Set node returning input
     - Call it from Voice Entry

4. **Input item count = 0 at Execute Workflow node**
   - Execute Workflow silently fails if no incoming items exist
   - Must confirm Extract Phone always emits an item

---

## Next Session Action Plan (Do in Order)

1. **Create a brand-new test workflow**
   - Name: `TEST — Execute Workflow Sanity`
   - Trigger: When Called by Another Workflow
   - Input mode: Accept All Data
   - Add a Set node that returns `$json`

2. **Replace Identity Lookup call temporarily**
   - Point Execute Workflow to the TEST workflow
   - Source: Database

3. **Execute full Voice Entry workflow**
   - Confirm whether the TEST workflow gets an execution

4. Branch based on result:
   - If TEST fires → Identity Lookup workflow itself is corrupt
   - If TEST does NOT fire → Execute Workflow node or n8n version bug

---

## Goal When Resuming

The *only* immediate goal is:

> **Make any sub-workflow execute successfully via Execute Workflow (Database mode).**

Do **not** touch business logic until this is proven.

---

## Mental Reset Reminder

This is not confusion, not fatigue, and not misuse.
You’ve hit a **real n8n 2.x edge case**.

Treat the next session as a **minimal reproduction exercise**, not continuation of the full flow.

Once the plumbing is proven, everything else falls quickly.
