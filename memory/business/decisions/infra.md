# Decisions — Infrastructure, Deploy & Ops

Part of the decisions index (`DECISIONS.md` is the manifest). Format: `rules/09-decisions.md`.

---

- **D-002** · AWS CDK + GitHub Actions CI/CD · Infra · Locked · → `memory/business/architecture.md`
- **D-013** · GitHub as git host & CI · Infra · Locked · → —
- **D-036** · 5-account AWS structure + SSO + OIDC · Infra · Locked · → `heediq-infra/`
- **D-037** · Resource naming — no environment prefix · Infra · Locked · → `heediq-infra/`
- **D-038** · SSM + secrets path convention · Infra · Superseded by D-100 · → `heediq-infra/`
- **D-043** · CI/CD pipeline structure · Infra / Process · Locked · → `heediq-infra/`
- **D-044** · Primary AWS region — eu-west-1 Ireland · Infra · Locked · → `heediq-infra/`
- **D-045** · AWS account IDs + local CLI profiles · Infra · Locked · → `heediq-infra/scripts/setup.sh`
- **D-047** · Release versioning strategy · Infra / Process · Locked · → `.github/workflows/`
- **D-051** · DNS — Route 53 hosted zone in shared-services account · Infra · Locked · → `heediq-infra/`
- **D-052** · Subdomain structure per environment · Infra · Locked · → `heediq-infra/`
- **D-053** · ACM certificate strategy · Infra · Locked · → `heediq-infra/`
- **D-055** · Compute resource sizing at launch · Infra / Cost · Superseded by D-059 · → `heediq-infra/`
- **D-057** · Business email — Zoho EU · Infra · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-056** · Dev account budgets — $50/month via management account CLI script · Infra / Cost · Locked · → `heediq-infra/scripts/setup-budgets.sh`
- **D-059** · EC2 GPU Spot compute for transcription · Infra / Cost · Superseded by D-066 · → `heediq-infra/lib/transcription/transcription-stack.ts`
- **D-063** · Per-workload-account ACM wildcard cert (eu-west-1) in FoundationStack · Infra · Locked · → `heediq-infra/lib/foundation/foundation-stack.ts`
- **D-064** · heediq-route53-dns-manager cross-account IAM role · Infra · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-062** · Whisper + pyannote models baked into Docker image · Infra / Cost · Locked · → `heediq-worker-transcription/`
- **D-070** · AWS region resolved from GitHub org-level variable, not hardcoded per repo · Infra / Process · Locked · → `.github/workflows/deploy.yml`
- **D-071** · Deploy role ARNs resolved from GitHub org-level variables, not hardcoded per repo · Infra / Process · Locked · → `.github/workflows/deploy*.yml`
- **D-084** · pnpm `minimumReleaseAge` cooldown disabled across all repos · Infra / Process · Locked · → `heediq-web/pnpm-workspace.yaml`
- **D-092** · `vars.AWS_REGION` is the sole region source everywhere except explicit per-service overrides · Infra · Locked · → `heediq-web/.github/workflows/deploy.yml`
- **D-100** · Secrets fetched via direct SDK call, not the Lambda Extension · Infra · Locked · → `heediq-infra/lib/summarization/summarization-stack.ts`
- **D-101** · ECR lifecycle rule fixed to actually expire old transcription-worker images · Infra / Cost · Superseded by D-108 · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-108** · ECR cost cleanup: keep-count lowered to 3/tier, build attestations disabled · Infra / Cost · Locked · → `heediq-infra/lib/shared-services/shared-services-stack.ts`
- **D-112** · Manual `workflow_dispatch` trigger on infra deploy pipeline · Infra · Locked · → `heediq-infra/.github/workflows/deploy.yml`
- **D-115** · Docs-only changes never trigger CI or deploy pipelines · Infra · Locked · → `.github/workflows/ci.yml`
