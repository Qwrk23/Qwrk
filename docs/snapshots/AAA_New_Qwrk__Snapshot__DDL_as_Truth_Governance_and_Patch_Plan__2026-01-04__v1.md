# AAA_New_Qwrk — Snapshot — DDL-as-Truth Governance + Patch Plan (v1)
**Timestamp:** 2026-01-04 (America/Chicago)  
**Snapshot Type:** Governance / Build Hygiene  
**Status:** Locked  
**Build Phase:** Definition → Execution (doc corrections + proof gate)

---

## Snapshot Trigger
Triggers fired:
- Multiple decisions locked
- Phase transition (Schema acquisition → Governed documentation + NoFail templates + proof gates)
- Restarting later would require reconstructing intent/sequencing

What this Snapshot preserves:
- The canonical LIVE DDL “stone tablet”
- The DDL-as-Truth governance rule in CLAUDE.md
- The discovered thorn/user/index mismatches
- The decision to issue a v1.1 patch (no silent overwrites)
- The next proof gate: thorn insert succeeds using v1.1 template

---

## 1) Current Objective
Establish **DDL-as-Truth** as the single authoritative schema source so that all SQL templates and payload mappings are correct “first time, every time,” then patch any doc/template drift discovered against the LIVE DDL.

## 2) Decisions Locked
1. Canonical schema truth is the schema-only dump file: `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`
2. Policy enforcement: Claude Code must reference the canonical DDL before generating SQL; no guessing.
3. Versioning discipline: When derived docs/templates are wrong, create v1.1 patch artifacts and mark v1 as superseded (no silent overwrites).
4. Network reality: For local machine dumping, use Supabase Session Pooler (IPv4 compatible) + SSL.
5. Tooling reality: `pg_dump` must be >= server version (installed pg_dump 17.x due to server 17.x).

## 3) Known Issues Discovered (Against LIVE DDL)
- `Schema_Reference__Kernel_v1__Canonical.md` (v1) missing index documentation and has incorrect columns for:
  - `qxb_artifact_thorn` (documented wrong enums/columns; actual is severity INT 1–5 default 3; status text; resolution_notes text)
  - `qxb_user` (missing status column + wrong nullability assumptions)
- `Kernel_v1__NoFail_Inserts__v1.md` includes a wrong thorn template (uses non-existent thorn columns)

## 4) Files Created/Updated
### Canonical truth
- `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql` (generated locally; verified contains CREATE TABLE for 11 qxb_* tables)

### CC deliverables (commit b28e036) — status
- ✅ `CLAUDE.md`: “Schema Truth Policy — DDL-as-Truth” section added (hard rules + checklist + consequences)
- ⚠️ `docs/schema/Schema_Reference__Kernel_v1__Canonical.md`: incomplete/incorrect as noted above
- ⚠️ `docs/sql_templates/Kernel_v1__NoFail_Inserts__v1.md`: thorn template incorrect

### Planned patch outputs (to be created)
- `docs/schema/Schema_Reference__Kernel_v1__Canonical__v1.1.md`
- `docs/sql_templates/Kernel_v1__NoFail_Inserts__v1.1.md`
- v1 files to be marked SUPERSEDED by v1.1 with pointer to replacement

## 5) Known-Good Commands (KG)
### Verify DDL contains qxb tables
```powershell
Select-String -Path "docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql" -Pattern "CREATE TABLE public.qxb_" | Select-Object -First 20
```

### Local dump via Supabase Session Pooler (pg_dump 17)
```powershell
$env:PGHOST="aws-0-us-west-2.pooler.supabase.com"
$env:PGPORT="5432"
$env:PGDATABASE="postgres"
$env:PGUSER="postgres.npymhacpmxdnkqdzgxll"
$env:PGPASSWORD="<DB_PASSWORD>"
$env:PGSSLMODE="require"

New-Item -ItemType Directory -Force -Path "docs/schema" | Out-Null

& "C:\Program Files\PostgreSQL\17\bin\pg_dump.exe" --schema-only --no-owner --no-privileges `
  --schema=public `
  --table='qxb_*' `
  > "docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql"
```

### Verify file exists
```powershell
Get-Item "docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql" | Select-Object FullName, Length, LastWriteTime
```

## 6) Open Questions
1. Add a CI/automation check later ensuring `Schema_Reference__Canonical` stays consistent with LIVE DDL (Run-stage hardening)?
2. Keep RLS/mutability notes only when directly supported by DDL/policies files (avoid speculative docs)?

## 7) Next 1–2 Actions (Gated)
1. CC generates v1.1 patch (schema reference + NoFail templates) fixing:
   - missing indexes
   - thorn table columns/types
   - qxb_user status + nullability
   - thorn SQL insert template
2. Proof gate: run a thorn insert using v1.1 template in Supabase SQL Editor and confirm success.
