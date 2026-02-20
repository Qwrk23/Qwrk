# Active Context Instructions

**Purpose:** Enable seamless continuation of ongoing work (e.g., reading journals, multi-session projects) without querying prior entries.

---

## Section A2 of Rolling Memory

Active Contexts are stored in Section A2 of Rolling Memory. Each context includes:

| Field | Description |
|-------|-------------|
| `context_type` | Category (e.g., `book`, `course`, `project`) |
| `context_ref` | Unique identifier for this engagement |
| `context_status` | `active` or `finished` |
| `latest_part` | Most recent part number |
| `titling_convention` | Pattern with `{n}` placeholder |
| Required tags | Tags to apply to continuation entries |

---

## At Session Start

Check Section A2 for active contexts. If present, note the fields above for use during session.

---

## On Continuation

When Joel requests continuation of an active context (e.g., "Let's continue Red October"):

1. **Compute next part** — `latest_part + 1`
2. **Apply titling convention** — Substitute `{n}` with next part number
3. **Apply tags** — Use tags from active context
4. **Do NOT query prior journals** — Context metadata is authoritative

### Example

**Active Context:**
- `latest_part`: 2
- `titling_convention`: `Reading Journal - Red October - Part {n}: {subtitle}`

**Next entry title:**
> Reading Journal - Red October - Part 3: {Joel provides subtitle}

---

## After Saving a Continuation Entry

After the continuation journal is saved:

1. **Inform Joel** — "Active Context should be advanced to Part {n}."
2. **If Joel requests**, generate a NEW snapshot:
   - Same `context_ref`
   - Incremented `latest_part`
   - Created via `artifact.save` with `artifact_type: snapshot`
   - Content in `extension.payload`
   - Tags: `for-q`, `active-context`, `active-{type}`, plus context-specific tags

### Example Advance Payload

```json
{
  "gw_action": "artifact.save",
  "artifact_type": "snapshot",
  "title": "Active Book Context — The Hunt for Red October",
  "tags": ["for-q", "active-context", "active-book", "book:red-october"],
  "payload": {
    "context_type": "book",
    "context_ref": "red-october-2026",
    "context_status": "active",
    "latest_part": 3,
    "titling_convention": "Reading Journal - Red October - Part {n}: {subtitle}",
    "book_title": "The Hunt for Red October",
    "author": "Tom Clancy",
    "first_journal_id": "..."
  }
}
```

**Critical:** Never mutate existing snapshots. Always create NEW snapshot with updated values.

---

## On Context Close

When Joel finishes an active context (e.g., "Finished Red October"):

1. Create a NEW snapshot with `context_status: finished`
2. All other fields remain the same
3. Context becomes ineligible for Section A2 on next rolling memory regeneration

### Example Close Payload

```json
{
  "gw_action": "artifact.save",
  "artifact_type": "snapshot",
  "title": "Active Book Context — The Hunt for Red October (Finished)",
  "tags": ["for-q", "active-context", "active-book", "book:red-october"],
  "payload": {
    "context_type": "book",
    "context_ref": "red-october-2026",
    "context_status": "finished",
    "latest_part": 5,
    "...": "same fields as last active snapshot"
  }
}
```

---

## Key Rules

1. **Snapshots are immutable** — Never update; always create new
2. **Latest wins** — Most recent snapshot by `created_at` is authoritative
3. **No reactivation** — Once finished, a new engagement requires new `context_ref`
4. **Context is truth** — Do not query prior entries; context provides all needed metadata

---

## CHANGELOG

### 2026-02-05
- Initial version extracted from system instructions for character budget
