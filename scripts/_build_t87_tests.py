"""Generate T87 regression test files for Phase2C certification harness."""
import json, os, sys
sys.stdout.reconfigure(encoding="utf-8")

tests_dir = "Phase2C_Cert/tests"

tests = [
    ("H01_t87_project_create.json", {
        "name": "H01 - T87 Create Project for spine testing",
        "expected": {"ok": True, "error_code": None},
        "capture": {"H_PROJECT_ID": "artifact_id"},
        "payload": {
            "gw_action": "artifact.save",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "title": "[T87-CERT] Spine Field Test Project",
            "summary": "Original summary before T87 spine updates",
            "tags": ["t87-cert"],
            "extension": {"lifecycle_stage": "seed"}
        }
    }),
    ("H02_t87_spine_only_summary.json", {
        "name": "H02 - T87 Spine-only update (summary)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "summary": "T87 spine-only summary update verified"
        }
    }),
    ("H03_t87_spine_only_title.json", {
        "name": "H03 - T87 Spine-only update (title)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "title": "[T87-CERT] Title Updated via Spine"
        }
    }),
    ("H04_t87_spine_only_priority.json", {
        "name": "H04 - T87 Spine-only update (priority)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "priority": 1
        }
    }),
    ("H05_t87_mixed_summary_tags.json", {
        "name": "H05 - T87 Mixed update (summary + tags)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "summary": "T87 mixed update - summary + tags in one PATCH",
            "tags": {"add": ["t87-mixed-verified"]}
        }
    }),
    ("H06_t87_mixed_title_priority_tags.json", {
        "name": "H06 - T87 Mixed update (title + priority + tags)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "title": "[T87-CERT] Multi-field Mixed Update",
            "priority": 2,
            "tags": {"add": ["t87-multi-mixed"]}
        }
    }),
    ("H07_t87_extension_plus_spine_rejected.json", {
        "name": "H07 - T87 Extension + spine = MIXED_UPDATE_NOT_ALLOWED",
        "expected": {"ok": False, "error_code": "MIXED_UPDATE_NOT_ALLOWED"},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "summary": "should be rejected",
            "extension": {"operational_state": "active"}
        }
    }),
    ("H08_t87_extension_plus_tags_rejected.json", {
        "name": "H08 - T87 Extension + tags = MIXED_UPDATE_NOT_ALLOWED",
        "expected": {"ok": False, "error_code": "MIXED_UPDATE_NOT_ALLOWED"},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "tags": {"add": ["should-reject"]},
            "extension": {"operational_state": "active"}
        }
    }),
    ("H09_t87_journal_create.json", {
        "name": "H09 - T87 Create Journal for immutability test",
        "expected": {"ok": True, "error_code": None},
        "capture": {"H_JOURNAL_ID": "artifact_id"},
        "payload": {
            "gw_action": "artifact.save",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "journal",
            "title": "[T87-CERT] Journal Immutability Test",
            "tags": ["t87-cert"],
            "extension": {
                "entry_text": "T87 journal for INSERT_ONLY verification"
            }
        }
    }),
    ("H10_t87_journal_extension_blocked.json", {
        "name": "H10 - T87 Journal extension update = JOURNAL_INSERT_ONLY",
        "expected": {"ok": False, "error_code": "JOURNAL_INSERT_ONLY"},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "journal",
            "artifact_id": "{{H_JOURNAL_ID}}",
            "extension": {"entry_text": "should be rejected"}
        }
    }),
    ("H11_t87_snapshot_create.json", {
        "name": "H11 - T87 Create Snapshot for immutability test",
        "expected": {"ok": True, "error_code": None},
        "capture": {"H_SNAPSHOT_ID": "artifact_id"},
        "payload": {
            "gw_action": "artifact.save",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "snapshot",
            "title": "[T87-CERT] Snapshot Immutability Test",
            "tags": ["t87-cert"],
            "extension": {
                "payload": {"note": "T87 immutability verification"}
            }
        }
    }),
    ("H12_t87_snapshot_extension_blocked.json", {
        "name": "H12 - T87 Snapshot extension update = IMMUTABILITY_ERROR",
        "expected": {"ok": False, "error_code": "IMMUTABILITY_ERROR"},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "snapshot",
            "artifact_id": "{{H_SNAPSHOT_ID}}",
            "extension": {"payload": {"note": "should be rejected"}}
        }
    }),
    ("H13_t87_query_verify_spine.json", {
        "name": "H13 - T87 Query project to verify spine updates persisted",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.query",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "hydrate": True
        }
    }),
    ("H14_t87_tags_only_regression.json", {
        "name": "H14 - T87 Tags-only update (regression)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "tags": {"add": ["t87-tags-regression"], "remove": ["t87-cert"]}
        }
    }),
    ("H15_t87_extension_only_regression.json", {
        "name": "H15 - T87 Extension-only update (regression)",
        "expected": {"ok": True, "error_code": None},
        "payload": {
            "gw_action": "artifact.update",
            "gw_workspace_id": "{{WORKSPACE_ID}}",
            "artifact_type": "project",
            "artifact_id": "{{H_PROJECT_ID}}",
            "extension": {"operational_state": "active"}
        }
    }),
]

for filename, data in tests:
    path = os.path.join(tests_dir, filename)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  Wrote: {filename}")

print(f"\nTotal: {len(tests)} test files")
