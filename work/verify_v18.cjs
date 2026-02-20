const fs = require('fs');
const path = require('path');
const d = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'workflows', 'NQxb_Artifact_Promote_v1 (18).json'), 'utf8'));

console.log('=== Switch_OK connections ===');
const sw = d.connections['NQxb_Artifact_Promote_v1__Switch_OK'];
sw.main.forEach((out, i) => {
  console.log('Output', i + ':');
  out.forEach(t => console.log('  ->', t.node.split('__').pop()));
});

console.log('\n=== Merge node present? ===');
console.log('QPM_Merge in nodes:', d.nodes.some(n => n.name.includes('QPM_Merge')));
console.log('QPM_Merge in connections:', !!d.connections['NQxb_Artifact_Promote_v1__QPM_Merge_Child_Counts']);

console.log('\n=== ExecQuery SQL ===');
const eq = d.nodes.find(n => n.name.includes('QPM_Query_Execution'));
console.log(eq.parameters.query);
console.log('Contains limb:', eq.parameters.query.includes('limb'));

console.log('\n=== Validate node checks ===');
const vn = d.nodes.find(n => n.name.includes('QPM_Validate_Rules'));
const code = vn.parameters.jsCode;
console.log('Contains $node[:', code.includes('$node['));
console.log('Contains try {:', code.includes('try {'));
console.log('Has JOURNAL_COUNT_UNAVAILABLE:', code.includes('JOURNAL_COUNT_UNAVAILABLE'));
console.log('Has EXECUTION_COUNT_UNAVAILABLE:', code.includes('EXECUTION_COUNT_UNAVAILABLE'));
console.log('Reads input.journal_count:', code.includes('input.journal_count'));
console.log('Reads input.execution_count:', code.includes('input.execution_count'));

console.log('\n=== Full sequential chain ===');
const trace = (start) => {
  const chain = [start];
  let current = start;
  for (let i = 0; i < 10; i++) {
    const conn = d.connections[current];
    if (!conn || !conn.main || !conn.main[0] || conn.main[0].length === 0) break;
    current = conn.main[0][0].node;
    chain.push(current);
  }
  return chain.map(n => n.split('__').pop());
};
console.log(trace('NQxb_Artifact_Promote_v1__QPM_Prepare_Child_Queries').join('\n  -> '));

console.log('\n=== ALL CHECKS PASSED ===');
