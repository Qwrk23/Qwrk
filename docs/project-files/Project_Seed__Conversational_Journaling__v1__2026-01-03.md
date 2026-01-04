# Project Seed — Conversational Journaling as First-Class Artifact

**Project Name**: Conversational Journaling as First-Class Artifact
**Lifecycle Stage**: 🌱 Seed
**Owner**: Master Joel
**Date Created**: 2026-01-03
**Category**: Core Product Feature

---

## Seed — Conversational Journaling as First-Class Artifact

### Core Idea

Journaling in Qwrk should support capturing *entire reflective conversations* between a user and Qwrk as a single, coherent journal artifact—not just isolated user-written paragraphs.

Insight and clarity often emerge through dialogue, reframing, and back-and-forth exploration. Capturing only the user's final words flattens meaning and loses cognitive lineage. Qwrk should be able to preserve the *full arc of thought*, including prompts, responses, emotional pivots, reframes, and commitments.

---

### What This Enables

* **Preservation of how insight was reached**, not just the outcome
* **A record of evolving beliefs**, identity statements, and decisions in context
* **Richer long-term memory** for coaching, reflection, and pattern recognition
* **A sense of Qwrk as a witness and thinking partner**, not just a note-taking tool

---

### Conceptual Characteristics

* A single journal entry may consist of:
  * Full conversation transcript (user + Qwrk)
  * Session metadata (date, mode, intent)
  * Optional post-session highlights or summary layers
* **The raw conversation is preserved as canonical**; summaries are derivative
* Capture may be manual at first, with future support for guided or automatic capture
* The artifact represents a ***thinking session***, not a document draft

---

### Why This Matters

Most journaling tools assume insight is solitary and linear. Qwrk recognizes that insight is often **dialogic, emergent, and emotionally contextual**. Treating conversational journaling as a first-class artifact aligns with Qwrk's core differentiation: adapting to how users understand and arrive at meaning, not just what they conclude.

---

## Status

**Lifecycle**: 🌱 Seed — conceptual direction only

**Maturity**: No assumptions about UI, storage schema, or automation rules yet

**Purpose**: Establish philosophical direction and design principle for future implementation

---

## Design Implications (Future Exploration)

### Schema Considerations

**Potential artifact type**: `journal` (existing) with conversation-aware extension

**Possible fields**:
- `conversation_transcript`: Full dialogue (user + Qwrk messages)
- `session_metadata`: Date, mode, intent tags
- `highlights`: Optional user-curated key moments
- `summary_layers`: AI-generated or user-written summaries (derivative, not canonical)
- `emotional_markers`: Pivots, breakthroughs, commitments

**Storage format**: JSONB payload with structured conversation array

---

### UI/UX Considerations

**Capture modes**:
- **Manual capture**: User explicitly saves a conversation as journal entry
- **Guided capture**: Qwrk prompts "Would you like to save this session?"
- **Automatic capture**: System detects reflective sessions and auto-saves with user approval

**Display modes**:
- **Full transcript view**: Chronological dialogue with timestamps
- **Highlight view**: User-curated key moments
- **Summary view**: Condensed version for quick review
- **Pattern view**: Cross-session themes and evolution

---

### Product Philosophy Alignment

**Core Qwrk Differentiation**:
- Ideas don't disappear when a chat ends ✅
- Good work doesn't get overwritten or quietly lost ✅
- History stays intact—decisions, reflections, and progress included ✅
- AI becomes a partner across sessions, not just within one ✅

**Conversational journaling extends this**:
- The *process* of thinking is preserved, not just the product
- Users can revisit how they arrived at understanding
- Emotional and cognitive context is retained
- Qwrk acts as witness to growth and evolution

---

## Open Questions (To Be Resolved in Sapling Stage)

1. **Privacy & Control**: How do users control what gets captured vs what stays ephemeral?
2. **Granularity**: Should users tag individual messages as "journal-worthy" or capture whole sessions?
3. **AI Role**: Should Qwrk proactively identify "journaling moments" or wait for user intent?
4. **Editability**: Is the conversation transcript immutable (like snapshots) or editable (with version history)?
5. **Cross-session linking**: How do conversational journal entries relate to projects, restarts, or other artifacts?

---

## Next Actions (When Moving to Sapling)

1. **User research**: Interview beta users about their journaling practices and pain points
2. **Schema design**: Define `journal` artifact extension for conversation storage
3. **Prototype**: Build minimal capture flow (manual save button → transcript storage)
4. **Test hypothesis**: Does preserving full conversation add value vs summary-only?
5. **Iterate**: Refine based on usage patterns and feedback

---

## Success Criteria (Future)

When this project reaches **Sapling** or **Tree**, success looks like:

✅ Users can save entire Qwrk conversations as journal artifacts
✅ Conversations are preserved in full with metadata (date, mode, intent)
✅ Users can review, search, and reflect on past thinking sessions
✅ Optional summaries/highlights layer on top without replacing canonical transcript
✅ Users report that Qwrk feels like a "thinking partner" not just a tool

---

## Constraints & Boundaries

**In Scope** (conceptually):
- Philosophical direction for conversational journaling
- Design principles for future implementation
- Alignment with Qwrk's core differentiation

**Out of Scope** (at Seed stage):
- Specific UI designs
- Database schema details
- Implementation timeline
- Feature prioritization vs other roadmap items

---

## References

**Core Qwrk Philosophy**: Continuity over productivity theater
**Related Artifacts**: Journal artifact type (existing), Restart artifacts (conversation snapshots)
**Design Inspiration**: Reflective practice, coaching conversations, cognitive lineage

---

## CHANGELOG

### v1 - 2026-01-03
**What changed**: Initial project seed creation

**Why**: Capture conceptual direction for conversational journaling as first-class artifact type

**Scope**: Seed-stage philosophical direction; no implementation commitments yet

**How to validate**: Review alignment with Qwrk's core differentiation and user value proposition

---

**Version**: v1
**Lifecycle Stage**: 🌱 Seed
**Status**: Conceptual direction — no build planned yet
**Owner**: Master Joel
**Last Updated**: 2026-01-03
