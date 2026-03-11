# Instruction Pack — Mother Tree Structural Map (v1)

**scope:** `global`
**pack_version:** `v1`
**status:** Active
**created:** 2026-03-09
**origin:** Twig `af0e15b5` → Instruction Pack `b48d0f9e`
**artifact_id:** `b48d0f9e-a080-4402-8cd7-cbf9bb909c99`

---

## Purpose

Provides Q with the authoritative UUID map for the Mother Tree and its direct structural children. Used when constructing Gateway payloads that require `parent_artifact_id`.

---

## Mother Tree Topology

| Name | Type | UUID |
|------|------|------|
| **Qwrk Prime — Mother Tree** | project | `dec0597b-8edc-4387-95e7-025960f3cedc` |
| Platform | project | `dd409298-4c64-4412-b0e0-2ace13a7283a` |
| Product | branch | `3ccc694d-7d84-4830-8d59-eee3184462fe` |
| Command Center | limb | `b00fc252-fdf5-4200-99e4-073d50868112` |
| Idea Nursery | project | `d130a4ec-535e-4e24-a6cd-63d4d8800865` |
| Historical Record | project | `fd0120ca-4328-45ab-92d5-99f2e1837ea6` |
| Snapshots | branch | `ae7b0467-0fb6-4fba-a10c-caa7a38de7f3` |
| Forest Map | project | `08396b6b-0b6a-4e13-8a51-e1247bd98e6f` |

---

## Behavioral Rule

When Q needs to set `parent_artifact_id` for an artifact being planted on the Mother Tree or one of its branches:

1. **Use this map.** The UUIDs above are authoritative.
2. **Match by intent.** Use the branch/container whose purpose best matches the artifact being planted.
3. **If uncertain:** Ask Joel before constructing the payload. Do not guess.
4. **If the target parent is not listed here:** Ask Joel. This map covers direct structural children only.

---

## Routing Guidance

| If the artifact is... | Parent to... |
|-----------------------|-------------|
| Platform infrastructure, system capability | Platform |
| User-facing product feature, design | Product |
| CmdCtr-related (observability, intelligence) | Command Center |
| Experimental idea, early-stage concept | Idea Nursery |
| Historical/archival record | Historical Record |
| Point-in-time snapshot, milestone | Snapshots |
| Topology reference, structural metadata | Forest Map |
| Doesn't fit any branch / top-level initiative | Mother Tree (root) |

---

## Scope & Limitations

- **Crawl-phase MVP.** Static map, manually maintained.
- **Direct children only.** Sub-branches (e.g., Historical Record → Governance Record) not included.
- **Updates:** When the Mother Tree topology changes (new branches added, branches renamed/removed), this file must be updated and re-uploaded to the ChatGPT project.
- **Walk/Run deferrals:** Dynamic topology awareness, CmdCtr-derived routing, automatic map regeneration — all deferred.

---

*CHANGELOG: v1 (2026-03-09): Initial MVP. Static structural map for Mother Tree direct children. Origin twig: af0e15b5.*
