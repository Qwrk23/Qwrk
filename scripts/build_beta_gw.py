"""
Build Step 2: Apply token auth + workspace resolver to Beta Gateway JSON.
One-time build script — safe to delete after use.
"""
import json

SOURCE = "workflows/NQxb_Gateway_v2_Beta (1).json"

with open(SOURCE) as f:
    data = json.load(f)

# ============================================================
# 1. WEBHOOK: Remove Basic Auth — accept all requests
# ============================================================
for node in data["nodes"]:
    if node["name"] == "NQxb_Gateway_v1__Webhook_In":
        node["parameters"]["authentication"] = "none"
        node.pop("credentials", None)
        print("[1] Webhook: auth=none, credentials removed")

# ============================================================
# 2. NORMALIZE_REQUEST: Add _auth_header passthrough
# ============================================================
for node in data["nodes"]:
    if node["name"] == "NQxb_Gateway_v1__Normalize_Request":
        code = node["parameters"]["jsCode"]
        anchor = 'gateway_version: "v2_resolver",'
        old_block = anchor + "\n      },"
        new_block = (
            anchor
            + "\n      },"
            + "\n"
            + "\n      // --- Auth header passthrough for token-based auth ---"
            + '\n      _auth_header: $json?.headers?.authorization ?? $json?.headers?.Authorization ?? null,'
        )
        if old_block in code:
            code = code.replace(old_block, new_block, 1)
            node["parameters"]["jsCode"] = code
            print("[2] Normalize_Request: _auth_header passthrough added")
        else:
            print("[2] WARNING: anchor not found!")

# ============================================================
# 3. GATEKEEPER: Full replacement — token auth + workspace resolver
# ============================================================
GATEKEEPER_CODE = """// NQxb_Gateway_v2_Beta__Gatekeeper
// Token-based auth + workspace resolver for Beta Gateway
// SECURITY: Hard overwrite of gw_workspace_id -- NEVER trust client value

// --- Token -> Workspace Map (hardcoded for beta scale) ---
const TOKEN_WORKSPACE_MAP = {
  "REPLACE_TOKEN_1": "0af5712b-2534-47c1-8e28-45be4a2131dc",  // Explore Qwrk Demo
  // Add beta user tokens here: "token_string": "workspace_uuid"
};

// --- Action Allowlist (restricted for beta -- no delete/restore/messaging) ---
const ALLOWED_ACTIONS = new Set([
  "artifact.save",
  "artifact.query",
  "artifact.list",
  "artifact.update",
  "artifact.promote",
]);

const TYPE_ALLOWLIST = new Set([
  "project", "journal", "restart", "snapshot",
  "instruction_pack", "branch", "limb", "leaf", "twig"
]);

function asObj(v) {
  return v && typeof v === "object" && !Array.isArray(v) ? v : {};
}

function fail(code, message, httpStatus, details) {
  details = details || {};
  return [{
    json: {
      ok: false,
      _gw_route: "error",
      _http_status: httpStatus,
      error: { code: code, message: message, details: details },
      timestamp: new Date().toISOString(),
    },
  }];
}

// ===== 1. EXTRACT BEARER TOKEN =====
const authHeader = ($json._auth_header || "").trim();
const token = authHeader.startsWith("Bearer ")
  ? authHeader.slice(7).trim()
  : null;

if (!token) {
  return fail(
    "UNAUTHORIZED",
    "Missing or invalid Authorization header. Expected: Bearer <token>",
    401
  );
}

// ===== 2. RESOLVE WORKSPACE FROM TOKEN =====
const workspace_id = TOKEN_WORKSPACE_MAP[token];

if (!workspace_id) {
  return fail("UNAUTHORIZED", "Invalid token. Access denied.", 401);
}

// ===== 3. CHECK ACTION ALLOWLIST =====
const gw_action = ($json.gw_action || "").trim();

if (!gw_action) {
  return fail("VALIDATION_ERROR", "Missing or invalid gw_action", 400,
    { expected: "string", got: typeof gw_action });
}

if (!ALLOWED_ACTIONS.has(gw_action)) {
  return fail(
    "ACTION_FORBIDDEN",
    "Action '" + gw_action + "' is not permitted on the beta gateway.",
    403,
    { allowed_actions: [...ALLOWED_ACTIONS] }
  );
}

// ===== 4. HARD OVERWRITE gw_workspace_id (CRITICAL) =====
// SECURITY: Delete client-provided value FIRST, then set from token.
// This is NOT a fallback. This is unconditional overwrite.
delete $json.gw_workspace_id;
delete $json.workspace_id;

// ===== 5. ARTIFACT VALIDATION =====
const artifact_type = ($json.artifact_type || "").trim() || null;
const artifact_id = $json.artifact_id || null;
const selector = asObj($json.selector);
const extension = asObj($json.extension);
const tags = asObj($json.tags);

if (gw_action === "artifact.query" || gw_action === "artifact.list") {
  if (!artifact_type) {
    return fail("VALIDATION_ERROR", "Missing artifact_type for " + gw_action, 400);
  }
  if (!TYPE_ALLOWLIST.has(artifact_type)) {
    return fail("ARTIFACT_TYPE_NOT_ALLOWED", "artifact_type not allowed", 400,
      { artifact_type: artifact_type, allowed: [...TYPE_ALLOWLIST] });
  }
}

if (gw_action === "artifact.query") {
  if (!artifact_id) {
    return fail("VALIDATION_ERROR", "Missing artifact_id for artifact.query", 400);
  }
}

if (gw_action === "artifact.list") {
  if (selector.limit !== undefined) {
    const n = Number(selector.limit);
    if (!Number.isFinite(n) || n < 1 || n > 100) {
      return fail("VALIDATION_ERROR", "selector.limit out of range (1-100)", 400,
        { limit: selector.limit });
    }
  }
}

if (gw_action === "artifact.update") {
  if (!artifact_type || !TYPE_ALLOWLIST.has(artifact_type)) {
    return fail("VALIDATION_ERROR", "Missing or invalid artifact_type for artifact.update", 400);
  }
  if (!artifact_id) {
    return fail("VALIDATION_ERROR", "Missing artifact_id for artifact.update", 400);
  }

  const hasExtension = Object.keys(extension).length > 0;
  const hasTags = (Array.isArray(tags.add) && tags.add.length > 0) ||
    (Array.isArray(tags.remove) && tags.remove.length > 0);
  const spineFieldCandidates = ["title", "summary", "priority", "lifecycle_status", "parent_artifact_id"];
  const hasSpineFields = spineFieldCandidates.some(function(f) {
    const val = $json[f];
    return val !== null && val !== undefined;
  });

  if (!hasExtension && !hasTags && !hasSpineFields) {
    return fail("VALIDATION_ERROR", "artifact.update requires extension, tags, or spine fields", 400);
  }
}

// ===== 6. BUILD OUTPUT (workspace set from token, not client) =====
const output = Object.assign({}, $json, {
  ok: true,
  _gw_route: "ok",
  gw_action: gw_action,
  gw_workspace_id: workspace_id,   // FROM TOKEN -- not client
  workspace_id: workspace_id,      // FROM TOKEN -- not client
  artifact_type: artifact_type,
  artifact_id: artifact_id,
  selector: selector,
  gateway_meta: {
    processed_at: new Date().toISOString(),
    gateway_version: "v2_beta",
  },
});

// Update-specific fields
if (gw_action === "artifact.update") {
  output.extension = extension;
  output.tags = tags;
  const sf = {};
  if ($json.title !== null && $json.title !== undefined) sf.title = $json.title;
  if ($json.summary !== null && $json.summary !== undefined) sf.summary = $json.summary;
  if ($json.priority !== null && $json.priority !== undefined) sf.priority = $json.priority;
  if ($json.lifecycle_status !== null && $json.lifecycle_status !== undefined) sf.lifecycle_status = $json.lifecycle_status;
  if ($json.parent_artifact_id !== null && $json.parent_artifact_id !== undefined) sf.parent_artifact_id = $json.parent_artifact_id;
  output.spine_fields = Object.keys(sf).length > 0 ? sf : null;
}

// Clean up internal field
delete output._auth_header;

return [{ json: output }];"""

for node in data["nodes"]:
    if node["name"] == "NQxb_Gateway_v2__Gatekeeper":
        node["parameters"]["jsCode"] = GATEKEEPER_CODE.strip()
        print("[3] Gatekeeper: full code replacement -- token auth + hard overwrite")

# ============================================================
# 4. ERROR RESPONSE: Dynamic HTTP status from _http_status
# ============================================================
for node in data["nodes"]:
    if node["name"] == "Error Response":
        node["parameters"]["options"]["responseCode"] = "={{ $json._http_status || 400 }}"
        print("[4] Error Response: dynamic status code (reads _http_status)")

# ============================================================
# SAVE
# ============================================================
with open(SOURCE, "w") as f:
    json.dump(data, f, indent=2)

print("\n[DONE] Beta gateway JSON updated with token auth.")
