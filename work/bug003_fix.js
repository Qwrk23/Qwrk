// BUG-003 Fix: Add hydrate gate to NQxb_Artifact_Query_v1
// Reads v16, modifies 6 Code nodes, writes v17

const fs = require('fs');

const v16Path = process.argv[2];
const v17Path = process.argv[3];

if (!v16Path || !v17Path) {
  console.error('Usage: node bug003_fix.js <v16-path> <v17-path>');
  process.exit(1);
}

const wf = JSON.parse(fs.readFileSync(v16Path, 'utf8'));

// --- Hydrate gate code (prepended to 5 merge nodes) ---
const hydrateGate = [
  '// BUG-003: Hydrate gate \u2014 skip extension merge when hydrate=false',
  'const _selector = $node["NQxb_Artifact_Query_v1__Normalize_Request"].json.selector ?? {};',
  'if (_selector.hydrate === false) {',
  '  const _spine = $node["NQxb_Artifact_Query_v1__DB_Get_Artifact_Spine"].json || {};',
  '  return [{ json: { ..._spine, artifact_type: (_spine.artifact_type ?? "").trim(), extension: null } }];',
  '}',
  '',
  ''
].join('\n');

// --- Target merge node names ---
const mergeNames = [
  'NQxb_Gateway_v1__Merge_Spine_And_Project_Extension',
  'NQxb_Gateway_v1__Merge_Spine_And_Journal_Extension',
  'NQxb_Gateway_v1__Merge_Spine_And_Restart_Extension',
  'NQxb_Gateway_v1__Merge_Spine_And_Snapshot_Extension',
  'NQxb_Gateway_v1__Merge_Spine_And_Instruction_Pack_Extension1'
];

// --- Replacement code for TypeMismatch node ---
const typeMismatchCode = [
  '// BUG-003: Check if types actually match but no extension table exists',
  '// Types like grass, thorn, forest, thicket, flower, branch, leaf have no extension tables.',
  '// When stored_type === requested_type, return spine only instead of TYPE_MISMATCH.',
  'const req = $node["NQxb_Artifact_Query_v1__Normalize_Request"]?.json ?? {};',
  'const j = $json ?? {};',
  '',
  'const stored = typeof j.artifact_type === "string" ? j.artifact_type.trim() : (j.artifact_type ?? null);',
  'const requested = typeof req.req_artifact_type === "string" ? req.req_artifact_type.trim() : (typeof req.artifact_type === "string" ? req.artifact_type.trim() : null);',
  '',
  '// If types match, no extension table \u2014 return spine only',
  'if (stored && requested && stored === requested) {',
  '  const spineRaw = $node["NQxb_Artifact_Query_v1__DB_Get_Artifact_Spine"].json || {};',
  '  return [{ json: { ...spineRaw, artifact_type: stored, extension: null } }];',
  '}',
  '',
  '// Actual TYPE_MISMATCH \u2014 existing logic preserved exactly',
  'const artifact_id = req.req_artifact_id ?? req.artifact_id ?? j.artifact_id ?? null;',
  'const gw_workspace_id = req.gw_workspace_id ?? req.workspace_id ?? null;',
  '',
  'return [{',
  '  json: {',
  '    ok: false,',
  '    _gw_route: "error",',
  '    gw_action: req.gw_action ?? "artifact.query",',
  '    gw_workspace_id,',
  '    artifact_id,',
  '    requested_artifact_type: requested,',
  '    stored_artifact_type: stored,',
  '    compare_key: `${stored ?? "null"}::${requested ?? "null"}`,',
  '    error: {',
  '      code: "TYPE_MISMATCH",',
  '      message: "Requested artifact_type does not match stored artifact_type for this artifact_id.",',
  '    },',
  '    timestamp: new Date().toISOString(),',
  '  }',
  '}];',
  ''
].join('\n');

// --- Apply modifications ---
const modified = [];

for (const node of wf.nodes) {
  if (mergeNames.includes(node.name)) {
    node.parameters.jsCode = hydrateGate + node.parameters.jsCode;
    modified.push(node.name);
  }

  if (node.name === 'NQxb_Artifact_Query_v1__Return_TypeMismatch') {
    node.parameters.jsCode = typeMismatchCode;
    modified.push(node.name);
  }
}

// --- Write v17 ---
fs.writeFileSync(v17Path, JSON.stringify(wf, null, 2), 'utf8');

console.log('BUG-003 fix applied. Modified ' + modified.length + ' nodes:');
modified.forEach(n => console.log('  + ' + n));
console.log('\nOutput: ' + v17Path);
