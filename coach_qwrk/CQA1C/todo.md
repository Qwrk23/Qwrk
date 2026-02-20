# Coach Qwrk: A1C — Implementation Checklist

**Created:** 2026-01-28
**Status:** Not Started
**Last Updated:** 2026-01-28
**PRD Version:** 1.2 (Locked)

---

## QP1 Review Refinements (v1.1)

These items were added based on QP1's sanity check review:

- [x] Add `artifact_id UUID` column to all cq_* tables (future Qxb integration)
- [x] Add `profile_version INT` to cq_user_profile (future multi-track support)
- [x] Update bs.log to NOT insert until context confirmed (write-once pattern)
- [x] Mark Phase 7 (Restaurant) as Beta-Optional
- [x] Add Beta Gate after Phase 5
- [x] Lock PRD as v1.1

## Architecture Refinement (v1.2)

- [x] CQA1C runs as subworkflow of NQxb_Gateway_v1 (not standalone)
- [x] All actions prefixed with `cqa1c.*` (e.g., `cqa1c.bs.log`)
- [x] Pattern supports future Coach Qwrk apps (cqfitness.*, cqsleep.*, etc.)
- [x] Lock PRD as v1.2

---

## How to Use This Checklist

- Mark items complete by changing `[ ]` to `[x]`
- Add completion date in parentheses: `[x] Task (2026-01-29)`
- Add notes under any item as needed
- Update "Last Updated" date when making changes

---

## Pre-Implementation

### Dependencies Check
- [ ] Confirm Supabase project access
- [ ] Confirm n8n instance access
- [ ] Confirm Qwrk Gateway pattern available for reference
- [ ] Review existing Qwrk authentication plans
- [ ] Set up test user ID: `test-user-cq-a1c`

### Documentation Review
- [ ] Read through full PRD (PRD_Coach_Qwrk_A1C_v1.md)
- [ ] Review the_seed.md for context
- [ ] Confirm all requirements are understood
- [ ] Identify any open questions before starting

---

## Phase 1: Foundation

### Step 1.1: Create User Profile Table
- [ ] Write SQL DDL for cq_user_profile
- [ ] Include `profile_version INT DEFAULT 1` column
- [ ] Include `artifact_id UUID` column (nullable, reserved)
- [ ] Create table in Supabase
- [ ] Add CHECK constraint for personality_style
- [ ] Enable Row Level Security (RLS)
- [ ] Create RLS policy for user isolation
- [ ] Verify table structure with \d command
- [ ] Test RLS policy works correctly
- [ ] Document any deviations from spec

### Step 1.2: Add CQA1C Route to Gateway + Create Subworkflow
- [ ] **Update NQxb_Gateway_v1:**
  - [ ] Add route for `cqa1c.*` actions in Switch node
  - [ ] Add Execute Subworkflow node → CQA1C_Gateway_v1
  - [ ] Pass through: action, user_id, payload, timestamp
- [ ] **Create CQA1C_Gateway_v1 subworkflow:**
  - [ ] Add Workflow trigger (receives data from parent)
  - [ ] Add prefix stripper Code node (cqa1c.user.profile.get → user.profile.get)
  - [ ] Add input validation Code node
  - [ ] Add Switch node for action routing
  - [ ] Add error response template node
  - [ ] Add success response template node
- [ ] Test: call NQxb_Gateway_v1 with `cqa1c.user.profile.get`
- [ ] Verify routing works end-to-end
- [ ] Document workflow connection

### Step 1.3: Implement cqa1c.user.profile.get
- [ ] Add route in CQA1C_Gateway_v1 Switch node for user.profile.get
- [ ] Create Supabase query node for SELECT
- [ ] Add logic to auto-create profile if not exists
- [ ] Format success response
- [ ] Handle database errors
- [ ] Test: `cqa1c.user.profile.get` for new user
- [ ] Test: `cqa1c.user.profile.get` for existing user
- [ ] Verify response format matches spec

### Step 1.4: Implement cqa1c.user.profile.update
- [ ] Add route in CQA1C_Gateway_v1 Switch node for user.profile.update
- [ ] Create validation logic for input fields
  - [ ] Validate current_a1c range (4.0-15.0)
  - [ ] Validate target_a1c range (4.0-15.0)
  - [ ] Validate personality_style enum
  - [ ] Reject unknown fields
- [ ] Create Supabase UPDATE node
- [ ] Set updated_at = NOW()
- [ ] Return updated profile
- [ ] Test: valid update (change target_a1c)
- [ ] Test: invalid update (target_a1c = 20)
- [ ] Test: update personality_style
- [ ] Test: invalid personality_style

### Step 1.5: Test User Profile End-to-End
- [ ] Run full test suite for user profile
- [ ] Document any bugs found
- [ ] Fix all bugs
- [ ] Re-run tests until all pass
- [ ] Clean up test data
- [ ] Mark Phase 1 complete

---

## Phase 2: Blood Sugar Logging

### Step 2.1: Create Blood Sugar Log Table
- [ ] Write SQL DDL for cq_blood_sugar_log
- [ ] Include `artifact_id UUID` column (nullable, reserved)
- [ ] Add CHECK constraint for reading (1-699)
- [ ] Add CHECK constraint for context enum
- [ ] Add CHECK constraint for meal_type enum
- [ ] Create table in Supabase
- [ ] Create index: idx_bs_log_user_timestamp
- [ ] Create index: idx_bs_log_user_context
- [ ] Enable RLS
- [ ] Create RLS policy
- [ ] Verify table structure
- [ ] Test RLS policy

### Step 2.2: Implement bs.log (Basic)
- [ ] Add route in Switch node for bs.log
- [ ] Create validation logic
  - [ ] Validate reading is integer
  - [ ] Validate reading range (1-699)
  - [ ] Validate context enum
  - [ ] Validate meal_type if provided
  - [ ] Validate timestamp format
  - [ ] Reject future timestamps
  - [ ] Reject timestamps > 1 year old
- [ ] Create Supabase INSERT node
- [ ] Format success response with message
- [ ] Test: log with explicit context
- [ ] Test: log with invalid reading
- [ ] Test: log with future timestamp

### Step 2.3: Add Context Inference
- [ ] Create context inference Code node
- [ ] Implement time-of-day rules:
  - [ ] 05:00-08:00 → wake_up
  - [ ] 08:00-10:00 → post_meal/fasting
  - [ ] 10:00-12:00 → pre_meal/other
  - [ ] 12:00-14:00 → post_meal (lunch)
  - [ ] 14:00-17:00 → pre_meal/snack
  - [ ] 17:00-20:00 → post_meal (dinner)
  - [ ] 20:00-23:00 → bedtime
  - [ ] 23:00-05:00 → other
- [ ] Implement confidence levels (HIGH/LOW)
- [ ] **WRITE-ONCE PATTERN:**
  - [ ] If HIGH confidence → insert immediately
  - [ ] If LOW confidence → DO NOT INSERT
  - [ ] Return needs_clarification with pending payload
  - [ ] Insert ONLY after user confirms context
- [ ] Test each time window
- [ ] Test ambiguous time response
- [ ] Verify no premature inserts on low confidence

### Step 2.4: Add Blood Sugar Thresholds
- [ ] Create threshold classification logic
- [ ] Implement response messages:
  - [ ] LOW_URGENT (< 70)
  - [ ] LOW_MILD (70-80)
  - [ ] TARGET (80-140)
  - [ ] ELEVATED (141-180)
  - [ ] HIGH (181-250)
  - [ ] VERY_HIGH (251-300)
  - [ ] CRITICAL (> 300)
- [ ] Include threshold in response data
- [ ] Test reading: 65 (LOW_URGENT)
- [ ] Test reading: 75 (LOW_MILD)
- [ ] Test reading: 120 (TARGET)
- [ ] Test reading: 155 (ELEVATED)
- [ ] Test reading: 200 (HIGH)
- [ ] Test reading: 280 (VERY_HIGH)
- [ ] Test reading: 350 (CRITICAL)

### Step 2.5: Implement bs.query
- [ ] Add route for bs.query
- [ ] Create validation for payload
  - [ ] Validate range enum
  - [ ] Validate custom date range if provided
  - [ ] Validate limit (max 500)
- [ ] Implement date range calculations:
  - [ ] today
  - [ ] yesterday
  - [ ] week
  - [ ] month
  - [ ] custom
- [ ] Create Supabase SELECT with filters
- [ ] Calculate summary stats:
  - [ ] count
  - [ ] average
  - [ ] min
  - [ ] max
  - [ ] in_range_percent (80-140)
- [ ] Test: query today
- [ ] Test: query week
- [ ] Test: query with context filter
- [ ] Verify summary calculations

### Step 2.6: Test Blood Sugar End-to-End
- [ ] Create comprehensive test data
- [ ] Run all blood sugar tests
- [ ] Document bugs
- [ ] Fix bugs
- [ ] Re-run tests
- [ ] Clean up test data
- [ ] Mark Phase 2 complete

---

## Phase 3: Meal Dictionary

### Step 3.1: Create Meal Dictionary Table
- [ ] Write SQL DDL for cq_meal_dictionary
- [ ] Include `artifact_id UUID` column (nullable, reserved)
- [ ] Add name_normalized column
- [ ] Add net_carbs as GENERATED column
- [ ] Add CHECK for glycemic_index (0-100)
- [ ] Add CHECK for source enum
- [ ] Add CHECK for confidence enum
- [ ] Add UNIQUE constraint (user_id, name_normalized)
- [ ] Create table in Supabase
- [ ] Create index on (user_id, name_normalized)
- [ ] Enable RLS + policy
- [ ] Create trigger for name_normalized
- [ ] Verify net_carbs calculation works
- [ ] Enable pg_trgm extension for fuzzy search

### Step 3.2: Implement meal.dict.create
- [ ] Add route for meal.dict.create
- [ ] Create validation logic:
  - [ ] name: 2-200 chars
  - [ ] nutrition: at least calories or carbs
  - [ ] source: valid enum
- [ ] Normalize name for storage
- [ ] Check for duplicates
- [ ] Return DUPLICATE error if exists
- [ ] Create Supabase INSERT node
- [ ] Return created entry with net_carbs
- [ ] Test: create meal with full nutrition
- [ ] Test: create duplicate (should fail)

### Step 3.3: Implement meal.dict.get (Exact)
- [ ] Add route for meal.dict.get
- [ ] Normalize input name
- [ ] Query with exact match on name_normalized
- [ ] Return found: true with meal data
- [ ] Return found: false if not exists
- [ ] Test: get existing meal
- [ ] Test: get non-existent meal

### Step 3.4: Implement meal.dict.search (Fuzzy)
- [ ] Add route for meal.dict.search
- [ ] Implement similarity search using pg_trgm
- [ ] Set similarity threshold (0.3)
- [ ] Return top 5 matches with scores
- [ ] Handle no matches case
- [ ] Test: search partial name
- [ ] Test: search with typo
- [ ] Test: search no matches

### Step 3.5: Implement meal.dict.update
- [ ] Add route for meal.dict.update
- [ ] Validate id exists and belongs to user
- [ ] Validate update fields:
  - [ ] nutrition values non-negative
  - [ ] source/confidence valid if provided
- [ ] Disallow name updates
- [ ] Update and set updated_at
- [ ] Return updated meal
- [ ] Verify net_carbs recalculated
- [ ] Test: update calories
- [ ] Test: update carbs (verify net_carbs)
- [ ] Test: update someone else's meal (should fail)

### Step 3.6: Test Meal Dictionary End-to-End
- [ ] Run full dictionary test suite
- [ ] Fix any bugs
- [ ] Clean up test data
- [ ] Mark Phase 3 complete

---

## Phase 4: Meal Logging

### Step 4.1: Create Meal Log Table
- [ ] Write SQL DDL for cq_meal_log
- [ ] Include `artifact_id UUID` column (nullable, reserved)
- [ ] Add FK to cq_meal_dictionary
- [ ] Add FK to cq_blood_sugar_log (pre/post)
- [ ] Add CHECK for meal_type enum
- [ ] Add CHECK for portion_multiplier > 0
- [ ] Create table in Supabase
- [ ] Create indexes
- [ ] Enable RLS + policy
- [ ] Verify FK constraints work

### Step 4.2: Implement meal.log (Basic)
- [ ] Add route for meal.log
- [ ] Look up meal in dictionary
- [ ] If not found: return needs_meal_creation
- [ ] If found: insert into meal_log
- [ ] Return success with nutrition summary
- [ ] Test: log existing meal
- [ ] Test: log non-existent meal

### Step 4.3: Add Portion and Modifiers
- [ ] Add portion_multiplier handling
- [ ] Calculate scaled nutrition
- [ ] Add modifiers array handling
- [ ] Calculate total nutrition (base + modifiers)
- [ ] Store modifiers in JSONB
- [ ] Include breakdown in response
- [ ] Test: log with 2x portion
- [ ] Test: log with modifiers
- [ ] Test: log with both

### Step 4.4: Add Blood Sugar Linking
- [ ] Implement auto-link for pre_meal reading (last 30 min)
- [ ] Implement auto-link for post_meal reading (meal in last 3 hrs)
- [ ] Support manual linking via payload
- [ ] Update blood_sugar_log.linked_meal_log_id
- [ ] Prompt for meal when post_meal reading has no meal
- [ ] Test: auto-link pre_meal reading
- [ ] Test: manual linking
- [ ] Test: prompt for missing meal

### Step 4.5: Test Meal Logging End-to-End
- [ ] Create test meals in dictionary
- [ ] Run all meal logging tests
- [ ] Verify linking works correctly
- [ ] Fix bugs
- [ ] Clean up test data
- [ ] Mark Phase 4 complete

---

## Phase 5: Meal Impact

### Step 5.1: Create Impact Table and View
- [ ] Write SQL DDL for cq_meal_impact
- [ ] Include `artifact_id UUID` column (nullable, reserved)
- [ ] Add bs_delta as GENERATED column
- [ ] Add UNIQUE constraint on meal_log_id
- [ ] Create table in Supabase
- [ ] Create indexes
- [ ] Enable RLS + policy
- [ ] Create cq_meal_impact_summary view
- [ ] Verify view calculates correctly
- [ ] Verify impact_level classification

### Step 5.2: Implement Automatic Impact Calculation
- [ ] Create logic to detect when both BS readings linked
- [ ] Query both blood sugar values
- [ ] Calculate time_elapsed_minutes
- [ ] Validate time range (60-240 minutes)
- [ ] Insert into cq_meal_impact
- [ ] Prevent duplicates
- [ ] Test: link both readings, verify impact created
- [ ] Test: time outside range, no impact created

### Step 5.3: Implement meal.impact.query
- [ ] Add route for meal.impact.query
- [ ] Query by specific meal_dictionary_id
- [ ] Query all meals if id not provided
- [ ] Join with meal_dictionary for names
- [ ] Sort by avg_delta descending
- [ ] Return impact data with levels
- [ ] Test: query specific meal
- [ ] Test: query all impacts

### Step 5.4: Add High-Impact Warning
- [ ] Check impact summary when logging meal
- [ ] If impact_level = 'high' AND sample_count >= 3:
  - [ ] Include warning in response
  - [ ] Add mitigation tips (walk, pushups)
- [ ] Format warning message
- [ ] Test: log high-impact meal, verify warning
- [ ] Test: log low-impact meal, no warning
- [ ] Mark Phase 5 complete

---

## BETA GATE (Decision Point)

**After Phase 5, core functionality is complete:**
- Blood sugar logging with context inference
- Meal dictionary with fuzzy search
- Meal logging with portions/modifiers
- Blood sugar ↔ meal linking
- Meal impact tracking with warnings

**Decision:** Ship early beta here, or continue to Phase 6+?

- [ ] Review Phase 1-5 completion
- [ ] Run full integration tests
- [ ] Decide: ship beta now OR continue
- [ ] If shipping: document known limitations
- [ ] If continuing: proceed to Phase 6

---

## Phase 6: Reports

### Step 6.1: Implement report.weekly
- [ ] Add route for report.weekly
- [ ] Calculate 7-day date range
- [ ] Query blood sugar data for range
- [ ] Query meal data for range
- [ ] Generate Blood Sugar Summary:
  - [ ] Average, min, max
  - [ ] Reading count
  - [ ] Time-in-range %
  - [ ] Comparison to previous week
- [ ] Generate Meal Insights:
  - [ ] Top 3 best meals
  - [ ] Top 3 worst meals
  - [ ] Most frequent meals
- [ ] Generate Progress section:
  - [ ] Trend vs last week
  - [ ] Logging consistency
- [ ] Generate Coaching Tip:
  - [ ] Analyze patterns
  - [ ] Personalized suggestion
- [ ] Test: generate with sample data
- [ ] Verify all sections populated

### Step 6.2: Implement report.monthly
- [ ] Add route for report.monthly
- [ ] Calculate 30-day date range
- [ ] Reuse weekly report logic
- [ ] Add week-over-week trends
- [ ] Add best/worst week comparison
- [ ] Add preliminary A1C trend (if 30+ days)
- [ ] Test: generate monthly report

### Step 6.3: Implement report.custom
- [ ] Add route for report.custom
- [ ] Validate start_date and end_date
- [ ] Validate range <= 365 days
- [ ] Validate dates not in future
- [ ] Generate report for custom range
- [ ] Test: 2-week custom range
- [ ] Test: invalid range (should fail)

### Step 6.4: Implement report.a1c_estimate
- [ ] Add route for report.a1c_estimate
- [ ] Query reading count and date range
- [ ] Check data requirements:
  - [ ] Minimum 30 days
  - [ ] Minimum 90 readings (3/day avg)
- [ ] If insufficient: return progress message
- [ ] If sufficient: calculate estimate
  - [ ] Formula: (avg + 46.7) / 28.7
  - [ ] Compare to target
  - [ ] Compare to last lab A1C
- [ ] Format response message
- [ ] Test: insufficient data
- [ ] Test: sufficient data

### Step 6.5: Test All Reports
- [ ] Create 45 days of test data
- [ ] Test weekly report
- [ ] Test monthly report
- [ ] Test custom range report
- [ ] Test A1C estimate (both scenarios)
- [ ] Verify all calculations correct
- [ ] Clean up test data
- [ ] Mark Phase 6 complete

---

## Phase 7: Restaurant Suggestions (BETA-OPTIONAL)

**Note:** This phase is nice-to-have for beta. Core value is delivered by Phases 1-6. Skip this phase if timeline is tight.

### Step 7.1: Implement restaurant.suggest
- [ ] Add route for restaurant.suggest
- [ ] Configure web search HTTP node
- [ ] Search for "[restaurant] menu nutrition"
- [ ] Parse search results
- [ ] Apply diabetic-friendly criteria:
  - [ ] Low carb (< 30g)
  - [ ] High protein
  - [ ] Avoid fried/breaded
  - [ ] Look for grilled/steamed
- [ ] Format recommendations (3 items)
- [ ] Format avoid list (2 items)
- [ ] Add modification tips
- [ ] Test: search "Chili's"

### Step 7.2: Handle Unknown Restaurants
- [ ] Detect when no specific menu found
- [ ] Return general dining tips
- [ ] Format helpful fallback message
- [ ] Test: obscure restaurant name

### Step 7.3: Polish Restaurant Feature
- [ ] Refine recommendation format
- [ ] Add meal_type context to search
- [ ] Test multiple restaurants
- [ ] Mark Phase 7 complete

---

## Phase 8: Export

### Step 8.1: Implement export.csv
- [ ] Add route for export.csv
- [ ] Validate range (30_days, 90_days, all)
- [ ] Query blood sugar readings for range
- [ ] Generate CSV with columns:
  - [ ] date
  - [ ] time
  - [ ] reading
  - [ ] context
  - [ ] meal_type
  - [ ] notes
- [ ] Return CSV content in response
- [ ] Test: export 30 days

### Step 8.2: Test Export
- [ ] Create 100 readings across 40 days
- [ ] Test 30_days export
- [ ] Test 90_days export
- [ ] Test all export
- [ ] Verify CSV format valid
- [ ] Verify columns correct
- [ ] Clean up test data
- [ ] Mark Phase 8 complete

---

## Phase 9: Polish

### Step 9.1: Error Handling Audit
- [ ] Review all actions for error handling
- [ ] Verify VALIDATION_ERROR used correctly
- [ ] Verify INTERNAL_ERROR used correctly
- [ ] Verify NOT_FOUND used correctly
- [ ] Verify DUPLICATE used correctly
- [ ] Standardize error response utility
- [ ] Add logging for errors
- [ ] Test error scenarios

### Step 9.2: Edge Case Handling
- [ ] Handle new user with no data gracefully
- [ ] Handle report with no data in range
- [ ] Handle meal at midnight (timezone)
- [ ] Handle orphaned meal_log entries
- [ ] Prevent duplicate readings at same timestamp
- [ ] Test pagination for large datasets
- [ ] Verify timezone handling

### Step 9.3: Full Scenario Testing
- [ ] Scenario: New User Onboarding
  - [ ] Get profile (auto-create)
  - [ ] Complete onboarding
  - [ ] Log first blood sugar
  - [ ] Log first meal
  - [ ] Receive feedback
- [ ] Scenario: Daily Usage
  - [ ] Log wake-up reading
  - [ ] Log breakfast
  - [ ] Log post-breakfast
  - [ ] Log lunch
  - [ ] Log post-lunch
  - [ ] Log dinner
  - [ ] Log bedtime
  - [ ] Request summary
- [ ] Scenario: Restaurant Outing
  - [ ] Get recommendations
  - [ ] Log restaurant meal
  - [ ] Log post-meal reading
  - [ ] Verify impact recorded
- [ ] Scenario: Weekly Review
  - [ ] Request weekly report
  - [ ] Check A1C progress
  - [ ] Export for doctor
- [ ] Scenario: High Impact Warning
  - [ ] Log known spike meal
  - [ ] Verify warning appears
- [ ] Document all results
- [ ] Mark Phase 9 complete

---

## Pre-Launch Checklist

### Database
- [ ] All 5 tables created
- [ ] All RLS policies active
- [ ] All indexes created
- [ ] All views working
- [ ] pg_trgm extension enabled
- [ ] Test data cleaned up

### n8n Workflows
- [ ] CQ_Gateway_v1 deployed
- [ ] All 16 actions implemented
- [ ] All routes tested
- [ ] Error handling complete
- [ ] Webhook URL documented

### Documentation
- [ ] PRD finalized
- [ ] API action catalog complete
- [ ] Error codes documented
- [ ] Test results documented

### Integration
- [ ] CustomGPT instructions drafted
- [ ] Action mappings defined
- [ ] Test with CustomGPT front-end
- [ ] End-to-end flow verified

### Dependencies
- [ ] Qwrk auth system ready
- [ ] User ID flow confirmed
- [ ] Production credentials set

---

## Post-Launch

### Monitoring
- [ ] Set up error alerting
- [ ] Monitor usage patterns
- [ ] Track A1C estimate accuracy
- [ ] Gather user feedback

### Phase 2 Planning
- [ ] Exercise/activity logging
- [ ] Medication tracking
- [ ] Proactive outreach (SMS/email)
- [ ] Social/accountability features
- [ ] Weekly educational tips
- [ ] Selectable personality
- [ ] Glycemic index tracking

---

## Notes

_Add implementation notes, decisions, and learnings here as you progress._

---

**Progress Summary:**

| Phase | Status | Completion Date | Required |
|-------|--------|-----------------|----------|
| Phase 1: Foundation | Not Started | | YES |
| Phase 2: Blood Sugar | Not Started | | YES |
| Phase 3: Meal Dictionary | Not Started | | YES |
| Phase 4: Meal Logging | Not Started | | YES |
| Phase 5: Meal Impact | Not Started | | YES |
| **BETA GATE** | — | | *Decision* |
| Phase 6: Reports | Not Started | | YES |
| Phase 7: Restaurant | Not Started | | OPTIONAL |
| Phase 8: Export | Not Started | | YES |
| Phase 9: Polish | Not Started | | YES |
| **Overall** | **0%** | | |
