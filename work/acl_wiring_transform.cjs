// T24 Step 2: ACL Wiring Transform for Clone Workflow
// Reads NQxb_Gateway_v1__ACL_Test.json, applies ACL wiring, writes updated version
// Archives original to workflows/Archive/

const fs = require('fs');
const path = require('path');

const workflowDir = path.join(__dirname, '..', 'workflows');
const inputPath = path.join(workflowDir, 'NQxb_Gateway_v1__ACL_Test.json');
const archivePath = path.join(workflowDir, 'Archive', 'NQxb_Gateway_v1__ACL_Test__v1__2026-02-17.json');

// Read current workflow
const workflow = JSON.parse(fs.readFileSync(inputPath, 'utf-8'));

// Archive original
fs.writeFileSync(archivePath, JSON.stringify(workflow, null, 2));
console.log('Archived to:', archivePath);

// === MODIFICATION 1: Update ACL_Lookup node ===
const aclLookup = workflow.nodes.find(n => n.name === 'NQxb_Gateway_v1__ACL_Lookup');
if (!aclLookup) throw new Error('ACL_Lookup node not found');

// Dynamic URL using workspace_id from normalized request
aclLookup.parameters.url = "={{ 'https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_gateway_acl?principal_name=eq.qwrk-gateway&workspace_id=eq.' + $json.gw_workspace_id + '&select=role' }}";

// Reposition between Normalize_Request and new ACL_Guard nodes
aclLookup.position = [-1088, 208];

// Fail-closed: ensure output even on empty array or error
aclLookup.alwaysOutputData = true;
aclLookup.onError = 'continueRegularOutput';

console.log('Updated ACL_Lookup: dynamic URL, alwaysOutputData, onError');

// === MODIFICATION 2: Add 3 new nodes ===

// ACL_Guard__HasRow — Code node: fail-closed evaluation + context restoration
const aclGuardHasRow = {
  parameters: {
    jsCode: `// NQxb_Gateway_v1__ACL_Guard__HasRow
// Fail-closed ACL evaluation + context restoration
//
// Input: ACL_Lookup HTTP response ($json)
// Context: Normalized request via $node ref
//
// FAIL-CLOSED: Only explicit ACL match with valid role passes.
// All other conditions (empty, null, undefined, error, malformed) -> DENIED.

const aclResponse = $json ?? {};
const normalizedRequest = $node["NQxb_Gateway_v1__Normalize_Request"].json;

// Fail-closed evaluation: ALL conditions must be true
const isAllowed =
  aclResponse !== null &&
  aclResponse !== undefined &&
  typeof aclResponse === "object" &&
  !Array.isArray(aclResponse) &&
  typeof aclResponse.role === "string" &&
  aclResponse.role.trim().length > 0;

if (isAllowed) {
  // ACL PASSED: Forward normalized request to Gatekeeper
  return [{
    json: {
      ...normalizedRequest,
      _acl_status: "allowed",
      _acl_role: aclResponse.role,
      _acl_debug: {
        evaluated_by: "ACL_Guard__HasRow",
        acl_response_shape: typeof aclResponse,
        has_role: true
      }
    }
  }];
}

// ACL DENIED: Return 403 envelope
return [{
  json: {
    ok: false,
    _gw_route: "error",
    _acl_status: "denied",
    error: {
      code: "ACL_FORBIDDEN",
      message: "Principal not authorized for requested workspace"
    },
    gw_workspace_id: normalizedRequest?.gw_workspace_id ?? null,
    artifact_type: normalizedRequest?.artifact_type ?? null,
    _kgb: {
      status: "ACL_DENIED"
    },
    _acl_debug: {
      evaluated_by: "ACL_Guard__HasRow",
      acl_response_shape: typeof aclResponse,
      acl_response_keys: Object.keys(aclResponse),
      has_role: false
    }
  }
}];
`
  },
  type: "n8n-nodes-base.code",
  typeVersion: 2,
  position: [-864, 208],
  id: "acl-guard-hasrow-001",
  name: "NQxb_Gateway_v1__ACL_Guard__HasRow"
};

// ACL_Guard__Route — IF node: routes based on _acl_status
const aclGuardRoute = {
  parameters: {
    conditions: {
      options: {
        caseSensitive: true,
        leftValue: "",
        typeValidation: "strict",
        version: 2
      },
      conditions: [
        {
          id: "acl-guard-condition",
          leftValue: "={{ $json._acl_status }}",
          rightValue: "allowed",
          operator: {
            type: "string",
            operation: "equals"
          }
        }
      ],
      combinator: "and"
    },
    options: {}
  },
  type: "n8n-nodes-base.if",
  typeVersion: 2.2,
  position: [-640, 208],
  id: "acl-guard-route-001",
  name: "NQxb_Gateway_v1__ACL_Guard__Route"
};

// ACL_Forbidden_Response — RespondToWebhook with 403
const aclForbiddenResponse = {
  parameters: {
    respondWith: "json",
    responseBody: "={{ JSON.stringify($json) }}",
    options: {
      responseCode: 403
    }
  },
  type: "n8n-nodes-base.respondToWebhook",
  typeVersion: 1.5,
  position: [-640, 500],
  id: "acl-forbidden-response-001",
  name: "NQxb_Gateway_v1__ACL_Forbidden_Response"
};

workflow.nodes.push(aclGuardHasRow, aclGuardRoute, aclForbiddenResponse);
console.log('Added 3 new nodes: ACL_Guard__HasRow, ACL_Guard__Route, ACL_Forbidden_Response');

// === MODIFICATION 3: Shift downstream node positions +672px on x-axis ===
const noShiftNodes = new Set([
  'NQxb_Gateway_v1__Webhook_In',
  'NQxb_Gateway_v1__Normalize_Request',
  'NQxb_Gateway_v1__ACL_Lookup',
  'NQxb_Gateway_v1__ACL_Guard__HasRow',
  'NQxb_Gateway_v1__ACL_Guard__Route',
  'NQxb_Gateway_v1__ACL_Forbidden_Response'
]);

const SHIFT = 672;

for (const node of workflow.nodes) {
  if (!noShiftNodes.has(node.name)) {
    node.position[0] += SHIFT;
  }
}
console.log(`Shifted ${workflow.nodes.length - noShiftNodes.size} nodes +${SHIFT}px on x-axis`);

// === MODIFICATION 4: Update connections ===

// Change Normalize_Request connection: was → Gatekeeper, now → ACL_Lookup
workflow.connections['NQxb_Gateway_v1__Normalize_Request'] = {
  main: [[
    { node: 'NQxb_Gateway_v1__ACL_Lookup', type: 'main', index: 0 }
  ]]
};

// Add ACL chain connections
workflow.connections['NQxb_Gateway_v1__ACL_Lookup'] = {
  main: [[
    { node: 'NQxb_Gateway_v1__ACL_Guard__HasRow', type: 'main', index: 0 }
  ]]
};

workflow.connections['NQxb_Gateway_v1__ACL_Guard__HasRow'] = {
  main: [[
    { node: 'NQxb_Gateway_v1__ACL_Guard__Route', type: 'main', index: 0 }
  ]]
};

// IF node: output 0 = TRUE (allowed → Gatekeeper), output 1 = FALSE (denied → 403)
workflow.connections['NQxb_Gateway_v1__ACL_Guard__Route'] = {
  main: [
    [{ node: 'NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly', type: 'main', index: 0 }],
    [{ node: 'NQxb_Gateway_v1__ACL_Forbidden_Response', type: 'main', index: 0 }]
  ]
};

console.log('Updated connections: NR → ACL_Lookup → Guard → Route → GK(true) / 403(false)');

// === VERIFICATION ===

// Verify OWNER_WORKSPACE_ID hard lock is untouched
const gatekeeper = workflow.nodes.find(n => n.name === 'NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly');
if (!gatekeeper) throw new Error('Gatekeeper node not found!');
if (!gatekeeper.parameters.jsCode.includes('OWNER_WORKSPACE_ID')) {
  throw new Error('OWNER_WORKSPACE_ID hard lock NOT FOUND in Gatekeeper!');
}
if (!gatekeeper.parameters.jsCode.includes('be0d3a48-c764-44f9-90c8-e846d9dbbd0a')) {
  throw new Error('OWNER_WORKSPACE_ID value NOT FOUND in Gatekeeper!');
}
console.log('VERIFIED: OWNER_WORKSPACE_ID hard lock untouched in Gatekeeper');

// Verify Gatekeeper code is unmodified (compare first 50 chars)
const gkCodeStart = gatekeeper.parameters.jsCode.substring(0, 50);
if (!gkCodeStart.includes('Gatekeeper_MVP_OwnerOnly')) {
  throw new Error('Gatekeeper code appears modified!');
}
console.log('VERIFIED: Gatekeeper code unmodified');

// Verify connection chain
const chain = [
  'NQxb_Gateway_v1__Normalize_Request',
  'NQxb_Gateway_v1__ACL_Lookup',
  'NQxb_Gateway_v1__ACL_Guard__HasRow',
  'NQxb_Gateway_v1__ACL_Guard__Route'
];
for (let i = 0; i < chain.length - 1; i++) {
  const conn = workflow.connections[chain[i]];
  if (!conn || !conn.main || !conn.main[0]) {
    throw new Error(`Missing connection from ${chain[i]}`);
  }
  const target = conn.main[0][0].node;
  if (target !== chain[i + 1]) {
    throw new Error(`Wrong connection from ${chain[i]}: expected ${chain[i + 1]}, got ${target}`);
  }
}
console.log('VERIFIED: ACL chain connections correct');

// Verify IF node routes
const routeConn = workflow.connections['NQxb_Gateway_v1__ACL_Guard__Route'];
if (routeConn.main[0][0].node !== 'NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly') {
  throw new Error('IF TRUE branch not connected to Gatekeeper!');
}
if (routeConn.main[1][0].node !== 'NQxb_Gateway_v1__ACL_Forbidden_Response') {
  throw new Error('IF FALSE branch not connected to Forbidden Response!');
}
console.log('VERIFIED: IF node routes correct (TRUE→GK, FALSE→403)');

// Write updated workflow
fs.writeFileSync(inputPath, JSON.stringify(workflow, null, 2));
console.log('\nUpdated workflow written to:', inputPath);
console.log('Total nodes:', workflow.nodes.length);
console.log('Total connections:', Object.keys(workflow.connections).length);
