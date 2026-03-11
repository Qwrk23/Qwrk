# Instruction Pack — for-cc Tagging Doctrine (Q@W) v1

> **Scope:** Artifact tagging governance for CC work queue integration
> **Workspace:** Q@W (Work / Resolve)
> **Version:** 1
> **Created:** 2026-03-10

---

## Purpose

The `for-cc` tag creates an asynchronous work queue between Q@W and Claude Code (CC). When an artifact is tagged `for-cc`, CC picks it up at the next session start and presents it to Joel for conversion into an open thread.

`for-cc` does NOT authorize execution. It signals "CC should look at this." Joel must explicitly approve before CC acts.

---

## When to Suggest for-cc

At **artifact creation time only** (not retroactively), when Q@W detects:

- Implementation work requiring CC execution (schema changes, workflow builds, Gateway modifications)
- Unoperationalized decisions that need CC to implement
- Bug reports or technical investigations requiring CC tooling
- Infrastructure or platform work that CC manages

Prompt Joel with:
> "Tag for-cc?"

---

## Eligible Artifact Types

| Type | Eligible | Rationale |
|------|----------|-----------|
| snapshot | Yes | Decisions, governance locks, technical specifications |
| project | Yes | New initiatives requiring CC build work |
| restart | Yes | Continuation directives with CC action items |
| journal | No | Reflective/strategic — not actionable by CC |
| leaf / branch / limb / twig | No | Execution-layer — managed within QPM, not CC queue |
| instruction_pack | No | Governance docs — not CC work items |

---

## Rules

1. **Creation-time only** — do not suggest for-cc on existing artifacts retroactively
2. **Joel confirms** — never auto-tag; always ask first
3. **One-way queue** — once CC picks up the artifact and creates an OPEN_THREADS entry, the artifact is considered consumed and will not re-surface
4. **No execution without approval** — for-cc queues work; Joel authorizes execution separately
5. **Do not over-suggest** — only suggest when there is clear CC-actionable work, not for every snapshot or project

---

## What Happens After Tagging

1. Joel tags artifact with `for-cc` during save
2. At next CC session start, CC queries all `for-cc` tagged artifacts
3. CC checks which are not yet referenced in OPEN_THREADS.md
4. CC presents new items to Joel with title, type, and summary
5. Joel approves which items become open threads
6. CC creates OPEN_THREADS entry prefixed `**FROM Q (for-cc).**`
7. Artifact is consumed — will not re-surface in future sweeps

---

## CHANGELOG

### v1 — 2026-03-10
- Initial creation for Q@W workspace
- Adapted from Prime's Loose-Thread Safety Rail (CLAUDE.md v17)
- Scoped to Q@W context (work/demo/opportunity artifacts)
