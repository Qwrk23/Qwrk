const fs = require('fs');
const j = JSON.parse(fs.readFileSync('workflows/NQxb_Artifact_Query_v1 (18).json', 'utf8'));
const names = new Set(j.nodes.map(n => n.name));
let ok = true;
for (const [src, val] of Object.entries(j.connections)) {
  if (names.has(src) === false) { console.log('BAD SRC:', src); ok = false; }
  for (const outs of val.main) {
    for (const c of outs) {
      if (names.has(c.node) === false) { console.log('BAD TGT:', c.node, 'from', src); ok = false; }
    }
  }
}
if (ok) console.log('All connection references valid');

const swQ = j.nodes.find(n => n.name === 'NQxb_Gateway_v1__Switch_ArtifactType_ForQuery');
console.log('Switch_ArtifactType_ForQuery cases:', swQ.parameters.rules.values.length);

const swM = j.nodes.find(n => n.name === 'NQxb_Gateway_v1__Switch_SpineType_Matches_RequestType');
console.log('Switch_SpineType_Matches_RequestType cases:', swM.parameters.rules.values.length);

const ret = j.nodes.find(n => n.name === 'NQxb_Artifact_Query_v1__Return');
console.log('Return numberInputs:', ret.parameters.numberInputs);

// Verify specific routing
const conn = j.connections;
const sw1Main = conn['NQxb_Gateway_v1__Switch_ArtifactType_ForQuery'].main;
console.log('\nSwitch1 outputs:');
sw1Main.forEach((outs, i) => console.log('  [' + i + '] ->', outs.map(c => c.node).join(', ')));

const sw2Main = conn['NQxb_Gateway_v1__Switch_SpineType_Matches_RequestType'].main;
console.log('\nSwitch2 outputs:');
sw2Main.forEach((outs, i) => console.log('  [' + i + '] ->', outs.map(c => c.node).join(', ')));

// Verify Return input indices used
console.log('\nReturn input indices:');
for (const [src, val] of Object.entries(conn)) {
  for (const outs of val.main) {
    for (const c of outs) {
      if (c.node === 'NQxb_Artifact_Query_v1__Return') {
        console.log('  input[' + c.index + '] <- ' + src);
      }
    }
  }
}
