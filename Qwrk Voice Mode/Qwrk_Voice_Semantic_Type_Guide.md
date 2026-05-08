# Qwrk Voice — Semantic Type Guide

Voice suggests a semantic type **only when confident**.

**If uncertain → flag for Prime review. Do not guess.**

The 9 semantic types below are the complete registry. No other values.

---

## Low-Cognitive-Load Rules

- Suggest only when the match is obvious within a moment.
- If brief spoken intent doesn't clearly map to one type → flag for Prime review.
- Use `exploratory` only when the intent is genuinely early / fuzzy / what-if. Do NOT default to `exploratory` as a "when I don't know" catch-all.
- If two seem to fit → flag uncertainty, let Prime decide.

Speed over inference. Do not over-analyze spoken input.

---

## execution-core

**Meaning:** Work that directly implements or delivers core system function.

**Suggest when:** Joel is describing build, implementation, shipping, production work.

**Example:** "I just shipped the Gateway update path fix."

---

## governance

**Meaning:** Rules, decisions, policy, architectural locks.

**Suggest when:** Joel is stating a rule, snapshotting a decision, or locking a design choice.

**Example:** "We're locking in: Voice captures, Prime executes."

---

## infrastructure

**Meaning:** Underlying platform plumbing — database, workflow, Gateway internals.

**Suggest when:** Joel mentions DDL, n8n, Supabase, Gateway internals, or structural plumbing.

**Example:** "Add a new column to the artifact spine for X."

---

## platform

**Meaning:** Cross-cutting capabilities reused across domains.

**Suggest when:** Joel is describing broad capability work — reusable across multiple surfaces or agents.

**Example:** "Build a shared notification layer all agents can use."

---

## product

**Meaning:** User-facing features, experience, product surface.

**Suggest when:** Joel is describing UX, user-facing features, or product direction.

**Example:** "Redesign how QSB surfaces confirmation messages."

---

## alignment

**Meaning:** Life / work / self alignment, reflection, priorities, values.

**Suggest when:** Joel is reflecting on purpose, focus, energy, priorities, or personal direction.

**Example:** "I'm noticing I've been avoiding the harder beta work."

---

## sales

**Meaning:** Customer-facing motion, deals, outreach, pipeline.

**Suggest when:** Joel talks about clients, pitches, positioning for buyers, or deal motion.

**Example:** "Rita's ServiceNow partner motion — next step is the intro call."

---

## marketing

**Meaning:** Messaging, positioning, content, external comms.

**Suggest when:** Joel is shaping how Qwrk is described externally, writing copy, or building awareness.

**Example:** "Draft a positioning paragraph for Qwrk Voice."

---

## exploratory

**Meaning:** Early-stage thinking, fuzzy ideas, what-ifs.

**Suggest when:** Joel is openly exploring with no commitment attached.

**Example:** "What if Qwrk had a fully autonomous mode someday?"

---

## Common Disambiguation

- User-facing feature or experience → **product**
- Internal system work / core implementation → **execution-core**
- Database / n8n / Supabase / Gateway plumbing → **infrastructure**
- Reusable capability spanning multiple surfaces or agents → **platform**

---

## Quick decision flow

1. Building something concrete? → **execution-core**
2. Making a rule or decision? → **governance**
3. DB / workflow / plumbing? → **infrastructure**
4. Cross-cutting capability? → **platform**
5. User-facing surface? → **product**
6. Personal direction / priorities? → **alignment**
7. Customer / deal motion? → **sales**
8. External messaging / copy? → **marketing**
9. Fuzzy, early, what-if? → **exploratory**

If two seem to fit → flag uncertainty, let Prime decide.
