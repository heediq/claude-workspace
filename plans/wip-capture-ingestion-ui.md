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
- [ ] **PR3d — heediq-web** (web-only; the whole upload→transcribe pipeline already exists from PR3c):
      live mic recording on `/capture` + the TopBar usage/limit indicator (D-026). Suggested branch
      `feat/capture-live-record` off `develop`. Likely 2 shippable chunks (keep each ≤3 files / 1
      behavior — split if it grows):
      **(A) Live record.**
      1. `ListenButton` **kit primitive** (`src/components/ui/ListenButton/`) — the canonical **3-state**
         control from rules 03 §4 / 04 §4: `idle` (mic icon, "Start recording") → `recording` (stop
         square + a live elapsed timer, pulsing/record affordance) → `processing` (Spinner, disabled).
         States driven by a `state` prop; labels/aria passed in by the feature via `t()` (compose like
         `Spinner` takes `aria-label`, don't hardcode copy). Gallery entry (all 3 states) + README
         (rules 03 §8/§9). Reduced-motion honored on the pulse.
      2. `useMediaRecorder` hook (`src/features/sources/` or `src/lib/`) — `getUserMedia({audio:true})`
         + `MediaRecorder`; collects chunks, and on stop resolves an **`audio/webm` Blob**. **Online-only
         (D-119)** — no offline/IndexedDB buffering. Handle: permission-denied, no-`MediaRecorder`
         support (feature-detect → `unsupported` copy), empty/0-length capture. Exposes
         `start/stop/state/elapsedMs`.
      3. `RecordIngestForm` (third method on `CapturePage`, under a "Record" heading beside Audio/Text) —
         drives `ListenButton` + `useMediaRecorder`; on stop, wrap the Blob as a `File`
         (`new File([blob], name, {type:'audio/webm'})`) and **feed it straight through the existing
         `useUploadAudio`** (contentType `'audio/webm'`) → same presign → XHR PUT (progress via the PR3c
         `Progress` bar) → `POST /:id/jobs {model:'small'}` → navigate to detail. **This is the big
         reuse**: PR3d adds capture, not a second upload path. Auto-title `capture.record.defaultTitle`
         (date-stamped), editable before submit. `useAsyncAction` guard; all copy `t()`.
      **(B) TopBar usage/limit indicator (D-026).** Feasible now — `GET /me` returns `org.plan` +
      `org.usageLifetimeCount` (`GetMeResponse`, `src/lib/rbac/types.ts`); reuse the existing `/me`
      query pattern (`src/lib/rbac/usePermissions.ts`, same `queryKey`). Free tier: show
      `used / limit` used + a near/at-limit state; paid: hidden or "Unlimited". A kit chip/meter in
      `src/components/layout/TopBar` (add a small `UsageMeter` primitive if none fits). **One open item:
      the free-tier limit number** — grep shared/decisions (D-011/D-019/D-059 cost basis) or heediq-api
      for the free lifetime cap constant before hardcoding; if it isn't a shared constant, that's a
      tiny shared PR (or read it from `/me` if the API starts returning a limit). If the number can't be
      sourced cleanly, ship (A) and split (B) to its own follow-up PR.
      - Tests: `ListenButton` states (gallery-level), `useMediaRecorder` (mock `MediaRecorder`/
        `getUserMedia`), `CapturePage.test.tsx` record path (mock recorder → reuse the PR3c stubbed-XHR
        presign/upload/jobs assertions), usage indicator render (free under/at limit, paid hidden).
        **Keep the no-`beforeEach`-reset pattern.**
      - On PR3d landing the Capture/Ingestion feature is complete → **delete this WIP file** (Step 6).

  **PR3d copy — pre-generated, ready to wire (en/translation.json):**
  ```jsonc
  // capture.record.*
  "record": {
    "heading": "Record",
    "prompt": "Record straight from your mic — we’ll transcribe it into your library when you stop.",
    "start": "Start recording",
    "stop": "Stop recording",
    "recording": "Recording… {{time}}",          // live elapsed, mm:ss
    "processing": "Uploading…",
    "titleLabel": "Title",
    "defaultTitle": "Recording {{date}}",         // e.g. "Recording Aug 4, 2026"
    "recordAnother": "Record again",
    "permissionDenied": "Heediq needs microphone access to record. Allow it in your browser settings, then try again.",
    "unsupported": "Your browser can’t record audio. Upload an audio file instead.",
    "empty": "That recording was empty — nothing was captured.",
    "submitError": "Something went wrong saving your recording. Please try again."
  },
  // ListenButton aria (screen-reader state announcements; passed in from RecordIngestForm)
  "listenButton": {
    "idleAria": "Start recording",
    "recordingAria": "Recording, {{time}} elapsed. Activate to stop.",
    "processingAria": "Processing your recording"
  },
  // TopBar usage/limit (D-026) — free tier
  "usage": {
    "used": "{{used}} of {{limit}} free transcriptions used",
    "remaining": "{{remaining}} left",
    "limitReached": "You’ve used all {{limit}} free transcriptions.",
    "unlimited": "Unlimited"
  }
  ```
  Also update `capture.subtitle` to drop "live recording is coming soon" once (A) ships.

## Decisions / notes taken
- API bases off `develop` (ledger PR still open on its own branch — our sources.ts/upload.ts changes
  are independent). Route name `/capture` confirmed.
- No new WS event: reuse `job_status` + `classification_ready`.
- Text has no tier-gating (no model choice); tier only selects Haiku/Sonnet downstream (D-067).
  Audio DOES take a whisper `model` at `/jobs` — PR3c sends `'small'` (free-safe); `large-v3` is paid-only.
- Usage indicator (PR3d) is **feasible now** — `GET /me` (`GetMeResponse`) returns `org.plan` +
  `org.usageLifetimeCount`; reuse the `usePermissions.ts` `/me` query. Only open item is the free-tier
  limit number (see PR3d (B)). No new endpoint needed.
- PR3d **reuses PR3c's `useUploadAudio` wholesale** — a recording is just an `audio/webm` File fed
  through the same create→presign→XHR-PUT→jobs path. PR3d adds *capture* (ListenButton +
  useMediaRecorder), not a new upload path. No shared/api PR expected (except possibly the free-tier
  limit constant for the usage meter).
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
- **PR3c done** — heediq-web#48 merged (squash) + deployed to dev (run 30882024370). **308 web tests
  green.** Branch `feat/capture-audio-upload` off `develop`. New `Progress` kit primitive
  (`src/components/ui/Progress/` — determinate bar, `role="progressbar"` ARIA, `accent`/`success` tones,
  width animates on the shared motion tokens; gallery + README; `common.progress` i18n added).
  `useUploadAudio` in `sources-api.ts` (factored a shared `createSourceShell` out of `useIngestText`):
  create → `POST /upload/presign` → **XHR PUT** to S3 with `upload.onprogress` → `POST /:id/jobs
  {model:'small'}` → resolve `sourceId`. `AudioIngestForm` (extension-based type resolve → one of five
  presign content types, 2 GB cap, both validated pre-network with a toast) added to `CapturePage`
  alongside `TextIngestForm` under method headings. Tests: 3 `Progress` + 5 new audio in
  `CapturePage.test.tsx` (stubbed `FakeXHR`, inputs told apart by `accept`, no-`beforeEach`-reset kept).
  **308 web tests green, typecheck clean.** READMEs (`src/features/sources/`, `Progress/`) + codebase
  MEMORY updated.
- **Next: PR3d (the last slice)** — live mic record on `/capture` + TopBar usage indicator. Full spec
  is the PR3d checklist item above (ListenButton 3-state kit primitive + `useMediaRecorder` +
  `RecordIngestForm` reusing `useUploadAudio`; D-026 usage meter off `GET /me`). Copy is pre-generated
  in the checklist item. On PR3d landing the whole Capture/Ingestion feature is done — delete this WIP.

### Cold-start kickoff (paste into the next session)
> Continue the Capture/Ingestion UI plan (`claude-workspace/plans/wip-capture-ingestion-ui.md`).
> PR3a/PR3b/PR3c are all merged + deployed to dev — text-file, audio-file upload, the `Progress` kit
> primitive, and `useUploadAudio` are live. Start **PR3d — live mic recording** on a new branch
> `feat/capture-live-record` off `develop`. It's web-only and the whole upload→transcribe pipeline
> already exists: build a 3-state `ListenButton` kit primitive (gallery + README), a `useMediaRecorder`
> hook (getUserMedia + MediaRecorder → an `audio/webm` Blob, online-only per D-119, handle
> permission-denied/unsupported/empty), and a `RecordIngestForm` on `CapturePage` that wraps the Blob
> as a File and **feeds it straight through the existing `useUploadAudio`** → navigate to detail. Then
> add the D-026 TopBar usage/limit indicator off `GET /me` (`org.plan` + `org.usageLifetimeCount` —
> find the free-tier limit constant first; split it to a follow-up PR if that number can't be sourced
> cleanly). Copy is pre-generated in the PR3d checklist item; keep the no-`beforeEach`-reset test
> pattern. Ship merge→deploy→continue like the others, then delete this WIP file.
