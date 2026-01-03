Execution bundle order (safe run sequence)

Prereq (once per database): enable pgcrypto for gen_random_uuid()

Run tables in dependency order:

Qxb_User

Qxb_Workspace

Qxb_Workspace_User

Qxb_Artifact

Qxb_Artifact_Project

Qxb_Artifact_Snapshot

Qxb_Artifact_Restart

Qxb_Artifact_Journal

Qxb_Artifact_Event

Apply policies last:

RLS_Policies__Kernel_v1

(Optional) Run KGB SQL pack immediately after policies to confirm baseline.