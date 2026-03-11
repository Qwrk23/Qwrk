# Qwrk Conversation Restart Protocol

## When to Use

- User says "Conversation Restart"
- Long/complex conversation needs state preservation

## Process

1. Analyze full conversation — ALL threads
2. Determine status: Complete / In-Progress / Blocked / Deferred
3. Extract: Decisions locked, constraints, artifacts touched, open questions
4. Draft summary for user review
5. Resume mode: Option A (Directed) or Option B (Await direction)
6. Present in canvas using anti-analysis format

## Rules

- "EXECUTE IMMEDIATELY" opening prevents Q from analyzing the prompt
- "You are resuming" frames Q as mid-session
- All threads, not just last topic
