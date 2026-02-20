# Conversation Restart — Gateway ACL Enforcement (Paused)

## Session Status
We intentionally **paused implementation** and rolled back to a safe state.

- The **edited Gateway workflow** (with ACL_Lookup + ACL_Guard nodes added) has been **archived/exported**.
- The **pre-ACL Gateway workflow** has been **re-activated** so production traffic is functional.
- No further wiring (Gatekeeper / Respond nodes) has been completed.

This pause was triggered by a **hard runtime error**:
- n8n instance is running with:
  ```
  N8N_BLOCK_ENV_ACCESS_IN_NODE=true
  ```
- As a result, **$env.* expressions are blocked even during real webhook execution**.
- The current ACL_Lookup node (which references `$env.SUPABASE_URL` and `$env.SUPABASE_SERVICE_ROLE_KEY`) **cannot work in this environment**.

This is a *confirmed runtime constraint*, not an editor-only limitation.

---

## Where We Stopped (Exact Point)

We stopped **immediately after**:

- Adding `NQxb_Gateway_v1__ACL_Lookup` (HTTP Request → Supabase `qxb_gateway_acl`)
- Adding `NQxb_Gateway_v1__ACL_Guard__HasRow` (IF node using `{{$json.length}} > 0`)

We **did NOT**:
- Wire true/false branches
- Modify Gatekeeper
- Add deny responses
- Activate ACL enforcement

The workflow is in a **safe, incomplete, non-enforcing state**.

---

## Resume Instructions (For Next Session)

At the start of the next session:

1. **Ask Joel to restore and upload** the archived **edited Gateway workflow** (the ACL-in-progress version).
2. Confirm we are resuming at:
   - **Step 9 (revision required)** — ACL_Lookup implementation
3. Acknowledge the constraint:
   - `$env.* cannot be used inside nodes`
4. Pivot the design to a **credentials-based Supabase access pattern** (n8n Credentials), not env expressions.

Only after the credential strategy is agreed should we:
- Rebuild `ACL_Lookup` correctly
- Re-run the PowerShell Gateway test
- Continue to **Step 10 (Gatekeeper enforcement)**

---

## Guardrails

- Do **not** assume env access will work
- Do **not** rewire Gatekeeper prematurely
- Keep rollback path intact until first successful end-to-end ACL test

---

## Opening Prompt for the Next Conversation

> "We paused Gateway ACL enforcement due to a confirmed `N8N_BLOCK_ENV_ACCESS_IN_NODE` runtime constraint. I’ve restored the archived ACL-in-progress Gateway workflow. Let’s resume at Step 9 by redesigning ACL_Lookup to use n8n credentials instead of `$env`, then re-test the Gateway before enforcing anything."

