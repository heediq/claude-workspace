# WIP — Capture / Ingestion UI (D-150)

**Feature:** The ingestion front door — record + audio-upload + text-upload as the D-026 Listen
landing, plus the real SourcesLibraryPage list. #1 pre-dogfooding blocker.
**Decision:** D-150 (locked 2026-08-03). Reuses D-026 / D-065 / D-137; online-only record (D-119).

## Slices / PRs (all land this round; each ≤3 files / 1 behavior)
- [x] **PR1 — heediq-shared** (branch `feature/capture-ingestion-contracts` off `develop`):
      `IngestTextRequestSchema` (`{text}`); optional `sourceType` on `SourceSchema`. Tests green (284).
      → **PR heediq-shared#50** (open). Blocks PR2/web on merge + version publish + Renovate bump.
- [ ] **PR2 — heediq-api** (off `develop`): `POST /sources/:id/text` (write transcript+status=processing,
      enqueue SummarizationJobMessage sourceType=text); presign stamps `audioS3Key`+sourceType=audio
      on the source row (unblocks `/:id/jobs`). Tests in sources.test.ts / upload.test.ts.
- [ ] **PR3a — heediq-web**: real SourcesLibraryPage list (`useSourcesList`, GET /sources) + Sources
      nav link + WS live-update. Tests.
- [ ] **PR3b — heediq-web**: capture landing `/capture` (post-auth redirect moves here) + text-upload
      path end-to-end (create → /text → detail → review). Tests.
- [ ] **PR3c — heediq-web**: audio-file upload path (create → presign → PUT w/ progress → /jobs). Tests.
- [ ] **PR3d — heediq-web**: `ListenButton` kit component (3-state) + `useMediaRecorder` + live record;
      TopBar usage/limit indicator (D-026). Tests + gallery + README.

## Decisions / notes taken
- API bases off `develop` (ledger PR still open on its own branch — our sources.ts/upload.ts changes
  are independent). Route name `/capture` confirmed.
- No new WS event: reuse `job_status` + `classification_ready`.
- Text has no tier-gating (no model choice); tier only selects Haiku/Sonnet downstream (D-067).
- Usage indicator (PR3d) may drop to a follow-up if `GET /me` doesn't expose plan+usageLifetimeCount.

## Status
- **PR1 done** — heediq-shared#50 open (contracts, tests green). Awaiting review/merge.
- **Next: PR2 (heediq-api)** — BLOCKED until #50 merges + `@heediq/shared` publishes a new version and
  heediq-api's dep bumps off `^0.15.4` (that version lacks `IngestTextRequest`). Then build
  `POST /sources/:id/text` + presign `audioS3Key` stamp off `develop`.
