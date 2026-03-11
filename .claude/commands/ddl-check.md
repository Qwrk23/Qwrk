Perform a DDL pre-flight check before writing SQL.

Source: CLAUDE.md "Schema Truth Policy" — last synced 2026-03-10

## Instructions

This skill enforces the **DDL-as-Truth** policy from CLAUDE.md. Before generating ANY SQL that touches `qxb_*` tables, you MUST verify against the authoritative schema.

1. **Read the LIVE DDL:**
   - Open `docs/schema/LIVE_DDL__Kernel_v1__2026-01-04.sql`

2. **Identify what the user needs:**
   - If the user specified a table name: look up that table's full definition
   - If the user specified a column: find which table(s) contain it
   - If the user wants to write SQL: extract ALL table and column references from their intent

3. **Run the pre-flight checklist** for each table/column referenced:

   | Check | Status |
   |-------|--------|
   | Table exists in LIVE DDL? | |
   | All columns exist? | |
   | Data types match? (uuid vs text, jsonb vs json, timestamptz, etc.) | |
   | NOT NULL constraints satisfied? | |
   | CHECK constraints respected? (artifact_type enum, priority range, etc.) | |
   | DEFAULT values noted? (gen_random_uuid(), now(), etc.) | |
   | JSONB key shapes match downstream expectations? | |
   | RLS policies relevant to this operation? | |

4. **Output format:**
   - Show the relevant table DDL excerpt (CREATE TABLE + constraints)
   - Show the completed pre-flight checklist
   - Flag any warnings (e.g., column doesn't exist, type mismatch, missing NOT NULL)
   - If everything passes: confirm "DDL pre-flight PASSED — safe to write SQL"
   - If anything fails: STOP and explain what's wrong. Do NOT proceed with SQL generation.

5. **Common gotchas to check:**
   - `owner_user_id` not `owner_id` (spine table)
   - `tags` is `text[]` not `jsonb`
   - `payload` on snapshot/restart extension tables is `jsonb`
   - `entry_text` on journal extension is `text`
   - `lifecycle_status` lives on spine (`qxb_artifact`), NOT on `qxb_artifact_project`
   - `operational_state` lives on `qxb_artifact_project` extension table
   - artifact_type CHECK v5: 12 types including branch, leaf, instruction_pack — but NOT video (video exists as table but not in CHECK)
   - Extension tables use PK=FK pattern: `artifact_id` references `qxb_artifact(artifact_id)`

6. **If the user hasn't specified what they need**, ask:
   - "Which table or operation do you want to verify against the DDL?"
