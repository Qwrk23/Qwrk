# Manus Reference — Current State Snapshot

**Purpose:** Deployed state orientation for plan review.
**Date:** 2026-03-22
**Snapshot only. Not timeless doctrine.**

---

> **WARNING**
>
> This document is a convenience snapshot for review orientation only.
> It is not authoritative over canonical governance, schema, workflow, or contract references.
> If this file conflicts with a plan's direct evidence or a canonical reference, the canonical reference wins.
> This file may become stale. Verify against canonical sources when precision matters.

---

## Deployed Versions

| Component | Version | Notes |
|-----------|---------|-------|
| Gateway | v68 | 10 actions (8 artifact + 2 messaging) |
| Gateway Endpoint | v2 | Unified `/webhook/nqxb/gateway/v2` with resolver-based workspace routing |
| DDL (Database Schema) | v2.10 | 20 tables + 1 view, 5 functions |
| Artifact Type CHECK | v8 | 15 types |
| Schema Reference | v2.10 | Human-readable, co-committed with DDL |
| CLAUDE.md | v25 | Current governance doc |
| North Star | v0.4 (locked) | Execution anatomy (branch/limb/leaf) |
| Phase 2C Certification | 26/26 PASS | Black-box regression harness |

---

## What Is Shipped and Operational

### Core CRUD
- `artifact.save` — all 15 types
- `artifact.query` — all types, spine + extension merge
- `artifact.list` — filtering by type, tags, pagination
- `artifact.update` — mutable fields on spine and extensions
- `artifact.promote` — project lifecycle transitions (atomic via RPC)
- `artifact.delete` / `artifact.restore` / `artifact.list_deleted` — soft delete lifecycle

### Messaging
- `messaging.send_email` — Gmail integration
- `messaging.create_calendar_event` — Google Calendar integration

### Execution Anatomy
- Branch/Limb/Leaf hierarchy operational
- `execution_status` tracked on spine (not_started → in_progress → blocked → complete)
- Leaf-to-leaf dependency enforcement via `qxb_artifact_dependency`
- Progress rollup view (`qxb_artifact_rollup_view`)

### Multi-Forest
- 5 workspaces active (Prime, Q@W, BlaggLife, Akara, Greg)
- Gateway v2 with resolver-based workspace routing
- Per-workspace rolling memory and registry indexes

### Execution Surfaces
- Chrome Extension (Qx) — raw JSON payload submission
- Sidebar (QSB) — structured UI for common operations
- Mobile — Gateway access via phone browser
- ChatGPT Projects — Q (governance), Q@W (work), Q@Akara, Q@BlaggLife, Q@Greg
- Claude Code — implementation and execution

### Certification
- Phase 2C harness: 26 test cases covering Gateway + Save + Update + Promote
- All tests PASS as of 2026-03-22
- Harness is advisory (not yet a deployment gate)

---

## What Is In Progress

| Thread | Status | Summary |
|--------|--------|---------|
| T150 | Ready for execution | Person artifact type — design complete, schema deployed (DDL v2.10), Gateway/assistant/certification remaining |
| T145 | Sapling | Beta user provisioning and onboarding system — teaching layer locked |
| T152 | Blocked | Akara Gateway access — n8n config issues (Basic Auth + Beta Gatekeeper) |
| T118 | Blocked | parent_artifact_id update path — n8n import debug needed |
| T127 | In progress | Qwrk Exploratory GPT (demo proxy) — 47/47 tests PASS, auth added |
| T144 | Seed | Lifecycle alignment guardrail — enforce spine/extension alignment |

---

## What Is NOT Yet Built

These items are in the thread backlog but not active:

- **Gateway `execution_status` update action** (T111) — no Gateway route to update execution_status; workaround is direct SQL
- **Gateway `content` field update path** (T140) — spine `content` field not mutable via Gateway
- **Read-Only Gateway Layer** (T147) — 5 read-only actions scoped but not implemented
- **Classification architecture** (T78) — category/subcategory model not designed
- **Type registry implementation** (T66) — Phase 3 scope
- **Retry/restart contract v2** (T58) — restart system redesign, not started
- **v1 Gateway clone decommission** — v2 is live but v1 clones still exist

---

## Known Technical Debt

- Extension-only updates on projects can clear spine `summary` field (T88)
- n8n JSON import double-escapes regex in Normalize_Request (manual fix required after import)
- Gateway response shapers may swallow sub-workflow errors (T113 — audit needed across all gateways)
- Mobile console returns silent failures (T114)

---

## Key System Boundaries

| Boundary | Rule |
|----------|------|
| Database writes | Gateway only (service_role); CC is read-only |
| Workspace isolation | Artifacts cannot cross workspace boundaries |
| Immutability | Snapshots and restarts: no UPDATE, no DELETE |
| Audit log | Append-only, triggers block modification |
| Lifecycle transitions | Directional only (seed→sapling→tree→archive), no backward |
| Soft delete | All deletes set `deleted_at`; no hard deletes |

---

## CHANGELOG

### v1 — 2026-03-22
Initial creation for Manus plan reviewer role.
