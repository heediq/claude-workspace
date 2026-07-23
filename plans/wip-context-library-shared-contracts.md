# WIP — Context Library build (multi-session)

**Spec:** `plans/context-library-spec.md` — build order is §11. **Decisions:** D-124–D-144.
This file tracks the whole Context Library build across repos/sessions, one step at a time.

## Step 1 — `@heediq/shared` contracts + Container→Context rename — ✅ DONE & SHIPPED

- Branch `feature/context-library-shared-contracts` → PR #38 merged to `develop` → release PR #39 merged to `main`.
- **`@heediq/shared@0.14.0` published to GitHub Packages** (Publish workflow green, 2026-07-20).
- Coherence fix (product.md Container→Context) + memory/dep-map updates committed to `claude-workspace`.

### What 0.14.0 contains (the contract next steps build on)
- `enums.ts`: `Domain`, `ContextStatus`, `SourceClassification`, `ExtractedItemStatus`, `LedgerEntryStatus`, `LedgerEntryOrigin`
- `domains.ts`: `DOMAIN_PROFILES` (work/study/personal/other; **slug-only** `extractionFields`/`starterPrompts`) + `DOMAIN_FIT_CONFIDENCE_THRESHOLD = 0.75`
- `context.ts`: `ContextSchema` (self-nesting `parentContextId`), `ProposedClassificationSchema` (exactly-one-of `proposedContextId`/`newContextName`), `ExtractedItemSchema`, `DecisionLedgerEntrySchema` + `LEDGER_REVIEW_CONFIDENCE_THRESHOLD = 0.5`
- `domain.ts`: Source +`contextId`/`classification`(optional, no default)/`proposedClassification`; **Summary shrunk** to `transcript`+`gist` (breaking, D-135)
- `ws.ts`: `classification_ready` / `chat_delta` / `chat_complete`

## Step 2 — Infra (`heediq-infra`) — ✅ DONE → **PR open** [heediq-infra#59](https://github.com/heediq/heediq-infra/pull/59) (branch `feature/context-library-infra-tables`)
> The `create-tables.ts` mirror lives on **`heediq-api` branch `feature/context-library-api`** (pushed, **kept open** — the Step 4 API work continues on it; not PR'd yet).
Six tables added in `lib/foundation/context-library-tables.ts` (split per D-103), composed by `tables.ts`, wired + SSM-exported in `foundation-stack.ts`, mirrored in `heediq-api/scripts/integration/create-tables.ts` (D-030). Tests: `test/foundation/tables.test.ts` (count 13→19 + 6 key/GSI assertions) + `ssm-exports.test.ts` (19→25 params). `pnpm run test:pre-pr` green (185 tests); heediq-api typecheck green. READMEs updated (`lib/foundation/README.md` key design + gotchas; top-level infra README SSM + key-design tables).

**Tables (key design, D-141/D-142 shaped the contexts + grants ones):**
- `heediq-contexts` — PK=`contextId`; GSI `by-scope` PK=`scopeKey`(`U#`/`G#`/`O#`) SK=`domainCreatedAt`(`<domain>#<createdAt>`). Serves personal/group/org in-org visibility (D-141), grouped by Domain; NOT a by-org GSI (would leak personal Contexts — D-021).
- `heediq-extracted-items` — PK=`sourceId` SK=`itemId`; GSI `by-context` (sparse on `contextId`) for chat memory (D-135).
- `heediq-decision-ledger` — PK=`contextId` SK=`entryId` (D-136). No `orgId` in contract → isolation via context-ownership chain.
- `heediq-conversations` — PK=`conversationId`; GSI `by-context` SK=`updatedAt` (D-138).
- `heediq-chat-messages` — PK=`conversationId` SK=`sk`(`ts#messageId`) (D-138).
- `heediq-context-grants` — PK=`granteeUserId` SK=`contextId`; GSI `by-context`; TTL `expiresAt` (cleanup only, expiry enforced in code). The regulated cross-org sharing primitive (D-142). PITR on.
- `heediq-chat` SQS/Lambda stack still deferred to the chat step (D-139). Source field additions + Summary shrink stayed non-key → no infra change.

**Forward deps for later steps (from D-141/D-142/D-143, don't lose these):**
- `@heediq/shared` **0.15.0 addendum** (Step 1 follow-on, lands with the API step): add `ContextVisibility` enum + `visibility`/`groupId?` to `ContextSchema` (D-141); add the cross-org **grant schema** + `access` enum (`read`/`contribute`) (D-142); add `context:share` permission key (append-only, D-106).
- **API step (Step 4):** writer computes `scopeKey`/`domainCreatedAt` on Context put; grant issuance/revoke routes + a per-request cross-org **authorization middleware** (authorize against a live, unexpired grant every request — heavily isolation-tested); contributed data homes in the Context's **owner org** (D-142).
- B2B/B2C productization (onboarding/positioning over the single-user-org model, D-143) ships in later PRs.

## Step 3 — Ingest (combined classify+extract, D-130/D-133) — ✅ DONE & MERGED
All 3 PRs merged: infra [heediq-infra#60](https://github.com/heediq/heediq-infra/pull/60) · worker [heediq-worker-summarization#16](https://github.com/heediq/heediq-worker-summarization/pull/16) · api [heediq-api#41](https://github.com/heediq/heediq-api/pull/41).
Full Step 3 across 3 repos (user chose the "emit classification_ready now" option). Workers don't push WS (D-109) — the worker writes `classification='pending_review'`; a `heediq-sources` DDB stream → `heediq-ws-classification-pusher` (heediq-api handler, shell in WebSocketStack) emits `classification_ready`.

- **`heediq-worker-summarization`** branch `feature/context-library-ingest` (commit 3fa74dc): bumped `@heediq/shared` ^0.12→^0.14; `provider.classifyExtract` = one Claude call → placement proposal + `gist` + items in the chosen Domain's shape; `shapeResult` enforces `other` fallback below `DOMAIN_FIT_CONFIDENCE_THRESHOLD` + drops items whose category is invalid for the final Domain + guarantees exactly-one placement; `context-loader.loadExistingContexts` reads candidate Contexts via `by-scope` GSI (`O#org`+`U#user`; **group scope `G#` deferred** — needs RBAC group lookup); `writer.writeExtractedItems` batch-writes to `heediq-extracted-items` (UnprocessedItems retry) + `writeSummaryAndClassification` sets gist/proposedClassification/`pending_review` on the Source and REMOVEs the old flat arrays. 28 tests.
- **`heediq-infra`** branch `feature/context-library-ingest-infra` (commit 3fcc881): SummarizationStack injects `CONTEXTS_TABLE_NAME`/`EXTRACTED_ITEMS_TABLE_NAME` + grants read on `heediq-contexts`(+GSI)/write on `heediq-extracted-items`; `heediq-sources` gains a `NEW_IMAGE` stream (in-place, no replacement); WebSocketStack adds the `heediq-ws-classification-pusher` Lambda shell on that stream, filtered to `classification='pending_review'`, via `grantPush`. 189 tests.
- **`heediq-api`** branch `feature/context-library-classification-pusher` (commit 9f08dcb): `src/handlers/classification-pusher.ts` (mirrors `ws-pusher.ts`) + `bundle:classification-pusher` + bump `@heediq/shared` ^0.13→^0.14. 204 tests.

**Deferred / flagged (carry forward):**
- `heediq-worker-transcription/src/models.py` **Summary mirror** still lists the old flat arrays — update it to `transcript`+`gist` (D-135) when that repo is next touched (consistency-check contract, §3). Not done this session (transcription repo untouched).
- **WS-CD gap (pre-existing):** `ws-connect`/`ws-pusher`/`classification-pusher` bundles are build-ready but **not wired into `heediq-api/.github/workflows/deploy.yml`** — WS handlers deploy manually. Out of Step 3 scope; flag for a WS-CD follow-up.
- **Group-scoped Contexts** not queried by the ingest classifier yet (only org+personal) — API-step follow-up.

## Step 4 — API (`heediq-api`) — ✅ 4a/4b DONE & MERGED, 4c (fast-follow) next

- **4a · `@heediq/shared` 0.15.0 addendum — ✅ SHIPPED** (PR [heediq-shared#40](https://github.com/heediq/heediq-shared/pull/40) merged, release PR [heediq-shared#41](https://github.com/heediq/heediq-shared/pull/41) merged — 0.15.0 published). `ContextVisibility` + `ContextGrantAccess` enums; `ContextSchema` +`visibility`(default personal)/+`groupId?` (required iff group); `ContextGrantSchema` (regulated cross-org share, `expiresAt` required, `ownerOrgId` homing); permission catalog appends `context:read/create/update/delete/share`.
- **4b-infra · `heediq-infra` ApiStack grants — ✅ DONE & MERGED** ([heediq-infra#61](https://github.com/heediq/heediq-infra/pull/61) merged to `develop`, branch `feature/context-library-api-grants`). Wires the `heediq-api` Lambda's IAM read/write grants + env vars for all 6 Context Library tables (previously only `SummarizationStack` had them). 190 tests.
- **4b-shared · `@heediq/shared` 0.15.1 addendum — ✅ DONE & SHIPPED**. PR [heediq-shared#42](https://github.com/heediq/heediq-shared/pull/42) merged, release PR merged to `main`, **0.15.1 published to GitHub Packages**. `CreateContextRequestSchema`/`UpdateContextRequestSchema` (mirrors `ContextSchema`'s visibility/groupId refine) + `ReviewApprovalRequestSchema` (`contextId`+`kept` item ids); `AuditPayloadMap` +`context`/+`extractedItemReview`. 230 tests.
- **4b-api · API routes — ✅ DONE & MERGED** ([heediq-api#42](https://github.com/heediq/heediq-api/pull/42) merged to `develop`, branch `feature/context-library-api`, bumped to 0.15.1). `src/routes/contexts.ts` (new — GET list/tree, POST, GET :id, PATCH :id, DELETE :id, writer computes `scopeKey`/`domainCreatedAt`) + `POST /sources/:id/review` review-approval endpoint on `sources.ts` (sets kept items' `contextId`+`status='kept'`, others `status='discarded'`, Source `classification='approved'`). Every mutating route: `requirePermission` + `auditWriter` (`context`/`extractedItemReview` payloads). 235 unit tests, integration suites green (contexts 12/12, sources 10/10). `heediq-api/README.md` updated (Key Files, Data Flow, Contracts, Dependencies, Testing, Gotchas). Also fixed two pre-existing latent bugs, root-caused per D-113 (unrelated to Context Library, picked up while getting the integration gate green): `resolveOwnerEmail`'s `'unknown'` fallback (invalid email format, 500ed PATCH/DELETE for any unseeded acting user) and `tests/integration/audit-log.test.ts`'s `seedEntry` (sk diverging from timestamp — deterministic, not a race, exposed by `requirePermission`'s D-114 denial-audit side effect). Both regression-tested; full gate green (235 unit / 53 integration tests). Also added `scripts/wipe-user.sh` dev utility (D-099 clean-slate identity retesting).
  **Not done in 4b-api (web-side, deferred to Step 5):** frontend `<Can>` gating — no `heediq-web` work happened this step.
  **Deferred out of 4b (per D-142's own locked fast-follow scoping, confirmed 2026-07-21):** grant issuance/revoke routes + cross-org authorization middleware — see Step 4c. Add group-scoped Contexts to the ingest classifier as a follow-up once group-scoped Context routes exist (RBAC group lookup).
- **4c-i · Cross-org grant issuance/revoke — ✅ DONE & MERGED** (branch `feature/context-library-grants`, both `heediq-shared` and `heediq-api`). `@heediq/shared` **0.15.2 published to GitHub Packages** ([heediq-shared#44](https://github.com/heediq/heediq-shared/pull/44) merged to `develop`, release PR [heediq-shared#45](https://github.com/heediq/heediq-shared/pull/45) merged to `main`, Publish workflow green, 2026-07-21): fixed `ContextGrantSchema.expiresAt` to epoch number, added `CreateContextGrantRequestSchema` + `contextGrant` audit payload. `heediq-api`: `config.ts` picks up `CONTEXT_GRANTS_TABLE_NAME`; `src/routes/context-grants.ts` (new — POST/DELETE grant, GET list-for-context, GET `/shared-with-me`, `resolveGranteeByEmail` helper, `requirePermission('context:share')` + `auditWriter` on mutations); `canAccessContext(c, item, minAccess?)` extended with a live per-request grant fallback (`hasActiveGrant()` + `GRANT_ACCESS_RANK` read/contribute comparison, never cached in JWT so revoke is immediate) — wired into `GET /contexts/:id` at `'read'` and `sources.ts`'s review route at `'contribute'`; PATCH/DELETE deliberately omit `minAccess` so a grant can never authorize mutating a Context entity. Consumes `@heediq/shared ^0.15.2` from the registry (the interim `pnpm link` workaround was dropped before merge). 243 unit tests (26 files) + 62 integration tests (10 files, incl. `context-grants.test.ts` covering issue/revoke/cross-org-reject/same-org-reject/tier-enforcement/immediate-revoke/list-views/wrong-owner-org-404). `heediq-api/README.md` updated (Key Files, Data Flow, Endpoints, Contracts, Dependencies, Testing, Gotchas). **[heediq-api#43](https://github.com/heediq/heediq-api/pull/43) merged to `develop`** 2026-07-21 (merge commit `d413531`). **All of Step 4 (4a/4b/4c-i) is now fully merged to `develop` across `heediq-shared` and `heediq-api`.**
- **4c-ii · Chat — ✅ DONE & MERGED** (2026-07-22). Full plan approved 2026-07-22 (incl. new **D-145**: `chat_failed` WS event, since D-139 only defined the success path). Branch `feature/context-library-chat` in `heediq-shared`/`heediq-infra`/`heediq-chat`; `heediq-api` used `feature/context-chat-conversations-routes`.
  - **`heediq-shared` — ✅ DONE & MERGED** ([heediq-shared#46](https://github.com/heediq/heediq-shared/pull/46) merged to `develop`). `ConversationSchema`/`ChatMessageSchema` (context.ts), `ChatJobMessageSchema` (messages.ts), `CreateConversationRequestSchema`/`CreateMessageRequestSchema` (requests.ts), `conversation`/`chatMessage` audit payloads (content excluded, D-093), `chat_failed` WS event (D-145). Bumped to 0.15.3. 257 tests, typecheck clean. **0.15.3 published to GitHub Packages** (verified via `gh run list --workflow=publish.yml` — publish run green).
  - **`heediq-infra` — ✅ DONE & MERGED**, in two PRs since the fix commit landed after the first merged: [heediq-infra#62](https://github.com/heediq/heediq-infra/pull/62) (new `ChatStack` in `lib/chat/chat-stack.ts` — SQS `heediq-chat`+DLQ+Lambda mirroring `SummarizationStack` (D-065 pattern); read-write grants on conversations/chat-messages, read-only on contexts/extracted-items/decision-ledger; `WebSocketStack.grantPush()` wired for `chat_delta`/`chat_complete`/`chat_failed`; `ApiStack` gets `CHAT_QUEUE_URL` env var + scoped `sqs:SendMessage`; `bin/infra.ts` composes `ChatStack` after `WebSocketStack`, before `ApiStack`) merged 2026-07-22, then [heediq-infra#63](https://github.com/heediq/heediq-infra/pull/63) (`grantPush()` only grants IAM on `heediq-ws-connections`, not the table-name env var `heediq-chat`'s own WS-push needs to query `by-user` — adds `WS_CONNECTIONS_TABLE_NAME` to the chat Lambda's env) merged same day. 211 tests, typecheck clean, `cdk synth -c env=dev` green.
  - **`heediq-chat` (new worker repo) — ✅ DONE & MERGED** ([heediq-chat#1](https://github.com/heediq/heediq-chat/pull/1) merged to `develop`). Mirrors `heediq-worker-summarization`'s layout; consumes `ChatJobMessage`, assembles Context memory, calls Claude with mandatory prompt caching (D-139), streams `chat_delta`/`chat_complete`/`chat_failed` via its own WS-push implementation (can't import `heediq-api`'s `src/lib/wsPush.ts` — separate Lambda/repo). Repo created with explicit confirmation before creation, per consequential-action policy. **One-time GitHub Packages gotcha hit on this PR** (new consumer repo, not previously covered by the process below): CI's `pnpm install` 403'd pulling `@heediq/shared` — the package's "Manage Actions access" list (web-UI-only GitHub Packages setting, no REST API for it) hadn't been extended to the new repo yet. Fixed by adding `heediq/heediq-chat` with Read access via the package's Settings page, then re-running the failed run. **Also brought its repo settings up to the other repos' convention**: default branch was `main` at repo-creation, switched to `develop`; branch protection (disallow force-push/deletion on `develop`+`main`, matching `heediq-api`/`heediq-infra`/`heediq-shared` exactly — no required status checks or reviews configured on any of them) had not been set at all, now is.
  - **`heediq-api` — ✅ DONE & MERGED** ([heediq-api#44](https://github.com/heediq/heediq-api/pull/44) merged to `develop`, branch `feature/context-chat-conversations-routes`, bumped to `@heediq/shared ^0.15.3`). `config.ts` picks up `CONVERSATIONS_TABLE_NAME`/`CHAT_MESSAGES_TABLE_NAME`/`CHAT_QUEUE_URL`; new `src/routes/conversations.ts` — `POST`/`GET /conversations?contextId=`, `GET`/`POST /conversations/:id/messages`, gated by `requirePermission('context:read')` + `canAccessContext()` (`'contribute'`-tier for starting a conversation/posting a message, `'read'`-tier for listing/viewing — a read-only cross-org grant can view a shared thread but never start or post into one); posting a message resolves the org's tier (`resolveTier()`, same pattern as `sources.ts`'s job enqueue) and enqueues a `ChatJobMessage` onto the chat SQS queue; `auditWriter` on both mutations, ids/role only, no message content (D-093). 260 unit tests (27 files) + full integration suite green (incl. 3 new conversations integration tests, DynamoDB Local + mocked SQS per D-030). `heediq-api/README.md` updated (Key Files, Data Flow, Contracts, Dependencies, Testing).
  - **All of Step 4 (4a/4b/4c-i/4c-ii) is now fully merged to `develop` across all four repos** (`heediq-shared`, `heediq-infra`, `heediq-chat`, `heediq-api`). Not yet done: an end-to-end smoke check (a real chat turn producing `chat_delta`/`chat_complete` over WS against a deployed `dev` stack) and promoting any of these repos' `develop`→`main` for staging/prod (not requested this session — `develop`-push already deploys to `dev` per each repo's CI/CD).

## Step 4c-ii smoke check (dev) — ✅ GREEN (2026-07-23)

End-to-end Context-chat smoke passed on the deployed **dev** stack: create Context → conversation →
post message → `heediq-chat` consumes the SQS job → streams `chat_delta` → persists → `chat_complete`
over WS (client assembled `"PONG"`, `completed: true`). Auth: `admin@heediq.com` via non-admin
`USER_PASSWORD_AUTH`. The smoke uncovered **7 real deploy/config/code gaps** invisible to unit +
integration tests (the case D-147 makes). Fixes:

1. **Stale RBAC seed** — dev admin/member roles (provisioned 2026-07-16) lacked the Context Library
   `context:*` perms → every Context route 403'd. Backfilled live. Locked **D-146** (append a perm →
   backfill existing orgs' system roles).
2. **`roles` PATCH 500** — `permissions` is a DynamoDB reserved word, wasn't aliased (`#permissions`).
   Fixed on branch `fix/roles-patch-permissions-reserved-word` (heediq-api) + integration regression
   (PATCH now updates permissions, not just name). **Committed, NOT yet PR'd** — needs the roles
   integration suite (DynamoDB Local) run before PR (Step 4.6).
3. **`heediq-chat` never deployed to dev** — its first deploy failed OIDC assume-role because GitHub
   now gives new repos the **immutable subject** `repo:heediq@<orgId>/<repo>@<repoId>:...`, which the
   `GitHubActionsDeployRole` trust (`repo:heediq/*:*`) didn't match. Dev trust patched live; durable
   fix `scripts/setup.sh` (both subject formats) → **heediq-infra#64 OPEN** (review + re-run setup.sh
   on staging/prod before any new repo deploys there).
4. **Missing Claude secrets** — `/heediq/chat/anthropic-api-key` + `/heediq/summarization/anthropic-api-key`
   never provisioned (per-service-secret convention confirmed; secrets are out-of-band, D-038). Andrii
   created both. (Note: summarization's was equally missing — its Claude call would also have failed.)
5. **`heediq-chat` ledger query bug** — `loadLedgerAnswers` built `KeyConditionExpression 'contextId =
   :cid'` with no `ExpressionAttributeValues` → 400 every turn. **heediq-chat#2 MERGED + deployed.**
6. **WS-CD gap** — `heediq-api/.github/workflows/deploy.yml` never deployed the WS handlers
   (`ws-connect`/`ws-pusher`→`heediq-ws-status-pusher`/`classification-pusher`), so they were infra
   placeholders since 2026-07-02: `$connect` returned 200 but wrote no connection row → chat push
   found 0 connections. Wired all three into CD → **heediq-api#45 MERGED.**
7. **WS zip filename** — #45 zipped `ws-connect.js` but the Lambdas run `index.handler` →
   `Runtime.ImportModuleError` at cold start (handshake failed). Repackaged as `index.js` →
   **heediq-api#46 MERGED + deployed.**

**Smoke script** lives in scratchpad (`chat-e2e.mjs`, Node 22 global WebSocket). Per D-147 it should be
generalized into a committed `tests/e2e/` smoke (owning repo) — **not yet done.**

**Backlog raised this session:** evaluate **WIF / keyless Anthropic auth** (Console Workload Identity
Federation — GA, no static key, auto-refresh; would retire the per-service Claude secrets + rotation +
onboarding gap; needs AWS-Lambda→Anthropic federation feasibility verified). Also verify `ws-pusher`
(`heediq-ws-status-pusher`) + `classification-pusher` now behave post-deploy (D-061/Step-3 paths).

## Step 5 — Web (`heediq-web`) — ⬜
Bump 0.15.3 (was 0.14.0 at last check — `/contexts`, `/context-grants`, and now `/conversations` routes plus the `ContextGrant`/chat contracts are all available to build against). Context tree/library, source detail (curated `ExtractedItem`s), the interactive review wizard (D-137 steps 1–2), Context chat UI streaming via `useWsEvent('chat_delta'/'chat_complete'/'chat_failed')`. Kit + motion system only; all copy through `t()` (map `DOMAIN_PROFILES` slugs → labels).

**Chat UI bar (read before building the chat panel):** `rules/04-loading-and-feedback.md` §6 — hold the
chat panel to the ChatGPT/Claude.ai feel specifically (token-by-token streaming, pre-first-token
thinking indicator, scroll-aware auto-scroll, Stop/Retry, incremental markdown, per-turn copy) — this
is a flagship surface the user explicitly wants held to that bar, not treated as a generic async form.

## Session 2026-07-23 (Step 5 kickoff) — progress
- **Cleanup 1 — roles PATCH fix → PR OPEN [heediq-api#47](https://github.com/heediq/heediq-api/pull/47).** Branch `fix/roles-patch-permissions-reserved-word` was stale (cut after #45, before #46) — its diff spuriously *reverted* #46's WS-zip `index.js` fix. Merged `develop` in (auto-resolved deploy.yml to develop's version); branch now diffs only `roles.ts` + `roles.test.ts`. Test gate green: typecheck + 260 unit, roles integration suite 5/5 (DynamoDB Local, incl. the new PATCH-with-permissions regression). Left for review — not merged.
- **Cleanup 2 — heediq-infra#64 already MERGED** (df89a7c on develop; local switched off the branch). **`scripts/setup.sh` re-run on staging+prod BLOCKED**: all four SSO sessions (`heediq-shared/dev/staging/prod`) expired; `aws sso login` needs an interactive browser flow unavailable in this session, and setup.sh runs all four accounts in one `set -e` pass (fails fast at the shared `verify_auth`). **Handed back to Andrii: `aws sso login --profile heediq-{shared,dev,staging,prod}` then `bash heediq-infra/scripts/setup.sh`.**
- **Step 5 bump DONE** — `@heediq/shared ^0.13.0 → ^0.15.3` on new branch **`feature/context-library-web`** (commit `0ceec80`). Bump surfaced a real gap the test gate caught: `PERMISSIONS` gained `context:{read,create,update,delete,share}` (D-146) but the `en` translation had no `rolesSettings.permissions` labels → `permission-coverage.test` failed. Added the five labels. Typecheck clean, 213 unit tests green.
- **Backend dep found for Step 5:** no endpoint returns a Source's `ExtractedItem`s (`GET /sources/:id` returns only the Source; review route reads items internally). Source-detail + review-wizard both need a new **`GET /sources/:id/items`** heediq-api route (no new shared contract — `ExtractedItemSchema` exists). Flagged in the Step-2 plan as a prerequisite API slice.
- **Kit gaps for Step 5:** no `EmptyState`, `Skeleton`, `Tabs`, `Tree`, `Stepper`, chat primitives, or markdown-render dep — all to be added to the kit + `/dev/ui` gallery.
- **Step-2 plan presented to Andrii 2026-07-23 — awaiting approval before any UI code.**

## Next session — Step 5 (Web) — READY TO START
Chat backend fully merged (all 4 repos) **and dev-smoke GREEN 2026-07-23** (see "Step 4c-ii smoke check"
above). Nothing left on the backend. **Kick off Step 5 like this:**
1. **First, resolve the two open cleanup items** (non-blocking, both worked around live):
   - PR the roles PATCH fix — branch `fix/roles-patch-permissions-reserved-word` on **heediq-api**
     (committed, typecheck clean) — run the roles integration suite (DynamoDB Local) then `gh pr create`.
   - **heediq-infra#64** (OIDC immutable-subject trust) — review/merge, then re-run `scripts/setup.sh`
     on staging/prod accounts.
2. **Bump `@heediq/shared` 0.14.0 → 0.15.3** in heediq-web (all `/contexts`, `/context-grants`,
   `/conversations` routes + ContextGrant/chat contracts available).
3. Read `rules/03-ui-kit.md` + `rules/04-loading-and-feedback.md` (§6 for the chat panel bar) +
   `heediq-web/README.md` + sub-module READMEs; then **write a Step-2 plan and get approval before UI code.**
4. Build: Context tree/library, source detail (curated `ExtractedItem`s), review wizard (D-137 steps 1–2),
   Context chat panel streaming via `useWsEvent('chat_delta'/'chat_complete'/'chat_failed')`. Kit + motion
   only; copy through `t()` (map `DOMAIN_PROFILES` slugs → labels). Tree/library + wizard don't need chat
   and can ship first; wire the chat panel in once its screens exist.
5. Per **D-147**, generalize the passing smoke (`scratchpad/chat-e2e.mjs`) into a committed `tests/e2e/`.

## Step 6 — Fast-follow — ⬜
Decision Ledger generation + fill-in UI + chat-time gating (D-136) + wizard step 3 (D-137).

## Standing follow-ups
- Archive fully-superseded **D-132** → `DECISIONS_ARCHIVE.md` at the next consistency check (per its own annotation).
- Renovate will open `@heediq/shared` 0.14.0 bump PRs in consumer repos; each consumer's step above does the bump + the code update together (the breaking `Summary` change lands with the code that handles it).
