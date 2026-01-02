# Restart Prompts — Session Continuation

**Context preservation for resuming Qwrk development sessions**

---

## Purpose

Restart prompts enable seamless session continuation when working with AI assistants (Claude Code, ChatGPT, etc.) on the New Qwrk build.

Each prompt captures:
- Current system state (what's built, what's locked)
- Known-Good baseline (KGB) status
- Next steps / options
- Governance rules in effect

---

## How to Use

### Starting a New Session

1. **Copy the latest restart prompt**
2. **Paste at the beginning of a new conversation**
3. **AI assistant resumes with full context**

### Which Prompt to Use

Use the **most recent** restart prompt for the area you're working on:

- **Gateway work**: `2025-12-31_Gateway.md`
- **Schema/RLS work**: `2025-12-30_PostSeed_RLSFix.md`

---

## Available Prompts

### 2025-12-31_Gateway.md

**Context**: Gateway v1 MVP status

**Covers**:
- `artifact.query` validated across 4 types
- Spine-first architecture in place
- Type mismatch guards active
- Next steps: artifact.list, NOT_FOUND handling, response envelopes

**Use when**: Resuming Gateway workflow development

---

### 2025-12-30_PostSeed_RLSFix.md

**Context**: Kernel v1 schema + RLS post-seed status

**Covers**:
- Supabase project: `npymhacpmxdnkdgzxll`
- Bundle OK + RLS OK + KGB OK
- RLS infinite recursion fix applied
- Minimal seed + read-path sanity check: PASS

**Use when**: Resuming database schema or RLS work

---

## Prompt Structure

Standard restart prompt includes:

### 1. Current System State (AUTHORITATIVE)

Describes what is complete, verified, and locked:
- Gateway/workflow status
- Schema execution status
- KGB validation results
- Governance rules in effect

### 2. Architectural Milestone Reached (CONTEXTUAL, NON-BINDING)

Optional snapshots or coordination artifacts:
- Combined snapshots
- Phase completions
- Governance frameworks

### 3. Status Sections

- ✅ Last completed step
- ❌ What has NOT been done yet (gating)
- 📍 Type B behaviors / future work

### 4. Rules for This Session

Explicit behavior expectations:
- No new features until gates pass
- Proceed one step at a time
- Test requirements
- Auditability over inference

### 5. First Question to Ask

Provides 2-3 options for resuming work:
- "Do you want to begin [next step]?"
- "Do you want a recap before proceeding?"
- "Do you want to stop here and resume later?"

---

## Creating New Restart Prompts

When creating a new restart prompt:

### Required Sections

1. **Title**: `RESTART — [Area] ([Brief Context])`
2. **Where we are**: Current state summary
3. **IDs (Known-Good)**: UUIDs for testing/validation
4. **Status summaries**: What's locked, what's in progress
5. **Next step gate**: What to do when resuming
6. **Rules**: Governance expectations

### Naming Convention

`YYYY-MM-DD_[Area].md`

Examples:
- `2026-01-05_Artifact_Promote.md`
- `2026-01-10_Structure_Layer.md`

### Content Guidelines

- **Be specific**: List exact file versions, workflow states
- **Be deterministic**: No ambiguity about what works
- **Gate clearly**: Explicit "do X before Y" rules
- **Preserve context**: Include relevant UUIDs, test IDs
- **Minimize prose**: Bullet points over paragraphs

---

## Best Practices

### For Users

- **Update prompts** after major milestones
- **Archive old prompts** (don't delete - history matters)
- **Test prompts** before relying on them
- **Version prompts** if iterating on the same area

### For AI Assistants

- **Read the entire prompt** before responding
- **Ask clarifying questions** if state seems unclear
- **Respect gates** (don't skip locked prerequisites)
- **Follow pacing rules** (one step at a time)

---

## Versioning

Restart prompts use **date-based versioning** (not semantic):

- `2025-12-30_` - Initial version for that area
- `2025-12-31_` - Updated version (next day or major change)
- `2026-01-02_` - Latest version

**No backward compatibility required** - always use the latest prompt.

---

## Archive Policy

- **Keep all prompts** (don't delete)
- **Mark superseded prompts** with `[SUPERSEDED]` in filename
- **Latest prompt** is always at the top when sorted by date

Example archive structure:
```
restart_prompts/
├── 2026-01-10_Gateway.md           # Latest
├── 2025-12-31_Gateway.md           # Previous
└── 2025-12-30_PostSeed_RLSFix.md   # Initial
```

---

## Integration with CLAUDE.md

Restart prompts **complement** but do not replace `CLAUDE.md`:

- **CLAUDE.md**: Permanent governance rules
- **Restart prompts**: Temporal state snapshots

When resuming:
1. AI reads CLAUDE.md (governance)
2. AI reads restart prompt (state)
3. AI proceeds under both contexts

---

## Troubleshooting

### Prompt Feels Stale

**Symptom**: Restart prompt references old status or completed work

**Solution**: Create a new prompt reflecting current state

### Conflicting Information

**Symptom**: Restart prompt contradicts CLAUDE.md or North Star

**Resolution Order**:
1. CLAUDE.md (governance)
2. North Star / Phase 1-3 (architecture)
3. Restart prompt (state snapshot)

If conflict persists, update the restart prompt.

### Too Much Context

**Symptom**: Restart prompt is too long (>500 lines)

**Solution**: Split into:
- **Current state** (restart prompt)
- **Historical context** (separate doc in snapshots/)

---

## Examples

### Minimal Restart Prompt

```
RESTART — [Area] ([Context])

Where we are:
- [Component] is complete and validated
- [Tests] pass
- [Feature] locked

Next step: Begin [Next Feature] once approved
```

### Comprehensive Restart Prompt

See `2025-12-30_PostSeed_RLSFix.md` for full example including:
- Authoritative state
- Milestones reached
- Type B behaviors (deferred)
- Last completed step
- What has NOT been done (gating)
- Rules for session
- First question

---

## References

- [CLAUDE.md](../governance/CLAUDE.md) - Governance rules
- [North Star](../architecture/North_Star_v0.1.md) - Vision
- [Phase 1-3](../architecture/Phase_1-3_Kernel_Semantics_Lock.md) - Semantics

---

**Last Updated**: 2026-01-02
**Active Prompts**: 2
