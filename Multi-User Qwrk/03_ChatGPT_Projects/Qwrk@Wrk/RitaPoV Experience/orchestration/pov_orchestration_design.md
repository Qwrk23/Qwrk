# PoV Orchestration Layer -- n8n Workflow Design

> **Status:** Build-ready design  
> **Version:** v1  
> **Date:** 2026-04-01  
> **Scenario file:** `servicenow_scenario_v1.json`

---

## Overview

This document defines the n8n workflow that orchestrates the Guided PoV Experience. The workflow manages session state and step progression across three webhook endpoints, serving structured step data to a Chrome side panel extension.

The workflow is self-contained: the ServiceNow scenario JSON is embedded directly as a Set node (no external fetch). Session state is stored in n8n static variables at the workflow level.

---

## Architecture Summary

```
Chrome Side Panel
    |
    |-- POST /webhook/pov/start     --> Initialize session, return first step
    |-- POST /webhook/pov/next      --> Advance step, return current step
    |-- POST /webhook/pov/complete   --> Mark complete, return summary
    |
n8n Workflow (PoV_Orchestrator)
    |
    |-- Static Variables (session state)
    |-- Embedded Scenario (Set node)
```

---

## Webhook Endpoints

### 1. `POST /webhook/pov/start`

**Purpose:** Initialize a new PoV session and return the first step.

**Request body:**
```json
{
  "scenario_id": "servicenow-agent-assist-v1"
}
```

**Response (200):**
```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "scenario_name": "ServiceNow Agent Assist with Rita",
  "total_steps": 6,
  "current_step": {
    "step_id": "sn-step-001",
    "type": "instruction",
    "title": "Welcome & Context",
    "description": "...",
    "ui": { "cta_label": "Get Started", "show_next": true },
    "action": { "endpoint": null, "method": null, "payload": {} },
    "completion": { "type": "manual", "success_signal": null },
    "value": { "message": null }
  }
}
```

### 2. `POST /webhook/pov/next`

**Purpose:** Advance to the next step and return it.

**Request body:**
```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d"
}
```

**Response (200) -- mid-scenario:**
```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "step_number": 2,
  "total_steps": 6,
  "current_step": { "...step object..." },
  "completed": false
}
```

**Response (200) -- final step already shown:**
```json
{
  "ok": false,
  "error": {
    "code": "NO_MORE_STEPS",
    "message": "All steps have been completed. Call /webhook/pov/complete to finalize the session."
  }
}
```

**Response (200) -- invalid session:**
```json
{
  "ok": false,
  "error": {
    "code": "SESSION_NOT_FOUND",
    "message": "No active session found for the provided session_id."
  }
}
```

### 3. `POST /webhook/pov/complete`

**Purpose:** Mark the session as complete and return a summary.

**Request body:**
```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d"
}
```

**Response (200):**
```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "completed": true,
  "summary": "PoV complete. You experienced Rita assisting a ServiceNow agent through a VPN incident -- from creation to resolution. Key value: faster resolution, consistent quality, reduced training burden, and measurable ROI."
}
```

**Response (200) -- invalid session:**
```json
{
  "ok": false,
  "error": {
    "code": "SESSION_NOT_FOUND",
    "message": "No active session found for the provided session_id."
  }
}
```

---

## Session State Management

### Storage Mechanism

Session state is stored in **n8n workflow-level static variables** via `$getWorkflowStaticData('global')`.

This is a key-value store scoped to the workflow instance. It persists across executions but is cleared on workflow re-import or n8n restart (acceptable for PoV -- sessions are short-lived).

### State Shape

Each session is stored under key `session:<session_id>`:

```json
{
  "session_id": "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "scenario_id": "servicenow-agent-assist-v1",
  "current_step_index": 0,
  "started_at": "2026-04-01T14:30:00.000Z",
  "status": "in_progress"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `session_id` | string (UUID v4) | Unique session identifier |
| `scenario_id` | string | References the embedded scenario |
| `current_step_index` | number | Zero-based index into scenario.steps array |
| `started_at` | string (ISO 8601) | Session creation timestamp |
| `status` | string | `in_progress` or `completed` |

### Session ID Generation

`crypto.randomUUID()` is **blocked** in n8n Code nodes. Use the following `Math.random`-based UUID v4 fallback:

```javascript
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}
```

---

## Scenario Storage

### Approach

v1 uses an **embedded scenario** -- the full ServiceNow scenario JSON is stored in a Set node within the workflow. No external database fetch or file read.

### Scenario Schema

```json
{
  "scenario_id": "string",
  "name": "string",
  "persona": "string",
  "steps": [
    {
      "step_id": "string",
      "type": "instruction | action | observation | explanation",
      "title": "string",
      "description": "string",
      "ui": {
        "cta_label": "string",
        "show_next": true
      },
      "action": {
        "endpoint": "string | null",
        "method": "POST | GET | null",
        "payload": {}
      },
      "completion": {
        "type": "manual | api_response",
        "success_signal": "string | null"
      },
      "value": {
        "message": "string | null"
      }
    }
  ]
}
```

The canonical scenario file lives at `servicenow_scenario_v1.json` alongside this document. Its contents are copied into the Set node verbatim.

---

## n8n Workflow Node Design

### Node Inventory

| # | Node Name | Node Type | Purpose |
|---|-----------|-----------|---------|
| 1 | `PoV_Webhook_Start` | Webhook | Receives POST /webhook/pov/start |
| 2 | `PoV_Webhook_Next` | Webhook | Receives POST /webhook/pov/next |
| 3 | `PoV_Webhook_Complete` | Webhook | Receives POST /webhook/pov/complete |
| 4 | `PoV_Load_Scenario` | Set | Embeds the full scenario JSON |
| 5 | `PoV_Init_Session` | Code | Generates session_id, writes initial state to static data |
| 6 | `PoV_Build_Start_Response` | Code | Constructs start response with first step |
| 7 | `PoV_Respond_Start` | Respond to Webhook | Returns start response to caller |
| 8 | `PoV_Lookup_Session` | Code | Reads session state from static data, validates |
| 9 | `PoV_Validate_Next` | IF | Checks if more steps remain |
| 10 | `PoV_Advance_Step` | Code | Increments current_step_index, updates static data |
| 11 | `PoV_Build_Next_Response` | Code | Constructs next response with current step |
| 12 | `PoV_Build_Next_Error` | Set | Constructs NO_MORE_STEPS or SESSION_NOT_FOUND error |
| 13 | `PoV_Respond_Next` | Respond to Webhook | Returns next response to caller |
| 14 | `PoV_Lookup_Session_Complete` | Code | Reads session state for complete endpoint |
| 15 | `PoV_Mark_Complete` | Code | Sets session status to completed |
| 16 | `PoV_Build_Complete_Response` | Code | Constructs completion summary |
| 17 | `PoV_Build_Complete_Error` | Set | Constructs SESSION_NOT_FOUND error |
| 18 | `PoV_Respond_Complete` | Respond to Webhook | Returns complete response to caller |

### Detailed Node Specifications

---

#### Node 1: `PoV_Webhook_Start`

- **Type:** Webhook
- **HTTP Method:** POST
- **Path:** `pov/start`
- **Response Mode:** `responseNode` (deferred to PoV_Respond_Start)
- **Purpose:** Entry point for session initialization
- **Output:** `{ body: { scenario_id: "servicenow-agent-assist-v1" } }`
- **Connects to:** `PoV_Load_Scenario`

---

#### Node 2: `PoV_Webhook_Next`

- **Type:** Webhook
- **HTTP Method:** POST
- **Path:** `pov/next`
- **Response Mode:** `responseNode` (deferred to PoV_Respond_Next)
- **Purpose:** Entry point for step advancement
- **Output:** `{ body: { session_id: "..." } }`
- **Connects to:** `PoV_Lookup_Session`

---

#### Node 3: `PoV_Webhook_Complete`

- **Type:** Webhook
- **HTTP Method:** POST
- **Path:** `pov/complete`
- **Response Mode:** `responseNode` (deferred to PoV_Respond_Complete)
- **Purpose:** Entry point for session completion
- **Output:** `{ body: { session_id: "..." } }`
- **Connects to:** `PoV_Lookup_Session_Complete`

---

#### Node 4: `PoV_Load_Scenario`

- **Type:** Set
- **Purpose:** Embeds the full ServiceNow scenario JSON as a workflow constant
- **Configuration:** A single field `scenario` of type JSON, containing the verbatim contents of `servicenow_scenario_v1.json`
- **Output:**
```json
{
  "scenario": { "scenario_id": "...", "name": "...", "persona": "...", "steps": [...] }
}
```
- **Connects to:** `PoV_Init_Session`
- **Note:** This node is the single source for scenario data. To update the scenario, update this node's JSON value and re-save the workflow.

---

#### Node 5: `PoV_Init_Session`

- **Type:** Code (JavaScript)
- **Purpose:** Generate a session ID, store initial session state in workflow static data
- **Input:** Scenario object from PoV_Load_Scenario
- **Code:**
```javascript
const scenario = $input.first().json.scenario;

// UUID v4 fallback (crypto.randomUUID blocked in n8n)
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

const sessionId = generateUUID();
const staticData = $getWorkflowStaticData('global');

staticData[`session:${sessionId}`] = {
  session_id: sessionId,
  scenario_id: scenario.scenario_id,
  current_step_index: 0,
  started_at: new Date().toISOString(),
  status: 'in_progress'
};

return [{
  json: {
    session_id: sessionId,
    scenario: scenario
  }
}];
```
- **Output:** `{ session_id, scenario }`
- **Connects to:** `PoV_Build_Start_Response`

---

#### Node 6: `PoV_Build_Start_Response`

- **Type:** Code (JavaScript)
- **Purpose:** Construct the start response payload with the first step
- **Input:** session_id and scenario from PoV_Init_Session
- **Code:**
```javascript
const { session_id, scenario } = $input.first().json;

return [{
  json: {
    session_id: session_id,
    scenario_name: scenario.name,
    total_steps: scenario.steps.length,
    current_step: scenario.steps[0]
  }
}];
```
- **Output:** Start response object (see Response Contracts above)
- **Connects to:** `PoV_Respond_Start`

---

#### Node 7: `PoV_Respond_Start`

- **Type:** Respond to Webhook
- **Purpose:** Send the start response back to the caller
- **Configuration:**
  - Response Code: 200
  - Response Headers: `Content-Type: application/json`
  - Response Body: `{{ $json }}` (the full output from PoV_Build_Start_Response)
- **Connects to:** (terminal)

---

#### Node 8: `PoV_Lookup_Session`

- **Type:** Code (JavaScript)
- **Purpose:** Look up session state from static data for the /next endpoint. Returns error payload if session not found or already completed.
- **Input:** `{ body: { session_id: "..." } }` from webhook
- **Code:**
```javascript
const sessionId = $input.first().json.body.session_id;
const staticData = $getWorkflowStaticData('global');
const session = staticData[`session:${sessionId}`];

if (!session) {
  return [{
    json: {
      _valid: false,
      ok: false,
      error: {
        code: 'SESSION_NOT_FOUND',
        message: 'No active session found for the provided session_id.'
      }
    }
  }];
}

if (session.status === 'completed') {
  return [{
    json: {
      _valid: false,
      ok: false,
      error: {
        code: 'SESSION_COMPLETED',
        message: 'This session has already been completed.'
      }
    }
  }];
}

return [{
  json: {
    _valid: true,
    session: session
  }
}];
```
- **Output:** `{ _valid: true, session: {...} }` or `{ _valid: false, ok: false, error: {...} }`
- **Connects to:** `PoV_Validate_Next`

---

#### Node 9: `PoV_Validate_Next`

- **Type:** IF
- **Purpose:** Route to step advancement or error response based on session lookup result
- **Condition:** `{{ $json._valid }}` equals `true`
- **True branch:** `PoV_Advance_Step`
- **False branch:** `PoV_Build_Next_Error`

---

#### Node 10: `PoV_Advance_Step`

- **Type:** Code (JavaScript)
- **Purpose:** Increment the step index, check bounds, update static data, load scenario for step retrieval
- **Input:** Valid session from PoV_Lookup_Session (via PoV_Validate_Next true branch)
- **Code:**
```javascript
const session = $input.first().json.session;
const staticData = $getWorkflowStaticData('global');

// Load scenario from the static data or re-embed
// For v1, the scenario is re-loaded inline since Set node data
// doesn't flow through the /next path. Embed scenario steps here.
const scenarioSteps = staticData['scenario_steps'];

const nextIndex = session.current_step_index + 1;

if (nextIndex >= scenarioSteps.length) {
  return [{
    json: {
      _has_next: false,
      ok: false,
      error: {
        code: 'NO_MORE_STEPS',
        message: 'All steps have been completed. Call /webhook/pov/complete to finalize the session.'
      }
    }
  }];
}

// Update session state
staticData[`session:${session.session_id}`].current_step_index = nextIndex;

return [{
  json: {
    _has_next: true,
    session_id: session.session_id,
    step_number: nextIndex + 1,
    total_steps: scenarioSteps.length,
    current_step: scenarioSteps[nextIndex],
    completed: false
  }
}];
```
- **Output:** Next response object or NO_MORE_STEPS error
- **Connects to:** `PoV_Build_Next_Response`

**Important -- Scenario Availability on /next Path:**

The `/next` webhook path does not flow through `PoV_Load_Scenario`. The scenario steps must be accessible from static data. To solve this, `PoV_Init_Session` should ALSO write the scenario steps to static data:

```javascript
// Add to PoV_Init_Session code:
staticData['scenario_steps'] = scenario.steps;
```

This ensures `PoV_Advance_Step` can read `staticData['scenario_steps']` without needing the Set node in the /next path.

---

#### Node 11: `PoV_Build_Next_Response`

- **Type:** Code (JavaScript)
- **Purpose:** Pass through the response from PoV_Advance_Step (already shaped correctly)
- **Input:** Output from PoV_Advance_Step
- **Code:**
```javascript
const data = $input.first().json;

// If it was a NO_MORE_STEPS error, pass through as-is
if (!data._has_next) {
  const { _has_next, ...response } = data;
  return [{ json: response }];
}

// Otherwise, strip internal flag and pass through
const { _has_next, ...response } = data;
return [{ json: response }];
```
- **Output:** Clean response (internal `_has_next` flag removed)
- **Connects to:** `PoV_Respond_Next`

---

#### Node 12: `PoV_Build_Next_Error`

- **Type:** Set
- **Purpose:** Pass through the error payload from PoV_Lookup_Session (SESSION_NOT_FOUND or SESSION_COMPLETED)
- **Configuration:** Forward `ok` and `error` fields from input, stripping `_valid` flag
- **Fields:**
  - `ok`: `{{ $json.ok }}`
  - `error`: `{{ $json.error }}`
- **Connects to:** `PoV_Respond_Next`

---

#### Node 13: `PoV_Respond_Next`

- **Type:** Respond to Webhook
- **Purpose:** Send the next/error response back to the caller
- **Configuration:**
  - Response Code: 200
  - Response Headers: `Content-Type: application/json`
  - Response Body: `{{ $json }}`
- **Connects to:** (terminal)
- **Note:** Both the success path (via PoV_Build_Next_Response) and error path (via PoV_Build_Next_Error) converge here.

---

#### Node 14: `PoV_Lookup_Session_Complete`

- **Type:** Code (JavaScript)
- **Purpose:** Look up session state for the /complete endpoint
- **Input:** `{ body: { session_id: "..." } }` from webhook
- **Code:**
```javascript
const sessionId = $input.first().json.body.session_id;
const staticData = $getWorkflowStaticData('global');
const session = staticData[`session:${sessionId}`];

if (!session) {
  return [{
    json: {
      _valid: false,
      ok: false,
      error: {
        code: 'SESSION_NOT_FOUND',
        message: 'No active session found for the provided session_id.'
      }
    }
  }];
}

return [{
  json: {
    _valid: true,
    session: session
  }
}];
```
- **Output:** `{ _valid: true, session: {...} }` or `{ _valid: false, ok: false, error: {...} }`
- **Connects to:** `PoV_Validate_Complete` (IF node -- if you want to split, or inline in PoV_Mark_Complete)

**Simplification note:** Since the complete path is simpler (no step arithmetic), the validation can be handled inline. The IF split is optional. The design below uses inline validation in `PoV_Mark_Complete` with a direct branch to error.

For clarity, use an IF node:

**Node 14b: `PoV_Validate_Complete`**
- **Type:** IF
- **Condition:** `{{ $json._valid }}` equals `true`
- **True branch:** `PoV_Mark_Complete`
- **False branch:** `PoV_Build_Complete_Error`

---

#### Node 15: `PoV_Mark_Complete`

- **Type:** Code (JavaScript)
- **Purpose:** Set session status to completed, build scenario name for summary
- **Input:** Valid session from PoV_Lookup_Session_Complete
- **Code:**
```javascript
const session = $input.first().json.session;
const staticData = $getWorkflowStaticData('global');

// Mark session as completed
staticData[`session:${session.session_id}`].status = 'completed';

return [{
  json: {
    session_id: session.session_id,
    scenario_id: session.scenario_id
  }
}];
```
- **Output:** `{ session_id, scenario_id }`
- **Connects to:** `PoV_Build_Complete_Response`

---

#### Node 16: `PoV_Build_Complete_Response`

- **Type:** Code (JavaScript)
- **Purpose:** Construct the completion summary response
- **Input:** session_id and scenario_id from PoV_Mark_Complete
- **Code:**
```javascript
const { session_id, scenario_id } = $input.first().json;

// Summary is scenario-specific. For v1, hardcoded for ServiceNow scenario.
const summaries = {
  'servicenow-agent-assist-v1': 'PoV complete. You experienced Rita assisting a ServiceNow agent through a VPN incident -- from creation to resolution. Key value: faster resolution, consistent quality, reduced training burden, and measurable ROI.'
};

const summary = summaries[scenario_id] || 'PoV session complete.';

return [{
  json: {
    session_id: session_id,
    completed: true,
    summary: summary
  }
}];
```
- **Output:** Complete response object (see Response Contracts above)
- **Connects to:** `PoV_Respond_Complete`

---

#### Node 17: `PoV_Build_Complete_Error`

- **Type:** Set
- **Purpose:** Pass through SESSION_NOT_FOUND error
- **Configuration:** Forward `ok` and `error` fields, strip `_valid`
- **Fields:**
  - `ok`: `{{ $json.ok }}`
  - `error`: `{{ $json.error }}`
- **Connects to:** `PoV_Respond_Complete`

---

#### Node 18: `PoV_Respond_Complete`

- **Type:** Respond to Webhook
- **Purpose:** Send the complete/error response back to the caller
- **Configuration:**
  - Response Code: 200
  - Response Headers: `Content-Type: application/json`
  - Response Body: `{{ $json }}`
- **Connects to:** (terminal)

---

## Workflow Connection Map

```
/start path:
  PoV_Webhook_Start --> PoV_Load_Scenario --> PoV_Init_Session --> PoV_Build_Start_Response --> PoV_Respond_Start

/next path:
  PoV_Webhook_Next --> PoV_Lookup_Session --> PoV_Validate_Next
    |-- true  --> PoV_Advance_Step --> PoV_Build_Next_Response --> PoV_Respond_Next
    |-- false --> PoV_Build_Next_Error --------------------------> PoV_Respond_Next

/complete path:
  PoV_Webhook_Complete --> PoV_Lookup_Session_Complete --> PoV_Validate_Complete
    |-- true  --> PoV_Mark_Complete --> PoV_Build_Complete_Response --> PoV_Respond_Complete
    |-- false --> PoV_Build_Complete_Error -----------------------------> PoV_Respond_Complete
```

---

## n8n Constraints Applied

| Constraint | How Applied |
|-----------|-------------|
| `crypto.randomUUID()` blocked | Using `Math.random`-based UUID v4 fallback in `PoV_Init_Session` |
| `$env.*` blocked | No env vars used; scenario embedded directly |
| No leading `=` in expressions | All expressions written without leading `=` |
| Supabase nodes are dumb writers | No Supabase nodes used (v1 uses static data only) |
| Execute Workflow runs saved version | Single workflow -- no sub-workflow calls. Reminder: save after every edit. |

---

## CORS Configuration

The Chrome side panel runs as a browser extension, which means webhook calls originate from the extension's service worker or content script. n8n webhooks accept POST by default. If the side panel uses `fetch()` from a content script:

- **Extension service workers:** No CORS restrictions (not subject to browser CORS policy)
- **Extension content scripts making fetch to n8n:** May require CORS headers depending on manifest permissions

**Recommendation:** Configure n8n webhook nodes to include `Access-Control-Allow-Origin: *` in response headers, or handle CORS at the n8n reverse proxy level. For PoV purposes, extension permissions (`host_permissions` in manifest) should cover the n8n webhook URL.

---

## Future Enhancements (Out of Scope for v1)

- **Persistent session storage:** Move from static data to database (Supabase `qxb_artifact` or dedicated table)
- **Multiple scenarios:** Dynamic scenario loading from external source instead of embedded Set node
- **Step completion tracking:** Record which steps were completed vs skipped
- **Analytics:** Track time-per-step, drop-off points, completion rates
- **Authentication:** Require bearer token or API key for webhook access

---

## Build Checklist

1. [ ] Create new n8n workflow named `PoV_Orchestrator`
2. [ ] Add three Webhook nodes (start, next, complete) with correct paths
3. [ ] Configure all webhooks with Response Mode: `responseNode`
4. [ ] Add PoV_Load_Scenario Set node with full JSON from `servicenow_scenario_v1.json`
5. [ ] Add all Code nodes with the JavaScript from this document
6. [ ] Add IF nodes for validation branching
7. [ ] Add Respond to Webhook nodes at each path terminal
8. [ ] Wire connections per the Connection Map above
9. [ ] Save workflow (Execute Workflow runs saved version only)
10. [ ] Activate workflow
11. [ ] Test all three endpoints with curl or Postman
12. [ ] Verify error responses for invalid session_id and past-end advancement
