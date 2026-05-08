# Qwrk Voice — Artifact Selection Guide

Voice suggests an artifact type when confident. Prime validates and saves.

- **Primary Voice capture types:** `journal`, `twig`
- **Prime-deferred types:** `project`, `snapshot`, `restart`
- **Never from Voice:** `branch`, `limb`, `leaf`

**If not clearly `journal` or `twig` → flag uncertainty and defer to Prime. Do not guess.**

---

## Primary Voice Types

### journal

**When:** Joel is reflecting, processing, or thinking out loud.

**When NOT:**
- Capturing a small discrete idea under existing work → **twig**
- Naming a new initiative → defer to Prime as possible **project** seed
- Locking a decision → defer to Prime as possible **snapshot**

**Voice example:** "I've been sitting with this idea about beta onboarding — concierge might be the right first move."

**Rule:** Reflection or thinking out loud → `journal`.

---

### twig

**When:** A small, discrete idea fragment under an existing project.

**When NOT:**
- The thought is reflective → **journal**
- The parent is not clearly stated or obvious from Joel's words → flag uncertainty, defer to Prime

**Voice example:** "Quick thought for the Voice Mode work — we should test what happens when the user mumbles."

**Rule:** If twig parent is not clearly stated or obvious → do NOT suggest twig confidently. Flag uncertainty for Prime.

---

## Prime-Deferred Types

Voice never saves these directly. Voice captures cleaned intent in a handoff prompt; Prime creates the artifact.

### project (seed)

**Signal:** Joel names a new initiative with commitment language — "let's start," "new project," "we should track," "build a."

**Voice action:** Capture cleaned intent. Use Template 3 (Needs Deeper Prime Governance) or Template 1 with artifact type suggested as `project`.

**Voice example:** "New idea — let's track a project for redesigning the mobile capture flow."

---

### snapshot

**Signal:** Joel locks a decision, state, or moment-in-time record.

**Voice action:** Capture cleaned decision statement. Defer to Prime — decisions are governance-weight.

**Voice example:** "Locking in — we're going with the separate Voice GPT approach, not the overlay."

---

### restart

**Signal:** Joel wants continuity to resume a thread later.

**Voice action:** Capture handoff intent. Defer to Prime — restart has a structured payload schema.

**Voice example:** "Set up a restart for the Voice Mode design work so I can pick it up tomorrow."

---

## Never From Voice

### branch / limb / leaf

Execution-anatomy artifacts belong to QPM build work. Voice never suggests, captures, or emits these.

If Joel describes something that sounds like a branch or leaf concept, capture the intent in a Prime handoff prompt and let Prime do the structuring.

---

## Quick decision flow

1. Reflection / thinking out loud → **journal**
2. Small fragment under existing work, parent obvious → **twig**
3. Small fragment under existing work, parent unclear → flag uncertainty, defer to Prime
4. New initiative with commitment language → defer to Prime as possible **project seed**
5. Decision or locked state → defer to Prime as possible **snapshot**
6. Resume-later continuity → defer to Prime as possible **restart**
7. Branch / limb / leaf → **never from Voice**
8. None of the above clearly match → flag uncertainty, defer to Prime
