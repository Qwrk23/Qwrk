# Phase 2 Scope — QPM and Lifecycle Governance

**Status:** Active (Phase 1 locked 2026-01-31)
**Snapshot UUID:** `1676fe7d-5bf1-496e-a7dc-35bc14314ca3`

---

## What Phase 1 Delivered

Phase 1 locked the foundational governance:
- Kernel Semantics (D1-D4) — lifecycle rules, snapshot/restart semantics
- Paper Schemas — project, snapshot, restart, journal, instruction_pack
- Gateway Contract (P3-D1 through P3-D5) — action set, envelope, error codes
- Telegram + Gateway promoted to Tree (production-grade)

**Phase 1 Lock Snapshot UUID:** `a59311c2-d388-4224-aab6-b1cb9d60e431`

---

## Phase 2 Deliverables

### 1. QPM (Qwrk Project Management)
Define lifecycle semantics for the full growth path:
- **seed** — raw idea, not yet actionable
- **sapling** — structured idea, ready to plan
- **tree** — active project with branches/leaves
- **oak** — mature, stable, production
- **archive** — retired, read-only

Each transition needs defined readiness criteria.

### 2. Promotion Validation (BUG-015)
Implement Gateway enforcement of transition requirements:
- seed → sapling: Summary OR linked content exists
- sapling → tree: Branches defined, acceptance criteria locked
- tree → oak: All branches complete
- oak → archive: Explicit archive reason

### 3. Open Bug Fixes
| Bug | Description |
|-----|-------------|
| BUG-003 | artifact.query ignores `hydrate: false` |
| BUG-015 | Promotion has no validation requirements |

### 4. Governance Additions
- Dead seed archival rule (monthly cleanup policy)
- Journal mutability policy (mutable vs append-only)

### 5. Schema Refinements
- Index plan for performance
- Tag strategy (jsonb vs normalized)

---

## What's NOT in Phase 2

- **BUG-004 (instruction_pack Update)** — Deferred to Phase 3
- **Custom front-end** — Phase 3
- **Dynamic instruction pack loading** — Phase 3
- **Multi-user access** — Phase 3+

---

## Current Architecture (Phase 1-2)

```
QP1 (ChatGPT) → Telegram → Gateway_Telegram (n8n) → Gateway (n8n) → Supabase
```

Pre-instruction packs via .md files attached to QP1 project files.

---

## Phase 2 Acceptance Criteria

Phase 2 is complete when:
1. QPM lifecycle rules are defined and documented
2. Promotion validation is implemented in Gateway
3. BUG-003 and BUG-015 are closed
4. Dead seed archival governance is documented
5. Journal mutability policy is decided and locked
