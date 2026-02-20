// upgrade_save_v29_to_v30.cjs
// Upgrades NQxb_Artifact_Save_v1 from v29 to v30:
//   1. Replaces Validate_Request jsCode with v2.2 (adds journal strict validation)
//   2. Removes payload field from DB_Insert_Journal_Extension1
//   3. Archives v29, writes v30

const fs = require('fs');
const path = require('path');

const base = path.resolve(__dirname, '..');
const v29Path = path.join(base, 'workflows', 'NQxb_Artifact_Save_v1 (29).json');
const v30Path = path.join(base, 'workflows', 'NQxb_Artifact_Save_v1 (30).json');
const archiveDir = path.join(base, 'workflows', 'Archive');
const archivePath = path.join(archiveDir, 'NQxb_Artifact_Save_v1__v29__ARCHIVED.json');
const jsCodePath = path.join(base, 'work', 'v22_validate_request.js');

// ---- Read inputs ----
console.log('Reading v29 workflow...');
const workflow = JSON.parse(fs.readFileSync(v29Path, 'utf8'));

console.log('Reading v2.2 jsCode...');
const v22JsCode = fs.readFileSync(jsCodePath, 'utf8').replace(/\r\n/g, '\n');

// ---- MODIFICATION 1: Replace Validate_Request jsCode ----
const validateNode = workflow.nodes.find(
  n => n.name === 'NQxb_Artifact_Save_v1__Validate_Request'
);
if (!validateNode) {
  console.error('ERROR: Validate_Request node not found');
  process.exit(1);
}

// Verify current version before replacing
const currentCode = validateNode.parameters.jsCode;
if (!currentCode.includes('v2.1')) {
  console.error('ERROR: Expected v2.1 jsCode, found something else. Aborting.');
  process.exit(1);
}
if (currentCode.includes('v2.2')) {
  console.error('ERROR: jsCode already contains v2.2. Already upgraded?');
  process.exit(1);
}

validateNode.parameters.jsCode = v22JsCode;
console.log('  [OK] Validate_Request jsCode updated to v2.2');

// ---- MODIFICATION 2: Remove payload from DB_Insert_Journal_Extension1 ----
const journalInsertNode = workflow.nodes.find(
  n => n.name === 'NQxb_Artifact_Save_v1__DB_Insert_Journal_Extension1'
);
if (!journalInsertNode) {
  console.error('ERROR: DB_Insert_Journal_Extension1 node not found');
  process.exit(1);
}

const fieldsBefore = journalInsertNode.parameters.fieldsUi.fieldValues;
const beforeCount = fieldsBefore.length;
const beforeFields = fieldsBefore.map(f => f.fieldId);

journalInsertNode.parameters.fieldsUi.fieldValues = fieldsBefore.filter(
  f => f.fieldId !== 'payload'
);

const afterCount = journalInsertNode.parameters.fieldsUi.fieldValues.length;
const afterFields = journalInsertNode.parameters.fieldsUi.fieldValues.map(f => f.fieldId);

if (beforeCount === afterCount) {
  console.error('WARNING: No payload field found to remove. Fields:', beforeFields);
} else {
  console.log(`  [OK] DB_Insert_Journal_Extension1: removed payload (${beforeFields.join(', ')} -> ${afterFields.join(', ')})`);
}

// ---- ARCHIVE v29 ----
if (!fs.existsSync(archiveDir)) {
  fs.mkdirSync(archiveDir, { recursive: true });
  console.log(`  [OK] Created Archive directory: ${archiveDir}`);
}

fs.copyFileSync(v29Path, archivePath);
console.log(`  [OK] Archived v29 -> ${archivePath}`);

// ---- WRITE v30 ----
const v30Json = JSON.stringify(workflow, null, 2);
fs.writeFileSync(v30Path, v30Json);
console.log(`  [OK] Wrote v30 -> ${v30Path}`);

// ---- VERIFICATION ----
console.log('\n=== Verification ===');
const v30 = JSON.parse(fs.readFileSync(v30Path, 'utf8'));
const v30Validate = v30.nodes.find(n => n.name === 'NQxb_Artifact_Save_v1__Validate_Request');
const v30JournalInsert = v30.nodes.find(n => n.name === 'NQxb_Artifact_Save_v1__DB_Insert_Journal_Extension1');

const checks = [
  ['v2.2 comment present', v30Validate.parameters.jsCode.includes('v2.2')],
  ['JOURNAL_EXTENSION_INVALID present', v30Validate.parameters.jsCode.includes('JOURNAL_EXTENSION_INVALID')],
  ['Project lifecycle_stage validation preserved', v30Validate.parameters.jsCode.includes('lifecycle_stage')],
  ['Snapshot/restart payload validation preserved', v30Validate.parameters.jsCode.includes("extension.payload")],
  ['Instruction_pack 4-field validation preserved', v30Validate.parameters.jsCode.includes('pack_format')],
  ['gw_workspace_id required check preserved', v30Validate.parameters.jsCode.includes('gw_workspace_id')],
  ['owner_user_id required check preserved', v30Validate.parameters.jsCode.includes('owner_user_id')],
  ['title required check preserved', v30Validate.parameters.jsCode.includes("'title'")],
  ['Error envelope _gw_route preserved', v30Validate.parameters.jsCode.includes('_gw_route')],
  ['Journal INSERT has NO payload field', !v30JournalInsert.parameters.fieldsUi.fieldValues.some(f => f.fieldId === 'payload')],
  ['Journal INSERT has entry_text field', v30JournalInsert.parameters.fieldsUi.fieldValues.some(f => f.fieldId === 'entry_text')],
  ['Journal INSERT has artifact_id field', v30JournalInsert.parameters.fieldsUi.fieldValues.some(f => f.fieldId === 'artifact_id')],
  ['Total nodes unchanged', v30.nodes.length === workflow.nodes.length],
  ['Connections preserved', Object.keys(v30.connections).length === Object.keys(workflow.connections).length],
  ['Workflow name unchanged', v30.name === 'NQxb_Artifact_Save_v1'],
  ['Workflow ID preserved', v30.id === 'n0bc7FWDBruPNWeZ'],
];

let allPassed = true;
for (const [label, result] of checks) {
  const status = result ? 'PASS' : 'FAIL';
  const color = result ? '' : '  <<<< FAILURE';
  console.log(`  [${status}] ${label}${color}`);
  if (!result) allPassed = false;
}

// Check that no other nodes were modified
const v29Reread = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
const modifiedNodeNames = [];
for (const v30Node of v30.nodes) {
  const v29Node = v29Reread.nodes.find(n => n.id === v30Node.id);
  if (!v29Node) {
    modifiedNodeNames.push(`${v30Node.name} (NEW - not in v29)`);
    continue;
  }
  if (v30Node.name === 'NQxb_Artifact_Save_v1__Validate_Request') continue;
  if (v30Node.name === 'NQxb_Artifact_Save_v1__DB_Insert_Journal_Extension1') continue;
  if (JSON.stringify(v30Node) !== JSON.stringify(v29Node)) {
    modifiedNodeNames.push(v30Node.name);
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
console.log(`  Output:  ${v30Path}`);
process.exit(allPassed ? 0 : 1);
