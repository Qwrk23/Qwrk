// Promote v17 → v18 Transformation Script
// Fixes: execution_child_count always 0 (Merge wiring + $node scope)
// Changes: DELETE Merge node, sequential chain, $json-based validation
const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Promote_v1 (17).json');
const outPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Promote_v1 (18).json');

const data = JSON.parse(fs.readFileSync(srcPath, 'utf8'));

// ============================================================
// 1. DELETE QPM_Merge_Child_Counts node
// ============================================================
const mergeIdx = data.nodes.findIndex(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts');
if (mergeIdx === -1) {
  console.error('ERROR: QPM_Merge_Child_Counts node not found');
  process.exit(1);
}
const removedNode = data.nodes.splice(mergeIdx, 1)[0];
console.log(`DELETED node: ${removedNode.name} (id: ${removedNode.id})`);

// ============================================================
// 2. Modify ExecQuery SQL — remove 'limb'
// ============================================================
const execNode = data.nodes.find(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children');
if (!execNode) {
  console.error('ERROR: QPM_Query_Execution_Children node not found');
  process.exit(1);
}
const oldQuery = execNode.parameters.query;
execNode.parameters.query = "SELECT COUNT(*)::int as execution_count\nFROM qxb_artifact\nWHERE parent_artifact_id = '{{ $json.artifact_id }}'\n  AND workspace_id = '{{ $json.gw_workspace_id }}'\n  AND artifact_type IN ('branch', 'leaf')\n  AND deleted_at IS NULL";
console.log(`MODIFIED ExecQuery SQL: removed 'limb' from IN clause`);
console.log(`  OLD: ...IN ('branch', 'limb', 'leaf')...`);
console.log(`  NEW: ...IN ('branch', 'leaf')...`);

// ============================================================
// 3. Add QPM_Attach_Journal_Count node
// ============================================================
data.nodes.push({
  parameters: {
    jsCode: "// NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count\n// Merge journal query result with upstream context from Prepare node.\n// Sequential chain: Prepare \u2192 JournalQuery \u2192 this \u2192 ExecQuery \u2192 ...\n\nconst context = $node[\"NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries\"].json;\nconst queryResult = $json;\n\nconst journal_count = queryResult?.journal_count;\n\nif (typeof journal_count !== 'number') {\n  return [{\n    json: {\n      ...context,\n      ok: false,\n      _gw_route: \"error\",\n      error: {\n        code: \"JOURNAL_COUNT_UNAVAILABLE\",\n        message: \"Journal child count query did not return a numeric result.\",\n        details: { raw_result: queryResult }\n      }\n    }\n  }];\n}\n\nreturn [{\n  json: {\n    ...context,\n    journal_count\n  }\n}];\n"
  },
  type: "n8n-nodes-base.code",
  typeVersion: 2,
  position: [776, 192],
  id: "qpm-attach-journal-count",
  name: "NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count"
});
console.log('ADDED node: NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count');

// ============================================================
// 4. Add QPM_Attach_Execution_Count node
// ============================================================
data.nodes.push({
  parameters: {
    jsCode: "// NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count\n// Merge execution query result with upstream context (includes journal_count).\n// Sequential chain: ... \u2192 AttachJournal \u2192 ExecQuery \u2192 this \u2192 Validate\n\nconst context = $node[\"NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count\"].json;\nconst queryResult = $json;\n\nconst execution_count = queryResult?.execution_count;\n\nif (typeof execution_count !== 'number') {\n  return [{\n    json: {\n      ...context,\n      ok: false,\n      _gw_route: \"error\",\n      error: {\n        code: \"EXECUTION_COUNT_UNAVAILABLE\",\n        message: \"Execution child count query did not return a numeric result.\",\n        details: { raw_result: queryResult }\n      }\n    }\n  }];\n}\n\nreturn [{\n  json: {\n    ...context,\n    execution_count\n  }\n}];\n"
  },
  type: "n8n-nodes-base.code",
  typeVersion: 2,
  position: [776, 384],
  id: "qpm-attach-execution-count",
  name: "NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count"
});
console.log('ADDED node: NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count');

// ============================================================
// 5. Update QPM_Validate_Rules code
// ============================================================
const validateNode = data.nodes.find(n => n.name === 'NQxb_Artifact_Promote_v1__QPM_Validate_Rules');
if (!validateNode) {
  console.error('ERROR: QPM_Validate_Rules node not found');
  process.exit(1);
}
validateNode.parameters.jsCode = "// NQxb_Artifact_Promote_v1__QPM_Validate_Rules\n// Purpose: Enforce QPM lifecycle transition validation rules\n//\n// QPM PHASE 2 RULES (2026-02-01):\n// 1. seed_to_sapling: Requires summary (non-empty, trimmed) OR linked journal child\n// 2. sapling_to_tree: Requires execution anatomy (branch or leaf child)\n// 3. tree_to_retired: No validation (always pass)\n//\n// v18 FIX: Reads counts from $json (sequential deterministic chain).\n// No $node[] references. No try/catch default-to-0.\n//\n// Error codes:\n// - PROMOTION_BLOCKED_SEED_NOT_READY\n// - PROMOTION_BLOCKED_NO_ANATOMY\n// - JOURNAL_COUNT_UNAVAILABLE\n// - EXECUTION_COUNT_UNAVAILABLE\n\nconst input = $json;\n\nconst transition = (input.transition ?? \"\").toString().trim();\nconst summary = input._spine_summary ?? null;\nconst summaryTrimmed = (typeof summary === \"string\") ? summary.trim() : \"\";\n\nconst journalCount = input.journal_count;\nconst executionCount = input.execution_count;\n\n// --- Explicit availability checks (no silent defaults) ---\n\nif (typeof journalCount !== 'number') {\n  return [{\n    json: {\n      ...input,\n      ok: false,\n      _gw_route: \"error\",\n      error: {\n        code: \"JOURNAL_COUNT_UNAVAILABLE\",\n        message: \"journal_count missing from upstream chain.\",\n        details: { journal_count: journalCount }\n      }\n    }\n  }];\n}\n\nif (typeof executionCount !== 'number') {\n  return [{\n    json: {\n      ...input,\n      ok: false,\n      _gw_route: \"error\",\n      error: {\n        code: \"EXECUTION_COUNT_UNAVAILABLE\",\n        message: \"execution_count missing from upstream chain.\",\n        details: { execution_count: executionCount }\n      }\n    }\n  }];\n}\n\n// --- QPM Validation ---\n\nif (transition === \"seed_to_sapling\") {\n  const hasSummary = summaryTrimmed.length > 0;\n  const hasJournalChild = journalCount > 0;\n\n  if (!hasSummary && !hasJournalChild) {\n    return [{\n      json: {\n        ...input,\n        ok: false,\n        _gw_route: \"error\",\n        error: {\n          code: \"PROMOTION_BLOCKED_SEED_NOT_READY\",\n          message: \"Seed \\u2192 Sapling requires summary or linked journal\",\n          details: {\n            artifact_id: input.artifact_id,\n            has_summary: hasSummary,\n            journal_child_count: journalCount,\n            rule: \"summary OR journal child required\"\n          }\n        }\n      }\n    }];\n  }\n}\n\nif (transition === \"sapling_to_tree\") {\n  const hasExecutionAnatomy = executionCount > 0;\n\n  if (!hasExecutionAnatomy) {\n    return [{\n      json: {\n        ...input,\n        ok: false,\n        _gw_route: \"error\",\n        error: {\n          code: \"PROMOTION_BLOCKED_NO_ANATOMY\",\n          message: \"Sapling \\u2192 Tree requires execution anatomy (branch or leaf)\",\n          details: {\n            artifact_id: input.artifact_id,\n            execution_child_count: executionCount,\n            rule: \"branch or leaf child required\"\n          }\n        }\n      }\n    }];\n  }\n}\n\n// tree_to_retired: No validation beyond state check (already handled)\n\nreturn [{\n  json: {\n    ...input,\n    ok: true,\n    _gw_route: input._gw_route ?? \"ok\",\n    _qpm_validated: {\n      transition,\n      summary_present: summaryTrimmed.length > 0,\n      journal_child_count: journalCount,\n      execution_child_count: executionCount\n    }\n  }\n}];\n";
console.log('MODIFIED node: QPM_Validate_Rules (reads from $json, explicit errors)');

// ============================================================
// 6. Rewire connections
// ============================================================

// 6a. Switch_OK output 0: only Prepare (remove Journal + Exec fan-out)
data.connections["NQxb_Artifact_Promote_v1__Switch_OK"].main[0] = [
  { node: "NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries", type: "main", index: 0 }
];
console.log('REWIRED: Switch_OK output 0 → Prepare only (removed parallel fan-out)');

// 6b. Prepare → JournalQuery (was → Merge input 0)
data.connections["NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries"].main[0] = [
  { node: "NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children", type: "main", index: 0 }
];
console.log('REWIRED: Prepare → JournalQuery');

// 6c. JournalQuery → AttachJournal (was → Merge input 1)
data.connections["NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children"].main[0] = [
  { node: "NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count", type: "main", index: 0 }
];
console.log('REWIRED: JournalQuery → AttachJournalCount');

// 6d. AttachJournal → ExecQuery (new)
data.connections["NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count"] = {
  main: [[
    { node: "NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children", type: "main", index: 0 }
  ]]
};
console.log('ADDED: AttachJournalCount → ExecQuery');

// 6e. ExecQuery → AttachExec (was → Merge input 2)
data.connections["NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children"].main[0] = [
  { node: "NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count", type: "main", index: 0 }
];
console.log('REWIRED: ExecQuery → AttachExecutionCount');

// 6f. AttachExec → Validate (new)
data.connections["NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count"] = {
  main: [[
    { node: "NQxb_Artifact_Promote_v1__QPM_Validate_Rules", type: "main", index: 0 }
  ]]
};
console.log('ADDED: AttachExecutionCount → Validate');

// 6g. Remove Merge connections
delete data.connections["NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts"];
console.log('DELETED: QPM_Merge_Child_Counts connections');

// ============================================================
// 7. Verify integrity
// ============================================================
const nodeNames = data.nodes.map(n => n.name);
const allTargets = [];
for (const [src, conn] of Object.entries(data.connections)) {
  if (!nodeNames.includes(src)) {
    console.error(`INTEGRITY ERROR: Connection source "${src}" not found in nodes`);
  }
  for (const output of conn.main) {
    for (const target of output) {
      allTargets.push(target.node);
      if (!nodeNames.includes(target.node)) {
        console.error(`INTEGRITY ERROR: Connection target "${target.node}" not found in nodes`);
      }
    }
  }
}

// Check QPM chain is connected
const chain = [
  'NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries',
  'NQxb_Artifact_Promote_v1__QPM_Query_Journal_Children',
  'NQxb_Artifact_Promote_v1__QPM_Attach_Journal_Count',
  'NQxb_Artifact_Promote_v1__QPM_Query_Execution_Children',
  'NQxb_Artifact_Promote_v1__QPM_Attach_Execution_Count',
  'NQxb_Artifact_Promote_v1__QPM_Validate_Rules'
];
for (let i = 0; i < chain.length - 1; i++) {
  const src = chain[i];
  const tgt = chain[i + 1];
  const conn = data.connections[src];
  if (!conn) {
    console.error(`CHAIN BREAK: No connections from "${src}"`);
    continue;
  }
  const targets = conn.main.flat().map(c => c.node);
  if (!targets.includes(tgt)) {
    console.error(`CHAIN BREAK: "${src}" does not connect to "${tgt}"`);
  }
}
console.log('\nChain verification: Switch_OK → Prepare → JournalQuery → AttachJournal → ExecQuery → AttachExec → Validate');

// Verify Merge is gone
if (nodeNames.includes('NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts')) {
  console.error('INTEGRITY ERROR: Merge node still present');
}
if (data.connections['NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts']) {
  console.error('INTEGRITY ERROR: Merge connections still present');
}

// ============================================================
// 8. Write output
// ============================================================
fs.writeFileSync(outPath, JSON.stringify(data, null, 2));
console.log(`\nOutput written to: ${outPath}`);
console.log(`Nodes: ${data.nodes.length} (was ${data.nodes.length - 2 + 1})`);
console.log(`  Removed: QPM_Merge_Child_Counts`);
console.log(`  Added: QPM_Attach_Journal_Count, QPM_Attach_Execution_Count`);
