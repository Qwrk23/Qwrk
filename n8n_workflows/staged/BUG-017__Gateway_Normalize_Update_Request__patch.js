// NQxb_Gateway_v1_Normalize_Update_Request
// v2: Pass through tags field for spine-level tag updates (BUG-017)
//
// PATCH INSTRUCTIONS:
// In n8n, edit the "NQxb_Gateway_v1_Normalize_Update_Request" node in NQxb_Gateway_v1
// Replace the entire jsCode with this content.
//
// CHANGE: Added `tags` and `req_tags` fields to the normalized output.
// Tags are passed through as-is from the incoming request to the Update sub-workflow.

const input = $json ?? {};
const extension = input.extension ?? input.req_extension ?? {};
const tags = input.tags ?? null;

return [
  {
    json: {
      gw_action: "artifact.update",
      gw_workspace_id: input.gw_workspace_id ?? input.workspace_id ?? null,
      artifact_type: input.artifact_type ?? input.req_artifact_type ?? null,
      artifact_id: input.artifact_id ?? input.req_artifact_id ?? null,
      extension,
      tags,
      // Freeze the request intent to survive downstream clobbering
      req_gw_workspace_id: input.gw_workspace_id ?? input.workspace_id ?? null,
      req_artifact_type: input.artifact_type ?? input.req_artifact_type ?? null,
      req_artifact_id: input.artifact_id ?? input.req_artifact_id ?? null,
      req_extension: extension,
      req_tags: tags,
      _gw_debug: {
        normalized_by: "NQxb_Gateway_v1_Normalize_Update_Request",
        received_keys: Object.keys(input),
        has_tags: tags !== null,
      },
    },
  },
];
