# Instruction Pack — Build Discipline (v1)

**artifact_id:** *(generated on insert)*
**scope:** `mode:build`
**pack_version:** `v1`
**status:** Active
**created:** 2026-01-25

---

## Purpose

Enforces disciplined execution during build/implementation sessions. Prevents multi-step dumps, ensures stop-and-wait patterns, and maintains receipt-driven workflow governance.

---

## Invariants

These rules are always enforced when build mode is active:

1. **One Step at a Time** — When building, only one actionable step may be provided at a time.
2. **Stop and Wait** — Runnable commands or SQL must be followed by a stop-and-wait for results.
3. **No Multi-Step Dumps** — Multi-step dumps are prohibited unless explicitly requested.

---

## Rules

### Rule: `one-step-only`

**When:** Context contains any of: `build`, `building`, `implement`, `execute`, `run sql`

**Then:**
- Provide exactly one next action
- Explain why it is next
- Request the receipt before continuing

---

## Templates

### Template: `build-next-step-template`

```
Next step (single):
```sql
<QUERY>
```
Paste the result and I will continue.
```

---

## Examples

| Name | Input | Expected Behavior |
|------|-------|-------------------|
| build single step | "We are building. Find the missing row." | Assistant returns one SQL query and waits |

---

## Activation

This pack activates when:
- User explicitly enters "build mode"
- Context indicates implementation work (building, executing, implementing)
- SQL or command execution is in progress

## Deactivation

This pack deactivates when:
- User exits build mode
- Context shifts to research/exploration
- User explicitly requests multiple steps at once

---

## Governance Integration

The Build Discipline pack reinforces Qwrk's receipt-driven governance model:

1. **Receipt Required** — No forward progress without confirmation of prior step
2. **Single Point of Failure** — If a step fails, it's immediately visible
3. **Audit Trail** — Each step is explicitly acknowledged before the next

This prevents:
- Silent failures buried in multi-step output
- User confusion about which step caused an issue
- Loss of context during complex implementations

---

## Usage Notes

- Scope `mode:build` means this pack only applies during build sessions
- Priority 0 (default) — can be overridden by higher-priority packs if needed
- Works in conjunction with Global pack shortcuts (`kg`, `snr`)

---

*Registered in qxb_artifact_instruction_pack with scope: mode:build*
