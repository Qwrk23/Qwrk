# Scheduling — Qwrk Prime Weekly Accomplishment Report

> **Status: documented only. NOT activated.**
>
> The skill author (CC, 2026-05-09) created this document. **No scheduler has been enabled.** Joel must explicitly approve a runtime before any recurring trigger fires.

---

## Target

| Field | Value |
|------|-------|
| **Cadence** | Weekly |
| **Day** | Friday |
| **Time** | 05:00 (5:00 AM) |
| **Timezone** | America/Chicago (CST/CDT — handles DST automatically) |
| **Window covered** | Prior Friday 00:00 → prior Thursday 23:59:59 local Central |
| **Output** | `C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Qwrk_Inbox\Qwrk_Prime_Weekly_Accomplishment_Report__YYYY-MM-DD.md` |
| **Mode** | Read-only Supabase access; single Markdown file write |

---

## Activation gate

Before any scheduler is enabled:

1. Joel reviews this scheduling doc
2. Joel selects which runtime to use (one of the four below)
3. Joel approves the activation in writing (chat is sufficient — recorded in the activation session)
4. The chosen runtime is configured by Joel or by CC under explicit direction
5. First scheduled run is monitored for at least one cycle before being treated as autonomous

The skill **must not** self-activate any scheduler. The skill **must not** install Task Scheduler entries, n8n nodes, or cron jobs without the gate above being satisfied.

---

## Runtime options

### Option A — Windows Task Scheduler (recommended for laptop/desktop only)

**Best when:** Joel's Windows machine is the canonical run environment and is reliably awake at 5:00 AM Central.

**Setup outline (DO NOT EXECUTE without approval):**

1. Open Task Scheduler → Create Task
2. **General tab**
   - Name: `Qwrk Prime Weekly Accomplishment Report`
   - Description: "Generates weekly Qwrk Prime accomplishment report. Read-only Supabase. Output to Qwrk_Inbox/."
   - Run whether user is logged on or not
   - Run with highest privileges: NOT required (read-only)
3. **Triggers tab**
   - New trigger → Weekly → Friday → 05:00:00 → time zone America/Chicago
   - "Synchronize across time zones" enabled
4. **Actions tab**
   - Action: Start a program
   - Program: `python.exe` (full path to Joel's Python install)
   - Arguments: `"C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\chatgpt-skills\qwrk-prime-weekly-accomplishment-report\scripts\generate_qwrk_prime_weekly_report.py" --readonly`
   - Start in: `C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel`
5. **Conditions tab**
   - Wake the computer to run this task: **Joel decides** (false by default — preserves laptop battery)
6. **Settings tab**
   - Allow task to be run on demand: yes
   - Run task as soon as possible after a scheduled start is missed: **yes** (catches missed runs after travel/shutdown)
   - Stop task if it runs longer than: 30 minutes

**Risks:**
- Machine asleep at 05:00 → run skipped unless wake-to-run is enabled
- Network/VPN issues at 05:00 → MCP fallback to PostgREST should still work; if both fail the script writes a blocker note
- Time-zone drift if Windows tz settings change → use named tz (America/Chicago), not fixed offset

---

### Option B — n8n scheduled workflow (recommended for headless reliability)

**Best when:** Joel's n8n instance is up reliably 24/7 (it is — Gateway runs there).

**Setup outline (DO NOT EXECUTE without approval):**

1. New workflow: `NQxb_Weekly_Report_Friday_5am` (READ-ONLY badge in description)
2. **Cron / Schedule node**
   - Trigger: Cron
   - Cron expression: `0 5 * * 5` (Friday 5:00)
   - Timezone: `America/Chicago`
3. **Execute Command node** (or HTTP-call-out, depending on where the script runs)
   - If running on the same n8n host: `python /path/to/generate_qwrk_prime_weekly_report.py --readonly`
   - If running on Joel's machine: HTTP webhook back to a trigger that runs locally
4. **Notification node** (optional)
   - On success: Telegram message "Weekly report saved: {path}"
   - On failure: Telegram message "Weekly report failed: {error}"
5. Activate workflow

**Risks:**
- n8n cannot directly write to Joel's OneDrive folder unless the script runs locally (n8n is in cloud/host, OneDrive is local)
- Workaround: write to a synced location accessible from both, or have n8n trigger a local executor
- File-system path discipline: the report must end up in `Qwrk_Inbox/` regardless of where the executor runs

---

### Option C — System cron (for Linux/WSL or future Linux host)

**Best when:** Joel migrates to a Linux primary or WSL is the chosen runner.

```cron
# Friday 05:00 Central — Qwrk Prime Weekly Accomplishment Report
0 5 * * 5  TZ=America/Chicago /usr/bin/python3 /path/to/generate_qwrk_prime_weekly_report.py --readonly >> /var/log/qwrk_weekly_report.log 2>&1
```

**Risks:**
- WSL OneDrive path translation can be brittle — verify the output path resolves correctly before activation
- Cron silently swallows errors unless redirected — log to file always

---

### Option D — ChatGPT scheduled task (if/when available to Joel's account)

**Best when:** ChatGPT Task scheduling is available and Joel wants the report generated and discussed in the same surface.

- Create a recurring Task in ChatGPT: "Every Friday at 5:00 AM Central, invoke the `qwrk-prime-weekly-accomplishment-report` skill."
- ChatGPT must have direct Supabase MCP access OR access to a Function/Tool that runs the read-only query
- Output destination must be a path ChatGPT can write to (likely a local file via tool-use)

**Risks:**
- ChatGPT scheduled tasks may not have reliable file-system write access
- Skill behavior under unattended ChatGPT execution is less predictable than a deterministic script
- Recommended only if Joel wants Q to also discuss the report on Friday morning

---

## Scheduler-of-record decision (TO BE MADE BY JOEL)

| Criterion | Task Scheduler | n8n | cron | ChatGPT Task |
|----------|:-:|:-:|:-:|:-:|
| Runs while Joel asleep | partial | yes | yes | yes |
| Writes to OneDrive directly | yes | requires bridge | requires path resolution | depends |
| Survives machine reboot | yes | yes | yes | yes |
| Easy to disable | yes | yes | yes | yes |
| Failure visibility | weak (Event Viewer) | strong | weak (log file) | depends |
| Setup complexity | low | medium | low | low |
| Recommended for first activation | ⭐ | second choice | — | — |

**CC's recommendation (non-binding):** Start with **Option A (Windows Task Scheduler)** because it writes directly to the OneDrive output path with no bridge logic and is easy to disable. If Joel wants headless 24/7 reliability without depending on machine wake state, switch to **Option B (n8n)** with a local-executor bridge.

---

## What the scheduler should call

When activated, the scheduler invokes the generator script in **read-only mode**:

```
python <path>/scripts/generate_qwrk_prime_weekly_report.py --readonly
```

Optional flags:

| Flag | Purpose |
|------|--------|
| `--readonly` | (default) refuses any write to Supabase. Recommended for all scheduled runs. |
| `--dry-run` | computes the window and prints planned actions without querying or writing |
| `--verify-only` | runs the verification ping query and exits |
| `--include-friday-of-run` | overrides the default exclusion of Friday-of-run; documented in §2 of that report |
| `--output-dir PATH` | overrides the default `Qwrk_Inbox/` (use only for testing) |

The script must **never** be invoked without `--readonly` in scheduled contexts. Manual ad-hoc invocations may omit it but are still bound by the script's internal read-only safety guard.

---

## Failure-mode handling at the scheduler layer

| Failure | Detection | Response |
|---------|-----------|----------|
| Script returns non-zero exit | Standard scheduler hook | Log + send notification to Joel (Telegram via existing messaging subsystem if available) |
| Script returns 0 but writes blocker file | File suffix `__BLOCKER__.md` in output dir | Notification "Weekly report blocker — see {path}" |
| Window count = 0 | Script writes Quiet Week report | No notification needed — the file itself is the signal |
| MCP + PostgREST both unavailable | Script's 3-attempt retry exhausts | Write blocker file; send notification; do NOT retry on its own |
| Output path unwritable | Script raises | Write blocker note to a fallback path (e.g., user temp dir) and send notification |

The scheduler must **not** silently retry on its own. The script's internal retry cap (3 attempts per CLAUDE.md §2.7) is the only retry layer.

---

## Disabling / pausing the schedule

| Runtime | How to disable |
|---------|----------------|
| Task Scheduler | Right-click task → Disable. (Or delete entirely.) |
| n8n | Toggle workflow to Inactive. |
| cron | Comment out the line in crontab. |
| ChatGPT Task | Pause / delete the task in ChatGPT settings. |

Joel may pause for any reason at any time. Pausing is non-destructive: history of prior weekly reports remains in `Qwrk_Inbox/`.

---

## Open questions for Joel

1. Which runtime do you want to use for the first activation?
2. Should the scheduler send a Telegram (or other) notification on success, or only on failure?
3. Should the scheduler also generate a Q-side WSY prompt as a sidecar file, or just the report?
4. Is `Qwrk_Inbox/` the long-term home, or should weekly reports eventually move to `docs/reports/weekly/`?
5. Should weekly reports eventually be saved as a snapshot artifact (tagged `weekly-report`, semantic `governance`) in addition to the `.md` file?

These do not block scheduling. They are decisions for the activation session.
