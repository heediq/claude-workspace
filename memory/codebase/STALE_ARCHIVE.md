# STALE_ARCHIVE.md — Removed Codebase Memory & README Content

Home for content trimmed from READMEs, `MEMORY.md`, or `feature_dependency_map.md` during a
consistency check (`rules/10-consistency-check.md`, size & staleness control section) — resolved
gotchas, condensed narration, superseded dependency entries. Moved here verbatim, never deleted, so
history stays recoverable.

**This file is intentionally excluded from normal context loads** — it is not part of the Step 0c /
session-start read set (`01-development-workflow.md`, `08-memory.md`) and is not re-read by future
consistency checks. Open it only when explicitly asked for removed/historical content. This mirrors
how `memory/business/DECISIONS_ARCHIVE.md` is handled for decisions.

## Format
```
## YYYY-MM-DD · <source file> · <reason removed>
<content, verbatim>
```

## Entries

## 2026-07-07 · heediq-worker-summarization/README.md · redundant gotcha, merged into an adjacent non-obvious entry during consistency check
- **Claude API key fetched at cold start** — any Secrets Manager error on init fails all warm invocations until the next cold start. Rotate secrets carefully.

(This restated the already-documented "fetched at cold start" fact from the Contracts section; the
genuinely non-obvious part — cold-start Secrets Manager errors poisoning all warm invocations — was
kept and reworded into the README's Gotchas section, tied to D-100's module-level caching mechanism.)

## 2026-07-16 · memory/business/DECISIONS.md (D-085) · stale PR/branch tracking, both repos confirmed merged during consistency check
Implemented across 5 repos. Merged to `develop`: `heediq-shared` (PR #13), `heediq-worker-transcription`
(PR #12, branch `feature/structured-logging-py`), `heediq-infra` (PR #41, branch
`feature/observability-stack`) — see D-093 for retention details. Still open on unmerged branch
`feature/structured-logging`: `heediq-api`, `heediq-worker-summarization`.

(The 10-consistency-check.md agents for both heediq-api and heediq-worker-summarization independently
confirmed `createLogger`/structured logging is fully wired in both repos with zero raw `console.log`
calls outside logger implementations — the "still open" branch reference was stale.)

## 2026-07-22 · memory/codebase/MEMORY.md · compressed to strict one-liner index format per Andrii's memory-redesign request (feature -> summary -> README -> decisions -> dependency-map entry, nothing else)

### "In-progress product work" section (full Context Library narrative, now just a pointer to the WIP file)
- **Context Library** (D-124–D-144, generalizes D-068/D-069; B2B **and** B2C per D-143; primary
  positioning is a contextual-memory platform, meetings one ingestion path, per D-144) — **build in
  progress**: §11 step 1 (shared contracts, v0.14.0), step 2 (infra — 6 DynamoDB tables incl. cross-org
  grants), and step 3 (ingest — combined classify+extract, D-130/D-133) all merged. `@heediq/shared`
  **0.15.0** (D-141/D-142 — Context `visibility`/`groupId`, `context:share` perm, grant schema) and
  **0.15.1** (request/audit schemas for the API step) both published. **Step 4b (API — `/contexts`
  CRUD + `POST /sources/:id/review`, [heediq-api#42](https://github.com/heediq/heediq-api/pull/42))
  and `heediq-infra` ApiStack IAM grants for the 6 tables
  ([heediq-infra#61](https://github.com/heediq/heediq-infra/pull/61)) both merged to `develop`.
  Step 4c-i (cross-org grant issuance/revoke routes + `canAccessContext` grant fallback) is
  **done and merged** (both `heediq-shared` and `heediq-api`). `@heediq/shared` **0.15.2 published**
  ([heediq-shared#44](https://github.com/heediq/heediq-shared/pull/44) merged to `develop`, release
  [heediq-shared#45](https://github.com/heediq/heediq-shared/pull/45) merged to `main`).
  [heediq-api#43](https://github.com/heediq/heediq-api/pull/43) merged to `develop` 2026-07-21.
  **All of Step 4 (4a/4b/4c-i) is now fully merged.** Next: pick Step 4c-ii (chat, api+infra) or
  Step 5 (web) — neither planned in detail yet, ask before starting.
  Deferred: transcription `models.py` Summary mirror → gist (D-135); WS-CD gap (pusher bundles not in
  api deploy.yml); group-scoped Contexts in the classifier.
  See WIP `../../plans/wip-context-library-shared-contracts.md` for full forward-deps.
  **Full spec: `../../plans/context-library-spec.md`** (data model, ingest flow, review
  wizard, chat, WS events, MVP/fast-follow/backlog scope, suggested build order). Locked: generalized
  scope + auto-first classification + chat output (D-124–126); Domain as predefined behavior-bearing
  type work/study/personal/other (D-127, D-131); one Context per Source (D-128); Container→Context
  rename (D-129); combined classify+extract in the summarization worker w/ confidence + `other`
  fallback (D-130); item-level `ExtractedItem` model (D-135, supersedes D-132's flat arrays);
  `classification_ready` WS event + review-gate state (D-133); nested Contexts in MVP (D-134);
  Context Decision Ledger — designed now, built fast-follow (D-136); interactive 3-step review wizard
  (D-137); multiple named conversations per Context (D-138); dedicated `heediq-chat` worker streaming
  tokens over WS (`chat_delta`/`chat_complete`) with prompt caching on the stable context block
  (D-139). No RAG at MVP — chat assembles kept `ExtractedItem`s (+ descendants) + ledger +
  full-source fallback at query time from DynamoDB. Context **visibility** personal/group/org,
  permission-gated sharing, `by-scope` GSI (D-141); regulated **cross-org grants** for any-user→
  any-user sharing, designed now / built fast-follow (D-142); Heediq serves **B2B and B2C**, personal
  user = single-member org (D-143). See also `../business/product.md` north-star and
  `../business/BACKLOG.md`.

### Module entry sub-bullet detail (RBAC & audit trail, Account linking, and per-repo implementation notes — durable facts here should already live in the pointed-to README; check before re-adding)

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
  rule for all future mutating endpoints/actions, not just this feature (D-107). `requirePermission`
  (`heediq-api/src/middleware/rbac.ts`) also writes a denial audit entry on every 403 (D-114), so the
  framework checks and records in one call.

- **Account linking & auth (D-077–D-091, D-096, D-099), built end-to-end.** Own verify-then-password
  flow (Cognito `SignUp`/`ConfirmSignUp` confirmation-code reuse, not IdP-trust or custom OTP) backs
  signup, reactive login-time linking, and proactive Settings linking through one shared component.
  `heediq-user-auth-methods` is the source of truth for a user's active sign-in methods (`GET
  /auth/methods`). Identity is keyed by an app-owned `accountId` (D-099, not Cognito's `sub`), resolved
  deterministically via `heediq-cognito-identities` (`sub → accountId`) and carried end-to-end as the
  `custom:accountId` JWT claim — email is now only a fallback self-heal lookup, not the primary
  identity. `POST /settings/link/add-provider` (proactive linking's backend half,
  `heediq-api/src/routes/settings.ts`) is now built.

- **heediq-infra** sub-bullets:
  - **Context Library tables** (`lib/foundation/context-library-tables.ts`, split per D-103; 6 tables, schema-only, no consumers yet) — `heediq-contexts` (PK=`contextId`, GSI `by-scope` PK=`scopeKey`(`U#`/`G#`/`O#`)/SK=`domainCreatedAt` for personal/group/org visibility grouped by Domain, D-141), `heediq-extracted-items` (PK=`sourceId`/SK=`itemId`, GSI `by-context` sparse, D-135), `heediq-decision-ledger` (PK=`contextId`/SK=`entryId`, D-136), `heediq-conversations` (GSI `by-context` SK=`updatedAt`, D-138), `heediq-chat-messages` (PK=`conversationId`/SK=`sk`=`ts#messageId`, D-138), `heediq-context-grants` (PK=`granteeUserId`/SK=`contextId`, GSI `by-context`, TTL `expiresAt` cleanup-only — the regulated cross-org sharing primitive, D-142). Names SSM-exported. Key-design + isolation gotchas: `heediq-infra/lib/foundation/README.md`.
  - **ObservabilityStack** (`lib/observability/observability-stack.ts`, D-085) — per-env CloudWatch Dashboard built from static resource-name strings (no cross-stack construct refs, per D-037); ApiStack/SummarizationStack Lambdas run with X-Ray active tracing.
  - `lib/config.ts` `logRetentionFor(workloadEnv)` (D-093) — 30 days dev/staging, 90 days prod; applied to ApiStack/SummarizationStack/TranscriptionStack log groups so none default to CDK's "Never Expire".
  - **TranscriptionStack** — EC2 GPU Spot (g4dn.xlarge, D-059); ASG min=0; two Ec2TaskDefs (free/paid, D-060); models baked in image (D-062).
  - **FoundationStack** (`lib/foundation/`, split by concern per D-103 — see `lib/foundation/README.md`) — tables (sources, orgs, users, jobs w/ DDB Streams NEW_IMAGE, ws-connections w/ TTL + by-user/by-org/by-broadcast GSIs (D-109), user-auth-methods, auth-audit-log, cognito-identities pk=sub, D-099, plus RBAC/audit tables roles/groups/role-assignments/audit-log, D-102) + Cognito User Pool (custom:orgId/custom:role/custom:accountId, PreTokenGeneration + pre-signup/post-confirmation/post-authentication triggers) + ACM wildcard cert eu-west-1 (D-063) + SSM params.
  - **WebSocketStack** — generalized real-time push framework (D-061, generalized D-109): WebSocket API + heediq-ws-connect + heediq-ws-status-pusher (DDB Streams trigger) + `grantPush()` IAM helper + custom domain ws-{env}.heediq.com (D-064) + SSM params.
  - **ApiStack** — Lambda heediq-api (Node.js 22) + HTTP API + custom domain api-{env}.heediq.com + IAM grants (tables, S3, SQS transcription+summarization, SecretsManager, SES role).
  - **SummarizationStack** — SQS queue + DLQ + Lambda heediq-summarization + IAM (SecretsManager, DynamoDB jobs+sources, S3 read). Source-agnostic: audio (transcription worker) + direct path (API Lambda, text/PDF/email/Excel), D-065.
  - **WorkloadCfCertStack** — ACM wildcard cert (`*.heediq.com`) in us-east-1 per workload account; passed to WebStack via `crossRegionReferences: true` (D-053).
  - **WebStack** — CloudFront + S3 OAC + custom domain + security headers (HSTS/X-Frame/CSP) + SPA 403/404→/index.html (D-053, D-055). OAC bucket policy lives in FoundationStack (source-account condition) to avoid a circular CDK dependency.
  - **SharedServicesStack** — ECR, Route 53, SES+DKIM, cross-account IAM roles (heediq-ses-email-sending, heediq-route53-dns-manager, D-064).
  - Gotcha: any stack renamed/replaced while another stack imports it via a direct CDK prop (not SSM) needs a two-phase deploy — only `WebSocketStack.jobsTable` uses this pattern today. Full DR recovery steps (incl. out-of-band table recreation staling the export): `heediq-infra/README.md` Gotchas.

- **heediq-shared** sub-bullets:
  - Schemas: enums, domain (Org/User/Source/Job/Summary), API requests, SQS messages (D-059/D-065), WS push (D-061), auth methods (D-091), account linking (D-078).
  - **Context Library contracts (v0.14.0–0.15.2, D-124–D-142):** `domains.ts` (`DOMAIN_PROFILES` behaviour catalog + `DOMAIN_FIT_CONFIDENCE_THRESHOLD`, slug-only fields/prompts for i18n), `context.ts` (`Context` self-nesting D-134 +`visibility`/`groupId` D-141, `ProposedClassification`, `ExtractedItem` D-135, `DecisionLedgerEntry` D-136 + `LEDGER_REVIEW_CONFIDENCE_THRESHOLD`, `ContextGrant` D-142); Source gains `contextId`/`classification`/`proposedClassification`; `Summary` shrunk to `transcript`+`gist` (breaking, D-135 supersedes D-132's flat arrays); `ws.ts` +`classification_ready`/`chat_delta`/`chat_complete`; 0.15.1 adds `CreateContextRequestSchema`/`UpdateContextRequestSchema`/`ReviewApprovalRequestSchema` + `AuditPayloadMap` `context`/`extractedItemReview` entries; **0.15.2** (published) fixes `ContextGrantSchema.expiresAt` to epoch number, adds `CreateContextGrantRequestSchema` + `AuditPayloadMap` `contextGrant` entry.
  - `src/passwordPolicy.ts` (0.7.0, D-094) — `PASSWORD_POLICY`/`PASSWORD_POLICY_RULES`/`isPasswordPolicyCompliant`, the single source of truth for Cognito's password rules (D-020), consumed by `heediq-api` and `heediq-web` only — `heediq-infra`'s CDK literal stays separate by design (checked via consistency check, not imported).
  - `src/logger.ts` (0.6.0, D-085/D-093) — `createLogger(service)` structured JSON logger, correlated by `sourceId`/`requestId`, recursive PII-redaction denylist, `LOG_LEVEL`-gated `debug`/`info`/`warn`/`error` threshold (default `info`).
  - Published to GitHub Packages; publish only fires on push to `main`, not `develop` — a `develop`→`main` PR is the release mechanism. New consuming repos need a manual read-access grant in GitHub Packages settings (see README).

- **heediq-api** sub-bullets:
  - **Context Library API (D-143/D-144, merged** [heediq-api#42](https://github.com/heediq/heediq-api/pull/42)
    **):** `src/routes/contexts.ts` (CRUD + tree over `heediq-contexts`, `by-scope` GSI visibility
    gate `canAccessContext` — personal/group/org) + `POST /sources/:id/review` on `sources.ts` (files
    kept `ExtractedItem`s into a Context). See `heediq-api/README.md` Contracts section.
  - **Cross-org grants (D-142, [heediq-api#43](https://github.com/heediq/heediq-api/pull/43) merged
    → `develop`, 2026-07-21):** `src/routes/context-grants.ts` (issue/revoke/list
    grants) + `canAccessContext`'s `minAccess` live-grant fallback. See WIP
    `../../plans/wip-context-library-shared-contracts.md` §4c-i.
  - `auth-provision.ts` (PreTokenGeneration trigger body) resolves `accountId` via `heediq-cognito-identities` first (deterministic, D-099), falling back to email self-heal; first login generates a new decoupled `accountId` — no `email_verified` gate (D-090). `src/lib/accountIdentity.ts` is the shared resolution helper used by every auth handler/route.
  - `routes/auth-methods.ts` (`GET /auth/methods`, D-091); `routes/auth.ts`'s `request-otp`/`verify-otp`/`confirm` serve native signup, reactive linking, and Settings-linking alike (D-089), via Cognito `SignUp`/`ConfirmSignUp` reuse (D-087) — `verify-otp` confirms the code on its own before `confirm` ever sets a password, so the code is checked before the caller can proceed. A Cognito `InvalidPasswordException` on `AdminSetUserPassword` returns `WEAK_PASSWORD` (D-094) instead of the generic `BAD_REQUEST`.
  - `src/middleware/request-id.ts` (D-085) — per-request UUID correlation fallback for routes without a `sourceId` yet; logs via `@heediq/shared`'s `createLogger`.
  - The `/api/v1` prefix is centralized in exactly one place per side (this repo's `app.ts` route mounts; `heediq-web`'s `api-client.ts` `request()`) — don't hardcode it elsewhere (D-088 root cause).
  - Gotcha: transcription-queue `SendMessageCommand` must set `MessageAttributes: { tier }` — without it both EventBridge Pipe filters fail and no job is ever processed.
  - DynamoDB Local integration test layer (D-030) — `tests/integration/`, real-table Vitest suite (not mocked), catches DynamoDB-syntax bugs mocked unit tests can't (found and fixed a reserved-keyword bug in `routes/audit-log.ts`). See `heediq-api/README.md` §Testing/§Gotchas. `scripts/integration/create-tables.ts` hand-mirrors `heediq-infra/lib/foundation/tables.ts` — drift-risk item in `10-consistency-check.md`.

- **heediq-worker-transcription** sub-bullets:
  - Transcript written to `heediq-sources[sourceId].transcript` in DynamoDB (task role has no S3 write grant); summarization worker reads it by sourceId.
  - `src/models.py` is hand-maintained (mirrors `@heediq/shared`, not generated).
  - `src/logger.py` (D-085/D-093) — Python mirror of `@heediq/shared`'s `logger.ts` (`print()`-based JSON logging + PII denylist + `LOG_LEVEL`-gated threshold, default `info`); no X-Ray sidecar on this worker (one-shot batch task, correlation via `source_id` in logs instead).

- **heediq-worker-summarization** sub-bullet: `sourceType='text'` → `contentRef` IS the sourceId (reads `heediq-sources[sourceId].transcript`), not an S3 key. Combined classify+extract Claude call (D-130) — one call → placement proposal (Domain + Context) + `gist` + per-statement `ExtractedItem`s in the chosen Domain's shape. Writes items to `heediq-extracted-items`, sets `gist`/`proposedClassification`/`classification='pending_review'` on the Source (which the api classification-pusher turns into `classification_ready`, D-133); reads candidate Contexts via `heediq-contexts` by-scope GSI (org+personal; group scope deferred).

- **heediq-web** sub-bullets:
  - App-wide double-submit guard: `src/lib/useAsyncAction.ts` (ref-guarded `run()` + `pending` state) is
    now the standard way any button/form submit prevents a rapid double-click from firing its handler
    twice — codified as a general rule (not per-button opt-in) in `04-loading-and-feedback.md` §4.
    Paired with an explicit `transition-[...]` property list (not bare `transition-colors`, which
    misses `box-shadow`/`opacity`) on `Button`/`Input` so focus/error/disabled visual states animate.
    Its `pending` output is debounced through `src/lib/usePerceivedLoading.ts` (150ms delay/500ms
    minimum, D-122) so a sub-150ms action never flashes a spinner; the double-submit guard itself
    (`pendingRef`) is synchronous and unaffected. Page-level loads use the same hook at 600ms minimum
    via the shared `FullPageLoading` kit component (`ProtectedRoute`, `HomePage`, `AuthCallbackPage`,
    `SettingsLinkCallbackPage`).
  - `startLogin`/`startProviderLink` (`src/lib/auth/cognito-oauth.ts`) send `prompt=select_account`
    whenever a `provider` is given, forcing the IdP's own account chooser instead of silently reusing
    a cached browser session. `HomePage` resets a stuck SSO-button loading state on a bfcache
    `pageshow` restore (cancelling the IdP picker returns via bfcache, not a fresh load) — see auth
    README Gotchas.
  - `Logo` (`src/components/ui/Logo/`) — brand mark shown next to the "heediq" wordmark on `HomePage`
    and `TopBar`; sizes `sm`/`md`/`lg`.
  - Installable PWA baseline built (D-119): `vite-plugin-pwa` (manifest + service worker, app-shell-only precache — no runtime caching for API calls), `public/icons/` favicon set, `src/lib/pwa/useInstallPrompt.ts` hook + Settings "Install app" card. Offline recording/queued-upload/Wake-Lock remain backlog.
  - Shared motion system (D-117): `src/lib/motion.ts` centralizes Framer Motion variants/tokens — any mount/unmount, page-transition, or appear/disappear animation must reuse a variant from here (never a bespoke inline `motion.div`), per `03-ui-kit.md` §1b.
  - `LoadingMark` (D-116, supersedes D-074's animation only) — waveform pulse (4 bars scaling height, staggered phase) replacing the old rotation animation; component contract/props unchanged.
  - Separate branded Google/Microsoft `IdentityProviderButton`s on `HomePage` (D-118), each going direct-to-provider via Cognito's `identity_provider` query param (`startLogin(provider)` in `src/lib/auth/cognito-oauth.ts`) instead of Cognito's generic IdP picker.
  - `src/lib/ws/` — `WsProvider` (connection lifecycle, reconnect backoff, parses `@heediq/shared`'s `WsEventEnvelopeSchema`) + `useWsEvent(type, handler)` (typed per-feature subscription; no central dispatcher, D-110). No feature wires a handler yet — `SourcesLibraryPage`/`SourceDetailPage` are still stubs.
  - `src/features/auth/VerifyAndSetPasswordForm.tsx` is the one shared own-verification + set-password component, reused by `HomePage` (signup/reactive-linking) and `SettingsPage` (D-091 active-methods list + inline "Set a password"). `cognito-idp.ts` no longer exports `signUp`/`confirmSignUp` — that round trip always goes through `heediq-api`. It also shows a live password-requirements checklist (`PasswordRequirements`, D-094) and disables submit until compliant, via `api-client.ts`'s `ApiClientError` distinguishing `WEAK_PASSWORD` from other failures.
  - Full i18n coverage via `react-i18next`, `src/i18n/` — all user-facing text goes through `t()` (D-075/D-076).
  - `HomePage` is the unified sign-in/sign-up entry (email-first; sign-up/sign-in/forgot-password/reactive-linking steps), calling Cognito directly via `lib/auth/cognito-idp.ts` (see auth README). `AuthCallbackPage` handles Hosted UI OAuth PKCE code exchange for SSO login.
  - Proactive account linking: `SettingsPage` (Add Google/Add Microsoft) + `SettingsLinkCallbackPage` (`/settings/link-callback`) — see auth README for why its tokens must never reach `applyTokens`.
  - `src/components/layout/` (`TopBar` + `AppShell`) mounted inside `ProtectedRoute` around `/sources`, `/sources/:sourceId`, `/settings`.
  - No client-side onboarding step — `custom:orgId`/`custom:role`/`custom:accountId` (D-099) arrive pre-baked in the token via `heediq-api`'s PreTokenGeneration trigger. `SourcesLibraryPage`/`SourceDetailPage` still placeholders per D-069 build order.
  - deploy.yml builds **per-environment** (not build-once-promote) — Vite inlines `VITE_*` env vars at build time, including Cognito domain/client-id/region read from SSM (D-082).

### Backlog item corrected (was stale — general API throttling claim conflated with OTP-specific work)
Old wording: "**Rate limiting / abuse protection.** No throttling at the Hono/API-Gateway layer yet.
Worth deciding before public signup traffic. Not scoped or designed yet." — D-097/D-098 landed
layered abuse protection (API Gateway stage throttling + WAF rate rule scaffold + DynamoDB
email+IP limiter) scoped to the OTP endpoints specifically; the backlog entry now reflects that
general (non-OTP) route throttling is what remains open.

## 2026-07-22 · memory/codebase/feature_dependency_map.md · compressed to pure name-only graph per Andrii's memory-redesign request (upstream/downstream/shared-surface NAMES only, no key schemas/field-level detail — full detail was living here, duplicating the code READMEs)

Full original entries (schema-level detail, exact GSI/key designs, message-shape field lists, SSM
param names, etc.) — preserved verbatim below. This detail should already live in (or be added to)
the relevant module's README per `06-documentation.md`; this archive exists so nothing already
written is lost, not because the detail is meant to come back into the dependency map.

### Infrastructure (heediq-infra)
- **Upstream**: AWS accounts (D-045), locked decisions on naming/sizing/DNS/SES (D-037, D-038, D-051–D-058)
- **Downstream**: all app repos — they deploy code on top of infra resources; all SSM params from FoundationStack must exist before app deploys succeed; `GitHubActionsECRRole` in shared-services account is used by all app repos to push Docker images
- **Shared surfaces**:
  - `lib/config.ts` — account IDs, regions, domains, compute sizing; any change ripples to all stacks
  - `scripts/setup-aws-profiles.sh` — configures AWS SSO profiles for all 4 accounts; owner-only, run once per new machine
  - `scripts/setup.sh` — one-time AWS setup (CDK bootstrap + OIDC providers + IAM roles); upstream for all repos' CI. Must be re-run if org is renamed or trust policy drifts.
  - `scripts/setup-budgets.sh` — creates AWS Budgets via management account
  - FoundationStack UserPool — owns the Cognito PreTokenGeneration trigger wiring (custom attributes `custom:orgId`/`custom:role`/`custom:accountId` + Lambda association, D-077/D-099) plus the `heediq-cognito-identities` table (D-099); the trigger's real handler code is a `heediq-api`-owned artifact deployed by that repo's CI, same cross-repo split as the WebSocket Connection Lambda below

### Transcription pipeline (TranscriptionStack)
- **Upstream**: FoundationStack (SQS `heediq-transcription`, S3 `heediq-audio-uploads-*`, DynamoDB `heediq-jobs` + `heediq-sources`); SharedServicesStack (ECR repo `heediq-worker-transcription`); per-env SSM params `/heediq/transcription/{free,paid}-image-tag` (written by CI, read by CloudFormation at deploy time)
- **Downstream**: `heediq-worker-transcription` (two per-tier images, D-062; deployed by that repo's CI via register-task-definition + pipes update-pipe); SummarizationStack (indirectly triggered after worker enqueues to heediq-summarization); WebSocket status push via Status Pusher Lambda + DDB Streams on `heediq-jobs` (D-061)
- **Shared surfaces**: `heediq-jobs` table (written by EC2 GPU task, read by Status Pusher Lambda + API); `heediq-sources` table (written by EC2 GPU task with transcript text); ECR repo (shared pull path per D-045)

### Real-time WebSocket framework (WebSocketStack, D-061 generalized D-109)
- **Upstream**: FoundationStack (heediq-jobs DDB Streams stream ARN; heediq-ws-connections table w/ by-user/by-org/by-broadcast GSIs; wildcardCert — ACM wildcard cert eu-west-1, D-063); Cognito (JWKS for JWT validation in Connection Lambda); `@heediq/shared`'s `ws.ts` (`WsScopeSchema`, `WsEventPayloadMap`, `buildWsEvent()` — the cross-repo contract)
- **Downstream**: heediq-web (connects via wss://ws-{env}.heediq.com; receives push events); heediq-api (ws-connect.ts/ws-pusher.ts/wsPush.ts code deployed by heediq-api CI per D-050); any future feature that calls `wsPush.ts`'s `pushToUser`/`pushToOrg`/`pushBroadcast` directly (no DDB Streams round trip required)
- **Shared surfaces**: heediq-ws-connections table (written by ws-connect.ts, read by wsPush.ts via GSI); heediq-jobs DDB Streams (read-only by ws-pusher.ts); `WebSocketStack.grantPush()` — IAM helper any Lambda in any stack can call to get push rights; SSM /heediq/api/ws-endpoint-url + /ws-management-endpoint (read by heediq-web and heediq-api)
- **Known gap**: `wsPush`/`ws-connect`/`ws-pusher` are unit-tested only (mocked `dynamo.send`), not against a real table. DynamoDB Local integration scaffolding now exists in `heediq-api` (D-030, see `heediq-api/README.md` Testing section) but isn't yet extended to these WS handlers.

### Summarization pipeline (SummarizationStack)
- **Upstream**: FoundationStack (heediq-jobs + heediq-sources DynamoDB tables; heediq-audio-uploads S3 bucket); SummarizationStack (heediq-summarization SQS queue — created here, consumed by Lambda event source)
- **Downstream**: `heediq-worker-summarization` (Node Lambda — placeholder in stack; real implementation deployed by that repo's CI, D-043); `heediq-api` (reads structured output from heediq-sources); `heediq-web` (displays extraction results)
- **Shared surfaces**:
  - `heediq-summarization` SQS queue — written by TranscriptionStack EC2 task role (audio path, live); ApiStack Lambda is wired with `SUMMARIZATION_QUEUE_URL` in its env (`config.ts`) for the direct non-audio path (D-065, D-026) but has no call site sending to it yet — `sources.ts` doesn't enqueue there, so this producer is not yet implemented, only provisioned. Consumed by summarization Lambda. Message schema: `SummarizationJobMessage { jobId, sourceId, orgId, sourceType, contentRef, tier }` — `tier` is required and forwarded by all producers so the summarization Lambda can select the correct Claude model (D-067)
  - `heediq-jobs` table — written by summarization Lambda (status: `summarizing → done/failed`); also written by transcription worker + read by Status Pusher Lambda
  - `heediq-sources` table — written by summarization Lambda (now `gist` + `classification='pending_review'` + `proposedClassification`, REMOVEs the old flat arrays, D-130/D-135); also written by transcription worker + read by ApiStack Lambda. **NEW_IMAGE stream → `heediq-ws-classification-pusher`** (heediq-api handler) emits `classification_ready` at org scope when a Source enters `pending_review` (D-133) — same stream→pusher pattern as heediq-jobs/job_status
  - `heediq-contexts` table — **read** by summarization Lambda via the `by-scope` GSI (`O#org`+`U#user`) to classify against the uploader's Contexts (D-130/D-141); written by heediq-api (Context CRUD, step 4)
  - `heediq-extracted-items` table — **written** by summarization Lambda (per-statement `ExtractedItem`s, `status:'proposed'`, no contextId until approval, D-135); read by heediq-api (review wizard / chat memory, steps 4–5)
  - `heediq-audio-uploads-*` S3 bucket — read by summarization Lambda (transcript + direct-path content files); also written by API (presigned URL upload)

### Web frontend delivery (WorkloadCfCertStack + WebStack)
- **Upstream**: FoundationStack (heediq-web-assets-{accountId} S3 bucket — OAC bucket policy grant added there; wildcardCert not used here); WorkloadCfCertStack (us-east-1 ACM cert via crossRegionReferences prop, D-053); SharedServicesStack (heediq-route53-dns-manager role for Route53AliasRecord D-064); `lib/config.ts → DOMAINS` (web domain per env)
- **Downstream**: heediq-web (React SPA — served from CloudFront; CI does S3 sync + `aws cloudfront create-invalidation` using `/heediq/web/cloudfront-distribution-id` SSM param); heediq-api (reads `/heediq/web/url` SSM param for CORS origin)
- **Shared surfaces**:
  - `heediq-web-assets-{accountId}` S3 bucket — written by heediq-web CI; served by CloudFront via OAC (source-account policy in FoundationStack)
  - `/heediq/web/url` SSM param — consumed by heediq-web (runtime config). NOT read by heediq-api —
    API Gateway CORS is a compile-time constant (`DOMAINS.web[env]`) baked into `api-stack.ts`'s
    `corsConfiguration`; `heediq-api`'s own `CORS_ORIGINS` env var is never set by the CDK stack, so
    the app-level CORS array in `app.ts` is always empty (flagged in the 2026-07-16 consistency check
    as an undocumented dead/misconfigured code path — Andrii to decide whether to wire it or remove it)
  - `/heediq/web/cloudfront-distribution-id` SSM param — consumed by heediq-web CI for cache invalidation
  - **Key CDK constraint**: OAC bucket policy must live in FoundationStack (source-account condition), not WebStack — avoids circular cross-stack reference. `s3.Bucket.fromBucketName()` in WebStack prevents CDK from adding a second bucket policy.

### @heediq/shared (heediq-shared)
- **Upstream**: nothing — this is the lowest-level package, no runtime dependencies beyond zod
- **Downstream**: `heediq-api` (Zod parse at every API boundary), `heediq-web` (request/response types, WS message types), `heediq-worker-summarization` (SQS message schema + summary domain types)
- **Shared surfaces**: all Zod schemas in `src/` — a breaking change here requires a version bump and coordinated update in all consuming repos (D-047/D-048)

### heediq-api (API Lambda)
- **Upstream**: `heediq-infra` ApiStack (Lambda must exist before code can be deployed, D-050); `@heediq/shared` (types + validation); Cognito User Pool (JWKS endpoint); DynamoDB tables (sources, orgs, users, jobs, ws-connections, roles, groups, role-assignments, audit-log, D-102); S3 audio bucket; SQS transcription + summarization queues
- **Downstream**: `heediq-web` (REST API consumer); `heediq-worker-transcription` (reads SQS transcription queue messages enqueued here); `heediq-worker-summarization` (reads SQS summarization queue for direct-path uploads, D-065)
- **Shared surfaces**: `heediq-sources` table (written by API on create; read by API on get/list; also written by summarization worker on completion); `heediq-jobs` table (written by API on enqueue; read by Status Pusher Lambda); SQS queue URLs (SSM params consumed by API env vars); `src/handlers/auth-provision.ts` (D-077, resolves `accountId` via `heediq-cognito-identities` first, falling back to email self-heal, D-099) — the Cognito PreTokenGeneration trigger handler; code owned and deployed by heediq-api CI as a second Lambda but *wired as a trigger* by `heediq-infra` FoundationStack; stamps `custom:orgId`/`custom:role`/`custom:accountId` claims onto the ID token — a contract shared with `heediq-web`'s auth flow; `src/lib/accountIdentity.ts` (D-099) — shared `sub → accountId` resolution/linking helper used by every auth handler/route; `src/routes/auth-methods.ts` (D-091) — `GET /auth/methods`, a new shared surface read by `heediq-web`'s `SettingsPage`; `src/routes/roles.ts`/`groups.ts`/`role-assignments.ts` + `src/lib/audit.ts` (D-102, all 5 phases merged) — CRUD on `heediq-roles`/`heediq-groups`/`heediq-role-assignments`, writes on `heediq-audit-log` via `auditWriter(c)` (D-107, wraps `writeAuditEvent()`), plus `src/routes/audit-log.ts`'s `GET /org/audit-log` read path (Phase 5); all gated by `requirePermission()` (D-105, pure in-token check, no DynamoDB read per request) — the legacy `requireAdmin()`/D-017 role check is fully retired

### heediq-worker-transcription
- **Upstream**: `heediq-infra` TranscriptionStack (EventBridge Pipes + ECS cluster + EC2 GPU Spot ASG + task defs + IAM grants, D-059); `heediq-infra` SharedServicesStack (ECR repo `heediq-worker-transcription`); `heediq-api` (must set `tier` SQS message attribute on enqueue — without it both Pipe filters fail silently); S3 audio bucket (read-only); DynamoDB `heediq-jobs` + `heediq-sources`; SQS `heediq-transcription` (re-enqueue on SIGTERM, D-066) + `heediq-summarization` (enqueues on completion, D-065)
- **Downstream**: `heediq-worker-summarization` (reads `heediq-sources[sourceId].transcript` from DynamoDB — NOT from S3; enqueued with `sourceType: 'text', contentRef: sourceId`); `heediq-web` (status push via DDB Streams → Status Pusher Lambda → WebSocket, D-061)
- **Shared surfaces**: `heediq-jobs` table (status writes: `starting → transcribing → diarizing → summarizing → done/failed/retrying`); `heediq-sources` table (writes `transcript` text field — consumed by summarization worker); DDB Streams on `heediq-jobs` (D-061)

### heediq-worker-summarization
- **Upstream**: `heediq-infra` SummarizationStack (Lambda + SQS event source must exist, D-065); `@heediq/shared` (SummarizationJobMessage schema); DynamoDB `heediq-jobs` + `heediq-sources` (reads `transcript` from sources table by `sourceId` when `sourceType='text'`); S3 audio bucket (reads direct-upload content when `sourceType != 'text'`); Secrets Manager (Claude API key)
- **Downstream**: `heediq-api` (reads structured extraction from `heediq-sources`); `heediq-web` (displays summary output)
- **Shared surfaces**: `heediq-sources` table (writes structured extraction: requirements, decisions, openQuestions, actionItems); `heediq-jobs` table (writes `status=done/failed` on completion); SQS `heediq-summarization` queue (shared entry point for audio + direct-upload paths, D-065)

### heediq-web (PWA frontend)
- **Upstream**: `heediq-infra` WebStack (CloudFront + S3 bucket must exist before deploy); `heediq-api` (all REST endpoints); WebSocket API (`ws-{env}.heediq.com`, D-061, generalized D-109 — connected to via `src/lib/ws/WsProvider.tsx`, D-110); `@heediq/shared` (request/response types, WS message types); Cognito Hosted UI (auth via OAuth 2.0 Authorization Code + PKCE, D-020, D-077); Cognito unauthenticated IdP JSON API (client-direct SignUp/InitiateAuth/ForgotPassword, D-082)
- **Downstream**: nothing — leaf consumer
- **Shared surfaces**: `/heediq/web/url` SSM param (consumed by `heediq-api` for CORS origin config); `/heediq/web/cloudfront-distribution-id` SSM param (consumed by web CI for cache invalidation); S3 `heediq-web-assets` bucket (written by web CI, served by CloudFront via OAC); `/heediq/api/cognito-hosted-ui-domain` + `/heediq/api/cognito-client-id` SSM params (written by `heediq-infra` FoundationStack, consumed by web CI to inject `VITE_COGNITO_DOMAIN`/`VITE_COGNITO_CLIENT_ID` at build time, D-077); the `custom:orgId`/`custom:role`/`custom:accountId` ID token claims contract — stamped by `heediq-api`'s auth-provision Lambda (D-077/D-099), consumed by heediq-web's AuthContext — a rename on either side breaks auth silently; `src/lib/ws/WsProvider.tsx`'s `useWsEvent(type, handler)` (D-110) — the only integration point any future feature (`SourcesLibraryPage`/`SourceDetailPage`) uses to react to a pushed `@heediq/shared` `WsEventPayloadMap` event; adding a new event type there is what makes it available here; `src/lib/motion.ts` (D-117) — the one place Framer Motion variants/tokens are defined; any new mount/unmount or page-transition animation across the app reuses a variant from here (enforced by `03-ui-kit.md` §1b), so changing a variant's timing/easing ripples to every consumer (`Modal`, `Toast`, `HomePage` step transitions, route transitions); `vite-plugin-pwa` manifest/service-worker config in `vite.config.ts` (D-119) — the service worker's `globPatterns` intentionally excludes API responses from precache, so adding a new static asset type there is the only safe way to extend offline coverage without accidentally caching per-org data

### Account linking (D-078–D-091, D-096–D-099)
- **Upstream**: `heediq-infra` FoundationStack (`by-email` GSI on `heediq-users` — fallback self-heal only, D-099; `heediq-cognito-identities` table, pk=`sub`, deterministic `sub → accountId` map, D-099; `heediq-user-auth-methods`/`heediq-auth-audit-log`/**`heediq-rate-limits`** tables; 3 Cognito triggers — pre-signup/post-confirmation/post-authentication; `custom:accountId` Cognito attribute, D-099; Cognito App Client `callbackUrls` incl. `/settings/link-callback`, D-083; ApiStack throttling + gated WAF scaffold, D-097/D-098); `heediq-api` (`POST /auth/lookup-email`, `POST /auth/link/request-otp`, `POST /auth/link/verify-otp`, `POST /auth/link/confirm` — generalized under D-089 to also serve native signup and Settings-linking, not just reactive linking, and split so the code is verified (`verify-otp`) before any password is collected (`confirm`); `GET /auth/methods`, D-091); Cognito unauthenticated IdP JSON API + Hosted UI OAuth (D-082, D-083)
- **Downstream**: nothing yet — leaf feature within heediq-web; `POST /settings/link/add-provider` (proactive linking's backend half) will reuse the same `heediq-api` `lib/cognito.ts` helpers once built
- **Shared surfaces**:
  - `passwordSet` flag on `heediq-users` (DynamoDB) — set by `heediq-api` provisioning, read by `/auth/lookup-email` to branch `HomePage`'s sign-in vs. shared verify-and-set-password step (D-089); flipped `true` by `recordAuthMethodAndAudit` in `routes/auth.ts` once `link/confirm` succeeds (only reachable after `link/verify-otp` has already confirmed the code)
  - `identities` Cognito ID-token claim — produced by Cognito on any federated sign-in, consumed by `heediq-web`'s `SettingsLinkCallbackPage` to get the provider's `{userId, providerName}` (see `heediq-web/src/lib/auth/README.md`); also parsed server-side in the 3 Cognito trigger handlers via `getProviderContext()`
  - `/settings/link-callback` Cognito callback URL — registered in `heediq-infra` FoundationStack (D-083); breaks the proactive-linking OAuth round trip if removed or renamed on either side
  - `heediq-user-auth-methods`/`heediq-auth-audit-log` (D-087) — written by both `heediq-api`'s `/auth/link/*` routes and its 3 Cognito trigger Lambdas; `pk = USER#<accountId>` ties both tables to the canonical `accountId`, now resolved deterministically via `heediq-cognito-identities` first (D-099), `by-email` only as fallback self-heal; now also the read source of truth for `GET /auth/methods` (D-091), scoped to the caller's own `userId`
  - `heediq-web/src/features/auth/VerifyAndSetPasswordForm.tsx` (D-089) — the shared two-step own-verification component; a new shared surface consumed by both `HomePage.tsx` and `SettingsPage.tsx`, so a change here retests both entry points
  - `heediq-cognito-identities`-first resolution (D-099, via `src/lib/accountIdentity.ts`'s `resolveAccountIdBySub`/`resolveAccountIdByEmail`/`linkIdentity`) — a post-linking re-login presents the destination/native user's `sub`, not the original federated `sub`; every handler/route resolves `sub → accountId` through this table before ever falling back to the `by-email` GSI, and any email-based resolution immediately pins a new `sub → accountId` row so future logins skip the guess entirely
  - **Still open**: `POST /settings/link/add-provider` (proactive linking's backend call) — not yet built
  - `heediq-api`'s `handleExistingNativeUser` in `routes/auth.ts` (D-096) — `request-otp`'s `AdminDeleteUser` self-heal for a native user stuck `CONFIRMED` with `passwordSet: false` (abandoned between `verify-otp` and `confirm`); reads the same `passwordSet` flag above to decide, so a change to how/when that flag is set must be checked against this heal condition too
  - `heediq-api`'s `checkRateLimit` (`src/lib/rateLimit.ts`, D-097) — app-level email+IP throttle wrapping `request-otp`/`verify-otp`, reusing D-078's `RATE_LIMITED` non-disclosure shape; backed by `heediq-infra`'s `heediq-rate-limits` table and layered under API Gateway stage throttling (all envs) and a WAF rate-based rule scaffolded but disabled everywhere until a marketing campaign is planned (D-098); `heediq-web`'s `VerifyAndSetPasswordForm.tsx` branches on the `RATE_LIMITED` error code from both calls (dedicated error state on `request-otp`, inline message on `verify-otp`)

### Context Library (D-124–D-144) — build in progress (§11 of `plans/context-library-spec.md`)
- **Upstream**: `@heediq/shared` Context Library contracts (**landed**, v0.14.0–0.15.2: `Domain`/`DOMAIN_PROFILES`, `Context`/`ExtractedItem`/`DecisionLedgerEntry`/`ProposedClassification`, `ContextGrant`, request schemas for the API step, Source review fields, `classification_ready`/`chat_delta`/`chat_complete` WS events; 0.15.2 published to GitHub Packages). **Infra tables landed** (step 2): `heediq-contexts` (+ `by-scope` GSI, D-141), `heediq-extracted-items`, `heediq-decision-ledger`, `heediq-conversations`, `heediq-chat-messages`, `heediq-context-grants` (cross-org sharing, D-142). **`heediq-api` `/contexts` CRUD + review-approval route landed** (step 4b, [heediq-api#42](https://github.com/heediq/heediq-api/pull/42) merged to `develop`). **Infra ApiStack IAM grants for the 6 tables landed** ([heediq-infra#61](https://github.com/heediq/heediq-infra/pull/61) merged to `develop`).
- **Downstream**: `heediq-worker-summarization` (writes `ExtractedItem`s + `gist`, runs the combined classify+extract call, D-130/D-135 — done); `heediq-api` (`/contexts` CRUD + `/sources/:id/review` — done, merged; `/context-grants` issuance/revoke — built on `feature/context-library-grants`, [heediq-api#43](https://github.com/heediq/heediq-api/pull/43) open → `develop`, CI green, awaiting review); `heediq-web` (Source/Summary/WS types, review wizard, Context chat — not started); `heediq-worker-transcription` `models.py` (hand-mirrored Summary shape — still has old flat-array shape, deferred).
- **Shared surfaces**: `Summary` schema — **breaking shrink** to `transcript`+`gist` (D-135 supersedes D-132); the four flat extraction arrays are gone, replaced by item-level `ExtractedItem`. `Source` gains `contextId`/`classification`/`proposedClassification` (non-key attrs, no infra change). `DOMAIN_PROFILES` `extractionFields`/`starterPrompts` are slug IDs consumed by both the summarization worker (extraction shape) and `heediq-web` (t()-mapped labels). New WS events flow through `wsPush.ts` (D-109) and `useWsEvent` (D-110). Infra `create-tables.ts` mirror (D-030 drift risk) now carries the 6 Context Library tables. Cross-org grants (D-142) are a regulated exception to D-021 org isolation — every cross-org read/write authorizes against a live grant; contributed data homes in the Context's owner org. `canAccessContext(c, item, minAccess?)` (`heediq-api/src/routes/contexts.ts`) is the shared personal/group/org visibility gate, extended with a live `heediq-context-grants` fallback when `minAccess` is passed (never on PATCH/DELETE, so a grant can't authorize mutating a Context); also imported by `sources.ts`'s review route (at `'contribute'`) and issued/revoked via `heediq-api/src/routes/context-grants.ts`.

### Observability (D-085, D-093)
- **Upstream**: reads other stacks'/repos' static resource names only (Lambda function names, SQS queue/DLQ names, ECS cluster/ASG name) — no CDK construct props, so it deploys independently of every other stack's synth order (enabled by D-037: names carry no env prefix). `heediq-shared/src/logger.ts` (+ Python mirror `heediq-worker-transcription/src/logger.py`) is the structured-log shape every service writes to CloudWatch Logs.
- **Downstream**: nothing depends on this stack; it's a pure read/dashboard layer. The dashboard's job-stage funnel Logs Insights query depends on `info`-level lines always being emitted (D-093) — dropping the default threshold to `warn` would silently break it.
- **Shared surfaces**: `ObservabilityStack` (`heediq-infra/lib/observability/observability-stack.ts`) dashboard widgets reference the same hardcoded resource-name strings used by ApiStack/SummarizationStack/TranscriptionStack — renaming a Lambda/queue/ASG in its owning stack silently breaks the corresponding dashboard widget (no compile-time link); `createLogger(service)` is imported by `heediq-api`, `heediq-worker-summarization`, and mirrored by hand in `heediq-worker-transcription`'s `logger.py` — a shape change (including the D-093 `LOG_LEVEL` threshold logic) must be mirrored in the other. `heediq-infra/lib/config.ts`'s `logRetentionFor(workloadEnv)` is the single source for CloudWatch Logs retention (D-093) — ApiStack, SummarizationStack, and TranscriptionStack log groups all call it; a new Lambda/ECS task must too, or it silently defaults to "Never Expire".

## 2026-07-22 · memory/business/architecture.md · RBAC & Audit Trail section condensed to a pointer per Andrii's memory-redesign request (architecture.md should be high-level only, no per-feature implementation detail; full detail already lives in heediq-api/README.md §"D-102/D-105 RBAC & audit trail" and heediq-web/src/lib/rbac/README.md)

Full original section text, preserved verbatim:

## RBAC & Audit Trail (D-102 — built, all 5 phases merged to `develop`, 2026-07-10)
Supersedes D-017's fixed Admin/Member roles with dynamic, per-org RBAC, plus a unified audit trail
raised to a GxP-quality bar (design-quality target, not a formal regulatory obligation today).
`DECISIONS.md` D-102 points here rather than duplicating this detail. D-105 supersedes the
invalidation mechanism only (Token strategy, below); D-104 resolved the audit-log migration
question (no migration — old table dropped outright, not backfilled).

**Domain model:** User ↔ Role (direct) and User ↔ Group ↔ Role (via membership), many-to-many;
effective permissions = union of all roles reached either way, no deny rules. Permissions are a
static `@heediq/shared`-defined catalog of `resource:verb` strings (e.g. `sources:delete`,
`org:manage-roles`, `audit:read`); what's dynamic per org is which permissions a role grants, not
the catalog itself. Enforcement is resource-type granularity only (no per-record ACLs) — "own
content only" stays a narrow ownership filter inside handlers, same shape as today's Member
restriction, now expressed as the `sources:read-own` permission instead of a hardcoded role check.

**Data model (new DynamoDB tables, `heediq-infra` FoundationStack):**
- `heediq-roles` (`pk=ORG#<orgId>`, `sk=ROLE#<roleId>`) — `name`, `permissions[]`, `isSystemRole`.
  Two non-deletable system roles (`admin`: all permissions, `member`: today's default set) are
  seeded into every org at first-login provisioning via `@heediq/shared`'s `DEFAULT_ORG_RBAC_SEED`
  — the direct migration path from D-017 — fully editable after creation; unlimited custom roles.
- `heediq-groups` (`pk=ORG#<orgId>`, `sk=GROUP#<groupId>`) — `name`, `roleIds[]`. No default groups
  seeded (pure org-admin convenience, starts empty).
- `heediq-role-assignments` (`pk=ORG#<orgId>#USER#<accountId>`, `sk=ROLE#<roleId>|GROUP#<groupId>`)
  — the join table resolved at token issuance; `by-role` GSI (`roleId` partition key, no sort key)
  answers "who holds this role" for the role-management UI, not currently queried by any consumer.
- `heediq-audit-log` (`pk=ORG#<orgId>`, `sk=<timestamp>#<eventId>`, `by-user` GSI) — supersedes the
  auth-only `heediq-auth-audit-log` (D-087) into one general-purpose, org-scoped, write-once (no
  update/delete code path) audit trail covering auth events and every RBAC-governed action.

**Token strategy (D-105, supersedes D-102's original design):** permissions are resolved once, at
token issuance, by `resolveEffectivePermissions()` in `auth-provision.ts`'s PreTokenGeneration
trigger, and baked into the Cognito ID token as an expanded `custom:permissions` claim
(JSON-stringified `Permission[]`, not `roleIds` + a version counter). `heediq-api`'s
`requirePermission` middleware is a pure in-token check — no DynamoDB read per request, and no
`rbacVersion` comparison against `heediq-users`. A role/permission change takes effect for a given
user only on their next token refresh (bounded by natural JWT expiry), not instantly — the
deliberate tradeoff Andrii chose over D-102's original per-request DB check + forced-logout design.

**Audit payloads:** `before`/`after` are resource-type-specific, human-readable snapshots (a
`AuditPayloadMap` discriminated union in `@heediq/shared`, e.g. `{ roleId, name, permissions }` for
a role change, `{ sourceId, title, ownerEmail }` for a source), resolved by the calling handler at
write time — never a raw DB row. This keeps entries self-contained (readable without a live join,
even after the referenced record is renamed/deleted) and structurally prevents transcript/PII from
reaching the log, the same PII discipline `createLogger` already applies to CloudWatch logs
(D-085/D-093).

**Audit viewer:** org Admins get `/org/audit-log` (`heediq-web`) backed by `GET /org/audit-log`
(`heediq-api`), cursor-paginated, filterable by date range (native `sk` range — cheapest), actor
(`by-user` GSI when it's the only filter besides date), action type, and resource type (both as
`FilterExpression`s over the date-range query, no dedicated GSI yet). Free-text search is
explicitly deferred — no DynamoDB-native text search; would need a separate index (OpenSearch or
similar) if a real need appears. Gated by a new `audit:read` permission, enforced server-side.

**Frontend permission checks:** `heediq-web`'s `usePermissions`/`<Can>` (in `src/lib/rbac/`, not
the styled kit — no visual styling of its own) read a server-resolved `effectivePermissions` field
added to `GET /me`, computed by the same `resolveEffectivePermissions(accountId)` function the
enforcement middleware uses — one implementation of "what can this user do," never duplicated
client-side. These wrappers are UX-only (hide/show); `requirePermission` middleware in `heediq-api`
remains the only real authority. See `heediq-web/src/lib/rbac/README.md`.

## 2026-07-22 · memory/business/DECISIONS.md · D-102 entry compressed (Decision text tightened to 3-4 sentences; Related code section's phase-by-phase PR-link/commit-hash merge narrative removed — that detail belongs in heediq-api/README.md §"D-102/D-105 RBAC & audit trail", not in the decision log, per the "Related code" discipline this consistency pass is codifying)

Full original entry text, preserved verbatim:

### D-102 · Dynamic per-org RBAC + unified GxP-quality audit trail — design locked (2026-07-08) — Locked
**Area:** Architecture
**Decision:** Replaces D-017's fixed Admin/Member roles with a dynamic, per-org RBAC framework:
Users, Groups, Roles, and a static code-defined Permission catalog (`resource:verb`, e.g.
`sources:delete`, `org:manage-roles`), enforced at resource-type granularity (not per-record ACLs)
in `heediq-api`'s Hono middleware. Each org manages its own roles/groups (no cross-org visibility,
no platform-wide super-admin tier yet). Two non-deletable system roles (`admin`, `member`) are
seeded into every org at first-login provisioning via a shared `DEFAULT_ORG_RBAC_SEED` — the direct
migration path from D-017 — fully editable afterward; unlimited custom roles per org. A user's
effective permissions = union of their direct role assignments + every group's roles they belong to
(no deny rules). Permissions are resolved and baked into the Cognito ID token at issuance (via the
existing `auth-provision.ts` PreTokenGeneration trigger) alongside an `rbacVersion` claim; a
per-request check in `heediq-api`'s auth middleware compares it against the live value on
`heediq-users` and forces a full re-login (`401 RBAC_STALE`, no silent refresh) the moment a user's
roles/permissions change — bounded staleness without a permission-set DB read on every request.
`heediq-web` gets UX-only permission wrappers (`usePermissions`, `<Can>`) driven by a server-resolved
`effectivePermissions` field on `GET /me` — never a client-side authority; server-side
`requirePermission` middleware remains the only real enforcement.
Audit trail: a single unified `heediq-audit-log` table (org-scoped partition, write-once by
construction, no delete/update path in application code) supersedes the auth-only
`heediq-auth-audit-log` (D-087), covering both auth events and every RBAC-governed action.
`before`/`after` snapshots are resource-type-specific, human-readable, and resolved at write time by
the calling handler (never a raw DB row) via a typed `AuditPayloadMap`/`writeAuditEvent` helper in
`@heediq/shared` — keeps entries self-contained (readable without a live join, even after the
referenced record is renamed/deleted) and structurally prevents PII (e.g. transcript text) from
reaching the log. Org Admins get a dedicated `/org/audit-log` viewer (`GET /org/audit-log`,
cursor-paginated, filterable by date range/actor/action/resource type, gated by a new `audit:read`
permission); free-text search is explicitly deferred.
**Why:** Andrii wants a comprehensive, dynamically configurable RBAC + audit framework ahead of
building a lot of functionality on top of the current fixed two-role model, and wants the audit
trail rigorous enough to meet a GxP-grade quality bar (immutable, complete who/what/when/before-after
records) even though no formal regulatory (21 CFR Part 11-style) obligation exists today — confirmed
as a design-quality target, not a compliance requirement to formally validate (no e-signatures or
validation docs built now). Resource-type (not per-record) permission granularity and JWT-bake-in
(not per-request DB lookup) were chosen to avoid a much heavier data model and extra request latency
that no current product need justifies; the `rbacVersion` forced-re-login mechanism was Andrii's
explicit preference over a silent-refresh alternative, trading an unannounced logout (rare,
admin-initiated event) for immediate effect and simplicity/auditability.
**Supersedes:** D-017 (the Admin/Member roles and their permission scope carry forward unchanged as
the seeded `admin`/`member` system roles — only the mechanism becomes dynamic)
**Superseded by:** D-105 (invalidation mechanism only — `rbacVersion`/`RBAC_STALE`/per-request DB
check dropped in favor of natural JWT expiry; Roles/Groups/Permissions catalog, effective-permission
union model, resource-type granularity, and audit trail all unchanged)
**Related code:** Phase 1 **done** — `heediq-shared/src/permissions.ts`, `src/audit.ts` merged &
published (`@heediq/shared@0.9.0`); `heediq-infra` FoundationStack tables
(`heediq-roles`/`heediq-groups`/`heediq-role-assignments`/`heediq-audit-log`, D-103-split
`lib/foundation/tables.ts`, README: `heediq-infra/lib/foundation/README.md`) merged to `develop`
via [PR #48](https://github.com/heediq/heediq-infra/pull/48). Phase 2 **done** — role/group CRUD +
audit write path in `heediq-api` (`routes/roles.ts`/`groups.ts`/`role-assignments.ts`, `lib/audit.ts`),
backed by `heediq-shared`'s 5 RBAC request schemas + `buildAuditLogEntry()` (`@heediq/shared@0.10.0`)
and `heediq-infra` ApiStack grants on the 4 tables — merged to `develop` via
[heediq-shared#26](https://github.com/heediq/heediq-shared/pull/26) (`4f073d4`),
[heediq-infra#49](https://github.com/heediq/heediq-infra/pull/49) (`5be8e07`),
[heediq-api#24](https://github.com/heediq/heediq-api/pull/24) (`87a3528`), all 2026-07-08.
README: `heediq-api/README.md` §"D-102 RBAC & audit trail". Phase 4 **merged to `develop`** —
frontend RBAC UI in `heediq-web`: `src/lib/rbac/` (`usePermissions`/`<Can>`, server-resolved
`effectivePermissions` off `GET /me`, D-105), `src/features/rbac/` (`RoleForm`/`GroupForm`/
`RolesPanel`/`GroupsPanel`/`UsersPanel`/`AssignmentsModal`), `src/routes/RolesSettingsPage.tsx`
(`/settings/roles`, tabbed Roles/Groups/Users). Backed by new `heediq-api` `GET /api/v1/users`
(`src/routes/users.ts`, org-scoped) and `GET /me`'s `effectivePermissions` field. Merged via
[heediq-api#26](https://github.com/heediq/heediq-api/pull/26) (`65b939f`),
[heediq-web#26](https://github.com/heediq/heediq-web/pull/26) (`803fb44`), both 2026-07-09.
READMEs: `heediq-api/README.md` §"D-102 RBAC & audit trail", `heediq-web/README.md`
(Key Files/Dependencies/Testing sections). Phase 5 **merged to `develop`** — audit-log viewer:
`GET /api/v1/org/audit-log` (`heediq-api` `src/routes/audit-log.ts`, cursor-paginated, filterable by
date range/actor/action/resource type, gated by `audit:read`) and the `/org/audit-log` page
(`heediq-web` `src/routes/AuditLogPage.tsx`), backed by a narrowed `dynamodb:Query` IAM grant on
`heediq-audit-log` (`heediq-infra` `lib/api/api-stack.ts`, `Scan`/`GetItem` still blocked). Merged via
[heediq-infra#51](https://github.com/heediq/heediq-infra/pull/51),
[heediq-api#27](https://github.com/heediq/heediq-api/pull/27),
[heediq-web#27](https://github.com/heediq/heediq-web/pull/27), all 2026-07-10.
All 5 phases now merged. Full architecture in `memory/business/architecture.md`
§"RBAC & Audit Trail".

## 2026-07-22 · memory/business/DECISIONS.md · D-141/D-142 entries compressed (key/GSI design detail removed — it already lives in heediq-infra/lib/foundation/README.md §"Context Library tables", confirmed verbatim there down to the TTL-vs-code-enforcement gotcha)

Full original entry text, preserved verbatim:

### D-141 · Context Library — Context visibility model: personal / group / org, permission-gated (2026-07-21) — Locked
**Area:** Product / Architecture
**Decision:** A Context carries a **visibility axis** so the library can show a user everything
available to them — their own plus what's shared — categorized by Domain:
- **`visibility: 'personal' | 'group' | 'org'`** added to `Context` (`@heediq/shared`, a 0.15.0
  addendum to the D-124–D-140 contracts) — `personal` = owner (`userId`) only; `group` = shared to
  one D-102 group (adds `groupId?`, required iff `group`); `org` = visible to the whole `orgId`.
  `userId` remains the creator/owner in every tier.
- **Sharing is permission-gated (D-107):** publishing a Context to a group or the org gates on a new
  RBAC permission key (`context:share`, append-only per D-106) via `requirePermission` + `<Can>`;
  creating a personal Context is not gated beyond org membership. The exact context permission set
  (create/read/update/delete/share) is defined with the API step.
- **Access-pattern / key design (`heediq-contexts`):** base PK=`contextId`; one GSI **`by-scope`**
  PK=`scopeKey` SK=`domainCreatedAt`, where the writer materializes `scopeKey` as `U#<userId>` /
  `G#<groupId>` / `O#<orgId>` from the visibility tier, and `domainCreatedAt` as `<domain>#<createdAt>`.
  A user's library is assembled by querying `by-scope` for `U#<self>`, `O#<orgId>`, and `G#<groupId>`
  per group they belong to; a single Domain is filterable via `begins_with(domainCreatedAt, '<domain>#')`.
  This replaces a naive by-`orgId` GSI, which would have leaked every member's personal Contexts to
  the whole org — a **D-021 row-level isolation** violation.
**Why:** Andrii confirmed the library must surface org-shared and personal Contexts together, grouped
by Domain. Three tiers reuse the existing RBAC groups (D-102) instead of inventing a new sharing
primitive; the single scope-key GSI serves all three audiences with one index and keeps personal
Contexts unreadable by other members by construction.
**Supersedes:** — (extends D-129/D-134 Context model; builds on D-102 groups, D-106/D-107 permissions, D-021 isolation) **Superseded by:** —
**Related code:** `heediq-shared/src/context.ts` + `enums.ts` + `permissions.ts` (0.15.0), `heediq-infra/lib/foundation/context-library-tables.ts`, `heediq-api/` (context routes + writer)

### D-142 · Context Library — cross-org Context sharing via regulated grants (design now, build fast-follow) (2026-07-21) — Locked
**Area:** Architecture / Policy
**Decision:** A Context can be shared **across org boundaries** to a specific external user through an
explicit, time-limited, revocable **grant** — a deliberate, strongly-regulated exception to the D-021
/ eng-std §2 "a user only ever touches their own org's data" invariant, never an implicit widening.
- **New table `heediq-context-grants`:** base PK=`granteeUserId` SK=`contextId` (the access-check
  point lookup *and* the grantee's "shared-with-me" library query — at most one active grant per
  grantee+context — the composite key **is** the grant's identity, no separate `grantId`); GSI
  `by-context` PK=`contextId` SK=`granteeUserId` (owner manages/revokes a Context's grantees). Item
  (`ContextGrantSchema`, `@heediq/shared` 0.15.0): `contextId, granteeUserId, granteeOrgId,
  ownerOrgId, grantedByUserId, access, expiresAt, createdAt, updatedAt`. No `status`/`revokedAt` — a
  revoke is a hard `DELETE` of the item (there is exactly one active grant per grantee+context by
  key design, so there's no past-grant history to retain in this table; an audited `DELETE` action
  is the record). TTL on `expiresAt` (epoch) + PITR + PAY_PER_REQUEST.
  *(Corrected 2026-07-21 — the original entry specified `grantId`/`ownerUserId`/`status`/`createdBy`/
  `revokedAt`; the shipped schema (PR heediq-shared#40) is simpler and is the source of truth.)*
- **Two access tiers:** `read` (view + chat over the Context's memory) and `contribute` (also add
  Sources — files/meetings/transcriptions — into the Context; implies `read`).
- **Enforcement invariants:** every cross-org read/write authorizes against an **active, unexpired**
  grant **at request time**, never cached into the JWT (revoke is immediate); **expiry is enforced in
  code** (read-time `expiresAt` check), DynamoDB TTL is cleanup-only because TTL deletion lags (the
  `heediq-rate-limits` precedent, D-097); grant create/revoke writes an audit event (D-107); the owner
  can revoke anytime. This is a mandatory cross-org-isolation test path.
- **Owner-org homing:** all data under a shared Context stays homed in the **owner org** — a
  contributed Source lands in the owner org's partition attached to the Context, contributed *into*
  the org under the grant, never copied across orgs — so a Context's memory stays unified and the
  grant is the single controlled crossing point.
- **Scope:** the table/model are designed in **now** (rewrite-free); grant issuance/revoke UI, the
  per-request authorization middleware, secure invite flow, and email-invite-before-signup build as a
  **fast-follow** (grants target existing Heediq accounts first — no magic-link/token flow yet). Not
  overengineered now.
**Why:** B2C sharing between individuals (D-143) and B2B cross-company collaboration both need one
person to use and optionally enrich another's accumulated Context; a per-user, expiring, permission-
scoped, audited grant is the minimal safe primitive that opens the org wall exactly as far as the
owner allows and no further.
**Supersedes:** — (regulated exception to D-021; builds on D-107 audit/permissions, D-141 Context model) **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/context-library-tables.ts` (`heediq-context-grants`), `heediq-shared/src/` (grant schema + access enum), `heediq-api/` (grant routes + cross-org authorization middleware)

## 2026-08-04 · memory/codebase/MEMORY.md (heediq-web pointer) · README-duplicating implementation detail pulled out of the index during a consolidation pass; the index now points to `src/features/sources/README.md` for the Capture ingest-path mechanics
The `heediq-web` sub-module pointer previously inlined the full Capture ingest breakdown:

> `src/features/sources/` (B; C review wizard = `src/routes/ReviewWizardPage.tsx`; Capture/ingest landing `/capture` = `src/routes/CapturePage.tsx`, all three D-026 methods: `TextIngestForm`/`useIngestText` (text), `AudioIngestForm`/`useUploadAudio` (audio: create → presign → XHR PUT w/ progress → `POST /:id/jobs {model:'small'}`), `RecordIngestForm`/`useMediaRecorder` (live mic → `audio/webm` Blob through the same `useUploadAudio`; `ListenButton` kit 3-state; D-119), D-150)

(This create→presign→XHR-PUT→`POST /:id/jobs {model:'small'}` flow, the `useMediaRecorder`→`audio/webm`→`useUploadAudio` record path, and the `ListenButton` 3-state kit primitive are all documented in `heediq-web/src/features/sources/README.md` and the `ListenButton` README — the index only needs to name the modules and point there.)

## 2026-08-04 · memory/codebase/MEMORY.md (engineering backlog) · dated completed-work narration trimmed out of active backlog entries during a consolidation pass; only the still-outstanding work stays in MEMORY.md
Verbose, history-carrying versions of five backlog entries, verbatim before trimming:

- **TopBar usage/limit indicator (D-026)** — deferred from Capture (heediq-web#49 shipped record-only).
  Blocked: no free-tier limit constant; `usageLifetimeCount` is set to `0` at provisioning, never
  incremented (no live signal); D-018 free tier is a decay ratchet + **soft prompt, not a `used/limit` cap**
  — a meter needs a product decision + counter wiring (API), then builds off `GET /me`.
- **RBAC catalog-append backfill migration (D-146)** — no tooling yet; when a permission is appended
  to `@heediq/shared`'s `PERMISSIONS`, existing orgs' system roles must be backfilled. Currently a
  manual per-org PATCH (done for the dev admin org 2026-07-22). Needs a scripted migration.
- **E2E dev-smoke harness (D-147)** — first instance **committed**: `heediq-chat/tests/e2e/chat-smoke.mjs`
  (`pnpm run e2e:chat`), the Context-chat happy path (create Context → conversation → post →
  chat_delta/chat_complete over WS), green on dev 2026-07-23. Open: shared token-provisioning helper + CI
  wiring, and smokes for the other features.
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
