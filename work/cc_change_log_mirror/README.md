# CC Change Log Mirror — Convenience Copy

**Purpose**: Convenience copy of CC change logs for quick access and development/debugging.

**Status**: Non-authoritative (best-effort mirror)

---

## Characteristics

- **Append-only (best-effort)**: Logs appended when possible, but not guaranteed
- **Single file**: Latest changes in `cc_change_log_latest.jsonl`
- **Not canonical**: For convenience only; audit root is source of truth
- **May be truncated**: File may be rotated or cleared to manage size
- **Development-friendly**: Easy to tail, grep, or parse without navigating date folders

---

## Filename Convention

```
./work/cc_change_log_mirror/cc_change_log_latest.jsonl
```

**Single file only** (no date-based rotation)

---

## Record Schema (Future)

Same schema as canonical audit log:

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

1. **Never treat as authoritative** (audit root is canonical)
2. **May be cleared/rotated** (not guaranteed to contain full history)
3. **For debugging/development only** (not for compliance or audit)
4. **Best-effort writes** (failures here don't block operations)

---

## Access Pattern

- **Read**: Quick debugging, tail -f for live monitoring, grep for recent changes
- **Write**: Automated logging only (CC writes, humans never write)
- **Backup**: NOT required (canonical audit is backed up)

---

## Use Cases

- **Development**: `tail -f cc_change_log_latest.jsonl` to watch CC activity
- **Debugging**: Quick grep for recent file changes without navigating date folders
- **Session review**: See what CC did in the current session without audit folder traversal

---

**Status**: Scaffolding created (no logging code implemented yet)
**Next Step**: Implement logging code in CC tool handlers (with best-effort mirror writes)
