# WIP — App repos scaffold (MVP critical path)

**Status:** All backend repos scaffolded and PRs open. CI green on all repos. D-068 PR 1 rename
sequence complete (steps 1–5, all pushed/PR'd — see below). `heediq-infra` PR #31 additionally
redeployed clean to dev — all 7 stacks live against `heediq-sources`/`sourceId` naming (hit the
cross-stack export deadlock gotcha twice along the way; now documented in
`heediq-infra/README.md` Gotchas). heediq-web initial scaffold (tooling, D-008 tokens, 3 base UI
kit components, placeholder routes, CI/deploy workflows) is committed on `feature/web-scaffold`
(not yet PR'd) — typecheck/test/build all green. The four MVP screens (auth, home/Listen, sources
library, source detail) are the next step on that branch.

**MVP build order (D-069, supersedes D-010's scope):** auth/onboarding → home/Listen → sources
library → source detail/summary → multi-source upload + container-level synthesis view

**⚠️ Pending rename (D-068 — Locked, in progress):** `recording` → **Source**
(`heediq-sources`, `sourceId`), `project` → **Container** (`heediq-containers`, `containerId`,
self-referencing `parentContainerId`, not yet built — no project/epic/story concept exists in
code today, this is net-new not a rename), plus a new `labels: string[]` field on Source. Locked
*after* the current open PRs were written — they still use `recording`/`heediq-recordings`
naming. Split into two PRs: **PR 1 (rename, mechanical, in progress)** vs **PR 2+ (Container
entity + container-level synthesis, D-069, real new feature — not started)**.

**PR 1 rename sequence:**
1. ~~**heediq-shared**~~ ✅ `Recording`→`Source`, `recordingId`→`sourceId`, `RecordingStatus`→
   `SourceStatus`, `CreateRecordingRequest`/`UpdateRecordingRequest`→`CreateSourceRequest`/
   `UpdateSourceRequest`, added `labels: string[]`. Bumped to `0.2.0` (breaking). 50/50 tests
   green. PR open: github.com/heediq/heediq-shared/pull/4 (`refactor/rename-recording-to-source`
   → develop).
2. ~~**heediq-infra**~~ ✅ `heediq-recordings` → `heediq-sources` table (FoundationStack), GSIs,
   `RECORDINGS_TABLE_NAME`→`SOURCES_TABLE_NAME` env vars, SSM param renamed. Confirmed dev table
   `RemovalPolicy.DESTROY` + no real data — safe destroy/recreate. 153/153 tests green. PR open:
   github.com/heediq/heediq-infra/pull/31 (`refactor/rename-recordings-table-to-sources` →
   develop).
3. ~~**heediq-api**~~ ✅ Bumped `@heediq/shared` to `0.2.0`. Renamed route file, mount path
   (`/recordings`→`/sources`), env var (`RECORDINGS_TABLE_NAME`→`SOURCES_TABLE_NAME`), S3 key
   prefix, and all field references; added `labels: []` on Source creation. 17/17 tests green.
   Scoped `pnpm-workspace.yaml`'s `minimumReleaseAgeExclude` to `'@heediq/*'` (pnpm's 24h
   supply-chain policy otherwise blocks installing same-day-published internal packages — kept
   the full 24h window for third-party deps). Pushed, updates existing PR:
   github.com/heediq/heediq-api/pull/2 (`feature/api-scaffold` → develop).
4. ~~**heediq-worker-summarization**~~ ✅ Bumped `@heediq/shared` to `0.2.0`. Renamed
   `recordingId`→`sourceId`, `recordingsTable`→`sourcesTable`,
   `RECORDINGS_TABLE_NAME`→`SOURCES_TABLE_NAME`, `heediq-recordings`→`heediq-sources` across
   `content-loader.ts`, `writer.ts`, `handler.ts`, `config.ts`, tests. Same
   `minimumReleaseAgeExclude: ['@heediq/*']` fix applied. 12/12 tests green. Pushed, updates
   existing PR: github.com/heediq/heediq-worker-summarization/pull/2
   (`feature/summarization-worker` → develop).
5. ~~**heediq-worker-transcription**~~ ✅ Python `models.py` is hand-maintained (mirrors
   `@heediq/shared`, not generated) — applied the same field renames manually:
   `recording_id`/`recordingId`→`source_id`/`sourceId`, `recordings_table`→`sources_table`,
   `RECORDINGS_TABLE_NAME`→`SOURCES_TABLE_NAME`, `heediq-recordings`→`heediq-sources` in
   `src/models.py`, `src/worker.py`, `src/config.py`, tests, README. 11/11 pytest + mypy --strict
   clean. New branch (this repo's current branch was an unrelated, already-merged PR #8), pushed,
   opened PR: github.com/heediq/heediq-worker-transcription/pull/9
   (`refactor/rename-recording-to-source-py` → develop).
6. **heediq-web** ⬅ NEXT — not started yet; will just use the new `Source` naming directly, no
   migration needed.

**Merge order matters:** heediq-shared PR #4 must merge (and publish `0.2.0`) before heediq-api /
heediq-worker-summarization can bump their dependency and update field references. heediq-infra
PR #31 can merge independently (no code dependency on `@heediq/shared`'s version) but should land
before any of the app repos deploy against it, since the table name changes together.

---

## Repo build sequence

1. ~~**heediq-shared**~~ ✅ `@heediq/shared@0.1.0` on GitHub Packages. 49 tests. Merged to develop.
2. ~~**heediq-api**~~ ✅ PR #1 open (feature/api-scaffold → develop). 17 tests. deploy.yml wired.
3. ~~**heediq-infra fix**~~ ✅ PR open (fix/transcription-task-runtime → develop). SSM-based image tag promotion + setup.sh section 3 (SSM seed).
4. ~~**heediq-worker-transcription**~~ ✅ PR open (feature/transcription-worker). 11 pytest + mypy. deploy.yml: ECR push + ssm/task-def/pipes promotion per env.
5. ~~**heediq-worker-summarization**~~ ✅ PR #1 open (feature/summarization-worker). 10 Vitest tests. deploy.yml: esbuild → lambda update-function-code per env.
6. **heediq-web** → Vite + React PWA. Initial scaffold done (this session); MVP screens ⬅ NEXT

---

## 6. heediq-web (next)

**Branch:** `feature/web-scaffold`

**Purpose:** Vite + React PWA — auth, home/Listen, sources library, source detail + summary.

**Initial scaffold — done, committed (not yet PR'd):** tooling (Vite/TS/Tailwind/Vitest per D-030),
D-008 design tokens (`tailwind.config.ts`, `src/styles/tokens.css` — `success`/`warning`/`danger`/
`info` are provisional, not yet locked), 3 base UI-kit components (Button, Spinner, Card, each with
its own README + `03-ui-kit.md`-compliant states), placeholder routes for all 4 MVP screens, a
dev-only `/dev/ui` component gallery, and CI (`ci.yml`) + deploy (`deploy.yml`) workflows. 5/5 tests
green, typecheck clean, `pnpm run build` succeeds. See `heediq-web/README.md` for full detail.
**Next**: build out the 4 screens below on the same branch.

### Screens (MVP)
1. **Auth** — Cognito hosted UI + Google/Microsoft IdP, org creation on first login
2. **Home / Listen** — three-state Listen button (idle/recording/processing, D-026/D-008), upload audio/text
3. **Sources library** — list with real-time status badges, search/filter
4. **Source detail** — transcript + summary tabs, live job status via WebSocket (D-061)

### Deploy
- Vite build → `aws s3 sync` → `aws cloudfront create-invalidation`
- Reads `/heediq/web/cloudfront-distribution-id` and `/heediq/web/url` from SSM

---

## Key implementation notes (carry into heediq-web)

- **Auth**: Cognito User Pool + Google + Microsoft IdPs (D-020). Cognito hosted UI or Amplify Auth. JWT from Cognito is passed as `Authorization: Bearer <token>` to all API calls.
- **API base**: `https://api-dev.heediq.com/api/v1/` (dev) — from SSM `/heediq/api/endpoint-url`. All routes under `/api/v1/` require JWT auth.
- **WebSocket**: `wss://ws-dev.heediq.com` (dev) — from SSM `/heediq/api/ws-endpoint-url`. Status events: `{ type: 'job_status', jobId, sourceId, status, updatedAt }` (WsStatusMessage in @heediq/shared).
- **Source flow**: `POST /sources` → `POST /upload/presign` → S3 PUT → `POST /sources/:id/jobs` → real-time status via WebSocket.
- **No transcript in DynamoDB on sources table for the frontend** — the `transcript` field is written by the transcription worker, readable via `GET /sources/:id`. The summary fields (requirements/decisions/openQuestions/actionItems) are written by the summarization worker, readable via `GET /sources/:id/summary`.
- **Status stages**: queued → starting → transcribing → diarizing (paid only) → summarizing → done / failed
- **Design tokens**: charcoal + amber, Inter/Geist UI, JetBrains Mono for transcript text. Linear/Vercel/Raycast aesthetic. UI kit must be built before feature screens (D-012, D-007).
- **Deploy wires to**: WebStack SSM params `/heediq/web/cloudfront-distribution-id` (for cache invalidation) and `/heediq/web/url` (set as CORS origin in API).

---

## Deployment model (reference — all app repos)

- **heediq-shared**: semver publish on `main` merge. Renovate bumps consuming repos (D-048).
- **heediq-api / heediq-worker-summarization**: esbuild bundle → `aws lambda update-function-code` per env (GitHubActionsDeployRole). pnpm 11.
- **heediq-worker-transcription**: two Docker builds (free/paid) → ECR push (GitHubActionsECRRole in shared-services) → `ssm put-parameter` + `ecs register-task-definition` + `aws pipes update-pipe` per env (GitHubActionsDeployRole).
- **heediq-web**: Vite build → `aws s3 sync` + CloudFront invalidation per env (GitHubActionsDeployRole).
- All repos: feature → PR → develop (auto-deploy dev) → main (staging → manual gate → prod).

## Standing notes (carry forward)
- `heediq-infra` ACM cert CNAME validation must be manually added to Route 53 for staging/prod on first deploy (D-063).
- `scripts/setup.sh` sections 1–3 must run for staging/prod before first CDK deploy.
- `HF_TOKEN` GitHub secret must be set in `heediq-worker-transcription` before paid-tier image builds.
- `@heediq/shared` package access must be granted to any new consuming repo in GitHub org package settings.
