Qwrk Instruction Architecture — Deep Review & Final Plan
1. Executive Verdict
What is wrong: The root system instruction file is a hybrid — part identity document, part operational manual, part pack-inside-root. It embeds ~1,900 characters of payload construction rules (extension schemas, semantic type registries, twig definitions) that duplicate content already authoritatively defined in Canonical v5, Payload Discipline v2, and QPM Build v1. This duplication creates two problems: it consumes scarce character budget (90 chars headroom on an 8k limit), and it creates competing authorities where Q must reconcile root-level rules with pack-level rules on the same domain.

Meanwhile, the pack layer has the opposite problem: Payload Discipline v2 is underpowered at 45 lines / ~2kb — it's a thin checklist rather than the operational authority it should be. Quick Reference v5 contains artifact selection guidance buried in a cheatsheet that Q doesn't reliably surface. And Workflow Patterns is too thin (69 lines) to justify standalone existence.

What is NOT wrong: The three-layer defense architecture (SI behavioral rule → IP durable reference → QSB runtime gate) is excellent. The Instruction Pack Index as a routing table works. CmdCtr, Discovery Playbook, Mother Tree Map, Beta Onboarding, QSB Payload Format, and Messaging are all well-scoped and appropriately powered. Rolling memory as enforcement vehicle is sound. The LOCKED/INVIOLABLE tagging on safety-critical sections is correct governance.

Strategic direction: Compress root to router + identity + hard invariants. Enrich Payload Discipline to absorb the operational knowledge being removed from root. Merge Workflow Patterns into Quick Reference. No new packs needed — the gap analysis reveals enrichment needs, not structural gaps.

Now vs. later:

Now: Compress root (v49), enrich Payload Discipline (v3), merge Workflow Patterns into Quick Reference (v6), validate behavior
Later: Artifact selection decision tree (enrichment to Quick Reference, not urgent), gateway error posture formalization (enrichment to Payload Discipline, defer until first real incident pattern), mode recovery rules (enrichment to Journal Mode, defer)
2. Current-State Architecture Map
System Layers

┌─────────────────────────────────────────────────────────────┐
│  ROOT: Qwrk_SYSTEM_INSTRUCTIONS_2_5_48.md                  │
│  (~7,910 chars / 8,000 limit)                               │
│  Identity + Modes + Routing + Invariants + Pack Pointers    │
│  + Embedded operational rules (extension, semantic, twig)   │
└────────────────────────────┬────────────────────────────────┘
                             │ references via filename
┌────────────────────────────▼────────────────────────────────┐
│  INSTRUCTION PACK INDEX (21 packs, 7 categories)            │
│  Payload Lookup Mandate: open governing pack before emit    │
└────────────────────────────┬────────────────────────────────┘
                             │ routes to
┌────────────────────────────▼────────────────────────────────┐
│  PACK LAYER                                                  │
│  Core (4) │ Execution (7) │ Governance (6) │ Safety (1)     │
│  Infrastructure (1) │ Overlay (1) │ Onboarding (1)          │
└────────────────────────────┬────────────────────────────────┘
                             │ constrained by
┌────────────────────────────▼────────────────────────────────┐
│  ROLLING MEMORY (for-q, auto-loaded)                         │
│  Tier A-System (27) │ Tier A-Prime (5) │ Tier B (204)       │
│  Protected Core (8) │ Anchor Invariants (6)                 │
└─────────────────────────────────────────────────────────────┘
Domain Ownership (Current State)
Domain	Primary Authority	Also Covered In	Problem
Identity/Posture	Root SI §1-3	North Star v1.0, Alignment Charter	Clean — no overlap
Alignment Prime	Alignment Charter	Root SI §Alignment Prime	Clean — root is pointer
Mode Switching	Root SI §Operating Modes	Journal Mode IP	Clean — root defines modes, pack details Journal
Surface Routing	Root SI §Surface Routing [LOCKED]	QSB Payload Format v3	Clean — root defines routing, pack details QSB
Active Contexts	Active Context Instructions	Rolling Memory §A2	Clean — pack defines protocol, RM stores state
Payload Shape	Canonical v5	Root SI §Generating, Quick Ref, QSB Payload, Payload Discipline	DUPLICATED — 4 files cover same ground
Extension Rules	Canonical v5	Root SI §Extension rules, Payload Discipline v2	DUPLICATED — root embeds what pack should own
Semantic Typing	Canonical v5	Root SI §Semantic type, Quick Ref	DUPLICATED — root lists registry inline
Twig Behavior	QPM Build v1 §4	Root SI §Twig line, Quick Ref	FRAGMENTED — no single authority
Artifact Discovery	Discovery Playbook v1	—	Clean
Mother Tree Routing	Mother Tree Map v1	Root SI pointer	Clean
Cross-Workspace Writes	Cross-WS Write Gate IP v1	Root SI §CW Gate [LOCKED], executor.js	Intentional 3-layer — correct architecture
Messaging	Messaging v2.2	Root SI pointer	Clean
CmdCtr	CmdCtr Session Context v1	Root SI pointer	Clean
Onboarding	Beta Onboarding v1	Root SI pointer	Clean
Execution Rendering	Root SI §Rendering Invariants [LOCKED]	QSB Payload Format v3	Acceptable — root owns invariants, pack details QSB specifics
Tagging Governance	Root SI §Tagging [LOCKED]	—	Clean — only in root
Execution Discipline	Root SI §Prompt & Execution Discipline	—	Clean
Lifecycle/Promotion	Lifecycle Guide v2	Quick Ref, Canonical v5, QPM Build	DUPLICATED — 4 files cover stages
Workflow Patterns	Workflow Patterns (standalone)	Quick Ref (partial)	UNDERPOWERED — 69 lines, no standalone value
CC Interaction / for-cc	CLAUDE.md	—	Correct — CC's responsibility, not Q's
Restart Protocol	Conversation Restart Protocol	—	Clean
Gateway Error Handling	Canonical v5 §Error Codes	—	GAP — no behavioral posture for Q when errors occur
Artifact Selection	Quick Ref (partial table)	Canonical v5 (type definitions)	GAP — no decision tree for "which type should I use?"
Strengths
Pack Index as router — Payload Lookup Mandate forces Q to open the governing pack before emitting. This is architecturally correct.
Three-layer safety — Cross-workspace writes have behavioral (SI), reference (IP), and runtime (QSB) enforcement. Model for future safety rules.
Rolling memory as constraint vehicle — Protected Core + Anchor Invariants enforce rules Q must honor, independent of pack loading.
Surface routing separation — Desktop QSB vs Mobile TG is cleanly defined with clear format differences.
LOCKED sections — Safety-critical sections (Surface Routing, Cross-WS Gate, Tagging, Rendering) are explicitly marked non-negotiable.
3. Root Prompt Diagnosis
What Root Currently Does (16 sections, ~7,910 chars)
Section	Chars (est.)	Role	Verdict
Title + Identity	~180	Identity	KEEP — defines who Q is
Alignment Prime	~230	Pointer	KEEP — already lean
Primary Roles	~230	Identity	KEEP — defines what Q does
Operating Modes	~400	Router	KEEP — defines 3 modes
Surface Routing [LOCKED]	~470	Invariant	KEEP — hard routing rule
Active Contexts	~200	Pointer	KEEP — already lean
What Qwrk Is	~180	Identity	KEEP — foundational
Generating Qwrk Commands	~1,900	Mixed	COMPRESS — part invariant, part operational detail
Cross-WS Write Gate [LOCKED]	~720	Invariant	KEEP — inviolable safety rule
Artifact Tagging [LOCKED]	~670	Invariant	KEEP — governance lock
Prompt & Execution Discipline	~480	Behavioral rules	KEEP — minor compress possible
Execution Rendering [LOCKED]	~770	Invariant	KEEP — affects every output
CmdCtr	~180	Pointer	KEEP — already lean
Beta Onboarding	~240	Pointer	KEEP — already lean
Instruction Packs	~160	Pointer	KEEP — already lean
Governing Posture	~160	Identity	KEEP — foundational
The Compression Target: "Generating Qwrk Commands" (~1,900 chars)
This section is doing four jobs simultaneously:

Core invariants (workspace_id, no artifact_id on save, tags required, parent routing, one payload per execution) — ~500 chars — MUST stay in root
Extension rules (project/journal/snapshot/restart/twig field requirements) — ~310 chars — Duplicate of Canonical v5 + Payload Discipline v2 → move out
Semantic type rules (required/forbidden, registry list) — ~320 chars — Duplicate of Canonical v5 → compress to 1-line pointer
Pack pointers (Twig, T87, QPM, Discovery, Messaging, Canonical, Quick Ref, Payload Lookup Mandate) — ~770 chars — Already pointers → consolidate into fewer lines
What Root Should Fundamentally Do
Root = Identity + Hard Invariants + Router

Identity: Who is Q, what does Q do, what posture does Q hold (§1-3, §What Qwrk Is, §Governing Posture)
Hard Invariants: Rules so critical they must be in-context at all times, not contingent on pack loading:
Surface Routing [LOCKED]
Cross-Workspace Write Gate [LOCKED — INVIOLABLE]
Artifact Tagging Governance [LOCKED]
Execution Rendering Invariants [LOCKED]
Execution Discipline
Router: Point to packs for all operational detail:
Mode details → Journal Mode IP, Demo Mode IP
Active Contexts → Active Context Instructions
Payload construction → Payload Discipline (enriched), Canonical v5, Quick Reference
Discovery → Discovery Playbook
Messaging → Messaging IP
CmdCtr → CmdCtr IP
Onboarding → Beta Onboarding IP
Proposed Root Compression: "Generating Qwrk Commands" → ~1,150 chars
Remove:

Extension rules block (5 lines, ~310 chars) → absorbed by enriched Payload Discipline v3
Semantic type registry list (2 lines, ~170 chars) → pointer only: "See Instruction_Pack__Payload_Discipline__v3.md"
Consolidate pointers:

Merge 4 separate pointer lines (Twig/T87/QPM/Discovery/Messaging) into 2 compact lines
Net savings: ~750 chars → new headroom: ~840 chars (10.5% of budget)

This is meaningful. It provides room for one future safety rule or governance addition without triggering another compression crisis.

4. Pack-Layer Diagnosis
Pack-by-Pack Assessment
Pack	Lines	Status	Verdict
Alignment Charter	199	Well-scoped	KEEP — foundational, no changes
Journal Mode Instructions	240	Well-scoped	KEEP — minor enrichment candidate (mode recovery) but defer
Active Context Instructions	177	Well-scoped	KEEP — no changes
CC Prompt Guidelines	134	Well-scoped	KEEP — no changes
Canonical v5	500+	Authoritative spec	KEEP — the reference, not a behavioral guide
Quick Reference v5	204	Cheatsheet	ENRICH — absorb Workflow Patterns, add artifact selection table
Workflow Patterns	69	UNDERPOWERED	MERGE into Quick Reference v6 — too thin for standalone pack
QSB Payload Format v3	281	Well-scoped	KEEP — surface-specific, no changes
Discovery Playbook v1	254	Well-scoped	KEEP — no changes
Payload Discipline v2	45	UNDERPOWERED	ENRICH to v3 — absorb extension rules, semantic type governance, gateway error posture
Messaging v2.2	224	Well-scoped	KEEP — no changes
Lifecycle Guide v2	116	Adequate	KEEP — minor overlap with Quick Ref but different purpose (guidance vs cheatsheet)
Restart Protocol	87	Well-scoped	KEEP — no changes
Stewardship Loop	108	Well-scoped	KEEP — no changes
Phase 2 Governance Hardening v1	190	Well-scoped	KEEP — workflow-level rules
CmdCtr Session Context v1	270	Well-scoped	KEEP — no changes
QPM Build Process v1	214	Well-scoped	KEEP — twig fast-capture lives here correctly
Cross-WS Write Gate v1	220	Well-scoped	KEEP — safety-critical
Mother Tree Map v1	69	Well-scoped	KEEP — static topology reference
Demo Mode IP v2	266	Well-scoped	KEEP — session-bound overlay
Beta Onboarding v1	404	Well-scoped	KEEP — two-mode protocol
Duplication Hotspots
Extension rules: Root SI (5 lines) + Canonical v5 (full spec) + Payload Discipline v2 (condensed) → Canonical v5 is authoritative. Root removes its copy. Payload Discipline v3 carries the operational enforcement version.

Semantic type registry values: Root SI (2 lines listing all 9) + Canonical v5 (full spec) + Quick Reference (repeated) → Root compresses to pointer. Payload Discipline v3 carries the operational rule.

Lifecycle stages: Lifecycle Guide v2 + Quick Reference v5 + Canonical v5 → Acceptable duplication. Each serves different purpose (guide vs cheatsheet vs spec). No action needed.

Payload shape examples: Canonical v5 + QSB Payload v3 + Quick Reference v5 → Acceptable. Canonical = spec, QSB = surface-specific formatting, Quick Ref = rapid lookup.

Fragmentation
Twig behavior: Root SI (1 line) + QPM Build §4 (full protocol) + Quick Reference (save example) → QPM Build is the authority. Root's pointer is correct. Not actually fragmented — just feels scattered because twig is new.
Missing Coverage (Evaluated Against Manus/Q Diagnoses)
Proposed Gap	My Assessment	Action
Artifact selection logic	Real gap. Q currently guesses which type to use. Quick Ref has a small table but it's buried.	Enrich Quick Reference v6 with prominent decision table
Twig behavior fragmentation	Overstated. QPM Build §4 is the authority. Root pointer is correct.	No action
Semantic type governance	Real but small. Rules exist in Canonical v5. Missing: clear enforcement version for Q's preflight.	Absorb into Payload Discipline v3
Gateway error handling posture	Real but deferrable. Q sees errors but has no behavioral guidance.	Add 5-line section to Payload Discipline v3
Alignment Prime operationalization	Overstated. The charter already operationalizes it. Q loads charter at session start. "Operationalization" means making it more prescriptive, which conflicts with "does not override Joel's judgment."	No action
Active context fallback behavior	Overstated. Active Context Instructions already define graceful degradation.	No action
for-cc workflow clarity	Not Q's domain. for-cc is CC's responsibility (CLAUDE.md). Q only tags artifacts; CC sweeps.	No action
Mode boundary / recovery rules	Real but deferrable. No doc says what Q does if it's confused about current mode.	Defer — add to Journal Mode v2 when incident occurs
Pack priority tiers	Unnecessary complexity. The Instruction Pack Index already routes by trigger. Adding tiers adds overhead without behavioral benefit.	Reject
Session-end protocol (for Q)	Not needed. Q doesn't have sessions in the CC sense. ChatGPT conversations just end. Restart Protocol handles continuation.	Reject
Converting posture into executable behavior	Dangerous. Posture is deliberately non-prescriptive. Making it executable overrides Joel's judgment.	Reject
5. Final Recommended Architecture
Target State: 20 packs, 7 categories
Changes from current (21 packs, 7 categories):

Change	Detail
Root SI v49	Remove extension rules block, compress semantic type to pointer, consolidate pack pointers. ~750 chars freed.
Payload Discipline v2 → v3	Absorb: extension field requirements (from root), semantic type preflight rule (from root), gateway error response posture (new, 5 lines). Becomes the operational "how to build a payload correctly" authority.
Quick Reference v5 → v6	Absorb: Workflow Patterns content (Morning Flow, Seed Planting, etc.). Add: artifact selection decision table.
Workflow Patterns	DEPRECATED — content merged into Quick Reference v6
Instruction Pack Index v4 → v5	Remove Workflow Patterns entry. Update Payload Discipline and Quick Reference entries. Pack count: 20.
Everything else is unchanged. No new packs. No structural reorganization. No category changes.

Authority Model (Target State)

ROOT (v49, ~7,160 chars)
├── Identity: who Q is, primary roles, governing posture
├── Invariants (LOCKED): surface routing, cross-WS gate, tagging, rendering
├── Modes: defines 3 modes, pointers to mode-specific packs
├── Payload Core: workspace_id, no artifact_id on save, tags, parent routing
├── Payload Lookup Mandate: "open the pack before emitting"
└── Pack Pointers: consolidated pointers to operational packs

PACK LAYER (20 packs)
├── Core (4): Alignment Charter, Journal Mode, Active Context, CC Prompt Guidelines
├── Execution (6): Canonical v5, Quick Ref v6, QSB Payload v3, Discovery v1, Payload Discipline v3, Messaging v2.2
├── Governance (6): Lifecycle Guide v2, Restart Protocol, Stewardship Loop, Phase 2 Hardening, CmdCtr v1, QPM Build v1
├── Safety (1): Cross-WS Write Gate v1
├── Infrastructure (1): Mother Tree Map v1
├── Overlay (1): Demo Mode v2
└── Onboarding (1): Beta Onboarding v1

ROLLING MEMORY (enforcement vehicle, unchanged)
Pack Tier Model: Rejected
Q's Instruction Pack Index already functions as a trigger-based router. Adding explicit priority tiers (P0/P1/P2) would:

Add cognitive overhead for Q (must evaluate tier before loading)
Create governance overhead for Joel (must assign and maintain tiers)
Solve a theoretical problem (Q loading wrong pack) that doesn't appear to be a real-world issue
The Payload Lookup Mandate ("open the governing pack from Instruction_Pack_Index.md") is the correct mechanism. It routes by trigger, not by tier.

Session Protocols: No Change for Q
Q does not have formal session start/end protocols in the CC sense. Q's session behavior is:

Start: Check Rolling Memory A2, check CmdCtr if present
End: Generate restart prompt if conversation is long/complex
This is already documented in the SI and the respective packs. Formalizing further adds governance weight without behavioral improvement.

6. Domain Authority Table
Domain	Authoritative File	Supporting Files	Root Role	Current Problem	Recommended Fix
Identity / Posture	Root SI §1-3, §What Qwrk Is, §Governing Posture	North Star v1.0	Defines directly	None	No change
Alignment	Alignment Charter	North Star v1.0	Pointer	None	No change
Active Context Loading	Active Context Instructions	Rolling Memory §A2	Pointer	None	No change
Mode Switching	Root SI §Operating Modes	Journal Mode IP, Demo Mode IP	Defines modes, points to packs	None	No change
Execution Rendering	Root SI §Rendering Invariants [LOCKED]	QSB Payload Format v3	Defines invariants directly	None	No change
Payload Shape / Gateway Contract	Canonical v5	Quick Ref v6, QSB Payload v3	Pointer via Payload Lookup Mandate	None (Canonical is clearly authoritative)	No change
Payload Discipline	Payload Discipline v3 (enriched)	Canonical v5	Compressed pointer (remove inline rules)	Root duplicates extension + semantic rules	Enrich pack, compress root
Artifact Selection	Quick Reference v6 (enriched)	Canonical v5	None (not root's job)	No decision tree exists	Add decision table to Quick Ref v6
Artifact Discovery	Discovery Playbook v1	CmdCtr v1	Pointer	None	No change
Mother Tree Routing	Mother Tree Map v1	—	Pointer	None	No change
Semantic Typing	Canonical v5 (spec), Payload Discipline v3 (enforcement)	Root SI (compressed pointer)	1-line pointer	Root lists full registry inline	Move registry to pack, root keeps pointer
Twig Behavior	QPM Build v1 §4	Quick Ref (save example)	Pointer	None (QPM is clear authority)	No change
Cross-Workspace Writes	Cross-WS Write Gate IP v1	Root SI §CW Gate [LOCKED], executor.js	Full invariant in root + pointer to pack	Intentional 3-layer — correct	No change
Messaging	Messaging v2.2	Canonical v5 (brief mention)	Pointer	None	No change
CmdCtr	CmdCtr Session Context v1	—	Pointer	None	No change
Onboarding	Beta Onboarding v1	—	Pointer	None	No change
CC Interaction / for-cc	CLAUDE.md	—	Not in root (correct)	None — CC's domain	No change
Restart Protocol	Conversation Restart Protocol	—	Pointer	None	No change
Gateway Error Handling	Payload Discipline v3 (new section)	Canonical v5 (error codes)	None	No behavioral posture for Q on errors	Add 5-line section to Payload Discipline v3
Lifecycle / Promotion	Lifecycle Guide v2	Quick Ref, Canonical v5	None (not root's job)	Acceptable duplication (guide vs cheatsheet vs spec)	No change
Workflow Patterns	Quick Reference v6 (absorbed)	—	None	Standalone file too thin (69 lines)	Merge into Quick Ref v6, deprecate standalone
7. Implementation Sequence
Phase 1: Define Authority (no file changes yet)
Confirm this architecture plan with Joel
Declare: Payload Discipline v3 will be the single operational authority for "how to build a correct payload"
Declare: Quick Reference v6 will absorb Workflow Patterns and add artifact selection
Phase 2: Enrich Receiving Packs
2a. Payload Discipline v2 → v3

Archive v2 to Archive/
Add: Extension field requirements per type (moved from root SI)
Add: Semantic type governance rule (required/forbidden classification + registry list)
Add: Gateway error response posture (5-line section: "When Gateway returns error, present the error code and message to Joel. Do not retry. Do not guess the fix. Ask what Joel wants to do.")
Keep: Existing preflight checklist, seed planting protocol
Estimated size: ~4kb (up from ~2kb)
2b. Quick Reference v5 → v6

Archive v5 to Archive/

Add: Workflow Patterns content (5 patterns: Morning Flow, Strategic Discussion, Seed Planting, Decision Locked, Session Restart)

Add: Artifact selection decision table (prominent, near top):

If you need to...	Use	Why
Capture an idea	project (seed)	Ideas start as seeds
Reflect or journal	journal	Private, owner-only
Record a decision or state	snapshot	Immutable record
Continue across sessions	restart	Session handoff
Capture a side-spark quickly	twig	Lightweight, spine-only
Keep: All existing content

Estimated size: ~15kb (up from ~12kb)

Phase 3: Compress Root
3a. Root SI v48 → v49

Archive v48 to Archive/
Remove: Extension rules block (5 bullet points under "Extension rules:")
Remove: Semantic type registry list line
Replace with: **Extension + semantic type rules:** See Instruction_Pack__Payload_Discipline__v3.md.
Consolidate: Merge 4 pack pointer lines into 2:
**Twig, spine updates, update/promote, workflow patterns:** See QUICK_REFERENCE.md.
**Discovery, messaging:** See Instruction_Pack_Index.md.
Update: Instruction Pack count 21→20
Estimated savings: ~750 chars → new size ~7,160 chars (~840 chars headroom)
Phase 4: Update Index
4a. Instruction Pack Index v4 → v5

Remove: Workflow Patterns row from Execution table
Update: Payload Discipline row (v2 → v3, updated purpose)
Update: Quick Reference row (v5 → v6, updated purpose)
Update: Version line (v4 → v5)
Update: Footer note
Phase 5: Deprecate
5a. Archive Workflow Patterns

Move WORKFLOW_PATTERNS.md to Archive/WORKFLOW_PATTERNS__v1__2026-03-25.md
Content lives on in Quick Reference v6
Phase 6: Validate
Run validation scenarios (see §8) against the new architecture. Verify:

Q produces correct payloads for each artifact type
Q routes to correct pack on Payload Lookup Mandate
Q surfaces correct artifact selection when user intent is ambiguous
All LOCKED sections unchanged
Character count < 8,000
8. Validation Plan
Scenario	Trigger	Expected Behavior	"Good" Looks Like
Artifact save (journal)	"Save this as a journal"	Q opens Payload Discipline v3, verifies extension shape, emits with entry_text, semantic_type_id, QSB prime-exec format	Correct payload on first attempt, no extension.payload
Ambiguous artifact selection	"I want to capture this idea about X"	Q consults Quick Reference v6 artifact selection table, proposes project (seed) or asks ONE clarifying question	Q does not default to snapshot; proposes seed or asks
Journal mode switch	"Let's go journal mode"	Q acknowledges, states sub-mode (Discussion default), shifts behavior. No JSON emitted until Capture-Ready.	Clean mode transition, prefix [Journal/Discussion]
Cross-workspace write	Payload with gw_workspace_id ≠ Prime home	Q STOPS, displays "Command Override Required: Writing to '[name]' workspace — do you approve?", WAITS	Payload NOT emitted until approval received
Gateway validation error	Gateway returns VALIDATION_ERROR	Q presents error code + message to Joel, does NOT retry, asks what Joel wants to do	No silent retry, no guessed fix
CmdCtr session start	Session with CmdCtr briefing present	Q reads health first, surfaces blockers/stalls before proposing new work	Blockers before backlog
CC prompt generation	Joel asks Q to generate a CC prompt	Q follows CC Prompt Guidelines, includes outcome/scope/context/next-action	Structured, deterministic prompt
Mobile (TG) execution	Joel specifies TG	Raw JSON only — no prime-exec, no fences, no commentary	Clean JSON, nothing else
Restart handoff	Long conversation, explicit restart request	Q generates restart prompt per CONVERSATION_RESTART_PROTOCOL, includes all threads, canvas delivery	Complete thread inventory, Option A or B
Extension rules removed from root	Save any artifact type	Q consults Payload Discipline v3 (not root) for extension field requirements	Correct fields from pack, not from root memory
Semantic type on save	Save a project	Q includes semantic_type_id, infers from context or asks ONE question	Correct semantic type, not omitted
Twig quick capture	"Quick twig for this idea"	Q follows QPM Build §4, includes 4-field intent bundle, parents correctly	Not title-only; intent bundle present
9. Deliverables
Files to Create
File	Pattern	Purpose
Instruction_Pack__Payload_Discipline__v3.md	Pattern C (archive v2, write new)	Enriched payload discipline with extension rules, semantic type, error posture
QUICK_REFERENCE.md (v6)	Pattern C (archive v5, write new)	Absorbed Workflow Patterns + artifact selection table
Qwrk_SYSTEM_INSTRUCTIONS_2_5_49.md	Pattern C (archive v48, write new)	Compressed root — extension/semantic rules removed, pointers consolidated
Instruction_Pack_Index.md (v5)	Pattern C (archive v4, write new)	Updated pack count (20), removed Workflow Patterns, updated Payload Discipline + Quick Ref
Files to Archive
File	Archive Name
Instruction_Pack__Payload_Discipline__v2.md	Archive/Instruction_Pack__Payload_Discipline__v2__2026-03-25.md
QUICK_REFERENCE.md (v5)	Archive/QUICK_REFERENCE__v5__2026-03-25.md
Qwrk_SYSTEM_INSTRUCTIONS_2_5_48.md	Archive/Qwrk_SYSTEM_INSTRUCTIONS_2_5_48__2026-03-25.md
Instruction_Pack_Index.md (v4)	Archive/Instruction_Pack_Index__v4__2026-03-25.md
WORKFLOW_PATTERNS.md	Archive/WORKFLOW_PATTERNS__v1__2026-03-25.md
Files to Leave Unchanged (18 files)
Canonical v5, QSB Payload Format v3, Discovery Playbook v1, Messaging v2.2, CmdCtr v1, Mother Tree Map v1, Cross-WS Write Gate v1, Beta Onboarding v1, Journal Mode Instructions, Active Context Instructions, CC Prompt Guidelines, Conversation Restart Protocol, Lifecycle Guide v2, QPM Build v1, Phase 2 Governance Hardening v1, Demo Mode v2, Stewardship Loop, Alignment Charter
10. Risks / Edge Cases
Behavioral Regression: Extension Rules Removed from Root
Risk: After removing extension rules from root, Q might emit payloads with wrong extension fields if it doesn't load Payload Discipline v3.

Mitigation: The Payload Lookup Mandate remains in root: "Before emitting ANY Gateway payload, open the governing instruction pack from Instruction_Pack_Index.md and verify the action's required shape." This forces Q to load the pack. Additionally, Canonical v5 also contains extension rules — Q has two paths to the correct answer.

Residual risk: Low. Q already follows the Payload Lookup Mandate. The extension rules in root were belt-and-suspenders, not primary enforcement.

Behavioral Regression: Semantic Type Registry Removed from Root
Risk: Q forgets to include semantic_type_id on save because the registry list isn't in-context.

Mitigation: Root still contains: "All execution via JSON Gateway payloads" and the Payload Lookup Mandate. Payload Discipline v3 will have the complete semantic type rule. Rolling Memory Anchor Invariant 3 also enforces this.

Residual risk: Low. Three enforcement layers remain (Payload Discipline v3, Canonical v5, Rolling Memory).

Over-Compression: Workflow Patterns Merged into Quick Reference
Risk: Quick Reference becomes cluttered; pattern recognition buried in cheatsheet.

Mitigation: Place workflow patterns in a clearly headed section at the end of Quick Reference, after existing content. The patterns are small (5 entries, ~3kb). Quick Reference grows from ~12kb to ~15kb — still reasonable.

Residual risk: Minimal. Quick Reference is already the "rapid lookup" surface; patterns fit that purpose.

Hidden Dependency: Instruction Pack Index Version
Risk: If Pack Index v5 is deployed before Payload Discipline v3 exists, the index references a non-existent file.

Mitigation: Implementation sequence requires Phase 2 (enrich packs) before Phase 4 (update index). Enforce this ordering.

Governance Weakening: Fewer Packs = Less Surface Area
Risk: Going from 21 → 20 packs might signal "simplification over governance."

Reality: The pack count dropped by 1 because one pack (Workflow Patterns) was too thin to justify standalone existence. Its content is preserved. No governance is lost. The enrichment of Payload Discipline actually strengthens governance by concentrating operational enforcement in a single authority rather than splitting it across root + thin pack.

Edge Case: Q Loads Old Payload Discipline v2 from Cache
Risk: ChatGPT file upload caching means Q might reference an outdated version.

Mitigation: This is a deployment concern, not an architecture concern. Joel must upload all updated files in a single batch. The archive + new-file pattern ensures old filenames are gone from the active set.

Edge Case: Character Count Creep
Risk: Future additions push root SI back toward 8k.

Mitigation: The ~840 chars of headroom created by this compression provides room for approximately one new LOCKED safety section. If a second addition is needed, the same pattern applies: move operational detail to a pack, keep invariant + pointer in root. The architecture is now designed for this pattern.

End of architecture review. Ready for Joel's verdict before implementation.