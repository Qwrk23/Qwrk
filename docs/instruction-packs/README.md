# Instruction Packs — Registry Documentation

**Status:** Phase 2 (Pending Type Registration)
**Last Updated:** 2026-01-25

---

## Overview

Instruction Packs are behavioral rule sets that modify Qwrk's behavior based on context, mode, or scope. They are stored as `instruction_pack` artifacts in the Qwrk kernel database.

---

## Current Packs

| Pack | Scope | Version | Status | artifact_id |
|------|-------|---------|--------|-------------|
| [Global](./Instruction_Pack__Global__v1.md) | `global` | v1 | Active | `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779` |
| [Build Discipline](./Instruction_Pack__Build_Discipline__v1.md) | `mode:build` | v1 | Active | *(generated)* |
| [Phase 2 Governance Hardening](./Instruction_Pack__Phase2_Governance_Hardening__v1.md) | `architecture:workflow` | v1 | Active | *(generated)* |

---

## Scope Types

| Scope | Meaning | Activation |
|-------|---------|------------|
| `global` | Applies to all interactions | Always active |
| `mode:build` | Applies during build/implementation sessions | Context-triggered |
| `mode:research` | Applies during research/exploration | Context-triggered |
| `artifact:<type>` | Applies when working with specific artifact type | Type-triggered |
| `architecture:workflow` | Applies to workflow engineering and design decisions | Always active |

---

## Pack Structure

Each instruction pack contains:

```json
{
  "pack_version": "v1",
  "scope": "<scope>",
  "invariants": ["Always-true rules"],
  "rules": [
    {
      "id": "rule-name",
      "when": { "trigger_condition": [...] },
      "then": { "assistant_behavior": [...] }
    }
  ],
  "templates": [
    {
      "id": "template-name",
      "text": "Template content"
    }
  ],
  "examples": [
    {
      "name": "example-name",
      "input": "User input",
      "expected": "Expected behavior"
    }
  ]
}
```

---

## Database Schema

**Spine:** `qxb_artifact` (artifact_type = 'instruction_pack')
**Extension:** `qxb_artifact_instruction_pack`

| Field | Type | Description |
|-------|------|-------------|
| scope | text | Activation scope |
| active | boolean | Whether pack is currently active |
| priority | integer | Resolution order (lower = higher priority) |
| pack_format | text | Format type (json) |

---

## Gateway Integration (Phase 2)

Once `instruction_pack` is registered in the Type Registry:

- `artifact.list` with `artifact_type: instruction_pack` will return all packs
- `artifact.query` will return full pack content
- `artifact.save` will allow creating new packs via Gateway

**Current Status:** instruction_pack is intentionally deferred to Phase 2. Packs are currently managed via direct SQL until Gateway integration is complete.

---

## Adding New Packs

Until Phase 2 Gateway integration:

1. Write pack content as JSON matching the structure above
2. Insert into `qxb_artifact` with `artifact_type: instruction_pack`
3. Insert extension row into `qxb_artifact_instruction_pack`
4. Document in this folder

---

*This documentation supports the Qwrk V2 Constitution governance model.*
