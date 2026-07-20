# WIP — Context Library Step 1: `@heediq/shared` contracts + Container→Context rename

**Branch:** `feature/context-library-shared-contracts` (repo: `heediq-shared`, off `develop`)
**Spec:** `plans/context-library-spec.md` — this is §11 **step 1** (shared contracts) only.
**Decisions:** D-124–D-140 (esp. D-127/D-129/D-130/D-131/D-133/D-134/D-135/D-136/D-139).

## Status: implementation green; docs/memory in progress

- [x] Step 0 — resume/git-sync/coherence check (fixed product.md Container→Context staleness, committed to claude-workspace)
- [x] Step 1–2 — questions + plan (locked: shrink Summary now; add DecisionLedgerEntry now)
- [x] Step 3 — implementation (commit `3b6f2ad`)
- [x] Step 4.5 — typecheck + `pnpm test` green (200 tests)
- [ ] Step 5 — `heediq-shared/README.md` update (approval-gated)
- [ ] Step 6 — memory: MEMORY.md + feature_dependency_map.md
- [ ] PR — not yet (ask Andrii: open PR or keep working)

## What shipped (contracts only)
- `enums.ts`: Domain, ContextStatus, SourceClassification, ExtractedItemStatus, LedgerEntryStatus, LedgerEntryOrigin
- `domains.ts` (new): `DOMAIN_PROFILES` (slug-only fields/prompts, i18n-safe) + `DOMAIN_FIT_CONFIDENCE_THRESHOLD = 0.75`
- `context.ts` (new): `ContextSchema`, `ProposedClassificationSchema` (exactly-one-of refine), `ExtractedItemSchema`, `DecisionLedgerEntrySchema` + `LEDGER_REVIEW_CONFIDENCE_THRESHOLD = 0.5`
- `domain.ts`: Source +`contextId`/`classification`(optional, no default)/`proposedClassification`; Summary shrunk to `transcript` + `gist` (breaking)
- `ws.ts`: `classification_ready` / `chat_delta` / `chat_complete` (additive)
- `package.json`: 0.13.0 → 0.14.0

## Handoff to next steps (out of scope here)
- **Infra (§11 step 2):** create `heediq-contexts` (PK/SK + `by-org` GSI for the D-134 tree), an ExtractedItem store, ledger table, conversations/chat-messages tables (D-138). Mirror in `heediq-api/scripts/integration/create-tables.ts` (D-030 drift risk). Source field additions + Summary shrink are **non-key attributes → no infra change**.
- **Consumers bump `@heediq/shared` in their own steps** — the breaking Summary shrink only bites `heediq-worker-summarization` / `heediq-api` / `heediq-web` / `heediq-worker-transcription`(models.py) when they upgrade.
- **Deferred, flagged:** archive fully-superseded **D-132** → `DECISIONS_ARCHIVE.md` at the next consistency check (per its own annotation).
