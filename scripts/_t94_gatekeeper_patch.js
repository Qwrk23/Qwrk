// T94: Gateway Gatekeeper patches for twig artifact type
// 
// The Gateway Gatekeeper (NQxb_Gateway_v1__Gatekeeper_MVP_OwnerOnly) has 3 locations
// that need updating to support twig:
//
// ============================================================================
// PATCH 1: TYPE_ALLOWLIST — add 'twig'
// ============================================================================
// FIND:
//   const TYPE_ALLOWLIST = new Set([
//     "project",
//     "journal",
//     "restart",
//     "snapshot",
//     "instruction_pack",
//     "branch",
//     "limb",
//     "leaf",
//   ]);
//
// REPLACE WITH:
//   const TYPE_ALLOWLIST = new Set([
//     "project",
//     "journal",
//     "restart",
//     "snapshot",
//     "instruction_pack",
//     "branch",
//     "limb",
//     "leaf",
//     "twig",
//   ]);

// ============================================================================
// PATCH 2: spineFieldCandidates in artifact.update validation — add lifecycle_status
// ============================================================================
// FIND:
//   const spineFieldCandidates = ["title", "summary", "priority"];
//
// REPLACE WITH:
//   const spineFieldCandidates = ["title", "summary", "priority", "lifecycle_status"];

// ============================================================================
// PATCH 3: spine_fields pass-through at bottom — add lifecycle_status
// ============================================================================
// FIND (in the PASS THROUGH section):
//   spine_fields: (() => {
//     const sf = {};
//     if ($json?.title !== null && $json?.title !== undefined) sf.title = $json.title;
//     if ($json?.summary !== null && $json?.summary !== undefined) sf.summary = $json.summary;
//     if ($json?.priority !== null && $json?.priority !== undefined) sf.priority = $json.priority;
//     return Object.keys(sf).length > 0 ? sf : null;
//   })(),
//
// REPLACE WITH:
//   spine_fields: (() => {
//     const sf = {};
//     if ($json?.title !== null && $json?.title !== undefined) sf.title = $json.title;
//     if ($json?.summary !== null && $json?.summary !== undefined) sf.summary = $json.summary;
//     if ($json?.priority !== null && $json?.priority !== undefined) sf.priority = $json.priority;
//     // T94: lifecycle_status extraction (twig lifecycle transitions via artifact.update)
//     if ($json?.lifecycle_status !== null && $json?.lifecycle_status !== undefined) sf.lifecycle_status = $json.lifecycle_status;
//     return Object.keys(sf).length > 0 ? sf : null;
//   })(),
//
// NOTE: lifecycle_status is extracted for ALL types here, but Check_Mutability_Rules v9
// guards against non-twig types at section 2a.5 (PROMOTE_ONLY rejection).
// This is defense-in-depth: Gatekeeper extracts, Mutability Rules validates.
