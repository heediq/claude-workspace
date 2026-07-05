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

- **Account linking model (D-078–D-087) — reactive linking built end-to-end, merged.** Email is the
  one true identity across native + IdP signup; `by-email` GSI + self-maintained `passwordSet` flag on
  `heediq-users`; linking available reactively (login-time conflict) and proactively (Settings); no
  separate marketing page — `/` is always the unified sign-in/sign-up screen. Client talks to Cognito
  directly wherever its public APIs allow (D-082) — see `heediq-web/src/lib/auth/README.md`. Proactive
  linking of a never-before-used provider needs its own OAuth round trip on a dedicated
  `/settings/link-callback` route (D-083), also documented there. D-078 spike resolved: Cognito
  `ForgotPassword` fails for `EXTERNAL_PROVIDER` users (confirmed live); reactive linking instead
  reuses Cognito's own `SignUp`/`ConfirmSignUp` confirmation-code flow (D-087, superseding D-086's
  custom-OTP-via-SES design — pattern replicated from `EmotiXOrg/emotix-infra`'s
  `password-setup-start`/`password-setup-complete` Lambdas, adapted to heediq's `by-email` GSI +
  PreTokenGeneration-based provisioning instead of emotix's `pk`/`sk` scheme). Built and merged:
  `heediq-infra` (`heediq-user-auth-methods`/`heediq-auth-audit-log` tables + 3 Cognito triggers —
  pre-signup, post-confirmation, post-authentication), `heediq-api` (`POST /auth/link/request-otp` +
  `POST /auth/link/confirm` + `lib/cognito.ts` + the 3 trigger handlers, 54 tests), `heediq-web`
  (`HomePage`'s `linkCode` step now calls the real endpoints, `SettingsPage`/
  `SettingsLinkCallbackPage` for proactive linking). Still open: `POST /settings/link/add-provider`
  (proactive linking's backend half — not yet built). See `DECISIONS.md` for full decision text.

- **Auth redesign built (D-089–D-091, 2026-07-04).** QA surfaced that Google/Microsoft
  `attributeMapping` in `foundation-stack.ts` never mapped `email_verified`, so `auth-provision.ts`'s
  D-080 check always read false and silently skipped org auto-provisioning for every federated login —
  reproducing "Google login → log out → email/password shows plain signup, not linking." Rather than
  just fix the mapping, three new decisions replace the model: D-089 (own verify-then-password flow,
  one shared two-step component — `heediq-web/src/features/auth/VerifyAndSetPasswordForm.tsx`,
  generalized from linking-only to also cover native signup and proactive settings-linking —
  supersedes D-080's IdP-trust mechanism, D-082's native-signup-stays-client-direct claim, and
  D-086/D-087's linking-only/one-combined-form scope), D-090 (provisioning trigger drops the
  `email_verified` check entirely and resolves the existing row by email first, falling back to `sub`
  — provisioning is now unconditional on first login, D-077's zero-friction promise unaffected), D-091
  (`heediq-user-auth-methods` is the source of truth for `GET /auth/methods`, which `SettingsPage`
  reads to display currently-active methods read-only, not just add-buttons). Built end-to-end in
  `heediq-api` (63 tests) and `heediq-web` (95 tests); see `heediq-web/src/features/auth/README.md`,
  `heediq-web/src/lib/auth/README.md`, `heediq-api/README.md`. **Not yet committed/PR'd** — verified
  working on `feature/own-verification-auth-model` in both repos as of 2026-07-04. Uses a manual
  dev-only `@heediq/shared` dist-copy workaround (no version bump/publish yet) — must be resolved
  before either branch ships.

- **heediq-infra** — CDK TypeScript project; all stacks for all accounts.
  README: `../../heediq-infra/README.md` · Decisions: D-036, D-037, D-038, D-044, D-045, D-051–D-068, D-077, D-083, D-087, D-090 (supersedes D-080)
  - Cognito App Client `callbackUrls` now includes `/settings/link-callback` alongside `/auth/callback` (D-083), each with a `localhost:5173` dev variant. 28/28 foundation-stack tests green.
  - **D-087 built and merged (PR #35, #36)**: `heediq-user-auth-methods`/`heediq-auth-audit-log` tables (`pk`/`sk`) + 3 Cognito triggers (pre-signup, post-confirmation, post-authentication) wired on the User Pool, real handler code deployed by `heediq-api` CI. IAM policies use an account/region-scoped `formatArn()` pattern, not a direct `userPool.userPoolArn` reference, to avoid a CloudFormation circular dependency. 161/161 tests green.
  - `feature/auth-org-provisioning-trigger` branch (not yet PR'd): FoundationStack UserPool now has `custom:orgId`/`custom:role` custom attributes + a PreTokenGeneration Lambda trigger (`heediq-auth-provision`, placeholder inline code — real handler deployed by `heediq-api`'s CI) + new SSM param `/heediq/api/cognito-hosted-ui-domain` (D-077). 155/155 tests green.
  - PR #31 open (refactor/rename-recordings-table-to-sources → develop). D-068 rename fully deployed clean to dev (all 7 stacks). 153/153 tests green.
  - **TranscriptionStack** — EC2 GPU Spot (g4dn.xlarge, D-059); ASG min=0; two Ec2TaskDefs (free/paid, D-060); models baked in image (D-062). Deployed to dev.
  - **FoundationStack** — 5 tables (sources, orgs, users, jobs w/ DDB Streams NEW_IMAGE, ws-connections w/ TTL + by-source GSI); ACM wildcard cert eu-west-1 (D-063); 14 SSM params. Deployed to dev. Table renamed `heediq-recordings`→`heediq-sources`, `recordingId`→`sourceId` (D-068).
  - **WebSocketStack** — WebSocket API + heediq-ws-connect + heediq-ws-status-pusher (DDB Streams trigger) + custom domain ws-{env}.heediq.com + Route53AliasRecord (D-064) + 2 SSM params (D-061). Deployed to dev.
  - **ApiStack** — Lambda heediq-api (Node.js 22, 512 MB, 30s) + HTTP API (CfnApi, ANY /{proxy+}, $default stage, CORS) + custom domain api-{env}.heediq.com + Route53AliasRecord + IAM grants (5 tables, S3, SQS transcription+summarization, SecretsManager, SES role) + 2 SSM params. Merged to develop (PR #23). Updated: sqs:SendMessage on summarization queue + SUMMARIZATION_QUEUE_URL env var (D-065).
  - **SummarizationStack** — SQS queue heediq-summarization + DLQ + Lambda heediq-summarization (Node.js 22, 512 MB, 300s) + SQS event source (batchSize=1) + IAM (SecretsManager, DynamoDB jobs+sources, S3 read) + 3 SSM params. Source-agnostic: audio (transcription worker) + direct path (API Lambda, text/PDF/email/Excel). D-065. PR #24 merged to develop.
  - **WorkloadCfCertStack** — ACM wildcard cert (`*.heediq.com`) in us-east-1 per workload account; cert ARN passed to WebStack via `crossRegionReferences: true`. D-053. PR #25 merged to develop.
  - **WebStack** — CloudFront + S3 OAC + custom domain + security headers (HSTS/X-Frame/CSP) + SPA 403/404→/index.html + Route53AliasRecord (Z2FDTNDATAQYW2) + 2 SSM params. D-053, D-055. Key gotcha: OAC bucket policy must live in FoundationStack (source-account condition) to avoid circular CDK dependency. PR #25 merged to develop.
  - **SharedServicesStack** — ECR, Route 53, SES+DKIM, cross-account IAM roles (heediq-ses-email-sending, heediq-route53-dns-manager D-064). Deployed.

- **heediq-shared** — `@heediq/shared`: Zod schemas + TypeScript types for all cross-repo contracts.
  README: `../../heediq-shared/README.md` · Decisions: D-033, D-040, D-047, D-048
  - Schemas: enums, domain (Org/User/Source/Job/Summary), API requests, SQS messages (D-023/D-059/D-065), WS push (D-061). `Recording`→`Source`, `recordingId`→`sourceId`, `+labels: string[]` (D-068).
  - `@heediq/shared@0.3.0` published to GitHub Packages (adds `LookupEmailRequest/Response`,
    `LinkStartRequest` for D-078 account linking) and consumed by `heediq-api`/`heediq-web`. 58 tests.
  - Gotcha: new consuming repos need manual read-access grant in GitHub Packages settings (see README).

- **heediq-api** — Hono Lambda: all REST endpoints under `/api/v1/`, JWT auth middleware, D-060 access control.
  README: `../../heediq-api/README.md` · Decisions: D-033, D-034, D-041, D-042, D-060, D-068, D-077, D-078, D-079, D-087, D-088, D-089, D-090, D-091
  - **D-089/D-090/D-091 built (2026-07-04, not yet committed)**: `auth-provision.ts` drops the
    `email_verified` gate and resolves existing users by email first, falling back to `sub`; new
    `routes/auth-methods.ts` (`GET /auth/methods`, D-091); `routes/auth.ts`'s `request-otp`/`confirm`
    generalized to also serve native signup and Settings-linking (D-089), not just reactive linking.
    63/63 tests green. Uses a dev-only manual `@heediq/shared` dist-copy (real version bump/publish
    still needed before shipping).
  - **D-088 fixed (2026-07-04)**: `heediq-web` was calling `/auth/lookup-email` etc. with no version
    prefix against a backend that only serves `/api/v1/auth/lookup-email` — 404 in `dev.heediq.com`.
    Root cause: both sides' route tests mounted a sub-router/mocked the client in isolation, never
    exercising the real `/api/v1` mount path. Fixed by centralizing the prefix in exactly one place
    per side (`heediq-web/src/lib/api-client.ts`'s `request()`; `heediq-api/src/app.ts`'s
    `app.route()` calls, already correct) and adding `src/__tests__/app-routing.test.ts` — imports
    the real `app`, not a bare sub-router. 58/58 tests green.
  - PR #1, #2 merged (feature/api-scaffold → develop, updated with D-068 rename). 19 tests. deploy.yml: esbuild bundle → Lambda update on develop push.
  - **D-087 built and merged (PR #6, #7)**: `routes/auth.ts` adds `POST /auth/link/request-otp` + `POST /auth/link/confirm`; new `src/lib/cognito.ts` SDK wrapper; 3 new `src/handlers/auth-trigger-*.ts` Cognito trigger handlers (own esbuild bundle + deploy step each, same pattern as `auth-provision.ts`). Deliberately does not upsert the main `users` row from `PostConfirmation` — `auth-provision.ts`'s PreTokenGeneration trigger owns that lazy provisioning. 54/54 tests green.
  - `feature/auth-provision-trigger` branch (not yet PR'd): new standalone handler `src/handlers/auth-provision.ts` — the real Cognito PreTokenGeneration trigger body (D-077), idempotent get-or-create of org+user by `sub`, injects `custom:orgId`/`custom:role` claims. Deliberately does not import `src/config.ts` (would eagerly require unrelated env vars). CI deploys it as a second Lambda (`heediq-auth-provision`) via its own bundle/zip/`update-function-code` steps alongside the main API Lambda.
  - Critical bug fixed: `SendMessageCommand` now sets `MessageAttributes: { tier }` on transcription enqueue — without this attribute, both EventBridge Pipe filters fail and no job is ever processed.
  - D-068: route `/recordings`→`/sources`, `RECORDINGS_TABLE_NAME`→`SOURCES_TABLE_NAME`, `@heediq/shared` bumped to `0.2.0`, `labels: []` set on Source creation.

- **heediq-worker-transcription** — Python ECS worker: one RunTask = one job via SQS_MESSAGE_BODY container override (D-066). Two per-tier images (free/paid) with model weights baked in (D-062).
  README: `../../heediq-worker-transcription/README.md` · Decisions: D-047, D-059, D-062, D-065, D-066, D-068
  - PR #9, #10 merged (refactor/rename-recording-to-source-py → develop). 11 pytest tests + mypy strict. deploy.yml: two SHA-tagged images → shared-services ECR → ssm put-parameter + register-task-definition + pipes update-pipe per env.
  - Transcript written to `heediq-sources[sourceId].transcript` in DynamoDB (task role has no S3 write grant). Downstream summarization worker reads it by sourceId.
  - `src/models.py` is hand-maintained (mirrors `@heediq/shared`, not generated) — D-068 field renames applied manually.

- **heediq-worker-summarization** — Node.js Lambda: reads transcript from DynamoDB, extracts structured fields (requirements/decisions/openQuestions/actionItems) via Claude, writes back to DynamoDB. CI deploys via `lambda update-function-code`.
  README: `../../heediq-worker-summarization/README.md` · Decisions: D-032, D-038, D-043, D-065, D-067, D-068, D-084
  - PR #2, #3, #4 merged (feature/summarization-worker → develop, updated with D-068 rename; PR #4 disables pnpm minimumReleaseAge cooldown, D-084). 12 Vitest tests across 4 suites. deploy.yml: test → esbuild bundle → lambda update-function-code per env (dev/staging/prod).
  - `sourceType='text'` → contentRef IS the sourceId (reads `heediq-sources[sourceId].transcript`). Not an S3 key.

- **heediq-web** — Vite + React + TS PWA frontend; D-030 stack (TanStack Query, CVA, Radix, Vitest/RTL).
  README: `../../heediq-web/README.md` · Auth README: `src/lib/auth/README.md` · Features/auth README: `src/features/auth/README.md` · Layout README: `src/components/layout/README.md` · Decisions: D-008, D-020, D-024, D-028, D-029, D-030, D-043, D-072, D-073, D-074, D-075, D-076, D-077, D-078, D-079, D-081, D-082, D-083, D-087, D-088, D-089, D-090, D-091
  - **D-089/D-090/D-091 built (2026-07-04, not yet committed)**: new `src/features/auth/` — first
    use of the `features/` layer in this codebase — holds `VerifyAndSetPasswordForm.tsx`, the one
    shared own-verification + set-password component, reused by `HomePage` (collapsed sign-up +
    reactive-linking `verify` step, replacing the old separate signup form) and `SettingsPage`
    (renders the D-091 active-methods list read-only + inline "Set a password"). `cognito-idp.ts` no
    longer exports `signUp`/`confirmSignUp` — the OTP round trip always goes through `heediq-api`'s
    `POST /auth/link/request-otp`/`confirm` now. 95/95 tests green (23 test files).
  - D-075/D-076 (2026-07-04): full i18n coverage via `react-i18next`, `src/i18n/` — all user text incl. errors goes through `t()`/translation keys.
  - `feature/web-scaffold` is an ongoing incrementally-merged branch (PR #1, #5, #6, #7 all merged to develop) — tooling + D-008 tokens + UI kit (Button, Spinner, Card, Badge, LoadingMark, ErrorState, Input) + dev-only `/dev/ui` gallery + CI/deploy workflows, most recently the i18n aria-label fix on `ProtectedRoute` (PR #7).
  - **Unified sign-in/sign-up screen built (D-078, D-081, D-082, D-087)**: `HomePage` replaces the old plain sign-in entry — email-first, branches into sign-up/sign-in/forgot-password/reactive-linking steps, calls Cognito directly via `lib/auth/cognito-idp.ts` (see auth README). Federated-only accounts now call the real `POST /auth/link/request-otp` + `POST /auth/link/confirm` endpoints (D-087; PR #9, #10), not a forgot-password placeholder. `AuthCallbackPage` still handles the Hosted UI OAuth PKCE code exchange for SSO login.
  - **Proactive account linking built (D-079, D-083)**: `SettingsPage` (Add Google/Add Microsoft buttons) + `SettingsLinkCallbackPage` (new `/settings/link-callback` route) — see auth README for the full flow and why its tokens must never reach `applyTokens`.
  - **App shell built and merged (PR #12)**: `src/components/layout/` (`TopBar` + `AppShell`) mounted inside `ProtectedRoute` around `/sources`, `/sources/:sourceId`, `/settings` — Logout button (wired to `useAuth().logout()`) and Settings nav link, unblocking manual QA that had no way to log out or reach Settings. See `src/components/layout/README.md`. Surfaced and fixed a real bug in `Button`'s `asChild` prop (documented but never used before — crashed via Radix `Slot`'s single-child requirement whenever `loading` was falsy); see `src/components/ui/Button/README.md` Gotchas. Deployed to dev.
  - No client-side onboarding step — `custom:orgId`/`custom:role` arrive pre-baked in the token via `heediq-api`'s PreTokenGeneration trigger. `SourcesLibraryPage`/`SourceDetailPage` still placeholders, now gated behind `ProtectedRoute` + `AppShell`.
  - deploy.yml builds **per-environment** (not build-once-promote like the Lambda/Docker repos) — Vite inlines `VITE_*` env vars at build time; each env's job now also reads `/heediq/api/cognito-hosted-ui-domain` + `/heediq/api/cognito-client-id` from SSM into `VITE_COGNITO_DOMAIN`/`VITE_COGNITO_CLIENT_ID`, plus `VITE_COGNITO_REGION` for the direct IdP API calls (D-082).
  - Sources library, source detail screens (real content) still pending per D-069 build order.

<!--
- **<feature/area>** — <one-line summary>.
  README: `path/to/module/README.md` · Decisions: ../business/DECISIONS.md (D-NNN)
-->

## Cross-module gotchas
_(Facts that span multiple modules and don't belong in any single README.)_

- **CDK cross-stack export deadlock on renaming a FoundationStack resource passed by direct construct reference** — see `heediq-infra/README.md` Gotchas. Any stack renamed/replaced (table name, key schema, GSI) while another stack imports it via a direct CDK prop (not SSM) requires a two-phase deploy. Currently only `WebSocketStack.jobsTable` uses this pattern; everything else reads from SSM and is immune.

## In-progress (not yet doc-worthy)
_(Short notes on things being worked out; promote to a README or decisions doc when settled.)_
