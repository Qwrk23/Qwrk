# CC Change Log — Canonical Audit Root

**Purpose**: Canonical source of truth for all Claude Code (CC) changes to the repository.

**Status**: Authoritative (append-only)

---

## Characteristics

- **Append-only**: Logs are never edited after creation
- **JSONL format**: Newline-delimited JSON for streaming and easy parsing
- **Daily rotation**: One file per day
- **Structured by date**: YYYY/MM/ folder structure for organization
- **Immutable**: Once written, entries are permanent audit records

---

## Filename Convention

```
./audit/cc_change_log/YYYY/MM/cc_change_log_YYYY-MM-DD.jsonl
```

**Examples:**
- `./audit/cc_change_log/2026/01/cc_change_log_2026-01-05.jsonl`
- `./audit/cc_change_log/2026/01/cc_change_log_2026-01-06.jsonl`

---

## Record Schema (Future)

Each line in a `.jsonl` file will be a single JSON object:

```json
{
  "timestamp": "2026-01-05T12:34:56.789Z",
  "event_type": "file_write|file_edit|file_delete|bash_command|workflow_export",
  "tool_used": "Write|Edit|Bash|...",
  "file_path": "relative/path/to/file.ext",
  "change_summary": "Brief description of change",
  "user_instruction": "Original user instruction that triggered change",
  "session_id": "unique_session_identifier",
  "metadata": {}
}
```

---

## Rules

1. **Never delete log files** (historical audit trail)
2. **Never edit log files** (append-only guarantee)
3. **Use UTC timestamps** (consistent timezone)
4. **One entry per line** (JSONL standard)
5. **Log all file changes** (Write, Edit, Delete operations)
6. **Log critical commands** (Bash commands that modify state)

---

## Access Pattern

- **Read**: Audit review, compliance checks, change history analysis
- **Write**: Automated logging only (CC writes, humans never write)
- **Backup**: This folder should be included in version control and backups

---

**Status**: Scaffolding created (no logging code implemented yet)
**Next Step**: Implement logging code in CC tool handlers
