// upgrade_save_v30_to_v31.cjs
// Upgrades NQxb_Artifact_Save_v1 from v30 to v31:
//   1. Adds JOURNAL_EXTENSION_INVALID to ALLOWED_ERROR_CODES in Return_Response
//   2. Archives v30, writes v31

const fs = require('fs');
const path = require('path');

const base = path.resolve(__dirname, '..');
const v30Path = path.join(base, 'workflows', 'NQxb_Artifact_Save_v1 (30).json');
const v31Path = path.join(base, 'workflows', 'NQxb_Artifact_Save_v1 (31).json');
const archiveDir = path.join(base, 'workflows', 'Archive');
const archivePath = path.join(archiveDir, 'NQxb_Artifact_Save_v1__v30__ARCHIVED.json');

// ---- Read input ----
console.log('Reading v30 workflow...');
const workflow = JSON.parse(fs.readFileSync(v30Path, 'utf8'));

// ---- MODIFICATION 1: Add JOURNAL_EXTENSION_INVALID to Return_Response allow-list ----
const returnNode = workflow.nodes.find(
  n => n.name === 'NQxb_Artifact_Save_v1__Return_Response'
);
if (!returnNode) {
  console.error('ERROR: Return_Response node not found');
  process.exit(1);
}

const currentCode = returnNode.parameters.jsCode;

// Verify the allow-list exists and JOURNAL_EXTENSION_INVALID is NOT already present
if (!currentCode.includes('ALLOWED_ERROR_CODES')) {
  console.error('ERROR: ALLOWED_ERROR_CODES not found in Return_Response jsCode');
  process.exit(1);
}
if (currentCode.includes('JOURNAL_EXTENSION_INVALID')) {
  console.error('ERROR: JOURNAL_EXTENSION_INVALID already in allow-list. Already upgraded?');
  process.exit(1);
}
if (!currentCode.includes("'INTERNAL_ERROR',")) {
  console.error('ERROR: Expected INTERNAL_ERROR in allow-list but not found');
  process.exit(1);
}

// Insert JOURNAL_EXTENSION_INVALID before INTERNAL_ERROR in the allow-list
// This keeps INTERNAL_ERROR as the last "real" entry and adds the new code alphabetically near other type-specific codes
const updatedCode = currentCode.replace(
  "  'INTERNAL_ERROR',\n]);",
  "  'JOURNAL_EXTENSION_INVALID',\n  'INTERNAL_ERROR',\n]);"
);

if (updatedCode === currentCode) {
  console.error('ERROR: String replacement did not match. Allow-list format may have changed.');
  process.exit(1);
}

returnNode.parameters.jsCode = updatedCode;
console.log('  [OK] Return_Response: added JOURNAL_EXTENSION_INVALID to ALLOWED_ERROR_CODES');

// ---- ARCHIVE v30 ----
if (!fs.existsSync(archiveDir)) {
  fs.mkdirSync(archiveDir, { recursive: true });
  console.log(`  [OK] Created Archive directory: ${archiveDir}`);
}

fs.copyFileSync(v30Path, archivePath);
console.log(`  [OK] Archived v30 -> ${archivePath}`);

// ---- WRITE v31 ----
const v31Json = JSON.stringify(workflow, null, 2);
fs.writeFileSync(v31Path, v31Json);
console.log(`  [OK] Wrote v31 -> ${v31Path}`);

// ---- VERIFICATION ----
console.log('\n=== Verification ===');
const v31 = JSON.parse(fs.readFileSync(v31Path, 'utf8'));
const v31Return = v31.nodes.find(n => n.name === 'NQxb_Artifact_Save_v1__Return_Response');
const v31Validate = v31.nodes.find(n => n.name === 'NQxb_Artifact_Save_v1__Validate_Request');

const checks = [
  // Allow-list fix
  ['JOURNAL_EXTENSION_INVALID in ALLOWED_ERROR_CODES', v31Return.parameters.jsCode.includes("'JOURNAL_EXTENSION_INVALID'")],
  ['INTERNAL_ERROR still in allow-list', v31Return.parameters.jsCode.includes("'INTERNAL_ERROR'")],
  ['VALIDATION_ERROR still in allow-list', v31Return.parameters.jsCode.includes("'VALIDATION_ERROR'")],
  ['CONFLICT still in allow-list', v31Return.parameters.jsCode.includes("'CONFLICT'")],
  ['IMMUTABLE_RECORD still in allow-list', v31Return.parameters.jsCode.includes("'IMMUTABLE_RECORD'")],
  ['LIFECYCLE_TRANSITION_NOT_ALLOWED still in allow-list', v31Return.parameters.jsCode.includes("'LIFECYCLE_TRANSITION_NOT_ALLOWED'")],
  ['SNAPSHOT_REQUIRED still in allow-list', v31Return.parameters.jsCode.includes("'SNAPSHOT_REQUIRED'")],

  // Validate_Request unchanged
  ['Validate_Request still has v2.2 comment', v31Validate.parameters.jsCode.includes('v2.2')],
  ['Validate_Request still has JOURNAL_EXTENSION_INVALID error code', v31Validate.parameters.jsCode.includes('JOURNAL_EXTENSION_INVALID')],
  ['Validate_Request still has project validation', v31Validate.parameters.jsCode.includes('lifecycle_stage')],
  ['Validate_Request still has instruction_pack validation', v31Validate.parameters.jsCode.includes('pack_format')],
  ['Validate_Request still has snapshot/restart validation', v31Validate.parameters.jsCode.includes("extension.payload")],

  // Structural integrity
  ['Total nodes unchanged', v31.nodes.length === workflow.nodes.length],
  ['Connections preserved', Object.keys(v31.connections).length === Object.keys(workflow.connections).length],
  ['Workflow name unchanged', v31.name === 'NQxb_Artifact_Save_v1'],
  ['Workflow ID preserved', v31.id === 'n0bc7FWDBruPNWeZ'],
];

let allPassed = true;
for (const [label, result] of checks) {
  const status = result ? 'PASS' : 'FAIL';
  const color = result ? '' : '  <<<< FAILURE';
  console.log(`  [${status}] ${label}${color}`);
  if (!result) allPassed = false;
}

// Check that no other nodes were modified
const v30Reread = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
const modifiedNodeNames = [];
for (const v31Node of v31.nodes) {
  const v30Node = v30Reread.nodes.find(n => n.id === v31Node.id);
  if (!v30Node) {
    modifiedNodeNames.push(`${v31Node.name} (NEW - not in v30)`);
    continue;
  }
  if (v31Node.name === 'NQxb_Artifact_Save_v1__Return_Response') continue;
  if (JSON.stringify(v31Node) !== JSON.stringify(v30Node)) {
    modifiedNodeNames.push(v31Node.name);
  }
}
if (modifiedNodeNames.length === 0) {
  console.log('  [PASS] No unintended node modifications');
} else {
  console.log(`  [FAIL] Unexpected modified nodes: ${modifiedNodeNames.join(', ')}`);
  allPassed = false;
}

console.log(`\n=== Result: ${allPassed ? 'ALL CHECKS PASSED' : 'SOME CHECKS FAILED'} ===`);
console.log(`\nFiles:`);
console.log(`  Archive: ${archivePath}`);
console.log(`  Output:  ${v31Path}`);
process.exit(allPassed ? 0 : 1);
