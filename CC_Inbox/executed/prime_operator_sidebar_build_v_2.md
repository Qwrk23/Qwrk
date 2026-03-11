# PROMPT — Build Prime Operator Sidebar (QSB) v2

INTENT:
Design and implement a separate Chrome extension called **Qwrk Prime Sidebar (QSB)** for internal Prime use only.

This extension is NOT public-facing.
This extension must NOT modify QX.
QX remains installed and operational as fallback.

---

## PRIMARY OBJECTIVE

Reduce execution latency between conversational intent and Gateway execution while preserving:

• Canonical v2 payload contract  
• Sequential discipline  
• Single-operation staging  
• Deterministic lifecycle semantics  
• Workspace isolation  
• Raw JSON invariant (QX)  

QSB is a UI transport layer only.  
It must NOT introduce business logic.

---

## ARCHITECTURAL CONSTRAINTS (NON-NEGOTIABLE)

1. Separate Chrome extension (different manifest, different build).
2. Use **Manifest V3**.
3. ChatGPT-only surface (chat.openai.com + chatgpt.com).
4. Thin bar injected ABOVE the message input area.
5. Shadow DOM isolation.
6. Multi-workspace support (same model as QX today).
7. Exactly ONE staged execution at a time.
8. QX remains fully functional and unchanged.
9. QSB must execute only fully-formed Gateway-ready JSON payloads.
10. QSB must NOT construct, mutate, or infer payload structure.
11. Raw Gateway error payloads must be displayed during hardening phase.
12. No cross-extension messaging with QX.

---

## GATEWAY INTEGRATION

• Gateway base URL and auth token are stored per workspace profile in extension local storage.
• Use placeholder values for MVP scaffolding if needed.
• Authentication: Bearer token header ("Authorization: Bearer <token>").
• QSB sends payload exactly as received inside the prime-exec block.
• QSB must NOT inject or modify workspace ID or any payload field.
• The PrimeExecutionObject already contains the correct gw_workspace_id.

---

## PRIMEEXECUTIONOBJECT FORMAT

Prime (model) will emit:

```prime-exec
{ FULL GATEWAY-READY JSON PAYLOAD }
```

Rules:

• Exactly one object inside block.
• No commentary inside block.
• Sidebar parses only blocks labeled `prime-exec`.
• Only the most recent valid block is staged.
• New block replaces previous staged block.
• Staged block clears after successful execution.
• Failed execution does NOT auto-clear staged block.
• No auto-execution ever.

---

## PARSER STRATEGY

• Use MutationObserver on the ChatGPT message list container.
• Scan only the most recent assistant message for `prime-exec` blocks.
• Do NOT scan entire thread history.
• Do NOT parse user messages.
• On detection, validate JSON parse success before enabling Execute.

---

## CORE UX MODEL

Conversation → PrimeExecutionObject emitted → Manual Execute → Gateway call → Execution log updated.

No automatic execution.
No payload inference.
No queueing.
No batch operations.

---

## QSB MVP FEATURES

1. Thin execution bar above ChatGPT input:
   [ Execute ]   [ Clear ]   [ Workspace ▼ ]   [ QX (Debug) ]

2. Execution state indicator:
   - "No staged operation"
   - "1 staged operation ready"

3. Session execution log (thin, below bar):
   ✔ Project Saved — short-id  
   ✖ Validation Error — expandable raw JSON

4. Embedded QX Debug Toggle:
   • QSB contains its own raw JSON viewer panel (no cross-extension communication).
   • Styled similarly to QX.
   • Standalone QX extension remains installed and usable.

---

## WORKSPACE SUPPORT

• Support multiple workspace profiles (like QX today).
• Visible workspace selector.
• No silent workspace switching.
• QSB does NOT inject workspace ID — payload must already contain it.

---

## ERROR HANDLING (Hardening Phase)

• Display full raw Gateway error payload.
• Allow copy of raw error JSON.
• Do NOT simplify error messages yet.
• Do NOT suppress validation errors.

---

## STATE MANAGEMENT

• Exactly one staged object allowed.
• Replace staged object only when new prime-exec block appears.
• Clear staged object on successful execution.
• Clear staged object on thread/conversation switch (SPA navigation).
• Clear staged object on full page reload.
• No persistence of staged object across sessions.

---

## DOM STRATEGY

• Inject via content script.
• Use Shadow DOM for UI isolation.
• Position relative to input container.
• Use MutationObserver to re-anchor if DOM shifts.
• Avoid injecting inside React tree.

---

## TECH STACK

• Vanilla JavaScript.
• No framework.
• No bundler.
• Plain CSS.
• Minimal modular file structure.

---

## NON-GOALS (DO NOT BUILD)

• No artifact editing UI.
• No lifecycle promotion UI.
• No queueing.
• No dashboard.
• No thread parsing beyond most recent assistant message.
• No AI summarization.
• No Beta/public shipping logic.
• No version auto-update mechanism (manual sideload only).

---

## BUILD ORDER

1. Scaffold extension (Manifest V3).
2. Implement DOM injection bar.
3. Implement PrimeExecutionObject parser.
4. Implement single staged-object state machine.
5. Implement Execute flow (fetch → Gateway).
6. Implement execution log.
7. Implement workspace selector.
8. Implement embedded QX debug viewer.
9. Add defensive validation.

---

## DELIVERABLES

• Full extension folder structure.
• manifest.json (MV3).
• Content script.
• Background service worker (if required).
• State manager module.
• Execution handler module.
• Minimal CSS (isolated).
• Clear README for internal install/testing.

---

## OPERATING MODE

If assumptions are required:
ASK before implementing.

Do NOT overbuild.
Do NOT abstract prematurely.
Do NOT introduce conversion layers.

This is Prime internal tooling.

Proceed.

