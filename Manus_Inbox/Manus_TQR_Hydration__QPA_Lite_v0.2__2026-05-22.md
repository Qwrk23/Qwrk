# Manus TQR Hydration Package — QPA Lite Static Startup Menu v0.2

> **Generated:** 2026-05-22 by CC (Claude Code) for Manus Team Qwrk Review.  
> **Workspace:** Qwrk Prime (`be0d3a48-c764-44f9-90c8-e846d9dbbd0a`).  
> **Hydration:** all artifact payloads pulled live from Supabase (`npymhacpmxdnkqdzgxll`) on 2026-05-22. Full UUIDs, full payloads, no truncation.

---

## Preamble — Manus, Qwrk Prime TQR Incoming

Manus — Qwrk Prime TQR incoming.

This is from a Qwrk Prime subsession on 2026-05-22 focused on the Qwrk Beta startup/onboarding experience.

We are preparing a Team Qwrk Review for the corrected v0.2 QPA Lite Static Startup Menu design. The original v0.1 design collided with the existing T199/UCC / "My Qwrk Profile" lane, so CC performed a reconciliation pass and Q saved a corrected v0.2 snapshot scoped only to the menu layer.

Primary artifact for review:
- `02fbf7bc-f1a6-421b-927d-9c15dcc04789`
- `Design — Qwrk Beta Static Startup Menu / QPA Lite v0.2`

Supporting artifact:
- `a91a865c-cfcb-4a68-a112-d0b78bb7e1e8`
- `UCC Field Asks — QPA Lite Static Startup Menu`

Please await the full TQR prompt. The review target will be whether v0.2 is ready to become the basis for PRD v1, with UCC/T199 treated as an external dependency rather than redefined here.

---

## How To Read This Package

- **Artifact 1 (v0.2)** is the primary review target.
- **Artifact 2 (UCC Field Asks)** is the companion handoff to the T199/UCC lane; supporting context.
- **Artifact 3 (v0.1)** is the superseded original design, included only so the before/after of the reconciliation is visible.
- **Artifact 4 (origin twig)** is the design precursor.
- **Artifacts 5-10 (T199/UCC)** are the external-dependency lane. They are included so Manus can verify v0.2 correctly *consumes* UCC rather than redefining it. These artifacts are NOT under review here — they are the authoritative T199 surface v0.2 must not contradict.

---

## Package Index

| # | Role | Artifact | Full UUID | Type |
|---|------|----------|-----------|------|
| 1 | PRIMARY REVIEW TARGET | Design — Qwrk Beta Static Startup Menu / QPA Lite v0.2 | `02fbf7bc-f1a6-421b-927d-9c15dcc04789` | snapshot |
| 2 | SUPPORTING ARTIFACT | UCC Field Asks — QPA Lite Static Startup Menu | `a91a865c-cfcb-4a68-a112-d0b78bb7e1e8` | snapshot |
| 3 | SUPERSEDED — v0.1 (context only) | Design — Qwrk Beta Static Startup Menu and Prime User Profile v0.1 | `766d6151-7a0c-43fc-8f74-882a6a58b038` | snapshot |
| 4 | ORIGIN TWIG | Twig — Static Beta Menu with Workbench Signals and Prime User Profile References | `aa686db4-06ed-49ac-b3db-c30bd5710c34` | twig |
| 5 | EXTERNAL DEPENDENCY — T199/UCC | UCC Seed — User Context Core / Startup Identity Layer | `088aa61b-a488-4d28-bdb6-e3c0e92b9abf` | project |
| 6 | EXTERNAL DEPENDENCY — T199/UCC | UCC Root Snapshot v2 — Design Synthesis | `2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0` | snapshot |
| 7 | EXTERNAL DEPENDENCY — T199/UCC | Decision — User Orientation Profile Folded into UCC | `f01106f8-bb47-4b18-826a-0f90d32c7478` | snapshot |
| 8 | EXTERNAL DEPENDENCY — T199/UCC | UCC Read Contract v1 | `b95ec7a4-0a62-4714-817e-0b07bb044808` | snapshot |
| 9 | EXTERNAL DEPENDENCY — T199/UCC | UCC Provisioning Integration Contract v1 | `cf74279e-5d02-4ee8-85c8-aa9826e1bea9` | snapshot |
| 10 | EXTERNAL DEPENDENCY — T199/UCC | UCC Privacy Contract v1 — Draft 3 | `ff95bc0c-3803-4708-89a2-e5e30372f172` | snapshot |

---

## 1. PRIMARY REVIEW TARGET — Design — Qwrk Beta Static Startup Menu / QPA Lite v0.2

- **artifact_id:** `02fbf7bc-f1a6-421b-927d-9c15dcc04789`
- **artifact_type:** `snapshot`
- **title:** Design — Qwrk Beta Static Startup Menu / QPA Lite v0.2
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `aa686db4-06ed-49ac-b3db-c30bd5710c34`
- **semantic_type_id:** `dd528b82-aad7-4c7b-b0fb-161550b42c9a`
- **lifecycle_status:** _(none)_
- **tags:** for-q, beta, qpa-lite, design
- **created_at:** 2026-05-22 19:30:33.444206+00
- **updated_at:** 2026-05-22 19:30:33.444206+00

**Hydrated extension.payload:**

```json
{
  "title": "Design — Qwrk Beta Static Startup Menu / QPA Lite v0.2",
  "status": "draft-for-manus-tqr",
  "purpose": {
    "goal": "Remove blank-canvas friction for new Beta users while preserving the freedom to state intent in natural language at any point.",
    "summary": "QPA Lite is the Beta-user-facing startup experience. After a Beta user runs the required startup/load step, Qwrk presents a static, numbered menu of plain-language actions.",
    "positioning": "QPA Lite is a Beta-scoped adaptation of the existing QPA menu-driven intent model. It is a lighter variant, not a new system."
  },
  "session_date": "2026-05-22",
  "prd_readiness": {
    "beta_release_gate": "T176 is release-blocked on T187. QPA Lite may be designed now but cannot ship to Beta ahead of that gate.",
    "can_proceed_after": "This v0.2 clears Manus TQR, scoped to static menu plus minimum UCC shell consumption.",
    "startup_dependencies": [
      "T185 Gateway zero-result defect",
      "T197 Bootstrap Bookmark doctrine"
    ],
    "must_declare_dependency": "PRD must declare T199/UCC as an external dependency.",
    "pre_prd_requirement_completed": "UCC Field Asks handoff has been saved and linked: a91a865c-cfcb-4a68-a112-d0b78bb7e1e8.",
    "rich_preference_features_gated_on": [
      "UCC reaching sapling",
      "UCC schema v1 field finalization",
      "UCC Privacy Contract readiness",
      "UCC Update Contract v1"
    ]
  },
  "workbench_mvp": {
    "not_mvp": [
      "artifact-level is_workbench_item boolean",
      "workbench_refs cache in UCC"
    ],
    "rationale": [
      "No DDL required.",
      "No new artifact field required.",
      "Gateway already supports structured tags.add and tags.remove.",
      "Tag-based implementation is artifact-type agnostic.",
      "Tag-filtered artifact.list can support show-all and continue-most-recent flows."
    ],
    "operations": {
      "show_all": "artifact.list filtered by tag workbench",
      "add_to_workbench": "tags.add: [\"workbench\"]",
      "clear_from_workbench": "tags.remove: [\"workbench\"]",
      "continue_most_recent": "artifact.list filtered by tag workbench, ordered by updated_at descending, limit 1"
    },
    "implementation": "Use artifact tag workbench.",
    "source_of_truth": "The workbench tag is the source of truth."
  },
  "origin_twig_id": "aa686db4-06ed-49ac-b3db-c30bd5710c34",
  "schema_version": "qpa-lite-menu-design-v0.2",
  "ucc_dependency": {
    "startup_read": "At the startup/load step, QPA Lite reads My Qwrk Profile / UCC as loaded per UCC Read Contract b95ec7a4-0a62-4714-817e-0b07bb044808.",
    "wake_load_order": "Per UCC wake_load_order, UCC absorbs first, before End Session, Rolling Memory, and CmdCtr.",
    "field_asks_handoff": "a91a865c-cfcb-4a68-a112-d0b78bb7e1e8",
    "menu_reads_ucc_for": [
      "prompting style",
      "detail level",
      "default support mode",
      "other preferences exposed by UCC"
    ],
    "minimum_shell_rule": "QPA Lite functions on a minimum UCC shell. If UCC is missing or empty at startup, QPA Lite follows UCC fail-soft behavior defined by UCC, not by this design.",
    "update_preferences_rule": "An Update my preferences menu action would invoke the future UCC Update Contract v1 path. QPA Lite does not specify or implement profile updates.",
    "menu_does_not_read_ucc_for": [
      "counts",
      "priorities",
      "routing",
      "live project lists",
      "workbench refs",
      "support request records"
    ]
  },
  "submenu_patterns": {
    "get_support": {
      "notes": "Support flow remains menu-layer design. UCC only owns default support preference if exposed.",
      "submenu": [
        "1. Report a problem",
        "2. Ask how something works",
        "3. Request a feature",
        "4. Check an existing support request"
      ]
    },
    "my_workbench": {
      "notes": "Workbench supports any artifact type.",
      "submenu": [
        "1. Show all workbench items",
        "2. Continue the most recent item",
        "3. Add something to the workbench",
        "4. Clear or close a workbench item"
      ]
    },
    "work_on_project": {
      "notes": "Planting routes to idea/project creation. Tending lists active, pinned, or recent projects.",
      "submenu": [
        "1. Plant something new",
        "2. Tend a current project"
      ]
    },
    "explore_freelance_figure_something_out": {
      "notes": "This path is explicitly freedom-preserving for users who do not yet know what they want.",
      "submenu": [
        "1. Explore an idea",
        "2. Think through a decision",
        "3. Shape a freelance/client-work path",
        "4. Turn this into a project later"
      ]
    }
  },
  "manus_review_role": "Review v0.2 as the primary artifact and the UCC Field Asks handoff as supporting context. Validate product architecture, scope, UCC dependency boundaries, MVP readiness, and risks before PRD v1.",
  "related_artifacts": {
    "ucc_root_v2": "2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0",
    "ucc_seed_project": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
    "qpa_project_anchor": "041cd5e4-ffdb-4589-9cf7-849dc40ea8a3",
    "ucc_read_contract_v1": "b95ec7a4-0a62-4714-817e-0b07bb044808",
    "ucc_provisioning_contract_v1": "cf74279e-5d02-4ee8-85c8-aa9826e1bea9",
    "ucc_privacy_contract_v1_draft_3": "ff95bc0c-3803-4708-89a2-e5e30372f172",
    "decision_profile_folded_into_ucc": "f01106f8-bb47-4b18-826a-0f90d32c7478"
  },
  "deferrals_non_goals": [
    "New DDL of any kind.",
    "New artifact types, including a dedicated support-request type.",
    "Dedicated profile table.",
    "UCC update protocol.",
    "Support-request mirror into Qwrk Prime.",
    "Full Easy Find generalized retrieval.",
    "Full Learn / training-content system.",
    "Artifact-level workbench boolean field.",
    "Rich preference-aware menu behavior before UCC sapling/read contract readiness."
  ],
  "manus_tqr_questions": [
    "Is a 9-item static menu too heavy for a friction-reduction goal, and should v0.1 trim to approximately 6 core items?",
    "Are Capture/Journal and Explore/Freelance/Figure Something Out distinct enough for a brand-new user?",
    "Should Start/Get Oriented and Wrap Up/Save Where I Left Off remain menu peers or surface as session bookends?",
    "Is support request as existing queryable type tagged support-request acceptable for MVP?",
    "Is operator-side cross-workspace sweep an acceptable MVP escalation model versus structured for-cc handoff?",
    "Does the menu reading UCC for preferences only, with counts/priorities derived from workspace data, correctly respect UCC boundaries?",
    "Can the menu PRD proceed in parallel with UCC sapling work, or must it wait for UCC minimum-shell field finalization?",
    "Can the menu PRD advance before T185/T197 resolve, given the menu sits on the startup/load step?"
  ],
  "support_request_mvp": {
    "origin": "Support request originates in the user's own workspace to preserve visibility and sovereignty.",
    "deferred": [
      "structured escalation via for-cc / cc-handoff pattern",
      "Prime-side mirror",
      "new support_request artifact type"
    ],
    "naming_rule": "Do not call this a Seed Pod because that term is reserved for the T164 portable-idea primitive.",
    "queryability": "Check existing support request works because the request artifact lives in the user's own workspace and uses a queryable type.",
    "escalation_mvp": "Operator-side cross-workspace sweep for support-request-tagged artifacts. Query, not copy.",
    "artifact_pattern": "Use an existing Gateway-queryable artifact type, such as project or twig, tagged support-request plus support semantic classification where applicable.",
    "no_prime_mirror_mvp": "No mirror into Qwrk Prime in MVP. Mirroring creates cross-workspace dual-write consistency risk."
  },
  "reconciliation_basis": {
    "date": "2026-05-22",
    "source": "CC T199/UCC reconciliation pass",
    "conclusion": "The Prime User Profile concept from v0.1 was fully duplicative of T199/UCC and has been removed. The QPA Lite static menu layer remains valid and independent."
  },
  "scope_of_this_design": {
    "in_scope": [
      "static startup menu",
      "submenus",
      "freeform natural-language override",
      "Workbench menu item",
      "Workbench tag-based MVP",
      "Support Request menu flow",
      "derived startup counts",
      "menu dependency on UCC read output"
    ],
    "out_of_scope_owned_elsewhere": {
      "t199_ucc": [
        "UCC storage",
        "UCC provisioning",
        "UCC privacy",
        "UCC read contract",
        "UCC update contract"
      ],
      "t145_t176": [
        "workspace provisioning",
        "beta onboarding sequencing"
      ],
      "t185_t197": [
        "startup/load Gateway behavior",
        "first-wake correctness",
        "Bootstrap Bookmark doctrine"
      ],
      "hidden_from_beta_users": [
        "QPM",
        "payload discipline",
        "artifact-model internals"
      ]
    }
  },
  "static_menu_contract": {
    "principle": "Show all core menu options every time after the startup/load step. Profile/workspace data enriches menu labels with live counts and indicators; it never hides an option.",
    "working_menu": [
      "1. Start / Get Oriented",
      "2. Capture or Journal",
      "3. Work on a Project (you have 12 active)",
      "4. My Workbench (you have 4 open)",
      "5. Find Something I Saved",
      "6. Explore / Freelance / Figure Something Out",
      "7. Learn How to Use Qwrk",
      "8. Get Support",
      "9. Wrap Up / Save Where I Left Off"
    ],
    "open_question": "Nine items may be heavy for a friction-reduction goal, and Capture/Journal overlaps conceptually with Explore/Freelance/Figure Something Out.",
    "count_behavior": "Counts or indicators appear beside a menu item only when derived workspace data supports them. Missing counts never hide or disable the item.",
    "menu_spec_discipline": "The menu and submenus should be defined declaratively as a single menu-spec section of the QPA Lite instruction layer, not scattered across multiple system-instruction locations."
  },
  "freeform_override_rule": {
    "rule": "At every menu level, the user may ignore the numbers and simply state intent in natural language.",
    "routing": "Qwrk routes the natural-language intent to the closest menu mode or asks one clarifying question if ambiguous.",
    "design_principle": "The numbered menu is an accelerator, never a cage."
  },
  "supersedes_snapshot_id": "766d6151-7a0c-43fc-8f74-882a6a58b038",
  "relationship_to_t199_ucc": {
    "rule": "QPA Lite consumes UCC. It does not define, store, or update UCC.",
    "ucc_owns": [
      "profile storage",
      "profile provisioning",
      "privacy and consent",
      "read contract",
      "update contract"
    ],
    "field_asks": "Preference fields the menu would benefit from are captured in the companion UCC Field Asks handoff. That handoff is a request to T199, not a schema decision.",
    "retired_terms": [
      "Prime User Profile",
      "soul file"
    ],
    "governance_name": "UCC",
    "menu_layer_name": "QPA Lite Static Startup Menu",
    "user_facing_beta_label": "My Qwrk Profile"
  },
  "ucc_field_asks_handoff_id": "a91a865c-cfcb-4a68-a112-d0b78bb7e1e8",
  "derived_counts_startup_data": {
    "rule": "Live counts and lists are derived from workspace queries at startup, never stored in UCC.",
    "examples": [
      "active project count",
      "workbench count",
      "recent project list",
      "findable artifact list"
    ],
    "ucc_boundary": "UCC must not be the source of counts, priorities, or routing.",
    "startup_performance": "The startup/load step should retrieve all menu counts in a single payload or round-trip, not one query per menu item.",
    "candidate_count_source": "cmdctr_operator_briefing() may already compute relevant per-workspace inventory counts and should be evaluated before building new count queries."
  }
}
```

---

## 2. SUPPORTING ARTIFACT — UCC Field Asks — QPA Lite Static Startup Menu

- **artifact_id:** `a91a865c-cfcb-4a68-a112-d0b78bb7e1e8`
- **artifact_type:** `snapshot`
- **title:** UCC Field Asks — QPA Lite Static Startup Menu
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **lifecycle_status:** _(none)_
- **tags:** for-q, ucc, t199, handoff
- **created_at:** 2026-05-22 19:29:44.604941+00
- **updated_at:** 2026-05-22 19:29:44.604941+00

**Hydrated extension.payload:**

```json
{
  "date": "2026-05-22",
  "title": "UCC Field Asks — QPA Lite Static Startup Menu",
  "status": "draft-handoff-to-t199-ucc-lane",
  "to_lane": "T199 / UCC lane",
  "from_lane": "QPA Lite design lane",
  "origin_twig_id": "aa686db4-06ed-49ac-b3db-c30bd5710c34",
  "schema_version": "ucc-field-asks-v0.1",
  "save_sequence_note": "Save this field-asks handoff first, then save the v0.2 QPA Lite design snapshot with this artifact_id embedded for Manus TQR.",
  "purpose_and_framing": {
    "purpose": "This is a handoff/request to the T199/UCC lane, not a schema decision. It lists the minimal preference/context fields the QPA Lite Static Startup Menu would benefit from reading at the startup/load step.",
    "degradation_rule": "None of these fields is required for the menu to function. The menu operates on a minimum UCC shell and degrades gracefully when fields are absent.",
    "governance_boundary": "T199 owns whether, where, and how these become UCC fields. QPA Lite consumes whatever UCC ultimately exposes."
  },
  "dependencies_on_t199": {
    "ucc_read_contract": "b95ec7a4-0a62-4714-817e-0b07bb044808",
    "ucc_privacy_contract": "ff95bc0c-3803-4708-89a2-e5e30372f172",
    "future_ucc_update_contract": "not yet drafted",
    "ucc_provisioning_integration_contract": "cf74279e-5d02-4ee8-85c8-aa9826e1bea9"
  },
  "ucc_seed_artifact_id": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
  "related_t199_artifacts": {
    "root_v2": "2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0",
    "ucc_read_contract_v1": "b95ec7a4-0a62-4714-817e-0b07bb044808",
    "ucc_provisioning_contract_v1": "cf74279e-5d02-4ee8-85c8-aa9826e1bea9",
    "ucc_privacy_contract_v1_draft_3": "ff95bc0c-3803-4708-89a2-e5e30372f172",
    "decision_profile_folded_into_ucc": "f01106f8-bb47-4b18-826a-0f90d32c7478"
  },
  "field_asks_by_menu_need": {
    "support": {
      "asks": [
        "Default support mode preference.",
        "Preferred support communication style."
      ],
      "exclusion": "No support request tracking should be stored in UCC. Support requests are artifacts in the user's workspace.",
      "menu_need": "Tune the Get Support flow's default behavior and tone.",
      "suggested_ucc_home": "service_preferences"
    },
    "closeout": {
      "asks": [
        "Whether the user wants end-session or closeout prompts.",
        "Preferred closeout detail level."
      ],
      "menu_need": "Tune the Wrap Up / Save Where I Left Off flow.",
      "suggested_ucc_home": "service_preferences"
    },
    "learn_qwrk": {
      "asks": [
        "User learning level.",
        "Preferred learning style.",
        "Completed tutorials only if T199 judges this appropriate."
      ],
      "menu_need": "Route how-to content at the right depth.",
      "suggested_ucc_home": "service_preferences; completed tutorials home is explicitly T199's call"
    },
    "work_projects": {
      "asks": [
        "Default project interaction style, if any."
      ],
      "exclusion": "No live project refs or counts should be stored in UCC. Those are derived workspace data.",
      "menu_need": "Tune how the Work on a Project flow engages the user.",
      "suggested_ucc_home": "service_preferences / q_behavior"
    },
    "capture_journal": {
      "asks": [
        "Preferred journaling style.",
        "Preferred reflection depth.",
        "Preferred question cadence."
      ],
      "menu_need": "Tune the Capture/Journal flow's prompting behavior.",
      "suggested_ucc_home": "service_preferences"
    },
    "startup_orientation": {
      "asks": [
        "Whether the user wants a startup/orientation routine run at the load step.",
        "Preferred startup prompting style, such as brief versus guided.",
        "Preferred detail level for menu/option presentation."
      ],
      "menu_need": "Decide whether to auto-run an orientation routine and how verbose the menu presentation should be.",
      "suggested_ucc_home": "service_preferences / q_behavior"
    },
    "explore_freelance_figure_something_out": {
      "asks": [
        "Whether the user wants exploratory mode surfaced explicitly.",
        "Preferred thinking style, only if UCC already supports a comparable preference; otherwise treat as a future ask, not a new field request."
      ],
      "menu_need": "Decide whether to emphasize the Explore option for users who like open-ended work.",
      "suggested_ucc_home": "service_preferences"
    }
  },
  "t199_decision_authority": "T199 decides field-by-field inclusion, naming, schema section, and core/vault tier. QPA Lite will consume whatever UCC ultimately exposes.",
  "must_not_be_placed_in_ucc": [
    "Live counts such as project counts or workbench counts.",
    "Active project lists.",
    "Workbench references; the workbench tag on artifacts is the source of truth.",
    "Support request records; these are artifacts in the user's workspace.",
    "Easy Find search indexes.",
    "Priority or routing state."
  ],
  "source_design_snapshot_id": "766d6151-7a0c-43fc-8f74-882a6a58b038"
}
```

---

## 3. SUPERSEDED — v0.1 (context only) — Design — Qwrk Beta Static Startup Menu and Prime User Profile v0.1

- **artifact_id:** `766d6151-7a0c-43fc-8f74-882a6a58b038`
- **artifact_type:** `snapshot`
- **title:** Design — Qwrk Beta Static Startup Menu and Prime User Profile v0.1
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `aa686db4-06ed-49ac-b3db-c30bd5710c34`
- **semantic_type_id:** `dd528b82-aad7-4c7b-b0fb-161550b42c9a`
- **lifecycle_status:** _(none)_
- **tags:** for-q, beta, menu, qpa, workbench
- **created_at:** 2026-05-22 19:12:00.284226+00
- **updated_at:** 2026-05-22 19:12:00.284226+00

**Hydrated extension.payload:**

```json
{
  "design_title": "Qwrk Beta Static Startup Menu and Prime User Profile v0.1",
  "session_date": "2026-05-22",
  "core_decision": {
    "decision": "Qwrk Beta startup should use a static top-level menu with all core options listed, rather than dynamically hiding or showing menu items based on profile state.",
    "rationale": "A static menu gives new users a clear, predictable operating surface and preserves freedom to explore. Profile-backed data should enrich menu labels with live indicators, counts, and open-item signals rather than determining whether the option appears."
  },
  "design_status": "draft-for-cc-review",
  "open_questions": [
    "Should Prime User Profile be implemented as a dedicated table, an artifact, or both?",
    "What exact threshold makes profile-held project references too large?",
    "Should workbench begin as a tag, a profile ref array, or a new artifact field?",
    "What artifact type should represent support request seed pods in MVP?",
    "Should support escalation create a mirrored artifact in Qwrk Prime, CC handoff restart, or both?",
    "Which menu items are v0.1 required versus v0.2 optional?",
    "What startup/load payload retrieves Prime User Profile and workspace menu counts?",
    "What must be included in the first PRD before sapling build?"
  ],
  "origin_twig_id": "aa686db4-06ed-49ac-b3db-c30bd5710c34",
  "schema_version": "design-snapshot-v0.1",
  "product_posture": {
    "positioning": "General-purpose personal operating layer, including work-related use, not narrowly positioned as a work/project tool at this stage.",
    "language_boundary": "Avoid exposing artifact model, lifecycle terms, QPM internals, governance language, or database concepts during normal beta use unless the user explicitly enters a learning or power-user path.",
    "user_experience_goal": "Reduce blank-canvas friction while making it clear the user can either choose a number or simply state what they want in natural language."
  },
  "static_menu_v0_1": {
    "example": [
      "1. Start / Get Oriented",
      "2. Capture or Journal",
      "3. Work on a Project (you have 12 active)",
      "4. My Workbench (you have 4 open)",
      "5. Find Something I Saved",
      "6. Explore / Freelance / Figure Something Out",
      "7. Learn How to Use Qwrk",
      "8. Get Support",
      "9. Wrap Up / Save Where I Left Off"
    ],
    "principle": "Show all core menu options every time after startup/load, enriched with live counts where available.",
    "count_behavior": "Counts or status indicators should appear beside menu items when profile or workspace data supports them. Missing counts should not hide the menu item.",
    "freeform_override": "At any menu level, the user may ignore numbers and simply state intent in natural language. Qwrk should route the natural-language intent to the closest menu mode or ask one clarifying question."
  },
  "submenu_patterns": {
    "support": {
      "notes": "Support request should be planted in the user's workspace first, then mirrored or escalated into Qwrk Prime / CC / support lane.",
      "submenu": [
        "1. Report a problem",
        "2. Ask how something works",
        "3. Request a feature",
        "4. Check an existing support request"
      ],
      "trigger": "User selects Get Support."
    },
    "my_workbench": {
      "notes": "Workbench should support any artifact type, not just projects.",
      "submenu": [
        "1. Show all workbench items",
        "2. Continue the most recent item",
        "3. Add something to the workbench",
        "4. Clear or close a workbench item"
      ],
      "trigger": "User selects My Workbench."
    },
    "work_on_project": {
      "notes": "Planting should route to idea/project creation flow. Tending should retrieve or list active/pinned/recent projects.",
      "submenu": [
        "1. Plant something new",
        "2. Tend a current project"
      ],
      "trigger": "User selects Work on a Project or expresses a project-related intent."
    },
    "explore_freelance": {
      "notes": "Joel explicitly wants users to have freedom to explore even when they do not know what they want to do. This should not be hidden inside journaling only.",
      "submenu": [
        "1. Explore an idea",
        "2. Think through a decision",
        "3. Shape a freelance/client-work path",
        "4. Turn this into a project later"
      ],
      "trigger": "User selects Explore/Freelance/Figure Something Out."
    }
  },
  "related_artifacts": [
    {
      "type": "project",
      "title": "Qwrk Beta User Provisioning & Onboarding System",
      "artifact_id": "2f26fbaa-29d1-4188-97ea-d1ad39470f30",
      "relationship": "Adjacent beta onboarding lane; relevant but not the main menu-startup design anchor."
    },
    {
      "type": "twig",
      "title": "QPA as Beta Onboarding Layer — CustomGPT + Qx Delivery",
      "artifact_id": "1fe70be3-72bb-4763-a6cc-a77a9150f543",
      "relationship": "Conceptual bridge establishing QPA as the beta onboarding/operating layer."
    },
    {
      "type": "twig",
      "title": "Twig — Define Workspace Master Context for Beta Wake Behavior",
      "artifact_id": "05a2c05f-dc15-4698-b5ef-4c691ae811d4",
      "relationship": "Related workspace-level context construct for beta wake/startup behavior."
    },
    {
      "type": "twig",
      "title": "Twig — Static Beta Menu with Workbench Signals and Prime User Profile References",
      "artifact_id": "aa686db4-06ed-49ac-b3db-c30bd5710c34",
      "relationship": "Immediate design precursor captured before this snapshot."
    }
  ],
  "design_constraints": [
    "Menu must remain understandable to a brand-new beta user.",
    "Menu labels should be user-facing and avoid QPM/artifact jargon.",
    "Static top-level menu is preferred for predictability.",
    "Profile data enriches menu counts and references but does not hide core options.",
    "Natural-language intent remains valid at every level.",
    "Workbench should be artifact-type agnostic.",
    "Explore/Freelance must remain explicit as a freedom-preserving option.",
    "Support should become a governed request flow, not loose chat only."
  ],
  "primary_project_anchor": {
    "type": "project",
    "title": "Qwrk@Wrk Personal Assist (QPA)",
    "reason": "QPA already contains menu-driven intent selection, session orientation, CmdCtr/context retrieval, daily loop structure, and continuity capture patterns.",
    "artifact_id": "041cd5e4-ffdb-4589-9cf7-849dc40ea8a3"
  },
  "support_request_concept": {
    "flow": [
      "User describes the issue, request, confusion, or feature idea.",
      "Qwrk classifies the request into bug, usability friction, feature request, account/setup issue, data concern, or general question.",
      "Qwrk creates a support request artifact in the user's workspace.",
      "System mirrors or escalates an associated support item into Qwrk Prime, CC, or another support processing lane.",
      "User can later query support status from their own workspace."
    ],
    "working_name": "Support Request Seed Pod",
    "design_principle": "Support artifacts should originate in the user's workspace to preserve user visibility and sovereignty, then escalate outward."
  },
  "cc_review_request_intent": {
    "objective": "Review the static Qwrk Beta startup menu and Prime User Profile design for architecture, schema implications, MVP boundaries, risk, and PRD readiness.",
    "expected_output": "CC should return structured review notes, concerns, recommended refinements, and a proposed MVP build boundary. CC should not implement anything yet."
  },
  "recommended_next_sequence": [
    "Share this design snapshot with CC for review.",
    "Ask CC to critique architecture, identify schema implications, and recommend MVP boundary.",
    "Bring CC review back to Q for synthesis.",
    "Prepare a Manus TQR prompt for full product/design review.",
    "After Manus TQR, synthesize PRD v1.",
    "After PRD v1 approval, launch full sapling build."
  ],
  "prime_user_profile_concept": {
    "definition": "A database-backed Prime User profile record for each workspace/user containing user-provided context, preferences, menu-related reference fields, and quick retrieval pointers.",
    "user_control": "The user may update profile context through a governed profile update sequence, not through casual incidental mutation.",
    "privacy_posture": "User controls how much personal context they share. The system should make profile scope visible and editable over time.",
    "source_of_truth": "Dedicated database record is likely the operational source of truth, with major profile changes optionally captured as historical snapshot artifacts."
  },
  "profile_reference_sections": {
    "support": {
      "purpose": "Tracks support requests, open issues, feedback, and escalation state.",
      "possible_fields": [
        "open_support_request_refs",
        "last_support_request_id",
        "support_preference",
        "support_status_summary"
      ]
    },
    "learning": {
      "purpose": "Tracks how the user learns Qwrk and where to route how-to content.",
      "possible_fields": [
        "learning_level",
        "completed_tutorials",
        "preferred_learning_style",
        "how_to_video_links",
        "last_training_topic"
      ]
    },
    "projects": {
      "purpose": "Maintains quick references for project retrieval and menu indicators.",
      "open_question": "Define the threshold for when project references are too large to keep directly in profile and should move into an archive/index strategy.",
      "possible_fields": [
        "active_project_refs",
        "pinned_project_refs",
        "recent_project_refs",
        "project_status_summary",
        "archived_project_index_ref",
        "project_index_last_refreshed_at"
      ]
    },
    "easy_find": {
      "purpose": "Generalized retrieval references beyond projects, including important journals, snapshots, people, themes, and repeated searches.",
      "possible_fields": [
        "easy_find_refs",
        "favorite_searches",
        "important_artifact_refs",
        "recent_artifact_refs",
        "saved_people_or_entity_refs"
      ]
    },
    "workbench": {
      "purpose": "Tracks open items the user may want surfaced in a My Workbench menu item.",
      "possible_implementation_paths": [
        "Use artifact tag 'workbench' for MVP.",
        "Add artifact-level boolean or structured field later, such as is_workbench_item.",
        "Maintain workbench_refs in the Prime User profile as a quick reference cache."
      ]
    },
    "journal_capture": {
      "purpose": "Tracks the user's journaling preferences, reflection style, tone, privacy posture, and preferred guidance depth.",
      "possible_fields": [
        "journal_style_preference",
        "reflection_depth",
        "default_journal_tags",
        "preferred_question_cadence",
        "capture_confirmation_preference"
      ]
    },
    "session_closeout": {
      "purpose": "Tracks end-session and end-subsession behavior preferences.",
      "possible_fields": [
        "end_session_enabled",
        "end_subsession_enabled",
        "closeout_prompt_style",
        "last_end_session_snapshot_id",
        "last_restart_artifact_id"
      ]
    },
    "startup_orientation": {
      "purpose": "Tracks whether the user has a startup, morning, or daily orientation routine and how Qwrk should run it.",
      "possible_fields": [
        "startup_routine_enabled",
        "startup_routine_type",
        "startup_routine_summary",
        "daily_orientation_template_id",
        "last_orientation_snapshot_id",
        "preferred_startup_prompting_style"
      ]
    }
  },
  "profile_update_protocol_draft": {
    "purpose": "Allow users to update Prime User Profile data safely and intentionally.",
    "non_goal": "Do not silently update durable profile context from casual conversation unless the user explicitly asks to remember or update profile behavior.",
    "sequence": [
      "User asks to update preferences/profile/context.",
      "Qwrk identifies the affected profile section.",
      "Qwrk restates the proposed profile change in plain language.",
      "User confirms.",
      "Qwrk emits or performs the governed update.",
      "Qwrk confirms what changed and how future behavior may differ."
    ]
  }
}
```

---

## 4. ORIGIN TWIG — Twig — Static Beta Menu with Workbench Signals and Prime User Profile References

- **artifact_id:** `aa686db4-06ed-49ac-b3db-c30bd5710c34`
- **artifact_type:** `twig`
- **title:** Twig — Static Beta Menu with Workbench Signals and Prime User Profile References
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `3ccc694d-7d84-4830-8d59-eee3184462fe`
- **semantic_type_id:** _(none)_
- **lifecycle_status:** _(none)_
- **tags:** beta, menu, qpa, workbench
- **created_at:** 2026-05-22 19:10:56.336947+00
- **updated_at:** 2026-05-22 19:10:56.336947+00

**Hydrated spine content:**

```json
{
  "idea": "Qwrk Beta startup should begin with a static, full menu rather than a dynamically generated menu, while showing live counts or open-item indicators beside relevant menu items such as active projects, workbench items, support requests, or saved follow-ups.",
  "why_now": "This refines the QPA-as-beta-onboarding concept into a clearer product direction before PRD creation, CC review, Manus TQR, and eventual sapling build.",
  "future_hook": "Design snapshot should specify a static top-level menu, submenu/action patterns, Prime User Profile reference fields for each menu item, a generalized Workbench marker/tag or future boolean field, explicit Explore/Freelance freedom, Support Request seed pod escalation, and end-session/end-subsession continuity behavior.",
  "problem_touched": "Reduces blank-canvas friction for beta users without forcing them to know what they want upfront, while preserving freedom for users to ignore menu numbers and state natural-language commands at any menu level."
}
```

---

## 5. EXTERNAL DEPENDENCY — T199/UCC — UCC Seed — User Context Core / Startup Identity Layer

- **artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **artifact_type:** `project`
- **title:** Seed — User Context Core / Startup Identity Layer
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `dd409298-4c64-4412-b0e0-2ace13a7283a`
- **semantic_type_id:** `f458c86a-e037-4c48-a4a2-ce228546957f`
- **lifecycle_status:** `seed`
- **tags:** seed, user-context, startup
- **created_at:** 2026-05-06 19:33:07.011143+00
- **updated_at:** 2026-05-06 19:33:07.011143+00

**Hydrated qxb_artifact_project extension row:**

```json
{
  "created_at": "2026-05-06T19:33:07.293625+00:00",
  "updated_at": "2026-05-06T19:33:07.293625+00:00",
  "artifact_id": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
  "design_spine": null,
  "state_reason": null,
  "lifecycle_stage": "seed",
  "operational_state": "active"
}
```

_Note: the UCC seed is a lifecycle anchor (project). Its substantive design content lives in UCC Root Snapshot v2 (artifact 6) and the contracts (artifacts 8-10)._

---

## 6. EXTERNAL DEPENDENCY — T199/UCC — UCC Root Snapshot v2 — Design Synthesis

- **artifact_id:** `2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0`
- **artifact_type:** `snapshot`
- **title:** Root Snapshot v2 — User Context Core Design Synthesis
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **semantic_type_id:** `f458c86a-e037-4c48-a4a2-ce228546957f`
- **lifecycle_status:** _(none)_
- **tags:** for-q, root-snapshot, user-context, startup, synthesis
- **created_at:** 2026-05-06 19:53:46.414934+00
- **updated_at:** 2026-05-06 19:53:46.414934+00

**Hydrated extension.payload:**

```json
{
  "version": "v2",
  "next_step": {
    "scope": "What must be true for the seed to promote seed→sapling without violating any locked decision in this synthesis. Defines lifecycle, payload shape, update rules, retrieval order, schema lock checkpoints, and provisioning contract integration.",
    "action": "CC produces sapling-readiness plan",
    "constraint": "No build prompt; no implementation; design boundaries are still being walked",
    "verdict_ref": "Q final synthesis 2026-05-06 — 'measure twice, pour concrete once'"
  },
  "supersedes": "c1352de4-ca93-48ff-8c49-a34e20a75d6d",
  "concept_name": "User Context Core / Startup Identity Layer",
  "snapshot_type": "root_design_synthesis",
  "wake_load_order": {
    "sequence": [
      "1. User Context Core (who) — must absorb first",
      "2. End Session Snapshot (where) — parallelizable after UCC",
      "3. Rolling Memory (what) — parallelizable after UCC",
      "4. CmdCtr Briefing (state) — parallelizable after UCC"
    ],
    "rationale": "UCC defines who Q is serving; primes interpretation of everything else. RM/End/CmdCtr can load in parallel after UCC absorbs.",
    "empty_ucc_behavior": "Bootstrap state — /wake detects empty UCC and triggers provisioning flow; does NOT proceed to RM/End/CmdCtr until UCC seeded",
    "missing_ucc_behavior": "Fail-soft per Decision 7"
  },
  "governance_hooks": [
    "CLAUDE.md §1 Binding Truth Hierarchy",
    "CLAUDE.md §2.5 Database Read-Only (CC payload only; Joel executes)",
    "CLAUDE.md §3 Absolute No-Overwrite (Pattern C if file artifacts emerge)",
    "CLAUDE.md §11 Planning Gate (sapling promotion will trigger this)",
    "CLAUDE.md §10 Parallel Mutation Guardrail (UCC schema is a structural surface)",
    "T176 Beta Active Launch Program — UCC bootstrap must satisfy 'no AI in provisioning' constraint",
    "T150 Person Artifact — orthogonal; do not merge"
  ],
  "locked_decisions": [
    {
      "id": 1,
      "title": "Artifact type for MVP",
      "decision": "snapshot with record_type: 'user_context_core'",
      "rationale": "Latest-wins matches Rolling Memory pattern Q already absorbs at /wake; immutability is desirable for governance-controlled identity record; no DDL change required for MVP; dedicated DDL type deferred to Walk phase if usage validates pattern"
    },
    {
      "id": 2,
      "title": "Not the person artifact",
      "decision": "UCC is NOT a person record; person and UCC are orthogonal",
      "rationale": "Person = third-party-of-operator (people Joel knows); UCC = operator/user as known by Q. Self ≠ person-in-network. UCC may reference person artifact_ids in important_relationships but UCC itself is not a person record."
    },
    {
      "id": 3,
      "title": "Topology: three-layer model",
      "decision": "Latest UCC snapshot = read projection; accepted-change journals = append-only provenance log; rebuild/compaction = new snapshot, never mutation",
      "components": {
        "audit_log": "journal-per-update, tags=['ucc-update']; references prior snapshot_id; full delta history",
        "projection": "each accepted update emits new snapshot; compaction collapses N updates into checkpoint when worthwhile",
        "read_surface": "latest snapshot, tags=['user-context-core'], workspace-local; what /wake loads"
      },
      "guardrails": [
        "Updates require explicit user confirmation — never auto-emit",
        "Removal = new snapshot omitting field + journal noting retraction; no tombstone in live record",
        "Concurrent updates use parent_snapshot_id for optimistic locking; mid-air conflicts rejected",
        "schema_version field at top of payload; Q at /wake refuses to absorb if schema_version > Q.known_version"
      ]
    },
    {
      "id": 4,
      "audit": "Every read of consent-required field emits a journal entry",
      "title": "Privacy model: tiered-vault",
      "decision": "UCC.core loads every /wake; UCC.vault requires session-specific consent",
      "rationale": "True non-surfacing requires Q to not have the field loaded; 'Q knows but doesn't volunteer' leaks via inference. Tiered-vault protects against inference leakage, workspace-boundary breaches, and creates auditable consent events.",
      "consent_transitions": "User can downgrade (more private) freely; upgrade (less private) requires explicit confirmation prompt; consent_changed_at logged per field",
      "field_sensitivity_classes": [
        "public-to-q (core; Q uses freely)",
        "private-sensitive (core; Q uses with care)",
        "do-not-surface (vault; Q does not surface unprompted)",
        "consent-required (vault; explicit per-session consent prompt before load)"
      ]
    },
    {
      "id": 5,
      "rls": "owner-only — even in shared workspaces (BlaggLife, Akara), UCC is owner-only like journals; workspace members do NOT see each other's UCC",
      "title": "Workspace boundary: workspace-local default",
      "decision": "UCC is workspace-local; no clone, sync, or inheritance without explicit operation",
      "rationale": "Joel's boundaries at Work ≠ Personal ≠ Akara. Cross-workspace clone is rejected by default — privacy-preserving. Existing-user provisioning into a new workspace starts UCC from minimum-required; user opts in to clone-from-source via explicit prompt."
    },
    {
      "id": 6,
      "title": "Provisioning order",
      "decision": "UCC → Bootstrap Rolling Memory → Bootstrap End Session",
      "rationale": "Identity exists first; memory baseline references identity; anchor exists for first /wake. Reverse breaks audit trail.",
      "constraint": "Per T176: all provisioning/binding/initialization via n8n + Gateway + DB — no AI runtime dependency. UCC bootstrap MUST satisfy this — n8n workflow creates UCC at activation; Q first /wake reads UCC, never creates it.",
      "minimum_required_at_provisioning": [
        "display_name",
        "preferred_name",
        "timezone",
        "email",
        "user_id",
        "workspace_id",
        "consent_to_load_at_wake (bool)"
      ]
    },
    {
      "id": 7,
      "title": "Runtime failure behavior: fail-soft",
      "behavior": "Q surfaces: 'User Context Core not found for this workspace. Skip, recreate, or restore?' Never silently proceed without UCC if it's expected to exist.",
      "decision": "Missing UCC during /wake fails soft with restore / skip / recreate options",
      "schema_mismatch": "If schema_version > known, halt absorb, prompt user — prevents silent doctrine drift"
    },
    {
      "id": 8,
      "title": "Provisioning failure behavior: fail-hard",
      "decision": "If UCC is required and missing, provisioning cannot mark workspace ready",
      "rationale": "Asymmetric failure semantics: runtime is forgiving (user can skip/recreate); provisioning is strict (workspace cannot enter ready state without UCC). Prevents downstream first-wake corruption."
    },
    {
      "id": 9,
      "title": "Influence boundary",
      "decision": "UCC can shape tone, pacing, preferences, and continuity. UCC cannot shape governance, priorities, workspace routing, privacy consent, Gateway contract, schema rules, or live user instruction.",
      "ucc_may_influence": [
        "tone of Q responses",
        "pacing of interaction",
        "format/detail preferences",
        "continuity references across sessions",
        "default support mode"
      ],
      "ucc_must_not_influence": [
        "governance rules (CLAUDE.md, SI doctrine)",
        "task/project priorities",
        "workspace routing or domain boundaries",
        "privacy or consent decisions (those flow user → UCC, not UCC → Q)",
        "Gateway contract enforcement",
        "schema or DDL rules",
        "active user instructions in the live conversation"
      ]
    }
  ],
  "schema_v1_sketch": {
    "note": "v1 schema sections preserved from initial root snapshot; further refinement deferred to sapling-readiness plan",
    "sections": {
      "user": "Basic identity and routing context",
      "boundaries": "Controls on what Qwrk must not assume or surface without consent",
      "provenance": "Track entry origin and update audit",
      "q_behavior": "Explicit behavior rules and known shortcuts",
      "review_control": "Prevent stale identity, preserve user sovereignty",
      "standing_context": "Durable user context across sessions",
      "service_preferences": "How Qwrk should communicate and pace interaction",
      "_tier_classification": "Each section field is tagged core | vault per Decision 4"
    },
    "record_type": "user_context_core",
    "size_target": "2-4KB initially; not a comprehensive biography",
    "schema_version": "v1"
  },
  "seed_artifact_id": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
  "synthesis_inputs": {
    "cc_review": {
      "role": "Critique on 5 focus areas (artifact type, mutability/update model, /wake load order, privacy controls, provisioning integration); recommended three-layer mutability model and tiered-vault privacy model",
      "source": "CC subsession 2026-05-06 (post-CLAUDE.md v32 lane)"
    },
    "manus_review": {
      "role": "Confirmed core architecture; added boundary rules — UCC is descriptive context not governance; deterministic workspace-scoped /wake; runtime fail-soft vs provisioning fail-hard",
      "source": "Manus pass relayed via Q compiled WSY 2026-05-06"
    },
    "v1_root_snapshot": {
      "role": "Initial OWL-level design — danger framing, entry-test, Option A architecture, schema v1 sketch, open questions",
      "artifact_id": "c1352de4-ca93-48ff-8c49-a34e20a75d6d"
    },
    "q_final_synthesis": {
      "role": "Locked decisions 1–9; identified the most-important-design-sentence; verdict = proceed to v2 root snapshot, no sapling yet",
      "source": "QP compiled WSY 2026-05-06"
    }
  },
  "out_of_scope_for_v2": [
    "Sapling promotion (explicit hold per Q verdict — design boundaries lock first)",
    "Schema field-by-field finalization (deferred to sapling-readiness plan)",
    "Implementation: payload shape, Save sub-workflow integration, /wake protocol changes, retrieval RPC",
    "Compaction policy cadence (every N journals or M days — to be specified at sapling)",
    "Cross-workspace UCC migration tooling (workspace-local default per Decision 5; future opt-in)",
    "GDPR export integration (qxb_user_data_export RPC — future-debt note, not blocking)",
    "T176 Activation Code Lifecycle integration details (handoff to T176 lane, not built here)"
  ],
  "most_important_design_sentence": "User Context Core is descriptive context for safe personalization and continuity. It is not governance, not memory, not security state, and not authority over live user instruction."
}
```

---

## 7. EXTERNAL DEPENDENCY — T199/UCC — Decision — User Orientation Profile Folded into UCC

- **artifact_id:** `f01106f8-bb47-4b18-826a-0f90d32c7478`
- **artifact_type:** `snapshot`
- **title:** Decision — User Orientation Profile Folded into UCC
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** _(none)_
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **lifecycle_status:** _(none)_
- **tags:** for-q, ucc, beta, governance
- **created_at:** 2026-05-09 12:34:50.448201+00
- **updated_at:** 2026-05-09 12:34:50.448201+00

**Hydrated extension.payload:**

```json
{
  "status": "locked_as_vocabulary_reconciliation_decision",
  "context": "Joel proposed a beta onboarding and /wake enhancement where Qwrk gathers user preferences, AI usage, shortcuts, and durable personalization context. CC performed an artifact scan and found the concept already exists in Qwrk as User Context Core (UCC). Manus confirmed this is a structural match, not a greenfield concept. The correct move is vocabulary reconciliation and routing through the existing UCC/T199 lane, not creation of a competing profile layer.",
  "decision": "Treat the proposed User Orientation Profile / soul file concept as existing User Context Core (UCC), not as a new architecture lane.",
  "decision_date": "2026-05-09",
  "source_inputs": [
    {
      "source": "CC preliminary artifact scan",
      "summary": "Found that the proposed User Orientation Profile concept matches existing UCC doctrine, especially artifacts 088aa61b and 2f96f79e."
    },
    {
      "source": "Manus TQR concept reconciliation review",
      "summary": "Confirmed the concept should be treated as UCC unless true structural deltas are identified; recommended UCC as governance name, My Qwrk Profile as user-facing label, and personalization/continuity layer as safer wording."
    },
    {
      "source": "Joel/Q discussion",
      "summary": "Joel clarified that the existing user table and workspace-owner model should be leveraged rather than creating a loose standalone artifact."
    }
  ],
  "beta_mvp_posture": {
    "defer": "Rich enrichment until privacy gates, consent posture, and provisioning integration are resolved.",
    "include": "Minimum UCC shell during beta provisioning / first-wake readiness.",
    "minimum_shell_candidates": [
      "preferred_name",
      "timezone",
      "communication/detail preference",
      "basic AI/Qwrk use case",
      "consent/load preference"
    ],
    "vault_or_consent_governed_candidates": [
      "important_people",
      "operating_patterns",
      "watch_for",
      "broad do_not_forget entries",
      "sensitive personal context"
    ]
  },
  "locked_decisions": [
    {
      "id": "D1",
      "decision": "UCC remains the canonical governance/system name for this capability."
    },
    {
      "id": "D2",
      "decision": "The preferred user-facing Beta label is My Qwrk Profile."
    },
    {
      "id": "D3",
      "decision": "My Qwrk Preferences is acceptable only if the Beta MVP is intentionally narrowed to preferences rather than broader user context."
    },
    {
      "id": "D4",
      "decision": "Soul file is retired from user-facing and governance-facing language. It may remain informal builder shorthand only if it does not leak into product, documentation, or system contracts."
    },
    {
      "id": "D5",
      "decision": "UCC should be described as a personalization/continuity layer loaded during /wake, not as a system memory/control layer."
    },
    {
      "id": "D6",
      "decision": "No competing User Orientation Profile architecture will be created beside UCC."
    },
    {
      "id": "D7",
      "decision": "Future implementation work routes through the existing UCC/T199 lane."
    },
    {
      "id": "D8",
      "decision": "Beta MVP should include a minimum UCC shell unless explicitly expanded later."
    }
  ],
  "implementation_gates": [
    "Do not create a competing profile layer.",
    "Route through UCC/T199.",
    "Clear or explicitly handle T199 privacy gates before implementation planning.",
    "Keep provisioning and onboarding separate: provisioning creates minimum UCC shell; onboarding enriches later.",
    "Do not let Q/GPT become provisioning authority.",
    "Propagate Bootstrap Bookmark Doctrine to T176 Branch B and T145 before relying on first-wake bootstrap behavior.",
    "Respect T176/T187 beta blocker state before release-impacting implementation."
  ],
  "user_facing_language": {
    "avoid": [
      "Soul file",
      "system memory/control layer",
      "User Orientation Profile as a separate canonical architecture"
    ],
    "preferred_label": "My Qwrk Profile",
    "preferred_description": "A personalization and continuity profile that helps Qwrk orient to the user within this workspace.",
    "acceptable_narrow_label": "My Qwrk Preferences"
  },
  "governance_boundaries": {
    "ucc_may_shape": [
      "tone",
      "pacing",
      "format/detail preferences",
      "continuity",
      "default support mode",
      "explicit user shortcuts and preferences"
    ],
    "ucc_must_not_shape": [
      "governance",
      "priorities",
      "workspace routing",
      "privacy or consent decisions",
      "Gateway contract",
      "schema behavior",
      "live user instruction"
    ],
    "workspace_boundary": "UCC remains workspace-local. No cross-workspace clone, sync, inheritance, or sharing occurs without explicit operation and consent."
  }
}
```

---

## 8. EXTERNAL DEPENDENCY — T199/UCC — UCC Read Contract v1

- **artifact_id:** `b95ec7a4-0a62-4714-817e-0b07bb044808`
- **artifact_type:** `snapshot`
- **title:** Contract Snapshot — UCC Read Contract v1
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **lifecycle_status:** _(none)_
- **tags:** for-q, ucc-contract, read, user-context
- **created_at:** 2026-05-06 20:36:55.71987+00
- **updated_at:** 2026-05-06 20:36:55.71987+00

**Hydrated extension.payload:**

```json
{
  "scope": {
    "in": [
      "Default /wake retrieval contract for UCC content snapshots",
      "Validation, ordering, fall-through, and failure semantics for the read path",
      "Vault leakage prevention at the read boundary"
    ],
    "out": [
      "Vault artifact shape, vault index, vault retrieval flow, vault consent UI (Privacy Contract v1)",
      "UCC update emission shape (Update Contract v1)",
      "Bootstrap UCC creation and per-workspace UCC root anchor (Provisioning Contract v1)",
      "Restore from soft-delete (future Restore Contract)",
      "Compaction trigger and rebuild emission (Update Contract v1)",
      "Cross-workspace UCC clone (future feature with Cross-Workspace Write Gate)",
      "Q known-schema-version bump mechanism (Q-head doctrine)",
      "Semantic classification of UCC content snapshots (Provisioning Contract v1 or earlier)",
      "Joel-side anomaly log storage (Q-head doctrine)"
    ]
  },
  "concept": "User Context Core / Startup Identity Layer",
  "lineage": {
    "seed": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
    "root_snapshot_v1": "c1352de4-ca93-48ff-8c49-a34e20a75d6d",
    "root_snapshot_v2_synthesis": "2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0"
  },
  "purpose": "Define the canonical retrieval shape, filters, ordering, and failure behavior for User Context Core absorption at /wake. Read path only.",
  "glossary": {
    "q": "Reasoning agent absorbing UCC. Multi-instance (heads + concurrent sessions) governed uniformly.",
    "wake_load": "Startup absorption sequence: UCC, then End Session, then Rolling Memory, then CmdCtr.",
    "ucc_snapshot": "A snapshot artifact tagged ['user-context-core','for-q'] carrying the read projection.",
    "valid_snapshot": "A UCC snapshot passing all checks in §6, §7, §8, §10, §11.",
    "candidate_window": "The bounded set of most-recent UCC snapshots considered during retrieval (max 5 per §2)."
  },
  "sections": {
    "12_absorption_boundary": {
      "title": "Absorption Boundary",
      "diagnostic_surfacing_allowance": "Q MAY use non-absorbed envelope fields for diagnostic surfacing (e.g., showing snapshot timestamp in the Skip/Recreate prompt copy), but MUST NOT incorporate them into identity context that influences response generation.",
      "absorbed_into_q_identity_context": [
        "extension.payload.core — the read projection content"
      ],
      "must_not_be_treated_as_identity_context": [
        "The full hydrated artifact envelope (spine columns, tags, etc.)",
        "extension.payload.vault_metadata (informational only — used for vault availability signaling)",
        "Any field outside core not enumerated above",
        "Any unrelated spine column (title, priority, parent_artifact_id, etc.) — these are operational/structural, not identity"
      ],
      "absorbed_for_validation_only_not_identity_context": [
        "extension.payload.record_type",
        "extension.payload.schema_version",
        "extension.payload.workspace_id (for §3 mismatch check)",
        "extension.payload.user_id",
        "extension.payload.generated_at (for staleness display only)"
      ],
      "diagnostics_only_must_not_be_absorbed_or_influence_response_generation": [
        "extension.payload.prior_snapshot_id — MAY be used for chain audit and diagnostics. MUST NOT be absorbed as identity context. MUST NOT influence response generation."
      ]
    },
    "13_open_items_deferred": {
      "title": "Open Items Explicitly Deferred to Other Contracts",
      "deferred_list": [
        "Vault artifact type, vault index, vault retrieval flow, vault consent UI → Privacy Contract v1",
        "UCC update emission shape (ucc-update snapshot payload) → Update Contract v1",
        "Bootstrap UCC creation at provisioning → Provisioning Contract v1",
        "Workspace UCC root anchor creation per workspace → Provisioning Contract v1",
        "Restore from soft-delete → future Restore Contract",
        "Compaction trigger and rebuild emission → Update Contract v1",
        "Cross-workspace UCC clone → future feature with Cross-Workspace Write Gate enforcement",
        "Q known-schema-version bump mechanism → Q-head doctrine (separate lane)",
        "Semantic classification for UCC content snapshots (the /wake-loaded ones, distinct from this Read Contract's own classification of governance) → Provisioning Contract v1 or earlier",
        "Joel-side anomaly log storage for tie-break collisions and multi-invalid-candidate events → Q-head doctrine (separate lane)"
      ]
    },
    "8_over_budget_behavior": {
      "title": "Over-Budget Behavior (No Silent Truncation)",
      "hard_rules": [
        "Q MUST NOT silently truncate",
        "Q MUST NOT modify or trim payload during retrieval",
        "Q MUST NOT cache the over-budget snapshot's content even partially"
      ],
      "size_budget": {
        "target": "2-4KB for extension.payload",
        "hard_ceiling": "8KB"
      },
      "privacy_precedence": "If a payload is over budget AND inspection indicates the bloat is caused by vault-classified material embedded in core, the snapshot MUST be treated as privacy-violating / invalid per §10 and §11, not merely over-budget. Privacy violation outranks normal payload bloat.",
      "size_behavior_table": [
        {
          "size": "≤ 4KB",
          "behavior": "Absorb normally"
        },
        {
          "size": "4-8KB",
          "behavior": "Absorb; emit non-blocking warning (TEMPLATE, behavior locked): 'UCC approaching size limit; recommend compaction at next user-confirmed update'"
        },
        {
          "size": "> 8KB",
          "behavior": "Halt absorption of this snapshot. Treat as invalid candidate; fall through to next candidate in window per §10. If a smaller valid candidate exists, load it with surfacing (TEMPLATE): 'Latest UCC snapshot exceeds size budget; loaded prior snapshot. Compaction needed before next update.' If no valid candidate within the 5-deep window, fail-soft per §9."
        }
      ]
    },
    "6_record_type_placement": {
      "rule": "record_type: 'user_context_core' MUST be placed at the top level of extension.payload (sibling to schema_version). NOT in extension.payload.core. NOT as a top-level spine column.",
      "title": "record_type Placement",
      "rationale": "record_type is content metadata distinguishing UCC from other future snapshot record types within the same artifact_type=snapshot class. Spine has artifact_type for the artifact-class distinction.",
      "validation": "Q at /wake MUST validate record_type === 'user_context_core' before absorbing payload as UCC. If absent or different, treat as invalid per §10."
    },
    "9_missing_ucc_fail_soft": {
      "title": "Missing-UCC Fail-Soft Behavior",
      "trigger": "The candidate window (§2) is empty OR all 5 candidates are invalid (§10).",
      "skip_behavior": "Q proceeds with remainder of /wake load, operates without UCC for the session, no persistent state change.",
      "blocking_behavior": "Q MUST wait for explicit user choice. Q MUST NOT silently proceed to End Session / Rolling Memory / CmdCtr until choice is made.",
      "recreate_or_restore_behavior": "Out of scope here — defined in Provisioning Contract v1 and future Restore Contract.",
      "user_prompt_template_behavior_locked": "User Context Core not found for this workspace. Options: Skip — proceed without UCC for this session (Q operates without identity context); Recreate — start UCC bootstrap flow now (per Provisioning Contract v1); Restore — search soft-deleted UCC snapshots and restore the most recent (Joel-confirmed; future Restore Contract)."
    },
    "1_canonical_payload_shape": {
      "title": "Canonical Payload Shape",
      "parent_strategy": {
        "other_workspaces": "workspace UCC root anchor MUST be defined in Provisioning Contract v1. Read Contract does NOT invent per-workspace anchors.",
        "spine_vs_revision_chain": "prior_snapshot_id (revision chain in payload) is distinct from parent_artifact_id (spine structural parent). They serve different purposes and MUST NOT be conflated.",
        "prime_workspace_transitional": "parent_artifact_id for Prime UCC content snapshots resolves to seed 088aa61b-a488-4d28-bdb6-e3c0e92b9abf until Provisioning Contract v1 defines a permanent workspace UCC root anchor"
      },
      "gateway_format_caveat": "When a save payload using semantic_type_id is prepared, the value MUST satisfy the current Gateway requirement (registry key string, registry UUID, or supported alias). Verify against live qxb_semantic_type_registry at payload-prep time. As of 2026-05-06: 'governance' is an active registry key resolved by the Gateway internally.",
      "vault_metadata_constraints": [
        "MUST NOT include fields_present, consent_required_for, or any list/enumeration of vault field names",
        "Privacy Contract v1 MAY further reduce this to zero vault signaling if 'vault exists' is itself considered leaky",
        "Read Contract permits the boolean shape; Privacy Contract may override"
      ],
      "ucc_content_canonical_shape": {
        "tags": [
          "user-context-core",
          "for-q"
        ],
        "title": "User Context Core — <workspace_label> — <YYYY-MM-DD>",
        "artifact_type": "snapshot",
        "semantic_type_id": "<deferred per above>",
        "parent_artifact_id": "<workspace UCC root anchor; see parent_strategy below>",
        "extension_payload_keys": {
          "core": {
            "user": "tier-classified core fields per Privacy Contract v1",
            "boundaries": "core",
            "provenance": "core",
            "q_behavior": "core",
            "review_control": "core",
            "standing_context": "core",
            "service_preferences": "core"
          },
          "user_id": "<UUID>",
          "record_type": "user_context_core",
          "generated_at": "<ISO datetime>",
          "workspace_id": "<UUID>",
          "schema_version": "v1",
          "vault_metadata": {
            "default_loaded": "boolean — always false in default /wake load; included for explicitness",
            "vault_available": "boolean — whether vault content exists for this user/workspace"
          },
          "prior_snapshot_id": "<artifact_id of superseded UCC snapshot, or null if bootstrap>"
        }
      },
      "semantic_classification_of_this_contract_artifact": {
        "value": "governance",
        "reason": "This contract governs startup retrieval behavior. Content of UCC itself is NOT governance per Decision 9 of Root Snapshot v2; the contract artifact is governance because it locks behavior."
      },
      "semantic_classification_of_future_ucc_content_snapshots": {
        "status": "deferred",
        "candidates": [
          "platform",
          "infrastructure",
          "or another approved type"
        ],
        "lock_point": "Provisioning Contract v1 or earlier"
      }
    },
    "11_vault_leakage_prevention": {
      "title": "Vault Leakage Prevention",
      "detection": "If a UCC candidate contains vault values in core, Q MUST treat it as invalid per §10. This is a Save-side contract violation upstream — Read Contract enforces detection; upstream prevention is Privacy Contract / Save sub-workflow concern.",
      "hard_rule": "Vault fields MUST be physically absent from the default /wake payload.",
      "specifics": [
        "extension.payload.core MUST NOT contain any field classified as vault per Privacy Contract v1",
        "extension.payload.vault_metadata carries only minimal non-enumerating signals (vault_available, default_loaded) per §1; MUST NOT enumerate vault field names",
        "Vault VALUES MUST be stored in a separate artifact governed by Privacy Contract v1 (artifact type, retrieval, consent flow, vault index defined there — explicitly out of scope here)",
        "The default /wake retrieval (§2) MUST NOT join, query, or read any artifact carrying vault values"
      ],
      "cache_discipline": "Q MUST NOT cache or persist vault values across sessions even after consented vault load. Vault content is per-session ephemeral by Privacy Contract v1 design.",
      "read_contract_bounds": [
        "default /wake MUST NOT enumerate vault fields",
        "default /wake MUST NOT load vault values",
        "vault artifact shape, vault index, and consent UI belong to Privacy Contract v1"
      ]
    },
    "2_tags_and_retrieval_filter": {
      "title": "Tags and Retrieval Filter",
      "optional_tags": [
        {
          "tag": "bootstrap",
          "purpose": "first UCC snapshot at provisioning (audit aid)"
        },
        {
          "tag": "compaction",
          "purpose": "snapshot generated by rebuild/compaction (vs accepted-update emission)"
        }
      ],
      "required_tags": [
        {
          "tag": "user-context-core",
          "role": "required"
        },
        {
          "tag": "for-q",
          "role": "required startup-scope tag"
        }
      ],
      "gateway_equivalent": "artifact.list with artifact_type=snapshot, selector.filters.tags_any=['user-context-core','for-q'], limit=5, hydrate=true. Workspace boundary enforced by Gateway credential resolution.",
      "bounded_scan_rationale": "Corrupt/over-budget/privacy-violating snapshots require fall-through to the next valid candidate (§8, §10, §11). An unbounded scan would create a degraded mode where Q archaeologically recovers from arbitrarily old snapshots. Five candidates is sufficient depth for handling transient corruption while preventing silent reliance on stale state.",
      "tag_semantics_clarification": {
        "expectation": "selector.filters.tags_any MUST behave as set-containment / tags-all. The candidate artifact MUST contain BOTH user-context-core AND for-q. Despite the field name tags_any, this is the expected and required interpretation for UCC retrieval.",
        "authoritative_reference": "The SQL form (above) uses chained ? JSONB key-existence operators which are unambiguously AND-semantics.",
        "defensive_post_validation": "If the Gateway implementation does NOT guarantee AND-semantics for tags_any (or if behavior changes in a future Gateway version), Q MUST post-validate that the returned artifact's tags array contains both tags before absorbing. A candidate failing post-validation is treated as invalid per §10."
      },
      "canonical_sql_retrieval_filter": "SELECT a.*, s.payload FROM qxb_artifact a JOIN qxb_artifact_snapshot s ON s.artifact_id = a.artifact_id WHERE a.artifact_type = 'snapshot' AND a.workspace_id = $WORKSPACE_ID AND a.deleted_at IS NULL AND a.tags ? 'user-context-core' AND a.tags ? 'for-q' ORDER BY a.created_at DESC, a.version DESC, a.artifact_id DESC LIMIT 5;"
    },
    "3_workspace_scoped_retrieval": {
      "rule": "UCC retrieval MUST be workspace-scoped. The retrieval filter MUST include workspace_id from the active /wake context. Gateway enforces workspace boundary via credential→workspace map.",
      "title": "Workspace-Scoped Retrieval",
      "defense_in_depth": "If a UCC snapshot is found whose internal extension.payload.workspace_id differs from the active session's workspace, Q MUST treat it as invalid per §10 (workspace mismatch). This catches data-layer drift even if Gateway-level enforcement is bypassed."
    },
    "10_invalid_candidate_behavior": {
      "title": "Invalid-Candidate Behavior (Corrupt, Privacy-Violating, Workspace-Mismatched)",
      "no_mutation": "Q MUST treat invalid candidates as read-only inputs. No update/cleanup/repair operations during /wake retrieval.",
      "anomaly_logging": "Joel-side anomaly logging recommended but out of scope for this contract.",
      "invalid_conditions": [
        "extension.payload missing",
        "record_type missing or not 'user_context_core' (per §6)",
        "schema_version missing or invalid format (per §7)",
        "core section missing",
        "Internal payload.workspace_id mismatches active session workspace (per §3)",
        "JSON parse error",
        "Vault values present in core (privacy violation per §11)",
        "Tags fail post-validation (per §2 — both user-context-core AND for-q not present)"
      ],
      "user_facing_copy_constraint": "Multi-invalid surfacing is summary-level only. Per-candidate failure reasons MUST NOT appear in user-facing copy. Detailed anomaly logging is out of scope for this contract.",
      "fall_through_behavior_bounded": [
        "Within the candidate window of up to 5 snapshots, Q evaluates candidates in §5 ordering",
        "The first valid candidate is loaded",
        "If candidates 1..N are invalid and candidate N+1 is valid, Q loads candidate N+1 and surfaces (TEMPLATE, behavior locked): 'Latest UCC snapshot for this workspace was invalid; loaded prior valid snapshot.'",
        "If all 5 candidates are invalid, fail-soft per §9 with additional summary-level surfacing (TEMPLATE): 'Multiple invalid UCC candidates encountered. Bootstrap state recommended.'",
        "Q MUST NOT scan beyond the 5-candidate window. No unbounded archaeology."
      ]
    },
    "4_active_non_deleted_constraint": {
      "rule": "Soft-deleted artifacts (deleted_at IS NOT NULL) MUST NOT be returned in the candidate window. If the candidate window is empty, fail-soft per §9.",
      "title": "Active / Non-Deleted Constraint",
      "deferred": "Restore-from-soft-delete is out of scope here (future Restore Contract)."
    },
    "5_latest_ordering_and_tie_break": {
      "title": "Latest Ordering and Tie-Break (within candidate window)",
      "ordering": [
        {
          "role": "primary",
          "rule": "created_at DESC",
          "step": 1
        },
        {
          "role": "secondary; default 1 for snapshot inserts; meaningful only if a future contract uses it",
          "rule": "version DESC",
          "step": 2
        },
        {
          "role": "tertiary; abnormal collision indicator",
          "rule": "artifact_id DESC",
          "step": 3
        }
      ],
      "candidate_processing": "Q processes the candidate window in this order, loading the first valid snapshot (per §10 valid-check). If the first candidate is invalid, the second is evaluated, and so on. If all 5 candidates are invalid, fail-soft per §9 with multi-invalid surfacing per §10.",
      "tie_break_collision_anomaly": {
        "trigger": "Reaching step 3 (two snapshots share both created_at and version)",
        "q_behavior": [
          "Continue with the deterministic choice (highest artifact_id lexicographically)",
          "Log the collision (Q-side telemetry; storage out of scope here)",
          "Surface a non-blocking warning at next session start handoff"
        ]
      }
    },
    "14_conformance_to_carry_forward_requirements": {
      "title": "Conformance to Carry-Forward Requirements (from sapling-readiness review)",
      "mapping": [
        {
          "section": "§1",
          "requirement": "1. Exact payload shape"
        },
        {
          "section": "§2",
          "requirement": "2. Required tags + filters"
        },
        {
          "section": "§3",
          "requirement": "3. Workspace-scoped retrieval"
        },
        {
          "section": "§4",
          "requirement": "4. Active/non-deleted constraint"
        },
        {
          "section": "§5",
          "requirement": "5. Latest ordering + tie-break"
        },
        {
          "section": "§6",
          "requirement": "6. record_type placement"
        },
        {
          "section": "§7",
          "requirement": "7. schema_version placement + too-new behavior"
        },
        {
          "section": "§8",
          "requirement": "8. Over-budget behavior (no silent truncation)"
        },
        {
          "section": "§9",
          "requirement": "9. Missing-UCC fail-soft"
        },
        {
          "section": "§10",
          "requirement": "10. Corrupt-UCC behavior"
        },
        {
          "section": "§11",
          "requirement": "11. Vault leakage detection"
        }
      ],
      "additional_section_added_at_review": "§12 Absorption Boundary (Amendment 8 from Team Qwrk WSY)"
    },
    "7_schema_version_placement_and_too_new_behavior": {
      "title": "schema_version Placement and Schema-Too-New Behavior",
      "placement": "schema_version MUST be placed at the top level of extension.payload adjacent to record_type.",
      "format_lock_v1": {
        "allowed_pattern": "vN, vN.N, or vN.N.N",
        "forbidden_in_v1": [
          "v1.1-rc1",
          "v1+build123"
        ],
        "allowed_examples": [
          "v1",
          "v1.1",
          "v1.1.3",
          "v2"
        ],
        "suffix_support_note": "Pre-release and build-metadata suffixes are forbidden for v1. Any future suffix support would require later schema-version doctrine, not modification of this contract."
      },
      "comparison_table": [
        {
          "behavior": "Absorb normally",
          "comparison": "Q.known_version equal to payload.schema_version"
        },
        {
          "behavior": "Absorb (forward-compatible read)",
          "comparison": "Q.known_version greater than payload.schema_version"
        },
        {
          "behavior": "Halt absorption. Surface user prompt (TEMPLATE wording, behavior locked, copy refinable): 'User Context Core schema version <payload.schema_version> is newer than this Q head's known version (<Q.known>). Skip UCC for this session, or update Q before proceeding?' Wait for explicit user choice. Do NOT silently downgrade.",
          "comparison": "Q.known_version less than payload.schema_version"
        },
        {
          "behavior": "Treat as invalid per §10",
          "comparison": "Format invalid or missing"
        }
      ],
      "comparison_semantics": "Schema version comparison MUST parse numeric components (split on '.', parse each segment as integer). Lexical/string comparison is FORBIDDEN. This prevents v10 vs v2 style drift when minor or major versions reach double digits.",
      "q_known_version_registry": "Q maintains a known-schema-version registry per Q-head (governance-level; bump mechanism out of scope here)."
    }
  },
  "contract_name": "UCC Read Contract v1",
  "snapshot_type": "design_contract",
  "review_history": {
    "draft_1": "CC initial draft 2026-05-06",
    "draft_2": "Team Qwrk amendments incorporated (9 amendments)",
    "draft_3_save_ready": "Final cleanup applied per Manus+Q review (5 items)"
  },
  "resolved_inputs": {
    "tie_break_ordering": {
      "note": "Reaching artifact_id DESC is an abnormal collision condition, not normal business logic",
      "primary": "created_at DESC",
      "tertiary": "artifact_id DESC",
      "secondary": "version DESC"
    },
    "update_log_artifact_type": {
      "decision": "Accepted UCC changes are append-only provenance artifacts. MVP implementation uses immutable snapshot artifacts tagged ucc-update. Reflective journals are not canonical UCC update logs.",
      "supersedes": "Decision 3 wording in Root Snapshot v2 (refined, not contradicted)"
    }
  },
  "contract_version": "v1",
  "governance_hooks": [
    "CLAUDE.md §1 Binding Truth Hierarchy",
    "CLAUDE.md §2 No-Guessing (resolved inputs locked before draft 2)",
    "CLAUDE.md §2.5 Database Read-Only (CC produces contracts; Joel/Q execute)",
    "CLAUDE.md §3 Pattern C Archive-based versioning (future contract revisions)",
    "CLAUDE.md §4 Pre-Write Confirmation Gate (this payload is review-pending)",
    "CLAUDE.md §10 Parallel Mutation Guardrail (UCC schema is structural surface)",
    "CLAUDE.md §11 Planning Gate (sapling promotion requires this contract locked)"
  ],
  "document_conventions": {
    "user_facing_copy": "Example user-facing prompts marked TEMPLATE are illustrative. Behavior is locked; exact copy may be refined by Q before runtime use without contract amendment, provided behavior is preserved. Sections containing TEMPLATE wording: §7, §8, §9, §10.",
    "placeholder_marker": "<…> indicates a value filled at usage time",
    "rfc_strength_keywords": "MUST, MUST NOT, SHOULD used in RFC sense"
  },
  "approved_as_written_inventory": {
    "description": "Items explicitly preserved from prior drafts under Manus + Q review. Listed as plain contract statements.",
    "preserved_contract_statements": [
      "UCC content lives in extension.payload.",
      "record_type 'user_context_core' is placed at the top level of extension.payload.",
      "schema_version is placed at the top level of extension.payload.",
      "UCC retrieval is workspace-scoped at both Gateway and payload-internal levels.",
      "Internal payload.workspace_id mismatch is treated as an invalid candidate.",
      "Missing UCC at /wake fails soft with Skip / Recreate / Restore options.",
      "Invalid or corrupt candidate snapshots are skipped and never mutated by Q during retrieval.",
      "Vault values are physically absent from the default /wake payload.",
      "Latest ordering uses created_at DESC, then version DESC, then artifact_id DESC.",
      "Accepted-change provenance uses snapshot artifacts tagged ucc-update; the update-log payload shape itself remains out of scope for this Read Contract."
    ]
  },
  "alignment_with_root_snapshot_v2": {
    "decision_4_tiered_vault": "Honored — vault values physically absent from /wake payload; minimal vault_metadata only",
    "decision_7_runtime_fail_soft": "Honored — §9 fail-soft behavior",
    "decision_9_influence_boundary": "Honored — §12 absorption boundary explicitly limits identity context to core, prevents UCC from influencing governance/priorities/contract through retrieval-side leakage",
    "most_important_design_sentence": "Honored throughout — UCC is descriptive context for safe personalization and continuity. It is not governance, not memory, not security state, and not authority over live user instruction.",
    "decision_3_three_layer_topology": "Honored — Read Contract addresses read projection layer; provenance and rebuild deferred to Update Contract v1",
    "decision_1_artifact_type_for_mvp": "Honored — UCC content is snapshot with record_type user_context_core",
    "decision_5_workspace_local_default": "Honored — workspace-scoped retrieval at Gateway and payload-internal levels"
  }
}
```

---

## 9. EXTERNAL DEPENDENCY — T199/UCC — UCC Provisioning Integration Contract v1

- **artifact_id:** `cf74279e-5d02-4ee8-85c8-aa9826e1bea9`
- **artifact_type:** `snapshot`
- **title:** Contract Snapshot — UCC Provisioning Integration Contract v1
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **lifecycle_status:** _(none)_
- **tags:** for-q, ucc-contract, provisioning, user-context
- **created_at:** 2026-05-06 21:22:25.872513+00
- **updated_at:** 2026-05-06 21:22:25.872513+00

**Hydrated extension.payload:**

```json
{
  "scope": {
    "in": [
      "Provisioning bundle composition, order, atomicity",
      "Workspace UCC enablement signal (workspace-config snapshot)",
      "/wake invocation gate chain",
      "Workspace UCC root anchor creation",
      "T176 Activation Code Lifecycle handshake interface (TBD-marked)",
      "n8n/Gateway/DB-only constraint enforcement",
      "Provisioning fail-hard semantics",
      "Idempotent re-entry",
      "Existing-user-new-workspace flow",
      "Beta-first rollout boundary"
    ],
    "out": [
      "UCC content payload shape (Read Contract v1)",
      "UCC update emission shape (Update Contract v1)",
      "Vault artifact + tier classification + consent UI (Privacy Contract v1)",
      "Restore-from-soft-delete (future Restore Contract)",
      "T176 Activation Code Lifecycle Contract internals — only the handshake interface is referenced",
      "T176 Master Record concept",
      "T176 Binding mechanism implementation",
      "Q known-schema-version bump mechanism",
      "Retrofit of Prime, Q@W, or current Qwrk_Akara — explicitly forbidden absent separate approval (§13)",
      "DDL changes — explicitly forbidden in this contract",
      "Implementation work (n8n nodes, RLS policies, Gateway changes)",
      "Operator-side anomaly logging payload shape",
      "Clone operation implementation",
      "Disable/re-enable authority and mechanics (§6.11 — future authorized lane and contract)"
    ]
  },
  "concept": "User Context Core / Startup Identity Layer — Provisioning Path",
  "lineage": {
    "seed": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
    "root_snapshot_v1": "c1352de4-ca93-48ff-8c49-a34e20a75d6d",
    "ucc_read_contract_v1": "saved 2026-05-06; governs /wake retrieval behavior post-invocation",
    "root_snapshot_v2_synthesis": "2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0",
    "t176_beta_active_launch_sapling": "4cac82b5-c9ff-40a6-9e5e-9778fc249ebf"
  },
  "purpose": "Define how UCC artifacts are created at workspace provisioning, how /wake learns whether to invoke UCC retrieval for the active workspace, and how the bundle landing is gated externally as atomic.",
  "glossary": {
    "ucc_bundle": "The three artifacts created at workspace provisioning: UCC content snapshot, Bootstrap Rolling Memory, Bootstrap End Session.",
    "ucc_enabled": "Boolean flag in workspace-config snapshot payload. true indicates workspace participates in UCC retrieval at /wake.",
    "for_q_tag_role": "Startup-scope tag. Not a governance authority signal.",
    "externally_atomic": "Workspace MUST NOT be marked ready=true (T176 readiness state) unless full bundle has landed and validated. Internal step ordering may be non-atomic; external visibility is binary.",
    "idempotent_re_entry": "A provisioning workflow execution that detects existing valid bundle members and avoids creating competing duplicates. (See §10.)",
    "workspace_config_snapshot": "Snapshot artifact carrying the ucc_enabled signal (and future config). Latest-wins, deterministic retrieval. Sole enablement authority for /wake.",
    "workspace_ucc_root_anchor": "Per-workspace project seed serving as structural parent for UCC content snapshots in that workspace. Non-executional. NOT an enablement signal.",
    "provisioning_bundle_landed_and_validated": "All 3 bundle artifacts created, valid (Read Contract §10 valid-check for UCC), and addressable via Gateway query."
  },
  "sections": {
    "1_purpose_and_scope": {
      "title": "Purpose and Scope",
      "summary": "Mirrors top-level purpose and scope above. See contract preamble."
    },
    "16_open_items_deferred": {
      "title": "Open Items Deferred to Other Contracts",
      "deferred_list": [
        "UCC content payload shape (Read Contract v1 — saved)",
        "UCC accepted-change snapshot shape, optimistic locking, rebuild emission (Update Contract v1)",
        "Vault artifact shape, vault tier classification, vault retrieval, vault consent UI (Privacy Contract v1)",
        "Restore-from-soft-delete (future Restore Contract)",
        "T176 Activation Code Lifecycle Contract internals",
        "T176 Master Record concept",
        "T176 Binding mechanism implementation",
        "Cross-Workspace Write Gate v1 internals (existing in production)",
        "Q known-schema-version bump mechanism (Q-head doctrine)",
        "DDL changes (forbidden in this contract)",
        "n8n workflow implementation specifics (idempotency mechanism, locking, concurrency reconciliation, cleanup of orphan artifacts)",
        "Disable/re-enable authority and mechanics (§6.11 — future authorized lane and contract)",
        "Operational anomaly logging payload shape and storage (§6.10 — Q-head doctrine)",
        "Operator-side anomaly review path implementation (§6.10)",
        "Operational cleanup of orphan artifacts after partial-bundle failure (operator-side)",
        "UCC clone operation implementation (§12.1 — future feature, CWG-gated)",
        "Operational Rolling Memory semantic classification beyond the bootstrap-only classification in §15.1 (sibling RM doctrine)",
        "Audit log storage for tie-break collisions, multi-invalid candidates, hard-failure events (Q-head doctrine)",
        "Future surface mechanism for the existing-user-new-workspace clone-availability invitation (§12 — operational)"
      ]
    },
    "5_workspace_ucc_root_anchor": {
      "type": "project artifact",
      "q_may": [
        "Use this project as the parent_artifact_id target for UCC content snapshots in this workspace (per Read Contract v1 §1 parent strategy)",
        "Use this project as the parent_artifact_id target for ucc-update snapshots when Update Contract v1 lands",
        "Reference its existence as an audit artifact and structural prerequisite (its absence is a coherence violation; its presence does NOT imply enablement)"
      ],
      "title": "Workspace UCC Root Anchor",
      "lifecycle": "stays seed; never promotes",
      "q_must_not": [
        "Treat this project as an executional or operator-facing project",
        "Add branches/limbs/leaves under it (NOT a tree-anatomy parent)",
        "Promote it lifecycle stages",
        "Surface it in operator project lists, CmdCtr active surface, or rolling memory active threads",
        "Apply project lifecycle doctrine (sapling promotion criteria, design spine review, etc.)",
        "Treat its existence as a UCC enablement signal — the latest valid workspace-config snapshot is the ONLY enablement authority (§6, §7)",
        "Substitute root-anchor presence for workspace-config presence in any /wake gate-chain decision"
      ],
      "hard_caveat": "The workspace UCC root project is a non-executional structural/lifecycle anchor only. It does NOT imply branches, leaves, task execution, promotion momentum, or operator-facing project work.",
      "prime_transitional_case": "Prime's existing seed 088aa61b-a488-4d28-bdb6-e3c0e92b9abf already serves this role per Read Contract v1 §1. No new anchor needed for Prime if/when Prime is later authorized for UCC retrofit.",
      "required_fields_at_creation": {
        "tags": [
          "workspace-anchor",
          "ucc-root",
          "structural-only",
          "for-q"
        ],
        "title": "UCC Root Anchor — <workspace_label>",
        "priority": 3,
        "artifact_type": "project",
        "lifecycle_status": "seed",
        "semantic_type_id": "governance (workspace-bounding structural marker)",
        "parent_artifact_id": "<TBD-PENDING-T176> — likely a T176 workspace Master Record. If T176 design does not surface such an anchor, fallback is unparented (top-level project). Mark as <TBD-PENDING-PROVISIONING-ANCHOR> until resolved.",
        "extension_design_spine": "null (intentionally — this anchor has no design spine; it is structural)",
        "extension_lifecycle_stage": "seed"
      }
    },
    "7_wake_invocation_gate_chain": {
      "title": "/wake Invocation Gate Chain",
      "q_must_not": [
        "Invoke UCC retrieval before checking the enablement signal",
        "Surface any UCC-related prompt for non-enabled workspaces",
        "Use UCC absence as a proxy for enablement (Joel directive: UCC content is not the gate)",
        "Use root anchor presence as a proxy for enablement (Amendment 7 from Draft 2)"
      ],
      "locked_chain": [
        "1. Determine active workspace (from session context, Gateway credential resolution)",
        "2. Check UCC enablement signal: query workspace-config snapshots per §6.7; apply ordering, validation, fall-through per §6.6 / §6.8",
        "3. Branch on enablement state: a. ABSENT or DISABLED or ALL-INVALID → silently skip UCC retrieval. Proceed to next /wake step (End Session, RM, CmdCtr per Decision 6 ordering). b. ENABLED (latest valid candidate has ucc_enabled: true and bundle_validated: true) → invoke UCC Read Contract v1 retrieval.",
        "4. If UCC retrieval invoked and returns valid UCC → absorb per Read Contract v1 §12 boundary. Continue /wake.",
        "5. If UCC retrieval invoked and fails (Read Contract v1 §9 or §10 paths) → follow Read Contract v1 fail-soft behavior (Skip / Recreate / Restore prompt)."
      ],
      "non_enabled_workspace_silence": "For non-UCC-enabled workspaces, NO missing-UCC prompt appears at any point. The Read Contract v1 §9 fail-soft prompt is reachable ONLY when retrieval was invoked, which requires enablement.",
      "critical_root_anchor_exclusion": "Step 2 reads the workspace-config snapshot and the workspace-config snapshot ONLY. The workspace UCC root anchor's existence (§5) is NOT consulted in this gate chain. Even if the root anchor exists for a workspace, absent/invalid workspace-config means silent skip."
    },
    "2_provisioning_bundle_composition": {
      "rule": "All 3 MUST be created in the same provisioning workflow execution. No partial bundle is acceptable as a 'ready' state. See §10 for idempotent re-entry semantics if a workflow restarts mid-bundle.",
      "title": "Provisioning Bundle Composition",
      "bundle_members": [
        "UCC content snapshot — per UCC Read Contract v1 §1 canonical shape; populated with minimum required fields (§4)",
        "Bootstrap Rolling Memory — minimal initial RM snapshot for the workspace; shape per §15.1",
        "Bootstrap End Session — minimal initial End Session anchor; shape per §15.2"
      ]
    },
    "11_provisioning_fail_hard_behavior": {
      "title": "Provisioning Fail-Hard Behavior",
      "trigger_table": [
        {
          "action": "Reject activation; T176 receives hard failure; workspace not provisioned",
          "condition": "Any required field missing from §4 list"
        },
        {
          "action": "Reject; bundle aborted",
          "condition": "UCC content snapshot save fails"
        },
        {
          "action": "Reject; bundle aborted; no retry within this workflow execution",
          "condition": "UCC content snapshot fails Read Contract §10 valid-check"
        },
        {
          "action": "Reject; bundle aborted",
          "condition": "Bootstrap Rolling Memory save fails or invalid"
        },
        {
          "action": "Reject; bundle aborted",
          "condition": "Bootstrap End Session save fails or invalid"
        },
        {
          "action": "Reject; workspace is not marked ready and UCC is not enabled even though prior bundle artifacts may have landed (operational anomaly)",
          "condition": "Workspace-config snapshot save fails"
        },
        {
          "action": "Reject; T176 cannot mark workspace ready",
          "condition": "<TBD-PENDING-T176> signal failure"
        },
        {
          "action": "Abort with 'already provisioned' hard signal — do NOT create competing config (per §10.1)",
          "condition": "Idempotency precheck finds existing valid ucc_enabled: true workspace-config"
        },
        {
          "action": "Hard fail — operator cleanup required (per §10.2)",
          "condition": "Idempotency detection finds existing-but-invalid artifact in expected slot"
        }
      ],
      "operationalizes": "Decision 8 of Root Snapshot v2",
      "partial_state_language": "Workspace is not marked ready and UCC is not enabled. Partial artifacts may exist internally — for example, a UCC content snapshot may have been saved before Bootstrap RM failed — but those partial artifacts do NOT activate the workspace because the workspace-config enablement snapshot is not written. Cleanup of any orphan artifacts is an operator-side concern (out of scope for this contract). Subsequent re-entry of the provisioning workflow follows §10 idempotency requirements.",
      "operator_facing_failure_template": "TEMPLATE — behavior locked, copy refinable: 'Workspace provisioning failed at step <step_name>. Activation cannot complete. Reason: <reason>. Workspace is not marked ready and UCC is not enabled.'"
    },
    "12_existing_user_new_workspace_flow": {
      "title": "Existing-User-New-Workspace Flow",
      "12_2_vault_clone_constraint": {
        "rule": "Vault values MUST NOT cross workspaces under any clone flow. User MUST re-establish vault content per workspace. This applies regardless of whether the rest of UCC clone is approved.",
        "title": "Vault Clone Constraint"
      },
      "12_1_clone_operation_future_work": {
        "title": "Clone Operation (Future Work)",
        "scope_status": "Out of scope for this contract.",
        "implementation_status": "Future feature; this contract MUST NOT be cited as authority",
        "required_properties_when_later_defined": [
          "MUST be initiated outside the /wake startup sequence",
          "MUST NOT block any /wake execution",
          "MUST require Cross-Workspace Write Gate v1 approval (existing in production)",
          "MUST NOT copy vault values cross-workspace",
          "MUST support per-field selection (full clone, customize, none)",
          "MUST log the cross-workspace operation in compliance with CWG audit requirements"
        ]
      },
      "default_behavior_at_provisioning": [
        "Provisioning workflow runs identically to first-time activation (§9)",
        "Workspace receives bundle with minimum-required fields only — same 7 fields as §4",
        "No automatic clone of the user's UCC content from a source workspace",
        "No automatic propagation of vault entries, preferences, boundaries, etc.",
        "Default workspace state: start fresh"
      ],
      "non_blocking_invitation_mechanism_neutral": {
        "rule": "A future surface may inform the operator outside the blocking startup path that clone-from-source is available. The mechanism is intentionally unspecified by this contract.",
        "constraints": [
          "Any such surface MUST NOT block /wake startup",
          "Any such surface is OPTIONAL — this contract does NOT require any /wake-time surface",
          "Default behavior remains start fresh (no clone) if the operator does not act",
          "Mechanism choice (chat text, operator console banner, deferred prompt, queue entry, etc.) is a future operational decision, not specified here"
        ]
      }
    },
    "10_provisioning_workflow_idempotency": {
      "title": "Provisioning Workflow Idempotency",
      "preamble": "Contract-level requirement. Implementation mechanics remain out of scope; the contract specifies what must hold true, not how it is enforced in n8n.",
      "10_2_constraints": {
        "rules": [
          "No competing duplicates. At no point may the workflow create a second workspace UCC root anchor, a second valid UCC content snapshot in identical state, or a second valid ucc_enabled: true workspace-config in the same workspace.",
          "Detection-before-creation. Each artifact-creation stage MUST be preceded by a detection query for prior artifacts of the same type/role.",
          "Existing-but-invalid = hard fail. If detection finds an existing artifact in the expected slot but the artifact is invalid (corrupt, wrong tags, Read Contract §10 fail), the workflow hard-fails. The contract does NOT authorize the workflow to overwrite, repair, or replace invalid pre-existing artifacts. Cleanup is operator-side (out of scope).",
          "Existing-and-valid = reuse. If detection finds an existing valid artifact, the workflow proceeds to the next stage using that artifact. No new save.",
          "Atomicity preserved. Idempotent re-entry does not weaken §3 external atomicity. The workspace remains not-ready until ALL bundle members are validated AND the workspace-config snapshot is written.",
          "No soft-recovery, replacement, repair, or overwrite behavior introduced by this contract."
        ],
        "title": "Constraints"
      },
      "10_3_out_of_scope": {
        "note": "These are operational/implementation concerns. The contract requires the behavior (no competing duplicates, safe restart) without prescribing the mechanism.",
        "items": [
          "The detection query implementation in n8n (specific node configurations)",
          "Locking mechanisms to prevent concurrent provisioning workflow executions",
          "Reconciliation of workflows that race against each other",
          "Cleanup of orphan or competing artifacts found during detection",
          "Versioning of the provisioning workflow itself"
        ],
        "title": "Out of Scope"
      },
      "10_1_required_behaviors": {
        "rule": "The provisioning workflow MUST be safe to restart at any stage.",
        "title": "Required Behaviors",
        "restart_behavior_table": [
          {
            "restart_point": "After activation handshake validation, before any artifact creation",
            "required_behavior": "Proceed normally — no prior artifacts to detect"
          },
          {
            "restart_point": "After workspace UCC root anchor creation",
            "detection_filter": "artifact_type=project, tags-all ['workspace-anchor','ucc-root','structural-only','for-q'], workspace match",
            "required_behavior": "Detect existing root anchor for workspace_id; reuse if present and valid; do NOT create competing duplicate. If existing anchor is invalid, hard fail (cleanup required before retry)."
          },
          {
            "restart_point": "After UCC content snapshot creation",
            "detection_filter": "Read Contract v1 §2 retrieval filter (tags-all ['user-context-core','for-q'], workspace match, valid per Read Contract §10)",
            "required_behavior": "Detect existing UCC content; reuse if present and valid (Read Contract §10 valid-check); do NOT create competing duplicate. If existing UCC is invalid, hard fail."
          },
          {
            "restart_point": "After Bootstrap Rolling Memory creation",
            "detection_filter": "artifact_type=snapshot, tags-all ['rolling-memory','for-q','bootstrap'], workspace match",
            "required_behavior": "Detect existing Bootstrap RM with the EXACT tag set above; reuse if present and tag-valid. The 'bootstrap' tag is REQUIRED in detection — operational (non-bootstrap) Rolling Memory snapshots MUST NOT match this detection filter."
          },
          {
            "restart_point": "After Bootstrap End Session creation",
            "detection_filter": "artifact_type=snapshot, tags-all ['session-end','cc','for-q','bootstrap'], workspace match",
            "required_behavior": "Detect existing Bootstrap End Session with the EXACT tag set above; reuse if present and tag-valid. The 'bootstrap' tag is REQUIRED in detection — operational (non-bootstrap) session-end snapshots MUST NOT match this detection filter."
          },
          {
            "restart_point": "After workspace-config enablement snapshot creation",
            "detection_filter": "§6.7 retrieval (tags-all ['workspace-config','ucc-enablement','for-q'], workspace match, ucc_enabled: true)",
            "required_behavior": "Detect existing valid workspace-config with ucc_enabled: true. If found: workflow MUST abort with 'already provisioned' signal — do NOT write a competing config. The existing valid config is authoritative."
          }
        ],
        "tag_convention_explicit_note": "The 'bootstrap' tag is intentionally part of the EXACT tag set for both Bootstrap Rolling Memory and Bootstrap End Session detection filters. This prevents detection from matching later operational Rolling Memory or operational session-end snapshots, which use overlapping but different tag sets."
      }
    },
    "9_n8n_provisioning_workflow_contract": {
      "title": "n8n Provisioning Workflow Contract",
      "hard_constraint": "All provisioning work MUST be n8n + Gateway + DB. No AI runtime dependency. No LLM in the provisioning loop.",
      "failure_handling": [
        "Hard failure surfaced to T176 lane / operator (per §11)",
        "No subsequent stages execute",
        "Workspace remains not-enabled by /wake (workspace-config snapshot never written or — for stage 11 idempotency abort — the prior valid config remains authoritative)",
        "Cleanup of partially-landed artifacts: out of scope"
      ],
      "workflow_stages_logical": [
        "1. Receive activation handshake (from T176; see §8)",
        "2. Validate input — all 7 minimum fields present per §4; reject with hard failure if any missing",
        "3. Idempotency precheck (per §10) — query existing artifacts; determine which stages must run vs are already complete",
        "4. Create or detect workspace UCC root anchor (§5) — single Gateway artifact.save for the project seed if not already present",
        "5. Create or detect UCC content snapshot — Gateway artifact.save if not already present, parent = workspace UCC root anchor, payload per Read Contract v1 §1",
        "6. Validate UCC — query just-created (or pre-existing) UCC; apply Read Contract v1 §10 valid-check; if invalid, hard failure",
        "7. Create or detect Bootstrap Rolling Memory snapshot (§15.1)",
        "8. Validate Bootstrap RM — basic existence + tag check",
        "9. Create or detect Bootstrap End Session snapshot (§15.2)",
        "10. Validate Bootstrap End Session — basic existence + tag check",
        "11. Create workspace-config snapshot (§6) — ucc_enabled: true, bundle_validated: true, populate provisioning_bundle_initial. Idempotency rule per §10: if a valid ucc_enabled: true workspace-config already exists, abort with 'already provisioned' hard signal rather than creating a competing config.",
        "12. Signal T176 readiness — <TBD-PENDING-T176> mechanism"
      ]
    },
    "17_conformance_to_joel_six_item_boundary": {
      "title": "Conformance to Joel's 6-Item Boundary",
      "mapping": [
        {
          "section": "§6 (entire section)",
          "boundary_item": "1. Define ucc_enabled workspace-level enablement"
        },
        {
          "section": "§1 scope; §13 explicit",
          "boundary_item": "2. Beta/new-user provisioning is first implementation target"
        },
        {
          "section": "§13 explicit no-retrofit list",
          "boundary_item": "3. Prime, Q@W, current Akara not retrofit targets"
        },
        {
          "section": "§7 gate chain step 3b; §6.5 / §6.8 explicit silent-skip",
          "boundary_item": "4. /wake invokes UCC retrieval only when workspace is UCC-enabled"
        },
        {
          "section": "§6.5, §6.8, §7 step 3a",
          "boundary_item": "5. Non-UCC-enabled workspaces silently skip; no missing-UCC prompt"
        },
        {
          "section": "§7 step 4–5 explicit handoff",
          "boundary_item": "6. Once invoked, Read Contract v1 governs"
        }
      ],
      "all_six_addressed": true
    },
    "14_cross_workspace_write_gate_implications": {
      "title": "Cross-Workspace Write Gate Implications",
      "preamble": "Cross-Workspace Write Gate (CWG) v1 is in production per CLAUDE.md / SI doctrine. This contract does NOT introduce or modify CWG behavior.",
      "this_contract_does_not": [
        "Authorize new CWG patterns",
        "Modify CWG enforcement",
        "Bypass CWG for any provisioning step (provisioning is single-workspace by design — workspace_id is fixed at activation)"
      ],
      "cwg_implicated_operations": [
        "Existing-user-new-workspace UCC clone (§12.1, future work) — REQUIRES CWG consent",
        "Future UCC migration / retrofit (§13) — REQUIRES CWG consent (and separate approval)",
        "Future UCC import-from-export operations — out of scope here, but flagged as CWG-bound"
      ]
    },
    "8_t176_activation_code_lifecycle_handshake": {
      "title": "T176 Activation Code Lifecycle Handshake",
      "blocking_status": "These markers BLOCK final contract lock, implementation work, provisioning workflow build, and runtime changes until T176 is resolved.",
      "known_interface_points": [
        "1. T176 Activation Code Lifecycle delivers user identity fields to provisioning workflow: display_name, preferred_name, timezone, email, consent_to_load_at_wake. <TBD-PENDING-T176>: exact delivery channel.",
        "2. T176 may surface a workspace structural anchor (Master Record or equivalent). Provisioning MAY parent the workspace UCC root anchor (§5) to it. <TBD-PENDING-PROVISIONING-ANCHOR>: artifact_id or pattern of the T176 anchor.",
        "3. T176 readiness signal: workspace marked ready=true in T176 lifecycle state. <TBD-PENDING-T176>: exact mechanism. This contract's §3 atomicity rule REQUIRES the bundle to land before T176 can mark ready.",
        "4. T176 binding mechanism (Activation Code form): fully T176-owned, not referenced here beyond the identity fields it delivers."
      ],
      "tbd_pending_t176_status": "This entire section is provisional pending T176 Activation Code Lifecycle Contract lock."
    },
    "3_provisioning_order_and_external_atomicity": {
      "title": "Provisioning Order and External Atomicity",
      "order_rule": "Reverse order or interleaving is FORBIDDEN. Each step references identity established in the prior step; reverse breaks audit trail and bundle coherence.",
      "bundle_failure_behavior": "If any of the 3 bundle artifacts fails to land or validate: the workspace is not marked ready and UCC is not enabled. The provisioning workflow MUST surface a hard failure. Partial artifacts may exist internally; those artifacts do NOT activate the workspace because the workspace-config enablement snapshot is not written (§6.9). Already-landed artifacts MUST NOT be auto-cleaned by this contract; cleanup is a separate operational concern (out of scope). Re-entry of the provisioning workflow is governed by §10 idempotency requirements; competing duplicates MUST NOT be created.",
      "external_atomicity_rule": [
        "Workspace MUST NOT be marked ready=true (T176 lifecycle state) unless ALL 3 bundle artifacts have landed and validated.",
        "Validated means: (a) Gateway returned save success; (b) artifact retrievable via Gateway list; (c) for UCC, passes Read Contract v1 §10 valid-check.",
        "Internal n8n workflow step ordering may run non-atomically (each step is its own Gateway save); the visibility of bundle completeness is binary external to the workflow."
      ],
      "order_locked_per_decision_6": [
        "1. UCC content snapshot",
        "2. Bootstrap Rolling Memory",
        "3. Bootstrap End Session"
      ]
    },
    "4_minimum_required_ucc_fields_at_provisioning": {
      "rule": "All 7 MUST be present in the UCC content snapshot at provisioning. If any required field is missing from the activation handshake input, provisioning fails per §3 + §11 (hard failure, no partial bundle activation).",
      "title": "Minimum Required UCC Fields at Provisioning",
      "fields": [
        {
          "field": "display_name",
          "source": "Activation Code Lifecycle (T176)",
          "purpose": "UI/identity"
        },
        {
          "field": "preferred_name",
          "source": "Activation Code Lifecycle (T176)",
          "purpose": "Service preference"
        },
        {
          "field": "timezone",
          "source": "Activation Code Lifecycle (T176)",
          "purpose": "Scheduling/temporal context"
        },
        {
          "field": "email",
          "source": "Activation Code Lifecycle (T176)",
          "purpose": "Identity routing"
        },
        {
          "field": "user_id",
          "source": "qxb_user.user_id (existing)",
          "purpose": "Internal mapping"
        },
        {
          "field": "workspace_id",
          "source": "Provisioning workflow context",
          "purpose": "Workspace-local identity"
        },
        {
          "field": "consent_to_load_at_wake",
          "source": "Activation Code Lifecycle (T176)",
          "purpose": "Default /wake UCC load behavior"
        }
      ],
      "tbd_pending_t176": "The exact channel by which Activation Code Lifecycle delivers display_name, preferred_name, timezone, email, consent_to_load_at_wake to the provisioning workflow. Lock when T176 Activation Code Lifecycle Contract is locked."
    },
    "6_ucc_enablement_signal_workspace_config_snapshot": {
      "title": "UCC Enablement Signal (Workspace-Config Snapshot)",
      "preamble": "This snapshot is the sole enablement authority for /wake UCC invocation. No other artifact (including the workspace UCC root anchor) substitutes.",
      "6_2_required_tags": {
        "rule": "All three tags MUST be present.",
        "tags": [
          {
            "tag": "workspace-config",
            "role": "REQUIRED — config-domain scope"
          },
          {
            "tag": "ucc-enablement",
            "role": "REQUIRED — config-type scope, distinguishes from future workspace-config types"
          },
          {
            "tag": "for-q",
            "role": "REQUIRED startup-scope tag"
          }
        ],
        "title": "Required Tags"
      },
      "6_1_snapshot_shape": {
        "title": "Snapshot Shape",
        "fields": {
          "tags": [
            "workspace-config",
            "ucc-enablement",
            "for-q"
          ],
          "priority": 3,
          "artifact_type": "snapshot",
          "title_pattern": "Workspace Config — UCC Enablement — <workspace_label> — <YYYY-MM-DD>",
          "semantic_type_id": "governance (string key; Gateway resolves per registry)",
          "parent_artifact_id": "Workspace UCC root anchor (§5)"
        },
        "extension_payload_shape": {
          "enabled_at": "<ISO datetime>",
          "config_type": "ucc_enablement",
          "ucc_enabled": true,
          "workspace_id": "<UUID>",
          "schema_version": "v1",
          "bundle_validated": true,
          "prior_config_snapshot_id": "<artifact_id of superseded config snapshot, or null>",
          "provisioning_bundle_initial": {
            "captured_at": "<ISO datetime>",
            "ucc_content": "<artifact_id>",
            "bootstrap_end_session": "<artifact_id>",
            "bundle_reference_type": "initial_activation_audit",
            "bootstrap_rolling_memory": "<artifact_id>"
          }
        },
        "provisioning_bundle_initial_semantics": [
          "Captures the initial validated bundle artifact_ids at activation time only",
          "Used for audit trail: 'this workspace was activated with these specific bundle members'",
          "MUST NOT be interpreted as the current live UCC / RM / End Session state",
          "MUST NOT be auto-updated when UCC, Rolling Memory, or End Session subsequently revise (each of those evolves under its own contract)",
          "Stale-reference protection: consumers reading this field MUST NOT use it for live state lookup; use the appropriate latest-wins retrieval per the relevant contract",
          "bundle_reference_type field is a machine-readable marker confirming audit-only semantics; long explanatory prose lives in this contract document, not the payload"
        ]
      },
      "6_3_tags_all_semantics": {
        "rules": [
          "Same convention as Read Contract v1 §2",
          "Gateway selector.filters.tags_any: ['workspace-config', 'ucc-enablement'] MUST behave as set-containment / tags-all",
          "Q MUST post-validate that the returned artifact's tags include both workspace-config AND ucc-enablement before honoring as enablement signal",
          "Authoritative reference: SQL with chained ? JSONB key-existence operators"
        ],
        "title": "Tags-All Semantics"
      },
      "6_7_canonical_retrieval_filter": {
        "sql": "SELECT a.*, s.payload FROM qxb_artifact a JOIN qxb_artifact_snapshot s ON s.artifact_id = a.artifact_id WHERE a.artifact_type = 'snapshot' AND a.workspace_id = $WORKSPACE_ID AND a.deleted_at IS NULL AND a.tags ? 'workspace-config' AND a.tags ? 'ucc-enablement' ORDER BY a.created_at DESC, a.version DESC, a.artifact_id DESC LIMIT 5;",
        "title": "Canonical Retrieval Filter",
        "gateway_equivalent": "artifact.list with artifact_type=snapshot, selector.filters.tags_any=['workspace-config','ucc-enablement'], limit=5, hydrate=true."
      },
      "6_11_disable_re_enable_authority": {
        "title": "Disable / Re-Enable Authority",
        "current_state": "These items remain open and require future authorized lane and contract before any disable/re-enable flow is implemented. As of save-ready: provisioning is the only authorized writer of workspace-config snapshots, and provisioning only writes ucc_enabled: true.",
        "allowed_by_this_contract": [
          "Define how /wake reads the latest valid workspace-config snapshot if it exists",
          "Define the format of a workspace-config snapshot with ucc_enabled: false (interpretable by /wake as silent-skip behavior, identical to absent)",
          "Note that prior_config_snapshot_id chains revisions for audit purposes"
        ],
        "forbidden_by_this_contract": [
          "Q MUST NOT write disable snapshots during runtime",
          "Q MUST NOT write re-enable snapshots during runtime",
          "This contract MUST NOT be cited as authority for any user-triggered disable/re-enable flow"
        ],
        "future_work_not_defined_here": [
          "Authority model for who/what can author disable snapshots",
          "UI/mechanism for re-enable",
          "Authorization for external actors to write workspace-config snapshots",
          "Crisis revocation procedures",
          "Whether disable snapshots are reversible or terminal",
          "Whether the explicit ucc_enabled: false state surfaces operator-facing acknowledgment vs silent persistence"
        ]
      },
      "6_10_internal_anomaly_classification": {
        "title": "Internal Anomaly Classification",
        "purpose": "Distinguish silent user-facing behavior (§6.5, §6.8) from internal operational signals worth attention.",
        "classification_table": [
          {
            "internal": "NOT anomalous (expected for non-enabled workspaces)",
            "condition": "Absent config (zero results in retrieval)",
            "user_facing": "Silent skip"
          },
          {
            "internal": "Low-severity anomaly. Recommend Q-side telemetry capture; review at next operator session start",
            "condition": "Single invalid candidate, fall-through finds valid",
            "user_facing": "Silent skip → invocation"
          },
          {
            "internal": "Medium-severity anomaly. Recommend operator review path",
            "condition": "Single invalid candidate, fall-through finds no valid (zero remaining)",
            "user_facing": "Silent skip"
          },
          {
            "internal": "Operational anomaly. REQUIRE operator review. Workspace MAY have governance corruption, schema drift, or upstream save violation.",
            "condition": "All 5 candidates invalid",
            "user_facing": "Silent skip"
          },
          {
            "internal": "NOT anomalous (per §6.11 — disable is a defined state); operator audit MAY still note 'workspace was UCC-enabled, now disabled, last updated <timestamp>'",
            "condition": "Workspace-config retrievable but ucc_enabled: false (explicit disable)",
            "user_facing": "Silent skip"
          },
          {
            "internal": "Low-severity anomaly per Read Contract v1 §5 pattern",
            "condition": "Tie-break collision reaching artifact_id DESC",
            "user_facing": "(no user impact — internal candidate selection)"
          }
        ],
        "no_auto_remediation_rules": [
          "Q MUST NOT auto-remediate these anomalies",
          "Q MUST NOT silently rewrite or 'fix' invalid config snapshots"
        ],
        "no_implementation_payload_defined": "This contract specifies classification policy; the storage/surfacing mechanism is Q-head doctrine (separate lane) and operator-side anomaly logging (deferred).",
        "all_5_invalid_recommended_review_path": [
          "Operator notified at next session start (mechanism TBD, out of scope)",
          "Operator inspects the 5 invalid candidates via Gateway query",
          "Determines root cause (corruption, schema drift, save-side violation)",
          "Either: writes a corrected workspace-config snapshot OR investigates upstream cause"
        ]
      },
      "6_9_when_enablement_signal_becomes_active": {
        "title": "When the Enablement Signal Becomes Active",
        "preconditions": [
          "1. UCC content snapshot landed and Read Contract v1 §10 valid-check passes",
          "2. Bootstrap Rolling Memory snapshot landed and validated (§15.1)",
          "3. Bootstrap End Session snapshot landed and validated (§15.2)",
          "4. Only then does the provisioning workflow write the workspace-config snapshot with ucc_enabled: true and bundle_validated: true"
        ],
        "audit_field_rule": "provisioning_bundle_initial.ucc_content / .bootstrap_rolling_memory / .bootstrap_end_session fields MUST reference the actual artifact_ids of the 3 bundle members at activation. Per §6.1 semantics, these are audit links only — not live-state pointers.",
        "ordering_enforcement": "Order is enforced by the n8n provisioning workflow (§9). The workspace-config snapshot is the LAST step of provisioning. If any earlier step fails, this final snapshot is never written, and the workspace is correctly seen as not-enabled by /wake (§6.5).",
        "critical_readiness_rule": "The workspace-config snapshot establishing ucc_enabled: true MUST NOT be written until the provisioning bundle has landed and validated."
      },
      "6_5_user_facing_behavior_for_absent_config": {
        "title": "User-Facing Behavior for Absent Config",
        "behavior": [
          "Q queries via §6.7 retrieval filter; result set is empty",
          "Q MUST silently skip UCC retrieval (per §7 gate chain step 3a)",
          "Q MUST NOT surface the missing-UCC fail-soft prompt from Read Contract v1 §9 (absent config = workspace not enabled, not 'UCC missing within an enabled workspace')",
          "No user-facing prompt of any kind appears for this case"
        ],
        "internal_classification": "NOT anomalous — absent config is the expected state for non-UCC-enabled workspaces (Prime, Q@W, current Qwrk_Akara). See §6.10 for cases that ARE classified as internal anomalies."
      },
      "6_6_behavior_for_multiple_config_candidates": {
        "title": "Behavior for Multiple Config Candidates",
        "pattern": "Same bounded-scan pattern as Read Contract v1 §2 — LIMIT 5 candidate window.",
        "outcomes": [
          "ucc_enabled: true in latest valid candidate → workspace enabled",
          "ucc_enabled: false in latest valid candidate → workspace explicitly disabled (different from absent — see §6.11)",
          "All 5 candidates invalid → user-facing: treat as absent per §6.5 (silent skip, no prompt). Internal: classify as anomaly per §6.10."
        ],
        "ordering_locked": [
          {
            "rule": "created_at DESC",
            "step": 1
          },
          {
            "rule": "version DESC",
            "step": 2
          },
          {
            "rule": "artifact_id DESC (abnormal collision indicator; same handling as Read Contract §5)",
            "step": 3
          }
        ],
        "candidate_processing": "Q processes the candidate window in order, honoring the first valid candidate (per §6.8). If the first candidate is invalid, the second is evaluated, etc."
      },
      "6_4_semantic_classification_and_registry_resolution": {
        "title": "Semantic Classification / Registry Resolution",
        "rationale": "This signal is a structural enablement gate (locks /wake behavior); it is governance-classified in the same sense as the Read Contract artifact itself.",
        "classification": "governance",
        "registry_resolution": "Gateway resolves the string key 'governance' to the registry UUID 02d3ff65-c86b-4c00-af32-209cb21134eb internally. Verify against live qxb_semantic_type_registry at payload-prep time."
      },
      "6_8_user_facing_behavior_for_corrupt_invalid_config": {
        "title": "User-Facing Behavior for Corrupt/Invalid Config",
        "invalid_conditions": [
          "extension.payload missing",
          "config_type missing or not 'ucc_enablement'",
          "schema_version missing or invalid format (per Read Contract v1 §7 numeric-comparison rules)",
          "ucc_enabled missing or non-boolean",
          "workspace_id mismatches active session workspace (defense-in-depth)",
          "bundle_validated field missing or not true (fresh/un-validated config MUST NOT be honored)",
          "JSON parse error",
          "Tags fail post-validation (per §6.3)"
        ],
        "no_auto_remediation": [
          "Q MUST NOT auto-remediate invalid config snapshots",
          "Q MUST NOT auto-rewrite invalid config snapshots",
          "Q MUST NOT silently repair invalid config snapshots"
        ],
        "all_5_invalid_behavior": "User-facing treat as absent per §6.5; internally classify as anomaly per §6.10.",
        "internal_classification": "See §6.10.",
        "user_facing_behavior_on_invalid_candidate": "Treat as absent (silently skip UCC retrieval). Do NOT surface a fail-soft prompt."
      }
    },
    "13_beta_first_rollout_boundary_no_retrofit_doctrine": {
      "title": "Beta-First Rollout Boundary / No-Retrofit Doctrine",
      "rationale": "These workspaces operate inside dedicated ChatGPT Project contexts that already provide strong operator/context identity. UCC is not needed there immediately and MUST NOT trigger retrofitting work.",
      "retrofit_policy": [
        "Any future UCC bootstrap of a no-retrofit workspace requires separate Joel approval in a dedicated lane",
        "A retrofit lane MUST: produce a retrofit-specific provisioning subset, justify the migration, address any in-flight ChatGPT Project context conflicts",
        "This contract MUST NOT be invoked as authority for retrofit"
      ],
      "first_implementation_target": [
        "Beta / new-user provisioning",
        "Single Custom GPT pattern",
        "User-identifiable Qx/QSB Chrome extension profile",
        "Gateway-bound workspace identity",
        "Deterministic /wake startup identity"
      ],
      "platform_general_design_note": "The contract itself remains platform-general. The rollout boundary is operational sequencing, not architectural restriction.",
      "no_retrofit_list_as_of_2026_05_06": [
        "Qwrk Personal / Prime",
        "Qwrk Resolve / Q@W",
        "Current Qwrk_Akara"
      ]
    },
    "15_bootstrap_rolling_memory_and_bootstrap_end_session": {
      "title": "Bootstrap Rolling Memory + Bootstrap End Session — Inline Minimal Definitions",
      "15_3_future_expansion": "If Bootstrap RM or Bootstrap End Session shapes need to evolve substantively, sibling contracts may be drafted. As of save-ready: scope is contained inline.",
      "15_2_bootstrap_end_session": {
        "title": "Bootstrap End Session",
        "fields": {
          "tags": [
            "session-end",
            "cc",
            "for-q",
            "bootstrap"
          ],
          "artifact_type": "snapshot",
          "title_pattern": "CC Session End — Bootstrap — <workspace_label> — <YYYY-MM-DD>",
          "semantic_type_id": "governance",
          "parent_artifact_id": "Workspace UCC root anchor (§5) — transitional"
        },
        "claude_md_alignment": "This shape conforms to the CLAUDE.md v32 Session End Snapshot Contract; the bootstrap variant satisfies that contract's locked schema with provisioning-appropriate placeholders.",
        "extension_payload_minimal_shape": {
          "context": "Workspace provisioning bootstrap. No prior session.",
          "decisions": "Workspace activated under Provisioning Integration Contract v1.",
          "timestamp": "<ISO datetime>",
          "open_loops": "None at provisioning.",
          "session_id": "bootstrap-<YYYY-MM-DDTHH:MM>",
          "key_outputs": "Workspace UCC bundle created.",
          "next_session_entry": "First operator session resumes from Rolling Memory bootstrap state."
        },
        "tag_convention_consistency_note": "The 4-tag set ['session-end','cc','for-q','bootstrap'] is the authoritative Bootstrap End Session tag convention referenced throughout this contract: §10.1 detection filter, §11 validation, §15.2 definition. The 'bootstrap' tag is REQUIRED — distinguishes from operational session-end snapshots (which use the same first three tags but lack 'bootstrap')."
      },
      "15_1_bootstrap_rolling_memory": {
        "title": "Bootstrap Rolling Memory",
        "fields": {
          "tags": [
            "rolling-memory",
            "for-q",
            "bootstrap"
          ],
          "artifact_type": "snapshot",
          "title_pattern": "Rolling Memory — Bootstrap — <workspace_label> — <YYYY-MM-DD>",
          "semantic_type_id": "governance (justified per below — bootstrap-only)",
          "parent_artifact_id": "Workspace UCC root anchor (§5) — transitional; future RM doctrine may define dedicated workspace RM anchor"
        },
        "empty_arrays_intentional": "Bootstrap RM has no operational content at provisioning. Q populates as the workspace is used.",
        "not_a_hidden_decision_for_rm": [
          "The semantic classification of operational (post-bootstrap) Rolling Memory snapshots is NOT decided by this contract",
          "Future sibling RM doctrine (Rolling Memory Contract v1 or equivalent) MUST decide operational RM semantic classification independently",
          "This contract sets precedent ONLY for the bootstrap snapshot; consumers MUST NOT infer that all RM snapshots are governance-classified",
          "If a sibling RM doctrine subsequently rejects governance for operational RM, the bootstrap classification in this contract may be revisited at that time"
        ],
        "extension_payload_minimal_shape": {
          "generated_at": "<ISO datetime>",
          "workspace_id": "<UUID>",
          "active_threads": [],
          "rotating_shell": [],
          "schema_version": "v1",
          "active_contexts": [],
          "bootstrap_notes": "Bootstrap Rolling Memory created at workspace provisioning. No initial active threads or contexts. Q populates on first user-confirmed update.",
          "tier_a_protected_core": []
        },
        "semantic_classification_justification": "The Bootstrap Rolling Memory snapshot is classified governance specifically because it is a contract-defined provisioning artifact, not because Rolling Memory is generally governance-classified. This is a bootstrap-only classification and does NOT determine the classification of subsequent operational Rolling Memory snapshots."
      }
    }
  },
  "contract_name": "UCC Provisioning Integration Contract v1",
  "snapshot_type": "design_contract",
  "review_history": {
    "draft_1": "Initial CC draft 2026-05-06 with Q1+Q2 resolutions and Joel's 6-item boundary",
    "draft_2": "Team Qwrk amendments incorporated (8 amendments)",
    "save_ready": "Final cleanup applied per Manus+Q review (7 items)",
    "planning_scope": "CC planning document 2026-05-06 — defined contract scope, surfaced Q1–Q7"
  },
  "contract_version": "v1",
  "governance_hooks": [
    "CLAUDE.md §1 Binding Truth Hierarchy",
    "CLAUDE.md §2 No-Guessing (resolved decisions locked before save-ready)",
    "CLAUDE.md §2.5 Database Read-Only (CC produces contracts; Joel/Q execute)",
    "CLAUDE.md §3 Pattern C Archive-based versioning (future contract revisions)",
    "CLAUDE.md §4 Pre-Write Confirmation Gate (this payload is review-pending)",
    "CLAUDE.md §10 Parallel Mutation Guardrail (UCC schema is structural surface)",
    "CLAUDE.md §11 Planning Gate (sapling promotion requires this contract locked + T176 resolved)"
  ],
  "document_conventions": {
    "tbd_pending_t176": "Interface fields blocked on T176 Activation Code Lifecycle Contract. These markers BLOCK final contract lock, implementation work, provisioning workflow build, and runtime changes until T176 is resolved.",
    "user_facing_copy": "Example user-facing prompts marked TEMPLATE are illustrative. Behavior is locked; exact copy may be refined by Q before runtime use without contract amendment, provided behavior is preserved. Sections affected: §11.",
    "placeholder_marker": "<…> indicates a value filled at usage time",
    "rfc_strength_keywords": "MUST, MUST NOT, SHOULD used in RFC sense",
    "tbd_pending_provisioning_anchor": "Interface fields blocked on resolution of T176 workspace structural anchor / Master Record (if T176 design surfaces such an anchor)."
  },
  "alignment_with_read_contract_v1": {
    "parent_strategy": "§5 follows Read Contract v1 §1 parent strategy (workspace UCC root anchor; Prime transitional via seed 088aa61b)",
    "tags_all_semantics": "§6.3 mirrors Read Contract v1 §2 tags-all convention",
    "tie_break_ordering": "§6.6 mirrors Read Contract v1 §5 ordering",
    "bounded_scan_pattern": "§6.6 mirrors Read Contract v1 §2 LIMIT 5 pattern",
    "schema_version_format": "§6.8 invalid-condition list references Read Contract v1 §7 numeric-comparison rules",
    "valid_check_definition": "§3 + §10 + §11 reuse Read Contract v1 §10 valid-check definition"
  },
  "alignment_with_root_snapshot_v2": {
    "decision_6_provisioning_order": "Honored — §3 locked order",
    "decision_9_influence_boundary": "Honored — UCC content cannot shape governance per Read Contract v1; this contract treats UCC as descriptive context being created, not governance authority",
    "most_important_design_sentence": "Honored throughout — UCC is descriptive context for safe personalization and continuity. It is not governance, not memory, not security state, and not authority over live user instruction.",
    "decision_1_artifact_type_for_mvp": "Honored — UCC content is snapshot with record_type user_context_core (Read Contract v1 governs); no DDL introduced",
    "decision_8_provisioning_fail_hard": "Honored — §11 trigger table; §3 atomicity rule",
    "decision_5_workspace_local_default": "Honored — §5, §6, §12, §13 explicit"
  },
  "resolved_decisions_carried_forward": {
    "Q6_t176_dependency_strategy": "Draft-with-markers; locked sections of save-ready contract are usable independently; T176-dependent sections explicitly marked as final-lock blockers.",
    "Q2_workspace_ucc_root_anchor": "Project seed. Non-executional structural/lifecycle anchor only. NOT an enablement signal.",
    "Q5_ucc_presence_verification": "Read Contract v1 §10 valid-check applies (corrupt UCC = no UCC) — §11 of this contract.",
    "Q1_ucc_enablement_signal_mechanism": "Workspace-config snapshot. Not DDL column. Not implicit. Not UCC-content-as-gate.",
    "Q3_bootstrap_rm_end_session_shapes": "Inline minimal definitions in §15; full shapes deferred to sibling contracts only if scope grows.",
    "Q4_existing_user_new_workspace_clone": "Workspace-local default (D5); future surface may inform operator outside the blocking startup path; actual clone is future work, CWG-gated, never blocks startup.",
    "Q7_consent_to_load_at_wake_revocability": "Revocable via Update Contract v1 path; vault remains separately consent-gated. Out of scope here."
  }
}
```

---

## 10. EXTERNAL DEPENDENCY — T199/UCC — UCC Privacy Contract v1 — Draft 3

- **artifact_id:** `ff95bc0c-3803-4708-89a2-e5e30372f172`
- **artifact_type:** `snapshot`
- **title:** Draft Snapshot — UCC Privacy Contract v1 Draft 3 (Near Save-Ready, 5 Gates)
- **workspace_id:** `be0d3a48-c764-44f9-90c8-e846d9dbbd0a`
- **parent_artifact_id:** `088aa61b-a488-4d28-bdb6-e3c0e92b9abf`
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **lifecycle_status:** _(none)_
- **tags:** for-q, ucc-contract, privacy, draft, user-context
- **created_at:** 2026-05-06 22:36:33.961226+00
- **updated_at:** 2026-05-06 22:36:33.961226+00

**Hydrated extension.payload:**

```json
{
  "concept": "User Context Core / Startup Identity Layer — Privacy Boundary",
  "lineage": {
    "seed": "088aa61b-a488-4d28-bdb6-e3c0e92b9abf",
    "root_snapshot_v1": "c1352de4-ca93-48ff-8c49-a34e20a75d6d",
    "ucc_read_contract_v1": "saved 2026-05-06; artifact_id not captured this session; recoverable via Gateway list with tags-all [ucc-contract, read, user-context]",
    "root_snapshot_v2_synthesis": "2f96f79e-ca16-4ff1-8fa3-f0fcce0d1ed0",
    "t176_beta_active_launch_sapling": "4cac82b5-c9ff-40a6-9e5e-9778fc249ebf",
    "ucc_provisioning_integration_contract_v1": "cf74279e-5d02-4ee8-85c8-aa9826e1bea9"
  },
  "posture": "proposed doctrine lock / implementation blocked pending Joel/Q approval",
  "glossary": {
    "tier": "Either core or vault",
    "ucc_core": "Tier loaded at every /wake. Structural identity and core descriptive context.",
    "ucc_vault": "Tier requiring explicit session-specific consent. Stored in separate artifact with owner-only access. Physically absent from default /wake payload.",
    "discovery_hint": "A tag or marker that helps locate vault content. NOT a privacy boundary; tags alone are not enforcement.",
    "sensitivity_class": "One of 4: public-to-q, private-sensitive, do-not-surface, consent-required",
    "vault_storage_type": "The artifact_type used to physically persist vault content. Path-dependent per §13 RLS feasibility.",
    "owner_only_readable": "Only the user_id matching the vault artifact's user_id may read. Workspace members other than owner MUST NOT see vault values OR vault metadata revealing vault presence/category (per §13 expanded scope).",
    "pre_consent_discovery": "Operations to determine vault eligibility/category for consent prompt purposes only. MUST NOT return values, fine-grained field names, specific topics, or summaries.",
    "post_consent_retrieval": "Operations to load approved category or field scope into the active session AFTER user has consented.",
    "inference_vs_persistence": "Q-temporary inference (allowed in-session) vs UCC-stored content (requires explicit user confirmation)",
    "neutral_structural_label": "Field path naming a broad life domain or behavioral category, not specific condition/event/identity",
    "vault_artifact_semantics": "Immutable full-state per update + deterministic latest-valid retrieval (Decision 4.4). Does NOT prescribe artifact_type — see §6 for storage paths."
  },
  "sections": {
    "12_audit_policy": {
      "12_1_locked_constraints": [
        "Audit MAY occur only under future Audit Contract — Privacy v1 does NOT authorize",
        "MUST NOT log vault values under any circumstance",
        "MUST NOT log field names that leak (per §10)",
        "MUST be owner-only readable by default",
        "Operator/admin exceptions require future explicit governance"
      ],
      "12_2_implementation_status": "No audit implementation authorized by Privacy v1. Future Audit Contract will define mechanism within constraints above."
    },
    "8_consent_contract": {
      "8_5_consent_record": "Q-side ephemeral state. Consent grants NOT logged to UCC. Q tracks granted consents within active session only.",
      "8_4_consent_revocation": "Per §14 revocation semantics",
      "8_2_consent_persistence": "Session-ephemeral only. Each new /wake re-prompts. Consent does NOT persist across sessions.",
      "8_3_consent_prompt_template": {
        "marking": "TEMPLATE — behavior locked, copy refinable",
        "wording": "'Q would like to reference your <category_label> for this session. Options: Yes / No. Default: No.'",
        "constraints": [
          "<category_label> is coarse domain name, never specific field path or value",
          "Default always No if user does not explicitly grant",
          "Q MUST wait for response before referencing vault content",
          "Q MUST NOT proceed with vault content if user chooses No"
        ],
        "customize_option_status": "ILLUSTRATIVE only; NOT implemented in v1. Locked prompt template offers Yes/No only. Future contract may authorize per-field consent UI."
      },
      "8_1_scope_and_category_source": {
        "scope": "Per-category default. Q prompts at the level of category entries.",
        "fallback_path_if_rejected": "Privacy Contract v1 fallback: hardcoded coarse list ['health', 'finances', 'relationships', 'family', 'values']. Q prompts use these as <category_label> per §8.3.",
        "decision_required_before_save": "Joel/Q chooses primary or fallback based on Gate 2",
        "primary_path_if_sensitive_categories_approved": "boundaries.sensitive_categories (DRAFT CANDIDATE per §4.4) is the v1 consent category source"
      }
    },
    "1_purpose_and_scope": {
      "purpose": "Define the privacy boundary for User Context Core: tier architecture, sensitivity class semantics, vault artifact semantics, consent contract (incl. pre-consent vs post-consent boundary), forbidden-storage list, field-name leakage prevention, audit constraints, revocation semantics, constraints on other UCC contracts.",
      "scope_in": [
        "Tier boundary architecture",
        "Sensitivity class taxonomy + per-section field classification",
        "Vault artifact semantics (storage path-dependent per §13)",
        "Pre-consent discovery vs post-consent retrieval boundary (§7)",
        "Consent contract",
        "Inference-vs-persistence boundary",
        "Field-name and metadata leakage prevention",
        "Forbidden-storage categories (absolute for v1)",
        "Audit anti-leak constraints (mechanism deferred)",
        "Vault metadata at /wake (boolean-only)",
        "Owner-only RLS invariant (with feasibility blocker)",
        "Constraints on Update Contract v1",
        "Reaffirmations / cross-references to Read + Provisioning contracts"
      ],
      "scope_out": [
        "Vault retrieval flow implementation",
        "Consent UI implementation incl. Customize",
        "Audit log mechanism (deferred to future Audit Contract)",
        "Update Contract v1 mechanics",
        "DDL changes (forbidden)",
        "Cross-workspace clone implementation",
        "T176 Activation Code Lifecycle internals",
        "Vault implementation work — blocked by both TBD markers",
        "Workspace-purpose forbidden-category exceptions",
        "Sapling promotion"
      ]
    },
    "19_open_items_deferred": [
      "UCC content payload shape (Read Contract v1 saved)",
      "UCC update emission shape (Update Contract v1 future)",
      "Bootstrap UCC creation (Provisioning Contract v1 saved)",
      "Restore / Delete / Privacy-Export — future contract",
      "Audit log mechanism (future Audit Contract)",
      "Vault retrieval flow implementation (blocked)",
      "Consent UI implementation incl. Customize",
      "Per-field consent UI mechanics",
      "T176 Activation Code Lifecycle Contract internals",
      "DDL changes (forbidden)",
      "Cross-Workspace Write Gate v1 internals (existing)",
      "Q known-schema-version bump mechanism (Q-head doctrine)",
      "GDPR qxb_user_data_export RPC implementation",
      "Workspace-purpose forbidden-category exception governance (separate future contract)",
      "Vault revocation mechanics beyond semantics (§14)",
      "Operational anomaly logging payload shape"
    ],
    "5_forbidden_categories": {
      "categories": [
        {
          "reason": "UCC is descriptive context, not health record",
          "category": "Medical specifics",
          "examples": "Specific conditions, medications, treatment plans, mental health diagnoses, lab results"
        },
        {
          "reason": "UCC is descriptive context",
          "category": "Financial details",
          "examples": "Specific account numbers, balances, debts, transactions, credit info"
        },
        {
          "reason": "Privacy of third parties",
          "category": "Relational gossip",
          "examples": "Specific conflicts, third-party relationship dynamics, gossip about non-workspace participants"
        },
        {
          "reason": "Q-inferred without confirmation — see §9",
          "category": "Psychological-state interpretations",
          "examples": "Q's inferences about mood, mental state, emotional patterns without user confirmation"
        },
        {
          "reason": "Cascading privacy violation",
          "category": "Third-party-of-third-parties",
          "examples": "Information about people-Joel-knows's other relationships, jobs, conflicts"
        },
        {
          "reason": "UCC may reference journal artifact_ids (subject to §4.7 constraint), but MUST NOT contain journal text",
          "category": "Raw journal content",
          "examples": "Full text of user journals; raw stream-of-consciousness writing"
        },
        {
          "reason": "Not durable identity",
          "category": "Temporary moods",
          "examples": "Momentary emotional states ('Joel is stressed today')"
        }
      ],
      "hard_rules": [
        "Q MUST NOT persist Q-inferred content without explicit user confirmation (§9)",
        "Q MUST NOT store content user has not affirmatively shared",
        "Q MUST NOT store content belonging to other parties without their consent",
        "Q MUST NOT use UCC as substitute for record-keeping system"
      ],
      "v1_absolute_no_exception": "For Privacy v1 and all current/non-exception workspaces (Prime, Q@W, current Akara, BlaggLife, Greg, Demo, future Beta workspaces), forbidden categories are absolutely forbidden in UCC. NO exception is authorized by Privacy v1.",
      "future_workspace_purpose_exception": "Requires separate versioned contract, explicit Joel approval in dedicated lane, per-workspace declaration of purpose, per-category override governance, audit and compliance review. Does NOT exist in v1."
    },
    "14_revocation_semantics": {
      "14_2_long_term_removal": {
        "trigger": "User wants vault field removed from operational vault state",
        "locked_semantics": [
          "Long-term removal achieved via Update Contract v1 mechanics",
          "Update Contract v1 writes new full-state vault artifact omitting removed field",
          "Latest valid vault artifact (after this write) no longer contains removed field",
          "Subsequent retrievals see only latest valid vault artifact"
        ],
        "mechanics_out_of_scope": true,
        "important_not_physical_deletion": "Long-term removal does NOT mean physical deletion of prior immutable vault versions. Prior vault artifacts remain stored as immutable history per §6.1 semantics. Bounded by owner-only and anti-leak constraints. Physical deletion of prior versions requires future Restore/Delete/Privacy-Export Contract."
      },
      "14_1_mid_session_revocation": {
        "trigger": "User revokes consent during active session after granting vault access for a category",
        "locked_semantics": [
          "Q MUST stop using vault content immediately",
          "Q MUST discard loaded vault values from session context (cache discipline per Read v1 §11)",
          "Q MUST NOT cache revoked values for future use within session",
          "No persistent state change required (consent was session-ephemeral per §8.2)",
          "Q MAY surface acknowledgment (TEMPLATE): 'Vault access for <category> revoked. I'll no longer reference it for this session.'"
        ],
        "mechanics_out_of_scope": true
      },
      "14_3_no_retroactive_propagation": "Audit history (when implemented) NOT erased by revocation. Future Audit Contract owns retention semantics."
    },
    "2_tier_boundary_architecture": {
      "tiers": {
        "core": {
          "classes": [
            "public-to-q",
            "private-sensitive"
          ],
          "loading": "Loaded at every /wake per Read Contract v1",
          "storage": "UCC content snapshot's extension.payload.core"
        },
        "vault": {
          "classes": [
            "do-not-surface",
            "consent-required"
          ],
          "loading": "NOT loaded at /wake; loaded only on explicit per-session consent (post-consent retrieval per §7)",
          "storage": "Separate vault artifact with owner-only access (storage type per §13)"
        }
      },
      "hard_rules": [
        "A field is exactly ONE tier; not split across tiers (mixed sections split into separate fields per tier)",
        "Tier is determined at write time and validated by Update Contract v1",
        "core fields visible in default /wake payload metadata and values",
        "vault VALUES NEVER in default /wake payload; vault NAMES also NOT in /wake (only boolean vault_available indicates vault exists)"
      ],
      "tags_as_discovery_hints_not_privacy_authority": "Tags ucc-vault and for-q are required discovery markers. Tags alone are NOT the privacy boundary. Privacy enforcement MUST rely on a non-bypassable classification path (per §13). If §13 Path 1 selected, filter MUST validate against non-bypassable source — never rely solely on user-editable or mutable tags."
    },
    "3_sensitivity_class_taxonomy": {
      "classes": [
        {
          "load": "Default /wake load.",
          "tier": "core",
          "class": "public-to-q",
          "behavior": "Q uses freely. May reference proactively."
        },
        {
          "load": "Default /wake load.",
          "tier": "core",
          "class": "private-sensitive",
          "behavior": "Q uses with discretion. Surfaces only in directly relevant contexts. Does NOT proactively reference unless directly material."
        },
        {
          "load": "Per-session consent prompt, opt-in.",
          "tier": "vault",
          "class": "do-not-surface",
          "behavior": "Q does NOT have loaded at default /wake. Loaded only on consent. Once loaded for the session, Q uses for the rest of session but does NOT volunteer or proactively surface."
        },
        {
          "load": "Per-use consent prompt within session.",
          "tier": "vault",
          "class": "consent-required",
          "behavior": "Q does NOT have loaded at default /wake. Highest-friction class. User must explicitly authorize use each time Q would reference."
        }
      ],
      "transition_rules": [
        "Higher privacy: free; no friction",
        "Lower privacy: explicit user confirmation required; Q MUST NOT auto-transition",
        "Q MUST NOT re-classify based on Q-side reasoning",
        "Core->vault transition: vault artifact written; field removed from next UCC core snapshot; mid-session, Q discards loaded value",
        "Vault->core transition: explicit user confirmation; Update Contract v1 owns mechanics"
      ],
      "default_when_ambiguous": "Update Contract v1 MUST default to vault / consent-required (most restrictive). Privacy-deny by default."
    },
    "13_owner_only_rls_feasibility": {
      "13_1_posture": "proposed doctrine lock / implementation blocked pending Joel/Q approval. Posture finalizes to 'doctrine locked / implementation blocked' once Joel/Q confirms appendix gates.",
      "13_5_three_paths": {
        "path_2_journal_storage": {
          "desc": "Use journal artifact type. Journal extension already has owner-only SELECT RLS today.",
          "trade_offs": [
            "Pro: Owner-only RLS verified for journal extension table",
            "Con: Spine row visibility may not be filtered by journal extension RLS — workspace members may still see spine fields incl. title and tags. Verification required.",
            "Con: Journal payload structure (entry_text vs extension.payload) requires verification"
          ],
          "open_questions": [
            "Does owner-only RLS on qxb_artifact_journal extension table also hide spine row from non-owner workspace members?",
            "Does qxb_artifact_journal support payload JSONB column, or is structured data forced into entry_text?"
          ]
        },
        "path_3_snapshot_rls_ddl": "Forbidden in this lane",
        "path_1_gateway_layer_filtering": {
          "desc": "Gateway recognizes vault classification, applies owner-only filter at request time (incl. title and tag filtering for non-owner queries). No DDL.",
          "open_question": "Does current Gateway architecture support non-bypassable owner-only filtering AND spine metadata visibility filtering?",
          "critical_constraint": "Vault privacy MUST NOT depend solely on user-editable or mutable tags. Privacy classification MUST be non-bypassable and validated by Gateway/control-plane logic."
        }
      },
      "13_2_marker_blocks": [
        "Vault implementation",
        "Runtime vault retrieval",
        "Gateway / n8n / RLS / DDL / schema work touching vault content",
        "Any claim that vault storage is implementation-ready",
        "Any final implementation authority"
      ],
      "13_3_marker_does_not_block": [
        "Privacy doctrine drafting (this contract)",
        "Tier classification doctrine (§3, §4)",
        "Consent semantics (§8)",
        "Field-name leakage rules (§10)",
        "Forbidden category rules (§5)",
        "Constraints on Update Contract v1 (§15)",
        "Constraints on Read / Provisioning contracts (§16, §17)"
      ],
      "13_4_privacy_invariant_locked": "Vault values MUST be readable only by the owner. Workspace members other than owner MUST NOT see vault content, even in shared workspaces. Scope expanded per amendment 6: also covers vault artifact titles, ucc-vault tags, metadata revealing vault presence, leaky structural labels in spine fields. Tags/titles NOT safe simply because payload values are protected.",
      "13_6_required_before_implementation": "Joel/Q MUST verify Path 1 or Path 2 is available BEFORE any vault implementation. Privacy Contract v1 does NOT require verification before save.",
      "13_7_implementable_today_as_doctrine": [
        "Read Contract v1 / Provisioning Contract v1 references to Privacy Contract constraints",
        "Update Contract v1 review against Privacy Contract §15",
        "Field classification reference for Privacy Contract drafters",
        "Doctrine for any lane not needing actual vault content storage"
      ]
    },
    "18_cross_workspace_implications": {
      "18_2_cwg_enforcement": [
        "Any future cross-workspace UCC operation requires CWG consent",
        "Vault content NEVER crosses workspaces, regardless of CWG approval"
      ],
      "18_4_workspace_local_default": "Privacy Contract v1 reaffirms Decision 5: workspace-local default. Privacy applies per workspace.",
      "18_1_vault_never_cross_workspace": [
        "No clone (Provisioning §12.2)",
        "No migration (deferred future feature)",
        "No import-from-export",
        "No backup-and-restore that crosses workspaces"
      ],
      "18_3_multi_tenant_workspace_privacy": [
        "Vault MUST be owner-only readable per §13 (incl. metadata visibility)",
        "Workspace members other than owner MUST NOT see vault content OR vault metadata revealing presence",
        "Workspace members CAN see core-tier UCC content (existing workspace-member RLS)"
      ]
    },
    "11_vault_metadata_in_default_wake": {
      "11_2_constraints": [
        "vault_available boolean indicates vault exists",
        "default_loaded boolean always false in default /wake",
        "NO field names, categories, summaries, values"
      ],
      "11_1_locked_shape": {
        "vault_metadata": {
          "default_loaded": false,
          "vault_available": true
        }
      },
      "11_3_acceptable_known_minor_leak": "vault_available: true is known minor leak. Accepted for v1 to enable consent UI. Privacy v2 may tighten.",
      "11_4_read_contract_reconciliation": "No Read Contract amendment required. Read v1 §11 already permits boolean shape and authorizes Privacy Contract to reduce signaling further (Privacy v1 does NOT reduce — boolean preserved).",
      "11_5_existence_metadata_vs_discovery": "vault_available is existence metadata, NOT content/category/field discovery. Existence metadata: tells consent UI vault IS or IS NOT present. Content discovery: would reveal what's in vault — NOT permitted at /wake. Category discovery: would reveal which categories — NOT permitted at /wake (happens at consent moment per §7.2). Field discovery: would reveal which specific fields — NEVER permitted by this contract."
    },
    "9_inference_vs_persistence_boundary": {
      "hard_rule": "Q-inferred content MUST NOT be persisted to UCC without explicit user confirmation",
      "9_3_forbidden": [
        "Q persists 'Joel is stressed' without confirmation",
        "Q persists 'Joel seems unhappy with his job' based on conversation patterns",
        "Q persists relationship dynamics observed in conversation",
        "Q persists psychological-state interpretations of any kind"
      ],
      "9_4_update_contract_v1_enforcement": "Update Contract v1 MUST validate any UCC write either: (a) Originates from explicit user confirmation, OR (b) Originates from provisioning workflow. Q-inferred writes WITHOUT explicit confirmation MUST be rejected.",
      "9_1_allowed_in_session_not_persisted": [
        "Q infers Joel is stressed about a meeting -> temporary, NOT persisted",
        "Q infers from message tone Joel is rushed -> temporary, NOT persisted",
        "Q infers Joel prefers shorter responses today -> temporary, NOT persisted"
      ],
      "9_2_allowed_with_user_confirmation_persistable": [
        "Joel says 'I prefer concise responses' -> persistable to service_preferences.detail_level",
        "Joel says 'I value autonomy' -> persistable to standing_context.personal_values",
        "Joel says 'Don't bring up my recent surgery unless I do' -> user-confirmed; surgery topic itself goes to vault per §10"
      ]
    },
    "15_constraints_on_update_contract_v1": {
      "15_3_review_gate": "When Update Contract v1 is drafted, Privacy Contract v1 §15 MUST be referenced authority. Update Contract v1 review MUST verify §15 conformance before save-ready preparation.",
      "15_1_required_behaviors": [
        "Tier validation before write — reject writes placing vault-tier content into core",
        "No auto-promotion vault->core — tier transitions require explicit user confirmation",
        "No persistence of Q-inferred content without explicit user confirmation (§9)",
        "No bypassing vault consent/tier classification — NO bypass path",
        "Honor §10 field-name conventions — reject content-bearing field paths",
        "Honor §11 vault metadata constraints — boolean form ONLY in vault_metadata",
        "Honor §4.7 source_artifact_ids leak-prevention — validate provenance.source_artifact_ids does NOT reference vault snapshots, vault journals, sensitive source artifacts, or artifacts whose title/tags/metadata reveal sensitive categories",
        "Default-deny for ambiguous classification — default to vault / consent-required",
        "Honor §13 RLS path — whatever verified, Update Contract v1 MUST honor",
        "Conditional fields (§4.1, §4.3) MUST validate context-appropriate tier — role_or_context and personal_values",
        "Honor §7 pre-consent vs post-consent boundary — Update writes do NOT bypass consent boundary; Update writes are NOT consent-discovery operations"
      ],
      "15_2_forbidden_behaviors": [
        "Auto-promote sensitivity classes",
        "Bypass Privacy Contract v1 tier validation under any circumstance",
        "Write into vault tier without honoring §6 vault artifact semantics",
        "Modify workspace UCC root anchor's structural-only nature",
        "Persist forbidden-category content (§5)",
        "Reference vault artifact_ids in core-tier provenance (§4.7)"
      ]
    },
    "4_per_section_field_tier_classification": {
      "4_1_user": [
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "display_name"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "preferred_name"
        },
        {
          "tier": "core",
          "class": "private-sensitive",
          "field": "email"
        },
        {
          "tier": "core",
          "class": "private-sensitive",
          "field": "user_id"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "workspace_id"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "timezone"
        },
        {
          "rule": "General role/context: core/private-sensitive. Sensitive roles, workplaces, client identities, regulated contexts, or roles that could expose protected/private status: vault-tier unless explicitly approved for core by user. Update Contract v1 validates.",
          "tier": "conditional",
          "class": "conditional",
          "field": "role_or_context"
        }
      ],
      "4_4_boundaries": [
        {
          "note": "Q-behavior rule, not sensitive content",
          "tier": "core",
          "class": "private-sensitive",
          "field": "do_not_assume"
        },
        {
          "note": "Q-behavior rule",
          "tier": "core",
          "class": "private-sensitive",
          "field": "do_not_surface_unprompted"
        },
        {
          "tier": "core",
          "class": "private-sensitive",
          "field": "sensitive_categories",
          "status": "DRAFT CANDIDATE — Gate 2; primary consent taxonomy source per §8.1; if rejected fallback path activates"
        },
        {
          "tier": "vault",
          "class": "consent-required",
          "field": "sensitive_topic_details",
          "status": "DRAFT CANDIDATE — Gate 3"
        },
        {
          "tier": "core",
          "class": "private-sensitive",
          "field": "consent_required_for"
        }
      ],
      "4_5_q_behavior": [
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "default_support_mode"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "nudge_permissions"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "known_shortcuts"
        }
      ],
      "4_7_provenance": {
        "fields": [
          {
            "tier": "core",
            "class": "public-to-q",
            "field": "created_from"
          },
          {
            "tier": "core",
            "class": "public-to-q",
            "field": "created_at"
          },
          {
            "tier": "core",
            "class": "public-to-q",
            "field": "updated_by"
          },
          {
            "tier": "core",
            "class": "public-to-q (with constraint)",
            "field": "source_artifact_ids"
          }
        ],
        "leak_prevention_constraint": [
          "MUST NOT reference vault snapshots or vault journals",
          "MUST NOT reference sensitive source artifacts (do-not-surface or consent-required content)",
          "MUST NOT reference artifacts whose title/tags/metadata reveal sensitive categories",
          "Vault-related provenance belongs INSIDE the vault artifact (vault payload provenance section, also vault-tier) or future Audit/Access Contract — NOT default-loaded core",
          "Update Contract v1 MUST validate before write (§15)"
        ]
      },
      "4_6_review_control": [
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "last_reviewed"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "review_cadence"
        },
        {
          "tier": "core",
          "class": "private-sensitive",
          "field": "pending_changes"
        }
      ],
      "4_3_standing_context": [
        {
          "note": "General professional context only. Sensitive workplace/client/regulated contexts -> vault per §4.1 rule.",
          "tier": "core",
          "class": "private-sensitive",
          "field": "work_context"
        },
        {
          "rule": "Broad operating principles: core/private-sensitive. Values revealing religious, political, identity-bearing, medical, relational, or otherwise sensitive commitments: vault-tier unless user explicitly approves core. Update Contract v1 validates.",
          "tier": "conditional",
          "class": "conditional",
          "field": "personal_values"
        },
        {
          "tier": "vault",
          "class": "do-not-surface",
          "field": "important_relationships"
        },
        {
          "note": "Default; user MAY opt specific items to core.",
          "tier": "vault",
          "class": "do-not-surface",
          "field": "active_life_context"
        },
        {
          "tier": "vault",
          "class": "consent-required",
          "field": "health_context"
        },
        {
          "tier": "vault",
          "class": "do-not-surface",
          "field": "family_context",
          "status": "DRAFT CANDIDATE — Gate 1; if rejected family content lives within important_relationships"
        }
      ],
      "4_2_service_preferences": [
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "tone"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "pacing"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "detail_level"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "format_preferences"
        },
        {
          "tier": "core",
          "class": "public-to-q",
          "field": "interaction_rules"
        }
      ]
    },
    "16_constraints_on_read_contract_v1_reaffirm": "Privacy Contract v1 does NOT amend Read Contract v1. Reaffirms: vault values absent from /wake (§1, §11), vault_metadata limited to boolean (§1; Privacy §11 confirms), vault values stored in separate artifact (§11; Privacy §6 specifies semantics), no vault caching (§11), vault values in core triggers invalid-candidate (§10/§11), owner-only RLS expectation (§11; Privacy §13). Privacy SUPPLEMENTS by: specifying core vs vault content (§4), vault artifact semantics (§6), consent + pre/post-consent boundary (§7, §8), source_artifact_ids constraint (§4.7).",
    "6_vault_artifact_semantics_and_storage_paths": {
      "6_2_storage_paths": [
        "Path 1: artifact_type=snapshot with non-bypassable classification (Gateway/control-plane logic; not user-editable tags)",
        "Path 2: artifact_type=journal leveraging existing owner-only journal RLS (verify Path 2 metadata visibility per §13)",
        "Path 3: DDL changes — explicitly forbidden in this lane"
      ],
      "6_1_semantics_locked": [
        "Immutable full-state per update — each save creates new immutable artifact carrying FULL current vault state",
        "Deterministic latest-valid retrieval — latest valid artifact (created_at DESC, version DESC, artifact_id DESC) authoritative at read time",
        "Bounded scan / fall-through — LIMIT 5 candidate window pattern (per Read Contract v1 §2 / §10)",
        "Owner-only readable — scope expanded per amendment 6 to also cover vault artifact titles, ucc-vault tags, and any metadata revealing vault presence/category",
        "Anti-leak constraints (§10) apply to all vault artifact metadata",
        "Historical artifacts persist but NOT broadly readable; same owner-only and anti-leak constraints",
        "LANGUAGE: latest valid vault is retrieval pattern, NOT mutable replacement"
      ],
      "6_6_validation_invalid_when": [
        "Vault payload (storage-type-equivalent) missing",
        "vault_record_type missing or not 'user_context_vault'",
        "schema_version missing or invalid format (per Read Contract v1 §7 numeric-comparison)",
        "vault_fields section missing",
        "workspace_id mismatches active session workspace",
        "user_id mismatches active session user (defense-in-depth)",
        "JSON parse error",
        "Tags fail post-validation (both ucc-vault AND for-q required)",
        "Owner-only enforcement bypass detected (per §13 path)"
      ],
      "6_4_payload_shape_illustrative_only": {
        "shape": {
          "user_id": "<UUID>",
          "generated_at": "<ISO datetime>",
          "workspace_id": "<UUID>",
          "schema_version": "v1",
          "vault_record_type": "user_context_vault",
          "prior_vault_artifact_id": "<artifact_id of superseded vault artifact, or null if first vault>",
          "vault_fields_keyed_by_section_dot_neutral_field_name": {
            "value": "<sensitive content>",
            "field_added_at": "<ISO datetime>",
            "sensitivity_class": "do-not-surface | consent-required",
            "consent_changed_at": "<ISO datetime>"
          }
        },
        "marking": "ILLUSTRATIVE ONLY — not implementation-authoritative. Actual storage location depends on §13 path resolution."
      },
      "6_3_required_fields_storage_agnostic": {
        "tags": "[ucc-vault, for-q] — REQUIRED both; discovery hints, NOT privacy authority; tag visibility part of <TBD-PENDING-RLS-FEASIBILITY>",
        "priority": 3,
        "artifact_type": "<TBD-PENDING-RLS-FEASIBILITY>",
        "title_pattern": "UCC Vault — <workspace_label> — <YYYY-MM-DD>",
        "semantic_type_id": "semantic classification: governance. Payload prep MUST resolve to Gateway-accepted form. String key 'governance' verified for Read v1 + Provisioning v1 saves on this lane.",
        "parent_artifact_id": "Workspace UCC root anchor (per Provisioning Contract v1 §5)",
        "title_visibility_note": "Title visibility to non-owner workspace members is part of <TBD-PENDING-RLS-FEASIBILITY> per amendment 6"
      },
      "6_5_retrieval_pattern_illustrative_only": "Both paths use bounded-scan retrieval (LIMIT 5, ordered created_at DESC, version DESC, artifact_id DESC). Actual query depends on §13 path. Path 1 ILLUSTRATIVE: SELECT from qxb_artifact JOIN qxb_artifact_snapshot WHERE artifact_type=snapshot AND tags ? 'ucc-vault' AND tags ? 'for-q' + non-bypassable owner-only. Path 2 ILLUSTRATIVE: SELECT from qxb_artifact JOIN qxb_artifact_journal WHERE artifact_type=journal + existing journal owner-only RLS + spine row visibility verification."
    },
    "10_field_name_and_metadata_leakage_prevention": {
      "10_1_granularity_rule": {
        "acceptable_labels": [
          "Broad LIFE DOMAINS: work, health, finances, relationships, family, values",
          "Broad BEHAVIORAL CATEGORIES: sensitive_topics, do_not_assume, consent_required_for",
          "Section-level: standing_context.health_context, boundaries.sensitive_topic_details, service_preferences.tone"
        ],
        "forbidden_labels_examples": [
          "Specific conditions: health.diabetes_management, health.depression_management",
          "Specific events: boundaries.divorce_proceedings, relationships.layoff_2025",
          "Specific identities: relationships.daughter_emma_conflict, family.mother_dementia",
          "Specific behaviors: finances.gambling_debts, health.addiction_recovery"
        ]
      },
      "10_2_too_revealing_test": [
        "Reading the label alone reveals a specific condition, event, or identity",
        "Label names a topic the user would consider private at the topic level",
        "Label could appear in error messages or logs and constitute a leak"
      ],
      "10_4_save_side_validation": "Update Contract v1 MUST reject writes that introduce content-bearing field paths to UCC",
      "10_3_metadata_exclusion_rules": [
        "Error messages MUST NOT echo vault values or vault field names that leak categories",
        "Telemetry MUST NOT log vault values",
        "Audit logs (when implemented) MUST follow §12 constraints",
        "Diagnostic surfacing MUST stay at structural-label level",
        "Logs from validation failures MUST scrub vault content before emission"
      ]
    },
    "17_constraints_on_provisioning_contract_v1_reaffirm": "Privacy Contract v1 does NOT amend Provisioning Contract v1. Reaffirms: bootstrap does NOT seed vault content (§4 minimum-required is core-tier only), provisioning does NOT cross-workspace clone vault content (§12.2). Privacy SUPPLEMENTS by: confirming all 7 minimum-required are core-tier (§4), Update Contract v1 owns vault writes post-activation.",
    "7_vault_discovery_and_retrieval_pre_vs_post_consent": {
      "core_principle": "Consent governs access/loading of vault values, not merely Q's later use/reference.",
      "7_1_default_wake": "vault_available boolean (existence metadata only); default_loaded always false; NO field names, categories, summaries, values",
      "7_5_no_pre_cache": "Q MUST NOT cache vault field names or categories from prior sessions. Each /wake fresh: Q knows only that vault exists (boolean per §11).",
      "7_2_pre_consent_discovery": {
        "allowed": [
          "Operations returning ONLY safe eligibility/category metadata needed to ask for consent",
          "Determining which broad categories exist for the user"
        ],
        "trigger": "Q needs to formulate a consent prompt (user-initiated action requires vault content)",
        "must_not_return": [
          "Vault values",
          "Fine-grained field names",
          "Specific sensitive topic details",
          "Payload summaries",
          "Anything that would reveal a vault value by metadata"
        ],
        "implementation_requirement": "System MUST be able to technically separate pre-consent category discovery from value loading"
      },
      "7_3_post_consent_retrieval": {
        "allowed": [
          "Operations loading ONLY approved category or approved field scope into active session",
          "Q absorbs loaded content for session duration (consent-required class re-prompts per use)"
        ],
        "trigger": "User has explicitly consented to a category or field scope for the active session",
        "must_not": [
          "Load content outside approved scope",
          "Cache loaded values for use after revocation",
          "Persist loaded values across sessions"
        ]
      },
      "7_4_consent_retrieval_feasibility_marker": {
        "marker": "<TBD-PENDING-CONSENT-RETRIEVAL-FEASIBILITY>",
        "until_verified": "Vault implementation BLOCKED, even if §13 RLS feasibility otherwise resolved",
        "verification_required": [
          "Can Gateway support 'category-only' query returning categories WITHOUT values, field names, or summaries?",
          "OR vault artifact structured such that 'shallow' retrieval returns only category-level metadata?",
          "OR control-plane vault index providing category enumeration without exposing payload?"
        ]
      }
    }
  },
  "draft_label": "Draft 3 / Save-Ready Cleanup",
  "draft_status": "near save-ready, 5 gates remaining (see approved_pending_joel_q_confirmation)",
  "contract_name": "UCC Privacy Contract v1",
  "snapshot_type": "design_contract_draft",
  "review_history": {
    "draft_1": "Initial CC draft 2026-05-06 with 7 §4 decisions locked + Joel's 6-item rollout boundary",
    "draft_2": "Team Qwrk + Manus amendments incorporated (13 amendments)",
    "planning_scope_v1": "CC planning document 2026-05-06 — defined scope, surfaced Joel's 10 questions",
    "planning_scope_vNext": "Consolidated planning packet after Team Qwrk integrity review — 7 architectural decisions surfaced",
    "draft_3_save_ready_cleanup": "Final cleanup applied per Manus + Q review (9 amendments) — this snapshot"
  },
  "session_context_note": "This draft snapshot was created at end of session 137 (2026-05-06) per Joel directive 'snapshot it' to preserve Draft 3 outside conversation context. Session began as Q@W subsession 2026-05-05 ('nsub'), spanned midnight, ended after Privacy Contract v1 Draft 3 reached near-save-ready state. Session-end snapshot will be saved separately with full session context. T199 thread captures pickup state in OPEN_THREADS.md.",
  "deferred_out_of_scope": [
    "Future Audit Contract mechanism",
    "Future Restore/Delete/Privacy-Export Contract",
    "Workspace-purpose forbidden-category exception governance (separate future contract)",
    "Per-field 'Customize' consent UI (future lane)",
    "Control-plane vault registry (Path 1 variant assessment)",
    "Operational anomaly logging (Q-head doctrine)"
  ],
  "save_ready_recommendation": {
    "verdict": "NEAR save-ready, with 5 small gates remaining",
    "judgment": "These 5 gates are decisions ON the contract that lock the existing draft. They are NOT amendments to the contract body. Once resolved, the contract body as-is becomes the save-ready payload (with appendix providing decision provenance). If Joel/Q resolves all 5 gates positively in next session, Privacy Contract v1 is save-ready and QSB payload prepared directly from this draft without further contract revisions. If any gate resolved differently, contract still saves cleanly via built-in fallback paths (§8.1) or by removing gated entries from §4. No structural rework required.",
    "rationale": "Privacy Contract v1 Draft 3 contract body is structurally complete. All cumulative amendments (Draft 2 + Draft 3, 22 total) are integrated. Doctrine is internally consistent. Cross-references with Read Contract v1 and Provisioning Contract v1 are clean.",
    "five_gates_summary": [
      "DRAFT CANDIDATE field approval (3 fields)",
      "Conditional doctrine lock posture for save",
      "Markers acceptable in saved contract",
      "§4.1/§4.3 conditional logic deferred to Update Contract v1",
      "Appendix structure satisfies decision-record vs blocker split"
    ]
  },
  "purpose_of_this_draft_snapshot": "Preserve UCC Privacy Contract v1 Draft 3 content outside conversation context. Source of truth for resumption when Joel/Q resolves the 5 gates and proceeds to save-ready payload preparation. NOT the final saved contract — that artifact will be created after gate resolution.",
  "approved_decision_records_locked": [
    "4.1: Sensitivity class taxonomy — lock 4 v2 classes (public-to-q, private-sensitive, do-not-surface, consent-required); no expansion in v1",
    "4.2: do-not-surface tier mapping — vault-tier; no core-tier inhibitor model",
    "4.3: Vault metadata at /wake — boolean-only (vault_available, default_loaded); accepted as known minor leak",
    "4.4: Vault artifact semantics — full-state immutable per update; deterministic latest-valid retrieval",
    "4.5: Field-name convention — neutral structural labels only; descriptive details as values, never field paths",
    "4.6: Audit policy posture — anti-leak constraints locked, mechanism deferred; no audit implementation authorized",
    "4.7: Owner-only RLS feasibility — <TBD-PENDING-RLS-FEASIBILITY> carried; scope expanded to metadata visibility per amendment 6",
    "D2-A1: RLS marker blocking posture — doctrine locked / implementation blocked (refined to 'proposed' pending approval per Draft 3 amendment 3)",
    "D2-A2: Snapshot semantics vs storage type — semantics locked; storage type path-dependent",
    "D2-A4: Tags as discovery hints, NOT privacy authority",
    "D2-A6: source_artifact_ids leak-prevention — locked in §4.7 + §15",
    "D2-A7: personal_values conditional classification — broad principles core; sensitive commitments vault unless explicitly approved",
    "D2-A8: role_or_context conditional classification — general role core; sensitive roles vault unless explicitly approved",
    "D2-A10: Forbidden categories vs workspace-purpose exception — v1 absolute; exception requires separate future contract",
    "D2-A11: Long-term vault removal language — removal from latest operational state, NOT physical deletion of prior immutable versions",
    "D2-A12: 'Customize' option non-committal — ILLUSTRATIVE only, not implemented in v1",
    "D3-A1: Consent-time discovery sequence — pre-consent discovery vs post-consent retrieval boundary; new <TBD-PENDING-CONSENT-RETRIEVAL-FEASIBILITY> if infrastructure cannot separate",
    "D3-A2: /wake metadata language — vault_available is existence metadata, NOT content/category/field discovery",
    "D3-A8: JSON/SQL posture — JSON minimal for shapes; SQL marked ILLUSTRATIVE ONLY"
  ],
  "approved_pending_joel_q_confirmation_5_gates": [
    {
      "gate": 1,
      "item": "Field: family_context",
      "status": "DRAFT CANDIDATE — recommended for approval",
      "default_if_rejected": "Family content lives within important_relationships (existing v2 schema); §4.3 entry removed",
      "q_tentative_direction": "approve"
    },
    {
      "gate": 2,
      "item": "Field: boundaries.sensitive_categories",
      "status": "DRAFT CANDIDATE — recommended for approval; primary consent taxonomy source per §8.1",
      "default_if_rejected": "Privacy Contract v1 §8.1 fallback path activates (hardcoded coarse list ['health','finances','relationships','family','values'])",
      "q_tentative_direction": "approve"
    },
    {
      "gate": 3,
      "item": "Field: boundaries.sensitive_topic_details",
      "status": "DRAFT CANDIDATE — recommended for approval; vault-tier fine-grained specifics",
      "default_if_rejected": "Sensitive topic specifics relocate within other vault fields; §4.4 entry removed",
      "q_tentative_direction": "approve"
    },
    {
      "gate": 4,
      "item": "Conditional doctrine lock posture for save",
      "status": "Confirm 'doctrine locked / implementation blocked' final language acceptable, OR keep 'proposed doctrine lock' indefinitely",
      "default_if_rejected": "Save-ready preparation cannot proceed",
      "q_tentative_direction": "accept doctrine locked / implementation blocked"
    },
    {
      "gate": 5,
      "item": "Both TBD markers acceptable as visible blockers in saved contract",
      "status": "Confirm <TBD-PENDING-RLS-FEASIBILITY> and <TBD-PENDING-CONSENT-RETRIEVAL-FEASIBILITY> acceptable in saved artifact",
      "default_if_rejected": "Save-ready preparation cannot proceed",
      "q_tentative_direction": "allow saved contract to carry both blockers"
    }
  ],
  "remaining_blockers_after_save_before_implementation": [
    {
      "blocker": "<TBD-PENDING-RLS-FEASIBILITY>",
      "verification_required": "Path 1 (Gateway-layer non-bypassable filter incl. metadata visibility) OR Path 2 (journal storage incl. spine row visibility verification) — DDL forbidden per Path 3"
    },
    {
      "blocker": "<TBD-PENDING-CONSENT-RETRIEVAL-FEASIBILITY>",
      "verification_required": "Infrastructure can technically separate pre-consent category discovery from value loading per §7"
    },
    {
      "blocker": "Path 2 journal extension column verification",
      "verification_required": "Whether qxb_artifact_journal supports payload JSONB column or forces entry_text"
    },
    {
      "blocker": "Update Contract v1 not yet drafted",
      "verification_required": "§15 constraints flow forward to Update Contract v1 lane (separate authorization)"
    }
  ]
}
```

---

## End of Hydration Package

_10 artifacts hydrated. Await full TQR prompt._
