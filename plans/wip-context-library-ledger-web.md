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

## 7c — Chat gating banner — ✅ DONE, PR #44 (CI green)
- `usePostMessage` takes optional `bypassLedgerGating` (omitted from body unless set).
- `ChatThread` (now takes `contextId`): `send(text, { bypass })` remembers the pending text; `onError`
  catches `ApiClientError` code `LEDGER_GATED`, parses `LedgerGatedDetailsSchema`, sets a `gate` state
  (no toast). Non-gated errors keep the toast path.
- `src/features/chat/LedgerGateBanner.tsx` (new): `Callout`(warning) above the composer. Reads blockers
  **live from `useLedger`** (not the stale error payload) filtered to the gated entryIds, renders them as
  `LedgerEntryRow`s to fill in place; a `sawBlocking` ref guards a premature auto-resolve on first paint,
  then fires `onAllResolved` → parent re-sends (no bypass). "Send anyway" → resend `{ bypass: true }`;
  "Dismiss" closes.
- `ContextChatPage` threads `contextId` in. Tests: `LedgerGateBanner.test.tsx` (4) + ChatThread gated
  case. Full gate green (`test:pre-pr`: typecheck + 288 tests).

**Gotcha found:** `LedgerBlockingEntry.entryId` is a **uuid** in the schema — test fixtures must use a
real uuid or `LedgerGatedDetailsSchema.safeParse` fails and the code falls through to the toast path.

## ✅ ALL SHIPPED — 7a #42, 7b #43, 7c #44 all merged to `develop`
Codebase memory written: `MEMORY.md` "Decision Ledger" entry + `feature_dependency_map.md`
`Decision Ledger (D-136/D-137/D-148/D-149)` entry (backend + web, one coherent entry). This branch's
work is complete; safe to close this WIP file once the branch is deleted. **MEMORY.md is at 141/150 —
flag a consolidation pass before the next big feature entry.**

## Notes / gotchas
- `needs_review` shares the amber `active` tone with in-progress by design (D-072 — no warning token).
- `ledger_ready` payload = `{ contextId, sourceId, entryCount }`; filter on both ids (same discipline
  as `useChatStream`'s conversationId filter) to avoid cross-context bleed.
- Write controls are UX-gated only; server `context:update` is the real boundary.
- After 7c merges: add the codebase `MEMORY.md` + `feature_dependency_map.md` entry for the whole
  Decision Ledger feature (backend + web) as one coherent entry.
