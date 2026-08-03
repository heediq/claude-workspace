# WIP · Context Library Decision Ledger — web half (D-136 / D-137 / D-149)

**Branch:** `feature/context-library-ledger-web` (heediq-web)
**Backend:** complete & deployed (shared 0.15.4, heediq-api 6d merged, heediq-ledger deployed). This
branch is the web consumer of the ledger CRUD routes, the `ledger_ready` WS event, and the
`LEDGER_GATED` 409.

Three sub-features on a shared foundation, shipped as three incremental PRs to `develop` (via `gh`):

## 7a — Foundation + standing ledger view — ✅ DONE (local), PR pending
- Bumped `@heediq/shared` → `^0.15.4`.
- `src/lib/api-client.ts`: `ApiClientError` now carries `details` (additive) — needed for
  `LEDGER_GATED`'s `blockingEntries` in 7c. Passes `body.error.details` through.
- `src/features/ledger/ledger-api.ts`: `useLedger` / `useCreateLedgerEntry` / `useUpdateLedgerEntry`
  / `useDeleteLedgerEntry` + `ledgerKeys`.
- Kit: new **`Callout`** primitive (`src/components/ui/Callout/`, tones warning/danger/info backed by
  existing tokens — no warning token, D-072) + README + `/dev/ui` gallery entry. Reused by 7b/7c.
- `src/features/ledger/`: `LedgerStatusBadge` (confirmed→success, needs_review→amber `active`,
  open→neutral), `LedgerEntryRow` (topic + status + inline fill/edit + confirm-delete, writes behind
  `<Can permission="context:update">` + `useAsyncAction` guard), `LedgerSection` (header, add-by-topic
  form, 3-branch list). README added.
- `ContextDetailPanel.tsx` embeds `LedgerSection` below sub-contexts.
- i18n: top-level `ledger.*` block (status labels, empty/error, action copy).
- Tests: `Callout` (3), `ledger-api` (5), `LedgerEntryRow` (5), `LedgerSection` (5). Full gate green
  (`test:pre-pr`: typecheck + 278 tests).

## 7b — Wizard step 3 (reconciliation) — ✅ DONE, PR #43 (CI green)
- `ReviewWizardPage`: 3rd `Stepper` step (`ledger` · "Decisions"). Step-2 confirm now advances to
  step 3 (`setStep(2)`) instead of navigating; the `alreadyFiled` early-return is gated to `step === 0`
  so the source flipping to `approved` post-file doesn't eject the wizard.
- `src/features/ledger/LedgerReconcileStep.tsx` (new): phase machine `reconciling → ready | timedOut`.
  Waits with a visible "Reconciling decisions…" `Callout`(info)+`Spinner`, driven by
  `useWsEvent('ledger_ready')` filtered to this `contextId`+`sourceId`. On ready, `useLedger` (enabled
  only then) fetches and surfaces `open`/`needs_review` entries as `LedgerEntryRow`s to fill; all-settled
  → `EmptyState`; 90s timeout → `ErrorState` + "Finish later". **Done** always exits to the source.
- Tests: `LedgerReconcileStep.test.tsx` (5); updated `ReviewWizardPage.test.tsx` (post-file advance).
  Full gate green (`test:pre-pr`: typecheck + 283 tests).

## 7c — Chat gating banner — ⏳ AFTER 7b
- `ChatThread.send`: catch `ApiClientError` code `LEDGER_GATED`, read `details.blockingEntries`
  (`LedgerGatedDetailsSchema`), render a `Callout` (warning) above the composer listing blocking
  topics with inline answer fields (PATCH via `useUpdateLedgerEntry`). As each clears it drops; when
  empty, auto-retry the send. Persistent "Send anyway" → resend with `bypassLedgerGating: true`.
  Non-gated errors keep the existing toast path. No new WS event (D-149 is synchronous).

## Notes / gotchas
- `needs_review` shares the amber `active` tone with in-progress by design (D-072 — no warning token).
- `ledger_ready` payload = `{ contextId, sourceId, entryCount }`; filter on both ids (same discipline
  as `useChatStream`'s conversationId filter) to avoid cross-context bleed.
- Write controls are UX-gated only; server `context:update` is the real boundary.
- After 7c merges: add the codebase `MEMORY.md` + `feature_dependency_map.md` entry for the whole
  Decision Ledger feature (backend + web) as one coherent entry.
