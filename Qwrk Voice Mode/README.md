# Qwrk Voice — Project Files

## What Qwrk Voice Is

Qwrk Voice is a lightweight, voice-first ChatGPT Project.

Its purpose: let Joel capture and shape spoken intent when he can't type — driving, hands-busy, mobile, away from desk — and hand that intent back to Qwrk Prime for governance, validation, and execution.

**Voice is a capture + shaping surface. Nothing more.**

## What Qwrk Voice Is NOT

- **Not Prime-lite.** Voice does not replicate Prime's governance, payload discipline, CmdCtr, instruction packs, or full execution surface.
- **Not a Gateway executor.** Default output is a Prime-ready prompt, not a payload. Voice can produce a finalized journal capture (Template 5) as a rare explicit-override path — but Joel still executes it via QSB/Prime. Voice never runs saves itself.
- **Not a retrieval surface.** Voice does NOT emit `artifact.list` or `artifact.query` payloads. Retrieval happens in Prime.
- **Not a decision-maker.** When classification is uncertain, Voice flags — it does not guess.
- **Not a continuity layer.** Voice has no access to Prime conversations, uploaded Prime files, or prior artifacts unless Joel provides them in the current turn.

## Voice Drift Red Flags

Watch for these signals that Voice is slipping into Prime-lite behavior. If you spot one in the field, interrupt and redirect.

- **Deciding instead of suggesting.** Voice proposes; Prime validates. If Voice speaks as if a decision is final, that's drift.
- **Response latency or hedging.** If Voice takes more than a beat to respond, or hedges with multiple qualifications before suggesting, it is reasoning past its scope — flag uncertainty and defer instead.
- **Output unsafe for driving.** If the spoken output requires visual attention (reading a long list, recalling a UUID, parsing structure aloud), that is a violation of the driving-safe rule.
- **Payload generation as default.** Payloads are a rare, explicit-override path (journal only). If Voice emits a payload without Joel explicitly asking, that's drift.
- **Shifting classification burden to Joel.** When uncertain, Voice flags uncertainty and routes to Prime. Asking Joel to choose the artifact or semantic type is drift.

## Files

| File | Purpose |
|---|---|
| `Qwrk_Voice_SYSTEM_INSTRUCTIONS.md` | System Instructions for the Qwrk Voice Custom GPT |
| `Qwrk_Voice_Artifact_Selection_Guide.md` | Voice-scoped guide for suggesting artifact type |
| `Qwrk_Voice_Semantic_Type_Guide.md` | Voice-scoped guide for suggesting semantic type |
| `Qwrk_Voice_Contextual_Memory.md` | How Voice uses shared memory for personalization and handoff shaping |
| `Qwrk_Voice_Prime_Handoff_Template.md` | Copy/paste templates for handing off to Prime |
| `README.md` | This file — project orientation |

## How to Use

1. Create a new ChatGPT Custom GPT named "Qwrk Voice."
2. Paste the contents of `Qwrk_Voice_SYSTEM_INSTRUCTIONS.md` into the Custom GPT's Instructions field.
3. Upload the other three `.md` files (Artifact Selection, Semantic Type, Prime Handoff Template) to the Custom GPT's Knowledge.
4. Enable ChatGPT voice on the GPT.
5. Use Qwrk Voice when you cannot type. When you return to the desk, paste the generated handoff prompt into Qwrk Prime.

## How to Test

**Smoke test checklist — run before routine use:**

- [ ] **Brevity:** Say "hello." Voice responds in 1–3 sentences.
- [ ] **One question:** Describe a rough idea. Voice asks at most one clarifying question.
- [ ] **Capture flow:** Describe a thought. Voice cleans it, suggests artifact type, produces a Prime-ready prompt.
- [ ] **Uncertainty:** Describe something ambiguous. Voice flags uncertainty in the handoff prompt, does not guess.
- [ ] **Garbled input:** Mumble something. Voice responds exactly: *"I didn't catch that. Could you repeat?"*
- [ ] **Scope boundary:** Ask Voice to promote, update, or send an email. Voice declines and generates a Template 3 handoff prompt instead.
- [ ] **Silent payload:** If Voice ever emits a `prime-exec` block (only on explicit request), it does NOT read the JSON aloud.
- [ ] **Memory boundary:** Ask Voice about a past Prime conversation. Voice acknowledges it has no access and offers to capture fresh intent.
- [ ] **Messy input:** Give Voice a rambling, multi-topic utterance. Voice produces a clean handoff or flags uncertainty — never over-analyzes.
- [ ] **Memory usage (positive):** Reference a known Qwrk project or person by name. Voice acknowledges context appropriately; handoff prompt includes inferred context marked as memory-based.
- [ ] **Memory absence (negative):** Reference a project or person Voice shouldn't know. Voice does NOT invent — flags unknown and defers to Prime.

## Review Workflow (Before Adding to ChatGPT Project)

1. Read `Qwrk_Voice_SYSTEM_INSTRUCTIONS.md` — does it match Joel's current intent? Any rules missing or overreaching?
2. Review `Qwrk_Voice_Artifact_Selection_Guide.md` — any types missing, any scope creep beyond capture?
3. Review `Qwrk_Voice_Semantic_Type_Guide.md` — confirm the 9 values match the Qwrk Prime registry exactly.
4. Review `Qwrk_Voice_Prime_Handoff_Template.md` — are the templates genuinely copy/paste ready? Do the angle-bracket placeholders scan cleanly?
5. Adjust tone if needed — warm, familiar, concise, grounded.
6. Upload to the ChatGPT Custom GPT only after review.

## Governance

- **Behavioral contract:** QVM snapshot `e14754e1-5b1e-4eb5-9356-c2fde1b68937` (Qwrk Prime workspace). Voice SI mirrors this contract for runtime availability.
- **Architectural framing:** Voice is a separate surface, not a Prime overlay. See pivot snapshot `9d3b1515-5bbc-4337-af6f-ba0e3422081d` for the structural decision.
- **Drift discipline:** If Prime's Gateway contract changes in a way that affects journal save schema, update the Voice Template 5 payload in the same change set.

## Status

Initial draft — awaiting Joel + Q review before deployment.
