"""
Build QXB__Resolve_Semantic_Type_v1 — Reusable Semantic Type Resolver

Creates a standalone n8n sub-workflow that resolves semantic_type_id
(text key or UUID) against qxb_semantic_type_registry.

READ-ONLY: No database mutations. Only registry lookups.

Input contract (via passthrough):
  { "semantic_type_id": "<key_or_uuid_or_null>", "artifact_type": "<type>" }

Output contract:
  Success: { "ok": true, "resolved_semantic_type_id": "<uuid>|null", "resolution_mode": "..." }
  Error:   { "ok": false, "resolved_semantic_type_id": null, "error": { "code", "message", "details" } }

Execute via: python scripts/build_semantic_resolver.py
"""

import json
import uuid
import os

outpath = os.path.join(
    r"c:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel",
    "workflows",
    "QXB__Resolve_Semantic_Type_v1.json"
)

prefix = "QXB__Resolve_Semantic_Type_v1__"

# ============================================================
# NODE 1: In (executeWorkflowTrigger)
# ============================================================
in_id = str(uuid.uuid4())
in_node = {
    "parameters": {
        "inputSource": "passthrough"
    },
    "type": "n8n-nodes-base.executeWorkflowTrigger",
    "typeVersion": 1.1,
    "position": [-1024, 300],
    "id": in_id,
    "name": f"{prefix}In"
}

# ============================================================
# NODE 2: Detect_Input (Code)
# ============================================================
detect_id = str(uuid.uuid4())
detect_code = r"""// QXB__Resolve_Semantic_Type_v1__Detect_Input
// Detect UUID vs text key. Route top-level vs non-top-level.
// Non-lookup paths return complete envelopes (terminal via Switch fallback).

const req = $json;
const semanticTypeId = (req.semantic_type_id ?? '').toString().trim();
const artifactType = (req.artifact_type ?? '').trim();

const TOP_LEVEL_TYPES = ['project', 'snapshot', 'journal', 'restart'];
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// --- Non-top-level types ---
if (!TOP_LEVEL_TYPES.includes(artifactType)) {
  if (!semanticTypeId) {
    // Non-top-level + null/empty: correct, not applicable
    return [{
      json: {
        ok: true,
        resolved_semantic_type_id: null,
        resolution_mode: 'not_applicable',
        _route: 'early_return',
        _resolution_debug: {
          original_value: null,
          artifact_type: artifactType,
          reason: 'non_top_level_type'
        }
      }
    }];
  }
  // Non-top-level + has value: error
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      _route: 'early_return',
      error: {
        code: 'VALIDATION_ERROR',
        message: 'semantic_type_id is not applicable for non-top-level artifact types',
        details: {
          artifact_type: artifactType,
          semantic_type_id: semanticTypeId,
          hint: 'Only project, snapshot, journal, restart support semantic_type_id'
        }
      }
    }
  }];
}

// --- Top-level types ---
if (!semanticTypeId) {
  // Top-level + missing: error (required)
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      _route: 'early_return',
      error: {
        code: 'VALIDATION_ERROR',
        message: 'semantic_type_id is required for top-level artifact types',
        details: {
          artifact_type: artifactType,
          hint: 'Provide a valid registry key (e.g., execution-core, governance) or UUID'
        }
      }
    }
  }];
}

// Top-level + has value: needs registry lookup
const isUuid = UUID_REGEX.test(semanticTypeId);

return [{
  json: {
    _route: 'needs_lookup',
    _semantic_lookup: {
      original_value: semanticTypeId,
      is_uuid: isUuid,
      filter_param: isUuid
        ? 'semantic_type_id=eq.' + semanticTypeId
        : 'key=eq.' + semanticTypeId
    },
    artifact_type: artifactType
  }
}];"""

detect_node = {
    "parameters": {
        "jsCode": detect_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-800, 300],
    "id": detect_id,
    "name": f"{prefix}Detect_Input"
}

# ============================================================
# NODE 3: Switch_Route (Switch)
# ============================================================
switch_id = str(uuid.uuid4())
switch_node = {
    "parameters": {
        "rules": {
            "values": [
                {
                    "conditions": {
                        "options": {
                            "caseSensitive": True,
                            "leftValue": "",
                            "typeValidation": "strict",
                            "version": 3
                        },
                        "conditions": [
                            {
                                "leftValue": "={{ $json._route }}",
                                "rightValue": "needs_lookup",
                                "operator": {
                                    "type": "string",
                                    "operation": "equals"
                                },
                                "id": "needs-lookup"
                            }
                        ],
                        "combinator": "and"
                    }
                }
            ]
        },
        "options": {
            "fallbackOutput": "extra"
        }
    },
    "type": "n8n-nodes-base.switch",
    "typeVersion": 3.4,
    "position": [-576, 300],
    "id": switch_id,
    "name": f"{prefix}Switch_Route"
}

# ============================================================
# NODE 4: Lookup_Registry (HTTP Request)
# ============================================================
lookup_id = str(uuid.uuid4())
lookup_node = {
    "parameters": {
        "url": "=https://npymhacpmxdnkqdzgxll.supabase.co/rest/v1/qxb_semantic_type_registry?{{ $json._semantic_lookup.filter_param }}&limit=1",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "supabaseApi",
        "options": {}
    },
    "type": "n8n-nodes-base.httpRequest",
    "typeVersion": 4.2,
    "position": [-352, 300],
    "id": lookup_id,
    "name": f"{prefix}Lookup_Registry",
    "alwaysOutputData": True,
    "credentials": {
        "supabaseApi": {
            "id": "n4R4JdOIV9zrCGIT",
            "name": "Qwrk Supabase \u2013 Kernel v1"
        }
    },
    "onError": "continueErrorOutput"
}

# ============================================================
# NODE 5: Guard_Result (Code, terminal)
# ============================================================
guard_id = str(uuid.uuid4())
guard_code = r"""// QXB__Resolve_Semantic_Type_v1__Guard_Result
// Validate registry lookup result.
// Handles: not found, inactive, HTTP errors, UUID contract assertion.
// Terminal node — output returns to calling workflow.

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const lookupCtx = $node['QXB__Resolve_Semantic_Type_v1__Detect_Input'].json;
const registryRow = $json;
const originalValue = lookupCtx._semantic_lookup.original_value;
const isUuidInput = lookupCtx._semantic_lookup.is_uuid;
const artifactType = lookupCtx.artifact_type;

// Handle HTTP error objects (from continueErrorOutput)
if (registryRow.errorMessage || registryRow.errorDescription || registryRow.error) {
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Registry lookup failed (HTTP error)',
        details: {
          semantic_type_id: originalValue,
          http_error: registryRow.errorMessage ?? registryRow.errorDescription ?? registryRow.error ?? 'unknown'
        }
      }
    }
  }];
}

// No row found (alwaysOutputData → {} when empty array [])
if (!registryRow || !registryRow.semantic_type_id) {
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      error: {
        code: 'INVALID_SEMANTIC_TYPE',
        message: 'semantic_type_id not found in registry',
        details: {
          semantic_type_id: originalValue,
          hint: 'Provide a valid registry key (e.g., execution-core, governance) or UUID'
        }
      }
    }
  }];
}

// Row found but inactive
if (registryRow.active === false) {
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      error: {
        code: 'SEMANTIC_TYPE_INACTIVE',
        message: 'Target semantic type is inactive in registry',
        details: {
          semantic_type_id: originalValue,
          resolved_uuid: registryRow.semantic_type_id
        }
      }
    }
  }];
}

// Contract assertion: resolved value must be UUID (defense-in-depth)
const resolvedUuid = registryRow.semantic_type_id;
if (!UUID_REGEX.test(resolvedUuid)) {
  return [{
    json: {
      ok: false,
      resolved_semantic_type_id: null,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Registry returned non-UUID semantic_type_id (contract assertion failed)',
        details: {
          raw_value: resolvedUuid,
          original_input: originalValue
        }
      }
    }
  }];
}

// Success — resolved
return [{
  json: {
    ok: true,
    resolved_semantic_type_id: resolvedUuid,
    resolution_mode: isUuidInput ? 'uuid_passthrough' : 'key_to_uuid',
    _resolution_debug: {
      original_value: originalValue,
      is_uuid: isUuidInput,
      resolved_uuid: resolvedUuid,
      artifact_type: artifactType
    }
  }
}];"""

guard_node = {
    "parameters": {
        "jsCode": guard_code
    },
    "type": "n8n-nodes-base.code",
    "typeVersion": 2,
    "position": [-128, 300],
    "id": guard_id,
    "name": f"{prefix}Guard_Result"
}

# ============================================================
# ASSEMBLE WORKFLOW
# ============================================================

nodes = [in_node, detect_node, switch_node, lookup_node, guard_node]

connections = {
    f"{prefix}In": {
        "main": [
            [{"node": f"{prefix}Detect_Input", "type": "main", "index": 0}]
        ]
    },
    f"{prefix}Detect_Input": {
        "main": [
            [{"node": f"{prefix}Switch_Route", "type": "main", "index": 0}]
        ]
    },
    f"{prefix}Switch_Route": {
        "main": [
            # [0] needs_lookup → Lookup_Registry
            [{"node": f"{prefix}Lookup_Registry", "type": "main", "index": 0}],
            # [1] fallback (early_return) → terminal (no downstream, returns to caller)
            []
        ]
    },
    f"{prefix}Lookup_Registry": {
        "main": [
            # [0] success → Guard_Result
            [{"node": f"{prefix}Guard_Result", "type": "main", "index": 0}],
            # [1] HTTP error → Guard_Result (handles error objects)
            [{"node": f"{prefix}Guard_Result", "type": "main", "index": 0}]
        ]
    }
    # Guard_Result has no downstream — terminal node
}

workflow = {
    "name": "QXB__Resolve_Semantic_Type_v1",
    "nodes": nodes,
    "connections": connections,
    "active": False,
    "settings": {
        "executionOrder": "v1"
    },
    "versionId": str(uuid.uuid4()),
    "tags": []
}

# ============================================================
# WRITE
# ============================================================

with open(outpath, 'w', encoding='utf-8') as f:
    json.dump(workflow, f, indent=2, ensure_ascii=True)

print(f"SUCCESS: Resolver workflow created -> {outpath}")
print(f"  Nodes: {len(nodes)}")
print(f"  1. {prefix}In (executeWorkflowTrigger, passthrough)")
print(f"  2. {prefix}Detect_Input (Code: UUID/key detection + top-level routing)")
print(f"  3. {prefix}Switch_Route (Switch: needs_lookup vs early_return)")
print(f"  4. {prefix}Lookup_Registry (HTTP Request: PostgREST dual-mode)")
print(f"  5. {prefix}Guard_Result (Code: validate row, resolve UUID, terminal)")
print(f"")
print(f"  Connections:")
print(f"    In -> Detect_Input -> Switch_Route")
print(f"    Switch_Route[0] (needs_lookup) -> Lookup_Registry -> Guard_Result (terminal)")
print(f"    Switch_Route[1] (fallback/early_return) -> (terminal, returns to caller)")
print(f"    Lookup_Registry[1] (HTTP error) -> Guard_Result (handles error objects)")
print(f"")
print(f"  NEXT STEP: Import to n8n, record the assigned workflow ID")
print(f"  Then run: python scripts/build_resolver_integration.py --resolver-id <ID>")
