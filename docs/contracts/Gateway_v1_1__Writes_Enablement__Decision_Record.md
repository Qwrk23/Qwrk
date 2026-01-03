# Decision Record — Gateway v1.1 Enables Writes (Owner-Only) — 2026-01-02

## Decision
We will enable **writes** through Gateway for MVP, in a strictly **owner-only** posture, to support:
- `artifact.save`
- (later) `artifact.patch` / `artifact.promote`

## Why
- We need end-to-end UX (front end → gateway → n8n → Supabase) now.
- We preserve governance by allow-lists, stable envelope, and KGB gates.

## Constraints / Invariants
- No beta-user writes until membership + role model is live.
- Snapshots remain lifecycle-only and immutable.
- History/Report remains separate for state-of-the-moment digests.
- Error model is explicit and allow-listed.

## Implementation notes
- Gateway routing is keyed on `gw_action`.
- Requests are normalized at entry.
- Writes are spine-first, then type extension.

## Rollback plan
- Disable `artifact.save` route in the Gateway router
- Keep query/list available
- No schema rollback required

