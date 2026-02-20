# Snapshot: Full Access Enablement Restart Prompt

**Snapshot Type:** Governance / Restart Prompt
**Created:** 2026-01-24
**Artifact Type:** snapshot
**Status:** PENDING (awaiting prerequisite completion)

---

## Metadata

| Field | Value |
|-------|-------|
| Title | Full Access Enablement — Restart Prompt |
| Version | v1 |
| Author | CC (Claude Code) |
| Prerequisites | Gateway Workflow Fixes (Update, Promote, Save) |
| Source File | `docs/qwrk-instructions/Full_Access_Enablement__Restart_Prompt.md` |

---

## Summary

This snapshot captures the restart prompt for enabling **full access** (read + write) capabilities in the Qwrk GPT front-end. It documents:

1. New schema file: `Qwrk_Gateway_v1_Actions_Schema.yaml` (v2.0.0-dev)
2. New instructions file: `Qwrk_Full_Access_MVP_Instructions_v1.md`
3. Verification tasks for Type Registry, extension tables, and subworkflows
4. Test harness expansion requirements
5. Deployment and validation checklist

---

## Scope of Changes

### Actions Enabled
- `artifact.list` (read)
- `artifact.query` (read)
- `artifact.save` (write - create/update)
- `artifact.update` (write - PATCH semantics)
- `artifact.promote` (write - lifecycle transitions)

### Artifact Types Enabled
- `project` — full read/write/promote
- `journal` — read + create only (append-only)
- `restart` — read + create only (immutable)
- `snapshot` — read + create only (immutable)

---

## Task Checklist

- [ ] Verify Type Registry has all 4 types enabled
- [ ] Verify extension tables exist for all 4 types
- [ ] Review Query workflow for multi-type support
- [ ] Review List workflow for multi-type support
- [ ] Review Save workflow for multi-type support
- [ ] Add immutability guard to Update workflow
- [ ] Expand test harness for journal/restart/snapshot
- [ ] Deploy schema to ChatGPT Custom GPT
- [ ] Update system instructions in ChatGPT
- [ ] End-to-end validation

---

## Related Artifacts

| Artifact | Path/ID |
|----------|---------|
| Schema v2.0.0-dev | `docs/qwrk-instructions/Qwrk_Gateway_v1_Actions_Schema.yaml` |
| Instructions v1 | `docs/qwrk-instructions/Qwrk_Full_Access_MVP_Instructions_v1.md` |
| Workflow Fixes Prompt | `docs/testing/Gateway_Workflow_Fixes__Restart_Prompt.md` |
| Full Restart Prompt | `docs/qwrk-instructions/Full_Access_Enablement__Restart_Prompt.md` |

---

## Payload

The full restart prompt content is stored in the associated Qwrk artifact extension payload.
