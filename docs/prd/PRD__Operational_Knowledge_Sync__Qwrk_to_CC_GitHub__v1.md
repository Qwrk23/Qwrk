# PRD — Operational Knowledge Sync (Qwrk → Docs → CC → GitHub)

## 1. Purpose
Ensure that **any change affecting how Qwrk functions, decides, or is interpreted** is automatically converted into a durable, human-readable Markdown document and made available to **Claude Code (CC)** and versioned in **GitHub**, so CC is always operating with current, authoritative operational knowledge.

This feature eliminates drift between:
- Qwrk’s internal operational state (truth)
- CC’s working knowledge (builder context)
- GitHub documentation (audit + collaboration layer)

---

## 2. Problem Statement
Today, Qwrk can correctly:
- Capture snapshots
- Capture restarts
- Capture governance and semantic decisions

However:
- These records live primarily **inside Qwrk**
- CC must rely on manual briefings or file uploads
- GitHub documentation can lag or fragment

This creates risk of:
- Context loss
- Incorrect builds
- Re-litigation of settled decisions
- Silent divergence between system behavior and documentation

---

## 3. Goals (What this feature must achieve)
1. **Authoritative sync**: When certain Qwrk records are saved, CC and GitHub are updated automatically.
2. **Selective scope**: Only *behaviorally meaningful* records trigger document creation.
3. **Human-first format**: Markdown (.md) is the canonical external representation.
4. **Low noise**: Routine data does not generate docs.
5. **Deterministic behavior**: Same input → same document structure.
6. **Auditability**: Git history shows when and why operational knowledge changed.

---

## 4. Non‑Goals
- Real-time syncing of all records
- Storing full raw JSON payloads in GitHub
- Replacing Qwrk as the system of record
- Generating user-facing documentation
- Supporting binary formats (PDF, DOCX) initially

---

## 5. Triggering Records (Doc Generation Criteria)

### 5.1 System Behavior
- How Qwrk functions
- What Qwrk is allowed to do
- What Qwrk will refuse to do
- How decisions are routed or prioritized

**Examples**
- Snapshots
- Restarts
- Gateway rule changes
- Kernel semantic locks
- Allow/deny lists
- Governance decisions

---

### 5.2 Interpretation & Meaning
Records that redefine *how existing behavior should be understood*.

**Examples**
- “From now on, X means Y”
- Field immutability declarations
- Temporary vs permanent behavior notes
- Advisory vs authoritative signals

---

### 5.3 Boundaries & Constraints
Records that define limits or guardrails.

**Examples**
- MVP limitations
- Owner-only rules
- Beta constraints
- Performance ceilings
- Scope exclusions

---

### 5.4 State Transitions
Records that declare a shift in authority or phase.

**Examples**
- Phase changes
- Supersession notices
- Canonical-source declarations
- “This replaces the previous approach”

---

### 5.5 Deferred Intent / Upgrade Seeds
Records that explain **why something is intentionally incomplete**.

**Examples**
- Planned migrations
- “Upgrade later” seeds
- Conditional future behavior

---

## 6. Records Explicitly Excluded
The following **must NOT** trigger document creation:
- Raw logs
- Telemetry
- Routine CRUD events
- Intermediate calculations
- Temporary test artifacts
- High-frequency operational data

Rule of thumb:
> If deleting the record would not confuse a future builder, it does not need a document.

---

## 7. Document Generation Rules

### 7.1 Format
- Markdown (`.md`) only
- UTF-8
- Deterministic headings and sections

### 7.2 Content Structure (Required)
Every generated document must include:
1. Title
2. Date
3. Source artifact ID
4. Purpose / Why this exists
5. What changed (summary)
6. Impact on Qwrk behavior
7. Constraints / boundaries
8. Next actions (if any)
9. Link back to full Qwrk record

---

## 8. Size & Payload Management
- Documents should favor **summaries**
- Large JSON payloads should be:
  - Omitted or summarized
  - Linked back to Qwrk as canonical source
- Hard size threshold (TBD) beyond which auto‑summarization is required

---

## 9. Storage & Sync Targets

### 9.1 Primary External Store
- Google Drive (shared folder accessible by CC)

### 9.2 Version Control
- GitHub repository
- One commit per generated document (or grouped by trigger batch)

### 9.3 Source of Truth
- Qwrk remains canonical
- Docs are representations, not authorities

---

## 10. Failure Handling
- If Drive upload fails → retry + alert
- If GitHub commit fails → retry + queue
- If doc generation fails → do not block Qwrk save

Failures must never corrupt or block core Qwrk operations.

---

## 11. Security & Access
- Docs inherit the security posture of the GitHub repo
- No secrets or credentials rendered into Markdown
- Sensitive payloads must be redacted or summarized

---

## 12. Open Design Questions (Clarification Needed)
These should be resolved before build:

1. **Trigger taxonomy**
   - Exact allow-list of `artifact_type` / tags that trigger docs?
2. **Timing**
   - Immediate on save vs queued batch processing?
3. **Naming convention**
   - File naming scheme (date-first vs artifact-first)?
4. **Overwrite vs append**
   - New file per trigger or append to rolling docs?
5. **Summarization threshold**
   - What size (KB) triggers summarization?
6. **Commit strategy**
   - One commit per doc or grouped commits?

---

## 13. Success Criteria
- CC can operate for weeks without manual re-briefing
- GitHub accurately reflects operational reality
- No significant behavioral change occurs without a corresponding doc
- Restarting work never requires archaeology

---

## 14. Future Enhancements (Out of Scope)
- Bi-directional sync (GitHub → Qwrk)
- Auto-generated diagrams
- Ranger-specific filtered views
- Per-user doc scopes
