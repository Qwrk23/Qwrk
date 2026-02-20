# Restart — Gateway Owner Source Surfaced

**Artifact Type:** restart
**Artifact ID:** f6c12ee1-4b4a-4deb-8f7f-862d88ae5550
**Workspace ID:** be0d3a48-c764-44f9-90c8-e846d9dbbd0a
**Date:** 2026-01-10
**Status:** Execution-proven

---

## Purpose

Capture the milestone where **Gateway v1 now surfaces `_owner_source`** in the top-level response envelope for `artifact.save`, with full PowerShell execution proof.

This resolves:
- Save → Gateway context loss
- Owner attribution opacity during MVP
- Debug visibility gaps prior to auth hardening

---

## What Changed

- Gateway response builder was updated to include `_owner_source`
- `_owner_source` is derived exclusively inside Save
- Gateway surfaces `_owner_source` without fabricating or guessing
- Verified via paste-and-run PowerShell execution

---

## Execution Proof

The Gateway returned:

- `ok: true`
- `gw_action: artifact.save`
- `artifact_type: restart`
- `operation: INSERT`
- `_owner_source: mvp_service_principal`

**Referenced proof artifact:**
- artifact_id: `fd4a7794-d852-45d2-9a28-65455589fb4b`
- timestamp: `2026-01-10T15:19:40.496Z`

**The Restart artifact saved with ID:**
- `f6c12ee1-4b4a-4deb-8f7f-862d88ae5550`

---

## Constraints & Invariants

- Caller never supplies `owner_user_id`
- Owner is derived inside Save (MVP service principal)
- `_owner_source` is temporary but mandatory until auth hardening
- PowerShell tests are paste-and-run, no prompts, no placeholders
- Gateway URL is never invented; sourced from environment variable

---

## Next Step

Proceed to the next Gateway objective using the same:
- Build discipline
- Evidence-first PowerShell testing
- Direct-execute scripts

---

**END OF RESTART**
