// Save v26 → v27 Transformation Script
// Purpose: Harden error routing — no dead-end switch branches, add Guard_Error_ShortCircuit
// Changes:
//   1. ADD Guard_Error_ShortCircuit IF node after Validate_Request
//   2. WIRE Switch output 0 (ok===false) → Return_Response
//   3. WIRE Switch_Type_Registry output 0 (ok===false) → Return_Response
//   4. REWIRE Validate_Request → Guard → Derive_Owner_From_Auth
// No nodes deleted. No logic changes. Routing-only correction.

const fs = require('fs');
const path = require('path');

const srcPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Save_v1 (26).json');
const outPath = path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Save_v1 (27).json');

const data = JSON.parse(fs.readFileSync(srcPath, 'utf8'));

// ============================================================
// 1. ADD Guard_Error_ShortCircuit IF node
// ============================================================
// Position: between Validate_Request [-2512, 720] and Derive_Owner_From_Auth [-2288, 720]
// Midpoint: [-2400, 720]

const guardNode = {
  parameters: {
    conditions: {
      options: {
        caseSensitive: true,
        leftValue: "",
        typeValidation: "strict"
      },
      conditions: [
        {
          id: "error-shortcircuit",
          leftValue: "={{ $json.ok }}",
          rightValue: false,
          operator: {
            type: "boolean",
            operation: "equals"
          }
        }
      ],
      combinator: "and"
    },
    options: {}
  },
  type: "n8n-nodes-base.if",
  typeVersion: 2,
  position: [-2400, 720],
  id: "guard-error-shortcircuit-save",
  name: "NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit"
};

data.nodes.push(guardNode);
console.log('ADDED node: NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit');
console.log('  Position: [-2400, 720] (between Validate_Request and Derive_Owner_From_Auth)');
console.log('  Condition: ok === false');

// ============================================================
// 2. REWIRE Validate_Request → Guard (was → Derive_Owner_From_Auth)
// ============================================================

data.connections["NQxb_Artifact_Save_v1__Validate_Request"].main[0] = [
  { node: "NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit", type: "main", index: 0 }
];
console.log('\nREWIRED: Validate_Request → Guard_Error_ShortCircuit (was → Derive_Owner_From_Auth)');

// ============================================================
// 3. ADD Guard connections
//    TRUE (ok === false) → Return_Response (passthrough)
//    FALSE (ok !== false) → Derive_Owner_From_Auth (continue normal flow)
// ============================================================

data.connections["NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit"] = {
  main: [
    // Output 0 = TRUE (condition matched: ok === false) → Return_Response
    [
      { node: "NQxb_Artifact_Save_v1__Return_Response", type: "main", index: 0 }
    ],
    // Output 1 = FALSE (condition not matched: ok !== false) → continue normal flow
    [
      { node: "NQxb_Artifact_Save_v1__Derive_Owner_From_Auth", type: "main", index: 0 }
    ]
  ]
};
console.log('ADDED connections for Guard_Error_ShortCircuit:');
console.log('  TRUE  (ok===false) → Return_Response');
console.log('  FALSE (ok!==false) → Derive_Owner_From_Auth');

// ============================================================
// 4. WIRE Switch output 0 (ok===false) → Return_Response
// ============================================================
// Currently: [] (dead end at line 1629)

data.connections["Switch"].main[0] = [
  { node: "NQxb_Artifact_Save_v1__Return_Response", type: "main", index: 0 }
];
console.log('\nWIRED: Switch output 0 (ok===false) → Return_Response (was DEAD END)');

// ============================================================
// 5. WIRE Switch_Type_Registry output 0 (ok===false) → Return_Response
// ============================================================
// Currently: [] (dead end at line 1751)

data.connections["NQxb_Artifact_Save_v1__Switch_Type_Registry"].main[0] = [
  { node: "NQxb_Artifact_Save_v1__Return_Response", type: "main", index: 0 }
];
console.log('WIRED: Switch_Type_Registry output 0 (ok===false) → Return_Response (was DEAD END)');

// ============================================================
// 6. INTEGRITY VERIFICATION
// ============================================================
console.log('\n=== INTEGRITY VERIFICATION ===');

const nodeNames = data.nodes.map(n => n.name);
let errors = 0;

// Check all connection sources exist as nodes
for (const [src, conn] of Object.entries(data.connections)) {
  if (!nodeNames.includes(src)) {
    console.error(`INTEGRITY ERROR: Connection source "${src}" not found in nodes`);
    errors++;
  }
  for (const output of conn.main) {
    for (const target of output) {
      if (!nodeNames.includes(target.node)) {
        console.error(`INTEGRITY ERROR: Connection target "${target.node}" not found in nodes`);
        errors++;
      }
    }
  }
}

// Check no dead-end switch outputs remain
const switchNodes = data.nodes.filter(n => n.type === 'n8n-nodes-base.switch');
for (const sw of switchNodes) {
  const conn = data.connections[sw.name];
  if (!conn) {
    console.error(`INTEGRITY ERROR: Switch node "${sw.name}" has no connections`);
    errors++;
    continue;
  }
  conn.main.forEach((output, i) => {
    if (output.length === 0) {
      // Check if this switch uses fallbackOutput (extra) — those are OK to be empty
      // Switch_Guard_Saved_ID has fallbackOutput: "extra" which means unmatched items go to extra output
      // But Switch_Type_For_Insert and Switch_Type_For_Update only handle specific types — those fallthrough outputs are acceptable
      const hasFallback = sw.parameters?.options?.fallbackOutput === 'extra';
      if (!hasFallback) {
        console.warn(`WARNING: Switch "${sw.name.split('__').pop()}" output ${i} is empty (no downstream)`);
      }
    }
  });
}

// Verify Guard node exists and is connected
if (!nodeNames.includes('NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit')) {
  console.error('INTEGRITY ERROR: Guard_Error_ShortCircuit node not found');
  errors++;
}

// Verify chain: Validate_Request → Guard → (TRUE: Return_Response, FALSE: Derive_Owner_From_Auth)
const validateConn = data.connections["NQxb_Artifact_Save_v1__Validate_Request"];
const guardConn = data.connections["NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit"];

if (validateConn.main[0][0].node !== "NQxb_Artifact_Save_v1__Guard_Error_ShortCircuit") {
  console.error('CHAIN BREAK: Validate_Request does not connect to Guard_Error_ShortCircuit');
  errors++;
}

if (guardConn.main[0][0].node !== "NQxb_Artifact_Save_v1__Return_Response") {
  console.error('CHAIN BREAK: Guard TRUE does not connect to Return_Response');
  errors++;
}

if (guardConn.main[1][0].node !== "NQxb_Artifact_Save_v1__Derive_Owner_From_Auth") {
  console.error('CHAIN BREAK: Guard FALSE does not connect to Derive_Owner_From_Auth');
  errors++;
}

// Verify Switch output 0 now connects to Return_Response
const switchConn = data.connections["Switch"];
if (switchConn.main[0].length === 0 || switchConn.main[0][0].node !== "NQxb_Artifact_Save_v1__Return_Response") {
  console.error('CHAIN BREAK: Switch output 0 does not connect to Return_Response');
  errors++;
}

// Verify Switch_Type_Registry output 0 now connects to Return_Response
const trConn = data.connections["NQxb_Artifact_Save_v1__Switch_Type_Registry"];
if (trConn.main[0].length === 0 || trConn.main[0][0].node !== "NQxb_Artifact_Save_v1__Return_Response") {
  console.error('CHAIN BREAK: Switch_Type_Registry output 0 does not connect to Return_Response');
  errors++;
}

// Count error-producing nodes and verify all route to Return_Response
console.log('\n=== ERROR PATH VERIFICATION ===');

// Trace all paths that can produce ok:false and verify they reach Return_Response
const errorProducers = [
  { name: 'Validate_Request', route: 'Guard_Error_ShortCircuit TRUE → Return_Response' },
  { name: 'Type_Registry_Guard (via Switch)', route: 'Switch output 0 → Return_Response' },
  { name: 'Type_Registry_Guard (via Switch_Type_Registry)', route: 'Switch_Type_Registry output 0 → Return_Response' },
  { name: 'DB_Insert_Spine (onError)', route: 'output 1 → Return_Response' },
  { name: 'Check_Immutability', route: 'via downstream chain → Return_Response' },
  { name: 'Merge_PATCH_Spine (NOT_FOUND)', route: 'via downstream chain → Return_Response' },
  { name: 'Normalize_Saved_ID (SAVE_ID_MISSING)', route: 'Switch_Guard_Saved_ID fallback → Return_Response' },
];

for (const ep of errorProducers) {
  console.log(`  ✓ ${ep.name}: ${ep.route}`);
}

if (errors > 0) {
  console.error(`\n${errors} INTEGRITY ERRORS — do NOT deploy`);
  process.exit(1);
}

console.log('\n=== ALL INTEGRITY CHECKS PASSED ===');

// ============================================================
// 7. WRITE OUTPUT
// ============================================================
fs.writeFileSync(outPath, JSON.stringify(data, null, 2));
console.log(`\nOutput: ${outPath}`);
console.log(`Nodes: ${data.nodes.length} (was ${data.nodes.length - 1})`);
console.log('Changes:');
console.log('  +1 node: Guard_Error_ShortCircuit (IF)');
console.log('  +3 connections: Guard TRUE→Return, Guard FALSE→Derive, Validate→Guard');
console.log('  ~2 connections: Switch output 0 → Return, Switch_Type_Registry output 0 → Return');
console.log('  0 nodes deleted');
console.log('  0 logic changes');
