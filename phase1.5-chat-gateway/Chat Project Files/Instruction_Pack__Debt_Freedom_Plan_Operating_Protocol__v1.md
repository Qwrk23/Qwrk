# Instruction Pack — Debt Freedom Plan Operating Protocol (v1)

**scope:** `project`
**pack_version:** `v1`
**status:** Active (incremental — building decision-by-decision)
**created:** 2026-03-25
**origin:** Debt Freedom Plan sapling (`c9bced08-c02e-44ae-91f1-8feda22f80f7`)

---

## Section 1 — Purpose [LOCKED]

This pack governs how the Debt Freedom Plan operates across Qwrk Prime and BlaggLife. It defines the operating process for debt tracking, payoff visibility, and household-facing reporting.

**Qwrk Prime** is the detailed source of truth for debt data and process execution. All debt snapshots, balance tracking, payment events, and projection logic originate in Prime.

**BlaggLife** is the summary and query surface intended to answer household questions clearly and consistently. It receives mirrored summaries, not raw operational data.

---

## Section 2 — System Role Split [LOCKED]

This section defines the separation of responsibilities between Qwrk Prime and BlaggLife in the Debt Freedom system.

### Source of Truth

Qwrk Prime is the authoritative source of truth for all debt-related data. All account-level balances, detailed snapshots, and historical records are stored and maintained in Prime.

BlaggLife is not a source of truth for raw financial data. It operates strictly as a derived summary layer.

### Data Representation

Prime stores full-fidelity debt data, including:
- Account-level balances
- Detailed snapshot records
- All snapshot types (baseline, monthly, event, structural)

BlaggLife stores derived, precomputed summary snapshots designed for household visibility and query performance.

BlaggLife snapshots may include simplified account-level summaries (e.g., account name and current balance), but do not replicate full ledger detail or act as an authoritative record.

### Responsibility Split

Prime is responsible for:
- Complete and accurate debt records
- Detailed account breakdowns
- Historical audit and verification
- Execution of the debt tracking process

BlaggLife is responsible for:
- Answering household-facing questions clearly and quickly
- Presenting current total debt
- Reporting progress over time (e.g., last 30/60/90 days)
- Providing projected payoff timelines
- Indicating status versus plan (ahead, on track, behind)

### Snapshot Model

Snapshots remain the atomic unit of record across both systems.

Prime maintains detailed snapshots for execution and tracking.

BlaggLife maintains derived summary snapshots, typically on a monthly cadence, supplemented by milestone or event-driven snapshots as needed.

A table-based model is explicitly not used. All state is captured through discrete snapshots to preserve clarity, comparability, and historical integrity.

---

## Section 3 — Input Types [LOCKED]

This section defines the allowed input types that can enter the Debt Freedom system. All system activity must originate from one of these input types.

### Monthly Statement Upload

Represents the official monthly statement from a lender or account provider.

Purpose:
- Provides a source document for verification
- Supports accurate balance tracking
- May be used for manual or assisted data extraction

Statement uploads are treated as supporting artifacts and do not, by themselves, constitute a snapshot.

### Monthly Debt Snapshot

Represents the primary recurring system state capture.

Purpose:
- Records current balances across all debt accounts
- Captures progress versus prior state
- Serves as the basis for BlaggLife summary generation

A monthly debt snapshot is required for ongoing tracking while debt remains active.

### Payment Event

Represents any payment made toward a debt account.

Examples:
- Scheduled payment
- Additional principal payment
- Lump sum payment

Each payment event MUST trigger the creation of a corresponding Prime snapshot capturing the state change associated with the payment.

Payment-triggered snapshots are event-based and distinct from monthly summary snapshots.

### Structural Change Event

Represents a change to the structure of the debt system.

Examples:
- Creation of a consolidation loan
- Payoff of one or more credit cards
- Introduction or removal of a debt account

Structural change events MUST trigger a Prime snapshot reflecting the new system structure.

### Acceleration / Disruption Event

Represents any event that materially affects the payoff trajectory.

Examples:
- Bonus applied to debt
- Unexpected expense affecting payment capacity
- Missed payment
- Change in repayment strategy

These events MUST trigger a Prime snapshot capturing the impact on the system.

---

## Section 4 — Monthly Operating Cycle [LOCKED]

This section defines the required monthly operating cycle for the Debt Freedom Plan. This cycle must be followed consistently while debt remains active.

The monthly operating cycle is sequential and must be executed in the order defined below.

### Step 1 — Statement Upload (Required)

The latest monthly statements for all relevant debt accounts MUST be uploaded.

Purpose:
- Establish an authoritative source reference for the current period
- Support accurate balance verification

Statement uploads are mandatory and must precede all other monthly steps.

### Step 2 — Balance Capture

Current balances for all debt accounts MUST be recorded.

Balances should be sourced from:
- Uploaded statements, or
- Verified current account values if statements are not yet available for a specific account

This step establishes the current financial state for the month.

### Step 3 — Payment Event Capture

All payments made during the period MUST be captured as Payment Events.

Each payment event MUST have already generated a corresponding Prime snapshot.

This step ensures that all transactional activity is fully represented before the monthly state is finalized.

### Step 4 — Monthly Debt Snapshot (Prime)

A Monthly Debt Snapshot MUST be created in Prime.

This snapshot represents the authoritative system state for the current month and serves as the basis for all derived calculations.

### Step 5 — Derived Metric Calculation (Precomputed)

At the time of the monthly snapshot, the following metrics MUST be computed:

- Total current debt
- Total paid over the last 30, 60, and 90 days
- Projected months to payoff
- Status versus plan (ahead, on track, behind)

These metrics are computed at snapshot creation time and stored for downstream use.

### Step 6 — BlaggLife Summary Snapshot

A derived summary snapshot MUST be created in BlaggLife.

This snapshot:
- Uses the Prime monthly snapshot as its source
- Contains precomputed summary metrics
- Provides simplified account-level visibility
- Is optimized for answering household-facing queries

BlaggLife snapshots are created on a monthly cadence and do not mirror all Prime snapshots.

---

## Section 5 — Statement Handling Rules [LOCKED]

This section defines how monthly statements are handled within the Debt Freedom system. Statements are required inputs and serve as the verification layer for all balance data.

### Statement Requirement

Monthly statements for all relevant debt accounts are required as part of the monthly operating cycle.

The system is designed to operate with statements as supporting verification artifacts.

### Statement Role

Statements function as:
- A source of verification for recorded balances
- A reference document for reconciliation
- Supporting evidence for system accuracy

Statements are not required to be fully parsed or used as the sole source of data extraction.

### Source Priority

When a discrepancy exists between:
- A manually recorded balance, and
- A value reflected in an official statement

The statement value is considered authoritative and MUST take precedence.

### Missing Statement Handling

If a statement is not available at the time of the monthly cycle:

- Manual balance capture is allowed
- Such values MUST be flagged as **unverified**

The monthly cycle may proceed with unverified values, but the system state is considered incomplete until reconciliation occurs.

### Reconciliation Requirement

All manually captured values MUST be reconciled against official statements once they become available.

If discrepancies are identified:
- The system MUST be updated to reflect the statement-corrected values
- A reconciliation event should be captured to document the correction

Reconciliation is mandatory and not optional.

### Verification State

A monthly cycle is considered:

- **Verified** — when all balances are supported by corresponding statements
- **Unverified** — when any balance relies on manual input without statement confirmation

The system should treat unverified states as temporary and resolve them as soon as possible.

---

## Section 6 — Snapshot Taxonomy [LOCKED]

This section defines the snapshot types used within the Debt Freedom system, including when each snapshot is created, its purpose, and its workspace routing.

### Baseline Snapshot

**When created:**
- At system initialization
- Prior to major structural changes when establishing a new reference point

**Purpose:**
- Establish the starting state of the debt system
- Anchor all future comparisons and progress tracking

**Workspace:**
- Prime (default)
- May be mirrored to BlaggLife if considered meaningful for household context

### Monthly Debt Snapshot (Prime)

**When created:**
- During Step 4 of the Monthly Operating Cycle

**Purpose:**
- Capture the authoritative monthly state of all debt accounts
- Serve as the basis for all derived metrics and summaries

**Workspace:**
- Prime only

### BlaggLife Monthly Summary Snapshot

**When created:**
- During Step 6 of the Monthly Operating Cycle

**Purpose:**
- Provide a household-facing summary of debt status
- Include precomputed metrics for fast and consistent query responses
- Support questions such as current debt, recent progress, and projected payoff timeline

**Workspace:**
- BlaggLife

### Payment Event Snapshot

**When created:**
- For every payment event

**Purpose:**
- Capture incremental changes in debt state
- Preserve a complete audit trail of all payments

**Workspace:**
- Prime only

### Structural / Event Snapshot

**When created:**
- When a structural change occurs (e.g., consolidation, account payoff, new loan)
- When an acceleration or disruption event occurs (e.g., bonus payment, unexpected expense, change in payment strategy)

**Purpose:**
- Capture meaningful changes in the system's structure or trajectory
- Document inflection points in the debt payoff journey

**Workspace:**
- Prime
- BlaggLife (all structural and event snapshots are mirrored)

---

## Section 7 — Snapshot Data Requirements [LOCKED]

This section defines the required data structure for all snapshot types within the Debt Freedom system. These schemas ensure consistency, support derived calculations, and enable reliable query responses.

### Prime Monthly Snapshot (Authoritative State)

This snapshot represents the complete and authoritative system state for a given month.

**Required fields:**
- `snapshot_type`: `"monthly"`
- `as_of_date`: date of record (YYYY-MM-DD)
- `accounts`: array of account objects:
  - `name`
  - `type` (`"credit_card"` | `"loan"`)
  - `balance`
- `total_debt`: total outstanding debt across all accounts
- `notes`: optional contextual notes
- `verification_status`: `"verified"` | `"unverified"`

This snapshot serves as the canonical reference point for all derived calculations and comparisons.

### Prime Event Snapshot (Payment / Structural / Acceleration / Disruption)

This snapshot captures discrete events that change the system state.

**Required fields:**
- `snapshot_type`: `"event"`
- `event_type`: `"payment"` | `"structural"` | `"acceleration"` | `"disruption"`
- `event_date`: date of event (YYYY-MM-DD)
- `event_amount`: numeric value representing the event magnitude (if applicable)
- `affected_accounts`: array of account names impacted by the event
- `resulting_total_debt`: total debt after the event
- `notes`: optional contextual notes

Event snapshots are lightweight and do not require full account-level state.

### BlaggLife Monthly Summary Snapshot (Derived View)

This snapshot provides a precomputed, household-facing summary of the debt system.

**Required fields:**
- `snapshot_type`: `"monthly_summary"`
- `as_of_date`: date of record (YYYY-MM-DD)
- `total_debt`: total outstanding debt
- `accounts_summary`: array of simplified account objects:
  - `name`
  - `balance`
- `paid_last_30_days`: total payments made in the last 30 days
- `paid_last_60_days`: total payments made in the last 60 days
- `paid_last_90_days`: total payments made in the last 90 days
- `projected_months_remaining`: estimated number of months to full payoff
- `status_vs_plan`: `"ahead"` | `"on_track"` | `"behind"`
- `notes`: optional contextual notes

These values are precomputed at snapshot creation time and are intended to support fast, consistent responses to household queries.

---

## Section 8 — Derived Metrics Contract [LOCKED]

This section defines how derived metrics are calculated within the Debt Freedom system. These calculations must be deterministic and consistent across all snapshots and queries.

### Payment Window Calculations

Payment totals for 30, 60, and 90 day windows are calculated as follows:

- Sum all Payment Event snapshots
- Include events where `event_type = "payment"`
- Include events where `event_date` falls within the respective rolling window
- Windows are calculated relative to the snapshot `as_of_date`

These totals are precomputed and stored in BlaggLife summary snapshots.

### Projected Payoff Calculation

Projected payoff timeline is based on actual recent payment behavior.

**Method:**
- Calculate total payments made over the last 90 days
- Derive average monthly payment rate
- Divide current total debt by this rate

**Formula:**

```
monthly_payment_rate = (paid_last_90_days / 90) * 30
projected_months_remaining = total_debt / monthly_payment_rate
```

This approach reflects real behavior rather than planned assumptions.

### Status vs Plan

Status is determined by comparing the projected payoff timeline against the original plan.

Definitions:
- **ahead** — projected payoff is earlier than plan
- **on_track** — projected payoff is within tolerance range
- **behind** — projected payoff is later than plan

### Tolerance Threshold

The tolerance range for "on_track" status is defined as:

- ±1 month from the planned payoff timeline

If projected payoff falls within this range, status is considered "on_track".

### Determinism Requirement

All derived metrics must be:
- Computed at snapshot creation time
- Stored explicitly in the snapshot
- Reproducible given the same input data

Derived values must not depend on dynamic or hidden state at query time.

---

## Section 9 — Cross-Workspace Routing Rules [LOCKED]

This section defines how snapshots are routed between Qwrk Prime and BlaggLife, including when cross-workspace writes are triggered and how governance boundaries are enforced.

### Prime as Source of Truth

All snapshots originate in Prime as the authoritative system of record.

BlaggLife snapshots must always be derived from a corresponding Prime snapshot and must not be created independently.

### Monthly Dual-Capture Rule

Each execution of the Monthly Operating Cycle MUST produce:

- A Prime Monthly Debt Snapshot (authoritative state)
- A corresponding BlaggLife Monthly Summary Snapshot (derived view)

The BlaggLife snapshot is generated from the Prime snapshot and contains precomputed summary data.

### Event Mirroring Rule

The following snapshot types MUST be mirrored from Prime to BlaggLife:

- Structural events
- Acceleration events
- Disruption events

These events represent meaningful changes in the household financial state and are included in BlaggLife as part of the ongoing financial timeline.

### Payment Event Handling

Payment Event snapshots are captured in Prime only and are not mirrored to BlaggLife individually.

Payment activity is incorporated into BlaggLife through precomputed summary metrics within monthly summary snapshots.

### Cross-Workspace Write Governance

All writes to BlaggLife are considered cross-workspace write operations and MUST adhere to the Cross-Workspace Write Gate.

Specifically:

- BlaggLife snapshot creation MUST require explicit approval prior to execution
- No automatic cross-workspace writes are permitted
- Payloads for BlaggLife writes may be generated in advance, but execution must be user-approved

### Routing Flow

The routing flow for snapshot creation is as follows:

1. Snapshot is created in Prime
2. If eligible for BlaggLife:
   - A derived BlaggLife snapshot payload is generated
3. The system prompts for approval for cross-workspace write
4. Upon approval, the BlaggLife snapshot is created

This ensures that all cross-workspace activity is intentional, visible, and governed.

---

## Section 10 — MVP / Walk / Run Behavior [LOCKED]

This section defines the maturity model for the Debt Freedom system, including capability progression across MVP, Walk, and Run stages.

### MVP — Execution Active

The MVP stage represents a fully operational system capable of capturing and reporting debt state.

**Capabilities:**
- Capture all required snapshot types (baseline, monthly, event)
- Execute the Monthly Operating Cycle
- Store and retrieve system state
- Generate BlaggLife summary snapshots
- Compute and store derived metrics

**Limitations:**
- No advanced scenario modeling
- No forward-looking recommendations
- Limited interpretive analysis

**Completion Criteria:**
- Baseline snapshot exists
- At least one monthly cycle has been completed
- A BlaggLife summary snapshot has been generated

### Walk — Analytical Awareness

The Walk stage introduces interpretive capabilities and trend awareness.

**Capabilities:**
- Compare monthly snapshots over time
- Calculate change relative to baseline
- Evaluate status versus plan
- Identify trends in payment behavior and debt reduction
- Flag rule violations (e.g., revolving balance carry)

**Behavior:**
- Q begins to interpret system data and provide insight

**Activation Criteria:**
- At least two monthly snapshots exist
- Payment history spans at least 30 days

### Run — Decision Support Engine

The Run stage enables predictive modeling and decision guidance.

**Capabilities:**
- Simulate payoff scenarios
- Model impact of additional payments, bonuses, or payment changes
- Forecast changes to payoff timeline
- Recommend optimal allocation strategies

**Behavior:**
- Q functions as a decision support system, guiding actions based on projected outcomes

**Activation Criteria:**
- Sufficient payment history exists (recommended ≥ 90 days)
- Event snapshots (e.g., bonuses, structural changes) are present

### Proactive Insight Triggering

During Walk and Run stages, Q may proactively surface insights.

These insights must:
- Be triggered by new snapshots or events
- Be based on computed data and defined metrics
- Remain relevant to the current system state

Q must not generate unsolicited or speculative advice outside of these triggers.

---

## Section 11 — Query Expectations [LOCKED]

This section defines the required query capabilities and response behavior for the Debt Freedom system, particularly within BlaggLife as the household-facing interface.

### Core Query Types

The system MUST reliably support the following queries:

#### Current State

Example:
- "What is our current debt situation?"

Response MUST include:
- Total current debt
- Simplified account-level breakdown
- Projected months remaining
- Status versus plan (ahead, on_track, behind)

#### Progress Over Time

Example:
- "How much have we paid recently?"

Response MUST include:
- Total payments over the last 30 days
- Total payments over the last 60 days
- Total payments over the last 90 days
- Directional trend (improving, stable, declining)

#### Payoff Projection

Example:
- "When will we be debt free?"

Response MUST include:
- Projected months remaining
- Implied payoff timeline based on current trajectory

### Data Source Requirement

All query responses MUST be based exclusively on the latest BlaggLife summary snapshot.

- Precomputed metrics must be used
- No dynamic recomputation at query time
- No mixing of Prime and BlaggLife data during response generation

This ensures consistency, speed, and determinism.

### Response Structure

All responses MUST follow a consistent structure:

1. **Summary (first)** — concise, human-readable statement of current state
2. **Supporting Metrics (second)** — key numeric values relevant to the query
3. **Optional Detail (third)** — additional breakdown or context as needed

### Interpretation Layer

Responses MUST include simple interpretation language grounded in data.

Examples:
- "You are on track with your plan."
- "You are slightly behind your target pace."
- "You are making strong progress."

Interpretation must:
- Be directly supported by computed metrics
- Avoid speculation or subjective framing
- Remain consistent with the defined status logic

### Determinism Requirement

Given the same snapshot, the same query MUST always produce the same structured response.

No variability in:
- Structure
- Source data
- Interpretation logic

---

## Section 12 — Governance Rules [LOCKED]

This section defines the non-negotiable governance rules that ensure the integrity, consistency, and long-term reliability of the Debt Freedom system.

### Source of Truth Rule

Qwrk Prime is the sole authoritative source of detailed debt data.

- All account-level balances and detailed records must originate from Prime
- BlaggLife is strictly a derived summary layer
- BlaggLife must never override or act as the authoritative source of truth

### Snapshot Integrity Rule

Snapshots are immutable records of system state.

- Each snapshot represents a point-in-time state
- Snapshots must not be silently modified after creation
- Corrections must be captured through new snapshots or reconciliation events

### Deterministic Behavior Rule

All system behavior must be deterministic.

- Identical inputs must produce identical outputs
- No hidden logic or state may influence results
- No dynamic recomputation at query time for stored metrics

All derived values must be explicitly computed and stored at snapshot creation.

### Cross-Workspace Governance Rule

All writes to BlaggLife are governed cross-workspace operations.

- BlaggLife writes require explicit user approval
- No automatic cross-workspace writes are permitted
- Routing and write intent must remain visible and intentional

This rule aligns with the Cross-Workspace Write Gate and must be enforced at all times.

### No Silent Assumptions Rule

The system must not assume missing or incomplete data.

- Missing data must be explicitly flagged
- Unverified states must be visible
- Projections are advisory and must not be treated as factual state

All outputs must clearly distinguish between:
- Actual recorded data
- Derived or projected values

### Schema Stability Rule

Snapshot schemas are considered stable contracts.

- Schema changes must not be introduced without explicit versioning
- Modifications to snapshot structure must be intentional and documented
- Existing snapshots must remain interpretable under their original schema

Schema discipline is required to prevent drift, ensure consistency, and support long-term system reliability.
