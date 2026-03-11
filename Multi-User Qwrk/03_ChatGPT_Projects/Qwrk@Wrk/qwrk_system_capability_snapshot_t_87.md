# System Capability Snapshot — Qwrk@Work Kernel (T87 State)

## Snapshot Metadata

- **artifact_id:** `44a4548f-5164-48b8-83f5-afd4c6baf7be`
- **artifact_type:** `snapshot`
- **workspace_id:** `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`
- **priority:** `2`
- **version:** `1`
- **created_at:** `2026-03-06T21:24:14.024128+00:00`
- **updated_at:** `2026-03-06T21:24:14.024128+00:00`
- **semantic_type_id:** `02d3ff65-c86b-4c00-af32-209cb21134eb`
- **tags:** `system-state`, `kernel`, `governance`, `snapshot`

---

## Timestamp Context

Post Gateway Operations v4 deployment with T87 spine mutability and lifecycle governance active.

---

## System Identity

- **system:** Qwrk@Work
- **workspace_id:** `635bb8d7-7b93-4bea-8ca6-ee2c924c9557`
- **gateway_version:** `v59`
- **ddl_version:** `v2.6`
- **execution_surface:** QSB (Chrome Extension) + Gateway

---

## Core Execution Model

- **execution_interface:** PrimeExecutionObject via QSB
- **marker:** `prime-exec`
- **payload_structure:** single JSON object per execution
- **execution_rule:** one payload per response, stop after emission
- **workspace_lock:** absolute

---

## Artifact Model

### Top-Level Types
- `project`
- `journal`
- `snapshot`
- `restart`

### Execution Types
- `branch`
- `limb`
- `leaf`

### Exploration Types
- `twig`

### Governance Types
- `instruction_pack`

---

## Semantic Type Registry

- **enforced:** `true`

### Required For
- `project`
- `journal`
- `snapshot`
- `restart`

### Forbidden For
- `branch`
- `limb`
- `leaf`
- `twig`
- `instruction_pack`

### Active Types
- `execution-core`
- `governance`
- `infrastructure`
- `platform`
- `product`
- `alignment`
- `sales`
- `marketing`
- `exploratory`

---

## Lifecycle Model

### Project Stages
- `seed`
- `sapling`
- `tree`
- `archive`

### Twig Stages
- `proposed`
- `active`
- `promoted`
- `pruned`

### Promotion Rules
- **seed_to_sapling:** requires summary OR journal child
- **sapling_to_tree:** requires branch OR leaf child
- **tree_to_archive:** no guard

---

## Mutability Governance

- **t87_enabled:** `true`

### Spine Fields
- `title`
- `summary`
- `priority`

### Mutability Matrix
- **seed:** fully mutable
- **sapling:** fully mutable
- **tree:** title frozen
- **archive:** fully immutable

---

## Update Modes
- `spine_only`
- `mixed`
- `tags_only`
- `semantic_type`
- `extension`

---

## Journal Doctrine

- **mutation_rule:** `insert_only`
- **extension_update_error:** `JOURNAL_INSERT_ONLY`

---

## Execution Doctrine

- **single_payload_rule:** `true`
- **no_uuid_invention:** `true`
- **confirm_artifact_id_before_followups:** `true`

---

## Instruction Pack Inventory
- Gateway Operations v4
- Execution Patterns v2
- Lifecycle Guide v3
- QSB Payload Format v2
- Cognitive Protocol v1
- Journal Mode Instructions v1.1
- Conversation Restart Protocol
- Workflow Patterns
- Quick Reference

---

## System Characteristics
- deterministic artifact operations
- semantic classification enforcement
- lifecycle governance
- instruction-pack authority
- execution-surface routing
- cognitive operating protocol

---

## Intent of Snapshot

Capture the full operational capability of the Qwrk@Work kernel after T87 deployment so the system architecture, governance rules, and execution model can be reconstructed later.

