# Heediq Decisions Archive (DECISIONS_ARCHIVE.md)

Fully-superseded decisions moved out of `DECISIONS.md` to keep the main log lean. An entry lives
here when its superseding decision's text (in `DECISIONS.md`) already restates whatever part of it
is still substantively true — nothing here is load-bearing for current work. Kept verbatim for
historical "why." Never edited; entries are moved here, not created here. See `rules/08-memory.md`
(Memory optimization) for the archive policy.

If a decision in `DECISIONS.md` is only *partially* superseded (its superseding entry says e.g.
"mechanism only" / "X unchanged" and doesn't restate the still-active part), it stays in the main
file — archiving is only for decisions that are fully replaced.

---

### D-003 · Three AWS accounts + shared ECR — Locked (2026-06-11)
**Area:** Infra
**Decision:** Separate prod/staging/dev accounts under one AWS Organization; a single shared ECR
registry — build the image once, promote across environments. Branch-based deployment with a
manual approval gate before production.
**Related:** `memory/business/architecture.md`
**Superseded by:** D-036 (5-account structure + SSO + OIDC)

### D-004 · Self-hosted faster-whisper on Fargate Spot — Locked (2026-06-11)
**Area:** Infra / Cost
**Decision:** Transcription runs on self-hosted `faster-whisper` on AWS Fargate Spot via SQS.
AWS Transcribe dropped entirely.
**Why:** ~70–75× cheaper than AWS Transcribe at scale (~$6/mo vs ~$432/mo at 10 meetings/day);
makes a usage-inclusive pricing model viable at all.
**Superseded by:** D-059 (compute only — self-hosted faster-whisper and SQS remain)
**Related:** `memory/business/architecture.md`

### D-005 · Transcription tiers — Locked (2026-06-11)
**Area:** Cost
**Decision:** Free tier = whisper `small` on CPU (~$0.02/60-min meeting, capped 30–45 min/recording);
paid tier = whisper `large-v3` + pyannote diarization with chunked parallel processing
(~$0.12/60-min meeting).
**Superseded by:** D-059 (compute: Fargate CPU → EC2 GPU, cost numbers revised), D-060 (mechanism: tier routing → API access control; model assignments unchanged)
**Related:** `memory/business/architecture.md`

### D-010 · MVP build order — Locked (2026-06-11)
**Area:** Product
**Decision:** auth/onboarding → home/Listen → recordings library → recording detail/summary
(critical path: record → transcribe → summarize → view). Org/billing and calendar/meeting-bot
settings are follow-on.
**Superseded by:** D-069 (build order sequence unchanged; scope widened to include multi-source
ingestion + container-level synthesis before first ship)
**Related:** `memory/business/product.md`

### D-023 · Upload & transcription processing flow — Locked (2026-06-11)
**Area:** Architecture
**Decision:** Client uploads directly to S3 via a presigned URL. An S3 event feeds an SQS queue;
EventBridge Pipes triggers an ECS Fargate Spot `RunTask` (faster-whisper, per D-004) with zero
idle cost. Job status is written to DynamoDB; client polls for completion.
**Supersedes:** an earlier S3-event → Lambda → AWS-Transcribe-job orchestration (dropped
alongside D-004).
**Superseded by:** D-059 (Fargate Spot RunTask → EC2 GPU RunTask; upload/SQS/EventBridge flow unchanged), D-061 (client polling → WebSocket push)
**Related:** `memory/business/architecture.md`

### D-080 · Unverified IdP email blocks org auto-provisioning (2026-07-04) — Locked
**Area:** Architecture / Policy
**Decision:** D-077's PreTokenGeneration trigger checks `email_verified` on every token it processes. If false (native user with an unconfirmed email, or a federated IdP asserting an unverified email — rare, but possible on some enterprise Microsoft tenants), the trigger does **not** auto-provision the org/user row. Instead it forces our own email-verification step before any org/user creation, since D-078's entire cross-provider linking model depends on email being trustworthy as the one true identity — an unverified email would let an attacker claim someone else's address as if it matched an existing account.
**Why:** The linking model in D-078 only holds if "this email" reliably means "this person." Trusting an unverified email for org auto-provisioning or linking would undermine that invariant for an edge case (unverified IdP email) that's rare enough not to justify the risk.
**Supersedes:** —
**Superseded by:** D-090 (the `email_verified` gate on org/user provisioning is dropped entirely — trustworthy verification is enforced separately per D-089, not as a provisioning precondition)
**Related code:** `heediq-infra/lib/foundation/foundation-stack.ts` (PreTokenGeneration trigger, D-077)

### D-086 · Cross-provider linking uses custom OTP-via-SES, not Cognito ForgotPassword (2026-07-04) — Locked
**Area:** Architecture
**Decision:** The D-078 spike is resolved: calling Cognito's `ForgotPassword` against a user in
`UserStatus: EXTERNAL_PROVIDER` returns `NotAuthorizedException: User password cannot be reset in the
current state` — confirmed against a real federated user (`admin@heediq.com`, Google) in the dev User
Pool. Cognito will never let a federated-only user through its native password-reset flow. The
linking-verification code is therefore custom-built, owned entirely by `heediq-api`: (1) `POST
/auth/link/request-otp` generates a 6-digit code, stores it in DynamoDB (`heediq-users` item or a new
short-TTL item, keyed by email, ~10 min TTL) and sends it via **SES** (reusing D-054/D-058's
`noreply@heediq.com` identity + `heediq-ses-email-sending` cross-account role, already granted to
`heediq-api`), (2) `POST /auth/link/confirm` verifies the code against DynamoDB, and on success calls
`AdminSetUserPassword` (not `ConfirmForgotPassword`) to set the password on the existing `sub`, then
flips `passwordSet=true` in the same request. Same non-disclosing UX as D-078 (generic "check your
email" prompt, no provider named) — only the delivery/verification mechanism changes.
**Why:** The spike this decision resolves was explicitly flagged as unverified in D-078 and D-082; it's
now proven Cognito has no native path for this case, so the fallback both decisions already
anticipated is what gets built. `AdminSetUserPassword` requires IAM credentials the browser never
holds, which is why `link/confirm` (already backend-owned per D-082) is the natural home for the new
`link/request-otp` endpoint too, rather than splitting OTP-send client-side and verify server-side.
**Supersedes:** D-078 (ForgotPassword-reuse mechanism only — identity model/GSI/passwordSet/generic
prompt unchanged), D-082 (the linking-OTP-request claim only — native sign-up/sign-in staying
client-direct is unaffected)
**Superseded by:** D-087 (custom OTP+SES mechanism replaced by Cognito-native SignUp/ConfirmSignUp
confirmation-code reuse — same problem, no custom OTP/SES code needed)
**Related code:** `heediq-api/src/routes/auth.ts` (`link/request-otp`, `link/confirm` — superseded,
see D-087)
