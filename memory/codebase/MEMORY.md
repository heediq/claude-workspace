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
  `src/features/contexts/` (Library slice A), `src/features/sources/` (slice B ingest + Capture landing
  `/capture` = `src/routes/CapturePage.tsx`, all three D-026 methods — text, audio-file, live mic record;
  D-119/D-150 — mechanics in that README), `src/routes/ReviewWizardPage.tsx` (slice C review wizard),
  `src/features/chat/` (D — streaming chat, lazy), `src/features/ledger/` (Decision Ledger — see its own
  entry), `src/components/layout/`, `src/lib/ws/`, `src/lib/pwa/`, `src/components/ui/` (UI kit)
  · Decisions: D-008, D-020, D-024, D-028–D-030, D-043, D-072–D-076, D-077–D-079, D-081–D-083,
  D-087–D-091, D-094, D-097, D-110, D-116–D-123, D-124–D-144, D-152, D-153 · Dependency map:
  `heediq-web (PWA frontend)`, `Context Library (D-124–D-144)`
  · Mobile-first layout (D-152/D-153): `src/components/layout/` owns nav + page frame; tables reflow to cards below `sm`; no-overflow invariant guarded by Playwright (`e2e/`, `pnpm test:responsive`) — see its README.

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

_(One line per item: label — status + where the detail lives. Promote to a README/decision once scoped.)_

- **TopBar usage/limit indicator (D-026)** — deferred; blocked on a free-tier limit constant + `usageLifetimeCount` wiring (D-018 is a soft-decay ratchet, not a used/limit cap).
- **Design precision** — no Figma/pixel-precise reference process; kit components risk being built against guesses.
- **Multitenancy feature-flag control** — no per-org feature-toggle mechanism.
- **Product analytics broadening (D-154, client + server LIVE in dev, 2026-08-06)** — shared id-prop contract in `heediq-shared/src/analytics.ts` (`@heediq/shared@0.15.6`); client taxonomy (~38 events, org group via `setGroup`) in heediq-web. Server choke-point in heediq-api: `heediq-api/src/lib/analytics.ts` (fail-safe/latency-bounded Amplitude Node emit helper wrapping the shared `buildServerAnalyticsEvent`) emits `source_processing_completed` from `ws-pusher.ts` (terminal job status), `user_provisioned` from `auth-provision.ts` (first login), `login_completed` from `auth-trigger-post-authentication.ts`. Infra: `heediq-infra/lib/shared/analytics-env.ts` gates `AMPLITUDE_API_KEY` on `-c analytics=true`, resolving SSM `/heediq/analytics/amplitude-api-key` (shared neutral param — same key heediq-web bakes into `VITE_AMPLITUDE_API_KEY`, so client + server land in one Amplitude project) at deploy onto the 3 emitting Lambdas only. **All three merged to `develop` + deployed to dev with `-c analytics=true`; verified the key is set on the 3 emitters and absent on non-emitters.** Staging/prod stay opt-out (no flag, param not provisioned there). Owed: Amplitude-UI validation of the cross-service join; Phase D (E2E Tier 1) + Phase E not started. Tracked in `plans/wip-analytics-e2e-d154-d155.md`. Follow-ups: worker-side emission + session-id correlation. See D-154.
- **E2E & stress testing (D-155, decided/not built)** — two-tier E2E: Tier 1 new mocked-backend Playwright suite over all authed flows (`VITE_E2E` synthetic-JWT auth, schema-parsed fixtures, fake WS, Amplitude-capture asserts; `pnpm test:e2e`, CI-on-PR); Tier 2 = existing D-147 dev smokes. Responsive harness landed (D-153). k6 + CI wiring pending. See D-155.
- **E2E dev-smoke harness (D-147)** — smokes committed: `heediq-chat/chat-smoke.mjs`, `heediq-api/tests/e2e/full-loop-smoke.mjs`; open: shared token helper + CI wiring + audio-path smoke.
- **General API rate limiting** — D-097/D-098 cover OTP endpoints only; no general throttling.
- **Dependency vulnerability scanning** — no `npm/pip audit` or image-scan CI gate (Renovate D-048 only bumps `@heediq/shared`).
- **Secrets rotation policy** — D-038 defines where secrets live, not rotation.
- **Alerting thresholds / on-call** — D-085 dashboards only; no paging policy.
- **Backup/DR restore drills** — retention set (D-022), restore never tested.
- **Bundle-size budget enforcement** — `07-engineering-standards.md` §6 principle only, no CI gate.
- **Offline recording + queued upload + Wake Lock** — D-024 PWA scope, deferred by D-119.
- **RBAC catalog-append backfill migration (D-146)** — appending a permission needs system-role backfill; currently manual per-org PATCH, no tooling.
- **Chat backend follow-ups** — server-side turn cancel (web Stop is client-only), no-duplicate regenerate (Retry re-posts), conversation rename/auto-title endpoint. See `heediq-chat/README.md`.
- **Staging/prod deploy prereqs owed** — re-run `heediq-infra/scripts/setup.sh` for dual-subject OIDC + provision `/heediq/ledger/anthropic-api-key` per account (D-038).
- **Keyless Anthropic auth via WIF** — evaluate Workload Identity Federation to retire per-service `/heediq/<svc>/anthropic-api-key` secrets; needs Lambda→Anthropic federation feasibility first.
- **Shared WS-push library** — push logic duplicated across `heediq-api` `wsPush.ts` / `heediq-chat` / `heediq-ledger`; extract one shared package (own repo — can't live in types-only `@heediq/shared`).
