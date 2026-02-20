# Coach Qwrk: A1C — Product Specification

**Status:** Discovery Complete
**Created:** 2026-01-28
**Version:** 1.0

---

## Executive Summary

**Coach Qwrk: A1C** is a conversational life coach for persons with Type 2 diabetes who want to lower or maintain their A1C. It combines blood sugar tracking, meal logging, nutritional awareness, and personalized guidance to help users build better habits and understand how their choices affect their health.

---

## Platform

| Component | Technology |
|-----------|------------|
| Runtime | Qwrk (n8n for automation) |
| Database | Supabase |
| Interface (Beta) | ChatGPT CustomGPT |
| Authentication | Qwrk user auth (shared infrastructure, TBD) |

---

## Target User

- Anyone with Type 2 diabetes (newly diagnosed to long-term)
- At least somewhat tech-savvy and comfortable using AI
- A1C at any range — goal is lowering or maintaining
- Typically: doesn't track blood sugar often, doesn't track meals, looking for actionable guidance

---

## Critical Constraints

1. **CQ must NEVER give medical advice** — always refer user to their doctor
2. **Data isolation required** — each user's health data must be completely isolated
3. **No A1C estimate without sufficient data** — minimum 30 days, 3 readings/day average
4. **Privacy-first onboarding** — user doesn't have to share anything they're uncomfortable with

---

## Database Schema

### Table: `user_profile`

| Column | Type | Description |
|--------|------|-------------|
| `user_id` | UUID | Primary key (from Qwrk auth) |
| `current_a1c` | DECIMAL | Last known lab A1C (optional) |
| `target_a1c` | DECIMAL | Doctor's target or user's goal |
| `medications` | JSONB | List of medications (optional) |
| `dietary_restrictions` | JSONB | Allergies, preferences (optional) |
| `personality_style` | TEXT | warm_friendly, professional, casual, motivational |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

### Table: `blood_sugar_log`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key |
| `reading` | INTEGER | Blood sugar value (mg/dL) |
| `context` | TEXT | wake_up, fasting, pre_meal, post_meal, bedtime |
| `meal_type` | TEXT | breakfast, lunch, dinner, snack (if pre/post meal) |
| `timestamp` | TIMESTAMP | When reading was taken |
| `linked_meal_log_id` | UUID | Link to meal_log entry (if applicable) |
| `created_at` | TIMESTAMP | |

### Table: `meal_dictionary`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key (user's personal dictionary) |
| `name` | TEXT | Meal name (e.g., "HEB cilantro lime chicken") |
| `serving_size` | TEXT | e.g., "1 cup", "4 oz" |
| `calories` | INTEGER | |
| `carbs_total` | DECIMAL | Grams |
| `fiber` | DECIMAL | Grams |
| `sugar` | DECIMAL | Grams |
| `net_carbs` | DECIMAL | Calculated: carbs_total - fiber |
| `protein` | DECIMAL | Grams |
| `fat_total` | DECIMAL | Grams |
| `glycemic_index` | INTEGER | (optional, if known) |
| `glycemic_load` | INTEGER | (optional, if known) |
| `source` | TEXT | user_provided, estimated, looked_up |
| `confidence` | TEXT | high, medium, low (for estimates) |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

### Table: `meal_log`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key |
| `meal_dictionary_id` | UUID | Foreign key to meal_dictionary |
| `meal_type` | TEXT | breakfast, lunch, dinner, snack |
| `portion_multiplier` | DECIMAL | Default 1.0 (e.g., 2.0 for double portion) |
| `modifiers` | JSONB | Additional items (e.g., {"croutons": {...}}) |
| `timestamp` | TIMESTAMP | When meal was eaten |
| `pre_meal_bs_id` | UUID | Link to blood_sugar_log (optional) |
| `post_meal_bs_id` | UUID | Link to blood_sugar_log (optional) |
| `created_at` | TIMESTAMP | |

### Table: `meal_impact`

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key |
| `meal_dictionary_id` | UUID | Foreign key |
| `meal_log_id` | UUID | Foreign key to specific meal instance |
| `bs_delta` | INTEGER | post_meal - pre_meal reading |
| `time_elapsed_minutes` | INTEGER | Time between readings |
| `post_meal_absolute` | INTEGER | Absolute post-meal value |
| `created_at` | TIMESTAMP | |

*Note: Record created only when BOTH pre and post meal readings exist.*

---

## MVP (Beta) Feature Checklist

### Core Logging
- [ ] Blood sugar logging with context (wake-up, fasting, pre/post meal, bedtime)
- [ ] Context inference from time of day; ask if uncertain
- [ ] Meal logging with meal type (breakfast, lunch, dinner, snack)
- [ ] Portion size support (default 1 serving, allow multipliers)
- [ ] Link blood sugar readings to meals

### Meal Dictionary
- [ ] Create new meal entries
- [ ] Capture nutritional content via:
  1. Nutrition label image upload
  2. User description (CQ estimates)
  3. Meal photo upload (CQ estimates)
  4. Web lookup (branded/restaurant items)
- [ ] Store: calories, carbs, fiber, sugar, net carbs, protein, fat
- [ ] Track source and confidence level
- [ ] Handle portion variations (auto-calculate)
- [ ] Handle modifiers (base meal + additions)
- [ ] Detect similar meals; ask before creating duplicates

### Meal Impact Tracking
- [ ] Calculate and store delta when pre/post readings available
- [ ] Build per-meal average impact score
- [ ] Flag high-impact meals
- [ ] Warn user when logging known high-impact meal
- [ ] Suggest mitigation tips (walk, pushups)

### Restaurant Suggestions
- [ ] Accept "I'm going to [restaurant]" queries
- [ ] Web search for current menu
- [ ] Recommend 3 diabetic-friendly options with explanations
- [ ] Warn about high-spike menu items
- [ ] Offer modification tips

### Feedback & Coaching
- [ ] Helpful feedback on blood sugar readings
- [ ] Flag urgent readings (< 70 or > 300 mg/dL) with safety info
- [ ] Ask retroactively about meals when post-meal reading logged without meal
- [ ] Probe conflicting data (low-carb meal but high spike)
- [ ] Gentle nudges for inconsistent logging
- [ ] No judgment, focus on what's next

### Reports & A1C Estimates
- [ ] Weekly report: BS summary, meal insights, progress, coaching tip
- [ ] Monthly report
- [ ] Custom range report ("last X weeks")
- [ ] A1C estimate using eAG formula: `(avg BS + 46.7) / 28.7`
- [ ] Require 30 days + 3 readings/day minimum
- [ ] Compare to goal and last lab A1C
- [ ] Show progress toward data threshold if insufficient

### Data Export
- [ ] Export blood sugar readings as CSV
- [ ] Include timestamps and context
- [ ] Preset ranges: 30 days, 90 days, all time

### Onboarding (basic)
- [ ] Collect (optional): current A1C, target A1C, medications, dietary restrictions
- [ ] Ask about willingness to try: more readings, exercise, etc.
- [ ] Explicit privacy messaging: "You don't have to share anything you're not comfortable with"

---

## Phase 2 Features (Post-Beta)

- [ ] Exercise/activity logging and correlation
- [ ] Medication tracking and reminders
- [ ] Proactive outreach (SMS/email)
- [ ] Social/accountability sharing
- [ ] Weekly educational tips
- [ ] Selectable personality style
- [ ] Glycemic index/load tracking
- [ ] Push notifications (requires native app)

---

## User Actions Catalog

### Logging
```
"Log blood sugar: 142"
"My sugar is 156"
"I ate [meal] for [meal type]"
```

### Queries
```
"What did I eat yesterday?"
"Show my blood sugar for this week"
"What's my average blood sugar?"
"How does [meal] usually affect me?"
```

### Guidance
```
"I'm going to [restaurant] for [meal type]"
"What should I eat for breakfast?"
"Why did my sugar spike?"
```

### Settings
```
"Update my A1C goal"
"Add a new meal to my dictionary"
```

### Reports
```
"Give me my weekly report"
"Give me my monthly report"
"Review my readings for the last X weeks and give me a report"
```

### Export
```
"Export my data for the last 90 days"
```

---

## CQ Personality & Tone

**Balance:** Supportive encouragement + straight talk

**Selectable styles (Phase 2, default one for beta):**
- Warm and friendly
- Professional and clinical
- Casual and conversational
- Motivational coach energy

**When user slips:**
- Gentle nudge: "I noticed you've been away — everything okay?"
- No judgment
- Focus on what's next

**Medical disclaimer:** Always refer to doctor for medical questions. CQ tracks and coaches, never prescribes.

---

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Qwrk user authentication | Not yet built | CQ launch blocked until ready |
| CustomGPT ↔ n8n integration | Existing | Same pattern as Qwrk |
| Supabase tables | To be created | Schema defined above |

---

## Open Implementation Questions

1. When user corrects meal dictionary nutrition info, should it affect past meal_log entries or only future ones?
2. Exact authentication token flow between CustomGPT and website
3. Default personality style for beta
4. Error message tone and content (TBD)

---

---

# Appendix: Discovery Interview

*The following Q&A documents the discovery process that produced this specification.*

---

### Q1: Who is the target user?

**Answer:**
- Anyone with Type 2 diabetes who is at least somewhat tech-savvy and comfortable using AI
- A1C can be at any range — goal is lowering or maintaining
- Typical current behavior:
  - Don't take blood sugar readings often
  - Don't track what they eat
  - Looking for guidance on actionable things to lower A1C
- Experience range: Newly diagnosed (know next to nothing) to Long-term (e.g., 17 years) but never managed well
- Key insight: User has personal experience — 17 years with T2 diabetes, historically not great at managing it

---

### Q2: What should onboarding collect?

**Answer:**

Potential onboarding data points:
- Current A1C (if known)
- Medications (metformin, insulin, etc.)
- Doctor's target A1C
- Dietary restrictions/preferences (vegetarian, allergies, etc.)
- How often they currently check blood sugar

**Key principles:**
- User doesn't have to share anything they're not comfortable with — make this explicit
- Privacy-first, trust-building approach

**Forward-looking questions (willingness to try):**
- Are you willing to take blood sugar readings more often?
- Are you willing to add some exercise?
- Other behavioral changes they're open to?

---

### Q3: How does CQ fit into the user's daily life?

**Answer:**

**Interaction model:** Both reactive AND proactive (long-term goal)

**Reactive:** User initiates when they want to log or ask questions

**Proactive (future):** CQ reaches out with reminders and check-ins

**Notification channels (in priority order):**
1. Push notifications (ideal, future)
2. SMS (option)
3. Email (option)

**Beta constraint:** Initial beta will be front-ended by a ChatGPT CustomGPT. Beta is primarily reactive; proactive outreach requires external channels.

---

### Q4: Blood sugar logging flow — what to capture and how to respond?

**Answer:**

**Data to capture:**
- Blood sugar reading (number)
- Context/timing: Wake-up, Fasting, Pre-meal, Post-meal, Bedtime

**Context capture approach:**
- Infer from time of day when possible
- Ask clarifying questions when not certain

**Feedback:**
- Helpful and offer guidance
- Especially important early in user's experience

**Post-meal prompt:** Yes — prompt user to log what they ate if not already logged

---

### Q5: Meal logging flow — what to capture and how to populate?

**Answer:**

**meal_log entry fields:**
- Meal type (inferred or asked)
- Timestamp
- Portion size (default "1 serving")
- Link to pre/post meal blood sugar readings
- Reference to meal_dictionary entry

**Nutritional info capture priority (if meal NOT in dictionary):**
1. User uploads nutrition label image
2. User describes ingredients → CQ estimates
3. User uploads photo of meal → CQ estimates
4. CQ looks it up online

---

### Q6: What nutritional fields should the meal_dictionary store?

**Answer:** Calories, Carbs (total), Protein, Fat (total), Fiber, Sugar, Net carbs, Glycemic index/load (if known), Serving size, Source, Confidence level

---

### Q7: How should the meal_impact table work?

**Answer:**

**Trigger:** Record created only when BOTH pre-meal AND post-meal readings available.

**Fields:** Blood sugar delta, time elapsed, absolute post-meal value

**Usage:** Build per-meal average impact score, flag high-impact meals, warn user with mitigation tips (not alternatives)

---

### Q8: How should the restaurant suggestion feature work?

**Answer:**

**Source:** Web search for current menu

**Criteria:** Low carb, low glycemic impact, high protein/fiber, reasonable portion, good macro balance

**Presentation:** 3 options with explanations, warnings about spike risks, modification tips

---

### Q9: What other features should CQ include?

**Answer:**
- Reporting & Insights — Core (MVP)
- Exercise & Activity — Optional, Phase 2
- Medication & Health — Optional, Phase 2
- Social / Accountability — Optional, Phase 2
- Education — Weekly tips, Phase 2

---

### Q10: What should CQ's personality and tone be?

**Answer:**
- Balance of supportive and firm
- NEVER give medical advice
- Personality is user-selectable (Phase 2)
- Gentle nudge when user slips, no judgment

---

### Q11: What's in MVP (Beta) vs. Phase 2?

**Answer:**

**MVP:** Blood sugar logging, meal logging, meal dictionary, meal impact, restaurant suggestions, feedback/coaching, onboarding, weekly reports, A1C estimates

**Phase 2:** Exercise, medication, proactive outreach, social sharing, weekly tips, selectable personality

---

### Q12: How will users be identified and authenticated?

**Answer:** Use Qwrk user authentication (shared infrastructure, not yet built). Data isolation required.

---

### Q13: What user actions/commands should CQ understand?

**Answer:** Logging, queries, guidance, settings, reports (weekly/monthly/custom range)

---

### Q14: How should CQ estimate A1C from blood sugar readings?

**Answer:** eAG formula, require 30 days + 3 readings/day, compare to goal and last lab A1C

---

### Q15: How should CQ handle edge cases?

**Answer:** Flag urgent readings, ask retroactively about meals, gentle reminders for inconsistent logging, probe conflicting data

---

### Q16: How should CQ handle meal variations in the dictionary?

**Answer:** Auto-calculate portions, use base + modifier pattern, ask before creating similar entries, allow user corrections

---

### Q17: What should the weekly report include?

**Answer:** Blood sugar summary, meal insights, progress metrics, one personalized coaching tip

---

### Q18: Final considerations

**Answer:** Final name is "Coach Qwrk: A1C", English only for beta, data export supported, no specific accessibility considerations for now

---

### Q19: Data export — format and content?

**Answer:** CSV format, blood sugar readings with timestamps and context, preset date ranges (30/90/all)

---

*End of specification.*
