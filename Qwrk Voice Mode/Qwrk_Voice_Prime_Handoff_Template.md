# Qwrk Voice — Prime Handoff Template

Voice output = a prompt Joel pastes into Qwrk Prime when back at the desk.

All templates are copy/paste ready. Fill the `<angle-bracket>` placeholders.

---

## Template 1 — Standard Artifact Capture

**Use when:** Voice is confident about artifact type AND semantic type.

```
Voice capture handoff — ready to save.

Suggested:
- Type: <journal | twig | project | snapshot | restart>
- Semantic type: <execution-core | governance | infrastructure | platform | product | alignment | sales | marketing | exploratory>
- Title: <short descriptive title>

Content / intent:
<cleaned, structured version of what Joel said>

Tags (suggested): <2–4 lowercase tags>

Action requested:
Prime — review, adjust if needed, and save.
```

---

## Template 2 — Uncertain Classification (Review Required)

**Use when:** Artifact type OR semantic type is unclear.

```
Voice capture handoff — CLASSIFICATION UNCERTAIN.

Raw intent:
<cleaned version of what Joel said>

Voice uncertainty flags:
- Artifact type: <best guess or "unclear">
- Semantic type: <best guess or "unclear">
- Why unclear: <one sentence — ambiguity, crosses two types, missing parent, etc.>

Action requested:
Prime — run a review pass. Determine correct artifact type and semantic type, confirm with Joel, then save.
```

---

## Template 3 — Needs Deeper Prime Governance

**Use when:** Request requires work beyond Voice scope — updates, promotions, cross-workspace writes, design work, multi-step work.

```
Voice capture handoff — PRIME GOVERNANCE REQUIRED.

Intent:
<cleaned statement of what Joel wants to happen>

Why escalated:
<one sentence — e.g., "cross-workspace write", "requires lifecycle transition", "touches multiple artifacts", "needs design pass">

Voice context captured:
<any relevant context Joel shared that Prime should know>

This requires Prime-level validation / execution.

Action requested:
Prime — handle governance, validation, and execution. Confirm back when complete.
```

---

## Template 4 — Continue Conversation in Prime

**Use when:** Joel wants to resume a Voice thread at the desk with full Prime governance.

```
Voice conversation handoff — CONTINUE IN PRIME.

Topic: <one line>

What was discussed in Voice:
- <point 1>
- <point 2>
- <point 3>
- <optional 4th–5th>

Where we left off:
<the last question, decision point, or open thread>

Action requested:
Prime — pick up from here with full Prime governance available. If a restart artifact would help preserve continuity, save one.
```

---

## Template 5 — Capture Finalization [EXPLICIT OVERRIDE ONLY]

> **This is capture finalization, not execution.**
>
> Voice produces the finalized capture form. Joel still executes it — via QSB pasting into Prime, or another Prime-connected surface. Voice does not run the save.
>
> - **Explicit override only** — use only when Joel explicitly requests a finalized capture ("give me the payload," "emit the save," "prime-exec").
> - **Journal finalization only.** No twig, project, snapshot, restart, update, promote, messaging, `artifact.list`, `artifact.query`, or cross-workspace capture is permitted from Voice — ever.
> - **Prime remains the executor.** Default Voice output is a Prime-ready prompt (Templates 1–4). Template 5 skips Prime's shaping step and hands Joel a directly-executable capture — but Joel (via QSB/Prime) still runs it.
>
> For anything other than a journal capture: decline politely and redirect to Template 1 or Template 3 — *"I'll generate a handoff prompt for Prime — that one needs Prime's validation."*

### Finalized journal capture (payload form)

```
prime-exec

{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "<short title>",
  "semantic_type_id": "<one of the 9 registry values>",
  "tags": ["<tag1>", "<tag2>"],
  "extension": {
    "entry_text": "<cleaned content>"
  }
}
```

**Template 5 is journal-only.** If Joel explicitly asks to finalize a twig / project / snapshot / restart capture, decline politely and offer Template 1 or 3 instead: *"I'll generate a handoff prompt for Prime — that one needs Prime's parent lookup / validation."*
