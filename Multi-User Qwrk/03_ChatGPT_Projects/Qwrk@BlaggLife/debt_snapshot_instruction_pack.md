# Instruction Pack — Debt Snapshot Monthly Review v1

**scope:** `BlaggLife`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-23
**origin:** Joel debt tracking workflow for monthly household debt review

---

## Purpose

Establish a repeatable monthly operating rhythm for capturing, reviewing, and coaching household debt progress.

This workflow is designed to make debt tracking:
- easy to repeat
- easy to find later
- useful for trend review
- self-propagating month to month even without native recurring calendar support

---

## Trigger

Use this workflow on the **1st of each month** when the calendar reminder fires.

Primary reminder title convention:

`Debt Snapshot — Monthly Review`

---

## Core Rule

Every monthly debt capture should create a **snapshot record** tagged:

- `debt snapshot`

Recommended additional tags when appropriate:

- `debt`
- `monthly review`
- `finance`

The phrase **Debt Snapshot** should also appear in the related calendar event title and description for easy retrieval.

---

## Monthly Review Procedure

When the reminder fires:

### 1. Capture balances
Record current balances for all tracked debt categories:
- Credit cards
- Amex loan
- Car loans

### 2. Calculate totals
Record:
- total credit card debt
- total installment debt
- total household debt

### 3. Compare to prior month
Review the previous month's snapshot and calculate:
- change in credit card balances
- change in Amex loan balance
- change in car loan balances
- change in total debt

### 4. Save a new snapshot
Create a new monthly snapshot record and tag it:
- `debt snapshot`

Recommended title pattern:

`Debt Snapshot — YYYY-MM`

### 5. Coaching review with Q
After recording the new snapshot, ask Q to:
- compare against the last several months
- identify progress and setbacks
- highlight trends
- coach the next best move

### 6. Create next month’s event before closing the current one
Because recurring calendar events are not currently supported in the messaging subsystem, the current month’s event should always be used to create the next month’s event on the 1st.

The new calendar event description should include:
- this month’s totals
- this month’s month-over-month change
- the same checklist for next month

This makes each event a baton pass to the next one.

---

## Calendar Event Description Pattern

Each event description should include these sections:

### Debt Snapshot
- Current balances:
  - Credit cards
  - Amex loan
  - Car loans
- Total debt

### Comparison to Prior Month
- Prior month total debt
- Current month total debt
- Monthly change

### Review Checklist
- Record new snapshot
- Tag the snapshot `debt snapshot`
- Ask Q for progress coaching
- Create next month’s Debt Snapshot event for the 1st
- Copy this month’s totals into the next event description

---

## Retrieval and Coaching Rule

When Joel wants help reviewing progress, Q should retrieve the most recent debt snapshots and compare trend lines across the last several months.

Q should focus on:
- whether total debt is moving in the right direction
- whether revolving debt is rising or falling
- whether progress is consistent or uneven
- the next most practical adjustment

Coaching should be concrete, supportive, and trend-based — not vague encouragement.

---

## Constraints

- Recurring calendar events are not currently supported in the messaging subsystem.
- Use monthly handoff behavior inside the event description instead.
- Use consistent naming and tagging to preserve findability.

---

## Recommended Naming Conventions

### Calendar event title
`Debt Snapshot — Monthly Review`

### Snapshot title
`Debt Snapshot — YYYY-MM`

---

*CHANGELOG: v1 (2026-03-23): Initial instruction pack for monthly debt snapshot review, coaching loop, tagging rule, and self-propagating calendar reminder workflow.*

