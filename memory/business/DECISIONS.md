# Heediq Decisions Index (DECISIONS.md)

One line per locked decision — the always-loaded constraint surface, grouped as in
`DECISIONS_FULL.md`. Full text (Decision / Why / Supersedes / Related code) lives in
`DECISIONS_FULL.md`, read on demand once a specific `D-NNN` is actually in play. Format and
capture process: `rules/09-decisions.md`.

Fully-superseded decisions (no substantive content still active) live in
`DECISIONS_ARCHIVE.md`, not here.

---

## Architecture & Infrastructure
- **D-001** · Full AWS serverless stack · Architecture · Locked · → `memory/business/architecture.md`
- **D-002** · AWS CDK + GitHub Actions CI/CD · Infra · Locked · → `memory/business/architecture.md`
- **D-006** · Transcription cost optimizations · Cost · Locked · → `memory/business/architecture.md`
- **D-007** · DynamoDB-only at launch · Architecture · Locked · → `memory/business/architecture.md`
- **D-021** · Multi-tenancy — shared DB, row-level isolation · Architecture · Locked · → `memory/business/architecture.md`
- **D-022** · Data retention & audio lifecycle · Policy · Locked · → `memory/business/product.md`

## Brand & Design
- **D-008** · Design system tokens · Design · Locked · → `memory/business/branding.md`
- **D-009** · Brand & logo · Brand · Superseded by D-073 · → `memory/business/branding.md`
- **D-026** · Home / Listen screen UX · Design · Locked · → `memory/business/product.md`

## Product, Access & Billing
- **D-017** · Account & roles model · Product · Superseded by D-102 · → `memory/business/product.md`
- **D-018** · Free-tier usage limits · Pricing · Locked · → `memory/business/product.md`
- **D-019** · Billing — Stripe, org as customer · Pricing · Locked · → `memory/business/product.md`
- **D-011** · Pricing principle · Pricing · Locked · → —
- **D-020** · Auth — AWS Cognito + federated IdPs · Architecture · Locked · → `memory/business/product.md`
- **D-024** · Platform — mobile-first PWA · Product · Locked · → `memory/business/product.md`
- **D-025** · Paid-tier meeting bot · Product · Locked · → `memory/business/product.md`

## Process (this workspace)
- **D-012** · Workspace rules & memory repo · Process · Superseded by D-046 · → —
- **D-013** · GitHub as git host & CI · Infra · Locked · → —
- **D-014** · No Jira for now · Process · Locked · → —
- **D-015** · Two-track memory + auto-decision-capture · Process · Locked · → —
- **D-016** · Documentation via code-level READMEs · Process · Locked · → —

## Infrastructure Access & Naming
- **D-036** · 5-account AWS structure + SSO + OIDC · Infra · Locked · → `heediq-infra/`
- **D-037** · Resource naming — no environment prefix · Infra · Locked · → `heediq-infra/`
- **D-038** · SSM + secrets path convention · Infra · Superseded by D-100 · → `heediq-infra/`

## Stack & Repos
- **D-027** · `develop` integration-branch model · Process · Locked · → `rules/02-git-and-commits.md`
- **D-028** · UI component stack · Architecture / Design · Locked · → `rules/03-ui-kit.md`
- **D-029** · Frontend build stack · Architecture · Locked · → `heediq-web/`
- **D-030** · Test stack · Architecture · Locked · → `rules/05-testing.md`
- **D-031** · DynamoDB multi-table design · Architecture · Locked · → —
- **D-032** · Summarization/extraction model · Architecture / Product · Locked · → `heediq-worker-summarization/`
- **D-033** · REST as API style · Architecture · Locked · → `heediq-api/`
- **D-034** · API service runtime — Hono on Lambda · Architecture / Infra · Locked · → `heediq-api/`
- **D-035** · Polyrepo structure — 7 repos · Architecture / Process · Superseded by D-046 · → github.com/heediq/
- **D-039** · Dev tooling — pnpm + Node 22 LTS · Architecture · Locked · → all Node repos
- **D-040** · `@heediq/shared` delivery via GitHub Packages · Architecture · Locked · → `heediq-shared/`
- **D-041** · JWT auth enforcement — Hono middleware · Architecture · Locked · → `heediq-api/`
- **D-042** · API versioning — `/api/v1/` URL prefix · Architecture · Locked · → `heediq-api/`
- **D-043** · CI/CD pipeline structure · Infra / Process · Locked · → `heediq-infra/`
- **D-044** · Primary AWS region — eu-west-1 Ireland · Infra · Locked · → `heediq-infra/`
- **D-045** · AWS account IDs + local CLI profiles · Infra · Locked · → `heediq-infra/scripts/setup.sh`
- **D-046** · GitHub org rename + workspace repo rename · Process / Infra · Locked · → `claude-workspace/`
- **D-047** · Release versioning strategy · Infra / Process · Locked · → `.github/workflows/`
- **D-048** · Renovate for @heediq/shared dependency updates · Process · Locked · → `heediq-shared/`
- **D-049** · Hotfix flow · Process · Locked · → `rules/02-git-and-commits.md`
- **D-050** · Infra-first deployment convention · Process / Infra · Locked · → `heediq-infra/`
- **D-051** · DNS — Route 53 hosted zone in shared-services account · Infra · Locked · → `heediq-infra/`
- **D-052** · Subdomain structure per environment · Infra · Locked · → `heediq-infra/`
- **D-053** · ACM certificate strategy · Infra · Locked · → `heediq-infra/`
- **D-054** · Transactional email via Amazon SES · Architecture / Infra · Superseded by D-058 · → `heediq-infra/`
- **D-058** · SES identity in shared-services account; cross-account role for workload sending · Architecture / Infra · Superseded by D-095 · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-055** · Compute resource sizing at launch · Infra / Cost · Superseded by D-059 · → `heediq-infra/`
- **D-057** · Business email — Zoho EU · Infra · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-056** · Dev account budgets — $50/month via management account CLI script · Infra / Cost · Locked · → `heediq-infra/scripts/setup-budgets.sh`
- **D-059** · EC2 GPU Spot compute for transcription · Infra / Cost · Superseded by D-066 · → `heediq-infra/lib/transcription/transcription-stack.ts`
- **D-060** · Model access control at API layer, not infra routing · Product / Architecture · Locked · → `heediq-api/`
- **D-061** · Real-time job status via API Gateway WebSocket · Architecture / Product · Locked · → `heediq-infra/lib/websocket/websocket-stack.ts`
- **D-063** · Per-workload-account ACM wildcard cert (eu-west-1) in FoundationStack · Infra · Locked · → `heediq-infra/lib/foundation/foundation-stack.ts`
- **D-064** · heediq-route53-dns-manager cross-account IAM role · Infra · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-062** · Whisper + pyannote models baked into Docker image · Infra / Cost · Locked · → `heediq-worker-transcription/`
- **D-065** · SummarizationStack trigger — SQS queue, source-agnostic · Architecture / Infra · Locked · → `heediq-infra/lib/summarization/summarization-stack.ts`
- **D-066** · Transcription Spot-interruption retry — explicit SQS re-enqueue, not visibility timeout · Architecture / Infra · Locked · → `heediq-worker-transcription/src/worker.py`
- **D-067** · Summarization model selection by tier — Haiku (free) / Sonnet (paid) · Cost / Architecture · Locked · → `heediq-shared/src/messages.ts`
- **D-068** · Generic entity naming — Source / Container / multi-label · Architecture · Superseded by D-129, D-128 · → `heediq-shared/src/`
- **D-070** · AWS region resolved from GitHub org-level variable, not hardcoded per repo · Infra / Process · Locked · → `.github/workflows/deploy.yml`
- **D-071** · Deploy role ARNs resolved from GitHub org-level variables, not hardcoded per repo · Infra / Process · Locked · → `.github/workflows/deploy*.yml`
- **D-072** · Status/semantic color tokens · Design · Locked · → `heediq-web/src/styles/tokens.css`
- **D-073** · Final logo assets supersede D-009 placeholder SVG · Brand · Locked · → `heediq-web/public/brand/`
- **D-074** · Animated 4-bar loading mark component · Design · Locked · → `heediq-web/src/components/ui/LoadingMark/`
- **D-075** · Full i18n coverage in heediq-web — all user-facing text, including errors · Architecture / Product · Locked · → `heediq-web/README.md`
- **D-076** · i18n library — react-i18next · Architecture · Locked · → `heediq-web/src/i18n/`
- **D-077** · Org creation on first login via a single Cognito PreTokenGeneration trigger · Architecture · Locked · → `heediq-infra/lib/foundation/foundation-stack.ts`
- **D-078** · Email is the one true identity — cross-provider account linking model · Architecture / Product · Superseded by D-087 · → `heediq-api/src/handlers/auth-*.ts`
- **D-079** · Account linking is available both reactively (login-time) and proactively (Settings) · Product · Locked · → `heediq-web/src/routes/SettingsPage.tsx`
- **D-081** · No separate marketing/landing page — "/" is always the sign-in/sign-up screen · Product · Locked · → `heediq-web/src/App.tsx`
- **D-082** · Auth flows are client-direct-to-Cognito; backend owns only lookup-email + link/confirm · Architecture · Superseded by D-089 · → `heediq-api/src/routes/auth.ts`
- **D-083** · Proactive provider-linking uses a dedicated OAuth callback route · Architecture · Locked · → `heediq-infra/lib/foundation/foundation-stack.ts`
- **D-084** · pnpm `minimumReleaseAge` cooldown disabled across all repos · Infra / Process · Locked · → `heediq-web/pnpm-workspace.yaml`
- **D-085** · Logging & observability: native AWS (CloudWatch + X-Ray), no separate tool · Architecture / Infra / Cost · Locked · → `heediq-shared/src/logger.ts`
- **D-093** · Logger usage is mandatory; default log level `info`, `debug` opt-in via env var, no unbounded log retention · Architecture / Cost · Locked · → `heediq-shared/src/logger.ts`
- **D-094** · Password-policy visibility — checked-not-wired sync, dedicated weak-password error · Architecture / Design · Locked · → `heediq-shared/src/passwordPolicy.ts`
- **D-088** · API version prefix owned by exactly one place per side; route tests must exercise the real mounted app · Architecture · Locked · → `heediq-web/src/lib/api-client.ts`
- **D-089** · Own-verification email-confirmation model replaces IdP-trust; unified verify+password component · Architecture / Product · Locked · → `heediq-api/src/routes/auth.ts`
- **D-090** · Org/user auto-provisioning no longer gated on IdP-asserted email_verified · Architecture / Policy · Locked · → `heediq-api/src/handlers/auth-provision.ts`
- **D-091** · heediq-user-auth-methods is the source of truth for active login methods · Architecture · Locked · → `heediq-api/src/routes/auth-methods.ts`
- **D-092** · `vars.AWS_REGION` is the sole region source everywhere except explicit per-service overrides · Infra · Locked · → `heediq-web/.github/workflows/deploy.yml`
- **D-095** · Per-workload-account SES identity, narrowly, so Cognito can send its own OTP emails · Architecture / Infra · Locked · → `heediq-infra/lib/foundation/foundation-stack.ts`
- **D-096** · request-otp self-heals a stuck confirmed-but-unlinked native Cognito user · Architecture · Locked · → `heediq-api/src/routes/auth.ts`
- **D-097** · Layered abuse protection for the OTP endpoints · Architecture / Policy · Superseded by D-098 · → `heediq-infra/lib/api/api-stack.ts`
- **D-098** · Defer WAF activation until a marketing campaign is planned · Architecture / Cost · Locked · → `heediq-infra/lib/api/api-stack.ts`
- **D-099** · Decouple internal accountId from Cognito `sub` via a `heediq-cognito-identities` mapping table · Architecture · Locked · → `heediq-api/src/lib/accountIdentity.ts`
- **D-100** · Secrets fetched via direct SDK call, not the Lambda Extension · Infra · Locked · → `heediq-infra/lib/summarization/summarization-stack.ts`
- **D-101** · ECR lifecycle rule fixed to actually expire old transcription-worker images · Infra / Cost · Superseded by D-108 · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-108** · ECR cost cleanup: keep-count lowered to 3/tier, build attestations disabled · Infra / Cost · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-102** · Dynamic per-org RBAC + unified GxP-quality audit trail · Architecture · Superseded by D-105 · → `heediq-api/README.md`
- **D-103** · Script files stay scoped to one thing · Architecture · Locked · → `heediq-infra/lib/foundation/README.md`
- **D-104** · No migration for `heediq-auth-audit-log` — drop the table · Architecture · Locked · → —
- **D-105** · RBAC permission invalidation rides the JWT, no per-request DB check · Architecture · Locked · → `heediq-api/README.md`
- **D-106** · Permission key strings are immutable once released — additive-only, never rename in place · Architecture · Locked · → `heediq-shared/src/permissions.ts`
- **D-107** · Every mutating endpoint/UI action requires permission gating + audit trail — standing rule · Architecture · Locked · → `heediq-api/src/lib/audit.ts`
- **D-109** · Generalized real-time WebSocket framework · Architecture · Locked · → `heediq-infra/lib/foundation/tables.ts`
- **D-110** · heediq-web centralized WebSocket client — Context + typed hook, no new cross-repo push access · Architecture · Locked · → `heediq-web/src/lib/ws/`
- **D-111** · Every feature with async backend work must use the WS framework for responsiveness · Product · Locked · → `heediq-web/src/lib/ws/README.md`
- **D-112** · Manual `workflow_dispatch` trigger on infra deploy pipeline · Infra · Locked · → `heediq-infra/.github/workflows/deploy.yml`
- **D-113** · Fix root causes, not symptoms · Policy · Locked · → `heediq-web/src/routes/SettingsLinkCallbackPage.tsx`
- **D-114** · `requirePermission` writes a denial audit entry on every 403 · Architecture · Locked · → `heediq-shared/src/audit.ts`
- **D-115** · Docs-only changes never trigger CI or deploy pipelines · Infra · Locked · → `.github/workflows/ci.yml`
- **D-116** · Waveform loading mark · Design · Locked · → `heediq-web/src/components/ui/LoadingMark/`
- **D-117** · App-wide motion system · Design · Locked · → `heediq-web/src/lib/motion.ts`
- **D-118** · Login — separate branded IdP buttons, direct-to-provider · Design · Locked · → `heediq-web/src/lib/auth/cognito-oauth.ts`
- **D-119** · PWA build tooling — vite-plugin-pwa · Architecture · Locked · → `heediq-web/vite.config.ts`
- **D-120** · App-wide double-submit guard + animated stroke/shadow transitions · Design · Locked · → `heediq-web/src/lib/useAsyncAction.ts`
- **D-121** · PWA app name varies per environment · Design · Locked · → `heediq-web/vite.config.ts`
- **D-122** · Perceived-loading timing values — component vs page level · Design · Locked · → `heediq-web/src/lib/usePerceivedLoading.ts`
- **D-123** · Extract-on-second-duplication — standing DRY/SOLID architecture rule · Architecture · Locked · → `heediq-web/src/lib/auth/README.md`
- **D-124** · Context Library generalizes north-star scope beyond dev-work to any life domain · Product · Locked · → `memory/business/product.md`
- **D-125** · Context Library — auto-first classification, no manual merge/split at MVP · Product · Locked · → —
- **D-126** · Context Library — output generation via chat, not fixed one-shot templates · Product · Locked · → —
- **D-127** · Context Library — Domain is a predefined, behavior-bearing type · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-128** · Context Library — one Context per Source at MVP · Product / Architecture · Locked · → `heediq-shared/src/domain.ts`
- **D-129** · Context Library — rename Container entity to Context · Architecture · Locked · → `heediq-shared/src/`
- **D-130** · Context Library — combined classify+extract in the summarization worker · Architecture / Cost · Locked · → `heediq-worker-summarization/`
- **D-131** · Context Library — Domain profile set: work / study / personal / other · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-133** · Context Library — `classification_ready` WS event + review-gate Source state · Architecture · Locked · → `heediq-shared/src/ws.ts`
- **D-134** · Context Library — nested Contexts (epic/story) are in MVP scope · Product · Locked · → `heediq-shared/src/`
- **D-135** · Context Library — item-level `ExtractedItem` model (supersedes D-132) · Architecture · Locked · → `heediq-shared/src/`
- **D-136** · Context Library — Context Decision Ledger (design now, build fast-follow) · Product / Architecture · Locked · → `heediq-shared/src/`
- **D-137** · Context Library — interactive 3-step review wizard · Product / Design · Locked · → `heediq-web/src/features/`
- **D-138** · Context Library — Context chat persistence model · Architecture · Locked · → `heediq-shared/src/`
- **D-139** · Context Library — dedicated `heediq-chat` worker, streamed over WS with prompt caching · Architecture / Cost · Locked · → `heediq-infra/lib/chat/`
- **D-140** · MVP v1 synthesis step reconciled to the Context Library · Product · Locked · → `plans/context-library-spec.md`
- **D-141** · Context Library — Context visibility model: personal / group / org, permission-gated · Product / Architecture · Locked · → `heediq-infra/lib/foundation/README.md`
- **D-142** · Context Library — cross-org Context sharing via regulated grants (design now, build fast-follow) · Architecture / Policy · Locked · → `heediq-infra/lib/foundation/README.md`
- **D-143** · Heediq serves B2B and B2C; org is the universal tenant boundary · Product · Locked · → `memory/business/product.md`
- **D-144** · Primary positioning is a contextual-memory platform; meetings are one ingestion path · Product · Locked · → `memory/business/product.md`

## Open / proposed (not yet locked)
- **Exact pricing/packaging** — principle locked at D-011/D-019; revisit numbers against the post-D-059 cost basis (GPU compute: ~$0.003/free job, ~$0.010/paid job).
- **SAML/OIDC for enterprise IdPs** — explicitly deferred (D-020); revisit once an enterprise deal needs it.
- **Context chat model tier for quality outputs** — D-139 reuses D-067's free→Haiku / paid→Sonnet mapping; revisit whether high-value generated deliverables (tech specs, slides) on the paid tier warrant a stronger model (e.g. Opus) against per-generation cost, once real output quality is observed.
- **Context Library retrieval strategy at scale** — MVP assembles a Context's full accumulated content directly into the Claude chat prompt (no vector store, consistent with `product.md`'s existing RAG note). Revisit only if a single Context's content outgrows a practical context-window budget, or if cross-Context semantic search ("find where we discussed X across my whole library") becomes a prioritized feature — recommended default is to defer RAG/embeddings until one of those two triggers is real, not to build it speculatively now.
