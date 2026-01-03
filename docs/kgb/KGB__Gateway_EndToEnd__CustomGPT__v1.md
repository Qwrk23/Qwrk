# KGB — Gateway End-to-End (CustomGPT) (v1) — 2026-01-02

## Purpose
Prove the CustomGPT front end can Save/Query/List using Gateway Actions.

## Pre-reqs
- GPT Actions configured:
  - Save
  - Query
  - List
- All actions point at the same Gateway endpoint
- Owner-only auth posture in effect

## Test steps
1. In CustomGPT: Save a Project (“Seed — Test Save from CustomGPT”).
2. In CustomGPT: Query it back by returned artifact_id.
3. In CustomGPT: List Projects; confirm it appears.
4. Confirm response shapes match the contract (no accidental field nesting).

## Expected results
- Deterministic responses
- No missing routing (gw_action always matches)
- Errors are readable and stable

## Evidence to capture
- Screenshots or copied JSON from each action call (redacted)

