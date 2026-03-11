I need you to help me **plan — not yet implement** — an upgrade to the BlaggLife assistant so it can correctly identify whether it is speaking with **Joel** or **Daisy** in a shared account, and then consistently tag created artifacts with the correct speaker tag.

Your task is to produce a **planning document** for two things:

1. the **system instruction additions/changes**
2. the **instruction_pack content** needed to support the behavior reliably

## Context

- Shared account users are **Joel Blagg** and **Daisy Blagg**.
- At the **start of every new conversation**, the assistant should determine who it is speaking with.
- If identity is unclear, it should **ask directly**.
- If the assistant thinks it knows, it should still **verify** rather than silently assume.
- Once confirmed, that person should be treated as the **active speaker for the session**.
- If both Joel and Daisy are clearly participating, the assistant should support **joint participation** and tag artifacts with **both** `joel` and `daisy`.
- The assistant should **never guess silently** when identity matters for artifact creation.

## Advanced behavior to include in the plan

I also want a more natural version of this capability, not just the simple rule set.
Please include a design for an **advanced speaker-resolution layer** that:

- uses conversational/contextual cues to form a tentative belief about whether the speaker is Joel or Daisy
- still **asks for confirmation** at the start of a new conversation
- can carry forward a working assumption across the **same active session** after confirmation
- handles cases where the conversation **shifts from one speaker to both speakers**
- handles cases where one person is speaking **about** the other person without that meaning the active speaker changed
- minimizes annoying repeated identity questions within the same session
- remains conservative when identity affects saved artifacts

## What I need from you

Please produce a planning document with these sections:

### 1. Goals
Define exactly what this feature is trying to achieve.

### 2. Non-goals
Clarify what this feature should **not** try to do.

### 3. Decision model
Design the logic for:
- new conversation speaker identification
- confirmation flow
- confidence handling
- session persistence
- joint participation detection
- when to re-check identity
- when artifact creation must pause pending confirmation

### 4. System instruction changes
Propose exact system-instruction language or near-final draft language for:
- speaker identification
- verification behavior
- session-scoped speaker state
- artifact tagging requirements
- joint tagging behavior
- fallback behavior when unclear

### 5. Instruction_pack design
Recommend what belongs in the instruction_pack versus the core system instructions.
I want a clean separation between:
- stable policy/rules in system instructions
- operational heuristics/examples in the instruction_pack

### 6. Tagging model
Define the exact tagging behavior for:
- Joel-only session
- Daisy-only session
- joint session
- artifact updates
- artifacts created before confirmation

Please include whether speaker tags should be mandatory, additive, replaceable, or protected.

### 7. State model
Propose a lightweight internal state model for conversation handling, such as:
- active_speaker
- speaker_confidence
- joint_session
- confirmation_status
- speaker_evidence

Do not write code. Just define the conceptual state model and transitions.

### 8. Edge cases and failure modes
Cover things like:
- assistant thinks it knows but is wrong
- speaker changes mid-conversation
- both users speak in one thread
- quoted text from the other spouse
- artifact request arrives before confirmation
- ambiguous identity after multiple turns
- retroactive tagging corrections

### 9. UX guidance
Design the ideal user-facing wording for:
- first identity check
- confirmation when assistant has a likely guess
- joint participation confirmation
- minimal-friction re-check when needed
- graceful recovery when an artifact cannot safely be tagged yet

### 10. Migration / rollout guidance
Recommend how to introduce this change without breaking existing artifact workflows.
Include whether old artifacts should remain untouched unless explicitly updated.

### 11. Risks and tradeoffs
Discuss accuracy vs friction, shared-account ambiguity, over-tagging, under-tagging, and session complexity.

### 12. Final recommendation
Give a concise recommended design that balances reliability, low friction, and governance.

## Important constraints

- This is for **planning only**.
- Do **not** implement.
- Do **not** produce gateway payloads.
- Do **not** create artifacts.
- Do **not** rewrite the entire BlaggLife system prompt unless necessary.
- Focus on the **minimum viable instruction changes** plus a robust instruction_pack.

## Output style

Please make the result practical and implementation-ready.
Use:
- explicit rules
- decision trees
- recommended wording
- concrete examples
- identified risks

I want something I can use to decide exactly what goes into the system instructions and what goes into the instruction_pack.

