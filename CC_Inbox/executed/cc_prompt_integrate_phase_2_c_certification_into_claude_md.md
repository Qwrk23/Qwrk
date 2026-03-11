# PROMPT — Integrate Phase 2C Certification Harness into claude.md (Governance Section Update)

## INTENT
Update `claude.md` to formally integrate the Phase 2C Black-Box Certification Harness into the deployment governance section.

This is a documentation update only.

Do NOT:
- Modify workflows
- Modify database
- Modify registry
- Modify MEMORY.md
- Execute certification
- Deploy anything

Update file only.

---

## TARGET FILE

C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\claude.md

---

## REQUIRED CHANGE

Locate the Deployment / Governance section of `claude.md`.

Integrate the following structured subsection under deployment governance rules (do not append randomly; integrate into the appropriate governance area).

---

## Phase 2C — Certification Harness (Gateway Contract Protection)

**Purpose**  
Black-box regression harness validating Gateway + Save + Update + Promote contract surfaces.

**Harness Location**  
C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Phase2C_Cert\Run-Phase2C-Cert.ps1

**Scope**  
- Gateway boundary behavior  
- Save normalization logic  
- Update mutation determinism  
- Promote lifecycle enforcement  
- Immutability enforcement  
- Error contract stability

**PASS Standard**  
- 100% tests passing  
- 0 systemic failures  
- 0 nondeterministic behavior  
- 0 contract drift  

**When To Run (Current Phase — Qwrk Prime)**  
Run after any change to:
- Gateway
- Save
- Update
- Promote
- Registry / lifecycle logic

Mandatory gating is deferred until QBeta Dev/Prod environment is stood up.

**Future State (QBeta Launch)**  
Certification becomes a required deployment gate prior to promotion from Dev → Prod.

---

## VALIDATION

After updating `claude.md`, return:
- A confirmation message
- A short diff summary of the inserted section

Do not execute any other action.

Update only.
