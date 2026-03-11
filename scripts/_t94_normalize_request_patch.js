// T94: Normalize_Request patch for twig lifecycle_status
// 
// CONTEXT: The Update workflow's Normalize_Request extracts spine fields
// (title, summary, priority) from the request. Twig lifecycle transitions
// require lifecycle_status to also be extracted as a spine field.
//
// CHANGE: Add lifecycle_status extraction after the existing spine field block.
// Only extracted when artifact_type === 'twig' to prevent bypassing 
// artifact.promote for projects.
//
// LOCATION: After the existing spine fields block in Normalize_Request:
//   if ('priority' in req) spine_fields.priority = req.priority;
//
// ADD THIS BLOCK:

// T94: lifecycle_status extraction (twig-only)
// Twig lifecycle transitions go through artifact.update, not artifact.promote.
// Guard: Check_Mutability_Rules v9 blocks lifecycle_status for non-twig types.
if ('lifecycle_status' in req && artifact_type === 'twig') {
  spine_fields.lifecycle_status = req.lifecycle_status;
}

// The rest of Normalize_Request remains unchanged.
// The spine PATCH path already writes all fields in spine_fields to qxb_artifact.
// The DB CHECK constraint (qxb_artifact_twig_lifecycle_check) validates allowed values.
// Check_Mutability_Rules v9 validates transition order (proposed -> active -> promoted | pruned).
