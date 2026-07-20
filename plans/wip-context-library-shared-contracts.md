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

## Step 2 — Infra (`heediq-infra`) — ⬜ NEXT
Create the tables the contracts imply (key design is a recorded decision per eng-std §8):
- `heediq-contexts` — PK/SK + `by-org` GSI for the D-134 tree (list/tree a user's Contexts)
- ExtractedItem store — access patterns: by `contextId` (+ descendants) for chat memory, by `sourceId` for the review wizard
- Decision Ledger table (D-136) — by `contextId`
- `heediq-conversations` (GSI `by-context`) + `heediq-chat-messages` (PK=`conversationId`, SK=`ts#messageId`), D-138
- New `heediq-chat` stack scaffolding can wait until the chat step (D-139), but tables can land now
- **Mirror every new table/GSI in `heediq-api/scripts/integration/create-tables.ts`** (hand-mirrored, D-030 drift risk)
- Source field additions + Summary shrink are **non-key attrs → no infra change**

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
