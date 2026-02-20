# Qwrk Gateway Payload Examples

Complete examples of each artifact type you can save through the Gateway.

All execution uses JSON Gateway payloads. One payload per execution. Raw JSON only.

---

## Journal Entry

**Use for:** Conversations, thoughts, meeting notes, learnings, daily reflections

**Simple:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Meeting Notes - Product Review",
  "priority": 3,
  "tags": ["meeting", "product"],
  "extension": {
    "entry_text": "We discussed the Q1 roadmap and agreed to prioritize the auth gate feature. Key decisions: 1) Ship MVP by Feb 15, 2) Use Supabase Auth, 3) Joel owns implementation."
  }
}
```

**Detailed:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Architecture Discussion - Gateway Patterns",
  "priority": 3,
  "tags": ["architecture", "gateway"],
  "extension": {
    "entry_text": "Today we explored different approaches to the Gateway architecture. Key Points: Single webhook entry point normalizes all requests, Gatekeeper validates permissions before routing, Sub-workflows handle type-specific logic. Decisions Made: Use n8n for orchestration layer, Supabase for persistence, Basic auth for MVP upgrade to JWT later. Next Steps: Implement artifact.promote workflow, Add instruction_pack support, Test 5K+ payload handling."
  }
}
```

---

## Project

**Use for:** Initiatives, features, work items, goals

**Simple (seed):**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Seed - Auth Gate MVP",
  "priority": 3,
  "tags": ["seed", "auth"],
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

**With companion journal (Two-Step Pattern — REQUIRED for rich content):**

Step 1 — Create the project:
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "title": "Seed - Introduce RAG Capabilities",
  "priority": 3,
  "tags": ["seed", "rag"],
  "extension": {
    "lifecycle_stage": "seed"
  }
}
```

Step 2 — Save content as companion journal (after confirming Step 1 artifact_id):
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "journal",
  "title": "Seed Content - Introduce RAG Capabilities",
  "priority": 3,
  "tags": ["seed-content", "rag", "companion"],
  "extension": {
    "entry_text": "Context: Today ChatGPT is the primary conversation surface. We will need RAG once the n8n agent becomes the primary planner because buffer-window memory won't scale. Goal: Add RAG as a governed long-term memory layer. Planning posture: Start slow with baby steps, prefer read-only retrieval first. Initial scope: Define what RAG is for and not for, define minimal retrieval unit, define retrieval triggers, define safety boundaries. Constraints: RAG must respect workspace scoping, retrieval must be selective, system-of-record remains Supabase artifacts."
  }
}
```

**Why two steps:** Projects track lifecycle (seed -> sapling -> tree). The companion journal holds the actual content.

---

## Snapshot

**Use for:** Decisions, milestones, governance docs, point-in-time records

**Decision Record:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "title": "Decision - Auth Provider Selection",
  "priority": 3,
  "tags": ["decision", "infrastructure", "for-q"],
  "extension": {
    "payload": {
      "decision": "Selected Supabase Auth",
      "rationale": "Already using Supabase for database, built-in RLS integration, cost-effective for MVP scale, can migrate later",
      "scope": "Phase 1",
      "status": "final"
    }
  }
}
```

**Milestone:**
```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "snapshot",
  "title": "Milestone - Gateway v1 Complete",
  "priority": 3,
  "tags": ["milestone", "gateway", "for-q"],
  "extension": {
    "payload": {
      "context": "Gateway v1 feature-complete with all 5 actions",
      "actions_verified": ["artifact.list", "artifact.query", "artifact.save", "artifact.update", "artifact.promote"],
      "status": "Ready for Phase 2"
    }
  }
}
```

---

## Restart Prompt

**Use for:** Session handoffs, "where I left off", context for resuming work

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "restart",
  "title": "Resume - Auth Gate Implementation",
  "priority": 3,
  "tags": ["restart", "auth"],
  "extension": {
    "payload": {
      "current_state": "Database schema complete, RLS policies drafted but not tested, login flow UI 80% complete",
      "blocked_on": "Waiting for design review of error states, need to decide session duration",
      "next_steps": ["Test RLS policies with test users", "Implement logout flow", "Add remember me checkbox"],
      "key_files": ["src/auth/login.tsx", "supabase/policies.sql"]
    }
  }
}
```

---

## Instruction Pack

**Use for:** Custom rules, shortcuts, automation triggers

```json
{
  "gw_action": "artifact.save",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "instruction_pack",
  "title": "Code Review Standards",
  "priority": 3,
  "tags": ["instruction", "code-review"],
  "extension": {
    "scope": "global",
    "active": true,
    "priority": 3,
    "pack_format": "text",
    "payload": {
      "instructions": "When reviewing code artifacts apply these checks: (1) Check for security vulnerabilities per OWASP top 10, (2) Verify error handling is present, (3) Ensure logging for debugging, (4) Flag any hardcoded credentials, (5) Note missing tests."
    }
  }
}
```

---

## List Examples

**List journals:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","selector":{"limit":10}}
```

**List projects:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":10}}
```

**List snapshots with tag filter:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"snapshot","selector":{"limit":10,"filters":{"tags_any":["for-q"]}}}
```

---

## Lifecycle Promotion

**Promote project to next stage:**
```json
{
  "gw_action": "artifact.promote",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "artifact_type": "project",
  "artifact_id": "[UUID from prior query]",
  "transition": "seed_to_sapling",
  "reason": "Development started"
}
```

**Valid transitions:**
- `seed_to_sapling` — idea validated, work starting
- `sapling_to_tree` — core functionality complete
- `tree_to_archive` — completed, historical

---

*CHANGELOG: v2 (2026-02-18): Converted all examples from Telegram NL format to JSON Gateway payloads. Removed plain-text/single-paragraph constraints. Added `priority` field to all examples. Added list, promote, and instruction_pack examples. Removed "oak" stage (not in canonical lifecycle). Previous version: Telegram-format examples (archived).*
