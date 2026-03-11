# CC Prompt — T107 Mobile Gateway Access (Phase 1)

Build request for **T107 — Mobile Gateway Access — Phone Execution Surface**.

## Objective
Create a **minimal mobile execution console inside n8n** that allows raw Gateway payload execution from a phone browser when Telegram or other transport layers are unavailable.

This is strictly **Phase 1** of T107.

The mobile surface must remain a **thin transport layer**. It must not implement business logic, workspace routing logic, lifecycle logic, or mutation logic. **Gateway remains the execution engine and enforcement boundary.**

## Done Means
The system is complete when:

1. Visiting the console URL on a phone loads a simple mobile-friendly page.
2. The page provides a payload textarea, execute button, response display, and **Copy Response** button.
3. The page pretty-displays the JSON response for readability.
4. The Copy Response button copies the **raw JSON response** exactly as returned so it can be pasted back into Q.
5. The browser remembers the **last payload** in local storage and restores it on reload.
6. Payload execution works for **any workspace** using the provided `gw_workspace_id` in the payload.
7. The mobile surface does **not** ask the user to choose a workspace.
8. Requests without a valid `X-QWRK-KEY` header are rejected.
9. Invalid JSON returns a clean error response instead of crashing or failing unclearly.
10. A lightweight diagnostic action/path exists so the operator can verify the transport chain is alive.

## Architecture Constraints (Non-Negotiable)
- Build this **entirely inside the existing n8n VPS**.
- No additional hosting, app framework, React Native app, or external service.
- Keep the console extremely thin.
- The console must **not** rewrite or infer `gw_workspace_id`.
- The console must **not** implement Qwrk business rules.
- The console simply transports payloads and renders responses.
- Gateway remains the sole enforcement layer for workspace scope, governance, routing, and artifact behavior.

## Key Design Decisions Locked
### 1. Two-endpoint structure
Use separate endpoints:

- `GET /qwrk-mobile` → serve the console page
- `POST /qwrk-mobile/execute` → execute payloads

Reason: cleaner separation of concerns, safer execution boundary, easier observability/logging, and better Phase 2 expansion path.

### 2. Workspace routing
The console must not present a workspace selector.

Routing is handled exclusively by the existing payload field:

- `gw_workspace_id`

The workflow must pass the payload unchanged to Gateway.

### 3. Security model
Use a required HTTP header:

- `X-QWRK-KEY: <secret>`

Store the secret in environment/config, not inline in the page source if avoidable. If the page must embed it for MVP execution from the browser, call that out explicitly as a tradeoff and propose the cleanest minimally acceptable implementation.

### 4. Response ergonomics
The page should:
- pretty-display JSON for readability
- provide a **Copy Response** button that copies the raw JSON string exactly
- show a small success toast/message after copy

### 5. Payload persistence
Use browser local storage to remember the last payload entered.

### 6. Diagnostic capability
Include a minimal diagnostic capability so the operator can verify the chain is alive.

Preferred approach:
- support a simple diagnostic action such as `system.ping` **if and only if** that fits cleanly within the existing Gateway architecture

If `system.ping` would require touching canonical Gateway behavior in a way that is too heavy for this thread, propose the smallest alternative diagnostic path that still validates the mobile surface + n8n execution transport.

## Scope
### In Scope
- n8n workflow design for GET console + POST execute
- HTML/CSS/JS mobile console served from n8n
- auth header validation
- JSON validation
- Gateway execution routing
- pretty response rendering
- raw response copying
- local storage last-payload restore
- explicit method guards / clean errors
- minimal diagnostic path

### Explicitly Out of Scope
- payload history
- quick templates
- CmdCtr signals
- rich response inspection panels
- error highlighting beyond basic readable output
- workspace switching UI
- PWA packaging
- app-store/mobile-native implementation
- idempotency system / `gw_request_id`
- TOTP, payload signing, IP allow-listing

## Acceptance Criteria / Verification
Please implement or specify how to verify all of the following:

1. `GET /qwrk-mobile` returns the mobile console page.
2. `POST /qwrk-mobile/execute` rejects missing or invalid `X-QWRK-KEY` with 401.
3. Invalid JSON returns a clean 400-style error response.
4. Valid Gateway payload executes successfully and returns the response.
5. Response is pretty-rendered in the browser.
6. Copy Response copies the raw response exactly.
7. The last payload is restored on refresh from local storage.
8. The UI shows the detected `gw_workspace_id` and `gw_action` from the submitted payload or returned response for operator visibility.
9. The execution endpoint supports any workspace as long as the payload includes `gw_workspace_id` and Gateway permits it.
10. The diagnostic path works.

## Implementation Guidance
Please produce the deliverable in this order:

### Step 1 — Plan
Confirm understanding and propose the exact implementation plan.

### Step 2 — Security note
Explicitly call out how the browser-side page will authenticate POST requests to `/qwrk-mobile/execute`, including any tradeoffs if the secret is embedded client-side for MVP.

### Step 3 — Workflow design
Provide the exact n8n workflow structure:
- nodes
- request flow
- method branching
- auth check
- JSON validation
- Gateway handoff
- response shaping

### Step 4 — HTML console
Provide the exact HTML/JS/CSS needed for the mobile page.

### Step 5 — Verification plan
Provide exact manual tests.

## Output Format
Default output contract:
- Summary
- Plan
- Risks
- Next Action

## Important Risks to Think Through Before Coding
Please explicitly reason through these before implementation:

1. **Browser auth tradeoff** — if the page is served directly to the phone and then POSTs from browser JS, where does the `X-QWRK-KEY` live, and is that acceptable for this MVP?
2. **Single workflow vs two workflows** — we want one logical mobile console system, but confirm whether GET and POST are cleaner inside one n8n workflow or two linked workflows.
3. **Diagnostic design** — confirm whether `system.ping` is the right path or whether a transport-level health check is cleaner for this phase.
4. **Raw copy fidelity** — ensure pretty display does not alter the copied response.

## Final Instruction
Do not expand scope. Keep this operator-grade, minimal, and resilient.

Confirm understanding and propose the implementation plan before making changes.

