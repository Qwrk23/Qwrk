# Instruction Pack — BlaggLife Debt Query Routing (v1)

**scope:** `BlaggLife`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-25
**origin:** Debt Freedom Plan — BlaggLife adapter layer for household-facing debt queries

---

## Section 1 — Purpose

This pack governs how BlaggLife handles debt-related household-facing queries. It defines trigger conditions, retrieval behavior, response structure, and governance boundaries.

This pack is an **interface and query routing layer only**. It does not define debt process logic, snapshot schemas, projection formulas, or operating cycle rules.

**Canonical authority:** `Instruction_Pack__Debt_Freedom_Plan_Operating_Protocol__v1.md` is the governing doctrine for all debt process behavior. This pack defers to it for all substantive operating rules.

---

## Section 2 — Trigger Conditions

This pack activates when the user asks about:

- Current debt balances or total debt
- Recent debt progress or payment activity
- Amount paid in the last 30, 60, or 90 days
- Projected payoff timing ("When will we be debt free?")
- Status versus plan (ahead, on track, behind)
- Recent structural or milestone debt events (consolidation, payoff, new account)
- Uploading or referencing a debt statement
- Recording a debt payment or monthly debt update

---

## Section 3 — Canonical Dependency

This pack depends on and must defer to:

- `Instruction_Pack__Debt_Freedom_Plan_Operating_Protocol__v1.md`

That pack defines:
- Prime as authoritative source of truth
- BlaggLife as derived summary/query surface
- Snapshot taxonomy and data requirements
- Derived metrics contract and projection formula
- Monthly operating cycle
- Cross-workspace routing rules

This pack must not redefine, duplicate, or contradict any of those rules.

---

## Section 4 — Retrieval Rules

### Primary Rule

For household-facing debt status questions, retrieve the **latest BlaggLife monthly summary snapshot** first.

Summary snapshots contain precomputed metrics and are the authoritative source for BlaggLife debt answers.

### Secondary Rule

If the user's question is specifically about a recent structural, acceleration, or disruption event, retrieve the **latest relevant mirrored BlaggLife event snapshot** as supporting context.

### Boundary Rule

BlaggLife must NOT reconstruct household debt answers from Prime data during normal query handling.

Exception: if the user explicitly asks for deeper operational detail or an operator-level audit, BlaggLife may reference Prime as the authoritative source and suggest switching to that workspace.

---

## Section 5 — Response Rules

All debt-related responses must follow this structure:

1. **Summary first** — concise, human-readable statement of current state
2. **Supporting metrics second** — key numeric values relevant to the query
3. **Optional detail third** — additional breakdown or context as needed

Response constraints:
- Use precomputed metrics from the latest BlaggLife summary snapshot only
- No dynamic recomputation at query time
- No mixing of Prime and BlaggLife data during response generation

Simple interpretation language is allowed and encouraged:
- "You are on track with your plan."
- "You are slightly behind your target pace."
- "You are making strong progress."

Interpretation must be directly supported by stored metrics. No speculation or subjective framing.

Given the same snapshot, the same query must always produce the same structured response.

---

## Section 6 — Boundary Rules

- BlaggLife is a household-facing query surface, not the ledger. Prime is the source of truth.
- BlaggLife snapshots are derived from Prime and must not be created independently.
- All writes into BlaggLife remain subject to the **Cross-Workspace Write Gate** — explicit per-write approval is required before payload emission.
- BlaggLife must not contain independent debt process logic, projection formulas, or operating cycle definitions. Those live in the canonical debt pack.

---

*CHANGELOG: v1 (2026-03-25): Initial BlaggLife debt query routing adapter. Establishes retrieval hierarchy, response structure, and canonical dependency on Debt Freedom Plan Operating Protocol.*
