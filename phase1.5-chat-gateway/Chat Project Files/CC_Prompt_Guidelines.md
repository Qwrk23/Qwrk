# CC Prompt Formulation Guidelines (Internal)

Purpose:
This document exists for one reason only: to help Qwrk generate consistently high-quality, deterministic, and effective prompts for Claude Code (CC). It is not a general prompt engineering guide. It is an operational checklist and mental model for interacting with CC as a coding agent.

Core Principle:
Claude Code performs best when it is given clear goals, explicit success criteria, bounded context, and permission to reason step by step. Ambiguity, oversized scope, and missing verification signals degrade results.

---

1. Always Start With the Outcome

Every CC prompt must explicitly state:
- What is being built, changed, or analyzed
- What "done" means
- How success will be verified

If tests, acceptance criteria, or validation steps exist, include them. If they do not exist, instruct CC to propose them before implementing.

---

2. Scope Ruthlessly

Never ask CC to "handle everything."
Instead:
- Define the smallest executable unit
- Explicitly state what is out of scope
- If work spans multiple steps, ask CC to plan first

When scope creep risk exists, include a short "Non-Goals" or "Explicitly Excluded" list. This prevents CC from helpfully expanding into areas you did not intend.

Large changes should be broken into phases: plan, confirm, implement.

---

3. Provide the Right Context (No More, No Less)

Include:
- Relevant files, paths, or modules
- Architectural constraints or invariants
- Governance rules or non-negotiables

Exclude:
- Historical discussion unless it affects decisions
- Speculation or future ideas not required for the task
- Redundant explanations CC already has from prior steps

When referencing files, provide paths rather than pasting content. CC can read files itself. Only paste excerpts when highlighting specific sections.

If context is long, summarize it yourself instead of pasting raw content.

---

4. Make Reasoning Explicit

When the task is non-trivial, instruct CC to:
- Think step by step
- Explain assumptions before coding
- Flag uncertainties or risks

This prevents silent misalignment and surfaces errors early.

---

5. Use Roles Deliberately

When useful, assign CC a role such as:
- "Act as a senior backend engineer familiar with Supabase and RLS"
- "Act as a careful refactoring assistant prioritizing safety over speed"

Roles should constrain behavior, not add flavor.

---

6. Enforce Determinism

Prefer language like:
- "Do not proceed until X is confirmed"
- "If information is missing, ask before acting"
- "Produce output in this exact structure"

Avoid:
- Vague encouragement ("do your best")
- Open-ended creativity unless explicitly desired

Default output contract: If no output format is specified, CC should default to: Summary, Plan, Risks, Next Action.

---

7. Anticipate Failure Modes

Explicitly guard against common CC issues:
- Making assumptions about missing files
- Overwriting unrelated code
- Implementing beyond the requested scope
- Skipping verification steps

When modifying existing systems, prefer additive or reversible changes unless explicitly authorized to refactor or delete. This reduces blast radius when assumptions are wrong.

If a mistake would be costly, name it in advance.

---

8. Close With a Clear Next Action

End every prompt with one of:
- "Confirm understanding and propose a plan"
- "Proceed with implementation as specified"
- "Ask any blocking questions before continuing"

Never leave CC guessing what to do next.

---

9. Iterate Rather Than Re-prompt

If CC's first attempt misses the mark, provide specific feedback rather than re-prompting from scratch. CC learns within the session and can self-correct with targeted guidance.

---

10. Use Restart Blocks for Multi-Session Work

For work that spans multiple CC sessions, include a Restart block with:
- Prior session context (what was done)
- Active constraints or governance rules
- Immediate next step

This ensures CC resumes with full awareness rather than starting cold.

---

Operating Rule for Qwrk:
When generating prompts for Claude Code, Qwrk must mentally walk through this document before sending the prompt. If any section is missing, the prompt is incomplete.
