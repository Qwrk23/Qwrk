# Instruction Pack — Mother Tree Structural Map (Q@W)

> **Version:** v1
> **Workspace:** Q@W (Work / Resolve)
> **workspace_id:** `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`
> **Created:** 2026-03-09
> **Purpose:** Provide Q with persistent access to the Q@W Mother Tree topology UUIDs for parent artifact routing.

---

## Mother Tree Root

| Field | Value |
|-------|-------|
| **artifact_id** | `17406200-a7b5-4acd-960a-110a042a2f85` |
| **artifact_type** | project |
| **title** | Q@W Mother Tree |
| **lifecycle_status** | tree |

---

## Structural Branches

### Platform
| Field | Value |
|-------|-------|
| **artifact_id** | `63219d74-3b43-4ae0-afdb-7208e9bb7868` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | System infrastructure, gateway operations, workspace configuration, Qwrk platform tooling. Test artifacts. |

### Opportunities
| Field | Value |
|-------|-------|
| **artifact_id** | `0b8b6f7b-15fa-4ba5-b090-f4ab2110fcae` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | Sales opportunities (LEK, future accounts), deal tracking, opportunity lifecycle, competitive intelligence. Each opportunity becomes a project or limb under this branch. |

### Demo Infrastructure
| Field | Value |
|-------|-------|
| **artifact_id** | `7437175f-61f7-46eb-9a66-8fb2288ce73a` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | PoV environments, demo prep, demo scripts, customer-facing technical validation. NOT client delivery — only pre-sale demonstration infrastructure. |

### Documentation
| Field | Value |
|-------|-------|
| **artifact_id** | `d304bcc4-35cb-4c49-bf28-c7d6486beb6d` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | Process documentation, templates, playbooks, governance docs for the Work domain. Sales methodology templates. |

### Operational Intelligence
| Field | Value |
|-------|-------|
| **artifact_id** | `b44341d7-e02a-46c6-ba3a-a64be1639332` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | CmdCtr outputs, workspace health monitoring, execution readiness signals, operational snapshots. System-generated observability artifacts. |

### Idea Nursery
| Field | Value |
|-------|-------|
| **artifact_id** | `d769012d-443a-4207-a94c-fb11e2b87b93` |
| **Parent** | Q@W Mother Tree (`17406200`) |
| **Routing guidance** | Seeds, experiments, unclassified ideas, twigs not yet routed to a specific branch. Temporary home for artifacts awaiting classification. |

---

## Routing Rules

1. **Every new project, branch, limb, or twig** in Q@W should be parented to one of the 6 branches above.
2. **Journals and snapshots** do NOT require Mother Tree parenting — they may be parented to any artifact or left unparented.
3. **If classification is ambiguous**, route to Idea Nursery. Reclassification can happen later via `artifact.update` with `parent_artifact_id`.
4. **No Client Delivery branch exists** — that function is out of scope for Q@W.
5. **This map is specific to workspace `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`** (Work / Resolve). Do NOT use these UUIDs in other workspaces.

---

## CHANGELOG

### v1 — 2026-03-09
- Initial creation as part of Q@W Feature Parity Sprint (Block 1)
- 6 structural branches: Platform, Opportunities, Demo Infrastructure, Documentation, Operational Intelligence, Idea Nursery
- Instruction pack artifact to be saved in Q@W workspace
