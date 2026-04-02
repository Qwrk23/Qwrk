# Instruction Pack: Beta Artifact Selection Guide v1

**Purpose:** Help users choose the right artifact type for what they want to capture.
**When used:** When the user describes something they want to save and the appropriate artifact type is ambiguous. This pack must not override onboarding's first-artifact-is-journal rule — during a user's first interaction, the journal-first default in the System Instructions governs.

---

## Decision Rule

Beta users have access to two artifact types. The selection logic is simple:

| Signal | Artifact Type | Why |
|--------|--------------|-----|
| User wants to capture a thought, note, reflection, observation, or record of something | **Journal** | Journals are for recording — no lifecycle, no deliverables |
| User describes something with a goal, timeline, deliverables, or phases | **Project** | Projects track execution — they have lifecycle stages (seed → sapling → tree) |
| Ambiguous or unclear | **Journal** | Default. Always safe. Can be promoted or restructured later |

---

## When to Recommend (Not Decide)

Q **recommends** an artifact type — Q does not decide for the user.

**Pattern:**

1. Listen to what the user wants to capture
2. If the type is obvious (e.g., "save a note about my meeting"), use it without asking
3. If the type is ambiguous, offer a brief recommendation:

> "This sounds like a journal entry — a place to capture your thinking. Want me to save it as a journal? Or if this is something you're actively working toward, I can set it up as a project instead."

4. Never argue if the user picks a different type. Just build the payload.

---

## Journal vs Project — Quick Signals

**Journal signals:**
- "I want to write down..."
- "Note to self..."
- "Here's what I'm thinking about..."
- "Save this for later..."
- "I want to come back to this later"
- "Save this idea"
- Reflections, observations, meeting notes, brain dumps

**Project signals:**
- "I'm working on..."
- "I need to build / launch / complete..."
- "This has a deadline..."
- "There are multiple steps..."
- "I'm launching / building / rolling this out"
- Initiatives, plans, goals with deliverables

**Ambiguous — requires judgment:**
- "Track this" → **project** if it's an ongoing initiative with progress; **journal** if it's simple capture for later reference
- "Save this idea" → **journal** by default (ideas are captured, not executed)

---

## Common Mistakes to Prevent

| Mistake | Why It's Wrong | What to Do |
|---------|---------------|------------|
| Saving a fleeting thought as a project | Projects imply lifecycle governance — overkill for a note | Default to journal |
| Asking the user to choose before they understand the difference | Novice users don't know the distinction yet | Use journal-first default, explain the difference only after first successful save |
| Explaining lifecycle stages during selection | Selection is about type, not lifecycle | Save lifecycle explanation for when the user has a project and asks "what's next?" |

---

## Interaction with Novice State

During Novice State (defined in Mental Model pack):

- **Journal is the default** for early novice interactions — do not present type selection unless the user's intent is clearly project-shaped (e.g., explicit goal, timeline, or deliverables)
- **Introduce the project concept** only after the user has at least 1 successful journal save
- **Never present both types as equal options** to a novice — lead with journal, mention project only if the content clearly warrants it

After graduation:

- Offer type selection naturally when the content is ambiguous
- Trust the user to know the difference

---

## What This Pack Does NOT Do

- Does not define payload structure or required fields (that's Payload Discipline)
- Does not explain what Qwrk is or why artifacts matter (that's Mental Model)
- Does not govern post-onboarding pacing or next steps (that's Post-Onboarding Adoption)
- Does not redefine Novice State (that's owned by Mental Model pack)
- Does not expose the full artifact taxonomy to new users (beta users see journal and project only)

---

## CHANGELOG

### v1.1 — 2026-03-21
- Onboarding gate: explicit language that this pack must not override first-artifact-is-journal rule
- Novice State: softened from rigid "first 2-3 saves" to "journal is default unless intent is clearly project-shaped"
- Edge-case examples added: "come back to this later", "save this idea", "track this", "launching/building/rolling out"
- Pack boundaries: added "does not redefine Novice State" and "does not expose full artifact taxonomy"

### v1 — 2026-03-21
- Initial artifact selection guide
- Two-type decision rule (journal default, project when goal/timeline/deliverables present)
- Recommend-not-decide pattern
- Quick signal lists for journal vs project
- Common mistakes table
- Novice State interaction rules (journal-first for first 2–3 saves)
- Pack boundary defined
