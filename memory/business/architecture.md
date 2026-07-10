# Heediq — Architecture & Infrastructure

`DECISIONS.md` (D-001, D-002, D-006, D-007, D-021, D-022) points here rather than duplicating
this detail. (Earlier D-003–D-005 and D-023 are fully superseded and live in `DECISIONS_ARCHIVE.md`.)

## Stack
Full AWS serverless: Lambda, API Gateway, EC2 GPU Spot/ECS (D-059), DynamoDB, S3, SQS, EventBridge,
Cognito, CloudFront, Route 53, Secrets Manager, CloudWatch.
- IaC: AWS CDK
- CI/CD: GitHub Actions
- Frontend: React (PWA)

## Environments
Five AWS accounts under one AWS Organization (D-036):
- **Management** — org root, IAM Identity Center (SSO), consolidated billing. No workloads.
- **Shared services** — ECR (all container images), Route 53 hosted zone (heediq.com), SES email identity + DKIM records, cross-account email sending IAM role, Route 53 DNS manager IAM role, Zoho DNS records, ACM wildcard cert eu-west-1 (shared-services own use) + us-east-1 (CloudFront). All DNS lives here (D-051–D-058, D-064). Workload-facing eu-west-1 certs live in each workload account FoundationStack — ACM cross-account restriction (D-063).
- **Dev / Staging / Prod** — fully isolated workload accounts (DynamoDB, Lambda, S3, SQS, Cognito, etc.).

Human access via IAM Identity Center (SSO) — one login URL, permission sets defined centrally, users assume roles per account. No IAM users or long-lived access keys.

Machine access (GitHub Actions) via OIDC — a `GitHubActionsDeployRole` per account with branch-scoped trust; no stored AWS credentials in GitHub Secrets. Container images push to ECR in the shared-services account and are promoted by image tag across dev → staging → prod. Manual approval gate before production deploys.

Resource naming: `heediq-{entity}` with no environment prefix — the account boundary is the environment boundary (D-037). SSM paths: `/heediq/{service}/{param}` (D-038).

## Multi-tenancy
Single shared database, row-level tenant isolation via `org_id` on every tenant-scoped row (e.g.
recordings carry `org_id` + `owner_user_id`). Query pattern:
`WHERE org_id = :tenant AND (owner_user_id = :user OR :role = 'admin')` — this `:role = 'admin'`
shorthand is the pre-RBAC baseline; under D-102 it becomes a permission check
(`sources:read` grants all-org visibility, `sources:read-own` restricts to `owner_user_id = :user`),
see RBAC & Audit Trail below.

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
- `heediq-role-assignments` (`pk=USER#<accountId>`, `sk=ROLE#<roleId>|GROUP#<groupId>`) — the
  join table resolved at token issuance; `by-role` GSI answers "who holds this role" for the
  role-management UI and for the `rbacVersion` fan-out below.
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

## Database
DynamoDB-only at launch (D-007). Design: **multi-table** — one table per service/entity domain, e.g. `heediq-sources`, `heediq-orgs` (D-031, table renamed from `heediq-recordings` per D-068). Aurora Serverless v2 (Postgres) deferred — open migration path per service if relational queries become necessary. At small scale, Aurora's ~$45/mo fixed floor dominates the bill disproportionately (see Cost baselines below).

## Upload & transcription processing flow
Client uploads audio directly to S3 via a presigned URL (avoids Lambda payload limits, standard
serverless pattern). An S3 event feeds the transcription queue (SQS). EventBridge Pipes triggers
an ECS `RunTask` running faster-whisper on an EC2 GPU Spot instance — zero idle cost, nothing
provisioned while the queue is empty (D-059). Job status is written to `heediq-jobs` DynamoDB;
the worker writes progress stages (`queued → starting → transcribing → diarizing → summarizing →
done/failed`) as it runs. A WebSocket Status Pusher Lambda (DDB Streams on `heediq-jobs`) pushes
each status change to the connected client in real time (D-061).

*(This flow superseded an earlier version that used AWS Transcribe with simpler S3-event →
Lambda → Transcribe-job orchestration — see Transcription engine below for why that was dropped.
Client polling was superseded by WebSocket in D-061. Fargate Spot compute was superseded by EC2
GPU Spot in D-059.)*

## Transcription engine
Self-hosted **faster-whisper** on **EC2 GPU Spot** (g4dn.xlarge, T4 16 GB VRAM), queued via SQS.
AWS Transcribe remains dropped. Compute moved from Fargate CPU to EC2 GPU in D-059.

**Model access** (D-060): model choice is enforced at the API enqueue endpoint, not at the
infra layer. Free users may only submit whisper small jobs; paid users may choose large-v3 +
speaker identification. Same ECS cluster and single g4dn.xlarge Spot ASG (min=0) serves all jobs.

- **Whisper small** (free users): ~1–2 min / 60-min meeting on T4 — ≈ **$0.003/meeting**
- **Whisper large-v3 + pyannote** (paid users, elective): ~3–5 min / 60-min meeting on T4 —
  ≈ **$0.010/meeting**. Pyannote diarization runs on the g4dn.xlarge CPU cores while faster-whisper uses the GPU.

**Zero idle cost:** ASG min=0; instances boot on demand (~45–90s cold start, accepted for async
batch), terminate after job completes.

**Spot interruption (D-066, corrects D-059's original mechanism):** worker catches SIGTERM →
writes `status=retrying` to DynamoDB → explicitly re-sends the original job message to the
`heediq-transcription` SQS queue (same `tier` attribute, so the EventBridge Pipe re-routes it) →
exits. Explicit re-enqueue, not SQS visibility timeout expiry — EventBridge Pipes (not the
worker) is the SQS consumer and deletes the message as soon as it hands the job to ECS `RunTask`,
before the worker even starts, so no visibility timeout is left to expire by SIGTERM time. Short
runtimes (1–5 min) make retry-from-scratch cheap. Capacity-optimized Spot allocation minimises
interruption frequency.

Why the original pivot: at ~10 meetings/day, faster-whisper costs ~$6/mo vs ~$432/mo on AWS
Transcribe — ~70–75× cheaper. Why the GPU upgrade (D-059): 10× faster, ~50% cheaper per meeting.

## Real-time status delivery (D-061)
Job progress is pushed to the client via **API Gateway WebSocket** (supersedes polling from D-023).

```
Worker writes status → heediq-jobs DynamoDB
                            ↓ DDB Streams
                  Status Pusher Lambda
                            ↓ execute-api:ManageConnections
              API Gateway WebSocket API  →  Client browser
```

Status stages displayed to the user:
`queued → starting → transcribing → diarizing (large-v3 only) → summarizing → done / failed`

`starting` is the worker's first DynamoDB write after picking up the SQS message — before model
load — so EC2 cold-start latency is visible as "Transcription server starting…".

Resources: `HeediqWebSocketStack` (WebSocket API + `heediq-ws-connect` Lambda + `heediq-ws-status-pusher` Lambda); `heediq-ws-connections` DynamoDB table in FoundationStack; subdomains `ws.heediq.com` / `ws-staging.heediq.com` / `ws-dev.heediq.com` — covered by `*.heediq.com` wildcard cert in `FoundationStack.wildcardCert` (D-063). All deployed to dev.

## Cost optimizations
- **Silence trimming:** accepted — safe, typically 10–30% duration reduction, no meaningful
  accuracy cost.
- **2× audio speed-up:** rejected — degrades word-error-rate and diarization accuracy too much
  to be worth the savings.

## Cost baselines
Per-meeting transcription costs (D-059, GPU): whisper small ~$0.003, large-v3 ~$0.010.
Previous Fargate CPU costs (~$0.006/$0.035) are superseded — do not use for pricing modelling.

Single environment (modelled before dev/staging overhead):

**1,000 users (900 free / 100 paid, 90/10 mix):**
- AWS-only, DynamoDB-only (post-D-059 GPU costs): ≈ $55–110/mo (transcription cost drops ~60%
  vs prior Fargate CPU model; exact number depends on meeting volume).
- Excludes third-party meeting-bot costs: ≈ $50–150/mo at this scale.

**100 users (90 free / 10 paid, 90/10 mix):**
- AWS-only, DynamoDB-only (post-D-059 GPU costs): ≈ $15–30/mo.
- Excludes third-party meeting-bot costs: ≈ $10–30/mo for 10 paid orgs.

Adding dev + staging: roughly **$20–40/mo total** at 100-user scale.

Note: exact packaging numbers are still open (D-011 principle is locked; revisit pricing
model against D-059 cost basis — see Open/proposed in DECISIONS.md).

Cost components: transcription compute (EC2 GPU Spot), S3 + Glacier, DynamoDB, Lambda/API
Gateway, SQS/EventBridge, Cognito (free at this scale), CloudFront/Route 53, CloudWatch,
Secrets Manager.

## Engineering process
- Git host: GitHub. PRs via `gh` CLI. CI: GitHub Actions — per-repo workflows, OIDC role assumption per account (D-043).
- No issue tracker (Jira) for now — may adopt later. Branch/commit naming: `<type>/<short-kebab-desc>`. `develop` is the integration branch (D-027).
- Two-track memory model (this repo): business memory (`memory/business/`) + codebase memory (`memory/codebase/`).
- Documentation lives in code-level `README.md` files next to the code — replaces Confluence.
- **Repos:** 7 polyrepos under `github.com/heediq/` — workspace, shared, web, api, worker-transcription, worker-summarization, infra (D-046).
- **API:** REST + Hono on Lambda + `/api/v1/` prefix + `@heediq/shared` Zod schemas (D-033, D-034, D-042).
- **Frontend:** Vite + React + TypeScript strict + Tailwind + Radix UI + TanStack Query (D-028, D-029).
- **Test stack:** Vitest/RTL + DynamoDB Local/LocalStack + Playwright + k6 (D-030).
- **Dev tooling:** pnpm + Node 22 LTS across all Node repos (D-039).
