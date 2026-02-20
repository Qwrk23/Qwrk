# Restart Prompt: Add Durable Intent Capture Invariant

**Created:** 2026-01-29
**Priority:** 2 of 4 (Moltbot-inspired features)
**Source:** `docs/governance/Moltbot_Feature_Assessment__Selective_Absorption__2026-01-29.md`
**Inspired By:** Moltbot's pre-compaction memory flush

---

## Goal

Before any state transition that summarizes or compacts information, force a **Durable Intent Capture** step.

---

## Why This Matters

> Summaries destroy information unless you explicitly preserve intent first.

Moltbot's insight: trigger a "flush" before compaction to capture what matters.

Qwrk's translation: before lifecycle transitions, capture:
- What changed?
- Why does it matter?
- What must not be lost?

---

## Trigger Points

The Durable Intent Capture should fire before:

| Transition | Current Behavior | With DIC |
|------------|------------------|----------|
| Snapshot creation | Captures state | First captures intent, then state |
| Restart creation | Captures resumption context | First captures "why stopping here" |
| Lifecycle promotion (seed→sapling→tree) | Updates stage | First captures "why ready to promote" |
| Context compaction (if implemented) | Summarizes | First preserves key decisions |

---

## Implementation Options

### Option A: Explicit field on transition artifacts
Add `durable_intent` field to snapshot/restart/promotion payloads.
- Pros: Simple, queryable
- Cons: Relies on caller discipline

### Option B: Gateway enforcement
Gateway rejects transitions without intent capture.
- Pros: Guaranteed
- Cons: Friction, may need exceptions

### Option C: qfe prompt discipline
qfe always asks "What must not be lost?" before transitions.
- Pros: Natural flow
- Cons: Not enforced at system level

---

## Deliverable

1. Decision on enforcement level (A, B, or C)
2. Schema change if needed (`durable_intent` field)
3. qfe instruction update for transition flows
4. Test: create snapshot, verify intent captured

---

## Start Command

> "I'm implementing Durable Intent Capture for Qwrk. Let's review the current snapshot/restart creation flows to understand where to inject the intent capture step."
