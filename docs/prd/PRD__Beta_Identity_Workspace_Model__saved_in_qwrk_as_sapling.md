PRD — Beta Identity & Workspace Model for Qwrk

## 1. Context
Qwrk will launch an **initial private beta** with multiple users but **no paid plans** and **no collaboration requirement on day one**.  
Despite being free, the system must support:
- Clear user identity
- Attribution of actions and artifacts
- Safe isolation between users
- A clean path to future collaboration and monetization

The Custom GPT will be the primary UI during beta.

---

## 2. Decision Summary (Locked for Beta)

### Identity
- **OAuth-based authentication is required from day one**
- Users authenticate via browser redirect (not inside chat)
- Each authenticated user maps to a stable internal `qwrk_user_id`

### Workspace Model (Beta)
- **Option A selected**:  
  **One personal workspace per user**
- Each user is automatically provisioned a single workspace on first login
- All artifacts for that user live exclusively in their workspace
- No user belongs to more than one workspace during initial beta

### Collaboration
- **Not required for initial beta**
- No shared trees, no multi-user editing
- Collaboration will be introduced later via shared workspaces

---

## 3. Beta Architecture Rules

### Workspace Resolution
- Gateway resolves workspace strictly as: