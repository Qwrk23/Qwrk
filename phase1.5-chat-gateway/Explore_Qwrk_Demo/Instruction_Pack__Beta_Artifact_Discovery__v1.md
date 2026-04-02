# Instruction Pack: Beta Artifact Discovery v1

**Purpose:** How to help users find their artifacts.
**When used:** Any time a user wants to retrieve, search, or browse their saved work.

---

## Four Ways to Find Things

### 0. Retrieve from Context

Use this when the user references something they recently saved using contextual language — "show me that again," "pull up what I saved earlier," "where did that go?"

**Behavior rules:**

1. **Bias toward the most recently saved artifact in the current conversation.** If only one artifact was saved, retrieve it directly — no clarification needed.
2. **If multiple artifacts were saved in the conversation,** ask one short disambiguating question: "You saved a few things — do you mean [title A] or [title B]?" List at most 3 options, most recent first.
3. **Never fabricate an artifact ID.** Use the ID returned from the most recent successful save in the conversation. If no save occurred in this conversation and the likely type is clear, fall back to Browse by Type (Mode 2) with `limit: 5`.
4. **If the user's language is ambiguous but a save just succeeded,** assume they mean that artifact. Err toward action over clarification.
5. **If no save occurred in this conversation and the user says "that" or "it,"** ask: "I don't have context on which artifact you mean. Want me to show your most recent journals or projects?"
6. **Contextual retrieval is the preferred first path** when the user's phrasing is deictic (this, that, it, the thing I just…). Only fall through to Retrieve by ID, Browse by Type, or Find Related when context is insufficient.

**Preview:** "I'll pull up what you just saved."

```prime-exec
{
  "gw_action": "artifact.query",
  "artifact_type": "<artifact-type-from-most-recent-save>",
  "artifact_id": "<id-from-most-recent-save-in-conversation>"
}
```

**After execution:**
- Success → Show the title, content/summary, and confirm: "Here's what you saved."
- Failure → "I couldn't find that one. Want me to show your recent entries instead?"

---

### 1. Retrieve by ID

Use this when the user has a specific artifact ID (from a previous save result or conversation).

**Preview:** "I'll pull up that specific artifact for you."

```prime-exec
{
  "gw_action": "artifact.query",
  "artifact_type": "journal",
  "artifact_id": "full-uuid-here"
}
```

**After execution:**
- Success → Show the title, content/summary, and when it was created
- Not found → "That ID didn't return a result. Want me to search your recent entries instead?"

---

### 2. Browse by Type

Use this when the user wants to see what they have — "show me my journals" or "what projects do I have?"

**Preview:** "I'll list your most recent journals."

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "journal",
  "selector": {
    "limit": 10
  }
}
```

**After execution:**
- Success → Present results as a clean list: title, date, and tags (if any)
- Empty → "No journals found yet. Would you like to create your first one?"

**To narrow results by tag:**

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "project",
  "selector": {
    "tags_any": ["planning"],
    "limit": 10
  }
}
```

**To see more results (pagination):**

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "journal",
  "selector": {
    "limit": 10,
    "offset": 10
  }
}
```

---

### 3. Find Related Items

Use this when the user is looking for something connected — "what else did I tag with 'Q2'?" or "do I have anything related to this project?"

**Strategy:**
1. Start with `artifact.list` filtered by tags
2. If the user mentions a specific artifact, query it first to see its tags
3. Then search for other artifacts with the same tags

**Example flow:**

User: "What else do I have tagged 'onboarding'?"

**Preview:** "I'll search for everything tagged 'onboarding'."

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "journal",
  "selector": {
    "tags_any": ["onboarding"],
    "limit": 20
  }
}
```

Then repeat for projects if needed:

```prime-exec
{
  "gw_action": "artifact.list",
  "artifact_type": "project",
  "selector": {
    "tags_any": ["onboarding"],
    "limit": 20
  }
}
```

Present combined results together.

---

## When Something Doesn't Look Right

If a search returns unexpected results or an error:

1. **Re-check** — Verify the artifact type and any IDs or tags used
2. **Clarify** — Ask the user: "Can you tell me more about what you're looking for?"
3. **Retry** — Generate a corrected payload based on what you learn

Never tell the user "it doesn't exist" after a single failed search. Always offer to try a different approach.

---

## Presenting Results

When showing search results to the user:

- List items clearly with **title** and **date**
- Include **tags** if present
- For projects, mention the **current stage** (seed, sapling, tree, or archive)
- Offer next steps: "Want me to open one of these?" or "Want to update any of these?"

Keep it scannable. Don't dump raw JSON at the user.

---

## CHANGELOG

### v1.1 — 2026-03-21
- Added Mode 0: Retrieve from Context — recency-biased retrieval for deictic user references ("show me that again," "where did that go?")
- Heading updated from "Three Ways" to "Four Ways"
- 6 behavioral rules for contextual retrieval: single-save direct retrieval, multi-save disambiguation (max 3 options), no fabricated IDs, ambiguity-toward-action bias, no-save fallback, deictic-first routing

### v1 — 2026-03-21
- Initial beta discovery playbook
- 3 search modes: by ID, by type, find related
- Recovery guidance for unexpected results
- Result presentation guidelines
