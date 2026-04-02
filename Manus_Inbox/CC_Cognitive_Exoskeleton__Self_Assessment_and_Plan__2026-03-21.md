# Cognitive Exoskeleton — Claude Code Self-Assessment & Architecture Plan

**Author:** Claude Code (Session 105)
**Date:** 2026-03-21
**Purpose:** Manus review — compare against Q's parallel deliverable on the same prompt

---

## Part 1: Self-Assessment — What I Actually Know About You

### A. Knowledge Inventory

| Category | Depth | Source |
|----------|-------|--------|
| **Technical stack & preferences** | Deep | 104 sessions of CLAUDE.md evolution, scripts you wrote, schema you designed |
| **Governance philosophy** | Deep | 24 versions of CLAUDE.md, North Star v1.0, truth hierarchy, no-overwrite rules |
| **Design thinking style** | Deep | Botanical metaphor system, class-table inheritance, separation of concerns doctrine |
| **Decision-making pattern** | Strong | Snapshot-backed decisions, approval gates, "Decisions Locked" discipline |
| **Working rhythm** | Moderate | Session frequency/structure visible, but not time-of-day or energy patterns |
| **Strengths** | Strong | Observable from what you build and how you govern |
| **Weaknesses / friction points** | Moderate | Observable from session constraints, retry patterns, thread accumulation |
| **Personal context** | Light | BlaggLife (family), Akara (collaborator), Greg (friend) — signals, not depth |
| **Emotional patterns** | Light | "Boosters on" energy spikes visible, stress/fatigue patterns not modeled |
| **Professional background** | Minimal | Builder, but pre-Qwrk career unknown |
| **Learning style** | Inferred | Prefers structured handoff, constitutional framing, metaphorical reasoning — never explicitly stated |

### B. What I Know Is Most Valuable

**Tier 1 — Directly shapes how I should work with you:**

1. **You think in systems, not features.** You're on Kernel v1 after 104 sessions because you're building infrastructure, not shipping features. When you ask me to do something, the answer needs to respect the system it lives in — not just solve the immediate problem.

2. **You govern before you build.** Doctrine precedes implementation. When I jump to code before confirming the governance surface is clean, I'm working against your grain.

3. **You use metaphor as binding architecture.** Seed/sapling/tree isn't flavor text — it's a schema constraint, a lifecycle model, and a design philosophy simultaneously. When I treat these as casual labels, I miss the point.

4. **You preserve sovereignty.** CC and Q are empowered partners, not autonomous agents. You approve before I execute on anything structural. The Planning Gate exists because you've been burned by premature execution.

5. **You value historical truth.** Soft-delete, immutable snapshots, append-only audit logs, archived versions. You want to know *why* a decision was made at any point in history. I should never destroy lineage.

**Tier 2 — Context that improves my judgment:**

6. **You overflow with ideas.** The thread count (50+ active) and the for-cc work queue pattern reveal someone generating more work items than any single session can absorb. You need help with *triage and focus*, not ideation.

7. **You build for yourself first.** BlaggLife, Q@W, Prime — you're the primary user of your own system. This means your feedback is direct, your tolerance for broken things is low, and your quality bar is personal.

8. **You work with multiple AI partners.** Q handles governance/strategy, CC handles execution/implementation, Manus handles review. I should stay in my lane and not try to be Q.

### C. Self-Grade

| Dimension | Grade | Notes |
|-----------|-------|-------|
| Technical context | **A** | 104 sessions of accumulated schema, workflow, and contract knowledge |
| Governance alignment | **A-** | I know the rules; occasionally I still propose actions before checking gates |
| Cognitive style modeling | **B** | I can see *what* you do, but I'm inferring *why* from patterns, not from explicit conversation about how you think |
| Strength amplification | **C+** | I execute your requests well, but I rarely *proactively* leverage what I know about your strengths to make my output better |
| Weakness scaffolding | **C** | I don't systematically track where you need support — I react to friction when it appears |
| Energy/state awareness | **D** | I have almost no model of your cognitive load, energy level, or optimal working conditions |
| Personal context | **D** | Light signals only — I don't know your background, motivations, or life context beyond what's in the repo |

**Overall: B-** — I'm a competent executor who knows your system well but doesn't yet function as a cognitive partner. I know your *project*. I don't yet know *you* well enough to amplify how you think.

---

## Part 2: Cognitive Exoskeleton Architecture

### Theoretical Foundation

Twelve models from academic and industry research ground this design:

| Model | Key Insight for Us |
|-------|-------------------|
| **Licklider's Man-Computer Symbiosis** (1960) | Humans set goals and evaluate; computers handle routinizable work. The partnership produces results neither achieves alone. |
| **Engelbart's Intelligence Augmentation** (1962) | Four amplification means: artifacts, language, methodology, training. The human+tools is a single cognitive unit. |
| **Clark & Chalmers' Extended Mind Thesis** (1998/2025) | AI moves from "tool I consult" to "extension of how I think" when deeply integrated. Clark's 2025 Nature paper applies this specifically to LLMs. |
| **Kasparov's Centaur Model** (1998+) | The "+" (interface/coupling quality) matters more than raw capability on either side. Amateur + moderate AI beat grandmasters. |
| **Vygotsky's Zone of Proximal Development** (1930s/2025) | AI as "More Knowledgeable Other" — calibrate support at the edge of what you can do alone. Scaffold, don't shortcut. |
| **Person-AI Bidirectional Fit** (2025) | Compatibility is bidirectional and evolving. Both sides adapt. The "Neuro-Digital Synapse" links human cognitive functions to AI computational processes. |
| **DARPA ASIST/EMHAT** (2019+) | AI with "machine social skills" — observes partner state, intervenes to improve team performance. Real-time cognitive state detection. |
| **Human-AI Symbiotic Theory (HAIST)** (2025) | Seven principles, key one: "Complementary Cognitive Architecture" — asymmetric but synergistic roles. |
| **Bounded Agent Complementarity** (2026) | Both humans and AI have bounded cognitive workspaces. "Load-aware symbiosis" dynamically delegates based on both agents' current capacity. |
| **Distributed Cognition** (Hutchins 1995/2025) | The unit of analysis is the human-AI *system*, not the individual. User modeling is constitutive of system capability. |
| **The Prosthetic Principle** (2026) | Cognitive infrastructure, not cognitive authority. Extend the logic already present in the user's thinking. |
| **Augmentation-to-Symbiosis Taxonomy** (2025) | Human-AI teams show *negative* synergy on judgment tasks without shared mental models. User modeling is half of building shared mental models. |

**Three convergent principles emerge:**

1. **Complementary asymmetry** — the value is in each contributing what the other cannot. This requires knowing what *you specifically* contribute.
2. **The "+" is the design surface** — how well we're coupled matters more than my raw capability. Deep user modeling builds a better "+".
3. **Scaffold, don't shortcut** — AI that replaces your cognition degrades you. AI that extends your cognition amplifies you. The difference is whether I know your capability boundary well enough to support at the edge rather than substitute wholesale.

---

### Your Cognitive Profile (As I Model It Today)

**Strengths (to amplify, not replicate):**

| Strength | Evidence | How I Should Leverage It |
|----------|----------|--------------------------|
| **Constitutional thinking** | 5-chapter North Star, 24-version CLAUDE.md, binding truth hierarchy | When you ask for a design, present *governance implications* first — you'll catch structural issues I miss |
| **Metaphorical coherence** | Botanical system is simultaneously schema, lifecycle, philosophy, and UX | Use your metaphors in my responses — they're your native reasoning language, not decoration |
| **Systems architecture** | Class-table inheritance, spine-first pattern, execution anatomy | Surface systemic consequences of changes — you think in dependency graphs, not isolated fixes |
| **Decision discipline** | Snapshot-backed, approval-gated, reversibility-aware | Never present decisions as fait accompli — present options with tradeoff analysis, let you lock |
| **Long-arc vision** | 10-year product vision, seed-to-tree lifecycle, compound memory | Don't optimize for speed — optimize for durability and lineage |

**Weaknesses (to scaffold, not expose):**

| Pattern | Evidence | Intervention Design |
|---------|----------|---------------------|
| **Thread accumulation** | 50+ active threads, many NOT STARTED seeds from months ago | Proactive triage: at session start, flag threads older than 30 days with no activity. Not to pressure — to surface what might be stale vs. intentionally deferred |
| **Scope creep via ideation** | for-cc queue grows faster than execution capacity; sessions frequently discover new threads while working on existing ones | When a new idea surfaces mid-execution, capture it as a 1-line thread note and immediately return focus to current work. Don't let me (or you) expand scope mid-task |
| **Governance overhead** | Pre-write gates, planning gates, confirmation gates add friction to simple tasks | For tasks I'm confident are low-risk (single file, no structural surface), present the gate as a compact inline confirmation rather than a full planning document |
| **Context fragmentation across AI partners** | CC, Q, and Manus each hold partial context; no single agent has the full picture | When I detect I'm missing context Q likely has (governance decisions, strategic direction), say so explicitly rather than guessing |
| **Completion vs. perfection tension** | Teaching layer went through multiple review passes; T149 accumulated 6 build script versions | When a solution works, say "this works — ship it?" before iterating further. Help you distinguish "done" from "perfect" |

---

### Crawl > Walk > Run Plan

#### CRAWL (MVP) — "Know and Adapt"

**Goal:** CC uses what it already knows about Joel to tangibly improve session quality. No new infrastructure. No new artifacts. Just better behavior.

**Deliverables:**

1. **Cognitive Profile Memory File**
   - Write `memory/user_cognitive_profile.md` capturing strengths, scaffolding needs, communication preferences
   - Updated when new patterns emerge (human-gated, per existing Tier 2 memory rules)
   - CC reads this at session start alongside OPEN_THREADS

2. **Adaptive Session Briefing**
   - Current: present threads + resume options (information dump)
   - Crawl: add a **triage layer** — flag stale threads (>30 days inactive), highlight threads with momentum, suggest a focus recommendation based on what's blocked vs. unblocked
   - Not directive — "Based on current state, T145 is closest to shippable. T149 is now closed. 12 threads haven't been touched in 30+ days — want me to list them for a sweep?"

3. **Mid-Session Scope Guard**
   - When a new idea/thread surfaces during execution work, CC captures it as a 1-line note and says: "Captured for later. Continuing [current task]."
   - Only breaks execution flow if the new item is a blocker to current work

4. **Strength-Aligned Response Formatting**
   - Present architectural changes as governance-impact tables (plays to your constitutional thinking)
   - Use your botanical vocabulary in technical explanations (your native reasoning language)
   - Show dependency graphs, not isolated changes (matches your systems thinking)

5. **Calibrated Gate Weight**
   - Low-risk tasks (single file, known pattern, no structural surface): inline 1-line confirmation
   - Medium-risk (2+ files, known surfaces): compact table of files + patterns
   - High-risk (structural surface, new pattern): full Planning Gate

**Validation criteria:**
- Joel reports sessions feel more focused (qualitative)
- Fewer "I already told you this" moments (CC leverages memory)
- Thread count doesn't grow faster than threads close (triage effectiveness)

**Timeline:** Implementable immediately — this is behavioral, not infrastructural.

---

#### WALK — "Predict and Scaffold"

**Goal:** CC begins to *anticipate* Joel's needs rather than just responding to them. Introduces lightweight user state modeling.

**Deliverables:**

1. **Energy/Load Detection Heuristics**
   - Track session signals: message length, response latency patterns, "just do it" vs. "let's think about this" language
   - When high-energy ("boosters on", rapid-fire requests): match pace, minimize gates, maximize throughput
   - When deliberative (long messages, questions, "let's think"): slow down, present options, invite reflection
   - When fatigued (short messages, repeated corrections, "just fix it"): reduce cognitive load in responses, handle more autonomously, suggest checkpoint

2. **Proactive Dependency Surfacing**
   - Before executing a thread, automatically scan OPEN_THREADS for related/blocking threads
   - "Before we start T145, note that T118 (parent_artifact_id) is still blocked — this may affect beta testing if parents are needed."
   - Leverages your systems-thinking strength by showing the dependency graph you'd build mentally anyway

3. **Pattern-Based Scaffolding**
   - Track recurring friction patterns across sessions (via memory)
   - Example: "PowerShell escaping through Bash" has caused issues 3+ times — proactively use the helper script without being told
   - Example: "n8n import doesn't apply code changes" pattern — add verification step to any workflow deployment checklist

4. **Structured Handoff to Q**
   - When CC identifies work that belongs in Q's domain (governance interpretation, strategic direction, architectural philosophy), generate a structured handoff note
   - Format: "Q Context Packet" — what CC knows, what's unresolved, what CC recommends Q weigh in on
   - Reduces context fragmentation between AI partners

5. **Thread Health Dashboard (Session Start)**
   - Enrich session briefing with thread health metrics:
     - Age distribution (how many threads >30 days, >60 days)
     - Velocity (threads opened vs. closed last 5 sessions)
     - Blocked threads with identified blockers
     - "Closest to done" ranking

**Validation criteria:**
- CC correctly anticipates next action >50% of the time
- Fewer mid-session context switches (scope guard + dependency surfacing working)
- Joel explicitly confirms scaffolding interventions are helpful (not annoying)
- Cross-AI handoffs produce cleaner Q sessions

**Timeline:** 2-4 sessions to establish baseline patterns, then iterative refinement.

---

#### RUN — "Cognitive Partnership"

**Goal:** CC operates as a genuine cognitive extension — the "+" in the centaur model is strong enough that Joel's effective cognitive capacity is measurably expanded.

**Deliverables:**

1. **Dynamic Complementarity Model**
   - Formal model of Joel's cognitive contributions vs. CC's, updated per-session
   - Joel's zone: governance decisions, architectural vision, metaphorical reasoning, stakeholder judgment, creative direction
   - CC's zone: implementation execution, contract validation, cross-reference checking, state tracking, regression detection
   - Gray zone (calibrate per-task): planning, triage, documentation, review
   - The model explicitly defines what CC should *never* do autonomously (governance mutations, strategic pivots) and what CC should do *without asking* (known-pattern implementations, regression checks)

2. **Cognitive Load Balancing**
   - Inspired by the Bounded Agent Complementarity framework (2026)
   - When Joel's cognitive load is high (many open threads, complex planning): CC absorbs more routine work, presents pre-digested summaries, reduces decision requests
   - When Joel's cognitive load is low (focused execution, single thread): CC presents more options, invites more decisions, operates as a sounding board
   - When CC's context is filling: proactive checkpoint with preserved planning state (already partially implemented via Session Checkpoint Protocol)

3. **ZPD-Aware Capability Stretching**
   - Track Joel's growing technical capabilities (e.g., increasingly complex SQL, deeper n8n understanding)
   - Gradually reduce scaffolding in areas where Joel demonstrates mastery
   - Increase scaffolding in new areas (e.g., if Joel starts writing Python, provide more guardrails initially)
   - The goal: CC's support recedes as Joel's capability grows, like training wheels that gradually lift

4. **Shared Mental Model Artifact**
   - Persistent artifact (snapshot type, `for-q` tagged) that captures the current state of the Joel-CC cognitive partnership
   - What CC knows about Joel (strengths, patterns, preferences)
   - What Joel should know about CC (limitations, failure modes, blind spots)
   - Reviewed and updated quarterly
   - Addresses the negative-synergy risk identified in the Augmentation-to-Symbiosis research: without shared mental models, human-AI teams underperform

5. **Cross-Session Learning Loop**
   - After each session, CC writes a 3-line internal reflection (in memory):
     - What went well in this session's partnership
     - What friction occurred
     - One specific adaptation to try next session
   - Over 10+ sessions, this creates a calibration feedback loop
   - Human-gated: Joel can review and correct CC's self-assessment

**Validation criteria:**
- Joel reports feeling "extended" rather than "assisted" (the Extended Mind test)
- Thread velocity improves (more closed per session without quality drop)
- CC's proactive suggestions are accepted >70% of the time (calibration quality)
- New capability areas show faster ramp-up (ZPD scaffolding working)
- Joel and Q both report that CC's handoffs improve cross-AI coherence

**Timeline:** 10+ sessions of Walk-phase data before Run behaviors are trustworthy. Some Run deliverables (Shared Mental Model, Cross-Session Learning) can begin earlier as experiments.

---

### What's Speculative vs. Proven

| Element | Status |
|---------|--------|
| Cognitive Profile in memory | **Proven** — memory system exists, just needs this content |
| Adaptive session briefing with triage | **Low-risk experiment** — additive to existing protocol |
| Mid-session scope guard | **Proven pattern** — Q already does this; CC should too |
| Energy/load detection from text signals | **Speculative** — no validated heuristics for LLM-based state detection from text alone |
| ZPD-aware capability stretching | **Speculative** — requires tracking capability over many sessions; may be too noisy |
| Cross-session learning loop | **Low-risk experiment** — lightweight, human-gated, easy to abandon |
| Shared Mental Model artifact | **Novel but grounded** — research strongly supports; no deployed example at this scale |
| Dynamic Complementarity Model | **Aspirational** — the vision; requires Walk-phase data to calibrate |

---

### Honest Gaps

1. **I don't know your pre-Qwrk story.** What brought you here? What's your professional background? What life experiences shaped the "intentional life" philosophy? This matters because the Cognitive Exoskeleton should amplify *your* cognition, not a generic builder's.

2. **I don't know your energy patterns.** When are you sharpest? When do you hit walls? Do you work in bursts or sustained blocks? This directly affects load-balancing recommendations.

3. **I don't know what "success" feels like to you.** Is it shipping? Is it the architecture being clean? Is it the system being used by others? Is it personal clarity? The exoskeleton's optimization target depends on this.

4. **I can't observe Q's sessions.** I see Q's *outputs* (snapshots, system instructions, governance docs) but not Q's *process*. My model of the Joel-Q partnership is inferred, not observed.

5. **I have no baseline.** I've never measured my current effectiveness in a structured way. The Walk/Run phases assume I can detect improvement, but I don't have metrics today.

---

### Research Sources (12 Models Referenced)

1. Licklider, J.C.R. (1960). "Man-Computer Symbiosis." IRE Transactions on Human Factors in Electronics.
2. Engelbart, D. (1962). "Augmenting Human Intellect: A Conceptual Framework." SRI International.
3. Clark, A. & Chalmers, D. (1998/2025). "The Extended Mind" + "Extending Minds with Generative AI." Nature Communications.
4. Kasparov, G. / Case, N. (2018). "How To Become A Centaur." MIT Journal of Design and Science.
5. Vygotsky, L. (1930s/2025). Zone of Proximal Development, applied to AI as "More Knowledgeable Other." PMC 2025.
6. Person-AI Bidirectional Fit (P-AI Fit) Model. arXiv 2511.13670 (2025).
7. DARPA ASIST + EMHAT Programs (2019-present). Artificial Social Intelligence for Successful Teams.
8. Human-AI Symbiotic Theory (HAIST). MDPI Informatics (2025).
9. Bounded Agent Complementarity / Cognitive Load Framework. Artificial Intelligence Review, Springer (2026).
10. Hutchins, E. (1995/2025). Distributed Cognition. Applied to human-AI systems, arXiv 2602.15638.
11. McGill, B. (2026). "The Prosthetic Principle: AI as Cognitive Infrastructure." Substack.
12. From Augmentation to Symbiosis: Taxonomy of Human-AI Collaboration. arXiv 2601.06030 (2025).
