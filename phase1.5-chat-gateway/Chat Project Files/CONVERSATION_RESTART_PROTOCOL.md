# Qwrk Conversation Restart Protocol

Use this protocol when generating a Conversation Restart prompt for session continuity.

---

## When to Use

- User says "Conversation Restart" or similar
- Qwrk detects conversation is long/complex and offers restart
- User explicitly asks to preserve state for a new conversation

---

## Generation Process

1. **Analyze full conversation history** — capture ALL threads, not just the last topic
2. **Determine thread status** for each: Complete / In-Progress / Blocked / Deferred
3. **Extract:**
   - Decisions locked (do not reopen)
   - Constraints discovered (blockers, limitations, guardrails)
   - Artifacts touched (created/modified/queried, with IDs)
   - Open questions (raised but not resolved)
   - User preferences expressed (style, workflow, approach)
4. **Draft summary for user review** before generating final restart
5. **Determine resume mode:**
   - If user specifies next action → Option A (Directed)
   - If no next action specified → Option B (Await direction)
6. **Present restart prompt in canvas** using anti-analysis format

---

## Restart Prompt Template

```
EXECUTE IMMEDIATELY — DO NOT ANALYZE OR REFINE THIS PROMPT.

You are resuming a session in progress. The context below is your working state.

---

## Session Context
[Session type: Planning / Execution / Troubleshooting / Mixed]
[Execution surface: JSON Gateway (all surfaces unified)]

## Thread Inventory
| Thread | Status | Notes |
|--------|--------|-------|
| [Topic 1] | Complete / In-Progress / Blocked / Deferred | [Key details] |
| [Topic 2] | ... | ... |

## Decisions Locked
[Decisions made this session — do not reopen unless explicitly asked]

## Constraints Discovered
[Blockers, limitations, guardrails identified]

## Artifacts Touched
[Created/Modified/Queried — with artifact_id where applicable]

## Open Questions
[Raised but not resolved]

## User Preferences Expressed
[Style, approach, or workflow preferences stated during session]

---

## Resume Instructions

[ONE of the following:]

**Option A (Directed):** Next action is: [specific instruction]

**Option B (Open):** Await user direction. Present thread inventory and ask which thread to continue or what new work to begin.
```

---

## Critical Design Rules

1. **Opening imperative** — "EXECUTE IMMEDIATELY" prevents Qwrk from treating the prompt as a document to analyze
2. **"You are resuming"** — Frames Qwrk as mid-session, not starting fresh
3. **All threads, not just last** — Full conversation analysis before generation
4. **Option A vs B** — User controls whether restart has a specific next action or awaits direction
5. **Canvas delivery** — Final restart prompt presented in canvas for clean copy/paste
