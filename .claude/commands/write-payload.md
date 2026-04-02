Generate a Gateway write payload for the user to execute via Chrome Extension.

Source: CLAUDE.md §2.5, §6
Authoritative contract: phase1.5-chat-gateway/Chat Project Files/Qwrk_Gateway_Payload_Canonical_v5.md
Last reconciled against Canonical: 2026-03-25 (promote fields corrected — reason Required, transition values aligned)

## Context

CC has READ-ONLY Gateway access. All write operations (save, update, promote) must be presented as JSON payloads for the user to execute manually via the Chrome Extension JSON Command Console.

## Instructions

1. **Ask the user** what action they need (if not already clear from their message):
   - `artifact.save` — Create a new artifact
   - `artifact.update` — Modify an existing artifact
   - `artifact.promote` — Advance lifecycle stage (projects only)

2. **Gather required fields** based on the action:

### artifact.save
| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | Always | `"artifact.save"` |
| `gw_workspace_id` | Always | Default: `be0d3a48-c764-44f9-90c8-e846d9dbbd0a` (Qwrk Personal). Ask if different workspace intended. |
| `artifact_type` | Always | project, journal, snapshot, restart, grass, thorn |
| `title` | Always | Short descriptive title |
| `summary` | Optional | Brief summary |
| `tags` | Optional | Array of strings |
| `extension` | Required | Type-specific fields (see below) |

**DO NOT include** `artifact_id` on save — the database generates it.

**Extension fields by type:**
- **project:** `{ "lifecycle_stage": "seed", "operational_state": "active" }`
- **journal:** `{ "entry_text": "<markdown content>" }`
- **snapshot:** `{ "payload": { <structured object> } }` — payload MUST be an object, never a string
- **restart:** `{ "payload": { <structured object> } }` — same rule
- **grass/thorn:** Check DDL before generating

**for-q snapshots** — If the user indicates this is a governance/for-q artifact, include:
- `tags` array with `"for-q"` and relevant topic tags
- Inside `extension.payload`: `for_q_why_q_needs_this`, `for_q_behavioral_impact`, `for_q_scope`, `for_q_priority`

### artifact.update
| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | Always | `"artifact.update"` |
| `gw_workspace_id` | Always | Same default as save |
| `artifact_type` | Always | Must match stored type |
| `artifact_id` | Always | UUID of existing artifact |
| `extension` | Required | Only mutable fields allowed |

**Mutability rules (CRITICAL):**
- **project:** `operational_state`, `state_reason`, `design_spine` only. `lifecycle_stage` is PROMOTE_ONLY.
- **journal:** INSERT-ONLY — no updates allowed (permanent, locked by T87)
- **snapshot/restart:** Extension payload is IMMUTABLE. Spine-level operations allowed: `tags` (add/remove) and `content_append` (timestamped append_log entries). Original extension payload is never modified.
- **ALL types:** `tags` can be updated via spine-level `tags` field (add/remove semantics, Update v11)
- **ALL types:** `content_append` can add timestamped entries to spine `content.append_log` (including immutable types)

**Tags update format** (spine-level, works on ALL types including immutable):

Use structured `add`/`remove` syntax — flat array replacement is NOT supported by the Gateway (causes VALIDATION_ERROR).

```json
{
  "gw_action": "artifact.update",
  "gw_workspace_id": "...",
  "artifact_type": "snapshot",
  "artifact_id": "...",
  "tags": {
    "add": ["new-tag"]
  }
}
```

To remove a tag:
```json
{
  "tags": {
    "remove": ["old-tag"]
  }
}
```

Both `add` and `remove` can be combined in one payload. Omit whichever is not needed.

### artifact.promote
| Field | Required | Notes |
|-------|----------|-------|
| `gw_action` | Always | `"artifact.promote"` |
| `gw_workspace_id` | Always | Same default |
| `artifact_type` | Always | `"project"` (only projects have lifecycle) |
| `artifact_id` | Always | UUID of project to promote |
| `transition` | Always | `seed_to_sapling`, `sapling_to_tree`, `tree_to_archive` |
| `reason` | Always | 1-280 chars explaining why promotion is happening |

3. **Before generating the payload:**
   - Read `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` if you need to verify column names or constraints
   - Read `docs/governance/Qwrk_Gateway_JSON_Payload_Canonical_v1.md` if you need the full contract reference
   - Verify artifact_type is in the CHECK constraint (project, journal, snapshot, restart, video, grass, thorn, forest, thicket, flower, branch, leaf, limb, instruction_pack, twig)

4. **Output the payload as raw JSON only:**
   - No markdown fences around the final payload
   - No explanatory text mixed into the JSON
   - Present a brief description ABOVE the JSON, then the clean JSON block
   - One payload per output

5. **If the operation requires multiple payloads** (e.g., save then promote):
   - Output them sequentially with clear labels
   - Remind the user: execute first, wait for Gateway response, extract artifact_id, then execute second

6. **After the user confirms execution**, offer to verify via read query:
   ```
   powershell -File "scripts/CC-Gateway-Query.ps1" -Action query -ArtifactType <type> -ArtifactId "<id>" -Hydrate
   ```
