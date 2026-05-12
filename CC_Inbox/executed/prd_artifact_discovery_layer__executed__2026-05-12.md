# PRD — Artifact Discovery Layer

**Version:** v0.2
**Status:** Draft for Joel review (post-TQR revision)
**Owner:** Joel / Qwrk Prime
**Prepared by:** Q (v0.1)
**Revised by:** CC (v0.2, per consolidated WSY + Manus TQR revision packet)
**Date:** 2026-05-12

> **Boundary:** This is a PRD-revision artifact. No implementation, DDL design, Gateway action implementation, n8n workflow construction, Operator Console code, or seed creation has been authorized by this document. Approval of v0.2 does not authorize Walk or Run. Seed creation is a separate explicit step.

---

## CHANGELOG

### v0.2 — 2026-05-12

**What changed:** Doctrine-tightening pass integrating CC WSY + Manus TQR conclusions.

- `artifact.resolve` removed as a future Gateway action. "Resolve" retained only as a Q behavior verb.
- §9 Capability Model split into one proposed backend primitive (`artifact.search`) and a separate list of Q protocol behaviors. The earlier "missing discovery verbs" framing is gone.
- `recommended_next_action` removed from the proposed search response. Server returns evidence (`matched_fields`, `match_signals`); Q decides workflow.
- Match-reasons ownership split: server returns signals; Q humanizes for Joel.
- Ghost detection clarified as Q-side heuristic only. No stored flag, no Gateway-returned `is_ghost`, no mutation path.
- Crawl split into Crawl-0 (audit) and Crawl-1 (protocol). Audit gates protocol authoring.
- Walk scope tightened: title + summary + tags + selected spine metadata. Extension payload indexing explicitly deferred. `include_deleted` deferred.
- `artifact.search` marked everywhere as proposed, not current.
- Workspace-selector behavior clarified: switches active workspace; never cross-workspace search.
- Semantic type locked to `platform` (verify registry value before payload emission).
- Seed creation framed as a separate Joel decision; favorable review does not authorize it.
- §11 Step 1 expanded with positive and negative fuzzy-intent examples.
- §10.5 Test corpus committed (10 queries + 5 success categories).
- §14 NFR-4 given provisional performance targets (P50 < 250ms, P95 < 800ms — reviewable by CC during Walk design).
- §20 Draft Manus Review Prompt removed as obsolete (TQR completed).

**Why:** v0.1 introduced future capability names and conceptual surface area beyond the one primitive actually proposed. WSY + TQR converged on the need to keep the backend primitive narrow, keep the protocol layer reversible, and prevent committed doctrine from forming around unbuilt actions.

**Scope of impact:** PRD document only. No infrastructure changes.

**Previous version:** `Archive/prd_artifact_discovery_layer__v0.1__2026-05-12.md`

### v0.2 post-review corrections — 2026-05-12 (Joel)

Two pre-finalization corrections applied to v0.2 before treating it as seed-ready:

1. **Instruction-pack file limit constraint.** The Qwrk project/file limit for `instruction_pack` artifacts has been reached. Crawl-1 deliverable language updated across §10.2, §15, §17 Q#8, and §19 step 5: Artifact Discovery Protocol v1 is folded into the existing Artifact Discovery Playbook (referenced in CLAUDE.md as snapshot `16b19a1c`) or another approved existing instruction surface — NOT authored as a new standalone IP file. Target surface chosen during Crawl-1.

2. **`tags_any` semantics not asserted as known.** §8.1 #3 corrected: removed the "OR semantics" claim. Live semantics is now stated as something to be verified in Crawl-0 (consistent with §8.3 #1 and §10.1 scope #1, which already listed this as an audit item).

No other content changes. PRD scope, governance boundaries, and proposed primitive surface remain unchanged.

### v0.1 — 2026-05-12

Initial PRD draft by Q, prepared from CC's exploratory design review.

---

## 1. Executive Summary

Qwrk needs a reliable way to help Joel find and hydrate artifacts when he remembers the *idea* but not the exact artifact type, title, tag, or UUID.

Current artifact retrieval works when Q knows the artifact ID or type. It breaks down when Joel says:

> "Hey Q, I know we saved a twig, seed, or sapling for feature xyz. Let's find and hydrate it."

Today, Q must guess artifact type, run multiple list payloads, scan titles manually, try brittle tag filters, and hope the right artifact appears. This creates friction and weakens trust in Qwrk's memory.

The core thesis:

> Qwrk does not only need artifact retrieval. It needs artifact discovery: a governed path from fuzzy human memory → ranked candidates → hydration → confidence or disambiguation.

The recommended path is phased:

- **Crawl-0 — Audit:** verify current capability, audit corpus, commit a test corpus. No protocol or implementation authored.
- **Crawl-1 — Protocol:** define Q behavior using existing Gateway actions only.
- **Walk:** propose a backend `artifact.search` Gateway primitive backed by database search/indexing.
- **Run:** Operator Console / Forest Explorer discovery UX, candidate lineage views, and optional semantic search when justified.

This should be a new QPM project, not a child of Operator Console. Operator Console should consume the discovery capability, but discovery itself is a platform primitive.

The only proposed Gateway action in this PRD is `artifact.search`. All higher-level discovery behavior — interpreting fuzzy human memory, presenting candidates, asking clarifying questions, humanizing match reasons, demoting ghost saves — is **Q-side protocol**, not a future Gateway endpoint.

---

## 2. Background and Context

### 2.1 Forest Explorer — possible predecessor / ghost save

- **Artifact:** `3b7a4aa6-a85a-4359-bd3c-18de58f2e0e1`
- **Type:** project
- **Title:** `Seed - Forest Explorer — Qwrk Artifact Interface`
- **Status:** seed
- **Tags:** `seed`, `ui`, `artifact-explorer`, `platform`

Relevant by title but body is empty (null summary, empty `content`, null `design_spine`). Should be treated as evidence, not authority. Possible later action: governance snapshot marking it superseded by Artifact Discovery Layer. No deletion until reviewed.

### 2.2 List Filter Enhancement — completed primitive

- **Artifact:** `4c6c9395-f608-4bd3-a4f3-de48d6020087`
- **Type:** project
- **Title:** `List Filter Enhancement`
- **Status:** tree
- **Tags:** `seed`, `platform`, `gateway`

Tree-state with v3 but empty body. Likely represents completed Gateway-side list/filter improvements. May be a historical dependency reference, not the parent.

### 2.3 Qwrk Operator Console — MVP

- **Artifact:** `152d9c11-521e-4597-8e72-d0bf07546805`
- **Type:** project
- **Title:** `Qwrk Operator Console — MVP`
- **Status:** sapling
- **Tags:** `operator-console`, `mvp`, `visibility`
- **Summary:** "First product surface for Qwrk providing visibility into artifacts across workspaces, including list, filter, hydration, and human-readable rendering. Transitioning from read-only console to full operator surface with topology visualization and controlled write actions."

The most likely future UI consumer of artifact discovery. Should not own the backend primitive.

### 2.4 Operator Console Navigation Snapshot

- **Artifact:** `a0e5e2d2-b7b4-49e1-b54e-81161026c377`
- **Type:** snapshot
- **Parent:** `152d9c11-521e-4597-8e72-d0bf07546805`

Identifies two branches:

1. **Core Console — Read & Hydration System** (`d5781fab-5659-4443-b656-bb84ca80752a`) — Phases 1–8 already built by CC.
2. **Topology Visualization — Artifact Tree & Relationships** (`298a32bd-191f-4f7f-8ecb-b84ea534b7e8`) — parent-child traversal, tree UI, lazy hydration, visual encoding (5 leaves, all `not_started`).

Reinforces that Operator Console is already positioned as a visibility surface; the missing discovery capability is platform-wide.

---

## 3. Problem Statement

Qwrk currently lacks a reliable artifact discovery path for fuzzy human memory.

The user can often remember a feature idea, partial title, system area, approximate timeframe, rough artifact type, or that "we saved something about this." But the system currently performs best only when Q knows exact artifact type, exact UUID, reliable tags, or a known parent/lineage.

The core mismatch:

> Qwrk remembers artifacts structurally, but Joel remembers them semantically.

The discovery layer must bridge that gap.

---

## 4. User Need

### 4.1 Primary user story

As Joel, I want to say:

> "Hey Q, I know we saved a twig, seed, or sapling for feature xyz. Let's find and hydrate it."

And have Q:

1. understand this as a fuzzy artifact discovery request,
2. produce a small, reliable payload or payload sequence,
3. search across plausible artifact types,
4. return ranked candidates with match reasons,
5. hydrate the likely artifact or ask me to choose between a few candidates,
6. identify likely ghost saves or stale duplicates instead of treating them as authoritative.

### 4.2 Secondary user stories

As Joel, I want Q to find artifacts when I only remember:

- "that beta onboarding thing,"
- "the artifact search sapling,"
- "the EV9 charging snapshot,"
- "the feature we saved about file search,"
- "the seed that later became Operator Console,"
- "the old ghost save that looked like the thing but wasn't."

As Q, I need a deterministic protocol so I do not improvise search payloads blindly.

As Operator Console, I need a backend discovery primitive that can power future UI search, filters, tree navigation, and hydration.

As Team Qwrk, we need a clear project container, scope boundaries, and phasing model before implementation.

---

## 5. Goals

### 5.1 Product goals

1. Make Qwrk feel more trustworthy by improving retrieval of previously saved work.
2. Reduce friction when Joel remembers an idea but not its artifact details.
3. Prevent artifact memory from feeling like a junk drawer.
4. Create a reusable discovery primitive for all future Qwrk surfaces.
5. Improve confidence, candidate ranking, and hydration flow.

### 5.2 Technical goals

1. Establish a deterministic Q-side Artifact Discovery Protocol using current capabilities.
2. Propose a backend search primitive capable of cross-type ranked artifact search.
3. Preserve workspace boundaries and Gateway governance.
4. Avoid premature semantic/vector search until lexical/fuzzy search is proven.
5. Avoid creating a second memory system that drifts from live artifacts.

### 5.3 Governance goals

1. Do not mutate artifacts during discovery.
2. Do not auto-delete, merge, alias, or tag artifacts during discovery.
3. Surface ghost/stale candidates as possible issues, not automatic conclusions.
4. Ensure any backend changes follow QPM and parallel-build governance.
5. Keep Operator Console as a consumer of discovery, not the owner of the platform primitive.

---

## 6. Non-Goals

This project does **not** include:

1. Full semantic/vector search.
2. Cross-workspace "search everywhere" behavior.
3. Automatic artifact deduplication.
4. Automatic ghost-save deletion.
5. Automatic tag cleanup.
6. Full Forest Explorer UI implementation.
7. Replacement of `artifact.query` or `artifact.list`.
8. Background indexing jobs unless later justified.
9. A separate artifact-memory registry that becomes a second source of truth.
10. A future `artifact.resolve` Gateway action. "Resolve" is a Q behavior verb only.
11. A stored `is_ghost` flag, Gateway-returned ghost annotation, or any ghost-save mutation path.
12. Indexing of extension payload / content. Deferred unless Crawl-0 audit proves it necessary and safe.
13. An `include_deleted` flag in Walk. `artifact.search` excludes soft-deleted artifacts by default.
14. Auto-hydration without rank threshold or confirmation when ambiguity exists.

---

## 7. Core Concepts

### 7.1 Retrieval vs discovery

**Retrieval** means Q knows the ID or exact type and can fetch the artifact.

**Discovery** means Q must find the likely artifact from incomplete, fuzzy, human memory.

Current Qwrk supports retrieval better than discovery.

### 7.2 Search vs resolve

**Search** is the proposed backend Gateway primitive (`artifact.search`): return ranked candidates matching a query. Does not exist today.

**Resolve** is a Q-side **behavior verb** for the act of interpreting Joel's fuzzy request, calling search, ranking, explaining, hydrating, or disambiguating. It is **not a proposed Gateway action**. There is no `artifact.resolve` payload in this PRD.

This PRD proposes exactly one Gateway action: `artifact.search`. Higher-level Q behavior does not require a new Gateway endpoint and must not be presented as one.

### 7.3 Ghost save

A ghost save is a plausible-looking artifact that may not contain enough content or lineage to be authoritative.

Q-side heuristic indicators (not database truth):

- empty `content`,
- null or generic `summary`,
- sparse tags,
- seed lifecycle never advanced,
- no design spine,
- no child artifacts,
- no navigation snapshot,
- title overlap with later stronger artifacts.

Ghost-like status is a **Q-side computed property** at candidate-ranking time. It is provisional and surfaced to Joel as "possible ghost-like candidate" or "low-content/stale candidate." It is never an authoritative server flag, and ghost detection never triggers a mutation.

---

## 8. Existing Capability Assessment

### 8.1 Current strengths

Qwrk already supports:

1. `artifact.query` by known UUID and artifact type.
2. `artifact.list` by artifact type with tag/lifecycle/execution-status filters.
3. Tag filters (`tags_any` — live semantics to be verified in Crawl-0).
4. Parent-child traversal through `parent_artifact_id`.
5. Hydration for supported artifact types.
6. Navigation snapshots for some saplings.
7. Rolling Memory as a starting index for active/high-salience artifacts.
8. Operator Console as an emerging visibility surface.

### 8.2 Current weaknesses

Qwrk currently lacks:

1. Cross-type search.
2. Fuzzy title matching.
3. Ranked candidate results.
4. Match evidence (matched fields, signals).
5. Search across title + summary + tags together.
6. Reliable search of heterogeneous JSON content.
7. A deterministic Q behavior protocol for fuzzy discovery.
8. A confidence threshold model.
9. Ghost-save demotion or duplicate detection.
10. A single payload to find likely artifacts from a fuzzy query.

### 8.3 Known uncertainty (to be resolved by Crawl-0 audit)

1. Live `tags_any` semantics.
2. Whether `pg_trgm` is enabled or can be enabled.
3. Whether `tsvector` / full-text search is already available or indexed.
4. Current DDL/index state for `qxb_artifact`.
5. Summary coverage across artifact types.
6. Ghost-save prevalence by type/workspace.
7. Whether existing instruction packs already define enough search-ladder behavior.
8. Soft-delete behavior on list/query (assumed: filtered by default).

---

## 9. Proposed Capability Model

### 9.1 Backend primitive (one proposed Gateway action)

- **`artifact.search`** — proposed. Ranked cross-type artifact search. Does not exist today. Requires separate design, authorization, implementation, testing, and documentation. **Not approved by PRD acceptance alone.**

### 9.2 Q protocol behaviors (not Gateway actions)

These are behaviors Q performs within its discovery protocol. **None of them are proposed Gateway endpoints:**

- hydrate candidate
- explain match
- disambiguate
- broaden search
- ghost-check
- lineage-check
- present confidence
- ask one clarifying question when needed

### 9.3 Action naming

Backend action (proposed):

```json
{
  "gw_action": "artifact.search"
}
```

There is no proposed `artifact.resolve` action. Resolve is a Q behavior verb, not a Gateway action name.

---

## 10. Crawl-0 / Crawl-1 / Walk / Run Phasing

### 10.1 Crawl-0 — Audit

**Purpose:** gather facts before writing protocol.

**Scope:**

1. Verify live `tags_any` semantics.
2. Verify current list/query/hydration/filter behavior.
3. Verify soft-delete behavior on list and query.
4. Audit summary/content coverage by artifact type.
5. Identify likely ghost-save candidates.
6. Confirm search-related DDL/index capabilities (`pg_trgm`, `tsvector` / full-text availability).
7. Commit the initial 10-query fuzzy discovery test corpus (see §10.5).

**Crawl-0 does NOT include:**

- protocol authoring
- Gateway changes
- DDL changes
- implementation of any kind

**Done means:**

- Audit snapshot exists.
- Initial test corpus is locked.
- Capability gaps are documented.
- No protocol or implementation has been authorized.

### 10.2 Crawl-1 — Protocol

**Purpose:** define Q behavior based on Crawl-0 evidence.

**Scope:**

1. Fuzzy discovery intent recognition (positive + negative examples, see §11 Step 1).
2. Candidate scoring v1 heuristic (title match, tag overlap, lifecycle relevance, recency, parent/lineage relevance, navigation snapshot presence, summary/content richness, ghost-save penalty).
3. Ghost-like demotion (Q-side heuristic, see §7.3).
4. Candidate presentation format.
5. Hydrate / disambiguate / broaden behavior.
6. One-clarifying-question max.
7. Execution of the committed test corpus.

**Crawl-1 does NOT include:**

- Gateway changes
- DDL changes
- UI work
- vector search

**Delivery surface (instruction-pack file limit constraint):** The Qwrk project/file limit for `instruction_pack` artifacts has been reached. **Artifact Discovery Protocol v1 must NOT be authored as a new standalone instruction_pack file.** It is folded into the existing Artifact Discovery Playbook (referenced in CLAUDE.md as snapshot `16b19a1c`) — via a new latest-wins version of that snapshot — or into another approved existing instruction surface (e.g., update to an existing IP's content via the spine-level content/content_append path, or absorption into a relevant system instruction). The exact target surface is selected during Crawl-1, not pre-committed by this PRD.

**Done means:**

- Artifact Discovery Protocol v1 exists, folded into the existing Artifact Discovery Playbook (or another approved existing instruction surface). Not a new standalone IP file.
- Q runs the protocol without improvisation using existing Gateway actions only.
- Test corpus has been executed; results documented.
- Crawl-1 acceptance target: ≥8 of 10 queries return useful candidate sets, failure modes documented.

### 10.3 Walk — Backend Search Primitive

**Status:** **Proposed only. Does not exist today.** `artifact.search` requires separate design, authorization, implementation, testing, and documentation after PRD acceptance. PRD acceptance does not authorize Walk implementation.

**Purpose:** add the missing platform primitive — a single Gateway action that searches artifacts across types and returns ranked candidates with evidence.

**Scope:**

1. Proposed Gateway action `artifact.search`.
2. Search over title, summary, tags, and selected spine metadata if useful.
3. Cross-type results within one workspace.
4. Server-returned rank and match evidence (`matched_fields`, `match_signals`).
5. Optional filters for type, lifecycle, execution status, tags, parent, and limit.
6. Test harness expansion (Phase 2C Cert).
7. Q protocol update to prefer `artifact.search`.

**Walk explicitly does NOT include:**

- Extension payload/content indexing. Deferred unless Crawl-0 audit proves necessary and safe.
- `include_deleted` flag. `artifact.search` excludes soft-deleted artifacts by default.
- Semantic / vector search.
- Cross-workspace global search.
- Full JSONB content indexing.
- Operator Console UI work.
- Server-returned `is_ghost` or workflow-recommendation fields.

**Walk requirements:**

#### WR-1: `artifact.search` payload shape (candidate draft for CC validation in Walk design)

```json
{
  "gw_action": "artifact.search",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "selector": {
    "query": "artifact discovery layer",
    "artifact_types": ["project", "snapshot", "twig", "restart", "branch", "leaf"],
    "filters": {
      "lifecycle_status": ["seed", "sapling", "tree"],
      "execution_status": ["not_started", "in_progress", "blocked", "complete"],
      "tags_any": ["platform"]
    },
    "limit": 10
  }
}
```

Exact schema to be validated by CC during Walk design phase, not by this PRD.

#### WR-2: `artifact.search` response shape (candidate draft)

```json
{
  "ok": true,
  "gw_action": "artifact.search",
  "gw_workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a",
  "data": {
    "candidates": [
      {
        "artifact_id": "...",
        "artifact_type": "project",
        "title": "Artifact Discovery Layer",
        "summary_excerpt": "...",
        "tags": ["platform", "gateway", "discovery"],
        "lifecycle_status": "seed",
        "execution_status": null,
        "rank": 0.87,
        "matched_fields": ["title", "tags", "summary"],
        "match_signals": [
          "title contains discovery",
          "tag match: platform"
        ]
      }
    ]
  }
}
```

**Server returns evidence, not workflow guidance.** No `recommended_next_action`, no `is_ghost`, no auto-hydrate hints in the response.

#### WR-3: Database search baseline

Likely direction (to be confirmed in Walk design):

- Full-text search over title, summary, and tags.
- `pg_trgm` fuzzy title matching.
- GIN indexes where appropriate.
- Workspace-scoped query.

Exact implementation to be determined by CC after Crawl-0 audit.

#### WR-4: Workspace scoping (mandatory)

`artifact.search` must never search across all workspaces by default. Each call must require `gw_workspace_id` and enforce the same workspace access posture as current Gateway reads.

#### WR-5: Read-only (mandatory)

`artifact.search` must not mutate artifacts, update tags, create aliases, mark ghosts, write snapshots, or change lifecycle/execution status. Ghost detection is **not** a Gateway concern.

#### WR-6: Ranked but humble

Ranking is candidate confidence, not truth. Q must avoid overclaiming. Server returns rank; Q decides thresholds:

- high confidence → hydrate likely match,
- medium confidence → ask Joel to choose,
- low confidence → broaden search or ask one clarifying question.

#### WR-7: Q protocol update

Once `artifact.search` exists, Q should:

1. prefer `artifact.search` for fuzzy discovery,
2. fall back to Crawl-1 protocol on error or unavailable action,
3. present candidates with humanized match reasons,
4. hydrate top result only when confidence is strong.

#### WR-8: Match-reasons ownership (division of responsibility)

- **Server** returns `matched_fields` (array of field names) and `match_signals` (array of short signal phrases).
- **Q** humanizes signals into match reasons for Joel.
- Q must preserve confidence humility — "matched on title and tags" not "this is definitely it."

Example:

Server signal:

```json
"matched_fields": ["title", "tags"],
"match_signals": ["title contains discovery", "tag match: platform"]
```

Q-facing explanation:

> "This matched because the title includes 'Artifact Discovery' and the tags include `platform`."

#### WR-9: Ghost detection is Q-side only

Gateway must not return an `is_ghost` flag. Ghost-like status is a Q-side computed heuristic at candidate-ranking time, based on returned metadata (per §7.3). Ghost candidates are surfaced as provisional ("possible ghost-like candidate") and never auto-hydrated.

#### WR-10: Soft-deleted artifacts excluded by default

`artifact.search` filters soft-deleted artifacts the same way `artifact.list` does. No `include_deleted` flag in this Walk scope.

#### WR-11: Performance targets (provisional)

Tentative Walk performance targets, pending CC runtime validation during Walk design:

- P50 under 250ms
- P95 under 800ms

These ceilings are reviewable. CC will validate against current Gateway + DB capacity before implementation.

**Walk done means:**

1. `artifact.search` exists, is documented, and is recognized as a Gateway action.
2. Search returns ranked cross-type candidates in one round trip.
3. Server returns matched-fields and match-signals (no workflow recommendations).
4. Search passes cert harness cases.
5. Search respects workspace boundaries.
6. Search excludes soft-deleted artifacts by default.
7. Q protocol is updated to prefer search.
8. Test corpus reaches target accuracy (improvement over Crawl-1 on the same set).
9. Performance targets validated or revised against runtime evidence.

### 10.4 Run — Resolve Behavior, UI, and Semantic Discovery

**Purpose:** turn backend search into a high-trust product experience across Q, Operator Console, and future Qwrk surfaces.

**Scope:**

1. Q-side resolve behavior — fuzzy interpretation, search, lineage check, hydration, disambiguation. **Protocol layer, not a Gateway endpoint.**
2. Operator Console discovery UI (consumer of `artifact.search`).
3. Forest Explorer / topology-aware artifact browsing.
4. Candidate lineage views.
5. Duplicate/ghost surfacing (Q-side).
6. Optional semantic/vector search once justified.

**Run explicitly does NOT include:**

- A future `artifact.resolve` Gateway action. Resolve is a Q behavior, not a backend endpoint.
- Replacing human judgment.
- Auto-merging artifacts.
- Auto-deleting ghost saves.
- Background autonomous cleanup.
- Cross-workspace mutation.

**Run requirements:**

#### RR-1: Resolve behavior (Q protocol, not a Gateway action)

Q's resolve behavior combines:

1. fuzzy query interpretation,
2. search via `artifact.search`,
3. candidate ranking and ghost demotion,
4. lineage check (parent/children/navigation snapshot),
5. hydration of top candidate when confidence is strong,
6. match explanation (humanized from server signals),
7. disambiguation prompt when confidence is medium.

This is Q protocol. **No `artifact.resolve` payload exists in this PRD.**

#### RR-2: Operator Console discovery UI

Operator Console consumes `artifact.search` and provides:

- search box,
- type facets,
- lifecycle facets,
- tag facets,
- workspace selector (see clarification below),
- candidate cards,
- hydrate-on-click,
- parent/child context,
- navigation snapshot indicators,
- ghost/stale warnings (Q-side / client-side heuristic).

**Workspace selector clarification:** the selector **switches the active workspace context**, then searches that one workspace. It does **not** enable cross-workspace search. Cross-workspace search remains out of scope per §6.

#### RR-3: Forest Explorer

Forest Explorer is a future visual mode, not the first solution. May include forest/tree visualization, artifact topology, project/branch/leaf structure, health/state overlays, neglected/stalled indicators, search results projected into topology.

#### RR-4: Semantic search gate

Semantic/vector search is considered only when:

- lexical/fuzzy search is operational,
- summary coverage is materially improved,
- real usage shows lexical search plateauing,
- embedding cost/governance is understood,
- model/version drift management is planned.

**Run done means:**

1. Joel can ask Q to find a fuzzy artifact and reliably get the right hydrated result or a useful candidate set.
2. Operator Console can search, filter, hydrate, and show artifact lineage.
3. Ghost/duplicate candidates are visible and understandable.
4. Search behavior feels like trusted memory, not manual database spelunking.

### 10.5 Committed test corpus (Crawl-0 lock)

Initial committed Crawl test set (10 queries):

1. artifact search thing
2. forest explorer
3. operator console search
4. beta onboarding
5. EV9 charging
6. deployment company signal
7. ghost capture blocker
8. QPA workday assistant
9. seed pod retrieval gap
10. debt freedom snapshot

Each query is evaluated against five success categories:

- **Exact match** — correct artifact surfaced as top candidate.
- **Useful candidate set** — correct artifact appears in top 3–7 with explainable rank.
- **False positive** — wrong artifact surfaced as top with high confidence (failure case).
- **No-result with good failure behavior** — Q broadens, asks, or fails honestly.
- **Ghost/stale candidate correctly flagged as uncertain.**

Crawl-1 acceptance target: ≥8 of 10 queries return useful candidate sets, with documented failure-mode behavior for the rest.

Walk acceptance target: Walk must improve over Crawl-1 protocol on the same committed test set.

---

## 11. Proposed Q Behavior Protocol

When Joel issues a fuzzy artifact discovery request, Q follows this protocol.

### Step 1 — Recognize intent

**Positive examples (these ARE artifact discovery requests):**

- "Find the artifact we saved about artifact discovery."
- "I know we created a seed for Forest Explorer."
- "Hydrate the sapling about Operator Console search."
- "What was the twig for ghost capture?"
- "Find the thing we captured about EV9 charging."

**Negative examples (these are NOT artifact discovery requests):**

- "Find the right person for this project." (people lookup, not artifacts)
- "Search the web for EV9 incentives." (web search)
- "Look up the latest OpenAI news." (web search)
- "Find my calendar opening." (calendar)
- "Find a restaurant near me." (location / external)

Purpose: prevent Q from treating every "find" request as artifact discovery.

### Step 2 — Extract hints

Extract:

- query phrase,
- likely workspace,
- artifact type hints,
- lifecycle hints,
- system/domain hints,
- timeframe hints,
- known related artifacts.

### Step 3 — Ask at most one clarifying question

Only when scoring is impossible without it. Examples:

- "Prime or BlaggLife?"
- "Are you thinking Qwrk build work or household/personal?"
- "Do you remember if it was recent?"

Do not ask if there is enough context to search.

### Step 4 — Search

- Crawl-1 mode: deterministic list/query ladder using existing Gateway actions.
- Walk/Run mode: `artifact.search`.

### Step 5 — Score and classify candidates

Candidate labels:

- likely match,
- possible match,
- weak match,
- possible ghost-like / stale duplicate,
- likely related but not the target.

### Step 6 — Present candidates

Show 3–7 candidates with title, type, lifecycle/status, artifact ID, humanized match reason, and recommended next action.

### Step 7 — Hydrate or disambiguate

- One strong match → provide hydrate payload.
- Multiple plausible matches → ask Joel to choose.
- No strong match → broaden search or ask one clarifying question.

### Step 8 — Handle ghost/stale candidates

If a candidate appears ghost-like (per §7.3 heuristic): flag it, do not auto-delete, suggest review only if relevant, prefer richer/active lineage when deciding likely authority. Never auto-hydrate a ghost.

---

## 12. Project Routing Recommendation

### 12.1 Recommended route

A favorable Joel review does **not** authorize seed creation. Seed creation is a separate, explicit Joel decision.

If favorable review concludes, Q may **prepare a seed proposal** for Joel's authorization. The seed itself is created only after Joel explicitly approves the proposed payload.

Proposed seed shape (for future Joel decision):

- **Title:** `Seed — Artifact Discovery Layer`
- **Tags:** `platform`, `gateway`, `discovery`, `artifact-search`
- **Semantic type:** `platform`
  - Note: verify exact registry value (`platform` key in `qxb_semantic_type_registry`) before payload emission. Do not save with ambiguous semantic type.
- **Parent:** Platform container, unless Joel chooses another route.

### 12.2 Rationale

This should be a new project because:

1. It is a platform primitive, not just a UI feature.
2. It benefits Q, Operator Console, Telegram, future front ends, and Team Qwrk workflows.
3. Operator Console should consume the capability, not own it.
4. List Filter Enhancement is already tree/completed.
5. Forest Explorer appears stale or ghost-like.
6. Backend search, Q protocol, and future UI all need a common project container.

### 12.3 Relationship to existing artifacts

- **Forest Explorer seed (`3b7a4aa6`)** — treat as possible predecessor / possible ghost / not authoritative. Possible later action: governance snapshot marking it superseded. No deletion until reviewed.
- **List Filter Enhancement (`4c6c9395`)** — historical Gateway capability, not the parent. Leave as completed tree.
- **Qwrk Operator Console MVP (`152d9c11`)** — downstream consumer, UI integration target, not the owner of the backend primitive. Later may get a child branch consuming `artifact.search`.

---

## 13. Functional Requirements

- **FR-1:** Q must recognize fuzzy artifact discovery requests and not treat them as generic conversation (positive/negative examples per §11 Step 1).
- **FR-2:** The system must support discovery when artifact type is unknown.
- **FR-3:** Results must be ranked using server-returned `rank`.
- **FR-4:** Server returns `matched_fields` and `match_signals`; Q humanizes for Joel.
- **FR-5:** The system must provide a clean path from candidate to hydrated artifact.
- **FR-6:** Ghost/stale warnings are Q-side heuristic only, surfaced as provisional language.
- **FR-7:** Discovery must be scoped to one workspace per request. Cross-workspace search is out of scope.
- **FR-8:** Search/discovery must not mutate artifact state.
- **FR-9:** If `artifact.search` is unavailable, Q must fall back to the Crawl-1 protocol.
- **FR-10:** Search response shape must be suitable for future Operator Console consumption.

---

## 14. Non-Functional Requirements

- **NFR-1: Trustworthy results** — Q must avoid false certainty. Candidate confidence framed clearly.
- **NFR-2: Low cognitive load** — Joel should not need to know artifact type or exact tags.
- **NFR-3: Low round-trip count** — Walk target: fuzzy search requires one payload before hydration/disambiguation.
- **NFR-4: Fast enough for interactive use** — Tentative Walk performance targets (provisional, pending CC runtime validation):
  - P50 under 250ms
  - P95 under 800ms

  Targets are reviewable; CC validates against current Gateway + DB capacity during Walk design.
- **NFR-5: Governance-safe** — no unauthorized writes, no cross-workspace mutation, no hidden cleanup.
- **NFR-6: Evolvable** — lexical search must not prevent later semantic/vector search.

---

## 15. Acceptance Criteria

### Crawl-0 acceptance

- Audit snapshot exists.
- Test corpus committed.
- Capability gaps documented.
- No protocol or implementation authorized.

### Crawl-1 acceptance

- Artifact Discovery Protocol v1 exists, folded into the existing Artifact Discovery Playbook (or another approved existing instruction surface). Not a new standalone IP file.
- Q runs the protocol without improvisation using existing Gateway actions only.
- Candidate presentation standardized.
- 10 real fuzzy queries tested.
- ≥8 of 10 return useful candidate sets.
- Failure modes documented.

### Walk acceptance

- `artifact.search` exists and is documented.
- Searches across multiple types in one round trip.
- Returns ranked candidates with `matched_fields` and `match_signals` (no workflow recommendations).
- Respects workspace scope.
- Excludes soft-deleted by default.
- Phase 2C cert harness coverage extended.
- Improves over Crawl-1 protocol on the same committed test corpus.
- Performance targets validated or revised.

### Run acceptance

- Q can resolve fuzzy artifact references with high trust.
- Operator Console can search and hydrate without UUID knowledge.
- Forest/topology UI can show search results in context.
- Ghost/stale artifacts surfaced without automatic mutation.
- Semantic search gated by evidence, not excitement.

---

## 16. Risks and Anti-Patterns

- **Overbuilding UI first** — building Forest Explorer before backend search risks creating a beautiful interface over weak retrieval.
- **Making tags more load-bearing** — tags are useful but too inconsistent to be primary search mechanism.
- **Creating a second memory system** — avoid search-index snapshots or manual registries that drift from live artifacts.
- **False confidence** — ranking must not become overclaiming. Q should say "likely" when it means likely.
- **Ghost-save contamination** — low-content seeds may appear plausible by title. The system must flag and demote them (Q-side, heuristic, provisional).
- **Schema churn** — do not add heavy indexing, materialized views, or vector search until Crawl-0 audit proves need.
- **Cross-workspace leakage** — search must stay workspace-scoped. Cross-workspace reads require explicit future design.
- **Protocol ossification** — do not make Crawl-1 protocol so elaborate that it becomes permanent brittle doctrine.
- **Future-action commitment drift** — naming actions that don't exist (e.g., `artifact.resolve`) before they're needed creates doctrine pressure to build them. Keep the proposed Gateway surface narrow.
- **Coupling search response to workflow** — server returns evidence; Q decides workflow. Putting `recommended_next_action` or similar in the response makes the primitive harder to evolve.

---

## 17. Open Questions for Manus Review (post-TQR — most resolved)

Many of these were resolved by the WSY + TQR review cycle. Retained for traceability.

1. Is a new `Artifact Discovery Layer` project the right product/governance container? **Resolved: yes.**
2. Should this be framed as platform, infrastructure, or product? **Resolved: platform.**
3. Does the Crawl/Walk/Run sequence avoid overbuild? **Resolved: yes, with Crawl split into Crawl-0 + Crawl-1.**
4. Does the PRD preserve Operator Console as consumer rather than owner? **Resolved: yes.**
5. Is `artifact.search` the right backend primitive name? **Resolved: yes.**
6. Should `artifact.resolve` be a future action, a Q protocol, or a product behavior only? **Resolved: Q behavior only. No `artifact.resolve` Gateway action.**
7. Does this improve the felt experience of Qwrk memory without making the system heavier? **Open — measured by Crawl-1/Walk acceptance against test corpus.**
8. What user-facing language should Q use when confidence is medium or low? **Partial — Q protocol defines confidence bands; exact phrasing TBD when Crawl-1 protocol is folded into the existing Artifact Discovery Playbook or another approved instruction surface.**
9. How should ghost saves be surfaced without creating cleanup anxiety? **Resolved: provisional language, Q-side heuristic only, never auto-action.**
10. What should be deliberately excluded from v1? **Resolved: §6 Non-Goals.**

---

## 18. Open Questions for CC Review (post-TQR — most pending Walk design)

Reserved for CC to address during Walk design phase, not in this PRD.

1. Is `artifact.search` feasible with current Gateway architecture? **Pending Crawl-0 audit + Walk design.**
2. What DDL/index changes are required for title + summary + tag search? **Pending Walk design.**
3. Is `pg_trgm` available and appropriate? **Pending Crawl-0 audit.**
4. Should search use `tsvector`, trigram, or both? **Pending Walk design.**
5. What cert harness cases are required? **Pending Walk design.**
6. What response shape is easiest for Q and Operator Console to consume? **Initial draft in WR-2; finalized in Walk design.**
7. How should rank/confidence be calculated? **Pending Walk design.**
8. What fields should be searchable in Walk? **PRD answer: title + summary + tags + selected spine metadata. Extension content deferred.**
9. Should JSONB content/extension search be deferred? **Resolved: yes, deferred unless Crawl-0 audit proves need.**
10. How do we verify workspace isolation? **Pending Walk design + cert harness.**

---

## 19. Concrete Next Steps

Sequence (each step is a separate Joel decision):

1. **Joel reviews PRD v0.2.**
2. If favorable: Q may prepare a seed proposal payload for Joel's authorization. **This is not seed creation; it is a draft for Joel's decision.**
3. **Joel separately authorizes seed creation** by executing the proposed payload via QSB (per §2.5 Read-Only Rule).
4. After seed exists: begin **Crawl-0 (Capability + Corpus Audit Snapshot)**.
5. After Crawl-0 done: begin **Crawl-1 (Artifact Discovery Protocol v1, folded into the existing Artifact Discovery Playbook or another approved existing instruction surface — not a new standalone IP file)**.
6. After Crawl-1 done and evaluated: Joel decides whether to authorize Walk.
7. Walk implementation begins only after Walk-specific authorization.

**Favorable PRD review does NOT authorize seed creation, Crawl-0, Crawl-1, Walk, or Run.** Each step is a separate explicit decision.
