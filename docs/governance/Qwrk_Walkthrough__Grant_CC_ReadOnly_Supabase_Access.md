# Qwrk Walkthrough — Grant Claude Code (CC) Read-Only Supabase Access

**Purpose**: Walk Master Joel through granting Claude Code read-only access to Qwrk's Brain (Supabase database).

**Audience**: Qwrk Chat (to guide Master Joel)

**Context**: Per CC Governance Model, CC should have read-only database access to query Qwrk artifacts, schemas, and metadata without write permissions.

**Security**: Read-only role (SELECT only), no INSERT/UPDATE/DELETE/DDL permissions.

---

## Prerequisites (Verify First)

Before starting, confirm Master Joel has:
- ✅ Supabase project URL (e.g., `https://[project-ref].supabase.co`)
- ✅ Admin access to Supabase dashboard
- ✅ Access to SQL Editor in Supabase dashboard
- ✅ Understands Supabase RLS (Row Level Security) is still enforced for read-only user

---

## Step-by-Step Guide for QP1 to Walk Master Joel Through

### Step 1: Open Supabase SQL Editor

**Instructions for Master Joel:**

1. Log into Supabase dashboard: https://supabase.com/dashboard
2. Select the **Qwrk Kernel v1** project
3. Navigate to **SQL Editor** (left sidebar)
4. Click **New Query** to open a blank SQL editor

**Qwrk Checkpoint**: Confirm Master Joel is in SQL Editor with blank query ready.

---

### Step 2: Create Read-Only Database Role

**Instructions for Master Joel:**

Copy and paste the following SQL into the SQL Editor, then click **Run**:

```sql
-- Create read-only role for Claude Code (CC)
CREATE ROLE cc_readonly WITH LOGIN PASSWORD 'GENERATE_STRONG_PASSWORD_HERE';

-- Grant CONNECT privilege to database
GRANT CONNECT ON DATABASE postgres TO cc_readonly;

-- Grant USAGE on public schema
GRANT USAGE ON SCHEMA public TO cc_readonly;

-- Grant SELECT on all existing tables in public schema
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cc_readonly;

-- Grant SELECT on all future tables in public schema (auto-grant)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO cc_readonly;

-- Grant USAGE on all sequences (for reading serial/uuid columns)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO cc_readonly;

-- Verify role created
SELECT rolname, rolcanlogin, rolsuper FROM pg_roles WHERE rolname = 'cc_readonly';
```

**IMPORTANT for Master Joel**:
- Replace `'GENERATE_STRONG_PASSWORD_HERE'` with a strong random password
- **Save this password securely** (you'll share it with CC later)
- Recommended password generator: https://passwordsgenerator.net/ (use 32+ chars)

**Expected Result**: Query executes successfully, final SELECT shows:
```
rolname      | rolcanlogin | rolsuper
-------------|-------------|----------
cc_readonly  | t           | f
```

**Qwrk Checkpoint**: Confirm Master Joel sees `rolcanlogin = t` (true) and `rolsuper = f` (false).

---

### Step 3: Verify Read-Only Permissions (Test)

**Instructions for Master Joel:**

Run this verification SQL to confirm read-only role has correct permissions:

```sql
-- Test 1: Check SELECT permission on qxb_artifact (should succeed)
SELECT has_table_privilege('cc_readonly', 'qxb_artifact', 'SELECT') AS can_select;

-- Test 2: Check INSERT permission on qxb_artifact (should be FALSE)
SELECT has_table_privilege('cc_readonly', 'qxb_artifact', 'INSERT') AS can_insert;

-- Test 3: Check UPDATE permission on qxb_artifact (should be FALSE)
SELECT has_table_privilege('cc_readonly', 'qxb_artifact', 'UPDATE') AS can_update;

-- Test 4: Check DELETE permission on qxb_artifact (should be FALSE)
SELECT has_table_privilege('cc_readonly', 'qxb_artifact', 'DELETE') AS can_delete;
```

**Expected Results**:
```
can_select: true
can_insert: false
can_update: false
can_delete: false
```

**Qwrk Checkpoint**: Confirm all four tests return expected values.

---

### Step 4: Get Connection Details for CC

**Instructions for Master Joel:**

Gather these connection details to share with Claude Code:

1. **Database Host**:
   - Go to **Project Settings** → **Database**
   - Copy **Host** (e.g., `db.[project-ref].supabase.co`)

2. **Database Name**: `postgres` (default for Supabase)

3. **Database Port**: `5432` (default PostgreSQL port)

4. **Username**: `cc_readonly`

5. **Password**: [The password you created in Step 2]

6. **Connection String** (optional, for convenience):
   ```
   postgresql://cc_readonly:[PASSWORD]@db.[project-ref].supabase.co:5432/postgres
   ```

**Qwrk Checkpoint**: Confirm Master Joel has all 5 connection details written down securely.

---

### Step 5: Share Credentials with CC (Secure Method)

**Instructions for Master Joel:**

Choose one of these secure methods to share credentials with Claude Code:

**Option A: Paste directly into Claude Code session (recommended for MVP)**
- Open Claude Code CLI
- Paste connection details directly into a message
- CC will acknowledge receipt and can test immediately
- **Note**: Credentials are not persisted between sessions; you may need to re-share

**Option B: Environment variable (for production)**
- Add to `.env` file in repo root (ensure `.env` is in `.gitignore`):
  ```
  QWRK_DB_HOST=db.[project-ref].supabase.co
  QWRK_DB_NAME=postgres
  QWRK_DB_PORT=5432
  QWRK_DB_USER=cc_readonly
  QWRK_DB_PASSWORD=[password]
  ```
- CC can read from environment variables in future sessions

**Option C: Config file (not recommended for passwords)**
- Only use for non-sensitive connection details
- Password should always be in `.env` or provided directly

**Qwrk Checkpoint**: Confirm Master Joel has chosen a method and is ready to share.

---

### Step 6: Test Connection from CC

**Instructions for Qwrk to relay to CC (via Master Joel):**

Once Master Joel shares credentials, ask CC to test the connection with:

**Test Query (CC to run):**
```sql
SELECT
  artifact_type,
  COUNT(*) as count
FROM qxb_artifact
GROUP BY artifact_type
ORDER BY count DESC;
```

**Expected CC Response**:
- Connection succeeds
- Returns count of artifacts by type (project, journal, restart, snapshot)
- No errors

**Qwrk Checkpoint**: Confirm CC reports successful connection and query results.

---

### Step 7: Verify RLS Still Enforced (Security Test)

**Instructions for Master Joel:**

Even though `cc_readonly` can SELECT, Row Level Security (RLS) policies still apply.

Test this by asking CC to query a workspace it shouldn't have access to:

**Test Query (CC to run):**
```sql
-- Try to query artifacts from a different workspace (should return empty or error)
SELECT *
FROM qxb_artifact
WHERE workspace_id = '00000000-0000-0000-0000-000000000000'
LIMIT 1;
```

**Expected Result**:
- Either returns 0 rows (RLS filters out)
- Or returns only rows where RLS policy allows (e.g., public data)
- **Should NOT** return sensitive data from other workspaces

**Qwrk Checkpoint**: Confirm RLS is still protecting workspace-scoped data.

---

## Post-Setup Verification Checklist

Ask Master Joel to confirm:

- ✅ `cc_readonly` role created successfully
- ✅ Role has SELECT on all public schema tables
- ✅ Role does NOT have INSERT/UPDATE/DELETE permissions
- ✅ Connection details shared securely with CC
- ✅ CC successfully connected and ran test query
- ✅ RLS policies still enforced (workspace isolation verified)

---

## What CC Can Now Do (Read-Only)

With read-only access, CC can:
- ✅ Query artifact metadata (titles, summaries, types)
- ✅ Read schema definitions (LIVE_DDL validation)
- ✅ Verify workflow outputs (check if Save workflow created records)
- ✅ Generate reports (artifact counts, status summaries)
- ✅ Validate data integrity (FK references, constraint checks)

**CC CANNOT:**
- ❌ Insert new artifacts (must use Gateway workflows)
- ❌ Update existing artifacts (must use Gateway workflows)
- ❌ Delete artifacts (destructive operations prohibited)
- ❌ Create/alter tables (DDL operations prohibited)
- ❌ Grant/revoke permissions (admin operations prohibited)

---

## Troubleshooting

### Issue: "role 'cc_readonly' already exists"

**Solution**: Role was created previously. Skip Step 2, proceed to Step 3 to verify permissions.

### Issue: "permission denied for table qxb_artifact"

**Solution**: Re-run the GRANT statements from Step 2:
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cc_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO cc_readonly;
```

### Issue: CC cannot connect (connection timeout)

**Solution**:
1. Verify Supabase project is not paused (check dashboard)
2. Verify connection string has correct host (check Project Settings → Database)
3. Verify port 5432 is not blocked by firewall

### Issue: CC sees empty results for known artifacts

**Solution**: RLS policy may be filtering rows. Verify workspace_id matches expected workspace, or check if RLS policy allows `cc_readonly` role to read.

---

## Security Notes for Master Joel

1. **Password Rotation**: Change `cc_readonly` password periodically
   ```sql
   ALTER ROLE cc_readonly WITH PASSWORD 'new_password_here';
   ```

2. **Audit Access**: Monitor `cc_readonly` queries in Supabase logs (if needed)

3. **Revoke Access** (if needed in future):
   ```sql
   REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM cc_readonly;
   DROP ROLE cc_readonly;
   ```

4. **Never share admin credentials**: CC should never receive `postgres` superuser credentials

---

## Success Criteria

✅ CC has read-only database access
✅ CC can query artifacts, schemas, metadata
✅ CC cannot write, update, or delete
✅ RLS policies still enforced
✅ Credentials shared securely

---

**Status**: Walkthrough ready for Qwrk to guide Master Joel

**Next Step**: Hand this document to Qwrk, who will walk Master Joel through the process step-by-step.
