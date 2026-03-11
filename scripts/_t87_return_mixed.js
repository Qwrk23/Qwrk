// NQxb_Artifact_Update_v1__Return_Mixed_Ack
// T87: Terminal acknowledgment for spine_only and mixed update modes

const item = $json;

// PostgREST returns array with updated row via Prefer: return=representation
// But n8n HTTP Request may unwrap it. Handle both cases.
const updated = Array.isArray(item) ? item[0] : item;

const result = {
  ok: true,
  operation: "MIXED_UPDATE",
  artifact_id: updated.artifact_id ?? item.artifact_id,
  workspace_id: updated.workspace_id ?? item.workspace_id,
  artifact_type: updated.artifact_type ?? item.artifact_type,
  version: updated.version ?? null,
  _update_mode: item._update_mode ?? "mixed",
};

// Include tag changes if this was a mixed update
if (item._tag_changes) {
  result._tag_changes = item._tag_changes;
}

// Include spine fields that were updated
if (item._spine_patch) {
  const patchKeys = Object.keys(item._spine_patch).filter(k => k !== 'version' && k !== 'tags');
  if (patchKeys.length > 0) {
    result._spine_fields_updated = patchKeys;
  }
}

return [{ json: result }];