# RESTART: BUG-019 Structural Hallucination Fix

**Created:** 2026-02-03
**Bug:** BUG-019 — artifact.save reports success with hallucinated artifact_id
**Status:** Implementation ready

---

## Objective (Non-Negotiable)

Update the **Gateway_Telegram workflow** so that it is **architecturally impossible** for an LLM to fabricate a successful save response.

Specifically:
- The AI (GPT-4o) must NEVER be the source of truth for `artifact_id`
- A Telegram "save success" message must ONLY be sent if `Tool_Save_Project` actually executed and returned a real `artifact_id`
- If the tool is skipped, fails, or returns no ID, the user must NOT receive a success response

This change must permanently eliminate the class of failure where the AI "knows what should happen" and hallucinates a UUID without calling the Gateway.

---

## Context

We identified a production bug where:
- Gateway_Telegram executed
- The AI agent (previously GPT-4o-mini) decided NOT to call `Tool_Save_Project`
- The AI hallucinated a plausible UUID
- Telegram received a fake "save succeeded" message
- Gateway_v1 and the database were never called

We are switching the model to **GPT-4o** for improved stability, but this is NOT relied on for correctness.
**Structural enforcement is required.**

---

## Important Context: Qwrk → Telegram = Natural Language

Qwrk front-end sends **natural language prompts** to Telegram, NOT formatted JSON.

Example input:
```
Save project titled "Seed — Canvas-First Prompt Review Paradigm" with tags seed, governance, ux: Establish a new default behavior for Qwrk...
```

The AI Agent in Gateway_Telegram parses this natural language and decides which tools to call. The hallucination bug occurs when the AI decides to skip the tool call entirely and fabricate the response.

---

## Required Architectural Change (Option B)

### Hard Rule
The AI agent must NOT:
- Extract `artifact_id`
- Emit `artifact_id`
- Construct the success response that includes `artifact_id`

### Instead
- The workflow must programmatically extract `artifact_id` from the HTTP response returned by `Tool_Save_Project`
- The Telegram success message must be built exclusively from this extracted value
- If the tool does not run or returns no ID, the workflow must send an explicit failure message

---

## Implementation Requirements

1. **Model Update**
   - Update the Qwrk AI Agent node to use **GPT-4o**
   - Do NOT change agent instructions beyond what is necessary for compatibility

2. **Tool Invocation Enforcement**
   - Ensure `Tool_Save_Project` is the only node capable of producing an `artifact_id`
   - Capture its raw HTTP response

3. **Structured Extraction**
   - Add a deterministic Set (or equivalent) node that extracts:
     - `artifact_id` from the tool response
   - No LLM parsing or interpretation allowed for this value

4. **Conditional Guardrail**
   - Add a conditional check:
     - IF `artifact_id` exists → proceed to success response
     - IF missing/null → send failure message indicating save did not occur

5. **Telegram Response Construction**
   - Build the success message ONLY from the extracted `artifact_id`
   - The AI agent's natural language output must NOT be used as message content for saves

6. **Failure Behavior**
   - If the tool was skipped or failed:
     - Telegram should receive a clear failure message
     - No UUID should be shown
     - No implication that persistence occurred

---

## Explicit Non-Goals (Do NOT Do These)

- Do NOT attempt to "fix" this via stronger prompts
- Do NOT rely on the model "always calling the tool"
- Do NOT allow the AI to generate fallback UUIDs
- Do NOT silently fail or "best-effort" a response

If the system cannot prove the save occurred, it must say so.

---

## Files / Artifacts

Primary target:
- `NQxb_Gateway_Telegram_v1.json` (or latest active version)

Do not modify:
- Gateway_v1 workflow logic
- Database schema
- Supabase functions

This is a Telegram-side enforcement fix only.

---

## Validation Criteria (Must Be Verifiable)

After implementation, verify:

1. A successful save:
   - Triggers Gateway_v1
   - Writes to the database
   - Returns a real `artifact_id`
   - Telegram message includes that exact ID

2. A simulated failure (tool not called or forced failure):
   - Gateway_v1 is NOT triggered
   - No database write occurs
   - Telegram does NOT receive a success message
   - No UUID is shown

3. There is no execution path where:
   - Telegram receives a success message
   - AND Gateway_v1 did not run

---

## Output Requested

1. Summary of changes made
2. Exact nodes added/modified (by name)
3. Before/after explanation of how `artifact_id` flows
4. Any risks or edge cases to be aware of
5. Confirmation that the AI can no longer fabricate persistence success

---

## Key Documents

- Bug tracker: `docs/Qwrk_Bug_Tracker.md` (BUG-019)
- Current workflow: `phase1.5-chat-gateway/NQxb_Gateway_Telegram_v1.json` (or numbered version)
