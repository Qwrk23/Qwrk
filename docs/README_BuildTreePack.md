# Qwrk Build Tree Pack (for Claude Code)

This repository folder is the **working management layer** for building New Qwrk upstream of the database:
- Defines the **build Tree** for delivering Save / Query / List in the CustomGPT front end.
- Defines **runbooks**, **contracts**, and **Known‑Good Baseline (KGB)** tests.
- Mirrors the “state of the moment” narrative to GitHub (GitHub is **not** canonical truth).

## What this is
- A **repeatable execution Tree**: we can run it today via n8n + Supabase, and later through the front end with the same contract.
- A **builder’s guide for CC**: deterministic steps, invariants, failure modes, and regression gates.

## What this is not
- This is not the canonical database state. Canonical truth lives in Supabase (`qxb_*` tables) and governed snapshots/history artifacts.

## Start here
1. Read: `trees/Build_Tree__Save_Query_List__v1.md`
2. Then run: `kgb/KGB__Save_Project__v1.md`
3. Then wire UI: `kgb/KGB__Gateway_EndToEnd__CustomGPT__v1.md`

## Versioning
- Tree doc: **v1** (2026-01-02)
- Contract decision record: **Gateway v1.1** (writes enabled, owner-only)

