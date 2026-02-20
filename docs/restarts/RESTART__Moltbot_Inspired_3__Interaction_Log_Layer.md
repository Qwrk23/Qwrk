# Restart Prompt: Design Interaction Log Layer

**Created:** 2026-01-29
**Priority:** 3 of 4 (Moltbot-inspired features)
**Source:** `docs/governance/Moltbot_Feature_Assessment__Selective_Absorption__2026-01-29.md`
**Inspired By:** Moltbot's append-only JSONL transcripts

---

## Goal

Create a **non-authoritative Interaction Log** layer that captures raw session evidence without claiming to be "the record."

---

## Why This Matters

Raw interaction logs provide:
- Replay capability
- Debugging
- Audit trails
- Evidence for disputes

But they are NOT canonical truth — artifacts are.

---

## Design Principles

| Principle | Implication |
|-----------|-------------|
| **Immutable** | Append-only, never edited |
| **Write-once** | No updates, no deletes |
| **Non-authoritative** | Explicitly labeled as evidence, not truth |
| **Linked** | References artifacts (snapshots, restarts, journals) |
| **Queryable** | Can search/filter by session, time, artifact |

---

## Key Distinction

```
Artifact (journal, snapshot, restart)
  └── IS the canonical record
  └── Human-curated
  └── Can be promoted/evolved

Interaction Log
  └── IS evidence of what happened
  └── System-generated
  └── Never promoted, never edited
  └── Links TO artifacts
```

---

## Schema Sketch

```sql
CREATE TABLE qxb_interaction_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL,
  session_id UUID,                    -- optional grouping
  artifact_id UUID,                   -- linked artifact (if any)
  timestamp TIMESTAMPTZ DEFAULT now(),
  actor TEXT NOT NULL,                -- 'user' | 'system' | 'qwrk'
  event_type TEXT NOT NULL,           -- 'message' | 'tool_call' | 'transition'
  payload JSONB NOT NULL,             -- raw content
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Append-only enforced by RLS (no UPDATE/DELETE)
```

---

## Open Questions

1. **Storage location:** Same Supabase instance or separate?
2. **Retention policy:** Keep forever? Archive after N days?
3. **Privacy:** What about sensitive content in logs?
4. **Access:** Who can query? User only? Admins?

---

## Deliverable

1. Schema design (finalized)
2. RLS policies (append-only enforcement)
3. Gateway integration (log on every interaction)
4. Query API (optional, for debugging)

---

## Start Command

> "I'm designing the Interaction Log layer for Qwrk. Let's start by reviewing the current database schema to understand where this table fits and what foreign keys it needs."
