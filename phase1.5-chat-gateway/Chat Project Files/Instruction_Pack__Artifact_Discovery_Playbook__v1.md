# Instruction Pack — Artifact Discovery Playbook (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-11
**origin:** CC analysis of Q search failure on messaging subsystem project `3f3f9725`

---

## A. Purpose

Artifact discovery — finding artifacts when you do not already have a UUID — requires an explicit strategy. Without one, Q defaults to vertical tree traversal (parent → child), which fails when the target artifact lives in a different subtree, has no parent link to the starting point, or is discoverable only by tags/keywords.

### Failure modes this playbook prevents

1. **Vertical anchoring** — Walking a known tree path and concluding absence when the target lives elsewhere in the forest.
2. **Premature stop** — Finding a plausible partial hit and not cross-checking whether it is the right artifact or the complete set.
3. **Incomplete pagination** — Declaring absence from a single page of results when more pages exist.
4. **Strategy lock-in** — Using only one search mode when the situation requires switching.

---

## B. Search Modes

Before making any search call, classify the search into one of these modes:

| Mode | When to use | Primary Gateway action |
|------|-------------|----------------------|
| **Direct Hydrate** | UUID is known or was just returned by a prior call | `artifact.query` with `hydrate: true` |
| **Horizontal Discovery** | Looking for artifacts by domain, topic, tags, or keywords — UUID unknown | `artifact.list` with `artifact_type` + `filters.tags_any` or title scanning |
| **Vertical Traversal** | Parent UUID is known, looking for children or siblings | `artifact.list` with `selector.parent_artifact_id` |
| **Lineage Reconstruction** | Need to find supporting artifacts (journals, snapshots, branches) connected to a known project | Combines horizontal (find project) → vertical (list children by parent) |

**Rule:** State the search mode before executing. If a mode returns insufficient results, switch modes — do not repeat the same mode with minor variations.

---

## C. Escalation Ladder

Follow this order. Skip steps that are clearly irrelevant, but do not skip step 0.

### Step 0 — Identify search mode

Classify the request into one of the four modes above. State it.

### Step 1 — Direct hydrate (if UUID known)

If the user provides a UUID or one was returned by a prior action:
```
artifact.query with artifact_id + hydrate: true
```
Done if result is sufficient.

### Step 2 — Check CmdCtr briefing (if available)

Scan `active_surface.in_progress`, `blocked`, `stalled` for relevant titles or artifact types. CmdCtr provides titles and artifact_ids without a Gateway call.

Skip if no CmdCtr briefing is present this session.

### Step 2.5 — Navigation Snapshot Hydration (Required for Execution Context)

If the target is a project/sapling with execution anatomy (branches, leaves), check for a navigation snapshot before running multi-query discovery:

```json
{"gw_action":"artifact.list","gw_workspace_id":"...","artifact_type":"snapshot","selector":{"limit":5,"filters":{"tags_any":["navigation"]},"parent_artifact_id":"<project_uuid>"}}
```

**If a navigation snapshot exists for the target project:**
- You **MUST** hydrate it first — select the most recent by `updated_at`
- The full execution tree map is in `extension.payload`
- This is the **authoritative structure map** — sapling-root traversal is NOT authoritative when a navigation snapshot exists
- This replaces the need for steps 4–7 for structure discovery

**Scope:** This rule applies when discovering structure for a known project in execution context (sapling hydration, builder handoff, branch/leaf lookup). It does NOT apply to general discovery outside execution context (e.g., searching for artifacts by topic or tags across the forest).

Skip if:
- Target is not a project
- You are searching for artifacts unrelated to a known project tree
- Discovery is not in execution context (general browsing, topic search)

### Step 3 — Check Rolling Memory / known anchors

Check Rolling Memory (Section B) and Mother Tree Structural Map for known UUIDs or project references that match the request.

Skip if the target is clearly not a governance or for-q artifact.

### Step 4 — Horizontal discovery

Search by `artifact_type` + filters. This is the primary discovery tool for unknown artifacts.

**Tag-based:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"...","artifact_type":"project","selector":{"limit":20,"filters":{"tags_any":["email","calendar"]}}}
```

**Type-only (then scan titles):**
```json
{"gw_action":"artifact.list","gw_workspace_id":"...","artifact_type":"project","selector":{"limit":20}}
```

Scan returned titles for keyword matches. If the result set is large, apply tag filters to narrow.

### Step 5 — Keyword/title scan within results

If step 4 returns results but none obviously match, scan all returned `title` fields for domain keywords. Partial matches count — flag them as candidates and hydrate for confirmation.

### Step 6 — Vertical traversal

If a parent UUID is now known (from steps 2-5 or from the user):
```json
{"gw_action":"artifact.list","gw_workspace_id":"...","artifact_type":"journal","selector":{"limit":20,"parent_artifact_id":"<parent_uuid>"}}
```

Useful for: finding companion journals, branches, leaves, or twigs under a known project.

### Step 7 — Lineage reconstruction

Combine horizontal + vertical:
1. Find the project via horizontal discovery (step 4/5)
2. List children via vertical traversal (step 6) for each relevant artifact type (journal, branch, snapshot)

This is the correct strategy when the user asks "find everything related to X."

### Step 8 — Pagination expansion

If any list call returned exactly `limit` results, there may be more. Paginate:
```json
{"gw_action":"artifact.list","gw_workspace_id":"...","artifact_type":"project","selector":{"limit":20,"offset":20}}
```

**Do not declare absence until pagination is exhausted or results clearly thin out.**

### Step 9 — Report what was tried

If discovery fails after multiple strategies, report:
- Which search modes were attempted
- Which filters/types were used
- How many results were returned per call
- What was not tried and why

Never say "I couldn't find it" without saying what you tried.

---

## D. Filter Caveats

### `tags_any` is set containment (tags-all), not OR

Despite the name, `tags_any` requires the artifact to contain **ALL** specified tags, not any one of them. This is AND semantics.

- `tags_any: ["email", "calendar"]` → returns artifacts tagged with BOTH `email` AND `calendar`
- To find artifacts with EITHER tag, run two separate list calls (one per tag) or use a single broader tag

### Selector filters combine with AND

All filters in the `selector.filters` object are AND-combined:
- `tags_any` + `lifecycle_status` → artifact must match both

### `execution_status` filter excludes NULL

Filtering by `execution_status` will exclude artifacts where `execution_status` is NULL (uninitialized). Many artifacts — especially journals, snapshots, and restarts — have NULL execution_status. Only use this filter when searching for artifacts known to have execution state set.

### `lifecycle_status` filter applies to all types

The filter works on the spine column, not just projects. Non-project artifacts may have NULL lifecycle_status and will be excluded by this filter.

### Pagination cap

`offset + limit + 1` must not exceed 500. Violation returns `PAGINATION_WINDOW_EXCEEDED`.

---

## E. Result Sufficiency Rule

**If a search returns a plausible but partial hit, perform at least one horizontal cross-check before concluding you have found the right artifact set.**

Examples:
- Found a project titled "Email Communication Loop" — before concluding this is the messaging subsystem project, check if other projects also have `email` or `messaging` tags.
- Found 2 journals under a parent — before concluding that is all, check if journals exist under a different parent with overlapping tags (parent linking is not always to the same project).
- Found a branch titled "Planning Phase" — verify it belongs to the correct project by checking its `parent_artifact_id`.

**One result is not proof of completeness.** Cross-check reduces false-negative conclusions.

**Content append awareness (T140):** When querying immutable artifacts (snapshot, journal, restart) that may have `append_log` entries, always hydrate (`selector.hydrate: true`) to see the full content including appended context. Unhhydrated queries return spine fields only and will miss append_log data.

---

## F. Worked Examples

### Example 1: Find a project when only domain keywords are known

**Scenario:** Joel asks "What do we have on messaging and email capabilities?"

**Search mode:** Horizontal Discovery

**Step 4 — Horizontal by tags:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":20,"filters":{"tags_any":["email"]}}}
```

Returns: "Seed - Outbound Email and Calendar Dispatch Architecture" (`3f3f9725`) and "Email Communication Loop - Daisy" (`88944802`).

**Result sufficiency check:** Two projects with `email` tag. Try `messaging` tag separately (since `tags_any` is AND, not OR):
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","selector":{"limit":20,"filters":{"tags_any":["messaging"]}}}
```

If this returns the same or overlapping set, discovery is sufficient. If it returns new results, include them.

### Example 2: Find supporting journals for a known project UUID

**Scenario:** Project `3f3f9725` found. Need its companion journals.

**Search mode:** Vertical Traversal → then Horizontal cross-check

**Step 6 — Vertical by parent:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","selector":{"limit":20,"parent_artifact_id":"3f3f9725-5761-4a47-8c9e-920b8a18a1bf"}}
```

Returns journals directly parented to this project.

**Result sufficiency check — Horizontal cross-check by tags:**
```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"journal","selector":{"limit":20,"filters":{"tags_any":["email","calendar"]}}}
```

This may return journals parented to a different artifact (e.g., a thematic branch) that are still relevant to the email/calendar domain. Include them in the results.

**Why this matters:** In the messaging subsystem case, some journals were parented to a different subtree due to mutability policy constraints. Vertical-only search missed them.

### Example 3: Find children under a known parent

**Scenario:** Need all branches and leaves under project `dec0597b` (Mother Tree).

**Search mode:** Vertical Traversal

```json
{"gw_action":"artifact.list","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"branch","selector":{"limit":20,"parent_artifact_id":"dec0597b-8edc-4387-95e7-025960f3cedc"}}
```

Repeat for other types (`leaf`, `project`, `limb`, `twig`) if the parent may have mixed-type children.

### Example 4: Distinguish a consumer (Daisy) from the underlying subsystem

**Scenario:** Two email-related projects found. Need to determine which is the infrastructure subsystem vs. the consumer application.

**Search mode:** Direct Hydrate (both candidates)

Hydrate both:
```json
{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"3f3f9725-5761-4a47-8c9e-920b8a18a1bf","selector":{"hydrate":true}}
```
```json
{"gw_action":"artifact.query","gw_workspace_id":"be0d3a48-c764-44f9-90c8-e846d9dbbd0a","artifact_type":"project","artifact_id":"88944802-5097-4761-8844-523c1af0c109","selector":{"hydrate":true}}
```

Compare:
- **Tags:** `3f3f9725` has `messaging`, `integration`, `sapling-ready` → infrastructure/subsystem. `88944802` has `communication`, `daisy`, `email-loop` → consumer application.
- **Parent:** `3f3f9725` parent is Mother Tree root. `88944802` parent is Product branch → it is a product feature, not the underlying subsystem.
- **Lifecycle:** `3f3f9725` is `sapling` (has spec). `88944802` is `seed` (earlier stage).

The subsystem is `3f3f9725`. Daisy (`88944802`) is a consumer that would use it.

---

## G. When NOT to Use This Playbook

- **Saving new artifacts** — this playbook is for discovery, not creation.
- **CmdCtr-specific queries** — CmdCtr has its own decision framework (see `Instruction_Pack__CmdCtr_Session_Context__v1.md`).
- **Known-UUID operations** — if the UUID is already known with certainty, skip directly to `artifact.query`.

---

*CHANGELOG: v1.2 (2026-04-01): T166 — Step 2.5 upgraded from optional check to required enforcement in execution context. Navigation snapshot is now MUST-use when present for sapling hydration. Added: sapling-root traversal non-authority rule, execution-context scope clarifier. Previous: `Archive/Instruction_Pack__Artifact_Discovery_Playbook__v1.1__2026-04-01.md`. v1.1 (2026-03-25): Added Step 2.5 — Check for Navigation Snapshot. Fast-path shortcut for project structure discovery before multi-query escalation. Source: governance snapshot `c9cfb7e5`. Previous: `Archive/Instruction_Pack__Artifact_Discovery_Playbook__v1__2026-03-25.md`. v1 (2026-03-11): Initial version. Addresses vertical-anchoring failure mode discovered during messaging subsystem search. Defines four search modes, 10-step escalation ladder, filter caveats (tags_any AND semantics, NULL execution_status), result sufficiency rule, and four worked examples.*
