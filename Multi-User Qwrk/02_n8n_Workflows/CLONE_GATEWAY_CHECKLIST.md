# Clone Gateway Checklist — Per-Gateway Execution Steps

**Purpose:** Step-by-step checklist for cloning `NQxb_Gateway_v1__ACL_Test.json` into a workspace-specific gateway.

**Repeat this checklist for each of the 4 target gateways.**

---

## Pre-Clone Requirements

- [ ] Basic Auth credential created in n8n for this gateway's principal
- [ ] Workspace UUID confirmed (from `WORKSPACE_REGISTRY_TRACKING.md`)
- [ ] ACL row seeded for this principal × workspace

---

## Clone Steps

### Step 1: Prepare Working Copy

- [ ] Copy `workflows/NQxb_Gateway_v1__ACL_Test.json` to working location
- [ ] Rename file: `NQxb_Gateway_v1__{{short_name}}.json`

### Step 2: Update Workflow Name

Find and replace in JSON:
```
"name": "NQxb_Gateway_v1__ACL_Test"
```
Replace with:
```
"name": "NQxb_Gateway_v1__{{GatewayName}}"
```

### Step 3: Update Webhook Path

In `NQxb_Gateway_v1__Webhook_In` node, find:
```
"path": "/nqxb/gateway/v1/acl-test"
```
Replace with:
```
"path": "/nqxb/gateway/v1/{{short_name}}"
```

### Step 4: Update Webhook Credential

In `NQxb_Gateway_v1__Webhook_In` node, find:
```json
"credentials": {
  "httpBasicAuth": {
    "id": "jTp4W3tGrw2s036g",
    "name": "Qwrk Ingest Basic Auth"
  }
}
```
Replace with:
```json
"credentials": {
  "httpBasicAuth": {
    "id": "{{credential_id}}",
    "name": "Qwrk Gateway — {{GatewayName}}"
  }
}
```

### Step 5: Update Gatekeeper OWNER_WORKSPACE_ID

In `NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly` node jsCode, find:
```javascript
const OWNER_WORKSPACE_ID = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a";
```
Replace with:
```javascript
const OWNER_WORKSPACE_ID = "{{workspace_uuid}}";
```

### Step 6: Update ACL_Lookup Principal

In `NQxb_Gateway_v1__ACL_Lookup` node URL, find:
```
principal_name=eq.qwrk-gateway
```
Replace with:
```
principal_name=eq.{{principal_name}}
```

**Do NOT change the Supabase credential** (`n4R4JdOIV9zrCGIT`) — this is the shared service_role key for ACL table access.

### Step 7: Clear Pinned Test Data (Optional)

- [ ] Remove `pinData` section from JSON (or update with clone-specific test data)
- Note: Pinned data references Joel's workspace UUID — may cause confusion if left

### Step 8: Import to n8n

- [ ] Open n8n → Workflows → Import from File
- [ ] Select the modified JSON file
- [ ] Confirm workflow appears with correct name

### Step 9: Activate

- [ ] Toggle workflow to Active
- [ ] Confirm webhook URL is generated
- [ ] Record webhook URL in `WORKSPACE_REGISTRY_TRACKING.md`

### Step 10: Verify

- [ ] Run Test 1 (allowed workspace → 200)
- [ ] Run Test 2 (wrong workspace → 403)
- [ ] Run Test 3 (malformed request → error)

---

## Quick Reference: Values Per Gateway

| Field | Qwrk@Work_Joel | Akara_Blagg | BlaggLife | Krista_Blagg |
|-------|----------------|-------------|-----------|-------------|
| GatewayName | Work_Joel | Akara | BlaggLife | Krista |
| short_name | work | akara | blagglife | krista |
| principal_name | qwrk-gw-work | qwrk-gw-akara | qwrk-gw-blagglife | qwrk-gw-krista |
| workspace_uuid | `{{TBD}}` | `{{TBD}}` | `b4e7f648-...` | `{{TBD}}` |
| credential_id | `{{TBD}}` | `{{TBD}}` | `{{TBD}}` | `{{TBD}}` |

---

## Nodes That Change (Summary)

| Node | Field | Change |
|------|-------|--------|
| Webhook_In | `path` | Unique per clone |
| Webhook_In | `credentials.httpBasicAuth` | Clone's credential |
| Gatekeeper | `OWNER_WORKSPACE_ID` in jsCode | Clone's workspace UUID |
| ACL_Lookup | `principal_name=eq.` in URL | Clone's principal |

**All other nodes remain unchanged.**
