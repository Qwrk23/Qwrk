# Beta Launch Execution Plan — Post-Vacation Path

> **Status:** On Hold — post-vacation unlock
> **Parent thread:** T184 (new) — derived from T176 (Beta Active Launch Program)
> **Captured:** 2026-04-18
> **Source:** Strategic assessment run against live DB state, Gateway v2 deployment, T176 sapling `4cac82b5-c9ff-40a6-9e5e-9778fc249ebf`, Authority Decision `5d80ee44`, Binding Restart `fb7650ed`, Beta Teaching Layer `c876b67c`, Beta Onboarding IP `824b446a`.

---

## CHANGELOG

### v1 — 2026-04-18
**What:** Captured full execution-grade Beta launch assessment. Pre-vacation concierge pilot plan executed separately; this file holds the **post-vacation scaling path**.
**Why:** Joel elected to park the broader scaling work until after vacation so the pre-vacation window focuses solely on pilot #1 via concierge manual provisioning.
**Scope of impact:** Reference only — no system behavior change. Unlock trigger: Joel returns from vacation AND pilot #1 has completed save→retrieve→feedback.
**How to validate:** See "Post-Vacation Path" section below for concrete gates.

---

## 1. Anchor — Current State (verified at capture time)

**Verified stable:**
- Gateway v2, 10 actions, 6 forests, all sub-workflows certified
- Kernel v1 (DDL v2.10), 15 artifact types, RLS across 19 tables
- Beta Teaching Layer content locked: Beta SI v1.2 + 7 packs (Onboarding, Payload Discipline, Mental Model, Artifact Selection, Post-Onboarding, Index, Discovery) in `phase1.5-chat-gateway/Explore_Qwrk_Demo/`
- Manual 10-step provisioning SOP: `Instruction_Pack__Beta_User_Onboarding__v1.md`
- Manual provisioning exercised 3+ times (BlaggLife, Akara, Greg). Test users: Demo JBlagg, Akazanar

**Verified fragile / unstarted:**
- T176 all six branches (A–F) `not_started` in practice (15 Branch-B leaves show phantom `in_progress` from bulk creation)
- Teaching layer content locked but **not deployed** (per restart `c876b67c` 2026-03-21)
- Beta Qx has hardcoded `KNOWN_WORKSPACES` — per-user edit + rebuild required
- Binding model memo produced, **not locked**
- No external non-Joel user has ever run a Qwrk session against any workspace

**False blockers for pilot launch:**
- "Deterministic binding model + Activation Code Lifecycle Contract" — needed for self-service, not needed for concierge
- "Gateway parity upgrade v46→v50+" — v50 already deployed
- "Master Record / bootstrap contract" — design concerns, not launch blockers
- Provisioning time optimization (B14 `<10 min`)

---

## 2. The Smallest Viable Beta Path (re-stated here for post-vacation reference)

**Minimum capabilities for launch:** one real external user can, in ≤90 minutes of Joel's time:
1. Hit a CustomGPT ("Q") URL with Beta SI v1.2 + 7 packs
2. Be routed into journal-first onboarding
3. Execute a `prime-exec` payload via QSB
4. See an `artifact_id` return
5. Retrieve the artifact in a follow-up message
6. Send a single piece of feedback

**Single gating factor:** a named human willing to use Qwrk this week.

---

## 3. Post-Vacation Execution Plan

### Entry conditions (must all be true to resume this work)
- Joel has returned from vacation
- Pilot #1 has either completed the first-success loop OR produced a documented friction log
- No higher-priority governance emergency

### Track 1 — Scale concierge to 5 users (≈2 weeks)
- Each onboarding sharpens the SOP
- Log every friction in a T184-parented snapshot
- **No automation investment until a step has taken <5 minutes three times in a row**

### Track 2 — Automate the single most painful step
- Almost certainly one of:
  - **(a)** Qx per-user configuration (remove hardcoded `KNOWN_WORKSPACES`, introduce runtime config)
  - **(b)** QSB credential distribution (packaged installer or signed config)
- Build ONE n8n workflow that takes `{email, display_name}` → emits the full provisioning bundle
- Do **not** pursue binding-code / self-service flow until 5 concierge pilots are behind you

### Do NOT resume post-vacation (until launch criteria met):
- Binding model selection (`fb7650ed` restart)
- Activation Code Lifecycle Contract
- Master Record concept
- Bootstrap contract
- Branches D (Acquisition), E (Validation), F (UX) of T176 sapling
- T174 Guided PoV (separate product)
- T172 Operator Console (orthogonal)
- T173 Website strategic planning (pre-product)

### Launch gate — Beta is "launchable" when:
1. ≥5 external users have completed the first-success loop (save → retrieve → feedback)
2. Weekly feedback review ritual is operational (any format)
3. Concierge provisioning time ≤15 minutes
4. One critical friction from each of those 5 users has been fixed

### Post-launch (not in scope for this file):
- Self-service provisioning (binding model + activation codes)
- Beta feature allowlist (twig `9a72c71e`)
- Per-user telemetry dashboard
- Public signup funnel

---

## 4. Risks to flag when unlocking

- **Teaching layer will have drifted** — packs and SI may no longer match Gateway v2 behavior after post-vacation changes. Validate before onboarding user #2.
- **Gateway v2 may have shifted** — check drift reconciliation per CLAUDE.md drift rule before resuming.
- **OPEN_THREADS state may be stale** — refresh before promoting this thread back to Active Surface.

---

## 5. Pointers

- Master sapling (T176): `4cac82b5-c9ff-40a6-9e5e-9778fc249ebf`
- Authority decision: `5d80ee44-543c-4178-b7ac-1a7107e58d9a`
- Binding restart: `fb7650ed-6b20-4e1d-b551-9ca330ff052f`
- Teaching layer lock restart: `c876b67c-e04f-4233-ab8f-3e843f951c5f`
- Beta Onboarding IP: `824b446a-bc5d-4df9-a72f-4a91693b256e`
- Manus review fold-in: `a68c4429-5c18-423b-b76a-d34e59d5d8c3`
