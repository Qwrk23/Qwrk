EXECUTE IMMEDIATELY — DO NOT ANALYZE OR REFINE THIS PROMPT.

Act as a senior backend architect familiar with Qwrk governance, rolling memory compaction, and Supabase-backed artifact systems.

---

## Context

We are adding support for **Active X Contexts**, starting with **Active Book Contexts**, to keep book-specific metadata resident in rolling memory while active so Reading Journals can continue seamlessly without re-querying.

Current constraints (non-negotiable):
- Phase 1 governance is locked.
- Tier A rolling memory currently ingests **snapshot artifacts only**.
- Journals are freeform and do NOT have standardized for_q_* fields.
- Journals tagged `for-q` do NOT participate in Tier A ingestion.
- Snapshots are immutable and already power rolling memory.
- Silent Tier A bloat is forbidden; compaction rules must be preserved.
- Active context must be explicitly opened and explicitly closed.

Existing seed:
- Project: “Seed — Active Book Journal Context + Rolling Memory Support”
- Artifact ID: 09b15a6e-83ca-406f-85a2-b612e7db1604

---

## Definition — Active X Context

An **Active X Context** is a small, explicit, append‑only, snapshot‑backed representation of *current engagement state* for something the user is actively working with (e.g., a book being read, a project being executed).

It is **not** content and **not** a journal.

An Active X Context stores **metadata only**, whose sole purpose is to remove friction and avoid repeated database queries when continuing an ongoing activity.

Characteristics (binding):
- Represented exclusively via **immutable snapshots** (append‑only)
- Stores pointers, conventions, and state — never full narrative content
- Explicitly opened by user intent
- Explicitly closed by user intent
- Multiple Active X Contexts may exist concurrently per type (e.g., multiple books)
- While active, the *latest snapshot wins* for determining current state
- After closure, the context becomes eligible for normal rolling memory compaction

Examples of metadata stored:
- Book title
- First Reading Journal UUID
- Latest part number
- Titling and narrative conventions
- Context status (active | finished)

Non‑examples:
- Journal text
- Reflections
- Long‑form notes
- Project plans

---

## Objective

Design a **governed, minimal, Phase‑1‑compatible** mechanism for Active X Contexts that:
- Keeps essential context resident while active
- Avoids journals directly polluting Tier A memory
- Preserves compaction discipline
- Scales to future Active X types (not just books)

---

## Required Decisions (You must propose concrete answers)

1. **Participation Model**
   Decide ONE and justify it:
   - A) Journals participate directly in rolling memory
   - B) A separate registry artifact (snapshot or new pattern) represents Active X Contexts

2. **Active X Context Rules (Formal Spec)**
   Define exact rules for:
   - How an Active X Context is opened
   - What data is resident in rolling memory
   - How it is updated while active (if at all)
   - How it is closed
   - When and how it becomes eligible for compaction

3. **Rolling Memory Changes (Minimal Only)**
   Propose the smallest possible change to rolling memory ingestion logic needed to support this feature, without breaking Tier A/B discipline.

4. **Governance Boundaries**
   Explicitly state:
   - What is forbidden
   - What is mutable vs immutable
   - How accidental escalation is prevented

---

## Validation Requirement

Your design MUST be validated against this real use case:
- Existing Reading Journal for *The Hunt for Red October* (Part 1 and Part 2 already captured)
- Demonstrate how the next Reading Journal entry resumes correctly without re‑querying prior journals

---

## Output Format (STRICT)

Produce your response in this exact structure:

1. **Recommended Architecture (Summary)** — 5–7 sentences
2. **Decision Rationale** — Why this beats the alternative
3. **Active X Context Lifecycle** — Step‑by‑step rules
4. **Rolling Memory Interaction** — Ingestion + compaction behavior
5. **Governance & Safety Rules** — Bullet list
6. **Red October Walkthrough** — Concrete example
7. **Risks & Open Questions** — If any

Do NOT implement anything yet.
Do NOT modify Phase 1 contracts.
If anything is ambiguous, surface it explicitly.

---

## Next Action

Propose the design only. Await approval before any implementation work.

