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
- **4c · Cross-org grants + chat — ⬜ (fast-follow, D-142)**: grant issuance/revoke routes + per-request cross-org authorization middleware (authorize against a live unexpired grant every request — heavily isolation-tested); `heediq-chat` SQS queue + Lambda worker (infra, D-139); conversations/messages endpoints + chat-job enqueue (api). Plan separately (Step 2 of dev workflow) before starting.

No open PRs remain in any repo as of 2026-07-21 — 4a/4b fully landed on `develop`.

## Step 5 — Web (`heediq-web`) — ⬜
Bump 0.14.0. Context tree/library, source detail (curated `ExtractedItem`s), the interactive review wizard (D-137 steps 1–2), Context chat UI streaming via `useWsEvent('chat_delta'/'chat_complete')`. Kit + motion system only; all copy through `t()` (map `DOMAIN_PROFILES` slugs → labels).

## Step 6 — Fast-follow — ⬜
Decision Ledger generation + fill-in UI + chat-time gating (D-136) + wizard step 3 (D-137).

## Standing follow-ups
- Archive fully-superseded **D-132** → `DECISIONS_ARCHIVE.md` at the next consistency check (per its own annotation).
- Renovate will open `@heediq/shared` 0.14.0 bump PRs in consumer repos; each consumer's step above does the bump + the code update together (the breaking `Summary` change lands with the code that handles it).
