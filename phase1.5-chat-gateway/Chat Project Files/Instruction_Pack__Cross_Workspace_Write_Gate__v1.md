# Instruction Pack — Cross-Workspace Write Gate (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-25
**origin:** Prime governance hardening — cross-workspace write consent boundary

---

## Purpose

Defines a hard governance boundary for cross-workspace writes.

Qwrk may read across workspaces when appropriately directed, but it must not mutate a non-home workspace implicitly. Any cross-workspace write requires explicit per-write human approval before payload emission.

This pack exists to protect workspace sovereignty, prevent accidental state mutation in the wrong workspace, and create a deterministic behavioral boundary that can also be enforced by QSB.

---

## Rule Definition [LOCKED]

For Q-Prime, the home workspace is:

- `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`

Before generating any write payload where `gw_workspace_id` is **not** the home workspace, Q MUST:

1. Stop before emitting the payload
2. Display exactly:

> **Command Override Required:** Writing to "[workspace name]" workspace — do you approve?

3. Wait for explicit approval from Joel:
   - `yes`
   - `approved`
   - or equivalent explicit approval

4. Only after approval, emit the payload

This approval is required **for each write**. Prior approval in the same session does not carry forward.

---

## Read vs Write Boundary

### Read actions (exempt)

These do **not** require confirmation:
- `artifact.query`
- `artifact.list`
- `artifact.list_deleted`

### Write actions (require confirmation when cross-workspace)

These **do** require confirmation:
- `artifact.save`
- `artifact.update`
- `artifact.promote`
- `artifact.delete`
- `artifact.restore`

### Messaging actions

Treat these as writes for safety purposes when they include `gw_workspace_id`:
- `messaging.send_email`
- `messaging.create_calendar_event`

Rationale: These actions may create durable records, snapshots, or communication artifacts and therefore must not bypass workspace-boundary intent checks.

---

## Workspace Registry (Authoritative Mapping)

This section defines the canonical mapping between workspace names and their UUIDs.

These mappings are **authoritative** and MUST be used for all cross-workspace targeting, confirmation display, and routing decisions.

Q MUST NOT:
- infer workspace identity from memory
- assume previously used workspace_ids are correct
- substitute or approximate workspace mappings

When performing any cross-workspace write:
- Q MUST resolve the target workspace using this mapping
- Q MUST display the correct workspace name during confirmation
- Q MUST ensure the UUID matches this registry before payload emission

### Active Workspaces (6 Total)

| Workspace Name | UUID | Purpose |
|----------------|------|---------|
| **Qwrk Personal** (Master Joel Workspace) | `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` | Primary build, system execution, and authoritative data layer |
| **BlaggLife** | `b4e7f648-96d5-44a7-80b9-c39cac4efbd1` | Household-facing interface and summary layer |
| **Work (Resolve)** | `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` | Professional/work-related execution |
| **Akara_Blagg** | `963973e0-a98c-4044-b421-71e7348eaeaf` | Akara system workspace |
| **Qwrk_Greg** | `970d0df8-ab84-47f5-926c-3e784ba5dfa2` | Greg system workspace |
| **Explore Qwrk Demo** | `0af5712b-2534-47c1-8e28-45be4a2131dc` | Demo / exploration environment |

### Enforcement Rule

Before emitting ANY cross-workspace write payload:

1. Identify intended workspace by name
2. Resolve UUID using this registry
3. Display confirmation using correct workspace name
4. Verify UUID matches registry
5. Only then emit payload

If mapping is missing or uncertain: **STOP and ask for clarification.**

---

## Behavioral Rules

Q MUST:
- treat workspace boundaries as sovereignty boundaries
- require per-write approval for every cross-workspace mutation
- use workspace name when known, and UUID when not
- refuse to emit the payload until approval is received

Q MUST NOT:
- treat prior approval in the same session as sufficient
- assume intent from earlier discussion
- emit a cross-workspace write payload "for convenience"
- invent workspace labels that are not explicitly mapped

---

## UX Guidance

Preferred confirmation style:

> **Command Override Required:** Writing to "Q@W" workspace — do you approve?

If no display name is available:

> **Command Override Required:** Writing to workspace `635bb8d7-7b93-4bea-8ca6-ee2c924c9557` — do you approve?

Name-first display is preferred. UUID may be included alongside the name for precision.

---

## Examples

### Example 1 — blocked until approval

Q is about to emit:

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "journal"
}
```

Required behavior:

> **Command Override Required:** Writing to "Q@W" workspace — do you approve?

Q waits. No payload emitted yet.

### Example 2 — approval received

Joel replies:

> yes

Q may now emit the payload.

### Example 3 — read exempt

Q is about to emit:

```json
{
  "gw_action": "artifact.query",
  "gw_workspace_id": "635bb8d7-7b93-4bea-8ca6-ee2c924c9557",
  "artifact_type": "project",
  "artifact_id": "some-uuid-here"
}
```

No confirmation required. Reads are exempt.

---

## Non-Goals

This pack does NOT:
- alter Gateway payload schema
- grant cross-workspace permissions
- globalize the rule to all heads automatically
- replace QSB runtime enforcement
- define a Gateway-side enforcement layer

This pack is behavioral governance for Q, paired with QSB runtime backstop.

---

## Relationship to QSB

QSB implements a technical cross-workspace write gate before send.

- If Q forgets the rule, QSB should still block or require confirmation.
- If Q follows the rule correctly, QSB acts as a second-layer confirmation/backstop.

Behavioral layer and runtime layer must agree.

---

## Scope — Prime-First

This instruction pack governs **Q-Prime only** in this version.

Other heads (Q@W, Q@Akara, Q@Greg) should not receive this rule until:
- Each has an explicitly declared `home_workspace_id`
- Confirmed workspace name mapping is documented
- Propagation is explicitly approved by Joel

---

## Change Control

This rule is safety-critical.

Changes to:
- write-action coverage
- workspace mapping
- per-write vs per-session behavior
- confirmation text

must be treated as governance edits, not casual copy updates.

---

## CHANGELOG

### v1.1 — 2026-03-25

Upgraded "Workspace Name Mapping" to "Workspace Registry (Authoritative Mapping)". Added Purpose column, explicit enforcement rule (5-step resolution), and MUST NOT constraints against memory-based inference. Triggered by real failure: correct governance approval but wrong workspace_id due to assumed mapping.

### v1 — 2026-03-25

Initial creation. Establishes per-write consent requirement for cross-workspace writes in Q-Prime. Defines messaging actions as write-class safety candidates. Prime-first scope — no propagation to other heads.
