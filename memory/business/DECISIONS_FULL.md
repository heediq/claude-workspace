# Heediq Decisions — Full Text (DECISIONS_FULL.md)

Full text for every locked decision indexed in `DECISIONS.md`. Read on demand for a specific
`D-NNN` — not part of the session-start read set. Format: `rules/09-decisions.md`.

---

## Architecture & Infrastructure

### D-001 · Full AWS serverless stack — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Build on a full AWS serverless stack: Lambda, API Gateway, Fargate Spot, DynamoDB,
S3, SQS, EventBridge, Cognito, CloudFront, Route 53, Secrets Manager, CloudWatch.
**Why:** scalability + cost profile fits Heediq's usage-spiky, mostly-async workload.
**Related:** `memory/business/architecture.md`

### D-002 · AWS CDK + GitHub Actions CI/CD — Locked (2026-06-11)
**Area:** Infra
**Decision:** IaC via AWS CDK; CI/CD via GitHub Actions.
**Related:** `memory/business/architecture.md`

### D-006 · Transcription cost optimizations — Locked (2026-06-11)
**Area:** Cost
**Decision:** Silence trimming accepted (10–30% duration reduction, safe). 2× audio speed-up
rejected (degrades word-error-rate and diarization accuracy too much).
**Related:** `memory/business/architecture.md`

### D-007 · DynamoDB-only at launch — Locked (2026-06-11)
**Area:** Architecture
**Decision:** DynamoDB only at launch; Aurora Serverless v2 deferred (possible future migration
for relational queries).
**Why:** Aurora's ~$45/mo fixed floor dominates the bill disproportionately at early scale.
**Related:** `memory/business/architecture.md`

### D-021 · Multi-tenancy — shared DB, row-level isolation — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Single shared database, row-level tenant isolation via `org_id` on every
tenant-scoped row. Query pattern: `WHERE org_id = :tenant AND (owner_user_id = :user OR :role =
'admin')`.
**Related:** `memory/business/architecture.md`

### D-022 · Data retention & audio lifecycle — Locked (2026-06-11)
**Area:** Policy
**Decision:** Free tier — audio + transcript stored 30 days, then audio deleted, transcript kept
indefinitely. Paid tier — audio stored 90 days then moved to S3 Glacier Deep Archive, transcript
indefinite. On cancellation: 30-day grace period, then full org data deletion.
**Why:** transcript text is the actual product value (cheap to retain); audio is the
expensive/bulky asset and is tiered down or archived.
**Related:** `memory/business/product.md`

---

## Brand & Design

### D-008 · Design system tokens — Locked (2026-06-11)
**Area:** Design
**Decision:** Charcoal/amber color token scale; Inter/Geist for UI (400/500 weights only);
JetBrains Mono for transcripts; 4px-base spacing scale + sm/md/lg/full radius tokens; three-state
Listen button (idle/recording/processing); inline-hint + dedicated empty states. Brand name
styled lowercase as "heediq" in UI.
**Related:** `memory/business/branding.md` (exact hex values, type scale, spacing scale, button
states, empty-state copy)

### D-009 · Brand & logo — Locked (2026-06-11)
**Area:** Brand
**Decision:** Name layers "heed" + "HQ" + "IQ"; four-slab monogram concept visually represents "HQ".
Domain: heediq.com.
**Superseded by:** D-073 (asset shape/proportions only — brand story, wordmark, tagline, color unchanged)
**Related:** `memory/business/branding.md`

### D-026 · Home / Listen screen UX — Locked (2026-06-11)
**Area:** Design
**Decision:** Home screen centers on one large "Listen" button (Shazam-style primary CTA) for
live recording. Secondary actions: upload an audio file, upload a text file (skips transcription,
straight to summary), view recordings. A subtle usage/limit indicator sits in the top bar. The
recordings library is a separate nav page, not embedded in home.
**Why:** one obvious primary action keeps the entry point simple; secondary paths cover
non-live-recording use cases without competing for attention.
**Related:** `memory/business/product.md`, `memory/business/branding.md` (button states)

---

## Product, Access & Billing

### D-017 · Account & roles model — Locked (2026-06-11)
**Area:** Product
**Decision:** Org-first account model for all users; personal users = single-seat org
(owner/admin), no separate personal account type. Admin/Member two-role concept carries forward
as D-102's seeded system roles.
**Related:** `memory/business/product.md`
**Superseded by:** D-102 (Admin/Member carried forward as seeded system roles — mechanism becomes dynamic)

### D-018 · Free-tier usage limits — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Free tier is a per-org shared usage pool with a one-way usage-decay ratchet: 1
use/day → after 3 lifetime uses, 2 uses/week → after 6 lifetime uses, 1 use/week (cumulative
lifetime count, never resets). One "use" = one transcription summarized and delivered. Exceeding
the limit triggers a soft upgrade prompt, never a hard block. Single paid plan exists alongside
free at launch.
**Why:** lets free users get real value while creating natural upgrade pressure without a
punitive cutoff.
**Related:** `memory/business/product.md`

### D-019 · Billing — Stripe, org as customer — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Stripe is the billing provider. Customer = org (not individual user); per-seat
quantity-based subscription. No card required on signup/trial; Stripe Checkout triggers only on
upgrade. Subscription state synced via Stripe webhooks.
**Related:** `memory/business/product.md`

### D-011 · Pricing principle — Locked (2026-06-11)
**Area:** Pricing
**Decision:** Flat per-seat pricing without usage caps or overage billing doesn't work at
Heediq's transcription cost structure; a fair-use meeting-cap model is preferred.
**Why:** confirmed via gross-margin math against AWS Transcribe baseline costs.
**Note:** the original supporting number ($35–40/seat/mo) predates the faster-whisper cost pivot
(D-004/D-005, ~70–75× cheaper) and should be revisited — exact packaging is still open. See
`memory/business/product.md`.

### D-020 · Auth — AWS Cognito + federated IdPs — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Authentication via AWS Cognito User Pool: email/password plus Google and Microsoft
(Entra/Azure AD) as federated identity providers, all from day one. SAML/OIDC for enterprise IdPs
explicitly deferred to later (design auth so it's addable, don't build it now). Email-domain
match on signup surfaces a "request to join" flow requiring admin approval — automatic
domain-based addition is explicitly not implemented (security).
**Related:** `memory/business/product.md`

### D-024 · Platform — mobile-first PWA — Locked (2026-06-11)
**Area:** Product
**Decision:** Heediq ships as a mobile-first, desktop-friendly installable PWA. Offline recording
supported (local capture, queued upload on reconnect; transcripts cached offline). True
lock-screen background recording is not feasible on iOS Safari; mitigated with the Screen Wake
Lock API during recording. Push notifications ("transcript ready") built at launch via Web Push
API (iOS 16.4+ for installed PWAs). Browser baseline: iOS Safari 16.4+, Android Chrome last 2,
desktop Chrome/Edge/Safari/Firefox last 2. Breakpoints: mobile <640px, tablet 640–1024px, desktop
>1024px.
**Why:** one codebase across mobile/desktop without native app-store overhead; explicit
fallback for iOS's background-audio limitation avoids overselling a capability the platform can't
deliver.
**Related:** `memory/business/product.md`

### D-025 · Paid-tier meeting bot — Locked (2026-06-11)
**Area:** Product
**Decision:** Paid tier supports an automated meeting bot via a third-party agent (e.g.
Recall.ai) with calendar OAuth integration, rather than building a custom bot in-house.
**Why:** third-party agents already solve cross-platform call-joining reliably.
**Timing:** post-MVP — paid-tier capability, not part of the first free-tier dogfood. Cross-platform
coverage (Zoom / Microsoft Teams / Google Meet) is exactly what the third-party agent provides, so
there is no per-platform bot work in-house.
**Related:** `memory/business/product.md`

---

## Process (this workspace)

### D-012 · Workspace rules & memory repo — Locked (2026-06-15)
**Area:** Process
**Decision:** Canonical repo for Claude's rules, memory, and plans (renamed to `claude-workspace`
under the `heediq` org by D-046). Root `CLAUDE.md` imports the modular rule set; memory is split
into business + codebase tracks.
**Superseded by:** D-046 (org/repo names only — canonical-repo concept and memory split unchanged)

### D-013 · GitHub as git host & CI — Locked (2026-06-15)
**Area:** Infra
**Decision:** Heediq is on GitHub; PRs via `gh`; CI via GitHub Actions.
**Supersedes:** — (consistent with D-002).

### D-014 · No Jira for now — Locked (2026-06-15)
**Area:** Process
**Decision:** No issue tracker (Jira) for Heediq dev tracking currently; may adopt later.
Branches/commits use `<type>/<short-kebab-desc>` with no issue key required.

### D-015 · Two-track memory + auto-decision-capture — Locked (2026-06-15)
**Area:** Process
**Decision:** Maintain business memory (decisions, this file) alongside codebase memory;
decisions are captured automatically and immediately when locked, per `rules/09-decisions.md`.

### D-016 · Documentation via code-level READMEs — Locked (2026-06-15)
**Area:** Process
**Decision:** Project documentation lives in `README.md` files next to the code (replacing
Confluence BD/TDD/TP/TRM). See `rules/06-documentation.md`.

---

## Infrastructure Access & Naming

### D-036 · 5-account AWS structure + SSO + OIDC (2026-06-16) — Locked
**Area:** Infra
**Decision:** Five AWS accounts under one AWS Organization:
- **Management** — org root, IAM Identity Center (SSO), consolidated billing. No workloads run here.
- **Shared services** — ECR (all container images), and future cross-environment shared infrastructure. OIDC trust for CI image push.
- **Dev / Staging / Prod** — isolated workload accounts (DynamoDB, Lambda, S3, SQS, Cognito, etc. each in their own account).

Human access via IAM Identity Center (SSO): one login URL, permission sets defined centrally (e.g. `AdministratorAccess`, `DeveloperAccess`), users assume roles per account. No IAM users or long-lived access keys.

Machine access (GitHub Actions) via OIDC: a `GitHubActionsDeployRole` IAM role in each account (workload + shared-services) with branch-scoped trust. No stored AWS credentials in GitHub Secrets — only role ARNs in workflow files. Container images are pushed to ECR in the shared-services account and promoted (by image tag) into dev → staging → prod.
**Why:** Account boundary is the blast-radius boundary; SSO eliminates credential sprawl; OIDC eliminates long-lived machine credentials. Shared-services account gives ECR a neutral home and room to grow into a platform layer without polluting workload accounts. Follows AWS Landing Zone best practice.
**Supersedes:** D-003
**Superseded by:** —
**Related code:** `heediq-infra/`

### D-037 · Resource naming — no environment prefix (2026-06-16) — Locked
**Area:** Infra
**Decision:** All AWS resources named `heediq-{entity}` with no environment prefix — e.g. `heediq-recordings`, `heediq-audio-uploads`, `heediq-transcription`. The account boundary is the environment boundary; the same name in different accounts refers to fully isolated resources. CDK stack names follow `Heediq{Service}Stack`. IAM policies use `heediq-*` wildcard to cover all resources in a given account.
**Why:** Environment prefix is redundant and noisy when accounts are isolated. Cleaner names, simpler CDK code, easier IAM policies.
**Supersedes:** — (replaces the `heediq-{env}-{entity}` pattern proposed pre-D-036)
**Superseded by:** —
**Related code:** `heediq-infra/`

### D-038 · SSM + secrets path convention (2026-06-16) — Locked
**Area:** Infra
**Decision:** SSM Parameter Store paths: `/heediq/{service}/{param}` — e.g. `/heediq/api/cognito-user-pool-id`. Secrets Manager paths: `/heediq/{service}/{secret}` — e.g. `/heediq/api/stripe-secret-key`. No environment prefix in either (account-scoped).
**Why:** Account boundary makes env prefix redundant.
**Superseded by:** D-100 (secret-fetch mechanism only — path convention unchanged)
**Related code:** `heediq-infra/`, `heediq-api/`

---

## Stack & Repos

### D-027 · `develop` integration-branch model (2026-06-16) — Locked
**Area:** Process
**Decision:** `develop` is the integration branch. All feature/fix/chore branches cut from `develop` and merge back via PR. Direct commits to `develop`, `main`, or `master` are not allowed. `heediq-workspace` is exempt — memory/plans commit straight to its default branch.
**Why:** Trunk-based integration with short-lived feature branches; keeps main always releasable.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/02-git-and-commits.md`

### D-028 · UI component stack (2026-06-16) — Locked
**Area:** Architecture / Design
**Decision:** UI built on Tailwind CSS (styling), Radix UI headless primitives (accessibility/keyboard/ARIA for complex components), and a shadcn/ui-style local component kit (templates copied into-repo and owned, not a black-box dependency).
**Why:** Radix solves accessibility correctly for dialogs, dropdowns, tooltips etc.; Tailwind enforces token-based styling per D-008; shadcn pattern means no vendor lock-in — every component line is auditable.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/03-ui-kit.md`

### D-029 · Frontend build stack (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Vite + React + TypeScript strict for the PWA frontend. React Router for client-side routing. TanStack Query for all server state (loading/error/cache). Lucide React for icons. class-variance-authority (CVA) for component variant system.
**Why:** Vite is the standard fast build tool for React PWAs; TanStack Query gives consistent loading/error/refetch behavior app-wide (required by rules/04); CVA enables the variant × size × tone system from rules/03 without prop sprawl.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/` (once scaffolded)

### D-030 · Test stack (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Vitest + React Testing Library (unit/component); Vitest + DynamoDB Local + LocalStack (integration, real services not mocks); Playwright (E2E browser); k6 (performance/load).
**Why:** Vitest is Vite-native and fast; real DynamoDB Local/LocalStack for integration avoids mock-vs-prod divergence (a known risk per rules/05); Playwright for critical journeys; k6 for transcription throughput and search surfaces.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/05-testing.md`

### D-031 · DynamoDB multi-table design (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Multi-table DynamoDB at launch — one table per service/entity domain. Migration of individual service data to Aurora Serverless v2 or RDS is explicitly kept open for when relational access patterns demand it.
**Why:** Multi-table is simpler to reason about before product shape is settled; single-table requires access pattern certainty upfront that's hard to achieve at MVP. Consistent with D-007 (DynamoDB-only at launch) while keeping the migration path open.
**Supersedes:** — **Superseded by:** —
**Related code:** —

### D-032 · Summarization/extraction model (2026-06-16) — Locked
**Area:** Architecture / Product
**Decision:** Claude API (Anthropic) as the initial LLM for transcript → structured extraction (requirements, decisions, open questions, summary). Implemented behind a provider interface so the model/vendor can be swapped without rewriting the worker.
**Why:** Claude has strong structured extraction from long-form text; provider abstraction future-proofs against model changes, cost optimization, or multi-provider routing. Closes the open item flagged in previous sessions.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-worker-summarization/` (once scaffolded)

### D-033 · REST as API style (2026-06-16) — Locked
**Area:** Architecture
**Decision:** REST over HTTP (JSON) for all frontend ↔ backend communication. Shared contract enforced via `@heediq/shared` — Zod schemas + derived TypeScript types, published as a private package and consumed by all repos.
**Why:** Natural fit for polyrepo (shared types package is necessary regardless); API Gateway HTTP API integrates natively; no TypeScript-only coupling that tRPC would impose; keeps the API surface externally consumable if needed later. tRPC rejected for polyrepo — its main benefit (automatic type sharing) requires monorepo.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`, `heediq-shared/`

### D-034 · API service runtime — Hono on Lambda (2026-06-16) — Locked
**Area:** Architecture / Infra
**Decision:** All REST API endpoints served by a single Lambda function running the Hono web framework. One deployment unit covers all domains (auth, orgs, recordings, billing) until a service shows clear reason to split (not expected before ~10k MAU).
**Why:** Hono is lightweight (~14kb), TypeScript-native, designed for Lambda + edge runtimes; single Lambda = one deployment, one log group, trivial local dev; same serverless cost model as individual Lambdas with far lower operational burden at <1000 MAU. Always-on containers (Fargate) rejected — $15–30/mo floor at zero traffic.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-035 · Polyrepo structure — 7 repos (2026-06-16) — Locked
**Area:** Architecture / Process
**Decision:** Seven repos under the `heediq` GitHub org: `claude-workspace`, `heediq-shared`,
`heediq-web`, `heediq-api`, `heediq-worker-transcription`, `heediq-worker-summarization`,
`heediq-infra`.
**Why:** Microservice-level granularity — workers split because they have different runtimes (Python vs Node) and scaling/cost profiles; shared types in own package consumed across repos; infra separated from application code. Not feature-level (too many repos) and not monorepo (polyrepo locked).
**Superseded by:** D-046 (org/repo names only — the 7-repo split itself stands)
**Related code:** github.com/heediq/

### D-039 · Dev tooling — pnpm + Node 22 LTS (2026-06-16) — Locked
**Area:** Architecture
**Decision:** pnpm as the package manager across all Node/TypeScript repos (web, api, worker-summarization, shared, infra). Node.js 22 LTS as the runtime version for all Node repos and Lambda functions.
**Why:** pnpm is faster and deduplicates packages on disk across 7 repos; strict dependency resolution avoids phantom dep bugs. Node 22 LTS is the current active LTS (supported until April 2027); Lambda supports it natively.
**Supersedes:** — **Superseded by:** —
**Related code:** all Node repos

### D-040 · `@heediq/shared` delivery via GitHub Packages (2026-06-16) — Locked
**Area:** Architecture
**Decision:** `heediq-shared` publishes `@heediq/shared` as a private npm package to GitHub Packages from day one. All other repos install it as a versioned dep. GitHub PAT (or Actions OIDC) authenticates package reads in CI.
**Why:** Polyrepo requires a published package for cross-repo consumption. `file:` path references create brittle dev-vs-CI divergence. GitHub Packages is the natural fit alongside the existing GitHub org.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/`

### D-041 · JWT auth enforcement — Hono middleware (2026-06-16) — Locked
**Area:** Architecture
**Decision:** Cognito JWT validation happens inside the Lambda via Hono middleware (JWKS-based, e.g. `hono/jwt` or `jose`), not at API Gateway. API Gateway is a plain HTTP API with no authorizer.
**Why:** Custom auth logic (role checks, org isolation enforcement, usage-ratchet) lives in the Lambda anyway; centralizing in Hono middleware means one place for all auth/authz rather than splitting between Gateway config and code. Full control over error response shape (per D-033 consistent error envelope).
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-042 · API versioning — `/api/v1/` URL prefix (2026-06-16) — Locked
**Area:** Architecture
**Decision:** All REST endpoints are prefixed `/api/v1/` from day one.
**Why:** Zero cost to add now; avoids a painful rename when a second client (native app, partner) can't be force-updated alongside a breaking API change.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/`

### D-043 · CI/CD pipeline structure (2026-06-16) — Locked
**Area:** Infra / Process
**Decision:** Consistent GitHub Actions pattern across all repos:
- **PR** → typecheck + unit tests only (no AWS calls).
- **Merge to `develop`** → assume `GitHubActionsDeployRole` in dev account → deploy to dev.
- **Merge to `main`** → assume role in staging → deploy to staging; manual approval job → assume role in prod → deploy to prod.
- Container images (Fargate workers) push to ECR in the shared-services account first, then ECS deploy in the target workload account.
- `heediq-infra` deploys shared resources (DynamoDB tables, SQS, S3, Cognito) first; app repo workflows deploy only their Lambda/ECS service on top of existing infra. Infra changes are applied before app deploys via workflow dependency or ordering convention.
**Why:** Keeps credentials out of GitHub Secrets (OIDC only); consistent pattern is copy-pasteable across repos; infra-before-app ordering prevents deploy-time resource-not-found errors.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`, all app repos `.github/workflows/`

### D-044 · Primary AWS region — eu-west-1 Ireland (2026-06-17) — Locked
**Area:** Infra
**Decision:** `eu-west-1` (Ireland) is the primary AWS region for all Heediq infrastructure.
**Why:** Most complete service catalog and lowest cost in Europe; strong Fargate Spot capacity; standard choice for EU SaaS startups targeting UK/EU markets. Frankfurt rejected — no DACH enterprise data-residency requirement at this stage. US expansion would add `us-east-1` as a second region later.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-045 · AWS account IDs + local CLI profiles (2026-06-17) — Locked
**Area:** Infra
**Decision:** Four AWS workload accounts with these IDs and local CLI profile names:
- shared-services: `313828097088` — profile `heediq-shared`
- dev: `276594885933` — profile `heediq-dev`
- staging: `475790160542` — profile `heediq-staging`
- prod: `438825592314` — profile `heediq-prod`

Management account has no local profile (used only for org/billing via SSO console).
**Why:** Canonical reference for scripts, CDK, and disaster recovery. Account boundary = environment boundary per D-036/D-037.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/scripts/setup.sh`, `heediq-infra/`

---

### D-046 · GitHub org rename + workspace repo rename (2026-06-17) — Locked
**Area:** Process / Infra
**Decision:** GitHub org renamed from `admin-heediq` to `heediq`. Workspace repo renamed from `heediq-workspace` to `claude-workspace`. All 7 repos now live under `github.com/heediq/`. Remote: `git@github-heediq:heediq/claude-workspace.git`.
**Why:** cleaner org name; workspace repo name reflects its actual content (Claude workspace config) rather than the product name.
**Supersedes:** D-012, D-035 (org/repo references only; polyrepo structure unchanged)
**Superseded by:** —
**Related code:** `claude-workspace/`

### D-047 · Release versioning strategy (2026-06-17) — Locked
**Area:** Infra / Process
**Decision:** Services (`heediq-api`, `heediq-web`, workers) use git SHA as the version identifier — Docker images tagged `sha-<7chars>`, Lambda deploys tracked by the same SHA. No semver for services at MVP. `@heediq/shared` uses semver from day one (starts at `0.1.0`; graduates to `1.0.0` when the contract stabilises). Docker images built once on `develop` CI, pushed to ECR with the SHA tag, and promoted to staging/prod by updating the ECS task definition — never rebuilt per environment.
**Why:** Services are deployed not consumed, so semver adds overhead with no benefit at MVP. `@heediq/shared` is a published package with multiple consumers, so semver is required for safe dependency pinning. Build-once/promote prevents environment drift.
**Supersedes:** — **Superseded by:** —
**Related code:** all repos `.github/workflows/`, `heediq-shared/`

### D-048 · Renovate for @heediq/shared dependency updates (2026-06-17) — Locked
**Area:** Process
**Decision:** Renovate is configured on all consuming repos (`heediq-api`, `heediq-web`, `heediq-worker-summarization`). When `@heediq/shared` publishes a new version to GitHub Packages, Renovate automatically opens a PR in each consuming repo to bump the dependency. Teams merge when ready.
**Why:** Avoids manual drift where consuming repos fall behind on shared type updates without anyone noticing. Renovate is better than Dependabot for private GitHub Packages in a monorepo-adjacent setup.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/`, consuming repos `renovate.json`

### D-049 · Hotfix flow (2026-06-17) — Locked
**Area:** Process
**Decision:** Hotfixes branch from `main` (`hotfix/xxx`), get a PR directly to `main`, auto-deploy to staging, manual gate to prod. Immediately after merging to prod, open a follow-up PR to merge `main` back into `develop`. Never leave `main` and `develop` diverged after a hotfix.
**Why:** Cutting from `main` ensures the fix targets exactly what's in prod, not unreleased develop work. Mandatory back-merge prevents the fix being silently lost on the next develop → main promotion.
**Supersedes:** — **Superseded by:** —
**Related code:** `rules/02-git-and-commits.md`

### D-050 · Infra-first deployment convention (2026-06-17) — Locked
**Area:** Process / Infra
**Decision:** When a change adds new AWS resources (table, queue, bucket, Cognito config), `heediq-infra` is merged and deployed first; app repos follow after infra deploy succeeds. App repos reference resource names/ARNs via SSM params (per D-038), never hardcoded. This is a process convention enforced by team discipline, not by CI automation at MVP.
**Why:** Prevents deploy-time resource-not-found errors. SSM param indirection means app code never needs to know the exact ARN at build time.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`, `rules/02-git-and-commits.md`

---

### D-051 · DNS — Route 53 hosted zone in shared-services account (2026-06-17) — Locked
**Area:** Infra
**Decision:** The Route 53 public hosted zone for `heediq.com` lives in the shared-services account (`313828097088`). Management account retains minimal footprint (SSO + billing only).
**Why:** Shared-services is already the cross-environment hub (ECR, future shared infra); DNS belongs there rather than polluting the management account with workload-level resources.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-052 · Subdomain structure per environment (2026-06-17) — Locked
**Area:** Infra
**Decision:** Environment prefix on all non-prod subdomains; prod sits on the root domain. All subdomains are single-level to stay within the wildcard cert coverage:
- Prod: `heediq.com` (web), `api.heediq.com` (API)
- Staging: `staging.heediq.com` (web), `api-staging.heediq.com` (API)
- Dev: `dev.heediq.com` (web), `api-dev.heediq.com` (API)
**Why:** Single-level subdomains are all covered by `*.heediq.com`; two-level subdomains (e.g. `api.staging.heediq.com`) would require additional wildcard certs per environment.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-053 · ACM certificate strategy (2026-06-17) — Locked
**Area:** Infra
**Decision:** Two wildcard ACM certificates, both covering `heediq.com` + `*.heediq.com`:
- `us-east-1` — used by CloudFront (required by AWS; all CloudFront certs must be in us-east-1)
- `eu-west-1` — used by API Gateway regional endpoint (cert must be co-located with the endpoint)
DNS validation via Route 53 (D-051). No per-subdomain certs unless a specific requirement arises.
**Why:** Single wildcard per region covers all current and future subdomains (D-052) without managing individual certs. Wildcard in both regions needed because CloudFront and API Gateway require certs in different regions.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/`

### D-054 · Transactional email via Amazon SES (2026-06-17) — Locked
**Area:** Architecture / Infra
**Decision:** Amazon SES in `eu-west-1` for all transactional email (auth flows, notifications). Domain verified on `heediq.com`; sending address `noreply@heediq.com`. DKIM, SPF, and DMARC configured at domain verification. SES sandbox exit requested before launch.
**Why:** Native AWS service — same account/region as the rest of the stack, CDK-manageable, cheapest at scale ($0.10/1000 emails). Third-party providers (Resend, Postmark) rejected to avoid an extra vendor dependency given existing AWS commitment.
**Superseded by:** D-058 (identity placement only — choice of SES, region, domain, DKIM/SPF/DMARC unchanged)
**Related code:** `heediq-infra/`

---

### D-058 · SES identity in shared-services account; cross-account role for workload sending (2026-06-19) — Locked
**Area:** Architecture / Infra
**Decision:** The `heediq.com` SES email identity lives in the shared-services account (alongside Route 53). DKIM CNAME records are created in the same CDK stack with no cross-stack dependency. Workload account Lambdas send email by assuming IAM role `heediq-ses-email-sending` (in shared-services account). Role ARN exported to workload accounts via SSM at `/heediq/api/ses-sending-role-arn`.
**Why:** Avoids SharedServicesStack depending on FoundationStack outputs (reverse dependency). SES identity and its DNS records are self-contained in the one account that owns Route 53 — simpler, no two-step deploy dance. Cross-account role assumption is standard IAM; no SES-specific policy quirks.
**Supersedes:** D-054 (extends — D-054's choice of SES still stands; this locks the placement)
**Superseded by:** D-095 (Cognito OTP email only — adds a per-workload-account SES identity for Cognito's native confirmation emails; cross-account role for app-initiated Lambda sends is otherwise unchanged)
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`, `heediq-infra/lib/foundation/foundation-stack.ts`

---

### D-055 · Compute resource sizing at launch (2026-06-17) — Locked
**Area:** Infra / Cost
**Decision:** All environments (dev/staging/prod) start at identical minimum viable resource settings. Scale up when real traffic demands it — no environment differentiation at launch.
- **Lambda — API (Hono, D-034)**: 512 MB, 30s timeout
- **Lambda — summarization worker (D-032)**: 512 MB, 5 min timeout
- **DynamoDB**: `PAY_PER_REQUEST` (on-demand) in all environments — no baseline cost, auto-scales, right for zero-to-low traffic
- **CloudFront price class**: `PriceClass_100` (US + EU edge locations) — fits EU SaaS target market; ~40% cheaper than all-regions
**Why:** No production traffic to justify larger sizing at launch. All settings are reversible CDK config values — scale up when metrics show need.
**Superseded by:** D-059 (transcription compute sizing only — Lambda/DynamoDB/CloudFront sizing above unchanged)
**Related code:** `heediq-infra/`

### D-057 · Business email — Zoho EU (2026-06-19) — Locked
**Area:** Infra
**Decision:** Team email (`@heediq.com` inboxes) hosted on Zoho Mail EU datacenter. DNS records (MX, SPF, DMARC, DKIM) managed in `SharedServicesStack` as Route 53 record constructs — version-controlled, deployed via CI.
**Why:** Separate from SES transactional email (D-054); Zoho EU keeps data in EU. Managing DNS in CDK means records survive hosted zone recreation and are auditable in git.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`

### D-056 · Dev account budgets — $50/month via management account CLI script (2026-06-18) — Locked
**Area:** Infra / Cost
**Decision:** $50/month monthly cost budget for the dev account (`276594885933`), created in the management account with a `LinkedAccount` filter. Split into two budgets (ACTUAL + FORECASTED) due to AWS's 10-notification-per-budget limit. Thresholds: 1, 10, 25, 50, 70, 85, 95% of budget — email alerts to `andriiperevoznyi@gmail.com`. Block at 100% via SCP Budget Action not yet automated (manual console setup documented in script header). Management account local SSO profile: `heediq-management`. No CDK/CloudFormation — provisioned via `heediq-infra/scripts/setup-budgets.sh` to keep management account free of CDK bootstrap (D-036).
**Why:** Management account must stay minimal (D-036). CLI script is reproducible and version-controlled without bootstrap overhead. Staging/prod budgets added later as separate linked-account budget entries when those accounts see real traffic.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/scripts/setup-budgets.sh`

---

### D-059 · EC2 GPU Spot compute for transcription (2026-06-23) — Locked
**Area:** Infra / Cost
**Decision:** Both transcription model variants (whisper small and large-v3+pyannote) run on EC2 Spot using g4dn.xlarge (T4, 16 GB VRAM, 4 vCPU, 16 GB RAM, ~$0.13–0.16/hr Spot in eu-west-1). Single instance type, single ASG (min=0, capacity-optimized), single ECS cluster — no separate pools per model. Replaces Fargate Spot task definitions with an EC2 capacity provider backed by an Auto Scaling Group. Zero idle cost preserved (ASG scales to zero when queue empty). Cold start ~45–90s accepted for async batch. AMI: AWS ECS-optimized GPU AMI (Docker + ECS agent + nvidia-container-toolkit pre-configured). g4dn.xlarge is the smallest CUDA GPU instance on AWS — no smaller option exists. (Spot-interruption retry mechanism corrected by D-066.)
**Why:** 10× faster transcription (1–2 min whisper small, 3–5 min large-v3 vs 15–20/30–60 min on Fargate CPU). Per-meeting cost drops ~50%+: whisper small ~$0.003, large-v3 ~$0.010 per 60-min meeting (vs ~$0.006/$0.035 on Fargate CPU Spot). Single pool simplifies infra; free/paid job mixing causes no contention at MVP volumes.
**Supersedes:** D-004 (Fargate Spot → EC2 GPU Spot; self-hosted faster-whisper and SQS unchanged), D-055 (transcription Fargate sizing lines only; Lambda/DynamoDB/CloudFront unchanged)
**Superseded by:** D-066 (retry mechanism only — GPU compute choice, cost numbers, instance type unchanged)
**Related code:** `heediq-infra/lib/transcription/transcription-stack.ts`, `heediq-infra/lib/config.ts`

### D-060 · Model access control at API layer, not infra routing (2026-06-23) — Locked
**Area:** Product / Architecture
**Decision:** Which model runs for a job is enforced at the API enqueue endpoint — not by giving free and paid users physically separate, differently-secured infra. The API rejects job requests specifying a model the caller's tier isn't allowed (free → small only; paid may choose large-v3 + pyannote diarization). Same ECS cluster, single g4dn.xlarge Spot ASG, serves all jobs; routing to the correct task definition is a mechanical consequence of the API's tier decision (carried via the SQS message's `tier` attribute → EventBridge Pipe filter), not a separate enforcement boundary. Chunked parallel processing for the paid tier (a CPU-era latency optimisation from D-005) is dropped — unnecessary at GPU speeds (3–5 min total).
**Why:** Access control belongs at the API boundary, not baked into infra routing. Single cluster/pool is simpler to operate at MVP scale. Decoupling access from infra means adding a third model variant requires only API logic changes, no infra change.
**Mechanism correction (2026-06-30):** originally stated "the TIER env var in the container controls which model loads" — superseded by D-062's "two images" (one per tier, model baked in at build time, no runtime switch). Each tier's task definition now points at its own image (`heediq-worker-transcription:free` / `:paid`); no `TIER` env var.
**Supersedes:** D-005 (mechanism: CPU routing → API access control; model assignments free=small / paid=large-v3+pyannote unchanged)
**Superseded by:** —
**Related code:** `heediq-api/` (job enqueue endpoint), `heediq-infra/lib/transcription/transcription-stack.ts`

### D-061 · Real-time job status via API Gateway WebSocket (2026-06-23) — Locked
**Area:** Architecture / Product
**Decision:** Job status is pushed to the client via API Gateway WebSocket, not polling. A new `HeediqWebSocketStack` owns: WebSocket API Gateway, connection management Lambda ($connect/$disconnect), and Status Pusher Lambda (triggered by DDB Streams on `heediq-jobs`, pushes to active connections). A new `heediq-ws-connections` DynamoDB table (in FoundationStack) stores active connection IDs keyed by connectionId with a GSI on recordingId. Workers write status stages to `heediq-jobs`; the pusher Lambda propagates each change to connected clients. Status stages: `queued → starting → transcribing → diarizing (large-v3 only) → summarizing → done / failed`. `starting` is written by the worker as its first DynamoDB update after receiving the SQS message (before model load) — making EC2 cold-start latency visible as "Transcription server starting…". New subdomains: `ws.heediq.com` / `ws-staging.heediq.com` / `ws-dev.heediq.com` — covered by existing `*.heediq.com` wildcard cert (D-053). The upload flow (S3 presigned URL), SQS queue, EventBridge Pipes → ECS RunTask, and DynamoDB job status writes all remain unchanged from D-023.
**Why:** Real-time status transparency is a product quality differentiator for a product users actively wait on. DDB Streams → pusher Lambda is the standard serverless WebSocket fan-out pattern — no always-on process. `starting` surfacing EC2 cold start is uniquely honest and trust-building UX.
**Supersedes:** D-023 (client polling → WebSocket push; upload/SQS/EventBridge/ECS flow unchanged)
**Superseded by:** —
**Related code:** `heediq-infra/lib/websocket/websocket-stack.ts` (new), `heediq-infra/lib/foundation/foundation-stack.ts`

### D-063 · Per-workload-account ACM wildcard cert (eu-west-1) in FoundationStack (2026-06-25) — Locked
**Area:** Infra
**Decision:** Each workload account (dev/staging/prod) creates its own `*.heediq.com` ACM wildcard cert in `eu-west-1` via `FoundationStack.wildcardCert`. This cert is passed directly as a CDK prop to `WebSocketStack` and `ApiStack`. The shared-services account cert cannot be used — API Gateway and WebSocket APIs reject cross-account ACM cert references (CloudFormation error at deploy time).
**Why:** Discovered during WebSocket stack deployment. ACM cross-account restriction is absolute for API Gateway regional endpoints. Cert ARN stored in SSM `/heediq/infra/cert-arn-eu-west-1` in each workload account. ACM generates a unique validation CNAME per cert request (not per domain) — the workload cert's CNAME must be manually added to Route 53 in shared-services on first deploy for each environment (one-time; ACM auto-renews).
**Supersedes:** — (clarifies D-053 placement; D-053 wildcard scope and two-region strategy unchanged)
**Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts` (wildcardCert), `heediq-infra/README.md` (Domains section)

### D-064 · heediq-route53-dns-manager cross-account IAM role (2026-06-25) — Locked
**Area:** Infra
**Decision:** IAM role `heediq-route53-dns-manager` in shared-services account trusts workload accounts (dev/staging/prod) to call `route53:ChangeResourceRecordSets + ListResourceRecordSets + GetChange` on the `heediq.com` hosted zone (Z0875312RP7WHSNW7AUM) only. Role ARN stored in SSM `/heediq/shared/route53-dns-manager-role-arn`.
**Why:** Route 53 is in shared-services; workload accounts need to write DNS records for their own subdomains (cert validation CNAMEs + A-alias records for ws/api/web custom domains). Cross-account IAM role assumption is the standard pattern. Role is the foundational piece; CDK custom resource Lambdas that assume it are the next PR.
**Supersedes:** —
**Superseded by:** —
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`

### D-062 · Whisper + pyannote models baked into Docker image (2026-06-25) — Locked
**Area:** Infra / Cost
**Decision:** faster-whisper model weights and pyannote diarization models are downloaded at Docker build time and embedded in the ECR image — not downloaded at container startup. Two images: one per tier (`small` for free, `large-v3` + pyannote for paid), built in `heediq-worker-transcription` CI and pushed to ECR in the shared-services account.
**Why:** Runtime download from HuggingFace adds 30–60s (small) or 2–5 min (large-v3 + pyannote) to cold start, plus internet egress cost. ECR pull within AWS (same region, S3-backed) is fast (~2–40s depending on image size) and free. Baking models in preserves the D-059 cold-start estimate of ~45–90s and per-meeting cost numbers.
**Supersedes:** —  **Superseded by:** —
**Related code:** `heediq-worker-transcription/` Dockerfile + CI

### D-065 · SummarizationStack trigger — SQS queue, source-agnostic (2026-06-25) — Locked
**Area:** Architecture / Infra
**Decision:** `HeediqSummarizationStack` creates an SQS queue `heediq-summarization` (+ DLQ) as the single entry point for all summarization requests. All content sources enqueue to this queue: transcription worker (audio, after faster-whisper completes) and API Lambda (text files, PDFs, emails, Excel, and any future source — skip-transcription paths). Queue message payload carries `sourceType` + `contentRef` (S3 path or inline). Queue URL/ARN published to SSM (`/heediq/summarization/queue-url`, `/heediq/summarization/queue-arn`). Transcription task role and API Lambda role each get `sqs:SendMessage` on the queue. Summarization Lambda polls the queue as its event source.
**Why:** DDB Streams on `heediq-jobs` only works cleanly for the audio path (transcription worker writes the trigger status). Multi-source summarization (text files already in D-026; emails, PDFs, Excel are natural extensions) needs a source-agnostic handoff. SQS gives one typed entry point regardless of how content arrived. Matches D-032's provider-interface design: swappable per source type, not just per model.
**Supersedes:** —         **Superseded by:** —
**Related code:** `heediq-infra/lib/summarization/summarization-stack.ts`

### D-066 · Transcription Spot-interruption retry — explicit SQS re-enqueue, not visibility timeout (2026-06-30) — Locked
**Area:** Architecture / Infra
**Decision:** On SIGTERM (Spot reclamation), the transcription worker writes `status=retrying` to `heediq-jobs` and explicitly re-sends the original `TranscriptionJobMessage` to the `heediq-transcription` SQS queue (same `tier` message attribute, so the EventBridge Pipe's filter re-routes it to the correct task definition) before exiting. The transcription task role is granted `sqs:SendMessage` on `heediq-transcription` (previously only granted on `heediq-summarization`).
**Why:** D-059's original retry text ("lets SQS visibility timeout expire and re-enqueue") assumed the worker itself was the SQS consumer. The actual deployed architecture uses EventBridge Pipes as the SQS consumer (D-023) — Pipes deletes the message from the queue as soon as it hands the job to ECS `RunTask`, before the worker container even starts. By the time a worker could catch SIGTERM, there is no visibility timeout left to expire. Explicit re-enqueue is the correct equivalent under the Pipes/RunTask (one-task-per-job) architecture.
**Supersedes:** D-059 (retry mechanism only — GPU compute choice, cost numbers, instance type, zero-idle-cost ASG design all unchanged)
**Superseded by:** —
**Related code:** `heediq-worker-transcription/src/worker.py`, `heediq-infra/lib/transcription/transcription-stack.ts`

### D-067 · Summarization model selection by tier — Haiku (free) / Sonnet (paid) (2026-07-01) — Locked
**Area:** Cost / Architecture
**Decision:** The summarization worker selects the Claude model based on the org's `tier` field carried in the `SummarizationJobMessage`: `free → claude-haiku-4-5-20251001`, `paid → claude-sonnet-4-6`. `tier` is added to `SummarizationJobMessageSchema` in `@heediq/shared` (mirroring `TranscriptionJobMessage`). The transcription worker passes `job.tier` when enqueuing the summarization message. Model is passed to `ClaudeProvider` at instantiation rather than hardcoded.
**Why:** Mirrors the transcription tier model pattern (D-059: small/large-v3). Haiku is dramatically cheaper for free-tier jobs (~10–20× vs Sonnet); Sonnet provides higher extraction quality for paid users. Provider interface (D-032) already supports swapping the model without rewriting the worker.
**Supersedes:** —         **Superseded by:** —
**Related code:** `heediq-shared/src/messages.ts`, `heediq-worker-summarization/src/handler.ts` (`MODELS` map + selection), `heediq-worker-summarization/src/provider.ts` (consumes the resolved model), `heediq-worker-transcription/src/models.py`

### D-068 · Generic entity naming — Source / Container / multi-label (2026-07-02) — Locked
**Area:** Architecture
**Decision:** Rename the core "recording" entity to **Source** (table `heediq-sources`,
`sourceId`) — any ingested unit (audio, PDF, doc, image, pasted text), not just audio. Introduce a
generic, self-nesting container entity (`containerId`, self-referencing `parentContainerId`) so
project/epic/story (or any depth) needs no separate tables per level — since renamed to Context
(D-129) and changed to one Context per Source (D-128). A Source carries a `labels: string[]`
field for free-form multi-label tagging.
**Why:** Supports the long-term universal-memory platform vision (`product.md`) without a costly
rename later once real data and more consumers exist. "Source" reads naturally as ingestion
input regardless of type.
**Superseded by:** D-129 (Container→Context naming), D-128 (multi-attach → one-per-source) — Source rename, self-nesting, and `labels[]` unchanged and still load-bearing.
**Related code:** `heediq-shared/src/`, `heediq-infra/lib/foundation/foundation-stack.ts`,
`heediq-api/`, `heediq-worker-transcription/`, `heediq-worker-summarization/`, `heediq-web/`

### D-070 · AWS region resolved from GitHub org-level variable, not hardcoded per repo (2026-07-03) — Locked
**Area:** Infra / Process
**Decision:** CI workflows resolve the AWS region from the GitHub organization-level Actions variable `vars.AWS_REGION`, not a hardcoded `eu-west-1` string duplicated in each repo's `deploy.yml`. Applies going forward to all repos' workflow files.
**Why:** All 5+ repos' `deploy.yml` files hardcoded the identical `AWS_REGION: eu-west-1` string — a single source of truth avoids a multi-repo edit if the primary region (D-044) ever changes.
**Supersedes:** — **Superseded by:** —
**Related code:** all repos' `.github/workflows/deploy.yml` (heediq-web updated first; other repos to be migrated as a follow-up, not blocking)

### D-071 · Deploy role ARNs resolved from GitHub org-level variables, not hardcoded per repo (2026-07-03) — Locked
**Area:** Infra / Process
**Decision:** CI workflows resolve `role-to-assume` for `configure-aws-credentials` from GitHub organization-level Actions variables, not hardcoded ARN strings duplicated per repo: `vars.AWS_DEPLOY_ROLE_DEV` (dev, `276594885933`), `vars.AWS_DEPLOY_ROLE_STAGING` (staging, `475790160542`), `vars.AWS_DEPLOY_ROLE_PROD` (prod, `438825592314`), `vars.AWS_DEPLOY_ROLE_SHARED` (shared-services `GitHubActionsDeployRole`, `313828097088`), `vars.AWS_ECR_ROLE` (shared-services `GitHubActionsECRRole`, `313828097088`).
**Why:** Same rationale as D-070 — the same account-scoped role ARNs were duplicated across every repo's `deploy.yml`; a single org-level source of truth means a role rename/rotation is a one-place edit instead of a multi-repo hunt.
**Supersedes:** — **Superseded by:** —
**Related code:** all repos' `.github/workflows/deploy*.yml`

### D-072 · Status/semantic color tokens (2026-07-04) — Locked
**Area:** Design
**Decision:** Lock `success` `#7FCB9C` text / `rgba(90,168,120,0.16)` bg / `rgba(90,168,120,0.32)` border (done state); `danger` `#E68A80` text / `rgba(214,90,80,0.16)` bg / `rgba(214,90,80,0.32)` border (failed state); in-progress/active states (queued, starting, transcribing, diarizing, summarizing) use the existing `accent` token, not a separate color. The placeholder `warning`/`info` tokens are dropped — no current design calls for them.
**Why:** The `design_handoff_heediq_brand` style guide flagged these as provisional; these are the exact values from that source-of-truth file, replacing guesses in `heediq-web`'s `tokens.css`.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/styles/tokens.css`, `heediq-web/tailwind.config.ts`

### D-073 · Final logo assets supersede D-009 placeholder SVG (2026-07-04) — Locked
**Area:** Brand
**Decision:** `heediq-logo.png` (composed mark), `heediq-badge-bg.svg` (badge shape), `heediq-stubs.svg` (four-bar mark, bevel filter, flat `#F0A93B` fill) from `design_handoff_heediq_brand/assets/` are the final logo assets, copied verbatim into `heediq-web/public/brand/`. These are the source of truth for shape/proportions going forward.
**Why:** The handoff shipped final, more refined assets with different bar shape/proportions than D-009's inline placeholder SVG (same color family and monogram concept). The placeholder was always marked "reproduce verbatim" pending final art — this is that final art.
**Supersedes:** D-009 (asset shape/proportions only — brand story, wordmark, tagline, color unchanged)
**Superseded by:** —
**Related code:** `heediq-web/public/brand/`, `memory/business/branding.md`

### D-074 · Animated 4-bar loading mark component (2026-07-04) — Locked
**Area:** Design
**Decision:** A new `LoadingMark` UI-kit primitive — an animated, logo-derived 4-bar SVG (keyframes `heediqRotate`/`heediqEarLeft`/`heediqEarRight`/`heediqFace1`/`heediqFace2`, 5.5s ease-in-out loop, base tilt -12deg, static fallback under `prefers-reduced-motion`) — is the canonical loading indicator for page-level and section-level async waits (`04-loading-and-feedback.md` §2–3). It does not replace `Spinner`, which remains for inline/button-level loading (§4). Two visual variants: flat `accent` fill (small/inline contexts) and a two-tone `linearGradient` (`#FFC876`→`#E89A26`, a decorative one-off scoped to this component, not a promoted design token) for larger/card contexts. Exact keyframe values and SVG bar geometry are copied verbatim from `Heediq Style Guide.dc.html`.
**Why:** Replaces a generic spinner for page/section transitions with an on-brand, motion-considered mark; the handoff's own style guide names this file as the source of truth for exact CSS.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/components/ui/LoadingMark/`

---

### D-075 · Full i18n coverage in heediq-web — all user-facing text, including errors (2026-07-04) — Locked
**Area:** Architecture / Product
**Decision:** `heediq-web` routes every piece of user-facing text — labels, copy, empty states, toasts, and **error messages** (client-side validation, API/structured-error mappings per `07-engineering-standards.md` §3, network/timeout failures) — through an i18n solution from the start, rather than hardcoding English strings in components and retrofitting later. No user-facing string is written directly in JSX/TS; it is a translation key resolved through the i18n layer. Applies going forward to all new `heediq-web` code; existing scaffold strings (Button/Spinner/Card, placeholder routes) get migrated as part of adopting the library.
**Why:** Andrii wants the app translatable at any point without a costly retrofit; errors are historically the easiest category to leave hardcoded (thrown/caught ad hoc) and the hardest to retrofit later since they're scattered across API-error mapping, form validation, and catch blocks. Locking the *coverage scope* (100%, including errors) now — before more screens are built — means the pattern is established from the first real feature.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/README.md` (once the i18n library/setup is added), `heediq-web/src/`

### D-076 · i18n library — react-i18next (2026-07-04) — Locked
**Area:** Architecture
**Decision:** `heediq-web` uses `react-i18next` (+ `i18next` core) as the i18n library implementing D-075's full-coverage scope. A single default namespace (`src/i18n/locales/en/translation.json`) holds all keys, nested by screen/module (`home.*`, `sourcesLibrary.*`, `errors.*`, `common.*`); split into per-feature namespaces later only if the file grows unwieldy. `src/i18n/config.ts` initializes synchronously (bundled resources, no lazy backend) so `t()` works both inside React (`useTranslation`) and in plain modules (`api-client.ts` error messages) without a loading gap.
**Why:** Most mature React i18n solution, native Vite compatibility (no extra build plugin), trivial to unit-test with Vitest/RTL (resources are bundled, not fetched), and supports non-hook `t()` calls needed for error messages thrown outside components. `react-intl` (heavier ICU API) and `@lingui/react` (needs a macro/build step) were considered and rejected as unnecessary tooling weight for the current scope.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/i18n/`, `heediq-web/README.md`

### D-077 · Org creation on first login via a single Cognito PreTokenGeneration trigger (2026-07-04) — Locked
**Area:** Architecture
**Decision:** Org + User row creation on first login (D-020's "org creation on first login") is implemented as **one** Cognito Lambda trigger on the User Pool in `heediq-infra`'s FoundationStack — **PreTokenGeneration**. On every token issuance it does an idempotent get-or-create: reads `heediq-users` by the token's `sub`; if absent, creates the `heediq-orgs` + `heediq-users` DynamoDB rows (email-domain match against the `by-email-domain` GSI surfaces a "request to join" pending-approval row per D-020 rather than auto-joining an existing org), then injects `custom:orgId`/`custom:role` into the token from the (just-created or existing) User row. `heediq-web`'s Auth screen needs no special first-login branch: `GET /me` works immediately after the OAuth callback token exchange, with no client-driven onboarding POST or manual token-refresh dance. **PostConfirmation was considered and rejected**: it only fires for native email/password signup, never for federated (Google/Microsoft) logins — D-020's primary path — so it would leave federated users without an org.
**Why:** A single trigger that fires uniformly for every auth flow (email/password, Google, Microsoft) is simpler and has no gap; PreTokenGeneration is the only trigger guaranteed to fire on every login regardless of IdP. Keeps org/claim provisioning atomic with the identity event Cognito already fires, instead of a client-orchestrated "call /me, 404, show onboarding form, create org via API, force refresh" flow.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts` (trigger not yet built — this session's follow-up), `heediq-api/src/middleware/auth.ts`, `heediq-web/README.md`

### D-078 · Email is the one true identity — cross-provider account linking model (2026-07-04) — Locked
**Area:** Architecture / Product
**Decision:** Email is the canonical, unique identity across every sign-in method (native password, Google, Microsoft) — never "one account per provider." `heediq-users` gains a `by-email` GSI (email lowercased/trimmed before every write and lookup) as the source of truth for "does this email exist, and does it have a password" (a `passwordSet` boolean we maintain ourselves, since Cognito's `InitiateAuth` returns the same generic error for "wrong password" and "no password set on this federated-only user"). The unified sign-in/sign-up screen is email-first: submit email → look it up → branch to sign-up (not found), sign-in (found, `passwordSet=true`), or a **generic, non-disclosing** linking prompt (found, `passwordSet=false`): "This email uses a different sign-in method — check your email to set a password," never naming the provider. (Linking-code delivery mechanism superseded by D-087 — see there.) The equivalent flow for linking a second federated provider calls `AdminLinkProviderForUser`. Native-account-gets-federated-login-added is handled by Cognito's built-in "attributes for linking federated users" = `email` setting — no custom code needed.
**Why:** Reactive, email-first linking prevents a user unknowingly creating a second, disconnected account with the same email. Staying generic about which provider is already linked avoids handing an unauthenticated caller a provider fingerprint for a given email.
**Superseded by:** D-087 (linking-code delivery mechanism only — identity model, GSI, `passwordSet`, generic prompt unchanged)
**Related code:** `heediq-api/src/handlers/auth-*.ts` (not yet built), `heediq-web/src/routes/AuthPage.tsx` (not yet built), `heediq-infra` FoundationStack (User Pool "attributes for linking federated users" setting)

### D-079 · Account linking is available both reactively (login-time) and proactively (Settings) (2026-07-04) — Locked
**Area:** Product
**Decision:** The linking flow from D-078 is built with two entry points from the start: (1) reactive — triggered automatically when a login attempt hits an existing email with a different credential type, and (2) proactive — an "Add a sign-in method" action in Account Settings for an already-authenticated user who wants to add Google/Microsoft/password to their account ahead of any conflict. Both call the same underlying API (verify email ownership → `AdminSetUserPassword` or `AdminLinkProviderForUser`).
**Why:** Andrii asked for both; building the Settings entry point alongside the login-time one exercises the same API from two call sites immediately, rather than risking the reactive-only path baking in assumptions that don't generalize.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/routes/SettingsPage.tsx` (not yet built), same API as D-078

### D-081 · No separate marketing/landing page — "/" is always the sign-in/sign-up screen (2026-07-04) — Locked
**Area:** Product
**Decision:** For the MVP, `heediq-web` has no distinct public marketing/landing page. The root route (`/`) is always the unified sign-in/sign-up screen from D-078; every unauthenticated user hitting any route is redirected there (already the `ProtectedRoute` behavior for `/sources` and `/sources/:sourceId`, per the Auth screen build).
**Why:** Simplest routing for an MVP with no marketing site yet; avoids building a landing page and a separate `/login` route for content that doesn't exist. Revisit once there's an actual marketing page to build.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/App.tsx`, `heediq-web/src/routes/HomePage.tsx`

### D-082 · Auth flows are client-direct-to-Cognito; backend owns only lookup-email + link/confirm (2026-07-04) — Locked
**Area:** Architecture
**Decision:** Native sign-in (`InitiateAuth` USER_PASSWORD_AUTH) calls Cognito **directly from the browser** — a public Cognito API needing only the User Pool Client ID, no IAM credentials, no backend code. This matches the app's existing Hosted-UI OAuth pattern. (Native sign-up no longer follows this client-direct pattern — see D-089; the linking-OTP path was separately corrected by D-087.) Backend-only endpoints: `POST /auth/lookup-email` (needs our own DynamoDB `by-email` GSI, which Cognito has no concept of) and the D-078 account-linking endpoints (D-087). `AdminLinkProviderForUser` (D-079's proactive Settings linking) also stays backend-only since it's an Admin API requiring IAM credentials the browser can never hold.
**Why:** Andrii wants maximum use of Cognito's own APIs and minimum custom backend code — backend code is added only where something is architecturally impossible client-side.
**Superseded by:** D-089 (native sign-up no longer fully client-direct; native sign-in and the `lookup-email`/Admin-API split are unaffected and still stand)
**Related code:** `heediq-api/src/routes/auth.ts` (`lookup-email` done, `link/request-otp` + `link/confirm` pending per D-087), `heediq-web/src/lib/auth/` (native sign-up/sign-in — not yet built)

### D-083 · Proactive provider-linking uses a dedicated OAuth callback route (2026-07-04) — Locked
**Area:** Architecture
**Decision:** D-079's proactive "add a sign-in method" button in Settings, for a provider the user has never authenticated with before, needs one fresh Hosted-UI OAuth round trip through that provider so Cognito creates/knows the federated identity before `AdminLinkProviderForUser` can be called with its provider user id. That round trip lands on a **new, dedicated** `/settings/link-callback` route — separate from the existing `/auth/callback` used for normal login — rather than overloading the login callback with a state-param marker. This requires registering `/settings/link-callback` as an additional allowed callback URL on the Cognito app client (`heediq-infra` CDK change) before it works.
**Why:** A dedicated route keeps the login callback's logic (exchange code → establish session → redirect to `/sources`) uncontaminated by an entirely different post-redirect action (exchange code → extract provider user id → call the add-provider backend endpoint → stay on Settings). Reusing one route with a branching marker would couple two unrelated flows for a marginal savings of one CDK change.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts` (Cognito app client callback URLs), `heediq-web/src/routes/SettingsLinkCallbackPage.tsx`, `heediq-api/src/routes/settings.ts` (`POST /settings/link/add-provider`, D-079)

### D-084 · pnpm `minimumReleaseAge` cooldown disabled across all repos (2026-07-04) — Locked
**Area:** Infra / Process
**Decision:** `minimumReleaseAge: 0` set in `pnpm-workspace.yaml` in all five pnpm repos (`heediq-web`, `heediq-infra`, `heediq-shared`, `heediq-api`, `heediq-worker-summarization`), disabling pnpm's default ~24h install-cooldown on freshly-published packages workspace-wide. The `minimumReleaseAgeExclude` per-package overrides already present in some repos (`@heediq/*`, specific `@heediq/shared` versions) are left in place but are now no-ops.
**Why:** The cooldown was blocking all new dependency installs in `heediq-api` (not just `@heediq/shared` itself — pnpm re-verifies the full lockfile on any install), which was directly blocking `POST /settings/link/add-provider` on installing `@aws-sdk/client-cognito-identity-provider`. Andrii chose to remove the guard outright rather than wait out the window or maintain per-package excludes.
**Note:** this removes a supply-chain safety default (time to catch a compromised just-published package before it's pulled in) — flagged at decision time; accepted as a deliberate tradeoff for faster iteration in a small team.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/pnpm-workspace.yaml`, `heediq-infra/pnpm-workspace.yaml`, `heediq-shared/pnpm-workspace.yaml`, `heediq-api/pnpm-workspace.yaml`, `heediq-worker-summarization/pnpm-workspace.yaml`

### D-085 · Logging & observability: native AWS (CloudWatch + X-Ray), no separate tool (2026-07-04) — Locked
**Area:** Architecture / Infra / Cost
**Decision:** Observability across all services (heediq-api, heediq-worker-transcription,
heediq-worker-summarization, the auth-provision trigger, and future workers) is built entirely on
native AWS: structured JSON logs (one shared shape, correlation ID threaded through every hop) to
CloudWatch Logs; CloudWatch Logs Insights as the cross-service search/debug tool; AWS X-Ray for
distributed tracing across the API → SQS → Fargate/EC2 GPU worker → DynamoDB chain; one CloudWatch
Dashboard per environment (dev/staging/prod) as the at-a-glance view (error rate, job-stage funnel,
GPU worker health). No Grafana, no self-hosted or SaaS observability tool.
**Why:** Already the locked stack (D-001 lists CloudWatch); genuinely zero incremental cost beyond
what the services already pay for; a separate Grafana instance either costs a running container
(violates "no cost") or caps retention at 14 days on the free SaaS tier and adds an external vendor
for a system that's otherwise fully AWS-native. This finally implements the tracing/correlation-ID
requirement already stated in `07-engineering-standards.md` §3, rather than adding new scope.
Revisit only if CloudWatch's UX becomes a real bottleneck — Grafana can point at CloudWatch as a data
source later without changing how anything logs, so this doesn't lock the door shut.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/logger.ts` (structured-logger + correlation ID helper);
`heediq-worker-transcription/src/logger.py` (Python mirror); `heediq-infra/lib/observability/observability-stack.ts`
(per-env CloudWatch Dashboard) + `lib/api/api-stack.ts`/`lib/summarization/summarization-stack.ts`
(X-Ray active tracing); `heediq-api/src/middleware/request-id.ts` (requestId correlation fallback).
Implemented and merged across all 5 repos (`heediq-shared`, `heediq-worker-transcription`,
`heediq-infra`, `heediq-api`, `heediq-worker-summarization`) — see D-093 for retention details.

### D-093 · Logger usage is mandatory; default log level `info`, `debug` opt-in via env var, no unbounded log retention (2026-07-05) — Locked
**Area:** Architecture / Cost
**Decision:** Every feature/Lambda/worker must log through `createLogger(service)` (TS) /
`create_logger(service)` (Python) — never raw `console.log`/`print`. The logger gains a level
threshold (`debug < info < warn < error`) read once at cold start from a `LOG_LEVEL` env var,
**default `info`** in every environment (dev/staging/prod alike — not `warn`, because `info`-level
lifecycle events are what the D-085 dashboard's job-stage funnel query depends on). `debug` is the
only level that's silent by default; ops can flip `LOG_LEVEL=debug` on a single Lambda via
CLI/console with no redeploy to get verbose detail during an incident, then flip back. X-Ray keeps
AWS's built-in default sampling (1 req/sec + 5% of the rest) — no custom sampling rule for now.
Every Lambda/log-producing resource must set an explicit CloudWatch Logs retention (recommended: 30
days dev/staging, 90 days prod) — "Never Expire" (the CDK default when `logRetention`/`LogGroup` is
omitted) is disallowed.
**Why:** Keeps day-to-day log coverage (the thing D-085 was built for) always on at negligible
cost, while giving a genuine, low-friction escape hatch (env var, not a redeploy) for deeper
verbosity when actually debugging something — without ever defaulting to `warn`-only, which would
silently break the observability dashboard's normal-operation queries. Explicit retention closes a
real cost gap found while implementing this: `ApiFn`/`SummarizationFn` in `heediq-infra` currently
have no retention set (unbounded storage growth); only `TranscriptionLogGroup` does today.
**Supersedes:** — **Superseded by:** — (refines D-085; does not contradict it — same
CloudWatch/X-Ray stack, no separate tool)
**Related code:** `heediq-shared/src/logger.ts` (level filtering + `LOG_LEVEL` support),
`heediq-worker-transcription/src/logger.py` (Python mirror), `heediq-infra/lib/config.ts`
`logRetentionFor(workloadEnv)` (applied to `ApiStack`, `SummarizationStack`, `TranscriptionStack`
log groups).

### D-094 · Password-policy visibility — checked-not-wired sync, dedicated weak-password error (2026-07-06) — Locked
**Area:** Architecture / Design
**Decision:** `@heediq/shared` gains `passwordPolicy.ts` (`PASSWORD_POLICY`, `PASSWORD_POLICY_RULES`,
`isPasswordPolicyCompliant`) as the single source of truth for Cognito's password rules (D-020),
consumed by both `heediq-api` and `heediq-web` (both already depend on the package). `heediq-api`'s
`POST /auth/link/confirm` calls `isPasswordPolicyCompliant` before ever calling Cognito, returning
the same `WEAK_PASSWORD` code as a genuine Cognito rejection — a fast, no-network-round-trip reject
for the common case, with the Cognito-side `InvalidPasswordException` handler kept as the
authoritative backstop (e.g. password-history reuse the shared check can't see). `heediq-infra`'s
CDK `passwordPolicy` literal (`foundation-stack.ts`) stays a separate, independent definition — no new
infra dependency on `@heediq/shared`, no publish-cycle coupling for a pure-CDK repo. Drift between the
CDK literal and the shared constant is caught only by the periodic cross-repo consistency check
(`rules/10-consistency-check.md`), not by a runtime import. `VerifyAndSetPasswordForm.tsx` (all three
D-089 entry points) shows a live, per-rule checklist (new `PasswordRequirements` kit component) as the
user types, and disables submit until every rule passes. Separately, a genuine backend rejection
(Cognito `InvalidPasswordException` on `AdminSetUserPassword`) now returns a distinct `WEAK_PASSWORD`
error code (previously collapsed into generic `BAD_REQUEST`), surfaced by a new frontend
`ApiClientError` class as a specific, actionable message instead of the generic failure toast.
**Why:** Wiring `heediq-infra` into `@heediq/shared` for full auto-sync would force a pure-CDK repo to
adopt a package dependency and publish-cycle coupling it doesn't otherwise need, for a policy that
rarely changes — a bigger architectural change than the feature warranted. The lighter check-not-wired
option keeps the sync mechanism proportional to the actual drift risk. The weak-password error
distinction closes a real gap observed live: a Cognito policy rejection was reaching the user as an
unhelpful generic "Failed to set password" message.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/passwordPolicy.ts`, `heediq-web/src/components/ui/PasswordRequirements/README.md`, `heediq-web/src/features/auth/README.md`, `heediq-api/src/routes/auth.ts`

### D-088 · API version prefix owned by exactly one place per side; route tests must exercise the real mounted app (2026-07-04) — Locked
**Area:** Architecture
**Decision:** `/api/v1/` remains the locked versioning scheme (D-042) for every `heediq-api` REST
endpoint, going forward. Two new standing rules close the gap that caused a production 404
(`heediq-web` calling `/auth/lookup-email` against a backend that only serves
`/api/v1/auth/lookup-email`): (1) **the version prefix is constructed in exactly one place per
side** — backend: `app.ts`'s top-level `app.route('/api/v1/...', ...)` calls; frontend:
`api-client.ts`'s `request()`, which now prepends `/api/v1` to every call. Route handlers, route
modules, and feature call sites never write the prefix themselves — they only know their resource
path (`/auth/lookup-email`, `/sources`, etc.). (2) **any test that asserts on a route's mounted
path must exercise the real top-level `app` export**, not a bare sub-router mounted at `/` in
isolation — mounting a sub-router alone hides prefix mismatches entirely (this is exactly how the
bug shipped with tests green on both sides).
**Why:** Both `heediq-api`'s route tests (mounting `authRouter` at `/`) and `heediq-web`'s
`HomePage` tests (mocking `apiClient.post`) passed while the real wired-up request 404'd in
`dev.heediq.com`, because neither exercised the actual prefix. Centralizing prefix construction to
one line per side means a future new endpoint can't repeat this mismatch, and it can never drift
between the two sides independently. Versioning itself is kept (not dropped) since it costs nothing
now and gives room for a `/api/v2/` migration path later without a big-bang rewrite.
**Supersedes:** — (extends D-042, does not change the `/api/v1/` scheme itself)
**Superseded by:** —
**Related code:** `heediq-web/src/lib/api-client.ts`, `heediq-api/src/app.ts`,
`heediq-api/src/__tests__/app-routing.test.ts` (new), `heediq-api/README.md`,
`heediq-web/README.md`, `heediq-web/src/lib/auth/README.md`

---

### D-089 · Own-verification email-confirmation model replaces IdP-trust; unified verify+password component (2026-07-04) — Locked
**Area:** Architecture / Product
**Decision:** Email verification for setting/activating a password on an account is performed
entirely on our side via Cognito's `SignUp`/`ConfirmSignUp` confirmation-code mechanism (D-087's
delivery mechanism, generalized) — never inferred from an IdP's asserted `email_verified`
attribute. One shared **two-step** component (step 1: enter the emailed code; step 2: set the
password — separate screens, not one combined form) is reused across all three entry points: (a)
reactive login-time linking (existing email found with no password set), (b) native sign-up, and
(c) proactive "add a sign-in method" in Settings. Backend flow in all three cases: `request-otp`
(Cognito `SignUp` with a throwaway random password if no native Cognito user yet exists for this
email, else `ResendConfirmationCode`) → user enters the code → `ConfirmSignUp` verifies it → user
sets their real password → `AdminSetUserPassword` → `AdminLinkProviderForUser` if a federated
identity needs attaching → the `heediq-user-auth-methods` row (D-091) is written/flipped active in
the same request.
**Why:** Investigating a QA report (Andrii logged in with Google, logged out, tried email/password
sign-in, got a plain "create password" form with no linking/verification) surfaced that
`PreTokenGeneration` was trusting Google's IdP-asserted `email_verified`, which was never actually
mapped in the Google/Microsoft `attributeMapping` — silently blocking org auto-provisioning (see
D-090). Rather than just fix the attribute mapping, Andrii decided the product should never depend
on an IdP's verification claim at all: verification is always ours, and consistently required
before any password can be set, whether that's first-time native signup, reactive linking, or
proactive settings linking. One shared component/flow (not three bespoke ones) keeps the UX and
code path identical everywhere D-078's identity model applies.
**Supersedes:** D-080 (its IdP-trust gating mechanism only — the underlying goal, "only a verified
email counts as identity," is preserved, just moved to our own verification), D-082 (native
sign-up no longer stays fully client-direct-to-Cognito with an immediate real password — it now
goes through the same backend verify-then-password flow as linking), D-086/D-087 (scope only —
generalized from "linking" to all three entry points, and split from one combined form into two
sequential steps; the underlying SignUp/ConfirmSignUp-reuse mechanism from D-087 is kept)
**Superseded by:** —
**Related code:** Built. `heediq-api/src/routes/auth.ts` (`request-otp`/`confirm` generalized
beyond `/auth/link/*` to also serve native signup and Settings), `heediq-web/src/features/auth/
VerifyAndSetPasswordForm.tsx` (the shared two-step component, see its README), used from
`heediq-web/src/routes/HomePage.tsx` and `heediq-web/src/routes/SettingsPage.tsx`.

### D-090 · Org/user auto-provisioning no longer gated on IdP-asserted email_verified (2026-07-04) — Locked
**Area:** Architecture / Policy
**Decision:** `auth-provision.ts`'s `PreTokenGeneration` trigger drops its `email_verified` check
entirely (previously gating org/user creation per D-080). Org/user auto-provisioning happens
unconditionally on first login for any method (native or federated), preserving D-077's
zero-friction promise (`GET /me` works immediately after any login, no onboarding gate).
Trustworthy identity/verification is enforced separately and only where it matters — before a
password can be set/activated on an account (D-089) — not as a precondition for basic product
access.
**Why:** Confirmed root cause of the QA bug: the Google/Microsoft IdP attribute mappings in
`foundation-stack.ts` never mapped `email_verified`, so it read as falsy on every federated login,
silently blocking provisioning. Rather than fix the mapping and keep relying on IdP-asserted
verification (D-080's model), Andrii decided the product should never gate on that signal at all —
it's brittle (this bug proves it) and redundant now that D-089 enforces our own verification at the
point where identity actually matters.
**Supersedes:** D-080
**Superseded by:** —
**Related code:** Built. `heediq-api/src/handlers/auth-provision.ts` (drops the `emailVerified`
check; also resolves the existing row by email first, falling back to `sub`, since a post-linking
re-login presents the destination/native user's `sub` rather than the original federated `sub` —
see the file's README for detail), `heediq-infra/lib/foundation/foundation-stack.ts`.

### D-091 · heediq-user-auth-methods is the source of truth for active login methods (2026-07-04) — Locked
**Area:** Architecture
**Decision:** `heediq-user-auth-methods` (created per D-087) is the authoritative record of which
sign-in methods are active for an account and any Cognito-side metadata needed to operate on them
(provider name, Cognito `sub`/`ProviderAttributeValue`, `linkedAt`, etc.) — Cognito itself is used
purely as the auth mechanism (token issuance, password verification), never queried ad hoc for
"what methods does this user have." Settings' sign-in-methods section (previously add-only per
D-079/D-083) is extended to read this table and display currently active methods, not just offer
buttons to add missing ones. Removing/unlinking a method is explicitly out of scope for now — Settings
shows current methods and offers adding new ones only.
**Why:** Andrii wants our own DB, not Cognito's `identities` claim or scattered flags, to be the one
place the app (and Claude) reasons about a user's sign-in methods — consistent with D-089/D-090's
shift toward owning identity/verification logic ourselves rather than trusting Cognito state. This
also closes a gap found during the same QA session: Settings had no way to see which methods were
already active.
**Supersedes:** — **Superseded by:** —
**Related code:** Built. `heediq-api/src/routes/auth-methods.ts` (`GET /api/v1/auth/methods`,
scoped to the caller's own `userId`), `heediq-web/src/routes/SettingsPage.tsx` (renders the active
methods list read-only, plus inline "Set a password" using the D-089 shared component).

### D-092 · `vars.AWS_REGION` is the sole region source everywhere except explicit per-service overrides (2026-07-05) — Locked
**Area:** Infra
**Decision:** The GitHub org-level `vars.AWS_REGION` (D-070) is the one source of truth for "current
region" across every repo and every layer — CI deploy roles, CDK stacks, and now also client-bundle
env vars like `heediq-web`'s `VITE_COGNITO_REGION` (forwarded from `vars.AWS_REGION` in `deploy.yml`,
not a new SSM param or hardcoded literal). No second definition of "the region" is added anywhere.
The only allowed deviations are explicit, named per-service overrides forced by an AWS API constraint
— e.g. the CloudFront-facing ACM cert must be in `us-east-1` regardless of primary region (D-053/D-054)
— and those stay scoped to exactly the resource that needs them, never promoted to a general default.
**Why:** Found while fixing the `VITE_COGNITO_REGION` gap in `heediq-web/deploy.yml` (undefined region
broke native sign-in/password-reset in every deployed environment) — Andrii flagged the risk of the
region getting defined redundantly across services as more of these needs come up. Reusing the
existing D-070 variable instead of inventing a new source keeps region resolution single-sourced.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/.github/workflows/deploy.yml` (`VITE_COGNITO_REGION: ${{ vars.AWS_REGION }}`).

---

### D-095 · Per-workload-account SES identity, narrowly, so Cognito can send its own OTP emails (2026-07-06) — Locked
**Area:** Architecture / Infra
**Decision:** Each workload account (dev/staging/prod) gets its own `heediq.com` SES email identity
(with its own DKIM CNAMEs added to the shared-services Route 53 zone, one manual one-time step per
environment — same pattern as the D-063 ACM cert). Cognito's User Pool `email:` config
(`cognito.UserPoolEmail.withSES(...)`) points at that in-account identity so Cognito's native
`SignUp`/`ConfirmSignUp` confirmation-code emails (D-087) actually deliver via real SES instead of
Cognito's default built-in mailer. This is narrowly scoped to Cognito's own email sending — all other
app-initiated transactional email continues to use the existing D-058 cross-account
`heediq-ses-email-sending` role into the shared-services identity; nothing about that path changes.
**Why:** Root-caused OTP non-delivery to Cognito silently using its default (non-SES) email service,
since no `email:` config was set on the User Pool. AWS confirms Cognito's custom-SES email config is a
hard same-account-only requirement — cross-account SES cannot be used by Cognito itself (unlike
Lambda, which can assume a role cross-account). The existing D-058 constraint ("do NOT create SES
identities in workload accounts") was written for app-initiated Lambda sends and didn't anticipate this
Cognito-specific limitation; superseding it here for this one narrow case avoids a much larger
architecture reversal (building custom OTP generation/storage/SES-sending to replace D-087's reuse of
Cognito's native confirmation flow).
**Supersedes:** D-058 (mechanism only — Cognito's own email sending gets its own per-account identity;
D-058's cross-account role for Lambda-initiated app email is unchanged and still the only path for
that traffic)
**Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts`, `heediq-infra/README.md` (SES gotcha)

### D-096 · request-otp self-heals a stuck confirmed-but-unlinked native Cognito user (2026-07-07) — Locked
**Area:** Architecture
**Decision:** `POST /auth/link/request-otp` gains a check for the case where a native Cognito user
already exists for the email, is `CONFIRMED` (i.e. `ConfirmSignUp` ran), but never completed
`link/confirm` (no `passwordSet=true` / no `heediq-user-auth-methods` row) — an account abandoned
between D-089's two screens. In that state, Cognito refuses both `SignUp` (`UsernameExistsException`)
and `ResendConfirmationCode` (`InvalidParameterException: already confirmed`), so no further code can
ever be delivered and the user is permanently stuck with no self-service way back in. The fix:
detect this exact state and `AdminDeleteUser` the stale native user, then re-run `SignUp` fresh so a
new code goes out. D-089's locked two-screen UX (enter code, then set password, separate screens) is
unchanged — this is a backend-only fix inside `request-otp`, not a flow/screen-count change.
**Why:** Found via live debugging (2026-07-06/07): CloudTrail showed every OTP retry for
`admin@heediq.com` after the first successful signup hitting `UsernameExistsException` →
`ResendConfirmationCode` → `InvalidParameterException`, silently swallowed into a generic `{sent:
true}` response with no email actually sent (D-078's non-disclosing-response design working exactly
as intended, but hiding a real stuck-state bug from both the user and our own logs). Combining the
two screens into one call was considered (would shrink but not eliminate the same race) and rejected
in favor of this narrower, lower-risk fix that touches only backend state-detection, not the UX.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/src/routes/auth.ts` (`link/request-otp`), `heediq-api/src/lib/cognito.ts`

### D-097 · Layered abuse protection for the OTP endpoints (2026-07-07) — Locked
**Area:** Architecture / Policy
**Decision:** `POST /auth/link/request-otp` and `POST /auth/link/verify-otp` (unauthenticated,
D-087/D-089) get defense-in-depth: (1) **API Gateway throttling** (steady-state + burst limit) in
every environment — stops raw request floods before Lambda even runs. (2) **AWS WAF rate-based
rule** (block an IP exceeding N requests per 5 min) — activation timing per D-098. (3) **App-level
throttling keyed by email *and* IP** (DynamoDB, fixed/sliding window) in every environment — the
only layer that stops a distributed attacker email-bombing one victim via rotating IPs. All three
respond with the same generic `RATE_LIMITED` shape, preserving D-078's non-disclosure guarantee.
CAPTCHA is explicitly deferred.
**Why:** Per-IP throttling alone doesn't stop a low-and-slow attack against one victim email from
many IPs, so the DynamoDB email+IP layer is necessary alongside the cheaper API Gateway/WAF layers.
Rate-limiting keyed only on email risks letting an attacker lock out a real user, so the email-side
threshold is generous while the IP-side is tighter.
**Superseded by:** D-098 (WAF activation timing only — the other two layers are unchanged and still built now)
**Related code:** `heediq-infra/lib/api/api-stack.ts` (throttling, gated WAF), `heediq-infra/lib/foundation/foundation-stack.ts` (`heediq-rate-limits` table), `heediq-api/src/lib/rateLimit.ts` + `src/routes/auth.ts` (email+IP limiter), `heediq-web/src/features/auth/VerifyAndSetPasswordForm.tsx` (`RATE_LIMITED` handling)

### D-098 · Defer WAF activation until a marketing campaign is planned (2026-07-07) — Locked
**Area:** Architecture / Cost
**Decision:** The WAF rate-based rule from D-097 is written into `heediq-infra` now but shipped
**disabled** (the `CfnWebACL`/`CfnWebACLAssociation` construct is present in code, gated behind a
config flag defaulting to off) rather than actually deployed active in prod. Enable it before the
first marketing campaign or any other expected traffic spike. API Gateway throttling and the
DynamoDB email+IP app-level limiter — the other two D-097 layers — are unaffected and still built
and active now in all environments.
**Why:** WAF has a real fixed monthly cost (~$5/mo per Web ACL + ~$1/mo per rule + usage) that isn't
justified before there's meaningful unauthenticated traffic to defend against; the DynamoDB
email+IP layer already covers the attack this system cares most about (targeted email-bombing one
victim), so WAF's edge-level flood protection can wait until volume actually warrants its cost.
Scaffolding it now (rather than building it later from scratch) means flipping it on is a config
change, not a new deploy, when a campaign is scheduled.
**Supersedes:** D-097 (WAF timing only) **Superseded by:** —
**Related code:** `heediq-infra/lib/api/api-stack.ts` (WAF construct, gated off by default)

### D-099 · Decouple internal accountId from Cognito `sub` via a `heediq-cognito-identities` mapping table (2026-07-07) — Locked
**Area:** Architecture
**Decision:** Heediq maintains its own internal `accountId`, generated and stored in DynamoDB,
fully decoupled from Cognito's `sub`. A new table `heediq-cognito-identities` (pk = `sub`, attribute
= `accountId`) maps every Cognito identity — native or federated — onto one `accountId`. The
`accountId` is created once at first login and simply extended with new `sub → accountId` rows as
further sign-in methods get linked; existing rows are never migrated or rewritten.
**Why:** `AdminLinkProviderForUser` makes a newly-created native Cognito user the alias destination
for a federated login's future `sub`, while the prior account-linking flow resolved the "canonical"
DynamoDB row via an email-lookup-and-hope (`resolveCanonicalAccountId`) — these two notions of "the
account" diverged permanently, causing a real production bug (`/me` 404, `/auth/methods` empty
after linking Google + email on the same account). Cognito's `sub` is not a stable per-account
identifier once linking can repoint it; migrating existing DynamoDB rows to follow a new `sub` is
fragile and has unbounded blast radius (sources, jobs, everything keyed by user). A stable,
app-owned `accountId` sidesteps this permanently and was needed for multi-method accounts anyway.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/src/lib/accountIdentity.ts`, `heediq-api/src/handlers/auth-provision.ts`,
`heediq-api/src/handlers/auth-trigger-*.ts`, `heediq-api/src/middleware/auth.ts`,
`heediq-api/src/routes/auth.ts`, `heediq-infra/lib/foundation/foundation-stack.ts`

### D-100 · Secrets fetched via direct SDK call, not the Lambda Extension (2026-07-07) — Locked
**Area:** Infra
**Decision:** Narrows D-038's secret-fetch mechanism: Lambdas that need a Secrets Manager value
(currently only `heediq-summarization` fetching the Claude API key) call
`SecretsManagerClient`/`GetSecretValueCommand` directly via the AWS SDK, cached at module scope so
the fetch only happens once per cold start (not per invocation). No AWS Parameters and Secrets
Lambda Extension layer is attached. The SSM/Secrets Manager path convention from D-038 is unchanged.
**Why:** Consistency-check audit (2026-07-07) found the Extension was never actually wired into
`summarization-stack.ts` or `heediq-worker-summarization/src/config.ts` — the direct-SDK
implementation was already what shipped and is safe in practice (module-level caching keeps the SDK
call out of the hot path, matching the original intent without the extra layer/config surface of the
Extension). Updating the decision to match reality avoids an unnecessary infra change to a working
prod Lambda.
**Supersedes:** D-038 (mechanism only — path convention unchanged, see D-038)
**Superseded by:** —
**Related code:** `heediq-infra/lib/summarization/summarization-stack.ts`, `heediq-worker-summarization/src/config.ts`

### D-101 · ECR lifecycle rule fixed to actually expire old transcription-worker images (2026-07-08) — Locked
**Area:** Infra / Cost
**Decision:** `SharedServicesStack`'s ECR lifecycle rule for `heediq-worker-transcription` is corrected
to match the tags CI actually pushes (`free-sha-<7chars>` / `paid-sha-<7chars>`). Untagged-layer
cleanup (1 day) is unchanged. (Keep-count changed from 5 to 3 per tier by D-108.)
**Why:** The original rule (D-047-era) used `tagPrefixList: ['sha-']`, which never matched either
tag because both are prefixed with the tier name first (`free-`/`paid-`), not `sha-`. Every image
ever built was being retained forever — the actual driver of ECR storage cost.
**Supersedes:** D-047 (retention mechanism only — SHA-tag versioning strategy itself unchanged)
**Superseded by:** D-108 (keep-count only, 5→3 per tier — tag-prefix fix and untagged-cleanup rule unchanged)
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`

### D-108 · ECR cost cleanup: keep-count lowered to 3/tier, build attestations disabled (2026-07-14) — Locked
**Area:** Infra / Cost
**Decision:** Two changes to `heediq-worker-transcription`'s ECR footprint: (1) `SharedServicesStack`'s
lifecycle rule keep-count drops from 5 to **3 images per tier** (free/paid) — current + 1 rollback is
enough per environment; dev/staging/prod all pull from the same shared-services repo by tag, so 3
covers the worst case of all three envs mid-promotion at once without needing per-env tracking
automation. (2) `docker/build-push-action@v6`'s default `provenance`/`sbom` attestations are disabled
(`provenance: false`, `sbom: false`) on both build steps in `deploy.yml` — these were pushing extra
untagged manifest images per build that D-101's "expire untagged after 1 day" rule never actually
cleaned up (confirmed via `start-lifecycle-policy-preview`: 0 images ever matched), because they
stay index-referenced by the tag. This was the real driver of unbounded growth, not the keep-count.
One-time cleanup also ran: manually deleted 4 stale, unreferenced SHA generations (8 tagged +
14 orphaned untagged images) confirmed unused via each workload account's live ECS task definitions,
freeing ~97.7 GB (139.5 GB → 41.9 GB).
**Why:** Repo had grown to 139.5 GB / 30 images while only 1 SHA generation was actually live anywhere
(staging/prod have no ECS deployment yet). Attestations aren't consumed anywhere in the pipeline today
(no supply-chain verification step), so disabling them has no functional cost. A custom
"pin what's live per env" script was considered and rejected in favor of a slightly larger static
keep-count — avoids building/maintaining new automation for a marginal storage saving.
**Supersedes:** D-101 (keep-count only)
**Superseded by:** —
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`,
`heediq-worker-transcription/.github/workflows/deploy.yml`

### D-102 · Dynamic per-org RBAC + unified GxP-quality audit trail (2026-07-08) — Locked
**Area:** Architecture
**Decision:** Replaces D-017's fixed Admin/Member roles with dynamic, per-org RBAC (Users, Groups,
Roles, a static `resource:verb` Permission catalog) enforced at resource-type granularity in
`heediq-api` middleware, plus a unified, write-once `heediq-audit-log` table covering auth events
and every RBAC-governed action. Two non-deletable system roles (`admin`, `member`) seed every org;
unlimited custom roles/groups. Effective permissions = union of direct + group-mediated role
assignments, no deny rules.
**Why:** Andrii wants comprehensive, dynamically configurable RBAC ahead of building more
functionality on the fixed two-role model, with an audit trail rigorous enough to meet a GxP-grade
quality bar (design target, not a formal compliance obligation).
**Supersedes:** D-017 (Admin/Member roles carry forward as the seeded system roles — only the
mechanism becomes dynamic)
**Superseded by:** D-105 (invalidation mechanism only — see D-105)
**Related code:** `heediq-api/README.md` §"D-102/D-105 RBAC & audit trail",
`heediq-web/src/lib/rbac/README.md`, `memory/business/architecture.md` §"RBAC & Audit Trail"

### D-103 · Script files stay scoped to one thing (2026-07-08) — Locked
**Area:** Architecture
**Decision:** Any script/code file (not infra/CDK-specific — this applies workspace-wide: Lambda
handlers, React components, CDK stacks, utilities, etc.) should stay focused on a single concern.
When a file starts mixing multiple distinct responsibilities (e.g. one CDK stack file defining
tables, Cognito, buckets, queues, and auth triggers all in one place), split it into focused
files grouped by concern, composed back together by a slim top-level file. There is no strict line
count — a long file that stays on one concern is fine, and a short file mixing concerns still needs
splitting. Scope, not size, is the trigger.
**Why:** Foundation stack (`heediq-infra/lib/foundation/foundation-stack.ts`) grew past 600 lines by
mixing DynamoDB tables, S3, SQS, Cognito, and Lambda trigger wiring in one file, making it hard to
scan. Andrii wants this as a general habit, not a one-off fix, so future files (in any repo) get
split by concern as they grow rather than accumulating unrelated responsibilities.
**Supersedes:** —         **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/README.md` (once the foundation-stack split lands)

### D-104 · No migration for `heediq-auth-audit-log` — drop the table (2026-07-08) — Locked
**Area:** Architecture
**Decision:** Resolves D-102's open migration question: `heediq-auth-audit-log` (D-087) is removed
outright once the auth event write path cuts over to the unified `heediq-audit-log` (D-102) — no
backfill of old rows, no read-only retention period. History in the old table is simply dropped.
**Why:** Andrii doesn't need the old auth-audit history preserved, so the simplest path (cut over
writes, then delete the table) beats a backfill migration with no product benefit.
**Supersedes:** —         **Superseded by:** —
**Related code:** — (the table removal happens later in the RBAC build-out, once the auth write path
cuts over to `heediq-audit-log`; `memory/business/architecture.md` §"RBAC & Audit Trail" is updated
at that point too, per Andrii — not now)

### D-105 · RBAC permission invalidation rides the JWT, no per-request DB check (2026-07-09) — Locked
**Area:** Architecture
**Decision:** Drops D-102's `rbacVersion`/`RBAC_STALE` staleness-check mechanism. Effective
permissions are still resolved and baked into `custom:permissions` on the Cognito ID token at
issuance (`auth-provision.ts`, unchanged from D-102), but there is no `custom:rbacVersion` claim, no
per-request comparison against `heediq-users`, and no forced `401 RBAC_STALE`. Staleness is instead
bounded purely by the token's natural lifecycle: the ID token expires and the client refreshes it via
the refresh token, which re-fires the same `PreTokenGeneration` trigger and picks up any role/
permission change — identical to how `custom:role` already works today. `requirePermission`
middleware becomes a pure in-token check (read the `permissions` claim already parsed by
`authMiddleware`), no DynamoDB read on the request path at all.
**Why:** Andrii questioned why RBAC needed a mechanism `custom:role` doesn't already use, and proposed
applying the same principle — cache permissions in the token until natural expiry/refresh. A
per-request DB read on every gated route adds latency and cost with no current product need; a rare,
bounded delay before a permission change takes effect (one token lifetime) is an acceptable tradeoff
for removing that read path entirely, consistent with how role changes already behave.
**Supersedes:** D-102 (mechanism only — see D-102's `Superseded by` note for exactly what's unchanged)
**Superseded by:** —
**Related code:** `heediq-api/README.md` §"D-102 RBAC & audit trail" — `requirePermission` middleware
is the pure in-token check described here (no `rbacVersion`/DB read); see D-102's `Related code` for
the full Phase 1–4 file list.

### D-106 · Permission key strings are immutable once released — additive-only, never rename in place (2026-07-09) — Locked
**Area:** Architecture
**Decision:** Once a `Permission` literal in `heediq-shared/src/permissions.ts`'s `PERMISSIONS` catalog
ships, its string value is never edited or removed in place. Adding a permission is fine. Retiring one
requires: add the replacement key, leave the old key valid and marked deprecated in a comment, run an
explicit one-off migration updating every stored `permissions` array in the `heediq-roles`/
`heediq-groups` DynamoDB tables, then remove the old key only in a later release once no stored role
references it. This is a strict rule — no exceptions for "just a rename."
**Why:** `PERMISSIONS` is the single source of truth feeding the API gate (`requirePermission`, exact
`Array.prototype.includes` string match — `heediq-api/src/middleware/rbac.ts`), the frontend `<Can>`
gate, and i18n key interpolation (D-102's constants-drive-everything design) — but role/group
`permissions` arrays are persisted as raw strings in DynamoDB (`heediq-api/src/routes/roles.ts`) with
no live link back to the catalog, and already-issued JWTs carry `custom:permissions` baked in at
issuance with no per-request DB re-check (D-105). Renaming a key in place silently breaks every
existing role that granted it (stored string no longer matches anything) and every live session
carrying the old string, with zero error surfaced — a same-request-cycle rename has no migration path
today. Treat the catalog as append-only, same discipline as a DB enum.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-shared/src/permissions.ts`; `heediq-api/README.md` §"D-102 RBAC & audit
trail"; `heediq-api/src/routes/roles.ts` (persistence); `heediq-api/src/middleware/rbac.ts` (exact-match
gate); `heediq-api/src/handlers/auth-provision.ts` (JWT claim stamping, D-105).

### D-107 · Every mutating endpoint/UI action requires permission gating + audit trail — standing rule (2026-07-14) — Locked
**Area:** Architecture
**Decision:** Every future create/update/delete API route gates on `requirePermission` (backend) and
every corresponding frontend action gates on `<Can>`; every create/update/delete route writes an audit
event via the `auditWriter(c)` helper (`heediq-api/src/lib/audit.ts`) — create writes `after` only,
delete writes `before` only, update writes both — using a resource-type-specific, human-readable
payload (never a raw DB row), extending `AuditPayloadMap` in `heediq-shared/src/audit.ts` per new
resource type. `auditWriter(c)` centralizes only actor/org context extraction (`orgId`, `actorUserId`,
`actorEmail`, `actorRole` — pulled from the verified `AuthContext`); payload construction stays
explicit per route. This was previously only implemented for the RBAC/roles feature (D-102) and not
codified as a standing rule for all future endpoints — this decision closes that gap.
**Why:** Andrii asked whether the rules mandate observability logging, `<Can>` gating, and a
human-readable audit trail (create=after-only, delete=before-only) for every new endpoint/UI action —
they didn't, only the one-off RBAC build followed the pattern. Locking it as a standing rule prevents
future features from silently skipping permission gating or audit coverage. `auditWriter(c)` avoids
repeating `orgId`/`actorUserId`/`actorEmail`/`actorRole` boilerplate at every call site without
centralizing payload construction, which would conflict with D-102's human-readable/resource-specific
design principle. `actorRole` is included because it's already on the verified JWT/`AuthContext` at
zero extra cost; `actorGroups` is deferred — group membership isn't in the JWT today and would require
either a DB read at write time or a JWT claim addition, and Andrii chose to skip it for now rather than
add either.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-api/src/lib/audit.ts` (`auditWriter`, `writeAuditEvent`);
`heediq-shared/src/audit.ts` (`actorRole` on the envelope); `heediq-api/src/routes/roles.ts`,
`groups.ts`, `role-assignments.ts` (reference implementations); `heediq-api/README.md` §"D-102 RBAC &
audit trail".

### D-109 · Generalized real-time WebSocket framework (2026-07-14) — Locked
**Area:** Architecture
**Decision:** `HeediqWebSocketStack` (D-061) is generalized from a job-status-only pusher into a
reusable event framework any feature can push into, ahead of the first transcription flow feature.
`heediq-ws-connections` rows grow from `{connectionId}` to `{connectionId, userId, orgId,
broadcastKey: 'ALL'}`, with new GSIs `by-user`/`by-org`/`by-broadcast` (the old `by-source` GSI is
retired — unused, and superseded by org-scoped targeting). `heediq-shared` replaces the one-off
`WsStatusMessageSchema` with a generic envelope (`WsEventEnvelopeSchema`: `{scope, type, payload,
occurredAt}`, `scope` = `user`/`org`/`broadcast`) plus an extensible `WsEventPayloadSchemas` registry
keyed by event `type` — `job_status` becomes its first entry, now pushed at **org scope** (not
per-source) to match the org-shared sources library. `heediq-api` gets the first real Lambda code
(connect/disconnect + pusher were inline CDK placeholders): `src/lib/wsPush.ts` exports
`pushToUser`/`pushToOrg`/`pushBroadcast`, callable directly by any Lambda with the new
`WebSocketStack.grantPush(fn)` IAM helper — this is the framework's one push mechanism.
**Job-status keeps its existing DDB Streams trigger on `heediq-jobs`** (mechanism unchanged for
table-backed state changes — decouples "state changed" from "push succeeded," and avoids porting a
push client into the Python transcription worker); its stream-triggered handler now just calls the
same shared `wsPush` library instead of bespoke code. A new SSM param
`/heediq/api/ws-management-endpoint` (built in `WebSocketStack` from `wsApi.ref` + region + stage —
no new resource) exposes the endpoint any push-calling Lambda needs for `ApiGatewayManagementApiClient`,
distinct from the public `wss://` client URL.
**Why:** Andrii wants "what's happening now" UI available from day one, not bolted onto the first
feature. Direct-call push is right for events with no natural backing table row; DDB Streams stays for
events that already write durable state (job status) because retry/decoupling comes for free and
Python-worker changes are avoided. Org-scoped job-status matches the org-shared library model instead
of a per-viewer scope that was never actually implemented.
**Supersedes:** D-061 (mechanism only — WS push instead of polling stays; connection-scoping model,
event schema, and push-trigger reusability are what changed)          **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/tables.ts`, `heediq-infra/lib/websocket/websocket-stack.ts`,
`heediq-shared/src/messages.ts` (or new `src/ws.ts`), `heediq-api/src/lib/wsPush.ts`,
`heediq-api/src/handlers/ws-connect.ts`, `heediq-api/src/handlers/ws-pusher.ts`

### D-110 · heediq-web centralized WebSocket client — Context + typed hook, no new cross-repo push access (2026-07-14) — Locked
**Area:** Architecture
**Decision:** `heediq-web` gets a single `WsProvider` (React Context) owning the entire WebSocket
connection lifecycle: connects once the user is authenticated (`wss://ws-{env}.heediq.com?token=<JWT>`,
the same query-param JWT pattern `ws-connect.ts` already expects per D-109), reconnects with backoff,
and parses every inbound message through `@heediq/shared`'s `WsEventEnvelopeSchema`. It exposes a typed
`useWsEvent(type, handler)` hook — features subscribe only to the event `type`s they care about (e.g.
`job_status`) rather than one central switch/reducer enumerating every feature's reaction. This is the
first real consumer of the D-061/D-109 push pipeline; nothing in `heediq-web` read from the socket
before this.
Separately: no other backend repo (`heediq-worker-transcription`, `heediq-worker-summarization`) gets
direct WS push access beyond what D-109 already built. `wsPush.ts`/`grantPush()` stay `heediq-api`-only,
triggered only by the existing `heediq-jobs` DDB Streams path — holding off on a generalized outbox
(e.g. SQS) until a concrete feature needs direct, non-DDB-backed push. This isn't a new decision, just
confirming D-109's scope stands as-is.
**Why:** A context+hook keeps event-handling ownership with the feature that cares about an event
(job-status UI updates, future event types) instead of a growing god-file every feature has to touch.
Matches `07-engineering-standards.md` §7 (server state via TanStack Query) — handlers typically call
`queryClient.invalidateQueries`/`setQueryData` rather than duplicating server state in a store. Holding
off on cross-repo push access is YAGNI: today only `job_status` exists and DDB Streams already covers
it; building an outbox now would be speculative infra with no consumer.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/ws/` (new — `WsProvider`, `useWsEvent`), `heediq-shared/src/ws.ts`

### D-111 · Every feature with async backend work must use the WS framework for responsiveness (2026-07-14) — Locked
**Area:** Product
**Decision:** Any feature involving async or long-running backend work (transcription, diarization,
summarization, and future job types) must push real-time progress through the WS framework
(D-061/D-109/D-110) — never a silent wait or a bare indeterminate spinner, and never polling instead
of the push. Planning a feature with backend job work (Step 2, `01-development-workflow.md`) must name
the `WsEventPayloadMap` event type(s) it needs (reuse `job_status` or add a new payload to
`heediq-shared/src/ws.ts`) and which `useWsEvent` handler the frontend registers to reflect
stage/progress/outcome. This applies to every future feature, not just the ones already built.
**Why:** The framework already exists and cost real build effort (D-061/D-109/D-110); skipping it
feature-by-feature would silently regress `04-loading-and-feedback.md`'s "every wait is visible"
principle back to polling or blind spinners on a case-by-case basis. Locking this in as a planning
requirement makes it structural instead of something that has to be re-argued per feature.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/ws/README.md`, `heediq-api/src/lib/wsPush.ts`,
`heediq-shared/src/ws.ts`

### D-112 · Manual `workflow_dispatch` trigger on infra deploy pipeline (2026-07-15) — Locked
**Area:** Infra
**Decision:** `heediq-infra`'s `deploy.yml` gained a `workflow_dispatch` trigger (`inputs.environment`:
dev/staging/prod) so any environment can be manually redeployed at the current tip of `develop`/`main`,
independent of a push event. Wired into the existing `deploy-dev`/`deploy-staging`/`approve-prod`/
`deploy-prod` job `if:` conditions alongside the push triggers, without weakening the staging→prod
manual-approval gate (`approve-prod` still requires `deploy-staging` to have succeeded on the push-to-
`main` path; the `workflow_dispatch` path to `prod` still goes through the same `approve-prod` gate).
**Why:** Root-caused a live incident (2026-07-15): a push-triggered `HeediqApiStack` deploy failed on
an unrelated, since-fixed test; the fix commit only touched a `paths-ignore`'d path so it never
re-triggered a deploy. `HeediqApiStack` in dev then silently ran 5 days behind `develop`, missing the
`WS_MANAGEMENT_ENDPOINT` env var (D-109) and 500'ing on every request — surfaced to the user as a
CORS error on `dev.heediq.com` since browsers report a non-2xx preflight as a CORS failure. No
mechanism existed to force a redeploy without a throwaway commit.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-infra/.github/workflows/deploy.yml`, `heediq-infra/README.md` (Gotchas)

### D-113 · Fix root causes, not symptoms (2026-07-15) — Locked
**Area:** Policy
**Decision:** When a bug is found, diagnose and fix the actual root cause, not the point where it
happens to surface — even if that means redoing prior work. A fix that only patches the visible
symptom (e.g. reclassifying an error code, adding a special case at the point of failure) without
addressing why the defect exists is not an acceptable fix.
**Why:** Prompted by the Settings provider-linking bug (2026-07-15): the account actually linked
successfully server-side, but the frontend showed a false error. The proximate fix (reclassify a
Cognito `AliasExistsException` as idempotent success in `heediq-api/src/routes/settings.ts`) would
have patched only where the defect surfaced. The actual root cause is structural: OAuth callback
pages (`SettingsLinkCallbackPage.tsx`, `AuthCallbackPage.tsx`) perform a one-time side effect
(exchanging a single-use authorization code, then a linking/login call) with no guard against the
effect running more than once — vulnerable to reload, browser back/forward, or duplicate navigation.
Both pages share the defect; a backend-only patch would have left it in place.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/routes/SettingsLinkCallbackPage.tsx`,
`heediq-web/src/routes/AuthCallbackPage.tsx`

### D-114 · `requirePermission` writes a denial audit entry on every 403 (2026-07-15) — Locked
**Area:** Architecture
**Decision:** The RBAC/audit framework (D-102) is a single check-and-record mechanism, not two
independently-wired ones. `requirePermission` (`heediq-api/src/middleware/rbac.ts`) itself writes a
minimal `resourceType: 'permission'`, `effect: 'denied'` audit entry on every 403, in addition to
route handlers writing `effect: 'permitted'` entries via `auditWriter` on success. `AuditLogEntrySchema`
gains an `effect: 'permitted' | 'denied'` field (default `permitted`, backward-compatible with every
already-stored row) and a new `permission` resourceType carrying just the attempted permission (no
resource instance exists for a denied check). Implemented as an O(1) middleware-level change — a
single file — not a per-route retrofit, since every gated route already calls `requirePermission`.
**Why:** Andrii identified that the framework was meant to check permission AND record the outcome
(permitted or denied) in one call; the actual code only ever recorded successful mutations via
`auditWriter`, leaving denied attempts with zero trace anywhere. Confirmed by reading `rbac.ts`: the
FORBIDDEN branch had no logger call and no audit write. Implementing now (rather than deferring)
costs the same regardless of endpoint count, since the fix lives in the single centralized
enforcement point every route already calls — waiting only creates a permanent gap in denial history
on the write-once audit table, with no way to backfill it later.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-shared/src/audit.ts`, `heediq-api/src/middleware/rbac.ts` (pending)

### D-115 · Docs-only changes never trigger CI or deploy pipelines (2026-07-16) — Locked
**Area:** Infra
**Decision:** Every repo's `ci.yml` (pull_request trigger) and `deploy.yml`/equivalent (push trigger)
carries a `paths-ignore: ['**/*.md']` (or equivalent scoped `paths:` allowlist that already excludes
markdown) so a README/docs-only change never burns a typecheck/test run or a real deploy
(build+S3-sync+CloudFront-invalidation, Lambda `update-function-code`, or CDK deploy). Applies to all
6 app repos (`heediq-shared`, `heediq-web`, `heediq-api`, `heediq-worker-summarization`,
`heediq-worker-transcription`, `heediq-infra`). New workflows must include this guard from the start.
**Why:** Andrii requested it explicitly while merging a batch of consistency-check README fixes —
routine doc corrections shouldn't cost CI minutes or risk an unnecessary redeploy. Caught a real gap
in the process: `heediq-infra`'s existing `paths-ignore` only excluded the root `README.md`, missing
`lib/foundation/README.md` (and any future nested README) — broadened to `**/*.md`.
**Supersedes:** —          **Superseded by:** —
**Related code:** `.github/workflows/ci.yml` and `.github/workflows/deploy.yml` in each app repo.

### D-116 · Waveform loading mark (2026-07-16) — Locked
**Area:** Design
**Decision:** `LoadingMark` (`heediq-web/src/components/ui/LoadingMark/`) is redesigned as a 4-bar
audio-waveform pulse — each bar animates height (scaleY) independently at a staggered phase, no
group rotation. Same component API/props (`size`, `tone`, `aria-label`); honors
`prefers-reduced-motion` as before.
**Why:** Andrii found the existing ear-perk rotation (D-074) "a bit ugly" and asked for a waveform
feel instead, matching Heediq's audio/transcription product identity.
**Supersedes:** D-074 (animation only — component contract/props unchanged)
**Superseded by:** —
**Related code:** `heediq-web/src/components/ui/LoadingMark/`, `heediq-web/src/styles/globals.css`

### D-117 · App-wide motion system (2026-07-16) — Locked
**Area:** Design
**Decision:** Page-to-page navigation uses a shared fade + slight y-axis transition (Framer Motion
`AnimatePresence`, keyed on route path). Any UI element that mounts/unmounts (modal, toast,
dropdown, form-step swap, validation message) animates in/out via fade + axis-shift — y-axis for
vertically-stacked content (list items, wizard steps), x-axis for horizontally-implied content
(side drawers, left↔right step navigation) — using one shared duration/easing token set
(`heediq-web/src/lib/motion.ts`: fast 150ms / base 200ms / slow 300ms, standard ease-out curve).
Applies to all kit "appears/disappears" components going forward, not just the ones touched in
this pass. `framer-motion` added as the animation dependency.
**Why:** Andrii asked for smooth, modern transitions between pages and consistent enter/exit
animation for any appearing/disappearing UI element, calling out standard UX practice rather than
specifying exact motion values.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/motion.ts`, `heediq-web/src/App.tsx`,
`heediq-web/src/components/ui/Modal/`, `heediq-web/src/components/ui/Toast/`

### D-118 · Login — separate branded IdP buttons, direct-to-provider (2026-07-16) — Locked
**Area:** Design
**Decision:** The login screen replaces the single "Continue with SSO" button with two separate
buttons — one per federated provider (Google, Microsoft) — each using that provider's own official
brand mark/style, not a Cognito-generic control. Each button passes `identity_provider` through to
Cognito's `/oauth2/authorize` call directly (mirroring the existing `startProviderLink` pattern),
so the user lands straight on that provider's own consent screen — Cognito's Hosted-UI provider
picker is skipped entirely for primary login.
**Why:** Andrii wants each IdP represented with its own recognizable button (reference: a
Google/Microsoft-style auth screen), which also improves the flow by removing an extra picker step.
Refines D-020's UI presentation only — the Cognito + federated-IdP auth backend is unchanged.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/auth/cognito-oauth.ts`, `heediq-web/src/lib/auth/AuthContext.tsx`,
`heediq-web/src/components/ui/IdentityProviderButton/`, `heediq-web/src/routes/HomePage.tsx`

### D-119 · PWA build tooling — vite-plugin-pwa (2026-07-16) — Locked
**Area:** Architecture
**Decision:** D-024's installable-PWA requirement is implemented via `vite-plugin-pwa`
(Workbox-based): auto-generated manifest + service worker precaching the app shell only, `autoUpdate`
registration. The service worker never caches `/api/v1/*` responses (transcripts/audio are sensitive
per-org data, D-024/`07-engineering-standards.md` §2 — must always hit the network). Offline audio
recording, queued upload, and the Screen Wake Lock API (also part of D-024) remain backlog — not
built in this pass.
**Why:** `vite-plugin-pwa` is the standard, well-maintained Vite-native PWA tool — avoids hand-rolling
a service worker and manifest injection. Scoping to installable-baseline-only (vs. full offline
recording) keeps this pass frontend-shell-only, no recording-pipeline risk.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/vite.config.ts`, `heediq-web/public/icons/`

### D-120 · App-wide double-submit guard + animated stroke/shadow transitions (2026-07-16) — Locked
**Area:** Design
**Decision:** The double-submit guard (`04-loading-and-feedback.md` §4) is a general frontend rule,
not a per-button opt-in — any interactive element triggering async work (button, form submit,
link-triggered mutation) must ignore a re-entrant trigger while pending, implemented via the shared
`useAsyncAction` hook (`heediq-web/src/lib/useAsyncAction.ts`). Separately, every appearing/
disappearing visual state (focus rings, error rings, borders, shadows) must animate rather than snap:
components must list `box-shadow`/`opacity` explicitly in their transition classes (Tailwind's
`transition-colors` omits both) using the shared `duration-base`/`ease-brand` tokens.
**Why:** Found via a login-page UX pass — rapid double-clicks on OTP/password submit buttons could
double-fire requests, and the focus/error ring on `Input` was snapping instantly instead of animating
because `transition-colors` doesn't cover `box-shadow`. Both are common oversights worth codifying as
standing rules rather than fixing ad hoc per component.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/useAsyncAction.ts`, `heediq-web/src/components/ui/Button/Button.tsx`,
`heediq-web/src/components/ui/Input/Input.tsx`, `heediq-web/src/features/auth/VerifyAndSetPasswordForm.tsx`

### D-121 · PWA app name varies per environment (2026-07-16) — Locked
**Area:** Design
**Decision:** The installed PWA's manifest `name`/`short_name` varies by environment — `Heediq` in
production, `Heediq (Staging)` / `Heediq (Dev)` otherwise, `Heediq (Local)` when `VITE_APP_ENV` is
unset (`pnpm dev` / a local build). `VITE_APP_ENV` is injected in `deploy.yml`'s `Build` step per
deploy job; icon/theme-color stay the same across environments (name only).
**Why:** Installing the PWA from dev/staging alongside prod previously looked identical on the
homescreen — no way to tell them apart at a glance. Mirrors D-039's existing non-prod-subdomain-
prefix convention rather than inventing a new one.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/vite.config.ts`, `heediq-web/.github/workflows/deploy.yml`,
`heediq-web/src/lib/pwa/README.md`

### D-122 · Perceived-loading timing values — component vs page level (2026-07-17) — Locked
**Area:** Design
**Decision:** Every loading indicator app-wide (component/button-level via `useAsyncAction`, and
page-level route/full-page loads) uses a **delay-before-show** (~150–200ms — an operation finishing
before this shows nothing at all) followed by a **minimum display-once-shown** once it does appear,
so nothing ever flickers for a single frame. Component-level minimum: **~500ms**. Page-level minimum:
**~600ms**. This is centralized in one shared hook/mechanism (not per-screen ad hoc timers) and
applied uniformly at both levels. Explicitly rejected: a flat 1–3s minimum applied everywhere — that
would make fast interactions (an 80ms save) feel deliberately slowed down, the opposite of "the
system is always responsive."
**Why:** Andrii wanted to eliminate spinner flicker on very fast operations (50–100ms) and asked for
smooth, always-present-for-a-beat loading animations; standard perceived-performance practice (and
the existing `04-loading-and-feedback.md` §10 guidance of ~150–200ms delay / ~400ms minimum) caps the
minimum well under a second specifically to avoid making fast operations feel slow — 500/600ms is a
small upward adjustment from that existing guidance for a slightly more deliberate, smoother feel,
not the 1–3s originally floated.
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/usePerceivedLoading.ts` (the shared hook), wired into
`heediq-web/src/lib/useAsyncAction.ts` (component level, 150ms/500ms) and
`heediq-web/src/components/ui/FullPageLoading/README.md` — used by `ProtectedRoute.tsx`,
`HomePage.tsx`, `AuthCallbackPage.tsx`, `SettingsLinkCallbackPage.tsx` (page level, 150ms/600ms)

### D-123 · Extract-on-second-duplication — standing DRY/SOLID architecture rule (2026-07-17) — Locked
**Area:** Architecture
**Decision:** Any UI or behavior pattern — loading/error/success sequencing, transition timing,
async/callback handling, or any other repeated logic shape — that appears (or is about to appear) in
**two or more places** must be extracted into one shared component/hook/utility and consumed by both,
never hand-copied with a "see X" comment pointing at the other instance. This generalizes what
D-117 (motion system), D-120 (double-submit guard), and D-122 (perceived-loading timing) already did
for their specific surfaces into a standing rule that applies going forward to any pattern, not just
those three. A second copy of the same logic is the trigger to extract — don't wait for a third.
**Why:** Found via a concrete bug: `AuthCallbackPage.tsx` and `SettingsLinkCallbackPage.tsx` both
hand-copied the same "loading vs. error" branching around `usePerceivedLoading`, and both copies
carried the identical race (the error branch rendered whenever `showLoading` was `false`, without
checking `failed` — true both when a fast failure hides the spinner *and* momentarily on mount before
the delay timer fires) causing a real error-page flash right after a successful Google sign-in. Fixing
each file separately treats the symptom; only extracting the shared logic into one place fixes the
defect once and prevents the same class of bug recurring in a third callback page later (D-113 root-
cause-over-symptom).
**Supersedes:** —          **Superseded by:** —
**Related code:** `heediq-web/src/lib/auth/README.md` (OAuth callback flow), the new shared
OAuth-callback component/hook extracted to fix the flash (see task in progress)

### D-124 · Context Library generalizes north-star scope beyond dev-work to any life domain (2026-07-20) — Locked
**Area:** Product
**Decision:** The Container/Source north-star model (D-068/D-069, `product.md`) is generalized now,
at requirements-design time, into a **Context Library** spanning any life domain a user organizes
activity around — work/project contexts, study, personal/home (e.g. groceries, receipts) — not just
dev-team technical requirements. The data model and UX are designed generically from this pass even
though the build order still ships the dev-team use case first (D-069's MVP v1 scope/build order is
unchanged). A coarse top-level "Domain" categorization (e.g. Work/Study/Personal) is under
discussion, not yet locked — see Open section.
**Why:** Avoids a data-model rewrite later, consistent with why D-068 already chose generic
Source/Container naming over meeting-specific terms.
**Supersedes:** — (extends D-069's framing; does not change its MVP build order) **Superseded by:** —
**Related code:** `memory/business/product.md`, `memory/business/BACKLOG.md`

### D-125 · Context Library — auto-first classification, no manual merge/split at MVP (2026-07-20) — Locked
**Area:** Product
**Decision:** On ingest, Heediq auto-classifies new source data against the user's existing Contexts
(or proposes creating a new one), generates a summary + labels, and requires user approval of the
auto-labeling/classification before the data is added to that Context's accumulated memory. No
manual context merge/split UI at MVP — the auto-classification + approval step is the only
correction mechanism.
**Why:** Keeps the human-in-the-loop trust check (already the north-star design intent in
`product.md`) while avoiding a heavier manual context-management UI before real usage shows whether
auto-classification is accurate enough to need one.
**Supersedes:** — **Superseded by:** —
**Related code:** —

### D-126 · Context Library — output generation via chat, not fixed one-shot templates (2026-07-20) — Locked
**Area:** Product
**Decision:** Generating an output from a Context (technical requirements, test plans, acceptance
criteria, stakeholder slides, or anything else) happens through a chat interface scoped to that
Context, backed by the Claude API: the assistant's context is the Context's accumulated
labeled/summarized data, plus a system prompt, plus the user's own free-form prompt. Predefined
starter prompts are offered as shortcuts, but the primary interaction is open chat, not a fixed set
of one-shot generation templates.
**Why:** A closed set of templates can't anticipate every output a user wants from their accumulated
context (dev requirements today, slides or a grocery list tomorrow); chat generalizes to any output
without predicting it up front.
**Supersedes:** — **Superseded by:** —
**Related code:** —

### D-127 · Context Library — Domain is a predefined, behavior-bearing type (2026-07-20) — Locked
**Area:** Product / Architecture
**Decision:** A **Domain** is a predefined system type (initial set: `work`, `study`, `personal`)
that categorizes Contexts and, critically, is not a bare label but a **behavior profile** — each
Domain carries an *extraction profile* (which structured fields the summarizer pulls), a set of
*starter prompts* (chat-output shortcuts, D-126), and *classifier hints* (framing for the ingest
auto-classifier). Domains live as a versioned constant in `@heediq/shared` (like the permission
catalog), **not** per-org DynamoDB rows, and are not user-editable at MVP. Adding a Domain is a code
change, not a schema migration. Every **Context** belongs to exactly one Domain. Fully user-defined
domains are deferred (`BACKLOG.md`). This resolves D-124's open taxonomy question.
**Why:** The ingest pipeline must know *what shape to extract* and *what outputs make sense* before
it can file data — a freeform user string can't drive the summarizer, the classifier, or the output
prompts. A small predefined set with behavior config is what makes auto-classification (D-125) and
chat output (D-126) work; open-ended domains would leave those three surfaces undriven.
**Supersedes:** — (resolves D-124's open item) **Superseded by:** —
**Related code:** `heediq-shared/src/` (Domain enum + profile constant), `memory/business/product.md`

### D-128 · Context Library — one Context per Source at MVP (2026-07-20) — Locked
**Area:** Product / Architecture
**Decision:** A Source attaches to **exactly one** Context (the auto-classified, user-approved one),
narrowing D-068's "one or more Containers." The classifier proposes a single best Context (or a new
one); the user approves or reassigns. `labels[]` (D-068) remains the mechanism for cross-cutting
multi-tag. Multi-Context attach is deferred to `BACKLOG.md`.
**Why:** Matches auto-first single classification (D-125) and drops significant model complexity —
no multi-select review UI, no shared-source dedupe when assembling a Context's memory for chat.
**Supersedes:** D-068 (source-multiplicity only — Source rename, self-nesting, `labels[]` unchanged) **Superseded by:** —
**Related code:** `heediq-shared/src/domain.ts` (Source gains `contextId`), `memory/business/product.md`

### D-129 · Context Library — rename Container entity to Context (2026-07-20) — Locked
**Area:** Architecture
**Decision:** D-068's "Container" entity is renamed **Context** everywhere: entity `Context`, table
`heediq-contexts`, `contextId`, self-referencing `parentContextId`. Aligns the code/table name with
the Context Library product language (D-124). Free to do now — the Container half of D-068 was never
built (no `heediq-containers` table or schema exists; only the Source half shipped).
**Why:** Keeps product vocabulary and code vocabulary in sync from the first line of the entity's
implementation, instead of permanently splitting "Context" (UI) from "Container" (code).
**Supersedes:** D-068 (entity naming only — Source naming and self-nesting concept unchanged) **Superseded by:** —
**Related code:** `heediq-shared/src/`, `heediq-infra/lib/foundation/`, all consumers (once built)

### D-130 · Context Library — combined classify+extract in the summarization worker (2026-07-20) — Locked
**Area:** Architecture / Cost
**Decision:** Ingest classification and structured extraction run as **one combined Claude call**
inside the existing summarization worker (`heediq-worker-summarization`) — no separate classifier
Lambda. Given the content + the user's existing Contexts (name/desc/domain) + the Domain profiles
(D-131), the call returns *both* a **classification proposal** (proposed Context or new-context
name, Domain, `labels[]`) *and* the extraction in the proposed Domain's shape (D-132). The proposal
carries a **domain-fit confidence score** (0–1); below a configurable threshold (~0.75, one constant
in `@heediq/shared`) the Source is filed to the catch-all **`other`** Domain (D-131) instead of a
low-confidence guess, and the review card flags it for the user to place. **Cross-domain
reassignment** during review (user moves the Source to a Context in a *different* Domain) triggers a
cheap **re-extract** in the new Domain's shape; same-domain reassignment does not.
**Why:** One call is the cheapest correct resolution of the extract-needs-domain / domain-needs-
classify circular dependency; the confidence score + `other` fallback keeps auto-first (D-125) honest
about uncertainty without requiring user-defined domains yet (deferred, `BACKLOG.md`).
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-worker-summarization/`, `heediq-shared/src/` (confidence threshold constant)

### D-131 · Context Library — Domain profile set: work / study / personal / other (2026-07-20) — Locked
**Area:** Product / Architecture
**Decision:** The predefined Domains (D-127) and their behavior profiles are:
- **work** — `extractionFields`: requirements, decisions, openQuestions, actionItems · starter
  prompts: technical requirements, test plan & acceptance criteria, stakeholder slides, risks &
  open questions. (This is today's summarizer behavior, now one profile among several.)
- **study** — `extractionFields`: keyConcepts, definitions, questions, references, actionItems ·
  starter prompts: study guide, flashcards (Q&A), practice quiz, key-concepts summary.
- **personal** — `extractionFields`: items, amounts, dates, notes · starter prompts: shopping
  list, spending summary, upcoming dates & reminders, checklist. (Deliberately generic — spans
  groceries/receipts/appointments.)
- **other** — catch-all for low domain-fit confidence (D-130). Generic `extractionFields`:
  keyPoints, actionItems, notes. No specialized starter prompts (generic summarize/extract).
Fields and prompts are a starting point, refined as real usage shows gaps; adding/adjusting a
profile is a code change (D-127), not a schema migration.
**Why:** Gives the summarizer a concrete per-domain extraction shape and the chat concrete starter
prompts (D-126); `other` provides a safe home when confidence is low without inventing a domain.
**Supersedes:** — (fills in D-127's profile bodies; adds `other` to D-127's initial enum) **Superseded by:** —
**Related code:** `heediq-shared/src/` (Domain enum + `DOMAIN_PROFILES` constant)

### D-133 · Context Library — `classification_ready` WS event + review-gate Source state (2026-07-20) — Locked
**Area:** Architecture
**Decision:** Ingest surfaces the human review gate (D-125) through a **new `classification_ready`
WS event** (added to `WsEventPayloadMap`, `heediq-shared/src/ws.ts`, additive per D-109) carrying
`{sourceId, proposedContextId | newContextName, domain, labels[], confidence}` so the review card
renders live without polling (D-111). The proposal is persisted on the Source as
`proposedClassification` (cleared on approval); the Source gains a `classification` axis
(`pending_review` → `approved`) separate from its existing `status`. Frontend stage flow (plain
language): Uploading → Transcribing (audio only) → Analyzing → **Ready for your review** → Filed in
[Context]. Every stage is a visible step via the existing `job_status` stream plus this event; the
review is an explicit, unmissable state, never a silent auto-file.
**Why:** The review gate needs a richer payload than plain `job_status` (the proposal itself);
pushing it over WS keeps the ingest process fully visible and interactive end to end, which is a
hard product requirement, not polish.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/ws.ts`, `heediq-shared/src/domain.ts` (Source fields),
`heediq-web/src/lib/ws/`, `heediq-worker-summarization/`

### D-134 · Context Library — nested Contexts (epic/story) are in MVP scope (2026-07-20) — Locked
**Area:** Product
**Decision:** The self-nesting `parentContextId` (D-129, from D-068) is **used at MVP**, not
deferred: a Context can nest sub-Contexts (project → epic → story, or any user-meaningful depth).
A Source files into a single Context at any level of the tree (D-128). Chat and context-memory
assembly at a parent Context include its descendants' memory (a parent sees its children's Sources).
**Why:** Andrii confirmed the epic/story hierarchy is core to how projects are organized; the
self-nesting table already supports it at zero extra schema cost, so there's no reason to ship a
flat-only v1 and retrofit nesting later.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/` (Context `parentContextId`), `heediq-web/` (context tree UI)

### D-135 · Context Library — item-level `ExtractedItem` model (supersedes D-132) (2026-07-20) — Locked
**Area:** Architecture
**Decision:** Structured extraction is stored as individually addressable **`ExtractedItem`** records,
not flat arrays on `Summary`. Shape: `{ itemId, sourceId, contextId?, orgId, category, text,
confidence, sourceQuote?, status: 'proposed'|'kept'|'discarded' }`, where `category` is one of the
filed Domain's `extractionFields` (D-131). The review wizard (D-137) curates each item
(keep/recategorize/edit/discard); only `kept` items become durable Context memory. `Summary` shrinks
to `transcript` + a short prose gist. A Context's chat memory (D-126) = all `kept` items across the
Context **and its descendants** (D-134), grouped by category, with **full Source content still
stored and available** as a detail fallback so extraction is never lossy.
**Why:** Item-level records are required for one-by-one review curation, per-item provenance back to
the transcript quote, and the kept/discarded distinction — none of which a flat `Record<field,
string[]>` (D-132) can persist. Realizes product.md's long-stated "extraction proposes, user decides
what's kept."
**Supersedes:** D-132 (extraction storage shape — domain-keyed categorization survives as `category`) **Superseded by:** —
**Related code:** `heediq-shared/src/`, `heediq-worker-summarization/src/writer.ts`, `heediq-web/`

### D-136 · Context Library — Context Decision Ledger (design now, build fast-follow) (2026-07-20) — Locked
**Area:** Product / Architecture
**Decision:** Each Context carries a **Decision Ledger** — a curated, deduplicated, context-level
roll-up of key decisions and open questions across all its Sources (distinct from per-source
`ExtractedItem`s). Entry shape: `{ entryId, contextId, topic, answer|null, status:
'confirmed'|'needs_review'|'open', confidence, origin: 'auto'|'user'|'chat_prompted', sourceRefs[] }`.
An auto-answer with **confidence < ~0.50** (a separate threshold from D-130's ~0.75 domain-fit) is
flagged `needs_review`; a decision with no supporting data is `open` for the user to fill.
**Chat-time gating:** before generating, chat checks which ledger entries are prerequisites for a
quality answer; if required entries are `open`/`needs_review`, it asks the user to fill them first,
then generates. **Scope:** the ledger fields/table are designed into the data model **now** (no later
rewrite), but ledger generation + fill-in UI + chat-time gating **build as a fast-follow** after the
core loop (ingest → classify/extract → review wizard → file → chat over extraction) ships. The core
loop is MVP; the ledger is the immediate next phase.
**Why:** The ledger is the "precise context" differentiator and generalizes Heediq's founding vision
(turn discussion into specs without months of clarification) into a standing per-context artifact;
staging it after the core loop de-risks MVP while keeping the model rewrite-free.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/`, `heediq-api/`, `heediq-web/`

### D-137 · Context Library — interactive 3-step review wizard (2026-07-20) — Locked
**Area:** Product / Design
**Decision:** The post-ingest human gate (D-125/D-133) is a **step-by-step wizard**, not a single
card, showing results progressively as the user answers: **(1) Placement** — confirm the proposed
Context, pick a different one (context-tree picker), or create a new Context (name + Domain), incl.
placing into a sub-Context (D-134); **(2) Extraction curation** — each `ExtractedItem` one by one
(text + proposed category + source quote) → keep / recategorize / edit / discard (only `kept`
persists, D-135); **(3) Ledger reconciliation** — new/changed ledger entries and any newly
`open`/low-confidence ones to approve or fill (this step activates with the D-136 fast-follow; the
core loop ships steps 1–2). All steps use kit components + the motion system; no silent auto-file.
**Why:** Andrii wants the approval interactive and one-by-one — suggestions surfaced and confirmed
step by step (placement, then labeling each extraction, then decisions) rather than a bulk
yes/no — which builds trust and produces cleaner curated memory.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/features/` (review wizard), `heediq-web/src/components/`

### D-138 · Context Library — Context chat persistence model (2026-07-20) — Locked
**Area:** Architecture
**Decision:** Output generation (D-126) persists as **multiple named conversations per Context**
(ChatGPT-style threads — e.g. "Tech spec draft", "Stakeholder deck"), not a single running thread.
Two new tables: **`heediq-conversations`** (`conversationId` PK, `contextId`, `orgId`, `userId`,
`title`, `createdAt`, `updatedAt`; GSI `by-context` PK=`contextId`) and **`heediq-chat-messages`**
(PK=`conversationId`, SK=`ts#messageId`, `role` 'user'|'assistant', `content`, `model?`,
`createdAt`). Conversations and messages are durable artifacts the user returns to (a generated test
plan/deck), not ephemeral chat.
**Why:** Users generate several distinct outputs from one Context; separate threads keep them
organized and each output recoverable, versus one shared transcript.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/`, `heediq-infra/lib/foundation/`, `heediq-api/`, `heediq-web/`

### D-139 · Context Library — dedicated `heediq-chat` worker, streamed over WS with prompt caching (2026-07-20) — Locked
**Area:** Architecture / Cost
**Decision:** A chat turn runs as an **async job in a new dedicated `heediq-chat` worker Lambda**
(300s, SQS-triggered — mirrors the summarization worker, D-065), never in the 30s `heediq-api`
Lambda (a long generation would truncate and block a request thread, `07-engineering-standards.md`
§6). Flow: `POST /conversations/:id/messages` persists the user message and enqueues a chat job →
the worker assembles the Context's memory (kept `ExtractedItem`s + Decision Ledger + full-source
fallback, D-135/D-136), calls `client.messages.stream()`, and **streams tokens live** to the user
via the existing WS framework (`wsPush.ts` direct `PostToConnection`, D-109) — batched into a new
`chat_delta` `WsEventPayloadMap` event (~100ms cadence), finalized by a `chat_complete` event; the
final assistant message is written to `heediq-chat-messages`. The API Gateway HTTP API buffers
responses so token streaming rides WS, not the REST path (D-111 — no silent wait, no polling).
**Prompt caching (mandatory):** the assembled Context-memory block (system prompt + kept items +
ledger) is a large stable prefix reused across every turn — place a `cache_control` breakpoint after
it so only the new user turn is uncached; a Context's memory can be large and this is the primary
cost lever for chat. Model follows the tier mapping (D-067): free→Haiku, paid→Sonnet, same as
summarization.
**Why:** Long generations need a >30s runtime and must not block the API; WS streaming keeps the
system responsive token-by-token; prompt caching turns an otherwise expensive large-context
per-turn cost into a ~0.1× cache read after the first turn.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/lib/chat/` (new stack), `heediq-chat` worker repo, `heediq-shared/src/ws.ts` (`chat_delta`/`chat_complete`), `heediq-api/src/routes/`, `heediq-web/src/lib/ws/`

### D-140 · MVP v1 synthesis step reconciled to the Context Library (2026-07-20) — Locked
**Area:** Product
**Decision:** D-069's "container-level synthesis" — a single one-shot structured
technical-requirement output view over a Container — **is the Context Library** (D-124–D-139). The
final build-order step of D-069 ("multi-source upload + container-level synthesis view") is replaced
by the Context Library flow: multi-source ingest → combined classify+extract → interactive review
wizard → file into a **Context** (renamed from Container, D-129) → **chat-based output generation**
(D-126/D-139) over curated `ExtractedItem`s + the Decision Ledger. Synthesis is therefore no longer
a single fixed tech-requirement output but any output the user asks for via chat, across any Domain
(D-127/D-131), not just work/dev.
**Unchanged from D-069:** multi-source ingestion (PDF/doc/image + audio) is in MVP v1; the critical
path **auth/onboarding → home/Listen → recordings library → source detail/summary** is unchanged
(source detail now surfaces curated `ExtractedItem`s); org/billing and calendar/meeting-bot settings
remain follow-on. So the Context Library spec's build order (`plans/context-library-spec.md` §11)
**is** the MVP v1 plan for everything from source-detail onward — not a separate track.
**Why:** Andrii confirmed reconciling D-069 with the Context Library. The generalized chat-over-a-
Context model (D-124–D-139) is a strict superset of D-069's synthesis intent; keeping D-069's
narrower "single synthesis view" wording would be a stale constraint that contradicts the locked
Context Library design.
**Supersedes:** D-069 (synthesis-output mechanism + final build-order step only — multi-source scope
and the sequence through source-detail unchanged) **Superseded by:** —
**Related code:** `plans/context-library-spec.md`, `memory/business/product.md`

### D-141 · Context Library — Context visibility model: personal / group / org, permission-gated (2026-07-21) — Locked
**Area:** Product / Architecture
**Decision:** A Context carries a `visibility: 'personal' | 'group' | 'org'` axis so the library can
show a user everything available to them — their own plus what's shared — grouped by Domain.
`personal` = owner only; `group` reuses an existing D-102 RBAC group; `org` = whole org. Publishing
to a group or org gates on a new `context:share` RBAC permission (D-106/D-107); creating a personal
Context is not gated beyond org membership.
**Why:** Andrii confirmed the library must surface org-shared and personal Contexts together, grouped
by Domain. Reusing RBAC groups avoids inventing a new sharing primitive.
**Supersedes:** — (extends D-129/D-134 Context model; builds on D-102 groups, D-106/D-107
permissions, D-021 isolation) **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/README.md` §"Context Library tables" (key/GSI design),
`heediq-shared/src/context.ts`, `heediq-api/` (context routes + writer)

### D-142 · Context Library — cross-org Context sharing via regulated grants (design now, build fast-follow) (2026-07-21) — Locked
**Area:** Architecture / Policy
**Decision:** A Context can be shared **across org boundaries** to a specific external user through
an explicit, time-limited, revocable **grant** (`heediq-context-grants` table) — a deliberate,
strongly-regulated exception to the D-021 org-isolation invariant, never an implicit widening. Two
access tiers: `read` and `contribute` (implies `read`). Every cross-org read/write authorizes against
an active, unexpired grant at request time (never cached into the JWT); expiry is enforced in code,
not by DynamoDB TTL alone. Contributed data always homes in the Context's owner org, never copied
across orgs. Table/model ship now; grant issuance/revoke UI, authorization middleware, and invite
flow are a fast-follow (grants target existing Heediq accounts first, no magic-link flow yet).
**Why:** B2C sharing between individuals (D-143) and B2B cross-company collaboration both need one
person to use and optionally enrich another's accumulated Context; a per-user, expiring,
permission-scoped, audited grant is the minimal safe primitive that opens the org wall exactly as far
as the owner allows and no further.
**Supersedes:** — (regulated exception to D-021; builds on D-107 audit/permissions, D-141 Context
model) **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/README.md` §"Context Library tables" (key/GSI design,
TTL-vs-code-enforcement gotcha), `heediq-shared/src/` (grant schema + access enum), `heediq-api/`
(grant routes + cross-org authorization middleware)

### D-143 · Heediq serves B2B and B2C; org is the universal tenant boundary (2026-07-21) — Locked
**Area:** Product
**Decision:** Heediq is positioned for **both B2B and B2C**, not B2B-only. A **personal user is
modeled as a single-member org** — the same `org` tenant concept is reused, not a separate account
type — so one data model serves a company (shared Contexts around workloads/projects, via D-141
group/org visibility) and an individual (a dynamic personal digitized memory / Context Library).
Cross-individual sharing (family/friends) and cross-company collaboration both run through the same
**cross-org grant** primitive (D-142). No separate "consumer" schema, tenancy model, or code path.
**Why:** Reusing org-as-tenant for solo users means B2C is a positioning/onboarding surface over the
existing multi-tenant model rather than a second architecture; it also makes the personal-memory
use case (individuals accumulating and sharing their own Context Library) a first-class product line
alongside the B2B requirements-capture roots, widening the D-124 north-star audience.
**Supersedes:** — (broadens the B2B-only framing in `product.md` / `CLAUDE.md`; the D-124 "individuals or companies" platform vision is now explicit positioning) **Superseded by:** —
**Related code:** `memory/business/product.md`

### D-144 · Primary positioning is a contextual-memory platform; meetings are one ingestion path (2026-07-21) — Locked
**Area:** Product
**Decision:** Heediq's canonical top-line positioning is a **contextual-memory / "Context Library"
platform** — it ingests anything (meetings via record/transcribe, documents, notes, files),
auto-classifies/extracts it into structured memory, and lets users **chat over a Context** to
generate any output (requirements, decisions, specs, answers). Meeting recording & transcription is
**one ingestion path**, and the original requirements-capture → Jira/Confluence flow is the **first
vertical on top of it**, not the whole product. Every top-line product description (CLAUDE.md header,
`product.md` Vision, brand story) leads with the memory-platform framing, not "meeting-recording
platform."
**Why:** The product outgrew its meeting-transcription origin — D-124–D-126 (universal contextual
memory), D-141/D-142 (shared / cross-org Contexts), D-143 (B2B+B2C personal memory) all point at a
memory platform. Leading every description with "meeting-recording platform" mis-scopes and
undersells it and drifts from the locked platform vision; this aligns the elevator line with what is
actually being built. Scope, build order (`product.md` MVP build order), and the founding
requirements-capture use case are **unchanged** — only the framing/emphasis is elevated.
**Supersedes:** — (elevates the D-124 platform vision into canonical positioning; does not change scope or build order) **Superseded by:** —
**Related code:** `memory/business/product.md`, `memory/business/branding.md`

### D-145 · Context Library — `chat_failed` WS event for a failed chat turn (2026-07-22) — Locked
**Area:** Architecture
**Decision:** Add `chat_failed` (`{ conversationId, messageId, error }`) to `WsEventPayloadMap`
alongside `chat_delta`/`chat_complete` (D-139), pushed at user scope when the `heediq-chat` worker
fails a turn (Claude API error, timeout) after retries are exhausted.
**Why:** D-139 defined the success path only; without a failure event the frontend has nothing to
react to on a worker error and would spin indefinitely, violating D-111 (no silent wait).
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/ws.ts`, `heediq-chat` worker repo

### D-146 · Appending a permission requires backfilling existing orgs' system roles (2026-07-22) — Locked
**Area:** Architecture
**Decision:** Adding a `Permission` to `heediq-shared`'s `PERMISSIONS` catalog requires a one-off
migration that adds the new key to every existing org's system roles (`admin`/`member`) in
`heediq-roles`, per `DEFAULT_ORG_RBAC_SEED` intent — admin receives all permissions; member receives
the new key only if it is in the member seed. Custom (non-system) roles are never auto-touched, and
system roles stay fully editable. Complements D-106, which mandated the same migration discipline for
retiring/renaming a permission but was silent on the append case.
**Why:** System-role permission sets are frozen into `heediq-roles` at org provisioning and never
re-synced, so any org created before a catalog addition silently lacks the new permission — hit on
2026-07-22 when the dev admin org (provisioned 2026-07-16) had none of the Context Library `context:*`
keys and every Context route 403'd. Resolving system-role perms dynamically from the seed at issuance
was rejected because it would break the "system roles are fully editable after creation" property.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/README.md` (RBAC & audit trail)

### D-147 · Every feature ships a scripted E2E happy-path smoke against the deployed dev stack (2026-07-22) — Locked
**Area:** Process
**Decision:** Each user-facing feature ships with a scripted, repeatable end-to-end happy-path smoke
that runs against the real deployed `dev` stack (real auth token, real API, real WS/queue) covering
the feature's trivial success scenario end to end. These live in the owning repo's `tests/e2e/`
(Playwright per D-030 for browser journeys; a lightweight Node script is acceptable for headless
API+WS/queue flows such as Context chat). They run deliberately — after deploying a feature to `dev`
and before calling it done — not as part of the local pre-PR gate (consistent with D-030's layer
table). Extends D-030's E2E layer from "critical journeys only" to "a happy-path smoke per feature."
**Why:** Merged unit + integration tests passed for Context chat, yet the first real dev run surfaced
a deploy/config gap (stale RBAC seed, D-146) that no in-repo mocked test could catch. A cheap,
scripted, real-stack smoke per feature catches wiring/permission/deploy gaps and turns "confirm it
works on dev" into a repeatable artifact instead of a manual one-off.
**Supersedes:** — **Superseded by:** —
**Related code:** — (harness home: owning repo `tests/e2e/`; first instance is the Context-chat smoke)

### D-148 · Context Library — Decision Ledger generation is a review-time async reconciliation in a new `heediq-ledger` worker (2026-07-23) — Locked
**Area:** Architecture / Product
**Decision:** Ledger generation (D-136) runs as a **review-time async reconciliation pass**. On
review-approval, after the API commits the source's kept `ExtractedItem`s, it enqueues a ledger job
(`{ contextId, sourceId, orgId, tier }`) onto a new `heediq-ledger` SQS queue. A **new dedicated
worker** (SQS+Lambda, D-065 pattern — *not* the summarization or chat worker) loads the Context's
existing ledger + this source's kept items, makes **one prompt-cached Claude call** (D-139 free→Haiku
/ paid→Sonnet tier map), and **persists** reconciled entries with computed status — `confirmed`,
`needs_review` (auto-answer confidence < `LEDGER_REVIEW_CONFIDENCE_THRESHOLD` 0.5), or `open` (topic
with no answer) — appending `sourceRefs`; a previously-`confirmed` entry the new source changes flips
to `needs_review`. It then pushes a new `ledger_ready` WS event; the D-137 wizard step 3 reads via
`GET /contexts/:id/ledger` and fills. Persist-then-review (consistent with the D-135 ExtractedItem
model — no separate pending-proposal staging).
**Why:** The ledger is context-level and deduplicated, so reconciliation needs the chosen Context
(unknown at ingest) and an LLM to merge/dedup against prior entries — a review-time pass fits D-137's
"reconciliation" step. A dedicated worker keeps the Claude call off the 30s API Lambda (D-139) and
isolates ledger scaling/failure from ingest and chat. Chosen over ingest-time per-source candidates
(context-less, weaker dedup) and over folding it into an existing worker (mixed responsibility).
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/` (contracts), `heediq-ledger/` (worker, to be created)

### D-149 · Context Library — chat-time ledger gating is a simple all-or-nothing rule at `POST /conversations/:id/messages` (2026-07-23) — Locked
**Area:** Architecture
**Decision:** Chat-time gating (D-136) is enforced **synchronously in the API** at
`POST /conversations/:id/messages`, before persisting/enqueuing the turn: query the Context's ledger,
and if **any** entry is `open`/`needs_review` and the request didn't set `bypassLedgerGating`, return
a `LEDGER_GATED` response listing the blocking entries and do **not** enqueue. The user fills them
(ledger PATCH) and retries, or retries with `bypassLedgerGating: true`. No extra Claude call and no new
WS event — it's a cheap DynamoDB query (D-139 requires only the *generation* Claude call to be async).
Ledger mutations reuse the existing `context:update` permission (+ `canAccessContext` `'contribute'`
for cross-org grants) — no new permission, so no D-146 backfill. The heediq-chat worker is unchanged;
its `loadLedgerAnswers` (settled answers into the prompt) stays.
**Why:** An all-or-nothing rule is deterministic, adds zero model cost/latency, and is the right MVP
for the "precise context" gate; chosen over an LLM prerequisite-relevance pre-pass (better UX but a
Claude call on every gated turn) — revisit if the rule proves too aggressive. Enforcing in the API
(not the worker) avoids a wasted worker invocation and returns the block synchronously so the client
can prompt the fill without a WS round-trip.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-api/README.md` (conversations + ledger routes)

### D-150 · First Capture / Ingestion UI — all three D-026 input methods ship together (2026-08-03) — Locked
**Area:** Product / Design
**Decision:** The first Capture/Ingestion UI in heediq-web ships **all three** D-026 input methods in
the same test round — live mic recording, audio-file upload, and text-file upload — built as the full
D-026 Listen-centered post-auth landing (the "Listen" hero as primary CTA, audio-upload and text-upload
as secondary actions), with the recordings/sources library as a separate nav page (the real
`SourcesLibraryPage` list replaces its stub). Text upload skips transcription via a **dedicated
`POST /sources/:id/text`** endpoint (parallel to the audio `POST /sources/:id/jobs` enqueue): it writes
the text to `heediq-sources[sourceId].transcript` and enqueues a `SummarizationJobMessage`
(`sourceType:'text'`, `contentRef:sourceId`) to the summarization queue (D-065), which the worker and
downstream `classification_ready` → D-137 review wizard already handle. Live recording is online-only
for now (offline capture + queued upload + Wake Lock stay deferred, D-119).
**Why:** The capture UI is the #1 pre-dogfooding blocker (no way to get content in), so the round
targets a complete ingestion front door rather than a partial one; all three methods reuse one
create→process→review spine so the incremental cost of the two upload paths on top of record is small.
A dedicated `/text` endpoint (over overloading `POST /sources` with an optional text body) keeps the
create route single-purpose and mirrors the existing audio enqueue split. The text path is chosen as
the first *implementation* slice because its backend gap is the smallest (worker + shared + infra grant
already built; only the API enqueue is missing) — fastest to real end-to-end content.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/features/sources/` + capture surface (to be built), `heediq-api/README.md` (`/sources/:id/text`)

### D-151 · Product-analytics vendor: Amplitude (free tier) for user-journey instrumentation (2026-08-04) — Locked
**Area:** Architecture / Product
**Decision:** Amplitude is the product-analytics tool for Heediq, starting on its **free tier** (sufficient
for the dogfooding phase; revisit packaging only when event volume or feature needs outgrow free). The
first instrumentation pass covers the **MVP critical-path funnel** — capture started (by method:
record/audio/text) → source created → source ready → review wizard opened → items kept → Context
chat sent — instrumented in heediq-web plus the key backend completion events. The ready milestone is
named `source_ready` (not `transcription_ready`) because it fires off the `classification_ready` WS
event for the *outcome* (a Source is ready to review) — text sources skip transcription entirely, so a
transcription-specific name would be wrong for them. Every event carries
**ids/metadata only, never transcript / message / PII text** (D-093). The event taxonomy stays small and
additive: expand only where the dogfood surfaces a real drop-off worth resolving. No self-hosted or
alternative analytics stack is added.
**Why:** The internal dogfood needs activation/funnel/drop-off signal to be worth running (otherwise it
yields anecdotes, not learning); Amplitude's free tier delivers this at zero cost with no infra to build,
and its event model maps cleanly onto the capture→review→chat funnel. Restricting instrumentation to
ids/metadata keeps analytics inside the existing privacy posture (D-093) so it never becomes a PII sink.
Scoping v1 to the critical path avoids over-instrumenting before real usage shows which questions matter.
**Supersedes:** — (scopes the "Product analytics / user-journey instrumentation" engineering-backlog item) **Superseded by:** —
**Related code:** `heediq-web/src/lib/analytics/` (the single client boundary + funnel/fire-site table in its README), `heediq-shared/src/logger.ts` (D-093 privacy boundary this must respect)

### D-152 · Mobile-first primary navigation: bottom tab bar (mobile) + top bar (desktop), secondary/destructive actions in Settings (2026-08-05) — Locked
**Area:** Brand & Design
**Decision:** Heediq's primary navigation is a fixed **bottom tab bar** on phones (`BottomTabBar`,
`md:hidden`, thumb-reachable, safe-area-padded) and a **top bar** on desktop (`TopBar`,
`hidden md:flex`). Both render from a single source of truth (`heediq-web/src/components/layout/nav-items.ts`)
so the two surfaces can never drift, and both are permission-gated identically. A top-only menu is not
an acceptable mobile pattern. **Secondary and destructive actions — logout, account — live inside the
Settings page, never in primary nav**; logout was deliberately removed from the top bar and buried in a
Settings "Account" card. The app content sits in a `<main>` with `pb-bottom-nav md:pb-0` so the fixed
bar never overlaps the last row.
**Why:** The MVP shipped with a desktop-style top menu that overflowed and was unreachable by thumb on
phones — wrong for a mobile-first PWA (D-119/D-121). The bottom tab bar is the platform-native mobile
pattern; keeping a desktop top bar preserves the wider affordance where there's room. One `nav-items`
source removes the classic drift bug (nav added in one place, missing in the other). Burying logout in
Settings stops an easily-mis-tapped destructive action from occupying prime thumb real estate while
keeping it discoverable.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/components/layout/` (`nav-items.ts`, `BottomTabBar.tsx`, `TopBar.tsx`, `AppShell.tsx`, README), `rules/03-ui-kit.md` §7.3

### D-153 · Mobile-first responsive layout system: PageContainer/PageHeader frame, table→card reflow, no-horizontal-overflow invariant guarded by Playwright (2026-08-05) — Locked
**Area:** Brand & Design
**Decision:** Every authenticated screen is framed by two mandatory layout primitives —
**`PageContainer`** (centralised max-width, mobile-first gutter `px-4 sm:px-6 lg:px-8`, vertical rhythm)
and **`PageHeader`** (`h1` + description + actions row) — replacing hand-rolled `mx-auto max-w-* p-*`
wrappers, which are now a layout-layer golden-rule violation. Genuine full-height split layouts (e.g.
the Context Library master/detail) are the documented exception. Data **tables reflow to stacked cards
below `sm` (640px)** (industry best practice): each row becomes a bordered card and each cell a
`label: value` line via `Table.Cell`'s `label` prop — no horizontal scroll for primary content. The
governing invariant is **no horizontal page overflow at any supported width (320/375/768/1280)**,
enforced by a package-local **Playwright responsive harness** (`heediq-web/e2e/responsive.e2e.ts`,
`pnpm test:responsive`) asserting `scrollWidth ≤ viewport` on every backend-free route. Tap targets are
≥44px and fixed/bottom elements respect device safe areas (`viewport-fit=cover` + `env(safe-area-inset-*)`).
A missing `h1` type token (page titles silently fell back to body size) was fixed as part of this.
**Why:** The MVP UI overflowed horizontally on phones, mis-sized page titles, and let every page invent
its own width/padding — the visible symptoms of having no shared page frame and no objective responsive
gate. A `scrollWidth ≤ viewport` assertion is machine-checkable and catches what screenshot review
misses (an un-shrinkable flex child, a wide table, a long token). Reflowing tables to cards is the
established mobile pattern for tabular data and removes the last common source of horizontal scroll.
Centralising the frame in `PageContainer`/`PageHeader` means a future spacing or breakpoint change is
one edit, not N.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-web/src/components/layout/` (`PageContainer.tsx`, `PageHeader.tsx`), `heediq-web/src/components/ui/Table/` (reflow), `heediq-web/e2e/` + `playwright.config.ts`, `rules/03-ui-kit.md` §7, `rules/05-testing.md`
