# ARTIFACT.SAVE — Known UUIDs (Canonical Reference)

Use this payload to store the authoritative, frequently-used UUIDs for this Qwrk workspace.
This artifact is intended to prevent memory lookups, reduce errors, and serve as a stable reference.

---

```json
{
  "artifact_type": "project",
  "title": "Known UUIDs — Canonical Reference",
  "summary": "Authoritative list of frequently used UUIDs for the primary Qwrk workspace, including user, workspace, owner, and instruction pack artifacts.",
  "content": {
    "purpose": "Provide a single, stable reference for commonly required UUIDs to avoid re-discovery and reduce operational friction.",
    "workspace": {
      "workspace_id": "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
    },
    "identity": {
      "user_id": "7097c16c-ed88-4e49-983f-1de80e5cfcea",
      "owner_user_id": "c52c7a57-74ad-433d-a07c-4dcac1778672"
    },
    "instruction_packs": {
      "global": {
        "artifact_id": "f9b97cd5-eb7d-4a8e-86a0-9f4b6dbd4779",
        "scope": "global",
        "description": "Global interaction rules, shortcuts, and prompt-formatting behaviors."
      },
      "mode_build": {
        "artifact_id": "749a965d-3bdb-42d5-9015-f93f637f7cd4",
        "scope": "mode:build",
        "description": "Build discipline pack enforcing one-step-at-a-time execution and receipt gating."
      }
    },
    "history": {
      "system_history_project": {
        "artifact_id": "d30bda32-9149-4bba-a2f8-194fca71a265",
        "artifact_type": "project",
        "title": "Qwrk — System History & Evolution",
        "description": "Canonical container for all historical artifacts related to Qwrk."
      },
      "history_entry_001": {
        "artifact_id": "44cff1d8-c2c3-42be-9133-a2aeef5ea925",
        "artifact_type": "journal",
        "title": "HISTORY · Qwrk · Capabilities Overview · Initial Introduction",
        "description": "Foundational origin record capturing Qwrk's initial self-description."
      }
    },
    "notes": [
      "This document is canonical and should be updated when any referenced UUID changes.",
      "Future instruction packs, gateways, or system anchors should be appended here.",
      "This artifact is intended for both human reference and AI operational grounding."
    ]
  },
  "tags": {
    "reference": "uuid",
    "canonical": "true",
    "governance": "operational"
  }
}
```
