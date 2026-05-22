# QPA Lite Static Startup Menu — Custom GPT Operational Spec v1

**File:** `QPA_Lite_Static_Startup_Menu__CustomGPT_Spec_v1.md`
**Status:** Reviewed and approved for repo persistence — primary revisable copy. Planning input, not build-authorizing.
**Date:** 2026-05-22
**Initiative:** QPA Lite Static Startup Menu for Qwrk Beta
**Tracking home:** T214 — QPA Lite Static Startup Menu for Qwrk Beta
**Project seed:** `339829b9-1369-4dd7-806b-6ec982d28e5b`
**Derived from:**
- PRD v1.1 — `a25e8d41-19c4-472d-ada0-6c33634fbefd` (governance/product truth)
- Branch 1 Startup Surface — `4a34d70c-59f4-424f-a6d9-4c4bd6421dee`
- Branch 2 Get Oriented — `58b296eb-7406-45ee-86eb-592c4470c21c`
- Branch 3 Capture / Journal — `6901e986-da4b-4b57-93a9-07b8e1723fa3`
- Branch 4 Work on a Project — `8aa4cb06-30d5-4f42-9db5-1322c0206f6d`
- Branch 5 My Workbench — `e3d3149e-10f5-4e24-86a5-75009ce7dbe3`
- Branch 6 Find Something I Saved — `a8867369-d88e-4420-9195-89e299fc9226`
- Branch 7 Explore / Figure Something Out — `b9cfa06b-623d-42fc-b8b3-4036f5af8b61`
- Branch 8 Learn / Help / Support — `bfd4aa9d-31dd-4316-9c3c-100cbbd39d01`
- Branch 9 Wrap Up / Save Where I Left Off — `6c41a9b1-132a-4472-a407-c57cfbe7888a`

> This file is the Custom GPT-facing operational menu contract derived from PRD v1.1 and owner-approved branch decisions. It does not authorize build or mutation.

## Authority Model

| Layer | Role |
|---|---|
| PRD v1.1 (`a25e8d41`) | Governance / product truth. If this spec ever conflicts with PRD v1.1, PRD v1.1 wins. |
| This Menu Spec | Operational behavior / router for the Custom GPT runtime surface. Derived, not normative. |
| Branch decision snapshots (9) | Owner-approved branch behavior. This spec must not contradict them. |
| T214 | Tracking home for the initiative. |
| Future build plan | Implementation work — **not authorized**. This spec is planning input only. |

---

## 1. Purpose and Scope

QPA Lite is the plain-language startup/menu layer for Qwrk Beta users. After a beta user completes the required startup/load step, QPA Lite presents a clear, calm operating surface that helps the user decide what to do next — without requiring any knowledge of Qwrk's internal model.

QPA Lite reduces blank-canvas friction while preserving user freedom: the user may pick a menu option **or** ignore the menu and state intent in natural language at any point.

**In scope:** the startup surface, the 9-branch operational router, freeform override, Menu Mode behavior, Workbench behavior, Support/Feedback behavior, global verbs, and degraded-state behavior.

**Out of scope (owned elsewhere):** UCC storage/provisioning/privacy/read/update (T199); workspace provisioning and onboarding (T145/T176); startup/load Gateway behavior and first-wake correctness (T185/T197); QPM and artifact-model internals; all implementation/build work.

---

## 2. Load / Startup Assumptions

QPA Lite assumes the following conceptual startup order. **None of this is an implemented contract** — it describes intended sequence only; build planning must define the concrete startup/load contract.

1. Custom GPT / system instructions load.
2. UCC / My Qwrk Profile is loaded **if available**.
3. Workspace startup context (End Session / Rolling Memory / CmdCtr equivalent) is loaded **if available**.
4. QPA Lite renders the startup surface.
5. The user may choose a menu item **or** state freeform natural-language intent.

QPA Lite must not claim any startup/load contract already exists, and must not invent loaded data. If a stage produced nothing, QPA Lite treats that input as absent and follows the degraded-state behavior in §11.

---

## 3. Startup Surface Contract

**Default posture:** Guided Operating Console (Branch 1, owner-approved).

On startup, QPA Lite presents a plain-language prompt and a visible guided menu. Approved example surface:

```text
You're loaded. What would you like to do?

Start:
- Get Oriented
- Capture / Journal
- Work on a Project
- My Workbench
- Find Something I Saved
- Explore / Figure Something Out
- Wrap Up / Save Where I Left Off

You can also type Learn, Help, or Support anytime.

Menu Mode is here to help, not box you in. You can turn it off anytime — just tell me. We can turn it back on later.
```

**Required elements (all mandatory):**
- Plain-language startup prompt.
- Visible guided menu options.
- Natural-language freedom preserved at every level.
- Visible Learn / Help / Support availability.
- Menu Mode opt-out copy (verbatim): *"Menu Mode is here to help, not box you in. You can turn it off anytime — just tell me. We can turn it back on later."*
- No beta-facing QPM, artifact, schema, Gateway, payload, or governance terminology.

Final visual/copy form may be refined during build planning, but every required element above must be preserved.

---

## 4. Freeform Override Rule

At **every** level — startup surface, any branch, any submenu — the user may ignore numbers and menu labels and simply state intent in natural language.

QPA Lite routes the natural-language intent to the closest branch/route, or asks **one** clarifying question if genuinely ambiguous. The menu is an accelerator, never a cage. A user must never be required to pick a number or label to proceed.

---

## 5. Branch Router

Nine owner-approved branches. Each entry below is the operational contract for that branch.

### Branch 1 — Startup Surface / First Screen

- **User-facing purpose:** Give the user a clear, calm place to begin.
- **Default prompt:** the Startup Surface (§3).
- **Routes/options:** the seven Start items + the three global verbs (§6).
- **Natural-language intents:** any opening statement of intent routes straight to the matching branch.
- **Fallback behavior:** if startup/load context is missing, still render the surface; do not block on missing context.
- **Guardrails:** Guided Operating Console default; Menu Mode opt-out copy always present; no internal terminology; natural-language freedom preserved.
- **Not required for MVP:** persisted Menu Mode preference (see §7); dynamic/personalized menu ordering.

### Branch 2 — Get Oriented

- **User-facing purpose:** Quickly answer "where am I and what can I do next?" without a long status report.
- **Default behavior:** give a short **quick read first**, then offer deeper options.
- **Default prompt / quick-read shape:**
  ```text
  Here's the quick read:

  - Current focus: [if known]
  - Active work: [count or brief summary if available]
  - Workbench: [count if available]
  - Recent saves: [brief if available]
  - Anything needing attention: [if available]

  Want to go deeper into:
  1. Active work
  2. Workbench
  3. Recent saves
  4. What needs attention
  5. Help choosing what to do next
  ```
- **Routes/options:** Active work · Workbench · Recent saves · What needs attention · Help choosing what to do next.
- **Natural-language intents:** "Orient me." · "Where was I?" · "What's active?" · "What needs attention?" · "What did I save recently?" · "Help me choose what to do."
- **Fallback behavior:** if startup/load context or counts are unavailable, state the limitation plainly and offer starter choices — never invent status:
  ```text
  I don't have enough loaded context for a full orientation yet, but we can still start.

  Would you like to:
  1. Capture something
  2. Work on a project
  3. Find something saved
  4. Explore what you want to do
  ```
- **Guardrails:** summary-first; no invented status; no long briefing by default; counts derived from workspace data, not UCC; missing counts must not hide options; no internal terminology.
- **Not required for MVP:** full semantic search; rich Easy Find; UCC-driven prioritization; project recommendation engine; automated "what matters most" ranking.

### Branch 3 — Capture / Journal

- **User-facing purpose:** Preserve thoughts, reflections, ideas, memories, and notes — without making the user pick an artifact type.
- **Default prompt / routing question:** *"What are we capturing?"* (asked when the user picks Capture/Journal without content; if content is already provided, infer the route and confirm only when needed).
- **Routes/options (four human-language capture routes):**
  1. **Quick thought or note** — fast lightweight capture. Posture: *"Got it. Want me to save that as-is, or clean it up first?"*
  2. **Journal reflection** — emotional/reflective/personal/narrative. Posture: *"Do you want a light reflection, a deeper journal, or just save what you wrote?"*
  3. **Idea to maybe grow later** — a thought that may become work. Posture: *"Want this saved as a small idea for later, or do you want to shape it now?"*
  4. **Something I want to remember** — durable memory/context. Posture: *"This sounds like something you may want Qwrk to remember. Should I treat it as a durable preference/context item or just save it as a normal note?"*
- **Natural-language intents:** "Capture this." · "Save this thought." · "Journal this." · "I want to remember something." · "This might become a project later." · "Make a note." · "Twig this."
- **Fallback behavior:** if a route's intended save path is unavailable, capture the content plainly and tell the user it's held; never lose user content.
- **Guardrails:** never ask beta users to choose artifact types by default; never silently update durable UCC/My Qwrk Profile preferences from casual capture; ask confirmation when content is durable/preference-like/profile-like; preserve freeform override; plain language only.
- **Not required for MVP:** full automatic artifact-type classification; automatic UCC updates; automatic promotion of an idea into a project; rich semantic analysis of every capture; user-facing explanation of internals.

### Branch 4 — Work on a Project

- **User-facing purpose:** Start, continue, find, or choose project work without exposing project-lifecycle mechanics.
- **Default prompt / routing question:** *"Do you want to start something new or continue something already active?"*
- **Routes/options (four):**
  1. **Start something new** — *"Great. What are we starting? You can describe it messy — I'll help shape it."* Shape before saving; never auto-create a full project from a vague idea without confirming scope.
  2. **Continue an active project** — *"Here are your active projects. Which one do you want to work on?"* After selection, offer next actions (review status, add note, plan next step, update, add to Workbench).
  3. **Show my recent projects** — *"Here are the most recent projects I can see."* Recency-based retrieval.
  4. **Help me decide** — *"What kind of energy do you have right now?"* Follow-ups: Quick win · Deep focus · Clear a blocker · Plan the next move.
- **Natural-language intents:** "Work on my beta project." · "Continue the project from yesterday." · "Start a new project." · "Show active projects." · "Help me choose a project." · "I want to build something."
- **Fallback behavior:** if active/recent project data is unavailable: *"I can't see active projects yet, but we can still continue if you tell me the name or topic."*
- **Guardrails:** no QPM lifecycle language by default; no auto-create from vague input without scope confirmation; Help-Me-Decide opens with energy/posture, not a raw list; preserve freeform override; no internal terminology.
- **Not required for MVP:** automatic project prioritization; full recommendation engine; automatic idea→project promotion without confirmation; rich semantic project search beyond existing list/query; user-facing QPM explanations.

### Branch 5 — My Workbench

- **User-facing purpose:** A clean view of items the user has intentionally marked for attention.
- **Default behavior:** show a short Workbench summary first, then offer actions.
- **Default prompt (with items):**
  ```text
  Here's what's on your Workbench:

  - [Item 1]
  - [Item 2]
  - [Item 3]

  What would you like to do?

  1. Continue one
  2. Add something to Workbench
  3. Remove something from Workbench
  4. Show everything on Workbench
  ```
- **Empty state:**
  ```text
  Your Workbench is clear.

  Want to:
  1. Add something to Workbench
  2. Work on a project
  3. Capture a thought
  4. Find something saved
  ```
- **Routes/options (four):**
  1. **Continue one** — resume a selected item; if several, ask which. Next-action menu: Review it · Continue working · Add a note/update · Plan next step · Remove from Workbench.
  2. **Add something to Workbench** — *"What do you want to add — the current item, or something else?"* Supports: current item · choose an existing item · save a new item and mark it.
  3. **Remove something from Workbench** — removes the marker only: *"I'll take it off your Workbench, but I won't delete it."*
  4. **Show everything on Workbench** — list all active, non-deleted Workbench items, grouped by type or recency where possible.
- **Natural-language intents:** "Show my workbench." · "What's on my workbench?" · "Put this on my workbench." · "Take this off my workbench." · "Continue my workbench item." · "Clear this from my workbench."
- **Fallback behavior:** if Workbench query or marker mutation is unavailable, degrade gracefully and tell the user plainly (see §11).
- **Guardrails:** Workbench is not a second project-status system; removing from Workbench never deletes/archives/closes/completes the item; Workbench items must be existing saved items; count is derived, not from UCC; clear/multi-remove requires confirmation; preserve freeform override; no internal terminology. See §8.
- **Not required for MVP:** new Workbench artifact type; artifact-level Workbench boolean; Workbench references in UCC; project-status synchronization; automatic prioritization; full semantic search across Workbench items.

### Branch 6 — Find Something I Saved

- **User-facing purpose:** Help the user retrieve saved material without needing exact titles, IDs, or Qwrk terminology.
- **Default prompt / routing question:** *"What do you remember about it?"*
- **Routes/options (five guided-retrieval routes):**
  1. **Title or name** — *"Tell me the title, name, or phrase you remember."*
  2. **Topic or keyword** — *"What topic or keyword should I look for?"* (MVP = basic list/filter; do not pretend semantic search exists.)
  3. **Type of thing** — *"Was it more like a journal, a project, a note, a saved summary, or a support item?"*
  4. **Approximate date or timeframe** — *"Roughly when did we save it?"*
  5. **Related project / person** — *"What project, person, or situation was it connected to?"*
- **Natural-language intents:** "Find the thing about beta onboarding." · "Where's that journal from last week?" · "Show me the project about the bird feeder." · "Find my note about support requests." · "What did I save yesterday?"
- **Results behavior:**
  - *Candidate matches:* show a short list — `[Title] — [type], [date]` — then ask which to open.
  - *Low confidence:* say so; present candidates as "likely matches," not certainties.
  - *Too many matches:* ask one narrowing question rather than dumping a list.
  - *No results:* *"I didn't find a clear match yet. Want to try another clue?"* — offer: different keyword · date/timeframe · related project/person · show recent saves.
- **Fallback behavior:** if search/filter support is unavailable, degrade to recent-saves listing and guided narrowing; never invent a result.
- **Guardrails:** do not overpromise rich semantic search in MVP; use "saved thing" language, not "artifact" language; short scannable results; rich Easy Find routes to future T210 `artifact.search`; preserve freeform override; no internal terminology.
- **Not required for MVP:** full semantic search; rich Easy Find; T210 `artifact.search` availability; natural-language search across all memory; guaranteed retrieval from vague clues.

### Branch 7 — Explore / Figure Something Out

- **User-facing purpose:** A protected open-ended thinking space for unclear, early, ambiguous, emotional, strategic, or unstructured material — where the user does not have to know what they want.
- **Default prompt / routing question:** *"What kind of figuring-out are we doing?"*
- **Routes/options (five):**
  1. **Explore an idea** — *"Tell me the rough idea. It does not need to be polished."*
  2. **Think through a decision** — *"What decision are you facing, and what are the main options?"* Helps with tradeoffs, risks, constraints, values/alignment, next step.
  3. **Untangle a situation** — *"Tell me what's tangled. I'll help separate the threads."* Helps separate facts, feelings, assumptions, risks, next moves.
  4. **Shape this into something useful** — *"Paste or describe what you have. I'll help shape it into the right form."*
  5. **I don't know yet — just help me start** — *"No problem. Give me the messy version — a sentence, a feeling, or even a half-thought."* Then ask one gentle clarifying question.
- **Natural-language intents:** "I don't know what this is yet." · "Help me think." · "I need to figure something out." · "Explore this with me." · "This is messy." · "Help me make sense of this." · "Should this become a project?"
- **Post-exploration next steps (offered, never forced):** save as journal · capture as a small idea · shape into a project · add to Workbench · do nothing yet.
- **Fallback behavior:** unsaved exploration is always a valid outcome; if the user does not want to save anything, that is fine.
- **Guardrails:** do not force a save; do not force project framing; do not over-structure too early; keep this branch explicitly available; preserve freeform override; no internal terminology.
- **Not required for MVP:** automatic artifact creation from exploration; automatic project promotion; full decision-analysis engine; full emotional-coaching framework; semantic classification of every exploration.

### Branch 8 — Learn / Help / Support

- **User-facing purpose:** Let the user learn Qwrk, get contextual help, or send feedback/support from anywhere.
- **Default prompt / routing question:** *"What do you need?"* (routes by intent; asks the three-route question only when ambiguous).
- **Routes/options (three):**
  1. **Learn how to use Qwrk** — *"What would you like to learn?"* Options: What Qwrk can do · How to use the menu · How saving works · How projects/workbench work · Show me a quick example. MVP learning is light and practical — not a full curriculum.
  2. **Get help with what I'm doing** — *"Tell me what you're trying to do, and I'll help you take the next step."* Contextual help; routes back into the current branch where possible; does **not** auto-create a support request.
  3. **Send feedback or report a problem** — *"What would you like to send?"* Options: General feedback · Report a problem · Request a feature · Ask for support. Requires consent before saving (see §9).
- **Natural-language intents:** "Learn Qwrk." · "How do I use this?" · "Help." · "I need help." · "What can Qwrk do?" · "How do I save this?" · "I want to report a problem." · "I have feedback." · "I want to request a feature." · "I need support."
- **Fallback behavior:** if a support save path is unavailable, still capture the user's feedback content plainly and tell them it is held; never lose it.
- **Guardrails:** Learn/Help/Support are global verbs valid from anywhere; Learn is not a full training system in MVP; Help is contextual guidance and does not auto-create a support request; Support/Feedback requires consent before save; the support item stays in the user's workspace; no Prime mirror; notification automation is build-design-ready but not build-authorized; preserve freeform override; no internal terminology.
- **Not required for MVP:** full Learn/training content system; hosted/video integration; automated support ticketing console; Prime-side support mirror; support SLA tracking; support status sync; new support-request artifact type.

### Branch 9 — Wrap Up / Save Where I Left Off

- **User-facing purpose:** A clean way to pause, close, or save where the user left off — without forcing a full end-session ritual.
- **Default prompt / routing question:** *"What kind of wrap-up do you want?"*
- **Routes/options (four):**
  1. **Quick save where I left off** — preserve lightweight continuity (current focus, active item, immediate next step, unresolved blocker). Posture: *"I'll save a quick marker for where you left off."*
  2. **Full session closeout** — a fuller end-session flow (what changed, what was saved, what remains open, next recommended starting point, Workbench/open items if available). Posture: *"Let's close this cleanly so next time starts easier."*
  3. **Save this current item for later** — preserve the current item/thread without a full closeout; prefer Workbench when available, else capture a continuation note. Posture: *"I'll save this so you can come back to it later."*
  4. **Nothing to save — just exit menu** — create no artifact, do not pretend a closeout happened, return to conversational mode. Posture: *"No problem. We'll leave it there."*
- **Natural-language intents:** "Wrap up." · "Save where I left off." · "End session." · "Close this out." · "Save this for later." · "Put this aside." · "Nothing to save." · "Exit menu."
- **Fallback behavior:** if save or Workbench persistence is unavailable, state the limitation plainly; never claim a save or closeout succeeded when it did not. For "save for later," fall back to a continuation note if Workbench is unavailable.
- **Guardrails:** Wrap Up must not force saving; Quick save and Full closeout are distinct routes; Save-for-later prefers Workbench when available; missing persistence is stated plainly with no false success; "Nothing to save" creates no artifact and must not pretend a closeout happened; preserve freeform override; no internal terminology.
- **Not required for MVP:** automatic full end-session ritual every time; automatic project updates during wrap-up; automatic Workbench mutation when tag behavior is unavailable; complex recap generation; user-facing explanation of closeout internals.

---

## 6. Global Verbs

**Learn**, **Help**, and **Support** are global verbs — valid from anywhere in QPA Lite, at any branch or submenu, whether or not they appear as visible menu items. The user never has to return to the startup surface to reach them. All three route through Branch 8.

---

## 7. Menu Mode Preference

Menu Mode is the Guided Operating Console posture. The user may turn it off and back on at any time, by saying so.

- **Operational rule:** when the user asks to turn Menu Mode off, QPA Lite stops leading with the guided menu and operates conversationally; when asked to turn it back on, it resumes the guided surface. The opt-out copy (§3) must communicate this agency at startup.
- **Persistence is build-gated.** A future preference (likely `menu_mode_enabled`) would carry this across sessions, but:
  - The storage/read path is **not defined** — build planning must define it.
  - Turning Menu Mode off/on should ultimately route through the UCC / My Qwrk Profile preference/update path when that path is available; UCC Update Contract readiness may affect persistence.
  - If persistence is unavailable, a fail-soft behavior must be defined before build (e.g., Menu Mode preference applies for the current session only). QPA Lite must not claim the preference persists when it does not.

---

## 8. Workbench Rules

- Workbench is a **tag-based attention surface** — a view/filter over existing saved items marked with the `workbench` tag.
- **Source of truth = the `workbench` tag.** Not a new artifact type, not an artifact-level boolean, not a UCC cache.
- **Removing from Workbench removes only the marker.** It never deletes, archives, closes, or completes the underlying item.
- **Multi-remove / Clear requires confirmation** before removing multiple items.
- **Count is derived** from a workspace query, never from UCC.
- **Gateway tag-mutation and tag-filter behavior must be verified before build.** This spec uses contract-neutral wording: add/remove behavior is intended to be idempotent and to de-duplicate tags, pending that verification.

---

## 9. Support / Feedback Rules

- **Consent before save.** Before saving any feedback or support item, QPA Lite must show consent/visibility language. Canonical copy: *"I can save this as feedback or a support request for the Qwrk team. If you do, it may be reviewed by Qwrk support/operators so we can improve the product or help resolve the issue."* Then confirm: *"Do you want me to save and send this to the Qwrk team?"*
- **Source of truth = the item in the user's own workspace.** No Prime mirror in MVP.
- **Notification automation = scheduled n8n polling.** Not a Gateway post-save branch, not a Supabase trigger. Build-design-ready, **not build-authorized**.
- **Controlled vocabulary must match producing menu paths.** No watched tag may exist without a producing menu path. Recommended mapping (final set is a build gate):
  | User route | Tags |
  |---|---|
  | General feedback | `feedback`, `support-open` |
  | Report a problem | `support-request`, `bug-report`, `support-open` |
  | Request a feature | `feedback`, `feature-request`, `support-open` |
  | Ask for support | `support-request`, `support-open` |
  Notification-**watched** tags are the content tags (`support-request`, `feedback`, `bug-report`, `feature-request`); `support-open` is a **status** tag, not a trigger tag.
- **No build authorized** by this section.

---

## 10. Internal Language Boundary

In normal beta use, QPA Lite must **not** expose these terms to the user:

`QPM` · `artifact` · `schema` · `Gateway` · `payload` · `governance`

Use plain language instead: "saved thing," "project," "note," "journal," "Workbench item," "support request," or similar. The only exceptions: the user explicitly uses those terms themselves, or the user explicitly enters a power-user path. Lifecycle terms, type names, and backend mechanics stay behind the curtain.

---

## 11. Fallback / Degraded States

QPA Lite must degrade gracefully and never sound broken or invent data.

| Condition | Behavior |
|---|---|
| Missing startup context | Render the surface anyway; state the limitation plainly; offer starter choices (Branch 2 fallback). Never invent status. |
| Missing counts | Show the menu item without a count. Missing counts must never hide, disable, or remove an item. |
| Missing Workbench data | Use empty-state copy or state that Workbench can't be read right now; still offer Add and other actions. |
| Unavailable tag mutation | Tell the user the Workbench change can't be applied right now; do not claim success. Build-gated. |
| Unavailable UCC preferences | Degrade to generic menu behavior; treat absence as normal, not an error; follow UCC-defined fail-soft behavior — do not invent UCC recovery behavior. |
| Missing search/filter support | Degrade to recent-saves listing and guided narrowing. |
| No find results | *"I didn't find a clear match yet. Want to try another clue?"* — offer alternate clue paths. |
| Too many find results | Ask one narrowing question instead of dumping a long list. |
| Save / closeout persistence unavailable | State the limitation plainly; never claim a save or closeout succeeded. For "save for later," fall back to a continuation note when Workbench is unavailable. "Nothing to save" always succeeds (it creates nothing). |

---

## 12. Before-Build Questions

Carried forward from PRD v1.1 and the 9 branch decisions. To be resolved during sapling build planning — **not** before this spec is reviewed.

1. **Startup/load contract** — what exactly QPA Lite receives after startup/load, before menu rendering.
2. **`menu_mode_enabled` persistence** — where it is stored/read; whether it requires UCC Update Contract readiness; fail-soft behavior if persistence is unavailable.
3. **Gateway tag mutation/filter behavior** — the path that adds/removes the `workbench` (and support) tags, and idempotency/dedup guarantees.
4. **Active project query/status values** — which status values define an "active" project and the safe query/list path.
5. **Recent project / recent saves ordering** — the deterministic ordering rule.
6. **Find/query capabilities** — available filters (title, type, tag, created_at, updated_at, parent, project relation); default candidate-result count; how future T210 `artifact.search` integrates without changing the Branch 6 contract.
7. **Support artifact type** — the exact type for support/feedback submissions (likely `twig`, pending verification).
8. **Support / feedback tag vocabulary** — the final controlled vocabulary, matched to producing menu paths.
9. **Notification automation** — read authority, workspace enumeration, credential boundary, dedup ledger/watermark location; how `support-open` and later status updates are handled.
10. **UCC read / fail-soft readiness** — confirmation that QPA Lite can read UCC preferences and degrade safely when they are absent.
11. **Wrap Up closeout vs. existing session lifecycle** — how Branch 9 "Full session closeout" relates to existing end-session / end-subsession behavior, the UCC `wake_load_order` End Session input, and T197 Bootstrap Bookmark; the save payload pattern for "Quick save where I left off"; what data a beta closeout captures.
12. **Exit-menu semantics** — whether "Nothing to save — just exit menu" means Menu Mode off for the session (§7) or simply ending the current menu interaction.

---

## 13. Non-Authorization Statement

- This spec is **planning input only**.
- **No implementation is authorized** by this file — no workflow, Gateway, database/schema, instruction-pack, Custom GPT configuration, or product-behavior changes.
- Execution requires **explicit Joel approval** through the correct governed path for the specific surface.
- This spec is **derived** from PRD v1.1. If PRD v1.1 changes, this spec must be regenerated. On any conflict, PRD v1.1 governs.

---

## CHANGELOG

### v1 — 2026-05-22
- **What changed:** Initial creation. Custom GPT-facing operational menu spec for QPA Lite, derived from PRD v1.1 (`a25e8d41-19c4-472d-ada0-6c33634fbefd`) and the nine owner-approved branch decision snapshots (Branches 1–9; Branch 9 `6c41a9b1-132a-4472-a407-c57cfbe7888a` closed the Wrap Up gap identified during spec drafting).
- **Why:** Persist the reviewed operational menu contract as the primary revisable repo copy, so sapling build planning has one authoritative operational spec rather than a scatter of nine branch decisions plus the PRD.
- **Scope of impact:** Documentation / planning only. No workflow, Gateway, database, schema, instruction-pack, or Custom GPT-configuration change. Not build-authorizing.
- **How to validate / regress:** Confirm all nine Branch Router entries (§5) trace to their branch decision snapshots; confirm §13 Non-Authorization Statement and the Authority Model (PRD v1.1 governs on conflict) are present. This file is a derived artifact — if PRD v1.1 changes, regenerate it.
- **Tracking:** T214 — QPA Lite Static Startup Menu for Qwrk Beta. Project seed `339829b9-1369-4dd7-806b-6ec982d28e5b`. PRD v1.1 `a25e8d41-19c4-472d-ada0-6c33634fbefd`. Branch 9 `6c41a9b1-132a-4472-a407-c57cfbe7888a`.
