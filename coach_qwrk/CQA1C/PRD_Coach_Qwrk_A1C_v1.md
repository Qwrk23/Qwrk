# Coach Qwrk: A1C — Product Requirements Document (PRD)

**Version:** 1.2
**Created:** 2026-01-28
**Updated:** 2026-01-28
**Status:** LOCKED — Ready for Implementation
**Authors:** Human + Claude Code + ANQ + Qwrk

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-28 | Initial PRD |
| 1.1 | 2026-01-28 | QP1 review refinements: artifact_id reservation, profile_version, write-once insert pattern, Phase 7 marked optional, Beta Gate added |
| 1.2 | 2026-01-28 | Architecture change: CQ runs as subworkflow of NQxb_Gateway_v1, actions prefixed with `cqa1c.*` |

---

# PART 1: COMPREHENSIVE SPECIFICATION

---

## 1. Executive Summary

**Coach Qwrk: A1C (CQ)** is a conversational life coach for persons with Type 2 diabetes. It helps users lower or maintain their A1C through:
- Blood sugar tracking with contextual feedback
- Meal logging with a personal nutrition dictionary
- Meal-to-blood-sugar impact correlation
- Restaurant meal recommendations
- Weekly/monthly progress reports with A1C estimates

**Target Launch:** Beta via ChatGPT CustomGPT front-end
**Platform:** Qwrk (n8n automation + Supabase database)

---

## 2. System Architecture

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER (ChatGPT CustomGPT)                     │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  NQxb_Gateway_v1 (existing Qwrk Gateway)         │
│                                                                  │
│  Switch on action prefix:                                        │
│  ├── artifact.*    → NQxb_Artifact_* subworkflows (existing)    │
│  └── cqa1c.*       → CQA1C_Gateway_v1 (NEW subworkflow)         │
│                              │                                   │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  CQA1C_Gateway_v1 — Routes to CQ-specific sub-subworkflows  ││
│  └─────────────────────────────────────────────────────────────┘│
│                              │                                   │
│    ┌──────────┬──────────┬──────────┬──────────┬──────────┐    │
│    ▼          ▼          ▼          ▼          ▼          │    │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │    │
│ │ bs   │ │ meal │ │ meal │ │report│ │ user │ │ rest │    │    │
│ │ log  │ │ log  │ │ dict │ │ gen  │ │profile│ │suggest│   │    │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │    │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SUPABASE (PostgreSQL)                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│  │ cq_user_     │ │ cq_blood_    │ │ cq_meal_     │            │
│  │ profile      │ │ sugar_log    │ │ dictionary   │            │
│  └──────────────┘ └──────────────┘ └──────────────┘            │
│  ┌──────────────┐ ┌──────────────┐                              │
│  │ cq_meal_log  │ │ cq_meal_     │                              │
│  │              │ │ impact       │                              │
│  └──────────────┘ └──────────────┘                              │
└─────────────────────────────────────────────────────────────────┘
```

**Routing Pattern:**
- All requests go to existing `NQxb_Gateway_v1`
- Actions starting with `cqa1c.*` route to `CQA1C_Gateway_v1` subworkflow
- CQA1C_Gateway_v1 then routes to action-specific sub-subworkflows
- Future Coach Qwrk apps use their own prefix (e.g., `cqfitness.*`, `cqsleep.*`)

### 2.2 Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| CustomGPT | Natural language interface, intent parsing, response formatting |
| NQxb_Gateway_v1 | Main entry point, routes `cqa1c.*` actions to CQA1C_Gateway_v1 |
| CQA1C_Gateway_v1 | CQ-specific routing, validation, dispatches to sub-subworkflows |
| CQ Sub-subworkflows | Action-specific logic (logging, queries, reports) |
| Supabase | Data persistence, RLS for user isolation |

### 2.3 Table Naming Convention

All CQ tables use the `cq_` prefix to namespace within the shared Qwrk database:
- `cq_user_profile`
- `cq_blood_sugar_log`
- `cq_meal_dictionary`
- `cq_meal_log`
- `cq_meal_impact`

---

## 3. Database Schema (DDL)

### 3.1 Table: cq_user_profile

```sql
CREATE TABLE cq_user_profile (
    user_id UUID PRIMARY KEY,  -- From Qwrk auth
    profile_version INT DEFAULT 1,  -- Future: multi-track support
    artifact_id UUID,  -- Reserved: future Qxb_Artifact integration
    current_a1c DECIMAL(3,1),  -- e.g., 7.2
    target_a1c DECIMAL(3,1),   -- e.g., 6.5
    medications JSONB DEFAULT '[]'::jsonb,
    dietary_restrictions JSONB DEFAULT '[]'::jsonb,
    personality_style TEXT DEFAULT 'warm_friendly'
        CHECK (personality_style IN ('warm_friendly', 'professional', 'casual', 'motivational')),
    onboarding_complete BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policy
ALTER TABLE cq_user_profile ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own profile" ON cq_user_profile
    FOR ALL USING (auth.uid() = user_id);
```

### 3.2 Table: cq_blood_sugar_log

```sql
CREATE TABLE cq_blood_sugar_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cq_user_profile(user_id),
    artifact_id UUID,  -- Reserved: future Qxb_Artifact integration
    reading INTEGER NOT NULL CHECK (reading > 0 AND reading < 700),
    context TEXT NOT NULL
        CHECK (context IN ('wake_up', 'fasting', 'pre_meal', 'post_meal', 'bedtime', 'other')),
    meal_type TEXT
        CHECK (meal_type IS NULL OR meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    reading_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    linked_meal_log_id UUID,  -- Populated when linking to a meal
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bs_log_user_timestamp ON cq_blood_sugar_log(user_id, reading_timestamp DESC);
CREATE INDEX idx_bs_log_user_context ON cq_blood_sugar_log(user_id, context);

-- RLS Policy
ALTER TABLE cq_blood_sugar_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own readings" ON cq_blood_sugar_log
    FOR ALL USING (auth.uid() = user_id);
```

### 3.3 Table: cq_meal_dictionary

```sql
CREATE TABLE cq_meal_dictionary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cq_user_profile(user_id),
    artifact_id UUID,  -- Reserved: future Qxb_Artifact integration
    name TEXT NOT NULL,
    name_normalized TEXT NOT NULL,  -- Lowercase, trimmed for matching
    serving_size TEXT,
    calories INTEGER,
    carbs_total DECIMAL(6,2),
    fiber DECIMAL(6,2),
    sugar DECIMAL(6,2),
    net_carbs DECIMAL(6,2) GENERATED ALWAYS AS (carbs_total - COALESCE(fiber, 0)) STORED,
    protein DECIMAL(6,2),
    fat_total DECIMAL(6,2),
    glycemic_index INTEGER CHECK (glycemic_index IS NULL OR (glycemic_index >= 0 AND glycemic_index <= 100)),
    glycemic_load INTEGER,
    source TEXT NOT NULL
        CHECK (source IN ('user_provided', 'estimated', 'looked_up')),
    confidence TEXT DEFAULT 'high'
        CHECK (confidence IN ('high', 'medium', 'low')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, name_normalized)
);

CREATE INDEX idx_meal_dict_user_name ON cq_meal_dictionary(user_id, name_normalized);

-- RLS Policy
ALTER TABLE cq_meal_dictionary ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own dictionary" ON cq_meal_dictionary
    FOR ALL USING (auth.uid() = user_id);
```

### 3.4 Table: cq_meal_log

```sql
CREATE TABLE cq_meal_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cq_user_profile(user_id),
    artifact_id UUID,  -- Reserved: future Qxb_Artifact integration
    meal_dictionary_id UUID NOT NULL REFERENCES cq_meal_dictionary(id),
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    portion_multiplier DECIMAL(4,2) DEFAULT 1.0 CHECK (portion_multiplier > 0),
    modifiers JSONB DEFAULT '[]'::jsonb,
    meal_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    pre_meal_bs_id UUID REFERENCES cq_blood_sugar_log(id),
    post_meal_bs_id UUID REFERENCES cq_blood_sugar_log(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_meal_log_user_timestamp ON cq_meal_log(user_id, meal_timestamp DESC);
CREATE INDEX idx_meal_log_dictionary ON cq_meal_log(meal_dictionary_id);

-- RLS Policy
ALTER TABLE cq_meal_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own meal logs" ON cq_meal_log
    FOR ALL USING (auth.uid() = user_id);
```

### 3.5 Table: cq_meal_impact

```sql
CREATE TABLE cq_meal_impact (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES cq_user_profile(user_id),
    artifact_id UUID,  -- Reserved: future Qxb_Artifact integration
    meal_dictionary_id UUID NOT NULL REFERENCES cq_meal_dictionary(id),
    meal_log_id UUID NOT NULL REFERENCES cq_meal_log(id) UNIQUE,
    bs_pre INTEGER NOT NULL,
    bs_post INTEGER NOT NULL,
    bs_delta INTEGER GENERATED ALWAYS AS (bs_post - bs_pre) STORED,
    time_elapsed_minutes INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_meal_impact_dictionary ON cq_meal_impact(meal_dictionary_id);
CREATE INDEX idx_meal_impact_user ON cq_meal_impact(user_id);

-- RLS Policy
ALTER TABLE cq_meal_impact ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can only access own impact data" ON cq_meal_impact
    FOR ALL USING (auth.uid() = user_id);
```

### 3.6 View: cq_meal_impact_summary

```sql
CREATE VIEW cq_meal_impact_summary AS
SELECT
    meal_dictionary_id,
    user_id,
    COUNT(*) as sample_count,
    ROUND(AVG(bs_delta), 1) as avg_delta,
    MIN(bs_delta) as min_delta,
    MAX(bs_delta) as max_delta,
    ROUND(STDDEV(bs_delta), 1) as stddev_delta,
    CASE
        WHEN AVG(bs_delta) >= 50 THEN 'high'
        WHEN AVG(bs_delta) >= 30 THEN 'medium'
        ELSE 'low'
    END as impact_level
FROM cq_meal_impact
GROUP BY meal_dictionary_id, user_id;
```

---

## 4. API Actions Catalog

### 4.1 Gateway Action Schema

All requests to CQ Gateway follow this envelope:

```json
{
    "action": "string",       // Action identifier
    "user_id": "uuid",        // From Qwrk auth
    "payload": { ... },       // Action-specific data
    "timestamp": "iso8601"    // Request timestamp
}
```

### 4.2 Action Definitions

All actions use the `cqa1c.` prefix to route through NQxb_Gateway_v1 to CQA1C_Gateway_v1.

| Action | Description | Payload Fields |
|--------|-------------|----------------|
| `cqa1c.bs.log` | Log blood sugar reading | `reading`, `context`, `meal_type?`, `timestamp?` |
| `cqa1c.bs.query` | Query blood sugar history | `range`, `context?`, `limit?` |
| `cqa1c.meal.log` | Log a meal | `meal_name`, `meal_type`, `portion?`, `modifiers?` |
| `cqa1c.meal.dict.get` | Get meal from dictionary | `meal_name` |
| `cqa1c.meal.dict.create` | Create dictionary entry | `name`, `nutrition`, `source` |
| `cqa1c.meal.dict.update` | Update dictionary entry | `id`, `nutrition` |
| `cqa1c.meal.dict.search` | Search dictionary | `query` |
| `cqa1c.meal.impact.query` | Get impact for a meal | `meal_dictionary_id` |
| `cqa1c.report.weekly` | Generate weekly report | `end_date?` |
| `cqa1c.report.monthly` | Generate monthly report | `end_date?` |
| `cqa1c.report.custom` | Generate custom range report | `start_date`, `end_date` |
| `cqa1c.report.a1c` | Get A1C estimate | (none) |
| `cqa1c.user.profile.get` | Get user profile | (none) |
| `cqa1c.user.profile.update` | Update user profile | `fields` |
| `cqa1c.user.onboard` | Complete onboarding | `data` |
| `cqa1c.restaurant.suggest` | Get restaurant suggestions | `restaurant_name`, `meal_type` |
| `cqa1c.export.csv` | Export data as CSV | `range` |

---

## 5. Business Logic Rules

### 5.1 Blood Sugar Context Inference

```
Time of Day → Default Context:
- 05:00-08:00 → wake_up
- 08:00-10:00 → post_meal (breakfast) OR fasting
- 10:00-12:00 → pre_meal (lunch) OR other
- 12:00-14:00 → post_meal (lunch)
- 14:00-17:00 → pre_meal (dinner) OR snack
- 17:00-20:00 → post_meal (dinner)
- 20:00-23:00 → bedtime
- 23:00-05:00 → other (ask user)
```

**IMPORTANT: Write-Once Insert Pattern**

If context cannot be confidently inferred, CQ must ask the user.

**DO NOT insert until context is confirmed:**
- If context is HIGH confidence → insert immediately
- If context is LOW confidence → return `needs_clarification: true` with pending payload
- Insert ONLY after user confirms context

This prevents dirty data from premature inserts.

### 5.2 Blood Sugar Thresholds

| Range (mg/dL) | Classification | CQ Response |
|---------------|----------------|-------------|
| < 70 | LOW (urgent) | Safety warning, suggest fast-acting sugar, refer to doctor |
| 70-80 | Slightly low | Gentle note |
| 80-140 | Target range | Positive reinforcement |
| 141-180 | Elevated | Note it, ask about recent meal |
| 181-250 | High | Coaching tip, track pattern |
| 251-300 | Very high | Concern, suggest checking with doctor |
| > 300 | Critical | Urgent, refer to doctor immediately |

### 5.3 A1C Estimation Rules

**Formula:** `A1C = (avg_blood_sugar + 46.7) / 28.7`

**Data Requirements:**
- Minimum 30 days of data
- Average of 3+ readings per day
- If requirements not met: show progress toward threshold, no estimate

**Output includes:**
- Estimated A1C value
- Comparison to target (if set)
- Comparison to last lab A1C (if provided)
- Trend vs. previous period

### 5.4 Meal Impact Classification

| Avg Delta (mg/dL) | Impact Level | CQ Behavior |
|-------------------|--------------|-------------|
| < 30 | Low | "This meal works well for you" |
| 30-49 | Medium | Neutral |
| 50+ | High | Warn user, suggest mitigation (walk, activity) |

**Minimum samples for classification:** 3 occurrences

### 5.5 Meal Dictionary Matching

1. Normalize input: lowercase, trim whitespace
2. Exact match on `name_normalized`
3. If no exact match, fuzzy search (threshold: 80% similarity)
4. If multiple fuzzy matches, ask user to confirm
5. If no match, prompt to create new entry

---

## 6. Error Handling Strategy

### 6.1 Error Envelope

All errors return this structure:

```json
{
    "ok": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Human-readable message",
        "details": { ... }  // Optional debugging info
    }
}
```

### 6.2 Error Codes

| Code | Meaning | User-Facing Message |
|------|---------|---------------------|
| `VALIDATION_ERROR` | Invalid input | "I couldn't understand that. Could you try again?" |
| `NOT_FOUND` | Resource not found | "I couldn't find that in your records." |
| `DUPLICATE` | Already exists | "You already have [X] in your dictionary." |
| `INSUFFICIENT_DATA` | Not enough data for operation | "I need more readings before I can [do X]." |
| `AUTH_ERROR` | Authentication failed | "I'm having trouble verifying your account." |
| `INTERNAL_ERROR` | System error | "Something went wrong on my end. Let's try again." |

### 6.3 Validation Rules

**Blood Sugar Reading:**
- Must be integer
- Range: 1-699 mg/dL
- Reject 0 or negative

**Meal Name:**
- Min length: 2 characters
- Max length: 200 characters
- No empty strings

**Portion Multiplier:**
- Must be positive number
- Range: 0.1-10.0

**Timestamps:**
- Must be valid ISO 8601
- Cannot be in the future (allow 5 min tolerance)
- Cannot be more than 1 year in the past

---

## 7. Testing Strategy

### 7.1 Test Categories

| Category | Description | Location |
|----------|-------------|----------|
| Unit Tests | Individual function tests | Each workflow node |
| Integration Tests | End-to-end action tests | Gateway level |
| Data Tests | Schema validation, RLS | Supabase |
| Scenario Tests | User journey simulations | Full stack |

### 7.2 Test Data Strategy

**Use real Supabase tables with test user:**
- Create dedicated test user: `test-user-cq-a1c`
- All tests use this user_id
- Cleanup: DELETE by user_id after test suite

**NO MOCKS for:**
- Database operations (use real Supabase)
- API calls (use real n8n webhooks)

**Test Data Fixtures:**
- Blood sugar readings: variety of contexts, ranges
- Meal dictionary: 10 standard meals with full nutrition
- Meal logs: covering all meal types
- Meal impact: pre-computed correlations

### 7.3 Test Cases by Feature

**Blood Sugar Logging:**
1. Log reading with explicit context → success
2. Log reading, infer context from time → correct context
3. Log reading outside normal range → appropriate warning
4. Log reading with future timestamp → reject
5. Log duplicate reading (same time) → handle gracefully

**Meal Dictionary:**
1. Create new meal → success
2. Create duplicate name → DUPLICATE error
3. Search exact match → found
4. Search fuzzy match → suggestions returned
5. Update nutrition → updated, net_carbs recalculated

**Meal Logging:**
1. Log known meal → success, dictionary linked
2. Log unknown meal → prompt to create
3. Log with portion multiplier → nutrition scaled
4. Log with modifiers → stored correctly
5. Link to blood sugar readings → linked

**Meal Impact:**
1. Link pre and post readings → impact calculated
2. Query impact summary → aggregated stats
3. Log high-impact meal → warning returned

**Reports:**
1. Weekly report with data → full report
2. Weekly report insufficient data → partial report with gaps
3. A1C estimate with sufficient data → estimate returned
4. A1C estimate insufficient data → progress shown

---

## 8. Security Considerations

### 8.1 Data Privacy

- All tables use Row-Level Security (RLS)
- User can only access their own data
- No cross-user data access possible at database level
- Health data treated as sensitive (HIPAA-adjacent practices)

### 8.2 Input Validation

- All inputs validated before database operations
- SQL injection prevented via parameterized queries (Supabase SDK)
- JSON payloads validated against schema

### 8.3 Medical Disclaimer

Every response involving health guidance must be prefaced with implicit understanding that:
- CQ is not a medical professional
- CQ does not provide medical advice
- User should consult doctor for medical concerns

For urgent readings (< 70 or > 300), explicit disclaimer required.

---

# PART 2: IMPLEMENTATION BLUEPRINT

---

## Phase Overview

| Phase | Focus | Deliverables | Required for Beta |
|-------|-------|--------------|-------------------|
| 1 | Foundation | Database schema, base Gateway, user profile | YES |
| 2 | Blood Sugar | BS logging, querying, context inference | YES |
| 3 | Meal Dictionary | CRUD operations, search, matching | YES |
| 4 | Meal Logging | Log meals, link to BS, portion/modifiers | YES |
| 5 | Meal Impact | Calculate impact, summarize, warn | YES |
| **BETA GATE** | | *Minimum viable product complete* | *Decision point* |
| 6 | Reports | Weekly, monthly, custom, A1C estimate | YES |
| 7 | Restaurant | Web search, recommendations | **OPTIONAL** |
| 8 | Export | CSV export | YES |
| 9 | Polish | Error handling, edge cases, testing | YES |

**Beta Gate:** After Phase 5, core logging and impact tracking is complete. This is a natural stopping point for an early beta if needed. Phase 6 (reports) and Phase 8 (export) are high-value additions. Phase 7 (restaurant) is nice-to-have and can be deferred.

---

## Detailed Step Breakdown

### PHASE 1: Foundation (Steps 1.1 - 1.5)

**Step 1.1:** Create database tables (cq_user_profile only)
**Step 1.2:** Create CQ Gateway workflow skeleton
**Step 1.3:** Implement user.profile.get action
**Step 1.4:** Implement user.profile.update action
**Step 1.5:** Test user profile CRUD end-to-end

### PHASE 2: Blood Sugar Logging (Steps 2.1 - 2.6)

**Step 2.1:** Create cq_blood_sugar_log table
**Step 2.2:** Implement bs.log action (basic)
**Step 2.3:** Add context inference logic
**Step 2.4:** Add blood sugar threshold responses
**Step 2.5:** Implement bs.query action
**Step 2.6:** Test blood sugar logging end-to-end

### PHASE 3: Meal Dictionary (Steps 3.1 - 3.6)

**Step 3.1:** Create cq_meal_dictionary table
**Step 3.2:** Implement meal.dict.create action
**Step 3.3:** Implement meal.dict.get action (exact match)
**Step 3.4:** Implement meal.dict.search action (fuzzy)
**Step 3.5:** Implement meal.dict.update action
**Step 3.6:** Test meal dictionary end-to-end

### PHASE 4: Meal Logging (Steps 4.1 - 4.5)

**Step 4.1:** Create cq_meal_log table
**Step 4.2:** Implement meal.log action (basic)
**Step 4.3:** Add portion multiplier and modifiers
**Step 4.4:** Add blood sugar linking logic
**Step 4.5:** Test meal logging end-to-end

### PHASE 5: Meal Impact (Steps 5.1 - 5.4)

**Step 5.1:** Create cq_meal_impact table and view
**Step 5.2:** Implement automatic impact calculation on meal link
**Step 5.3:** Implement meal.impact.query action
**Step 5.4:** Add high-impact meal warning logic

### PHASE 6: Reports (Steps 6.1 - 6.5)

**Step 6.1:** Implement report.weekly action
**Step 6.2:** Implement report.monthly action
**Step 6.3:** Implement report.custom action
**Step 6.4:** Implement report.a1c_estimate action
**Step 6.5:** Test all report types

### PHASE 7: Restaurant Suggestions (Steps 7.1 - 7.3)

**Step 7.1:** Implement restaurant.suggest action (web search)
**Step 7.2:** Add diabetic-friendly filtering logic
**Step 7.3:** Format recommendations with tips

### PHASE 8: Export (Steps 8.1 - 8.2)

**Step 8.1:** Implement export.csv action
**Step 8.2:** Test export with all date ranges

### PHASE 9: Polish (Steps 9.1 - 9.3)

**Step 9.1:** Comprehensive error handling audit
**Step 9.2:** Edge case handling
**Step 9.3:** Full scenario testing

---

# PART 3: IMPLEMENTATION PROMPTS

Each prompt below is designed to be given to a code-generation LLM (Claude, ANQ, Qwrk, or yourself) to implement one step. Prompts are sequential and build on each other.

---

## PHASE 1: Foundation

---

### Prompt 1.1: Create User Profile Table

```text
CONTEXT:
We are building Coach Qwrk: A1C, a diabetes management app on the Qwrk platform (n8n + Supabase). This is the first step: creating the user profile table.

TASK:
Create the cq_user_profile table in Supabase with the following requirements:

1. Table name: cq_user_profile
2. Columns:
   - user_id (UUID, PRIMARY KEY) — from Qwrk auth system
   - current_a1c (DECIMAL 3,1) — last known lab A1C, nullable
   - target_a1c (DECIMAL 3,1) — goal A1C, nullable
   - medications (JSONB, default empty array)
   - dietary_restrictions (JSONB, default empty array)
   - personality_style (TEXT, default 'warm_friendly', constrained to: warm_friendly, professional, casual, motivational)
   - onboarding_complete (BOOLEAN, default FALSE)
   - created_at (TIMESTAMPTZ, default NOW())
   - updated_at (TIMESTAMPTZ, default NOW())

3. Enable Row Level Security (RLS)
4. Create policy: users can only access rows where user_id matches their auth.uid()

OUTPUT:
- The complete SQL DDL to run in Supabase SQL editor
- Verify by describing how to test the RLS policy works

DO NOT use mocks. This SQL will be run against real Supabase.
```

---

### Prompt 1.2: Add CQA1C Route to Gateway + Create CQA1C Subworkflow

```text
CONTEXT:
We are building Coach Qwrk: A1C. The user profile table (cq_user_profile) now exists in Supabase. CQA1C runs as a subworkflow of the existing NQxb_Gateway_v1, not as a standalone gateway.

PLATFORM: n8n workflow automation

TASK:
Two parts:

PART A: Update NQxb_Gateway_v1
1. Add a new route to the existing Gateway Switch node
2. Route: actions starting with "cqa1c.*" → Execute Subworkflow node
3. The subworkflow node calls CQA1C_Gateway_v1
4. Pass through: action, user_id, payload, timestamp

PART B: Create CQA1C_Gateway_v1 subworkflow
1. Workflow trigger (called by parent workflow)
   - Receives: action, user_id, payload, timestamp

2. Strip prefix node (Code node)
   - Input: "cqa1c.user.profile.get"
   - Output: "user.profile.get" (for internal routing)

3. Input validation node (Code node)
   - Validate request has: action, user_id, payload
   - Return error envelope if missing required fields

4. Switch node for action routing
   - Initial routes (we'll add more later):
     - user.profile.get
     - user.profile.update
     - default (unknown action → error)

5. Error response node
   - Standard error envelope: { ok: false, error: { code, message } }

5. Success response node template
   - Standard envelope: { ok: true, data: {...} }

OUTPUT:
- Changes to NQxb_Gateway_v1 (new route + subworkflow call)
- CQA1C_Gateway_v1 workflow JSON
- Test instructions

TEST:
Call NQxb_Gateway_v1 webhook with:
{
  "action": "cqa1c.user.profile.get",
  "user_id": "test-user-cq-a1c",
  "payload": {}
}

Verify it routes through to CQA1C_Gateway_v1 and returns a response.
```

---

### Prompt 1.3: Implement cqa1c.user.profile.get Action

```text
CONTEXT:
We have:
- cq_user_profile table in Supabase
- NQxb_Gateway_v1 routing cqa1c.* to CQA1C_Gateway_v1
- CQA1C_Gateway_v1 subworkflow with routing skeleton

TASK:
Implement the cqa1c.user.profile.get action:

1. Add a subworkflow or inline nodes for user.profile.get route in CQA1C_Gateway_v1

2. Logic:
   - Receive user_id from gateway payload
   - Query cq_user_profile WHERE user_id = {{user_id}}
   - If found: return profile data
   - If not found: auto-create profile with defaults, then return it

3. Response format:
   {
     "ok": true,
     "data": {
       "user_id": "...",
       "current_a1c": null,
       "target_a1c": null,
       "medications": [],
       "dietary_restrictions": [],
       "personality_style": "warm_friendly",
       "onboarding_complete": false
     }
   }

4. Error handling:
   - Database errors → INTERNAL_ERROR

OUTPUT:
- Updated workflow JSON or new subworkflow JSON
- SQL used in the Supabase node
- Test payload to verify it works

TEST:
Call NQxb_Gateway_v1 webhook with:
{
  "action": "cqa1c.user.profile.get",
  "user_id": "test-user-cq-a1c",
  "payload": {}
}

Verify profile is returned (or created and returned).
```

---

### Prompt 1.4: Implement cqa1c.user.profile.update Action

```text
CONTEXT:
We have:
- cq_user_profile table
- CQA1C_Gateway_v1 with cqa1c.user.profile.get working

TASK:
Implement the user.profile.update action:

1. Accept payload with optional fields:
   - current_a1c
   - target_a1c
   - medications
   - dietary_restrictions
   - personality_style
   - onboarding_complete

2. Validation:
   - current_a1c: if provided, must be number between 4.0 and 15.0
   - target_a1c: if provided, must be number between 4.0 and 15.0
   - personality_style: if provided, must be one of allowed values
   - Reject unknown fields

3. Logic:
   - UPDATE cq_user_profile SET ... WHERE user_id = {{user_id}}
   - Set updated_at = NOW()
   - Return updated profile

4. Error handling:
   - Validation failure → VALIDATION_ERROR with details
   - User not found → create profile first, then update

OUTPUT:
- Workflow nodes to add
- Validation logic code
- Test payloads for:
  - Valid update (change target_a1c to 6.5)
  - Invalid update (target_a1c = 20, should fail)
  - Update personality_style to 'casual'
```

---

### Prompt 1.5: Test User Profile End-to-End

```text
CONTEXT:
We have user.profile.get and user.profile.update implemented.

TASK:
Create an end-to-end test suite for user profile operations:

1. Test: Get profile for new user
   - Call user.profile.get with new user_id
   - Verify profile created with defaults
   - Verify ok: true

2. Test: Get profile for existing user
   - Call user.profile.get again
   - Verify same profile returned (not duplicated)

3. Test: Update target_a1c
   - Call user.profile.update with target_a1c: 6.5
   - Verify response shows updated value
   - Call user.profile.get, verify persisted

4. Test: Update with invalid a1c
   - Call user.profile.update with target_a1c: 20
   - Verify VALIDATION_ERROR returned

5. Test: Update personality_style
   - Call user.profile.update with personality_style: "casual"
   - Verify success

6. Test: Update with invalid personality_style
   - Call user.profile.update with personality_style: "angry"
   - Verify VALIDATION_ERROR

OUTPUT:
- List of test payloads (JSON)
- Expected responses for each
- Any bugs found and fixes needed

CLEANUP:
After tests, DELETE FROM cq_user_profile WHERE user_id = 'test-user-cq-a1c';
```

---

## PHASE 2: Blood Sugar Logging

---

### Prompt 2.1: Create Blood Sugar Log Table

```text
CONTEXT:
Phase 1 complete. We have CQ Gateway and user profile working.

TASK:
Create the cq_blood_sugar_log table:

1. Table name: cq_blood_sugar_log
2. Columns:
   - id (UUID, PRIMARY KEY, auto-generated)
   - user_id (UUID, FK to cq_user_profile, NOT NULL)
   - reading (INTEGER, NOT NULL, CHECK > 0 AND < 700)
   - context (TEXT, NOT NULL, CHECK IN: wake_up, fasting, pre_meal, post_meal, bedtime, other)
   - meal_type (TEXT, nullable, CHECK IN: breakfast, lunch, dinner, snack)
   - reading_timestamp (TIMESTAMPTZ, NOT NULL, default NOW())
   - linked_meal_log_id (UUID, nullable) — will FK to meal_log later
   - notes (TEXT, nullable)
   - created_at (TIMESTAMPTZ, default NOW())

3. Indexes:
   - idx_bs_log_user_timestamp ON (user_id, reading_timestamp DESC)
   - idx_bs_log_user_context ON (user_id, context)

4. RLS: users can only access own readings

OUTPUT:
- Complete SQL DDL
- Verification query to confirm table exists
```

---

### Prompt 2.2: Implement cqa1c.bs.log Action (Basic)

```text
CONTEXT:
cq_blood_sugar_log table exists. CQA1C Gateway needs the cqa1c.bs.log action.

TASK:
Implement cqa1c.bs.log action:

1. Add route to CQA1C_Gateway_v1 Switch node for "bs.log"

2. Payload schema:
   {
     "reading": 142,           // required, integer
     "context": "post_meal",   // required
     "meal_type": "lunch",     // optional
     "timestamp": "ISO8601",   // optional, defaults to now
     "notes": "felt tired"     // optional
   }

3. Validation:
   - reading: integer, 1-699
   - context: must be valid enum value
   - meal_type: if context is pre_meal or post_meal, meal_type should be provided (prompt if missing)
   - timestamp: if provided, must be valid ISO8601, not in future, not > 1 year old

4. Insert into cq_blood_sugar_log

5. Response:
   {
     "ok": true,
     "data": {
       "id": "uuid",
       "reading": 142,
       "context": "post_meal",
       "message": "Got it! 142 mg/dL logged for post-lunch."
     }
   }

OUTPUT:
- Workflow nodes/code
- Test payloads for valid and invalid inputs
```

---

### Prompt 2.3: Add Context Inference Logic

```text
CONTEXT:
bs.log works with explicit context. Now add smart inference.

TASK:
Add context inference when context is not provided:

1. Create a Code node that infers context from timestamp:
   - 05:00-08:00 → wake_up
   - 08:00-10:00 → post_meal (assume breakfast) OR fasting
   - 10:00-12:00 → pre_meal (lunch coming) OR other
   - 12:00-14:00 → post_meal (lunch)
   - 14:00-17:00 → pre_meal (dinner) OR snack-related
   - 17:00-20:00 → post_meal (dinner)
   - 20:00-23:00 → bedtime
   - 23:00-05:00 → other

2. Confidence levels:
   - High confidence (wake_up, bedtime times) → auto-apply
   - Medium confidence → auto-apply but note in response
   - Low confidence → return needs_clarification: true with options

3. When needs_clarification is true:
   - DO NOT insert into database yet
   - Return pending payload for user confirmation
   - Response should be:
   {
     "ok": true,
     "needs_clarification": true,
     "question": "Was this reading before or after a meal?",
     "options": ["pre_meal", "post_meal", "fasting", "other"],
     "pending_reading": { ... }
   }

4. Only insert after context is confirmed (either auto-inferred with high confidence, or user-confirmed)

OUTPUT:
- Inference logic code
- Test cases for each time window
- Example response for ambiguous time
```

---

### Prompt 2.4: Add Blood Sugar Threshold Responses

```text
CONTEXT:
bs.log works with context inference. Now add threshold-based feedback.

TASK:
Add response logic based on blood sugar ranges:

1. Define thresholds:
   - < 70: LOW_URGENT
   - 70-80: LOW_MILD
   - 80-140: TARGET
   - 141-180: ELEVATED
   - 181-250: HIGH
   - 251-300: VERY_HIGH
   - > 300: CRITICAL

2. Response messages:
   - LOW_URGENT: "That's quite low ({{reading}} mg/dL). If you're feeling shaky, have some fast-acting sugar like juice. If symptoms persist, contact your doctor right away."
   - LOW_MILD: "{{reading}} mg/dL is a little low. How are you feeling?"
   - TARGET: "Nice! {{reading}} mg/dL is right in the target range."
   - ELEVATED: "{{reading}} mg/dL is a bit elevated. Let's track what you ate and look for patterns."
   - HIGH: "{{reading}} mg/dL is high. This might be a good time for a short walk. Let's see if we can identify what caused it."
   - VERY_HIGH: "{{reading}} mg/dL is quite elevated. If this persists, you might want to check in with your doctor."
   - CRITICAL: "{{reading}} mg/dL is very high. Please check with your doctor if you're feeling unwell."

3. Include threshold category in response data for downstream use

OUTPUT:
- Updated response logic
- Test each threshold with sample readings: 65, 75, 120, 155, 200, 280, 350
```

---

### Prompt 2.5: Implement cqa1c.bs.query Action

```text
CONTEXT:
cqa1c.bs.log complete with inference and thresholds. Now add querying.

TASK:
Implement cqa1c.bs.query action:

1. Payload schema:
   {
     "range": "today" | "yesterday" | "week" | "month" | "custom",
     "start_date": "ISO8601",  // required if range = custom
     "end_date": "ISO8601",    // required if range = custom
     "context": "post_meal",   // optional filter
     "limit": 50               // optional, default 50, max 500
   }

2. Range calculations:
   - today: midnight today to now
   - yesterday: midnight yesterday to midnight today
   - week: 7 days ago to now
   - month: 30 days ago to now
   - custom: use provided dates

3. Query cq_blood_sugar_log with filters, ORDER BY reading_timestamp DESC

4. Response:
   {
     "ok": true,
     "data": {
       "readings": [ ... ],
       "summary": {
         "count": 15,
         "average": 142,
         "min": 98,
         "max": 185,
         "in_range_percent": 73
       }
     }
   }

5. Calculate in_range_percent as % of readings between 80-140

OUTPUT:
- Query logic and SQL
- Summary calculation code
- Test: query week, verify summary stats
```

---

### Prompt 2.6: Test Blood Sugar Logging End-to-End

```text
CONTEXT:
Blood sugar logging complete. Time for integration tests.

TASK:
Create test suite for blood sugar features:

1. Setup: Ensure test user exists

2. Tests:
   a. Log reading with explicit context
      - Log: reading=142, context=post_meal, meal_type=lunch
      - Verify: inserted, response message is TARGET range

   b. Log reading, infer context from morning time
      - Log: reading=105, timestamp=07:30
      - Verify: context inferred as wake_up

   c. Log low reading, verify warning
      - Log: reading=65
      - Verify: LOW_URGENT message returned

   d. Log high reading, verify warning
      - Log: reading=310
      - Verify: CRITICAL message returned

   e. Log with invalid reading (negative)
      - Log: reading=-50
      - Verify: VALIDATION_ERROR

   f. Log with future timestamp
      - Log: timestamp=tomorrow
      - Verify: VALIDATION_ERROR

   g. Query today's readings
      - Call bs.query with range=today
      - Verify: returns readings from today only

   h. Query with context filter
      - Call bs.query with context=post_meal
      - Verify: only post_meal readings returned

   i. Verify summary stats
      - Call bs.query with range=week
      - Verify: average, min, max, in_range_percent calculated

3. Cleanup: DELETE FROM cq_blood_sugar_log WHERE user_id = 'test-user-cq-a1c';

OUTPUT:
- All test payloads
- Expected responses
- Any fixes needed
```

---

## PHASE 3: Meal Dictionary

---

### Prompt 3.1: Create Meal Dictionary Table

```text
CONTEXT:
Blood sugar logging complete. Now building meal dictionary.

TASK:
Create cq_meal_dictionary table:

1. Columns:
   - id (UUID, PRIMARY KEY, auto-generated)
   - user_id (UUID, FK, NOT NULL)
   - name (TEXT, NOT NULL)
   - name_normalized (TEXT, NOT NULL) — lowercase, trimmed
   - serving_size (TEXT)
   - calories (INTEGER)
   - carbs_total (DECIMAL 6,2)
   - fiber (DECIMAL 6,2)
   - sugar (DECIMAL 6,2)
   - net_carbs (DECIMAL 6,2, GENERATED AS carbs_total - COALESCE(fiber,0))
   - protein (DECIMAL 6,2)
   - fat_total (DECIMAL 6,2)
   - glycemic_index (INTEGER, CHECK 0-100 if not null)
   - glycemic_load (INTEGER)
   - source (TEXT, NOT NULL, CHECK IN: user_provided, estimated, looked_up)
   - confidence (TEXT, default 'high', CHECK IN: high, medium, low)
   - created_at, updated_at

2. Unique constraint: (user_id, name_normalized)

3. Index on (user_id, name_normalized)

4. RLS: users access own dictionary only

OUTPUT:
- Complete SQL DDL
- Trigger to auto-populate name_normalized on INSERT/UPDATE
```

---

### Prompt 3.2: Implement cqa1c.meal.dict.create Action

```text
CONTEXT:
cq_meal_dictionary table exists.

TASK:
Implement cqa1c.meal.dict.create action:

1. Payload:
   {
     "name": "HEB Cilantro Lime Chicken",
     "serving_size": "5 oz",
     "nutrition": {
       "calories": 180,
       "carbs_total": 3,
       "fiber": 0,
       "sugar": 1,
       "protein": 26,
       "fat_total": 8
     },
     "source": "user_provided",
     "confidence": "high"
   }

2. Validation:
   - name: required, 2-200 chars
   - nutrition: at least calories or carbs_total required
   - source: required, valid enum
   - Check for duplicate name_normalized for this user

3. If duplicate:
   {
     "ok": false,
     "error": {
       "code": "DUPLICATE",
       "message": "You already have 'HEB Cilantro Lime Chicken' in your dictionary.",
       "existing_id": "uuid"
     }
   }

4. On success, return created entry with net_carbs calculated

OUTPUT:
- Workflow nodes
- Duplicate detection logic
- Test: create meal, create duplicate (should fail)
```

---

### Prompt 3.3: Implement cqa1c.meal.dict.get Action (Exact Match)

```text
CONTEXT:
cqa1c.meal.dict.create works.

TASK:
Implement cqa1c.meal.dict.get for exact match lookup:

1. Payload:
   {
     "meal_name": "HEB Cilantro Lime Chicken"
   }

2. Normalize input: lowercase, trim

3. Query: WHERE user_id = X AND name_normalized = Y

4. If found:
   {
     "ok": true,
     "data": {
       "found": true,
       "meal": { ... full meal object ... }
     }
   }

5. If not found:
   {
     "ok": true,
     "data": {
       "found": false,
       "message": "I don't have that meal in your dictionary yet."
     }
   }

OUTPUT:
- Implementation
- Test: get existing meal, get non-existent meal
```

---

### Prompt 3.4: Implement meal.dict.search Action (Fuzzy)

```text
CONTEXT:
Exact match works. Now add fuzzy search.

TASK:
Implement meal.dict.search for fuzzy matching:

1. Payload:
   {
     "query": "cilantro chicken"
   }

2. Search logic:
   - Normalize query
   - Use PostgreSQL similarity or ILIKE patterns
   - Return matches with similarity score
   - Threshold: 0.3 similarity minimum (pg_trgm)

3. Response:
   {
     "ok": true,
     "data": {
       "matches": [
         {
           "id": "uuid",
           "name": "HEB Cilantro Lime Chicken",
           "similarity": 0.85
         },
         {
           "id": "uuid",
           "name": "Cilantro Rice",
           "similarity": 0.45
         }
       ]
     }
   }

4. Limit to top 5 matches

5. If no matches, suggest creating new entry

PREREQUISITE:
Enable pg_trgm extension in Supabase:
CREATE EXTENSION IF NOT EXISTS pg_trgm;

OUTPUT:
- Search query using similarity()
- Test: search "chicken", verify fuzzy matches
```

---

### Prompt 3.5: Implement meal.dict.update Action

```text
CONTEXT:
Dictionary CRUD almost complete. Add update.

TASK:
Implement meal.dict.update:

1. Payload:
   {
     "id": "uuid",
     "updates": {
       "calories": 200,
       "carbs_total": 5
     }
   }

2. Allowed update fields:
   - All nutrition fields
   - serving_size
   - source, confidence
   - NOT: name (would require duplicate check)

3. Validation:
   - id must exist and belong to user
   - nutrition values must be non-negative

4. Update and set updated_at = NOW()

5. Return updated meal with recalculated net_carbs

OUTPUT:
- Implementation
- Test: update calories, verify net_carbs unchanged
- Test: update carbs_total, verify net_carbs recalculated
```

---

### Prompt 3.6: Test Meal Dictionary End-to-End

```text
CONTEXT:
Meal dictionary CRUD complete.

TASK:
Integration tests for meal dictionary:

1. Create meal with full nutrition
   - Verify: created, net_carbs calculated

2. Create duplicate
   - Verify: DUPLICATE error, existing_id returned

3. Get meal (exact match)
   - Verify: found=true, full data returned

4. Get non-existent meal
   - Verify: found=false

5. Search with partial name
   - Verify: fuzzy matches returned with scores

6. Update nutrition
   - Verify: updated, net_carbs recalculated

7. Attempt update on other user's meal
   - Verify: NOT_FOUND (RLS blocks access)

CLEANUP:
DELETE FROM cq_meal_dictionary WHERE user_id = 'test-user-cq-a1c';

OUTPUT:
- Test payloads and expected results
- Any bugs found
```

---

## PHASE 4: Meal Logging

---

### Prompt 4.1: Create Meal Log Table

```text
CONTEXT:
Meal dictionary complete. Now meal logging.

TASK:
Create cq_meal_log table:

1. Columns:
   - id (UUID, PK)
   - user_id (UUID, FK, NOT NULL)
   - meal_dictionary_id (UUID, FK to cq_meal_dictionary, NOT NULL)
   - meal_type (TEXT, NOT NULL, CHECK IN: breakfast, lunch, dinner, snack)
   - portion_multiplier (DECIMAL 4,2, default 1.0, CHECK > 0)
   - modifiers (JSONB, default empty array)
   - meal_timestamp (TIMESTAMPTZ, NOT NULL, default NOW())
   - pre_meal_bs_id (UUID, FK to cq_blood_sugar_log)
   - post_meal_bs_id (UUID, FK to cq_blood_sugar_log)
   - notes (TEXT)
   - created_at

2. Indexes on (user_id, meal_timestamp DESC) and meal_dictionary_id

3. RLS for user isolation

OUTPUT:
- SQL DDL
- Verify FK relationships
```

---

### Prompt 4.2: Implement cqa1c.meal.log Action (Basic)

```text
CONTEXT:
cq_meal_log table ready.

TASK:
Implement cqa1c.meal.log action:

1. Payload:
   {
     "meal_name": "HEB Cilantro Lime Chicken",
     "meal_type": "dinner",
     "timestamp": "ISO8601"  // optional
   }

2. Flow:
   a. Look up meal in dictionary (exact match)
   b. If not found:
      - Return needs_meal_creation: true
      - Include prompt to create meal
   c. If found:
      - Insert into cq_meal_log
      - Return success with logged meal + nutrition summary

3. Response on success:
   {
     "ok": true,
     "data": {
       "id": "uuid",
       "meal_name": "HEB Cilantro Lime Chicken",
       "meal_type": "dinner",
       "nutrition": {
         "calories": 180,
         "carbs_total": 3,
         "net_carbs": 3
       },
       "message": "Logged HEB Cilantro Lime Chicken for dinner (180 cal, 3g net carbs)."
     }
   }

OUTPUT:
- Implementation
- Test: log existing meal, log non-existent meal
```

---

### Prompt 4.3: Add Portion Multiplier and Modifiers

```text
CONTEXT:
Basic meal.log works.

TASK:
Add portion_multiplier and modifiers support:

1. Extended payload:
   {
     "meal_name": "HEB Cilantro Lime Chicken",
     "meal_type": "dinner",
     "portion": 2,      // multiplier, e.g., "double portion"
     "modifiers": [
       {
         "name": "side of rice",
         "carbs_total": 30,
         "calories": 150
       }
     ]
   }

2. Calculate total nutrition:
   - base nutrition * portion_multiplier
   - + sum of modifier nutrition

3. Store modifiers in JSONB

4. Response includes:
   - Base nutrition
   - Modifier nutrition
   - Total nutrition

Example:
"Logged 2x HEB Cilantro Lime Chicken + side of rice for dinner. Total: 510 cal, 36g carbs."

OUTPUT:
- Updated implementation
- Test: log meal with 2x portion
- Test: log meal with modifiers
```

---

### Prompt 4.4: Add Blood Sugar Linking Logic

```text
CONTEXT:
Meal logging with portions/modifiers works.

TASK:
Add logic to link blood sugar readings to meals:

1. Auto-linking:
   - When logging meal, look for pre_meal reading in last 30 minutes
   - If found, link it (pre_meal_bs_id)
   - When logging post_meal blood sugar, look for meal in last 3 hours
   - If found, link it (post_meal_bs_id)

2. Manual linking via payload:
   {
     "meal_name": "...",
     "meal_type": "dinner",
     "pre_meal_bs_id": "uuid",   // explicit link
     "post_meal_bs_id": "uuid"   // explicit link
   }

3. When post_meal reading is logged without linked meal:
   - Return prompt: "Your 2pm reading was 185 — what did you have for lunch?"

4. Update cq_blood_sugar_log.linked_meal_log_id when linking

OUTPUT:
- Auto-link query logic
- Test: log meal, verify auto-link to recent pre_meal reading
- Test: log post_meal reading, verify prompt for meal
```

---

### Prompt 4.5: Test Meal Logging End-to-End

```text
CONTEXT:
Meal logging complete.

TASK:
Integration tests:

1. Setup: Create test meal in dictionary

2. Tests:
   a. Log meal (basic)
   b. Log meal with 2x portion — verify nutrition doubled
   c. Log meal with modifiers — verify total nutrition
   d. Log non-existent meal — verify needs_meal_creation
   e. Log meal, verify auto-link to recent pre_meal reading
   f. Log post_meal reading without meal — verify prompt
   g. Query meals for today — verify data

CLEANUP:
DELETE FROM cq_meal_log WHERE user_id = 'test-user-cq-a1c';

OUTPUT:
- Test suite results
- Any bugs
```

---

## PHASE 5: Meal Impact

---

### Prompt 5.1: Create Meal Impact Table and View

```text
CONTEXT:
Meal logging with blood sugar linking done.

TASK:
Create cq_meal_impact table and summary view:

1. Table: cq_meal_impact
   - id (UUID, PK)
   - user_id (UUID, FK)
   - meal_dictionary_id (UUID, FK)
   - meal_log_id (UUID, FK, UNIQUE)
   - bs_pre (INTEGER, NOT NULL)
   - bs_post (INTEGER, NOT NULL)
   - bs_delta (INTEGER, GENERATED AS bs_post - bs_pre)
   - time_elapsed_minutes (INTEGER, NOT NULL)
   - created_at

2. RLS for user isolation

3. View: cq_meal_impact_summary
   SELECT
     meal_dictionary_id,
     user_id,
     COUNT(*) as sample_count,
     ROUND(AVG(bs_delta), 1) as avg_delta,
     MIN(bs_delta) as min_delta,
     MAX(bs_delta) as max_delta,
     CASE
       WHEN AVG(bs_delta) >= 50 THEN 'high'
       WHEN AVG(bs_delta) >= 30 THEN 'medium'
       ELSE 'low'
     END as impact_level
   FROM cq_meal_impact
   GROUP BY meal_dictionary_id, user_id;

OUTPUT:
- SQL DDL
- Verify view works
```

---

### Prompt 5.2: Implement Automatic Impact Calculation

```text
CONTEXT:
Impact table and view exist.

TASK:
Trigger impact calculation when meal_log has both pre and post readings:

1. Create n8n logic or Supabase trigger:
   - When cq_meal_log.post_meal_bs_id is set (and pre_meal_bs_id exists)
   - Query both blood sugar readings
   - Calculate time_elapsed_minutes
   - Insert into cq_meal_impact

2. Only insert if:
   - time_elapsed >= 60 minutes (minimum)
   - time_elapsed <= 240 minutes (maximum 4 hours)

3. Avoid duplicates: meal_log_id is UNIQUE

OUTPUT:
- Implementation (n8n node or Supabase function)
- Test: link both readings to meal, verify impact created
```

---

### Prompt 5.3: Implement meal.impact.query Action

```text
CONTEXT:
Impact data is being collected.

TASK:
Implement meal.impact.query:

1. Payload:
   {
     "meal_dictionary_id": "uuid"  // optional, omit for all meals
   }

2. If meal_dictionary_id provided:
   - Return impact data for that meal
   - Include sample_count, avg_delta, impact_level

3. If omitted:
   - Return summary for all meals with impact data
   - Sorted by avg_delta descending (worst first)

4. Response:
   {
     "ok": true,
     "data": {
       "impacts": [
         {
           "meal_name": "HEB Cilantro Lime Chicken",
           "meal_dictionary_id": "uuid",
           "sample_count": 5,
           "avg_delta": 25,
           "impact_level": "low"
         }
       ]
     }
   }

OUTPUT:
- Implementation
- Test: query all impacts, query specific meal
```

---

### Prompt 5.4: Add High-Impact Meal Warning Logic

```text
CONTEXT:
Impact tracking works.

TASK:
Add warning when user logs high-impact meal:

1. When meal.log is called:
   - Check cq_meal_impact_summary for this meal
   - If impact_level = 'high' and sample_count >= 3:
     - Include warning in response

2. Warning message:
   "Heads up: This meal has caused blood sugar spikes for you before (avg +{{avg_delta}} mg/dL). Consider taking a short walk after eating or doing some pushups to help manage the spike."

3. Include warning as separate field:
   {
     "ok": true,
     "data": {
       ...meal data...,
       "impact_warning": {
         "level": "high",
         "avg_delta": 55,
         "message": "..."
       }
     }
   }

OUTPUT:
- Implementation
- Test: log high-impact meal, verify warning appears
```

---

## PHASE 6: Reports

---

### Prompt 6.1: Implement cqa1c.report.weekly Action

```text
CONTEXT:
All logging complete. Now reporting.

TASK:
Implement cqa1c.report.weekly:

1. Payload:
   {
     "end_date": "ISO8601"  // optional, defaults to today
   }

2. Calculate date range: end_date - 7 days to end_date

3. Gather data:
   - Blood sugar readings for week
   - Meals logged for week
   - Impact data for meals eaten

4. Generate report sections:

   a. Blood Sugar Summary:
      - Average, min, max
      - Count of readings
      - Time-in-range % (80-140)
      - Comparison to previous week (if data exists)

   b. Meal Insights:
      - Top 3 best meals (lowest avg_delta)
      - Top 3 worst meals (highest avg_delta)
      - Most frequently eaten meals

   c. Progress:
      - Trend vs last week
      - Logging consistency: "You logged X of Y meals"

   d. Coaching Tip:
      - Generate personalized tip based on data
      - E.g., if post-dinner spikes common: "Try a 10-min walk after dinner"

5. Response includes all sections as structured data

OUTPUT:
- Implementation with all sections
- Test: generate report with sample data
```

---

### Prompt 6.2: Implement report.monthly Action

```text
CONTEXT:
Weekly report done.

TASK:
Implement report.monthly:

1. Similar to weekly but 30-day range
2. Add additional insights:
   - Week-over-week trends
   - Best week vs worst week
3. If 30+ days data: include preliminary A1C trend

OUTPUT:
- Implementation
- Reuse weekly report logic where possible
```

---

### Prompt 6.3: Implement report.custom Action

```text
CONTEXT:
Weekly and monthly done.

TASK:
Implement report.custom:

1. Payload:
   {
     "start_date": "ISO8601",
     "end_date": "ISO8601"
   }

2. Validate:
   - end_date > start_date
   - Range <= 365 days
   - Dates not in future

3. Generate report for custom range using same logic as weekly/monthly

OUTPUT:
- Implementation
- Test: 2-week custom range
```

---

### Prompt 6.4: Implement report.a1c_estimate Action

```text
CONTEXT:
Reports working.

TASK:
Implement report.a1c_estimate:

1. Formula: A1C = (avg_blood_sugar + 46.7) / 28.7

2. Data requirements:
   - Minimum 30 days of readings
   - Minimum 3 readings per day average (total >= 90 readings)

3. If requirements NOT met:
   {
     "ok": true,
     "data": {
       "can_estimate": false,
       "reason": "insufficient_data",
       "progress": {
         "days_with_data": 22,
         "days_required": 30,
         "readings_count": 58,
         "readings_required": 90
       },
       "message": "I need 8 more days of readings (at least 3/day) before I can estimate your A1C."
     }
   }

4. If requirements met:
   {
     "ok": true,
     "data": {
       "can_estimate": true,
       "estimated_a1c": 6.8,
       "average_blood_sugar": 148,
       "data_quality": {
         "days_with_data": 35,
         "total_readings": 112,
         "readings_per_day_avg": 3.2
       },
       "comparison": {
         "target_a1c": 6.5,
         "vs_target": "+0.3",
         "last_lab_a1c": 7.2,
         "vs_lab": "-0.4"
       },
       "message": "Based on 35 days of readings, your estimated A1C is 6.8%. That's 0.4% lower than your last lab result!"
     }
   }

OUTPUT:
- Implementation
- Test: insufficient data scenario
- Test: sufficient data scenario
```

---

### Prompt 6.5: Test All Report Types

```text
CONTEXT:
All reports implemented.

TASK:
Integration tests for reports:

1. Setup:
   - Create 45 days of test blood sugar readings (3-4/day)
   - Create 10 meals in dictionary
   - Log 40 meals with pre/post readings

2. Tests:
   a. Weekly report — verify all 4 sections populated
   b. Monthly report — verify week-over-week data
   c. Custom 2-week report — verify date range honored
   d. A1C estimate with sufficient data — verify calculation
   e. A1C estimate with new user (no data) — verify insufficient message

CLEANUP:
- Delete all test data

OUTPUT:
- Test results
- Sample report outputs
```

---

## PHASE 7: Restaurant Suggestions

---

### Prompt 7.1: Implement cqa1c.restaurant.suggest Action (Web Search)

```text
CONTEXT:
Reports complete. Now restaurant suggestions.

TASK:
Implement cqa1c.restaurant.suggest:

1. Payload:
   {
     "restaurant_name": "Chili's",
     "meal_type": "lunch"
   }

2. Use web search (n8n HTTP Request) to find restaurant menu:
   - Search query: "[restaurant] menu nutrition information"
   - Parse results for menu items

3. For MVP, if web search is complex:
   - Use web search to get general info
   - Let GPT front-end interpret and recommend based on diabetic-friendly criteria

4. Criteria for recommendations:
   - Low carb (< 30g preferred)
   - High protein
   - Avoid fried/breaded items
   - Look for grilled, steamed options

5. Response format:
   {
     "ok": true,
     "data": {
       "restaurant": "Chili's",
       "recommendations": [
         {
           "item": "6oz Classic Sirloin with steamed broccoli",
           "why": "High protein, low carb, no added sugars",
           "tips": ["Skip the loaded mashed potatoes", "Ask for steamed veggies instead of fries"]
         }
       ],
       "avoid": [
         {
           "item": "Honey-Chipotle Chicken Crispers",
           "why": "Breaded and high in sugar from honey glaze"
         }
       ]
     }
   }

OUTPUT:
- Implementation approach
- Web search configuration
- Test with "Chili's"
```

---

### Prompt 7.2-7.3: Polish Restaurant Suggestions

```text
CONTEXT:
Basic restaurant.suggest working.

TASK:
Add polish:

1. Cache results for common restaurants (optional, future)

2. Format recommendations with:
   - 3 recommended items
   - 2 items to avoid
   - 2-3 modification tips

3. Handle unknown restaurants:
   - Return general tips for dining out
   - "I couldn't find specific menu info for [restaurant], but here are general tips for eating out as a diabetic..."

4. Handle chain vs local:
   - Chains: more likely to have nutrition info
   - Local: general guidance

OUTPUT:
- Final implementation
- Test with obscure restaurant name
```

---

## PHASE 8: Export

---

### Prompt 8.1: Implement cqa1c.export.csv Action

```text
CONTEXT:
Core features complete. Add export.

TASK:
Implement cqa1c.export.csv:

1. Payload:
   {
     "range": "30_days" | "90_days" | "all"
   }

2. Query cq_blood_sugar_log for date range

3. Generate CSV with columns:
   - date
   - time
   - reading
   - context
   - meal_type
   - notes

4. Return CSV data (or URL if stored):
   {
     "ok": true,
     "data": {
       "format": "csv",
       "row_count": 95,
       "csv_content": "date,time,reading,context,meal_type,notes\n2026-01-28,08:30,142,wake_up,,\n..."
     }
   }

5. For large exports, consider:
   - Supabase storage + signed URL
   - For MVP: inline CSV is fine

OUTPUT:
- Implementation
- Test: export 30 days
```

---

### Prompt 8.2: Test Export

```text
CONTEXT:
Export implemented.

TASK:
Test export functionality:

1. Create 100 blood sugar readings across 40 days

2. Tests:
   a. Export 30_days — verify count and date range
   b. Export 90_days — verify includes all data
   c. Export all — verify complete export
   d. Verify CSV format is valid (can be opened in spreadsheet)
   e. Verify context and meal_type columns populated correctly

CLEANUP:
- Delete test data

OUTPUT:
- Test results
- Sample CSV output
```

---

## PHASE 9: Polish

---

### Prompt 9.1: Comprehensive Error Handling Audit

```text
CONTEXT:
All features implemented. Now polish.

TASK:
Audit all actions for proper error handling:

1. For each action, verify:
   - Input validation returns VALIDATION_ERROR with details
   - Database errors return INTERNAL_ERROR
   - Not found cases return NOT_FOUND
   - Duplicate cases return DUPLICATE

2. Ensure error messages are user-friendly

3. Add logging for errors (n8n error workflow or logging node)

4. Create error response utility that all actions use

OUTPUT:
- Audit results
- Any fixes needed
- Standardized error handling code
```

---

### Prompt 9.2: Edge Case Handling

```text
CONTEXT:
Error handling audited.

TASK:
Handle edge cases:

1. Empty states:
   - New user with no data → helpful onboarding messages
   - Report with no data in range → clear message, not error

2. Boundary conditions:
   - Exactly 30 days of data for A1C estimate
   - Meal at midnight (which day?)
   - Timezone handling

3. Data integrity:
   - Orphaned meal_log (dictionary entry deleted) — handle gracefully
   - Duplicate readings at same timestamp — prevent or merge

4. Large data:
   - User with 10,000 readings — pagination, performance

OUTPUT:
- Edge case fixes
- Additional validation rules
```

---

### Prompt 9.3: Full Scenario Testing

```text
CONTEXT:
All polish complete.

TASK:
Run full user journey scenarios:

1. Scenario: New User Onboarding
   - Get profile (auto-created)
   - Complete onboarding
   - Log first blood sugar
   - Log first meal
   - Get feedback

2. Scenario: Daily Usage
   - Log wake-up reading
   - Log breakfast
   - Log post-breakfast reading
   - Log lunch
   - Log post-lunch reading
   - Log dinner
   - Log bedtime reading
   - Request daily summary

3. Scenario: Restaurant Outing
   - Ask for Chili's recommendations
   - Log meal from Chili's
   - Log post-meal reading
   - See impact recorded

4. Scenario: Weekly Review
   - Request weekly report
   - Check A1C estimate progress
   - Export data for doctor

5. Scenario: High Impact Warning
   - Log meal known to cause spikes
   - Verify warning appears

Verify all scenarios complete without errors.

OUTPUT:
- Scenario test results
- Any final bugs
- Sign-off for beta launch
```

---

# PART 4: SUMMARY CHECKLIST

## Pre-Launch Checklist

- [ ] All 5 Supabase tables created with RLS
- [ ] CQ Gateway workflow deployed
- [ ] All 16 actions implemented and tested
- [ ] Error handling standardized
- [ ] Edge cases handled
- [ ] Full scenario tests passed
- [ ] CustomGPT instructions written
- [ ] Test user data cleaned up
- [ ] Production user_id flow confirmed (depends on Qwrk auth)

## Dependencies Blocking Launch

1. **Qwrk User Authentication** — required for user_id in production
2. **CustomGPT Configuration** — instructions and action mappings

---

*End of PRD and Implementation Blueprint*
