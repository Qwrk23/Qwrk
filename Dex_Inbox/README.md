# Dex_Inbox

> Curated context delivery folder for Dex (Codex / Horizon Scout).
> Read-only on Dex side. Joel and Q are authoritative on contents.

## Purpose

This folder is the bounded surface CC and Joel use to deliver context to Dex without giving Dex direct access to Qwrk's artifact graph, Gateway, or database. Dex reads files placed here. Dex does not query, scan, or write anything in return.

## Boundary

- Dex sees only what is placed in this folder.
- Dex does not query Gateway, Supabase, or any Qwrk runtime.
- Dex does not inspect Cold Archive, Mother Tree, saplings, or any Qwrk artifact directly.
- Q and Joel decide what enters this folder.
- CC may draft proposals; CC does not unilaterally update canonical files here.

## Files

| File | Role | Update authority |
|------|------|------------------|
| `Scout_Grounding_Brief.md` | Canonical curated concept surface Dex uses to recognize Qwrk-relevant external signals. | Joel / Q ratify. CC writes on approval. |
| `Scout_Grounding_Brief__candidates__<YYYY-MM-DD>.md` (optional, future) | Ad-hoc proposed additions, retirements, or rewordings — for Joel/Q to review and ratify into canonical. | CC writes when invoked. |
| `README.md` | This file. | CC writes; Joel approves. |

## Update flow (v0.1 — manual)

1. Joel or Q identifies a Qwrk concept Dex should know about (or a concept that should be retired).
2. Joel asks CC to update the canonical brief, or to draft a candidate delta.
3. CC drafts the change.
4. Joel approves.
5. CC writes the canonical update using Pattern C — prior version moves to `Archive/Scout_Grounding_Brief__v<N>__<date>.md`.

**No scheduled sweep is active in v0.1.** Reassess whether scheduled sweeps are justified after 2–3 Scout cycles.

## Boundary statement (for Dex's reference)

> The Scout Grounding Brief is curated. It is not exhaustive. Concepts not in the brief may still be Qwrk-relevant — Dex should classify uncertain matches as `Watch` or `Joel skim` rather than guess. Dex must not infer absence as confirmation.

## CHANGELOG

### v0.1 — 2026-05-07
- Initial folder created.
- README + canonical Scout_Grounding_Brief.md (v0.1, 8 concepts) drafted.
- No automated sweep, no Cold Archive inclusion, no broad governance sweep, no auto-learning canonical names.
- Reassessment trigger: after 2–3 Scout cycles.
