# Feature Dependency Map

Drives "what to retest" (Step 2) and PR blast-radius notes. One entry per feature.

## Format
```
### <feature name>
- **Upstream** (this depends on): …
- **Downstream** (breaks if this changes): …
- **Shared surfaces**: files/data models touched by multiple features
```

## Entries

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
- **Upstream**: `@heediq/shared` Context Library contracts (**landed**, v0.14.0–0.15.1: `Domain`/`DOMAIN_PROFILES`, `Context`/`ExtractedItem`/`DecisionLedgerEntry`/`ProposedClassification`, `ContextGrant`, request schemas for the API step, Source review fields, `classification_ready`/`chat_delta`/`chat_complete` WS events). **Infra tables landed** (step 2): `heediq-contexts` (+ `by-scope` GSI, D-141), `heediq-extracted-items`, `heediq-decision-ledger`, `heediq-conversations`, `heediq-chat-messages`, `heediq-context-grants` (cross-org sharing, D-142). **`heediq-api` `/contexts` CRUD + review-approval route landed** (step 4b, [heediq-api#42](https://github.com/heediq/heediq-api/pull/42) merged to `develop`). **Infra ApiStack IAM grants for the 6 tables landed** ([heediq-infra#61](https://github.com/heediq/heediq-infra/pull/61) merged to `develop`).
- **Downstream**: `heediq-worker-summarization` (writes `ExtractedItem`s + `gist`, runs the combined classify+extract call, D-130/D-135 — done); `heediq-api` (`/contexts` CRUD + `/sources/:id/review` — done, merged); `heediq-web` (Source/Summary/WS types, review wizard, Context chat — not started); `heediq-worker-transcription` `models.py` (hand-mirrored Summary shape — still has old flat-array shape, deferred).
- **Shared surfaces**: `Summary` schema — **breaking shrink** to `transcript`+`gist` (D-135 supersedes D-132); the four flat extraction arrays are gone, replaced by item-level `ExtractedItem`. `Source` gains `contextId`/`classification`/`proposedClassification` (non-key attrs, no infra change). `DOMAIN_PROFILES` `extractionFields`/`starterPrompts` are slug IDs consumed by both the summarization worker (extraction shape) and `heediq-web` (t()-mapped labels). New WS events flow through `wsPush.ts` (D-109) and `useWsEvent` (D-110). Infra `create-tables.ts` mirror (D-030 drift risk) now carries the 6 Context Library tables. Cross-org grants (D-142) are a regulated exception to D-021 org isolation — every cross-org read/write authorizes against a live grant; contributed data homes in the Context's owner org. `canAccessContext(c, item)` (`heediq-api/src/routes/contexts.ts`) is the shared personal/group/org visibility gate, also imported by `sources.ts`'s review route.

### Observability (D-085, D-093)
- **Upstream**: reads other stacks'/repos' static resource names only (Lambda function names, SQS queue/DLQ names, ECS cluster/ASG name) — no CDK construct props, so it deploys independently of every other stack's synth order (enabled by D-037: names carry no env prefix). `heediq-shared/src/logger.ts` (+ Python mirror `heediq-worker-transcription/src/logger.py`) is the structured-log shape every service writes to CloudWatch Logs.
- **Downstream**: nothing depends on this stack; it's a pure read/dashboard layer. The dashboard's job-stage funnel Logs Insights query depends on `info`-level lines always being emitted (D-093) — dropping the default threshold to `warn` would silently break it.
- **Shared surfaces**: `ObservabilityStack` (`heediq-infra/lib/observability/observability-stack.ts`) dashboard widgets reference the same hardcoded resource-name strings used by ApiStack/SummarizationStack/TranscriptionStack — renaming a Lambda/queue/ASG in its owning stack silently breaks the corresponding dashboard widget (no compile-time link); `createLogger(service)` is imported by `heediq-api`, `heediq-worker-summarization`, and mirrored by hand in `heediq-worker-transcription`'s `logger.py` — a shape change (including the D-093 `LOG_LEVEL` threshold logic) must be mirrored in the other. `heediq-infra/lib/config.ts`'s `logRetentionFor(workloadEnv)` is the single source for CloudWatch Logs retention (D-093) — ApiStack, SummarizationStack, and TranscriptionStack log groups all call it; a new Lambda/ECS task must too, or it silently defaults to "Never Expire".

<!--
Template:
### <feature>
- Upstream: ...
- Downstream: ...
- Shared surfaces: ...
-->
