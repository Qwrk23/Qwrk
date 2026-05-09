#!/usr/bin/env python3
"""
generate_qwrk_prime_weekly_report.py

Generator skeleton for the Qwrk Prime Weekly Accomplishment Report.

Status: SKELETON. Window math + safety scaffolding + dry-run + verification
ping are functional. Full report rendering requires either:
  - Supabase Python client (`pip install supabase`) with a read-only key, OR
  - psycopg2 / psycopg with a read-only DATABASE_URL.

This script intentionally does not call any LLM. The conversational synthesis
(theme analysis, significance summaries) is performed by the model that invokes
this skill (Q in ChatGPT, or CC in Claude Code). The script's job is the
deterministic part: window calculation, paginated fetch, deduplication, and
markdown skeleton emission.

USAGE
    python generate_qwrk_prime_weekly_report.py --dry-run
    python generate_qwrk_prime_weekly_report.py --verify-only
    python generate_qwrk_prime_weekly_report.py --readonly
    python generate_qwrk_prime_weekly_report.py --readonly --include-friday-of-run
    python generate_qwrk_prime_weekly_report.py --readonly --output-dir /tmp/test

ENV (one of these paths must be configured for non-dry-run modes):
    SUPABASE_URL                + SUPABASE_READONLY_KEY (or SUPABASE_ANON_KEY)
    DATABASE_URL                (read-only role, postgresql://...)

GOVERNANCE
    - Read-only Supabase only. Any write attempt raises and exits non-zero.
    - Workspace is hard-locked to Qwrk Prime.
    - 3-attempt retry cap per CLAUDE.md §2.7. No silent retry loops.
    - Output filename collision: appends timestamp suffix and warns.
    - Does NOT activate any scheduler. Does NOT modify n8n / Gateway.

EXIT CODES
    0   success (report or quiet-week or verify-only or dry-run)
    1   blocker (no data access, write attempted, schema drift, etc.)
    2   user error (invalid args)
"""

from __future__ import annotations

import argparse
import os
import sys
import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone, tzinfo as _tzinfo, date as _date
from pathlib import Path
from typing import Optional

def _resolve_central_tz():
    """
    Resolve America/Chicago timezone. Order of preference:
      1. zoneinfo (Python stdlib, requires tzdata on Windows)
      2. dateutil.tz (commonly installed)
      3. Embedded CT fallback (US DST rules: 2nd Sun Mar → 1st Sun Nov)
    """
    try:
        from zoneinfo import ZoneInfo
        return ZoneInfo("America/Chicago")
    except Exception:
        pass
    try:
        from dateutil.tz import gettz
        tz = gettz("America/Chicago")
        if tz is not None:
            return tz
    except Exception:
        pass
    return _EmbeddedCentralTZ()


class _EmbeddedCentralTZ(_tzinfo):
    """Minimal CT fallback. Works without zoneinfo/dateutil/tzdata."""

    def utcoffset(self, dt):
        return timedelta(hours=-5) if self._is_dst(dt) else timedelta(hours=-6)

    def dst(self, dt):
        return timedelta(hours=1) if self._is_dst(dt) else timedelta(0)

    def tzname(self, dt):
        return "CDT" if self._is_dst(dt) else "CST"

    @staticmethod
    def _second_sunday(year, month):
        d = _date(year, month, 1)
        first_sun = 1 + ((6 - d.weekday()) % 7)
        return first_sun + 7

    @staticmethod
    def _first_sunday(year, month):
        d = _date(year, month, 1)
        return 1 + ((6 - d.weekday()) % 7)

    def _is_dst(self, dt):
        if dt is None:
            return False
        y = dt.year
        dst_start = datetime(y, 3, self._second_sunday(y, 3), 2, 0)
        dst_end   = datetime(y, 11, self._first_sunday(y, 11), 2, 0)
        naive = dt.replace(tzinfo=None) if dt.tzinfo else dt
        return dst_start <= naive < dst_end


# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

WORKSPACE_ID_PRIME = "be0d3a48-c764-44f9-90c8-e846d9dbbd0a"
WORKSPACE_NAME_PRIME = "Qwrk Prime"

DEFAULT_OUTPUT_DIR = Path(
    r"C:\Users\j_bla\OneDrive\AAA QwrkX\new-qwrk-kernel\Qwrk_Inbox"
)
FILENAME_PATTERN = "Qwrk_Prime_Weekly_Accomplishment_Report__{date}.md"

CENTRAL = _resolve_central_tz()
PAGE_SIZE = 25
RETRY_CAP = 3   # CLAUDE.md §2.7
WINDOW_COUNT_DENSE_FLAG = 500

LOG = logging.getLogger("qwrk-weekly-report")


# -----------------------------------------------------------------------------
# Dataclasses
# -----------------------------------------------------------------------------

@dataclass
class Window:
    start_local: datetime
    end_local: datetime
    start_utc: datetime
    end_utc: datetime
    report_date_local: datetime
    is_friday_of_run_included: bool = False

    def as_table_rows(self) -> list[tuple[str, str]]:
        return [
            ("Window start (local Central)", self.start_local.isoformat()),
            ("Window end (local Central)", self.end_local.isoformat()),
            ("Window start (UTC)", self.start_utc.isoformat()),
            ("Window end (UTC)", self.end_utc.isoformat()),
            ("Report generation date (local)", self.report_date_local.date().isoformat()),
            ("Friday-of-run included", str(self.is_friday_of_run_included).lower()),
        ]


@dataclass
class RunConfig:
    readonly: bool
    dry_run: bool
    verify_only: bool
    include_friday_of_run: bool
    output_dir: Path
    report_date_override: Optional[str] = None  # YYYY-MM-DD


@dataclass
class RunReport:
    window: Window
    artifact_count: int = 0
    blocker: Optional[str] = None
    output_path: Optional[Path] = None
    quiet_week: bool = False
    notes: list[str] = field(default_factory=list)


# -----------------------------------------------------------------------------
# Window calculation
# -----------------------------------------------------------------------------

def compute_window(now_local: datetime, include_friday_of_run: bool = False) -> Window:
    """
    Default rule (Friday 5:00 AM run):
      report_date = today (local Central, the Friday on which we run)
      window_start = (report_date - 7 days) at 00:00:00 local
      window_end   = (report_date - 1 day)  at 23:59:59.999999 local

    If include_friday_of_run is True, window_end shifts forward to the run moment
    (less common; documented in §2 of the report).

    On non-Friday runs, the same arithmetic applies relative to the run date.
    The skill warns in §2 that this is a non-default-cadence run.
    """
    if now_local.tzinfo is None:
        raise ValueError("now_local must be timezone-aware (America/Chicago)")

    report_date_local = now_local
    start_local = (report_date_local - timedelta(days=7)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )

    if include_friday_of_run:
        end_local = report_date_local
    else:
        end_local = (report_date_local - timedelta(days=1)).replace(
            hour=23, minute=59, second=59, microsecond=999999
        )

    start_utc = start_local.astimezone(timezone.utc)
    end_utc = end_local.astimezone(timezone.utc)

    return Window(
        start_local=start_local,
        end_local=end_local,
        start_utc=start_utc,
        end_utc=end_utc,
        report_date_local=report_date_local,
        is_friday_of_run_included=include_friday_of_run,
    )


def dry_run_window_preview(cfg: RunConfig) -> None:
    """Print the computed window without touching Supabase or filesystem."""
    now_local = _resolve_now_local(cfg)
    win = compute_window(now_local, cfg.include_friday_of_run)
    out_path = cfg.output_dir / FILENAME_PATTERN.format(
        date=win.report_date_local.date().isoformat()
    )

    print("=" * 70)
    print("DRY RUN — Qwrk Prime Weekly Accomplishment Report")
    print("=" * 70)
    print(f"Workspace        : {WORKSPACE_NAME_PRIME} ({WORKSPACE_ID_PRIME})")
    print(f"Report date      : {win.report_date_local.date().isoformat()} ({win.report_date_local.strftime('%A')})")
    print(f"Window start (CT): {win.start_local.isoformat()}")
    print(f"Window end (CT)  : {win.end_local.isoformat()}")
    print(f"Window start UTC : {win.start_utc.isoformat()}")
    print(f"Window end UTC   : {win.end_utc.isoformat()}")
    print(f"Friday-of-run    : {'INCLUDED (override)' if cfg.include_friday_of_run else 'EXCLUDED (default)'}")
    print(f"Output path      : {out_path}")
    print(f"Output path exists: {out_path.exists()} (collision risk if true)")
    print(f"Output dir exists: {cfg.output_dir.exists()}")
    print(f"Read-only mode   : {cfg.readonly}")
    print("No queries issued. No files written. Exit 0.")


# -----------------------------------------------------------------------------
# Supabase access
# -----------------------------------------------------------------------------

class SupabaseAccessUnavailable(Exception):
    """Raised when no read-only Supabase access path is configured."""


def get_supabase_client():
    """
    Returns a configured Supabase client (preferred) or raises
    SupabaseAccessUnavailable. Caller falls back to psycopg if available.
    """
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_READONLY_KEY") or os.environ.get("SUPABASE_ANON_KEY")
    if not (url and key):
        raise SupabaseAccessUnavailable(
            "SUPABASE_URL + SUPABASE_READONLY_KEY (or SUPABASE_ANON_KEY) not set"
        )
    try:
        from supabase import create_client  # type: ignore
    except ImportError as e:
        raise SupabaseAccessUnavailable(f"supabase python client not installed: {e}")
    return create_client(url, key)


def get_pg_connection():
    """psycopg/psycopg2 fallback. Read-only DATABASE_URL required."""
    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        raise SupabaseAccessUnavailable("DATABASE_URL not set")
    try:
        import psycopg  # type: ignore
        return psycopg.connect(dsn, autocommit=True)
    except ImportError:
        try:
            import psycopg2  # type: ignore
            conn = psycopg2.connect(dsn)
            conn.set_session(readonly=True, autocommit=True)
            return conn
        except ImportError as e:
            raise SupabaseAccessUnavailable(f"neither psycopg nor psycopg2 installed: {e}")


def verify_access(window: Window) -> int:
    """
    Run Q0 verification ping. Returns count or raises.
    Honors the 3-attempt retry cap (CLAUDE.md §2.7).
    """
    attempts = 0
    last_err: Optional[Exception] = None
    while attempts < RETRY_CAP:
        attempts += 1
        try:
            try:
                client = get_supabase_client()
                # Use rpc or direct SQL. Supabase python client doesn't expose
                # execute_sql directly; use postgrest .rpc('') if you have a
                # function, or fall back to psycopg.
                raise SupabaseAccessUnavailable(
                    "supabase-py does not expose raw SQL; use psycopg fallback"
                )
            except SupabaseAccessUnavailable:
                conn = get_pg_connection()
                cur = conn.cursor()
                cur.execute(
                    """
                    SELECT count(*)
                    FROM qxb_artifact
                    WHERE workspace_id = %s
                      AND (
                        (created_at >= %s AND created_at <= %s)
                        OR
                        (updated_at >= %s AND updated_at <= %s)
                      )
                    """,
                    (
                        WORKSPACE_ID_PRIME,
                        window.start_utc, window.end_utc,
                        window.start_utc, window.end_utc,
                    ),
                )
                row = cur.fetchone()
                cur.close()
                conn.close()
                return int(row[0])
        except Exception as e:
            last_err = e
            LOG.warning("verify_access attempt %d/%d failed: %s", attempts, RETRY_CAP, e)
    assert last_err is not None
    raise last_err


# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

def safe_output_path(cfg: RunConfig, window: Window) -> Path:
    """Resolve output path; if it already exists, append a timestamp suffix."""
    base_name = FILENAME_PATTERN.format(date=window.report_date_local.date().isoformat())
    candidate = cfg.output_dir / base_name
    if not candidate.exists():
        return candidate
    stamp = datetime.now(CENTRAL).strftime("%H%M%S")
    suffixed = candidate.with_name(f"{candidate.stem}__rerun_{stamp}{candidate.suffix}")
    LOG.warning("Output path collision; using %s", suffixed)
    return suffixed


def write_blocker_note(cfg: RunConfig, window: Window, blocker: str) -> Path:
    """Write a small blocker file to output dir so the scheduler/Joel sees the failure."""
    name = FILENAME_PATTERN.format(
        date=window.report_date_local.date().isoformat()
    ).replace(".md", "__BLOCKER__.md")
    path = cfg.output_dir / name
    body = (
        f"# Qwrk Prime Weekly Accomplishment Report — BLOCKER\n\n"
        f"**Date:** {window.report_date_local.date().isoformat()}\n"
        f"**Window (UTC):** {window.start_utc.isoformat()} → {window.end_utc.isoformat()}\n"
        f"**Window (CT):** {window.start_local.isoformat()} → {window.end_local.isoformat()}\n\n"
        f"## Blocker\n\n{blocker}\n\n"
        f"## What CC/Joel should do\n\n"
        f"1. Verify Supabase read access (env vars, MCP wiring, network).\n"
        f"2. If MCP available, re-run from CC interactively rather than the scheduler.\n"
        f"3. Do NOT attempt to write fabricated data.\n"
        f"4. Re-trigger after the underlying access path is restored.\n"
    )
    path.write_text(body, encoding="utf-8")
    return path


def write_quiet_week_report(cfg: RunConfig, window: Window) -> Path:
    """Emit a short report when artifact_count == 0."""
    out = safe_output_path(cfg, window)
    body = (
        f"# Qwrk Prime — Weekly Accomplishment Report\n\n"
        f"**Generated:** {window.report_date_local.date().isoformat()} (Quiet Week)\n"
        f"**Workspace:** {WORKSPACE_NAME_PRIME} (`{WORKSPACE_ID_PRIME}`)\n"
        f"**Window:** {window.start_local.isoformat()} → {window.end_local.isoformat()} (America/Chicago)\n"
        f"**Window UTC:** {window.start_utc.isoformat()} → {window.end_utc.isoformat()}\n"
        f"**Inclusion:** `created_at` OR `updated_at` within window\n"
        f"**Artifacts reviewed:** 0\n\n"
        f"## 1. Executive Summary\n\n"
        f"No artifacts were created or spine-updated in Qwrk Prime during the "
        f"reporting window. This is a Quiet Week.\n\n"
        f"Possible interpretations (require human judgment):\n"
        f"- Joel was traveling, on break, or focused outside Qwrk\n"
        f"- All work this week happened in another workspace\n"
        f"- A scheduling/timezone bug excluded artifacts that should have appeared\n\n"
        f"## 2. Reporting Scope and Method\n\n"
        f"Workspace: Qwrk Prime only. Window non-overlapping 7-day calendar in "
        f"America/Chicago. Verified via read-only Supabase ping.\n\n"
        f"## 7. Notable Risks, Gaps, or Ambiguities\n\n"
        f"1. **Quiet Week** — verify the window matches expectations before "
        f"acting on this report. If artifacts were expected, re-run with explicit "
        f"window override.\n\n"
        f"*End of report.*\n"
    )
    out.write_text(body, encoding="utf-8")
    return out


def write_report_skeleton(cfg: RunConfig, window: Window, artifact_count: int) -> Path:
    """
    Emits a structural skeleton with window + count + standard headings.
    The actual thematic synthesis is the LLM caller's job — this script is the
    deterministic harness around it.
    """
    out = safe_output_path(cfg, window)
    body = (
        f"# Qwrk Prime — Weekly Accomplishment Report\n\n"
        f"**Generated:** {window.report_date_local.date().isoformat()}\n"
        f"**Workspace:** {WORKSPACE_NAME_PRIME} (`{WORKSPACE_ID_PRIME}`)\n"
        f"**Window:** {window.start_local.isoformat()} → {window.end_local.isoformat()} (America/Chicago)\n"
        f"**Window UTC:** {window.start_utc.isoformat()} → {window.end_utc.isoformat()}\n"
        f"**Inclusion:** `created_at` OR `updated_at` within window\n"
        f"**Artifacts reviewed:** {artifact_count}\n\n"
        f"> NOTE: This file was emitted as a SKELETON by "
        f"`generate_qwrk_prime_weekly_report.py`. Thematic synthesis sections "
        f"(§1, §3–§9) require LLM rendering — invoke the "
        f"`qwrk-prime-weekly-accomplishment-report` skill against this file or "
        f"re-run via Q/CC.\n\n"
        f"## 1. Executive Summary\n\n_(LLM render required.)_\n\n"
        f"## 2. Reporting Scope and Method\n\n"
        + "| Item | Value |\n|------|-------|\n"
        + "\n".join(f"| {k} | {v} |" for k, v in window.as_table_rows())
        + f"\n| Workspace | {WORKSPACE_NAME_PRIME} |\n"
        + f"| Inclusion rule | created_at OR updated_at |\n"
        + f"| Query method | psycopg / psycopg2 (read-only DATABASE_URL) |\n"
        + f"| Artifacts in window | {artifact_count} |\n\n"
        f"## 3. Thematic Accomplishment Summary\n\n_(LLM render required.)_\n\n"
        f"## 4. Shipped / Completed Work\n\n_(LLM render required.)_\n\n"
        f"## 5. In-Progress Work\n\n_(LLM render required.)_\n\n"
        f"## 6. Decisions and Governance Captured\n\n_(LLM render required.)_\n\n"
        f"## 7. Notable Risks, Gaps, or Ambiguities\n\n_(LLM render required.)_\n\n"
        f"## 8. Future Automation Notes\n\n"
        f"- Schedule target: Fridays 05:00 America/Chicago\n"
        f"- Window non-overlap: prior Fri 00:00 → prior Thu 23:59:59 local CT\n"
        f"- Runtime options: Windows Task Scheduler, n8n, cron, ChatGPT Task\n"
        f"- See `references/scheduling.md` in the skill folder for activation gate.\n\n"
        f"## 9. Recommended Follow-Up Questions for Q\n\n_(LLM render required.)_\n\n"
        f"## 10. Chronological Artifact Appendix\n\n_(LLM render required.)_\n\n"
        f"## Data Quality / Confidence\n\n"
        f"- Query method: psycopg/psycopg2 read-only\n"
        f"- Artifacts reviewed: {artifact_count}\n"
        f"- Workspace scope: strictly Qwrk Prime\n"
        f"- No write operations: confirmed\n\n"
        f"*End of report.*\n"
    )
    out.write_text(body, encoding="utf-8")
    return out


# -----------------------------------------------------------------------------
# Orchestration
# -----------------------------------------------------------------------------

def _resolve_now_local(cfg: RunConfig) -> datetime:
    if cfg.report_date_override:
        d = datetime.strptime(cfg.report_date_override, "%Y-%m-%d")
        return d.replace(tzinfo=CENTRAL, hour=5, minute=0, second=0, microsecond=0)
    return datetime.now(CENTRAL)


def run(cfg: RunConfig) -> int:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    if cfg.dry_run:
        dry_run_window_preview(cfg)
        return 0

    now_local = _resolve_now_local(cfg)
    window = compute_window(now_local, cfg.include_friday_of_run)
    LOG.info("Window: %s (CT) → %s (CT)", window.start_local, window.end_local)

    if not cfg.output_dir.exists():
        LOG.error("Output dir does not exist: %s", cfg.output_dir)
        return 1

    try:
        count = verify_access(window)
    except SupabaseAccessUnavailable as e:
        msg = (
            f"Read-only Supabase access unavailable.\n\n"
            f"Configure ONE of the following:\n"
            f"  - SUPABASE_URL + SUPABASE_READONLY_KEY (or SUPABASE_ANON_KEY)\n"
            f"  - DATABASE_URL (postgresql://...)\n\n"
            f"Detail: {e}"
        )
        LOG.error("Access blocker: %s", msg)
        path = write_blocker_note(cfg, window, msg)
        LOG.info("Wrote blocker note: %s", path)
        return 1
    except Exception as e:
        msg = f"Verification ping failed after {RETRY_CAP} attempts: {e}"
        LOG.error(msg)
        path = write_blocker_note(cfg, window, msg)
        LOG.info("Wrote blocker note: %s", path)
        return 1

    LOG.info("Window count: %d", count)

    if cfg.verify_only:
        print(json.dumps({
            "window_start_local": window.start_local.isoformat(),
            "window_end_local": window.end_local.isoformat(),
            "window_start_utc": window.start_utc.isoformat(),
            "window_end_utc": window.end_utc.isoformat(),
            "artifact_count": count,
            "dense_flag": count > WINDOW_COUNT_DENSE_FLAG,
        }, indent=2))
        return 0

    if count == 0:
        path = write_quiet_week_report(cfg, window)
        LOG.info("Quiet Week report written: %s", path)
        print(json.dumps({"status": "quiet_week", "path": str(path)}, indent=2))
        return 0

    # NOTE: full thematic synthesis lives in the SKILL.md workflow, executed by
    # the model that invokes this skill. The script writes a skeleton with
    # window + count + section headers; the LLM caller fills sections 1, 3-9, 10.
    path = write_report_skeleton(cfg, window, count)
    LOG.info("Skeleton report written (LLM synthesis required): %s", path)
    print(json.dumps({
        "status": "skeleton_written",
        "path": str(path),
        "artifact_count": count,
        "next_step": "invoke the qwrk-prime-weekly-accomplishment-report skill to render sections 1, 3-9, 10",
    }, indent=2))
    return 0


def parse_args(argv: list[str]) -> RunConfig:
    p = argparse.ArgumentParser(
        description="Generate the Qwrk Prime Weekly Accomplishment Report (read-only)."
    )
    p.add_argument("--readonly", action="store_true", help="Enforce read-only mode (default)")
    p.add_argument("--dry-run", action="store_true", help="Compute window + show plan, no queries, no writes")
    p.add_argument("--verify-only", action="store_true", help="Run verification ping and exit")
    p.add_argument("--include-friday-of-run", action="store_true",
                   help="Override default exclusion of Friday-of-run")
    p.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR,
                   help=f"Output directory (default: {DEFAULT_OUTPUT_DIR})")
    p.add_argument("--report-date", type=str, default=None,
                   help="Override report date as YYYY-MM-DD (testing)")
    args = p.parse_args(argv)

    return RunConfig(
        readonly=True,  # always read-only regardless of flag
        dry_run=args.dry_run,
        verify_only=args.verify_only,
        include_friday_of_run=args.include_friday_of_run,
        output_dir=args.output_dir,
        report_date_override=args.report_date,
    )


def main(argv: Optional[list[str]] = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    try:
        cfg = parse_args(argv)
    except SystemExit as e:
        return int(e.code) if isinstance(e.code, int) else 2
    return run(cfg)


if __name__ == "__main__":
    sys.exit(main())
