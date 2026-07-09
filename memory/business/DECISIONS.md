# Heediq Decisions Log (DECISIONS.md)

Canonical, append-only record of locked decisions — the business-memory source of truth. Capture and
format per `rules/09-decisions.md`. Read this at the start of every chat; locked decisions are
constraints.

Fully-superseded decisions (no substantive content still active) live in
`DECISIONS_ARCHIVE.md`, not here — this file stays lean. A decision only moves there once its
superseding entry restates whatever part of it is still true; partially-superseded decisions
(e.g. "mechanism only" / "X unchanged" annotations) stay here.

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
**Decision:** Logo = four angled (−12°) amber slabs forming an h+q monogram (exact SVG in
`branding.md` — reproduce verbatim, do not redesign). Name layers "heed" + "HQ" + "IQ"; the four
slabs also visually represent "HQ". Domain: heediq.com. Full asset library generated
(`heediq-brand-assets.zip`).
**Related:** `memory/business/branding.md` (verbatim SVG, brand story, taglines, asset list)

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
(owner/admin), no separate personal account type. Roles: Admin (billing, seats, member
management, sees all org content) and Member (own content only). No per-recording sharing at
launch (deferred).
**Why:** keeps the data model unified across personal and team accounts.
**Related:** `memory/business/product.md`
**Superseded by:** D-102

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
**Related:** `memory/business/product.md`

---

## Process (this workspace)

### D-012 · Workspace rules & memory repo — Locked (2026-06-15)
**Area:** Process
**Decision:** Adopt `heediq-workspace` as the canonical repo for Claude's rules, memory, and
plans, hosted at github.com/admin-heediq/heediq-workspace. Root `CLAUDE.md` imports the modular
rule set; memory is split into business + codebase tracks.
**Why:** one shared, version-controlled contract and memory for the team.
**Superseded by:** D-046

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
**Decision:** SSM Parameter Store paths: `/heediq/{service}/{param}` — e.g. `/heediq/api/cognito-user-pool-id`. Secrets Manager paths: `/heediq/{service}/{secret}` — e.g. `/heediq/api/stripe-secret-key`. No environment prefix in either (account-scoped). CDK injects non-secret config (table names, bucket names, Cognito IDs) as Lambda environment variables at deploy time. Actual secrets (Stripe key, Claude API key, Recall.ai key) are fetched from Secrets Manager at Lambda cold start.
**Why:** Account boundary makes env prefix redundant. Separating config (env vars, fast) from secrets (Secrets Manager, secure) avoids SSM latency on every config value while keeping secrets out of the Lambda console.
**Supersedes:** —
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
**Decision:** Seven repos under the `heediq` GitHub org (renamed from `admin-heediq`, D-046):
- `claude-workspace` — rules, memory, plans (renamed from `heediq-workspace`, D-046)
- `heediq-shared` — `@heediq/shared`: Zod schemas + TypeScript types, private GitHub Package
- `heediq-web` — Vite + React PWA
- `heediq-api` — Hono on Lambda (all REST endpoints)
- `heediq-worker-transcription` — Python, EC2 GPU Spot (faster-whisper, per D-059/D-060 — supersedes the original Fargate CPU plan, D-004/D-005)
- `heediq-worker-summarization` — Node Lambda (Claude API extraction, per D-032)
- `heediq-infra` — AWS CDK (all stacks, all envs per D-036)
**Why:** Microservice-level granularity — workers split because they have different runtimes (Python vs Node) and scaling/cost profiles; shared types in own package consumed across repos; infra separated from application code. Not feature-level (too many repos) and not monorepo (polyrepo locked).
**Supersedes:** — **Superseded by:** D-046 (org/repo names only — the 7-repo split itself stands)
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
**Supersedes:** — **Superseded by:** D-058
**Related code:** `heediq-infra/`

---

### D-058 · SES identity in shared-services account; cross-account role for workload sending (2026-06-19) — Locked
**Area:** Architecture / Infra
**Decision:** The `heediq.com` SES email identity lives in the shared-services account (alongside Route 53). DKIM CNAME records are created in the same CDK stack with no cross-stack dependency. Workload account Lambdas send email by assuming IAM role `heediq-ses-email-sending` (in shared-services account). Role ARN exported to workload accounts via SSM at `/heediq/api/ses-sending-role-arn`.
**Why:** Avoids SharedServicesStack depending on FoundationStack outputs (reverse dependency). SES identity and its DNS records are self-contained in the one account that owns Route 53 — simpler, no two-step deploy dance. Cross-account role assumption is standard IAM; no SES-specific policy quirks.
**Supersedes:** D-054 (extends — D-054's choice of SES still stands; this locks the placement)
**Superseded by:** D-095 (Cognito OTP email only — adds a per-workload-account SES identity solely for
Cognito's native confirmation emails; this decision's cross-account role for app-initiated Lambda
sends is otherwise unchanged)
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`, `heediq-infra/lib/foundation/foundation-stack.ts`

---

### D-055 · Compute resource sizing at launch (2026-06-17) — Locked
**Area:** Infra / Cost
**Decision:** All environments (dev/staging/prod) start at identical minimum viable resource settings. Scale up when real traffic demands it — no environment differentiation at launch.
- **Fargate — free-tier transcription task** (whisper small, CPU): 1 vCPU, 2 GB RAM
- **Fargate — paid-tier transcription task** (whisper large-v3 + pyannote, CPU): 4 vCPU, 8 GB RAM. Note: Fargate has no GPU support; large-v3 runs on CPU via Fargate Spot (acceptable for async batch jobs).
- **Lambda — API (Hono, D-034)**: 512 MB, 30s timeout
- **Lambda — summarization worker (D-032)**: 512 MB, 5 min timeout
- **DynamoDB**: `PAY_PER_REQUEST` (on-demand) in all environments — no baseline cost, auto-scales, right for zero-to-low traffic
- **CloudFront price class**: `PriceClass_100` (US + EU edge locations) — fits EU SaaS target market; ~40% cheaper than all-regions
**Why:** No production traffic to justify larger sizing at launch. All settings are reversible CDK config values — scale up when metrics show need.
**Supersedes:** — **Superseded by:** D-059 (transcription Fargate lines only; Lambda/DynamoDB/CloudFront sizing unchanged)
**Related code:** `heediq-infra/`, `heediq-worker-transcription/`

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
**Decision:** Both transcription model variants (whisper small and large-v3+pyannote) run on EC2 Spot using g4dn.xlarge (T4, 16 GB VRAM, 4 vCPU, 16 GB RAM, ~$0.13–0.16/hr Spot in eu-west-1). Single instance type, single ASG (min=0, capacity-optimized), single ECS cluster — no separate pools per model. Fargate Spot task definitions and FARGATE_SPOT capacity provider replaced by an EC2 capacity provider backed by an Auto Scaling Group. Zero idle cost preserved (ASG scales to zero when queue empty). Cold start ~45–90s accepted for async batch. Spot interruption: worker catches SIGTERM, writes `status=retrying` to heediq-jobs, lets SQS visibility timeout expire and re-enqueue. AMI: AWS ECS-optimized GPU AMI (Docker + ECS agent + nvidia-container-toolkit pre-configured). g4dn.xlarge is the smallest CUDA GPU instance on AWS — no smaller option exists.
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
`sourceId`) — any ingested unit (audio, PDF, doc, image, pasted text), not just audio. Rename the
core "project" entity to **Container** (table `heediq-containers`, `containerId`,
self-referencing `parentContainerId`) — one generic self-nesting table gives project/epic/story
(or any depth) without separate tables per level. A Source attaches to one or more Containers and
carries a `labels: string[]` field for free-form multi-label tagging in addition to its container
association — labeling is not limited to "which container." Applies across `@heediq/shared`
schemas, DynamoDB table/field names in `heediq-infra` FoundationStack, and all consumers
(`heediq-api`, `heediq-worker-transcription`, `heediq-worker-summarization`, `heediq-web`).
Executed as a standalone rename PR across all five repos before further feature work, since dev
has no real data yet (cheapest point to rename).
**Why:** Supports the long-term universal-memory platform vision (`product.md`) without a costly
rename later once real data and more consumers exist. "Source" reads naturally as ingestion
input regardless of type; "Container" generalizes project/epic/story into one flexible hierarchy
instead of three narrowly-named tables.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-shared/src/`, `heediq-infra/lib/foundation/foundation-stack.ts`,
`heediq-api/`, `heediq-worker-transcription/`, `heediq-worker-summarization/`, `heediq-web/`

### D-069 · MVP v1 scope expanded to multi-source ingestion + container-level synthesis (2026-07-02) — Locked
**Area:** Product
**Decision:** MVP v1 expands beyond audio-only to include multi-source ingestion (PDF/doc/image
uploads alongside audio, already source-agnostic at the pipeline level per D-065) plus a
**container-level synthesis** capability: given multiple labeled Sources attached to the same
Container (e.g. meeting transcripts + a rules PDF + design-standard screenshots for one project),
generate a single structured technical-requirement output ready to implement, rather than the user
manually reconciling separate per-source summaries. Critical path (build order sequence
unchanged): auth/onboarding → home/Listen → recordings library → source detail/summary →
multi-source upload + container-level synthesis view. Org/billing and calendar/meeting-bot
settings remain follow-on.
**Why:** Validates the platform's core differentiator (ready-to-implement requirements assembled
from many source types, not months of clarification) at v1 instead of as a later fast-follow. The
source-agnostic SQS entry point (D-065) already exists, so the marginal build is upload UI +
container-level synthesis logic, not new pipeline architecture.
**Supersedes:** D-010 (scope only — build order sequence unchanged) **Superseded by:** —
**Related code:** `memory/business/product.md`, `plans/wip-app-repos-scaffold.md`

---

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
**Decision:** Email is the canonical, unique identity across every sign-in method (native password, Google, Microsoft) — never "one account per provider." `heediq-users` gains a `by-email` GSI (email lowercased/trimmed before every write and lookup — our own normalization, not relied on from Cognito) as the source of truth for "does this email exist, and does it have a password" (a `passwordSet` boolean we maintain ourselves, since Cognito's `InitiateAuth` deliberately returns the same generic error for "wrong password" and "no password set on this federated-only user" and cannot be used to distinguish them). The unified sign-in/sign-up screen is email-first: submit email → we look it up → branch to sign-up (not found), sign-in (found, `passwordSet=true`), or a **generic, non-disclosing** linking prompt (found, `passwordSet=false`): "This email uses a different sign-in method — check your email to set a password," never naming the provider. That prompt sends a one-time code via **Cognito's native ForgotPassword/ConfirmForgotPassword flow** (reused as-is, not custom-built) to set a password on the *existing* `sub` via the confirm-forgot-password path — no new Cognito user is ever created for an email that already exists. The equivalent flow for linking a second federated provider (e.g. already-Google, now trying Microsoft) uses the same "verify email ownership, then attach" shape but calls `AdminLinkProviderForUser` instead. Native-account-gets-federated-login-added is handled by Cognito's built-in "attributes for linking federated users" = `email` setting (auto-links when both sides assert a verified email) — this direction needs no custom code.
**Why:** Reactive, email-first linking (rather than exposing "sign up" vs "sign in" as separate entry points) prevents the exact failure mode Andrii flagged: a user unknowingly creating a second, disconnected account with the same email. Staying generic about which provider is already linked avoids handing an unauthenticated caller a provider fingerprint for a given email, at the cost of one extra click for the legitimate owner. Reusing Cognito's native ForgotPassword instead of building custom OTP delivery avoids owning an extra email-sending/code-verification path — **pending a spike to confirm ForgotPassword/ConfirmForgotPassword actually completes for a user whose `UserStatus` is `EXTERNAL_PROVIDER`** (this is not documented Cognito behavior we've verified yet; see Open/proposed below for the fallback if it doesn't).
**Supersedes:** — **Superseded by:** D-087 (ForgotPassword-reuse mechanism proven not to work, replaced via D-086 then D-087; identity model/GSI/passwordSet/generic-prompt parts of this decision stand unchanged)
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
**Decision:** Native sign-up (`SignUp`/`ConfirmSignUp`) and native sign-in (`InitiateAuth` USER_PASSWORD_AUTH) call Cognito **directly from the browser** — these are public Cognito APIs needing only the User Pool Client ID, no IAM credentials, no secret, and no new backend code. This matches the app's existing Hosted-UI OAuth pattern (already browser-direct). The linking OTP request itself is **no longer** one of these client-direct calls — see D-087 (superseding D-086, which itself superseded the `ForgotPassword`-for-linking part of this decision after the spike proved it doesn't work for `EXTERNAL_PROVIDER` users). The backend endpoints for the whole D-078 account-linking feature are: (1) `POST /auth/lookup-email` (already built — needs our own DynamoDB `by-email` GSI, which Cognito has no concept of), (2) `POST /auth/link/request-otp` and (3) `POST /auth/link/confirm` (D-087 — `SignUp`/`ConfirmSignUp` reused for code delivery/verification, then `AdminSetUserPassword` + `AdminLinkProviderForUser` server-side, flipping our own `passwordSet=true` in the same request) — needed both because Cognito has no concept of `passwordSet` at all, and because `ForgotPassword` itself is unusable for this case. `AdminLinkProviderForUser` (D-079's proactive Settings linking) also stays backend-only since it's an Admin API requiring IAM credentials the browser can never hold.
**Why:** Andrii wants maximum use of Cognito's own APIs and minimum custom backend code. Every operation Cognito can do unauthenticated from a public client should be called directly; backend code is added only where something is architecturally impossible client-side (our own DB bookkeeping, an Admin API needing IAM creds, or — per D-087 — a spike proving the public API doesn't support our case) — not for defense-in-depth on operations Cognito already secures itself.
**Supersedes:** — **Superseded by:** D-089 (native sign-up no longer stays fully client-direct — it now goes through the same backend verify-then-password flow as linking; the linking-OTP claim was separately corrected by D-087; native sign-in and the `lookup-email`/Admin-API split are unaffected and still stand)
**Related code:** `heediq-api/src/routes/auth.ts` (`lookup-email` done, `link/request-otp` + `link/confirm` pending per D-087), `heediq-web/src/lib/auth/` (native sign-up/sign-in — not yet built)

### D-083 · Proactive provider-linking uses a dedicated OAuth callback route (2026-07-04) — Locked
**Area:** Architecture
**Decision:** D-079's proactive "add a sign-in method" button in Settings, for a provider the user has never authenticated with before, needs one fresh Hosted-UI OAuth round trip through that provider so Cognito creates/knows the federated identity before `AdminLinkProviderForUser` can be called with its provider user id. That round trip lands on a **new, dedicated** `/settings/link-callback` route — separate from the existing `/auth/callback` used for normal login — rather than overloading the login callback with a state-param marker. This requires registering `/settings/link-callback` as an additional allowed callback URL on the Cognito app client (`heediq-infra` CDK change) before it works.
**Why:** A dedicated route keeps the login callback's logic (exchange code → establish session → redirect to `/sources`) uncontaminated by an entirely different post-redirect action (exchange code → extract provider user id → call the add-provider backend endpoint → stay on Settings). Reusing one route with a branching marker would couple two unrelated flows for a marginal savings of one CDK change.
**Supersedes:** — **Superseded by:** —
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts` (Cognito app client callback URLs), `heediq-web/src/routes/SettingsLinkCallbackPage.tsx` (not yet built), `heediq-api` `link/add-provider` endpoint (D-079, blocked on pnpm cooldown per D-082's related-code note)

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
Implemented across 5 repos. Merged to `develop`: `heediq-shared` (PR #13), `heediq-worker-transcription`
(PR #12, branch `feature/structured-logging-py`), `heediq-infra` (PR #41, branch
`feature/observability-stack`) — see D-093 for retention details. Still open on unmerged branch
`feature/structured-logging`: `heediq-api`, `heediq-worker-summarization`.

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
**Related code:** `heediq-shared/src/logger.ts` (0.6.0) and
`heediq-worker-transcription/src/logger.py` — level filtering +
`LOG_LEVEL` support implemented. `heediq-infra/lib/config.ts` `logRetentionFor(workloadEnv)` (30
days dev/staging, 90 days prod) applied to `ApiStack`, `SummarizationStack`, and
`TranscriptionStack`'s log groups. All three merged to `develop`
(`heediq-shared` PR #13, `heediq-worker-transcription` PR #12, `heediq-infra` PR #41).

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

### D-087 · Cross-provider linking reuses Cognito's native SignUp/ConfirmSignUp confirmation code, not custom OTP+SES (2026-07-04) — Locked
**Area:** Architecture
**Decision:** Replicating a working pattern from Andrii's own prior implementation
(`EmotiXOrg/emotix-infra`), linking a password to an existing `EXTERNAL_PROVIDER`-only user reuses
Cognito's **own** `SignUp`/`ConfirmSignUp` verification-code mechanism instead of building custom
OTP generation/storage/SES-sending (D-086). Flow: (1) `POST /auth/link/request-otp` calls Cognito's
`SignUp` with the user's email and a throwaway random password — this creates a **native** Cognito
user in `UNCONFIRMED` status and Cognito automatically emails its own confirmation code (via
Cognito's own SES-backed delivery — no app code touches SES directly for this). (2) `POST
/auth/link/confirm` calls `ConfirmSignUp` with the code (verifies it), then `AdminSetUserPassword`
(sets the real chosen password, `Permanent=True`), then `AdminLinkProviderForUser` (links the
existing federated identity — Google/Microsoft — onto this newly-confirmed native user via its
`ProviderAttributeValue`/`sub`), then flips our own `passwordSet=true` / writes the `METHOD#COGNITO`
DynamoDB row in the same request. Same non-disclosing UX as D-078/D-086 (generic prompt, no provider
named). If `SignUp` returns `UsernameExistsException`/`AliasExistsException` (user already mid-flow),
skip straight to `ResendConfirmationCode` rather than erroring.
**Why:** Cognito already owns code generation, expiry, delivery, and resend-rate-limiting for
`SignUp`/`ConfirmSignUp` — reusing it means zero custom OTP code (no DynamoDB TTL item design, no
hashing/storage, no SES template, no custom rate-limiting) versus D-086's fully hand-rolled
equivalent. This is a strictly smaller, already-proven implementation (Andrii built and ran this
exact pattern in `emotix-infra`) for the identical problem D-086 was solving. `AdminSetUserPassword`
and `AdminLinkProviderForUser` still require IAM credentials the browser never holds, so both backend
endpoints stay server-owned per D-082 — unaffected by this decision.
**Supersedes:** D-086 (custom OTP+SES mechanism only — the problem statement, non-disclosing UX, and
`passwordSet` semantics from D-078 are unchanged)
**Superseded by:** D-089 (scope only — generalized from linking-only to also cover native signup and
proactive settings-linking, and split into two sequential screens instead of one combined form; the
underlying SignUp/ConfirmSignUp-reuse mechanism defined here is kept)
**Related code:** `heediq-api/src/routes/auth.ts` (`link/request-otp`, `link/confirm` — built, see
D-089's Related code for the generalized version), `heediq-infra` (no new resources — no SES role
needed by app code for this path; D-058's SES role stays for other transactional email)

---

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
D-087/D-089) get three defense layers, built now: (1) **API Gateway throttling** (steady-state +
burst limit on the route) in every environment — stops raw request floods before Lambda even runs.
(2) **AWS WAF rate-based rule** (block an IP exceeding N requests per 5 min) attached to the HTTP
API, **prod only** — edge-level protection against a single-IP flood; not built for dev/staging to
keep local/CI testing unthrottled. (3) **App-level throttling keyed by email *and* IP**
(DynamoDB, fixed/sliding window) inside `request-otp`/`verify-otp` specifically, in every
environment — the only layer that stops a distributed attacker from email-bombing one victim
address via rotating IPs, which (1) and (2) cannot catch. All three respond with the same generic
`RATE_LIMITED` shape regardless of which key (email or IP) tripped, preserving D-078's
non-disclosure guarantee. **CAPTCHA (e.g. Cloudflare Turnstile) is explicitly deferred** — kept in
mind as a follow-up if the above prove insufficient, not built in this pass (needs a new UI-kit
component and adds flow friction, D-089).
**Why:** D-096's investigation surfaced that `request-otp` has no abuse protection at all today —
an unauthenticated caller can loop it against any email (email-bombing via Cognito's own SES-backed
delivery) or hammer it at high volume (SES quota/cost, pool-wide noisy-neighbor risk). Per-IP
throttling alone doesn't stop a low-and-slow attack against one victim email from many IPs, so the
DynamoDB email+IP layer is necessary alongside the cheaper API Gateway/WAF layers, not instead of
them. Rate-limiting keyed only on email risks letting an attacker lock out a real user by tripping
their limit deliberately, so the email-side threshold is generous while the IP-side is tighter.
**Supersedes:** — **Superseded by:** D-098 (WAF activation timing only — the other two layers are unchanged and still built now)
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
to match the tags CI actually pushes (`free-sha-<7chars>` / `paid-sha-<7chars>`, see
`heediq-worker-transcription/.github/workflows/deploy.yml`) and retains the **last 5 images per
tier** (free, paid), independently. Untagged-layer cleanup (1 day) is unchanged.
**Why:** The original rule (D-047-era) used `tagPrefixList: ['sha-']`, which never matched either
tag because both are prefixed with the tier name first (`free-`/`paid-`), not `sha-`. Every image
ever built (5GB free + 9GB paid per commit) was being retained forever — this is the actual driver of
ECR storage cost, not a need to shrink an already-working retention window. 5 per tier gives enough
rollback headroom across dev/staging/prod (only the currently-promoted SHA per env matters day to
day) while capping steady-state storage to roughly 5×(5GB+9GB) ≈ 70GB.
**Supersedes:** D-047 (retention mechanism only — SHA-tag versioning strategy itself unchanged)
**Superseded by:** —
**Related code:** `heediq-infra/lib/shared-services/shared-services-stack.ts`

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
(Key Files/Dependencies/Testing sections). Phase 5 (audit-log viewer) not started. Tracker:
`plans/wip-rbac-audit-trail.md`. Full architecture still in `memory/business/architecture.md`
§"RBAC & Audit Trail".

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

## Open / proposed (not yet locked)
- **Exact pricing/packaging** — principle locked at D-011/D-019; revisit numbers against the post-D-059 cost basis (GPU compute: ~$0.003/free job, ~$0.010/paid job).
- **SAML/OIDC for enterprise IdPs** — explicitly deferred (D-020); revisit once an enterprise deal needs it.
