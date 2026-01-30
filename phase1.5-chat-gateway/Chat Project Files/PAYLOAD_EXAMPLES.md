# Qwrk Telegram Payload Examples

Complete examples of each artifact type you can save through Telegram.

**CRITICAL FORMAT RULE:** All content must be plain text, single paragraph. NO markdown (headers, bullets, bold, code blocks, emojis). Use periods and colons for structure. See `TELEGRAM_PAYLOAD_RULES.md` for details.

---

## Journal Entry

**Use for:** Conversations, thoughts, meeting notes, learnings, daily reflections

**Simple:**
```
Save journal titled "Meeting Notes - Product Review": We discussed the Q1 roadmap and agreed to prioritize the auth gate feature. Key decisions: 1) Ship MVP by Feb 15, 2) Use Supabase Auth, 3) Joel owns implementation.
```

**Detailed (single paragraph - REQUIRED FORMAT):**
```
Save journal titled "Architecture Discussion - Gateway Patterns": Today we explored different approaches to the Gateway architecture. Key Points: Single webhook entry point normalizes all requests, Gatekeeper validates permissions before routing, Sub-workflows handle type-specific logic. Decisions Made: Use n8n for orchestration layer, Supabase for persistence, Basic auth for MVP upgrade to JWT later. Next Steps: Implement artifact.promote workflow, Add instruction_pack support, Test 5K+ payload handling.
```

**IMPORTANT:** Content must be plain text, single paragraph. No markdown headers, bullets, or newlines. Use colons and commas for structure.

---

## Project

**Use for:** Initiatives, features, work items, goals

**KNOWN LIMITATION (BUG-012):** Project artifacts do NOT persist content or summary fields. Only title and lifecycle are saved. Use the companion journal pattern below for projects with rich content.

**Simple (no content needed):**
```
Save project titled "Auth Gate MVP"
```

**Seed with Rich Content (Two-Step Pattern - REQUIRED):**

Step 1 — Create the project:
```
Save project titled "Seed — Introduce RAG Capabilities"
```

Step 2 — Save content as companion journal:
```
Save journal titled "Seed Content - Introduce RAG Capabilities": Context: Today ChatGPT is the primary conversation surface. We will need RAG once the n8n agent becomes the primary planner because buffer-window memory wont scale. Goal: Add RAG as a governed long-term memory layer. Planning posture: Start slow with baby steps, prefer read-only retrieval first. Initial scope: Define what RAG is for and not for, define minimal retrieval unit, define retrieval triggers, define safety boundaries. Constraints: RAG must respect workspace scoping, retrieval must be selective, system-of-record remains Supabase artifacts.
```

**Why two steps:** Projects currently don't persist content (BUG-012). The project tracks lifecycle (seed → sapling → tree); the companion journal holds the actual content.

---

## Snapshot

**Use for:** Decisions, milestones, governance docs, point-in-time records

**Decision Record (plain text format):**
```
Save snapshot titled "Decision - Auth Provider Selection": After evaluating Auth0, Clerk, and Supabase Auth, we selected Supabase Auth. Reasons: (1) Already using Supabase for database, (2) Built-in RLS integration, (3) Cost-effective for MVP scale, (4) Can migrate to dedicated provider later if needed. This decision is final for Phase 1.
```

**Milestone (plain text format):**
```
Save snapshot titled "Milestone - Gateway v1 Complete": Gateway v1 is now feature-complete with all 5 actions implemented and tested. Actions: artifact.list with pagination, artifact.query with hydration, artifact.save for all 5 types, artifact.update with mutability enforced, artifact.promote for lifecycle transitions. All KGB proofs documented. Ready for Phase 2.
```

---

## Restart Prompt

**Use for:** Session handoffs, "where I left off", context for resuming work

**Session Handoff (plain text format):**
```
Save restart titled "Resume - Auth Gate Implementation": Current State: Database schema complete, RLS policies drafted but not tested, login flow UI 80% complete. Blocked On: Waiting for design review of error states, need to decide session duration. Next Steps: (1) Test RLS policies with test users, (2) Implement logout flow, (3) Add remember me checkbox. Key Files: src/auth/login.tsx, supabase/policies.sql.
```

**Context Capture (plain text format):**
```
Save restart titled "Resume - Bug Investigation BUG-012": Problem: Users reporting intermittent 403 errors on artifact.save. Investigation So Far: Reproduced locally 2/10 attempts, appears related to session expiry, Gateway logs show valid auth header. Hypothesis: Race condition between token refresh and request. Next Steps: (1) Add request timing logs, (2) Check token expiry buffer, (3) Test with longer sessions.
```

---

## Instruction Pack

**Use for:** Custom rules, shortcuts, automation triggers

**Simple Rule:**
```
Save instruction pack titled "Quick Save Shortcut": When user says qs followed by content, save it as a journal with auto-generated title based on the first line of content.
```

**Domain Rules (plain text format):**
```
Save instruction pack titled "Code Review Standards": When reviewing code artifacts apply these checks: (1) Check for security vulnerabilities per OWASP top 10, (2) Verify error handling is present, (3) Ensure logging for debugging, (4) Flag any hardcoded credentials, (5) Note missing tests. Format findings as a checklist with pass/fail status.
```

---

## Retrieval Examples

**List artifacts:**
```
list journals
list projects
list snapshots
list restarts
list instruction packs
```

**Get specific artifact:**
```
retrieve 1
```
(Gets first item from most recent list)

```
retrieve Auth Gate MVP
```
(Finds by title - will list first, then query)

---

## Lifecycle Promotion

**Promote project to next stage:**
```
promote Auth Gate MVP to sapling
```

**Valid transitions:**
- seed → sapling (idea validated, work starting)
- sapling → tree (core functionality complete)
- tree → oak (stable, production-ready)
- oak → archive (completed, historical)

**With reason:**
```
promote Auth Gate MVP to tree
```
(AI will ask for reason or use "User requested")
