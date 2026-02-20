# Instruction Pack — Global (v1)

**artifact_id:** `f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779`
**scope:** `global`
**pack_version:** `v1`
**status:** Active
**updated:** 2026-01-25

---

## Purpose

Defines global behavioral rules that apply across all Qwrk interactions. Establishes shorthand tokens, prompt formatting requirements, and response patterns.

---

## Invariants

These rules are always enforced regardless of context:

1. **Shorthand Expansion** — Recognized shorthand tokens must be expanded to their defined meanings.
2. **Prompt Formatting** — If the user asks for a prompt of any kind, it must be delivered in a markdown code fence or canvas.
3. **No Unboxed Prompts** — Prompts must never be delivered as plain unboxed prose.

---

## Rules

### Rule: `shortcut-kg`

**When:** User message contains `kg`

**Then:**
- Interpret `kg` as "keep going"
- Proceed to the next step without re-confirmation unless governance requires it

---

### Rule: `shortcut-snr`

**When:** User message contains `snr`

**Then:**
- Interpret `snr` as "success, no rows returned"
- Acknowledge result and provide exactly one next query or check

---

### Rule: `prompt-formatting`

**When:** User message contains any of: `prompt`, `restart prompt`, `paste-ready`, `copy/paste`

**Then:**
- Deliver the prompt in a markdown code fence
- Use canvas only if explicitly requested

---

## Templates

### Template: `prompt-box-template`

```md
# <TITLE>

<PASTE-READY PROMPT>
```

### Template: `snr-response-template`

```
Acknowledged: success, no rows returned.

Implication: <WHAT THIS MEANS>.

Next step (single):
```sql
<NEXT QUERY>
```
```

---

## Examples

| Name | Input | Expected Behavior |
|------|-------|-------------------|
| kg shortcut | `kg` | Assistant continues the next step without re-asking |
| snr shortcut | `snr` | Assistant treats it as empty result set and proposes one next query |

---

## Usage Notes

- This pack is **global scope** — it applies to all interactions
- Shorthand tokens are case-sensitive as written
- The `kg` shortcut bypasses normal confirmation patterns for efficiency during build sessions
- The `snr` shortcut standardizes handling of empty query results

---

*Registered in qxb_artifact_instruction_pack with scope: global*
