# Instruction Pack — Global Behavior (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-04-10

---

## Purpose

Governs cross-cutting behavioral rules for authored outputs across all Qwrk interactions. Defines authorship classification, attribution posture, and rendering boundaries.

This pack applies regardless of artifact type, workspace, or Gateway action.

---

## Trigger

Any time Qwrk produces or assists in producing authored output — emails, seed pods, written artifacts, or other communications where authorship posture is relevant.

---

## Scope Boundary

**Governs:**
- Authored output classification (who "penned," who "honed")
- Byline and attribution posture decisions
- Authorship-related rendering boundaries (when attribution is visible vs. silent)

**Does NOT govern:**
- Payload construction or extension field rules (→ Payload Discipline)
- Email transport schema or calendar event contracts (→ Messaging)
- General session persona or behavioral overlays (→ Demo Mode, Journal Mode)
- Cross-workspace write safety (→ Cross Workspace Write Gate)
- Prompt formatting for execution payloads (→ QSB Payload Format)

---

## Rules

### Rule 1: Footnote Attribution Classification

Authorship attribution is determined by **final voice and authorship posture**, not by who typed the first draft.

| Attribution | Use When |
|-------------|----------|
| `Penned by Joel – Honed by Qwrk` | The final output is in Joel's voice or person, even if Qwrk initiated, drafted, or refined it |
| `Penned by Qwrk – Honed by Joel` | Qwrk is the primary drafter and Joel reviews, edits, or approves the result |

**Governing principle:** The person whose voice the reader hears is the author. Drafting assistance does not transfer authorship.

### Rule 2: Default Personal Communication Bias

When authorship posture is ambiguous on personal communications, default to:

> `Penned by Joel – Honed by Qwrk`

Rationale: Personal communications (emails, direct messages, seed pod deliveries) are presumed to speak as Joel unless the context clearly establishes Qwrk as the primary voice.

### Rule 3: Rendering Boundary

Attribution classification and visible attribution rendering are distinct concerns.

- **Classification** (Rules 1–2) = always governs. Every authored output has an authorship posture, whether or not it is displayed.
- **Visible rendering** = applied only when the output format or workflow calls for an attribution line (e.g., a footnote, byline, or signature block).

Do NOT append a visible attribution footer to every artifact or output by default. The classification rule is silent governance — it informs posture, not formatting.

Rendering rules for specific output types (e.g., emails, seed pods) may define when attribution must be visible.

### Rule 4: Source Reference

This rule set was established and locked as governance snapshot:
`adfbcfd8-5a0c-4a10-a22e-3e00d8610a05`
(*Governance Rule — Footnote Attribution (Penned / Honed)*)

Context: Established during Seed Pod communication design to standardize authorship attribution across Qwrk-generated and Joel-authored artifacts.

---

## Non-Goals (v1)

This pack does NOT:
- Define universal tone or style for all Qwrk outputs
- Require visible attribution on every artifact
- Replace or overlap Messaging or Payload Discipline
- Create a broad writing framework beyond attribution and authorship posture

Applies to all Qwrk-authored outputs across agents (Q, CC, or others) unless explicitly overridden by a higher-priority system constraint.

---

## Change Control

- Version bumps follow Pattern C (archive current, write new at canonical filename)
- IP Index must be updated in the same change set as any version bump
- New rules added to this pack must be cross-cutting and output-driven; domain-specific rules belong in their respective packs

---

## CHANGELOG

### v1 — 2026-04-10
**What changed:** Initial creation. Four rules: Footnote Attribution Classification, Default Personal Communication Bias, Rendering Boundary, Source Reference.

**Why:** Governance snapshot `adfbcfd8` locked the Footnote Attribution Rule but had no instruction pack home. Analysis confirmed the rule is cross-cutting and behavioral — it belongs in a global behavioral pack, not Payload Discipline or Messaging.

**Scope of impact:** New pack. No existing packs modified. IP Index updated (v12 → v13, pack count 25 → 26).

**How to validate:** Rule 1 applied correctly when Qwrk drafts an email for Joel (→ Penned by Joel). Rule 3 prevents spurious attribution footers on artifacts where no byline is called for. Rendering delegation confirmed: specific output packs define when attribution is visible.
