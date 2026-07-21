# WIP — Context Library build (multi-session)

**Spec:** `plans/context-library-spec.md` — build order is §11. **Decisions:** D-124–D-140.
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

## Step 2 — Infra (`heediq-infra`) — ✅ DONE (branch `feature/context-library-infra-tables`, not yet PR'd)
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

## Step 3 — Ingest (`heediq-worker-summarization`) — ⬜
Bump `@heediq/shared` to 0.14.0. Add the **combined classify+extract** Claude call (D-130): input = content + user's Contexts + `DOMAIN_PROFILES`; output = `ProposedClassification` (+ `other` fallback under `DOMAIN_FIT_CONFIDENCE_THRESHOLD`) + `ExtractedItem`s. Persist `proposedClassification` on the Source, set `classification: 'pending_review'`, emit `classification_ready`. Stop writing the old flat `Summary` arrays; write `gist` + `ExtractedItem`s. Update `heediq-worker-transcription/src/models.py` Summary mirror.

## Step 4 — API (`heediq-api`) — ⬜
Bump 0.14.0. Contexts CRUD (+ tree), review-approval endpoints, conversations/messages endpoints, chat-job enqueue. Every mutating route: `requirePermission` + `auditWriter` (extend `AuditPayloadMap`) + frontend `<Can>` (D-107).

## Step 5 — Web (`heediq-web`) — ⬜
Bump 0.14.0. Context tree/library, source detail (curated `ExtractedItem`s), the interactive review wizard (D-137 steps 1–2), Context chat UI streaming via `useWsEvent('chat_delta'/'chat_complete')`. Kit + motion system only; all copy through `t()` (map `DOMAIN_PROFILES` slugs → labels).

## Step 6 — Fast-follow — ⬜
Decision Ledger generation + fill-in UI + chat-time gating (D-136) + wizard step 3 (D-137).

## Standing follow-ups
- Archive fully-superseded **D-132** → `DECISIONS_ARCHIVE.md` at the next consistency check (per its own annotation).
- Renovate will open `@heediq/shared` 0.14.0 bump PRs in consumer repos; each consumer's step above does the bump + the code update together (the breaking `Summary` change lands with the code that handles it).
