const fs = require('fs');
const j = JSON.parse(fs.readFileSync('workflows/NQxb_Artifact_List_v1 (28).json', 'utf8'));

// 1. Basic counts
console.log('Node count:', j.nodes.length);
const connKeys = Object.keys(j.connections);
let edgeCount = 0;
for (const val of Object.values(j.connections)) {
  for (const outs of val.main) {
    edgeCount += outs.length;
  }
}
console.log('Connection source nodes:', connKeys.length);
console.log('Total edges:', edgeCount);

// 2. Validate all connection references
const names = new Set(j.nodes.map(n => n.name));
let ok = true;
for (const [src, val] of Object.entries(j.connections)) {
  if (!names.has(src)) { console.log('BAD SRC:', src); ok = false; }
  for (const outs of val.main) {
    for (const c of outs) {
      if (!names.has(c.node)) { console.log('BAD TGT:', c.node, 'from', src); ok = false; }
    }
  }
}
if (ok) console.log('All connection references valid');

// 3. Switch_ArtifactType cases
const sw = j.nodes.find(n => n.name === 'NQxb_Artifact_List_v1__Switch_ArtifactType');
console.log('\nSwitch_ArtifactType cases:', sw.parameters.rules.values.length);
sw.parameters.rules.values.forEach((v, i) => {
  console.log('  [' + i + ']', v.conditions.conditions[0].rightValue);
});

// 4. Switch outputs
const swConn = j.connections['NQxb_Artifact_List_v1__Switch_ArtifactType'].main;
console.log('\nSwitch outputs:');
swConn.forEach((outs, i) => console.log('  [' + i + '] ->', outs.map(c => c.node).join(', ')));

// 5. Combine_Hydrated_Results numberInputs
const combine = j.nodes.find(n => n.name === 'NQxb_Artifact_List_v1__Combine_Hydrated_Results');
console.log('\nCombine numberInputs:', combine.parameters.numberInputs);

// 6. Combine input indices
console.log('\nCombine input indices:');
for (const [src, val] of Object.entries(j.connections)) {
  for (const outs of val.main) {
    for (const c of outs) {
      if (c.node === 'NQxb_Artifact_List_v1__Combine_Hydrated_Results') {
        console.log('  input[' + c.index + '] <-', src);
      }
    }
  }
}

// 7. New nodes present
const newNodes = [
  'NQxb_Artifact_List_v1__Spine_Only_List_Merge',
  'NQxb_Artifact_List_v1__Explode_Limb_Page',
  'NQxb_Artifact_List_v1__DB_Get_Limb_Extension',
  'NQxb_Artifact_List_v1__Merge_Limb'
];
console.log('\nNew nodes:');
newNodes.forEach(name => {
  const found = j.nodes.find(n => n.name === name);
  console.log('  ' + name + ':', found ? 'PRESENT' : 'MISSING');
});

// 8. JSON validity
try {
  JSON.stringify(j);
  console.log('\nJSON round-trip: OK');
} catch (e) {
  console.log('\nJSON round-trip: FAILED -', e.message);
}
