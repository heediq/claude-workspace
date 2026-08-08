# WIP — fix/transcription-dispatcher-lambda-d157

**Branch:** `fix/transcription-dispatcher-lambda-d157` (heediq-infra, off `develop`)
**Decision:** D-157 — retire EventBridge Pipes for transcription; SQS → dispatcher Lambda → ECS
RunTask (supersedes the Pipes mechanism of D-060/D-066/D-023).

## Root cause being fixed
Two EventBridge Pipes polled the single `heediq-transcription` queue with complementary `tier`
message-attribute filters. Whichever Pipe won `ReceiveMessage` first ate the message; if it was the
wrong tier, its filter rejected it and **Pipes silently deleted it** (filter-rejected messages are
dropped with no error, no DLQ). ~50% of audio jobs vanished with no terminal state — the
`pnpm e2e:audio` smoke timed out. Secondary defect: a stale pre-D-023 S3 `OBJECT_CREATED` → SQS
notification on the audio bucket.

## Design (locked)
One queue, one consumer. A small infra-owned dispatcher Lambda reads `tier` from the message **body**
and `ecs:RunTask`s the matching task-def **family** (`heediq-transcription-{free,paid}`) on the EC2
GPU Spot capacity provider, passing the raw body as the `SQS_MESSAGE_BODY` container override.
Family-based RunTask means CI image promotions need no pipe/target update step. Real DLQ via the
existing `maxReceiveCount:3 → heediq-transcription-dlq` + `reportBatchItemFailures`.

## heediq-infra — DONE (this branch)
- `lib/transcription/dispatcher/{index.mjs,routing.mjs,README.md}` — handler + pure routing (SDK-free
  so it unit-tests without `@aws-sdk/client-ecs`).
- `transcription-stack.ts` — added dispatcher Lambda + `SqsEventSource` + IAM (`ecs:RunTask` scoped
  to `…-{free,paid}:*`, `iam:PassRole` on exec+task roles) + SSM `dispatcher-function-name`; deleted
  both `CfnPipe`s, the `pipeRole`, and the `pipes` import; updated D-066 comment + task-def family
  comment.
- `storage.ts` — deleted stale S3→SQS notification + unused `s3n` import; queue visibility timeout
  3600s → **90s** (> dispatcher 30s timeout; message isn't held for job duration).
- `config.ts` — `COMPUTE.lambda.transcriptionDispatcher = {128 MB, 30s}`.
- Tests: `test/transcription-dispatcher.test.ts` (routing unit tests) + rewrote the Pipes assertions
  in `test/transcription-stack.test.ts` (now: Lambda, event source, IAM, `Pipes::Pipe` count 0, SSM)
  + fixed `test/foundation/storage.test.ts` (visibility 90, no S3 grant).
- `README.md` — TranscriptionStack table/prose rewritten to the dispatcher; removed dead
  S3-notification gotcha; ECR promotion note drops `update-pipe`.
- ✅ `pnpm test:pre-pr` green (240 tests), typecheck clean.

## heediq-api — DONE (branch: same feature, its own repo branch when pushed)
- `src/routes/sources.ts` — dropped the `tier` `MessageAttributes` on the transcription enqueue AND
  on the text-path summarization enqueue (the summarization worker reads `tier` from the body; the
  attribute's only rationale was mirroring the transcription producer, now gone). `tier` stays in
  every message body.
- Tests updated (`src/__tests__/sources.test.ts`): assert `MessageAttributes` undefined + `tier` in
  body for both paths. ✅ `pnpm test:pre-pr` green (309 tests).
- README: removed the two stale "tier attribute / EventBridge-Pipes tier-routing" references.

## heediq-worker-transcription — DONE
- `src/sqs_client.py` — Spot re-enqueue drops the `tier` attribute (tier already in body).
- `scripts/promote-transcription-worker.sh` — removed the `describe-pipe`/`update-pipe` block (would
  break once Pipes are gone); dispatcher runs by family so a new task-def revision is picked up with
  no target update.
- `src/worker.py` docstring + SIGTERM comment: Pipes → dispatcher Lambda.
- README + Data-Flow diagram rewritten to the dispatcher. Tests updated (`test_sqs_client.py`,
  `test_worker.py`): assert no message attribute + `tier` in body. ✅ `pytest` green (16), `mypy src`
  clean.

## Net effect
No producer sets a `tier` SQS message attribute anywhere; every queue consumer reads `tier` from the
message body. One transcription queue, one dispatcher Lambda, one DLQ.

## Deploy + PRs — DONE (2026-08-08)
All three PRs merged to `develop` via `gh` (squash, infra-first per D-050): **infra #67, api #55,
worker #18** — all dev deploys green (worker's first build hit a transient 6h registry-cache stall;
recovered by re-running the failed jobs).

**Dispatcher fix PROVEN in dev.** `pnpm e2e:audio` enqueued a job and the dispatcher Lambda routed it
end-to-end: CloudWatch `/aws/lambda/heediq-transcription-dispatcher` logged `runtask.launched
jobId=… tier=free taskArn=…` ~2s after enqueue (read `tier` from the **body**, matched the free
family, launched an ECS task). The queue→compute handoff that D-157 fixes now works.

## BLOCKED — e2e:audio can't fully pass in dev (NOT a code issue) ⚠️ pick up tomorrow
The launched ECS task sat in **PROVISIONING** forever → smoke timed out at 600s. Root cause: the
**dev account's GPU quota is 0** — both `L-3819A6DF` (All G & VT **Spot**) and `L-DB2E81BA` (**On-Demand**
G & VT) = 0 vCPU. The ASG (capacity provider bumped desired→2) fails every launch with
`MaxSpotInstanceCountExceeded`. The audio path has **never had GPU capacity in dev**; the old Pipes
bug hid it by dropping messages before capacity mattered. This is a pre-existing infra gap the fix
merely revealed.
- **Action taken:** submitted a Service Quotas increase for **Spot G/VT (L-3819A6DF) → 8 vCPU**
  (2× g4dn.xlarge). Request ID **`cb2756563f9f44a191f05a1deddf9d97TbMM9Na4`**, status **PENDING**
  (AWS-Support-gated, async). Stopped the orphaned PROVISIONING task so the ASG relaxes to 0.
- **Tomorrow:** check request status (`aws service-quotas get-requested-service-quota-change
  --request-id cb2756563f9f44a191f05a1deddf9d97TbMM9Na4 --profile heediq-dev`). Once **APPROVED**,
  re-run `pnpm e2e:audio` against dev with a **fresh** Cognito ID token (they expire ~1h):
  `API_BASE=https://api-dev.heediq.com WS_URL=wss://ws-dev.heediq.com ID_TOKEN=<fresh> pnpm e2e:audio`.
  Endpoints/client-id resolvable from dev SSM (`/heediq/api/{endpoint-url,ws-endpoint-url,cognito-client-id}`).

## CI hardening — DONE (2026-08-08)
The worker's 6h build stall (a routine app-only commit ran ~5.5h because the mutable `nvidia/cuda`
tag busts the layer cache) drove **PR #19** (`chore/…-caching-and-timeout`, merged `00ebfb9`):
digest-pin the CUDA base in both Dockerfiles, `timeout-minutes: 45` + `BUILDKIT_PROGRESS=plain` on
the build job, and free/paid built as a parallel `fail-fast:false` matrix. Merge triggered deploy run
`31267107436` (validates the new matrix build — glance at it tomorrow).

## Deferred follow-up (own PR, not started)
**P2 — shared prebuilt base image**: extract CUDA+apt+pip into a `…-transcription-base` image built
only when `requirements.txt` changes; free/paid become `FROM base` + model-bake + `COPY src`, so
app-only commits rebuild in seconds. Needs a new ECR repo + build job (medium risk).

## Next-session docs sweep
`plans/wip-docs-codebase-sync-sweep.md` already seeds the post-D-157 doc cleanup across repos.
