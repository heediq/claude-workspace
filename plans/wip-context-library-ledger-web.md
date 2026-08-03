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

## 7b — Wizard step 3 (reconciliation) — ⏳ NEXT
- `ReviewWizardPage`: add a 3rd `Stepper` step. On step-2 confirm (review already enqueues the ledger
  job), advance to step 3 instead of navigating. Show a determinate "Reconciling decisions…" state
  driven by `useWsEvent('ledger_ready')` filtered to this `contextId`+`sourceId` (§5). On the event,
  fetch the ledger and render open/needs_review entries to fill/approve (reuse `LedgerEntryRow` or a
  fill-only variant). "Finish later" exits any time; timeout fallback → `ErrorState`.
- Reuses 7a's `Callout` (info/warning) + ledger hooks.

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
