# MEMORY.md — Index

The lean index Claude reads first. Each entry points to a code README or a decision — it does not
duplicate their content. See `rules/08-memory.md` for the contract.

## How to use this file
- At task start, scan for the area you're touching, then open the pointed-to README(s) and decisions.
- After a task, add/correct pointers here for any new or changed module.

## Decisions
- Canonical locked decisions live in **`../business/DECISIONS.md`** (business memory). Reference
  decision IDs (e.g. D-007) from entries below; don't copy decision text here.

## Modules / Features (pointers)

- **RBAC & audit trail (D-102, supersedes D-017; D-105 supersedes D-102's staleness mechanism only;
  D-106 — permission key strings are append-only, never renamed in place; also D-104 —
  `heediq-auth-audit-log` to be dropped, no migration, once the auth write path cuts over)** —
  All 5 phases merged to `develop`, including Phase 5 (audit-log viewer — `GET /org/audit-log` in
  `heediq-api`, `/org/audit-log` page in `heediq-web`). Permission catalog
  (`heediq-shared/src/permissions.ts`) drives the API gate (`requirePermission`), the frontend `<Can>`
  gate, and i18n key interpolation from one constant — see `heediq-api/README.md` §"D-102 RBAC & audit
  trail" and its `GET /org/audit-log` entry. Dynamic per-org roles/groups/permissions + unified
  GxP-quality-bar audit trail. Full architecture: `../business/architecture.md` §"RBAC & Audit Trail"
  (still describes design as "not yet built" — intentionally left stale until the full feature is
  implemented, per Andrii). `auditWriter(c)` (`heediq-api/src/lib/audit.ts`) centralizes actor/org
  context (incl. `actorRole`) for every audit write; permission gating + audit trail is now a standing
  rule for all future mutating endpoints/actions, not just this feature (D-107). Decisions:
  `DECISIONS.md` D-102, D-104, D-105, D-106, D-107.

- **Account linking & auth (D-077–D-091, D-096, D-099), built end-to-end.** Own verify-then-password
  flow (Cognito `SignUp`/`ConfirmSignUp` confirmation-code reuse, not IdP-trust or custom OTP) backs
  signup, reactive login-time linking, and proactive Settings linking through one shared component.
  `heediq-user-auth-methods` is the source of truth for a user's active sign-in methods (`GET
  /auth/methods`). Identity is keyed by an app-owned `accountId` (D-099, not Cognito's `sub`), resolved
  deterministically via `heediq-cognito-identities` (`sub → accountId`) and carried end-to-end as the
  `custom:accountId` JWT claim — email is now only a fallback self-heal lookup, not the primary
  identity. Still open: `POST /settings/link/add-provider` (proactive linking's backend half). Full
  contracts/gotchas: `heediq-web/src/lib/auth/README.md`, `heediq-web/src/features/auth/README.md`,
  `heediq-api/README.md`, `heediq-infra/README.md`. Decision history: `DECISIONS.md` D-077–D-091, D-099.

- **heediq-infra** — CDK TypeScript project; all stacks for all accounts.
  README: `../../heediq-infra/README.md` · Decisions: D-036, D-037, D-038, D-044, D-045, D-051–D-068, D-077, D-083, D-085, D-087, D-090 (supersedes D-080), D-093, D-095, D-097, D-098, D-099, D-102, D-103
  - **ObservabilityStack** (`lib/observability/observability-stack.ts`, D-085) — per-env CloudWatch Dashboard built from static resource-name strings (no cross-stack construct refs, per D-037); ApiStack/SummarizationStack Lambdas run with X-Ray active tracing.
  - `lib/config.ts` `logRetentionFor(workloadEnv)` (D-093) — 30 days dev/staging, 90 days prod; applied to ApiStack/SummarizationStack/TranscriptionStack log groups so none default to CDK's "Never Expire".
  - **TranscriptionStack** — EC2 GPU Spot (g4dn.xlarge, D-059); ASG min=0; two Ec2TaskDefs (free/paid, D-060); models baked in image (D-062).
  - **FoundationStack** (`lib/foundation/`, split by concern per D-103 — see `lib/foundation/README.md`) — tables (sources, orgs, users, jobs w/ DDB Streams NEW_IMAGE, ws-connections w/ TTL + by-source GSI, user-auth-methods, auth-audit-log, cognito-identities pk=sub, D-099, plus RBAC/audit tables roles/groups/role-assignments/audit-log, D-102) + Cognito User Pool (custom:orgId/custom:role/custom:accountId, PreTokenGeneration + pre-signup/post-confirmation/post-authentication triggers) + ACM wildcard cert eu-west-1 (D-063) + SSM params.
  - **WebSocketStack** — WebSocket API + heediq-ws-connect + heediq-ws-status-pusher (DDB Streams trigger) + custom domain ws-{env}.heediq.com (D-064) + SSM params (D-061).
  - **ApiStack** — Lambda heediq-api (Node.js 22) + HTTP API + custom domain api-{env}.heediq.com + IAM grants (tables, S3, SQS transcription+summarization, SecretsManager, SES role).
  - **SummarizationStack** — SQS queue + DLQ + Lambda heediq-summarization + IAM (SecretsManager, DynamoDB jobs+sources, S3 read). Source-agnostic: audio (transcription worker) + direct path (API Lambda, text/PDF/email/Excel), D-065.
  - **WorkloadCfCertStack** — ACM wildcard cert (`*.heediq.com`) in us-east-1 per workload account; passed to WebStack via `crossRegionReferences: true` (D-053).
  - **WebStack** — CloudFront + S3 OAC + custom domain + security headers (HSTS/X-Frame/CSP) + SPA 403/404→/index.html (D-053, D-055). OAC bucket policy lives in FoundationStack (source-account condition) to avoid a circular CDK dependency.
  - **SharedServicesStack** — ECR, Route 53, SES+DKIM, cross-account IAM roles (heediq-ses-email-sending, heediq-route53-dns-manager, D-064).
  - Gotcha: any stack renamed/replaced while another stack imports it via a direct CDK prop (not SSM) needs a two-phase deploy — only `WebSocketStack.jobsTable` uses this pattern today. Full DR recovery steps (incl. out-of-band table recreation staling the export): `heediq-infra/README.md` Gotchas.

- **heediq-shared** — `@heediq/shared`: Zod schemas + TypeScript types for all cross-repo contracts.
  README: `../../heediq-shared/README.md` · Decisions: D-033, D-040, D-047, D-048, D-085, D-093, D-094, D-102
  - Schemas: enums, domain (Org/User/Source/Job/Summary), API requests, SQS messages (D-059/D-065), WS push (D-061), auth methods (D-091), account linking (D-078).
  - `src/passwordPolicy.ts` (0.7.0, D-094) — `PASSWORD_POLICY`/`PASSWORD_POLICY_RULES`/`isPasswordPolicyCompliant`, the single source of truth for Cognito's password rules (D-020), consumed by `heediq-api` and `heediq-web` only — `heediq-infra`'s CDK literal stays separate by design (checked via consistency check, not imported).
  - `src/logger.ts` (0.6.0, D-085/D-093) — `createLogger(service)` structured JSON logger, correlated by `sourceId`/`requestId`, recursive PII-redaction denylist, `LOG_LEVEL`-gated `debug`/`info`/`warn`/`error` threshold (default `info`).
  - Published to GitHub Packages; publish only fires on push to `main`, not `develop` — a `develop`→`main` PR is the release mechanism. New consuming repos need a manual read-access grant in GitHub Packages settings (see README).

- **heediq-api** — Hono Lambda: all REST endpoints under `/api/v1/`, JWT auth middleware, D-060 access control.
  README: `../../heediq-api/README.md` · Decisions: D-033, D-034, D-041, D-042, D-060, D-068, D-077, D-078, D-079, D-085, D-087, D-088, D-089, D-090, D-091, D-094, D-096, D-097, D-098, D-099, D-102
  - `auth-provision.ts` (PreTokenGeneration trigger body) resolves `accountId` via `heediq-cognito-identities` first (deterministic, D-099), falling back to email self-heal; first login generates a new decoupled `accountId` — no `email_verified` gate (D-090). `src/lib/accountIdentity.ts` is the shared resolution helper used by every auth handler/route.
  - `routes/auth-methods.ts` (`GET /auth/methods`, D-091); `routes/auth.ts`'s `request-otp`/`verify-otp`/`confirm` serve native signup, reactive linking, and Settings-linking alike (D-089), via Cognito `SignUp`/`ConfirmSignUp` reuse (D-087) — `verify-otp` confirms the code on its own before `confirm` ever sets a password, so the code is checked before the caller can proceed. A Cognito `InvalidPasswordException` on `AdminSetUserPassword` returns `WEAK_PASSWORD` (D-094) instead of the generic `BAD_REQUEST`.
  - `src/middleware/request-id.ts` (D-085) — per-request UUID correlation fallback for routes without a `sourceId` yet; logs via `@heediq/shared`'s `createLogger`.
  - The `/api/v1` prefix is centralized in exactly one place per side (this repo's `app.ts` route mounts; `heediq-web`'s `api-client.ts` `request()`) — don't hardcode it elsewhere (D-088 root cause).
  - Gotcha: transcription-queue `SendMessageCommand` must set `MessageAttributes: { tier }` — without it both EventBridge Pipe filters fail and no job is ever processed.

- **heediq-worker-transcription** — Python ECS worker: one RunTask = one job via SQS_MESSAGE_BODY container override (D-066). Two per-tier images (free/paid) with model weights baked in (D-062).
  README: `../../heediq-worker-transcription/README.md` · Decisions: D-037, D-038, D-047, D-059, D-062, D-065, D-066, D-068, D-085, D-093
  - Transcript written to `heediq-sources[sourceId].transcript` in DynamoDB (task role has no S3 write grant); summarization worker reads it by sourceId.
  - `src/models.py` is hand-maintained (mirrors `@heediq/shared`, not generated).
  - `src/logger.py` (D-085/D-093) — Python mirror of `@heediq/shared`'s `logger.ts` (`print()`-based JSON logging + PII denylist + `LOG_LEVEL`-gated threshold, default `info`); no X-Ray sidecar on this worker (one-shot batch task, correlation via `source_id` in logs instead).

- **heediq-worker-summarization** — Node.js Lambda: reads transcript from DynamoDB, extracts structured fields (requirements/decisions/openQuestions/actionItems) via Claude, writes back to DynamoDB.
  README: `../../heediq-worker-summarization/README.md` · Decisions: D-032, D-038, D-043, D-065, D-067, D-068, D-084, D-085, D-093
  - `sourceType='text'` → `contentRef` IS the sourceId (reads `heediq-sources[sourceId].transcript`), not an S3 key.

- **heediq-web** — Vite + React + TS PWA frontend; D-030 stack (TanStack Query, CVA, Radix, Vitest/RTL).
  README: `../../heediq-web/README.md` · Auth README: `src/lib/auth/README.md` · Features/auth README: `src/features/auth/README.md` · Layout README: `src/components/layout/README.md` · PasswordRequirements README: `src/components/ui/PasswordRequirements/README.md` · Decisions: D-008, D-020, D-024, D-028, D-029, D-030, D-043, D-072–D-076, D-077–D-079, D-081–D-083, D-087–D-091, D-094, D-097
  - `src/features/auth/VerifyAndSetPasswordForm.tsx` is the one shared own-verification + set-password component, reused by `HomePage` (signup/reactive-linking) and `SettingsPage` (D-091 active-methods list + inline "Set a password"). `cognito-idp.ts` no longer exports `signUp`/`confirmSignUp` — that round trip always goes through `heediq-api`. It also shows a live password-requirements checklist (`PasswordRequirements`, D-094) and disables submit until compliant, via `api-client.ts`'s `ApiClientError` distinguishing `WEAK_PASSWORD` from other failures.
  - Full i18n coverage via `react-i18next`, `src/i18n/` — all user-facing text goes through `t()` (D-075/D-076).
  - `HomePage` is the unified sign-in/sign-up entry (email-first; sign-up/sign-in/forgot-password/reactive-linking steps), calling Cognito directly via `lib/auth/cognito-idp.ts` (see auth README). `AuthCallbackPage` handles Hosted UI OAuth PKCE code exchange for SSO login.
  - Proactive account linking: `SettingsPage` (Add Google/Add Microsoft) + `SettingsLinkCallbackPage` (`/settings/link-callback`) — see auth README for why its tokens must never reach `applyTokens`.
  - `src/components/layout/` (`TopBar` + `AppShell`) mounted inside `ProtectedRoute` around `/sources`, `/sources/:sourceId`, `/settings`.
  - No client-side onboarding step — `custom:orgId`/`custom:role`/`custom:accountId` (D-099) arrive pre-baked in the token via `heediq-api`'s PreTokenGeneration trigger. `SourcesLibraryPage`/`SourceDetailPage` still placeholders per D-069 build order.
  - deploy.yml builds **per-environment** (not build-once-promote) — Vite inlines `VITE_*` env vars at build time, including Cognito domain/client-id/region read from SSM (D-082).

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN)
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

_(none currently — see `heediq-infra` entry above for the one cross-stack CDK gotcha)_

## In-progress (not yet doc-worthy)
_(Short notes on things being worked out; promote to a README or decisions doc when settled.)_

**Backlog — not yet planned, don't forget:**
- **Real-time WebSocket framework.** Every user connects on login; server pushes status/progress
  events to user/org/broadcast scopes for interactive "what's happening now" UI (job stage updates,
  etc.). `heediq-infra`'s `WebSocketStack` (ws-connections table + heediq-ws-status-pusher) already
  exists for job status push — this backlog item is about generalizing it into a small reusable
  framework (typed event/channel model) rather than one-off per-feature wiring. Needs a real plan
  (Step 1–2) when picked up.
- **Design precision.** Don't build features against an approximate/guessed design — get pixel-precise
  design references (Figma or similar) before building UI, so `03-ui-kit.md` components are built
  once, correctly, rather than re-styled later. No tooling/process decided yet.
- **Multitenancy feature flag control.** Need a way to enable/disable/config features per org/tenant
  (e.g. audit trail, RBAC) — possibly a new internal "tenants dashboard" repo for Heediq staff to
  manage per-org config. Not scoped or designed yet.
- **E2E & stress testing framework/approach.** `05-testing.md` locks the stack (Playwright for E2E,
  k6 for load) but there's no actual test infrastructure, coverage strategy, or CI wiring built yet —
  need an approach that scales to cover both current features and future ones with comprehensive
  automated coverage (critical journeys, load-sensitive surfaces like transcription throughput).
  Not scoped or designed yet.
