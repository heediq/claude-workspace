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
  - FoundationStack UserPool — owns the Cognito PreTokenGeneration trigger wiring (custom attributes `custom:orgId`/`custom:role` + Lambda association, D-077); the trigger's real handler code is a `heediq-api`-owned artifact deployed by that repo's CI, same cross-repo split as the WebSocket Connection Lambda below

### Transcription pipeline (TranscriptionStack)
- **Upstream**: FoundationStack (SQS `heediq-transcription`, S3 `heediq-audio-uploads-*`, DynamoDB `heediq-jobs` + `heediq-sources`); SharedServicesStack (ECR repo `heediq-worker-transcription`); per-env SSM params `/heediq/transcription/{free,paid}-image-tag` (written by CI, read by CloudFormation at deploy time)
- **Downstream**: `heediq-worker-transcription` (two per-tier images, D-062; deployed by that repo's CI via register-task-definition + pipes update-pipe); SummarizationStack (indirectly triggered after worker enqueues to heediq-summarization); WebSocket status push via Status Pusher Lambda + DDB Streams on `heediq-jobs` (D-061)
- **Shared surfaces**: `heediq-jobs` table (written by EC2 GPU task, read by Status Pusher Lambda + API); `heediq-sources` table (written by EC2 GPU task with transcript text); ECR repo (shared pull path per D-045)

### WebSocket real-time status (WebSocketStack)
- **Upstream**: FoundationStack (heediq-jobs DDB Streams stream ARN; heediq-ws-connections table; wildcardCert — ACM wildcard cert eu-west-1, D-063); Cognito (JWKS for JWT validation in Connection Lambda)
- **Downstream**: heediq-web (connects via wss://ws-{env}.heediq.com; receives status push events); heediq-api (Connection Lambda code deployed by heediq-api CI per D-050)
- **Shared surfaces**: heediq-ws-connections table (written by Connect Lambda, read by Status Pusher Lambda); heediq-jobs DDB Streams (read-only by Status Pusher Lambda); SSM /heediq/api/ws-endpoint-url (read by heediq-web and heediq-api)

### Summarization pipeline (SummarizationStack)
- **Upstream**: FoundationStack (heediq-jobs + heediq-sources DynamoDB tables; heediq-audio-uploads S3 bucket); SummarizationStack (heediq-summarization SQS queue — created here, consumed by Lambda event source)
- **Downstream**: `heediq-worker-summarization` (Node Lambda — placeholder in stack; real implementation deployed by that repo's CI, D-043); `heediq-api` (reads structured output from heediq-sources); `heediq-web` (displays extraction results)
- **Shared surfaces**:
  - `heediq-summarization` SQS queue — written by TranscriptionStack EC2 task role (audio path) + ApiStack Lambda (direct non-audio path, D-065, D-026); consumed by summarization Lambda. Message schema: `SummarizationJobMessage { jobId, sourceId, orgId, sourceType, contentRef, tier }` — `tier` is required and forwarded by all producers so the summarization Lambda can select the correct Claude model (D-067)
  - `heediq-jobs` table — written by summarization Lambda (status: `summarizing → done/failed`); also written by transcription worker + read by Status Pusher Lambda
  - `heediq-sources` table — written by summarization Lambda (structured extraction fields); also written by transcription worker + read by ApiStack Lambda
  - `heediq-audio-uploads-*` S3 bucket — read by summarization Lambda (transcript + direct-path content files); also written by API (presigned URL upload)

### Web frontend delivery (WorkloadCfCertStack + WebStack)
- **Upstream**: FoundationStack (heediq-web-assets-{accountId} S3 bucket — OAC bucket policy grant added there; wildcardCert not used here); WorkloadCfCertStack (us-east-1 ACM cert via crossRegionReferences prop, D-053); SharedServicesStack (heediq-route53-dns-manager role for Route53AliasRecord D-064); `lib/config.ts → DOMAINS` (web domain per env)
- **Downstream**: heediq-web (React SPA — served from CloudFront; CI does S3 sync + `aws cloudfront create-invalidation` using `/heediq/web/cloudfront-distribution-id` SSM param); heediq-api (reads `/heediq/web/url` SSM param for CORS origin)
- **Shared surfaces**:
  - `heediq-web-assets-{accountId}` S3 bucket — written by heediq-web CI; served by CloudFront via OAC (source-account policy in FoundationStack)
  - `/heediq/web/url` SSM param — consumed by heediq-api (CORS) and heediq-web (runtime config)
  - `/heediq/web/cloudfront-distribution-id` SSM param — consumed by heediq-web CI for cache invalidation
  - **Key CDK constraint**: OAC bucket policy must live in FoundationStack (source-account condition), not WebStack — avoids circular cross-stack reference. `s3.Bucket.fromBucketName()` in WebStack prevents CDK from adding a second bucket policy.

### @heediq/shared (heediq-shared)
- **Upstream**: nothing — this is the lowest-level package, no runtime dependencies beyond zod
- **Downstream**: `heediq-api` (Zod parse at every API boundary), `heediq-web` (request/response types, WS message types), `heediq-worker-summarization` (SQS message schema + summary domain types)
- **Shared surfaces**: all Zod schemas in `src/` — a breaking change here requires a version bump and coordinated update in all consuming repos (D-047/D-048)

### heediq-api (API Lambda)
- **Upstream**: `heediq-infra` ApiStack (Lambda must exist before code can be deployed, D-050); `@heediq/shared` (types + validation); Cognito User Pool (JWKS endpoint); DynamoDB tables (sources, orgs, users, jobs, ws-connections); S3 audio bucket; SQS transcription + summarization queues
- **Downstream**: `heediq-web` (REST API consumer); `heediq-worker-transcription` (reads SQS transcription queue messages enqueued here); `heediq-worker-summarization` (reads SQS summarization queue for direct-path uploads, D-065)
- **Shared surfaces**: `heediq-sources` table (written by API on create; read by API on get/list; also written by summarization worker on completion); `heediq-jobs` table (written by API on enqueue; read by Status Pusher Lambda); SQS queue URLs (SSM params consumed by API env vars); `src/handlers/auth-provision.ts` (D-077) — the Cognito PreTokenGeneration trigger handler; code owned and deployed by heediq-api CI as a second Lambda but *wired as a trigger* by `heediq-infra` FoundationStack; stamps `custom:orgId`/`custom:role` claims onto the ID token — a contract shared with `heediq-web`'s auth flow

### heediq-worker-transcription
- **Upstream**: `heediq-infra` TranscriptionStack (EventBridge Pipes + ECS cluster + EC2 GPU Spot ASG + task defs + IAM grants, D-059); `heediq-infra` SharedServicesStack (ECR repo `heediq-worker-transcription`); `heediq-api` (must set `tier` SQS message attribute on enqueue — without it both Pipe filters fail silently); S3 audio bucket (read-only); DynamoDB `heediq-jobs` + `heediq-sources`; SQS `heediq-transcription` (re-enqueue on SIGTERM, D-066) + `heediq-summarization` (enqueues on completion, D-065)
- **Downstream**: `heediq-worker-summarization` (reads `heediq-sources[sourceId].transcript` from DynamoDB — NOT from S3; enqueued with `sourceType: 'text', contentRef: sourceId`); `heediq-web` (status push via DDB Streams → Status Pusher Lambda → WebSocket, D-061)
- **Shared surfaces**: `heediq-jobs` table (status writes: `starting → transcribing → diarizing → summarizing → done/failed/retrying`); `heediq-sources` table (writes `transcript` text field — consumed by summarization worker); DDB Streams on `heediq-jobs` (D-061)

### heediq-worker-summarization
- **Upstream**: `heediq-infra` SummarizationStack (Lambda + SQS event source must exist, D-065); `@heediq/shared` (SummarizationJobMessage schema); DynamoDB `heediq-jobs` + `heediq-sources` (reads `transcript` from sources table by `sourceId` when `sourceType='text'`); S3 audio bucket (reads direct-upload content when `sourceType != 'text'`); Secrets Manager (Claude API key)
- **Downstream**: `heediq-api` (reads structured extraction from `heediq-sources`); `heediq-web` (displays summary output)
- **Shared surfaces**: `heediq-sources` table (writes structured extraction: requirements, decisions, openQuestions, actionItems); `heediq-jobs` table (writes `status=done/failed` on completion); SQS `heediq-summarization` queue (shared entry point for audio + direct-upload paths, D-065)

### heediq-web (PWA frontend)
- **Upstream**: `heediq-infra` WebStack (CloudFront + S3 bucket must exist before deploy); `heediq-api` (all REST endpoints); WebSocket API (`ws-{env}.heediq.com`, D-061); `@heediq/shared` (request/response types, WS message types); Cognito Hosted UI (auth via OAuth 2.0 Authorization Code + PKCE, D-020, D-077); Cognito unauthenticated IdP JSON API (client-direct SignUp/InitiateAuth/ForgotPassword, D-082)
- **Downstream**: nothing — leaf consumer
- **Shared surfaces**: `/heediq/web/url` SSM param (consumed by `heediq-api` for CORS origin config); `/heediq/web/cloudfront-distribution-id` SSM param (consumed by web CI for cache invalidation); S3 `heediq-web-assets` bucket (written by web CI, served by CloudFront via OAC); `/heediq/api/cognito-hosted-ui-domain` + `/heediq/api/cognito-client-id` SSM params (written by `heediq-infra` FoundationStack, consumed by web CI to inject `VITE_COGNITO_DOMAIN`/`VITE_COGNITO_CLIENT_ID` at build time, D-077); the `custom:orgId`/`custom:role` ID token claims contract — stamped by `heediq-api`'s auth-provision Lambda (D-077), consumed by heediq-web's AuthContext — a rename on either side breaks auth silently

### Account linking (D-078–D-083)
- **Upstream**: `heediq-infra` FoundationStack (`by-email` GSI on `heediq-users`, Cognito App Client `callbackUrls` incl. `/settings/link-callback`, D-083); `heediq-api` (`POST /auth/lookup-email` — built; `POST /auth/link/confirm` and `POST /settings/link/add-provider` — not yet built, see below); Cognito unauthenticated IdP JSON API + Hosted UI OAuth (D-082, D-083)
- **Downstream**: nothing yet — leaf feature within heediq-web; will gate `heediq-api`'s `AdminLinkProviderForUser`/`AdminSetUserPassword` calls once built
- **Shared surfaces**:
  - `passwordSet` flag on `heediq-users` (DynamoDB) — set by `heediq-api` provisioning, read by `/auth/lookup-email` to branch `HomePage`'s sign-in vs. forgot-password-linking step
  - `identities` Cognito ID-token claim — produced by Cognito on any federated sign-in, consumed by `heediq-web`'s `SettingsLinkCallbackPage` to get the provider's `{userId, providerName}` (see `heediq-web/src/lib/auth/README.md`)
  - `/settings/link-callback` Cognito callback URL — registered in `heediq-infra` FoundationStack (D-083); breaks the proactive-linking OAuth round trip if removed or renamed on either side
  - **Blocked backend work**: `POST /auth/link/confirm` blocked on a spike (does `ForgotPassword`/`ConfirmForgotPassword` work for a Cognito user in `EXTERNAL_PROVIDER` status?); `POST /settings/link/add-provider` blocked on installing `@aws-sdk/client-cognito-identity-provider` in `heediq-api`, itself blocked by the pnpm `minimumReleaseAge` cooldown on `@heediq/shared@0.3.0`

<!--
Template:
### <feature>
- Upstream: ...
- Downstream: ...
- Shared surfaces: ...
-->
