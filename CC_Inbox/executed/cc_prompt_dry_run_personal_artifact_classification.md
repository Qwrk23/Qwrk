## EXECUTION-READY PROMPT (DO NOT MODIFY)

### Role
Act as a careful classification assistant. Prioritize safety, conservatism, and explicit reasoning over speed or completeness.

### Objective
Produce a **dry-run report** identifying existing Qwrk artifacts that are **high-confidence personal**, suitable for later tagging with a `personal` tag. This task is classification-only and must not mutate system state.

### Binding Definition — What Qualifies as Personal
An artifact qualifies as **personal** if it primarily relates to Joel’s:
- personal life
- health or wellbeing
- identity, reflection, journaling
- relationships, inner work, spirituality, or personal growth

An artifact is **NOT personal** if it relates to:
- Qwrk system governance, architecture, or rules
- Qwrk build projects, planning, or execution
- paid work, employment, consulting, or client deliverables
- operational tooling, infrastructure, automation, or integrations

**Conservative rule:** When in doubt, do **not** classify.

### Scope
- Analyze all artifacts accessible in the current workspace
- Use only existing artifact data: title, artifact_type, tags, summary, and content (if present)
- Do not infer intent beyond what is explicitly represented

### Constraints (Non‑Negotiable)
- ❌ Do NOT modify, tag, update, move, promote, delete, or otherwise mutate any artifact
- ❌ Do NOT propose lifecycle changes
- ❌ Do NOT assume future forest structure or workspace separation
- ❌ Do NOT create new artifacts
- ✅ Read-only analysis only
- ✅ High-confidence classification only

### Output Requirements (Strict)
Produce **one Markdown file** named:

`personal_artifact_classification_dry_run.md`

The file must contain the following sections **in this order**:

---

#### 1. Summary
- Total artifacts reviewed
- Number classified as high-confidence personal
- Number skipped due to ambiguity

---

#### 2. High-Confidence Personal Artifacts
A table with **one row per artifact**, containing:
- artifact_id
- artifact_type
- title
- current tags (as a comma-separated list)
- justification (1–2 concise sentences explaining why this is personal)

Only include artifacts that clearly meet the personal definition.

---

#### 3. Ambiguous / Skipped Artifacts (Optional)
Include this section **only if applicable**.
A table containing:
- artifact_id
- artifact_type
- title
- reason skipped (why classification confidence was insufficient)

---

#### 4. Explicit Confirmation (Required)
End the document with the following statement verbatim:

> No artifacts were modified. No tags were applied. This was a dry run only.

### Non‑Goals (Explicitly Excluded)
- No tagging
- No migration or re‑homing
- No forest assignment
- No governance recommendations
- No lifecycle commentary
- No prioritization or cleanup suggestions

### Completion Signal
Task is complete when the Markdown file is produced exactly as specified and no system state has been changed.

Proceed with analysis and generate the report.

