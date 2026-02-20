// Promote v20 → v2_HTTP Transformation Script
// Replaces Supabase executeQuery nodes with HTTP Request + PostgREST
// Changes: 2 Supabase nodes → 2 HTTP Request nodes, 2 Attach Code nodes updated
const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Promote_v1 (20).json');
const outPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Promote_v2_HTTP.json');

const data = JSON.parse(fs.readFileSync(srcPath, 'utf8'));

// ============================================================
// 1. Replace QPM_Query_Journal_Children (Supabase → HTTP Request)
// ============================================================
const jIdx = data.nodes.findIndex(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children');
if (jIdx === -1) { console.error('ERROR: Journal query node not found'); process.exit(1); }
const jOld = data.nodes[jIdx];

data.nodes[jIdx] = {
  parameters: {
    method: "GET",
    url: "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?select=artifact_id&parent_artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.gw_workspace_id }}&artifact_type=eq.journal&deleted_at=is.null",
    authentication: "predefinedCredentialType",
    nodeCredentialType: "supabaseApi",
    sendHeaders: true,
    headerParameters: {
      parameters: [
        { name: "Prefer", value: "count=exact" }
      ]
    },
    options: {
      response: {
        response: {
          responseFormat: "json"
        }
      }
    }
  },
  type: "n8n-nodes-base.httpRequest",
  typeVersion: 4.2,
  position: jOld.position,
  id: jOld.id,
  name: jOld.name,
  credentials: {
    supabaseApi: jOld.credentials.supabaseApi
  },
  alwaysOutputData: true
};
console.log('REPLACED: QPM_Query_Journal_Children (Supabase → HTTP Request)');

// ============================================================
// 2. Replace QPM_Query_Execution_Children (Supabase → HTTP Request)
// ============================================================
const eIdx = data.nodes.findIndex(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children');
if (eIdx === -1) { console.error('ERROR: Execution query node not found'); process.exit(1); }
const eOld = data.nodes[eIdx];

data.nodes[eIdx] = {
  parameters: {
    method: "GET",
    url: "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?select=artifact_id&parent_artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.gw_workspace_id }}&artifact_type=in.(branch,leaf)&deleted_at=is.null",
    authentication: "predefinedCredentialType",
    nodeCredentialType: "supabaseApi",
    sendHeaders: true,
    headerParameters: {
      parameters: [
        { name: "Prefer", value: "count=exact" }
      ]
    },
    options: {
      response: {
        response: {
          responseFormat: "json"
        }
      }
    }
  },
  type: "n8n-nodes-base.httpRequest",
  typeVersion: 4.2,
  position: eOld.position,
  id: eOld.id,
  name: eOld.name,
  credentials: {
    supabaseApi: eOld.credentials.supabaseApi
  },
  alwaysOutputData: true
};
console.log('REPLACED: QPM_Query_Execution_Children (Supabase → HTTP Request)');

// ============================================================
// 3. Update QPM_Attach_Journal_Count (count HTTP items)
// ============================================================
const ajIdx = data.nodes.findIndex(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count');
if (ajIdx === -1) { console.error('ERROR: Attach Journal node not found'); process.exit(1); }

data.nodes[ajIdx].parameters.jsCode = `// NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count
// Counts journal children from HTTP Request response items.
// Sequential chain: Prepare \\u2192 JournalHTTP \\u2192 this \\u2192 ExecHTTP \\u2192 ...
//
// HTTP Request returns N items (one per matching artifact).
// alwaysOutputData guarantees at least 1 item on empty result.
// Count = items with valid artifact_id.

const context = $node["NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries"].json;
const items = $input.all();
const journal_count = items.filter(i => i.json?.artifact_id).length;

if (typeof journal_count !== 'number' || !Number.isFinite(journal_count)) {
  return [{
    json: {
      ...context,
      ok: false,
      _gw_route: "error",
      error: {
        code: "JOURNAL_COUNT_UNAVAILABLE",
        message: "Could not determine journal child count from HTTP response.",
        details: { item_count: items.length }
      }
    }
  }];
}

return [{
  json: {
    ...context,
    journal_count
  }
}];
`;
console.log('UPDATED: QPM_Attach_Journal_Count (count HTTP response items)');

// ============================================================
// 4. Update QPM_Attach_Execution_Count (count HTTP items)
// ============================================================
const aeIdx = data.nodes.findIndex(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count');
if (aeIdx === -1) { console.error('ERROR: Attach Execution node not found'); process.exit(1); }

data.nodes[aeIdx].parameters.jsCode = `// NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count
// Counts execution children from HTTP Request response items.
// Sequential chain: ... \\u2192 AttachJournal \\u2192 ExecHTTP \\u2192 this \\u2192 Validate
//
// HTTP Request returns N items (one per matching artifact).
// alwaysOutputData guarantees at least 1 item on empty result.
// Count = items with valid artifact_id.

const context = $node["NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count"].json;
const items = $input.all();
const execution_count = items.filter(i => i.json?.artifact_id).length;

if (typeof execution_count !== 'number' || !Number.isFinite(execution_count)) {
  return [{
    json: {
      ...context,
      ok: false,
      _gw_route: "error",
      error: {
        code: "EXECUTION_COUNT_UNAVAILABLE",
        message: "Could not determine execution child count from HTTP response.",
        details: { item_count: items.length }
      }
    }
  }];
}

return [{
  json: {
    ...context,
    execution_count
  }
}];
`;
console.log('UPDATED: QPM_Attach_Execution_Count (count HTTP response items)');

// ============================================================
// 5. Verify integrity
// ============================================================
const nodeNames = data.nodes.map(n => n.name);

// Check all connection sources and targets exist
let errors = 0;
for (const [src, conn] of Object.entries(data.connections)) {
  if (!nodeNames.includes(src)) {
    console.error(`INTEGRITY ERROR: Connection source "${src}" not found`);
    errors++;
  }
  for (const output of conn.main) {
    for (const target of output) {
      if (!nodeNames.includes(target.node)) {
        console.error(`INTEGRITY ERROR: Connection target "${target.node}" not found`);
        errors++;
      }
    }
  }
}

// Verify chain
const trace = (start) => {
  const chain = [start];
  let current = start;
  for (let i = 0; i < 15; i++) {
    const conn = data.connections[current];
    if (!conn || !conn.main || !conn.main[0] || conn.main[0].length === 0) break;
    current = conn.main[0][0].node;
    chain.push(current);
  }
  return chain.map(n => n.split('__').pop());
};
console.log('\nChain:', trace('NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries').join(' -> '));

// Verify replaced nodes are HTTP Request type
const jNode = data.nodes.find(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children');
const eNode = data.nodes.find(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children');
console.log('\nJournal node type:', jNode.type, 'v' + jNode.typeVersion);
console.log('Execution node type:', eNode.type, 'v' + eNode.typeVersion);

// Verify no other Supabase executeQuery nodes remain
const supabaseExecNodes = data.nodes.filter(n =>
  n.type === 'n8n-nodes-base.supabase' && n.parameters?.operation === 'executeQuery'
);
if (supabaseExecNodes.length > 0) {
  console.error('WARNING: Remaining Supabase executeQuery nodes:', supabaseExecNodes.map(n => n.name));
}

if (errors > 0) {
  console.error(`\n${errors} INTEGRITY ERRORS — do NOT deploy`);
  process.exit(1);
}

// ============================================================
// 6. Write output
// ============================================================
fs.writeFileSync(outPath, JSON.stringify(data, null, 2));
console.log(`\nOutput: ${outPath}`);
console.log(`Nodes: ${data.nodes.length}`);
console.log('Changes: 2 Supabase → HTTP Request, 2 Attach Code nodes updated');
