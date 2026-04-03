"""
build_payload_build_v1.py — Patch Gateway v2 (4) -> v2 (5)
Adds payload.build action to Gateway

Changes:
  1. Gatekeeper: Add "payload.build" to ACTION_ALLOWLIST
  2. Switch_Action: Add case 10 for "payload.build"
  3. New Code node: NQxb_Gateway__Payload_Builder
  4. New Respond node: NQxb_Gateway__Respond_Build
  5. Wire: Switch_Action[10] -> Payload_Builder -> Respond_Build

Source: Leaf 2.1 spec (eaf3c349), Branch 2 (03fcfc9e)
"""

import json
import shutil
import uuid

GW_INPUT = "workflows/NQxb_Gateway_v2 (4).json"
GW_OUTPUT = "workflows/NQxb_Gateway_v2 (5).json"
GW_ARCHIVE = "workflows/Archive/NQxb_Gateway_v2 (4)__pre-payload-build__2026-04-03.json"

# ─── Load ────────────────────────────────────────────────────────────

with open(GW_INPUT, "r", encoding="utf-8") as f:
    gw = json.load(f)

print(f"Loaded: {GW_INPUT}")
print(f"Nodes: {len(gw['nodes'])}")

# ─── 1. Patch Gatekeeper ACTION_ALLOWLIST ────────────────────────────

gatekeeper = None
for n in gw["nodes"]:
    if "Gatekeeper" in n.get("name", ""):
        gatekeeper = n
        break

assert gatekeeper, "Gatekeeper node not found"

old_allowlist = '"messaging.create_calendar_event",'
new_allowlist = '"messaging.create_calendar_event",\n  "payload.build",'

assert old_allowlist in gatekeeper["parameters"]["jsCode"], "ACTION_ALLOWLIST marker not found"
gatekeeper["parameters"]["jsCode"] = gatekeeper["parameters"]["jsCode"].replace(
    old_allowlist, new_allowlist, 1
)
print("[OK] Gatekeeper: payload.build added to ACTION_ALLOWLIST")

# ─── 2. Patch Switch_Action: add case 10 ────────────────────────────

switch_node = None
for n in gw["nodes"]:
    if "Switch_Action" in n.get("name", ""):
        switch_node = n
        break

assert switch_node, "Switch_Action node not found"

# Add new condition for payload.build
new_condition = {
    "conditions": {
        "options": {
            "caseSensitive": True,
            "leftValue": "",
            "typeValidation": "strict",
            "version": 3,
        },
        "conditions": [
            {
                "leftValue": "={{ $json.gw_action }}",
                "rightValue": "payload.build",
                "operator": {"type": "string", "operation": "equals"},
                "id": str(uuid.uuid4()),
            }
        ],
        "combinator": "and",
    },
    "renameOutput": True,
    "outputKey": "payload.build",
}

switch_node["parameters"]["rules"]["values"].append(new_condition)
print(f"[OK] Switch_Action: case 10 (payload.build) added ({len(switch_node['parameters']['rules']['values'])} total)")

# ─── 3. Add Payload Builder Code node ───────────────────────────────

BUILDER_JS = r"""
// payload.build v1.0 — Intent -> Canonical Payload Assembly
// Spec: Leaf 2.1 (eaf3c349) | Branch: 03fcfc9e
// SPEC_VERSION must match spec artifact version
const SPEC_VERSION = '1.0';

// ─── Type Rules (from Save v50 Check_Mutability_Rules + Validate_Request) ───

const TYPE_RULES = {
  project: {
    semantic_type: 'required',
    parent: 'optional',
    content_target: 'spine',
    extension_inject: { lifecycle_stage: 'seed' },
    extension_allowlist: ['lifecycle_stage', 'operational_state', 'state_reason', 'design_spine'],
  },
  journal: {
    semantic_type: 'required',
    parent: 'optional',
    content_target: 'extension.entry_text',
    content_type: 'string',
    extension_allowlist: ['entry_text'],
  },
  snapshot: {
    semantic_type: 'required',
    parent: 'optional',
    content_target: 'extension.payload',
    content_must_be_object: true,
    extension_allowlist: ['payload'],
  },
  restart: {
    semantic_type: 'required',
    parent: 'optional',
    content_target: 'extension.payload',
    content_must_be_object: true,
    extension_allowlist: ['payload'],
  },
  branch: {
    semantic_type: 'forbidden',
    parent: 'required',
    content_target: 'spine',
    extension_allowlist: [],
    default_execution_status: 'not_started',
  },
  leaf: {
    semantic_type: 'forbidden',
    parent: 'required',
    content_target: 'spine',
    extension_allowlist: [],
    default_execution_status: 'not_started',
  },
  limb: {
    semantic_type: 'forbidden',
    parent: 'required',
    content_target: 'spine',
    extension_allowlist: [],
    default_execution_status: 'not_started',
  },
  twig: {
    semantic_type: 'forbidden',
    parent: 'required',
    content_target: 'spine',
    extension_allowlist: [],
    default_execution_status: 'not_started',
    twig_content_required: true,
  },
  instruction_pack: {
    semantic_type: 'forbidden',
    parent: 'optional',
    content_target: 'spine',
    extension_allowlist: ['scope', 'active', 'priority', 'pack_format', 'payload'],
    extension_auto_created: true,
  },
  person: {
    semantic_type: 'required',
    parent: 'optional',
    content_target: 'extension_direct',
    extension_allowlist: [
      'full_name', 'preferred_name', 'relationship_type', 'status', 'pronouns',
      'personal_email', 'work_email', 'mobile_phone', 'work_phone', 'home_phone',
      'preferred_contact_method', 'preferred_contact_channel', 'timezone',
      'company', 'title', 'department', 'importance_level',
      'interaction_frequency', 'last_contacted_at', 'next_follow_up_at', 'do_not_contact',
      'address', 'communication_style', 'what_they_care_about', 'key_facts', 'preferences',
    ],
    person_required: ['full_name', 'preferred_name', 'relationship_type'],
  },
};

const SEMANTIC_TYPES = new Set([
  'governance', 'execution-core', 'infrastructure', 'platform',
  'product', 'alignment', 'sales', 'marketing', 'exploratory',
]);

const VALID_ACTIONS = new Set(['artifact.save', 'artifact.update', 'artifact.promote']);
const VALID_TRANSITIONS = new Set(['seed_to_sapling', 'sapling_to_tree', 'tree_to_archive']);
const CHILD_TYPES = new Set(['branch', 'leaf', 'limb', 'twig']);

// ─── Parse Intent ───

const raw = $json;
const workspace_id = raw.gw_workspace_id; // already resolved by Gatekeeper

const intent = {
  action:        (raw.action || '').trim(),
  type:          (raw.type || raw.artifact_type || '').trim(),
  title:         (raw.title || '').trim(),
  artifact_id:   (raw.artifact_id || '').trim() || null,
  semantic_type: (raw.semantic_type || raw.semantic_type_id || '').trim() || null,
  priority:      raw.priority ?? null,
  tags:          raw.tags || null,
  parent:        (raw.parent || raw.parent_artifact_id || '').trim() || null,
  content:       raw.content ?? null,
  summary:       (raw.summary || '').trim() || null,
  transition:    (raw.transition || '').trim() || null,
  reason:        (raw.reason || '').trim() || null,
  mode:          (raw.mode || 'dry_run').trim(),
  extension:     raw.extension || null,
};

const errors = [];
const warnings = [];

// ─── Validate Action ───

if (!intent.action) {
  errors.push('Missing required field: action');
} else if (!VALID_ACTIONS.has(intent.action)) {
  errors.push(`Unknown action: "${intent.action}". Allowed: ${[...VALID_ACTIONS].join(', ')}`);
}

// ─── Validate Type ───

const typeRule = TYPE_RULES[intent.type];
if (!intent.type) {
  errors.push('Missing required field: type (artifact_type)');
} else if (!typeRule) {
  errors.push(`Unknown artifact_type: "${intent.type}". Allowed: ${Object.keys(TYPE_RULES).join(', ')}`);
}

// ─── Validate Mode ───

if (intent.mode !== 'dry_run' && intent.mode !== 'execute') {
  errors.push(`Invalid mode: "${intent.mode}". Allowed: dry_run, execute`);
}

// Short-circuit on fatal errors
if (errors.length > 0 || !typeRule) {
  return [{
    json: {
      ok: false,
      gw_action: 'payload.build',
      spec_version: SPEC_VERSION,
      mode: intent.mode,
      validation: { errors, warnings },
    }
  }];
}

// ─── Action-Specific Validation ───

if (intent.action === 'artifact.save') {

  // Title required on save
  if (!intent.title) {
    errors.push('Missing required field: title (required for save)');
  }

  // artifact_id forbidden on save
  if (intent.artifact_id) {
    errors.push('artifact_id is FORBIDDEN on save — server generates it');
  }

  // Semantic type
  if (typeRule.semantic_type === 'required') {
    if (!intent.semantic_type) {
      errors.push(`semantic_type is REQUIRED for artifact_type "${intent.type}"`);
    } else if (!SEMANTIC_TYPES.has(intent.semantic_type)) {
      errors.push(`Unknown semantic_type: "${intent.semantic_type}". Allowed: ${[...SEMANTIC_TYPES].join(', ')}`);
    }
  } else if (typeRule.semantic_type === 'forbidden' && intent.semantic_type) {
    errors.push(`semantic_type is FORBIDDEN for artifact_type "${intent.type}"`);
  }

  // Parent requirement
  if (typeRule.parent === 'required' && !intent.parent) {
    errors.push(`parent_artifact_id is REQUIRED for artifact_type "${intent.type}"`);
  }

  // Content validation per type
  if (typeRule.content_must_be_object && intent.content !== null) {
    if (typeof intent.content !== 'object' || Array.isArray(intent.content)) {
      errors.push(`content must be an object for artifact_type "${intent.type}" (not string or array)`);
    } else if (Object.keys(intent.content).length === 0) {
      errors.push(`content must be non-empty for artifact_type "${intent.type}"`);
    }
  }

  // Journal: content should be string (maps to entry_text)
  if (intent.type === 'journal' && intent.content !== null) {
    if (typeof intent.content !== 'string') {
      errors.push('content must be a string for journal (maps to extension.entry_text)');
    } else if (intent.content.trim().length === 0) {
      errors.push('content (entry_text) must be non-empty for journal');
    }
  }

  // Twig content completeness
  if (typeRule.twig_content_required && intent.content) {
    const c = intent.content;
    if (typeof c === 'object' && !Array.isArray(c)) {
      const required = ['idea', 'why_now', 'problem_touched', 'future_hook'];
      for (const field of required) {
        if (!c[field] || (typeof c[field] === 'string' && c[field].trim().length === 0)) {
          errors.push(`Twig content requires non-empty field: "${field}"`);
        }
      }
    }
  }

  // Person required fields
  if (typeRule.person_required && intent.content) {
    const c = intent.content;
    if (typeof c === 'object' && !Array.isArray(c)) {
      for (const field of typeRule.person_required) {
        if (!c[field] || (typeof c[field] === 'string' && c[field].trim().length === 0)) {
          errors.push(`Person requires non-empty field: "${field}"`);
        }
      }
      // Validate JSONB array fields
      for (const arrField of ['key_facts', 'what_they_care_about', 'preferences']) {
        if (c[arrField] !== undefined && c[arrField] !== null && !Array.isArray(c[arrField])) {
          errors.push(`Person field "${arrField}" must be an array (or null)`);
        }
      }
      // Check unknown fields
      const allowedSet = new Set(typeRule.extension_allowlist);
      for (const key of Object.keys(c)) {
        if (!allowedSet.has(key)) {
          errors.push(`Unknown person field: "${key}". Not in extension allowlist.`);
        }
      }
      // Contact info warning
      const contactFields = ['personal_email', 'work_email', 'mobile_phone', 'work_phone', 'home_phone'];
      const hasContact = contactFields.some(f => c[f] && String(c[f]).trim().length > 0);
      if (!hasContact) {
        warnings.push('Person has no contact information; follow-up tracking may be limited');
      }
    }
  }

} else if (intent.action === 'artifact.update') {

  // artifact_id required on update
  if (!intent.artifact_id) {
    errors.push('Missing required field: artifact_id (required for update)');
  }
  if (!intent.type) {
    errors.push('Missing required field: type (required for update)');
  }

} else if (intent.action === 'artifact.promote') {

  // artifact_id required
  if (!intent.artifact_id) {
    errors.push('Missing required field: artifact_id (required for promote)');
  }
  // transition required
  if (!intent.transition) {
    errors.push('Missing required field: transition (required for promote)');
  } else if (!VALID_TRANSITIONS.has(intent.transition)) {
    errors.push(`Invalid transition: "${intent.transition}". Allowed: ${[...VALID_TRANSITIONS].join(', ')}`);
  }
  // reason required
  if (!intent.reason) {
    errors.push('Missing required field: reason (required for promote)');
  } else if (intent.reason.length > 280) {
    errors.push(`reason exceeds 280 characters (${intent.reason.length})`);
  }
}

// Warnings
if (!intent.tags || (Array.isArray(intent.tags) && intent.tags.length === 0)) {
  warnings.push('No tags provided (recommended but not required)');
}
if (intent.priority !== null && (intent.priority < 1 || intent.priority > 5)) {
  warnings.push(`Priority ${intent.priority} outside 1-5 range — will default to 3`);
}
if (intent.content === null && intent.action === 'artifact.save' &&
    !['branch', 'leaf', 'limb'].includes(intent.type)) {
  warnings.push('Content is empty (valid but unusual for this type)');
}

// ─── Early Return on Validation Errors ───

if (errors.length > 0) {
  return [{
    json: {
      ok: false,
      gw_action: 'payload.build',
      spec_version: SPEC_VERSION,
      mode: intent.mode,
      validation: { errors, warnings },
    }
  }];
}

// ─── Assemble Canonical Payload ───

const payload = {};

if (intent.action === 'artifact.save') {

  payload.gw_action = 'artifact.save';
  payload.gw_workspace_id = workspace_id;
  payload.artifact_type = intent.type;
  payload.title = intent.title;

  // Priority (default 3)
  payload.priority = (intent.priority !== null && intent.priority >= 1 && intent.priority <= 5)
    ? intent.priority : 3;

  // Summary
  if (intent.summary) {
    payload.summary = intent.summary;
  }

  // Tags (flat array on save)
  if (intent.tags && Array.isArray(intent.tags) && intent.tags.length > 0) {
    payload.tags = intent.tags;
  }

  // Semantic type (pass human key — Gateway Semantic_Resolver handles key->UUID)
  if (typeRule.semantic_type === 'required') {
    payload.semantic_type_id = intent.semantic_type;
  }

  // Parent
  if (intent.parent) {
    payload.parent_artifact_id = intent.parent;
  }

  // Content routing per type
  const target = typeRule.content_target;

  if (target === 'spine') {
    // Content goes to spine content field
    if (intent.content !== null && intent.content !== undefined) {
      payload.content = intent.content;
    }
    // Extension injection (e.g., project lifecycle_stage)
    if (typeRule.extension_inject) {
      payload.extension = { ...typeRule.extension_inject };
    }
    // Instruction pack: extension auto-created by trigger, don't send extension
    if (typeRule.extension_auto_created) {
      delete payload.extension;
    }

  } else if (target === 'extension.entry_text') {
    // Journal: string content -> extension.entry_text
    payload.extension = { entry_text: intent.content };

  } else if (target === 'extension.payload') {
    // Snapshot/restart: object content -> extension.payload
    payload.extension = { payload: intent.content };

  } else if (target === 'extension_direct') {
    // Person: content fields map directly to extension fields
    if (intent.content && typeof intent.content === 'object') {
      payload.extension = {};
      const allowedSet = new Set(typeRule.extension_allowlist);
      for (const [key, val] of Object.entries(intent.content)) {
        if (allowedSet.has(key)) {
          payload.extension[key] = val;
        }
      }
    }
  }

  // Execution status default for child types
  if (typeRule.default_execution_status) {
    payload.execution_status = typeRule.default_execution_status;
  }

} else if (intent.action === 'artifact.update') {

  payload.gw_action = 'artifact.update';
  payload.gw_workspace_id = workspace_id;
  payload.artifact_type = intent.type;
  payload.artifact_id = intent.artifact_id;

  // Spine fields (only include if provided)
  if (intent.title) payload.title = intent.title;
  if (intent.summary) payload.summary = intent.summary;
  if (intent.priority !== null) payload.priority = intent.priority;

  // Tags (structured format for update)
  if (intent.tags) {
    if (Array.isArray(intent.tags)) {
      // Auto-convert flat array to add format
      payload.tags = { add: intent.tags };
    } else if (typeof intent.tags === 'object') {
      // Already structured { add: [], remove: [] }
      payload.tags = intent.tags;
    }
  }

  // Content (if provided)
  if (intent.content !== null && intent.content !== undefined) {
    payload.content = intent.content;
  }

  // Extension (passthrough if provided)
  if (intent.extension) {
    payload.extension = intent.extension;
  }

} else if (intent.action === 'artifact.promote') {

  payload.gw_action = 'artifact.promote';
  payload.gw_workspace_id = workspace_id;
  payload.artifact_type = intent.type;
  payload.artifact_id = intent.artifact_id;
  payload.transition = intent.transition;
  payload.reason = intent.reason;

}

// ─── Return Result ───

return [{
  json: {
    ok: true,
    gw_action: 'payload.build',
    spec_version: SPEC_VERSION,
    mode: intent.mode,
    target_action: intent.action,
    assembled_payload: payload,
    validation: { errors: [], warnings },
    _meta: {
      type_rule_applied: intent.type,
      content_target: typeRule ? typeRule.content_target : null,
      timestamp: new Date().toISOString(),
    },
  }
}];
""".strip()

builder_node = {
    "parameters": {
        "jsCode": BUILDER_JS,
        "mode": "runOnceForEachItem",
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [560, 1200],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Gateway__Payload_Builder",
}

gw["nodes"].append(builder_node)
print(f"[OK] Added node: NQxb_Gateway__Payload_Builder")

# ─── 4. Add Respond node ────────────────────────────────────────────

respond_node = {
    "parameters": {
        "respondWith": "json",
        "responseBody": "={{ JSON.stringify($json) }}",
        "options": {},
    },
    "type": "n8n-nodes-base.respondToWebhook",
    "typeVersion": 1.5,
    "position": [980, 1200],
    "id": str(uuid.uuid4()),
    "name": "NQxb_Gateway__Respond_Build",
}

gw["nodes"].append(respond_node)
print(f"[OK] Added node: NQxb_Gateway__Respond_Build")

# ─── 5. Wire connections ────────────────────────────────────────────

# Switch_Action output 10 -> Payload_Builder
switch_conn = gw["connections"]["NQxb_Gateway_v1__Switch_Action"]["main"]

# Currently output 10 is the fallback (NQxb_Gateway_v1__Return_Unhandled_Route_Error)
# The fallback uses "fallbackOutput: extra" in the Switch node options,
# which means it fires on its own output. We just need to add our new
# case connection at index 10.
# The fallback output is separate from numbered outputs.
switch_conn.append(
    [{"node": "NQxb_Gateway__Payload_Builder", "type": "main", "index": 0}]
)
print(f"[OK] Switch_Action: output {len(switch_conn)-1} -> Payload_Builder")

# Payload_Builder -> Respond_Build
gw["connections"]["NQxb_Gateway__Payload_Builder"] = {
    "main": [
        [{"node": "NQxb_Gateway__Respond_Build", "type": "main", "index": 0}]
    ]
}
print(f"[OK] Payload_Builder -> Respond_Build")

# ─── Archive + Save ─────────────────────────────────────────────────

shutil.copy2(GW_INPUT, GW_ARCHIVE)
print(f"[OK] Archived: {GW_ARCHIVE}")

with open(GW_OUTPUT, "w", encoding="utf-8") as f:
    json.dump(gw, f, indent=2, ensure_ascii=False)

print(f"[OK] Saved: {GW_OUTPUT}")
print(f"\nTotal nodes: {len(gw['nodes'])}")
print(f"Total switch cases: {len(switch_node['parameters']['rules']['values'])}")
print(f"\nNext steps:")
print(f"  1. Import {GW_OUTPUT} to n8n")
print(f"  2. Activate workflow")
print(f"  3. Test: POST to gateway with gw_action='payload.build'")
