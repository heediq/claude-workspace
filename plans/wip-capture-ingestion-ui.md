# WIP — Capture / Ingestion UI (D-150)

**Feature:** The ingestion front door — record + audio-upload + text-upload as the D-026 Listen
landing, plus the real SourcesLibraryPage list. #1 pre-dogfooding blocker.
**Decision:** D-150 (locked 2026-08-03). Reuses D-026 / D-065 / D-137; online-only record (D-119).

## Slices / PRs (all land this round; each ≤3 files / 1 behavior)
- [x] **PR1 — heediq-shared** (branch `feature/capture-ingestion-contracts` off `develop`):
      `IngestTextRequestSchema` (`{text}`); optional `sourceType` on `SourceSchema`. Tests green (284).
      → **PR heediq-shared#50** (open). Blocks PR2/web on merge + version publish + Renovate bump.
- [x] **PR2 — heediq-api** (branch `feature/text-ingest-endpoint` off `develop`): `POST /sources/:id/text`
      (write transcript+status=processing+sourceType=text, enqueue SummarizationJobMessage sourceType=text
      with tier msg-attr, failed-rollback on enqueue error); presign stamps `audioS3Key`+sourceType=audio
      on the source row (unblocks `/:id/jobs`). Tests in sources.test.ts (6) / upload.test.ts (3); full
      suite 291 green, typecheck+build clean. dep bumped `@heediq/shared` → `^0.15.5`.
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
- **PR1 done** — heediq-shared#50 merged; `@heediq/shared@0.15.5` published (bump chain #52→#53, publish
  run 30850255124). Local GH Packages read token was stale — refreshed `gh` with `read:packages`.
- **PR2 done (code)** — `feature/text-ingest-endpoint` off `develop`; heediq-api now on `@heediq/shared@0.15.5`.
  291 tests green, typecheck+build clean. → opening PR to `develop`.
- **Next: PR3a (heediq-web)** — real SourcesLibraryPage list. Web is still on the older `@heediq/shared`;
  it needs `sourceType`/`IngestTextRequest` only from PR3b onward, so a shared reinstall is due before PR3b.
