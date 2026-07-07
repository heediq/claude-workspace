# STALE_ARCHIVE.md — Removed Codebase Memory & README Content

Home for content trimmed from READMEs, `MEMORY.md`, or `feature_dependency_map.md` during a
consistency check (`rules/10-consistency-check.md`, size & staleness control section) — resolved
gotchas, condensed narration, superseded dependency entries. Moved here verbatim, never deleted, so
history stays recoverable.

**This file is intentionally excluded from normal context loads** — it is not part of the Step 0c /
session-start read set (`01-development-workflow.md`, `08-memory.md`) and is not re-read by future
consistency checks. Open it only when explicitly asked for removed/historical content. This mirrors
how `memory/business/DECISIONS_ARCHIVE.md` is handled for decisions.

## Format
```
## YYYY-MM-DD · <source file> · <reason removed>
<content, verbatim>
```

## Entries

## 2026-07-07 · heediq-worker-summarization/README.md · redundant gotcha, merged into an adjacent non-obvious entry during consistency check
- **Claude API key fetched at cold start** — any Secrets Manager error on init fails all warm invocations until the next cold start. Rotate secrets carefully.

(This restated the already-documented "fetched at cold start" fact from the Contracts section; the
genuinely non-obvious part — cold-start Secrets Manager errors poisoning all warm invocations — was
kept and reworded into the README's Gotchas section, tied to D-100's module-level caching mechanism.)
