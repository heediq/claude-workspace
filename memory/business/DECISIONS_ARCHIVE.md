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
**Superseded by:** D-059 (Fargate Spot RunTask → EC2 GPU RunTask; upload/SQS/EventBridge flow unchanged), D-061 (client polling → WebSocket push), D-157 (EventBridge Pipes SQS→ECS consumer → dispatcher Lambda; presign→S3→SQS upload flow unchanged)
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
**Supersedes:** D-010 (scope only — build order sequence unchanged) **Superseded by:** D-140 (synthesis-output mechanism + the final "synthesis view" build-order step only — the multi-source-ingestion scope and the critical path through source-detail are unchanged and still load-bearing).
**Related code:** `memory/business/product.md`, `plans/wip-app-repos-scaffold.md`

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

### D-132 · Context Library — Summary becomes generic domain-keyed extraction (2026-07-20) — Locked
**Area:** Architecture
**Decision:** The `Summary` schema's hardcoded work fields (`requirements`/`decisions`/
`openQuestions`/`actionItems`) are replaced by a generic `extracted: Record<string, string[]>`
keyed by the filed Domain's `extractionFields`, plus a `domain` field recording which profile
shaped it. Keys are validated at write time against the Domain profile (D-131) so the shape can't
drift. `transcript` and provenance fields are unchanged.
**Why:** A fixed work-shaped Summary can't represent a study or personal (or `other`) extraction;
domain-keyed storage lets one schema carry every Domain's output and lets chat (D-126) read it
generically when assembling a Context's memory.
**Supersedes:** — **Superseded by:** D-135 (extraction storage moves to item-level `ExtractedItem`; domain-keyed *categorization* survives as each item's `category`) — fully superseded, archive at next consistency check.
**Related code:** `heediq-shared/src/domain.ts` (`SummarySchema`), `heediq-worker-summarization/src/writer.ts`
