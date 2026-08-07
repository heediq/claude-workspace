# WIP — Cross-repo docs ↔ codebase sync sweep (scheduled)

**Status:** Scheduled — run at the **start of the next session** (Andrii's request, 2026-08-07).
**Not a code branch** — this is a docs/memory hygiene pass; commits land per-repo (`docs:` /
`docs(memory):`) and straight to `claude-workspace`'s default branch for memory/plans.

## Why
Andrii wants active docs to reflect **only what actually exists** — no history, no obsolete
mechanisms, no references to files/resources/components that are gone. This is now locked as
**D-158**. This sweep is the first full application of it across every repo.

## What to do
Run the full **`rules/10-consistency-check.md`** end to end (it already encodes the procedure —
per-repo README-vs-code, cross-repo contracts, memory-index accuracy, §5 size/staleness compression,
DR completeness), with the **D-158 emphasis**: actively delete/rewrite anything that names something
no longer in the code, and archive (don't delete) superseded/history content.

Trigger with `/consistency-check` from the workspace root (spawns one agent per repo per its
dependency edges).

## Specific known targets to catch this run (seed list — not exhaustive)
- **Archive fully-superseded decisions still sitting active:** `D-155` (fully superseded by D-156 —
  the mocked E2E tier was dropped, never shipped) → move verbatim to `DECISIONS_ARCHIVE.md`, drop its
  bullet from `decisions/process.md`, decrement the manifest Process count. Scan for any other
  entry whose `Superseded by:` fully restates it.
- **Transcription pipeline docs after the D-157 change lands** (EventBridge Pipes → dispatcher
  Lambda; one queue, no tier filter/attribute; stale S3→SQS notification removed): sweep
  `heediq-infra/README.md` §TranscriptionStack + the "Message routing"/"Spot interruption" notes,
  `memory/business/architecture.md`, `memory/codebase/MEMORY.md`, and `feature_dependency_map.md`
  for any lingering "EventBridge Pipes" / "tier message attribute" / "Pipe filter" references —
  rewrite to the dispatcher-Lambda reality. (These are updated as part of the D-157 feature's Step 5,
  but double-check here.)
- Any README "until PR #N" / "to be added after" caveats now resolved.

## Output
Findings table (severity · repo · file · finding · fixed?) + rough size delta, per `rules/10`.

## Related
D-158 (active-docs principle), D-157 (transcription dispatcher Lambda — its own infra branch/WIP),
`rules/10-consistency-check.md`, `rules/08-memory.md` (§ Active docs).
