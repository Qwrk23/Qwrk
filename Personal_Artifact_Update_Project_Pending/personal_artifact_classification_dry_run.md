# Personal Artifact Classification - Dry Run Report

**Generated:** 2026-02-05T22:35:00Z
**Classification Mode:** Read-only analysis
**Classification Rule:** Conservative (when in doubt, do not classify)

---

## 1. Summary

| Metric | Count |
|--------|-------|
| Total artifacts reviewed | 191 |
| High-confidence personal | 10 |
| Skipped due to ambiguity | 8 |

**Notes:**
- Reviewed first 50 artifacts each for: project, journal, snapshot types
- Reviewed all 41 restart artifacts
- Classification based on title, artifact_type, and tags only (spine data)
- Applied conservative rule: artifacts mixing personal and Qwrk system concerns were skipped

---

## 2. High-Confidence Personal Artifacts

| artifact_id | artifact_type | title | current tags | justification |
|-------------|---------------|-------|--------------|---------------|
| `253cb8eb-b6e9-427a-9e99-eb06126760af` | journal | Year-End Vision 2026 - Me | reflection, vision, personal | Personal vision and identity planning; explicitly tagged "personal" |
| `d13e690d-eae1-49f0-8a5e-eb0d9472896c` | journal | Year-End Vision 2026 - Relationships | reflection, vision, relationships | Personal reflection on relationships and relational goals |
| `c8dc4eda-3cd9-4e24-91f6-ca43793767f3` | journal | Year-End Vision 2026 - Qwrk and ADHD as Superpower | reflection, vision, qwrk, adhd | Personal identity and ADHD as personal trait/strength |
| `76f00a98-2f18-4096-a7af-f69781bbafa8` | journal | 10-Year Family Anniversary - Havi's Message and Identity Alignment | family, identity, havi, qwrk, purpose, coach qwrk, cqa1c | Family milestone and personal identity alignment |
| `04ac158c-3c3f-4f3e-bebc-19b4790253f9` | journal | Active Journaling - From Proving to Expressing Who I Am | journal, reflection, identity | Personal identity and self-expression journey |
| `b5f14d41-340a-4351-8d07-2c3eb672c4b6` | journal | Tuesday Strength Re-Entry - Gym Morning Reflection | journal, fitness, tuesday, discipline | Health, fitness, and physical wellbeing |
| `e9df9708-948e-4be7-85f5-0ae6745fa061` | journal | Morning Flow - 2026-02-05 | morning-flow, reflection | Personal daily reflection and morning routine |
| `bb698d50-da2d-47be-bd95-e2052eeb75e6` | journal | Reading Journal - The Hunt for Red October - Part 2: How Did You Love | reading-journal, book:red-october, season:old-bull | Personal reading and literary reflection |
| `6ef36b70-6f77-4a19-a75b-ffa6a41162a8` | journal | Reading Journal - The Hunt for Red October - Part 1: Opening | reading-journal, book:red-october, season:old-bull | Personal reading and literary reflection |
| `a52f402e-1b07-4e6e-bb44-a3bb776f87af` | snapshot | Active Book Context - The Hunt for Red October | for-q, active-context, active-book, book:red-october | Active personal reading engagement context |

---

## 3. Ambiguous / Skipped Artifacts

| artifact_id | artifact_type | title | reason skipped |
|-------------|---------------|-------|----------------|
| `e7040cbd-bcfb-4d42-afb8-708e7a76ff69` | journal | A Productive Day, Earned | Mixes personal reflection with "work" tag; unclear if personal or professional productivity |
| `d6ab1fa5-ffd5-4056-80f8-c3adda514863` | journal | Five Hours of Governance and Grounding | Title suggests reflection but context is Qwrk governance work |
| `0a167e68-0406-42ed-b37c-05e92b16e0bc` | journal | Soul-Fulfillment and the Making of Qwrk | Personal growth language but deeply intertwined with Qwrk system building |
| `eecc76ed-6af8-4e58-8045-a5471b549b6f` | journal | Back in the Gym - Showing D How Qwrk Thinks | Health/fitness topic but includes demonstration of Qwrk system |
| `c114a340-b7f0-41ea-84ae-a8ec6121eb3c` | journal | One Window Insight - Comfort, Clarity, and How I Actually Work | Could be personal ergonomics or operational tooling; insufficient signal |
| `c5e46e21-a34a-45b6-a750-9fa062721280` | journal | Routine Goals and Balance Posture - Strategic Execution Manager Lens | Routines sound personal but "Strategic Execution Manager" suggests professional role |
| `f27cfe11-54fd-4a04-a363-1cda59cfae0c` | journal | One Window, One Authority - Using Qwrk to Build Qwrk (Early Insight) | Meta-insight but about Qwrk system, not personal |
| `1bd8d5f9-2bf0-4e98-9536-fd8d673c06f4` | journal | Reading Journal Style Invariant - Narrative, First-Person, Meaning-Resolving | Governance about reading journal format, not personal reading content |

---

## 4. Explicit Confirmation (Required)

> No artifacts were modified. No tags were applied. This was a dry run only.

---

## Classification Methodology

### Binding Definition Applied

**Classified as Personal if primarily relates to:**
- Personal life
- Health or wellbeing
- Identity, reflection, journaling
- Relationships, inner work, spirituality, or personal growth

**NOT Classified as Personal if relates to:**
- Qwrk system governance, architecture, or rules
- Qwrk build projects, planning, or execution
- Paid work, employment, consulting, or client deliverables
- Operational tooling, infrastructure, automation, or integrations

### Conservative Rule
When an artifact's title or tags suggested mixed personal/professional content, it was placed in the Ambiguous/Skipped category rather than classified.

### Data Sources
- artifact.list for project (50 artifacts, offset 0)
- artifact.list for journal (50 artifacts, offset 0)
- artifact.list for snapshot (50 artifacts, offset 0)
- artifact.list for restart (41 artifacts, complete)

**Total reviewed:** 191 artifacts from the default workspace.
