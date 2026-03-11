"""T80: Update Schema Reference from v2.8 to v2.9"""
import pathlib

src = pathlib.Path("docs/schema/Schema_Reference__Kernel_v1__v2.8.md")
dst = pathlib.Path("docs/schema/Schema_Reference__Kernel_v1__v2.9.md")

content = src.read_text(encoding="utf-8")

# 1. Header updates
content = content.replace("(v2.8)", "(v2.9)")
content = content.replace("(DDL v2.8)", "(DDL v2.9)")
content = content.replace("**Date**: 2026-03-06", "**Date**: 2026-03-07")
content = content.replace("**Version**: v2.8", "**Version**: v2.9")
content = content.replace(
    "**Supersedes**: v2.7 (`Archive/Schema_Reference__Kernel_v1__v2.7__2026-03-06.md`)",
    "**Supersedes**: v2.8 (`Archive/Schema_Reference__Kernel_v1__v2.8__2026-03-06.md`)",
)

# 2. Table count
content = content.replace("**20 tables + 1 VIEW total.**", "**19 tables + 1 VIEW total.**")

# 3. Rollup view section
content = content.replace(
    "Inherits RLS from underlying `qxb_artifact`",
    "Uses `security_invoker = true`",
)
content = content.replace(
    "workspace isolation is automatic",
    "runs with caller RLS permissions, not view creator",
)
content = content.replace(
    "**Type**: VIEW (not a table",
    "**Type**: VIEW with `security_invoker = true` (not a table",
)
content = content.replace(
    "no RLS policies needed)",
    "caller RLS applies)",
)

# 4. RLS policy rules: auth.uid() -> (select auth.uid())
content = content.replace(
    "`auth_user_id = auth.uid()`",
    "`auth_user_id = (select auth.uid())`",
)
content = content.replace(
    "`auth_user_id = auth.uid()`",
    "`auth_user_id = (select auth.uid())`",
)

# 5. Add v2.9 changelog entry before v2.7
v29_entry = """### v2.9 \u2014 2026-03-07

**T80 Security Advisor Fixes.**

1. `qxb_artifact_rollup_view`: added `WITH (security_invoker = true)`. View now runs with caller permissions/RLS instead of creator permissions.
2. `qxb_artifact_dependency`: RLS + 3 policies confirmed deployed (were in DDL v2.5+ but missing from live DB \u2014 T71 drift fix).
3. `_migration_priority_null_snapshot`: dropped (leftover migration table, 494 rows, no references).
4. RLS initplan optimization: 4 policies updated to use `(select auth.uid())` instead of `auth.uid()` for per-query evaluation instead of per-row. Tables: `qxb_user` (2 policies), `qxb_workspace` (1), `qxb_workspace_user` (1).

**Table count**: 20 \u2192 19 tables + 1 VIEW (dropped `_migration_priority_null_snapshot`).

**Source**: LIVE DDL v2.9 (2026-03-07)
**Previous version**: `Archive/Schema_Reference__Kernel_v1__v2.8__2026-03-06.md`

"""

content = content.replace("### v2.7", v29_entry + "### v2.7", 1)

dst.write_text(content, encoding="utf-8")
src.unlink()
print(f"Done: {dst} created, {src} removed")
