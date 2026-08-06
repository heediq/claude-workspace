# Feature Dependency Map

Drives "what to retest" (Step 2) and PR blast-radius notes. One entry per feature. **Names only** —
no schemas, message shapes, SSM paths, or key designs; that detail lives in the owning module's
README (`06-documentation.md`). This file exists to answer "what else could break," not "how does
it work."

## Format
```
### <feature name>
- **Upstream** (this depends on): feature/resource names
- **Downstream** (breaks if this changes): feature/resource names
- **Shared surfaces**: resource/file names touched by multiple features
```

## Entries

### Infrastructure (heediq-infra)
- **Upstream**: AWS accounts, `lib/config.ts` naming/sizing/DNS/SES decisions
- **Downstream**: all app repos (heediq-api, heediq-worker-transcription, heediq-worker-summarization, heediq-web)
- **Shared surfaces**: `lib/config.ts`, setup scripts (`setup-aws-profiles.sh`, `setup.sh`, `setup-budgets.sh`), FoundationStack UserPool, `heediq-cognito-identities` table

### Transcription pipeline (TranscriptionStack)
- **Upstream**: FoundationStack (SQS, S3, DynamoDB tables), SharedServicesStack (ECR)
- **Downstream**: heediq-worker-transcription, Summarization pipeline, Real-time WebSocket framework
- **Shared surfaces**: `heediq-jobs` table, `heediq-sources` table, ECR repo

### Real-time WebSocket framework (WebSocketStack, D-061 generalized D-109)
- **Upstream**: FoundationStack (DDB Streams, `heediq-ws-connections` table, wildcard cert), Cognito, `@heediq/shared` `ws.ts`
- **Downstream**: heediq-web, heediq-api, any future feature pushing WS events
- **Shared surfaces**: `heediq-ws-connections` table, `heediq-jobs` DDB Streams, `WebSocketStack.grantPush()`, WS endpoint SSM params
- **Known gap**: WS handlers (`ws-connect`/`ws-pusher`/`wsPush`) are unit-tested only, not against a real table — see `heediq-api/README.md`.

### Summarization pipeline (SummarizationStack)
- **Upstream**: FoundationStack (`heediq-jobs`, `heediq-sources`, S3 audio bucket), SummarizationStack SQS queue
- **Downstream**: heediq-worker-summarization, heediq-api, heediq-web
- **Shared surfaces**: `heediq-summarization` SQS queue, `heediq-jobs` table, `heediq-sources` table, `heediq-contexts` table, `heediq-extracted-items` table, S3 audio bucket

### Web frontend delivery (WorkloadCfCertStack + WebStack)
- **Upstream**: FoundationStack (`heediq-web-assets` bucket), WorkloadCfCertStack, SharedServicesStack (Route53 role), `lib/config.ts` domains
- **Downstream**: heediq-web, heediq-api (CORS)
- **Shared surfaces**: `heediq-web-assets` bucket, `/heediq/web/url` SSM param, `/heediq/web/cloudfront-distribution-id` SSM param
- **Known gap**: `heediq-api`'s app-level CORS array is dead/misconfigured — see `heediq-api/README.md`.

### @heediq/shared (heediq-shared)
- **Upstream**: none (lowest-level package)
- **Downstream**: heediq-api, heediq-web, heediq-worker-summarization
- **Shared surfaces**: all Zod schemas in `src/`

### heediq-api (API Lambda)
- **Upstream**: heediq-infra ApiStack, heediq-shared, Cognito, DynamoDB tables (sources, orgs, users, jobs, ws-connections, roles, groups, role-assignments, audit-log), S3 audio bucket, SQS queues
- **Downstream**: heediq-web, heediq-worker-transcription, heediq-worker-summarization
- **Shared surfaces**: `heediq-sources` table, `heediq-jobs` table, SQS queue URLs, `auth-provision.ts` (Cognito PreTokenGeneration trigger), `accountIdentity.ts`, RBAC routes (`roles.ts`/`groups.ts`/`role-assignments.ts`) + `audit.ts`

### heediq-worker-transcription
- **Upstream**: heediq-infra TranscriptionStack, SharedServicesStack ECR, heediq-api (tier attribute), S3 audio bucket, `heediq-jobs`/`heediq-sources` tables, SQS transcription + summarization queues
- **Downstream**: heediq-worker-summarization, heediq-web (via WS status push)
- **Shared surfaces**: `heediq-jobs` table, `heediq-sources` table, `heediq-jobs` DDB Streams

### heediq-worker-summarization
- **Upstream**: heediq-infra SummarizationStack, heediq-shared, `heediq-jobs`/`heediq-sources` tables, S3 audio bucket, Secrets Manager
- **Downstream**: heediq-api, heediq-web
- **Shared surfaces**: `heediq-sources` table, `heediq-jobs` table, `heediq-summarization` SQS queue

### heediq-web (PWA frontend)
- **Upstream**: heediq-infra WebStack, heediq-api, WebSocket API, heediq-shared, Cognito Hosted UI + unauthenticated IdP API
- **Downstream**: none (leaf consumer)
- **Shared surfaces**: `/heediq/web/url` SSM param, `/heediq/web/cloudfront-distribution-id` SSM param, `heediq-web-assets` bucket, Cognito SSM params, `custom:orgId`/`custom:role`/`custom:accountId` ID-token claims contract, `WsProvider.tsx`/`useWsEvent`, `motion.ts`, `vite-plugin-pwa` config

### Account linking (D-078–D-091, D-096–D-099)
- **Upstream**: heediq-infra FoundationStack (`heediq-cognito-identities`, `heediq-user-auth-methods`, `heediq-auth-audit-log`, `heediq-rate-limits` tables; Cognito triggers; `custom:accountId` attribute), heediq-api auth/link routes, Cognito Hosted UI OAuth
- **Downstream**: none yet (leaf feature within heediq-web)
- **Shared surfaces**: `passwordSet` flag on `heediq-users`, `identities` ID-token claim, `/settings/link-callback` callback URL, `heediq-user-auth-methods`/`heediq-auth-audit-log` tables, `VerifyAndSetPasswordForm.tsx`, `accountIdentity.ts` resolution helpers, `rateLimit.ts`

### Context Library (D-124–D-144)
- **Upstream**: heediq-shared Context Library contracts, heediq-infra Context Library tables (`heediq-contexts`, `heediq-extracted-items`, `heediq-decision-ledger`, `heediq-conversations`, `heediq-chat-messages`, `heediq-context-grants`), heediq-infra `ChatStack` (SQS `heediq-chat`+DLQ, D-138/D-139)
- **Downstream**: heediq-worker-summarization, heediq-api, heediq-chat (new repo, D-138/D-139 — consumes `ChatJobMessage`, own WS-push), heediq-ledger (D-148 reconcile worker), heediq-web (slices A–D shipped: contexts / source-detail / review-wizard / chat panel; Decision Ledger — own entry below), heediq-worker-transcription `models.py` (deferred mirror update)
- **Shared surfaces**: `Summary` schema, `Source` classification fields, `DOMAIN_PROFILES`, `wsPush.ts`/`useWsEvent`, `create-tables.ts` mirror, `heediq-context-grants` table, `canAccessContext()` gate, `ChatJobMessage`/`chat_delta`/`chat_complete`/`chat_failed` (D-145)

### Decision Ledger (D-136/D-137/D-148/D-149)
- **Upstream**: heediq-shared ledger contracts (`DecisionLedgerEntry`, ledger CRUD requests, `LedgerGatedDetails`, `ledger_ready`), heediq-infra `LedgerStack` (`heediq-ledger` SQS+DLQ, `heediq-decision-ledger` table), heediq-api review route (enqueues the ledger job on approval), Secrets Manager (Claude key), Context Library (contexts + extracted-items it reconciles)
- **Downstream**: heediq-web (standing ledger view, review-wizard step 3 reconciliation, chat gate banner), heediq-api chat send (D-149 synchronous gate)
- **Shared surfaces**: `heediq-decision-ledger` table, `heediq-ledger` SQS queue, `ledger_ready` WS event, `LEDGER_GATED` error code + `bypassLedgerGating` flag, `DecisionLedgerEntry` schema, web `features/ledger` hooks + `LedgerEntryRow` (reused by chat `LedgerGateBanner`), status-from-answer/confidence derivation (never trusted from the model — enforced in both heediq-ledger `reconcile.ts` and heediq-api)

### Observability (D-085, D-093)
- **Upstream**: reads other stacks'/repos' resource names only (no construct-level dependency)
- **Downstream**: none (pure dashboard layer)
- **Shared surfaces**: `ObservabilityStack` dashboard widgets, `createLogger`/`create_logger`, `logRetentionFor()`

### Product analytics (D-151, D-154)
- **Upstream**: `@heediq/shared` analytics contract (`buildServerAnalyticsEvent` + id-prop types + cross-service event names); Amplitude (external); `custom:accountId`/`custom:orgId` ID-token claims (identity/join keys); `heediq-sources`/`heediq-users` reads for the server emit sites; SSM `/heediq/api/amplitude-api-key`
- **Downstream**: none (fire-and-forget emission to Amplitude; no repo consumes it)
- **Shared surfaces**: `heediq-shared/src/analytics.ts` (client+server contract), `heediq-web/src/lib/analytics/` (client boundary + `AnalyticsBridge` WS→analytics mapper), `heediq-api/src/lib/analytics.ts` (server emit helper) fired from `ws-pusher.ts`/`auth-provision.ts`/`auth-trigger-post-authentication.ts`, `heediq-infra/lib/shared/analytics-env.ts` (`AMPLITUDE_API_KEY` opt-in wiring), the `sourceId`/`orgId`/`accountId` join keys shared with capture/source + auth flows

<!--
Template:
### <feature>
- Upstream: ...
- Downstream: ...
- Shared surfaces: ...
-->
