# Runbook — History/Report + GitHub Mirror (v1) — 2026-01-02

## Purpose
Give Claude Code (and humans) a reliable “state-of-the-moment” anchor without breaking Snapshot semantics.

## Canonical truth vs mirror
- Canonical truth: Supabase artifacts (qxb_* tables)
- Mirror: GitHub folders/files derived from History/Report artifacts

## When to create a History/Report artifact
- KGB passed
- Phase transition
- Contract version bump
- Schema migration / RLS patch
- “We fixed a thorn” moment that matters

## What to include in the GitHub mirror
Create a folder per report:
`history_reports/YYYY-MM-DD__<short_slug>__<artifact_id>/`

Inside include:
- `REPORT.md` (filled from template)
- `KGB.md` (commands/results summary; no secrets)
- `LINKS.md` (artifact ids, PRs, workflow export filenames)

## Safety rules
- Never commit secrets (Supabase keys, passwords).
- GitHub content is narrative; do not treat it as execution source of truth.

