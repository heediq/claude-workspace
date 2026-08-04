# MEMORY.md — Index

The lean index Claude reads first. Each entry: feature/area -> one-line summary -> README path ->
decision IDs -> matching `feature_dependency_map.md` entry name. Nothing else — no progress
narrative, no PR links, no implementation detail. See `rules/08-memory.md` for the contract.

## How to use this file
- At task start, scan for the area you're touching, then open **only** the pointed-to README(s) and
  decisions for that area — not the whole file.
- After a task, add/correct a pointer here for any new or changed module. Status/progress narrative
  goes in the branch's `plans/wip-*.md` or the README's own "Status" line — never here.

## Decisions
- Canonical locked decisions live in **`../business/DECISIONS.md`** (business memory). Reference
  decision IDs (e.g. D-007) from entries below; never copy decision text here.
- Product feature backlog (postponed/not-yet-scoped feature ideas, distinct from the engineering
  backlog below): **`../business/BACKLOG.md`**.

## Modules / Features (pointers)

- **RBAC & audit trail** — dynamic per-org roles/groups/permissions gate every mutating
  endpoint/action, backed by a unified audit trail.
  README: `../../heediq-api/README.md` §"D-102 RBAC & audit trail" · Decisions: D-102, D-104, D-105,
  D-106, D-107, D-114 · Dependency map: `heediq-api (API Lambda)`

- **Account linking & auth** — own verify-then-password flow (Cognito SignUp/ConfirmSignUp reuse)
  backs signup, reactive login-time linking, and proactive Settings linking through one shared
  component; identity keyed by an app-owned `accountId`, decoupled from Cognito's `sub`.
  README: `../../heediq-web/src/lib/auth/README.md`, `../../heediq-api/README.md` · Decisions:
  D-077–D-091, D-096, D-099 · Dependency map: `Account linking (D-078–D-091, D-096–D-099)`

- **heediq-infra** — CDK TypeScript project; all stacks for all accounts (Foundation,
  Transcription, Summarization, WebSocket, Api, Web, Observability, SharedServices).
  README: `../../heediq-infra/README.md` · Decisions: D-036–D-038, D-044, D-045, D-051–D-068, D-077,
  D-083, D-085, D-087, D-090, D-093, D-095, D-097–D-099, D-102, D-103, D-108, D-112, D-135, D-136,
  D-138, D-141, D-142 · Dependency map: `Infrastructure (heediq-infra)`, `Transcription pipeline
  (TranscriptionStack)`, `Real-time WebSocket framework (WebSocketStack, D-061 generalized D-109)`,
  `Summarization pipeline (SummarizationStack)`, `Web frontend delivery (WorkloadCfCertStack +
  WebStack)`, `Observability (D-085, D-093)`

- **heediq-shared** — `@heediq/shared`: Zod schemas + TypeScript types for all cross-repo contracts
  (domain, API requests, SQS/WS messages, Context Library).
  README: `../../heediq-shared/README.md` · Decisions: D-033, D-040, D-047, D-048, D-085, D-093,
  D-094, D-102, D-127, D-129–D-131, D-133, D-135, D-136, D-139, D-141, D-142 · Dependency map:
  `@heediq/shared (heediq-shared)`

- **heediq-api** — Hono Lambda: all REST endpoints under `/api/v1/`, JWT auth middleware, Context
  Library API, account-linking/RBAC routes.
  README: `../../heediq-api/README.md` · Decisions: D-033, D-034, D-041, D-042, D-060, D-068,
  D-077–D-079, D-085, D-087–D-091, D-094, D-096–D-099, D-102, D-107, D-113, D-141, D-143, D-144 ·
  Dependency map: `heediq-api (API Lambda)`

- **heediq-worker-transcription** — Python ECS worker: one RunTask per job; two per-tier images
  (free/paid) with model weights baked in.
  README: `../../heediq-worker-transcription/README.md` · Decisions: D-037, D-038, D-047, D-059,
  D-062, D-065, D-066, D-068, D-085, D-093 · Dependency map: `heediq-worker-transcription`

- **heediq-worker-summarization** — Node.js Lambda: combined classify+extract Claude call producing
  a `gist` + per-statement `ExtractedItem`s filed into a Context.
  README: `../../heediq-worker-summarization/README.md` · Decisions: D-032, D-038, D-043, D-065,
  D-067, D-068, D-084, D-085, D-093, D-100, D-130, D-133, D-135, D-141 · Dependency map:
  `heediq-worker-summarization`

- **Decision Ledger** — per-Context curated roll-up of decisions/open-questions (D-136); entry status
  (confirmed/needs_review/open) derived from answer+confidence, never trusted from the model. Review-time
  async reconciliation merges kept items → `ledger_ready` (D-148, worker `heediq-ledger`); chat-time
  gating blocks sends when a Context has open/needs_review entries (`LEDGER_GATED` 409, override with
  `bypassLedgerGating`, D-149). Web: standing view + wizard step 3 + chat gate banner.
  READMEs: `../../heediq-ledger/README.md`, `../../heediq-api/README.md` (CRUD + gate),
  `../../heediq-web/src/features/ledger/README.md` · Decisions: D-136, D-137, D-148, D-149 ·
  Dependency map: `Decision Ledger (D-136/D-137/D-148/D-149)`

- **heediq-web** — Vite + React + TS PWA frontend; UI kit, auth flows, WS client, motion system,
  Context Library UI.
  README: `../../heediq-web/README.md` · sub-module READMEs: `src/lib/auth/`, `src/features/auth/`,
  `src/features/contexts/` (Library slice A), `src/features/sources/` (B; C review wizard =
  `src/routes/ReviewWizardPage.tsx`; Capture/ingest landing `/capture` = `src/routes/CapturePage.tsx`, all three D-026 methods:
  `TextIngestForm`/`useIngestText` (text), `AudioIngestForm`/`useUploadAudio` (audio: create → presign →
  XHR PUT w/ progress → `POST /:id/jobs {model:'small'}`), `RecordIngestForm`/`useMediaRecorder` (live
  mic → `audio/webm` Blob through the same `useUploadAudio`; `ListenButton` kit 3-state; D-119), D-150), `src/features/chat/`
  (D — streaming chat, lazy),
  `src/features/ledger/` (Decision Ledger — see its own entry), `src/components/layout/`, `src/lib/ws/`,
  `src/lib/pwa/`, `src/components/ui/{PasswordRequirements,Logo,IdentityProviderButton,FullPageLoading}/`
  · Decisions: D-008, D-020, D-024, D-028–D-030, D-043, D-072–D-076, D-077–D-079, D-081–D-083,
  D-087–D-091, D-094, D-097, D-110, D-116–D-123, D-124–D-144 · Dependency map:
  `heediq-web (PWA frontend)`, `Context Library (D-124–D-144)`

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN) · Dependency map: `<entry name>`
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

- Any CDK stack renamed/replaced while another stack imports it via a direct construct prop (not
  SSM) needs a two-phase deploy — see `heediq-infra/README.md` Gotchas.

## Engineering backlog (not yet planned)
_(Deferred technical work, not tied to a single feature. Promote to a README/decision once scoped.)_

- **TopBar usage/limit indicator (D-026)** — deferred from Capture (heediq-web#49 shipped record-only).
  Blocked: no free-tier limit constant; `usageLifetimeCount` is set to `0` at provisioning, never
  incremented (no live signal); D-018 free tier is a decay ratchet + **soft prompt, not a `used/limit` cap**
  — a meter needs a product decision + counter wiring (API), then builds off `GET /me`.
- **Design precision** — no Figma/pixel-precise reference process yet; UI kit components risk being
  built against guesses.
- **Multitenancy feature-flag control** — no per-org/tenant feature toggle mechanism.
- **E2E & stress testing framework** — stack locked (`05-testing.md`: Playwright, k6) but no test
  infrastructure/CI wiring built yet.
- **General API rate limiting** — D-097/D-098 cover OTP-endpoint abuse protection specifically;
  no general-purpose throttling exists for other routes yet.
- **Dependency vulnerability scanning** — Renovate (D-048) only auto-bumps `@heediq/shared`; no
  `npm audit`/`pip audit`/image-scanning CI gate in any repo.
- **Secrets rotation policy** — D-038 defines where secrets live, not how/when they rotate.
- **Alerting thresholds / on-call** — D-085 gives dashboards, nothing defines page/Slack/none.
- **Backup/DR restore drills** — retention defined (D-022), restore never tested.
- **Bundle-size budget enforcement** — `07-engineering-standards.md` §6 states the principle, no
  CI gate.
- **Offline recording + queued upload + Wake Lock** — part of D-024's PWA scope, deferred by D-119.
- **RBAC catalog-append backfill migration (D-146)** — no tooling yet; when a permission is appended
  to `@heediq/shared`'s `PERMISSIONS`, existing orgs' system roles must be backfilled. Currently a
  manual per-org PATCH (done for the dev admin org 2026-07-22). Needs a scripted migration.
- **E2E dev-smoke harness (D-147)** — first instance **committed**: `heediq-chat/tests/e2e/chat-smoke.mjs`
  (`pnpm run e2e:chat`), the Context-chat happy path (create Context → conversation → post →
  chat_delta/chat_complete over WS), green on dev 2026-07-23. Open: shared token-provisioning helper + CI
  wiring, and smokes for the other features.
- **Chat backend follow-ups (slice D UX limits)** — (1) **server-side turn cancel**: web Stop is
  client-side only (worker keeps generating + persists); needs a cancel path. (2) **no-duplicate
  regenerate/retry**: web Retry re-posts the last user message as a new turn (no regenerate endpoint).
  (3) **conversation rename / auto-title**: new chats get "New chat"; no rename/auto-title endpoint yet.
- **Staging/prod deploy prerequisites owed** — two out-of-band tasks done on **dev only**, still owed on
  staging + prod: (1) `heediq-infra/scripts/setup.sh` re-run for the dual-subject OIDC trust
  (heediq-infra#64) — required before any *new* repo (heediq-chat, heediq-ledger) can deploy to staging/prod;
  blocked on interactive `aws sso login`. (2) `/heediq/ledger/anthropic-api-key` provisioned per-account
  (D-038) — dev done, staging/prod owed when heediq-ledger deploys there.
- **Keyless Anthropic auth via WIF** — evaluate Workload Identity Federation (Anthropic Console; GA, SDK
  auto-detects 4 env vars, exchanges a workload JWT at `/v1/oauth/token`, auto-refreshes — no static
  key). Would retire the per-service `/heediq/<svc>/anthropic-api-key` secrets + rotation + the "new
  service forgot its secret" gap (all hit 2026-07-23). Needs AWS-Lambda→Anthropic federation feasibility
  verified first; touches heediq-chat + heediq-worker-summarization + infra + Console. Supersedes the
  per-service-secret choice for Claude keys.
- **Product analytics / user-journey instrumentation** — none yet. Before/at test start, instrument
  heediq-web + key backend events into a product-analytics tool (Amplitude a candidate, not locked) for
  funnels/activation/per-feature usage. Needs an event taxonomy + must respect D-093 (ids/metadata only,
  never transcript/message/PII). Vendor+scope = a decision when picked up.
- **Shared WS-push library** — the connections-table-query + API-Gateway-Management push logic is
  duplicated across `heediq-api` `wsPush.ts`, `heediq-chat`, and `heediq-ledger` (heediq-worker-summarization
  uses the DDB-stream `ws-pusher` variant). Extract one shared package (own repo/pkg — can't live in
  types-only `@heediq/shared`) so push semantics + the by-user/by-org/by-broadcast GSI access live once.
