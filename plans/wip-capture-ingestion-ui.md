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
- [x] **PR3a — heediq-web**: real SourcesLibraryPage list (`useSourcesList`, GET /sources) + Sources
      nav link + WS live-update. Table gains an `interactive` row variant. Tests (6). → **heediq-web#46**
      merged; deployed to dev (run 30852627108). 294 web tests green.
- [x] **PR3b — heediq-web**: capture landing `/capture` (post-auth redirect moves here) + text-upload
      path end-to-end (create → /text → detail → review). Tests (5). → **heediq-web#47** merged;
      deployed to dev (run 30880857083). 300 web tests green.
- [x] **PR3c — heediq-web** (web-only; all backend + contracts already exist): audio-file upload
      method on the Capture landing. New `AudioIngestForm` (sibling of `TextIngestForm`, added to
      `CapturePage`) + `useUploadAudio` hook in `sources-api.ts`. Flow, all endpoints live on dev:
      1. `POST /sources {title}` → `{source}` (reuse the shell-create; factor the shared bit out of
         `useIngestText` if clean).
      2. `POST /upload/presign {sourceId, contentType, fileSizeBytes}` → `{uploadUrl, s3Key, expiresIn}`
         (also stamps `audioS3Key`+`sourceType='audio'` on the row — required before `/jobs`).
         `contentType` ∈ `audio/webm|mp4|mpeg|wav|ogg`; 2 GB cap. Contracts:
         `PresignUploadRequest/ResponseSchema` (already in `@heediq/shared@0.15.5`, web is on it).
      3. `PUT uploadUrl` with the File as body — **must use `XMLHttpRequest`, not `fetch`** (fetch can't
         report upload progress); wire `xhr.upload.onprogress` to a determinate progress UI. This is
         raw S3, no auth header, `Content-Type` = the file's type.
      4. `POST /sources/:id/jobs {sourceId, model}` (`EnqueueJobRequestSchema`) → `{jobId}`. **Send
         `model: 'small'`** — `WhisperModel` is `'small'|'large-v3'` and `large-v3` 403s on free tier
         (D-060). (Model/tier picker is a later nicety, not PR3c.)
      5. `navigate('/sources/:id')` — detail page shows transcription→summarize→classify progress via WS.
      - **Kit gap:** there is **no Progress/ProgressBar component** in `src/components/ui/`. PR3c needs a
        determinate progress indicator for the upload → add a `Progress` kit primitive (gallery entry +
        README per rules 03 §8/§9). If that bloats PR3c past ~3 files, split the kit `Progress` into its
        own tiny PR first. Golden rule: no bespoke progress bar in feature code.
      - Same conventions as PR3b: `t()` copy (`capture.audio.*`), `useAsyncAction` guard, `Can` gating is
        already at the `/capture` route so the form itself doesn't re-gate. Reject oversize/wrong-type
        files client-side with a toast before presigning. Tests in `CapturePage.test.tsx` (mock presign +
        a stubbed XHR) — **keep the no-`beforeEach`-reset pattern** (see the vitest note below).
- [ ] **PR3d — heediq-web**: `ListenButton` kit component (3-state) + `useMediaRecorder` + live record;
      TopBar usage/limit indicator (D-026). Tests + gallery + README.

## Decisions / notes taken
- API bases off `develop` (ledger PR still open on its own branch — our sources.ts/upload.ts changes
  are independent). Route name `/capture` confirmed.
- No new WS event: reuse `job_status` + `classification_ready`.
- Text has no tier-gating (no model choice); tier only selects Haiku/Sonnet downstream (D-067).
  Audio DOES take a whisper `model` at `/jobs` — PR3c sends `'small'` (free-safe); `large-v3` is paid-only.
- Usage indicator (PR3d) may drop to a follow-up if `GET /me` doesn't expose plan+usageLifetimeCount.
- **PR3c is web-only** — the presign endpoint, `/jobs`, and the `PresignUpload*` contracts already exist
  (shared 0.15.5, api on dev). No shared/api PR needed.
- **Testing gotcha (vitest v2):** on a `vi.fn` API mock, a `beforeEach` `mockReset`/`mockClear`/
  `mockImplementation` makes an *already-caught* fire-and-forget rejection (intentional error-path
  tests) report as *unhandled* and fail spuriously. Fix used in `CapturePage.test.tsx`: omit the
  `beforeEach` reset, set impl per-test, assert with existence-based `toHaveBeenCalledWith`. Carry this
  into PR3c's tests. (Auto-memory: `reference-vitest-vifn-reset-unhandled-rejection`.)

## Status
- **PR1 done** — heediq-shared#50 merged; `@heediq/shared@0.15.5` published (bump chain #52→#53, publish
  run 30850255124). Local GH Packages read token was stale — refreshed `gh` with `read:packages`.
- **PR2 done (code)** — `feature/text-ingest-endpoint` off `develop`; heediq-api now on `@heediq/shared@0.15.5`.
  291 tests green, typecheck+build clean. → opening PR to `develop`.
- **PR3a done** — heediq-web#46 merged + deployed to dev (run 30852627108). 294 web tests green.
- **PR3b done** — heediq-web#47 merged + deployed to dev (run 30880857083). 300 web tests green. Web
  bumped to `@heediq/shared@^0.15.5`. `/capture` route (`Can`-gated on `sources:create`) + post-auth
  redirect + `SourcesLibraryPage` Capture CTA + `TextIngestForm`/`useIngestText`. Note: `CapturePage.
  test.tsx` deliberately omits a `beforeEach` mock reset — a vitest v2 `vi.fn` spy-result-tracking bug
  mis-flags the intentionally-caught ingest-failure rejection as unhandled (comment in-file).
- **PR3c done (code)** — branch `feat/capture-audio-upload` off `develop`. New `Progress` kit primitive
  (`src/components/ui/Progress/` — determinate bar, `role="progressbar"` ARIA, `accent`/`success` tones,
  width animates on the shared motion tokens; gallery + README; `common.progress` i18n added).
  `useUploadAudio` in `sources-api.ts` (factored a shared `createSourceShell` out of `useIngestText`):
  create → `POST /upload/presign` → **XHR PUT** to S3 with `upload.onprogress` → `POST /:id/jobs
  {model:'small'}` → resolve `sourceId`. `AudioIngestForm` (extension-based type resolve → one of five
  presign content types, 2 GB cap, both validated pre-network with a toast) added to `CapturePage`
  alongside `TextIngestForm` under method headings. Tests: 3 `Progress` + 5 new audio in
  `CapturePage.test.tsx` (stubbed `FakeXHR`, inputs told apart by `accept`, no-`beforeEach`-reset kept).
  **308 web tests green, typecheck clean.** READMEs (`src/features/sources/`, `Progress/`) + codebase
  MEMORY updated. → **next: PR to `develop` via `gh`, watch CI, squash+delete, sync, watch dev deploy.**
- **Next after PR3c ships: PR3d** — `ListenButton` + `useMediaRecorder` + live record; TopBar usage
  indicator. Same merge→deploy→continue cadence.

### Cold-start kickoff (paste into the next session)
> Continue the Capture/Ingestion UI plan (`claude-workspace/plans/wip-capture-ingestion-ui.md`).
> PR3a/PR3b are merged + deployed to dev. Start **PR3c — audio-file upload** on a new branch
> `feat/capture-audio-upload` off `develop`. It's web-only (presign, `/jobs`, and the `PresignUpload*`
> contracts already exist). Build `AudioIngestForm` + `useUploadAudio` per the PR3c checklist item
> (create → presign → XHR PUT with progress → `POST /:id/jobs {model:'small'}` → navigate to detail),
> add a `Progress` kit primitive for the upload bar (gallery + README), tests using the no-`beforeEach`-
> reset pattern. Then ship it merge→deploy→continue like the others.
