# CC Prompt — Remove Surface Split; JSON-Only Execution Everywhere

Role: Act as a careful refactoring assistant. Prioritize safety, determinism, and zero drift.

## Outcome
Update Qwrk docs + system instructions so **ALL execution surfaces use JSON gateway payloads**. The old “desktop vs mobile/Telegram” execution split must be removed everywhere it still exists.

## Definition of Done
1. No documentation in the repo suggests different execution formats by surface (desktop vs mobile vs Telegram).
2. All “Telegram natural language” save/list/retrieve/promote commands are removed or clearly marked **ARCHIVED / DEPRECATED**.
3. A single, unified execution doctrine remains: **JSON payloads only**, plus **raw JSON invariant** for execution.
4. Any remaining “Telegram formatting rules” (single paragraph, no markdown, etc.) are removed from active docs.
5. You return:
   - A concise **change log** (what files changed, what was removed/added)
   - A **step-by-step manual checklist for Joel/Q** to finish anything that cannot be done in-repo (e.g., updating pinned docs, deploying updated instruction packs, moving archived files, updating ChatGPT Project attachments)

## Scope
### In scope
- Update/clean these files (or their equivalents in the repo):
  - `Qwrk_Quick_Reference.md` (or similarly named quick reference card)
  - `TELEGRAM_COMMANDS.md`
  - `TELEGRAM_PAYLOAD_RULES.md`
  - `PAYLOAD_EXAMPLES.md`
- Update the **system instructions markdown** file (the active one in the repo, e.g. `Qwrk_SYSTEM_INSTRUCTIONS_*.md`) to remove surface-based branching and any references to Telegram NL execution.
- Add an **Archive** record for deprecated Telegram NL docs.

### Explicitly NOT in scope
- No workflow/n8n changes.
- No database changes.
- No gateway contract changes.

## Required Behavior Changes (Specific Edits)
1. **Replace “Session Surface Declaration” logic** with a single rule:
   - “All execution uses JSON gateway payloads. Surface does not matter.”
2. Keep and strengthen the **Raw JSON Invariant**:
   - Payload must be raw JSON only.
   - One payload per execution.
   - Sequential action discipline applies.
3. Remove or archive:
   - Any “Save journal titled … with tags …” natural language command examples.
   - Any “plain text single paragraph, no markdown” Telegram formatting rules.
   - Any “list journals” / “retrieve 1” Telegram command docs.
4. Ensure any remaining references to Telegram are limited to **transport only**, not formatting.
   - If Telegram is mentioned at all, it should say it is just a delivery channel for JSON payload execution.

## File Operations
- Create an `Archive/` entry (or use existing archive structure) for deprecated Telegram NL docs.
- If you archive files, add a short header at top of archived files:
  - `STATUS: ARCHIVED` + date + one-line reason.

## Suggested Repo Search Terms (use ripgrep)
Search for and eliminate/replace:
- “mobile”
- “desktop”
- “Telegram natural language”
- “Save journal titled”
- “list journals”
- “retrieve 1”
- “plain text only”
- “single paragraph”
- “no markdown”
- “Chrome Extension” (keep only the raw JSON invariant, remove desktop framing)

## Verification
After edits:
1. Run a repo-wide search for “Save journal titled” and confirm **0** hits outside Archive.
2. Run a repo-wide search for “retrieve 1” and confirm **0** hits outside Archive.
3. Run a repo-wide search for “mobile”/“desktop” and confirm remaining mentions are non-execution (or none).
4. Confirm the quick reference contains:
   - Canonical JSON payload example for journal save including `priority`.
   - No mention of different formats by surface.

## Deliverables
1. PR-style summary:
   - Files changed
   - Files archived
   - Key deltas
2. Manual completion checklist for Joel/Q (step-by-step):
   - Exactly what needs to be updated outside the repo (e.g., ChatGPT Project attached files, instruction pack regeneration, any pinned references)
   - Provide the exact file names/paths and the exact steps.

## Final Instruction
Do not implement anything beyond this scope. If you discover ambiguous references, normalize them to the new rule: **JSON-only execution everywhere**.

