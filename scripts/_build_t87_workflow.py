"""Build T87 Update workflow - spine field forwarding + mixed update support."""
import json, sys

sys.stdout.reconfigure(encoding='utf-8')

with open('workflows/NQxb_Artifact_Update_v1__T87.json', 'r', encoding='utf-8') as f:
    wf = json.load(f)

PREFIX = 'NQxb_Artifact_Update_v1__'

def find_node(name):
    full = PREFIX + name
    for i, n in enumerate(wf['nodes']):
        if n['name'] == full:
            return i, n
    return None, None


# ============================================================
# 1. MODIFY Normalize_Request (v3 -- spine fields forwarding)
# ============================================================
idx_nr, nr_node = find_node('Normalize_Request')
nr_code = nr_node['parameters']['jsCode']

# Add v3 comment
nr_code = nr_code.replace(
    '// v2: Tags forwarding (T41)',
    '// v2: Tags forwarding (T41)
// v3: T87 — Spine fields forwarding (title, summary, priority)'
)

# Insert spine_fields extraction before the canonical output
OLD_CANONICAL_START = 'const canonical = {'
SPINE_EXTRACT = """// T87: Spine fields extraction (title, summary, priority)
// Only include keys explicitly present in request (preserve null vs absent)
const spine_fields = {};
if ('title' in req) spine_fields.title = req.title;
if ('summary' in req) spine_fields.summary = req.summary;
if ('priority' in req) spine_fields.priority = req.priority;
const hasSpineFields = Object.keys(spine_fields).length > 0;

const canonical = {"""

nr_code = nr_code.replace(OLD_CANONICAL_START, SPINE_EXTRACT, 1)

# Add spine_fields to canonical output (after tags line)
nr_code = nr_code.replace(
    '  tags: tags,
  deleted_at:',
    '  tags: tags,
  spine_fields: hasSpineFields ? spine_fields : null,
  deleted_at:'
)

# Add debug fields
nr_code = nr_code.replace(
    '  has_extension: Object.keys(canonical.extension).length > 0,',
    '  has_extension: Object.keys(canonical.extension).length > 0,
  has_spine_fields: hasSpineFields,
  spine_field_keys: hasSpineFields ? Object.keys(spine_fields) : [],'
)

nr_node['parameters']['jsCode'] = nr_code
print('1a. Modified Normalize_Request (v3 — spine fields forwarding)')

# 1b. Modify Detect_Semantic_Route — use spine_fields object instead of raw field detection
idx_dr, dr_node = find_node('Detect_Semantic_Route')
dr_code = dr_node['parameters']['jsCode']

# Update spine field detection to use the new spine_fields object
OLD_SPINE_DETECT = "const spineFields = ['summary','priority'];"
if OLD_SPINE_DETECT in dr_code:
    # Old approach detected individual fields; new approach uses spine_fields object
    dr_code = dr_code.replace(
        OLD_SPINE_DETECT,
        "// T87: spine fields now in dedicated object
const spineFieldsObj = normalizeNode.spine_fields || {};"
    )
    dr_code = dr_code.replace(
        "const spinePresent = spineFields.filter(f => f in normalizeNode);",
        "const spinePresent = Object.keys(spineFieldsObj);"
    )
    dr_node['parameters']['jsCode'] = dr_code
    print('1b. Modified Detect_Semantic_Route (uses spine_fields object)')
else:
    print('1b. Detect_Semantic_Route — checking alternative patterns...')
    if "spine_fields" not in dr_code:
        print('    WARNING: Could not find spine field detection to patch')
    else:
        print('    Already patched')

# ============================================================
# 2. PATCH Validate_Request -- accept spine_fields
# ============================================================
idx_vr, vr_node = find_node('Validate_Request')
vr_code = vr_node['parameters']['jsCode']

OLD_VR = """if (!hasExtension && !hasTags) {
  errors.push({ field: "extension_or_tags", reason: "required", expected: "at least one of: extension object, tags object" });
}"""
NEW_VR = """const hasSpineFields = req.spine_fields !== null && req.spine_fields !== undefined && Object.keys(req.spine_fields).length > 0;

if (!hasExtension && !hasTags && !hasSpineFields) {
  errors.push({ field: "extension_or_tags_or_spine", reason: "required", expected: "at least one of: extension object, tags object, spine_fields object" });
}"""

if OLD_VR in vr_code:
    vr_code = vr_code.replace(OLD_VR, NEW_VR)
    vr_node['parameters']['jsCode'] = vr_code
    print('2. Patched Validate_Request (accepts spine_fields)')
else:
    print('2. WARNING: Could not find Validate_Request check to patch')

# ============================================================
# 3. MODIFY Check_Mutability_Rules
# ============================================================
idx, node = find_node('Check_Mutability_Rules')

NEW_CHECK_MUTABILITY = open('scripts/_t87_check_mutability.js', 'r', encoding='utf-8').read()

node['parameters']['jsCode'] = NEW_CHECK_MUTABILITY
print('3. Modified Check_Mutability_Rules')

# ============================================================
# 4. Add new Switch_Update_Mode rules
# ============================================================
idx_sw, sw_node = find_node('Switch_Update_Mode')
rules = sw_node['parameters']['rules']['values']

spine_only_rule = {
    "conditions": {
        "options": {"caseSensitive": True, "leftValue": "", "typeValidation": "strict", "version": 3},
        "conditions": [{
            "leftValue": "={{ $json._update_mode }}",
            "rightValue": "spine_only",
            "operator": {"type": "string", "operation": "equals"},
            "id": "route-spine-only"
        }],
        "combinator": "and"
    }
}

mixed_rule = {
    "conditions": {
        "options": {"caseSensitive": True, "leftValue": "", "typeValidation": "strict", "version": 3},
        "conditions": [{
            "leftValue": "={{ $json._update_mode }}",
            "rightValue": "mixed",
            "operator": {"type": "string", "operation": "equals"},
            "id": "route-mixed"
        }],
        "combinator": "and"
    }
}

rules.append(spine_only_rule)
rules.append(mixed_rule)
print(f'4. Added spine_only + mixed rules (now {len(rules)} rules)')

# ============================================================
# 5. Add 3 new nodes
# ============================================================

COMPUTE_MIXED_CODE = open('scripts/_t87_compute_mixed.js', 'r', encoding='utf-8').read()
RETURN_MIXED_CODE = open('scripts/_t87_return_mixed.js', 'r', encoding='utf-8').read()

_, db_tags_node = find_node('DB_Update_Spine_Tags')
creds = db_tags_node.get('credentials', {})

compute_mixed = {
    "parameters": {
        "jsCode": COMPUTE_MIXED_CODE,
        "mode": "runOnceForAllItems"
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [0, -400],
    "id": "compute-mixed-spine-t87",
    "name": PREFIX + "Compute_Mixed_Spine_Update"
}

db_mixed = {
    "parameters": {
        "method": "PATCH",
        "url": "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_artifact?artifact_id=eq.{{ $json.artifact_id }}&workspace_id=eq.{{ $json.workspace_id }}&version=eq.{{ $json.current_version }}",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "sendHeaders": True,
        "headerParameters": {
            "parameters": [
                {"name": "Prefer", "value": "return=representation"}
            ]
        },
        "sendBody": True,
        "specifyBody": "json",
        "jsonBody": "={{ JSON.stringify($json._spine_patch) }}",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [224, -400],
    "id": "db-mixed-spine-t87",
    "name": PREFIX + "DB_Update_Mixed_Spine",
    "alwaysOutputData": True,
    "credentials": creds,
    "onError": "continueErrorOutput"
}

return_mixed = {
    "parameters": {
        "jsCode": RETURN_MIXED_CODE,
        "mode": "runOnceForAllItems"
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [448, -400],
    "id": "return-mixed-ack-t87",
    "name": PREFIX + "Return_Mixed_Ack"
}

wf['nodes'].extend([compute_mixed, db_mixed, return_mixed])
print(f'5. Added 3 new nodes (total: {len(wf["nodes"])})')

# ============================================================
# 6. Update connections
# ============================================================
sw_key = PREFIX + 'Switch_Update_Mode'
current_main = wf['connections'][sw_key]['main']

if len(current_main) == 4:
    extension_fallthrough = current_main[3]
    current_main[3] = [{"node": PREFIX + "Compute_Mixed_Spine_Update", "type": "main", "index": 0}]
    current_main.append([{"node": PREFIX + "Compute_Mixed_Spine_Update", "type": "main", "index": 0}])
    current_main.append(extension_fallthrough)
    print(f'6a. Updated Switch_Update_Mode connections ({len(current_main)} outputs)')
else:
    print(f'6a. WARNING: Unexpected count: {len(current_main)}')

compute_key = PREFIX + 'Compute_Mixed_Spine_Update'
db_mixed_key = PREFIX + 'DB_Update_Mixed_Spine'
return_mixed_key = PREFIX + 'Return_Mixed_Ack'

wf['connections'][compute_key] = {
    "main": [[{"node": db_mixed_key, "type": "main", "index": 0}]]
}

wf['connections'][db_mixed_key] = {
    "main": [
        [{"node": return_mixed_key, "type": "main", "index": 0}],
        [{"node": PREFIX + "Return_Error_Passthrough", "type": "main", "index": 0}]
    ]
}
print('6b. Wired: Compute_Mixed -> DB_Update_Mixed -> Return_Mixed_Ack / Error')

# ============================================================
# Save
# ============================================================
with open('workflows/NQxb_Artifact_Update_v1__T87.json', 'w', encoding='utf-8') as f:
    json.dump(wf, f, indent=2, ensure_ascii=False)

print(f'\nFinal node count: {len(wf["nodes"])}')
print('Saved: workflows/NQxb_Artifact_Update_v1__T87.json')
