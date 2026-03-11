// NQxb_Artifact_Update_v1__Compute_Mixed_Spine_Update
// T87: Build unified spine PATCH for spine_only and mixed modes
// Handles: title, summary, priority, tags, version increment
// Single atomic PostgREST PATCH to qxb_artifact

const item = $json;
const normalizeNode = item._normalized_request;
const existingArtifact = item._existing_artifact;

const spineFields = normalizeNode.spine_fields || {};
const tags = normalizeNode.tags || null;
const currentVersion = existingArtifact.version ?? 0;

// Build the spine patch object
const patch = {};

// Spine fields (title, summary, priority)
if ('title' in spineFields) patch.title = spineFields.title;
if ('summary' in spineFields) patch.summary = spineFields.summary;
if ('priority' in spineFields) patch.priority = spineFields.priority;

// Tag merge (if mixed mode)
let tagChanges = null;
if (tags) {
  const currentTags = existingArtifact.tags || [];
  const addTags = tags.add || [];
  const removeTags = tags.remove || [];

  // Start with current, remove specified, add specified
  let merged = currentTags.filter(t => !removeTags.includes(t));
  for (const t of addTags) {
    if (!merged.includes(t)) merged.push(t);
  }

  patch.tags = JSON.stringify(merged);
  tagChanges = {
    added: addTags.filter(t => !currentTags.includes(t)),
    removed: removeTags.filter(t => currentTags.includes(t)),
    final: merged,
  };
}

// Version increment (always)
patch.version = currentVersion + 1;

return [{
  json: {
    artifact_id: existingArtifact.artifact_id,
    workspace_id: existingArtifact.workspace_id,
    artifact_type: existingArtifact.artifact_type,
    current_version: currentVersion,
    _spine_patch: patch,
    _tag_changes: tagChanges,
    _update_mode: item._update_mode,
    _gw_debug: item._gw_debug,
    gw_action: item.gw_action,
    gw_workspace_id: item.gw_workspace_id,
  }
}];