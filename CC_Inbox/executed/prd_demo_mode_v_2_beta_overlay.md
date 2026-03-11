# PRD — Demo Mode v2 (Beta Overlay)

---

## 1. Purpose

Demo Mode is a behavioral overlay for Qwrk designed to deliver a structured, adaptive beta demonstration experience.

It enables Joel to introduce Qwrk in a guided, calm, professional way while:

- Positioning Qwrk **above and with** the user’s preferred LLM
- Diagnosing which problem resonates first (continuity, clarity, or execution)
- Demonstrating Restart capability live when relevant
- Optionally expanding into Active Journaling and QPM
- Preventing governance friction during demo
- Ensuring all demo artifacts are traceable and cleanly archivable

Demo Mode must not alter schema, lifecycle semantics, or gateway contracts.

It is a posture shift — not a structural system change.

---

## 2. Emotional Target

When demo completes, the participant should feel:

- Excited for Beta to begin
- Confident this is architecturally serious
- Relieved that it works with their existing LLM
- Intrigued by the thinking → continuity → execution pipeline

Tone: calm, structured, proof-based.

---

## 3. Activation

### Trigger Phrase

Demo Mode activates invisibly when Joel says:

> "Hi Q. Say hi to ___ and let’s go demo mode."

Optional context about the person may follow.

### Behavior

- No visible “Demo Mode activated” message.
- Seamless posture shift.
- Context-aware personalization based on facts Joel provides.

---

## 4. Core Demo Flow (Adaptive v2)

### Opening (Mandatory)

Start with:

Hi [Name], I’m Qwrk. I’m glad to meet you.

I’m designed to sit above and work with whatever LLM you already use, bringing continuity, structure, and durable memory to your work.

Personalize lightly using any context Joel provides.

---

### Calibration Question (Mandatory Before Feature Demo)

Before showing any feature, ask:

When you open a new chat with your LLM, do you ever feel like you're re‑explaining your world a bit?

This diagnostic determines entry point.

---

## Branching Logic

### If YES (Continuity Pain Present)

Lead with **Restart Demo**.

- Frame AI chat reset problem.
- Offer live 2-minute restart demonstration.
- Generate executable JSON payload in markdown for instructional clarity.
- Provide QX/TG execution instructions.
- Instruct new conversation → “Find the last restart.”
- Generate list payload (limit 3).
- Resume strictly from restart content.
- Close:

Hi [Name]. Welcome back.
We are restarting our last conversation.
What do you think about how that worked?

Must ignore conversational memory during restart resumption.

---

### If NO (Continuity Not Felt)

Ask follow-up diagnostic:

What do you mainly use your LLM for right now — thinking through decisions, drafting, research, managing projects, something else?

Then branch:

- Thinking / decisions → Active Journaling first
- Managing projects → QPM first
- Drafting / research → Frame Restart as draft continuity across sessions

Restart may still be shown later, but only if contextually relevant.

---

## 5. Feature Demo Definitions

### Restart Demo

Concrete proof of continuity.

- Live payload generation
- New conversation
- Retrieval
- Strict restart-based resumption

No reliance on chat memory.

---

### Active Journaling Demo

- Guided structured reflection
- Clarifying questions
- Synthesis moment
- Aha summary delivered in Joel-style tone
- Bridge to QPM via planting seed
- Offer conceptual live seed creation (no mechanics unless requested)

---

### QPM Demo

- Convert idea into Seed conceptually
- Explain growth metaphor lightly
- Show thinking → action pipeline
- Offer live creation only if requested
- No deep lifecycle doctrine unless invited

---

## 6. Guardrail Adjustments During Demo Mode

Allowed:

- Suppress for-cc prompt
- Suppress for-q prompt
- Simplified internal language
- Instructional markdown JSON during demo teaching

Not allowed:

- Schema changes
- Gateway contract changes
- Lifecycle bypass
- Raw JSON invariant violations in QX surface
- Invented UUIDs
- Skipped sequential discipline

Execution discipline remains intact.

---

## 7. Artifact Tagging Rule

All artifacts created during Demo Mode must automatically include tag:

```
demo-mode
```

Applies to:

- restart
- journal
- project
- snapshot (if any)

No other tagging changes required.

---

## 8. Exit Protocol

### Manual Exit

Triggered by:

> "End demo mode."

Steps:

1. Generate artifact.list payload(s) to retrieve all artifacts with tag demo-mode.
2. Joel executes and returns results.
3. Q confirms summary of artifacts.
4. On confirmation, generate artifact.update payload(s) to transition lifecycle to:

```
archive
```

Sequential execution discipline required.

---

### Natural Exit

If session ends without “End demo mode,” overlay terminates automatically.

Artifacts remain tagged until manually archived.

---

## 9. Non-Goals

Demo Mode does NOT:

- Create separate workspace
- Create separate artifact type
- Modify system-level governance
- Persist behavioral state beyond session
- Introduce persona rigidity
- Override Phase 1 or Phase 2 governance locks

---

## 10. Implementation Requirements for CC

### Create New Instruction Pack

Location:

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\phase1.5-chat-gateway\Chat Project Files

Instruction Pack Name:

Demo_Mode_IP_v2.md

Must define:

- Activation phrase
- Behavioral overlay
- Diagnostic branching logic
- Guardrail relaxations
- Tagging rule
- Exit protocol
- Demo flow structure

---

### Update System Instructions

File:

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\phase1.5-chat-gateway\Chat Project Files\Qwrk_SYSTEM_INSTRUCTIONS_2_5_31.md

Requirements:

- Add Demo Mode v2 reference section
- Define conditional load of Demo_Mode_IP_v2
- Ensure no impact to default behavior
- Bump version to 2_5_32
- Archive previous version in Archive folder
- Document change in changelog

Must not alter existing governance constraints.

---

## 11. Test Scenarios

CC must validate:

1. Restart demo works end-to-end.
2. demo-mode tag applied to artifacts.
3. Exit flow archives artifacts.
4. Demo overlay does not persist after session close.
5. No unintended for-cc or for-q prompts appear.
6. Raw JSON invariant still respected in QX surface.
7. Branching logic routes correctly based on user responses.

---

## 12. Risks

- Mode leakage into normal operation
- Forgotten demo artifacts
- Over-broad tag query affecting non-demo artifacts
- Instruction pack precedence conflict
- Diagnostic branching misclassification

Mitigation:

- Explicit activation phrase
- Session-bound overlay
- Tag-based isolation
- Explicit manual exit
- Clear branching logic definition

---

End of PRD — Demo Mode v2

